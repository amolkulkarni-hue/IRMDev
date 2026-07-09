/*
* Updates the Lookup fields under Account Coverage Section by copying data from Formula field to Lookup field.
* Field mappings are stored in AccountCoverageFieldsSync__c CUstom Setting.
* #26231 #26660 
*/
global class AccountCoverageFieldsSync implements Database.Batchable<sObject>, Database.Stateful {
    
    global static final String objName = 'Account';
    
    public static final String initialQuery = 'SELECT Id FROM ' + objName;
    global static final List<AccountCoverageFieldsSync__c> AccountCoverageFields=[select id,From_Field__c, To_Field__c from AccountCoverageFieldsSync__c];
    global static final Map<String,String> mapFromToFields =new Map<String,String>();
    
    public final String Query{get; private set;}
    public Schema.sObjectType SObjType{get; private set;}
    
    public Integer RecordsProcessed{get; private set;}
    public Integer RecordsUpdated{get; private set;}   
    public Integer Errors{get; private set;}
    public Integer tobeUpdated{get; private set;}
    
    public AccountCoverageFieldsSync(){
        this(null);
        System.debug('============== inside default constructor ========================');
    }
    
    public AccountCoverageFieldsSync(String query){
        System.debug('============== inside constructor AccountCoverageFieldsSync(String query) ========================');
        
        this.Query = (query!=null)? query : initialQuery;
        recordsProcessed = 0;
        recordsUpdated = 0;
        errors=0;
        tobeUpdated=0;
        
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('============== inside start method ========================');
        if(Test.IsRunningTest()){
            String Querttest=query;
            return Database.getQueryLocator(Querttest);
        }
        else{
            return Database.getQueryLocator(query);
        }
    }
    
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        System.debug('============== inside execute method ========================');
        System.debug(userinfo.getUserId());
        
        //this is a workaround to create a list of sObjects of the same type as the query. This is better than cloning and clearng the 'scope' list collection 
        List<SObject> sObjsToUpdate = database.query('Select Id From ' + objName + ' Limit 0');
        
        System.debug(scope);
        Set<Id> sObjIds = new Set<Id>();
        for(sObject sObj : scope){
            sObjIds.add(sObj.Id);
        }
        
        System.debug('============== inside processing block. Size of the batch to process: ' + sObjIds.size() + ' ========================');  
        
        String getFields='Select Id,Name,IM_Hierarchy_Level__c';
        String SObjectQuery=' from Account where';
        String whereClause=' Id IN :sObjIds';
        
        sObjType = Schema.getGlobalDescribe().get(objName);
        System.assert(sObjType != null, 'Object ' + objName + 'cannot be retrieved from the Schema definition.');
        
        DescribeSObjectResult objDef = sObjType.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();
        System.debug(fields);
        System.debug('fieldmap'+AccountCoverageFields);
        for(AccountCoverageFieldsSync__c cov: AccountCoverageFields)
        {
            mapFromToFields.put(cov.From_Field__c,cov.To_Field__c);  
            getFields+= ','+cov.From_Field__c +','+cov.To_Field__c;
        } 
        
        System.debug(mapFromToFields);
        for(String fromFieldName : mapFromToFields.keySet()){ 
            String toFieldName = mapFromToFields.get(fromFieldName);
            
            System.assert(fields.keySet().contains(fromFieldName.toLowerCase()), 'Field name "' + fromFieldName + '" cannot be retrieved from the Schema definition');
            System.assert(fields.keySet().contains(toFieldName.toLowerCase()), 'Field name "' + toFieldName + '" cannot be retrieved from the Schema definition');      
        }
        
        
        sObject [] sObjs = Database.Query(getFields+SObjectQuery+whereClause);
        
        
        for(sObject sObj : sObjs){
            //process batch 
            System.debug('=========== inside inner loop - iterating over each record in the batch  ===================');
            System.debug('-------------- sObject before update: ' + sObj);
            
            
            Boolean updateRecord = false;
            
            for(String fromFieldName : mapFromToFields.keySet()){
                System.debug('=========== inside 2nd inner loop - iterating over each field in the field map, comparing and copying values ===================');
                
                String toFieldName = mapFromToFields.get(fromFieldName);
                
                //Schema.sObjectField fromField = mapFieldNameToType.get(fromFieldName);
                //Schema.sObjectField toField = mapFieldNameToType.get(toFieldName);
                System.debug('-------------- ' + fromFieldName + ': ' + sObj.get(fromFieldName));
                System.debug('-------------- ' + toFieldName + ': ' + sObj.get(toFieldName));
                
                //#34498: Skip copy-down for Sector and Industry when Industry Override = True on CP
                if(sObj.get('Industry_Override__c') == True && sObj.get('IM_Hierarchy_Level__c')=='Country Parent' && 
                  (fromFieldName == 'Sector_Formula__c' || fromFieldName == 'Industry_Formula__c')){
                      System.debug('---------Skipped Copy:: Industry Override = True + CP + Industry/Sector------------');
                    continue;
                }
                
                // Normal copy-down logic
                if((sObj.get(fromFieldName)) != (sObj.get(toFieldName))){
                    System.debug('-----------  inside if - updating target field ---------------- ');
                    Object fromfieldValue=sObj.get(fromFieldName);
                    sObj.put(toFieldName,  fromfieldValue);
                    System.debug('----- Copying Down: '+ fromFieldName + ' --> '+ sObj.get(fromFieldName));
                    System.debug('----- Copying Down: '+ toFieldName + ' --> '+ sObj.get(toFieldName));
                    
                    updateRecord = true;
                }
            }
            if(updateRecord)
                sObjsToUpdate.add(sObj);
        }
        
        List<Database.SaveResult> res=Database.update(sObjsToUpdate,False);
        
        recordsProcessed = recordsProcessed + scope.size();
        tobeUpdated = tobeUpdated + sObjsToUpdate.size();
        
        
        for(Integer i=0; i < res.size(); i++) {
            if(res.get(i).isSuccess()) {
                System.debug('Records are updated Successfully');
                recordsUpdated=recordsUpdated+1;
            } 
            else if(!res.get(i).isSuccess()) {
                Database.Error error =  res.get(i).getErrors().get(0);
                System.debug('Error Occurs While Processing The Record'+error.getMessage());
                System.debug('Failure Record Ids While Updating'+res.get(i).Id);
                errors=errors+1;
            }
        }
        
        System.debug('^^^^^^^^^^^^^^^^^^^^ Total Records Processed: ' + recordsProcessed);
        System.debug('^^^^^^^^^^^^^^^^^^^^ Total Records Updated: ' + recordsUpdated);
        
    }
    
    
    global void finish(Database.BatchableContext BC){
        System.debug('============== inside finish method ========================');
        
        
        AsyncApexJob job = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                            from AsyncApexJob where Id = :BC.getJobId()];
        
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {job.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
        mail.setSubject(objName + 'Account Coverage Field Sync Apex Batch Job: ' + job.Status);
        mail.setPlainTextBody('Dear ' + job.CreatedBy.Firstname + ', ' +
                              '\n\nThe batch Apex job processed ' + job.TotalJobItems + ' batches with '+ job.NumberOfErrors + ' failures.' +
                              '\n\nTotal records processed: ' + recordsProcessed +
                              'Actually updated: '+recordsUpdated+'Errors: '+errors);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
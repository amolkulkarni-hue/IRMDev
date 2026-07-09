/*
Auhtor       : Andrey Volosevich
Company      : Fujitsu America
Created Date : 21 Dec-2009
Description  : Batch Apex class for copying values between fields in an object. This is a pilot implementation.
               May need to be updated/enhanced after the pilot is complted.
               
Updated      : Apr 28, 2010
Description  : Also included GUDUNS_Name, GUDUNS_Nbr into batch job    - #nganji# 

Updated    : Sep 09, 2010
Description: 1)GUDUNS_Name, GUDUNS_Nbr are places out of sync process and  going forward they will be used by D&B process.       
            
          2)To Support the BI process we need the LastModifiedDate to be updated incase of any GUDUNS changes. So we have created new
            place holders High_Level_Name__c, High_Level_Key__c to be in sync with GUDUNS_Name_Formula, GUDUNS_Nbr_Formula
Updated : January 21, 2010
           1.  Add Digital Sales Executive filed to sync process.            
*/
/*
    Developer Name:Madhu Paladugu
    Description   : added some fields(Enterprise_ISR_DBR_FORMULA__c,Enterprise_ISR_DBR__c,Enterprise_ISR_RM_FORMULA__c,Enterprise_ISR_RM__c) and removed "Digital Sales Executive" field. 
    Case          : 602350
    Date          : 9/26/12
*/
/*
    Developer Name:Madhu Paladugu
    Description   : added some fields(Primary_BDE_FORMULA__c,Primary_BDE__c,Primary_CDE_Formula__c,Primary_CDE__c,IMGA_Owner_Formula__c, IMGA_Owner__c ,IMGA_Owner_Director_formula__c ,IMGA_Owner_Director__c) for synchronization.
    Case          : 01073189
    Date          : 1/16/13
*/
/*
    Developer Name:Madhu Paladugu
    Description   : added some fields(Primary_BDE_DB_R__c, Primary_BDE_DB_R_Formula__c, Primary_CDE_DB_R__c, Primary_CDE_DB_R_Formula__c) fields to SynchronizeFieldValues batch class. 
    Case          : 01104242
    Date          : 1/30/13
*/
/* Developer Name : Madhu Paladugu
   Discription    : Remove the following fields from the batch job IM_Enterprise_Account_Executive__c,IM_Enterprise_Account_Executive_FORMULA__c,IM_Enterprise_Account_Manager__c,IM_Enterprise_Account_Manager_FORMULA__c,IM_Digital_Sales_Executive__c,IM_Digital_Sales_Executive_Formula__c,Enterprise_ISR_DBR__c,Enterprise_ISR_DBR_FORMULA__c,Enterprise_ISR_RM__c,Enterprise_ISR_RM_FORMULA__c
   Case           : 01112078
   Date           : 1/31/13
*/
/* Developer Name: Sandhya Ramesh
   Description   : Add Tele_CDE__c field to be updated upon batch run using value from Tele_CDE_Formula__c
   Case          : 03624018
   Date          : 05/06/2015
*/
/* Developer Name: Gopinandan Biswal
   Description   : Add Library_Services_BDE__c field to be updated upon batch run using value from Library_Services_BDE_Formula
   Case          : 06101648
   Date          : 01/02/2017
*/

/* Developer Name: Vinutha Iyengar
   Description   : Add Information_Governance_Rep__c field to be updated upon batch run using value from Information_Governance_Rep_Formula__c
   Case          : 06481552 
   Date          : 27/06/2017
*/
/* Developer Name: Masthan vali Patnam
   Description   : Added two fields in SOQL query i.e Data_Center_BDE__c, Data_Center_BDE_Formula__c
   Case          : 07401502 
   Date          : 23/11/2017
*/
/* Developer Name: Masthan vali Patnam
   Description   : Added field DM_Cloud_Sales_Rep__c, DM_Cloud_Sales_Rep_Formula__c and Removed DM_Cloud_Sales_Rep__c
   Case          : 08050817 
   Date          : 06/03/2018
*/
/* Developer Name: Amarendra
   Description   : Added fields IM_Partner_Type__c,Partner_Type_Formula__c,Partner_Overview_Formula__c,IM_Partner_Overview__c
   Case          : 07956824 
   Date          : 28/03/2018
*/
/* Developer Name: Keerthi Senthilnathan
   Description   : Added fields Global_Account_Director_Formula__c, Global_Account_Director__c, Global_Account_Manager_Formula__c, Global_Account_Manager__c, Global_IMGA_Owner_Formula__c and Global_IMGA_Owner__c
   Case          : 08630064 
   Date          : 13/07/2018
*/
/* Developer Name: Amarendra Nallamalli
   Description   : Added fields Global_Account_Formula__c, Global_Account__c
   Case          : 08321313
   Date          : 19/07/2018
*/
/* Developer Name: Rangababu Chimata
   Description   : Added fields Primary_Local_Market_Rep_1__c, Entertainment_Services_CDE_Formula__c
   GitLabStory   : 1854
   Date          : 15/07/2021
*/
/*#26660 #26231: Created a new Custom Setting SynchronizeFieldValues to store the From and To fields*/

global class SynchronizeFieldValues implements Database.Batchable<sObject>, Database.Stateful {

    global static final Integer QUERY_BATCH_SIZE = 200;
    global static final String objName = 'Account';
    /* Added two fields IMGA_Owner_DB_R__c,IMGA_Owner_DB_R_FORMULA__c batch job,date :3/20/13 */
    //TODO: Extract the map population to a separate class potentially to a Custom Setting. It should be passed into this class as a parameter
    /*#26660 #26231 : Storing these mappings in Custom Setting SynchronizeFieldValues
     * global static final Map<String, String> mapFromToFields = new Map<String, String>{
        'IM_IMGA__c' =>  'IM_IMGA_Indexed__c', 
        'IM_Sales_Segment_FORMULA__c' =>  'IM_Sales_Segment__c',
        'Global_Account_Formula__c' => 'Global_Account__c',// added on 18/07/2018 by Amar
        'Partner_Type_Formula__c' => 'IM_Partner_Type__c',
        'Partner_Overview_Formula__c' => 'IM_Partner_Overview__c',
        'IM_GUDUNS_Name_Formula__c' => 'High_Level_Name__c',
        'IM_GUDUNS_Nbr_Formula__c' => 'High_Level_Key__c',
        'Primary_BDE_FORMULA__c' => 'Primary_BDE__c',
        'Data_Center_BDE_Formula__c' => 'Data_Center_BDE__c',   
        'Primary_CDE_Formula__c' => 'Primary_CDE__c',
        'IMGA_Owner_Formula__c' => 'IMGA_Owner__c'  ,
        'IMGA_Owner_Director_formula__c' => 'IMGA_Owner_Director__c',
        //#26660 Field is deleted 'Primary_BDE_DB_R_Formula__c' => 'Primary_BDE_DB_R__c',
        'Tele_CDE_Formula__c' => 'Tele_CDE__c', //Added on 05/06/2015 by Sandhya Ramesh for Case #03624018
        'Country_Parent_ID__c' => 'CountryParentIDText__c', //Added on 10/06/2015 by Sandhya Ramesh for indexing field for reports
        'Country_Parent_Formula__c' => 'CountryParentNameText__c', //Added on 18/06/2015 by Sandhya Ramesh for indexing field for reports
        //#26660 Field is deleted 'Primary_CDE_DB_R_Formula__c' => 'Primary_CDE_DB_R__c',
        //#26660 Field is deleted 'IMGA_Owner_DB_R_FORMULA__c' => 'IMGA_Owner_DB_R__c', 
        'IMGA_Id__c' => 'IMGA_Lookup__c', // added on 22/8/2014 by Kavya Somashekar
        'DMS_Owner_Formula__c' => 'DMS_Owner__c',// added on 16/1/2015 by vijay andrews
        'Account_Sub_Segment_lookup_ID__c' => 'Account_Segment_lookup__c', //added on 20/10/2014 by Kavya Somashekar
        //'Account_Sub_Segment_Formula__c' => 'Account_Segment_lookup__c' //added on 11/05/2014 by Venkat
        //'Library_Services_BDE_Formula__c' => 'Library_Services_BDE__c', //added on 01/02/2017 by Gopinandan
        'DM_Cloud_Sales_Rep_Formula__c' => 'DM_Cloud_Sales_Rep__c', // added on 06/03/2018 by Masthan
        'Information_Governance_Rep_Formula__c' => 'Information_Governance_Rep__c', // added on 27/June/2017 by Vinutha 
        'Global_Account_Director_Formula__c' => 'Global_Account_Director__c', 
        'Global_Account_Manager_Formula__c' => 'Global_Account_Manager__c', 
        'Global_IMGA_Owner_Formula__c' => 'Global_IMGA_Owner__c', // added on 13/07/2018 by Keerthi
        'Entertainment_Services_CDE_Formula__c' => 'Primary_Local_Market_Rep_1__c' //Added by Rangababu on 15/07/2021
    };*/

    //global final Map<String, Schema.sObjectField> mapFieldNameToType = new Map<String, Schema.sObjectField>();
    
    public static final String initialQuery = 'SELECT Id FROM ' + objName;
    global static final List<SynchronizeFieldValues__c> SynchronizeFieldValues=[select id,From_Field__c, To_Field__c from SynchronizeFieldValues__c];
    global static final Map<String,String> mapFromToFields =new Map<String,String>();
      
      //String str = '0018000000ZQ4b5';
      //public static final String initialQuery = 'SELECT Id FROM Account Where Id=:str';  
    public final String Query{get; private set;}
    public Schema.sObjectType SObjType{get; private set;}
    
    public Integer RecordsProcessed{get; private set;}
    public Integer RecordsUpdated{get; private set;}   
    public Integer Errors{get; private set;}
    public Integer tobeUpdated{get; private set;}
    
    public SynchronizeFieldValues(){
        this(null);
        System.debug('============== inside default constructor ========================');
    }

    public SynchronizeFieldValues(String query){
        System.debug('============== inside constructor SynchronizeFieldValues(String query) ========================');
        
        this.Query = (query!=null)? query : initialQuery;
        recordsProcessed = 0;
        recordsUpdated = 0;
        errors=0;
        tobeUpdated=0;
        
        //Prepare and validate input. This should later be extracted to a separate method of class
        sObjType = Schema.getGlobalDescribe().get(objName);
        System.assert(sObjType != null, 'Object ' + objName + 'cannot be retrieved from the Schema definition.');

        DescribeSObjectResult objDef = sObjType.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();
        
        for(String fromFieldName : mapFromToFields.keySet()){ 
            String toFieldName = mapFromToFields.get(fromFieldName);
            
            System.assert(fields.keySet().contains(fromFieldName.toLowerCase()), 'Field name "' + fromFieldName + '" cannot be retrieved from the Schema definition');
            System.assert(fields.keySet().contains(toFieldName.toLowerCase()), 'Field name "' + toFieldName + '" cannot be retrieved from the Schema definition');      

            //add both to To and From fields to the map
            //mapFieldNameToType.put(toFieldName, fields.get(toFieldName));
            //mapFieldNameToType.put(fromFieldName, fields.get(fromFieldName));
        }
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('============== inside start method ========================');
        if(Test.IsRunningTest()){
            String Querttest=query+' limit 20';
            return Database.getQueryLocator(Querttest);
        }
        else{
            return Database.getQueryLocator(query);
        }
    }

    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
    
            System.debug('============== inside execute method ========================');
        
        //this is a workaround to create a list of sObjects of the same type as the query. This is better than cloning and clearng the 'scope' list collection 
        List<SObject> sObjsToUpdate = database.query('Select Id From ' + objName + ' Limit 0');
        
    
        Set<Id> sObjIds = new Set<Id>();
        for(sObject sObj : scope){
            //break up the table for querying batches as per SFDC R&D recommendation on 01/14/2009
            sObjIds.add(sObj.Id);
        }
            
        System.debug('============== inside processing block. Size of the batch to process: ' + sObjIds.size() + ' ========================');  
        //TODO: Consider refactoring to build the SOQL dynamically. This would allow later to make this code abstract to work on any object.
        //Using Custom Setting Data to build a Map of From and To fields
        for(SynchronizeFieldValues__c cov: SynchronizeFieldValues)
         {
           mapFromToFields.put(cov.From_Field__c,cov.To_Field__c);  
         } 
                           
        sObject [] sObjs = [SELECT Id, Name,
                                IM_IMGA_Indexed__c, IM_IMGA__c, IM_Sales_Segment__c, IM_Sales_Segment_FORMULA__c,
                                IM_GUDUNS_Name_Formula__c, High_Level_Name__c, IM_GUDUNS_Nbr_Formula__c, High_Level_Key__c
                                ,IMGA_Owner_Formula__c, IMGA_Owner__c ,
                                IMGA_Owner_Director_formula__c ,IMGA_Owner_Director__c, 
                                IMGA_Id__c, IMGA_Lookup__c, 
                                Account_Sub_Segment_Formula__c, 
                                Country_Parent_ID__c, CountryParentIDText__c, Country_Parent_Formula__c, CountryParentNameText__c,
                                
                                IM_Partner_Type__c,Partner_Type_Formula__c,Partner_Overview_Formula__c,
                                IM_Partner_Overview__c,
                                Global_Account_Formula__c,Global_Account__c,IM_Territories__c,
                                D_B_Segmentation__c,D_B_Segmentation_Formula__c, Program_Designation_Formula__c, Program_Designation__c
                                FROM Account
                                WHERE Id IN :sObjIds];
        
                
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
                                
                if((sObj.get(fromFieldName)) != (sObj.get(toFieldName))){
                    System.debug('-----------  inside if - updating target field ---------------- ');
                    //Case #08321313 - Global Accounts: Account Field Identifier : Below condition is to convert from String to Boolean(checkbox value)
                    if(fromFieldName == 'Global_Account_Formula__c'){
                        sObj.put(toFieldName,  Boolean.valueOf(sObj.get(fromFieldName)));
                    }else{
                        sObj.put(toFieldName,  String.valueof(sObj.get(fromFieldName)));
                    }
                    updateRecord = true;
                }
            }
            if(updateRecord)
                sObjsToUpdate.add(sObj);
        }
        
        List<Database.SaveResult> res=Database.update(sObjsToUpdate,False);
        
        recordsProcessed = recordsProcessed + scope.size();
       // recordsUpdated = recordsUpdated + sObjsToUpdate.size();
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
        mail.setSubject(objName + ' Field Synchronization Apex Batch Job: ' + job.Status);
        mail.setPlainTextBody('Dear ' + job.CreatedBy.Firstname + ', ' +
            '\n\nThe batch Apex job processed ' + job.TotalJobItems + ' batches with '+ job.NumberOfErrors + ' failures.' +
            '\n\nTotal records processed: ' + recordsProcessed +
            '\nTotal records updated: ' + tobeUpdated +'Actually updated: '+recordsUpdated+'Errors: '+errors);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
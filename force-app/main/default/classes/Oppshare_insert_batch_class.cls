/*
Author             : Abhay Gupta
Company            : Patni Computer Systems
Created Date       : 10-May-2011
Description        : Apex Batch class for creation of the manual Opportunity share records for all the existing opportunities having Account.BillingCountry as "United States" or 'Canada".
                       This batch class should run nightly to process opportunity share records.
Original Case:  0079331
Updated by SFDC to optimize code:  00301477
                       
Author             : Ketan Benegal
Company            : CloudFountain Inc.
Modified Date      : 18-Apr-2012
Case No.           : 00357920
Description        : Checks to ensure that sharing rules don't exists for the userorgroupid as team member for a particular opportunity.                               

CHANGE LOG         :
  [[Version; Date; Author; Project/Case; Description]]
  v1.0; 2013/05/07; Srinivasa Rao/Randstad; Reviewing code coverage for all components/Case#01367998; Initial release.
  Description      : Added a condition to reduce execution time when it's running through batch class.
*/

global class Oppshare_insert_batch_class implements Database.Batchable<Sobject>,Database.Stateful 
    {
        public String query='';
        public string database_query='';
        integer RecordsProcessed = 0;
        integer RecordsUpdated = 0;
        global static final String objName = 'Opportunity Share';
        /***************************************************/
        Set <String> Opty_fields = new Set <String>();
        List <String> Opty_fields_list = new List <String>();
        Set <String> Account_fields = new Set <String>();
        List <String> Account_fields_list = new List <String>();
        Set <String> Postal_Code_fields = new Set <String>();
        List <String> Postal_Code_fields_list = new List <String>();
        Set<string> country = new  Set<string>();
        Map<String, String> Visibility_setting = new Map<String, String>();
        List <Country_Settings__c> country_list = Country_Settings__c.getall().values();
        List<Opportunity_Security__c> Opty = Opportunity_Security__c.getall().values();
        set <id> opty_id;
        string Opty_query_fields ='';
        string Account_query_fields ='';
        string Postal_Code_query_fields ='';
        string country_query ='';
        //Ketan Benegal - Case 00357920 - Code Start 04/18/2012 - class properties
        public Map<Id, list<OpportunityTeamMember>> oppTeamMembersMap ;
        integer errCount = 0;
        String strErrorMessages ;
        //Ketan Benegal - Code End
        //Constructor for the batch class.
        global Oppshare_insert_batch_class()
            {
                try
                {
                    
                    // Creation of string containing list of country names from custom settings.
                    for (Country_Settings__c c: country_list)
                    {
                        if(!country.contains(c.Name))
                        {
                            country.add(c.Name);
                            country_query += '\''+c.Name+'\',';
                        }                        
                    }
                    
                    // Creation of strings containing list of Coverage fields from Account,Postal Code and Opportunity from Opportunity custom settings.
                   
                    for(Opportunity_Security__c op: Opty)
                    {
                        if (op.Object_name__c=='Opportunity')
                        {
                            if(!Opty_fields.contains(op.Field_Name__c))
                            {
                                //System.debug('1111111111111 op.Field_Name__c:' + op.Field_Name__c);
                                Opty_fields.add(op.Field_Name__c);
                                Opty_query_fields += ' '+op.Field_name__c +',';
                                Visibility_setting.put(op.Field_name__c, op.Visibility_Access_Level__c);
                                Opty_fields_list.add(op.Field_Name__c);
                            }
                            //System.debug('Opty_query_fields: '+ Opty_query_fields) ;   
                        }
                    
                        if (op.Object_name__c=='Postal_Code')
                        {
                            if(!Postal_Code_fields.contains(op.Field_Name__c))
                            {    
                                Postal_Code_fields.add('Postal_Code2__r.'+op.Field_Name__c);
                                Postal_Code_query_fields += 'Postal_Code2__r.'+op.Field_name__c +',';
                                Visibility_setting.put('Postal_Code2__r.'+op.Field_name__c, op.Visibility_Access_Level__c);
                                Postal_Code_fields_list.add(op.Field_Name__c);
                            }
                        }
                        //System.debug('Postal Code query: ' + Postal_Code_query_fields);
                    
                        if (op.Object_name__c=='Account')
                        {
                            if(!Account_fields.contains(op.Field_Name__c))
                            {    
                                Account_fields.add(op.Field_Name__c);
                                Account_query_fields += ' '+op.Field_name__c +',';
                                Visibility_setting.put(op.Field_name__c, op.Visibility_Access_Level__c);
                                Account_fields_list.add(op.Field_Name__c);
                            }
                        }
                    }
                    //System.debug('Account query:'+ Account_query_fields);
                    if(Opty_query_fields!='')
                    Opty_query_fields = Opty_query_fields.substring (0,Opty_query_fields.length()-1);
                    if(country_query!='')
                    country_query = country_query.substring (0,country_query.length()-1);
                    if(Postal_Code_query_fields!='')
                    Postal_Code_query_fields = Postal_Code_query_fields.substring (0,Postal_Code_query_fields.length()-1);
                    if(Account_query_fields!='')
                    Account_query_fields = Account_query_fields.substring (0,Account_query_fields.length()-1);
                    // Creation of dynamic SOQL query for retrieving the list of Opportunity coverage fields.
                    // query = 'select Id,OwnerId,AccountId,'+ opty_query_fields +' from Opportunity where Opportunity.Account.BillingCountry IN (' +country_query +')';
                    if(Opty_query_fields!=''){ 
                      query = 'select Id,OwnerId,AccountId, Account.BillingCountry,'+ opty_query_fields +' from Opportunity where Opportunity.Account.BillingCountry IN ('+country_query +')';
                    }
                    else{
                     query = 'select Id,OwnerId,AccountId, Account.BillingCountry from Opportunity where Opportunity.Account.BillingCountry IN ('+country_query +')and  where RecordType.Name!=\'NA Renewal\'';
                    }
                    system.debug('**********' + query);
                    }
                   catch(Exception e)
                   {
                     System.debug('********' + e.getMessage());
                   }

            }
        
        //Method to get the data to be proceesed i.e the Start method.  
        global database.Querylocator start(Database.BatchableContext context)
            {
                System.debug('============== inside START method ========================');
                //If it's executed by test method, query will take 20 records. 
                if(Test.isRunningTest()){
                    query = query+' limit 20 ';
                }
                system.debug('++++++++++query in start method+++++++++'+query );
                return Database.getQueryLocator(query);                
            }//End of start method.
        
        //Method to execute the batch i.e the Execute method.
        global void execute(Database.BatchableContext context , Sobject[] scope)
            {
               System.debug('============== inside EXECUTE method ========================');
               Set<String> Account_Id = new Set<String>();
               Map<String, List<String>> acc_opty_map = new Map<String, List<String>>();
               List<OpportunityShare> Opty_share = new List<OpportunityShare>();
               List<OpportunityShare> Opty_share_insert = new List<OpportunityShare>();
               opty_id = new set <id>();
               List<String> Opty_ids = new List<string>();
               string opty_id_list = '';
               string account_id_list = '';
               Set<String> optyshare_userid = new Set<String>();
               Map<Id, User> Optyshare_activeuser = new Map<Id, User>();
               Map<String,String> opty_owner = new Map<String,String>();
               /*Ketan Benegal - Case 00357920 - Code Start 04/18/2012*/
               List<OpportunityTeamMember> lstTeamMembers;
               /*Ketan Benegal - Case 00357920 - Code End 04/18/2012 */
               RecordsProcessed = RecordsProcessed + scope.size();
               try
                   {
                        for(sObject s: scope)
                        {                           
                            Opportunity o = (Opportunity) s; 
                            //System.debug('o.Account.BillingCountry:' + o.Account.BillingCountry);
                            if(country.contains(o.Account.BillingCountry)){
                              opty_id.add(o.id);                              
                              if(!acc_opty_map.containskey(o.AccountId)){
                               
                                account_id_list += '\''+o.AccountId+'\',';
                                List<String> opty_id = new list<String>();
                                opty_id.add(o.Id);
                                acc_opty_map.put(o.AccountId,opty_id);                            
                              }
                              else{
                                //System.debug('^^^^^^^^^^^^^^^^^^^^o.id:'+ o.id +'\tAccount Id: '+ o.AccountId +'\to.Account.BillingCountry:'+ o.Account.BillingCountry);
                                List<String> opty_id = acc_opty_map.get(o.AccountId);
                                opty_id.add(o.Id);
                                acc_opty_map.put(o.AccountId,opty_id);                             
                              }
                            }                           
                        }
                    /*Ketan Benegal - Case 00357920 - Code Start 04/18/2012
                      create a map<Opp.Id, list<team members>>
                    */
                        integer iCount = 0;
                        Id prevOppId ;
                        //List<OpportunityTeamMember> lstTeamMembers;
                        oppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
                        for(OpportunityTeamMember opt : [SELECT Division, OpportunityAccessLevel, OpportunityId, Id, TeamMemberRole, UserId FROM OpportunityTeamMember where opportunityId in :opty_id order by opportunityID desc, createddate desc]){
                            //System.debug('*******iCount:'+ iCount + '\t prevOppId:'+ prevOppId);
                            if(iCount==0){
                                prevOppId = opt.OpportunityId ;
                                lstTeamMembers = new List<OpportunityTeamMember>();
                                lstTeamMembers.add(opt);
                                iCount++;
                            }else{
                                if(prevOppId == opt.OpportunityId){
                                    lstTeamMembers.add(opt);
                                }else{
                                    //System.debug('@@@@@@@@@@@@@@@@@@@prevOppId:'+ prevOppId + '\topt.OpportunityId:'+ opt.OpportunityId);
                                    oppTeamMembersMap.put(prevOppId, lstTeamMembers);
                                    prevOppId = opt.OpportunityId;
                                    //System.debug('************************lstTeamMembers size:' + lstTeamMembers.size());
                                    lstTeamMembers = new List<OpportunityTeamMember>();
                                    lstTeamMembers.add(opt);
                                }
                            }
                        }
                     /*Ketan Benegal - Case 00357920 - Code End 04/18/2012
                     GeneralUtilities.printLimits('Oppshare_insert_batch_class Execute method');*/
                     System.debug('******************oppTeamMembersMap size:'+ oppTeamMembersMap.size());
                        //System.debug('@@@@@@@@@@@@@@@ account_id_list:'+ account_id_list + '\t acc_opty_map size:'+ acc_opty_map.size());
                        for(sObject optyRecord: scope)
                        {  
                            //System.debug('Opty_fields_list.size():' + Opty_fields_list.size());
                          for(integer i=0;i<Opty_fields_list.size();i++)
                          {                             
                            OpportunityShare optyshare = new OpportunityShare();
                            optyshare.OpportunityId = string.valueof(optyrecord.get('Id'));
                            optyshare.UserOrGroupId = string.valueof(optyRecord.get(Opty_fields_list[i]));
                            if(Visibility_setting.get(Opty_fields_list[i]) =='R')
                               optyshare.OpportunityAccessLevel = 'Read';
                            if(Visibility_setting.get(Opty_fields_list[i]) =='W')
                               optyshare.OpportunityAccessLevel = 'Edit';
                            //System.debug('*************** optyshare: oppId UserID Accesslevel'+ optyshare.OpportunityId + '\t'+ optyshare.UserOrGroupId + '\t ' + optyshare.OpportunityAccessLevel);   
                            Opty_share.add(optyshare);
                            opty_owner.put(string.valueof(optyrecord.get('Id')),string.valueof(optyrecord.get('OwnerId')));
                          }
                        }
                        List<sObject> List_Account = new list<sObject>() ;
                        if(account_id_list != '')
                           account_id_list = account_id_list.substring (0,account_id_list.length()-1);
                       
                        // Creation of dynamic SOQL query for retrieving the list of Account and Postal code coverage fields.
                        if(account_id_list != ''){
                            if(postal_code_query_fields!=''){
                              database_query = 'select Id,Postal_Code2__c,'+account_query_fields +','+postal_code_query_fields +' from Account where ID IN (' +account_id_list +')';
                            }
                            else{
                             database_query = 'select Id,Postal_Code2__c,'+account_query_fields  +' from Account where ID IN (' +account_id_list +')';
                            }
                            
                            List_Account = Database.query(database_query);
                        }
                        
                        if(!List_Account.isEmpty()){
                            for(SObject acctRecord : List_Account){
                               for(integer i=0;i<Account_fields_list.size();i++){
                                   for( string optyid: acc_opty_map.get(string.valueof(acctrecord.get('Id')))){
                                      OpportunityShare optyshare = new OpportunityShare();
                                      optyshare.OpportunityId = optyid;
                                      optyshare.UserOrGroupId = string.valueof(acctRecord.get(Account_fields_list[i]));
                                      if(Visibility_setting.get(Account_fields_list[i]) =='R')
                                        optyshare.OpportunityAccessLevel = 'Read';
                                      if(Visibility_setting.get(Account_fields_list[i]) =='W')
                                        optyshare.OpportunityAccessLevel = 'Edit';
                                 //System.debug('@@@@@@@@@@@@@ optyshare: oppId UserID Accesslevel'+ optyshare.OpportunityId + '\t'+ optyshare.UserOrGroupId + '\t ' + optyshare.OpportunityAccessLevel);   
                                      Opty_share.add(optyshare);
                                    }
                                }
    
                                for(integer i=0;i<Postal_Code_fields_list.size();i++){
                                    SObject postal_code = acctRecord.getSObject('Postal_Code2__r');
                                    if(acctrecord.get('Postal_Code2__c') != Null)
                                    {
                                        for( string optyid: acc_opty_map.get(string.valueof(acctrecord.get('Id'))))
                                        {
                                            OpportunityShare optyshare = new OpportunityShare();
                                            optyshare.OpportunityId = optyid;
                                            optyshare.UserOrGroupId = string.valueof(postal_code.get(Postal_Code_fields_list[i]));
                                            if(Visibility_setting.get('Postal_Code2__r.'+Postal_Code_fields_list[i]) =='R')
                                                optyshare.OpportunityAccessLevel = 'Read';
                                            if(Visibility_setting.get('Postal_Code2__r.'+Postal_Code_fields_list[i]) =='W')
                                                optyshare.OpportunityAccessLevel = 'Edit';
                                            
                                            Opty_share.add(optyshare);
                                        }
                                    }
                                 }
                             }                       
                        }  
                         
                        for(OpportunityShare opshare: opty_share)
                        {
                            optyshare_userid.add(opshare.userorgroupid);
                        }
                        for(User u: [select Id, isactive from user where Id in: optyshare_userid and isactive = true])
                        {
                            optyshare_activeuser.put(u.Id, u);
                        }
                        /*Ketan Benegal - if canInsert true then opportunityshare record inserted.
                        
                        */
                        boolean canInsert = false;
                        for(OpportunityShare opshare: opty_share)
                        {
                            canInsert = true;
                            if(optyshare_activeuser.containskey(opshare.userorgroupid)&& opty_owner.get(opshare.OpportunityId) != opshare.userorgroupid){
                                /*Ketan Benegal - Case 00357920 - Code Start */
                                /*- Check if opportunity has a list of teammembers.
                                  for each opshare.User check if a team member entry exists, if exists, 
                                  check if the opshare accesslevel is not read then canInsert will be true.
                                  If canInsert is true, select the record for upsert.
                                */
                                if(!oppTeamMembersMap.isEmpty()){
                                if(oppTeamMembersMap.containskey(opshare.OpportunityId)){
                                //System.debug('*************opshare.opportunityid:' + opshare.OpportunityId);
                                    lstTeamMembers = oppTeamMembersMap.get(opshare.OpportunityId);
                                    if(!lstTeamMembers.isEmpty()){
                                    for(OpportunityTeamMember teamMember : lstTeamMembers){
                                        if(opshare.UserOrGroupId == teamMember.UserId){
                                            //System.debug('22222222222 opshare.OpportunityAccessLevel:'+ opshare.OpportunityAccessLevel);
                                            if(opshare.OpportunityAccessLevel != 'Read'){
                                                System.debug('************READ ACCESS**********');
                                                canInsert = true;
                                             }
                                            else{
                                                System.debug('**********************WRITE ACCESS*********'); 
                                                canInsert = false;
                                            }
                                        }
                                    }
                                    }
                                }
                                }
                                if(canInsert)
                                /*Ketan Benegal - Case 00357920 - Code End */
                                  opty_share_insert.add(opshare);
                            }
                        }
                        
                        /*Ketan Benegal - Case 00357920 - Code Start */
                        // Recreate the Opp sharing records for all in-scope Opportunity records in the batch.
                        //Code commented out by Ketan. Replaced with Database.Insert method to allow partial inserts.                    
                        //insert Opty_share_insert;
                        Database.Saveresult[] lsr =  Database.insert(opty_share_insert, false);
                        //Iterate through saveResults to check for errors.
                        for(Database.Saveresult sr1 : lsr){
                            if(!sr1.isSuccess()){
                              Database.Error err = sr1.getErrors()[0];
                              //strErrorMessages = strErrorMessages + err.getMessage() + '\n';
                              errCount++;
                            }
                        }
                        /*Ketan Benegal - Case 00357920 - Code End */
                        
                        RecordsUpdated = RecordsUpdated + Opty_share_insert.size();                        
                   }
                  
               catch(Exception e)
                   {
                       system.debug('********' + e.getMessage());
                   }
            } //End of execute method.            
                        
         //Method to be called after the execution i.e the Finish method.
         global void finish(Database.BatchableContext BC)
            {
                System.debug('============== inside FINISH method ========================');
                AsyncApexJob job = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                                    from AsyncApexJob where Id = :BC.getJobId()];        
                // Send an email to the Apex job's submitter notifying of job completion.
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {job.CreatedBy.Email};
                mail.setToAddresses(toAddresses);
                mail.setSubject(objName + ' Insert Apex Batch Job: ' + job.Status);
                mail.setPlainTextBody('Dear ' + job.CreatedBy.Firstname + ', ' +
                '\n\nThe batch Apex job processed ' + job.TotalJobItems + ' batches with '+ job.NumberOfErrors + ' failures.'+
                '\n\nTotal Opportunity processed: ' + recordsProcessed +
                '\nTotal Oppshare records inserted: ' + recordsUpdated +
                //Ketan Benegal - Case 00357920 - total records with errors.
                '\nTotal Errors in OppShare records insert:' + errCount);
                //'\n Errors:' + strErrorMessages);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }// End of finish method.
        
         
  }// End of batch class.
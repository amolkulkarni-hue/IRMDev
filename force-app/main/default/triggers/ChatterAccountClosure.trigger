/*
Developed By: Kavya Somashekar
Date: 9/9/2014
Purpose: To notify the TGM via Chatter whenever a new account closure case has been created.

* Modified By: Vinutha Iyengar on 25-Nov-2015 
*           --To stop trigger being fired from Email Archive batch job

* Modified By: Vinutha Iyengar on 08-Aug-2019 
*           --Case No 10886923, Account Retention remediation

*/
trigger ChatterAccountClosure on Case(after insert, after update) 
{
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
    Boolean IsEmailArchiveBatchJob=false;
    if(system.isBatch()==true)
    {
        if(Validator_cls.isArchiveBatchJobDone())
        {
            IsEmailArchiveBatchJob=Validator_cls.isArchiveJobExecuting();
        }
        else
        {
            List<String> classIds = Label.Email_Archive_Class.split(';');
            List<AsyncapexJob> emailArchiveJob=[SELECT Id FROM AsyncapexJob WHERE ApexClassID in :classIds and Status = 'Processing'];
            if(!emailArchiveJob.isEmpty())            
            {
                Validator_cls.setArchiveJobExecuting();
                IsEmailArchiveBatchJob=true;
            }
            Validator_cls.setArchiveBatchJobDone();
        }
    }
    system.debug(LoggingLevel.INFO,'ChatterAccountClosure - emailArchiveBatchJob value is  =='+IsEmailArchiveBatchJob); 
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
    
    if(!IsEmailArchiveBatchJob)
    {
        Map<String, String> CustIdMap = new Map<String, String>();
        Map<String, Id> UserId = new Map<String, id>();
        List<String> strCusAccntLst = new List<String>();
        List<String> strUsrLst = new List<String>();
        List<IM_Customer_Account__c> CustAccList = new List<IM_Customer_Account__c>();
        List<User> UsrList = new List<User>();
        Map<String, String> mapCaseRT = new Map<String, String>();
        
        ID recTypeDpClosure = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CAC_DP_Closure').getRecordTypeId();        
        ID  recTypeSkpRm = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CAC_SKP_RM').getRecordTypeId();         
        ID  recTypeSkpShred = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CAC_SKP_Shred').getRecordTypeId(); 
        
        for(Case cas : Trigger.new)
        {
            strCusAccntLst.add(cas.Customer_ID__c);
            strUsrLst.add(cas.Territory_GM__c);
            mapCaseRT.put(cas.RecordTypeId,cas.RecordTypeId);
        }
        
        system.debug('mapCaseRT.con-------'+mapCaseRT.containsKey(recTypeDpClosure));
        if(mapCaseRT.containsKey(recTypeDpClosure)|| mapCaseRT.containsKey(recTypeSkpRm)|| mapCaseRT.containsKey(recTypeSkpShred))
        {
            CustAccList = [Select id, name from IM_Customer_Account__c where id IN: strCusAccntLst];
            UsrList = [Select id, name from User where name IN: strUsrLst];
        }
        
        if(!CustAccList.isEmpty())
        {
            for(IM_Customer_Account__c rt :CustAccList)
            {
                CustIdMap.put(rt.Id, rt.Name);
            }
        }
        if(!UsrList.isEmpty())
        {
            for(User rt :UsrList)
            {
                UserId.put(rt.Name,rt.Id);
            }
        }
        
        if(trigger.isInsert && trigger.isAfter)
        {   
            system.debug('entering isAfter');  
            for(Case cas : Trigger.new)
            {
                system.debug('entering for loop');
                system.debug('Trigger.new----'+Trigger.new);
                if(cas.recordTypeID == recTypeDpClosure || cas.recordTypeID == recTypeSkpRm || cas.recordTypeID == recTypeSkpShred)
                {                           
                    system.debug('entering first if loop');
                    system.debug('cas.Date_Closure_CSA_Assigned__c--------'+cas.Date_Closure_CSA_Assigned__c);
                    if(cas.Territory_GM__c != NULL && cas.Date_Closure_CSA_Assigned__c != NULL)
                    {
                        system.debug('entering second if');
                        system.debug('cas.Territory_GM__c-----'+cas.Territory_GM__c);
                        system.debug('cas.Account-----'+cas.Account);
                        if(cas.Closure_Reason__c == '1a - Price - Uncompetitive Pricing - RM'
                           || cas.Closure_Reason__c == '1b - Price - Uncompetitive Pricing - Shred'
                           || cas.Closure_Reason__c == '1c - Price - Uncompetitive Pricing - DM'   
                           || cas.Closure_Reason__c == '1d - Price - Unhappy with Price Increase - RM'
                           || cas.Closure_Reason__c == '1e - Price - Unhappy with Price Increase - Shred'
                           || cas.Closure_Reason__c == '1f - Price - Unhappy with Price Increase - DM'   
                           || cas.Closure_Reason__c == '2a - Program Change - Customer already retrieved inventory - RM'
                           || cas.Closure_Reason__c == '2b - Program Change - Customer already had shred bins removed - Shred'
                           || cas.Closure_Reason__c == '2c - Program Change - Customer already retrieved inventory - DM'   
                           || cas.Closure_Reason__c == '2k - Program Change - Account moved out of service area' 
                           || cas.Closure_Reason__c == '3a - Service Quality - Logistical Service Issues - Shred' 
                           || cas.Closure_Reason__c == '3b - Service Quality - IM Non-responsive to / unable to resolve repeated customer service issues' 
                           || cas.Closure_Reason__c == '3c - Service Quality - IM Non-responsive to / unable to resolve repeated billing issues' 
                           || cas.Closure_Reason__c == '3d - Service Quality - IM Non-responsive to / unable to resolve repeated market service issues' 
                           || cas.Closure_Reason__c == '5c - Relationship - Local competitor influenced decision' 
                           || cas.Closure_Reason__c == '5d - Relationship - Decision Maker change' 
                           || cas.Closure_Reason__c == '5e - Relationship - Contractual Concerns' )
                        {
                            String idString =  SendChatterPostUtil.sendChatterPost(UserId,CustIdMap,cas.id,
                                                                                   cas.Territory_GM__c,cas.Customer_ID__c,
                                                                                   cas.Customer_Name__c,cas.Market_Name__c,
                                                                                   cas.OwnerId);
                            System.debug('idString='+idString);  
                        }
                    }
                    
                }
            }
        }
        else if(trigger.isUpdate && trigger.isAfter)
        {
            
            system.debug('entering isAfter1');  
            for(Case cas : Trigger.new)
            {
                system.debug('trigger.new---'+trigger.new);
                
                if (cas.Territory_GM__c != Trigger.oldMap.get(cas.Id).Territory_GM__c 
                    || cas.Customer_ID__c != Trigger.oldMap.get(cas.Id).Customer_ID__c
                    || cas.Customer_Name__c != Trigger.oldMap.get(cas.Id).Customer_Name__c
                    || cas.Market_Name__c != Trigger.oldMap.get(cas.Id).Market_Name__c
                    || cas.OwnerId != Trigger.oldMap.get(cas.Id).OwnerId
                    || cas.Date_Closure_CSA_Assigned__c != Trigger.oldMap.get(cas.Id).Date_Closure_CSA_Assigned__c
                    || cas.Closure_Reason__c != Trigger.oldMap.get(cas.Id).Closure_Reason__c)
                { 
                    system.debug('entering for loop1');
                    system.debug('Trigger.new1----'+Trigger.new);
                    
                    if(cas.recordTypeID == recTypeDpClosure || cas.recordTypeID == recTypeSkpRm || cas.recordTypeID == recTypeSkpShred)
                    {
                        system.debug('entering first if loop1');
                        if(cas.Date_Closure_CSA_Assigned__c != NULL)
                        {
                            system.debug('entering second if1');
                            system.debug('cas.Territory_GM__c1-----'+cas.Territory_GM__c);
                            system.debug('cas.Account1-----'+cas.Account);
                            if(cas.Closure_Reason__c == '1a - Price - Uncompetitive Pricing - RM'
                               || cas.Closure_Reason__c == '1b - Price - Uncompetitive Pricing - Shred'
                               || cas.Closure_Reason__c == '1c - Price - Uncompetitive Pricing - DM'   
                               || cas.Closure_Reason__c == '1d - Price - Unhappy with Price Increase - RM'
                               || cas.Closure_Reason__c == '1e - Price - Unhappy with Price Increase - Shred'
                               || cas.Closure_Reason__c == '1f - Price - Unhappy with Price Increase - DM'   
                               || cas.Closure_Reason__c == '2a - Program Change - Customer already retrieved inventory - RM'
                               || cas.Closure_Reason__c == '2b - Program Change - Customer already had shred bins removed - Shred'
                               || cas.Closure_Reason__c == '2c - Program Change - Customer already retrieved inventory - DM'   
                               || cas.Closure_Reason__c == '2k - Program Change - Account moved out of service area' 
                               || cas.Closure_Reason__c == '3a - Service Quality - Logistical Service Issues - Shred' 
                               || cas.Closure_Reason__c == '3b - Service Quality - IM Non-responsive to / unable to resolve repeated customer service issues' 
                               || cas.Closure_Reason__c == '3c - Service Quality - IM Non-responsive to / unable to resolve repeated billing issues' 
                               || cas.Closure_Reason__c == '3d - Service Quality - IM Non-responsive to / unable to resolve repeated market service issues' 
                               || cas.Closure_Reason__c == '5c - Relationship - Local competitor influenced decision' 
                               || cas.Closure_Reason__c == '5d - Relationship - Decision Maker change' 
                               || cas.Closure_Reason__c == '5e - Relationship - Contractual Concerns' )
                            {
                                system.debug('entering third if loop1');
                                
                                String idString1 = SendChatterPostUtil.sendChatterPost(UserId,CustIdMap,cas.id,
                                                                                       cas.Territory_GM__c,cas.Customer_ID__c,
                                                                                       cas.Customer_Name__c,cas.Market_Name__c,
                                                                                       cas.OwnerId);
                                System.debug('idString1='+idString1); 
                            }   
                        }
                    }
                    
                }
            }
        }
    }
}
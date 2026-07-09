/**  
       * Name: IRM_SC_fetchUpdateQueue
       * Description: Fetches the queue name and updates the Queue field on the Case page layout.
       * Copyright: HCL Technologies
       * Author: Himanshu Jain
       * Modification Log: Created:2-Mar-2012
                           Modified : 10-Mar-2012 
**/

public class IRM_SC_fetchUpdateQueue {

private static boolean alreadyUpdatedCase = false;
   
    public void UpdateQueueName(Case[] Objcase, Map<ID, Case> oldCaseMap, Boolean updateValue)
    {
        string Country;
        for(Case queryCase : Objcase)
        {
            //manual case creation if country is Norway and Ireland updating reporting queue name
            if((String.valueOf(queryCase.OwnerId).startsWith('005'))&& queryCase.IME_SC_Queue_name__c == null)
            {
                for (IME_SC_Country_Queues__c countryQueue : IME_SC_Country_Queues__c.getAll().values()){
                    if(queryCase.IME_SC_Country__c == 'Ireland')
                    {
                        Country = 'United Kingdom';
                    }
                    else if(queryCase.IME_SC_Country__c == 'Lithuania' || queryCase.IME_SC_Country__c == 'Latvia' ||queryCase.IME_SC_Country__c == 'Estonia')
                    {
                        Country = 'Baltics';
                    }
                    else
                    {
                        Country = queryCase.IME_SC_Country__c;
                    }
                    if(countryQueue.Country__c == Country && countryQueue.Queue_Type__c=='INDEX' )
                    {
                        queryCase.IME_SC_Queue_name__c = countryQueue.name;                           
                    }
                }
            }
        }
        if(updateValue)
        {
            List<Id> listCaseID = new List<Id>();
            List<Case> oldCaseList = new List<Case>();
            Set<Id> listCaseOwnerID= new Set<Id>();
            Map<id, Group> caseGroup;
            for (Case caseRec :Objcase)
            {
                Case oldCase;
                
                if(oldCaseMap != null && !oldCaseMap.isEmpty())
                    oldCase = oldCaseMap.get(caseRec.id);
                    
                if(oldCase != null && oldCase.ownerID != caseRec.ownerID && String.valueof(oldCase.ownerID).startsWith('00G'))
                    listCaseOwnerID.add(oldCase.ownerID);
            }
            if(listCaseOwnerID != null && !listCaseOwnerID.isEmpty())
            {
                caseGroup = new Map<id, Group>([select id, name from Group where id in :listCaseOwnerID]);
            }
            for (Case caseRec :Objcase)
            {
               //updating reporting queue name if owner is queue at the time of case updation
               if(oldCaseMap != null && !oldCaseMap.isEmpty() && String.valueof(oldCaseMap.get(caseRec.id).ownerID).startsWith('00G'))
                   if(caseGroup!= null && !caseGroup.isEmpty() && caseGroup.containsKey(oldCaseMap.get(caseRec.id).ownerID) && caseGroup.get(oldCaseMap.get(caseRec.id).ownerID)!= null)
                        caseRec.IME_SC_Queue_name__c = caseGroup.get(oldCaseMap.get(caseRec.id).ownerID).name;
            }
            for(Case queryCase : Objcase)
            {
                //updating reporting queue name if owner is user at the time of case updation
                if((String.valueOf(queryCase.OwnerId).startsWith('005'))&& queryCase.IME_SC_Queue_name__c == null) 
                {
                    for (IME_SC_Country_Queues__c countryQueue : IME_SC_Country_Queues__c.getAll().values())
                    {
                        if(countryQueue.Country__c == queryCase.IME_SC_Country__c && countryQueue.Queue_Type__c=='INDEX' )
                        {
                            queryCase.IME_SC_Queue_name__c = countryQueue.name;                           
                        }
                    }
                }
            } 
        }   
    }  
}
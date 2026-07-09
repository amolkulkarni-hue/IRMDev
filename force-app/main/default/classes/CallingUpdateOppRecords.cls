/**
    Developer Name : Madhu Paladugu
    Company Name   : CloudFountain Inc.
    Description    : This Class will do update on Opportunity Object that are intiated from Case Object Trigger(to reduce SOQL we have added this class).
    Date           : 12/18/2012 
    Case Number    : 00593195

**/

public Class CallingUpdateOppRecords{

@future
public static void doUpdate(List<Id> OppId,List<String> NCSP_Status,List<String> StageName,List<Date> Service_Completed_Entered_Date,List<String> IM_Reason_Lost){
    //Commented out Portion of Query
    //Case # :01428416
    //Date   :05/22/2013
    List<Opportunity> oppToUpdate=[select Id,NCSP_Status__c,StageName,Service_Completed_Entered_Date__c,IM_Reason_Lost__c from Opportunity where Id IN:OppId /*for update */]; 
    for(Integer i=0;i<oppToUpdate.size();i++){
        for(Integer j=0;j<OppId.size();j++){
                if(oppToUpdate[i].Id==OppId.get(j)){
                    if(NCSP_Status.get(j)!=null)
                    oppToUpdate[i].NCSP_Status__c=NCSP_Status.get(j);
                    if(StageName.get(j)!=null)
                    oppToUpdate[i].StageName=StageName.get(j);
                    if(Service_Completed_Entered_Date.get(j)!=null)
                    oppToUpdate[i].Service_Completed_Entered_Date__c=Service_Completed_Entered_Date.get(j);
                    if(IM_Reason_Lost.get(j)!=null)
                    oppToUpdate[i].IM_Reason_Lost__c=IM_Reason_Lost.get(j);
                    break;
            }
        }
    }
   
    try{
    	 update oppToUpdate;
    }
    catch(DmlException e){
    	//if(e.getMessage().contains('UNABLE_TO_LOCK_ROW')){
    		system.debug('+++++++do nothing++++');
    	//}
    }
}
/* Developer Name: Madhu Paladugu
   Case Number   : 01045376
   Discription   : Removed using this @future method calling to update Opportunities from CaseObject trigger.
@future
public static void doUpdateOfDates(List<Id> OppId,List<DateTime> Service_Schedule_Date){
    List<Opportunity> OppToUpdatewithDates=[select Id,Service_Schedule_Date__c from Opportunity where Id IN:OppId];
    for(Integer i=0;i<OppToUpdatewithDates.size();i++){
    for(Integer j=0;j<OppId.size();j++){
                if(OppToUpdatewithDates[i].Id==OppId.get(j)){
                   if(Service_Schedule_Date.get(j)!=null)
                    OppToUpdatewithDates[i].Service_Schedule_Date__c =Service_Schedule_Date.get(j);
                    break;
            }
        }
    }
    update OppToUpdatewithDates;
}
*/
}
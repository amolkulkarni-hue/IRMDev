/**  
* Class: CaseRecordtypeupdate
* Author: 
* Purpose: To update the Case Recordtype and Close the Transcript cases 
* Requirement:  
* 
Change History:
             
* Modification: Gitlab- #9914 Added these 2 profiles IMLA_SC_Representative and IMLA_SC_Manager to update the case IME SC Case recordtype for the Chat transcript cases.
* Modification Date: 22-08-2022
* Modified By: Avanthi Gadamsetty
* -------------------------------------------------------------------------------------------
* 
*/





public class CaseRecordtypeupdate {
   @InvocableMethod
   public static void NASrecordtypeupdate(List<Id> sid) {
     system.debug('CaseID'+sid);
     List<Case> lc = new List<Case>();
     map<id,case> casemap = new map<id,case>();
     List<LiveChatTranscript> livechattrasncriptlist = [Select Id,CaseId,Ownerid from LiveChatTranscript where CaseId=:sid];
     List<Case> caselist = [Select Id,Recordtypeid,RecordType.Name,End_Time_Cutoff_SLA__c,Status,ownerid from case where Id=:sid];
    
     Id profileId=userinfo.getProfileId();
     String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
     system.debug('ProfileName'+profileName);
     
     Id nasrectypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NAS General Support Case').getRecordTypeId();
     Id imescrectypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IME SC Case').getRecordTypeId();
     
     for(Case cc:caselist){
     
     if(cc.Status!='Closed'){
         if(cc.RecordType.Name == 'NAS Community Support case' &&(profileName == 'NAS Support Agent' || profileName =='NAS Support Manager')){
             System.debug('NAS');
             cc.Recordtypeid = nasrectypeid;
             System.debug('Test###');
             lc.add(cc);
         }
         if(cc.RecordType.Name == 'NAS Community Support case' &&(profileName== 'IM_Custom Sys Admin' || profileName == 'IME_SC_Representative' || profileName =='IME_SC_Manager' || profileName =='IMLA_SC_Manager' || profileName =='IMLA_SC_Representative' )){
             System.debug('IME');
             cc.Recordtypeid = imescrectypeid;
             //cc.End_Time_Cutoff_SLA__c = System.now().addminutes(15);
             cc.IME_SC_Cut_Off_Time__c='';
             lc.add(cc);
         }
       }
       
       if(cc.Status =='Closed'){
           
           for(LiveChatTranscript lct:livechattrasncriptlist){
               cc.ownerid =lct.ownerId;
               lc.add(cc);
           }
           
       }
           
       casemap.putAll(lc);    
     }
     if(casemap.size()>0 && !Test.isRunningTest()) update casemap.values();
   }
    
}
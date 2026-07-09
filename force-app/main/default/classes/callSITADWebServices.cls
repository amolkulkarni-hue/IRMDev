/******************************************************************************************************************************************
 * Class: callSITADWebServices
 * 
 * Change History:     11/07/2023
 * Developer           Date                Description
 * ------------------------------------------------------------------------------------------- 
 * Removed the fields (CDM_Global_Ultimate_ID__c,CDM_Global_Ultimate_Name__c) dependency as part of #16051
 * Renuka Prasad       11/07/2023          Story #19589 - Changes to pass Billing Account Legal Entity for Country field for SMS Case Sync
 ******************************************************************************************************************************************/
global class callSITADWebServices{
@Future(callout=true)
public static void callSITADUpdate(List<Id> casIds){
List<Case> CasList = [SELECT Customer_ID__c,QTB_SITAD_Integration_Flag__c, SMS_Order_Sync_Date__c, Customer_ID__r.name, Customer_ID__r.SITAD_Flag__c, Owner.Name, Owner.Phone, Owner.Email,SITAD_Disposition_Type__c, IM_Market__c, Owner.id, Market_Name__c, Service_Order_Date__c,Service_Schedule_Date__c, Service_Completion_Date__c, CaseNumber, Customer_Name__c, Account.Id,Account.Name,Address__c,City__c,  State__c, Zip__c, Country__c, Case_Contact_Name__c, Contact.Phone, Contact.Email,Bill_To_Site_Number__c, Account.QTB_Legal_Entity_Country__c FROM Case WHERE id in:casIds];
    Map<id,Case> CAFlagMap = new Map<id,case>();
    for(case ca : CasList){
        CAFlagMap.put(ca.id,ca);
    }
    for(case ca : CasList){
        if(CAFlagMap.get(ca.id).QTB_SITAD_Integration_Flag__c){ // Replaced Customer_ID__r.SITAD_Flag__c with QTB_SITAD_Integration_Flag__c as per #20941
            //SITADIntegration.callTriggerToSMSSync(CAFlagMap.get(ca.id));
        }
   }

}
}
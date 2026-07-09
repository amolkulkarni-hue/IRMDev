/********************************************************************************************************
* @Description: This Apex Class is created to calculate Auto-Follow Up Dates for Global Service Case Record Type when an email is sent to a customer by selecting "Does this Case require more Information?" as Yes.
		It is getting used in Flow "Auto Follow Up Email For Case" API Name: "Auto_Follow_Up_Email_For_Case"
		It is calculating Auto-Follow Up Dates by factoring the Holidays/Weekends/Business Hours for the specific countries and updating the fields on the EmailMessage record.
		Also we are using Metadata "GSC_Case_Country_Closure_Email__mdt" to fetch the BusinessHours Id for the specific country for the calculations.
* @Copyright: Iron Mountain
* @Author: Simranjit Kaur
* @Created on:  04/19/2024(MM/DD/YYYY)
* @TestClass Name: GSCUpdateAutoFollowUpDatesTest
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 04/19/2024 - Simranjit Kaur - Initial Development - GitLab #22253
* ===================================================
*
********************************************************************************************************/
global class GSCUpdateAutoFollowUpDates {
	 global class DataWrapper {
        @InvocableVariable(label='Country' required=true)
        public String country;
        @InvocableVariable(label='Email Message Record Id' required=true)
        public id recordId;
        }  
    @invocableMethod(label='Calculate Auto Follow Up Dates')
    public static void calculateAutoFollowUpDates(List<DataWrapper> passedData)
    {
        for (DataWrapper dw: passedData) {
            BusinessHours[] bh;
            //Get the Metadata Details to fetch the Business Hours details
            GSC_Case_Country_Closure_Email__mdt[] metadataDetails = [Select Business_Hours_Id__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__c =:dw.country and Default__c =:true  LIMIT 1];
			//Check if the metadata has any records returned and Business Hours field is not null
            if(metadataDetails.size()>0 && String.isNotBlank(metadataDetails[0].Business_Hours_Id__c)){
                bh = [SELECT Id FROM BusinessHours WHERE Id =:metadataDetails[0].Business_Hours_Id__c LIMIT 1];
                if(bh.size()==0)
				{
                    bh = [SELECT Id FROM BusinessHours WHERE IsDefault =:true]; 
				}
            }
            else{
                bh = [SELECT Id FROM BusinessHours WHERE IsDefault =:true]; 
            }  
            //Fetch the Email Message details to update the Follow up Date
			EmailMessage[] emailMessageDetail = [SELECT id,Auto_Follow_up_Date_24_Hours__c,Auto_Follow_up_Date_48_Hours__c,Auto_Follow_up_Date_72_Hours__c FROM EmailMessage WHERE id =: dw.recordId limit 1];        
            //Calculate the Auto Follow Up Dates
            if(emailMessageDetail.size()>0){
                emailMessageDetail[0].Auto_Follow_up_Date_24_Hours__c = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh[0].id, 1);
                emailMessageDetail[0].Auto_Follow_up_Date_48_Hours__c = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh[0].id, 2);
                emailMessageDetail[0].Auto_Follow_up_Date_72_Hours__c = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh[0].id, 3);          
                //Updating the Email Message after setting Follow Up Dates
                List<Database.saveResult> emailMessageUpdatedResult = Database.Update(emailMessageDetail);
            }    
        }
    }
}
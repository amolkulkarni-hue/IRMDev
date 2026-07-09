/********************************************************************************************************
* @Description: This Apex Class is created to calculate Follow Up Dates for Global Service Case Record Type when the Pending Reason is updated.
		It is getting used in Flow "GSC Case - After Update Flow" API Name: "GSC_Case_After_Update_Flow"
		It is calculating Follow Up Dates by factoring the Holidays/Weekends/Business Hours for the specific countries.
		Also we are using Metadata "GSC_Case_Country_Closure_Email__mdt" to store the number of business days needs to be added to the current date to populate the follow date.
* @Copyright: Iron Mountain
* @Author: Simranjit Kaur
* @Created on:  04/19/2024(MM/DD/YYYY)
* @TestClass Name: GSCFollowUpDateTest
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 04/19/2024 - Simranjit Kaur - Initial Development - GitLab #22253
* ===================================================
*
********************************************************************************************************/
global class GSCFollowUpDate {
    global class DataWrapper {
        @InvocableVariable(label='Country' required=true)
        public String country;
        @InvocableVariable(label='Pending Reason' required=true)
        public String pendingReason;
        @InvocableVariable(label='Case Record Id' required=true)
        public id recordId;
        }  
    @invocableMethod(label='Calculate Follow Up Date')
    public static void calculateFollowUpDate(List<DataWrapper> passedData)
    {
        for (DataWrapper dw: passedData) {
            BusinessHours[] bh;
            //Get the Metadata Details to fetch the Business Hours details
            GSC_Case_Country_Closure_Email__mdt[] metadataDetails = [Select Business_Hours_Id__c,Customer_Response_Follow_up_Days__c,Internal_Response_Follow_up_Days__c,Supervisor_Follow_up_Days__c from GSC_Case_Country_Closure_Email__mdt where GSC_Country__c =:dw.country and Default__c =:true  LIMIT 1];
			//Check if the metadata has any records returned and Business Hours field is not null
            if(metadataDetails.size()>0 && String.isNotBlank(metadataDetails[0].Business_Hours_Id__c)){
                bh = [SELECT Id FROM BusinessHours WHERE Id =:metadataDetails[0].Business_Hours_Id__c];
                if(bh.size()==0)
				{
                    bh = [SELECT Id FROM BusinessHours WHERE IsDefault =:true]; 
				}
            }
            else{
                bh = [SELECT Id FROM BusinessHours WHERE IsDefault =:true]; 
            }  
            //Fetch the Case details to update the Follow up Date
			List<Case> caseDetail = [SELECT id,Follow_up_Date__c FROM Case WHERE id =: dw.recordId limit 1];      
			//Checking the Pending Reason and calling the method to calculate Follow up Date
            if(dw.pendingReason=='Internal Response')
			{  
                if(Integer.valueOf(metadataDetails[0].Internal_Response_Follow_up_Days__c)<>0 && Integer.valueOf(metadataDetails[0].Internal_Response_Follow_up_Days__c)<>null)
                {  
					caseDetail[0].Follow_up_Date__c = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh[0].id,Integer.valueOf(metadataDetails[0].Internal_Response_Follow_up_Days__c));
                    
                }
                else
                {
                	caseDetail[0].Follow_up_Date__c = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh[0].id,1);
                }
            }
            else if(dw.pendingReason=='Customer Response')
            {
                if(Integer.valueOf(metadataDetails[0].Customer_Response_Follow_up_Days__c)<>0 && Integer.valueOf(metadataDetails[0].Customer_Response_Follow_up_Days__c)<>null)
                {  
                	caseDetail[0].Follow_up_Date__c = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh[0].id,Integer.valueOf(metadataDetails[0].Customer_Response_Follow_up_Days__c));
                }
                else
                {	
                   caseDetail[0].Follow_up_Date__c = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh[0].id,3);
                }
            }
			else if(dw.pendingReason=='Supervisor')
            {	
                if(Integer.valueOf(metadataDetails[0].Supervisor_Follow_up_Days__c)<>0 && Integer.valueOf(metadataDetails[0].Supervisor_Follow_up_Days__c)<>null)
                {  
					caseDetail[0].Follow_up_Date__c = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh[0].id,Integer.valueOf(metadataDetails[0].Supervisor_Follow_up_Days__c));
                }
                else
                {
                	caseDetail[0].Follow_up_Date__c = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh[0].id,1);    
                }
            }
            //Updating the Cases after setting Follow Up Date
            try {
                List<Database.saveResult> caseUpdatedResult = Database.Update(caseDetail);
            } 
            catch (Exception e) {
				List<Exception_log__C> exceptionList = new List<Exception_log__C>();
                Exception_log__C newException = new Exception_log__C(Class_Reference__C = 'GSCFollowUpDate', Error_Message__C = 'Unable to update Follow Up Date on Case Record', Exception_Type__C ='DML', Name = 'Case Update Error', Originating_Org__C ='Core', Record_id__C= dw.recordID , Stack_Trace__c ='Global service Case - Update Case Record - error Occurred');
                exceptionList.add(newException);
                List<Database.saveResult> exceptionInsertedResult = Database.Insert(exceptionList);
             } 
        }    
    }
}
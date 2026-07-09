/********************************************************************************************************
@Description: This Apex Class is created to calculate the Business Case age in Business Hours.
@Copyright: Iron Mountain
@Author:  Mastan Shaik
@Created on:  4/24/2024(MM/DD/YYYY)
@TestClass Name: GSCBusinessCaseAge
*
Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
4/24/2024 - Mastan Shaik - Initial Development - GitLab #23309
===================================================
*
********************************************************************************************************/
global class GSCBusinessCaseAge {
    global class DataWrapper {
        @InvocableVariable(label='Case Created Date' required=true)
        public Datetime createdDate;
        @InvocableVariable(label='Case Closed Date' required=true)
        public Datetime closedDate;
        @InvocableVariable(label='Country' required=true)
        public String country;
        @InvocableVariable(label='Case Record Id' required=true)
        public Id recordId;
        }  
    
    @InvocableMethod(label='Calculate Business Case Age')
    public static void calculateBusinessCaseAge(List<DataWrapper> passedData) {
        system.debug('@@DataWrapper-='+passedData);
        List<Case> casesToUpdate = new List<Case>();
        
        for (DataWrapper dw: passedData) {
             if (dw.createdDate != null && dw.closedDate != null) {
                // Get business hours based on the country
                BusinessHours bh = getBusinessHours(dw.country);
                system.debug('@@bh-='+bh);
                if (bh != null) {
                    // Calculate the age in business hours
                    Long diff = BusinessHours.diff(bh.Id, dw.createdDate, dw.closedDate);
                    Integer elapsedHours = GSCCalculateDateBasedOnBusinessHours.calculateElapsedHours(bh.Id);
                    Double days = (Double) diff / (1000 * 60 * 60 * elapsedHours);
                    system.debug('@@days-='+days);
                    casesToUpdate.add(new Case(Id = dw.recordId, Business_Case_Age__c = days));
				}
            } else {
                // Case is open or dates are missing; set age to null
                casesToUpdate.add(new Case(Id = dw.recordId, Business_Case_Age__c = null));
            }
            }  
			
        // Update cases in one go
        if (!casesToUpdate.isEmpty()) {
            Database.update(casesToUpdate, false); // Use false to allow partial success
        }    
    }

    private static BusinessHours getBusinessHours(String country) {
        // Fetch the appropriate business hours based on country metadata
        GSC_Case_Country_Closure_Email__mdt[] metadataDetails = [SELECT Business_Hours_Id__c FROM GSC_Case_Country_Closure_Email__mdt WHERE GSC_Country__c = :country AND Default__c = :true LIMIT 1];
        if (metadataDetails.size() > 0 && String.isNotBlank(metadataDetails[0].Business_Hours_Id__c)) {
            return [SELECT Id FROM BusinessHours WHERE Id = :metadataDetails[0].Business_Hours_Id__c LIMIT 1];
        } else {
            return [SELECT Id FROM BusinessHours WHERE IsDefault = :true LIMIT 1];
        }
}
}
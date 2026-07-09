/*****************************************************************************************************************************
Name : Test_EventObject 
Created By : Srinivasa Rao Mandalapu
Created Date : 03rd Dec, 201
Usages : Test coverage of CheckEventsCreatedOnClosedCase Trigger with custom settings logic.
*****************************************************************************************************************************/
@isTest(SeeAllData=true)
private class Test_EventObject {
	
	public static String CheckEventCreatedOnClosedCase=null;
    
    /*CheckEventCreatedOnClosedCase code coverage*/
    static testMethod void TestCheckEventsCreatedOnClosedCase() {
        
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
	    List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
	    for(Trigger_Activation_Settings__c cs : customsettings){
	      if(cs.Object__c == 'Event') {
	        cs.Value__c='True';
	        updatesettings.add(cs);
	      }
	    }
	    update updatesettings;
	    
        // TO DO: implement unit test
        IM_Customer_Account__c custAcc = GenerateTestData.createCustomerAccount('101' , 'Test');
        system.debug('customer acct created:'+custAcc.Id);
        Case newCase = GenerateTestData.createCase(null ,custAcc.Id);    
        // Add comment for closed case
        CaseComment cComment = GenerateTestData.createCaseComment(newCase.id);       	
         //      
        Event evt = GenerateTestData.createEvent(null);
        newCase.Status = 'Closed';
        update newCase;       
               
        try{
            evt.WhatID = newCase.ID;
            update evt;
        }
        Catch(Exception ex){
            //System.assert(ex.getMessage().Contains('Event cannot be created on a closed case'));
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        evt = [Select id , WhatID from Event where id = : evt.Id];
        system.assertNotEquals(evt.Id , newCase.Id);
    }
}
@isTest(seealldata = true)
private class TestOppCustomerVerifiersContExt {

    private static Account acct;
    private static Opportunity opp;

    static {
        acct = TestingUtils.createAccounts(1,true)[0];
        opp = TestingUtils.createOpportunity(null, acct.Id, false);

    }

    @isTest static void testConstructor() {
        opp.Customer_Verifier_2__c = true;
        opp.Customer_Verifier_3__c = true;
        insert opp;
        Test.startTest();
        
        OppCustomerVerifiersContExt cont = new OppCustomerVerifiersContExt(new ApexPages.StandardController(opp));
        string verifier = cont.verifiers;
        try{
        	cont.addMessage('Test message');
        }
        catch(Exception ex){
            
        }
        Test.stopTest();

        //system.assertEquals(Opportunity.Customer_Verifier_2__c.getDescribe().getInlineHelpText(), cont.cv2);
        system.assertEquals('view', cont.mode);
        //system.assertEquals('ac', cont.verifiers);
    }
    
    @isTest static void testEdit() {
        OppCustomerVerifiersContExt cont = new OppCustomerVerifiersContExt(new ApexPages.StandardController(opp));
        system.assertEquals('view', cont.mode);

        Test.startTest();
        cont.edit();
        Test.stopTest();

        system.assertEquals('edit', cont.mode);
    }

    @isTest static void testCancel() {
        OppCustomerVerifiersContExt cont = new OppCustomerVerifiersContExt(new ApexPages.StandardController(opp));
        cont.edit();
        system.assertEquals('edit', cont.mode);

        Test.startTest();
        cont.cancel();
        Test.stopTest();

        system.assertEquals('view', cont.mode);
    }
    
    @isTest static void testSave() {
        insert opp;

        OppCustomerVerifiersContExt cont = new OppCustomerVerifiersContExt(new ApexPages.StandardController(opp));
        cont.edit();
        system.assertEquals('edit', cont.mode);
        cont.opp.Customer_Verifier_2__c = true;
        cont.opp.Customer_Verifier_3__c = true;

        Test.startTest();
        cont.save();
        Test.stopTest();

        system.assertEquals('view', cont.mode);
        opp = [SELECT Id, Customer_Verifier_3__c, Customer_Verifier_4__c, Customer_Verifier_2__c FROM Opportunity WHERE Id=:opp.Id];
        system.debug(opp);
        //system.assert(opp.Customer_Verifier_4__c);
        //system.assert(!opp.Customer_Verifier_2__c);
        //system.assert(opp.Customer_Verifier_3__c);
        //system.assertEquals('ac',cont.verifiers);

    }
    
}
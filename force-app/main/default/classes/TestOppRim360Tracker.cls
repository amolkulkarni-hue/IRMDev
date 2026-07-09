@isTest
private class TestOppRim360Tracker {

    private static Account acct;
    private static Opportunity opp;

    static {
        acct = TestingUtils.createAccounts(1,true)[0];
        opp = TestingUtils.createOpportunity('testOppt', acct.Id, false);
        //opp.RIM360_1__c = 'Yes';
        // #16915 opp.RIM360_2__c = 'NO';
    }

    @isTest static void testConstructor() {
       
        Test.startTest();
        OppRim360TrackerClass oppRimCls = new OppRim360TrackerClass(new ApexPages.StandardController(opp));
        Test.stopTest();        
        system.assertEquals('view', oppRimCls.mode);
    }
    
    @isTest static void testEdit() {
        OppRim360TrackerClass oppRimCls = new OppRim360TrackerClass(new ApexPages.StandardController(opp));
        system.assertEquals('view', oppRimCls.mode);

        Test.startTest();
        oppRimCls.edit();
        Test.stopTest();

        system.assertEquals('edit', oppRimCls.mode);
    }
    
    @isTest static void testEdit_noAccess() {
        OppRim360TrackerClass oppRimCls = new OppRim360TrackerClass(new ApexPages.StandardController(opp));
        system.assertEquals('view', oppRimCls.mode);
        
        oppRimCls.canEdit=false;
        Test.startTest();
        oppRimCls.edit();
        Test.stopTest();
    }

    @isTest static void testCancel() {
        OppRim360TrackerClass oppRimCls = new OppRim360TrackerClass(new ApexPages.StandardController(opp));
        oppRimCls.edit();
        system.assertEquals('edit', oppRimCls.mode);

        Test.startTest();
        oppRimCls.cancel();
        Test.stopTest();

        system.assertEquals('view', oppRimCls.mode);
    }
    
    @isTest static void testSave() {
        //insert opp;

        OppRim360TrackerClass oppRimCls = new OppRim360TrackerClass(new ApexPages.StandardController(opp));
        oppRimCls.edit();
        system.assertEquals('edit', oppRimCls.mode);

        Test.startTest();
        oppRimCls.save();
        Test.stopTest();

        system.assertEquals('view', oppRimCls.mode);
       // opp = [SELECT Id ,RIM360_1__c /*, #16915 RIM360_2__c */ FROM Opportunity WHERE Id=:opp.Id];
        //system.debug(opp);     

    }
    
     @isTest static void testSave_noAccess() {
        //insert opp;

        OppRim360TrackerClass oppRimCls = new OppRim360TrackerClass(new ApexPages.StandardController(opp));
        oppRimCls.edit();
        system.assertEquals('edit', oppRimCls.mode);

        oppRimCls.canEdit=false;
        Test.startTest();
        oppRimCls.save();
        Test.stopTest();

        //opp = [SELECT Id , RIM360_1__c /*#16915 RIM360_2__c*/ FROM Opportunity WHERE Id=:opp.Id];
        //system.debug(opp);     

    }
    
    @isTest static void testSave_oppNull() {
       // insert opp;
        OppRim360TrackerClass oppRimCls = new OppRim360TrackerClass(new ApexPages.StandardController(opp));
        oppRimCls.edit();
        system.assertEquals('edit', oppRimCls.mode);

        oppRimCls.opp.Id= null;
        Test.startTest();
        oppRimCls.save();
        Test.stopTest();

       // opp = [SELECT Id,RIM360_1__c  /*#16915, RIM360_2__c */ FROM Opportunity WHERE Id=:opp.Id];
        //system.debug(opp);   
    }
    
    @isTest static void testErrorMsgs() {
        
        OppRim360TrackerClass oppRimCls = new OppRim360TrackerClass(new ApexPages.StandardController(opp));
        oppRimCls.addMessage('Dummy','Dummy message');
        
    }
    
}
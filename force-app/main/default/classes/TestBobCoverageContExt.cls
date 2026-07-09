/* Commenting the entire code as part of Gitlab #24446 */
@isTest
private class TestBobCoverageContExt {
/*
    static BobCoverageContExt bobExt;
    static  ApexPages.StandardController controller; 
    static integer amountTotal; 
    
    
    static void setup() {
        RecordType imgaRecordType = [ SELECT Id  FROM RecordType WHERE SObjectType = 'Account' and DeveloperName = 'IMGA_Record_Type' LIMIT 1];
        
        Account testAcc = TestingUtils.createAccounts( 1, false )[0];
        testAcc.RecordTypeId = imgaRecordType.ID;
        insert testAcc;
        
        Bob_Coverage__c bobCoverage = TestingUtils.createBoBCoverages( 1, testAcc.Id, 'TestBoB', 'Test Product', 'United Kingdom', true )[0];
        
        amountTotal = 0;
        list<Bob_Coverage_join__C> bobJoins = new list<Bob_Coverage_join__c>();
        for(integer i = 0; i < 12; i++) {
            bobJoins.add(new Bob_Coverage_Join__c(Invoice_Date__c = date.newinstance(2013, i + 1, 1), amount_total__c = i * 100, bob_coverage__c = bobCoverage.id));
            amountTotal += i * 100;
        }
        insert bobJoins;
        controller = new ApexPages.StandardController(bobCoverage);
        
    }
    
    
    static testMethod void testBobCoverageContExtInit(){
        setup();
        
        Test.startTest();
            bobExt = new BobCoverageContExt(controller);
        Test.stopTest();
        BoB_Coverage__c bob = bobExt.bob;
        
       // System.AssertEquals(bob.CY_YTD_Amount__c - bob.M2_YTD_Quota_Summary__c, bobExt.currentYearSum , 'The current Year Sum is not being calculated correctly');
        System.AssertEquals(12, bobExt.currentYearPercentages.size(), 'The current year percentages need twelve values');

    }
        */
}
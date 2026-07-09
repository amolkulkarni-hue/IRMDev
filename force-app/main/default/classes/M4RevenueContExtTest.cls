@isTest
public with sharing class M4RevenueContExtTest {
    
    /* Commenting the entire code as part of Gitlab #25402 */
    
/*
    public static testMethod void M4RevenueContExtTest(){
        List<User> reps;
        System.runAs(TestingUtils.ADMIN_USER) 
        {
            reps = IMGAUtilities.insertSalesReps();
        }
        Account account = IMGAUtilities.instantiateImgaAccounts(1, reps[0].Id, reps[1].Id)[0];
        insert account;
        
        Parent_Billing_Market__c pbm = TestingUtils.createParentBillingMarketRecords(1, false)[0];
        pbm.Country_Coverage__c = 'United States';
        insert pbm;
               
        M4_Revenue_Coverage__c coverage = ImgaUtilities.createTestM4(account.id, pbm.Id, 'Canada', 'DB&R');
        insert coverage;
        
        Test.startTest();
            ApexPages.StandardController stdCont = new ApexPages.StandardController(coverage);
            M4RevenueContExt newExt = new M4RevenueContExt(stdCont);
        Test.stopTest();
        
        System.assertEquals(12, newExt.currentYearActuals.size(), 'An incorrect number of Actuals setup');
        System.assertEquals(12, newExt.currentYearPercentages.size(), 'An incorrect number of Percentages setup');
        System.assertEquals(12, newExt.currentYearQuotas.size(), 'An incorrect number of Quotas setup');
        System.assertEquals(12, newExt.currentYearTotals.size(), 'An incorrect number of totals setup');
        
    } 
    
    
*/    
}
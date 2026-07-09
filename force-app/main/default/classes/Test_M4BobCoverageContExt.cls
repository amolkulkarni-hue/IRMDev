/* Commenting the entire code as part of Gitlab #24446 */
@isTest
public with sharing class Test_M4BobCoverageContExt{
    /*
    public static testMethod void Test_M4BobCoverageContExt(){
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
               
    //    BoB_Coverage_Eligible__c coverage = TestingUtils.createBoBCoverageEligibles(account[0].Id,false)[0];
        BoB_Coverage_Eligible__c coverage = new BoB_Coverage_Eligible__c(Account__c=account.Id);
        insert coverage;
        
        Test.startTest();
            ApexPages.StandardController stdCont = new ApexPages.StandardController(coverage);
            M4BobCoverageContExt newExt = new M4BobCoverageContExt (stdCont);
        Test.stopTest();
        
        System.assertEquals(12, newExt.currentYearActuals.size(), 'An incorrect number of Actuals setup');
        System.assertEquals(12, newExt.currentYearPercentages.size(), 'An incorrect number of Percentages setup');
        System.assertEquals(12, newExt.currentYearQuotas.size(), 'An incorrect number of Quotas setup');
        System.assertEquals(12, newExt.currentYearTotals.size(), 'An incorrect number of totals setup');
        
    } 
    
    
    */
}
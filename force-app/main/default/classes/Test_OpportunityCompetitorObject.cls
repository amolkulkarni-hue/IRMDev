/** 
 *Author: Srinivasa Rao Mandalapu
 *Date: 12/13/2012
 *Comments: Test class for Test_Opportunity_CompetitorObject Trigger under Opportunity_Competitor__c.
 */
 /* Developer Name: Madhu Paladugu
   Case number   : 01074173
   Date          : 2/12/2013
   Discription   : made changes to test class to get coverage to newly added logic for opportunitycompetitorsCountTrig.
*/ 
@isTest(SeeAllData=true)
private class Test_OpportunityCompetitorObject {
    
    public static String PopulateOpportunityOwnerEmail = null;
    
    static testMethod void TestPopulateOpportunityOwnerEmail() {
      
        Competitor__c COMP=new Competitor__c();
        COMP.Name='TEST COMP';
        INSERT COMP;
        
        Competitor__c COMP1=new Competitor__c();
        COMP1.Name='TEST COMP1';
        INSERT COMP1;
        
        Account ACC= new Account(name='ACCOUNT FOR TEST COMP TEST CLASS', BillingCountry='United States');
        insert ACC;
        
        Opportunity OPP=new Opportunity();
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        OPP.AccountId=ACC.Id;
        OPP.Name='TEST OPP FOR COMP';
        OPP.CloseDate = date.today();
        OPP.StageName = '1 - Qualification';
        OPP.IM_Booked_Date__c=Date.today();
        //OPP.StageName='4 - Negotiate';
        OPP.Type='New Deal';
        OPP.Lead_Source_Most_Recent__c = 'Email';
        OPP.IM_Servicing_Region__c = 'Aberdeen';
        
        INSERT OPP;
        
        Opportunity_Competitor__c OPPCOMP=new Opportunity_Competitor__c();
        OPPCOMP.Opportunity__c=OPP.Id;
        OPPCOMP.Competitor__c=COMP.Id;
        
        INSERT OPPCOMP;
        
        Opportunity_Competitor__c OPPCOMP1=new Opportunity_Competitor__c();
        OPPCOMP1.Opportunity__c=OPP.Id;
        OPPCOMP1.Competitor__c=COMP1.Id;
        
        INSERT OPPCOMP1;
        
        Test.starttest();
        Opportunity TEST_OPP_FOR_ASSET=[Select Id,IM_Has_Competitors__c from Opportunity where Id=:OPPCOMP.Opportunity__c];
        
        //System.assertEquals(TEST_OPP_FOR_ASSET.IM_Has_Competitors__c,true);
        
        DELETE OPPCOMP;
        Opportunity TEST_OPP_FOR_ASSET1=[Select Id,IM_Has_Competitors__c from Opportunity where Id=:OPPCOMP.Opportunity__c];
        //System.assertEquals(TEST_OPP_FOR_ASSET1.IM_Has_Competitors__c,false);
        
         DELETE OPPCOMP1;
         TEST_OPP_FOR_ASSET1=[Select Id,IM_Has_Competitors__c from Opportunity where Id=:OPPCOMP.Opportunity__c];
        System.assertEquals(TEST_OPP_FOR_ASSET1.IM_Has_Competitors__c,false);
        
        Test.stoptest();
       
    }
}
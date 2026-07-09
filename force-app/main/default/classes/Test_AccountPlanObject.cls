@isTest(SeeAllData=true)
private class Test_AccountPlanObject {

    
    
    static testMethod void createAccPlan1()
    {
        Account a = new Account(Name='Account4TestMethod1'+system.now()
                               , BillingPostalCode='BD3 11'
                               , BillingCountry='United Kingdom',
                               IM_Hierarchy_Level__c='Country Parent');
        insert a;
        
        
        SFDC_Acct_Plan__c ap = new SFDC_Acct_Plan__c();
        ap.name='Acc Plan 1';
        ap.Account__c = a.id;
        ap.Organizational_Chart__c = ' This is text and <img src= \'www.google.com/img.jpg\' /img> and some more text.';
        //ap.INTL_Country_Parent__c = null;
        //ap.INTL_Country_Parent_ID__c = null;
        insert ap;

    
    }
    
  /*  static testMethod void createAccPlan2()
    {
        Account a = new Account(Name='Account4TestMethod1'+system.now()
                               , BillingPostalCode='BD3 11'
                               , BillingCountry='United Kingdom');
        insert a;
        
        
        SFDC_Acct_Plan__c ap = new SFDC_Acct_Plan__c();
        ap.name='Acc Plan 1';
        ap.Account__c = a.id;
        insert ap;

    } */


}
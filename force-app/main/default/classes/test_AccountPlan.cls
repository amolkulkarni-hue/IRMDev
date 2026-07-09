@isTest(seeAllData= true)
public class test_AccountPlan {
public static testMethod Void doTest(){
    Id IMGARecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('IMGA Record Type').getRecordTypeId();
    Id StdRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Standard Account').getRecordTypeId();
    Id GlobalRecordTypeId = Schema.SObjectType.SFDC_Acct_Plan__c.getRecordTypeInfosByName().get('Global Account Plan').getRecordTypeId();
    Id INTLRecordTypeId = Schema.SObjectType.SFDC_Acct_Plan__c.getRecordTypeInfosByName().get('INTL Account Plan').getRecordTypeId();
    
    
    Account IMGAAccount = new Account(Name='Test Account',
                                      IM_Hierarchy_Level__c = 'IM Group (IMGA)', RecordTypeId=IMGARecordTypeId);
    insert IMGAAccount;
    
    Account IMGAAccount1 = new Account(Name='Test Account2',
                                      IM_Hierarchy_Level__c = 'IM Group (IMGA)', RecordTypeId=IMGARecordTypeId);
    insert IMGAAccount1;
    
    Account StdAccount = new Account(Name='Test Account1',
                                      IM_Hierarchy_Level__c = 'Country Parent', ParentId=IMGAAccount.Id,
                                     RecordTypeId=StdRecordTypeId);
    
    insert StdAccount;
    
    SFDC_Acct_Plan__c acctPlan = new SFDC_Acct_Plan__c();
    acctPlan.RecordTypeId = GlobalRecordTypeId;
    acctPlan.Name = 'Test account plan for global account';
    acctPlan.Account__c = IMGAAccount.Id;
    insert acctPlan;
    
    
    SFDC_Acct_Plan__c acctPlan1 = new SFDC_Acct_Plan__c();
    acctPlan1.RecordTypeId = INTLRecordTypeId;
    acctPlan1.Name = 'Test account plan for INTL account';
    acctPlan1.Account__c = StdAccount.Id;
    insert acctPlan1;
    
    SFDC_Acct_Plan__c accPlan = new SFDC_Acct_Plan__c();
        accPlan.RecordTypeId = GlobalRecordTypeId;
        accPlan.Name = 'Test account plan for global account';
        accPlan.Account__c = IMGAAccount1.Id;
        insert accPlan;
        
        
    try{
        SFDC_Acct_Plan__c acctPlan2 = new SFDC_Acct_Plan__c();
        acctPlan2.RecordTypeId = GlobalRecordTypeId;
        acctPlan2.Name = 'Test account plan for global accounts';
        acctPlan2.Account__c = IMGAAccount1.Id;
        insert acctPlan2;
    }
        catch(Exception e) {}
     try{   
        accPlan.Account__c = IMGAAccount.id;
        update accPlan; }
        catch(Exception e) {}


}
}
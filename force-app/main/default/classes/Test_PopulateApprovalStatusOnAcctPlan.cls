/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Test_PopulateApprovalStatusOnAcctPlan (Test Class)
**
** PURPOSE
**   Code Coverage for 'PopulateApprovalStatusOnAcctPlan' trigger on 'Management Account Plan Review' Object.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 10/1/2013; Srinivasa Rao/Randstad; Stamp of "approval" on Account Plan (Case # 01758327); Initial release
**
************************************************************************/
@isTest
public class Test_PopulateApprovalStatusOnAcctPlan {

    //Commenting code as part of #24270
   /* static testMethod void myUnitTest() {
        
        //Retrieving Admin Profile
        Profile p = [select id from profile where name='System Administrator' LIMIT 1];
        
        //Retrieving 'IMNA Account Plan' Record Type Id
        RecordType RT = [Select Id From RecordType Where SObjectType= :'SFDC_Acct_Plan__c' AND Name = :'IMNA Account Plan' LIMIT 1];
        
        //Create User
        User u = new user(alias = 'smand99', username='srinu.mandalapu99@IM.com', email='srinu.mandalapu99@IM.com', lastname='mandalapu99',
                          emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id, 
                          timezonesidkey='America/New_York' , country='USA');
        insert u;                         
        
        //create Account
        Account act = new Account();
        act.Name='TestAccount';
        act.IM_Hierarchy_Level__c='Country Parent';
        insert act;
        
        //Create Account Plan
        SFDC_Acct_Plan__c actpln = new SFDC_Acct_Plan__c();
        actpln.Name='IMNAAccountPlan';
        actpln.Account__c=act.Id;
        actpln.RecordTypeId=RT.Id;
        insert actpln;
        
        //Create Management Account Plan Review
        Management_Account_Plan_Review__c mapr = new Management_Account_Plan_Review__c();
        mapr.Reviewed_By__c=u.Id;
        mapr.Account_Plan__c=actpln.Id;
        mapr.Completed_Date__c=System.Today();        
        mapr.Customer_Narrative__c='Not Started';
        mapr.Customer_Challenges__c='In Progress';
        mapr.Organizational_Heat_Map_Key_Contacts__c='Completed';
        mapr.Account_Strategy__c='Not Started';
        mapr.Objectives__c='In Progress';
        mapr.Completeness__c='Completed';
        insert mapr;
        
        //Verify that the Approval_Status__c field is populated on the AccountPlan.        
        List<SFDC_Acct_Plan__c> insertedStatus = [Select Id, Approval_Status__c From SFDC_Acct_Plan__c Where Id = :actpln.Id];
        System.assertEquals('Not Approved', insertedStatus[0].Approval_Status__c);
        
        //Update Management Account Plan Review
        mapr.Reviewed_By__c=u.Id;
        mapr.Account_Plan__c=actpln.Id;
        mapr.Completed_Date__c=System.Today();        
        mapr.Customer_Narrative__c='Completed';
        mapr.Customer_Challenges__c='Completed';
        mapr.Organizational_Heat_Map_Key_Contacts__c='Completed';
        mapr.Account_Strategy__c='Completed';
        mapr.Objectives__c='Completed';
        mapr.Completeness__c='Completed';
        update mapr;
        
        //Verify that the Approval_Status__c field was updated in the database.        
        List<SFDC_Acct_Plan__c> updatedStatus = [Select Id, Approval_Status__c From SFDC_Acct_Plan__c Where Id = :actpln.Id];
        System.assertEquals('Approved', updatedStatus[0].Approval_Status__c);

    } */
}
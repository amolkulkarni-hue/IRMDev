@isTest

private class Test_IMNA_preventTeamMemberDelete{
    
    @testSetup
    public static void init()
    {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
        tA.name = 'PreventTeamMemberDelete';
        tA.Object__c = 'OpportunityTeamMember';
        tA.Trigger__c = 'preventTeamMemberDelete';
        tA.Value__c = 'True';
        
        insert tA;
        
        IM_Country__c cntry = TestingUtil.createIMCountry();
        Account acc = TestingUtils.createAccounts(1, true)[0];
        Contact con = TestingUtils.createContact(acc.id,True);
        
        RecordType NAOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        
        
        Id standardPB = Test.getStandardPricebookId();
        Id IMNA_RT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
        
        Product2 prod=TestingUtils.createProduct('Test Product',False);
        prod.recordtypeId=IMNA_RT;
        insert prod;
        
        PriceBookEntry pbe=TestingUtils.createPriceBookEntry(prod.Id,standardPB,true);
        
        Profile sales = [select Id from profile where Name='IM_Sales']; 
        
        Profile admin = [select id from profile where Name='IM_Custom Sys Admin'];
        
        User owner = new User(Lastname='Owner',alias = 'owner', email='u1@im.com',
                              emailencodingkey='UTF-8', languagelocalekey='en_US',
                              localesidkey='en_US', profileid = sales.Id, Country = 'USA',
                              timezonesidkey='America/Los_Angeles', username='hello1.test1@testorg.com', CurrencyIsoCode='USD',isActive=True);
        
        insert owner;
        
        User member = new User(Lastname='member',alias = 'member', email='u2@im.com',
                               emailencodingkey='UTF-8', languagelocalekey='en_US',
                               localesidkey='en_US', profileid = sales.Id, Country = 'USA',
                               timezonesidkey='America/Los_Angeles', username='hello2.test1@testorg.com', CurrencyIsoCode='USD',isActive=True);
        insert member;  
        
        User AdminUser = new User(Lastname='Admin',alias = 'member', email='u3@im.com',
                                  emailencodingkey='UTF-8', languagelocalekey='en_US',
                                  localesidkey='en_US', profileid = admin.Id, Country = 'USA',
                                  timezonesidkey='America/Los_Angeles', username='hello3.test1@testorg.com', CurrencyIsoCode='USD',isActive=True);
        insert AdminUser;
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel;
        
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
        Opportunity opp = TestingUtils.createOpportunity('test Opportunity', acc.id, false);
        opp.Source_System__c = 'test SKP Europe';
        opp.Billing_Country__c = cntry.id;
        opp.StageName = '1 - Qualification';
        opp.IM_Servicing_Region__c ='London';
        opp.IME_Reason_Won__c = 'Price';
        opp.CloseDate = System.today();
        opp.CurrencyIsoCode = 'USD';
        opp.IM_Booked_Date__c = System.today();
        opp.IM_Stage_5_Entered_Date__c  = System.today();
        opp.RecordTypeId = NAOppType.Id;
        opp.pricebook2ID= standardPB;
        opp.ownerId=owner.id;
        
        insert opp;
        
        //Adding Team Members
        OpportunityTeamMember otm1=new OpportunityTeamMember(OpportunityId=opp.id,userId=member.id);
        insert otm1;
        
        //Adding OCR to Opportunity
        OpportunityContactRole ocr=new OpportunityContactRole(OpportunityId=opp.id,ContactId=con.id,role='Decision Maker');
        insert ocr;
        
        //Adding Products to Opportunity
        OpportunityLineItem oli=TestingUtils.createOLI(pbe.id, opp.Id, true);
        
        ContentVersion  content=new  ContentVersion();
        content.Title = 'Attachment1';
        content.PathOnClient = '/' + content.Title + '.jpg';
        Blob  bodyBlob = Blob.valueof('unit test Contentversion Body');
        Content.VersionData = bodyBlob;
        content.Origin = 'H';
        content.firstPublishLocationId=opp.id;
        insert Content;
        
    }
    
    
    static testMethod void deleteTSU(){
        
        test.starttest();
        
        Opportunity opp=[select id,tsu__c from Opportunity where name ='test Opportunity' limit 1];
        /*Opportunity opp = new Opportunity(Name= 'Test Opp', 
Lead_Source_Most_Recent__c= 'Manual',
StageName = '1 - Qualification',
type = 'Renewal',
OwnerId=u2.id,
CloseDate = system.today()
);  */
        User u1=[Select id from User where Lastname='member' limit 1];
        opp.tsu__c=u1.id;
        update opp;
        
        List<OpportunityTeamMember> otm = new list<OpportunityTeamMember>();
        otm = [select id from OpportunityTeamMember where Opportunity.id = :opp.id and userId= :u1.id];
        System.debug('otm'+otm);
        try{
            delete otm;
        }catch (Exception ex){
            System.assert(ex.getMessage().contains('You cannot delete this team member unless you delete them from the TSU field on the Opportunity.'));
            
        }
        
        test.stoptest();
    }
    
    static testMethod void Test_Delete_TeamMember_As_NonAdmin_Open_Oppty(){
    
        test.starttest();
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        
        User owner=[select id from user where lastName='owner' limit 1];
        
        Opportunity opp=[select id,StageName from Opportunity where name ='test Opportunity' limit 1];

        List<OpportunityTeamMember> otm = new list<OpportunityTeamMember>();
        otm = [select id,user.name from OpportunityTeamMember where Opportunity.id = :opp.id and user.name='member'];
         
        System.runAs(owner){
            try{
                delete otm;
                System.assert(True);
            }catch (Exception ex){
                System.assert(false,'Exception should have not been thrown');
                
            }
        }
        
        test.stoptest();
        
    }
    
    static testMethod void Test_Delete_TeamMember_As_NonAdmin_ClosedOppty_without_Permission(){
        
        test.starttest();
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        User owner=[select id from user where lastName='owner' limit 1];
        
        Opportunity opp=[select id,StageName from Opportunity where name ='test Opportunity' limit 1];
        opp.StageName='5 - Signed/PO in';
        
        update opp;
        
        List<OpportunityTeamMember> otm = new list<OpportunityTeamMember>();
        otm = [select id,user.name from OpportunityTeamMember where Opportunity.id = :opp.id and user.name='member'];
        
        System.runAs(owner){
            try{
                delete otm;
            }catch (Exception ex){
                System.assert(ex.getMessage().contains('Opportunity Team cannot be updated or deleted on a Closed Opportunity. Need Help? Please contact your Business Partner.'));
                
            }
        }
        
        test.stoptest();
        
    }
    
    static testMethod void Test_Delete_TeamMember_As_NonAdmin_ClosedOppty_with_Permission(){
        
         User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
         User owner=[select id from user where lastName='owner' limit 1];
        
        System.runAs (thisUser) {
        PermissionSet AllowTeamMemebrDeletionOnClosedStage =[select id from permissionSet where Name='Update_Fields_on_a_Closed_Opportunity'];
        PermissionSetAssignment psa= new PermissionSetAssignment(permissionSetId=AllowTeamMemebrDeletionOnClosedStage.id,
                                                                AssigneeId=owner.Id);
            insert psa;
        }
        
        test.starttest();
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        
        Opportunity opp=[select id,StageName from Opportunity where name ='test Opportunity' limit 1];
        opp.StageName='5 - Signed/PO in';
        
        update opp;
        
        List<OpportunityTeamMember> otm = new list<OpportunityTeamMember>();
        otm = [select id,user.name from OpportunityTeamMember where Opportunity.id = :opp.id and user.name='member'];
        
        System.runAs(owner){
            try{
                delete otm;
                System.assert(True);
            }catch (Exception ex){
                System.assert(false,'Error should have not been thrown');
                
            }
        }
        
        test.stoptest();
        
    }
}
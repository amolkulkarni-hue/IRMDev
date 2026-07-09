@IsTest

// #16277 Commenting out the code as its main class(ChatterAccountClosure) is Inactive 

public class ChatterAccountClosure_Test {
  /*  public static Account testAccount;
    public static Contact testContact;
    public static Opportunity testOpp;
    public static IM_Customer_Account__c testcustomeraccount;
    public static Case testCase; */
    
  // public static void setup() {
       
      /*  Recordtype OppRT=[select id from recordtype where name='Standard Opportunity' limit 1];
        Recordtype r2=[select id from recordtype where name='NA Customer Account' limit 1];
        
        testAccount = new Account(Name='Test Account',BillingCountry= 'United States',BillingPostalCode='11209',BillingState='NY');
        insert testAccount;
        
        testcontact= new Contact(AccountId=testAccount.Id,LastName='silk',Phone='415-906-3801');
        insert testcontact;
        
        testopp= new Opportunity(Name = 'Test Opportunity', Type='New Deal',AccountId = testAccount.Id, StageName = '1 - Qualification', IM_Booked_Date__c = Date.Today(), closedate = Date.Today(),recordtypeid=OppRT.id,
                                 Group_Purchasing_Organization_GPO__c='HealthTrust',IME_Vended_Unvended__c='Unknown',IM_Servicing_Region__c='London',Source_System__c='SKP NA');
        insert testopp;
        
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        
        User u = new User(Alias = 'unt', Email='stdunit@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Test', FirstName='Test', 
            LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = adminProfile.Id, 
            TimeZoneSidKey='America/New_York', Country='United States', UserName='stdunit@testorg.com');
       insert u;
            
        testcustomeraccount = new IM_Customer_Account__c(Name='Test12',Owning_District_Id__c =testMarket.Id,Source_System__c='SKP NA',IM_Account__c=testAccount.Id,IM_Status__c='Active',RecordTypeId=r2.Id,NA_CY_YTD_Film_Sound__c=10,NA_PY_YTD_Secure_Shredding__c=10,NA_PY_Full_Year_Consulting__c = 70000);
        insert testcustomeraccount;
        
        
        Billing_Cut_Off_Schedule__c bill= new Billing_Cut_Off_Schedule__c(Billing_Cut_Off_Date__c=Date.Today(),Invoice_Mailing_Date__c=Date.Today(),Name='test',Service_Line__c='RM',Year__c='2015');
        insert bill;
        
    } */
    
    static testmethod void ChatterAccountClosureTest1(){
       /* setup();  
        Test.startTest(); 
        
        Recordtype CaseRT=[select id,DeveloperName from recordtype where DeveloperName='CAC_DP_Closure' limit 1];
        
        testCase = new Case(
            NCSP_Opportunity__c=testopp.Id, 
            ContactId=testcontact.Id,
            AccountId=testAccount.id,
            RecordTypeId=CaseRT.Id,
            Territory_GM__c = 'Test',
            Date_Closure_CSA_Assigned__c = System.today(),
            Customer_ID__c = testcustomeraccount.Id
        );
        insert testCase;
        Test.stopTest();        
    }
    static testmethod void ChatterAccountClosureTest2(){
        setup();  
        Test.startTest(); 
        
        Recordtype CaseRT=[select id,DeveloperName from recordtype where DeveloperName='CAC_SKP_RM' limit 1];
        
        testCase = new Case(
            NCSP_Opportunity__c=testopp.Id, 
            ContactId=testcontact.Id,
            AccountId=testAccount.id,
            RecordTypeId=CaseRT.Id,
            Territory_GM__c = 'Test',
            Date_Closure_CSA_Assigned__c = System.today(),
            Authorized_User__c = 'No',
            Customer_ID__c = testcustomeraccount.Id
        );
        insert testCase;
        Test.stopTest();        
    }
    static testmethod void ChatterAccountClosureTest3(){
        setup();  
        Test.startTest(); 
        
        Recordtype CaseRT=[select id,DeveloperName from recordtype where DeveloperName='CAC_SKP_Shred' limit 1];
        
        Map<String, String> CustIdMap = new Map<String, String>();
        Map<String, Id> UserId = new Map<String, id>();
        
        testCase = new Case(
            NCSP_Opportunity__c=testopp.Id, 
            ContactId=testcontact.Id,
            AccountId=testAccount.id,
            RecordTypeId=CaseRT.Id,
            Territory_GM__c = 'Test Test',
            Date_Closure_CSA_Assigned__c = System.today(),
            //Closure_Reason__c = '5e - Relationship - Contractual Concerns',
            Authorized_User__c = 'No',
            Customer_ID__c = testcustomeraccount.Id
        );
        insert testCase;
        
        
        ConnectApi.FeedElementPage testPage = new ConnectApi.FeedElementPage();
        List<ConnectApi.FeedItem> testItemList = new List<ConnectApi.FeedItem>();
        testItemList.add(new ConnectApi.FeedItem());
        testItemList.add(new ConnectApi.FeedItem());
        testPage.elements = testItemList;
        
        // Set the test data
        ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(null,ConnectApi.FeedType.News, 'me', testPage);
        
        Test.stopTest();        
    }
    
    static testmethod void ChatterAccountClosureTest4(){
        setup();  
        Test.startTest(); 
        
        Recordtype CaseRT=[select id,DeveloperName from recordtype where DeveloperName='CAC_SKP_Shred' limit 1];
        
        Map<String, String> CustIdMap = new Map<String, String>();
        Map<String, Id> UserId = new Map<String, id>();
        
        testCase = new Case(
            NCSP_Opportunity__c=testopp.Id, 
            ContactId=testcontact.Id,
            AccountId=testAccount.id,
            RecordTypeId=CaseRT.Id,
            Territory_GM__c = 'Test Test',
            Date_Closure_CSA_Assigned__c = System.today(),
            //Closure_Reason__c = '5e - Relationship - Contractual Concerns',
            Authorized_User__c = 'No',
            Customer_ID__c = testcustomeraccount.Id
        );
        insert testCase;
        
        
		String idString =  SendChatterPostUtil.sendChatterPost(UserId,CustIdMap,testCase.id,
                                                                                   testCase.Territory_GM__c,testCase.Customer_ID__c,
                                                                                   testCase.Customer_Name__c,testCase.Market_Name__c,
                                                                                   testCase.OwnerId);	        
        
        Test.stopTest();        
    } */  
    } 
}
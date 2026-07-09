/*Developer Name: Vijay Andrews
  Company       : Iron Mountain Services.
  Desrciption   : This is the test utility for SKPOpportunitySync Class.
  Date          : 12/11/2015 */
@isTest(seeAllData=true)
public class SKPOpportunitySync_test {
    public static Account testAccount;
    public static Contact testContact;
    public static Opportunity testOpp;
    public static IM_Customer_Account__c testcustomeraccount;
    public static Case testCase;
    public static void setup() {
      List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
      List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
      for(Trigger_Activation_Settings__c cs : customsettings){
          if(cs.Object__c == 'Opportunity') {
              if(cs.Trigger__c == 'SKPOpportunitySync'){
          cs.Value__c='True';
              } else {
               cs.Value__c='false';   
              }
          updatesettings.add(cs);
        }
      }
      update updatesettings;
      OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
      AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        IM_Country__c cntry = TestingUtil.createIMCountry();
        Id standardPB = Test.getStandardPricebookId();
        
      Recordtype r=[select id from recordtype where name='Standard Opportunity' limit 1];
      Recordtype r1=[select id from recordtype where name='NCSP: SKP New Customer Setup' limit 1];
      Recordtype r2=[select id from recordtype where name='NA Customer Account' limit 1];
      testAccount = new Account(Name='Test Account',BillingCountry= 'United States',BillingPostalCode='11209',BillingState='NY');
      insert testAccount;
      testcontact= new Contact(AccountId=testAccount.Id,LastName='silk',Phone='415-906-3801');
      insert testcontact;
      testopp= new Opportunity(Name = 'Test Opportunity', Type='New Deal',AccountId = testAccount.Id, StageName = '1 - Qualification', IM_Booked_Date__c = Date.Today(), closedate = Date.Today(),recordtypeid=r.id,
        Group_Purchasing_Organization_GPO__c='HealthTrust',IME_Vended_Unvended__c='Unknown',IM_Servicing_Region__c='London', Billing_Country__c = cntry.id, Source_System__c='SKP NA');
      insert testopp;
      //Pricebook2 testStandardPriceBook = [select id from Pricebook2 where IsStandard = true];

      //Creating a Prooduct, PriceBookEntry for it and using these record to generate OpportunityLineItem record.
      //Product2 testProd = new Product2(Name = 'Test Product', IsActive= true/*, recordtypeid=r3.id*/ );
      //insert testProd;
      Id rt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
            
        Product2 testProd = new Product2(Name = '9999',
                                         recordTypeId=rt, 
                                         IsActive= true,
                                         Bill_Code_Classification__c='Storage');
        insert testProd;
        
      PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = testProd.Id, Pricebook2Id = standardPB, UnitPrice = 1, IsActive = true, UseStandardPrice = false);
      insert testPriceBookEntry;
        
        testopp.Pricebook2Id = testPriceBookEntry.Pricebook2Id;
        update testopp;
        
      OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = testPriceBookEntry.Id, OpportunityId = testopp.Id, Product2Id = testProd.Id, unitPrice = 1, Update_New_Revenue_Forecast__c =false );
      insert oppProd;
      Market__c testMarket = new Market__c( name= 'testMarket' );
      insert testMarket;
      testcustomeraccount = new IM_Customer_Account__c(Name='Test12',Owning_District_Id__c =testMarket.Id,Source_System__c='SKP NA',IM_Account__c=testAccount.Id,IM_Status__c='Active',RecordTypeId=r2.Id,NA_CY_YTD_Film_Sound__c=10,NA_PY_YTD_Secure_Shredding__c=10);
      insert testcustomeraccount;
      Billing_Cut_Off_Schedule__c bill= new Billing_Cut_Off_Schedule__c(Billing_Cut_Off_Date__c=Date.Today(),Invoice_Mailing_Date__c=Date.Today(),Name='test',Service_Line__c='RM',Year__c='2015');
      insert bill;
      testCase = new Case(NCSP_Opportunity__c=testopp.Id, ContactId=testcontact.Id,AccountId=testAccount.id,RecordTypeId=r1.Id);
      insert testCase;
        
        contentVersion  content=new  ContentVersion();
        content.Title = 'Attachment1';
        content.PathOnClient = '/' + content.Title + '.jpg';
        Blob  bodyBlob = Blob.valueof('unit test Contentversion Body');
        Content.VersionData = bodyBlob;
        content.Origin = 'H';
        insert Content;
        
        ContentVersion ContentVersion_2 = [ select id, title, contentdocumentid from contentversion where Title ='Attachment1' limit 1];
        contentDocumentLink cdlObj = new  contentDocumentLink();
        cdlObj.LinkedEntityId = testOpp.id;
        cdlObj.ContentDocumentId =ContentVersion_2.ContentDocumentId;
        cdlObj.ShareType = 'V';
        insert cdlObj;
        
      }
    static testmethod void SKPOpportunitySynccreatetest(){
        setup();
        testopp.stagename = '5 - Signed/PO in';
        testopp.IME_Reason_Won__c = 'Price';
        update testOpp;
        
        testOpp.StageName='6 - Setup';
        update testOpp;
        Test.startTest();
        testCase.Customer_ID__c=testcustomeraccount.id;
        update testCase;
        Test.stopTest();
         
    }
    static testmethod void SKPOpportunitySyncupdatetest(){
        setup();
        testopp.stagename = '5 - Signed/PO in';
        testopp.IME_Reason_Won__c = 'Price';
        update testOpp;
        
        testOpp.StageName='6 - Setup';
        testOpp.SKP_Opportunity_Sync_Date__c=Date.Today();
        update testOpp;
        Test.startTest();
        testCase.Customer_ID__c=testcustomeraccount.id;
        update testCase;
        Test.stopTest();
         
    }
}
@isTest
public with sharing class DocuSignStatusTriggerTest {
    
    private final static Integer NUM_PROD = 5;
    private final static Integer NUM_DOCUSIGN = 30;
    private final static String COMPLETED_ENVELOPE_STATUS = 'Completed';
    private final static String VOID_ENVELOPE_STATUS = 'Void';
    private static Account testAccount;
    private static Opportunity testOpp;
    private static Contact testContact;
    private static IM_Customer_Account__c ca;
    private static Case testCase;

    public static Pricebook2 stdpbook{
        get
        {
            if(stdpbook == null){
                Id stdPBId = Test.getStandardPricebookId();
                Pricebook2 stdpbook = new Pricebook2(Id=stdPBId, Name='Standard Pricebook', isActive=true);
                return stdpbook;
            }
            else{ return stdpbook; }
        }
        set;
    }
    
    public static Pricebook2 testPriceBook{
        get
        {
            if(testPricebook == null){
                Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
                insert customPB;
                return [Select Id, Name from Pricebook2 where Name = 'Custom Pricebook' LIMIT 1];
            }
            else
                return testPriceBook;
        }
        set;
    }
    
    public static PricebookEntry createStandardPricebookEntry(Id prodId)
    {
        PriceBookEntry stdPriceBookEntry = TestingUtils.createPriceBookEntry(prodId, Test.getStandardPricebookId(), false);
        stdPriceBookEntry.useStandardPrice = false;
        stdPriceBookEntry.UnitPrice = 200;
        stdPriceBookEntry.IsActive = true;
        insert stdPriceBookEntry;
        
        return stdPriceBookEntry;
    }
    
    public static PricebookEntry createTestPricebookEntry(Id prodId)
    {
        PriceBookEntry testPriceBookEntry = TestingUtils.createPriceBookEntry(prodId, testPriceBook.Id, false);
        testPriceBookEntry.useStandardPrice = false;
        testPriceBookEntry.UnitPrice = 100;
        testPriceBookEntry.IsActive = true;
        insert testPriceBookEntry;
        
        return testPriceBookEntry;
    }
    
    public static void setUp()
    {
        //testAccount = TestingUtils.createAccounts ( 1, true)[0];
        IM_Country__c mainName = new IM_Country__c(Name='United States');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States');
        insert country;
        Country_Settings__c Cs = new Country_Settings__c(Name='United States',
                                                      Object_Name__c = 'Account',
                                                      CurrencyIsoCode = 'USD');
      insert Cs;
        OpportunityProductSelection__c OpS = new OpportunityProductSelection__c(Name='CloudSolutionsProduct',
                                                                              Product_Class_Name__c='Test',
                                                                              Product_Line_Name__c = 'Test');
      insert OpS;
             testAccount = new Account();
             testAccount.Name = 'TestAccount_' +Math.random();
             testAccount.BillingCountry = 'United States';
             testAccount.BillingPostalCode = '11209';
             testAccount.BillingState = 'NY';
             testAccount.IM_Hierarchy_Level__c = 'Sales (Site)';    

        insert testAccount;
        system.debug('Print account ' + testAccount);
        system.debug('Pring billing country '+ testAccount.BillingCountry);
        ca = TestingUtils.createCustomerAccount(testAccount.id, true);
        ca.Billing_Country__c = mainName.id;
        update ca;
        system.debug('Print customer acc billing country '+ ca.Billing_Country__c);
        //OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;
        //testOpp = TestingUtils.createOpportunity('Sample Oppr', testAccount.Id, true);
        testOpp = new Opportunity(IM_Servicing_Region__c='Houston',
                                              IM_Booked_Date__c=Date.today(), 
                                              StageName='1 - Qualification', 
                                              AccountId = testAccount.Id, 
                                              CloseDate = System.today(),
                                              Name = 'Sample Oppr');
        insert testOpp;
        system.debug('Print opp acc id '+ testOpp.account.id + ' billing country '+ testOpp.Account.BillingCountry);
        DocuSignStatusService.PRICEBOOK_NORTH_AMERICA = testPriceBook;
        testContact = TestingUtils.createContact(testAccount.id,true);
        testCase = TestingUtils.createCase(testOpp,testContact,true);
      //  testContact.Email = 'abc@ironmountain.com';
      //  update testContact;

        //  update DocuSign_SenderEmail_List__c
        list<DocuSign_SenderEmail_List__c> DSLlst = new list<DocuSign_SenderEmail_List__c>();
        DocuSign_SenderEmail_List__c DSL = new DocuSign_SenderEmail_List__c(Name = 'Ukiinventory',
                                                                           Sender_Email__c = 'ukiinventoryservices@ironmountain.co.uk');
        DSLlst.add(DSL);
        DocuSign_SenderEmail_List__c DSL1 = new DocuSign_SenderEmail_List__c(Name = 'Testing',
                                                                           Sender_Email__c = 'test.email@example.com');
        DSLlst.add(DSL1);
        insert DSLlst;
        //insert user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        system.debug('++++++++'+p.id);
      	User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
      			EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
      			LocaleSidKey='en_US', ProfileId = p.Id,TimeZoneSidKey='America/Los_Angeles',
        		UserName='standarduserrrr@testorg.com',country='india');
        insert u;
           system.debug('++++++++'+u.id);
            testCase.Status = 'New';
            testCase.Origin = 'Internal';
            testCase.IM_Division__c = 'IMAP';
            testCase.Priority = 'Medium';
            testCase.Subject = 'Testing';
            testCase.Description='Testing';
            testCase.Case_Category__c = 'incident';
            testCase.Case_Sub_Category__c = 'Security';
            testCase.IM_Functional_Group__c = 'IT';
            testCase.Sales_Tools_Ranking__c = '1. High';
            testCase.OwnerId =u.Id;
            update testCase;
        
    }

    public static String generateScheduleAJsonString(Id acctId, Id opptyId,Integer num)
    {
        String scheduleAJsonStr = '{'+
        '\"Name\": '+'\"TestQuote'+num+'\",'+
        '\"Service_Line__c\": '+'\"Record Management\",'+
        '\"Contract_Length__c\": '+'12,'+
        '\"Account\": '+'\"'+acctId+'\",'+
        '\"Opportunity\": '+'\"'+opptyId+'\",'+
        '\"Effective_Date__c\": '+'\"04212003\"'+
        '}';
        
        return scheduleAJsonStr;
    }
    
    public static String generateSLTJsonString(List<Product2> testProducts)
    {
        String scheduleALineItemJsonStr = '['+'{'+
        '\"Product2\": '+'\"Test Prod1\",'+
        '\"ProductId\": '+'\"'+testProducts[0].Id+'\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '},'+
        '{'+
        '\"Product2\": '+'\"Test Prod2\",'+
        '\"ProductId\": '+'\"'+testProducts[1].Id+'\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '},'+
        '{'+
        '\"Product2\": '+'\"Test Prod3\",'+
        '\"ProductId\": '+'\"'+testProducts[2].Id+'\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '},'+
        '{'+
        '\"Product2\": '+'\"Test Prod4\",'+
        '\"ProductId\": '+'\"'+testProducts[3].Id+'\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '},'
         +'{'+
        '\"Product2\": '+'\"Test Prod5\",'+
        '\"ProductId\": '+'\"'+testProducts[4].Id+'\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '}'+
         ']';
        
        return scheduleALineItemJsonStr;
    }
    
    public static List<Schedule_A_Data__c> setUpScheduleAData()
    {
        List<Product2> testProducts = new List<Product2>();
        for(Integer i=0; i < NUM_PROD; i++)
        {
            Product2 testProduct = TestingUtils.createProduct('Test Product'+i, false);
            testProducts.add(testProduct);
        }
        insert testProducts;
        for(Integer i=0; i < NUM_PROD; i++)
        {
            PricebookEntry stdPbe = createStandardPricebookEntry(testProducts[i].Id);
            PricebookEntry testPbe = createTestPricebookEntry(testProducts[i].Id);
        }
        
        
        List<Schedule_A_Data__c> listOfScheduleAData = new List<Schedule_A_Data__c>();
        for(Integer i = 0; i<NUM_DOCUSIGN; i++)
        {
            system.debug('Print account id '+testAccount.Id );
            system.debug('Print opp id '+testOpp.Id);
            String scheduleAJsonStr = generateScheduleAJsonString(testAccount.Id, testOpp.Id, i);
            system.debug('print scheduleAJsonStr'+ scheduleAJsonStr);
            String scheduleALineItemJsonStr = generateSLTJsonString(testProducts);
            Schedule_A_Data__c  testScheduleData = new Schedule_A_Data__c();
            testScheduleData.Schedule_A__c = scheduleAJsonStr;
            testScheduleData.Schedule_A_Line_Item__c = scheduleALineItemJsonStr;
            testScheduleData.Opportunity__c = testOpp.Id;
            listOfScheduleAData.add(testScheduleData);
        }
        insert listOfScheduleAData;
        return listOfScheduleAData;
        
    }
    
    static testMethod void testDocuSignStatusTrigger()
    {
        setUp();
        List<Schedule_A_Data__c> allScheduleAData = setUpScheduleAData();
        List<dsfs__DocuSign_Status__c> testDocuSignListOld = TestingUtils.createDocusignStatus(testOpp, NUM_DOCUSIGN, false);
        
        for (Integer i = 0; i < NUM_DOCUSIGN; i++ )
        {
            testDocuSignListOld[i].dsfs__Case__c = testCase.id;
            if(Math.mod(i,2) == 0) 
                testDocuSignListOld[i].dsfs__Envelope_Status__c = VOID_ENVELOPE_STATUS;
            else
                testDocuSignListOld[i].dsfs__Envelope_Status__c = '';
            testDocuSignListOld[i].Schedule_A_Data__c = allScheduleAData[i].Id;
            
        }
        insert testDocuSignListOld;
        
        for (Integer i = 0; i < NUM_DOCUSIGN; i++ )
        {
            if(Math.mod(i,2) == 0) 
                testDocuSignListOld[i].dsfs__Envelope_Status__c = COMPLETED_ENVELOPE_STATUS;
            else
                testDocuSignListOld[i].dsfs__Envelope_Status__c = COMPLETED_ENVELOPE_STATUS;
        }
        
        Test.startTest();
            update testDocuSignListOld;
        Test.stopTest();
        
        List<Quote> testQuotes = [Select Id, AccountId From Quote Where OpportunityId = :testOpp.Id ];
        //system.assertEquals(NUM_DOCUSIGN, testQuotes.size(),'The total number of quotes created should be correctly calculated');
        
        Set<Id> testQuoteIds = Pluck.ids(testQuotes);
        List<QuoteLineItem> qlis = [SELECT Id, Product2.Id, Quote.OpportunityId, Quantity FROM QuoteLineItem 
        WHERE QuoteId IN :testQuoteIds];
        
        //system.assertEquals(NUM_PROD*(NUM_DOCUSIGN), qlis.size(),'The total number of quote line items created should be correctly calculated');
    }
    static testMethod void DocuSignStatusTriggerEmail()
    {
        setUp();
        //insert DocuSign Status
        dsfs__DocuSign_Status__c DocSign = new dsfs__DocuSign_Status__c();
        DocSign.dsfs__Case__c = testCase.Id;
        DocSign.dsfs__Company__c = testAccount.id;
        DocSign.dsfs__Envelope_Status__c = 'Voided';
        DocSign.dsfs__Sender_Email__c = 'def@ironmoutain.com';
        insert DocSign;
        // update DocuSign Status
        DocSign.dsfs__Envelope_Status__c = 'Completed' ;
        DocSign.dsfs__Sender_Email__c = 'ukiinventoryservices@ironmountain.co.uk';        	
        update DocSign;
        DocSign.dsfs__Sender_Email__c = 'test.email@example.com';
        update DocSign;
    }
}
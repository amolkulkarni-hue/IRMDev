@isTest
public with sharing class SKPIntegrationHelperTest {
    
    public static testMethod void getCasesTest(){
        Account acc = TestingUtils.createAccounts(1, true)[0];
        Opportunity opp = TestingUtils.createOpportunity('testOp', acc.id, true);
        Contact testContact = TestingUtils.createContact(acc.id, true);
        
        List<Case> testCases = TestingUtils.createCases(10, opp, testContact, true);
        
        Test.startTest();
            List<Case> returnedCases = SKPIntegrationHelper.getCases(testCases[0].id);
        Test.stopTest();
        
        System.AssertEquals(1, returnedCases.size(), 'An incorrect number of cases returned');
        System.AssertEquals(testCases[0].id, returnedCases[0].id, 'Incorrect cases returned');
        
        
        
    }
    
    public static testMethod void getMappingsTest(){
        List<SKP_Contract_Type_Mapping__c> mappings = new List<SKP_Contract_Type_Mapping__c>();
        SKP_Contract_Type_Mapping__c expectedMapping = testingUtils.createSkpMappingObject('USA', 'test version', false);
        mappings.add(expectedMapping);
        mappings.add(testingUtils.createSkpMappingObject('Canada', 'test version', false));
        mappings.add(testingUtils.createSkpMappingObject('USA', 'Other version', false));
        
        insert mappings;
        
        Test.startTest();
           List<SKP_Contract_Type_Mapping__c> returnedMappings = SKPIntegrationHelper.getMappings('test version');
        Test.stopTest();
         
        
        System.AssertEquals(1, returnedMappings.size(), 'An incorrect Mapping returned'); 
        System.AssertEquals(expectedMapping.id, returnedMappings[0].id, 'An incorrect Mapping returned');
    }
    
    public static testMethod void insertObjectsTest(){
        
        Account account = TestingUtils.createAccounts(1, true)[0];
        String dummyAccountID = '001000000000000';
        
        Contact contactToCreate = TestingUtils.createContact(account.id, false);
        Contact contactToError = TestingUtils.createContact(dummyAccountID, false);
        
        Test.startTest();
            SKPIntegrationHelper.insertObjects(new List<Sobject>{contactToCreate});
        Test.stopTest();
        
        System.Assert(ApexPages.getMessages().isEmpty(), 'No errors should be returned');
        
        SKPIntegrationHelper.insertObjects(new List<Sobject>{contactToError});
        System.Assert(!ApexPages.getMessages().isEmpty(), 'An invalid cross reference ID error should be returned');
        
        
    }
    
    public static testMethod void upsertObjectsTest(){
        
        Account account = TestingUtils.createAccounts(1, true)[0];
        String dummyAccountID = '001000000000000';
        
        Contact contactToCreate = TestingUtils.createContact(account.id, true);
        Contact contactToError = TestingUtils.createContact(account.id, true);
        
        Test.startTest();
            SKPIntegrationHelper.upsertObjects(new List<Sobject>{contactToCreate});
        Test.stopTest();
        
        System.Assert(ApexPages.getMessages().isEmpty(), 'No errors should be returned');
        
        contactToError.accountid = dummyAccountId;
        SKPIntegrationHelper.upsertObjects(new List<Sobject>{contactToError});
        System.Assert(!ApexPages.getMessages().isEmpty(), 'An invalid cross reference ID error should be returned');
        
        
    }
    public static testMethod void buildRequestTest(){
        
        string endpoint = '/test.com/create';
        string header = 'Basic user:pass';
        string jsonString = '{"userID":"sfc123"}'; 
        
        
        Test.startTest();
            HttpRequest req = SkpIntegrationHelper.buildRequest(endpoint, header, jsonString);
        Test.stopTest();
        
        System.AssertEquals('application/json', req.getHeader('Content-Type'), 'An incorrect content type set');
        System.AssertEquals(header, req.getHeader('Authorization'), 'An authorization type set');
        System.AssertEquals(endpoint, req.getEndpoint(), 'An incorrect endpoint set');
        
        
    }
    
    public static testMethod void getScheduleAsTest(){
        
        Account acc = TestingUtils.createAccounts(1, true)[0];
        Opportunity opp = TestingUtils.createOpportunity('testOpp', acc.id, true);
        
        List<Quote> expectedQuotes = TestingUtils.createQuotes(opp.id, 4, false);
        for(Quote q : expectedQuotes) {
            q.status = 'Accepted';
        }
        insert expectedQuotes;
        
        
        List<Quote> actualQuotes =  new List<Quote>();
        Test.startTest();
            actualQuotes = SkpIntegrationHelper.getScheduleAs(opp.id, new List<String>{'id'});
        Test.stopTest();
        
        System.AssertEquals(4, actualQuotes.size(), 'An incorrect number of quotes returned');
        System.AssertEquals(Pluck.ids(expectedQuotes), Pluck.ids(actualQuotes), 'Incorrect quotes returned');
        
    }
    
    public static testMethod void maxDateTest(){
        
        Date tomorrowDate = Date.today().addDays(1); 
        Date yesterdayDate = Date.today().addDays(-1);
        
        Date returnedDate, returnedDate2, returnedDate3, returnedDate4;
        
        Test.startTest();
            returnedDate = SkpIntegrationHelper.maxDate(tomorrowDate, null);
            returnedDate2 = SkpIntegrationHelper.maxDate(null, yesterdayDate);
            returnedDate3 = SkpIntegrationHelper.maxDate(null, null);
            returnedDate4 = SkpIntegrationHelper.maxDate(tomorrowDate, yesterdayDate);
        Test.stopTest();
        
        System.AssertEquals(tomorrowDate, returnedDate, 'An incorrect max date has been returned');
        System.AssertEquals(yesterdayDate, returnedDate2, 'An incorrect max date has been returned');
        System.AssertEquals(Date.today(), returnedDate3, 'An incorrect max date has been returned');
        System.AssertEquals(tomorrowDate, returnedDate4, 'An incorrect max date has been returned');
        
    }
    
    public static testMethod void billCodeInRangeTest(){
        Test.startTest();
            Boolean expectedTrue = SkpIntegrationHelper.billCodeInRange(100, 250, 100);
            Boolean expectedTrue2 = SkpIntegrationHelper.billCodeInRange(250, 250, 100);
            
            Boolean expectedFalse = SkpIntegrationHelper.billCodeInRange(150, 200, 151);
            Boolean expectedFalse2 = SkpIntegrationHelper.billCodeInRange(201, 200, 100);
        Test.stopTest();
        
        System.Assert(expectedTrue, 'The first billcode should be within the set range.');
        System.Assert(expectedTrue2, 'The second billcode should be within the set range.');
        System.Assert(!expectedFalse, 'The third billcode should not be within the set range.');
        System.Assert(!expectedFalse2, 'The fourth billcode should not be within the set range.');
    }
    
    public static testMethod void CustomerIndicatorTest(){
        
        Account acc = TestingUtils.createAccounts(1, true)[0];
        Opportunity opp = TestingUtils.createOpportunity('Opp', acc.id, true);
        Quote ourQoute = TestingUtils.createQuotes(opp.id, 1, false)[0];
        ourQoute.Pricebook2Id = test.getStandardPriceBookId();
        insert ourQoute;
        
        
        
        Product2 productforShred = TestingUtils.createProduct('1500', false);
        Product2 productforHardCopy = TestingUtils.createProduct('999INIT', false);
        Product2 otherProduct = TestingUtils.createProduct('9999', false);
        insert new List<Product2>{productforShred, ProductForHardcopy, otherProduct};
        
        PriceBookEntry shredPBE = TestingUtils.createPriceBookEntry(productforShred.id, Test.getStandardPricebookId(), false);
        PriceBookEntry hardcopyPBE = TestingUtils.createPriceBookEntry(productforHardCopy.id, Test.getStandardPricebookId(), false);
        PriceBookEntry otherPBE = TestingUtils.createPriceBookEntry(otherProduct.id, Test.getStandardPricebookId(), false);
        insert new List<PricebookEntry>{shredPBE, hardcopyPBE, otherPBE};
        
        QuoteLineItem qliForShred = TestingUtils.createQuoteLineItem(shredPBE.id, ourQoute.id, false);
        QuoteLineItem qliForHardCopy = TestingUtils.createQuoteLineItem(hardcopyPBE.id, ourQoute.id, false);
        QuoteLineItem qliOther = TestingUtils.createQuoteLineItem(otherPBE.id, ourQoute.id, false);
        insert new List<QuoteLineItem> {qliForShred,qliForHardCopy,qliOther};
        
        List<QuoteLineItem> qlis = [Select id, Product_Name__c from QuoteLineItem];
        
        
        SKP_Customer_Indicator_Ranges__c hardCopyRange =  new SKP_Customer_Indicator_Ranges__c(Bill_Code_Minimum__c = 700, Bill_Code_Maximum__c = 999, Customer_Indicator__c = SkpIntegrationHelper.HARDCOPY_NAME, Name = 'test');
        SKP_Customer_Indicator_Ranges__c iodRange =  new SKP_Customer_Indicator_Ranges__c(Bill_Code_Minimum__c = 100, Bill_Code_Maximum__c = 300, Customer_Indicator__c = SkpIntegrationHelper.IOD_NAME, Name = 'test2');
        SKP_Customer_Indicator_Ranges__c shreddingRange = new SKP_Customer_Indicator_Ranges__c(Bill_Code_Minimum__c = 1000, Bill_Code_Maximum__c = 1500, Customer_Indicator__c = SkpIntegrationHelper.SHRED_NAME, Name = 'test3');   
        upsert new List<SKP_Customer_Indicator_Ranges__c> {hardCopyRange, iodRange, ShreddingRange};
        
        
        
        Test.startTest();
            SkpIntegrationHelper.CustomerIndicator indicator = new SkpIntegrationHelper.CustomerIndicator(qlis, 'IM5000T');
        Test.stopTest();
        
        System.Assert(indicator.shred, 'Shred should be enabled in the customer indicator' );
        System.Assert(indicator.hardCopy, 'Hardcopy should be enabled in the customer indicator' );
        System.Assert(!indicator.iod, 'IOD should not be enabled in the customer indicator' );
        System.Assert(!indicator.efs, 'EFS should not be enabled in the customer indicator' );
        
        System.Assert(!indicator.faxtrieval, 'Faxtrieval should not be enabled in the customer indicator' );
        System.Assert(!indicator.vault, 'Vault should not be enabled in the customer indicator' );
        System.Assert(!indicator.xod, 'XOD should not be enabled in the customer indicator' );
        System.Assert(!indicator.openshelf, 'OpenShelf should not be enabled in the customer indicator' );
        
    }
    public static testMethod void findReasonCodeTest(){
         
         QuoteLineItem qliForTest = new QuoteLineItem(Product_Number__c = '1500');
         String testVersion = 'test version';
         SkpIntegrationHelper.CustomerIndicator bundledIndicator = new SkpIntegrationHelper.CustomerIndicator(new List<QuoteLineItem>{qliForTest}, testVersion);
         SkpIntegrationHelper.CustomerIndicator replacementIndicator = new SkpIntegrationHelper.CustomerIndicator(new List<QuoteLineItem>{qliForTest}, testVersion);
         SkpIntegrationHelper.CustomerIndicator applyToMasterIndicator1 = new SkpIntegrationHelper.CustomerIndicator(new List<QuoteLineItem>{qliForTest}, testVersion);
         SkpIntegrationHelper.CustomerIndicator applyToMasterIndicator2 = new SkpIntegrationHelper.CustomerIndicator(new List<QuoteLineItem>{qliForTest}, testVersion);
         SkpIntegrationHelper.CustomerIndicator applyToMasterIndicator3 = new SkpIntegrationHelper.CustomerIndicator(new List<QuoteLineItem>{qliForTest}, testVersion);
         SkpIntegrationHelper.CustomerIndicator minIndicator = new SkpIntegrationHelper.CustomerIndicator(new List<QuoteLineItem>{qliForTest}, testVersion);
         SkpIntegrationHelper.CustomerIndicator dmsIndicator = new SkpIntegrationHelper.CustomerIndicator(new List<QuoteLineItem>{qliForTest}, testVersion);
         SkpIntegrationHelper.CustomerIndicator otherIndicator = new SkpIntegrationHelper.CustomerIndicator(new List<QuoteLineItem>{qliForTest}, testVersion);
         
         Test.startTest();
             bundledIndicator.findReasonCode (true, new Set<Integer>{}, false, false);
             replacementIndicator.findReasonCode (false, new Set<Integer>{890}, false, true);
             
             applyToMasterIndicator1.findReasonCode (false, new Set<Integer>{3476}, true, false);
             applyToMasterIndicator2.findReasonCode (false, new Set<Integer>{3476, 890}, false, false);
             applyToMasterIndicator3.findReasonCode (false, new Set<Integer>{5788}, false, true);
             minIndicator.findReasonCode(false, new Set<Integer>{890, 3475}, false, false);
             dmsIndicator.findReasonCode(false, new Set<Integer>{58}, false, false);
             otherIndicator.findReasonCode(false, new Set<Integer>{}, false, false);
             
         Test.stopTest();
         
         /* System.assert(!bundledIndicator.rmAdminFee,'No Rm Admin fee should be applied to this customer indicator.');
         System.assert(replacementIndicator.rmAdminFee, 'No Rm Admin fee should be applied to this customer indicator.');
         System.assert(applyToMasterIndicator1.rmAdminFee, 'A Rm Admin fee should be applied to this customer indicator.');
         System.assert(applyToMasterIndicator2.rmAdminFee, 'A Rm Admin fee should be applied to this customer indicator.');
         System.assert(applyToMasterIndicator3.rmAdminFee, 'A Rm Admin fee should be applied to this customer indicator.');
         System.assert(!minIndicator.rmAdminFee, 'No Rm Admin fee should be applied to this customer indicator.');
         System.assert(!otherIndicator.rmAdminFee, 'No Rm Admin fee should be applied to this customer indicator.');
         System.assert(!dmsIndicator.rmAdminFee, 'No Rm Admin fee should be applied to this customer indicator.');
         
         System.assertEquals(SkpIntegrationHelper.BUNDLED_PROGRAM, bundledIndicator.reasoncode, 'The reason code should be Bundled Program');
         System.assertEquals('' , replacementIndicator.reasoncode, 'The reason code should be Replacement Value');
         System.assertEquals('' , applyToMasterIndicator1.reasoncode, 'The reason code should be Master Indicator');
         System.assertEquals('' , applyToMasterIndicator2.reasoncode, 'The reason code should be Master Indicator');
         System.assertEquals('' , applyToMasterIndicator3.reasoncode, 'The reason code should be Master Indicator');
         System.assertEquals(SkpIntegrationHelper.MINIMUM_STORAGE_ACCOUNT , minIndicator.reasoncode, 'The reason code should be Min Storage Account');
         System.assertEquals(SkpIntegrationHelper.Shred_ONLY , otherIndicator.reasoncode, 'The reason code should be Shred Only');
         System.assertEquals(SkpIntegrationHelper.DMS_SERVICE_ONLY , dmsIndicator.reasoncode, 'The reason code should be Shred Only');
         */
         
     }
     
     public static testMethod void cleanCountryCodeTest(){
         String canadaString =  'Canada';
         String otherString = 'United States';
         
         String returnedCanadaString, returnedOtherString;
         
         Test.startTest();
             returnedCanadaString = SkpIntegrationHelper.cleanCountryCode(canadaString);
             returnedOtherString = SkpIntegrationHelper.cleanCountryCode(otherString);
         Test.stopTest();
         
         System.AssertEquals('CAN', returnedCanadaString, 'The USA string should not be converted.' );
         System.AssertEquals(otherString, returnedOtherString, 'The USA string should not be converted.' );
     }
     
     public static testMethod void getNextYearDateStringTest(){
         Date janDate = Date.newInstance(2015, 1, 14);
         Date febDate = Date.newInstance(2015, 1, 15);
         
         
         Test.startTest();
             string janDateString = SkpIntegrationHelper.getNextYearDateString(janDate);
             string febDateString =  SkpIntegrationHelper.getNextYearDateString(febDate);
         Test.stopTest();
         
         System.AssertEquals('2016/01/01', janDateString);
         System.AssertEquals('2016/02/01', febDateString);
         
     } 
     
     
     
}
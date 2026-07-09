@isTest
private class SKPIntegrationObjectsTest {

    static testMethod void testSKPResponse_Success_WithResultWarnings() {
        String testResponse =  '{"success": true, "result": {"customerId": "ABC14","contractType": "AR", "exceptionRateId": "EXP01"}, "warnings": [';
               testResponse += '{"code": "WRN11","message": "warning 1"},';
               testResponse += '{"code": "WRN12","message": "warning 2"}], "statusDescription": "The entered contract details are valid"}';
        
        Test.startTest();
            SKPResponse response = (SKPResponse)JSON.deserializeStrict(testResponse, SKPResponse.class);
        Test.stopTest();
        
        System.assertEquals(true, response.success, 'We would expect the success response to be true');
        System.assertEquals('The entered contract details are valid', response.statusDescription, 'Correct value should be set for statusDescription');
        System.assertEquals('ABC14', response.result.customerId, 'Correct value for customerID should be set for result');
        System.assertEquals('AR', response.result.contractType, 'Correct value for contractType should be set for result');
        System.assertEquals('EXP01', response.result.exceptionRateId, 'Correct value for exceptionRateId should be set for result');
        
        System.assert(!response.warnings.isEmpty(), 'We would expect some warnings to be there for the given JSON string');
        
        List<String> codes = new List<String>();
        List<String> messages = new List<String>();
        for(integer i = 0; i < response.warnings.size(); i++) {
            SKPResponse.CodeAndMessage responseCodeMsgObj = response.warnings.get(i);
            codes.add(responseCodeMsgObj.code);
            messages.add(responseCodeMsgObj.message);
        }
        
        System.assertEquals(new List<String>{'WRN11', 'WRN12'}, codes, 'We would expect the codes to be correct');
        System.assertEquals(new List<String>{'warning 1', 'warning 2'}, messages, 'We would expect the messages to be correct');
    }
    
    static testMethod void testSKPResponse_Fail_WithErrors() {
        String testResponse =  '{"success": false, "errors": [';
               testResponse += '{"code": "COM003","message": "contract already exists"},';
               testResponse += '{"code": "COM004","message": "error 2"}], "warnings": null}';
        
        Test.startTest();
            SKPResponse response = (SKPResponse)JSON.deserializeStrict(testResponse, SKPResponse.class);
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'We would expect the success response to be false');
        System.assertEquals(null, response.statusDescription, 'Correct value should be set for statusDescription');
        System.assertEquals(null, response.result, 'Result should be null');
        
        System.assertEquals(null, response.warnings, 'We would expect warnings to be null');
        System.assert(!response.errors.isEmpty(), 'We would expect errors to be present in the JSON response');
        
        List<String> codes = new List<String>();
        List<String> messages = new List<String>();
        for(integer i = 0; i < response.errors.size(); i++) {
            SKPResponse.CodeAndMessage responseCodeMsgObj = response.errors.get(i);
            codes.add(responseCodeMsgObj.code);
            messages.add(responseCodeMsgObj.message);
        }
        
        System.assertEquals(new List<String>{'COM003', 'COM004'}, codes, 'We would expect the codes to be correct');
        System.assertEquals(new List<String>{'contract already exists', 'error 2'}, messages, 'We would expect the messages to be correct');
    }
    
    public static testmethod void SKPContractTest(){
        string BILLCODE = '1100';
        string INIT_BILLCODE = 'INIT1235';
        string INIT_BILLCODE_PAIR = '1235';
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        Contact testContact = TestingUtils.createContact(testAccount.Id, true);
        List<User> testUsers = TestingUtil.createUsers(2, true);
        Opportunity testOpp = TestingUtils.createOpportunity('test_Opp', testAccount.Id, false);
        testOpp.Split_Type__C = '50% / 50%';
        testOpp.Sales_Rep_Percent__c = 50;
        testOpp.Split_Rep_Percent__c = 50;
        insert testOpp;
        
        Map<String, object> additionalProfileValues = new Map<String, object>{};
        Customer_Profile__c profile = TestingUtils.createCustomerProfile (testOpp.id, additionalProfileValues, true);
        
        
        Case skpCase = TestingUtils.createCase(testOpp, testContact, false);
        skpCase.Customer_Profile__c = profile.id;
        skpCase.NCSP_Opportunity__c = testOpp.id;
        skpCase.contract_Type__c = 'IM-Test';
        skpCase.contract_Effective_Date__c = Datetime.now();
        insert skpCase;
        
        
        
        Quote quote = TestingUtils.createQuotes(testOpp.id, 1, false)[0];
        quote.pricebook2id = test.getStandardPriceBookId();
        quote.status = 'Accepted';
        insert quote;
        
        Product2 prod = TestingUtils.createProduct(BILLCODE, false);
        Product2 initProd = TestingUtils.createProduct(INIT_BILLCODE, false);
        Product2 initProdPair = TestingUtils.createProduct(INIT_BILLCODE_PAIR, false);
        prod.IM_Unit_of_Measure__c = initProd.IM_Unit_of_Measure__c = initProdPair.IM_Unit_of_Measure__c = 'Unit of Measure';
        insert new List<Product2>{prod, initProd, initProdPair};
        
        PricebookEntry pbe = TestingUtils.createPriceBookEntry(prod.id, test.getStandardPricebookId(), false);
        PricebookEntry initPbe = TestingUtils.createPriceBookEntry(initProd.id, test.getStandardPricebookId(), false);
        PricebookEntry initPbePair = TestingUtils.createPriceBookEntry(initProdPair.id, test.getStandardPricebookId(), false);
        insert new List<PriceBookEntry>{pbe, initPbe, initPbePair};
        
        QuoteLineItem qli = TestingUtils.createQuoteLineItem(pbe.id, quote.id, false);
        QuoteLineItem initQli = TestingUtils.createQuoteLineItem(initPbe.id, quote.id, false);
        QuoteLineItem initQliPair = TestingUtils.createQuoteLineItem(initPbePair.id, quote.id, false);
        qli.product_Number__C = BILLCODE;
        initQli.product_Number__C = INIT_BILLCODE;
        initQliPair.product_Number__C = INIT_BILLCODE_PAIR;
         
        insert new List<QuoteLineItem>{qli, initQli, initQliPair};
        
        SKP_Minimum_Mapping__c minMapping = TestingUtils.createSKPMinMapping(BILLCODE, true);
        
        SKP_Contract_Type_Mapping__c skpMapping = TestingUtils.createSkpMappingObject('CAN', 'IM-Test', false);
        skpMapping.Excess_Value_of_Deposit__c = 'Value';
        upsert skpMapping;
        
        SKP_Bill_Code_UOM__c uomSetting = new SKP_Bill_Code_UOM__c (Name = 'Unit of Measure', SKP_UOM__c='EA');
        insert uomSetting;
        
        
        quote = SKPIntegrationHelper.getScheduleAs((string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
        
        SKPContract.scaleListObj expectedScaleListObject = new SKPContract.scaleListObj (qli,null);
        expectedScaleListObject.UOM = 'EA';
        expectedScaleListObject.exceptRate = 1.00;
        SKPContract.scaleListObj expectedScaleListObject2 = expectedScaleListObject.clone();
        SKPContract.scaleListObj expectedScaleListObject3 = expectedScaleListObject.clone();
        
        SKPContract.exceptionRateObj expectedExceptionRate1 = new SKPContract.exceptionRateObj();
        SKPContract.exceptionRateObj expectedExceptionRate2 = new SKPContract.exceptionRateObj();
        SKPContract.exceptionRateObj expectedExceptionRate3 = new SKPContract.exceptionRateObj();
        expectedExceptionRate1.districtID =  expectedExceptionRate2.districtID =  expectedExceptionRate3.districtID =  'ALL' ;
        expectedExceptionRate1.billCode =  expectedExceptionRate2.billCode = INIT_BILLCODE_PAIR;
        expectedExceptionRate3.billCode =  BILLCODE;
        expectedExceptionRate1.effectiveDate = Datetime.now().addMonths(3).format('yyyy/MM/dd');
        expectedExceptionRate2.effectiveDate = expectedExceptionRate3.effectiveDate = Datetime.now().format('yyyy/MM/dd'); 
        expectedExceptionRate1.scaleList = expectedScaleListObject;
        expectedExceptionRate2.scaleList = expectedScaleListObject2;
        expectedExceptionRate3.scaleList = expectedScaleListObject3;
         
        skpCase = SkpIntegrationHelper.getCases(skpCase.id)[0];
        
        string testversion = 'testversion';
        SkpIntegrationHelper.CustomerIndicator indicator = new SkpIntegrationHelper.customerIndicator(quote.quoteLineItems, 'testversion');
        
        
        Test.startTest();
           SKPContract contract = new SKPContract(skpCase, quote, skpMapping, indicator, true, 'ABC49', 'ABC Systems',1);
        Test.stopTest(); 
        
        System.AssertEquals(1,contract.AddDetails.contractDetails.minimum.size(), 'An incorrect number of minimums set' );
        System.AssertEquals('ABC49', contract.customerID, 'An incorrect customer ID has been set');
        System.AssertEquals('Value', contract.addDetails.contractDetails.contractSettings.excessValidation, 'An incorrect excess Validation value has been set');
        System.AssertEquals(UserInfo.getUserEmail().substring(0,7), contract.userID, 'An incorrect customer ID has been set');
        
        //System.AssertEquals(3, contract.addDetails.contractDetails.exceptionRateDetail.exceptionRates.size(), 'Incorrect exception rates set');
        
        System.AssertEquals(1, contract.addDetails.contractDetails.salesCommission.size(), 'An incorrect number of commission details created');
        System.AssertEquals(2, contract.addDetails.contractDetails.salesCommission[0].salesDetail.commissionDetails.size(), 'An incorrect number of commission details created');
        
    }
    
    public static testmethod void SKPCustomerTest(){
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        Contact testContact = TestingUtils.createContact(testAccount.Id, true);
        
        Opportunity testOpp = TestingUtils.createOpportunity('test_Opp', testAccount.Id, true);
        
        Map<String, Object> custProfileAdditionalFieldMap = new Map<String, Object>{
                                                                   'Same_as_Service_Address_cor__c'=> false,
                                                                   'Same_as_Billing_Address__c'=> false,
                                                                   'Same_as_Service_Address_cor__c'=> false,
                                                                   'Same_as_Service_Address__c' => false,
                                                                   'Department_Billing_Code__c' => '4 - billingcode',
                                                                   'Remittance_Level__c' => '2 - Remit Level',
                                                                   'Invoice_Delivery_Method__c' =>  '2 - Email Level'
                                                            };
        
        Customer_Profile__c custProfile = TestingUtils.createCustomerProfile(testOpp.id, custProfileAdditionalFieldMap, true);
        Case skpCase = TestingUtils.createCase(testOpp, testContact, false);
        skpCase.Customer_Profile__c = custProfile.id;
        insert skpCase;
        
        Quote quote = TestingUtils.createQuotes(testOpp.id, 1, false)[0];
        quote.pricebook2id = test.getStandardPriceBookId();
        quote.status = 'Accepted';
        insert quote;
        
        
        String testversion = 'test version';
        skpCase = SkpIntegrationHelper.getCases(skpCase.id)[0];
        SkpIntegrationHelper.CustomerIndicator indicator = new SkpIntegrationHelper.customerIndicator(quote.quoteLineItems, testversion);
        
        Test.startTest();
            SKPCustomer customer = new SkpCustomer(skpCase, quote, true, 'TestUser', indicator);
        Test.stopTest();
        
        System.AssertEquals(2, customer.addDetails.customerDetail.billing.remittanceLevel, 'An incorrect remit level has been set');
        System.AssertEquals(4, customer.addDetails.customerDetail.billing.deptBillCode, 'An incorrect bill code has been set');
        System.AssertEquals(UserInfo.getUserEmail().substring(0,7), customer.userId, 'An incorrect user entered');
        System.AssertEquals(3, customer.addDetails.customerDetail.address.size(), 'An incorrect number of addresses created');
    }
}
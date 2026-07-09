@isTest
public with sharing class DocuSignStatusServiceTest {
	
	
	private final static Integer NUM_PROD = 5;
	private final static Integer NUM_DOCUSIGN = 30;
	private final static String COMPLETED_ENVELOPE_STATUS = 'Completed';
	private final static String VOID_ENVELOPE_STATUS = 'Void';
	private static Account testAccount;
	private static Opportunity testOpp;
	
	static Pricebook2 stdpbook{
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
	
	static Pricebook2 testPriceBook{
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
        IM_Country__c cntry = TestingUtil.createIMCountry();
		testAccount = TestingUtils.createAccounts ( 1, true)[0];
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        Id standardPB = Test.getStandardPricebookId();
        testOpp = TestingUtils.createOpportunity('Sample Oppr', testAccount.Id, false);
        testOpp.Source_System__c = 'test SKP Europe';
        testOpp.Billing_Country__c = cntry.id;
        testOpp.Lead_Source_Most_Recent__c = 'x';
        testOpp.StageName = '1 - Qualification';
        testOpp.IM_Servicing_Region__c ='London';
        testOpp.IME_Reason_Won__c = 'Price';
        testOpp.CloseDate = System.today();
        testOpp.CurrencyIsoCode = 'USD';
        testOpp.Lead_Source_Most_Recent__c = 'x';
        testOpp.IM_Booked_Date__c = System.today();
        testOpp.IM_Commit_to_Forecast__c = true;
        testOpp.IM_Stage_5_Entered_Date__c  = System.today();
        testOpp.RecordTypeId = EUOppType.Id;
        testOpp.pricebook2ID= standardPB;
        testOpp.type = 'Price Change';
        
        
        insert testOpp;
        DocuSignStatusService.PRICEBOOK_NORTH_AMERICA = testPriceBook;
	}

	static String generateScheduleAJsonString(Id acctId, Id opptyId,Integer num)
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
        '\"BaseQty\": '+'\"3\",'+
        '\"UnitQty\": '+'\"2\",'+
        '\"BaseAmount\": '+'\"3.06\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '},'+
        '{'+
        '\"Product2\": '+'\"Test Prod2\",'+
        '\"ProductId\": '+'\"'+testProducts[1].Id+'\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"BaseAmount\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"BaseQty\": '+'\"3\",'+
        '\"UnitQty\": '+'\"2\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '},'+
        '{'+
        '\"Product2\": '+'\"Test Prod3\",'+
        '\"ProductId\": '+'\"'+testProducts[2].Id+'\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"BaseAmount\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"BaseQty\": '+'\"3\",'+
        '\"UnitQty\": '+'\"2\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '},'+
        '{'+
        '\"Product2\": '+'\"Test Prod4\",'+
        '\"ProductId\": '+'\"'+testProducts[3].Id+'\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"BaseAmount\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"BaseQty\": '+'\"3\",'+
        '\"UnitQty\": '+'\"2\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '},'
         +'{'+
        '\"Product2\": '+'\"Test Prod5\",'+
        '\"ProductId\": '+'\"'+testProducts[4].Id+'\",'+
        '\"BaseAmount\": '+'\"3.06\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"BaseQty\": '+'\"3\",'+
        '\"UnitQty\": '+'\"2\",'+
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
        	String scheduleAJsonStr = generateScheduleAJsonString(testAccount.Id, testOpp.Id, i);
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
	static testMethod void testfilterDocuSignStatusChanged()
	{
		setUp();
        
		List<dsfs__DocuSign_Status__c> testDocuSignListOld = TestingUtils.createDocusignStatus(testOpp, NUM_DOCUSIGN, false);
		for (Integer i = 0; i < NUM_DOCUSIGN; i++ )
		{
			if(Math.mod(i,2) == 0) 
        		testDocuSignListOld[i].dsfs__Envelope_Status__c = COMPLETED_ENVELOPE_STATUS;
        	else
        		testDocuSignListOld[i].dsfs__Envelope_Status__c = '';
		}
		insert testDocuSignListOld;
		
		List<dsfs__DocuSign_Status__c> testDocuSignListNew = testDocuSignListOld.deepClone(true);
		
		for (Integer i = 0; i < NUM_DOCUSIGN; i++ )
        		testDocuSignListNew[i].dsfs__Envelope_Status__c = COMPLETED_ENVELOPE_STATUS;
        	
       
        Map<Id, dsfs__DocuSign_Status__c> oldMapDocuSignStatus = new Map<Id, dsfs__DocuSign_Status__c>(testDocuSignListOld);
        Test.startTest();
        	List<dsfs__DocuSign_Status__c> results = DocuSignStatusService.filterDocuSignStatusChanged(testDocuSignListNew, oldMapDocuSignStatus);
        Test.stopTest();
        //system.assertEquals(NUM_DOCUSIGN/2, results.size(), 'The docuSign objects with envelope status are filtered out');
        
	}
	
	static testMethod void testRetrieveScheduleAData(){
		setUp();
        
		List<dsfs__DocuSign_Status__c> testDocuSignList = TestingUtils.createDocusignStatus(testOpp, NUM_DOCUSIGN, false);
		List<Schedule_A_Data__c> allScheduleAData = setUpScheduleAData();
		List<Schedule_A_Data__c> expectedScheduleAData = new List<Schedule_A_Data__c>();
		for(Integer i = 0; i < NUM_DOCUSIGN; i++ )
		{
			if(Math.mod(i,2) == 0){
				testDocuSignList[i].Schedule_A_Data__c = allScheduleAData[i].Id;
        		expectedScheduleAData.add(allScheduleAData[i]);
			}	
        	else{
        		testDocuSignList[i].Schedule_A_Data__c = null;
        	}
        		
		}
			
		
		Test.startTest();
        	List<Schedule_A_Data__c> results = DocuSignStatusService.retrieveScheduleAData(testDocuSignList);
        Test.stopTest();
        
        //system.assertEquals(NUM_DOCUSIGN/2, results.size(), 'The correct number of Schedule A Data objects related to the Docusign Sign Status Object are retrieved');
        //system.assertEquals(expectedScheduleAData, results, 'The Schedule A Data objects related to the Docusign Sign Status Object is same as the expected number of Schedule A Data objects');
        
	}
	
/*	static testMethod void testBulkBuildScheduleA()
	{
	    setUp();
        
        List<Schedule_A_Data__c> listOfScheduleAData = setUpScheduleAData();
        
        Test.startTest();
        	DocuSignStatusService.buildScheduleA(listOfScheduleAData);
        Test.stopTest();
        
        List<Quote> testQuotes = [Select Id, AccountId From Quote Where OpportunityId = :testOpp.Id ];
        system.assertEquals(NUM_DOCUSIGN, testQuotes.size(),'The total number of quotes created should be correctly calculated');
        
        Set<Id> testQuoteIds = Pluck.ids(testQuotes);
    	List<QuoteLineItem> qlis = [SELECT Id, Product2.Id, Quote.OpportunityId, Quantity FROM QuoteLineItem 
        WHERE QuoteId IN :testQuoteIds];
        
		
		system.assertEquals(NUM_PROD*NUM_DOCUSIGN, qlis.size(),'The total number of quote line items created should be correctly calculated');
    	
	}
*/
/*	static testMethod void testBuildScheduleAError()
	{
	    setUp();
        
        Product2 testProduct = TestingUtils.createProduct('Test Product', false);
        insert testProduct;
        
        Product2 testProduct1 = TestingUtils.createProduct('Test Product1', false);
        insert testProduct1;
        
        PriceBookEntry testPriceBookEntry = createStandardPricebookEntry(testProduct.Id);
        
        PriceBookEntry testPriceBookEntry1 = createTestPricebookEntry(testProduct.Id);
        
        PriceBookEntry testPriceBookEntry2 = createStandardPricebookEntry(testProduct1.Id);
        
        PriceBookEntry testPriceBookEntry3 = createTestPricebookEntry(testProduct1.Id);
        
        date testDate = date.parse('04/21/2003');
        
         String scheduleAJsonStr = '{'+
        '\"Name\": '+'\"TestQuote'+'\",'+
        '\"Service_Line__c\": '+'\"Record Management\",'+
        '\"\":\"\",'+
        '\"Contract_Length__c\": '+'\"\",'+
        '\"Account\": '+'\"'+testAccount.Id+'\",'+
        '\"Opportunity\": '+'\"'+testOpp.Id+'\",'+
        '\"Effective_Date__c\": '+'\"04212003\"'+
        '}';
        
        String scheduleALineItemJsonStr = '['+'{'+
        '\"Product2\": '+'\"Test Prod1\",'+
        '\"ProductId\": '+'\"'+testProduct.Id+'\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '},'+
        '{'+
        '\"Product2\": '+'\"Test Prod2\",'+
        '\"ProductId\": '+'\"'+testProduct1.Id+'\",'+
        '\"UnitPrice\": '+'\"3.06\",'+
        '\"Quantity\": '+'\"5\",'+
        '\"Unit_of_Measure__c\": '+'\"Cubic feet\"'+
        '}]';
        
        Schedule_A_Data__c  testScheduleData = new Schedule_A_Data__c();
        testScheduleData.Schedule_A__c = scheduleAJsonStr;
        testScheduleData.Schedule_A_Line_Item__c = scheduleALineItemJsonStr;
        testScheduleData.Opportunity__c = testOpp.Id;
        
        Test.startTest();
        	DocuSignStatusService.buildScheduleA(new List<Schedule_A_Data__c>{testScheduleData});
        Test.stopTest();
        
        List<Quote> testQuote = [Select Id, AccountId, Effective_Date__c, Schedule_A_Contract_Length__c  From Quote Where Name = 'TestQuote'];
        system.assertEquals(12,testQuote[0].Schedule_A_Contract_Length__c,'The contract length is set correctly');
        system.assertNotEquals(null,testQuote[0].Id,'On insert the Schedule A Data object, A quote should be created');
        system.assertEquals(testAccount.Id,testQuote[0].AccountId,'On insert the Schedule A Data object, A quote should be created');
        system.assertEquals(testDate,testQuote[0].Effective_Date__c,'On insert the Schedule A object should contain a date in the Effective_Date__c field');
        
    	List<QuoteLineItem> qlis = [SELECT Id, Product2.Id, Quote.OpportunityId, Quantity, UnitPrice FROM QuoteLineItem 
        WHERE Quote.OpportunityId =:testOpp.Id and Quote.Name = 'TestQuote'];
        system.assertEquals(2,qlis.size(),'The size');
    	
	}*/
	
	static testMethod void testProcessDocuSignUpdates()
	{
		setUp();
        List<Schedule_A_Data__c> allScheduleAData = setUpScheduleAData();
		List<dsfs__DocuSign_Status__c> testDocuSignListOld = TestingUtils.createDocusignStatus(testOpp, NUM_DOCUSIGN, false);
		for (Integer i = 0; i < NUM_DOCUSIGN; i++ )
		{
			if(Math.mod(i,2) == 0) 
        		testDocuSignListOld[i].dsfs__Envelope_Status__c = VOID_ENVELOPE_STATUS;
        	else
        		testDocuSignListOld[i].dsfs__Envelope_Status__c = '';
        	testDocuSignListOld[i].Schedule_A_Data__c = allScheduleAData[i].Id;
		}
		insert testDocuSignListOld;
		
		List<dsfs__DocuSign_Status__c> testDocuSignListNew = testDocuSignListOld.deepClone(true);
		
		for (Integer i = 0; i < NUM_DOCUSIGN; i++ )
		{
			if(Math.mod(i,2) == 0) 
        		testDocuSignListNew[i].dsfs__Envelope_Status__c = COMPLETED_ENVELOPE_STATUS;
        	else
        		testDocuSignListNew[i].dsfs__Envelope_Status__c = '';
		}
        Map<Id, dsfs__DocuSign_Status__c> oldMapDocuSignStatus = new Map<Id, dsfs__DocuSign_Status__c>(testDocuSignListOld);
        
         Id standardPB = Test.getStandardPricebookId();
          Quote testScheduleA = TestingUtils.createQuotes(testOpp.id, 1, false)[0];
        testScheduleA.Pricebook2Id = test.getStandardPriceBookId();
        insert testScheduleA;
        
        Product2 productforShred = TestingUtils.createProduct('1500', true);
        
         PriceBookEntry shredPBE = TestingUtils.createPriceBookEntry(productforShred.id, standardPB, true);
        
         QuoteLineItem qliForShred = TestingUtils.createQuoteLineItem(shredPBE.id, testScheduleA.id, true);
        
        
        Test.startTest();
        	DocuSignStatusService.processDocuSignUpdates(testDocuSignListNew , oldMapDocuSignStatus);
        
        
        
        List<Quote> testQuotes = [Select Id, AccountId From Quote Where OpportunityId = :testOpp.Id ];
       
        Set<Id> testQuoteIds = Pluck.ids(testQuotes);
    	List<QuoteLineItem> qlis = [SELECT Id, Product2.Id, Quote.OpportunityId, Quantity FROM QuoteLineItem 
        WHERE QuoteId IN :testQuoteIds];
		DocuSignStatusService.updateQuotesLineItems(qlis);
        Test.stopTest();
         system.assertEquals(NUM_DOCUSIGN/2 + 1, testQuotes.size(),'The total number of quotes created should be correctly calculated');
        
		//system.assertEquals(NUM_PROD*(NUM_DOCUSIGN/2) + 1, qlis.size(),'The total number of quote line items created should be correctly calculated');
	}
	
}
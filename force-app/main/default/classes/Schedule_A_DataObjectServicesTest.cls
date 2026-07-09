@isTest
public with sharing class Schedule_A_DataObjectServicesTest {
    
    @testSetup
    static void setupData() {
        // Create Pricebook
        Pricebook2 pb = new Pricebook2(Name = 'North America', IsActive = true);
        insert pb;

        // Assign to static var (simulates setter logic)
        Schedule_A_DataObjectServices.PRICEBOOK_NORTH_AMERICA = pb;

        // Create Product and PricebookEntry
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        // Insert standard PricebookEntry (required)
Id standardPbId = Test.getStandardPricebookId();
PricebookEntry stdEntry = new PricebookEntry(
    Product2Id = prod.Id,
    Pricebook2Id = standardPbId,
    UnitPrice = 100,
    IsActive = true
);
insert stdEntry;

   PricebookEntry customEntry = new PricebookEntry(
    Product2Id = prod.Id,
    Pricebook2Id = pb.Id,
    UnitPrice = 100,
    IsActive = true
);
insert customEntry;
        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = new IM_Country__c(Name='United Kingdom',Region__c='Europe');
        insert retCountry;  
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry;
       Test.startTest();
        Account account = new Account(
        Name = 'Test Account',
        ShippingCity = 'London',
        ShippingState = 'England',
        ShippingPostalCode = 'SW1A 1AA',
        ShippingCountry = 'United Kingdom',
        BillingCity = 'London',            
        BillingState = 'England',
        BillingPostalCode = 'SW1A 1AA',
        BillingCountry = 'United Kingdom',
        QTB_Legal_Entity_Country__c = 'United Kingdom'  
    );
    insert account;

        // Create Opportunity
        Opportunity insOpp = new Opportunity();
        insOpp.name = 'testOpp';
        insOpp.AccountId = account.id;
        insOpp.CloseDate = Date.today();
        insOpp.StageName = '1 - Qualification';
        insOpp.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        insOpp.Amount = 500;
        //insOpp.Pricebook2Id=pricebookId;
        insert insOpp;

        // Create DocuSign Status
        dsfs__DocuSign_Status__c dStatus = new dsfs__DocuSign_Status__c(
            dsfs__Opportunity__c = insOpp.Id,
            dsfs__Envelope_Status__c = 'Completed'
        );
        insert dStatus;

        // Prepare Schedule A Data JSON
        String scheduleAJSON = JSON.serialize(new Map<String, Object>{
            'Opportunity' => insOpp.Id,
             'Effective_Date__c' => '2025-01-31',
            'Name' => 'Schedule A Quote',
            'Service_Line__c' => 'Consulting',
            'Contract_Length__c' => '12'
        });

        List<Schedule_A_DataObjectServices.ScheduleALineItemWrapper> lineItems = new List<Schedule_A_DataObjectServices.ScheduleALineItemWrapper>();
        Schedule_A_DataObjectServices.ScheduleALineItemWrapper lineItem = new Schedule_A_DataObjectServices.ScheduleALineItemWrapper();
        lineItem.ProductId = prod.Id;
        lineItem.UnitPrice = '100.00';
        lineItem.Quantity = '2';
        lineItem.BaseQty = '1';
        lineItem.BaseAmount = '100.00';
        lineItem.UnitQty = '2';
        lineItem.UnitRate = '50.00';
        lineItems.add(lineItem);

        String lineItemJSON = JSON.serialize(lineItems);

        // Create Schedule_A_Data__c
        Schedule_A_Data__c schedData = new Schedule_A_Data__c(
            Schedule_A__c = scheduleAJSON,
            Schedule_A_Line_Item__c = lineItemJSON
        );
        insert schedData;
    }

    @isTest
    static void testBuildScheduleA() {
        List<Schedule_A_Data__c> schedDataList = [SELECT Id, Schedule_A__c, Schedule_A_Line_Item__c FROM Schedule_A_Data__c];
        
        Test.startTest();
        Schedule_A_DataObjectServices.buildScheduleA(schedDataList);
        Test.stopTest();

        // Assert that quote was inserted
        List<Quote> insertedQuotes = [SELECT Id, Name, Effective_Date__c FROM Quote];
        System.assertEquals(1, insertedQuotes.size(), 'One Quote should have been inserted.');

        // Assert that quote line items were inserted
        List<QuoteLineItem> insertedQLIs = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem];
        System.assertEquals(1, insertedQLIs.size(), 'One QuoteLineItem should have been inserted.');
        System.assertEquals(100.00, insertedQLIs[0].UnitPrice);
        System.assertEquals(2, insertedQLIs[0].Quantity);
    }

    @isTest
    static void testCovertStringToDate() {
        Test.startTest();

        // Test date conversion from string
        String dateStr = '05052025'; // Format MMDDYYYY
        Date convertedDate = Schedule_A_DataObjectServices.covertStringToDate(dateStr);

        // Assert that the date is correctly converted
        System.assertEquals(convertedDate, Date.newInstance(2025, 5, 5), 'Date conversion should work as expected');

        Test.stopTest();
    }
}
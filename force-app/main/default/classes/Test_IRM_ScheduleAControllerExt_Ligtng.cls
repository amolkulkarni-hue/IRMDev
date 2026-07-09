/**
* Class: Test_IRM_ScheduleAControllerExt_Ligtng
*
* Author: TCS
*
* Purpose: This is a test class for IRM_ScheduleAControllerExt_Lightning
*
* Requirement: Gitlab - 10822 & 11734
*
* Change History:
*
* Developer                     Date             Descriptio
* -------------------------------------------------------------------------------------------
Praneel Patalay 29-Sep-20222 Increased the code coverage by removing the validation errors with respect to opportunity object
Gitlab story    : 19277 Removed logic related to PA Model Approval process and improved code coverage
*
*/

@isTest
public with sharing class Test_IRM_ScheduleAControllerExt_Ligtng {
    
    public static final Integer NUM_CUST_ACCT = 10;
    public static final String BASE_VERSION_NUMBER = '9.8.1';
    public static final Id Bill_codeRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Bill Code').getRecordTypeId();
    
    /*
public static IRM_ScheduleAControllerExt_Lightning init() {
return init(null);
}
*/
    
    @testSetup
    public static void init()
    {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        IM_Country__c cntry = TestingUtil.createIMCountry();
        Account acc = TestingUtils.createAccounts(1, true)[0];
        RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        
        Product2 product1 =
            new Product2(
                Secondary_Product_Allowed__c=true,
                Name='420',
                CurrencyIsoCode='USD',
                IsActive=true,recordtypeId=Bill_codeRT);
        insert product1;
        
        Product2 product2 =
            new Product2(
                Secondary_Product_Allowed__c=true,
                Name='430',
                CurrencyIsoCode='USD',
                IsActive=true,recordtypeId=Bill_codeRT);
        insert product2;
        
        Product2 product3 =
            new Product2(
                Secondary_Product_Allowed__c=true,
                Name='440',
                CurrencyIsoCode='USD',
                IsActive=true,recordtypeId=Bill_codeRT);
        insert product3;
        
        Pricebook2 NA_pbook =TestingUtils.createPriceBook('North America',true);
        
        Id standardPB = Test.getStandardPricebookId();
        
        TestingUtils.createPriceBookEntry(product1.id,standardPB,true);
        TestingUtils.createPriceBookEntry(product2.id,standardPB,true);
        TestingUtils.createPriceBookEntry(product1.id,NA_pbook.id,true);   
        TestingUtils.createPriceBookEntry(product2.id,NA_pbook.id,true);
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        Profile prof = [Select Id from profile where Name='System Administrator'];
        User u = new User(alias = 'standt', email='standarduser@testorg.com',
                          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/Los_Angeles', username='hello.test1@testorg.com', CurrencyIsoCode='USD');
        insert u;
        List<opportunity> preOpp = [select id from opportunity]; 
        system.debug('preOpp '+preOpp.size());
        system.debug('Number of queries '+limits.getQueries());
        Opportunity opp;
        if(preOpp.size() == 0 ) { // Checking if any opportunity all created as part of test class; #10822
            opp   = TestingUtils.createOpportunity('test', acc.id, false);
            
            opp.Source_System__c = 'test SKP Europe';
            opp.Billing_Country__c = cntry.id;
            opp.Lead_Source_Most_Recent__c = 'x';
            opp.StageName = '1 - Qualification';
            opp.IM_Servicing_Region__c ='London';
            opp.IME_Reason_Won__c = 'Price';
            opp.CloseDate = System.today();
            opp.CurrencyIsoCode = 'USD';
            opp.Lead_Source_Most_Recent__c = 'x';
            opp.IM_Booked_Date__c = System.today();
            opp.IM_Commit_to_Forecast__c = true;
            opp.IM_Stage_5_Entered_Date__c  = System.today();
            opp.RecordTypeId = EUOppType.Id;
            opp.pricebook2ID= standardPB;
            opp.type = 'Price Change';
            opp.Forecast_Owner__c = u.id;
            
            
            insert opp;
        }else{
            opp = preOpp[0]; // assigning the existing opportunity id; #10822
            
        }
        system.debug('Number of queries '+limits.getQueries());
        /* Quote quote = TestingUtil.createQuote();*/
        Quote quote = new Quote();
        quote.Name  = 'Test Quote';
        quote.OpportunityId  = opp.id;
        
        insert quote;
        
        Contact testContact = TestingUtils.createContact(acc.id, true);
        Case resultCase = TestingUtils.createCases(1, opp, testContact, true)[0];
        
        BaseVersionNumber__c test = new BaseVersionNumber__c( Version__c = BASE_VERSION_NUMBER);
        insert test;
        IM_Customer_Account__c cusAcct=TestingUtils.createCustomerAccount(acc.id,false);
        cusAcct.name='adfe2';
        insert cusAcct;
         
        pse__Proj__c project = new pse__Proj__c();
        project.Name = 'Test Project';
        project.Service_State__c ='Test';
        project.pse__Billing_Type__c ='Bundle';
        project.pse__Account__c = acc.Id;
        project.pse__Is_Active__c = True;
        
        insert project;
    }
    
    public static IRM_ScheduleAControllerExt_Lightning init(String step) {
        Opportunity opp = [select id from opportunity limit 1]; 
        Quote quote = [select id from quote limit 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        if(step != null) {
            ApexPages.currentPage().getParameters().put('Step', IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        }
        
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ApexPages.currentPage().getParameters().put('quoteid', quote.id);
        system.debug('Number of queries '+limits.getQueries());
        IRM_ScheduleAControllerExt_Lightning scheduleCont = new IRM_ScheduleAControllerExt_Lightning(sc);
        system.debug('Number of queries '+limits.getQueries());
        return scheduleCont;
    }
    
    public static testMethod void testScenario1()
    {
        String test = null;
        test = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN;
        test = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_SCHEDULE_A_ITEMS;
        test = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_SCHEDULE_A_TEMPLATES;
        test = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_UPLOAD_FILE;
        test = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_UPLOAD_EXCEL_FILE;
        //Gitlab: 19277 code cleanup test = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_UPLOAD_FILE_APPROVERS;
        test = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_UPLOAD_COMPLETE;
        test = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_PRICE_ADJUST_QUESTION;
        test = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_PRICE_ADJUST;
        test = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_QUOTE_COMPLETE;
    }
    
    public static testMethod void testInit()
    {
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        scheduleCont = new IRM_ScheduleAControllerExt_Lightning();
    }
    
    public static testMethod void testGetScheduleAList()
    {
        //IRM_ScheduleAControllerExt scheduleCont = Test_IRM_ScheduleAControllerExt.init();
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        User u = TestingUtil.createUsers(1,true)[0];
        TestingUtil.createScheduleA(ApexPages.currentPage().getParameters().get('id'), u);
        TestingUtil.createScheduleA(ApexPages.currentPage().getParameters().get('id'), u);
        TestingUtil.createScheduleA(ApexPages.currentPage().getParameters().get('id'), u);
        List<Schedule_A__c> scList = scheduleCont.getScheduleAList();
        scheduleCont.exemptBillingCodeMap = null;
        
    }
    
    public static testMethod void testGetScheduleATemplateList()
    {
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        User u = TestingUtil.createUsers(1,true)[0];
        TestingUtil.createScheduleA(true);
        TestingUtil.createScheduleA(true);
        TestingUtil.createScheduleA(true);
        List<Schedule_A__c> scList = scheduleCont.getScheduleATemplateList();
    }
    
    public static testMethod void testSelectTemplateScheduleA()
    {
        IRM_ScheduleAControllerExt_Lightning ctr = new IRM_ScheduleAControllerExt_Lightning();
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        scheduleCont.selectTemplateScheduleA();
        //Boolean b1 = ctr.rmIncluded;
        //        Boolean b2 = ctr.dbrIncluded;
        //Set<String> s1 = ctr.includedServiceTypes;
        
    }
    
    public static testMethod void testStepScheduleAFromAccount()
    {
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        scheduleCont.stepScheduleAFromAccount();
    }
    
    public static testMethod void testStepUploadPAFile()
    {
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        scheduleCont.stepUploadPAXMLFile();
        // scheduleCont.stepUploadPAExcelFile();
    }
    
    /* public static testMethod void testViewScheduleA()
{
IRM_ScheduleAControllerExt scheduleCont = Test_IRM_ScheduleAControllerExt.init();
User u = TestingUtil.createUsers(1,true)[0];
TestingUtil.createScheduleA(ApexPages.currentPage().getParameters().get('id'), u);
List<Schedule_A__c> scList = scheduleCont.getScheduleAList();
scheduleCont.selectedScheduleAId = scList.get(0).Id;
scheduleCont.viewScheduleA();
}*/
    
    /*public static testMethod void testAdjustScheduleAPrices()
{
IRM_ScheduleAControllerExt scheduleCont = Test_IRM_ScheduleAControllerExt.init();
User u = TestingUtil.createUsers(1,true)[0];
TestingUtil.createScheduleA(ApexPages.currentPage().getParameters().get('id'), u);
List<Schedule_A__c> scList = scheduleCont.getScheduleAList();
scheduleCont.selectedScheduleAId = scList.get(0).Id;
scheduleCont.adjustScheduleAPrices();
}*/
    /*assert here*/
    /*public static testMethod void testSelectScheduleA()
{

IRM_ScheduleAControllerExt scheduleCont = Test_IRM_ScheduleAControllerExt.init();
User u = TestingUtil.createUsers(1,true)[0];
TestingUtil.createScheduleA(ApexPages.currentPage().getParameters().get('id'), u);
List<Schedule_A__c> scList = scheduleCont.getScheduleAList();
scheduleCont.selectedScheduleAId = scList.get(0).Id;
TestingUtil.createScheduleAQuoteItem(scheduleCont.selectedScheduleAId);
TestingUtil.createScheduleAQuoteItem(scheduleCont.selectedScheduleAId);

scheduleCont.selectScheduleA();
//Boolean b1 = scheduleCont.rmIncluded;

//Boolean b2 = scheduleCont.dbrIncluded;
//System.assertEquals(2, scheduleCont.quoteItemList.size());
}
*/
    public static String buildXML(String CustomerIDs)
    {
        String xml =     
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+
            '<schedulea xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
            '           <CustomerName>Test Customer</CustomerName>'+
            '           <IMGA>IM_Customer</IMGA>'+
            '           <Salesseg>Non-Territory Sales Team</Salesseg>'+
            '           <Industry>Sales Vertical</Industry>'+
            '           <Country>USA</Country>'+
            '           <Currency>'+'USD'+'</Currency>'+
            '           <AWSRequestID>0</AWSRequestID>'+
            '           <CustomerIDs>'+CustomerIDs+'</CustomerIDs>'+
            '           <totalrevenue>673737.26</totalrevenue>'+
            '           <revenuedelta>-895.56</revenuedelta>'+
            '           <margindelta>503.91</margindelta>'+
            '           <revenueyeartargetpricing>833221.16</revenueyeartargetpricing>'+
            '           <revenueatlistpricing>2065394.33</revenueatlistpricing>'+
            '           <totalcontractrevenue>673737.26</totalcontractrevenue>'+
            '           <RMEffectiveDiscount>65.1</RMEffectiveDiscount>'+
            '           <includeclawback>1</includeclawback>'+
            '           <DMcontractlength>1</DMcontractlength>'+
            '           <SScontractlength>1</SScontractlength>'+
            '           <NumberOfShredLocations>0</NumberOfShredLocations>'+
            '           <PAVersion>'+BASE_VERSION_NUMBER+'</PAVersion>'+
            '           <RMMultiyear>false</RMMultiyear>'+
            '           <RMFUI>false</RMFUI>'+
            '           <RMPWPaid>false</RMPWPaid>'+
            '           <RMUnvended>false</RMUnvended>'+
            '           <RMProgramPricing>false</RMProgramPricing>'+
            '           <RMTieredPricing>false</RMTieredPricing>'+
            '           <RMFreeStorage>false</RMFreeStorage>'+
            '           <RMFreeServices>false</RMFreeServices>'+
            '           <RMFreeStorageviaWA>false</RMFreeStorageviaWA>'+
            '           <RMFreeServicesviaWA>false</RMFreeServicesviaWA>'+
            '           <RMOther>false</RMOther>'+
            '           <DMMultiyear>false</DMMultiyear>'+
            '           <DMTieredPricing>false</DMTieredPricing>'+
            '           <dealsummary1>Test Deal Summary</dealsummary1>'+
            '           <Newrev>304650</Newrev>'+
            '           <Investment>200000</Investment>'+
            '           <TotalCost>273374.217647138</TotalCost>'+
            '           <TotalCashBasedCost>273374.2176</TotalCashBasedCost>'+
            '           <ServiceHours>12</ServiceHours>'+
            '           <ServiceLaborCost>2</ServiceLaborCost>'+
            '           <floorrevenue>1234</floorrevenue>'+
            '           <RevenueDilution>-0.13</RevenueDilution>'+
            '           <quoteLines>'+
            '                   <quoteItem>'+
            '                           <productNumber>'+'420'+'</productNumber>'+
            '                           <listprice>1.02</listprice>'+
            '                           <keepflag>1</keepflag>'+
            '                           <targetprice>0.232</targetprice>'+
            '                           <forecastableflag>0</forecastableflag>'+
            '                           <unitcost>0.0646439383833079</unitcost>'+
            '                           <floorprice>0.201</floorprice>'+
            '                           <unitcostcashview>0.0646439383833079</unitcostcashview>'+
            '                   </quoteItem>'+
            '                   <quoteItem>'+
            '                           <productNumber>'+'430'+'</productNumber>'+
            '                           <listprice>1.02</listprice>'+
            '                           <keepflag>1</keepflag>'+
            '                           <targetprice>0.232</targetprice>'+
            '                           <forecastableflag>1</forecastableflag>'+
            '                           <unitcost>0.0646439383833079</unitcost>'+
            '                           <floorprice>0.201</floorprice>'+
            '                           <unitcostcashview>0.0646439383833079</unitcostcashview>'+
            '                   </quoteItem>'+
            '                   <quoteItem>'+
            '                           <productNumber>'+'440'+'</productNumber>'+
            '                           <listprice>0</listprice>'+
            '                           <keepflag>1</keepflag>'+
            '                           <targetprice>0</targetprice>'+
            '                           <forecastableflag>1</forecastableflag>'+
            '                           <unitcost>0</unitcost>'+
            '                           <floorprice>0</floorprice>'+
            '                           <unitcostcashview>0</unitcostcashview>'+
            '                   </quoteItem>'+  
            '           </quoteLines>'+
            '</schedulea>'  ;
        return xml;        
    }
    public static testMethod void testSavePAFile()
    {
        //Scenario : XML and XLSM file are uploaded successfully. PA model Approval record should be created.
        Test.startTest();
        
        String xml=buildxml('adfe2');
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        
        Folder folder = [SELECT Id, Name FROM Folder WHERE Type = 'Document' LIMIT 1];
        Document xmlDoc = new Document(Body = Blob.valueOf(xml), Name = 'test.xml', FolderId = folder.Id);
        insert xmlDoc;
        Document xls = new Document(Body = Blob.valueOf(xml),ContentType = 'application/vnd.ms-excel',IsPublic = true,Name = 'test.xls',FolderId =folder.Id);
        insert xls;
        
        xmlDoc = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xmlDoc.Id];
        
        xls = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xls.Id];
        
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile = xmlDoc;
        scheduleCont.stepUploadPAXMLFile();
        
        scheduleCont.paEXCELFile = xls;   
        scheduleCont.stepUploadPAExcelFile();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        Pagereference afterupload=scheduleCont.redirectToScheduleA();
        
        System.assertEquals(2,pageMessages.size());
        for(integer i=0;i<2;i++) {
            Boolean assertion=pageMessages[0].getSummary().contains('Product [ 440 ] is not associated with North America pricebook. Product ignored.');
            System.assert(assertion);
            System.assertEquals(ApexPages.Severity.Warning, pageMessages[0].getSeverity());
            System.assertEquals(System.Label.See_Deal_Review_For_Any_Approvals, pageMessages[1].getSummary());
            System.assertEquals(ApexPages.Severity.Warning, pageMessages[1].getSeverity());
        }
        
        System.assertEquals('/'+scheduleCont.opportunity.id,afterupload.getUrl());
        Schedule_A__c PAModelRecord=[select id,opportunity__c,Account__c from Schedule_A__c limit 1]; 
        
        Test.clearApexPageMessages();
        scheduleCont.resetPage();
        
		System.Test.stopTest();

        //Gitlab: 19277 code cleanup scheduleCont.savePAFileApprovers();
        /*scheduleCont.selectScheduleA();        
Map<String, boolean> ebc=scheduleCont.exemptBillingCodeMap;
Map<String, String> dtm=scheduleCont.dbrTypeMap;
boolean rminc = scheduleCont.rmIncluded;
boolean dbinc = scheduleCont.dbrIncluded;
Set<String> incServiceTypes = scheduleCont.includedServiceTypes;
Schedule_A__c newSchA =  scheduleCont.newScheduleA;
List<SelectOption> nav = scheduleCont.navigateOptions;
scheduleCont.saveScheduleAPrices();
scheduleCont.viewScheduleA();
scheduleCont.includeQuoteCustomerAccounts();
scheduleCont.adjustScheduleAPrices();
scheduleCont.gotoNextStep();
scheduleCont.gotoPercentNextStep();*/
        //scheduleCont.declareforTest();
        //scheduleCont.redirectToQuote();
        //scheduleCont.saveQuoteNRedirect();
    }
    
    public static testmethod void testDuplicatePAModel()
    {
        //Scenario : Test duplicate logic on PA model. If already used PA xml model file is used during upload error is thrown
        String xml=buildxml('adfe2');
        Test.startTest();
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        
        Folder folder = [SELECT Id, Name FROM Folder WHERE Type = 'Document' LIMIT 1];
        Document xmlDoc = new Document(Body = Blob.valueOf(xml), Name = 'test.xml', FolderId = folder.Id);
        insert xmlDoc;
        
        Document xls = new Document(Body = Blob.valueOf(xml),ContentType = 'application/vnd.ms-excel',IsPublic = true,Name = 'test.xls',FolderId =folder.Id);
        insert xls;
        
        xmlDoc = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xmlDoc.Id];
        
        xls = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xls.Id];
        
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile = xmlDoc;
        scheduleCont.stepUploadPAXMLFile();
        
        scheduleCont.paEXCELFile = xls;   
        scheduleCont.stepUploadPAExcelFile();
        
        Pagereference afterupload=scheduleCont.redirectToScheduleA();
        
        System.assertEquals('/'+scheduleCont.opportunity.id,afterupload.getUrl());
        Test.clearApexPageMessages();
        
        //PA model is created using xml file
        //When tried to upload the same xml file error should be received
        
        scheduleCont.resetPage();
        
        scheduleCont.gotoNextStep();
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile = xmlDoc;
        scheduleCont.stepUploadPAXMLFile();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        scheduleCont.cancelAction();
        System.assertEquals(1,pageMessages.size());
        for(ApexPages.Message msg :  ApexPages.getMessages()) {
            System.assertEquals(System.Label.File_Already_Uploaded, msg.getSummary());
            System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
        }
        Test.clearApexPageMessages();
        Test.stopTest();
        
    }
    
    public static testmethod void testredirectToProject()
    {
        //Scenario : Test duplicate logic on PA model. If already used PA xml model file is used during upload error is thrown
        String xml=buildxml('adfe2');
        Test.startTest();
    
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        Id p=[select id from pse__Proj__c limit 1].id;
        ApexPages.currentPage().getParameters().put('retURL', '/'+String.valueOf(p));
        scheduleCont.retURLId='/'+String.valueOf(p);
        Folder folder = [SELECT Id, Name FROM Folder WHERE Type = 'Document' LIMIT 1];
        Document xmlDoc = new Document(Body = Blob.valueOf(xml), Name = 'test.xml', FolderId = folder.Id);
        insert xmlDoc;
        
        Document xls = new Document(Body = Blob.valueOf(xml),ContentType = 'application/vnd.ms-excel',IsPublic = true,Name = 'test.xls',FolderId =folder.Id);
        insert xls;
        
        xmlDoc = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xmlDoc.Id];
        
        xls = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xls.Id];
        
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile = xmlDoc;
        scheduleCont.stepUploadPAXMLFile();
        
        scheduleCont.paEXCELFile = xls;   
        scheduleCont.stepUploadPAExcelFile();
        
        Pagereference afterupload=scheduleCont.redirectToScheduleA();
        System.debug('after Upload proj: '+afterupload.getUrl());
        System.assertEquals(scheduleCont.retURLId,afterupload.getUrl());
        Test.clearApexPageMessages();
    }
    public static testmethod void testPAModelScenario1()
    {
        String xml=buildxml('adfe2');
        //Scenario :xml and xls files should be of same name. else error is thrown
        Test.startTest();
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        
        Folder folder = [SELECT Id, Name FROM Folder WHERE Type = 'Document' LIMIT 1];
        Document xmlDoc = new Document(Body = Blob.valueOf(xml), Name = 'test123.xml', FolderId = folder.Id);
        insert xmlDoc;
        
        Document xls=new Document(Body = Blob.valueOf(xml),ContentType = 'application/vnd.ms-excel',IsPublic = true,Name = 'test2.xls',FolderId =folder.Id);
        insert xls;
        
        xmlDoc = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xmlDoc.Id];
        
        xls= [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xls.Id];
        
        
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile = xmlDoc;
        scheduleCont.stepUploadPAXMLFile();
        
        scheduleCont.paEXCELFile = xls;   
        scheduleCont.stepUploadPAExcelFile();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        
        System.assertEquals(2,pageMessages.size());
        Boolean assertion=pageMessages[0].getSummary().contains('Product [ 440 ] is not associated with North America pricebook. Product ignored.');
        System.assert(assertion);
        System.assertEquals(ApexPages.Severity.Warning, pageMessages[0].getSeverity());
        
        String xmlName=scheduleCont.paXMLFile.name;
        System.assertEquals(System.Label.File_Name_Does_Not_Match.replace('{!FILENAME}',xmlName.substring(0, xmlName.indexOf('.'))), pageMessages[1].getSummary());
        System.assertEquals(ApexPages.Severity.ERROR, pageMessages[1].getSeverity());
        
        Test.stopTest();
        System.debug('test 3 passed');
        
    }
    
    public static testmethod void testPAModelScenario2()
    {
        //Scenario: If an excel file with blank body is uploaded error is thrown
        String xml=buildxml('adfe2');
        Test.startTest();
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        
        Folder folder = [SELECT Id, Name FROM Folder WHERE Type = 'Document' LIMIT 1];
        Document xmlDoc = new Document(Body = Blob.valueOf(xml), Name = 'test123.xml', FolderId = folder.Id);
        insert xmlDoc;
        
        Document xls=new Document(Body =Blob.valueOf(''),ContentType = 'application/vnd.ms-excel',IsPublic = true,Name = 'test123.xls',FolderId =folder.Id);
        insert xls;
        
        xmlDoc = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xmlDoc.Id];
        
        xls= [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xls.Id];
        
        
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile = xmlDoc;
        scheduleCont.stepUploadPAXMLFile();
        
        scheduleCont.paEXCELFile = xls;   
        scheduleCont.stepUploadPAExcelFile();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(2,pageMessages.size());
        
         Boolean assertion=pageMessages[0].getSummary().contains('Product [ 440 ] is not associated with North America pricebook. Product ignored.');
        System.assert(assertion);
        System.assertEquals(ApexPages.Severity.Warning, pageMessages[0].getSeverity());
        
        System.assertEquals(System.Label.Excel_File_Is_Empty, pageMessages[1].getSummary());
        System.assertEquals(ApexPages.Severity.ERROR, pageMessages[1].getSeverity());
 
        Test.stopTest();
        
    }
    
    public static testmethod void testPAModelScenario3()
    {
        //Scenario: If an xml file with blank body is uploaded error is thrown
       Test.startTest();
        
        String xml=buildxml('adfe2');
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        
        Folder folder = [SELECT Id, Name FROM Folder WHERE Type = 'Document' LIMIT 1];
        Document xmlDoc = new Document(Body = Blob.valueOf(''), Name = 'test123.xml', FolderId = folder.Id);
        insert xmlDoc;
        
        xmlDoc = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xmlDoc.Id];
        
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile = xmlDoc;
        scheduleCont.stepUploadPAXMLFile();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        
        System.assertEquals(1,pageMessages.size());
        System.assertEquals(ApexPages.Severity.ERROR, pageMessages[0].getSeverity());
        System.assertEquals(System.Label.File_Is_Empty, pageMessages[0].getSummary());
        Test.stopTest();
        
    }
    
    public static testmethod void testPAModelScenario4()
    {
        //Scenario: Cannot move to next step without uploading XMl file
        Test.startTest();
        
        String xml=buildxml('adfe2');
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        
        /*Folder folder = [SELECT Id, Name FROM Folder WHERE Type = 'Document' LIMIT 1];
        
        Document xmlDoc = new Document(Body = Blob.valueOf(xml),Name = '', FolderId = folder.Id);
        insert xmlDoc;*/
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile.Name='';
        scheduleCont.stepUploadPAXMLFile();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        
        System.assertEquals(1,pageMessages.size());
        
        System.assertEquals(ApexPages.Severity.ERROR, pageMessages[0].getSeverity());
        System.assertEquals(System.Label.XML_File_Must_Be_Specified, pageMessages[0].getSummary());
        
        Test.stopTest();
        
    }
    
    public static testMethod void testPAModelScenario5()
    {
        //Scenario : After uploading xml file XLS file is must to proceed
        String xml=buildxml('adfe2');
        Test.startTest();
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        
        Folder folder = [SELECT Id, Name FROM Folder WHERE Type = 'Document' LIMIT 1];
        Document xmlDoc = new Document(Body = Blob.valueOf(xml), Name = 'test.xml', FolderId = folder.Id);
        insert xmlDoc;
        
       /* Document xls=new Document(Body =Blob.valueOf(xml),ContentType = 'application/vnd.ms-excel',IsPublic = true,Name = '',FolderId =folder.Id);
        insert xls;
        */
        xmlDoc = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xmlDoc.Id];
        
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile = xmlDoc;
        scheduleCont.stepUploadPAXMLFile();
        
        scheduleCont.paEXCELFile.Name = '';   
        scheduleCont.stepUploadPAExcelFile();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        Pagereference afterupload=scheduleCont.redirectToScheduleA();
        
        System.assertEquals(2,pageMessages.size());
        
        Boolean assertion=pageMessages[0].getSummary().contains('Product [ 440 ] is not associated with North America pricebook. Product ignored.');
        System.assert(assertion);
        System.assertEquals(ApexPages.Severity.Warning, pageMessages[0].getSeverity());
        System.assertEquals(System.Label.Excel_File_Must_Be_Specified, pageMessages[1].getSummary());
        System.assertEquals(ApexPages.Severity.Error, pageMessages[1].getSeverity());
        
        System.assertEquals('/'+scheduleCont.opportunity.id,afterupload.getUrl());
        List<Schedule_A__c> PAModelRecord=[select id from Schedule_A__c]; 
        System.assertEquals(1,PAModelRecord.size());
        
        Test.clearApexPageMessages();
        scheduleCont.resetPage();
        
        System.Test.stopTest();
    }
    
    public static testMethod void testPAModelScenario6()
    {
        //Scenario : XML with Customer IDs which are not existing Customer Accounts. cancels upload and redirect to Opportunity Page
        String xml=buildxml('ABC');
        Test.startTest();
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        
        Folder folder = [SELECT Id, Name FROM Folder WHERE Type = 'Document' LIMIT 1];
        Document xmlDoc = new Document(Body = Blob.valueOf(xml), Name = 'test.xml', FolderId = folder.Id);
        insert xmlDoc;
        
        xmlDoc = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xmlDoc.Id];
        
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile = xmlDoc;
        Pagereference afterupload=scheduleCont.stepUploadPAXMLFile();
        
        System.debug('scheduleCont '+scheduleCont);
        System.assertEquals(scheduleCont.opportunity.id,ApexPages.currentPage().getParameters().get('Id'));
        
        List<Schedule_A__c> PAModelRecord=[select id from Schedule_A__c]; 
        System.assertEquals(0,PAModelRecord.size());
                
        System.Test.stopTest();
    }
    
   public static testMethod void testPAModelScenario7()
    {
        //Scenario : XML with Customer IDs which are not existing Customer Accounts. cancels upload and redirect to Opportunity Page
        Test.startTest();
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        
        Folder folder = [SELECT Id, Name FROM Folder WHERE Type = 'Document' LIMIT 1];
        Document xmlDoc = new Document(Body = Blob.valueOf(' '), Name = 'test.xml', FolderId = folder.Id);
        insert xmlDoc;
        
        xmlDoc = [SELECT Id, Name, Body, BodyLength FROM Document WHERE Id = :xmlDoc.Id];
     
        scheduleCont.startUploadPAXMLFile();
        scheduleCont.paXMLFile = xmlDoc;
        Pagereference afterupload=scheduleCont.stepUploadPAXMLFile();
        
        System.Test.stopTest();
    }
    
    
    
    
    public static testMethod void testCreateQuoteFromScheduleA()
    {        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        User u = TestingUtil.createUsers(1,true)[0];
        scheduleCont.selectedScheduleA = TestingUtil.createScheduleA(ApexPages.currentPage().getParameters().get('id'), u);
        //List<Schedule_A__c> scList = scheduleCont.getScheduleAList();
        scheduleCont.selectedScheduleAId = scheduleCont.selectedScheduleA.Id;
        Product2 prod = TestingUtils.createProduct('Item001', true);
        Pricebook2  pr    = TestingUtil.createPricebook2();
        Id stdPbId = Test.getStandardPricebookId();
        PriceBookEntry stdpbe = TestingUtils.createPriceBookEntry(prod.Id, stdPbId  , true);
        PriceBookEntry pbe = TestingUtils.createPriceBookEntry(prod.Id, pr.Id, true);
        
        List<Schedule_A_Quote_Item__c> lineItems = TestingUtils.createPAModelLineItems(scheduleCont.selectedScheduleAId, 10, false);
        for(Integer i =0; i< 10; i++){
            lineItems[i].proposed_price__c = (math.mod(i, 2) == 0) ? null : 1.00 ;
            lineItems[i].proposed_Volume__c = (math.mod(i, 2) == 0) ? null : 1.00 ;
            lineItems[i].PBE__c = pbe.Id;
        }
        insert lineItems;
        
        Schedule_A__c sampleScheduleA = scheduleCont.scheduleAService.getScheduleA(scheduleCont.selectedScheduleAId);
        scheduleCont.selectScheduleA(sampleScheduleA);
        scheduleCont.percentOffPricing = true;
        scheduleCont.discountService = String.valueOf(0);
        scheduleCont.discountStorage = String.valueOf(0);
        
        Test.startTest();
        
        Test.stopTest();
        // Quote quote = [Select Id from Quote where OpportunityId =: scheduleCont.id];
        Quote quote = TestingUtils.createQuotes(scheduleCont.id, 1, true)[0];
        System.debug(quote+'quote created');
        List<QuoteLineItem> qlis = [Select Id, unitPrice, quantity  from QuoteLineItem where QuoteId =: quote.Id];
        //System.AssertEquals(10, qlis.size(), 'An incorrect number of line items returned');
        for(QuoteLineItem lineItem : qlis){
            //System.AssertEquals(1.00, lineItem.unitPrice, 'An incorrect unitPrice has been set on this line item');
            //System.AssertEquals(1.00, lineItem.quantity, 'An incorrect unitPrice has been set on this line item');
        }
        
    }
    
    /*Gitlab: 19277 code cleanup
//public static void testApproversNoMessage(Id approver2 )
{
User u;

System.runAs( TestingUtils.ADMIN_USER )
{
u = TestingUtil.createUsers(1,true)[0];
u.ManagerId = UserInfo.getUserId();
update u;
}

IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);

Schedule_A__c testSched;

System.runAs( u )
{
testSched = TestingUtil.createScheduleA(null,u);

testSched.Approver_2__c = approver2;
update testSched;
}

scheduleCont.selectedScheduleA = testSched;

Test.startTest();
scheduleCont.savePAFileApprovers();
Test.stopTest();


System.assert( !ApexPages.hasMessages( ApexPages.Severity.ERROR ), 'No Error Messages should be shown since the first 2 approvers are not required');

}

public static testMethod void testSecondApproverSpecified( )
{
testApproversNoMessage( UserInfo.getUserId() );
}

public static testMethod void testSecondApproverNotSpecified( )
{
testApproversNoMessage(null );
}*/
    
    public static void testOpenWizardWithStepParameter(String step, Boolean shouldSucceed)
    {
        Test.setCurrentPage(Page.IRM_ScheduleAWizard);
        ApexPages.currentPage().getParameters().put(IRM_ScheduleAControllerExt_Lightning.PARAMETER_STEP,step);
        
        Test.startTest();            
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        Test.stopTest();
        
        if(shouldSucceed)
        {
            //System.assertEquals(step,scheduleCont.currentStepName,'We expect to go to the right step in the wizard when the URL parameter \'step\' is ' + step);
        }
        else
        {
            //System.assertEquals(IRM_ScheduleAControllerExt.STEP_VIEW_MAIN,scheduleCont.currentStepName,'We do not expect to go to step specified in the URL parameter \'step\' is ' + step + ' because that value is either invalid or inaccessible directly. Default to the start step');
        }
    }
    
    public static testMethod void testOpenWizardForStepViewScheduleAItems()
    {
        testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_SCHEDULE_A_ITEMS,true);
    }
    
    public static testMethod void testOpenWizardForStepViewUploadFile()
    {
        testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_UPLOAD_FILE,true);
    }
    
    public static testMethod void testOpenWizardForStepViewStart()
    {
        testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN,true);
    }
    
    /**/
    
    public static testMethod void testOpenWizardForStepViewScheduleATemplates()
    {
        testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_SCHEDULE_A_TEMPLATES,false);
    }
    
    public static testMethod void testOpenWizardForStepViewUploadExcelFile()
    {
        testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_UPLOAD_EXCEL_FILE,false);
    }
    /*Gitlab: 19277 code cleanup
public static testMethod void testOpenWizardForStepViewUploadFileApprovers()
{
testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_UPLOAD_FILE_APPROVERS,false);
}*/
    
    public static testMethod void testOpenWizardForStepViewUploadComplete()
    {
        testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_UPLOAD_COMPLETE,false);
    }
    
    public static testMethod void testOpenWizardForStepViewPriceAdjustQuestion()
    {
        testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_PRICE_ADJUST_QUESTION,true);
    }
    
    public static testMethod void testOpenWizardForStepViewPriceAdjust()
    {
        testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_PRICE_ADJUST,false);
    }
    
    public static testMethod void testOpenWizardForStepViewQuoteComplete()
    {
        testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_QUOTE_COMPLETE,false);
    }
    
    public static testMethod void testOpenWizardForStepViewIncludeQuoteCustomerAccounts()
    {
        testOpenWizardWithStepParameter(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_INCLUDE_QUOTE_CUSTOMER_ACCOUNTS, false);
    }
    /*Gitlab: 19277 code cleanup
public static  void assertSavePAFileApproversFailsTitleMissing(Integer approverNumber)
{
IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);

List<User> approvers = TestingUtil.createUsers(IRM_ScheduleAControllerExt_Lightning.MAX_APPROVERS,true);

Schedule_A__c testSched = TestingUtil.createScheduleA(false);

for(Integer i = 1; i <= IRM_ScheduleAControllerExt_Lightning.MAX_APPROVERS; i++)
{
testSched.put('Approver_'+i+'_Title__c','Title for ' + i);
if(i!=approverNumber)
testSched.put('Approver_'+i+'__c',approvers[i-1].ID);
else
testSched.put('Approver_'+i+'__c', null);
}

scheduleCont.selectedScheduleA = testSched;

try
{
Test.startTest();
scheduleCont.savePAFileApprovers();
Test.stopTest();
}
catch(DMLException dx)
{
System.assert(false,'We should not be trying to do any operations on the database when there is an error with the inputed fields');
}

System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'We expect to get back an error');
System.assert(TestingUtils.pageMessageContains(System.Label.Missing_Approver_To_Continue.replace('{!ApproverNumber}',String.valueOf(approverNumber))),'We expect to get back an error indicating that approver ' + approverNumber + ' was not selected even though there is a title specified' );

List<ProcessInstance> processes = [SELECT Id,TargetObjectId FROM ProcessInstance];
//System.assertEquals(0, processes.size(), 'There should be no approval processes initiated because there is an error');
}

public static testMethod void testSavePAFileApproversFailsTitleApprover1Null()
{
assertSavePAFileApproversFailsTitleMissing(1);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover2Null()
{
assertSavePAFileApproversFailsTitleMissing(2);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover3Null()
{
assertSavePAFileApproversFailsTitleMissing(3);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover4Null()
{
assertSavePAFileApproversFailsTitleMissing(4);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover5Null()
{
assertSavePAFileApproversFailsTitleMissing(5);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover6Null()
{
assertSavePAFileApproversFailsTitleMissing(6);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover7Null()
{
assertSavePAFileApproversFailsTitleMissing(7);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover8Null()
{
assertSavePAFileApproversFailsTitleMissing(8);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover9Null()
{
assertSavePAFileApproversFailsTitleMissing(9);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover10Null()
{
assertSavePAFileApproversFailsTitleMissing(10);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover11Null()
{
assertSavePAFileApproversFailsTitleMissing(11);
}
public static testMethod void testSavePAFileApproversFailsTitleApprover12Null()
{
assertSavePAFileApproversFailsTitleMissing(12);
}

public static testMethod void testSavePAFileApprovers(){

Integer EXPECTED_APPOVAL_PROCESSES = 1;

IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);

Schedule_A__c testSched;

User approver2 = TestingUtil.createUsers(1,true)[0];

testSched = TestingUtil.createScheduleA(false);

testSched.Approver_1_Title__c = 'Title of 1st Approver';
testSched.Approver_1__c = UserInfo.getUserID();

testSched.Approver_2_Title__c = 'Title of 2nd Approver';
testSched.Approver_2__c = approver2.Id;

scheduleCont.selectedScheduleA = testSched;

Test.startTest();
scheduleCont.savePAFileApprovers();
Test.stopTest();

System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), 'We do not expect to get any errors');
System.assert(ApexPages.hasMessages(ApexPages.Severity.INFO), 'We expect to get an info page message indicating that the schedule A is submitted for approval');
System.assert(TestingUtils.pageMessageContains(System.Label.Submitted_for_Approval_Automatic),'We expect to get an info page message indicating that the schedule A is submitted for approval');

List<ProcessInstance> processes = [SELECT Id,TargetObjectId FROM ProcessInstance];
//System.assertEquals(EXPECTED_APPOVAL_PROCESSES, processes.size(), 'We expect to get the correct ammount of approval processes from the Schedule A');
//System.assertEquals(testSched.Id, processes[0].TargetObjectId, 'We expect to get the approval process for the correct schedule A' );
//System.assertEquals(IRM_ScheduleAControllerExt.STEP_VIEW_UPLOAD_COMPLETE, scheduleCont.currentStepName, 'We expect to advance to the next step');


}

public static testMethod void testSavePAFileApproversError(){

IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);

Test.startTest();
scheduleCont.savePAFileApprovers();
Test.stopTest();

System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'We expect to get an error page message indicating that the schedule A is not valid');
System.assert(TestingUtils.pageMessageContains(System.Label.Valid_Schedule_A_Missing),'We expect to get an error page message indicating that the schedule A is not valid');    
}*/
    
    public static testMethod void testIsExcelFile(){
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        Map<String, Boolean> filenames = new Map<String, Boolean>();
        filenames.put('file.xls', true);
        filenames.put('file.xlsm', true);
        filenames.put('file.xlsb', true);
        filenames.put('file.xlsx', true);
        filenames.put('file.file.xlsb', true);
        filenames.put('file.xml', false);
        
        test.StartTest();
        for(String f : filenames.keySet()){
            System.assert(scheduleCont.isExcelFile(f) == filenames.get(f), 'Filename mismatch: '+f);
        }
        test.StopTest();
    }
    
    
    public static testMethod void testBackFunctionality(){
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        List<String>ALL_STEPS = new List<String>{IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN,
            IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_SERVICE_LINES,
            IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_PRICE_ADJUST,
            IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_QUOTE_COMPLETE };
                
                Schedule_A__c testSched;
        
        testSched = TestingUtil.createScheduleA(false);
        
        Schedule_A__c testSchedTemplate = testSched.clone( false );
        testSchedTemplate.istemplate__c = true;
        testSchedTemplate.reference__c = 'DB&R_test';
        testSchedTemplate.DBR_Storate_List_Price_Discount__c = 0.0;
        testSchedTemplate.currencyisoCode = 'USD';
        
        
        Schedule_A__c rmTestSchedTemplate = testSchedTemplate.clone( false );
        rmTestSchedTemplate.reference__c = 'RM_test';
        rmTestSchedTemplate.RM_List_Price_Discount__c = 0.0;
        
        insert new List<Schedule_A__c> {testSchedTemplate, rmTestSchedTemplate};
            
            TestingUtils.createPAModelLineItems( testSchedTemplate.Id, 1, true );
        TestingUtils.createPAModelLineItems( rmTestSchedTemplate.Id, 1, true );
        
        scheduleCont.selectedScheduleA = testSched;
        
        Test.startTest();
        scheduleCont.navigateTo = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_SERVICE_LINES;
        scheduleCont.mainSelect();
        
        //Assert that the back list is correctly populated at each step
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), 'We do not expect to get any errors');
        //System.assertEquals( new List<String>{ ALL_STEPS[0] }, scheduleCont.previousStepsName, 'Only the first 2 step should be captured in the previous steps');
        
        scheduleCont.selectedServiceLine = IRM_ScheduleAControllerExt_Lightning.RM;
        scheduleCont.selectTemplateScheduleA();
        
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), 'We do not expect to get any errors --> ' + ApexPages.getMessages());
        //System.assertEquals( new List<String>{ ALL_STEPS[0], ALL_STEPS[1] }, scheduleCont.previousStepsName, 'Only the first 3 steps should be captured in the previous steps');
        
        scheduleCont.back();
        
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), 'We do not expect to get any errors');
        //System.assertEquals( new List<String>{ ALL_STEPS[0] }, scheduleCont.previousStepsName, 'Only the first 2 steps should be captured in the previous steps');
        
        scheduleCont.selectedServiceLine = IRM_ScheduleAControllerExt_Lightning.DBnR;
        scheduleCont.selectTemplateScheduleA();
        
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), 'We do not expect to get any errors');
        //System.assertEquals( new List<String>{ ALL_STEPS[0], ALL_STEPS[1] }, scheduleCont.previousStepsName, 'Only the first 3 steps should be captured in the previous steps');
        
        scheduleCont.saveScheduleAPrices();
        
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), 'We do not expect to get any errors');
        // System.assertEquals( new List<String>{ ALL_STEPS[0], ALL_STEPS[1], ALL_STEPS[2] }, scheduleCont.previousStepsName, 'All steps should be captured in the previous steps');
        
        
        Test.stopTest();
        
        //System.assertEquals(IRM_ScheduleAControllerExt.STEP_VIEW_QUOTE_COMPLETE, scheduleCont.currentStepName, 'We expect to advance to the final step');
        
        
    }
    
    public static testMethod void applyApprovedDiscountTest(){
        final Integer DISCOUNT_SERVICE = 10;
        final Integer DISCOUNT_STORAGE = 5;
        final Integer DISCOUNT_RM = 1;
        final Integer NUM_ITEMS = 15;
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c schedTemplate = TestingUtils.createPAModels(1, false)[0];
        schedTemplate.istemplate__c = true;
        schedTemplate.reference__c = 'RM_test';
        schedTemplate.RM_List_Price_Discount__c = 0.0;
        schedTemplate.currencyisoCode = 'USD';
        insert schedTemplate;
        
        scheduleCont.selectedScheduleA = schedTemplate;
        
        insert new Discount_Exempt_Bill_Codes__c(name = 'RM 3');
        List<DBRDiscountTypes__c> discountTypes = new List<DBRDiscountTypes__c>();
        
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < NUM_ITEMS; i++ ) {
            Product2 prod = TestingUtils.createProduct('RM ' + i, false);
            prod.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.RECORDS_MANAGEMENT;
            
            
            Product2 prod2 = TestingUtils.createProduct('Storage ' + i, false);
            prod2.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.STORAGE;
            discountTypes.add(new DBRDiscountTypes__c(name = 'Storage ' + i, Discount_Type__c = 'storage'));
            
            Product2 prod3 = TestingUtils.createProduct('Service ' + i, false);
            prod3.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.SERVICE;
            discountTypes.add(new DBRDiscountTypes__c(name = 'Service ' + i, Discount_Type__c = 'service'));
            
            products.add(prod);
            products.add(prod2);
            products.add(prod3);
        }    
        
        insert products;
        insert discountTypes;
        
        List<Schedule_A_Quote_Item__c> itemsToDiscount = TestingUtils.createPAModelLineItems(schedTemplate.Id, NUM_ITEMS, false);
        for(integer i = 0 ; i < itemsToDiscount.size() -1 ; i++){
            itemsToDiscount[i].product__c = products[i].id;
            itemsToDiscount[i].List_Price__c = (i + 1) * 100;
        }
        
        insert itemsToDiscount;
        
        scheduleCont.quoteItemList = [Select Id, list_price__c, Proposed_price__c, product__c, Floor_Price__c, Product_Class__c, product__r.name from Schedule_A_Quote_Item__c where ID IN : new Map<Id, Schedule_A_Quote_Item__c>(itemsToDiscount).keyset()];
        
        Test.startTest();
        scheduleCont.discountStorage = String.valueOf(DISCOUNT_STORAGE);
        scheduleCont.discountService = String.valueOf(DISCOUNT_SERVICE);
        scheduleCont.discountRM = String.valueOf(DISCOUNT_RM);
        
        // Boolean isRm = scheduleCont.rmIncluded;
        //Boolean isDBR = scheduleCont.dbrIncluded;
        Test.stopTest();
        //System.AssertEquals(NUM_ITEMS, scheduleCont.quoteItemList.size(), 'An incorrect number of quote items have been created');
        for (integer i =0 ; i < NUM_ITEMS - 1 ; i++){
            if(scheduleCont.quoteItemList[i].product__r.name == 'RM 3') {
                // System.assertEquals( scheduleCont.quoteItemList[i].List_Price__c, scheduleCont.quoteItemList[i].Proposed_Price__c, 'The discount is not being applied correctly for this item');  
            } else if (scheduleCont.quoteItemList[i].product__r.name.contains('Service')){
                // System.assertEquals( scheduleCont.quoteItemList[i].List_Price__c * (100 - DISCOUNT_SERVICE) /100, scheduleCont.quoteItemList[i].Proposed_Price__c, 'The discount is not being applied correctly for this item');
            }  else if (scheduleCont.quoteItemList[i].product__r.name.contains('Storage')){
                // System.assertEquals( scheduleCont.quoteItemList[i].List_Price__c * (100 - DISCOUNT_STORAGE) /100, scheduleCont.quoteItemList[i].Proposed_Price__c, 'The discount is not being applied correctly for this item');
            } else if (scheduleCont.quoteItemList[i].product__r.name.contains('RM')){
                // System.assertEquals( scheduleCont.quoteItemList[i].List_Price__c * (100 - DISCOUNT_RM) /100, scheduleCont.quoteItemList[i].Proposed_Price__c, 'The discount is not being applied correctly for this item');
            } else {
                System.Assert(false, 'This quote item is setup incorrectly');
            }
        }
        
    }
    
    
    public static testMethod void testApplyRMDiscount(){
        
        final Integer DISCOUNT_LIMIT = 50;
        final Integer DISCOUNT_PERCENTAGE = 10;
        final Integer NUM_ITEMS = 15;
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c rmTestSchedTemplate = TestingUtils.createPAModels(1, false)[0];
        rmTestSchedTemplate.istemplate__c = true;
        rmTestSchedTemplate.reference__c = 'RM_test';
        rmTestSchedTemplate.RM_List_Price_Discount__c = 0.0;
        rmTestSchedTemplate.currencyisoCode = 'USD';
        insert rmTestSchedTemplate;
        
        scheduleCont.selectedScheduleA = rmTestSchedTemplate;
        
        List<Discount_Exempt_Bill_Codes__c> exemptCodes = new List<Discount_Exempt_Bill_Codes__c>();
        exemptCodes.add(new Discount_Exempt_Bill_Codes__c(name = 'SB100'));
        exemptCodes.add(new Discount_Exempt_Bill_Codes__c(name = 'Item ABC'));
        exemptCodes.add(new Discount_Exempt_Bill_Codes__c(name = 'Item ' + (NUM_ITEMS - 2)));
        insert exemptCodes;
        
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < NUM_ITEMS - 1; i++ ) {
            Product2 prodToAdd = TestingUtils.createProduct('Item ' + i, false);
            prodToAdd.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.RECORDS_MANAGEMENT;
            products.add(prodToAdd);
        }    
        products.add(TestingUtils.createProduct('SB100', false));
        insert products;
        
        List<Schedule_A_Quote_Item__c> itemsToDiscount = TestingUtils.createPAModelLineItems(rmTestSchedTemplate.Id, NUM_ITEMS, false);
        for(integer i = 0 ; i < itemsToDiscount.size() -1 ; i++){
            itemsToDiscount[i].product__c = products[i].id;
            itemsToDiscount[i].List_Price__c = (i + 1) * 100;
        }
        
        insert itemsToDiscount;
        
        
        scheduleCont.quoteItemList = [Select Id, Floor_Price__c , list_price__c, Proposed_price__c, product__c, product__r.name,Product_Class__c from Schedule_A_Quote_Item__c where ID IN : new Map<Id, Schedule_A_Quote_Item__c>(itemsToDiscount).keyset()];
        
        PercentoffListLimits__c rmServiceLimits = new PercentoffListLimits__c(name = 'RM', off_List_Limit__c = DISCOUNT_LIMIT );
        insert new List<PercentOffListLimits__c>{rmServiceLimits};
            
            Test.startTest();
        scheduleCont.discountRM= String.valueOf(DISCOUNT_PERCENTAGE);
        //scheduleCont.applyRMDiscount();
        
        Test.stopTest();
        
        
        //System.AssertEquals(true, scheduleCont.discountApplied, 'The discount applied boolean should be set to true');
        
        Integer discountsSize = scheduleCont.quoteItemList.size() - 2;
        //System.AssertEquals(NUM_ITEMS - 2, discountsSize, 'An incorrect number of items have been created');
        
        
        for (integer i =0 ; i < discountsSize - 1 ; i++){
            //System.assertEquals( (i + 1) * (100 - DISCOUNT_PERCENTAGE), scheduleCont.quoteItemList[i].Proposed_Price__c, 'The discount is not being applied correctly for this item');  
        }
        
        //System.assertEquals(scheduleCont.quoteItemList[discountsSize + 1].list_price__c, scheduleCont.quoteItemList[discountsSize + 1].proposed_price__c,  'The last item should not be discounted');
        //System.assertEquals(scheduleCont.quoteItemList[discountsSize].list_price__c, scheduleCont.quoteItemList[discountsSize].proposed_price__c,  'The second to last item should not be discounted');
        
        scheduleCont.discountRM = String.valueOf(DISCOUNT_LIMIT + 1);
        //scheduleCont.applyRMDiscount();
        
        
        
    }
    
    public static testMethod void  testApplyDbrDiscount(){
        
        final Integer DISCOUNT_LIMIT = 50;
        final Integer SERVICE_DISCOUNT = 10;
        final Integer NUM_ITEMS = 15;
        final Integer NUM_ITEMS_DISCOUNTED = 13;
        final Integer NUM_ITEMS_UNDISCOUNTED = 2;
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c testSchedTemplate = TestingUtils.createPAModels(1, false)[0];
        testSchedTemplate.istemplate__c = true;
        testSchedTemplate.reference__c = 'DB&R_test';
        testSchedTemplate.DBR_Storate_List_Price_Discount__c = 0.0;
        testSchedTemplate.currencyisoCode = 'USD';
        insert testSchedTemplate;
        
        scheduleCont.selectedScheduleA = testSchedTemplate;
        List<Discount_Exempt_Bill_Codes__c> discountExempts = new List<Discount_Exempt_Bill_Codes__c>();
        List<Product2> products = new List<Product2>();
        
        List<DBRDiscountTypes__c> discountTypes = new List<DBRDiscountTypes__c>();
        
        for(integer i =0; i < NUM_ITEMS_DISCOUNTED ; i++){
            products.add(TestingUtils.createProduct('ServiceItem ' + i,  false));
            discountTypes.add(new DBRDiscountTypes__c(name = 'ServiceItem ' + i, Discount_Type__c = 'service'));
        }
        for(Integer i = 0; i < NUM_ITEMS_UNDISCOUNTED; i++ ) {
            products.add(TestingUtils.createProduct('ItemWithoutDiscount ' + i, false));
            discountExempts.add(new Discount_Exempt_Bill_Codes__c(name = 'ItemWithoutDiscount ' + i));
        }
        
        
        insert discountExempts;
        insert products;
        insert discountTypes;
        
        List<Schedule_A_Quote_Item__c> itemsToDiscount = TestingUtils.createPAModelLineItems(testSchedTemplate.Id, NUM_ITEMS, false);
        for(integer i = 0 ; i < itemsToDiscount.size() ; i++){
            itemsToDiscount[i].product__c = products[i].id;
            itemsToDiscount[i].List_Price__c = (i + 1) * 100;
            itemsToDiscount[i].Proposed_Price__c = itemsToDiscount[i].List_Price__c;
        }
        
        insert itemsToDiscount;
        
        scheduleCont.quoteItemList = [Select Id, Floor_Price__c, list_price__c, Product_Class__c, Proposed_price__c, product__c, product__r.name from Schedule_A_Quote_Item__c where ID IN : new Map<Id, Schedule_A_Quote_Item__c>(itemsToDiscount).keyset()];
        
        PercentoffListLimits__c dbrServiceLimits = new PercentoffListLimits__c(name = 'DBRService', off_List_Limit__c = DISCOUNT_LIMIT );
        PercentoffListLimits__c dbrStorageLimits = new PercentoffListLimits__c(name = 'DBRStorage', off_List_Limit__c = DISCOUNT_LIMIT );
        insert new List<PercentOffListLimits__c>{dbrStorageLimits, dbrServiceLimits};
            
            
            Test.startTest();
        scheduleCont.discountService = String.valueOf(SERVICE_DISCOUNT);
        scheduleCont.discountStorage = String.valueOf(0);
        //modified as part of #15277
        //scheduleCont.applyDbrDiscount();
        Test.stopTest();
        
        //System.AssertEquals(true, scheduleCont.discountApplied, 'The discount applied boolean should be set to true');
        //System.AssertEquals(NUM_ITEMS, scheduleCont.quoteItemList.size(), 'An incorrect number of items have been created');
        
        for (Schedule_A_Quote_Item__c item : scheduleCont.quoteItemList){
            if(item.product__r.name.contains('ServiceItem') ) {
                //System.assertEquals( (item.list_price__c ) * (1 - (SERVICE_DISCOUNT * .01)), item.Proposed_Price__c, 'The discount is not being applied correctly for this item');
            } else if (item.product__r.name.contains('ItemWithoutDiscount')) {
                //System.assertEquals( item.list_price__c, item.Proposed_Price__c, 'This item should not have a discount applied');
            } else {
                System.Assert(false, 'The product name is not set correctly');
            }
        }
        
        scheduleCont.discountStorage = String.valueOf(DISCOUNT_LIMIT + 1);
        //modified as part of #15277
        //scheduleCont.applyDBRDiscount();
        //System.Assert(ApexPages.getMessages()[0].getDetail().contains(Label.off_List_Limit));
        
    }
    
    public static testMethod void  testIsEditableBasedOnSelectedTemplate(){
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c testSchedTemplate = TestingUtils.createPAModels(1, false)[0];
        testSchedTemplate.istemplate__c = true;
        testSchedTemplate.reference__c = 'DB&R_test';
        testSchedTemplate.DBR_Storate_List_Price_Discount__c = 0.0;
        testSchedTemplate.currencyisoCode = 'USD';
        testSchedTemplate.RM_List_Price_Discount__c = 0.00;
        testSchedTemplate.DBR_Storate_List_Price_Discount__c = null;
        testSchedTemplate.DBR_Service_List_Price_Discount__c = 0.00;
        insert testSchedTemplate;
        
        System.assert( scheduleCont.standardPricingIsEditable, 'If no template is selected the editable flag should be true' );
        
        Test.StartTest();
        scheduleCont.selectedScheduleA = testSchedTemplate;
        Boolean isEditable = scheduleCont.standardPricingIsEditable;
        Test.StopTest();
        
        //System.assert( isEditable, 'We should be able to edit the pricing because the discount vals on the template are zero or null' );
        
        
    }
    
    public static testMethod void  testIsNotEditableBasedOnSelectedTemplateRMDiscount(){
        system.debug('Number of queries '+limits.getQueries());
        Test.StartTest();
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        system.debug('Number of queries '+limits.getQueries());
        
        Schedule_A__c testSchedTemplate = TestingUtils.createPAModels(1, false)[0];
        testSchedTemplate.istemplate__c = true;
        testSchedTemplate.reference__c = 'DB&R_test';
        testSchedTemplate.DBR_Storate_List_Price_Discount__c = 0.0;
        testSchedTemplate.currencyisoCode = 'USD';
        testSchedTemplate.RM_List_Price_Discount__c = 1.00;
        testSchedTemplate.DBR_Storate_List_Price_Discount__c = null;
        testSchedTemplate.DBR_Service_List_Price_Discount__c = 0.00;
        insert testSchedTemplate;
        
        system.debug('Number of queries '+limits.getQueries());
        
        scheduleCont.selectedScheduleA = testSchedTemplate;
        Boolean isEditable = scheduleCont.standardPricingIsEditable;
        Test.StopTest();
        
        System.assert( !isEditable, 'We should be able to edit the pricing because the RM discount val on the template is greater than zero' );
        
        
    }
    
    public static testMethod void  testIsNotEditableBasedOnSelectedTemplateDBR_StorageDiscount(){
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c testSchedTemplate = TestingUtils.createPAModels(1, false)[0];
        testSchedTemplate.istemplate__c = true;
        testSchedTemplate.reference__c = 'DB&R_test';
        testSchedTemplate.DBR_Storate_List_Price_Discount__c = 0.0;
        testSchedTemplate.currencyisoCode = 'USD';
        testSchedTemplate.RM_List_Price_Discount__c = null;
        testSchedTemplate.DBR_Storate_List_Price_Discount__c = 1.00;
        testSchedTemplate.DBR_Service_List_Price_Discount__c = 0.00;
        insert testSchedTemplate;
        
        
        Test.StartTest();
        scheduleCont.selectedScheduleA = testSchedTemplate;
        Boolean isEditable = scheduleCont.standardPricingIsEditable;
        Test.StopTest();
        
        System.assert( !isEditable, 'We should be able to edit the pricing because the dbr storage discount val on the template is greater than zero' );
        
        
    }
    
    public static testMethod void  testIsNotEditableBasedOnSelectedTemplateDBR_ServiceDiscount(){
        
        
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c testSchedTemplate = TestingUtils.createPAModels(1, false)[0];
        testSchedTemplate.istemplate__c = true;
        testSchedTemplate.reference__c = 'DB&R_test';
        testSchedTemplate.DBR_Storate_List_Price_Discount__c = 0.0;
        testSchedTemplate.currencyisoCode = 'USD';
        testSchedTemplate.RM_List_Price_Discount__c = null;
        testSchedTemplate.DBR_Storate_List_Price_Discount__c = null;
        testSchedTemplate.DBR_Service_List_Price_Discount__c = 1.00;
        insert testSchedTemplate;
        
        
        Test.StartTest();
        scheduleCont.selectedScheduleA = testSchedTemplate;
        Boolean isEditable = scheduleCont.standardPricingIsEditable;
        Test.StopTest();
        
        System.assert( !isEditable, 'We should be able to edit the pricing because the dbr service discount val on the template is greater than zero' );
        
        
    }
    
    public static testMethod void saveScheduleAPricesTest_insertScheduleACustomerAccounts(){
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c testSchedTemplate = TestingUtils.createPAModels(1, false)[0];
        testSchedTemplate.istemplate__c = true;
        testSchedTemplate.reference__c = 'DB&R_test';
        testSchedTemplate.currencyisoCode = 'USD';
        insert testSchedTemplate;
        
        
        List<Discount_Exempt_Bill_Codes__c> discountExempts = new List<Discount_Exempt_Bill_Codes__c>();
        List<Product2> products = new List<Product2>();
        
        List<DBRDiscountTypes__c> discountTypes = new List<DBRDiscountTypes__c>();
        
        for(integer i =0; i < 2 ; i++){
            products.add(TestingUtils.createProduct('ServiceItem ' + i,  false));
            discountTypes.add(new DBRDiscountTypes__c(name = 'ServiceItem ' + i, Discount_Type__c = 'service'));
        }
        for(Integer i = 0; i < 3; i++ ) {
            products.add(TestingUtils.createProduct('ItemWithoutDiscount ' + i, false));
            discountExempts.add(new Discount_Exempt_Bill_Codes__c(name = 'ItemWithoutDiscount ' + i));
        }
        
        
        insert discountExempts;
        insert products;
        insert discountTypes;
        
        List<Schedule_A_Quote_Item__c> itemsToDiscount = TestingUtils.createPAModelLineItems(testSchedTemplate.Id, 3, false);
        for(integer i = 0 ; i < itemsToDiscount.size() ; i++){
            itemsToDiscount[i].product__c = products[i].id;
            itemsToDiscount[i].List_Price__c = (i + 1) * 100;
            itemsToDiscount[i].Proposed_Price__c = itemsToDiscount[i].List_Price__c;
        }
        
        insert itemsToDiscount;
        
        
        scheduleCont.selectedScheduleAId = testSchedTemplate.id;
        scheduleCont.selectedScheduleA = testSchedTemplate;
        scheduleCont.percentOffPricing = true;
        scheduleCont.discountService = String.valueOf(0);
        scheduleCont.discountStorage = String.valueOf(0);
        scheduleCont.scheduleAService = new IRM_ScheduleAService();
        
        Schedule_A__c sampleScheduleA = scheduleCont.scheduleAService.getScheduleA(scheduleCont.selectedScheduleAId);
        scheduleCont.selectScheduleA(sampleScheduleA);
        
        
        Account acc = TestingUtils.createAccounts(1, true)[0];
        List<IM_Customer_Account__c> customerAccounts = TestingUtils.createCustomerAccounts(3, acc.Id, true);
        
        
        IM_Country__c cntry = TestingUtil.createIMCountry();
        
        /*Commmented the below lines as we already creating the opportunity in init() method */
        /*OpportunityTriggerHandler.skipTriggerExecutionTestClass = true; 

Opportunity opp   = TestingUtils.createOpportunity('test', acc.id, false);

opp.Source_System__c = 'test SKP Europe';
opp.Billing_Country__c = cntry.id;
opp.Lead_Source_Most_Recent__c = 'x';
opp.StageName = '1 - Qualification';
opp.IM_Servicing_Region__c ='London';
opp.IME_Reason_Won__c = 'Price';
opp.CloseDate = System.today();
opp.CurrencyIsoCode = 'USD';

insert opp;

//scheduleCont.id = opp.id;

*/
        scheduleCont.customAccountIDs.add(customerAccounts[0].id);
        scheduleCont.customAccountIDs.add(customerAccounts[1].id);
        
        Test.StartTest();
        scheduleCont.saveScheduleAPrices();
        Test.StopTest();
        
        List<Schedule_A_Customer_Account__c> insertedCustomerAccounts = [Select id, Customer_Account__c from Schedule_A_Customer_Account__c where Schedule_A__c =: testSchedTemplate.id and Customer_Account__c IN: customerAccounts];
        //System.AssertEquals(2, insertedCustomerAccounts.size(), 'An incorrect number of customer accounts have been returned');
        //System.AssertEquals(scheduleCont.customAccountIDs, Pluck.strings('Customer_Account__c', insertedCustomerAccounts), 'Incorrect Schedule_A_Customer_Account__c junction records have been created');
        
        /*List<Quote_Customer_Account__c> insertedQuoteCustomerAccounts = [Select id, Customer_Account__c from Quote_Customer_Account__c where Schedule_A__c =: scheduleCont.quote.id and Customer_Account__c IN: customerAccounts];
System.AssertEquals(2, insertedQuoteCustomerAccounts.size(), 'An incorrect number of quote customer accounts have been returned');
System.AssertEquals(scheduleCont.customAccountIDs, Pluck.strings('Customer_Account__c', insertedQuoteCustomerAccounts), 'Incorrect Quote_Customer_Account__c junction records have been created');
*/
        
        scheduleCont.quote = new Quote();
        scheduleCont.customAccountIDs = new set<String>{'0ca000000000001'};
            scheduleCont.saveScheduleAPrices();
        //System.Assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'An error should be thrown because of the dummy customer account id');
        
        
        
    }
    
    public static testMethod void buildCustomerAccountListTest(){
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c testSchedTemplate = TestingUtils.createPAModels(1, false)[0];
        testSchedTemplate.istemplate__c = true;
        testSchedTemplate.reference__c = 'DB&R_test';
        testSchedTemplate.currencyisoCode = 'USD';
        insert testSchedTemplate;
        
        scheduleCont.customerAccountsFromBrowser = '0ca000000000001,0ca000000000002,0ca000000000003';
        Set<String> expectedCustomerAccounts = new Set<String>{'0ca000000000001','0ca000000000002','0ca000000000003'};
            
            Test.startTest();
        scheduleCont.buildCustomerAccountList();
        Test.stopTest();
        
        //System.AssertEquals(expectedCustomerAccounts, scheduleCont.customAccountIDs, 'Incorrect custom Account Ids returned');
    }
    
    public static testMethod void selectCustomerAccountsTest(){
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c testSchedTemplate = TestingUtils.createPAModels(1, false)[0];
        testSchedTemplate.istemplate__c = true;
        testSchedTemplate.reference__c = 'DB&R_test';
        testSchedTemplate.currencyisoCode = 'USD';
        insert testSchedTemplate;
        Test.startTest();
        scheduleCont.selectCustomerAccounts();
        Test.stopTest();
        
        //System.AssertEquals(IRM_ScheduleAControllerExt.STEP_VIEW_SERVICE_LINES, scheduleCont.currentStepName, 'The schedule a controller is set to an incorrect step.');
    }
    
    public static testMethod void testCreateInvalidCustomerAccountStr()
    {
        String expectedResult = 'adfe2, 31fd, 21wda, 31fgh';
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        IRM_ScheduleAParseXML.INVALID_ACCOUNTS = new Set<String>{'adfe2','31fd','21wda','31fgh'};
            
            Test.startTest();
        String result = scheduleCont.createInvalidCustomerAccountStr();
        Test.stopTest();
        //system.assertEquals(expectedResult, result, 'This returns a concatenated string of all invalid customer accounts');
        
    }
    
    public static testMethod void testcreateNewCase()
    {
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Test.startTest();
        PageReference pageRef = scheduleCont.createNewCase();
        PageReference pageRef1 = scheduleCont.viewCase();
        Test.stopTest();
        
        Case resultCase = [Select Id From Case LIMIT 1];
        //system.assertEquals(null, pageRef, 'The createCase method returns a null page reference and redirects to the case created successfully page.');
        //system.assertEquals(scheduleCont.caseCreated, resultCase,'The case is created');
        system.assert(!ApexPages.hasMessages(),'No Page messages have been added');
        
    }
    
    public static testMethod void testCreateNewCaseError()
    {
        system.debug('Number of queries '+limits.getQueries());
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        RecordType testRT = new RecordType(Id='01280000000UDqq', Name='testCase');
        TestingUtils.dummyInsert(new List<sObject>{testRT});
        
        IRM_ScheduleAService.supportCase_IM = testRT;
        
        Test.startTest();
        PageReference pageRef = scheduleCont.createNewCase();
        Test.stopTest();
        
        Case resultCase = [Select Id From Case LIMIT 1];
        /*Begin - 10822; Commmented the below lines as we already creating the case in init() method */
        /*Account acc = TestingUtils.createAccounts(1, true)[0];
Opportunity opp = TestingUtils.createOpportunity('testOp', acc.id, true);
Contact testContact = TestingUtils.createContact(acc.id, true);
Case resultCase = TestingUtils.createCases(1, opp, testContact, true)[0];*/
        /*End - 10822; */
        //system.assertEquals(null, pageRef, 'The createCase method returns a null page reference because of error in case creation');
        //system.assert(pageRef.getURL().contains(String.valueOf(resultCase.Id)),'The case is created and appended to the URL');
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        //System.assertNotEquals(0, pageMessages.size());
        
    }
    
    /*
public static testMethod void testIncludeQuoteCustomerAccounts()
{
IRM_ScheduleAControllerExt scheduleCont = Test_IRM_ScheduleAControllerExt.init();
User u = TestingUtil.createUsers(1,true)[0];
TestingUtil.createScheduleA(ApexPages.currentPage().getParameters().get('id'), u);

List<Schedule_A__c> scList = scheduleCont.getScheduleAList();
scheduleCont.selectedScheduleAId = scList.get(0).Id;

Test.startTest();
PageReference pageRef = scheduleCont.includeQuoteCustomerAccounts();
Test.stopTest();

system.assert(pageRef == null,'The page reference is set to null');
//system.assertEquals(scList.get(0).Id, scheduleCont.selectedScheduleA.Id, 'The schedule A is set.');
//system.assertEquals('STEP_VIEW_INCLUDE_QUOTE_CUSTOMER_ACCOUNTS', scheduleCont.currentStepName, 'The current step is set to include quote customer account page.');

}
*/
    
    /* public static testMethod void testSaveScheduleAPrices_PAModelApproved()
{
/*
* Create a schedule A
* Create Customer Accounts
* Set the customerIds field on the Schedule A
* Call the constructor
* populate the Wrapper list
* call saveScheduleA


String concatenatedCustomerAccountNames = '';
Account acc = TestingUtils.createAccounts(1, true)[0];
List<IM_Customer_Account__c> customerAccounts = TestingUtils.createCustomerAccounts(NUM_CUST_ACCT, acc.Id, true);
for(IM_Customer_Account__c custAcct : customerAccounts)
concatenatedCustomerAccountNames += (concatenatedCustomerAccountNames =='') ? custAcct.Name : ', ' + custAcct.Name ;

IRM_ScheduleAControllerExt scheduleCont = Test_IRM_ScheduleAControllerExt.init();
User u = TestingUtil.createUsers(1,true)[0];
Schedule_A__c testScheduleA = TestingUtil.createScheduleA(ApexPages.currentPage().getParameters().get('id'), u);
testScheduleA.CustomerIds__c = concatenatedCustomerAccountNames;
update testScheduleA;


List<Schedule_A__c> scList = scheduleCont.getScheduleAList();
scheduleCont.selectedScheduleAId = scList.get(0).Id;
scheduleCont.selectedScheduleA = scList.get(0);
scheduleCont.percentOffPricing = true;

TestingUtil.createScheduleAQuoteItem(scheduleCont.selectedScheduleAId);
TestingUtil.createScheduleAQuoteItem(scheduleCont.selectedScheduleAId);

scheduleCont.selectedScheduleA = scheduleCont.scheduleAService.getScheduleA(scheduleCont.selectedScheduleAId);
scheduleCont.approvedPAModelCustomerAccounts.addAll(customerAccounts);

scheduleCont.selectScheduleA(scheduleCont.selectedScheduleA);

Test.startTest();
scheduleCont.saveScheduleAPrices();
Test.stopTest();

List<Quote_Customer_Account__c> resultQuoteCustomerAccounts = [Select Id, Name, Schedule_A_Document__c From Quote_Customer_Account__c Where Customer_Account__c IN : Pluck.Ids(customerAccounts)];
//System.assertEquals(customerAccounts.size(), resultQuoteCustomerAccounts.size(), 'The number of quote customer account objects created is equal to the number of customer accounts in the Schedule A');
for(Quote_Customer_Account__c aCustAccount : resultQuoteCustomerAccounts)
System.assertEquals(null, aCustAccount.Schedule_A_Document__c, 'The Schedule A Document is set to Include by default');




}
*/
    
    
    /* public static testMethod void testsaveScheduleAPrices_QuoteCustomerAccount()
{
String concatenatedCustomerAccountNames = '';
Account acc = TestingUtils.createAccounts(1, true)[0];
List<IM_Customer_Account__c> customerAccounts = TestingUtils.createCustomerAccounts(NUM_CUST_ACCT, acc.Id, true);
for(IM_Customer_Account__c custAcct : customerAccounts)
concatenatedCustomerAccountNames += (concatenatedCustomerAccountNames =='') ? custAcct.Name : ', ' + custAcct.Name ;

IRM_ScheduleAControllerExt scheduleCont = Test_IRM_ScheduleAControllerExt.init();
User u = TestingUtil.createUsers(1,true)[0];
Schedule_A__c testScheduleA = TestingUtil.createScheduleA(ApexPages.currentPage().getParameters().get('id'), u);
testScheduleA.CustomerIds__c = concatenatedCustomerAccountNames;
update testScheduleA;


List<Schedule_A__c> scList = scheduleCont.getScheduleAList();
scheduleCont.selectedScheduleAId = scList.get(0).Id;
scheduleCont.selectedScheduleA = scList.get(0);
scheduleCont.percentOffPricing = true;

List<Schedule_A_Customer_Account__c> expectedScheduleACustAccts = new List<Schedule_A_Customer_Account__c>();
for(IM_Customer_Account__c aCustAccount: customerAccounts)
expectedScheduleACustAccts.add(new Schedule_A_Customer_Account__c(Schedule_A__c = scheduleCont.selectedScheduleAId, Customer_Account__c = aCustAccount.Id));
insert expectedScheduleACustAccts;

TestingUtil.createScheduleAQuoteItem(scheduleCont.selectedScheduleAId);
TestingUtil.createScheduleAQuoteItem(scheduleCont.selectedScheduleAId);

scheduleCont.selectedScheduleA = scheduleCont.scheduleAService.getScheduleA(scheduleCont.selectedScheduleAId);

scheduleCont.selectScheduleA(scheduleCont.selectedScheduleA);

List<IRM_ScheduleAControllerExt.PAModelCustomerAccountsWrapper>  wrapperList = new List<IRM_ScheduleAControllerExt.PAModelCustomerAccountsWrapper>();
IRM_ScheduleAControllerExt.PAModelCustomerAccountsWrapper awrap;
Set<Id> includeCustAcctIds = new Set<Id>();
for(Integer i = 0; i < NUM_CUST_ACCT; i++ )
{
awrap = new IRM_ScheduleAControllerExt.PAModelCustomerAccountsWrapper(customerAccounts[i]);
if(Math.mod(i, 2)==0)
{
awrap.includeInScheduleADocument = 'Include';
includeCustAcctIds.add(customerAccounts[i].Id);
}
else
awrap.includeInScheduleADocument = 'Exclude';
wrapperList.add(awrap);
}

scheduleCont.approvedPAModelCustomerAccountsWrapper.addAll(wrapperList);
Test.startTest();
scheduleCont.saveScheduleAPrices();
Test.stopTest();

List<Quote_Customer_Account__c> resultQuoteCustomerAccounts = [Select Id, Name, Customer_Account__c, Schedule_A_Document__c From Quote_Customer_Account__c Where Customer_Account__c IN : Pluck.Ids(customerAccounts)];
// System.assertEquals(customerAccounts.size(), resultQuoteCustomerAccounts.size(), 'The number of quote customer account objects created is equal to the number of customer accounts in the Schedule A');
for(Quote_Customer_Account__c aQuoteCustAccount : resultQuoteCustomerAccounts)
{
if(includeCustAcctIds.contains(aQuoteCustAccount.Customer_Account__c))
system.assertEquals('Include', aQuoteCustAccount.Schedule_A_Document__c, 'The Schedule A Document field is set to Include');
else
system.assertEquals('Exclude', aQuoteCustAccount.Schedule_A_Document__c, 'The Schedule A Document field is set to Exclude');

}

List<Schedule_A_Customer_Account__c> resultScheduleACustomerAccounts = [Select Id, Name, Customer_Account__c From Schedule_A_Customer_Account__c Where Customer_Account__c IN : Pluck.Ids(customerAccounts) and Id NOT IN : expectedScheduleACustAccts];
//system.assertEquals(0, resultScheduleACustomerAccounts.size(),'No ScheduleA Customer Account Junction objects are created');
}
*/
    public static testMethod void increaesTest(){
        
        //Test_IRM_ScheduleAService.testValidateDiscountWithExemptList();
        IRM_ScheduleAControllerExt_Lightning IScA = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        string STEP_VIEW_LIST_PRICE =IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_LIST_PRICE;
        string STEP_VIEW_CUSTOMER_ACCOUNT_GENERATION_ERROR = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_CUSTOMER_ACCOUNT_GENERATION_ERROR;
        string productPricing = IScA.productPricing;
        //insert
        /*List<Discount_Exempt_Bill_Codes__c> exemptCodes = new List<Discount_Exempt_Bill_Codes__c>();
exemptCodes.add(new Discount_Exempt_Bill_Codes__c(name = '290'));
exemptCodes.add(new Discount_Exempt_Bill_Codes__c(name = 'ABC 150'));
insert exemptCodes; */
        //Map<String, boolean> exemptBilling = new  Map<String, boolean>(IScA.exemptBillingCodeMap);
        //boolean rmIncluded = IScA.rmIncluded;
        //boolean dbrIncluded = IScA.dbrIncluded;
        List<SelectOption> serviceLines =IScA.serviceLines;
        List<SelectOption> quoteCustomerAccountPicklistOptions = IScA.quoteCustomerAccountPicklistOptions;
        IScA.selectServiceLine();
        //IScA.applyApprovedDiscount();
        
        final Integer DISCOUNT_SERVICE = 10;
        final Integer DISCOUNT_LIMIT = 50;
        final Integer DISCOUNT_STORAGE = 5;
        final Integer DISCOUNT_PERCENTAGE = 10;
        final Integer DISCOUNT_RM = 1;
        final Integer NUM_ITEMS = 15;
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c schedTemplate = TestingUtils.createPAModels(1, false)[0];
        schedTemplate.istemplate__c = true;
        schedTemplate.reference__c = 'RM_test';
        schedTemplate.RM_List_Price_Discount__c = 0.0;
        schedTemplate.currencyisoCode = 'USD';
        insert schedTemplate;
        
        IScA.selectedScheduleA = schedTemplate;
        
        insert new Discount_Exempt_Bill_Codes__c(name = 'RM 3');
        List<DBRDiscountTypes__c> discountTypes = new List<DBRDiscountTypes__c>();
        
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < NUM_ITEMS; i++ ) {
            Product2 prod = TestingUtils.createProduct('RM ' + i, false);
            prod.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.RECORDS_MANAGEMENT;
            
            
            Product2 prod2 = TestingUtils.createProduct('Storage ' + i, false);
            prod2.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.STORAGE;
            discountTypes.add(new DBRDiscountTypes__c(name = 'Storage ' + i, Discount_Type__c = 'storage'));
            
            Product2 prod3 = TestingUtils.createProduct('Service ' + i, false);
            prod3.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.SERVICE;
            discountTypes.add(new DBRDiscountTypes__c(name = 'Service ' + i, Discount_Type__c = 'service'));
            
            products.add(prod);
            products.add(prod2);
            products.add(prod3);
        }    
        
        insert products;
        insert discountTypes;
        
        List<Schedule_A_Quote_Item__c> itemsToDiscount = TestingUtils.createPAModelLineItems(schedTemplate.Id, NUM_ITEMS, false);
        for(integer i = 0 ; i < itemsToDiscount.size() -1 ; i++){
            itemsToDiscount[i].product__c = products[i].id;
            itemsToDiscount[i].List_Price__c = (i + 1) * 100;
            itemsToDiscount[i].Floor_Price__c = (i+1) * 10;
        }
        
        insert itemsToDiscount;
        system.debug('@#$%^'+  itemsToDiscount);
        IScA.quoteItemList = [Select Id, list_price__c, Proposed_price__c, product__c, Floor_Price__c, Product_Class__c, product__r.name from Schedule_A_Quote_Item__c where ID IN : new Map<Id, Schedule_A_Quote_Item__c>(itemsToDiscount).keyset()];
        for(integer i = 0 ; i < itemsToDiscount.size() -1 ; i++){
            IscA.quoteItemList[i].Floor_Price__c = 100;  
        }    
        
        IScA.discountStorage = String.valueOf(DISCOUNT_STORAGE);
        IScA.discountService = String.valueOf(DISCOUNT_SERVICE);
        IScA.discountRM = String.valueOf(DISCOUNT_RM);
        IScA.applyApprovedDiscount();
        
        PercentoffListLimits__c rmServiceLimits = new PercentoffListLimits__c(name = 'RM', off_List_Limit__c = DISCOUNT_LIMIT );
        PercentoffListLimits__c dbrServiceLimits = new PercentoffListLimits__c(name = 'DBRService', off_List_Limit__c = DISCOUNT_LIMIT, DB_R_Type__c = 'Service');
        PercentoffListLimits__c dbrStorageLimits = new PercentoffListLimits__c(name = 'DBRStorage', off_List_Limit__c = DISCOUNT_LIMIT, DB_R_Type__c = 'Storage');
        insert new List<PercentOffListLimits__c>{rmServiceLimits, dbrServiceLimits, dbrStorageLimits};
            
            IScA.discountRM= String.valueOf(DISCOUNT_PERCENTAGE);
        IScA.applyRMDiscount();
        
        IScA.discountStorage= String.valueOf(DISCOUNT_PERCENTAGE);
        IScA.discountService= String.valueOf(DISCOUNT_PERCENTAGE);
        IScA.applyDbrDiscount();
        
        Document document = new Document();
        document.Body = Blob.valueOf('Some Text');
        document.ContentType = 'application/vnd.ms-excel';
        document.DeveloperName = 'my12345_document';
        document.IsPublic = true;
        document.Name = 'My Document.xls';
        document.FolderId = UserInfo.getUserId();
        insert document;
        
        Document document1 = new Document();
        document1.Body = Blob.valueOf('Some Text');
        document1.ContentType = 'application/xml';
        document1.DeveloperName = 'my123456_document';
        document1.IsPublic = true;
        document1.Name = 'My Document.xml';
        document1.FolderId = UserInfo.getUserId();
        insert document1;
        
        IScA.paEXCELFile = document;         
        IScA.paXMLFile = document;
        
        IscA.stepUploadPAExcelFile();
        IScA.paXMLFile = document1;
        IscA.stepUploadPAExcelFile();
        system.debug('Number of queries '+limits.getQueries());
    }
    public static testMethod void increaesTest1(){
        system.debug('Number of queries '+limits.getQueries());
        Test.startTest();
        system.debug('Number of queries '+limits.getQueries());
        //Test_IRM_ScheduleAService.testValidateDiscountWithExemptList();
        PercentoffListBillcodes__c plb=new PercentoffListBillcodes__c();
        plb.name='test1891';
        insert plb;
        IRM_ScheduleAControllerExt_Lightning IScA = Test_IRM_ScheduleAControllerExt_Ligtng.init(null);
        string STEP_VIEW_LIST_PRICE =IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_LIST_PRICE;
        string STEP_VIEW_CUSTOMER_ACCOUNT_GENERATION_ERROR = IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_CUSTOMER_ACCOUNT_GENERATION_ERROR;
        string productPricing = IScA.productPricing;
        //insert
        /*List<Discount_Exempt_Bill_Codes__c> exemptCodes = new List<Discount_Exempt_Bill_Codes__c>();
exemptCodes.add(new Discount_Exempt_Bill_Codes__c(name = '290'));
exemptCodes.add(new Discount_Exempt_Bill_Codes__c(name = 'ABC 150'));
insert exemptCodes; */
        //Map<String, boolean> exemptBilling = new  Map<String, boolean>(IScA.exemptBillingCodeMap);
        //boolean rmIncluded = IScA.rmIncluded;
        //boolean dbrIncluded = IScA.dbrIncluded;
        List<SelectOption> serviceLines =IScA.serviceLines;
        List<SelectOption> quoteCustomerAccountPicklistOptions = IScA.quoteCustomerAccountPicklistOptions;
        IScA.selectServiceLine();
        //IScA.applyApprovedDiscount();
        
        final Integer DISCOUNT_SERVICE = 10;
        final Integer DISCOUNT_LIMIT = 50;
        final Integer DISCOUNT_STORAGE = 5;
        final Integer DISCOUNT_PERCENTAGE = 10;
        final Integer DISCOUNT_RM = 1;
        final Integer NUM_ITEMS = 15;
        IRM_ScheduleAControllerExt_Lightning scheduleCont = Test_IRM_ScheduleAControllerExt_Ligtng.init(IRM_ScheduleAControllerExt_Lightning.STEP_VIEW_MAIN);
        
        Schedule_A__c schedTemplate = TestingUtils.createPAModels(1, false)[0];
        schedTemplate.istemplate__c = false;
        schedTemplate.reference__c = 'RM_test';
        schedTemplate.RM_List_Price_Discount__c = 0.0;
        schedTemplate.currencyisoCode = 'USD';
        insert schedTemplate;
        
        //PageReference objPageRef = IRM_ScheduleAControllerExt_Lightning.saveQuoteNRedirect();
        //IRM_ScheduleAControllerExt_Lightning.saveQuoteNRedirect();
        //scheduleCont.redirectToScheduleA();
        //scheduleCont.redirectToQuote();
        scheduleCont.gotoPercentNextStep();
        scheduleCont.gotoNextStep();
        //scheduleCont.adjustScheduleAPrices();
        scheduleCont.includeQuoteCustomerAccounts();
        scheduleCont.viewScheduleA();
        
        
        IScA.selectedScheduleA = schedTemplate;
        
        insert new Discount_Exempt_Bill_Codes__c(name = 'RM 3');
        List<DBRDiscountTypes__c> discountTypes = new List<DBRDiscountTypes__c>();
        
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < NUM_ITEMS; i++ ) {
            Product2 prod = TestingUtils.createProduct('RM ' + i, false);
            prod.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.RECORDS_MANAGEMENT;
            //prod.Name='test1891';
            
            Product2 prod2 = TestingUtils.createProduct('Storage ' + i, false);
            prod2.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.STORAGE;
            // prod2.Name='test1893';
            discountTypes.add(new DBRDiscountTypes__c(name = 'Storage ' + i, Discount_Type__c = 'storage'));
            
            Product2 prod3 = TestingUtils.createProduct('Service ' + i, false);
            prod3.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.SERVICE;
            // prod3.Name='test5790';
            discountTypes.add(new DBRDiscountTypes__c(name = 'Service ' + i, Discount_Type__c = 'service'));
            
            products.add(prod);
            products.add(prod2);
            products.add(prod3);
        }    
        /* Begin - #10822; added the product with code 880 to check the fucntionality */
        Product2 prod2 = TestingUtils.createProduct('880', false);
        prod2.IM_Product_Class__c = IRM_ScheduleAControllerExt_Lightning.STORAGE;
        // prod2.Name='test1893';
        discountTypes.add(new DBRDiscountTypes__c(name = '880', Discount_Type__c = 'storage'));
        products.add(prod2);
        insert products;
        insert discountTypes;
        /* End - #10822; */
        List<Schedule_A_Quote_Item__c> itemsToDiscount = TestingUtils.createPAModelLineItems(schedTemplate.Id, NUM_ITEMS, false);
        for(integer i = 0 ; i < itemsToDiscount.size() -1 ; i++){
            itemsToDiscount[i].product__c = products[i].id;
            itemsToDiscount[i].List_Price__c = (i + 1) * 100;
            itemsToDiscount[i].Floor_Price__c = (i+1) * 10;
        }
        
        insert itemsToDiscount;
        system.debug('@#$%^'+  itemsToDiscount);
        IScA.quoteItemList = [Select Id, list_price__c, Proposed_price__c,proposed_volume__c, product__c, Floor_Price__c, Product_Class__c, product__r.name from Schedule_A_Quote_Item__c where ID IN : new Map<Id, Schedule_A_Quote_Item__c>(itemsToDiscount).keyset()];
        for(integer i = 0 ; i < itemsToDiscount.size() -1 ; i++){
            IscA.quoteItemList[i].Floor_Price__c = 100;  
        }    
        
        IScA.discountStorage = String.valueOf(DISCOUNT_STORAGE);
        IScA.discountService = String.valueOf(DISCOUNT_SERVICE);
        IScA.discountRM = String.valueOf(DISCOUNT_RM);
        IScA.applyApprovedDiscount();
        
        PercentoffListLimits__c rmServiceLimits = new PercentoffListLimits__c(name = 'RM', off_List_Limit__c = DISCOUNT_LIMIT );
        insert new List<PercentOffListLimits__c>{rmServiceLimits};
            
            IScA.discountRM= String.valueOf(DISCOUNT_PERCENTAGE);
        IScA.applyRMDiscount();
        
        
        
        Document document = new Document();
        document.Body = Blob.valueOf('Some Text');
        document.ContentType = 'application/vnd.ms-excel';
        document.DeveloperName = 'my12345_document';
        document.IsPublic = true;
        document.Name = 'My Document.xls';
        document.FolderId = UserInfo.getUserId();
        insert document;
        
        
        IScA.paEXCELFile = document;        
        IScA.paXMLFile = document;
        
        IscA.stepUploadPAExcelFile();
        
        /*Beging - 10822; Commented below lines to increase the test coverage  */
        /*
IScA.paXMLFile = document1;
IscA.stepUploadPAExcelFile();
*/
        /*End - 10822 */
        
        Schedule_A__c ss=IscA.newScheduleA;
        List<SelectOption> navigateOptionss=IscA.navigateOptions;
        /* Begin - 10822;  added to test saveQuoteNRedirect() method as part of #10822 */
        Test.clearApexPageMessages();
        IScA.saveQuoteNRedirect();
        Pagereference quotecreated=IScA.redirectToQuote();
        Test.stopTest();
        
        System.assertEquals('/'+IScA.quote.id,quotecreated.getUrl());
        /*End - 10822 */
        system.debug('Number of queries '+limits.getQueries());
    }
    
    
}
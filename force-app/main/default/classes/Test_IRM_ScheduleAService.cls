/**  
 * Name            : Test_IRM_ScheduleAService
 * Description     : Test Schedule A Services
 * 
 * Copyright       : Bluewolf
 * Author          : Chris Matthews
 * Modification Log: Created:02-Feb-2013 
 * Gitlab story    : 19277 Removed logic related to PA Model Approval process
 **/
@isTest
private class Test_IRM_ScheduleAService 
{
    public static Id stdPBId = Test.getStandardPricebookId();
    public static final Integer NUM_CUST_ACCT = 10; 
    public static Opportunity   opportunity = null;
    public static Schedule_A__c scheduleA   = null;
    public static List<PricebookEntry> pricebookList=null;
    public static final String BASE_VERSION_NUMBER = '8.0.5';

    @TestSetup
   static void initData()
   {
       /*
       User user = [ select id, name ,currencyisocode
                     from User 
                     where isActive=true 
                     and im_vp__c!=null limit 1 ];
       */
       Country_Settings__c setting = new Country_Settings__c();
       setting.Name = 'United States';
       setting.object_name__c = 'Account';
       insert setting;
       User user = TestingUtil.createUsers(1, false)[0];
       String pricebookName=System.Label.PA_MODEL_PRICE_BOOK;
      
      System.runAs(TestingUtils.ADMIN_USER)
      {
        user.IM_VP__c = UserInfo.getUserId();
        user.CurrencyIsoCode='USD';
        insert user;
      }
      //Custom Setting
		insert new SVStatus__c(Name='SVStatusPassed',Amount__c = 24000,OpptType__c='New Deal,Up-Sell/Lift',Stage__c='6 - Setup');
		//Custom Setting
		List<OpportunityProductSelection__c> opprodsel = new List<OpportunityProductSelection__c >();
        OpportunityProductSelection__c ops = new OpportunityProductSelection__c();
        ops.Name = 'CloudSolutionsProduct';
        ops.Product_Class_Name__c = 'Data Backup and Recovery';
        ops.Product_Class_Name__c = 'Cloud Solutions';
        opprodsel.add(ops);
        
        insert opprodsel;
        //Custom Setting
        // insert opportunity custom setting 
        List<Opportunity_Security__c> oppSettingList = new List<Opportunity_Security__c>();
        Opportunity_Security__c oppSett = new Opportunity_Security__c();
        oppSett.Name = 'Original Lead Owner';
        oppSett.Field_Name__c = 'IM_Original_Lead_Owner__c';
        oppSett.Object_Name__c = 'Opportunity';
        oppSett.Visibility_Access_Level__c = 'W';
        oppSettingList.add(oppSett);
        
        Opportunity_Security__c oppSett1 = new Opportunity_Security__c();
        oppSett1.Name = 'Primary BDE';
        oppSett1.Field_Name__c = 'Primary_BDE__c';
        oppSett1.Object_Name__c = 'Account';
        oppSett1.Visibility_Access_Level__c = 'W';
        oppSettingList.add(oppSett1);
        
        Opportunity_Security__c oppSett2 = new Opportunity_Security__c();
        oppSett2.Name = 'Primary CDE';
        oppSett2.Field_Name__c = 'Primary_CDE__c';
        oppSett2.Object_Name__c = 'Account';
        oppSett2.Visibility_Access_Level__c = 'R';
        oppSettingList.add(oppSett2);
		
        insert oppSettingList;
        QTB_TestDataFactory.createLOBMapping();
      BaseVersionNumber__c baseVersionNumber = BaseVersionNumber__c.getOrgDefaults();
     
        if(baseVersionNumber != null)
        {
            delete [Select Id from BaseVersionNumber__c];
        } 

        BaseVersionNumber__c test = new BaseVersionNumber__c( Version__c = BASE_VERSION_NUMBER);
        insert test;
                    
      system.debug('+++++++++++user++++++++'+user );

       /* Pricebook2 stdpbook = new Pricebook2(Id=stdPBId, Name='Standard Pricebook', isActive=true);
        return stdpbook;*/
        Pricebook2 customPB = new Pricebook2(Name=pricebookName, isActive=true);
        		insert customPB;

        
        List<Product2> testProducts = new List<Product2>();
        for(Integer i=0; i < 1; i++)
        {
        	Product2 testProduct = TestingUtils.createProduct('Test Product'+i, false);
        	testProducts.add(testProduct);
        }
        testProducts[0].IM_Product_Class__c='Data Centers';
        insert testProducts;
        PricebookEntry stdPbe = new PricebookEntry();
        PricebookEntry testPbe = new PricebookEntry();
       
       
       	stdPbe =  TestingUtils.createPriceBookEntry(testProducts[0].Id,stdPBId, false);
   		stdPbe.useStandardPrice = false;
        stdPbe.UnitPrice = 200;
        stdPbe.IsActive = true;
        insert stdPbe;
               
        	testPbe = TestingUtils.createPriceBookEntry(testProducts[0].Id,customPB.id, false);
            testPbe.useStandardPrice = false;
            testPbe.currencyisocode ='USD';
        testPbe.UnitPrice = 100;
        testPbe.IsActive = true;
        insert testPbe;

        
       List<DBRDiscountTypes__c> newDiscountTypes = new List<DBRDiscountTypes__c>();
       newDiscountTypes.add(new DBRDiscountTypes__c(Discount_Type__c = 'service', name = 'Item ABC'));
       newDiscountTypes.add(new DBRDiscountTypes__c(Discount_Type__c = 'sTOrAGE', name = 'Item 123'));
       newDiscountTypes.add(new DBRDiscountTypes__c(Discount_Type__c = 'service', name = 'Item 0123'));
       insert newDiscountTypes;
        
       pricebookList=[select id,name from priceBookEntry where currencyisocode=:user.currencyisocode
                                           and pricebook2.name=:pricebookName and isActive=true limit 3];
        //product2.recordtype.Name='Bill Code' and 
        system.debug('+++++++++pb list++++'+pricebookList);     
       
       //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
      Account accc = TestingUtils.createAccounts(1, true)[0];
       opportunity = new Opportunity();
       opportunity.name        = 'Test Opportunity';
       opportunity.IM_Booked_Date__c   = System.now().date();
       opportunity.StageName   = '1 - Qualification';
       opportunity.ownerid     = user.id;
       opportunity.accountid =accc.id;
       opportunity.Lead_Source_Most_Recent__c = 'Email';
       opportunity.currencyisocode=User.currencyisocode;
        opportunity.CloseDate = System.today();
       insert opportunity;
        //added currency tag to test xml
       String xml =              
           '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+
           '<schedulea xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
           '           <CustomerName>Test Customer</CustomerName>'+
           '           <IMGA>IM_Customer</IMGA>'+
           '           <Salesseg>Non-Territory Sales Team</Salesseg>'+
           '           <Industry>Sales Vertical</Industry>'+
           '           <Country>USA</Country>'+
           '           <Currency>'+User.currencyisocode+'</Currency>'+
           '           <AWSRequestID>0</AWSRequestID>'+
           '           <CustomerIDs>adfe2,31fd,21wda</CustomerIDs>'+
           '           <pricingpromotions>0</pricingpromotions>'+
           '           <totalrevenue>673737.26</totalrevenue>'+
           '           <revenuedelta>-895.56</revenuedelta>'+
           '           <margindelta>503.91</margindelta>'+
           '           <RMcontractlength>1</RMcontractlength>'+
           '           <largestmarket1>0</largestmarket1>'+
           '           <largestmarketvolume1>0</largestmarketvolume1>'+
           '           <largestmarket2>0</largestmarket2>'+
           '           <largestmarketvolume2>0</largestmarketvolume2>'+
           '           <largestmarket3>0</largestmarket3>'+
           '           <largestmarketvolume3>0</largestmarketvolume3>'+
           '           <RM-PriceDecrease>0</RM-PriceDecrease>'+
           '           <RM-Vended>0</RM-Vended>'+
           '           <RM-Competition>0</RM-Competition>'+
           '           <DM-PriceDecrease>0</DM-PriceDecrease>'+
           '           <DM-Vended>0</DM-Vended>'+
           '           <DM-Competition>0</DM-Competition>'+
           '           <SS-PriceDecrease>0</SS-PriceDecrease>'+
           '           <SS-Vended>0</SS-Vended>'+
           '           <SS-Competition>0</SS-Competition>'+
           '           <currentstoragevolume>125000</currentstoragevolume>'+
           '           <currentstorageprice>0.201</currentstorageprice>'+
           '           <newstoragevolume>0</newstoragevolume>'+
           '           <newstorageprice>0.203</newstorageprice>'+
           '           <ListPriceYear>2022</ListPriceYear>'+
           '           <currenteffectivediscount>0</currenteffectivediscount>'+
           '           <RMStoragelistpricediscount>0</RMStoragelistpricediscount>'+
           '           <RMServicelistpricediscount>0</RMServicelistpricediscount>'+
           '           <estimatedyear1revenue>720337.26</estimatedyear1revenue>'+
           '           <revenueyeartargetpricing>833221.16</revenueyeartargetpricing>'+
           '           <revenueatlistpricing>2065394.33</revenueatlistpricing>'+
           '           <totalcontractrevenue>673737.26</totalcontractrevenue>'+
           '           <RMEffectiveDiscount>65.1</RMEffectiveDiscount>'+
           '           <includeclawback>1</includeclawback>'+
           '           <DMcontractlength>1</DMcontractlength>'+
           '           <DBRStorageEffectiveDiscount/>'+
           '           <DBRServiceEffectiveDiscount>0</DBRServiceEffectiveDiscount>'+
           '           <DBRStoragelistpricediscount>100</DBRStoragelistpricediscount>'+
           '           <DBRServicelistpricediscount>0</DBRServicelistpricediscount>'+
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
           '           <DMOther>false</DMOther>'+
           '           <SSMultiyear>false</SSMultiyear>'+
           '           <SSTieredPricing>false</SSTieredPricing>'+
           '           <SSOther>false</SSOther>'+
           '           <Financing>false</Financing>'+
           '           <Rebate>false</Rebate>'+
           '           <Retroactive>false</Retroactive>'+
           '			<dealsummary1>Test Deal Summary</dealsummary1>'+
           '           <NonStandardServices>false</NonStandardServices>'+
           '			<nonbillableterm1>Test Bill Term1</nonbillableterm1>'+          
           '           <AdditionalTerms1/>'+
           '           <AdditionalTerms2>The customers RM contract must be extended until September 11, 2024</AdditionalTerms2>'+
           '           <AdditionalTerms3/>'+
           '           <AdditionalTerms4>0</AdditionalTerms4>'+
           '           <AdditionalTerms5>0</AdditionalTerms5>'+
           '           <AdditionalTerms6>0</AdditionalTerms6>'+
           '           <AdditionalTerms7>0</AdditionalTerms7>'+
           '           <AdditionalTerms8>0</AdditionalTerms8>'+
           '           <XODStudies>0</XODStudies>'+
           '           <XODProgramfee>0</XODProgramfee>'+
           '           <XODPerunit>0</XODPerunit>'+
           '           <Newrev>304650</Newrev>'+
           '			<costtoirm1>123</costtoirm1>'+
           '			<programpricing>234</programpricing>'+          
           '           <Investment>200000</Investment>'+
           '           <TotalCost>273374.217647138</TotalCost>'+
           '           <TotalCashBasedCost>273374.2176</TotalCashBasedCost>'+
           '           <ServiceHours>12</ServiceHours>'+
           '           <ServiceLaborCost>2</ServiceLaborCost>'+
           '			<floorrevenue>1234</floorrevenue>'+
           '           <RevenueDilution>-0.13</RevenueDilution>'+
           '           <quoteLines>'+
           '                   <quoteItem>'+
           '                           <productNumber>'+pricebookList[0].Name+'</productNumber>'+
           '                           <listprice>1.02</listprice>'+
           '                           <currentprice>0.201</currentprice>'+
           '                           <currentvolume>125000</currentvolume>'+
           '                           <currentrevenue>304243.65</currentrevenue>'+
           '                           <proposedprice>0.203</proposedprice>'+
           '                           <proposedvolume>125000</proposedvolume>'+
           '                           <proposedrevenue>307422.315</proposedrevenue>'+
           '                           <yr2price>0.211</yr2price>'+
           '                           <yr3price>0.22</yr3price>'+
           '                           <yr4price>0.228</yr4price>'+
           '                           <yr5price>0.238</yr5price>'+
           '                           <yr6price>0.247</yr6price>'+
           '                           <yr7price>0.257</yr7price>'+
           '                           <yr8price>0.267</yr8price>'+
           '                           <yr9price>0.278</yr9price>'+
           '                           <yr10price>0.289</yr10price>'+
           '                           <keepflag>1</keepflag>'+
           '                           <targetprice>0.232</targetprice>'+
           '                           <forecastableflag>0</forecastableflag>'+
           '                           <unitcost>0.0646439383833079</unitcost>'+
           '                           <floorprice>0.201</floorprice>'+
           '                           <unitcostcashview>0.0646439383833079</unitcostcashview>'+
           '                   </quoteItem>'+
           '                   <quoteItem>'+
           '                           <productNumber>'+pricebookList[0].Name+'</productNumber>'+
           '                           <listprice>1.02</listprice>'+
           '                           <currentprice>0</currentprice>'+
           '                           <currentvolume>0</currentvolume>'+
           '                           <currentrevenue>0</currentrevenue>'+
           '                           <proposedprice>0.203</proposedprice>'+
           '                           <proposedvolume>0</proposedvolume>'+
           '                           <proposedrevenue>0</proposedrevenue>'+
           '                           <yr2price>0.211</yr2price>'+
           '                           <yr3price>0.22</yr3price>'+
           '                           <yr4price>0.228</yr4price>'+
           '                           <yr5price>0.238</yr5price>'+
           '                           <yr6price>0.247</yr6price>'+
           '                           <yr7price>0.257</yr7price>'+
           '                           <yr8price>0.267</yr8price>'+
           '                           <yr9price>0.278</yr9price>'+
           '                           <yr10price>0.289</yr10price>'+
           '                           <keepflag>1</keepflag>'+
           '                           <targetprice>0.232</targetprice>'+
           '                           <forecastableflag>1</forecastableflag>'+
           '                           <unitcost>0.0646439383833079</unitcost>'+
           '                           <floorprice>0.201</floorprice>'+
           '                           <unitcostcashview>0.0646439383833079</unitcostcashview>'+
           '                   </quoteItem>'+
           '                   <quoteItem>'+
           '                           <productNumber>'+pricebookList[0].Name+'</productNumber>'+
           '                           <keepflag>1</keepflag>'+
           '                           <targetprice>0</targetprice>'+
           '                           <forecastableflag>1</forecastableflag>'+
           '                           <unitcost>100</unitcost>'+
           '                           <floorprice>0</floorprice>'+
           '                           <unitcostcashview>0</unitcostcashview>'+
           '                   </quoteItem>'+
           '           </quoteLines>'+
           '</schedulea>'  ;
       
       scheduleA = 
           IRM_ScheduleAParseXML.parseXML( 'TestScheduleA', 
                                            xml,
                                            opportunity.id ); 
       /*Gitlab: 19277 code cleanup                                     
       scheduleA.Approver_1__c       = user.id;
       scheduleA.Approver_1_Title__c = 'Title 1';
       scheduleA.Approver_2__c = user.id;
       scheduleA.Approver_2_Title__c = 'Title 2';
       scheduleA.Approver_3__c = user.id;
       scheduleA.Approver_3_Title__c = 'Title 3';
       scheduleA.Approver_4__c = user.id;
       scheduleA.Approver_4_Title__c = 'Title 4';       
       scheduleA.Approver_5__c = user.id;
       scheduleA.Approver_5_Title__c = 'Title 5';       
       scheduleA.Approver_6__c = user.id;       
       scheduleA.Approver_6_Title__c = 'Title 6';*/
       
       //upsert scheduleA;
       system.debug('scheduleAtest>>'+scheduleA);
       update scheduleA;    																  //#30912 PA Model LINES field clean up
       Schedule_A_Quote_Item__c sq = new Schedule_A_Quote_Item__c(Schedule_A__c = scheduleA.id, /*Offering_Type__c = 'TEST_TYPE',*/ proposed_volume__c =5, PBE__c= testPbe.id);

    insert sq;
       string iddd=scheduleA.id;
    list<Schedule_A__c>  cg = [select id,(select id from Schedule_A_Quote_Items__r) from Schedule_A__c where id =:iddd];
       system.debug('scheduleAtestidsq>>'+cg);
       system.debug('scheduleAtestidsq>>'+sq);
       system.debug('scheduleAtestid>>'+scheduleA.Schedule_A_Quote_Items__r);
       
   }
    public static testMethod void testingSenario() {
        
    Test.startTest();
        	
        IRM_ScheduleAService serviceInstance = new IRM_ScheduleAService();
       //init();
       list<Schedule_A__c> scheduleAlst = Database.query('SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Schedule_A__c').getDescribe().fields.getMap().keySet()), ',') + ' FROM Schedule_A__c limit 1');
        Schedule_A__c scheduleA = scheduleAlst[0];
        IRM_ScheduleAService.lockScheduleAQuoteItems(scheduleA);
        system.debug('scheduleA.id >>>>>>>>>'+scheduleA.id );
        List<Schedule_A_Quote_Item__c> qitemList = serviceInstance.getScheduleAQuoteItemList(scheduleA.id);
        String discount = IRM_ScheduleAService.getDiscountType(qitemList[0]);    
      
        Test.stopTest();
    
    }
    public static testMethod void testSenario1() 
    {
        Test.startTest();
        IRM_ScheduleAService service = new IRM_ScheduleAService();
       // init(); 
       list<opportunity> op = Database.query('SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('opportunity').getDescribe().fields.getMap().keySet()), ',') + ' FROM opportunity limit 1');  
       opportunity opportunity = op[0];
       list<Schedule_A__c> schedulelist = Database.query('SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Schedule_A__c').getDescribe().fields.getMap().keySet()), ',') + ' FROM Schedule_A__c limit 1');  
       Schedule_A__c scheduleA = schedulelist[0];
        system.debug('scheduleAid>>>>>>>>>'+scheduleA.id);
        IRM_ScheduleAService.lockScheduleAQuoteItems(scheduleA);
        system.debug('scheduleAid>>>>>>>>>'+scheduleA.id);
        List<Schedule_A_Quote_Item__c> qitemList = service.getScheduleAQuoteItemList( scheduleA.id );
        IRM_ScheduleAService.checkFileIsUploaded('TestA');
        service.getOpportunity( opportunity.id );
        service.getScheduleA( scheduleA.Id );
        service.getScheduleAList( opportunity.id, false );
        service.getScheduleAList( opportunity.id, true );
       // Account acc = TestingUtils.createAccounts(1, true)[0];
        //acc.IM_Hierarchy_Level__c ='IM Group (IMGA)';Parent HQ
       
        //acc.IM_Hierarchy_Level__c ='Parent HQ';
        //insert acc;

        //opportunity.accountId = acc.Id;
        //update opportunity;
        service.getScheduleAList( opportunity.id, false );
        service.getScheduleAList( opportunity.id, true );
        service.getOpportunityFields(opportunity.id);
        //
         List<Schedule_A_Quote_Item__c>  scheAQuote = TestingUtils.createPAModelLineItems(scheduleA.id, 2, true );
        system.debug('===>scheduleA'+scheduleA);
        system.debug('===>scheduleA-->'+scheduleA.Schedule_A_Quote_Items__r);
        //
        service.createQuoteFromScheduleA( opportunity.id, scheduleA, false, 10, 350, 'RM');
                        
        List<Schedule_A__c> saOld  = new List<Schedule_A__c>();
        List<Schedule_A__c> saList = new List<Schedule_A__c>();
        saList.add(scheduleA);

        List<Schedule_A_Quote_Item__c> saqOld  = new List<Schedule_A_Quote_Item__c>();
        List<Schedule_A__c> sche = TestingUtils.createPAModels(1, true);
        system.debug(sche+'!!!!!!!!');
        opportunity.type = 'Renewal';
        update opportunity;
        sche[0].New_Storage_Volume__c = 450;
        update sche[0];
        
        List<Schedule_A_Quote_Item__c> saqOldList = TestingUtils.createPAModelLineItems(scheduleA.id, 1, false);
        saqOldList[0].PBE__c='01u800000060Yp3AAE';
        saqOldList[0].proposed_volume__c=1234;
        upsert saqOldList;
        
        service.createQuoteFromScheduleA( opportunity.id, sche[0], false, 10, 350, null);
        
        system.debug('$$$$$$'+saqOldList);
        saqOld = service.getScheduleAQuoteItemList(sche[0].id);
        system.debug(saqOld+'&&&&&&&&&');
        List<Schedule_A_Quote_Item__c> saqList = service.getScheduleAQuoteItemList( scheduleA.id );
        system.debug(saqList+'@@@'+saqOld);
        IRM_ScheduleAService.lockScheduleA( saList, saOld );
        IRM_ScheduleAService.lockScheduleAQuoteItemVerification( saqList, saqOld );
        Test.stopTest();
    }
    
    public static testMethod void testBadData()
    {
       Test.startTest();
        
        IRM_ScheduleAService service = new IRM_ScheduleAService();
        
       //init();

        IRM_ScheduleAService.checkFileIsUploaded( null );
        
        service.getOpportunity( null );
        service.getScheduleA( null );
        //service.getScheduleAList( null, false );
        //service.getScheduleAList( null, true );

        service.getScheduleAQuoteItemList( null );
        service.createQuoteFromScheduleA( null, null, null, null, null, null );
                
        List<Schedule_A_Quote_Item__c> qitemList = 
             service.getScheduleAQuoteItemList( null);
        
        IRM_ScheduleAService.lockScheduleA( null, null );
        IRM_ScheduleAService.lockScheduleAQuoteItemVerification( null, null );  
       
        Test.stopTest();
    }
    
    public static testMethod void  testValidateDiscountWithExemptList(){
      
        
        List<Discount_Exempt_Bill_Codes__c> exemptCodes = new List<Discount_Exempt_Bill_Codes__c>();
        exemptCodes.add(new Discount_Exempt_Bill_Codes__c(name = '290'));
        exemptCodes.add(new Discount_Exempt_Bill_Codes__c(name = 'ABC 150'));
        insert exemptCodes;
        
        Product2 exemptProduct = TestingUtils.createProduct('ABC 150', false);
        Product2 notExemptProduct = TestingUtils.createProduct('ABC 2900', false);
        TestingUtils.dummyInsert( new List<Product2> {exemptProduct, notExemptProduct});
        
        
        Schedule_A__c schedA = TestingUtils.createPAModels(1, false)[0];
        TestingUtils.dummyInsert(new List<Schedule_A__c>{schedA});
        
        List<Schedule_A_Quote_Item__c> scheduleALineItems = TestingUtils.createPAModelLineItems(schedA.Id, 2, false);
        TestingUtils.dummyInsert(scheduleALineItems);
        
        Schedule_A_Quote_Item__c exemptItem = scheduleALineItems[0]; 
        exemptItem.product__c = exemptProduct.id;
        Schedule_A_Quote_Item__c notExemptItem = scheduleALineItems[1];
        exemptItem.product__c = notExemptProduct.id;
        
        Boolean isExempt;
        Boolean notExempt;
        
        Test.startTest();
            isExempt = IRM_ScheduleAService.validateDiscountWithExemptList(exemptProduct.name);
            notExempt = IRM_ScheduleAService.validateDiscountWithExemptList(notExemptProduct.name);
        Test.stopTest();
        
        System.AssertEquals(true, isExempt, 'The first line item should be exempt from discounts.');
        System.AssertEquals(false, notExempt, 'The second line item should not be exempt from discounts.');
    }
    
    public static testMethod void testGetDbrDiscountType(){
       
       /*List<DBRDiscountTypes__c> newDiscountTypes = new List<DBRDiscountTypes__c>();
       newDiscountTypes.add(new DBRDiscountTypes__c(Discount_Type__c = 'service', name = 'Item ABC'));
       newDiscountTypes.add(new DBRDiscountTypes__c(Discount_Type__c = 'sTOrAGE', name = 'Item 123'));
       newDiscountTypes.add(new DBRDiscountTypes__c(Discount_Type__c = 'service', name = 'Item 0123'));
       insert newDiscountTypes;*/
       
       String storageProduct;
       String serviceProduct;
       String nullProduct;
       
       Test.startTest();
           serviceProduct = IRM_ScheduleAService.getDbrDiscountType('item abc');
           storageProduct = IRM_ScheduleAService.getDbrDiscountType('item 123');
           nullProduct = IRM_ScheduleAService.getDbrDiscountType('item 0');
       Test.stopTest();
       
       System.AssertEquals(IRM_ScheduleAService.Service, serviceProduct, 'An incorrect discount type is being returned for the storage product.');
       System.AssertEquals(IRM_ScheduleAService.Storage, storageProduct, 'An incorrect discount type is being returned for the service product.');
       System.AssertEquals(null, nullProduct, 'An incorrect discount type is being returned for the service product.');
    }
    
    public static testMethod void testGetScheduleACustomerAccounts()
    {
    
        Schedule_A__c schedA = TestingUtils.createPAModels(1, true)[0];
        
        Account acc = TestingUtils.createAccounts(1, true)[0];
        List<IM_Customer_Account__c> customerAccounts = TestingUtils.createCustomerAccounts(NUM_CUST_ACCT, acc.Id, true);
        
        Set<Id> expectedCustomerAccountIds = Pluck.Ids(customerAccounts);
        
        List<Schedule_A_Customer_Account__c> expectedScheduleACustAccts = new List<Schedule_A_Customer_Account__c>();
        for(IM_Customer_Account__c aCustAccount: customerAccounts)
            expectedScheduleACustAccts.add(new Schedule_A_Customer_Account__c(Schedule_A__c = schedA.Id, Customer_Account__c = aCustAccount.Id));
        insert expectedScheduleACustAccts;
        
        IRM_ScheduleAService serviceCont = new IRM_ScheduleAService();
        system.debug('===>'+[Select Id, Customer_Account__c From Schedule_A_Customer_Account__c Where Schedule_A__c = :schedA.id]);
        Test.startTest();
            List<Schedule_A_Customer_Account__c> resultScheduleACustAccts = serviceCont.getScheduleACustomerAccounts(schedA.Id);
        Test.stopTest();
        
        Set<Id> resultCustAcctsIds = Pluck.ids('Customer_Account__c', resultScheduleACustAccts);
        system.assertEquals(expectedScheduleACustAccts.size(), resultScheduleACustAccts.size(),'Correct number of Schedule A Customer Accounts are set');
        system.assert(resultCustAcctsIds == expectedCustomerAccountIds, 'The correct scheduleA accounts are created');
    }
    
    public static testMethod void testGetScheduleACustomerAccounts_NoScheduleAJunctionObjs()
    {
       
        Schedule_A__c schedA = TestingUtils.createPAModels(1, true)[0];
        IRM_ScheduleAService serviceCont = new IRM_ScheduleAService();
        Test.startTest();
            List<Schedule_A_Customer_Account__c> resultScheduleACustAccts = serviceCont.getScheduleACustomerAccounts(schedA.Id);
        Test.stopTest();
        system.assertEquals(0, resultScheduleACustAccts.size(),'Correct number of Schedule A Customer Accounts are set');
    }
 

       
}
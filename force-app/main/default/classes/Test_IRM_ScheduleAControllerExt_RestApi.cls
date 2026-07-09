@isTest
public class Test_IRM_ScheduleAControllerExt_RestApi {
    static string countryId='';
    public static final Id Bill_codeRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Bill Code').getRecordTypeId();
    private static final String BASE_VERSION_NUMBER = '10.10.10';
    
    static string successXML='<?xml version="1.0" encoding="UTF-8"?>' +
                            '<schedulea>' +
                              '<CustomerName>Tillicoultyry Quarries Limited</CustomerName>' +
                              '<IMGA>IM_CORVALLIS_PROFESSIONAL_FIREFIGHTERS_CHARITY_FUND</IMGA>' +
                              '<Salesseg/>' +
                              '<Industry>A</Industry>' +
                              '<Country>United Kingdom</Country>' +
                              '<Currency>USD</Currency>' +
                              '<AWSRequestID>0</AWSRequestID>' +
                              '<CustomerIDs>adfe2</CustomerIDs>' +
                              '<pricingpromotions>0</pricingpromotions>' +
                              '<totalrevenue>236662</totalrevenue>' +
                              '<revenuedelta>-5264</revenuedelta>' +
                              '<margindelta>0</margindelta>' +
                              '<numberofapprovers>0</numberofapprovers>' +
                              '<RMcontractlength>36</RMcontractlength>' +
                              '<largestmarket1>CalgaryAB</largestmarket1>' +
                              '<largestmarketvolume1>10000</largestmarketvolume1>' +
                              '<largestmarket2>EdmontonAB</largestmarket2>' +
                              '<largestmarketvolume2>8000</largestmarketvolume2>' +
                              '<largestmarket3>HalifaxNS</largestmarket3>' +
                              '<largestmarketvolume3>6000</largestmarketvolume3>' +
                              '<RM-PriceDecrease>0</RM-PriceDecrease>' +
                              '<RM-Vended>UnvendedOffSite</RM-Vended>' +
                              '<RM-Competition>High</RM-Competition>' +
                              '<DM-PriceDecrease>B</DM-PriceDecrease>' +
                              '<DM-Vended>VendedOffSite</DM-Vended>' +
                              '<DM-Competition>Low</DM-Competition>' +
                              '<SS-PriceDecrease>C</SS-PriceDecrease>' +
                              '<SS-Vended>UnvendedOnSite</SS-Vended>' +
                              '<SS-Competition>Low</SS-Competition>' +
                              '<currentstoragevolume>303</currentstoragevolume>' +
                              '<currentstorageprice>2.28</currentstorageprice>' +
                              '<newstoragevolume>0</newstoragevolume>' +
                              '<newstorageprice>2.5</newstorageprice>' +
                              '<ListPriceYear>0</ListPriceYear>' +
                              '<currenteffectivediscount>0</currenteffectivediscount>' +
                              '<RMStoragelistpricediscount>0</RMStoragelistpricediscount>' +
                              '<RMServicelistpricediscount>0</RMServicelistpricediscount>' +
                              '<estimatedyear1revenue>13902</estimatedyear1revenue>' +
                              '<revenueyeartargetpricing>0</revenueyeartargetpricing>' +
                              '<revenueatlistpricing>0</revenueatlistpricing>' +
                              '<totalcontractrevenue>44879.12</totalcontractrevenue>' +
                              '<RMEffectiveDiscount>0</RMEffectiveDiscount>' +
                              '<includeclawback>0</includeclawback>' +
                              '<DMcontractlength>24</DMcontractlength>' +
                              '<DBRStorageEffectiveDiscount>0</DBRStorageEffectiveDiscount>' +
                              '<DBRServiceEffectiveDiscount>0</DBRServiceEffectiveDiscount>' +
                              '<DBRStoragelistpricediscount>0</DBRStoragelistpricediscount>' +
                              '<DBRServicelistpricediscount>0</DBRServicelistpricediscount>' +
                              '<SScontractlength>0</SScontractlength>' +
                              '<NumberOfShredLocations>0</NumberOfShredLocations>' +
                              '<PAVersion>10.10.10</PAVersion>' +
                              '<RMMultiyear>0</RMMultiyear>' +
                              '<RMFUI>false</RMFUI>' +
                              '<RMPWPaid>false</RMPWPaid>' +
                              '<RMUnvended>false</RMUnvended>' +
                              '<RMProgramPricing>false</RMProgramPricing>' +
                              '<RMTieredPricing>false</RMTieredPricing>' +
                              '<RMFreeStorage>false</RMFreeStorage>' +
                              '<RMFreeServices>false</RMFreeServices>' +
                              '<RMFreeStorageviaWA>false</RMFreeStorageviaWA>' +
                              '<RMFreeServicesviaWA>false</RMFreeServicesviaWA>' +
                              '<RMOther>0</RMOther>' +
                              '<DMMultiyear>0</DMMultiyear>' +
                              '<DMTieredPricing>0</DMTieredPricing>' +
                              '<DMOther>0</DMOther>' +
                              '<SSMultiyear>0</SSMultiyear>' +
                              '<SSTieredPricing>false</SSTieredPricing>' +
                              '<SSOther>false</SSOther>' +
                              '<Financing>false</Financing>' +
                              '<Rebate>false</Rebate>' +
                              '<Retroactive>false</Retroactive>' +
                              '<NonStandardServices>false</NonStandardServices>' +
                              '<XODStudies>0</XODStudies>' +
                              '<XODProgramfee>0</XODProgramfee>' +
                              '<XODPerunit>0</XODPerunit>' +
                              '<Newrev>0</Newrev>' +
                              '<ShredRevenues_1>-5264</ShredRevenues_1>' +
                              '<Investment>0</Investment>' +
                              '<TotalCost>0</TotalCost>' +
                              '<TotalCashBasedCost>0</TotalCashBasedCost>' +
                              '<ServiceHours>118490</ServiceHours>' +
                              '<ServiceLaborCost>102914</ServiceLaborCost>' +
                              '<RevenueDilution>0</RevenueDilution>' +
                              '<FloorRevenue>30.7058</FloorRevenue>' +
                              '<FloorRevenueRealization>-0.274653031409788</FloorRevenueRealization>' +
                              '<RedFlagItems>0</RedFlagItems>' +
                              '<RevenueDilutionDollar>118.660282283336</RevenueDilutionDollar>' +
                              '<quoteLines>' +
                                '<quoteItem>' +
                                  '<productNumber>890</productNumber>' +
                                  '<listprice>0</listprice>' +
                                  '<currentprice>0</currentprice>' +
                                  '<currentvolume>0</currentvolume>' +
                                  '<currentrevenue>0</currentrevenue>' +
                                  '<proposedprice>0</proposedprice>' +
                                  '<proposedvolume>0</proposedvolume>' +
                                  '<proposedrevenue>0</proposedrevenue>' +
                                  '<yr2price>0</yr2price>' +
                                  '<yr3price>0</yr3price>' +
                                  '<yr4price>0</yr4price>' +
                                  '<yr5price>0</yr5price>' +
                                  '<yr6price>0</yr6price>' +
                                  '<yr7price>0</yr7price>' +
                                  '<yr8price>0</yr8price>' +
                                  '<yr9price>0</yr9price>' +
                                  '<yr10price>0</yr10price>' +
                                  '<keepflag>1</keepflag>' +
                                  '<targetprice>0</targetprice>' +
                                  '<forecastableflag>0</forecastableflag>' +
                                  '<unitcost>0</unitcost>' +
                                  '<floorprice>0</floorprice>' +
                                  '<unitcostcashview>0</unitcostcashview>' +
                                '</quoteItem>' +
                              '</quoteLines>' +
                            '</schedulea>';
    static string errorXML='<?xml version="1.0" encoding="UTF-8"?>' +
                            '<schedulea>' +
                              '<QuoteNumber>P-1703</QuoteNumber>' +
                              '<QuoteDescription>IM_TILLICOULTRY_QUARRIES_1931_LIMITED</QuoteDescription>' +
                              '<CustomerName>Tillicoultyry Quarries Limited</CustomerName>' +
                              '<IMGA>IM_CORVALLIS_PROFESSIONAL_FIREFIGHTERS_CHARITY_FUND</IMGA>' +
                              '<Salesseg/>' +
                              '<Industry>A</Industry>' +
                              '<Country>United Kingdom</Country>' +
                              '<Currency>GBP</Currency>' +
                              '<AWSRequestID>0</AWSRequestID>' +
                              '<CustomerIDs>adfe2</CustomerIDs>' +
                              '<pricingpromotions>0</pricingpromotions>' +
                              '<totalrevenue>236662</totalrevenue>' +
                              '<revenuedelta>-5264</revenuedelta>' +
                              '<margindelta>0</margindelta>' +
                              '<numberofapprovers>0</numberofapprovers>' +
                              '<RMcontractlength>36</RMcontractlength>' +
                              '<largestmarket1>CalgaryAB</largestmarket1>' +
                              '<largestmarketvolume1>10000</largestmarketvolume1>' +
                              '<largestmarket2>EdmontonAB</largestmarket2>' +
                              '<largestmarketvolume2>8000</largestmarketvolume2>' +
                              '<largestmarket3>HalifaxNS</largestmarket3>' +
                              '<largestmarketvolume3>6000</largestmarketvolume3>' +
                              '<RM-PriceDecrease>0</RM-PriceDecrease>' +
                              '<RM-Vended>UnvendedOffSite</RM-Vended>' +
                              '<RM-Competition>High</RM-Competition>' +
                              '<DM-PriceDecrease>B</DM-PriceDecrease>' +
                              '<DM-Vended>VendedOffSite</DM-Vended>' +
                              '<DM-Competition>Low</DM-Competition>' +
                              '<SS-PriceDecrease>C</SS-PriceDecrease>' +
                              '<SS-Vended>UnvendedOnSite</SS-Vended>' +
                              '<SS-Competition>Low</SS-Competition>' +
                              '<currentstoragevolume>303</currentstoragevolume>' +
                              '<currentstorageprice>2.28</currentstorageprice>' +
                              '<newstoragevolume>0</newstoragevolume>' +
                              '<newstorageprice>2.5</newstorageprice>' +
                              '<ListPriceYear>0</ListPriceYear>' +
                              '<currenteffectivediscount>0</currenteffectivediscount>' +
                              '<RMStoragelistpricediscount>0</RMStoragelistpricediscount>' +
                              '<RMServicelistpricediscount>0</RMServicelistpricediscount>' +
                              '<estimatedyear1revenue>13902</estimatedyear1revenue>' +
                              '<revenueyeartargetpricing>0</revenueyeartargetpricing>' +
                              '<revenueatlistpricing>0</revenueatlistpricing>' +
                              '<totalcontractrevenue>44879.12</totalcontractrevenue>' +
                              '<RMEffectiveDiscount>0</RMEffectiveDiscount>' +
                              '<includeclawback>0</includeclawback>' +
                              '<DMcontractlength>24</DMcontractlength>' +
                              '<DBRStorageEffectiveDiscount>0</DBRStorageEffectiveDiscount>' +
                              '<DBRServiceEffectiveDiscount>0</DBRServiceEffectiveDiscount>' +
                              '<DBRStoragelistpricediscount>0</DBRStoragelistpricediscount>' +
                              '<DBRServicelistpricediscount>0</DBRServicelistpricediscount>' +
                              '<SScontractlength>0</SScontractlength>' +
                              '<NumberOfShredLocations>0</NumberOfShredLocations>' +
                              '<PAVersion>10.10.10</PAVersion>' +
                              '<RMMultiyear>0</RMMultiyear>' +
                              '<RMFUI>false</RMFUI>' +
                              '<RMPWPaid>false</RMPWPaid>' +
                              '<RMUnvended>false</RMUnvended>' +
                              '<RMProgramPricing>false</RMProgramPricing>' +
                              '<RMTieredPricing>false</RMTieredPricing>' +
                              '<RMFreeStorage>false</RMFreeStorage>' +
                              '<RMFreeServices>false</RMFreeServices>' +
                              '<RMFreeStorageviaWA>false</RMFreeStorageviaWA>' +
                              '<RMFreeServicesviaWA>false</RMFreeServicesviaWA>' +
                              '<RMOther>0</RMOther>' +
                              '<DMMultiyear>0</DMMultiyear>' +
                              '<DMTieredPricing>0</DMTieredPricing>' +
                              '<DMOther>0</DMOther>' +
                              '<SSMultiyear>0</SSMultiyear>' +
                              '<SSTieredPricing>false</SSTieredPricing>' +
                              '<SSOther>false</SSOther>' +
                              '<Financing>false</Financing>' +
                              '<Rebate>false</Rebate>' +
                              '<Retroactive>false</Retroactive>' +
                              '<NonStandardServices>false</NonStandardServices>' +
                              '<XODStudies>0</XODStudies>' +
                              '<XODProgramfee>0</XODProgramfee>' +
                              '<XODPerunit>0</XODPerunit>' +
                              '<Newrev>0</Newrev>' +
                              '<ShredRevenues_1>-5264</ShredRevenues_1>' +
                              '<Investment>0</Investment>' +
                              '<TotalCost>0</TotalCost>' +
                              '<TotalCashBasedCost>0</TotalCashBasedCost>' +
                              '<ServiceHours>118490</ServiceHours>' +
                              '<ServiceLaborCost>102914</ServiceLaborCost>' +
                              '<RevenueDilution>0</RevenueDilution>' +
                              '<FloorRevenue>30.7058</FloorRevenue>' +
                              '<FloorRevenueRealization>-0.274653031409788</FloorRevenueRealization>' +
                              '<RedFlagItems>0</RedFlagItems>' +
                              '<RevenueDilutionDollar>118.660282283336</RevenueDilutionDollar>' +
                              '<quoteLines>' +
                                '<quoteItem>' +
                                  '<productNumber>890</productNumber>' +
                                  '<listprice>0</listprice>' +
                                  '<currentprice>0</currentprice>' +
                                  '<currentvolume>0</currentvolume>' +
                                  '<currentrevenue>0</currentrevenue>' +
                                  '<proposedprice>0</proposedprice>' +
                                  '<proposedvolume>0</proposedvolume>' +
                                  '<proposedrevenue>0</proposedrevenue>' +
                                  '<yr2price>0</yr2price>' +
                                  '<yr3price>0</yr3price>' +
                                  '<yr4price>0</yr4price>' +
                                  '<yr5price>0</yr5price>' +
                                  '<yr6price>0</yr6price>' +
                                  '<yr7price>0</yr7price>' +
                                  '<yr8price>0</yr8price>' +
                                  '<yr9price>0</yr9price>' +
                                  '<yr10price>0</yr10price>' +
                                  '<keepflag>1</keepflag>' +
                                  '<targetprice>0</targetprice>' +
                                  '<forecastableflag>0</forecastableflag>' +
                                  '<unitcost>0</unitcost>' +
                                  '<floorprice>0</floorprice>' +
                                  '<unitcostcashview>0</unitcostcashview>' +
                                '</quoteItem>' +
                              '</quoteLines>' +
                            '</schedulea>';
    static string warningXML='<?xml version="1.0" encoding="UTF-8"?>' +
                            '<schedulea>' +
                              '<CustomerName>Tillicoultyry Quarries Limited</CustomerName>' +
                              '<IMGA>IM_CORVALLIS_PROFESSIONAL_FIREFIGHTERS_CHARITY_FUND</IMGA>' +
                              '<Salesseg/>' +
                              '<Industry>A</Industry>' +
                              '<Country>United Kingdom</Country>' +
                              '<Currency>USD</Currency>' +
                              '<AWSRequestID>0</AWSRequestID>' +
                              '<CustomerIDs>adfe2</CustomerIDs>' +
                              '<pricingpromotions>0</pricingpromotions>' +
                              '<totalrevenue>236662</totalrevenue>' +
                              '<revenuedelta>-5264</revenuedelta>' +
                              '<margindelta>0</margindelta>' +
                              '<numberofapprovers>0</numberofapprovers>' +
                              '<RMcontractlength>36</RMcontractlength>' +
                              '<largestmarket1>CalgaryAB</largestmarket1>' +
                              '<largestmarketvolume1>10000</largestmarketvolume1>' +
                              '<largestmarket2>EdmontonAB</largestmarket2>' +
                              '<largestmarketvolume2>8000</largestmarketvolume2>' +
                              '<largestmarket3>HalifaxNS</largestmarket3>' +
                              '<largestmarketvolume3>6000</largestmarketvolume3>' +
                              '<RM-PriceDecrease>0</RM-PriceDecrease>' +
                              '<RM-Vended>UnvendedOffSite</RM-Vended>' +
                              '<RM-Competition>High</RM-Competition>' +
                              '<DM-PriceDecrease>B</DM-PriceDecrease>' +
                              '<DM-Vended>VendedOffSite</DM-Vended>' +
                              '<DM-Competition>Low</DM-Competition>' +
                              '<SS-PriceDecrease>C</SS-PriceDecrease>' +
                              '<SS-Vended>UnvendedOnSite</SS-Vended>' +
                              '<SS-Competition>Low</SS-Competition>' +
                              '<currentstoragevolume>303</currentstoragevolume>' +
                              '<currentstorageprice>2.28</currentstorageprice>' +
                              '<newstoragevolume>0</newstoragevolume>' +
                              '<newstorageprice>2.5</newstorageprice>' +
                              '<ListPriceYear>0</ListPriceYear>' +
                              '<currenteffectivediscount>0</currenteffectivediscount>' +
                              '<RMStoragelistpricediscount>0</RMStoragelistpricediscount>' +
                              '<RMServicelistpricediscount>0</RMServicelistpricediscount>' +
                              '<estimatedyear1revenue>13902</estimatedyear1revenue>' +
                              '<revenueyeartargetpricing>0</revenueyeartargetpricing>' +
                              '<revenueatlistpricing>0</revenueatlistpricing>' +
                              '<totalcontractrevenue>44879.12</totalcontractrevenue>' +
                              '<RMEffectiveDiscount>0</RMEffectiveDiscount>' +
                              '<includeclawback>0</includeclawback>' +
                              '<DMcontractlength>24</DMcontractlength>' +
                              '<DBRStorageEffectiveDiscount>0</DBRStorageEffectiveDiscount>' +
                              '<DBRServiceEffectiveDiscount>0</DBRServiceEffectiveDiscount>' +
                              '<DBRStoragelistpricediscount>0</DBRStoragelistpricediscount>' +
                              '<DBRServicelistpricediscount>0</DBRServicelistpricediscount>' +
                              '<SScontractlength>0</SScontractlength>' +
                              '<NumberOfShredLocations>0</NumberOfShredLocations>' +
                              '<PAVersion>10.10.10</PAVersion>' +
                              '<RMMultiyear>0</RMMultiyear>' +
                              '<RMFUI>false</RMFUI>' +
                              '<RMPWPaid>false</RMPWPaid>' +
                              '<RMUnvended>false</RMUnvended>' +
                              '<RMProgramPricing>false</RMProgramPricing>' +
                              '<RMTieredPricing>false</RMTieredPricing>' +
                              '<RMFreeStorage>false</RMFreeStorage>' +
                              '<RMFreeServices>false</RMFreeServices>' +
                              '<RMFreeStorageviaWA>false</RMFreeStorageviaWA>' +
                              '<RMFreeServicesviaWA>false</RMFreeServicesviaWA>' +
                              '<RMOther>0</RMOther>' +
                              '<DMMultiyear>0</DMMultiyear>' +
                              '<DMTieredPricing>0</DMTieredPricing>' +
                              '<DMOther>0</DMOther>' +
                              '<SSMultiyear>0</SSMultiyear>' +
                              '<SSTieredPricing>false</SSTieredPricing>' +
                              '<SSOther>false</SSOther>' +
                              '<Financing>false</Financing>' +
                              '<Rebate>false</Rebate>' +
                              '<Retroactive>false</Retroactive>' +
                              '<NonStandardServices>false</NonStandardServices>' +
                              '<XODStudies>0</XODStudies>' +
                              '<XODProgramfee>0</XODProgramfee>' +
                              '<XODPerunit>0</XODPerunit>' +
                              '<Newrev>0</Newrev>' +
                              '<ShredRevenues_1>-5264</ShredRevenues_1>' +
                              '<Investment>0</Investment>' +
                              '<TotalCost>0</TotalCost>' +
                              '<TotalCashBasedCost>0</TotalCashBasedCost>' +
                              '<ServiceHours>118490</ServiceHours>' +
                              '<ServiceLaborCost>102914</ServiceLaborCost>' +
                              '<RevenueDilution>0</RevenueDilution>' +
                              '<FloorRevenue>30.7058</FloorRevenue>' +
                              '<FloorRevenueRealization>-0.274653031409788</FloorRevenueRealization>' +
                              '<RedFlagItems>0</RedFlagItems>' +
                              '<RevenueDilutionDollar>118.660282283336</RevenueDilutionDollar>' +
                              '<quoteLines>' +
                                '<quoteItem>' +
                                  '<productNumber>8900_a</productNumber>' +
                                  '<listprice>0</listprice>' +
                                  '<currentprice>0</currentprice>' +
                                  '<currentvolume>0</currentvolume>' +
                                  '<currentrevenue>0</currentrevenue>' +
                                  '<proposedprice>0</proposedprice>' +
                                  '<proposedvolume>0</proposedvolume>' +
                                  '<proposedrevenue>0</proposedrevenue>' +
                                  '<yr2price>0</yr2price>' +
                                  '<yr3price>0</yr3price>' +
                                  '<yr4price>0</yr4price>' +
                                  '<yr5price>0</yr5price>' +
                                  '<yr6price>0</yr6price>' +
                                  '<yr7price>0</yr7price>' +
                                  '<yr8price>0</yr8price>' +
                                  '<yr9price>0</yr9price>' +
                                  '<yr10price>0</yr10price>' +
                                  '<keepflag>1</keepflag>' +
                                  '<targetprice>0</targetprice>' +
                                  '<forecastableflag>0</forecastableflag>' +
                                  '<unitcost>0</unitcost>' +
                                  '<floorprice>0</floorprice>' +
                                  '<unitcostcashview>0</unitcostcashview>' +
                                '</quoteItem>' +
                              '</quoteLines>' +
                            '</schedulea>';
    
    @testSetup
    static void setupTestData(){
        //Create Test Account and Opportunity Records
        IM_Country__c cntry = TestingUtil.createIMCountry();
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel;
        
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
        Account testAccount = TestingUtils.createAccounts( 1, true)[0];

        List<IM_Customer_Account__c> expectedCustomerAccounts = TestingUtils.createCustomerAccounts (2, testAccount.Id, false);
        expectedCustomerAccounts[0].Source_System__c = 'SKP NA';       
        expectedCustomerAccounts[0].name = 'adfe2';       
        insert expectedCustomerAccounts;
        
        Product2 product1 =Testingutils.createProduct('890', false);
        product1.recordtypeId=Bill_codeRT;
        
        insert product1;
        
        Pricebook2 NA_pbook =TestingUtils.createPriceBook('North America',true);
        
        Id standardPB = Test.getStandardPricebookId();
        
        TestingUtils.createPriceBookEntry(product1.id,standardPB,true);      
        TestingUtils.createPriceBookEntry(product1.id,NA_pbook.id,true);   
        
        Opportunity opp = TestingUtils.createOpportunity('TestPAModel', testAccount.Id, false);
        opp.currencyisocode='USD';
        insert opp;
        
        BaseVersionNumber__c test = new BaseVersionNumber__c( Version__c = BASE_VERSION_NUMBER);
        insert test;
     
    }
        
	@isTest
    static void UploadPAModelTest_Success() {
        //Set up Mock Request and Response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        //Fetch Opportunity Id for the from the test record for input request
        Opportunity testOpp=[Select Id from opportunity LIMIT 1];
        
        //Set request properties
        req.requestURI='services/apexrest/PAModelUpload/' + testOpp.Id ;
        req.httpMethod='POST';
        
        String reqBody = successXML;
        
        		req.requestBody=Blob.ValueOf(reqBody);
        		RestContext.request=req;
        		RestContext.response=res;
        		//Invoke Rest API Method
        		IRM_ScheduleAControllerExt_RestApi.UploadPAModel();
        
        		//Validate the response
        		System.assertEquals(200,RestContext.response.statusCode,'Expected Status is 200');
    }
    
    @isTest
    static void UploadPAModelTest_error() {
        //Set up Mock Request and Response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        //Fetch Opportunity Id for the from the test record for input request
        Opportunity testOpp=[Select Id from opportunity LIMIT 1];
        
        //Set request properties
        req.requestURI='services/apexrest/PAModelUpload/' + testOpp.Id ;
        req.httpMethod='POST';
        
        String reqBody = errorXML;
        
        		req.requestBody=Blob.ValueOf(reqBody);
        		RestContext.request=req;
        		RestContext.response=res;
        		//Invoke Rest API Method
        		IRM_ScheduleAControllerExt_RestApi.UploadPAModel();
        
        		//Validate the response
        		System.assertEquals(200,RestContext.response.statusCode,'Expected Status is 200');
    }
    
    @isTest
    static void UploadPAModelTest_Warning() {
        //Set up Mock Request and Response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        //Fetch Opportunity Id for the from the test record for input request
        Opportunity testOpp=[Select Id from opportunity LIMIT 1];
        
        //Set request properties
        req.requestURI='services/apexrest/PAModelUpload/' + testOpp.Id;
        req.httpMethod='POST';
        
        String reqBody = warningXML;
        
        		req.requestBody=Blob.ValueOf(reqBody);
        		RestContext.request=req;
        		RestContext.response=res;
        		//Invoke Rest API Method
        		IRM_ScheduleAControllerExt_RestApi.UploadPAModel();
        
        		//Validate the response
        		System.assertEquals(200,RestContext.response.statusCode,'Expected Status is 200');
    }
}
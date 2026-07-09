/**  
* Name            : IRM_IRM_ScheduleAParseXML
* Description     : XML Parser for Schedule A PA Files gnerated from Excel PA tool
* 
* Copyright       : Bluewolf
* Author          : Chris Matthews
* Modification Log: Created:26-Oct-2012 
* Gitlab story    : 19277 Removed logic related to PA Model Approval process and improved code coverage
**/
@isTest
private class Test_IRM_ScheduleAParseXML 
{
    private static Opportunity opp   = null;
    private static User        user  = null;
    private static Pricebook2  pbook = null;
    private static List<PricebookEntry> pricebookList=null;
    private static Account testAccount=null;
    public static final Id Bill_codeRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Bill Code').getRecordTypeId();
    private static List<IM_Customer_Account__c> expectedCustomerAccounts = new List<IM_Customer_Account__c>();
    
    private static String testXml = '';
    private static final String BASE_VERSION_NUMBER = '9.8.1';
    private static final String OLDER_VERSION_NUMBER = '8.0.2';
    private static final String NEWER_VERSION_NUMBER = '9.8.2';
    
    @testSetup
    private static void setup()
    {
        /*user = [ select id,currencyisocode 
from User 
where username like 'dan.manca@ironmountain.com%' 
and isActive=true 
limit 1 ];*/
        //Name: Srinu
        /*Start*/
        //Create a test user
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        
        list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'IM_Custom Sys Admin'];        
        user= new User();
        user.FirstName = 'fName';
        user.LastName = 'lName';
        user.Email = 'Test@mail.com';
        user.Username = 'danmanca@org.com';
        user.Sales_Division__c='North America';
        user.Alias ='Testuser';
        user.IsActive = true;
        user.CommunityNickname = 'Dtest';
        user.TimeZoneSidKey ='America/New_York';
        user.LocaleSidKey = 'en_US';
        user.EmailEncodingKey = 'UTF-8';
        user.CurrencyIsoCode='USD';
        user.ProfileId = p1[0].id;
        user.LanguageLocaleKey = 'en_US';
        user.Country = 'United States';
        insert user;
        
        /*End*/
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
        
        testAccount = TestingUtils.createAccounts( 1, true)[0];
        
        expectedCustomerAccounts = TestingUtils.createCustomerAccounts (2, testAccount.Id, false);
        expectedCustomerAccounts[0].Source_System__c = 'SKP NA';
        expectedCustomerAccounts[1].Source_System__c = 'SKP NA';
        expectedCustomerAccounts[0].name = 'adfe2';
        expectedCustomerAccounts[1].name = '21wda';
        insert expectedCustomerAccounts;
        
        Product2 product1 =Testingutils.createProduct('890', false);
        product1.recordtypeId=Bill_codeRT;
        insert product1;
        
        Product2 product2 =Testingutils.createProduct('880', false);
        product1.recordtypeId=Bill_codeRT;
        insert product2;
        
        Product2 product3 =Testingutils.createProduct('3471', false);
        product1.recordtypeId=Bill_codeRT;
        insert product3;
        
        Pricebook2 NA_pbook =TestingUtils.createPriceBook(System.Label.PA_MODEL_PRICE_BOOK,true);
        
        Id standardPB = Test.getStandardPricebookId();
        
        TestingUtils.createPriceBookEntry(product1.id,standardPB,true);
        TestingUtils.createPriceBookEntry(product2.id,standardPB,true);
        TestingUtils.createPriceBookEntry(product3.id,standardPB,true);
        
        TestingUtils.createPriceBookEntry(product1.id,NA_pbook.id,true);   
        TestingUtils.createPriceBookEntry(product2.id,NA_pbook.id,true);
        TestingUtils.createPriceBookEntry(product3.id,NA_pbook.id,true);
        system.debug('PBE created');
        
        /**                             
pbook = new Pricebook2();
pbook.name='North America';
pbook.IsActive   = true;
pbook.IsStandard = true;       
insert pbook;

Product2 product    = new Product2();
product.name        = 'BACKUPCARE';
product.Description = 'Backup Care Product';
product.ProductCode = 'BACKUPCARE';       
insert product; 

PricebookEntry pbe   = new PricebookEntry();
pbe.Pricebook2Id     = pbook.id;
pbe.Product2Id       = product.id;
pbe.IsActive         = true;
pbe.UnitPrice        = 100;
pbe.UseStandardPrice = false;
insert pbe;
*/
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        
        opp = TestingUtils.createOpportunity('TestPAModel', testAccount.Id, false);
        opp.OwnerId      = user.id;
        
        insert opp;
        
        BaseVersionNumber__c test = new BaseVersionNumber__c( Version__c = BASE_VERSION_NUMBER);
        insert test;
        
    }
    /*Gitlab: 19277 code cleanup
private static String getApproverTitle(Integer num)
{
return 'Approver ' + String.valueOf(num);
}*/
    
    /*  private static testMethod void testUpdateApproversForUsersForInactiveUser()
{
User testUser;     
System.runAs(TestingUtils.ADMIN_USER)
{
testUser = TestingUtil.createUsers(1,true)[0];
}

Schedule_A__c scheduleA = TestingUtil.createScheduleA(true);

Opportunity testOpp;

System.runAs(testUser)
{
testOpp = TestingUtil.createOpportunity();
}

testOpp = [SELECT ID, OwnerID FROM Opportunity WHERE ID =: testOpp.ID LIMIT 1];

testUser.ISActive=false;
System.runAs(TestingUtils.ADMIN_USER)
{
update testUser;
}

Test.startTest();
IRM_ScheduleAParseXML.updateApprovers(scheduleA,testOpp,new List<String> {'Test'});
Test.stopTest();

System.assert(ApexPages.hasMessages(),'There should be an error because the opportunity owner is inactive');
System.assert(TestingUtils.pageMessageContains(System.Label.Opportunity_Owner_Inactive),'We expect to get an error indicating that the opportunity owner is inactive');
}*/
    /*Gitlab: 19277 code cleanup 
private static void assertUpdateApproverForActiveUser(User testUser)
{
Schedule_A__c scheduleA = TestingUtil.createScheduleA(true);
scheduleA.Approver_1__c = null;

Opportunity testOpp;

System.runAs(testUser)
{
testOpp = TestingUtil.createOpportunity();
}

testOpp = [SELECT ID, OwnerID FROM Opportunity WHERE ID =: testOpp.ID LIMIT 1];

List<String> testApprovers = new List<String>();
final Integer NUM_APPROVERS = 12;
for(Integer i = 1; i <= NUM_APPROVERS; i++)
{
testApprovers.add(getApproverTitle(i));
}

Test.startTest();
IRM_ScheduleAParseXML.updateApprovers(scheduleA,testOpp,testApprovers);
Test.stopTest();

System.assert(!ApexPages.hasMessages(),'There should be no errors');

System.assertEquals(null,scheduleA.Approver_1__c, 'The first approver should not be defaulted to any user');
System.assertEquals(null,scheduleA.Approver_2__c,'The second approver should not be defaulted to any user');
System.assertEquals(null,scheduleA.Approver_3__c,'The third approver should not be defaulted to any user');

for(Integer i = 1; i <=NUM_APPROVERS; i++)
{
System.assertEquals(getApproverTitle(i),scheduleA.get('Approver_' + i + '_Title__c'),'We expect the approver title fields on the schedule A to be populated with the right values');
}
}

private static testMethod void testUpdateApproversForUsersWithoutDirectorFields()
{    
User testUser;     
System.runAs(TestingUtils.ADMIN_USER)
{
testUser = TestingUtil.createUsers(1,true)[0];
}
assertUpdateApproverForActiveUser(testUser);
}

private static testMethod void testUpdateApproversForUsersWithoutVPDirectorField()
{    
User testUser;     
System.runAs(TestingUtils.ADMIN_USER)
{
testUser = TestingUtil.createUsers(1,true)[0];
}
testUser.IM_VP__c = UserInfo.getUserId();
update testUser;

assertUpdateApproverForActiveUser(testUser);
}

private static testMethod void testUpdateApproversForUsersWithoutRSMDirectorField()
{    
User testUser;     
System.runAs(TestingUtils.ADMIN_USER)
{
testUser = TestingUtil.createUsers(1,true)[0];
}
testUser.IM_RSM__c = UserInfo.getUserId();
update testUser;

assertUpdateApproverForActiveUser(testUser);
}*/
    
    public static void buildXml(String versionNumber){ 
        
        pricebookList=[select id,name from priceBookEntry where pricebook2.name!='Standard PriceBook'];
        system.debug('+++++++++pb list++++'+pricebookList);                                   
        User u=[select id,currencyisocode from user limit 1];
        testXml =                   
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+
            '<schedulea xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
            '           <CustomerName>Test Customer</CustomerName>'+
            '           <IMGA>IM_Customer</IMGA>'+
            '           <Salesseg>Non-Territory Sales Team</Salesseg>'+
            '           <Industry>Sales Vertical</Industry>'+
            '           <Country>USA</Country>'+
            '           <Currency>'+u.currencyisocode+'</Currency>'+
            '           <AWSRequestID>0</AWSRequestID>'+
            '           <CustomerIDs>,</CustomerIDs>'+
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
            '           <PAVersion>'+versionNumber+'</PAVersion>'+
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
            '           <dealsummary1>Test Deal Summary</dealsummary1>'+
            '           <NonStandardServices>false</NonStandardServices>'+
            '           <nonbillableterm1>Test Bill Term1</nonbillableterm1>'+          
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
            '           <costtoirm1>123</costtoirm1>'+
            '           <programpricing>234</programpricing>'+          
            '           <ShredRevenues_1>138098.48</ShredRevenues_1>'+
            '           <ShredRevenues_2/>'+
            '           <ShredRevenues_3/>'+
            '           <ShredRevenues_4/>'+
            '           <ShredRevenues_5/>'+
            '           <ShredRevenues_6/>'+
            '           <ShredRevenues_7/>'+
            '           <ShredRevenues_8/>'+
            '           <ShredRevenues_9/>'+
            '           <ShredRevenues_10/>'+
            '           <Investment>200000</Investment>'+
            '           <TotalCost>273374.217647138</TotalCost>'+
            '           <TotalCashBasedCost>273374.2176</TotalCashBasedCost>'+
            '           <ServiceHours>12</ServiceHours>'+
            '           <ServiceLaborCost>2</ServiceLaborCost>'+
            '           <floorrevenue>1234</floorrevenue>'+
            '           <RevenueDilution>-0.13</RevenueDilution>'+
            '			<RedFlagItems>True</RedFlagItems>'+
	        '           <revenuedilutiondollar>'+2004.32+'</revenuedilutiondollar>'+
            '           <shredlocations>' +
            '               <shredlocation>' +
            '                   <Description>Headquarters</Description>' +
            '                   <Market>Boston</Market>' +
            '                   <Number_Containers>5</Number_Containers>' +
            '                   <Container_Type>Console</Container_Type>' +
            '                   <Service_Type>Staged</Service_Type>' +
            '                   <Frequency>2 Weeks</Frequency>' +
            '               </shredlocation>' +
            '           </shredlocations>' +
            
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
            '                           <unitcostcashview>0.0646</unitcostcashview>'+
            '                   </quoteItem>'+
            '                   <quoteItem>'+
            '                           <productNumber>'+pricebookList[1].Name+'</productNumber>'+
            '                           <listprice>1.02</listprice>'+
            '                           <currentprice>0</currentprice>'+
            '                           <currentvolume>0</currentvolume>'+
            '                           <currentrevenue>0</currentrevenue>'+
            '                           <proposedprice>0.203</proposedprice>'+
            '                           <proposedvolume>13</proposedvolume>'+
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
            '                           <unitcostcashview>0.0646</unitcostcashview>'+
            '                   </quoteItem>'+
            '                   <quoteItem>'+
            '                           <productNumber>'+pricebookList[2].Name+'</productNumber>'+
            '                           <listprice>0</listprice>'+
            '                           <currentprice>0</currentprice>'+
            '                           <currentvolume>0</currentvolume>'+
            '                           <currentrevenue>0</currentrevenue>'+
            '                           <proposedprice>0.203</proposedprice>'+
            '                           <proposedvolume>13</proposedvolume>'+
            '                           <proposedrevenue>0</proposedrevenue>'+
            '                           <yr2price>0</yr2price>'+
            '                           <yr3price>0</yr3price>'+
            '                           <yr4price>0</yr4price>'+
            '                           <yr5price>0</yr5price>'+
            '                           <yr6price>0</yr6price>'+
            '                           <yr7price>0</yr7price>'+
            '                           <yr8price>0</yr8price>'+
            '                           <yr9price>0</yr9price>'+
            '                           <yr10price>0</yr10price>'+
            '                           <keepflag>0</keepflag>'+
            '                           <targetprice>0</targetprice>'+
            '                           <forecastableflag>1</forecastableflag>'+
            '                           <unitcost>0</unitcost>'+
            '                           <floorprice>0</floorprice>'+
            '                           <unitcostcashview>0</unitcostcashview>'+
            '                   </quoteItem>'+
            '                   <quoteItem>' +
            '                           <productNumber>'+'1234'+'</productNumber>'+
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
    }
    
    // Test that the XML string contains specific values 
    static testMethod void testBookParser() 
    {       
        buildXml(BASE_VERSION_NUMBER);
        IRM_ScheduleAParseXML demo = new IRM_ScheduleAParseXML();
        Opportunity opp=[select id,currencyisocode from Opportunity limit 1];  
        System.debug(opp.currencyisocode);
        Test.startTest();
        // XML Parser parsing
        Schedule_A__c scheduleA = 
            IRM_ScheduleAParseXML.parseXML('Test PA Model', testXml, opp.id );
        
        Schedule_A__c blankScheduleA = TestingUtils.createPAModels(1, true)[0];
        
        Test.StopTest();
        // #30914 PA Model: Clean Up the XML mapping job
        Map<Id, Schedule_A__c> testScheduleAsCreatedMap = new Map<Id, Schedule_A__c>( [Select Id, /*Pricing_Strategy__c, Non_Billable_Deal_Term1__c,
                                                                                       Non_Billable_Deal_Term2__c, Non_Billable_Deal_Term3__c,
                                                                                       Non_Billable_Deal_Term4__c, Non_Billable_Deal_Term5__c,
                                                                                       Non_Billable_Deal_Term6__c, Cost_to_IRM1__c,
                                                                                       Cost_to_IRM2__c, Cost_to_IRM3__c,
                                                                                       Cost_to_IRM4__c, Cost_to_IRM5__c,
                                                                                       Cost_to_IRM6__c,Pricing_Recommendations1__c, 
                                                                                       Pricing_Recommendations2__c, Pricing_Recommendations3__c,
                                                                                       Pricing_Recommendations4__c, Units1__c,
                                                                                       Units2__c, Units3__c, 
                                                                                       Units4__c, Units5__c,
                                                                                       Units6__c, Deal_Summary2__c,
                                                                                       Deal_Summary3__c, Deal_Summary4__c,
                                                                                       Tiered_Pricing__c, Program_Pricing__c,
                                                                                       Bundled_Pricing__c,*/ RM_List_Price_Discount__c,
                                                                                       RM_Service_List_Price_Discount__c, include_Clawback__c,
                                                                                       Salesseg__c, Industry__c,Service_Labor_Hours__c,Total_Cashview_Cost__c,
                                                                                       Service_Labor_rate__c,Revenue_Dilution__c,Total_Floor_Revenue__c,
                                                                                       Investment__c,Red_Flag__c,Revenue_Dilution_dollar__c FROM Schedule_A__c where Id in :new List<Schedule_A__c>{ scheduleA, blankScheduleA }]);
        
        scheduleA = testScheduleAsCreatedMap.get( scheduleA.Id );               
        blankScheduleA = testScheduleAsCreatedMap.get( blankScheduleA.Id );             
       //// #30914 PA Model: Clean Up the XML mapping job 
      //  System.assertEquals('Test Bill Term1', scheduleA.Non_Billable_Deal_Term1__c, 'The Non Billable Deal Term1 should be correctly set');
      //  System.assertEquals(123, scheduleA.Cost_to_IRM1__c, 'The Cost to IRM should be correctly set');
     //   System.assertEquals(false, scheduleA.Program_Pricing__c, 'The Program Pricing should be correctly set');
        System.assertEquals(true, scheduleA.include_Clawback__c, 'The include_Clawback__c should be correctly set');
        System.assertEquals('Non-Territory Sales Team', scheduleA.Salesseg__c, 'The Sales segment should be correctly set');
        System.assertEquals('Sales Vertical', scheduleA.Industry__c, 'Industry should be correctly set');
        System.assertEquals(12,scheduleA.Service_Labor_Hours__c,'Service Labor hour should be properly set');
        System.assertEquals(273374.2176,scheduleA.Total_Cashview_Cost__c,'Total cashview cost should be properly set');
        System.assertEquals(2,scheduleA.Service_Labor_rate__c,'Service labor Rate should be properly set');
        System.assertEquals(1234,scheduleA.Total_Floor_Revenue__c,'Total floor revenue should be properly set');
        System.assertEquals(200000,scheduleA.Investment__c,'Investment should be properly set');
        System.assertEquals(-13,scheduleA.Revenue_Dilution__c,'Revenue Dilution should be properly set');
        System.assertEquals(true, scheduleA.Red_Flag__c, 'The Red Flag should be correctly set');
        System.assertEquals(2004.32, scheduleA.Revenue_Dilution_dollar__c, 'The Revenue Dilution $ should be correctly set');
        
        
        System.assert(IRM_ScheduleAParseXML.PA_MODEL_OK == true);
        
        //Assertion of Schedule A Quote Items
        List<Schedule_A_Quote_Item__c> lines=[select id,product_number__c,Cashview_Cost_Line__c,
                                              Floor_Price__c,
                                              Target_Price__c,
                                              Proposed_Price_Year_10__c,
                                              Proposed_Price_Year_9__c,
                                              Proposed_Price_Year_8__c,
                                              Proposed_Price_Year_7__c,
                                              Proposed_Price_Year_6__c,
                                              Proposed_Price_Year_5__c,
                                              Proposed_Price_Year_4__c,
                                              Proposed_Price_Year_3__c,
                                              Proposed_Price_Year_2__c,
                                              /*Proposed_Price_Year_1__c,*/    //#30912 PA Model LINES field clean up
                                              Proposed_Price__c,
                                              XML_Proposed_Volume__c,
                                              Current_Price__c,
                                              Current_Volume__c,
                                              List_Price__c,
                                              keep_flag__c,
                                              Forecastable__c from  Schedule_A_Quote_Item__c where schedule_A__c=:scheduleA.id];
        for(Schedule_A_Quote_Item__c sc:lines)
        {
            System.assertEquals(0.0646,sc.Cashview_Cost_Line__c,'Cashview Cost Line value is not parsed correctly from xml');
            System.assertEquals(0.201,sc.Floor_Price__c,'Floor Price value is not parsed correctly from xml');
            System.assertEquals(0.232,sc.Target_Price__c,'Target Price value is not parsed correctly from xml');
            System.assertEquals(0.289,sc.Proposed_Price_Year_10__c,'Proposed Price year 10 value is not parsed correctly from xml');
            System.assertEquals(0.278,sc.Proposed_Price_Year_9__c,'Proposed Price year 9 value is not parsed correctly from xml');
            System.assertEquals(0.267,sc.Proposed_Price_Year_8__c,'Proposed Price year 8 value is not parsed correctly from xml');
            System.assertEquals(0.22,sc.Proposed_Price_Year_3__c,'Proposed Price year 3 value is not parsed correctly from xml');
            System.assertEquals(0.203,sc.Proposed_Price__c,'Proposed Price value is not parsed correctly from xml');
            System.assertEquals(sc.product_number__c=='890'?125000:13,sc.XML_Proposed_Volume__c,'Proposed Volume value is not parsed correctly from xml');
            System.assertEquals(sc.product_number__c=='890'?0.201:0,sc.Current_Price__c,'Current price value is not parsed correctly from xml');
            System.assertEquals(sc.product_number__c=='890'?125000:0,sc.Current_Volume__c,'Current Volume value is not parsed correctly from xml');
            System.assertEquals(1.02,sc.List_Price__c,'List Price value is not parsed correctly from xml');
            System.assertEquals(sc.product_number__c=='880'?True:false,sc.Forecastable__c,'Forecastable value is not parsed correctly from xml');
           
        }
    }
    
    static testMethod void testNewerVersionNumber() 
    {       
        Test.startTest();
        buildXml(NEWER_VERSION_NUMBER);
        Opportunity opp=[select id from Opportunity limit 1];
        IRM_ScheduleAParseXML demo = new IRM_ScheduleAParseXML();
        //added currency tag to test xml
        
        // XML Parser parsing
        Schedule_A__c scheduleA = IRM_ScheduleAParseXML.parseXML('Test PA Model', testXml, opp.id );
        Test.stoptest();
        
        System.assert(IRM_ScheduleAParseXML.PA_MODEL_OK == true);
    }    
    
    static testMethod void testOlderVersionNumber() 
    {      
        Test.startTest();
        buildXml(OLDER_VERSION_NUMBER);
        Opportunity opp=[select id from Opportunity limit 1];
        IRM_ScheduleAParseXML demo = new IRM_ScheduleAParseXML();
        //added currency tag to test xml
        
        // XML Parser parsing
        Schedule_A__c scheduleA = IRM_ScheduleAParseXML.parseXML('Test PA Model', testXml, opp.id );
        Test.stoptest();
        
        System.assert(IRM_ScheduleAParseXML.PA_MODEL_OK == false);
    }
    
    static testMethod void testFilterInvalidCustomerAccounts()
    {
        List<String> customerAccountnamesFromXML = new List<String>{'adfe2','31fd','21wda', '31fgh'};
            List<IM_Customer_Account__c> expectedCustomerAccounts=[select id,name from IM_Customer_Account__c];
        
        Test.startTest();
        Set<String> invalidCustomerAccounts = IRM_ScheduleAParseXML.filterInvalidCustomerAccounts(customerAccountnamesFromXML, expectedCustomerAccounts);
        Test.stopTest();
        
        system.assertEquals(invalidCustomerAccounts.size(), (customerAccountnamesFromXML.size() - expectedCustomerAccounts.size()), ' The total number of invalid accounts is the difference between the list of xml customer accounts and salesforce customer accounts');
    }
    
    static testMethod void testProcessCustomerAssociations()
    {
        List<String> customerAccountnamesFromXML = new List<String>{'adfe2','31fd','21wda', '31fgh'};
            List<IM_Customer_Account__c> expectedCustomerAccounts=[select id,name from IM_Customer_Account__c];
        
        Schedule_A__c sampleScheduleA = TestingUtils.createPAModels(1, false)[0];
        sampleScheduleA.CustomerIds__c = 'adfe2,31fd,21wda,31fgh';
        sampleScheduleA.Reference__c='Testxml.xlsx';
        
        insert sampleScheduleA;
        
        Test.startTest();
        boolean result = IRM_ScheduleAParseXML.processCustomerAssociations(sampleScheduleA);
        Test.stopTest();
        
        system.assertEquals(false, result, 'The processCustomerAssociations must return a false if the xml doc contains invalid accounts');
    }
    
}
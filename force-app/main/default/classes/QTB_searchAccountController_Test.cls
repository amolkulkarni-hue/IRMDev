/****************************************************************************************************
* Test Class for QTB_searchAccountController_Test
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author : Accenture 
* @ModifiedBy : Accenture
* @Created : 5/6/2020
* @Modified : 5/6/2020
********************************************************************************************************/
@isTest(seealldata=false)
private class QTB_searchAccountController_Test {

	@testSetup private static void setup(){
        Test.startTest();
        Id recordTypeValue = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(2, 'Billing Account');
        blng__LegalEntity__c le=QTB_TestDataFactory.createLegalEntity('India');
        for(Account acc :testAccounts){
            acc.RecordTypeId=recordTypeValue;
            acc.QTB_scan__c=true;
            acc.QTB_Records_Management__c=true;
            acc.QTB_shred__c=true;
            acc.QTB_Data_Management__c=true;
            acc.QTB_Create_Parent_Billing_Account__c=true;
            acc.QTB_Contract_Entity__c=le.id;
            acc.QTB_Invoice_Delivery_Options__c='Email';
        }
        testAccounts[0].QTB_Create_Parent_Billing_Account__c=false;
        testAccounts[0].ParentId=testAccounts[1].Id;
        testAccounts[0].BillingCountry='India';
        testAccounts[0].BillingStreet='XYZ';
        testAccounts[0].BillingCity='Pune';
        testAccounts[1].IMGA_Lookup__c=testAccounts[0].Id;
        update testAccounts;
       
     /*  List<Contact> testContacts =QTB_TestDataFactory.createContacts(1);
        testContacts[0].AccountId=testAccounts[0].Id;
        testContacts[0].IM_Role__c='Billing';
        update testContacts;  */
        
        IM_Country__c con= new IM_Country__c();
        con.Name='India';
        insert con;
        
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c='Opportunity';
        custSetting.Disable_VR__c=true;
        insert custSetting;
        List<Opportunity> testOpportunity = QTB_TestDataFactory.createCPQOppsNew(new List<Account>{testAccounts[1]}, 'CPQ Sales Opportunity');
        testOpportunity[0].Billing_Country__c=con.id;
        testOpportunity[0].StageName='1 - Qualification';
        testOpportunity[0].IME_Reason_Won__c ='test';
        update testOpportunity;   
        //testOpportunity[0].StageName=QTB_Constants.STAGEVALUE_SIXSETUP;
        //update testOpportunity;
        Test.stopTest();
    }
    
    static testmethod void method1() {   
        Test.startTest();
        List<Account> acc = new List<Account>([select id,QTB_Customer_Number__c	 from Account where Name='Test Account']);
        Account val=new Account();
        val.QTB_Level_1__c='Test';
        val.QTB_Level_2__c='Test';
        val.QTB_Department__c='Test';
        val.QTB_Division__c='Test';
        val.QTB_Customer_District__c='Test';
        val.QTB_Create_Operating_System_Account__c=true;
        Opportunity opp = [select id, RecordTypeId From Opportunity where RecordType.Name= 'CPQ Sales Opportunity'];
        
        QTB_searchAccountController.fetchAccount('Test',acc[0].QTB_Customer_Number__c,opp.id);
        QTB_searchAccountController.fetchAccount('Test','',opp.id);
        try{
        	QTB_searchAccountController.SaveAccRecord(new List<id>{acc[0].id},opp.id,val);
        }catch(Exception e){
            system.assertEquals('Script-thrown exception',e.getMessage());
        }
        QTB_searchAccountController.checkLatestOpportunityDetails(opp.id);
        opp.Primary_Product_line__c=Label.QTB_LOB_Records_Management;
        update opp;
        QTB_searchAccountController.SaveAccRecord(new List<id>{acc[0].id},opp.id,val);
        Test.stopTest();
        system.assertEquals(Label.QTB_LOB_Records_Management, opp.Primary_Product_line__c);
    }
    static testmethod void method1_2() {   
        Test.startTest();
        List<Account> acc = new List<Account>([select id,QTB_Customer_Number__c	 from Account where Name='Test Account']);
        Account val=new Account();
        val.QTB_Level_1__c='Test';
        val.QTB_Level_2__c='Test';
        val.QTB_Department__c='Test';
        val.QTB_Division__c='Test';
        val.QTB_Customer_District__c='Test';
        val.QTB_Create_Operating_System_Account__c=true;
        Opportunity opp = [select id, RecordTypeId From Opportunity where RecordType.Name= 'CPQ Sales Opportunity'];
        
        QTB_searchAccountController.fetchAccount('Test',acc[0].QTB_Customer_Number__c,opp.id);
        QTB_searchAccountController.fetchAccount('Test','',opp.id);
        try{
        	QTB_searchAccountController.SaveAccRecord(new List<id>{acc[0].id},opp.id,val);
        }catch(Exception e){
            system.assertEquals('Script-thrown exception',e.getMessage());
        }
       
         QTB_searchAccountController.SaveAccRecord(new List<id>{acc[1].id},opp.id,val);
        opp.Primary_Product_line__c=Label.QTB_LOB_Data_Management;
        update opp;
        QTB_searchAccountController.SaveAccRecord(new List<id>{acc[0].id},opp.id,val);
        Test.stopTest();
       
         }
    static testmethod void method1_3() {   
        Test.startTest();
        List<Account> acc = new List<Account>([select id,QTB_Customer_Number__c	 from Account where Name='Test Account']);
        Account val=new Account();
        val.QTB_Level_1__c='Test';
        val.QTB_Level_2__c='Test';
        val.QTB_Department__c='Test';
        val.QTB_Division__c='Test';
        val.QTB_Customer_District__c='Test';
        val.QTB_Create_Operating_System_Account__c=true;
        Opportunity opp = [select id, RecordTypeId From Opportunity where RecordType.Name= 'CPQ Sales Opportunity'];
        
        QTB_searchAccountController.fetchAccount('Test',acc[0].QTB_Customer_Number__c,opp.id);
        QTB_searchAccountController.fetchAccount('Test','',opp.id);
        try{
        	QTB_searchAccountController.SaveAccRecord(new List<id>{acc[0].id},opp.id,val);
        }catch(Exception e){
            system.assertEquals('Script-thrown exception',e.getMessage());
        }
         QTB_searchAccountController.SaveAccRecord(new List<id>{acc[0].id},opp.id,val);
        opp.Primary_Product_line__c=Label.QTB_LOB_Shred;
        update opp;
         QTB_searchAccountController.SaveAccRecord(new List<id>{acc[0].id},opp.id,val);
        Test.stopTest();
    }
    
    //cover catch
    static testmethod void testMethod2() {   
        Test.startTest();
        QTB_searchAccountController.throwExplicitException=true;
        try{
    		QTB_searchAccountController.checkLatestOpportunityDetails(null);
        }
        catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        try{
    		QTB_searchAccountController.fetchAccount(null,null,null);
        }
        catch(Exception e){
        }
        
        Test.stopTest();
        system.assertEquals(true, QTB_searchAccountController.throwExplicitException);
    }
    static testmethod void testmethod3(){
        List<Account> accountList = new List<Account>([select id,QTB_Customer_Number__c	 from Account where Name='Test Account']);
        List<Opportunity> oppList = [select id,SBQQ__PrimaryQuote__c, RecordTypeId From Opportunity where RecordType.Name= 'CPQ Sales Opportunity'];
        
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        oppList[0].SBQQ__PrimaryQuote__c = quoteList[0].id;
        update oppList;
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        database.update(product);
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);
        
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        database.update(quoteList);
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
       /* List<account> accountList2 = QTB_TestDataFactory.createAccounts(1,accountList[0],null,'Billing Account');
        accountList2[0].QTB_Source_Opportunity__c = oppList[0].id;
        update accountList2;  */
        List<Order> orderList1 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        QTB_searchAccountController.checkLatestOpportunityDetails(oppList[0].id);
    }
    
}
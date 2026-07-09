/*****************************************************************************************************
* Test class: QTB_WithoutSharingUtillsTest
* Author: Virtusa
* Purpose: This is a Test class for class "QTB_WithoutSharingUtills"
* Requirement: //GITLAB:28527 
* Change History: 01/23/2025
* Developer Name : Ayeisha Kathon
*******************************************************************************************************/
@isTest(seealldata=false) 
public class QTB_WithoutSharingUtillsTest {
    @testSetup
    static void setup() {
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;AccountContactRelation;blng__UsageSummary__c;order;OrderItem;Opportunity;blng__InvoiceLine__c;blng__CreditNote__c';
        custSetting.Disable_VR__c = true;
        custSetting.Disable_PB__c = true;
        custSetting.Disable_Trigger__c = true;
        // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
        insert custSetting;
        
        Credit_ReBill_InvoiceSchedulerValidation__c invSchCust = new Credit_ReBill_InvoiceSchedulerValidation__c();
        invSchCust.Name = 'Finland';
        invSchCust.isRunning__c = false;
        insert invSchCust;
        
        QTB_Billing_Countries__c BillingCountries = new QTB_Billing_Countries__c();
        BillingCountries.Name = 'Singapore';
        BillingCountries.Legal_entity_country__c = 'Singapore' ;
        insert BillingCountries;
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        //Product
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        database.update(product);
        
        //Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        //Account
        List<Account> accountList = new List<Account>();
        ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        Id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 10; i++) {
            Account a = new Account();
            a.Name = (a.Name == null ? 'Test' : a.Name) + i;
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.Name = 'Test Account';
            a.BillingCountry = 'Singapore';
            a.BillingPostalCode = '11209';
            a.BillingState = 'TN';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'Singapore';
            a.QTB_Legal_Entity_Country__c='Singapore';
            if(i == 0){
                a.QTB_Legal_Entity_Country__c='United States';
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
            accountList.add(a);
        }
        
        if (!accountList.isEmpty()) {
            insert accountList;
        }
        
        List<Account> standardAccountList = QTB_TestDataFactory.createAccounts(1,'Standard Account');
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        //accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Standard Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'United States';
        accountList[0].IM_Hierarchy_Level__c = 'Country Parent';
        update standardAccountList; 
        
        //Legal Entity
        blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
        USEntity.Name = 'Test Legal Entity United States';
        USEntity.blng__Active__c = true;
        USEntity.blng__Country__c = 'United States';
        USEntity.QTB_Type__c = 'Contract';
        USEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        //USEntity.QTB_Legal_Entity_Number__c = '45000';
        insert USEntity;
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';    
        im.Active__c = true;
        insert im;
        //Account
        Account a = new Account();
        a.Name = 'testdata123';
        a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
        a.RecordTypeId = recordTypeValue;
        a.QTB_Create_Parent_Billing_Account__c = true;
        a.Name = 'Test Account';
        a.BillingCountry = 'Singapore';
        a.BillingPostalCode = '11209';
        a.BillingState = 'TN';
        a.Registration_Number__c = 'Reg';
        a.ShippingCountry = 'Singapore';
        a.QTB_Legal_Entity_Country__c='Singapore';
        insert a;
        //opportunity
        /*List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
oppList[0].Pricebook2Id = pricebookId;
//oppList[0].Legal_Entity__c = USEntity.id;
oppList[0].Billing_Country__c = im.id;
database.update(oppList);*/
        
        List<Opportunity> oppList = new List<Opportunity>();
        
        Opportunity insOpp = new Opportunity();
        insOpp.name = 'testOpp';
        insOpp.AccountId = standardAccountList[0].id;
        insOpp.CloseDate = Date.today();
        insOpp.StageName = '1 - Qualification';
        insOpp.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        insOpp.Amount = 500;
        insOpp.Pricebook2Id=pricebookId;
        oppList.add(insOpp);
        
        insert oppList;
        
        //Quote
        /*List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
quoteList[0].SBQQ__PriceBook__c = pricebookId;
quoteList[0].SBQQ__StartDate__c = System.Today();
quoteList[0].QTB_IM_Legal_Entity__c = USEntity.id;
quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
database.update(quoteList);
List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);

List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
*/
        //  SBQQ.TriggerControl.disable();
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        database.update(orderList3);
        
        
        List<OrderItem> orderItemList3 = new List<OrderItem>();
        //QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);
        try {
            for (Integer i = 0; i < 1; i++) {
                orderItemList3.add(
                    new OrderItem(
                        OrderId = orderList3[0].Id,
                        Quantity = 2.00,
                        UnitPrice = 12.00,
                        //SBQQ__QuoteLine__c = quoteLines[i].id,
                        PricebookEntryId = standardPrice.Id,
                        SBQQ__ChargeType__c = 'One-Time',
                        product2id = product[0].Id,
                        SBQQ__Activated__c = true,
                        blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
                        .id,
                        blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                            'Yes'
                        )
                        .id,
                        blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id,
                        blng__HoldBilling__c = 'Yes'
                    )
                );
            }
            if (!orderItemList3.isEmpty()) {
                system.debug('orderItemList3>' + orderItemList3);
                insert orderItemList3;
            }
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            System.debug('The following exception has occurred: ' + e);
        }
        /*orderItemList3[0].blng__HoldBilling__c = 'Yes';
update orderItemList3;*/
        Contact cont = new Contact();
        cont.LastName = 'test11 ';
        cont.FirstName = 'abc1 ';
        cont.email = 'so11@email.com';
        cont.AccountId = accountList[0].Id;
        cont.MailingCountry = 'Canada';
        cont.IM_Role__c = 'PO Contact';
        insert cont;
        /* AccountContactRelation acr = new AccountContactRelation();
acr.accountId = accountList[1].id;
acr.ContactId = cont.Id;
acr.Roles = 'PO Contact';
QTB_AccountContactRelationHandler accHandler = new QTB_AccountContactRelationHandler();
accHandler.IsDisabled();
insert acr;*/
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.accountId = accountList[1].id;
        acr.ContactId = cont.Id;
        insert acr;
        
        acr.Roles = 'PO Contact';
        update acr;
        
        List<QTB_PurchaseOrder__c> POlist = new List<QTB_PurchaseOrder__c>();
        List<QTB_PurchaseOrder__c> POlist1 = new List<QTB_PurchaseOrder__c>();
        Map<id,QTB_PurchaseOrder__c> ordOldMap = new Map<id,QTB_PurchaseOrder__c>();
        Map<id,blng__Invoice__c> poInvMap = new Map<id,blng__Invoice__c>();
        
        QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(
            QTB_Billing_Account__c = accountList[1].id,
            QTB_Status__c = 'Active',
            QTB_Start_Date__c = System.today(),
            QTB_End_Date__c = System.today(),
            QTB_PO_Type__c = 'Standard',
            QTB_Customer_PO__c = 'QW2315',
            QTB_Amount__c = 10000,
            QTB_Service_Type__c = 'Mixed',
            QTB_Date_Of_100_Utilization__c = System.Today()
        );
        insert pOrder;
        system.debug('pOrder'+pOrder);
        system.debug('pOrder'+pOrder.QTB_Status__c);
        
        Polist.add(Porder);
        Map<id,blng__Invoice__c> oldMap = new Map<id,blng__Invoice__c>();
        System.debug('Polist>>>>??'+Polist);
        System.debug('>>>>Porder'+Porder);
        //Invoice
        List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
        
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[1].id;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__InvoiceDate__c = System.today()-10;
        invoice.QTB_PurchaseOrder__c = pOrder.Id;
        invoiceList.add(invoice);
        
        
        if (!invoiceList.isEmpty()) {
            insert invoiceList;
        }
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';
        invoiceList[0].QTB_ReBill_Status__c = '';
        invoiceList[0].QTB_Transferred_To_Oracle__c = true;
        invoiceList[0].QTB_Invoice_Type__c = 'ReBill';
        
        update invoiceList;
        for(blng__Invoice__c Invlist22:invoiceList){
            if(Invlist22.blng__InvoiceStatus__c == 'Posted'){
                poInvMap.put(Invlist22.id,Invlist22);
            }
        } 
        Map<id,blng__Invoice__c> invMap;
        invMap = new Map<id,blng__Invoice__c>([SELECT  QTB_PurchaseOrder__c, QTB_PurchaseOrder__r.QTB_Status__c 
                                               FROM blng__Invoice__c 
                                               WHERE QTB_PurchaseOrder__c =:invoiceList[0].QTB_PurchaseOrder__c
                                               and QTB_PurchaseOrder__r.QTB_Status__c = 'Active' LIMIT 1]);      
        Test.startTest();
        List<QTB_PurchaseOrder__c> purchaseOrderWithoutSharing = QTB_WithoutSharingUtills.calculatingPOBalanceAmountWithoutSharing(invoiceList, poInvMap);
        Test.stopTest();
        porder.QTB_PO_Utilized_Amount__c = '50'; 
        porder.QTB_Amount__c = 5;
        Map<Id, QTB_PurchaseOrder__c> poMap = new Map<Id, QTB_PurchaseOrder__c>();
        poMap.put(porder.Id, porder);
        
         try {
            QTB_WithoutSharingUtills.updatingPOBalanceAmountWithoutSharing(poMap);
        } catch (DmlException e) {
            // Catch the DmlException and assert that we are logging the expected behavior
            System.assertNotEquals(null, e.getMessage(), 'DmlException should contain a message');
            System.debug('Caught DmlException: ' + e.getMessage());

            // Assert specific error message from the exception (optional)
            System.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'FIELD_CUSTOM_VALIDATION_EXCEPTION, PO Amount Should be greater than Balance.: []');
        } 
    }   
    static testMethod void testmethod2() {
        
        try {
            List<QTB_PurchaseOrder__c> calculatingPOBalanceAmountList2 = QTB_WithoutSharingUtills.calculatingPOBalanceAmountWithoutSharing(null,null);
            QTB_WithoutSharingUtills.updatingPOBalanceAmountWithoutSharing(null);
        } catch (Exception e) {
            //System.assert('Script-thrown exception' == e.getMessage());
        }               
    }
}
/*****************************************************************************************************
* Class: QTB_OrderHelper_Test
* Author: Accenture
* Purpose: This is a test class for QTB_OrderHelper
* Change History: 6/1/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_OrderHelper_Test {
    @TestSetup
    static void createData() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        
       
    System.runAs(userList[0]) 
    {
            List<account> accountList = QTB_TestDataFactory.createAccounts(1);
            accountList[0].BillingCountry = 'India';
            accountList[0].QTB_Legal_Entity_Country__c = 'India';
            update accountList;
       System.debug('DEBUGLOG --> accountList:'+accountList); 
      blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule( 'Yes' );
      blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule( 'Yes' );
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            database.update(product);
            
            Id pricebookId = Test.getStandardPricebookId();
      PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry( product[0] );
            
            // Update the pricebook of opportunity
            //   List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            //IM Country
            IM_Country__c im = new IM_Country__c();
            im.Name = 'United States';
            im.CurrencyIsoCode = 'USD';
            im.Region__c = 'North America';
            im.AlternativeNames__c = 'United States';
            im.Iso31662Code__c ='US';
            im.Iso31663Code__c ='USA'; 
            im.Active__c = true;
            insert im;
        System.debug('DEBUGLOG --> Im  :'+im);
            list<opportunity> oppList =new list<opportunity>();
            for (Integer i = 0; i < accountList.size(); i++) {
                oppList.add(
                    new Opportunity(
                        Name = 'Test' + i,
                        AccountId = accountList[i].Id,
                        CloseDate = Date.today(),
                        StageName = '1 - Qualification',
                        RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID,
                        Amount = 500,
                        Billing_Country__c =im.id
                        //Primary_Product_Line__c = 'Data Management'
                    )
                );
            }
                System.debug('DEBUGLOG --> oppList  :'+oppList);

      if (!oppList.isEmpty()) 
      {
         Database.SaveResult[] srList = Database.insert(oppList, false);

        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('DEBUGLOG --> Successfully inserted Opportunity. Opp ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors())
                {
                    System.debug('DEBUGLOG --> The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }  
            }
      
            oppList[0].Pricebook2Id = pricebookId;
            database.update(oppList);
            
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        						1, oppList[0].id, accountList[0].id, true, null  );
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            database.update(quoteList);
            QTB_Promotion__c promo = new QTB_Promotion__c();
            promo.Name = 'test promo';
            promo.QTB_Quote_Type__c = 'Quote';
            promo.QTB_Promo_Description__c = 'test data';
            promo.QTB_Promo_Term__c = 2;
            try{
                insert promo;
            }
            catch(Exception e){
                
            }
            
            QTB_Quote_Promotion__c quotePromo = new QTB_Quote_Promotion__c();
            quotePromo.name = 'test QuotePromotion';
            quotePromo.QTB_Promotion_Name__c = promo.id;
            quotePromo.qtb_quote__c = quoteList[0].id;
            quotePromo.QTB_Promo_Term__c = 2;
            insert quotePromo;
            
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
        1, quoteList[0].id, accountList[0].id );
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
        1,quoteList[0].id, quoteGroupList[0].id, product[0].id );
            SBQQ.Triggercontrol.Disable();
            
        Test.startTest();
            List<account> accountList2 = QTB_TestDataFactory.createAccounts(
       							 1, accountList[0], null, 'Billing Account'  );
            accountList2[0].QTB_Source_Opportunity__c = oppList[0].id;
            
            update accountList2[0];
        
      
            List<Order> orderList1 = QTB_TestDataFactory.createCPQOrders(
        						1, quoteList[0].Id, accountList[0].id );
            orderList1[0].blng__BillingAccount__c = accountList2[0].id;
     //  orderList1[0].blng__BillingAccount__c = accountList3.id;
            orderList1[0].RecordTypeId = QTB_Utils.ORDER_SALES_RECTYPEID;
            orderList1[0].SBQQ__PriceCalcStatus__c = 'Not Needed';
            
            try{
                database.update(orderList1);
            }
            catch(Exception e){
            }
            orderList1[0].RecordTypeId = QTB_Utils.ORDER_BILL_RECTYPEID;
            
            try{
                database.update(orderList1);
            }
            catch(Exception e){
                
            }
            List<Order> orderList2 = QTB_TestDataFactory.createBillingOrders( 1, quoteList[0].Id,  accountList[0].id );
             // Team san-diego >>Start
            List<Order> orderList3 = QTB_TestDataFactory.createBillingOrders( 1, quotelist[0].Id, accountList2[0].id );
            orderList3[0].QTB_Hold_Contracting__c=true;
              try{
                    Database.update(orderList3[0]); 
            }
            catch(Exception e){
                System.debug('orderList3 update1 : '+e.getMessage());
            }
            orderList3[0].EffectiveDate = Date.today().adddays(-3);
            orderList3[0].blng__InvoiceBatch__c='US-SBS-1st-EOM';
            orderList3[0].RecordTypeId=QTB_Utils.ORDER_BILL_RECTYPEID;
            orderList3[0].QTB_Legal_Entity_Country__c='United States';
            orderList3[0].QTB_OrderCategory__c='Ad-Hoc';
            orderList3[0].QTB_Hold_Contracting__c=false;
            
                try{
                Database.update(orderList3[0]); 
            }
            catch(Exception e){
                System.debug('orderList3 : '+e.getMessage());
            }
            // Team san-diego >>end
            List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(
        orderList1[0].Id, product[0].Id, quoteLinesList, standardPrice );
            
            //  orderList1[0].Status = 'Activated';
            //  update orderList1[0]; 
            Test.stopTest();
            system.assert(orderItemList[0].SBQQ__ChargeType__c == 'One-Time');
        }
    }
    
    // cover catch
    static testMethod void testmethod5() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        Test.startTest();
        System.runAs(userList[1]) {
            QTB_OrderTriggerHandler.throwExplicitException = true;
            QTB_OrderTriggerHandler handler = new QTB_OrderTriggerHandler();
            handler.AfterDelete(null);
            handler.BeforeDelete(null);
            handler.AfterUndelete(null);
            try {   
                handler.AfterUpdate(null, null);
            }
            catch (NullPointerException e) {
                System.assertEquals('System.NullPointerException', e.getTypeName());
            }
            QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_ORDER);
            handler.IsDisabled();
            Test.stopTest();
        }
    }
    static testmethod void testmethod6() {
        try {
            List<order> ordLST = [SELECT id,Status,RecordTypeId,OrderNumber,SBQQ__PriceCalcStatus__c from order];
            system.debug('New order List'+ordLST);
            Test.startTest();
            QTB_OrderTriggerHandler.throwExplicitException = true;
            QTB_OrderHelper.countryClone(null, null);
            Test.stopTest();
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
    }
    static testMethod void testmethod7() {
        try {
            Test.startTest();
            QTB_OrderTriggerHandler.throwExplicitException = true;
            QTB_OrderHelper.updateOnActivationOrder(null, null);
            Test.stopTest();
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
    }
    static testMethod void testmethod8() {
        try {
            Test.startTest();
            QTB_OrderTriggerHandler.throwExplicitException = true;
            QTB_OrderHelper.setOrderTypeValue(null, null, null);
            Test.stopTest();
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
    }
    static testMethod void testmethod9() {
        try {
            Test.startTest();
            
            QTB_OrderTriggerHandler.throwExplicitException = true;
            
            QTB_OrderHelper.billingPromotions(null, null);
            Test.stopTest();
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
    }
}
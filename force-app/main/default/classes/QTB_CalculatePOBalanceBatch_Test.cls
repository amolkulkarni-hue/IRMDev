/*****************************************************************************************************
* Class: QTB_CalculatePOBalanceBatch_Test
* Author: TCS
* Purpose: Test Class for QTB_CalculatePOBalanceBatch
* Change History: 6/07/2021
* Developer       Date           Description
* ------------------------------------------------------------------------------------------- 
* Renuka Prasad   6/07/2021
*******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_CalculatePOBalanceBatch_Test {
    
    static testmethod void test() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
                'Yes'
            );
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
            );
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            database.update(product);
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
                product[0]
            );
            
            List<Account> accountList = QTB_TestDataFactory.createAccounts(
                1,
                'Billing Account'
            );
            accountList[0].QTB_Legal_Entity_Country__c='United States';
            accountList[0].CurrencyIsoCode = 'USD';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
            accountList[0].ShippingCity = 'New York';
            accountList[0].ShippingState = 'New York';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'United States';
            update accountList;
            
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            oppList[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
            oppList[0].Pricebook2Id = pricebookId;
            database.update(oppList);
            
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
                1,
                oppList[0].id,
                accountList[0].id,
                true,
                null
            );
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
            database.update(quoteList);
            Test.startTest();
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
                1,
                quoteList[0].id,
                accountList[0].id
            );
            
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
                1,
                quoteList[0].id,
                quoteGroupList[0].id,
                product[0].id
            );
            
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
                1,
                quoteList[0].Id,
                accountList[0].id
            );
            orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
            database.update(orderList3);
            SBQQ.TriggerControl.disable();
            List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
                orderList3[0].Id,
                product[0].Id,
                quoteLinesList,
                standardPrice
            );
            List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(
                accountList
            );
            
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
                1,
                accountList[0],
                orderList3[0],
                orderItemList3[0]
            );
            blng__UsageSummary__c usagesummary = usageSum[0];
            
            usagesummary.blng__Status__c = 'Queued For Invoice';
            usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
            usagesummary.blng__Subtotal__c = 100;
            usagesummary.blng__TotalQuantity__c = 10;
            usagesummary.blng__PreratedQuantity__c = 20;
            usagesummary.blng__UnbilledQuantity__c = 1;
            usagesummary.blng__UnitPrice__c = 400;
            usagesummary.blng__PreratedAmount__c = 22;
            database.update(usagesummary);
            
            List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(
                1,
                accountList[0],
                usagesummary
            );
            usageList[0].QTB_System_Generated__c = true;
            usageList[0].blng__PreratedAmount__c = 100;
            usageList[0].blng__PreratedQuantity__c = 10;
            database.update(usageList);
            
            blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity(
                'India'
            );
            
            blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
            taxIntegration.blng__TaxEngine__c = 'Standard';
            taxIntegration.blng__Active__c = true;
            database.insert(taxIntegration);
            
            blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
            blngTax.blng__TaxLegalEntity__c = indiaEntity.id;
            blngTax.blng__TaxIntegration__c = taxIntegration.id;
            blngTax.blng__TaxRule__c = taxRule.id;
            blngTax.blng__TaxCode__c = 'STD-CGST';
            database.insert(blngTax);
            
            blng__TaxRate__c taxRate = new blng__TaxRate__c();
            taxRate.blng__LegalEntity__c = indiaEntity.id;
            taxRate.blng__Priority__c = '1';
            taxRate.blng__Country__c = 'India';
            taxRate.blng__State__c = 'TN';
            taxRate.blng__City__c = 'Chennai';
            taxRate.blng__ZipCode__c = '500032';
            taxRate.blng__TaxCode__c = 'STD-CGST';
            taxRate.blng__Rate__c = 10;
            taxRate.blng__AddressComparison__c =
                taxRate.blng__Country__c +
                '-' +
                taxRate.blng__State__c +
                '-' +
                taxRate.blng__City__c +
                '-' +
                taxRate.blng__ZipCode__c +
                '-' +
                taxRate.blng__TaxCode__c +
                '-' +
                taxRate.blng__LegalEntity__c;
            taxRate.blng__Rate__c = 9;
            database.insert(taxRate);
            
            /*List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(
                1,
                invoiceList,
                product
            );
            invLineList[0].blng__OrderProduct__c = orderItemList3[0].id;
            invLineList[0].blng__UsageSummary__c = usagesummary.id;
            invLineList[0].blng__InvoiceLineStatus__c = 'Cancelled';
            invLinelist[0].blng__TaxAmount__c = 50;
            invLinelist[0].blng__TaxCountry__c = 'India';
            invLinelist[0].blng__TaxState__c = 'TN';
            invLinelist[0].blng__TaxCity__c = 'Chennai';
            invLinelist[0].blng__TaxZipCode__c = '500032';
            //invLinelist[0].QTB_Tax_Code__c='STD-CGST';
            invLinelist[0].blng__TaxTreatment__c = blngTax.id;
            invLinelist[0].blng__LegalEntity__c = indiaEntity.id;
            invLinelist[0].blng__Subtotal__c = 100;
            invLinelist[0].blng__Quantity__c = 1;
            QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
            database.update(invLineList);*/
            
            List<blng__InvoiceLine__c> invLineListFinal = new List<blng__InvoiceLine__c>();
            for (blng__Invoice__c inv : invoiceList) {
                for (Integer i = 0; i < 1; i++) {
                    blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
                    invoiceLine.Name = product[i].Name;
                    invoiceLine.blng__Invoice__c = invoiceList[i].Id;
                    invoiceLine.blng__Product__c = product[i].Id;
                    invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
                    invoiceLine.blng__Quantity__c = 1;
                    invoiceLine.blng__UnitPrice__c = 5;
                    invoiceLine.blng__TaxPercentageApplied__c = 24;
                    invoiceLine.blng__OrderProduct__c = orderItemList3[0].id;
                    invoiceLine.blng__UsageSummary__c = usagesummary.id;
                    invoiceLine.blng__TaxAmount__c = 50;
                    invoiceLine.blng__TaxCountry__c = 'India';
                    invoiceLine.blng__TaxState__c = 'TN';
                    invoiceLine.blng__TaxCity__c = 'Chennai';
                    invoiceLine.blng__TaxZipCode__c = '500032';
                    invoiceLine.blng__LegalEntity__c = indiaEntity.id;
                    invoiceLine.blng__Subtotal__c = 100;
                    //invoiceLine.blng__TaxRule__c = taxRule.id;
                    invoiceLine.QTB_Inc_Quantity__c = 10;
                    invoiceLine.QTB_Taxable_Amount__c = 10; 
                    invoiceLine.blng__TaxTreatment__c = blngTax.id;
                    invLineListFinal.add(invoiceLine);
                }
            }
            if (!invLineListFinal.isEmpty()) {
                insert invLineListFinal;
            }
            
            string invoicelineComparison =
                taxRate.blng__Country__c +
                '-' +
                taxRate.blng__State__c +
                '-' +
                taxRate.blng__City__c +
                '-' +
                taxRate.blng__ZipCode__c +
                '-' +
                taxRate.blng__TaxCode__c +
                '-' +
                taxRate.blng__LegalEntity__c;
            
            invoiceList[0].blng__InvoiceStatus__c = 'Posted';
            invoiceList[0].blng__InvoicePostedDate__c = System.today();
            update invoiceList;
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(
                accountList
            );
            System.debug('creditNotesTestClass@@'+creditNotes);
            
            List<blng__CreditNoteLine__c> CreditNoteLine = new List<blng__CreditNoteLine__c>();
            
            blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
            cnl1.QTB_Account__c = accountList[0].Id;
            cnl1.blng__CreditNote__c = creditNotes[0].id;
            cnl1.QTB_Invoice__c =  invoiceList[0].id;
            cnl1.QTB_InvoiceLine__c = invLineListFinal[0].id;
            cnl1.blng__Product__c = product[0].Id;
            cnl1.blng__Subtotal__c = 100; 
        	cnl1.QTB_Credit_Quantity__c = 1;
            cnl1.blng__CalculateTax__c=false;
            cnl1.blng__TotalAmount__c = 10;
            CreditNoteLine.add(cnl1);
            
            if(CreditNoteLine.size() > 0){
                insert CreditNoteLine;
            }
            
            //creditNotes[0].blng__Status__c = 'Posted';
            creditNotes[0].QTB_CreditNote_Posted_Date__c = System.today();
            update creditNotes;
            
            Contact con = New Contact();
            con.LastName = 'Custom Last Name:20 ' ;
            con.FirstName = 'Custom First Name ';
            con.email = 'some1@email.com';
            con.AccountId = accountList[0].id;      
            con.IM_Role__c = 'PO Contact';          
            insert con;
            /*
Contact con2 = New Contact();
con2.LastName = 'Custom Last Name:21 ' ;
con2.FirstName = 'Custom First Name ';
con2.email = 'some2@email.com';
con2.AccountId = accountList[0].Id;                
insert con2;
*/
            AccountContactRelation acr = new AccountContactRelation();
            acr.accountId = accountList[0].id;
            acr.ContactId = con.Id;
            acr.Roles = 'PO Contact';
           // insert acr;
            
            AccountContactRelation acrToUpdate = new AccountContactRelation();
            acrToUpdate.Roles = 'PO Contact';
            acrToUpdate.id = acr.id;
            //update acrToUpdate;
            
            QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c(QTB_Amount__c = 234444,
                                                               QTB_Billing_Account__c = accountList[0].id, QTB_Customer_Id__c = 'Test1111',
                                                               QTB_End_Date__c=System.today() + 20, QTB_Start_Date__c = System.today() - 5,
                                                               QTB_Status__c = 'Active',QTB_Service_Type__c = 'Mixed',QTB_PO_Type__c = 'Standard'
                                                              ,QTB_Customer_PO__c = 'PO1234');
            insert po;
            System.debug('***po**'+po.QTB_Billing_Account__r.QTB_Language__c+po.Id);
            
            Set<ID> invoiceIds = new Set<ID>();
            invoiceIds.add(invLineListFinal[0].id);
            Set<ID> creditNoteIds = new Set<ID>();
            creditNoteIds.add(creditNotes[0].id);
            
            Set<ID> poIds = new Set<ID>();
            poIds.add(po.Id);
            
            QTB_CalculatePOBalanceBatch poBalanceBatch = new QTB_CalculatePOBalanceBatch(invoiceIds, creditNoteIds, poIds);
            Database.executeBatch(poBalanceBatch,200);
            
            Test.stopTest();
            System.Assert(invLineListFinal[0].blng__InvoiceLineStatus__c == 'Posted');
        }   
    }
}
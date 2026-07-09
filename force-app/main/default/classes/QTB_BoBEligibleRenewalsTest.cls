/*****************************************************************************************************
* Class: QTB_BoBEligibleRenewalsTest
* Author: Accenture
* Purpose: This is a test class for QTB_BoBEligibleRenewals
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   28/01/2021
*******************************************************************************************************/

@isTest(seealldata=false)
public class QTB_BoBEligibleRenewalsTest {
    
    /* Commenting the entire code as part of Gitlab #25402 */
    
/*    
   @testSetup
  static void setup(){
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
        
        SBQQ.TriggerControl.disable();    
        List<Account> accList = QTB_TestDataFactory.createAccounts(1, 'Standard Account');
        accList[0].name = 'Account for Renewal Uplift';
        database.update(accList);
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product=QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c=billingRule.id;
        product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[0].blng__TaxRule__c =taxRule.id;
        database.update(product); 
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        IM_Country__c country = new IM_Country__c(Name = 'United States',Iso31662Code__c='US');
        database.insert(country);
        
       
        List<Opportunity> oppList = QTB_TestDataFactory.createOpps(accList);
        oppList[0].Pricebook2Id =pricebookId;
        oppList[0].billing_country__c = country.id;
        oppList[0].recordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        oppList[0].Primary_Product_Line__c ='Records Management';
        
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c=pricebookId;
        quoteList[0].SBQQ__StartDate__c = date.parse('01/01/2020');
        quoteList[0].SBQQ__Status__c ='Draft';
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, quoteList[0].id,accList[0].id );
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id );
        quoteList[0].SBQQ__Status__c ='Approved';
        
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].id,accList[0].id);
        List<Contract> testContracts = QTB_TestDataFactory.createCPQContracts(1,orderList[0].id,accList[0].id,quoteList[0].id);
        testContracts[0].SBQQ__Quote__c = quoteList[0].id;
        database.update(testContracts);
        
        List<Opportunity> testRenewalOpp = QTB_TestDataFactory.createCPQOppsNew(accList,'CPQ Sales Opportunity');
        testRenewalOpp[0].SBQQ__RenewedContract__c = testContracts[0].id;
        testRenewalOpp[0].QTB_Deferred_Renewal_Opportunity__c = True;
        testRenewalOpp[0].QTB_Original_Quote__c =quoteList[0].id;
        testRenewalOpp[0].billing_country__c = country.id;
        testRenewalOpp[0].Primary_Product_Line__c ='Records Management';
        
        database.update(testRenewalOpp);
        
        Test.startTest();    
        List<SBQQ__Quote__c> testRenewalQuotes = QTB_TestDataFactory.createRenewalQuotes(1, testRenewalOpp[0].Id, oppList[0].AccountId, false, null);
        
        testRenewalQuotes[0].SBQQ__Opportunity2__c = testRenewalOpp[0].id;
        testRenewalQuotes[0].SBQQ__Status__c = 'Draft';
        testRenewalQuotes[0].SBQQ__Primary__c = true;
        testRenewalQuotes[0].SBQQ__StartDate__c = system.today();  //date.parse('04/30/2021');
        
        database.update(testRenewalQuotes[0]);
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList4 = QTB_TestDataFactory.createCPQQuoteLineGroups(1, testRenewalQuotes[0].id,accList[0].id );
        List<SBQQ__QuoteLine__c> quoteLinesList4 = QTB_TestDataFactory.createCPQQuoteLines(1,testRenewalQuotes[0].id,quoteGroupList4[0].id,product[0].id );
        quoteLinesList4[0].SBQQ__ListPrice__c =10;
        database.update(quoteLinesList4);
            
         List<QTB_BoBEligibleRenewals.RenewalQuoteData> RenewalQuoteDataList = new List<QTB_BoBEligibleRenewals.RenewalQuoteData>();
         
            RenewalQuoteDataList.add(new QTB_BoBEligibleRenewals.RenewalQuoteData(testRenewalQuotes[0],true));
            QTB_BoBEligibleRenewals ren = new QTB_BoBEligibleRenewals();
            //ren.quoteList[0] = testquoteList[0];
            ren.quotewrapperList = RenewalQuoteDataList; 
            ren.next();
            //ren.previous();
            Boolean p = ren.getDisableNext();
            Boolean q = ren.getDisablePrevious(); 
            Test.stopTest();
            System.assertEquals('Account for Renewal Uplift',accList[0].name );
        }        
    } 

    static testMethod void testrenewalQuotes1(){         
        QTB_BoBEligibleRenewals ren = new QTB_BoBEligibleRenewals();
        ren.limitsize=0;
        ren.previous();
        ren.getDisableNext();
        ren.getDisablePrevious();  
        ren.submitAll();
        System.assertEquals(0, ren.limitsize );
    }
*/
}
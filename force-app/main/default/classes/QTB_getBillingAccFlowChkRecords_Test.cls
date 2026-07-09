/*************************************************************************************************************************
* Class: QTB_getBillingAccFlowChkRecords_Test
* Author: Virtusa
* Purpose: This is Test class QTB_getBillingAccFlowChkRecords
* Requirement:  GitLab #19884
* Change History:
* Developer        Date          Description
* ChandraPrakash   01/12/2023    Adding test methods to increase the coverage
***************************************************************************************************************************/
@isTest(seeAlldata=false)
public class QTB_getBillingAccFlowChkRecords_Test {
    
    @IsTest
    public static void testgetBillingAccFlowChkRecords(){
        blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('United States');
        LglEntity.CurrencyIsoCode='USD';
        update LglEntity;
        List<Account> accountList = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        IM_Country__c testCountry = new IM_Country__c(Name='United States',active__c=true);
        insert testCountry;
        list<opportunity> oppsToReturn =new list<opportunity>();
        for (Integer i = 0; i < accountList.size(); i++) {
            oppsToReturn.add(
                new Opportunity(
                    Name = 'Test' + i,
                    AccountId = accountList[i].Id,
                    CloseDate = Date.today(),
                    StageName = '1 - Qualification',
                    RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID,
                    Amount = 500,
                    Billing_Country__c=testCountry.id,
                    Primary_Product_Line__c = 'Data Management',
                    CurrencyIsoCode='USD'
                )
            );
        }
        if (!oppsToReturn.isEmpty()) {
            insert oppsToReturn;
        }
        
        List<SBQQ__Quote__c> testquote = QTB_TestDataFactory.createCPQQuotes(
            1,
            oppsToReturn[0].id,
            accountList[0].id,
            true,
            null
        );
        
        SBQQ__Quote__c updateQt = new SBQQ__Quote__c();
        updateQt.id = testquote[0].id;
        updateQt.CurrencyIsoCode = 'USD';
        
        update updateQt;
        
        List<priceBook2> prbk =QTB_TestDataFactory.priceBookMethdLst(1,'United States');
        prbk[0].QTB_Country__c='United States';
        prbk[0].CurrencyIsoCode = 'USD';
        update prbk[0];
        
        List<opportunity> oppList = [Select id,Billing_Country__c,QTB_Billing_Country_Name__c,Primary_Product_Line__c from opportunity];
        
        QTB_getBillingAccFlowChkRecords getBillAccChk = new QTB_getBillingAccFlowChkRecords();
        
        QTB_getBillingAccFlowChkRecords.OppCountryAndPrimaryProduct getBillAccFlow = new QTB_getBillingAccFlowChkRecords.OppCountryAndPrimaryProduct();
        getBillAccFlow.oppCountry = oppList[0].QTB_Billing_Country_Name__c;
        getBillAccFlow.oppPrimaryProductLine = oppList[0].Primary_Product_Line__c;
        
        List<QTB_getBillingAccFlowChkRecords.OppCountryAndPrimaryProduct> fl = new List<QTB_getBillingAccFlowChkRecords.OppCountryAndPrimaryProduct>{
            getBillAccFlow
                };
                    QTB_getBillingAccFlowChkRecords.getBillingAccountFlowSettingRecord(fl);   
        
    }
}
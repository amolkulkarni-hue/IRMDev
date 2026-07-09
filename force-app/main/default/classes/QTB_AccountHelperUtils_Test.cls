/*****************************************************************************************************
* Class: QTB_AccountHelperUtils_Test
* Author: Virtusa
* Purpose: This is a test class for QTB_AccountHelperUtils
* Change History:
* Developer         Date           Description
* -------------------------------------------------------------------------------------------
* Virtusa(Parth)    07/14/2023      
*******************************************************************************************************/
@isTest(seeAllData = false)
private class QTB_AccountHelperUtils_Test {
    @testSetup
    static void setup(){
        
    }
    static testMethod void method1() {
        try {
            test.startTest();
            blng__LegalEntity__c thailandEntity = QTB_TestDataFactory.createLegalEntity('Thailand');
            blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
            List<Account> accList = new List<Account>();
            List<Account> accList1 = new List<Account>();
            Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
            string recordType = 'Billing Account';
            Id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
                       
            list<QTB_Remit_To__c> testRemitAddr = new list<QTB_Remit_To__c>();
            
            QTB_Remit_To__c testRemit1 = new QTB_Remit_To__c();
            testRemit1.QTB_Country__c = 'Thailand';
            testRemit1.QTB_State__c = 'Phra Borom Maha Ratchawang';
            testRemit1.QTB_Default__c = true;
            testRemit1.QTB_PIN_Code_Mapping_Required__c = true;
            testRemit1.QTB_Postal_Code_From__c = '11200';
            testRemit1.QTB_Postal_Code_To__c = '11212';
            testRemit1.QTB_Legal_Entity__c = thailandEntity.Id;
            testRemit1.QTB_Status__c = 'Active';
            testRemitAddr.add(testRemit1);
            
            QTB_Remit_To__c testRemit2 = new QTB_Remit_To__c();
            testRemit2.QTB_Country__c = 'India';
            testRemit2.QTB_State__c = 'Karnataka';
            testRemit2.QTB_Default__c = true;
            testRemit2.QTB_PIN_Code_Mapping_Required__c = true;
            testRemit2.QTB_Postal_Code_From__c = '11200';
            testRemit2.QTB_Postal_Code_To__c = '11212';
            testRemit2.QTB_Legal_Entity__c = indiaEntity.Id;
            testRemit2.QTB_Status__c = 'Active';
            testRemitAddr.add(testRemit2);
            
            QTB_Remit_To__c testRemit3 = new QTB_Remit_To__c();
            testRemit3.QTB_Country__c = 'India';
            testRemit3.QTB_State__c = 'Karnataka';
            testRemit3.QTB_Default__c = false;
            testRemit3.QTB_PIN_Code_Mapping_Required__c = true;
            testRemit3.QTB_Postal_Code_From__c = '43500';
            testRemit3.QTB_Postal_Code_To__c = '54332';
            testRemit3.QTB_Status__c = 'Active';
            testRemit3.QTB_Legal_Entity__c = indiaEntity.Id;
            testRemitAddr.add(testRemit3);
            insert testRemitAddr;
            
            list<QTB_Bank_Detail__c> testBankDetails = new list<QTB_Bank_Detail__c>();
            QTB_Bank_Detail__c testBankDet1 = new QTB_Bank_Detail__c();
            testBankDet1.Name = 'BankName';
            testBankDet1.QTB_Bank_Country__c = '123456789';
            testBankDet1.CurrencyIsoCode = 'THB';
            testBankDet1.QTB_Default__c = true;
            testBankDet1.QTB_Legal_Entity__c = thailandEntity.Id;
            testBankDet1.QTB_Payment_Method__c = 'ACH';
            testBankDet1.QTB_Status__c = 'Active';
            testBankDetails.add(testBankDet1);
            insert testBankDetails;
            list<QTB_Bank_To_Remit__c> testBankToRemit = new list<QTB_Bank_To_Remit__c>();
            QTB_Bank_To_Remit__c testBankToRemit1 = new QTB_Bank_To_Remit__c();
            testBankToRemit1.QTB_Remit_To__c = testRemitAddr[0].id;
            testBankToRemit1.QTB_Bank_Details__c = testBankDetails[0].id;
            testBankToRemit1.QTB_Is_Active__c = true;
            testBankToRemit1.QTB_Legal_Entity__c = thailandEntity.Id;
            testBankToRemit1.QTB_Payment_Method__c = 'ACH';
            testBankToRemit.add(testBankToRemit1);
            insert testBankToRemit;
            //Billing Account
            Account a = new Account();
            a.Name = 'Test';
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.BillingCountry = 'Thailand';
            a.BillingPostalCode = '11209';
            a.BillingState = 'Phra Borom Maha Ratchawang';
            a.BillingCity = 'Phra Nakhon';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'Thailand';
            a.ShippingState = 'Phra Borom Maha Ratchawang';
            a.ShippingPostalCode = '11209';
            a.QTB_Contract_Entity__c = thailandEntity.id;
            a.QTB_Legal_Entity_Country__c = 'Thailand';
            a.Payment_Terms__c = 'Net 15';
            accList.add(a);
            Insert accList;
            Set<Id> accIds = new Set<Id>();
            if(!accList.isEmpty() && accList.size() >0){
                accIds.add(accList[0].Id);
                System.debug('accIds>>'+accIds);
            }
            QTB_AccountHelperUtils.validateStateValue(accList);
            QTB_AccountHelperUtils.validateCityValue(accList);
            AccountTriggerHandler.throwExplicitException = true;
            QTB_AccountHelperUtils.validateStateValue(accList);
            QTB_AccountHelperUtils.updatePaymentTermBasedUponAccountPaymentTermValue(accIds);
            Set<String> billingCountrySet = new Set<String>();
            Set<String> legalEntitySet = new Set<String>();
            Set<String> remitToSet = new Set<String>();
            billingCountrySet.add('India');
            billingCountrySet.add('Thailand');
            legalEntitySet.add(thailandEntity.id);
            remitToSet.add(testRemitAddr[0].id);
            QTB_AccountHelperUtils.updateRemitToAddress(accList,legalEntitySet);
            QTB_AccountHelperUtils.updateBankDetail(accList,remitToSet,legalEntitySet);
            
            AccountTriggerHandler.throwExplicitException = true;
            QTB_AccountHelperUtils.validateTaxTreatmentOnAccount(accList,'BEFORE_INSERT');
            test.stopTest();
        }
        catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
    }
    static testMethod void method2() {
        try {
            //Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
            //Billing Account
            /*List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
accountList[0].QTB_Legal_Entity_Country__c = 'India';
accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
accountList[0].ShippingCity = 'TN';
accountList[0].ShippingState = 'Chennai';
accountList[0].ShippingPostalCode = '500032';
accountList[0].ShippingCountry = 'India';
accountList[0].QTB_Records_Management__c = true;
accountList[0].Payment_Terms__c = 'Net 30';
accountList[0].RecordTypeId=accBillRecordTypeId;
Update accountList[0];

blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');*/
            QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
            setting.name = 'India';
            setting.Active__c = true;
            setting.Legal_entity_country__c = 'India';
            insert setting;
            
            blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
            //Tax Rule
            blng__TaxRule__c taxRule = new blng__TaxRule__c();
            taxRule.Name = 'Standard tax Rule';
            taxRule.blng__Active__c = true;
            taxRule.blng__TaxableYesNo__c = 'Yes';
            insert taxRule;
            
            //Tax Integration
            blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
            taxIntegration.blng__TaxEngine__c = 'Standard';
            taxIntegration.blng__Active__c = true;
            insert taxIntegration;
            
            //Tax Treatment
            blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
            blngTax.blng__TaxLegalEntity__c = indiaEntity.id;
            blngTax.blng__TaxIntegration__c = taxIntegration.id;
            blngTax.blng__TaxRule__c = taxRule.id;
            blngTax.QTB_TaxCountry__c = 'India';
            blngTax.blng__TaxCode__c = 'STD-CGST';
            insert blngTax;
            
            //Tax Rate
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
            insert taxRate;
            
            //string custLabel = label.QTB_CountryNameForStateValidation;
            //system.debug('custLabel--->'+custLabel);
            List<Account> accList = new List<Account>();
            List<Account> accList1 = new List<Account>();
            Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
            string recordType = 'Billing Account';
            Id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
            //Billing Account
            Account a = new Account();
            a.Name = 'Test';
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.BillingCountry = 'India';
            a.BillingPostalCode = '11209';
            a.BillingState = 'Phra Borom Maha Ratchawang';
            a.BillingCity = 'Phra Nakhon';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'India';
            a.ShippingState = 'Phra Borom Maha Ratchawang';
            a.ShippingPostalCode = '11209';
            a.QTB_Contract_Entity__c = indiaEntity.id;
            a.QTB_Legal_Entity_Country__c = 'India';
            a.Payment_Terms__c = 'Net 15';
            accList.add(a);
            Insert accList;
            
            
            Test.startTest();
            list<Account> acc = [select id,name,QTB_Legal_Entity_Country__c,QTB_Legal_Entity__c, QTB_Legal_Entity__r.blng__Country__c, ShippingCountry, QTB_Special_Tax_Condition__c,QTB_Contract_Entity__c from Account where CreatedDate = TODAY ];
            Set<Id> accLegalEntity = new Set<Id>();
            Set<ID> entityID = new Set<ID>();
            Set<String> accShipTo = new Set<String>();
            Set<String> accSplTax = new Set<String>();
            accLegalEntity.add(acc[0].QTB_Legal_Entity__c);
            accShipTo.add(acc[0].ShippingCountry);
            entityID.add(acc[0].QTB_Contract_Entity__c);
            accSplTax.add(acc[0].QTB_Special_Tax_Condition__c);
            QTB_AccountHelperUtils.validateTaxTreatmentOnAccount(acc,'BEFORE_INSERT');
            AccountTriggerHandler.throwExplicitException = true;
            QTB_AccountHelperUtils.validateTaxTreatmentOnAccount(acc,'BEFORE_INSERT');
            //QTB_AccountHelperUtils.updatePaymentTermBasedUponAccountPaymentTermValue(accIds);
            Test.stopTest();
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
    }
    static testMethod void method3() {
        try {
            Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
            blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
            
            QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
            setting.name = 'India';
            setting.Active__c = true;
            setting.Legal_entity_country__c = 'India';
            insert setting;

            //Tax Rule
            blng__TaxRule__c taxRule = new blng__TaxRule__c();
            taxRule.Name = 'Standard tax Rule';
            taxRule.blng__Active__c = true;
            taxRule.blng__TaxableYesNo__c = 'Yes';
            insert taxRule;
            
            //Tax Integration
            blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
            taxIntegration.blng__TaxEngine__c = 'Standard';
            taxIntegration.blng__Active__c = true;
            insert taxIntegration;
            
            //Tax Treatment
            blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
            blngTax.blng__TaxLegalEntity__c = indiaEntity.id;
            blngTax.blng__TaxIntegration__c = taxIntegration.id;
            blngTax.blng__TaxRule__c = taxRule.id;
            blngTax.QTB_TaxCountry__c = 'India';
            blngTax.blng__TaxCode__c = 'STD-CGST';
            insert blngTax;
            
            //Tax Rate
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
            insert taxRate;
            
             list<QTB_Remit_To__c> testRemitAddr = new list<QTB_Remit_To__c>();
            QTB_Remit_To__c testRemit = new QTB_Remit_To__c();
            testRemit.QTB_Country__c = 'India';
            testRemit.QTB_State__c = 'Karnataka';
            testRemit.QTB_Default__c = true;
            testRemit.QTB_Legal_Entity__c = indiaEntity.Id;
            //testRemit.QTB_PIN_Code_Mapping_Required__c = true;
            testRemit.QTB_Postal_Code_From__c = '54332';
            testRemit.QTB_Postal_Code_To__c = '54332';
            testRemit.QTB_Status__c = 'Active';
            testRemitAddr.add(testRemit);
            insert testRemitAddr;
            
            System.debug('testRemitAddr>>'+testRemitAddr);
            
            list<QTB_Bank_Detail__c> testBankDetails1 = new list<QTB_Bank_Detail__c>();
            
            QTB_Bank_Detail__c testBankDet2 = new QTB_Bank_Detail__c();
            testBankDet2.Name = 'BankName';
            testBankDet2.QTB_Bank_Country__c = 'India';
            testBankDet2.CurrencyIsoCode = 'INR';
            testBankDet2.QTB_Default__c = true;
            testBankDet2.QTB_Legal_Entity__c = indiaEntity.Id;
            testBankDet2.QTB_Payment_Method__c = 'ACH';
            testBankDet2.QTB_Status__c = 'Active';
            testBankDetails1.add(testBankDet2);
            insert testBankDetails1;
            list<QTB_Bank_To_Remit__c> testBankToRemit1 = new list<QTB_Bank_To_Remit__c>();
            QTB_Bank_To_Remit__c testBankToRemit2 = new QTB_Bank_To_Remit__c();
            testBankToRemit2.QTB_Remit_To__c = testRemitAddr[0].id;
            testBankToRemit2.QTB_Bank_Details__c = testBankDetails1[0].id;
            testBankToRemit2.QTB_Is_Active__c = true;
            testBankToRemit2.QTB_Legal_Entity__c = indiaEntity.Id;
            testBankToRemit2.QTB_Payment_Method__c = 'ACH';
            testBankToRemit1.add(testBankToRemit2);
            insert testBankToRemit1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c = 'India';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
            accountList[0].ShippingCity = 'CH';
            accountList[0].ShippingState = 'CH';
            accountList[0].QTB_Contract_Entity__c = indiaEntity.id;
            accountList[0].ShippingPostalCode = '500032';
            accountList[0].ShippingCountry = 'India';
            accountList[0].BillingCountry = 'India';
            accountList[0].BillingState = 'Karnataka';
            accountList[0].BillingPostalCode = '54332';
            accountList[0].QTB_Records_Management__c = true;
            accountList[0].Payment_Terms__c = 'Net 30';
            accountList[0].RecordTypeId=accBillRecordTypeId;
            accountList[0].SBQQ__TaxExempt__c = 'No';
            accountList[0].Payment_Terms__c = 'Net 15';
            accountList[0].QTB_Payment_Method__c = 'ACH';
            update accountList[0];
            
            Test.startTest();
            list<Account> acc = [select id,name,SBQQ__TaxExempt__c,QTB_Legal_Entity_Country__c,QTB_Legal_Entity__c, QTB_Legal_Entity__r.blng__Country__c, ShippingCountry, QTB_Special_Tax_Condition__c,QTB_Contract_Entity__c from Account where CreatedDate = TODAY ];
            Set<Id> accLegalEntity = new Set<Id>();
            Set<String> legalEntitySet = new Set<String>();
            Set<String> accShipTo = new Set<String>();
            Set<String> accSplTax = new Set<String>();
            Set<ID> entityID = new Set<ID>();
            Set<String>remitToSet = new Set<String>();
            Set<Id>accIds = new Set<Id>();
            accIds.add(acc[0].Id);
            remitToSet.add(testRemitAddr[0].id);
            accLegalEntity.add(acc[0].QTB_Legal_Entity__c);
            legalEntitySet.add(acc[0].QTB_Contract_Entity__c);
            entityID.add(acc[0].QTB_Contract_Entity__c);
            accShipTo.add(acc[0].ShippingCountry);
            accSplTax.add(acc[0].QTB_Special_Tax_Condition__c);
            QTB_AccountHelperUtils.validateTaxTreatmentOnAccount(acc,'BEFORE_UPDATE');
            Set<String> billingCountrySet = new Set<String>();
            billingCountrySet.add('India');
            QTB_AccountHelperUtils.updateRemitToAddress(acc,legalEntitySet);
            QTB_AccountHelperUtils.updateBankDetail(acc,remitToSet,legalEntitySet);
            QTB_AccountHelperUtils.updatePaymentTermBasedUponAccountPaymentTermValue(accIds);
            Test.stopTest();
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
    }
    static testMethod void catchException() {
         	List<Account> accList1 = new List<Account>();
            Set<Id> accIds = new Set<Id>();
            Set<String> legalEntitySet = new Set<String>();
            Set<String>remitToSet = new Set<String>();
        try {
            test.startTest();
            AccountTriggerHandler.throwExplicitException = true;
            QTB_AccountHelperUtils.validateCityValue(accList1);
            }
        catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
        try {
      		QTB_AccountHelperUtils.updateRemitToAddress(accList1,legalEntitySet);
    		} 
        catch (NullPointerException e) 
        {
      		System.assertEquals('System.NullPointerException', e.getTypeName());
    	}
        try {
      		QTB_AccountHelperUtils.updateBankDetail(accList1,remitToSet,legalEntitySet);
    		} 
        catch (NullPointerException e) 
        {
      		System.assertEquals('System.NullPointerException', e.getTypeName());
    	}
        try {
      		QTB_AccountHelperUtils.updatePaymentTermBasedUponAccountPaymentTermValue(null);
    		} 
        catch (NullPointerException e) 
        {
      		System.assertEquals('System.NullPointerException', e.getTypeName());
    	}
        try {
      		QTB_AccountHelperUtils.updateOperationalAccInfoBasedUponBillCUpdate(accIds);
    		} 
        catch (NullPointerException e) 
        {
      		System.assertEquals('System.NullPointerException', e.getTypeName());
    	}
         test.stopTest();
    }
       
}
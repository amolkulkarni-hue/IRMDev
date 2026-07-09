/*****************************************************************************************************
* Class: QTB_CreditNoteIDGeneration_Test
* Author: Accenture
* Purpose: This is a test class for QTB_CreditNoteIDGeneration
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture     5/4
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_CreditNoteIDGeneration_Test {
    
    private static testMethod void methodIndia()
    {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'india';
            sweCustomSettings.QTB_Country__c = 'india';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '2000000001';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'india credit';
            sweCustomSettings1.QTB_Country__c = 'india';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '2000000001';
            insert sweCustomSettings1; 
            blng__LegalEntity__c Indiaentity= QTB_TestDataFactory.createLegalEntity('India');
            blng__LegalEntity__c Indiaentity1= QTB_TestDataFactory.createLegalEntity('India');
            Indiaentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update  Indiaentity1;
            //Billing Account
            Market__c IndiaMarket = new Market__c(Name='Maharashtra-MH',QTB_State__c='Maharashtra',District_NAME__c='Maharashtra');
            Insert IndiaMarket;
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='india';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'Pune';
            accountList[0].ShippingState = 'Maharashtra';
            accountList[0].ShippingPostalCode = '45000';
            accountList[0].ShippingCountry = 'india';
            accountList[0].QTB_Contract_Entity__c=Indiaentity.id;
            accountList[0].QTB_Market__c=IndiaMarket.id;
            accountList[1].QTB_Legal_Entity_Country__c='india';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test2';
            accountList[1].ShippingCity = 'Pune';
            accountList[1].ShippingState = 'Maharashtra';
            accountList[1].ShippingPostalCode = '45000';
            accountList[1].ShippingCountry = 'india';
            accountList[1].QTB_Market__c=IndiaMarket.id;
            accountList[1].QTB_Contract_Entity__c=Indiaentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
            // creditNotes[0].blng__Account__c = accountList[0].Id;
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'NOK';
            Update creditNotes;             
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
        }
    }
    private static testMethod void methodFinland()
    {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'finland';
            sweCustomSettings.QTB_Country__c = 'finland';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000010540';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'finland credit';
            sweCustomSettings1.QTB_Country__c = 'finland';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000010540';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c Swedenentity=QTB_TestDataFactory.createLegalEntity('finland');
            blng__LegalEntity__c Swedenentity1=QTB_TestDataFactory.createLegalEntity('finland');
            Swedenentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            Update Swedenentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Finland';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Finland';
            accountList[0].QTB_Contract_Entity__c=Swedenentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Finland';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Finland';
            accountList[1].QTB_Contract_Entity__c=Swedenentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
            
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'EUR';
            Update creditNotes;   
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
        
    } 
     private static testMethod void methodFinlandDuplicate()
    {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'finland';
            sweCustomSettings.QTB_Country__c = 'finland';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000010540';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'finland credit';
            sweCustomSettings1.QTB_Country__c = 'finland';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000010540';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c Swedenentity=QTB_TestDataFactory.createLegalEntity('finland');
            blng__LegalEntity__c Swedenentity1=QTB_TestDataFactory.createLegalEntity('finland');
            Swedenentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            Update Swedenentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Finland';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Finland';
            accountList[0].QTB_Contract_Entity__c=Swedenentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Finland';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Finland';
            accountList[1].QTB_Contract_Entity__c=Swedenentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
            
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'EUR';
            Update creditNotes;   
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
               
            }catch(exception e){}
            Test.stopTest();
            
        }
        
    }    
    
    private static testMethod void methodDenmark()
    {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'denmark';
            sweCustomSettings.QTB_Country__c = 'denmark';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '4000003698';
            insert sweCustomSettings; 
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'denmark credit';
            sweCustomSettings1.QTB_Country__c = 'denmark';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '4000003698';
            insert sweCustomSettings1;
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('denmark');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('denmark');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Denmark';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Denmark';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Denmark';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Denmark';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);       
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'DKK';
            Update creditNotes;   
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
        
    }
    private static testMethod void methodDenmarkDuplicate()
    {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'denmark';
            sweCustomSettings.QTB_Country__c = 'denmark';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '4000003698';
            insert sweCustomSettings; 
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'denmark credit';
            sweCustomSettings1.QTB_Country__c = 'denmark';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '4000003698';
            insert sweCustomSettings1;
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('denmark');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('denmark');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Denmark';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Denmark';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Denmark';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Denmark';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);       
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'DKK';
            Update creditNotes;   
            try
            {
                  Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
           }catch(exception e){}
            Test.stopTest();
            
        }
        
    }
    private static testMethod void methodSweden() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'sweden';
            sweCustomSettings.QTB_Country__c = 'sweden';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '2000008740';
            insert sweCustomSettings;  
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'sweden credit';
            sweCustomSettings1.QTB_Country__c = 'sweden';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '2000008740';
            insert sweCustomSettings1;
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('sweden'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('sweden');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = true;
            update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='sweden';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].BillingPostalCode = '123 45';
            accountList[0].ShippingPostalCode = '123 45';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingCountry = 'sweden';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='sweden';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].BillingPostalCode = '133 45';
            accountList[1].ShippingPostalCode = '133 45';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingCountry = 'sweden';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SEK';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
     private static testMethod void methodSwedenDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'sweden';
            sweCustomSettings.QTB_Country__c = 'sweden';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '2000008740';
            insert sweCustomSettings;  
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'sweden credit';
            sweCustomSettings1.QTB_Country__c = 'sweden';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '2000008740';
            insert sweCustomSettings1;
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('sweden'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('sweden');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = true;
            update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='sweden';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].BillingPostalCode = '123 45';
            accountList[0].ShippingPostalCode = '123 45';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingCountry = 'sweden';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='sweden';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].BillingPostalCode = '133 45';
            accountList[1].ShippingPostalCode = '133 45';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingCountry = 'sweden';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SEK';
            Update creditNotes;
            
            try
            {
                    Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
           
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodTaiwan() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'taiwan';
            sweCustomSettings.QTB_Country__c = 'taiwan';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '5000000001';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'taiwan credit';
            sweCustomSettings1.QTB_Country__c = 'taiwan';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '5000000001';
            insert sweCustomSettings1;    
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('taiwan');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('taiwan');       
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c= True;
            Update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Taiwan';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Taiwan';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Taiwan';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Taiwan';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'THB';      
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodTaiwanDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            list<Id> accId = new list<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'taiwan';
            sweCustomSettings.QTB_Country__c = 'taiwan';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '5000000001';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'taiwan credit';
            sweCustomSettings1.QTB_Country__c = 'taiwan';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '5000000001';
            insert sweCustomSettings1;    
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('taiwan');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('taiwan');       
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c= True;
            Update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Taiwan';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Taiwan';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Taiwan';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Taiwan';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accId.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'THB';      
            Update creditNotes;
            
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accId[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodThailand() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'thailand';
            sweCustomSettings.QTB_Country__c = 'thailand';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '6000025396';
            insert sweCustomSettings;        
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'thailand credit';
            sweCustomSettings1.QTB_Country__c = 'thailand';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '6000025396';
            insert sweCustomSettings1;    
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('thailand');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('thailand'); 
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            Update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Thailand';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Thailand';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Thailand';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Thailand';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);       
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'THB';   
            Update creditNotes;
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }   
    private static testMethod void methodThailandDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'thailand';
            sweCustomSettings.QTB_Country__c = 'thailand';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '6000025396';
            insert sweCustomSettings;        
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'thailand credit';
            sweCustomSettings1.QTB_Country__c = 'thailand';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '6000025396';
            insert sweCustomSettings1;    
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('thailand');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('thailand'); 
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            Update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Thailand';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Thailand';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Thailand';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Thailand';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);       
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'THB';   
            Update creditNotes;
            try
            {
              Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
              
            }catch(exception e){}
            Test.stopTest();
            
        }
    }   
    private static testMethod void methodMalaysia() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'malaysia';
            sweCustomSettings.QTB_Country__c = 'malaysia';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '6000025396';
            insert sweCustomSettings; 
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'malaysia credit';
            sweCustomSettings1.QTB_Country__c = 'malaysia';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '6000025396';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('MALAYSIA'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('MALAYSIA');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;      
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Malaysia';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Malaysia';
            accountList[0].QTB_Tax_Registration__c ='15234237';
            accountList[0].QTB_Tax_ID__c ='1235';
            accountList[0].QTB_TIN__c = '9102335';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id; 
            accountList[1].QTB_Legal_Entity_Country__c='Malaysia';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Malaysia';
            accountList[1].QTB_Tax_Registration__c ='15234237';
            accountList[1].QTB_Tax_ID__c ='1235';
            accountList[1].QTB_TIN__c = '9102335';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote         
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);       
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'MYR';
            Update creditNotes;
            
            try
            {
               QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    private static testMethod void methodMalaysiaDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accId = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'malaysia';
            sweCustomSettings.QTB_Country__c = 'malaysia';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '6000025396';
            insert sweCustomSettings; 
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('MALAYSIA');       
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Malaysia';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Malaysia';
            accountList[0].QTB_Tax_Registration__c ='15234237';
            accountList[0].QTB_Tax_ID__c ='1235';
            accountList[0].QTB_TIN__c = '9102335';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;   
            update accountList;
            for (Account acc : accountList) {
                accId.add(acc.Id);
            }
            //creditnote         
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);       
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'MYR';
            Update creditNotes;
            
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accId[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }     
    private static testMethod void methodHongKong() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'hong kong';
            sweCustomSettings.QTB_Country__c = 'hong kong';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055191';
            insert sweCustomSettings; 
            
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'hong kong credit';
            sweCustomSettings1.QTB_Country__c = 'hong kong';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '8000055191';
            insert sweCustomSettings1; 
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('HONG KONG');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('HONG KONG');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Hong Kong';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Hong Kong';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Hong Kong';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Hong Kong';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);       
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'HKD';
            Update creditNotes;    
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }     
    private static testMethod void methodHongKongDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'hong kong';
            sweCustomSettings.QTB_Country__c = 'hong kong';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055191';
            insert sweCustomSettings; 
            
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'hong kong credit';
            sweCustomSettings1.QTB_Country__c = 'hong kong';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '8000055191';
            insert sweCustomSettings1; 
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('HONG KONG');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('HONG KONG');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Hong Kong';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Hong Kong';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Hong Kong';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Hong Kong';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);       
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'HKD';
            Update creditNotes;    
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
              
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodSingapore() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'singapore';
            sweCustomSettings.QTB_Country__c = 'singapore';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055191';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'singapore credit';
            sweCustomSettings1.QTB_Country__c = 'singapore';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '8000055191';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('SINGAPORE');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('SINGAPORE');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Singapore';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Singapore';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }  
    private static testMethod void methodSingaporeDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'singapore';
            sweCustomSettings.QTB_Country__c = 'singapore';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055191';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'singapore credit';
            sweCustomSettings1.QTB_Country__c = 'singapore';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '8000055191';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('SINGAPORE');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('SINGAPORE');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Singapore';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Singapore';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                 Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
              
            }catch(exception e){}
            Test.stopTest();
            
        }
    }   
    private static testMethod void methodFrance() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'france';
            sweCustomSettings.QTB_Country__c = 'france';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '2000002174';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'france credit';
            sweCustomSettings1.QTB_Country__c = 'france';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '2000002174';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('france'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('france');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='france';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'france';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }  
    private static testMethod void methodFranceDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accId = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'france';
            sweCustomSettings.QTB_Country__c = 'france';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '2000002174';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'france credit';
            sweCustomSettings1.QTB_Country__c = 'france';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '2000002174';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('france'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('france');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='france';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'france';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accId.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accId[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }     
    private static testMethod void methodbelgium() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'belgium';
            sweCustomSettings.QTB_Country__c = 'belgium';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'belgium credit';
            sweCustomSettings1.QTB_Country__c = 'belgium';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('belgium'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('belgium');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='belgium';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'belgium';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    private static testMethod void methodbelgiumDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accId = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'belgium';
            sweCustomSettings.QTB_Country__c = 'belgium';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'belgium credit';
            sweCustomSettings1.QTB_Country__c = 'belgium';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('belgium'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('belgium');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='belgium';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'belgium';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accId.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accId[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }   
    
    private static testMethod void methodNetherlands() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'netherlands';
            sweCustomSettings.QTB_Country__c = 'netherlands';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '4000001533';
            insert sweCustomSettings;
            
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'netherlands credit';
            sweCustomSettings1.QTB_Country__c = 'netherlands';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '4000001533';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('netherlands'); 
            blng__LegalEntity__c denmarkentity1 = QTB_TestDataFactory.createLegalEntity('netherlands');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Singapore';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Singapore';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
               }catch(exception e){}
            Test.stopTest();
            
        }
    }   
     private static testMethod void methodNetherlandsDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'netherlands';
            sweCustomSettings.QTB_Country__c = 'netherlands';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '4000001533';
            insert sweCustomSettings;
            
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'netherlands credit';
            sweCustomSettings1.QTB_Country__c = 'netherlands';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '4000001533';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('netherlands'); 
            blng__LegalEntity__c denmarkentity1 = QTB_TestDataFactory.createLegalEntity('netherlands');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Singapore';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Singapore';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
               Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
            
            }catch(exception e){}
            Test.stopTest();
            
        }
    }    
    private static testMethod void methodRomania() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'romania';
            sweCustomSettings.QTB_Country__c = 'romania';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings;
            
            // Sequencing Added
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'romania credit';
            sweCustomSettings1.QTB_Country__c = 'romania';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings1;           
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('romania'); 
            blng__LegalEntity__c romaniaentity=QTB_TestDataFactory.createLegalEntity('romania');
            romaniaentity.QTB_Separate_Inv_Crd_Seq__c = true;
            update romaniaentity;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Singapore';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Singapore';
            accountList[1].QTB_Contract_Entity__c=romaniaentity.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
             QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodRomaniaDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'romania';
            sweCustomSettings.QTB_Country__c = 'romania';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings;
            
            // Sequencing Added
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'romania credit';
            sweCustomSettings1.QTB_Country__c = 'romania';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings1;           
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('romania'); 
            blng__LegalEntity__c romaniaentity=QTB_TestDataFactory.createLegalEntity('romania');
            romaniaentity.QTB_Separate_Inv_Crd_Seq__c = true;
            update romaniaentity;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Singapore';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Singapore';
            accountList[1].QTB_Contract_Entity__c=romaniaentity.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                  Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
           }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodSlovakia() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'slovakia';
            sweCustomSettings.QTB_Country__c = 'slovakia';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '101234';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'slovakia credit';
            sweCustomSettings1.QTB_Country__c = 'slovakia';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '101234';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('slovakia');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('slovakia'); 
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='slovakia';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'slovakia';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='slovakia';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity1';
            accountList[1].ShippingState = 'teststate1';
            accountList[1].ShippingPostalCode = '221311';
            accountList[1].ShippingCountry = 'slovakia';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
              QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }      
    private static testMethod void methodSlovakiaDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'slovakia';
            sweCustomSettings.QTB_Country__c = 'slovakia';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '101234';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'slovakia credit';
            sweCustomSettings1.QTB_Country__c = 'slovakia';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '101234';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('slovakia');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('slovakia'); 
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='slovakia';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'slovakia';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='slovakia';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity1';
            accountList[1].ShippingState = 'teststate1';
            accountList[1].ShippingPostalCode = '221311';
            accountList[1].ShippingCountry = 'slovakia';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                  Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodGreece() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'greece';
            sweCustomSettings.QTB_Country__c = 'greece';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '5000008006';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'greece credit';
            sweCustomSettings1.QTB_Country__c = 'greece';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '5000008006';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('greece');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('greece');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            Update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='greece';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Singapore';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodGreeceDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accId = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'greece';
            sweCustomSettings.QTB_Country__c = 'greece';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '5000008006';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'greece credit';
            sweCustomSettings1.QTB_Country__c = 'greece';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '5000008006';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('greece');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('greece');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            Update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Singapore';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'Singapore';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='greece';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'Singapore';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accId.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accId[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
                
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    
    
    private static testMethod void methodHungary() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            //#28025
            sweCustomSettings.Name = 'hungary;45000';
            sweCustomSettings.QTB_Country__c = 'hungary';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '6000008027';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            //#28025
            sweCustomSettings1.Name = 'hungary;45000;credit';
            sweCustomSettings1.QTB_Country__c = 'hungary';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '6000008027';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('hungary');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('hungary');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='hungary';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'hungary';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='hungary';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'hungary';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodHungaryDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            //#28025
            sweCustomSettings.Name = 'hungary;45000';
            sweCustomSettings.QTB_Country__c = 'hungary';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '6000008027';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            //#28025
            sweCustomSettings1.Name = 'hungary;45000;credit';
            sweCustomSettings1.QTB_Country__c = 'hungary';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '6000008027';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('hungary');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('hungary');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='hungary';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'hungary';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='hungary';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'hungary';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    
    private static testMethod void methodSpain() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'spain';
            sweCustomSettings.QTB_Country__c = 'spain';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '2000003021';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'spain credit';
            sweCustomSettings1.QTB_Country__c = 'spain';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '2000003021';
            insert sweCustomSettings1;
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('spain');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('spain');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='spain';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'spain';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id; 
            accountList[1].QTB_Legal_Entity_Country__c='spain';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'spain';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }   
    
    private static testMethod void methodSpainDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'spain';
            sweCustomSettings.QTB_Country__c = 'spain';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '2000003021';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'spain credit';
            sweCustomSettings1.QTB_Country__c = 'spain';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '2000003021';
            insert sweCustomSettings1;
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('spain');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('spain');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='spain';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'spain';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id; 
            accountList[1].QTB_Legal_Entity_Country__c='spain';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'spain';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
                
            }catch(exception e){}
            Test.stopTest();
            
        }
    }     
    
    private static testMethod void methodAustria() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'austria';
            sweCustomSettings.QTB_Country__c = 'austria';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '4000008027';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'austria credit';
            sweCustomSettings1.QTB_Country__c = 'austria';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '4000008027';
            insert sweCustomSettings1;
            
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('austria');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('austria'); 
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            Update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='austria';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'austria';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='austria';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'austria';
            accountList[0].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    private static testMethod void methodAustriaDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'austria';
            sweCustomSettings.QTB_Country__c = 'austria';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '4000008027';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'austria credit';
            sweCustomSettings1.QTB_Country__c = 'austria';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '4000008027';
            insert sweCustomSettings1;
            
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('austria');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('austria'); 
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            Update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='austria';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'austria';
            accountList[0]. QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='austria';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'austria';
            accountList[0]. QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
                
            }catch(exception e){}
            Test.stopTest();
            
        }
    }         
    private static testMethod void methodGermany() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            //#28025
            sweCustomSettings.Name = 'germany;45000';
            sweCustomSettings.QTB_Country__c = 'germany';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '8000008032';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            //#28025
            sweCustomSettings1.Name = 'germany;45000;credit';
            sweCustomSettings1.QTB_Country__c = 'germany';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '8000008032';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('germany');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('germany');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='germany';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'germany';
            accountList[0]. QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='germany';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'germany';
            accountList[1]. QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }            
    private static testMethod void methodGermanyDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            //#28025
            sweCustomSettings.Name = 'germany;45000';
            sweCustomSettings.QTB_Country__c = 'germany';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '8000008032';
            insert sweCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            //#28025
            sweCustomSettings1.Name = 'germany;45000;credit';
            sweCustomSettings1.QTB_Country__c = 'germany';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '8000008032';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('germany');       
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('germany');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='germany';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'germany';
            accountList[0]. QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='germany';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'germany';
            accountList[1]. QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
            Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    private static testMethod void methodNorway() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'norway';
            sweCustomSettings.QTB_Country__c = 'norway';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '1000003360';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'norway credit';
            sweCustomSettings1.QTB_Country__c = 'norway';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '1000003360';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('norway');
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('norway');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;       
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='norway';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'norway';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id; 
            accountList[1].QTB_Legal_Entity_Country__c='norway';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'norway';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;  
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    private static testMethod void methodNorwayDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'norway';
            sweCustomSettings.QTB_Country__c = 'norway';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '1000003360';
            insert sweCustomSettings;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('norway');       
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='norway';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'norway';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;   
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'SGD';
            Update creditNotes;
            
            try
            {
             Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    private static testMethod void methodNewzealand() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'new zealand';
            sweCustomSettings.QTB_Country__c = 'new zealand';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'new zealand credit';
            sweCustomSettings1.QTB_Country__c = 'new zealand';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('new zealand'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('new zealand');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='new zealand';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'new zealand';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='new zealand';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'new zealand';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'AUD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    
    private static testMethod void methodNewzealandDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'new zealand';
            sweCustomSettings.QTB_Country__c = 'new zealand';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'new zealand credit';
            sweCustomSettings1.QTB_Country__c = 'new zealand';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('new zealand'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('new zealand');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='new zealand';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'new zealand';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='new zealand';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'new zealand';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'NZD';
            Update creditNotes;
            
            try
            {
                 Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
                
           
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    
    private static testMethod void methodAustralia() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'australia';
            sweCustomSettings.QTB_Country__c = 'australia';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'australia credit';
            sweCustomSettings1.QTB_Country__c = 'australia';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('australia'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('australia');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='australia';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'australia';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='australia';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'australia';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'AUD';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    
    private static testMethod void methodTurkey() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'turkey;e-Arşiv';
            sweCustomSettings.QTB_Country__c = 'turkey';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'turkey;e-Arşiv;credit';
            sweCustomSettings1.QTB_Country__c = 'turkey';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings1;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings2 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings2.Name = 'turkey;e-Fatura';
            sweCustomSettings2.QTB_Country__c = 'turkey';
            sweCustomSettings2.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings2;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings3 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings3.Name = 'turkey;e-Fatura;credit';
            sweCustomSettings3.QTB_Country__c = 'turkey';
            sweCustomSettings3.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings3;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('turkey'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('turkey');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='turkey';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].QTB_Invoice_Delivery_Options__c = 'e-Fatura';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'turkey';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='turkey';
            accountList[1].QTB_Invoice_Delivery_Options__c = 'e-Arşiv';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'turkey';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'TRY';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    
    private static testMethod void methodTurkeyDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'turkey';
            sweCustomSettings.QTB_Country__c = 'turkey';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'turkey credit';
            sweCustomSettings1.QTB_Country__c = 'turkey';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('turkey'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('turkey');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='turkey';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'turkey';
            accountList[0].QTB_Invoice_Delivery_Options__c = 'e-Arşiv';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='turkey';
            accountList[1].QTB_Invoice_Delivery_Options__c = 'e-Fatura';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'turkey';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'TRY';
            Update creditNotes;
            
            try
            {
                 Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Invoice_Delivery_Options__c,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
                
           
            }catch(exception e){}
            
            try
            {
                 Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Invoice_Delivery_Options__c,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[0]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
                
           
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    
    private static testMethod void methodAustraliaDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'australia';
            sweCustomSettings.QTB_Country__c = 'australia';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings;
            
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'australia credit';
            sweCustomSettings1.QTB_Country__c = 'australia';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000001518';
            insert sweCustomSettings1;
            
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('australia'); 
            blng__LegalEntity__c denmarkentity1=QTB_TestDataFactory.createLegalEntity('australia');
            denmarkentity1.QTB_Separate_Inv_Crd_Seq__c = True;
            update denmarkentity1;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='australia';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[0].ShippingCity = 'testcity';
            accountList[0].ShippingState = 'teststate';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'australia';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='australia';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'test1';
            accountList[1].ShippingCity = 'testcity';
            accountList[1].ShippingState = 'teststate';
            accountList[1].ShippingPostalCode = '22131';
            accountList[1].ShippingCountry = 'australia';
            accountList[1].QTB_Contract_Entity__c=denmarkentity1.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'AUD';
            Update creditNotes;
            
            try
            {
                 Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
                
           
            }catch(exception e){}
            Test.stopTest();
            
        }
    } 
    private static testMethod void methodIreLand() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'ireland';
            sweCustomSettings.QTB_Country__c = 'ireland';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings;
            
            // Sequencing Added
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'ireland credit';
            sweCustomSettings1.QTB_Country__c = 'ireland';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings1;           
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('ireland'); 
            blng__LegalEntity__c romaniaentity=QTB_TestDataFactory.createLegalEntity('ireland');
            romaniaentity.QTB_Separate_Inv_Crd_Seq__c = true;
            update romaniaentity;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Ireland';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'testIre';
            accountList[0].ShippingCity = 'testcity1';
            accountList[0].ShippingState = 'teststate1';
            accountList[0].ShippingPostalCode = '22137';
            accountList[0].ShippingCountry = 'Ireland';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Ireland';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'testIre';
            accountList[1].ShippingCity = 'testcity1';
            accountList[1].ShippingState = 'teststate1';
            accountList[1].ShippingPostalCode = '22137';
            accountList[1].ShippingCountry = 'Ireland';
            accountList[1].QTB_Contract_Entity__c=romaniaentity.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'EUR';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodCR() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            List<Id> accIdList = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'czech republic';
            sweCustomSettings.QTB_Country__c = 'czech republic';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings;
            
            // Sequencing Added
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'czech republic credit';
            sweCustomSettings1.QTB_Country__c = 'czech republic';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000008017';
            insert sweCustomSettings1;           
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('czech republic'); 
            blng__LegalEntity__c romaniaentity=QTB_TestDataFactory.createLegalEntity('czech republic');
            romaniaentity.QTB_Separate_Inv_Crd_Seq__c = true;
            update romaniaentity;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Czech Republic';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'testUK';
            accountList[0].ShippingCity = 'testcityCR';
            accountList[0].ShippingState = 'teststateCR';
            accountList[0].ShippingPostalCode = '22135';
            accountList[0].ShippingCountry = 'Czech Republic';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Czech Republic';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'testCR';
            accountList[1].ShippingCity = 'testcityCR';
            accountList[1].ShippingState = 'teststateCR';
            accountList[1].ShippingPostalCode = '22135';
            accountList[1].ShippingCountry = 'Czech Republic';
            accountList[1].QTB_Contract_Entity__c=romaniaentity.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
                accIdList.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'EUR';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodCRDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'czech republic';
            sweCustomSettings.QTB_Country__c = 'czech republic';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings;
            
            // Sequencing Added
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'czech republic credit';
            sweCustomSettings1.QTB_Country__c = 'czech republic';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000008017';
            insert sweCustomSettings1;           
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('czech republic'); 
            denmarkentity.blng__Country__c ='czech republic';  
            update denmarkentity;
            blng__LegalEntity__c romaniaentity=QTB_TestDataFactory.createLegalEntity('czech republic');
            romaniaentity.QTB_Separate_Inv_Crd_Seq__c = true;
            update romaniaentity;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Czech Republic';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'testCR';
            accountList[0].ShippingCity = 'testcityCR';
            accountList[0].ShippingState = 'teststateCR';
            accountList[0].ShippingPostalCode = '22135';
            accountList[0].ShippingCountry = 'Czech Republic';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Czech Republic';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'testCR';
            accountList[1].ShippingCity = 'testcityCR';
            accountList[1].ShippingState = 'teststateCR';
            accountList[1].ShippingPostalCode = '22135';
            accountList[1].ShippingCountry = 'Czech Republic';
            accountList[1].QTB_Contract_Entity__c=romaniaentity.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'EUR';
            Update creditNotes;
            
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
     private static testMethod void methodIreLandDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accIds = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'ireland';
            sweCustomSettings.QTB_Country__c = 'ireland';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings;
            
            // Sequencing Added
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'ireland credit';
            sweCustomSettings1.QTB_Country__c = 'ireland';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings1;           
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('ireland'); 
            blng__LegalEntity__c romaniaentity=QTB_TestDataFactory.createLegalEntity('ireland');
            romaniaentity.QTB_Separate_Inv_Crd_Seq__c = true;
            update romaniaentity;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='Ireland';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'testIre';
            accountList[0].ShippingCity = 'testcity1';
            accountList[0].ShippingState = 'teststate1';
            accountList[0].ShippingPostalCode = '22137';
            accountList[0].ShippingCountry = 'Ireland';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='Ireland';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'testIre';
            accountList[1].ShippingCity = 'testcity1';
            accountList[1].ShippingState = 'teststate1';
            accountList[1].ShippingPostalCode = '22137';
            accountList[1].ShippingCountry = 'Ireland';
            accountList[1].QTB_Contract_Entity__c=romaniaentity.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'EUR';
            Update creditNotes;
            
            try
            {
              Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accIds[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
            
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodUK() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Set<Id> accIds = new Set<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'united kingdom';
            sweCustomSettings.QTB_Country__c = 'united kingdom';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings;
            
            // Sequencing Added
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'united kingdom credit';
            sweCustomSettings1.QTB_Country__c = 'united kingdom';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings1;           
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('united kingdom'); 
            blng__LegalEntity__c romaniaentity=QTB_TestDataFactory.createLegalEntity('united kingdom');
            romaniaentity.QTB_Separate_Inv_Crd_Seq__c = true;
            update romaniaentity;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='United Kingdom';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'testUK';
            accountList[0].ShippingCity = 'testcityIK';
            accountList[0].ShippingState = 'teststateUK';
            accountList[0].ShippingPostalCode = '22139';
            accountList[0].ShippingCountry = 'United Kingdom';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='United Kingdom';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'testUK';
            accountList[1].ShippingCity = 'testcityUK';
            accountList[1].ShippingState = 'teststateUK';
            accountList[1].ShippingPostalCode = '22139';
            accountList[1].ShippingCountry = 'United Kingdom';
            accountList[1].QTB_Contract_Entity__c=romaniaentity.id;
            update accountList;
            for (Account acc : accountList) {
                accIds.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'EUR';
            Update creditNotes;
            
            try
            {
                QTB_CreditNoteIDGeneration.processCreditNote(creditNotes, accIds);
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void methodUKDuplicate() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Id> accId = new List<Id>();
            
            QTB_TestDataFactory.createCustomInvoiceNumber();
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'united kingdom';
            sweCustomSettings.QTB_Country__c = 'united kingdom';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings;
            
            // Sequencing Added
            //custom settings
            QTB_CustomInvoiceNumber__c sweCustomSettings1 = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings1.Name = 'united kingdom credit';
            sweCustomSettings1.QTB_Country__c = 'united kingdom';
            sweCustomSettings1.QTB_Next_Sequence_Number__c = '3000008015';
            insert sweCustomSettings1;           
            blng__LegalEntity__c denmarkentity=QTB_TestDataFactory.createLegalEntity('united kingdom'); 
            blng__LegalEntity__c romaniaentity=QTB_TestDataFactory.createLegalEntity('united kingdom');
            romaniaentity.QTB_Separate_Inv_Crd_Seq__c = true;
            update romaniaentity;
            
            //Billing Account
            List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='United Kingdom';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'testUK';
            accountList[0].ShippingCity = 'testcityIK';
            accountList[0].ShippingState = 'teststateUK';
            accountList[0].ShippingPostalCode = '22139';
            accountList[0].ShippingCountry = 'United Kingdom';
            accountList[0].QTB_Contract_Entity__c=denmarkentity.id;
            accountList[1].QTB_Legal_Entity_Country__c='United Kingdom';
            accountList[1].QTB_Billing_Account_Invoice_Name__c = 'testUK';
            accountList[1].ShippingCity = 'testcityUK';
            accountList[1].ShippingState = 'teststateUK';
            accountList[1].ShippingPostalCode = '22139';
            accountList[1].ShippingCountry = 'United Kingdom';
            accountList[1].QTB_Contract_Entity__c=romaniaentity.id;
            update accountList;
            for (Account acc : accountList) {
                accId.add(acc.Id);
            }
            //creditnote
            
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);      
            creditNotes[0].blng__CreditNoteDate__c = date.today();
            creditNotes[0].QTB_Reason_Code__c = 'Account Creation';
            creditNotes[0].blng__Status__c = 'Draft';
            creditNotes[0].CurrencyIsoCode = 'EUR';
            Update creditNotes;
            
            try
            {
                Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                duplicateMapCreditNote.put(creditNotes[0].Id,creditNotes[0]);
                Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                               QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                               FROM Account WHERE ID =:accId[1]];
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, acc,duplicateMapCreditNote);
                
            }catch(exception e){}
            Test.stopTest();
            
        }
    }
    private static testMethod void method12() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[1]) {
            QTB_CreditNoteIDGeneration.throwExplicitException = true;
            Test.stopTest();
            try {
                QTB_CreditNoteIDGeneration.processCreditNote(null, null);
            } catch (Exception e) {
                System.assert('Script-thrown exception' == e.getMessage());
            }
            try {
                QTB_CreditNoteIDGeneration.updateCreditNoteID(null, null,null);
            } catch (Exception e) {
                System.assert('Script-thrown exception' == e.getMessage());
            }
            System.assertEquals(
                true,
                QTB_CreditNoteIDGeneration.throwExplicitException
            );
        }
    }
}
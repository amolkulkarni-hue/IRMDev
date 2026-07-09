/*****************************************************************************************************
* Class: QTB_Ready_For_integration_Scheduler_Test
* Author: 
* Purpose: This is a test class for QTB_Ready_For_integration_Scheduler
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*            05/07/2024
*******************************************************************************************************/
@isTest(seeallData=false)
private with sharing class QTB_Ready_For_integration_Scheduler_Test {
    @TestSetup
    static void createData() {
        //List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //System.runAs(userList[0]) {
        Test.startTest();
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;AccountContactRelation;blng__Invoice__c';
        custSetting.Disable_VR__c = true;
        custSetting.Disable_PB__c = true;
        custSetting.Disable_Trigger__c = true;
        // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
        insert custSetting;
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Thailand'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Sweden'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Finland'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Denmark'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Taiwan'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Malaysia'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Hong Kong'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Singapore'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('India'));
        for(blng__LegalEntity__c le :entityList){
            if(le.blng__Country__c == 'Thailand'){
                le.QTB_Tax_Applicability__c ='Product Based';
            }
            else{
                le.QTB_Tax_Applicability__c ='Flat Rate';
            }
        }
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(10); //insert 10 accounts
        for (Integer i = 0; i < accList.size(); i++) {
            accList[i].QTB_Hold_Invoice__c = false;
            accList[i].QTB_Contract_Entity__c = entityList[8].Id;
            accList[i].QTB_Legal_Entity_Country__c = 'Thailand';
        }
        update accList;
                
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(
            accList
        );
        
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        invList[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList[0].QTB_Custom_Invoice_Number__c=null;
        invList[0].QTB_KID__c=null;
        invList[0].blng__InvoiceStatus__c='Posted';
        invList[0].QTB_Bill_Cycle_Day__c ='1';
        for(blng__Invoice__c inv :invList){
            inv.QTB_Tax_Override_Amount__c = 10;
        }
        
        
        List<blng__InvoiceLine__c> invLinesList = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__TaxCountry__c = 'India';
        invoiceLine.blng__Invoice__c = invList[0].id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        insert invoiceLine;
        
        
        invLinesList.add(invoiceLine);
        if(!invLinesList.isEmpty()){  
            SBQQ.TriggerControl.disable();
            update invList;
            System.debug('Invoice lines created'+invList);
            SBQQ.TriggerControl.enable();
            
        }
        // }
    }
    static testmethod void test() {
        Test.startTest();
         List<blng__Invoice__c> invLst = [SELECT ID,blng__InvoiceStatus__c,RecordType.Name,QTB_Transferred_to_Invoice_Compliance__c,blng__InvoicePostedDate__c,QTB_Custom_Invoice_Number__c 
                                         from blng__Invoice__c]; 

        Set<Id> invIds = new Set<Id>();
        if(!invLst.isEmpty()){
            for(blng__Invoice__c inv:invLst){
                invIds.add(inv.Id);
            }
        }
        QTB_Ready_for_Int_Invoice_Scheduler obj = new QTB_Ready_for_Int_Invoice_Scheduler(invIds);
        String sch = '10 0 * * * ?';
        String jobID = System.schedule('Schedule to update Invoice', sch,obj);
        /*QTB_Ready_for_Integration_Batch b=new QTB_Ready_for_Integration_Batch(invIds);
        Database.executeBatch(b);
        b.execute(invIds);
        b.finish(null);*/
        Test.stopTest();
        system.assertNotEquals(jobID, null);
    }
    static testmethod void test1() {
        Test.startTest();
        
        //Legal Entity
        blng__LegalEntity__c ThailandEntity = new blng__LegalEntity__c();
        ThailandEntity.Name = 'Test Legal Entity Singapore';
        ThailandEntity.blng__Active__c = true;
        ThailandEntity.blng__Country__c = 'Singapore';
        ThailandEntity.QTB_Type__c = 'Contract';
        ThailandEntity.QTB_Tax_Applicability__c = 'Product Based';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert ThailandEntity; 
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Thailand-1st';
        accountList[0].QTB_Legal_Entity_Country__c='Thailand';
        accountList[0].QTB_Contract_Entity__c  = ThailandEntity.Id;
        //accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Operational Account').getRecordTypeId();
        update accountList;
        
        List<blng__Invoice__c> invList1 = QTB_TestDataFactory.createInvoices(
            accountList
        );
        invList1[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList1[0].QTB_Custom_Invoice_Number__c=null;
        invList1[0].QTB_KID__c=null;
        invList1[0].blng__InvoiceStatus__c='Posted';
        invList1[0].QTB_Bill_Cycle_Day__c ='1';
        update invList1;
        
		List<blng__Invoice__c> invList2 = QTB_TestDataFactory.createInvoices(
            accountList
        );
		
        invList2[0].blng__InvoiceStatus__c = 'Posted';
        //invList2[0].blng__InvoiceDate__c = System.today();
        invList2[0].QTB_Invoice_Type__c = 'ReBill';
        invList2[0].QTB_Rebilled__c = true;
        invList2[0].QTB_Parent_Invoice__c = invList1[0].id; 
        invList2[0].QTB_Ready_for_Integration__c = false;
        update invList2;
        
        List<blng__InvoiceLine__c> invLinesList1 = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        invoiceLine1.Name = 'prodName';
        invoiceLine1.blng__TaxCountry__c = 'Thailand';
        invoiceLine1.blng__Invoice__c = invList1[0].id;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Draft';
        invLinesList1.add(invoiceLine1);
        insert invLinesList1;
        
        list<QTB_Tax_Detail__c> testTax = new list<QTB_Tax_Detail__c>();
        QTB_Tax_Detail__c test1 = new QTB_Tax_Detail__c();
        //test1.QTB_Invoice_Line__c  = invLinesList1[0].id;
        test1.QTB_Invoice__c  = invList1[0].id;
        test1.QTB_Jurisdiction__c = 'Test1';
        test1.QTB_Imposition__c  = 'Test2';
        test1.QTB_CalculatedTax__c = 23.00;
        testTax.add(test1);
        
        QTB_Tax_Detail__c test2 = new QTB_Tax_Detail__c();
        test2.QTB_Invoice__c  = invList1[0].id;
        test2.QTB_Invoice_Line__c  = invLinesList1[0].id;
        test2.QTB_Jurisdiction__c = 'Test11';
        test2.QTB_Imposition__c  = 'Test22';
        test2.QTB_CalculatedTax__c = 24.00;
        testTax.add(test2);
        insert testTax;
        
        system.debug('testTax>>'+testTax);
        
        List<blng__Invoice__c> invIds = [SELECT ID,blng__InvoiceStatus__c,RecordType.Name,QTB_Transferred_to_Invoice_Compliance__c,blng__InvoicePostedDate__c,QTB_Custom_Invoice_Number__c 
                                         from blng__Invoice__c];
        
        List<blng__InvoiceLine__c> lstInvLine = [select id,blng__InvoiceLineStatus__c,blng__Invoice__c,blng__Invoice__r.blng__InvoiceStatus__c from blng__InvoiceLine__c limit 1];
        
        system.debug('@@@@@@@@2  '+invIds);
        system.debug('@@@@@@@@3333  '+lstInvLine);
        Set<Id> invIds1 = new Set<Id>();
        if(!invIds.isEmpty()){
            for(blng__Invoice__c inv:invIds){
                system.debug('STATUSSS @@  '+INV.blng__InvoiceStatus__c);
                system.debug('IDDDC @@  '+INV.id);
                invIds1.add(inv.Id);
            }
        }
        
        QTB_ReadyForIntegrationWithSuccessError a = new QTB_ReadyForIntegrationWithSuccessError(invIds1);
    	database.executeBatch(a);

        QTB_Ready_for_Int_Invoice_Scheduler obj = new QTB_Ready_for_Int_Invoice_Scheduler(invIds1);
        String sch = '10 0 * * * ?';
        String jobID = System.schedule('Schedule to update Invoice', sch,obj);
        QTB_Ready_for_Integration_Batch.throwExplicitException = True;
       
	   QTB_Rebill_ReadyForInt_Scheduler rebill = new QTB_Rebill_ReadyForInt_Scheduler();
        String sch1 = '10 0 * * * ?';
		String jobID1 = System.schedule('Rebill to update Invoice', sch1,rebill);
        
        System.debug('invLst>>>'+invIds1);
        
        Test.stopTest();
        system.assertNotEquals(jobID, null);
    }
    //cover catch
    static testMethod void testMethod1() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Test.startTest();
            QTB_Ready_for_Integration_Batch.throwExplicitException = true;
            
            QTB_Ready_for_Integration_Batch obj = new QTB_Ready_for_Integration_Batch(null);
            obj.execute(null, null);
            QTB_Ready_for_Integration_Batch obj1 = new QTB_Ready_for_Integration_Batch(null);
            obj1.finish(null);
            
            QTB_ReadyForIntegrationWithSuccessError b1=new QTB_ReadyForIntegrationWithSuccessError(null);
            b1.execute(null, null);
            QTB_ReadyForIntegrationWithSuccessError b2=new QTB_ReadyForIntegrationWithSuccessError(null);
            b2.finish(null);
            Test.stopTest();
            System.assertEquals(true, QTB_Ready_for_Integration_Batch.throwExplicitException);
            System.assertEquals(false, QTB_ReadyForIntegrationWithSuccessError.throwExplicitException);
        }
    }
    static testmethod void test2() {
        Test.startTest();
        
        //Legal Entity
        blng__LegalEntity__c ThailandEntity = new blng__LegalEntity__c();
        ThailandEntity.Name = 'Test Legal Entity Singapore';
        ThailandEntity.blng__Active__c = true;
        ThailandEntity.blng__Country__c = 'Singapore';
        ThailandEntity.QTB_Type__c = 'Contract';
        ThailandEntity.QTB_Tax_Applicability__c = 'Product Based';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert ThailandEntity; 
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Thailand-1st';
        accountList[0].QTB_Legal_Entity_Country__c='Thailand';
        accountList[0].QTB_Contract_Entity__c  = ThailandEntity.Id;
        //accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Operational Account').getRecordTypeId();
        update accountList;
        
        List<blng__Invoice__c> invList1 = QTB_TestDataFactory.createInvoices(
            accountList
        );
        invList1[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList1[0].QTB_Custom_Invoice_Number__c=null;
        invList1[0].QTB_KID__c=null;
        invList1[0].blng__InvoiceStatus__c='Posted';
        invList1[0].QTB_Bill_Cycle_Day__c ='1';
        update invList1;
        
		List<blng__Invoice__c> invList2 = QTB_TestDataFactory.createInvoices(
            accountList
        );
		
        invList2[0].blng__InvoiceStatus__c = 'Posted';
        //invList2[0].blng__InvoiceDate__c = System.today();
        invList2[0].QTB_Invoice_Type__c = 'ReBill';
        invList2[0].QTB_Rebilled__c = true;
        invList2[0].QTB_Parent_Invoice__c = invList1[0].id; 
        invList2[0].QTB_Ready_for_Integration__c = false;
        update invList2;
        
        List<blng__InvoiceLine__c> invLinesList1 = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        invoiceLine1.Name = 'prodName';
        invoiceLine1.blng__TaxCountry__c = 'Thailand';
        invoiceLine1.blng__Invoice__c = invList1[0].id;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Draft';
        invLinesList1.add(invoiceLine1);
        insert invLinesList1;
        
        list<QTB_Tax_Detail__c> testTax = new list<QTB_Tax_Detail__c>();
        QTB_Tax_Detail__c test1 = new QTB_Tax_Detail__c();
        //test1.QTB_Invoice_Line__c  = invLinesList1[0].id;
        test1.QTB_Invoice__c  = invList1[0].id;
        test1.QTB_Jurisdiction__c = 'Test1';
        test1.QTB_Imposition__c  = 'Test2';
        test1.QTB_CalculatedTax__c = 23.00;
        testTax.add(test1);
        
        QTB_Tax_Detail__c test2 = new QTB_Tax_Detail__c();
        test2.QTB_Invoice__c  = invList1[0].id;
        test2.QTB_Invoice_Line__c  = invLinesList1[0].id;
        test2.QTB_Jurisdiction__c = 'Test11';
        test2.QTB_Imposition__c  = 'Test22';
        test2.QTB_CalculatedTax__c = 24.00;
        testTax.add(test2);
        insert testTax;
        
        system.debug('testTax>>'+testTax);
        
        List<blng__Invoice__c> invIds = [SELECT ID,blng__InvoiceStatus__c,RecordType.Name,QTB_Transferred_to_Invoice_Compliance__c,blng__InvoicePostedDate__c,QTB_Custom_Invoice_Number__c 
                                         ,QTB_Invoice_Type__c,QTB_Rebilled__c,QTB_Ready_for_Integration__c from blng__Invoice__c];
        
        List<blng__InvoiceLine__c> lstInvLine = [select id,blng__InvoiceLineStatus__c,blng__Invoice__c,blng__Invoice__r.blng__InvoiceStatus__c from blng__InvoiceLine__c limit 1];
        
        system.debug('@@@@@@@@2  '+invIds);
        system.debug('@@@@@@@@3333  '+lstInvLine);
        Set<Id> invIds1 = new Set<Id>();
        if(!invIds.isEmpty()){
            for(blng__Invoice__c inv:invIds){
                system.debug('STATUSSS @@  '+inv.blng__InvoiceStatus__c);
                system.debug(inv.QTB_Invoice_Type__c);
                system.debug(inv.QTB_Rebilled__c);
                system.debug(inv.QTB_Ready_for_Integration__c);
                system.debug('IDDDC @@  '+INV.id);
                invIds1.add(inv.Id);
            }
        }
        
         
		QTB_Rebill_ReadyForInt_Scheduler rebill = new QTB_Rebill_ReadyForInt_Scheduler();
        String sch1 = '10 0 * * * ?';
		String jobID1 = System.schedule('Rebill to update Invoice', sch1,rebill);
        
        Test.stopTest();
        
    }
}
/*****************************************************************************************************
* Class: QTB_ReadyForIntWithSuccessError_Test
* Author: 
* Purpose: Test Class for QTB_Ready_for_Integration_Batch
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*           5/7/2024
*******************************************************************************************************/
@isTest(seeAllData=false) 
private class QTB_ReadyForIntWithSuccessError_Test {
    @TestSetup
    static void createData() {
        //List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //System.runAs(userList[0]) {
        Test.startTest();
        
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Sweden'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Finland'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Denmark'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Taiwan'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Thailand'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Malaysia'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Hong Kong'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Singapore'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('India'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('United States'));
        for(blng__LegalEntity__c le :entityList){
            if(le.blng__Country__c == 'Thailand'){
                le.QTB_Tax_Applicability__c ='Product Based';
            }
            else{
                le.QTB_Tax_Applicability__c ='Flat Rate';
            }
        }
        update entityList;
        for(blng__LegalEntity__c le :entityList){
            system.debug('legal entity.QTB_Tax_Applicability__c--->'+le.QTB_Tax_Applicability__c);
        }
        List<Account> accList = QTB_TestDataFactory.createAccounts(11); //insert 10 accounts
        for (Integer i = 0; i < accList.size(); i++) {
            accList[i].QTB_Hold_Invoice__c = false;
            accList[i].QTB_Contract_Entity__c = entityList[i].Id;
        }
        update accList;
        system.debug('accList>>'+accList);
        
         //Invoice
        List<blng__Invoice__c> invoiceList2 = new List<blng__Invoice__c>();
        for (integer i = 0; i < accList.size(); i++) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accList[i].Id;
            invoice.blng__InvoiceStatus__c = 'Draft';
            if(i == 0){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Invoice_Type__c = 'New';
                invoice.QTB_Custom_Invoice_Number__c='IND12345670';
            }
            if(i == 1 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Custom_Invoice_Number__c='IND12345671';
            }
            if(i == 2){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Invoice_Type__c = 'New';
                invoice.QTB_Custom_Invoice_Number__c='IND12345672';
                //invoice.QTB_Parent_Invoice__c = invoiceList[0].id;
            }
            if(i == 3 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Custom_Invoice_Number__c='IND12345673';
            }
            if(i == 4 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Custom_Invoice_Number__c='IND12345674';
            }
            if(i == 5 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Custom_Invoice_Number__c='IND12345675';
            }
            if(i == 6 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Custom_Invoice_Number__c='IND12345676';
            }
            if(i == 7 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Custom_Invoice_Number__c='IND12345677';
            }
            if(i == 8 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Custom_Invoice_Number__c='IND12345678';
            }
            invoiceList2.add(invoice);
        }
        if (!invoiceList2.isEmpty()) {
            insert invoiceList2;
        }
        List<blng__InvoiceLine__c> invLinesList = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__TaxCountry__c = 'India';
        invoiceLine.blng__Invoice__c = invoiceList2[0].id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        insert invoiceLine;
        
        
        invLinesList.add(invoiceLine);
            
       /* if(!invLinesList.isEmpty()){	
            insert invLinesList;
            System.debug('1!!! '+invLinesList[0].blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c);
            System.debug('2@@@ '+invLinesList[0].blng__TaxPercentageApplied__c);
        	System.debug('3### '+invLinesList[0].blng__TaxCountry__c);
            System.debug('Invoice created'+invoiceList2[0].blng__Account__c+'->'+invoiceList2[0].blng__Account__r.QTB_Contract_Entity__c+'->'+invoiceList2[0].blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c);
            System.debug('Invoice lines created'+invLinesList[0].blng__Invoice__c+'->'+invLinesList[0].blng__Invoice__r.blng__Account__c+'->'+invLinesList[0].blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__c+'->'+invLinesList[0].blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c);
        }*/
    }
    static testmethod void test1() {
        Test.startTest();
        blng__LegalEntity__c ThailandEntity = new blng__LegalEntity__c();
        ThailandEntity.Name = 'Test Legal Entity Singapore';
        ThailandEntity.blng__Active__c = true;
        ThailandEntity.blng__Country__c = 'Singapore';
        ThailandEntity.QTB_Type__c = 'Contract';
        ThailandEntity.QTB_Tax_Applicability__c = 'Product Based';
        insert ThailandEntity; 
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Thailand-1st';
        accountList[0].QTB_Legal_Entity_Country__c='Thailand';
        accountList[0].QTB_Contract_Entity__c  = ThailandEntity.Id;
        accountList[0].BillingCity = 'Hi';
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
	    Test.stopTest();
       
    }
    static testmethod void testMethod1() {
        Test.startTest();
        List<blng__InvoiceLine__c> invLinesLst = [select id,blng__Invoice__r.blng__Account__c,blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__c,blng__TaxAmount__c,blng__InvoiceLineStatus__c,QTB_Tax_Override_Amount__c,blng__Invoice__r.id,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                             blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Invoice__r.QTB_Transferred_to_Invoice_Compliance__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                             blng__Invoice__c,blng__Invoice__r.blng__NumberOfInvoiceLines__c,LastModifiedDate,blng__Invoice__r.QTB_Custom_Invoice_Number__c,blng__Invoice__r.QTB_Ready_for_Integration__c,blng__Invoice__r.QTB_Ready_for_Integration_Status__c,
                                                             blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                                                             blng__Invoice__r.blng__Account__r.QTB_Customer_Number__c from blng__InvoiceLine__c];   
        
        blng__LegalEntity__c indEntity = [select id from blng__LegalEntity__c where blng__Country__c = 'India' Limit 1];
        blng__TaxRate__c taxRate = new blng__TaxRate__c();
        taxRate.blng__LegalEntity__c = indEntity.id;
        taxRate.blng__Priority__c = '1';
        taxRate.blng__Country__c = 'India';
        taxRate.blng__State__c = 'TN';
        taxRate.blng__City__c = 'Chennai';
        taxRate.blng__ZipCode__c = '500032';
        taxRate.blng__TaxCode__c = 'STD-CGST';
        taxRate.blng__Rate__c = 10;
        taxRate.blng__AddressComparison__c =taxRate.blng__Country__c +'-' +taxRate.blng__State__c +'-' +taxRate.blng__City__c +'-' +taxRate.blng__ZipCode__c +'-' +taxRate.blng__TaxCode__c +'-' +taxRate.blng__LegalEntity__c;
        try{
            insert taxRate;
        }
        catch(exception e){
            system.debug(e.getMessage());
        }
        QTB_Tax_Detail__c taxDet1 = new QTB_Tax_Detail__c(); 
        taxDet1.QTB_Individual_Tax_Amount__c = 10;
        taxDet1.QTB_Invoice__c = invLinesLst[0].blng__Invoice__c;
        taxDet1.QTB_CalculatedTax__c = 10;
        taxDet1.QTB_Tax_Code__c = taxRate.blng__TaxCode__c;
        taxDet1.QTB_EffectiveRate__c = taxRate.blng__Rate__c;
        //taxDet1.QTB_Invoice_Line_Subtotal__c = invList[0].blng__Subtotal__c;
        taxDet1.CurrencyIsoCode = 'INR';
        taxDet1.QTB_TaxRateId__c = taxRate.Id;
        taxDet1.QTB_TaxType__c = taxRate.QTB_TaxDisplay__c;
        insert taxDet1;
        
        
        Set<Id>InvoiceIds = new Set<Id>();
        for(blng__InvoiceLine__c invln :invLinesLst){
            InvoiceIds.add(invln.blng__Invoice__c);
        }
        
        QTB_ReadyForIntegrationWithSuccessError b=new QTB_ReadyForIntegrationWithSuccessError(InvoiceIds);
        Database.executeBatch(b);
        Test.stopTest();
    }
    //cover catch
    static testMethod void testMethod2() {
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Test.startTest();
            QTB_ReadyForIntegrationWithSuccessError.throwExplicitException = true;
           
            QTB_ReadyForIntegrationWithSuccessError b4=new QTB_ReadyForIntegrationWithSuccessError(null);
        	b4.start(null);
            QTB_ReadyForIntegrationWithSuccessError b1=new QTB_ReadyForIntegrationWithSuccessError(null);
            b1.execute(null, null);
            QTB_ReadyForIntegrationWithSuccessError b2=new QTB_ReadyForIntegrationWithSuccessError(null);
            b2.finish(null);
            Test.stopTest();
            System.assertEquals(true, QTB_ReadyForIntegrationWithSuccessError.throwExplicitException);
        }
    }
    
        static testmethod void testMethod3() {
        Test.startTest();
             blng__LegalEntity__c indEntity = [select id from blng__LegalEntity__c where blng__Country__c = 'Thailand' Limit 1];
            
              List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
            accList[0].QTB_Hold_Invoice__c = false;
            accList[0].QTB_Contract_Entity__c = indEntity.id;
        update accList;
            
             blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accList[0].Id;
            invoice.blng__InvoiceStatus__c = 'Draft';
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Invoice_Type__c = 'New';
                invoice.QTB_Custom_Invoice_Number__c='IND12345670';
            insert invoice;
            
           List<blng__InvoiceLine__c> invLinesList = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__TaxCountry__c = 'India';
        invoiceLine.blng__Invoice__c = invoice.id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        insert invoiceLine;
        
        
        invLinesList.add(invoiceLine);
    
            
        blng__TaxRate__c taxRate = new blng__TaxRate__c();
        taxRate.blng__LegalEntity__c = indEntity.id;
        taxRate.blng__Priority__c = '1';
        taxRate.blng__Country__c = 'Thailand';
        taxRate.blng__State__c = 'LN';
        taxRate.blng__City__c = 'Lucknow';
        taxRate.blng__ZipCode__c = '226024';
        taxRate.blng__TaxCode__c = 'STD-CGST';
        taxRate.blng__Rate__c = 10;
        taxRate.blng__AddressComparison__c =taxRate.blng__Country__c +'-' +taxRate.blng__State__c +'-' +taxRate.blng__City__c +'-' +taxRate.blng__ZipCode__c +'-' +taxRate.blng__TaxCode__c +'-' +taxRate.blng__LegalEntity__c;
        try{
            insert taxRate;
        }
        catch(exception e){
            system.debug(e.getMessage());
        }
        QTB_Tax_Detail__c taxDet1 = new QTB_Tax_Detail__c(); 
        taxDet1.QTB_Individual_Tax_Amount__c = 10;
        taxDet1.QTB_Invoice_Line__c = invLinesList[0].id;
        taxDet1.QTB_CalculatedTax__c = 10;
        taxDet1.QTB_Tax_Code__c = taxRate.blng__TaxCode__c;
        taxDet1.QTB_EffectiveRate__c = taxRate.blng__Rate__c;
        //taxDet1.QTB_Invoice_Line_Subtotal__c = invList[0].blng__Subtotal__c;
       // taxDet1.CurrencyIsoCode = 'INR';
        taxDet1.QTB_TaxRateId__c = taxRate.Id;
        taxDet1.QTB_TaxType__c = taxRate.QTB_TaxDisplay__c;
        insert taxDet1;
        
        
        Set<Id>InvoiceIds = new Set<Id>();
        for(blng__InvoiceLine__c invln :invLinesList){
            InvoiceIds.add(invln.blng__Invoice__c);
        }
        
        QTB_ReadyForIntegrationWithSuccessError b=new QTB_ReadyForIntegrationWithSuccessError(InvoiceIds);
        Database.executeBatch(b);
        Test.stopTest();
    }
}
/*****************************************************************************************************
* Class			: QTB_PreBillBatchFlowController_Test 
* Author		: Accenture
* Purpose		: This is a test class for QTB_PreBillBatchFlowController
* Change History: 24/5/2021
* Developer     		Date           Description
* -------------------------------------------------------------------------------------------
* Accenture
* (Shailesh)Virtusa      12/27/2023     Gitlab US#20367 - Excluding Pre-bill Run for BillingOnlyCountries for Regular & Credit-Rebill Invoice generation process
* Sarwar(Virtusa)         04/28/2024    Gitlab US#23432 - Exclude Orders whose Opportunity's Primary Product Line is Warehouse and logistics from Pre Bill Run
*******************************************************************************************************/

@isTest(seealldata=false)
public class QTB_PreBillBatchFlowController_Test {
    
    @isTest
    static void testMethod1(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[0]){
        QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
        insert prebillrunrecord;
        
        QTB_PreBillBatchFlowController.FlowInputs prebillInputs = new QTB_PreBillBatchFlowController.FlowInputs();
        prebillInputs.invoiceBatches ='finland-26';
        prebillInputs.targetDate=date.today();
        prebillInputs.prebillBatchRunRecordId=prebillrunrecord.id;
        List<QTB_PreBillBatchFlowController.FlowInputs> flowInput = new List<QTB_PreBillBatchFlowController.FlowInputs>{prebillInputs};
            QTB_PreBillBatchFlowController.runPreBillBatches(flowInput);
        }
    }
    
     /***********************************************************************************************************
* Method      : testMethod2
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to provide test coverage for -- exclude prebill logic functionality for billingOnly countries.
**************************************************************************************************************/  
    @isTest
    static void testMethod2(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[0]){
            Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
			custSetting.SObject_API_Name__c = 'blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
      		custSetting.Disable_VR__c = true;
      		custSetting.Disable_PB__c = true;
      		custSetting.Disable_Trigger__c = true;
      		// custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      		insert custSetting;
        QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
        setting.Name = 'Singapore';
        setting.Active__c= true;
        setting.Legal_entity_country__c='Singapore';
        insert setting;
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        system.debug('Testdata--->'+accountList);
        accountList[0].QTB_Legal_Entity_Country__c='Singapore';
        update accountList;
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
		
		blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
		usaEntity.Name = 'Test Legal Entity United States';
		usaEntity.blng__Active__c = true;
		usaEntity.blng__Country__c = 'Norway';
		usaEntity.QTB_Type__c = 'Contract';
		// indiaEntity.QTB_Legal_Entity_Number__c = '45000';
		insert usaEntity;
		
		
		//Billing Finanace
        blng__FinanceBook__c singaporeFinanceBook = new blng__FinanceBook__c();
        singaporeFinanceBook.Name = 'Accounting Finance Book';
        singaporeFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        singaporeFinanceBook.blng__Active__c = true;
        singaporeFinanceBook.blng__PeriodType__c='Accounting';
        insert singaporeFinanceBook;
		
		blng__FinancePeriod__c singaporeFinancePeriod = new blng__FinancePeriod__c();
        singaporeFinancePeriod.Name = 'singapore Mar 2024';
        singaporeFinancePeriod.blng__FinanceBook__c = singaporeFinanceBook.id;
        singaporeFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
        singaporeFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
        singaporeFinancePeriod.blng__LegalEntity__c = usaEntity.id;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        //Invoice Scheduler
     /*   blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c();
        ins.Name = 'Rebill Run';
        ins.blng__Type__c = 'Once';
        ins.blng__StartDateTime__c = system.now()+1;
        ins.blng__TargetDate__c = system.today().addDays(2);
        ins.QTB_Parent_Invoice__c = invoiceList[0].Id;
		ins.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert ins; */
        
        blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c();
        ins.Name ='Test-' +'Norway-26th' +String.valueOf(Crypto.getRandomInteger());            
        ins.blng__InvoiceBatches__c = 'Norway-26th';
        ins.blng__StartDateTime__c = system.now() + 1;
        ins.blng__Type__c = 'Once';
        //  blngIn.blng__InvoiceDayOfMonth__c = '4';
        //  blngIn.blng__TargetDayOfMonth__c = '6';
        ins.blng__ApexJobId__c = '12345678';
        ins.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
        ins.QTB_Legal_Entity__c = usaEntity.id;
        ins.blng__StartDateTime__c = System.today().adddays(2);
        ins.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        ins.blng__TargetDate__c = Date.valueOf('2021-09-01');
        ins.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        ins.blng__InvoiceBatches__c = 'Rebill Run' ;
        insert ins;
        
        //BillFlowController
        QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
        prebillrunrecord.Invoice_Scheduler__c = ins.Id;
        insert prebillrunrecord;
        
        //preBill Inputs
        QTB_PreBillBatchFlowController.FlowInputs prebillInputs = new QTB_PreBillBatchFlowController.FlowInputs();
        prebillInputs.invoiceBatches = 'Rebill Run';
        prebillInputs.targetDate = date.today();
        prebillInputs.prebillBatchRunRecordId = prebillrunrecord.id;
        
        List<QTB_PreBillBatchFlowController.FlowInputs> flowInput = new List<QTB_PreBillBatchFlowController.FlowInputs>{prebillInputs};
            QTB_PreBillBatchFlowController.runPreBillBatches(flowInput);
        }
    }

         /***********************************************************************************************************
* Method      : testMethod3
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to provide test coverage for -- exclude prebill logic functionality for billingOnly countries.
**************************************************************************************************************/  
    @isTest
    static void testMethod3(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[0]){
            Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
			custSetting.SObject_API_Name__c = 'blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
      		custSetting.Disable_VR__c = true;
      		custSetting.Disable_PB__c = true;
      		custSetting.Disable_Trigger__c = true;
      		// custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      		insert custSetting;
      /*TB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
        setting.Name = 'Singapore';
        setting.Active__c= true;
        setting.Legal_entity_country__c='Singapore';
        insert setting; */
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c= 'United States';
        update accountList;
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
		
		blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
		usaEntity.Name = 'Test Legal Entity United States';
		usaEntity.blng__Active__c = true;
		usaEntity.blng__Country__c = 'United States';
		usaEntity.QTB_Type__c = 'Contract';
		// indiaEntity.QTB_Legal_Entity_Number__c = '45000';
		insert usaEntity;
		
		  //Invoice Scheduler
        blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c();
        ins.Name = 'Rebill Run';
        ins.blng__Type__c = 'Once';
        ins.blng__StartDateTime__c = system.now()+1;
        ins.blng__TargetDate__c = system.today().addDays(2);
        ins.QTB_Parent_Invoice__c = invoiceList[0].Id;
		ins.QTB_Legal_Entity__c = usaEntity.id ;
        ins.blng__InvoiceBatches__c = 'Rebill Run' ;
        insert ins;
        
        //BillFlowController
        QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
        prebillrunrecord.Invoice_Scheduler__c = ins.Id;
        insert prebillrunrecord;
        
        //preBill Inputs
        QTB_PreBillBatchFlowController.FlowInputs prebillInputs = new QTB_PreBillBatchFlowController.FlowInputs();
        prebillInputs.invoiceBatches = 'Rebill Run';
        prebillInputs.targetDate = date.today();
        prebillInputs.prebillBatchRunRecordId = prebillrunrecord.id;
        
        List<QTB_PreBillBatchFlowController.FlowInputs> flowInput = new List<QTB_PreBillBatchFlowController.FlowInputs>{prebillInputs};
            QTB_PreBillBatchFlowController.runPreBillBatches(flowInput);
        }
    }    
    
         /***********************************************************************************************************
* Method      : testMethod4
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to provide test coverage for -- exclude prebill logic functionality for billingOnly countries.
**************************************************************************************************************/  
    @isTest
    static void testMethod4(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[0]){
            Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
			custSetting.SObject_API_Name__c = 'blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
      		custSetting.Disable_VR__c = true;
      		custSetting.Disable_PB__c = true;
      		custSetting.Disable_Trigger__c = true;
      		// custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      		insert custSetting;
      /*TB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
        setting.Name = 'Singapore';
        setting.Active__c= true;
        setting.Legal_entity_country__c='Singapore';
        insert setting; */
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c= 'United States';
        update accountList;
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
		
		blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
		usaEntity.Name = 'Test Legal Entity United States';
		usaEntity.blng__Active__c = true;
		usaEntity.blng__Country__c = 'United States';
		usaEntity.QTB_Type__c = 'Contract';
		// indiaEntity.QTB_Legal_Entity_Number__c = '45000';
		insert usaEntity;
		
		  //Invoice Scheduler
      /*  blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c();
        ins.Name = 'United States-DM-1st-EOM';
        ins.blng__Type__c = 'Once';
        ins.blng__StartDateTime__c = system.now()+1;
        ins.blng__TargetDate__c = system.today().addDays(2);
        ins.QTB_Parent_Invoice__c = invoiceList[0].Id;
		ins.QTB_Legal_Entity__c = usaEntity.id ;
        ins.blng__InvoiceBatches__c = 'United States-DM-1st-EOM' ;
        insert ins;
        */
		
        //BillFlowController
        QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
     //   prebillrunrecord.Invoice_Scheduler__c = ins.Id;
        insert prebillrunrecord;
        
        //preBill Inputs
        QTB_PreBillBatchFlowController.FlowInputs prebillInputs = new QTB_PreBillBatchFlowController.FlowInputs();
        prebillInputs.invoiceBatches = 'United States-DM-1st-EOM';
        prebillInputs.targetDate = date.today();
        prebillInputs.prebillBatchRunRecordId = prebillrunrecord.id;
        
        List<QTB_PreBillBatchFlowController.FlowInputs> flowInput = new List<QTB_PreBillBatchFlowController.FlowInputs>{null};
            QTB_PreBillBatchFlowController.runPreBillBatches(null);
        }
    }
    
/***********************************************************************************************************
* Method      : testMethod5
* Parameter   : N/A
* Return Type : void
* Author      : Virtusa(Sarwar US#23432)
* Description : This method is used to provide test coverage for -- exclude prebill logic functionality for Warehouse&logistic countries.
* Changes     : This test method was added as part of US#23432
**************************************************************************************************************/  
    @isTest
    static void testMethod5(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[0]){
            Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
			custSetting.SObject_API_Name__c = 'opportunity;blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
      		custSetting.Disable_VR__c = true;
      		custSetting.Disable_PB__c = true;
      		custSetting.Disable_Trigger__c = true;
      		// custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      		insert custSetting;
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c= 'Singapore';
        accountList[0].W_L__c = true;
        update accountList;
        //custom settings
        QTB_Billing_Countries__c bc = new QTB_Billing_Countries__c();
        bc.Name =  'Singapore';
        bc.Active__c = true;
        bc.Legal_entity_country__c = 'Singapore';
        insert bc;
        Id pricebookId = Test.getStandardPricebookId();
        
        //IM Country
        IM_Country__c im = new IM_Country__c();
        im.Name = 'Singapore';
        im.CurrencyIsoCode = 'SGD';
        im.Region__c = 'Central Region';
        im.AlternativeNames__c = 'Singapore';
        im.Iso31662Code__c ='SGD';
        im.Iso31663Code__c ='SGD';        
        //im.Active__c = true;//billing country criteria not match issue getting
        insert im;
        
        
         //Legal Entity
        blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
        indiaEntity.Name = 'Test Legal Entity Singapore';
        indiaEntity.blng__Active__c = true;
        indiaEntity.blng__Country__c = 'Singapore';
        indiaEntity.QTB_Type__c = 'Contract';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert indiaEntity;
        
          //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
       // oppList[0].Legal_Entity__c = indiaEntity.id;
        oppList[0].Billing_Country__c = im.id;
        //database.update(oppList);
        
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = indiaEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'Singapore';
        database.update(quoteList);
        
        
         //Order
        List<Order> orderList = new List<Order>();
        
        Order ord = new Order(
            SBQQ__Quote__c =  quoteList[0].Id,
            AccountId = accountList[0].id,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = QTB_Constants.DRAFT_STATUS,
            Pricebook2Id = pricebookId,
            blng__InvoiceBatch__c = 'Rebill Run'
            //RecordTypeId = QTB_Utils.ORDER_BILL_RECTYPEID
        );        
        orderList.add(ord);
        System.debug('orderList@@'+orderList);
        sbqq.TriggerControl.disable();
            insert orderList;
            system.debug('orderList--->'+orderList[0]);
        sbqq.TriggerControl.enable();
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
		
		blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
		usaEntity.Name = 'Test Legal Entity Singapore';
		usaEntity.blng__Active__c = true;
		usaEntity.blng__Country__c = 'Singapore';
		usaEntity.QTB_Type__c = 'Contract';
		// indiaEntity.QTB_Legal_Entity_Number__c = '45000';
		insert usaEntity;
		
		  //Invoice Scheduler
     /*   blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c();
        ins.Name = 'US-SBS-1st-EOM';
        ins.blng__Type__c = 'Once';
        ins.blng__StartDateTime__c = system.now()+1;
        ins.blng__TargetDate__c = system.today().addDays(2);
        ins.QTB_Parent_Invoice__c = invoiceList[0].Id;
		ins.QTB_Legal_Entity__c = usaEntity.id ;
        ins.blng__InvoiceBatches__c = 'US-SBS-1st-EOM' ;
        insert ins;
        */
        //BillFlowController
        system.debug('orderId--->'+orderList[0].Id);
        QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
       // prebillrunrecord.Invoice_Scheduler__c = ins.Id;
        prebillrunrecord.Name = 'Test';
        prebillrunrecord.QTB_Rebill_Order__c = orderList[0].Id;
        prebillrunrecord.QTB_PreBill_Run_status__c = 'Completed';
        
        insert prebillrunrecord;
        
        //preBill Inputs
        QTB_PreBillBatchFlowController.FlowInputs prebillInputs = new QTB_PreBillBatchFlowController.FlowInputs();
        prebillInputs.invoiceBatches = 'Rebill Run';
        prebillInputs.targetDate = date.today();
        prebillInputs.prebillBatchRunRecordId = prebillrunrecord.id;
        
        List<QTB_PreBillBatchFlowController.FlowInputs> flowInput = new List<QTB_PreBillBatchFlowController.FlowInputs>{prebillInputs};
            QTB_PreBillBatchFlowController.runPreBillBatches(flowInput);           
        }
    }
    
}
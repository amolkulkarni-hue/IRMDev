/*****************************************************************************************************
* Class			: QTB_SbaaApprovalTriggerHandler_Test
* Author		: Virtusa
* Purpose		: This is a handler class for business logic to prevent creation of Approval record and throw validation error if credit note tax is not estimated
* Requirement	: GITLAB #20221
* Change History: 11/12/2023
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
Ramesh/Shailesh 11/12/2023   GILAB #20221 - On Account Credit: Tax Calculation Validation when performing On Account Credit
*******************************************************************************************************/
@isTest(seealldata=false) 
public class QTB_SbaaApprovalTriggerHandler_Test {
    @testSetup
    static void setup() {
         Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
      custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;blng__Invoice__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c;AccountContactRelation;Contact';
      custSetting.Disable_VR__c = true;
      custSetting.Disable_PB__c = true;
      custSetting.Disable_Trigger__c = true;
      // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      insert custSetting;
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //System.runAs(userList[0]) {
            List<Account> testAccounts = QTB_TestDataFactory.createAccounts(1,'Billing Account');
            blng__LegalEntity__c USEntity= QTB_TestDataFactory.createLegalEntity('United States');
            testaccounts[0].QTB_Legal_Entity_Country__c='India';
            testaccounts[0].QTB_Records_Management__c = true;
            update testAccounts;
            List<product2> product = QTB_TestDataFactory.createProducts(1);  
            Group groupinfo = [
                SELECT id
                FROM Group
                WHERE Name = 'QTB VP India'
                LIMIT 1
            ];
            
            Contact con = new Contact();
            con.LastName = 'Custom Lasttest Name:201 ';
            con.FirstName = 'Custom Firsttest Name1 ';
            con.email = 'test@email.com';
            con.AccountId = testAccounts[0].Id;
            con.MailingCountry = 'Canada';
            con.IM_Role__c = 'PO Contact';
            insert con;
            
          /*   AccountContactRelation acr = new AccountContactRelation();
            acr.accountId = testAccounts[0].id;
            acr.ContactId = con.Id;
          //  insert acr;
            
            acr.Roles = 'PO Contact';
           // update acr;
           */
            
            sbaa__Approver__c testApp1 = QTB_TestDataFactory.createApprover();
            testApp1.sbaa__User__c = UserInfo.getUserId();
            sbaa__Approver__c testApp2 = QTB_TestDataFactory.createApprover();
            testApp2.sbaa__GroupId__c = groupinfo.id;
            testApp2.QTB_Approver_Country__c = 'United States';
            testApp2.QTB_Approver_Level__c = 'VP';
            update new List<sbaa__Approver__c>{ testApp1, testApp2 };
                
            //Parent Invoice  
            List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);            
            parentInvoiceList[0].QTB_ReBill_Status__c = 'Usage Completed';
            parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';    
            update parentInvoiceList;
            
            
            //Rebill Invoice
            List<blng__Invoice__c> rebillInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);
            rebillInvoiceList[0].QTB_Parent_Invoice__c = parentInvoiceList[0].id;
            rebillInvoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
            rebillInvoiceList[0].blng__InvoiceStatus__c = 'Draft';        
            update rebillInvoiceList;
            
            //Rebill Invoice Lines
            List<blng__InvoiceLine__c> invoiceLineList = QTB_TestDataFactory.createInvoiceLine(3,rebillInvoiceList,product);
            
            
        /*    blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
            singaporeEntity.Name = 'Test Legal Entity India';
            singaporeEntity.blng__Active__c = true;
            //singaporeEntity.blng__Country__c = 'United States';
            singaporeEntity.blng__Country__c = 'India';
            singaporeEntity.QTB_Type__c = 'Contract';
            singaporeEntity.QTB_Legal_Entity_Number__c = 45000;
            insert singaporeEntity;  */
            
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
            singaporeFinancePeriod.blng__LegalEntity__c = USEntity.id;
            singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
            insert singaporeFinancePeriod;
            
            
            //Invoice Schedular
            blng__InvoiceScheduler__c invSch = new blng__InvoiceScheduler__c();
            invSch.Name = 'Test1234567';
            invSch.blng__Type__c = 'Once';
            invSch.blng__InvoiceBatches__c = 'Rebill Run';
            invSch.CurrencyIsoCode = 'USD';
            invSch.blng__StartDateTime__c = System.now()+100;
            invSch.blng__InvoiceDate__c = system.today();
            invSch.blng__TargetDate__c = system.today();
            invSch.QTB_Parent_Invoice__c = parentInvoiceList[0].id;
            invSch.QTB_Legal_Entity__c = USEntity.id;
            invSch.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
            insert invSch;
            
            //Invoice Run
            blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
            invoiceRun.blng__InvoiceScheduler__c = invSch.id;
            invoiceRun.Name = 'test invoice';
            invoiceRun.blng__Status__c = 'Completed';
            invoiceRun.blng__TargetDate__c = System.today();
            insert invoiceRun;
            
            //Bill Flow Controller
            QTB_Bill_Flow_Controller__c bfc = new QTB_Bill_Flow_Controller__c();
            bfc.Name = 'Test';
            bfc.Execute_Pre_Bill_Run__c = true;
            bfc.Execute_Post_Bill_Run__c = false;
            bfc.QTB_PreBill_Run_Status__c = 'Completed';
            bfc.Invoice_Scheduler__c = invSch.id;
            insert bfc;
            
            //rebillInvoiceList[0].blng__InvoiceDate__c = System.today();
            rebillInvoiceList[0].blng__InvoiceStatus__c = 'Posted';       
            rebillInvoiceList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
            //update rebillInvoiceList[0];            
            Test.startTest();
            // Create CreditNote
            /*List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c>();
            blng__CreditNote__c creditNote = new blng__CreditNote__c();
            creditNote.blng__Account__c = testAccounts[0].Id;
            creditNote.blng__CreditNoteDate__c = date.today();
            creditNote.QTB_Reason_Code__c = 'Legacy Credit';
            creditNote.blng__Status__c = 'Draft';
            creditNote.CurrencyIsoCode = 'SGD';
            creditNote.QTB_Manager_Approver__c = testApp1.Id;
            creditNote.QTB_VP_Approver__c = testApp2.Id;
            creditNote.blng__Status__c = 'Draft';  
            creditNote.blng__RelatedInvoice__c =  parentInvoiceList[0].Id;
            creditNote.QTB_On_Account_Credit__c = true;
            creditNotes.add(creditNote);
            insert creditNotes;
            
            creditNotes[0].ApprovalStatus__c='Draft';
            update creditNotes[0]; */
			
			
			
			   // Create Credit Note
        List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c>();
        
        QTB_PurchaseOrder__c PO=new QTB_PurchaseOrder__c();
        PO.QTB_PO_Type__c ='Standard';
        PO.QTB_Customer_PO__c ='123';
        PO.QTB_Billing_Account__c =testAccounts[0].Id;
        po.QTB_Status__c = 'Inactive';
        PO.QTB_Amount__c =50000;
        PO.QTB_PO_Balance_Amount__c =4000;
        po.QTB_Service_Type__c = 'Mixed';        
        insert PO;
        
        //Regular CreditNote
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = testAccounts[0].Id;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Account Creation';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'EUR';
        creditNote1.blng__RelatedInvoice__c = parentInvoiceList[0].Id;
        creditNote1.QTB_Rebill_Invoice__c = rebillInvoiceList[0].Id;
        creditNote1.QTB_Purchase_Order__c =PO.id;
        creditNote1.QTB_On_Account_Credit__c = false;
        
        creditNote1.QTB_Credit_Note_Type__c = 'Credit Only';
        creditNote1.QTB_CreditNote_Posted_Date__c = null;
        creditNote1.QTB_Purchase_Order__c = null;
        creditNote1.QTB_Internal_PO_Notes__c = 'tetda';
        creditNotes.add(creditNote1);
        System.debug('setup_creditNotesList@@'+creditNotes);
        
        custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__CreditNote__c;AccountContactRelation;Contact';
        update custSetting;
        insert creditNotes;
			
			
			
            
            //Create CreditNote Lines
            List<blng__CreditNoteLine__c> crdLineList = new List<blng__CreditNoteLine__c>();
            blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
            cnl.QTB_Account__c = testAccounts[0].Id;
            cnl.blng__CreditNote__c = creditNotes[0].id;
            //cnl.QTB_Invoice__c = parentInvoiceList[0].id;
            //cnl.QTB_InvoiceLine__c = invoiceLineList[0].id;
            cnl.blng__Product__c = product[0].Id;
            cnl.blng__Subtotal__c = 0;            
            cnl.blng__CalculateTax__c=true;
            cnl.blng__TotalAmount__c = 10;
            cnl.blng__TaxStatus__c = '';
            crdLineList.add(cnl);
            insert crdLineList;
            
            // Create Approval Rule
            sbaa__ApprovalRule__c testRule = QTB_TestDataFactory.createApprovalRule();
            
            //Create Approvals
            List<sbaa__Approval__c> appList = new List<sbaa__Approval__c>();
            sbaa__Approval__c testApproval = new sbaa__Approval__c();
            testApproval.sbaa__Status__c = 'Approved';
            testApproval.sbaa__RecordField__c = 'Test1';
            testApproval.sbaa__ApprovalStep__c = 1;
            testApproval.QTB_Credit_Note__c = creditNotes[0].Id;
            testApproval.sbaa__Rule__c = testRule.Id;
            appList.add(testApproval);
            sbaa__Approval__c testApproval2 = new sbaa__Approval__c();
            testApproval2.sbaa__Status__c = 'Rejected';
            testApproval2.sbaa__RecordField__c = 'Test2';
            testApproval2.sbaa__ApprovalStep__c = 1;
            testApproval2.QTB_Credit_Note__c = creditNotes[0].Id;
            testApproval2.sbaa__Rule__c = testRule.Id;
            appList.add(testApproval2);
            sbaa__Approval__c testApproval3 = new sbaa__Approval__c();
            testApproval3.sbaa__Status__c = 'Requested';
            testApproval3.sbaa__RecordField__c = 'Test3';
            testApproval3.sbaa__ApprovalStep__c = 1;
            testApproval3.QTB_Credit_Note__c = creditNotes[0].Id;
            testApproval3.sbaa__Rule__c = testRule.Id;
            appList.add(testApproval3);
            sbaa__Approval__c testApproval4 = new sbaa__Approval__c();
            testApproval4.sbaa__Status__c = 'Recalled';
            testApproval4.sbaa__RecordField__c = 'Test4';
            testApproval4.sbaa__ApprovalStep__c = 1;
            testApproval4.QTB_Credit_Note__c = creditNotes[0].Id;
            testApproval4.sbaa__Rule__c = testRule.Id;
            appList.add(testApproval4);
            sbaa__Approval__c testApproval5 = new sbaa__Approval__c();
            testApproval5.sbaa__Status__c = 'Revoked';
            testApproval5.sbaa__RecordField__c = 'Test5';
            testApproval5.sbaa__ApprovalStep__c = 1;
            testApproval5.QTB_Credit_Note__c = creditNotes[0].Id;
            testApproval5.sbaa__Rule__c = testRule.Id;
            appList.add(testApproval5);
            try{
               database.insert(appList); 
            }
            Catch(Exception e){
                System.debug('Exception@@'+e.getMessage());
            }
            // system.assert(appList.size()==5);
            
            //Update Credit Note
            creditNotes[0].ApprovalStatus__c = 'Pending';
            database.update(creditNotes);
            Test.stopTest();
        //}
    }
   
    @isTest
    static void testMethod1(){
        List<sbaa__Approval__c> ApprvlList = [Select Id, QTB_Credit_Note__c from sbaa__Approval__c];
        QTB_SbaaApprovalTriggerHandler.handleBeforeInsert(ApprvlList);
    }
}
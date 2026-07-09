@isTest(seealldata=false) 
public class QTB_ApprovalEmailHandlerTest {
    @testSetup
    static void setup() {
        Test.startTest();
       
            List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
                1,
                'Standard Account'
                
            );
        
         blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
        USEntity.Name = 'Test Legal Entity US';
        USEntity.blng__Active__c = true;
        USEntity.blng__Country__c = 'United States';
        USEntity.QTB_Type__c = 'Contract';
        USEntity.QTB_Legal_Entity_Number__c = 45409;
        insert USEntity; 
        
        //Billing Finanace
        blng__FinanceBook__c USFinanceBook = new blng__FinanceBook__c();
        USFinanceBook.Name = 'Accounting Finance Book';
        USFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        USFinanceBook.blng__Active__c = true;
        USFinanceBook.blng__PeriodType__c='Accounting';
        insert USFinanceBook;
        
        
        blng__FinancePeriod__c USFinancePeriod = new blng__FinancePeriod__c();
        USFinancePeriod.Name = 'US Mar 2024';
        USFinancePeriod.blng__FinanceBook__c = USFinanceBook.id;
        USFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
        USFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
        USFinancePeriod.blng__LegalEntity__c = USEntity.id;
        USFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert USFinancePeriod;
        
            blng__LegalEntity__c USEntity1= QTB_TestDataFactory.createLegalEntity('United States');
            testaccounts[0].QTB_Legal_Entity_Country__c='United States';
            update testAccounts;
            List<product2> product = QTB_TestDataFactory.createProducts(1);  
            Group groupinfo = [
                SELECT id
                FROM Group
                WHERE Name = 'QTB VP India'
                LIMIT 1
            ];
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
            
        blng__InvoiceScheduler__c USSchedule = new blng__InvoiceScheduler__c();
        USSchedule.Name = 'test for US';
        USSchedule.blng__Type__c = 'Once';
        //USSchedule.blng__InvoiceBatches__c = 'Rebill Run';
        USSchedule.CurrencyIsoCode = 'USD';
        USSchedule.blng__StartDateTime__c = System.today().adddays(2);
        USSchedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        USSchedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        USSchedule.QTB_Legal_Entity__c  = USEntity.id;
        USSchedule.QTB_Invoice_Period__c = USFinancePeriod.id ;
        insert USSchedule;
        
            
            //Invoice Run
            blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
            invoiceRun.blng__InvoiceScheduler__c = USSchedule.id;
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
            bfc.Invoice_Scheduler__c = USSchedule.id;
            insert bfc;
            
            //rebillInvoiceList[0].blng__InvoiceDate__c = System.today();
            rebillInvoiceList[0].blng__InvoiceStatus__c = 'Posted';       
            rebillInvoiceList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
            update rebillInvoiceList[0];            
            
            // Create CreditNote
            List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c>();
            blng__CreditNote__c creditNote = new blng__CreditNote__c();
            creditNote.blng__Account__c = testAccounts[0].Id;
            creditNote.blng__CreditNoteDate__c = date.today();
            creditNote.QTB_Reason_Code__c = 'Account Creation';
            creditNote.blng__Status__c = 'Draft';
            creditNote.CurrencyIsoCode = 'USD';
            creditNote.QTB_Manager_Approver__c = testApp1.Id;
            creditNote.QTB_VP_Approver__c = testApp2.Id;
            creditNote.blng__Status__c = 'Draft';  
            creditNote.blng__RelatedInvoice__c =  parentInvoiceList[0].Id;
            creditNotes.add(creditNote);
            insert creditNotes;
            
            creditNotes[0].ApprovalStatus__c='Draft';
            update creditNotes[0];
            
            //Create CreditNote Lines
            List<blng__CreditNoteLine__c> ListCredirLines = QTB_TestDataFactory.createCreditNoteLine(1,testAccounts[0],creditNotes[0],parentInvoiceList[0],invoiceLineList[0],product[0]);
            
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
            database.insert(appList);
            // system.assert(appList.size()==5);
            
            //Update Credit Note
            creditNotes[0].ApprovalStatus__c = 'Pending';
            database.update(creditNotes);
            
            //  system.assert(creditNotes[0].ApprovalStatus__c=='Pending');
            creditNotes[0].ApprovalStatus__c = 'Approved';
            creditNotes[0].blng__Status__c = 'Draft';
            try{
                database.update(creditNotes);
            }
            catch(Exception e)
            {
                System.assert('Script-thrown exception@@' != e.getMessage());
            }
            
            QTB_CreditNoteTriggerHandler.throwExplicitException = false;
            
            Test.stopTest();
            system.assert(creditNotes[0].ApprovalStatus__c == 'Approved');
            
        }

    
    private static testMethod void method2() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[1]) {
            QTB_CreditNoteTriggerHandler.throwExplicitException = true;
            QTB_CreditNoteTriggerHandler handler = new QTB_CreditNoteTriggerHandler();
            handler.BeforeDelete(null);
            handler.AfterDelete(null);
            handler.AfterUndelete(null);
            handler.isDisabled();
            handler.bypass();
            Test.stopTest();
            try {
                QTB_CreditNoteHelper.notifyAdditionalRecipientsOnApprovalSubmission(
                    null,
                    null
                );
            } catch (Exception e) {
                
                System.assertEquals('Script-thrown exception', e.getMessage());
            }
            try {
                QTB_CreditNoteHelper.setApprovers(null);
            } catch (Exception e) {
                System.assertEquals('Script-thrown exception', e.getMessage());
            }
            try {
                QTB_CreditNoteHelper.getApproverIds(null);
            } catch (Exception e) {
                System.assertEquals('Script-thrown exception', e.getMessage());
            }
            try {
                QTB_TestDataFactory.createBypassSetting(
                    QTB_Constants.SOBJECT_BLNG_CREDITNOTE
                );
            } catch (Exception e) {
                System.assertEquals('Script-thrown exception', e.getMessage());
            }
            System.assertEquals(
                true,
                QTB_CreditNoteTriggerHandler.throwExplicitException
            );
            try {
                QTB_CreditNoteHelper.creditReBill(null,null,null,null);
            } catch (Exception e) {
                System.assertEquals('Script-thrown exception', e.getMessage());
            }
            
        }
    }
    
    @isTest
    static void testMethod3(){
        List<blng__CreditNoteLine__c> finalCreditNoteLineList = new List<blng__CreditNoteLine__c>();
        List<blng__CreditNote__c> finalCreditNoteList = new List<blng__CreditNote__c>();
        Map<Id, blng__CreditNote__c> mapOfNewCreditNotes = new Map<Id, blng__CreditNote__c>();
        Map<Id, blng__CreditNote__c> mapOfOldCreditNotes = new Map<Id, blng__CreditNote__c>();
        List<blng__CreditNoteLine__c> ListCredirLines = [Select Id, blng__Subtotal__c from blng__CreditNoteLine__c ];
        for(blng__CreditNoteLine__c cnl : ListCredirLines){
            cnl.blng__Subtotal__c = 10;
            finalCreditNoteLineList.add(cnl);
        }
        update finalCreditNoteLineList;
        
        List<blng__CreditNote__c> creditNotes = [Select ID, Name, QTB_Country__c,QTB_IsReBill__c from blng__CreditNote__c ];
        for(blng__CreditNote__c cn :creditNotes ){
            cn.blng__Notes__c = 'test';            
            finalCreditNoteList.add(cn);
            mapOfOldCreditNotes.put(cn.id,cn);
        }
        //update finalCreditNoteList;
        
        for(blng__CreditNote__c cn :finalCreditNoteList){
            mapOfNewCreditNotes.put(cn.id,cn);
        }
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        
        Set<String> setOfUserIdOrCountires = new  Set<String>();
        setOfUserIdOrCountires.add('United States');
        setOfUserIdOrCountires.add('India');
        setOfUserIdOrCountires.add('Canada');
        setOfUserIdOrCountires.add(userList[0].id);
        Map<String, Id> abc = QTB_CreditNoteHelper.getApproverIds(setOfUserIdOrCountires);
    }
    
    @isTest
    static void testMethod4() {
        Test.startTest();
        List<blng__CreditNote__c> creditNotes = [Select ID, Name, QTB_Country__c,blng__RelatedInvoice__c,QTB_ReBill_Credit_Amount__c,
        QTB_IsReBill__c from blng__CreditNote__c where QTB_Country__c = '' limit 1];
        QTB_CreditNoteHelper.setApprovers(creditNotes);
        Test.stopTest();
    }
    
    private static testMethod void method5() {
        Test.startTest();
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        
         //Legal Entity
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity Singapore';
        singaporeEntity.blng__Active__c = true;
        singaporeEntity.blng__Country__c = 'Singapore';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45409;
        insert singaporeEntity; 
        
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
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.id;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        
        blng__LegalEntity__c USEntity= QTB_TestDataFactory.createLegalEntity('Singapore');
        testaccounts[0].QTB_Legal_Entity_Country__c='Singapore';
        testaccounts[0].SBQQ__TaxExempt__c = 'No';
        update testAccounts;
        List<product2> product = QTB_TestDataFactory.createProducts(1);  
        Group groupinfo = [
            SELECT id
            FROM Group
            WHERE Name = 'QTB VP India'
            LIMIT 1
        ];
        sbaa__Approver__c testApp1 = QTB_TestDataFactory.createApprover();
        testApp1.sbaa__User__c = UserInfo.getUserId();
        sbaa__Approver__c testApp2 = QTB_TestDataFactory.createApprover();
        testApp2.sbaa__GroupId__c = groupinfo.id;
        testApp2.QTB_Approver_Country__c = 'Singapore';
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
     
        blng__InvoiceScheduler__c singaporeSchedule = new blng__InvoiceScheduler__c();
        singaporeSchedule.Name = 'test for Singapore';
        singaporeSchedule.blng__Type__c = 'Once';
        singaporeSchedule.blng__InvoiceBatches__c = 'Rebill Run';
        singaporeSchedule.CurrencyIsoCode = 'SGD';
        singaporeSchedule.blng__StartDateTime__c = System.today().adddays(2);
        singaporeSchedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        singaporeSchedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        singaporeSchedule.QTB_Legal_Entity__c  = singaporeEntity.id;
        singaporeSchedule.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert singaporeSchedule;
        
        
        //Invoice Run
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.blng__InvoiceScheduler__c = singaporeSchedule.id;
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
        bfc.Invoice_Scheduler__c = singaporeSchedule.id;
        insert bfc;
        
        //rebillInvoiceList[0].blng__InvoiceDate__c = System.today();
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Posted';       
        rebillInvoiceList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        update rebillInvoiceList[0];            
        
        // Create CreditNote
        List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c>();
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = testAccounts[0].Id;
        creditNote.blng__CreditNoteDate__c = date.today();
        creditNote.QTB_Reason_Code__c = 'Account Creation';
        creditNote.blng__Status__c = 'Draft';
        creditNote.CurrencyIsoCode = 'SGD';
        creditNote.QTB_Manager_Approver__c = testApp1.Id;
        creditNote.QTB_VP_Approver__c = testApp2.Id;
        creditNote.blng__Status__c = 'Draft';  
        creditNote.blng__RelatedInvoice__c =  parentInvoiceList[0].Id;
        creditNote.QTB_ReBill_Credit_Amount__c = 200;
        creditNotes.add(creditNote);
        insert creditNotes;
        
        creditNotes[0].ApprovalStatus__c='Draft';
        update creditNotes[0];
        
        Set<Id> InvListIds = new Set<ID>();
        InvListIds.add(parentInvoiceList[0].Id);
        
        Set<Id> CreditnoteIds = new Set<Id>();
        CreditnoteIds.add(creditNotes[0].id); 
        
        QTB_CreditNoteHelper.creditReBill(InvListIds,CreditnoteIds,'Insert',null);  
        QTB_CreditNoteHelper.creditReBill(InvListIds,CreditnoteIds,'Update',true);
        QTB_ApprovalEmailHandler.testFunctionality();
        QTB_ApprovalEmailHandler.sendEmail(new List<Messaging.SingleEmailMessage>());
        Test.stopTest(); 
    }
}
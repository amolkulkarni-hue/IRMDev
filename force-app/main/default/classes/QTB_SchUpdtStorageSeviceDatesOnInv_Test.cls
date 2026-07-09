/*****************************************************************************************************
* Class: QTB_SchUpdtStorageSeviceDatesOnInv_Test
* Author: Virtusa
* Purpose: This is a Test class for QTB_ScheduleUpdtStorageSeviceDatesOnInv
* Requirement:
* Change History: 22/07/2025
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Parth			22/07/2025             
*******************************************************************************************************/
@isTest(seealldata=false) 
private class QTB_SchUpdtStorageSeviceDatesOnInv_Test {
	@testSetup static void setup(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
			custSetting.SObject_API_Name__c = 'Account;blng__Invoice__c;blng__InvoiceLine__c';
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
        }
    }
    static testmethod void testmethod1(){
        test.startTest();
        list<blng__Invoice__c>invList = [Select Id from blng__Invoice__c];
        set<Id>invoiceRunIDSet = new Set<Id>{invList[0].Id};
            //Legal Entity
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity Singapore';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert usaEntity;
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test schedule 2';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today().addDays(1);
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Parent_Invoice__c = invList[0].ID;
        schedule.QTB_Legal_Entity__c = usaEntity.ID;
        insert schedule;
        set<Id>invSchId = new Set<Id>();
        invSchId.add(schedule.Id);
        QTB_ScheduleUpdtStorageSeviceDatesOnInv.scheduleUpdateOfInvDates(invoiceRunIDSet,invSchId);
        //System.schedule('QTB_ScheduleAccountDMSourceUpdate',System.now().addSeconds(15).format('s m H d M ? yyyy'),new QTB_ScheduleAccountDMSourceUpdate(accList));
        test.stopTest();
    }
}
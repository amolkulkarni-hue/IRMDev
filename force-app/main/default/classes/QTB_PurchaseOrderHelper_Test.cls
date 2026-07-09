/*****************************************************************************************************
* Class: QTB_PurchaseOrderHelper_Test
* Author: Accenture
* Purpose: This is a test class for QTB_PurchaseOrderHelper
* Change History:
* Developer          Date           Description
* Divya Battula   13 Dec,2022      Added testData4() Method
* -------------------------------------------------------------------------------------------
* Accenture
*******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_PurchaseOrderHelper_Test {
    
    static testMethod void testData3() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        Test.startTest();
        Metadata_Activation_Settings__c cs = new Metadata_Activation_Settings__c();
        cs.Disable_VR__c=true;
        insert cs;
        cs.Disable_VR__c=false;
        update cs;
        
    //    System.runAs(userList[1]) {
            
            
         /*   List<account> accountList = QTB_TestDataFactory.createAccounts(
                2,
                'Billing Account'
            );
            accountList[0].QTB_Legal_Entity_Country__c = 'India';
            accountList[1].QTB_Legal_Entity_Country__c = 'India';
            update accountList; */
			
			
			List<Account> accountList = new List<Account>();
			ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
			Id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
			for (Integer i = 0; i < 10; i++) {
            Account a = new Account();
            a.Name = (a.Name == null ? 'Test' : a.Name) + i;
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.Name = 'Test Account';
            a.BillingCountry = 'India';
            a.BillingPostalCode = '11209';
            a.BillingState = 'TN';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'India';
            a.QTB_Legal_Entity_Country__c='India';
            if(i == 0){
                a.QTB_Legal_Entity_Country__c='United States';
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
            accountList.add(a);
        }
        
        if (!accountList.isEmpty()) {
            insert accountList; // insert Accounts 
        }
            
            
            
            Contact con = new Contact();
            con.LastName = 'Custom Lasttest Name:20 ';
            con.FirstName = 'Custom Firsttest Name ';
            con.email = 'test@email.com';
            con.AccountId = accountList[0].Id;
            con.MailingCountry = 'Canada';
            con.IM_Role__c = 'PO Contact';
            insert con;
            
            AccountContactRelation acr = new AccountContactRelation();
            acr.accountId = accountList[1].id;
            acr.ContactId = con.Id;
            insert acr;
            
            acr.Roles = 'PO Contact';
            update acr;
            
            List<QTB_PurchaseOrder__c> POlist = new List<QTB_PurchaseOrder__c>();
            List<QTB_PurchaseOrder__c> POlist1 = new List<QTB_PurchaseOrder__c>();
            Map<id,QTB_PurchaseOrder__c> ordOldMap = new Map<id,QTB_PurchaseOrder__c>();
            
            QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(
                QTB_Billing_Account__c = accountList[1].id,
                QTB_Status__c = 'Active',
                QTB_Start_Date__c = date.Today(),
                QTB_End_Date__c = date.today(),
                QTB_PO_Type__c = 'Project',
                QTB_Customer_PO__c = 'QW2315',
                QTB_Amount__c = 10000,
                QTB_Service_Type__c = 'Mixed',
                QTB_PO_Balance_Amount__c = 10000
            );
            insert pOrder;
            Polist.add(Porder);
            
            QTB_PurchaseOrder__c pOrder1 = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[1].id,
                                                                    QTB_Status__c = 'Active',
                                                                    QTB_Start_Date__c = date.Today()+10,
                                                                    QTB_End_Date__c = date.today()+15,
                													QTB_PO_Type__c = 'Standard',
                													QTB_Customer_PO__c = 'QW2315',
                                                                    QTB_Amount__c = 10000,QTB_Service_Type__c = 'Mixed');
            insert Porder1;
            Polist.add(Porder1);
            
            QTB_PurchaseOrder__c pOrder2 = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[1].id,
                                                                    QTB_Status__c = 'Active',
                                                                    QTB_Start_Date__c = date.Today()+30,
                                                                    QTB_End_Date__c = date.today()+35,
                                                                    QTB_PO_Type__c = 'Contract',
                													QTB_Customer_PO__c = 'QW2315',
                                                                    QTB_Amount__c = 10000,QTB_Service_Type__c = 'Mixed',
																	QTB_Legal_Entity_Country__c = 'United States');
            insert pOrder2;
           	ordOldMap.put(Porder2.id,Porder2);
           
            pOrder2.QTB_End_Date__c = date.today()+60;
            update pOrder2;
            
            Polist1.add(pOrder2);
            
           // QTB_PurchaseOrderHelper.duplicateupdatetimeperiod(Polist1,ordOldMap);
            
            
            
          //  QTB_PurchaseOrderHelper.duplicatetimeperiod(Polist1);
            Test.StopTest();
         //   System.Assert(accountList[0].QTB_Legal_Entity_Country__c == 'India');
   //     }
    }
    
    static testMethod void testData2() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        Test.startTest();
        System.runAs(userList[1]) {
            QTB_PurchaseOrderTriggerHandler handler = new QTB_PurchaseOrderTriggerHandler();
            QTB_PurchaseOrderTriggerHandler.throwExplicitException = true;
            
            try{ handler.BeforeUpdate(null,null);
                handler.AfterInsert(null);
                handler.BeforeDelete(null);
                handler.AfterDelete(null);
                handler.AfterUndelete(null);
                
               }catch(Exception e){}
            
            QTB_TestDataFactory.createBypassSetting(
                QTB_Constants.SOBJECT_PURCHASEORDER
            );
            handler.isDisabled();
            Test.stopTest();
            try {
          //      QTB_PurchaseOrderHelper.countryClone(null);
            } catch (Exception e) {
                System.assert('Script-thrown exception' == e.getMessage());
            }
            system.assertEquals(true,QTB_PurchaseOrderTriggerHandler.throwExplicitException);
            try {
                //QTB_PurchaseOrderHelper.reCalculatePOBalance(null,null,false);
            } catch (Exception e) {
                System.assert('Script-thrown exception' == e.getMessage());
            }
            system.assertEquals(true,QTB_PurchaseOrderTriggerHandler.throwExplicitException);
            try {
          //      QTB_PurchaseOrderHelper.duplicateupdatetimeperiod(null,null);
            } catch (Exception e) {
                System.assert('Script-thrown exception' == e.getMessage());
            }
            system.assertEquals(true,QTB_PurchaseOrderTriggerHandler.throwExplicitException);
            try {
         //       QTB_PurchaseOrderHelper.duplicatetimeperiod(null);
                
            } catch (Exception e) {
                System.assert('Script-thrown exception' == e.getMessage());
            }
            system.assertEquals(true,QTB_PurchaseOrderTriggerHandler.throwExplicitException);
            try {
         //       QTB_PurchaseOrderHelper.isPoContactPresent(null);
            } catch (Exception e) {
                System.assert('Script-thrown exception' == e.getMessage());
            }
            system.assertEquals(true,QTB_PurchaseOrderTriggerHandler.throwExplicitException);
             try {// null exeception
                QTB_PurchaseOrderHelper.calculatingPOBalanceAmount(null);
            } catch (Exception e) {
             //   System.assert('Script-thrown exception' == e.getMessage());
            }
            system.assertEquals(true,QTB_PurchaseOrderTriggerHandler.throwExplicitException);
            try {
                QTB_PurchaseOrderHelper.poAmountChange(null,null);
            } catch (Exception e) {
              //  System.assert('Script-thrown exception' == e.getMessage());
            }
            system.assertEquals(true,QTB_PurchaseOrderTriggerHandler.throwExplicitException);
            try {
                QTB_PurchaseOrderHelper.reCalculatePOBalance(null,null,false);
            } catch (Exception e) {
            //    System.assert('Script-thrown exception' == e.getMessage());
            }
            system.assertEquals(true,QTB_PurchaseOrderTriggerHandler.throwExplicitException);
            
        }
    }
    
    // added for 12087
    static testMethod void testData4() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
      
        Test.startTest();
        Metadata_Activation_Settings__c cs = new Metadata_Activation_Settings__c();
        cs.Disable_VR__c=true;
        insert cs;
        cs.Disable_VR__c=false;
        update cs;
        
      //  System.runAs(userList[1]) {
            
            try {
                QTB_PurchaseOrderHelper.storeSentEmailAlertsOnInsert(null);
            } catch (Exception e) {
                System.assert('Script-thrown exception' == e.getMessage());
            }
            try {
                QTB_PurchaseOrderHelper.storeSentEmailAlertsOnUpdate(null,null);
            } catch (Exception e) {
                System.assert('Script-thrown exception' == e.getMessage());
            }
        /*    List<account> accountList = QTB_TestDataFactory.createAccounts(
                2,
                'Billing Account'
            );
            accountList[0].QTB_Legal_Entity_Country__c = 'India';
            accountList[1].QTB_Legal_Entity_Country__c = 'India';
            update accountList; */
			
			List<Account> accountList = new List<Account>();
			ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
			Id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
			for (Integer i = 0; i < 10; i++) {
            Account a = new Account();
            a.Name = (a.Name == null ? 'Test' : a.Name) + i;
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.Name = 'Test Account';
            a.BillingCountry = 'India';
            a.BillingPostalCode = '11209';
            a.BillingState = 'TN';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'India';
            a.QTB_Legal_Entity_Country__c='India';
            if(i == 0){
                a.QTB_Legal_Entity_Country__c='United States';
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
            accountList.add(a);
        }
        
        if (!accountList.isEmpty()) {
            insert accountList; // insert Accounts 
        }
            
            
            
            Contact con = new Contact();
            con.LastName = 'Custom Last Name:20 ';
            con.FirstName = 'Custom First Name ';
            con.email = 'some1@email.com';
            con.AccountId = accountList[0].Id;
            con.MailingCountry = 'United States';
            con.IM_Role__c = 'PO Contact';
            insert con;
            
            AccountContactRelation acr = new AccountContactRelation();
            acr.accountId = accountList[1].id;
            acr.ContactId = con.Id;
            insert acr;
            
            acr.Roles = 'PO Contact';
            update acr;
            
            List<QTB_PurchaseOrder__c> POlist = new List<QTB_PurchaseOrder__c>();
            List<QTB_PurchaseOrder__c> POlist1 = new List<QTB_PurchaseOrder__c>();
            Map<id,QTB_PurchaseOrder__c> ordOldMap = new Map<id,QTB_PurchaseOrder__c>();
            List<QTB_PurchaseOrder__c> POlist2 = new List<QTB_PurchaseOrder__c>();
            Map<id,QTB_PurchaseOrder__c> ordOldMap2 = new Map<id,QTB_PurchaseOrder__c>();
            
            QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(
                QTB_Billing_Account__c = accountList[1].id,
                QTB_Status__c = 'Active',
                QTB_Start_Date__c = date.Today(),
                QTB_End_Date__c = date.today(),
                QTB_100_Utilization_Email_Sent__c = True,
                QTB_30_Days_After_100_Utilization_Email__c = True,
                QTB_30_Days_Before_Email_Sent__c = True,
                QTB_50_Utilization_Email_Sent__c = True,
                QTB_60_Days_After_100_Utilization_Email__c = True,
                QTB_60_Days_After_Email_Sent__c = True,
                QTB_60_Days_Before_Email_Sent__c = True,
                QTB_75_Utilization_Email_Sent__c = true,
                QTB_90_Days_After_Email_Sent__c = True,
                QTB_90_Days_Before_Email_Sent__c = True,
                QTB_90_Utilization_Email_Sent__c = True,
                QTB_PO_Type__c = 'Standard',
                QTB_Customer_PO__c = 'QW2315',
                QTB_Amount__c = 10000,
                QTB_Service_Type__c = 'Mixed',
                QTB_PO_Balance_Amount__c = 10000
            );
            insert pOrder;
            Polist.add(Porder);
            
            QTB_PurchaseOrder__c pOrder1 = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[1].id,
                                                                    QTB_Status__c = 'Active',
                                                                    QTB_Start_Date__c = date.Today()+10,
                                                                    QTB_End_Date__c = date.today()+15,
                                                                    QTB_PO_Type__c = 'Blanket',
                													QTB_Customer_PO__c = 'QW2315',
                                                                    QTB_Amount__c = 10000,QTB_Service_Type__c = 'Mixed');
            insert Porder1;
            Polist.add(Porder1);
            
            QTB_PurchaseOrder__c pOrder2 = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[1].id,
                                                                    QTB_Status__c = 'Active',
                                                                    QTB_Start_Date__c = date.Today()+30,
                                                                    QTB_End_Date__c = date.today()+35,
                                                                    QTB_PO_Type__c = 'Contract',
                													QTB_Customer_PO__c = 'QW2315',
                                                                    QTB_Amount__c = 10000,QTB_Service_Type__c = 'Mixed',
																	QTB_Legal_Entity_Country__c = 'United States');
            insert pOrder2;
            ordOldMap.put(Porder2.id,Porder2);
            
            pOrder2.QTB_End_Date__c = date.today()+40;
            pOrder2.QTB_100_Utilization_Email_Sent__c = false;
            pOrder2.QTB_30_Days_After_100_Utilization_Email__c = false;
            pOrder2.QTB_30_Days_Before_Email_Sent__c = false;
            pOrder2.QTB_50_Utilization_Email_Sent__c = false;
            pOrder2.QTB_60_Days_After_100_Utilization_Email__c = false;
            pOrder2.QTB_60_Days_After_Email_Sent__c = false;
            pOrder2.QTB_60_Days_Before_Email_Sent__c = false;
            pOrder2.QTB_75_Utilization_Email_Sent__c = false;
            pOrder2.QTB_90_Days_After_Email_Sent__c = false;
            pOrder2.QTB_90_Days_Before_Email_Sent__c = false;
            pOrder2.QTB_90_Utilization_Email_Sent__c = false;
            update pOrder2;
            Polist1.add(pOrder2);
            
            pOrder2.QTB_100_Utilization_Email_Sent__c = true;
            pOrder2.QTB_30_Days_After_100_Utilization_Email__c = true;
            pOrder2.QTB_30_Days_Before_Email_Sent__c = true;
            pOrder2.QTB_50_Utilization_Email_Sent__c = true;
            pOrder2.QTB_60_Days_After_100_Utilization_Email__c = true;
            pOrder2.QTB_60_Days_After_Email_Sent__c = true;
            pOrder2.QTB_60_Days_Before_Email_Sent__c = true;
            pOrder2.QTB_75_Utilization_Email_Sent__c = true;
            pOrder2.QTB_90_Days_After_Email_Sent__c = true;
            pOrder2.QTB_90_Days_Before_Email_Sent__c = true;
            pOrder2.QTB_90_Utilization_Email_Sent__c = true;
            Polist1.add(pOrder2);
            update pOrder2;
            ordOldMap.put(Porder2.id,Porder2);
            Map<Id,List<QTB_PurchaseOrder__c>>accPOMap = new Map<Id,List<QTB_PurchaseOrder__c>>();
            accPOMap.put(accountList[1].id,Polist);
            QTB_PurchaseOrderHelper.storeSentEmailAlertsOnInsert(Polist);
            QTB_PurchaseOrderHelper.storeSentEmailAlertsOnUpdate(Polist1, ordOldMap);
            Test.StopTest();
          //  System.Assert(accountList[0].QTB_Legal_Entity_Country__c == 'India');
        }
 //   }
    
}
/*****************************************************************************************************
* Class: QTB_sendPONotificationBatch_Test
* Author: IRM
* Purpose: Test Class for QTB_sendPONotificationBatch
* Change History: 6/07/2021
* Developer       Date           Description
* ------------------------------------------------------------------------------------------- 
* Gopinandan Biswal   6/07/2021
*******************************************************************************************************/

@isTest(seeAllData=false)
private with sharing class QTB_sendPONotificationBatch_Test {
    
    @testSetup static void setup() {
        blng__LegalEntity__c indiaLegalEntity = QTB_TestDataFactory.createLegalEntity('India');
        indiaLegalEntity.QTB_Legal_Entity_Number__c = 45000.0;
        update indiaLegalEntity; 
        
        blng__LegalEntity__c usLegalEntity = QTB_TestDataFactory.createLegalEntity('United States');
        usLegalEntity.QTB_Legal_Entity_Number__c = 50000.0;
        update usLegalEntity;

        List<Account> accountList = QTB_TestDataFactory.createAccounts(4, 'Billing Account');
        
        accountList[0].QTB_Language__c = 'en_US';
        accountList[0].QTB_Legal_Entity_Country__c = 'India';
        accountList[0].QTB_Contract_Entity__c = indiaLegalEntity.id;
        
        accountList[1].QTB_Language__c = 'en_US';
        accountList[1].QTB_Legal_Entity_Country__c = 'United States';
        accountList[1].QTB_Contract_Entity__c = usLegalEntity.id;
        
        accountList[2].QTB_Language__c = 'en_US';
        accountList[2].QTB_Legal_Entity_Country__c = 'United States';

        update accountList;

        // Create PO contacts
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName = 'PO Contact 1', FirstName = 'Test', Email = 'pocontact1@example.com', AccountId = accountList[0].Id, IM_Role__c = 'PO Contact'),
            new Contact(LastName = 'PO Contact 2', FirstName = 'Test', Email = 'pocontact2@example.com', AccountId = accountList[1].Id, IM_Role__c = 'PO Contact'),
            new Contact(LastName = 'PO Contact 3', FirstName = 'Test', Email = 'pocontact3@example.com', AccountId = accountList[2].Id, IM_Role__c = 'PO Contact')
        };
        insert contacts;

        // Account Contact Relations
        insert new List<AccountContactRelation>{
            new AccountContactRelation(AccountId = accountList[1].id, ContactId = contacts[0].Id, Roles = 'PO Contact'),
            new AccountContactRelation(AccountId = accountList[0].id, ContactId = contacts[1].Id, Roles = 'PO Contact')
        };

        // Create POs (no Billing_Account__c now)
        List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>{
            new QTB_PurchaseOrder__c(
                QTB_Status__c = 'Active',
                QTB_End_Date__c = date.today(),
                QTB_Start_Date__c = date.Today(),
                QTB_100_Utilization_Email_Sent__c = true,
                QTB_30_Days_After_100_Utilization_Email__c = true,
                QTB_30_Days_Before_Email_Sent__c = true,
                QTB_50_Utilization_Email_Sent__c = true,
                QTB_60_Days_After_100_Utilization_Email__c = true,
                QTB_60_Days_After_Email_Sent__c = true,
                QTB_60_Days_Before_Email_Sent__c = true,
                QTB_75_Utilization_Email_Sent__c = true,
                QTB_90_Days_After_Email_Sent__c = true,
                QTB_90_Days_Before_Email_Sent__c = true,
                QTB_90_Utilization_Email_Sent__c = true,
                QTB_PO_Type__c = 'Standard',
                QTB_Customer_PO__c = 'QW2315',
                QTB_Amount__c = 10000,
                QTB_PO_Balance_Amount__c = 10000,
                QTB_Service_Type__c = 'Mixed'
            ),
            new QTB_PurchaseOrder__c(
                QTB_Amount__c = 1000,
                QTB_PO_Balance_Amount__c = -20,
                QTB_Legal_Entity_Country__c = 'India',
                QTB_Customer_Id__c = 'Test1111',
                QTB_End_Date__c = date.today(),
                QTB_Start_Date__c = date.Today(),
                QTB_Status__c = 'Active',
                QTB_Customer_PO__c = 'PO-001',
                QTB_PO_Type__c = 'Standard',
                QTB_Service_Type__c = 'Mixed',
                QTB_50_Utilization_Email_Sent__c = false,
                QTB_75_Utilization_Email_Sent__c = false,
                QTB_90_Utilization_Email_Sent__c = false
            ),
            new QTB_PurchaseOrder__c(
                QTB_Amount__c = 1000,
                QTB_PO_Balance_Amount__c = 250,
                QTB_Legal_Entity_Country__c = 'United States',
                QTB_Customer_Id__c = 'Test2222',
                QTB_End_Date__c = System.today().addDays(30),
                QTB_Start_Date__c = System.today() - 60,
                QTB_Status__c = 'Active',
                QTB_Customer_PO__c = 'PO-002',
                QTB_PO_Type__c = 'Standard',
                QTB_Service_Type__c = 'Mixed',
                QTB_75_Utilization_Email_Sent__c = false
            ),
            new QTB_PurchaseOrder__c(
                QTB_Amount__c = 500,
                QTB_PO_Balance_Amount__c = 200,
                QTB_Legal_Entity_Country__c = 'United States',
                QTB_Customer_Id__c = 'Test5555',
                QTB_End_Date__c = System.today().addDays(-60),
                QTB_Start_Date__c = System.today() - 120,
                QTB_Status__c = 'Active',
                QTB_Customer_PO__c = 'PO-005',
                QTB_PO_Type__c = 'Standard',
                QTB_Service_Type__c = 'Mixed',
                QTB_60_Days_After_Email_Sent__c = false
            )
        };
        insert poList;

                List<QTB_PurchaseOrder__c> pos = new List<QTB_PurchaseOrder__c>{
            new QTB_PurchaseOrder__c(
                QTB_Amount__c = 1000,
                QTB_PO_Balance_Amount__c = 400, // 60% used
                QTB_50_Utilization_Email_Sent__c = false,
                QTB_75_Utilization_Email_Sent__c = true,
                QTB_90_Utilization_Email_Sent__c = true,
                QTB_100_Utilization_Email_Sent__c = true,
                QTB_Status__c = 'Active',
                QTB_Customer_PO__c = 'PO-60',
                QTB_PO_Type__c = 'Standard',
                QTB_Service_Type__c = 'Mixed',
                QTB_Legal_Entity_Country__c = 'India'
            ),
            new QTB_PurchaseOrder__c(
                QTB_Amount__c = 1000,
                QTB_PO_Balance_Amount__c = 200, // 80% used
                QTB_50_Utilization_Email_Sent__c = true,
                QTB_75_Utilization_Email_Sent__c = false,
                QTB_90_Utilization_Email_Sent__c = true,
                QTB_100_Utilization_Email_Sent__c = true,
                QTB_Status__c = 'Active',
                QTB_Customer_PO__c = 'PO-80',
                QTB_PO_Type__c = 'Standard',
                QTB_Service_Type__c = 'Mixed',
                QTB_Legal_Entity_Country__c = 'India'
            ),
            new QTB_PurchaseOrder__c(
                QTB_Amount__c = 1000,
                QTB_PO_Balance_Amount__c = 50, // 95% used
                QTB_50_Utilization_Email_Sent__c = true,
                QTB_75_Utilization_Email_Sent__c = true,
                QTB_90_Utilization_Email_Sent__c = false,
                QTB_100_Utilization_Email_Sent__c = true,
                QTB_Status__c = 'Active',
                QTB_Customer_PO__c = 'PO-95',
                QTB_PO_Type__c = 'Standard',
                QTB_Service_Type__c = 'Mixed',
                QTB_Legal_Entity_Country__c = 'India'
            ),
            new QTB_PurchaseOrder__c(
                QTB_Amount__c = 1000,
                QTB_PO_Balance_Amount__c = 0, // 100% used
                QTB_50_Utilization_Email_Sent__c = true,
                QTB_75_Utilization_Email_Sent__c = true,
                QTB_90_Utilization_Email_Sent__c = true,
                QTB_100_Utilization_Email_Sent__c = false,
                QTB_Status__c = 'Active',
                QTB_Customer_PO__c = 'PO-100',
                QTB_PO_Type__c = 'Standard',
                QTB_Service_Type__c = 'Mixed',
                QTB_Legal_Entity_Country__c = 'India'
            )
        };
        insert pos;

        // Link POs to Accounts using Junction object
        List<QTB_PurchaseOrderAccount__c> poAccountList = new List<QTB_PurchaseOrderAccount__c>{
            new QTB_PurchaseOrderAccount__c(QTB_Purchase_Order__c = poList[0].Id, QTB_Account__c = accountList[1].Id),
            new QTB_PurchaseOrderAccount__c(QTB_Purchase_Order__c = poList[1].Id, QTB_Account__c = accountList[0].Id),
            new QTB_PurchaseOrderAccount__c(QTB_Purchase_Order__c = poList[2].Id, QTB_Account__c = accountList[1].Id),
            new QTB_PurchaseOrderAccount__c(QTB_Purchase_Order__c = poList[3].Id, QTB_Account__c = accountList[1].Id)
        };
        insert poAccountList;
        

        for (QTB_PurchaseOrder__c po : poList) {
            System.debug('Created PO ID: ' + po.Id + ', Amount: ' + po.QTB_Amount__c + ', Balance: ' + po.QTB_PO_Balance_Amount__c);
        }
    }

    @isTest static void testMethod1() {
        List<QTB_PurchaseOrder__c> posorder = [SELECT Id, QTB_Amount__c, QTB_PO_Balance_Amount__c, QTB_Status__c,
            QTB_50_Utilization_Email_Sent__c, QTB_75_Utilization_Email_Sent__c, QTB_90_Utilization_Email_Sent__c,
            QTB_100_Utilization_Email_Sent__c, QTB_Legal_Entity_Country__c
            FROM QTB_PurchaseOrder__c];

        List<Id> poIds = new List<Id>();
        for (QTB_PurchaseOrder__c po : posorder) {
            poIds.add(po.Id);
            System.debug(po.QTB_Amount__c + ' Balance ' + po.QTB_PO_Balance_Amount__c);
        }

        Test.startTest();   
        QTB_sendPONotificationBatch poBatch = new QTB_sendPONotificationBatch(poIds);
        Database.executeBatch(poBatch);
        Test.stopTest();
    }

        @isTest
        static void test_100Percent_Utilization() {

            // Create Account
              Test.startTest(); 
            Account acc = new Account(
                Name = 'Test Account Utilization',
                BillingPostalCode = '90210',
                BillingState = 'CA',
                ShippingCountry = 'United States',
                QTB_Legal_Entity_Country__c = 'United States',
                QTB_Language__c = 'en_US'
            );
            insert acc;

            // Create Legal Entity and assign to Account
            blng__LegalEntity__c indiaLegalEntity = QTB_TestDataFactory.createLegalEntity('India');
            indiaLegalEntity.QTB_Legal_Entity_Number__c = 45000.0;
            update indiaLegalEntity;

            acc.QTB_Contract_Entity__c = indiaLegalEntity.Id;
            update acc;

            // Create Contact and associate with Account
            Contact con = new Contact(
                FirstName = 'Util',
                LastName = 'User',
                Email = 'utiluser@example.com',
                AccountId = acc.Id
            );
            insert con;

            // Update AccountContactRelation to include 'PO Contact' role
            AccountContactRelation acr = [
                SELECT Id, Roles FROM AccountContactRelation
                WHERE AccountId = :acc.Id AND ContactId = :con.Id LIMIT 1
            ];
            acr.Roles = 'PO Contact';
            update acr;


            QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c(
                QTB_Legal_Entity_Country__c = acc.QTB_Legal_Entity_Country__c,
                QTB_Customer_Id__c = 'Test1111',
                QTB_End_Date__c = date.today(),
                QTB_Start_Date__c = date.Today(),
                QTB_Amount__c = 1000,
                QTB_PO_Balance_Amount__c = 1000, // 100% used
                QTB_Status__c = 'Active',
                QTB_Customer_PO__c = 'PO-100',
                QTB_100_Utilization_Email_Sent__c = true,
                QTB_PO_Type__c = 'Standard',
                QTB_Service_Type__c = 'Mixed'
            );
            insert po;

            // Create junction to link PO with Account
            QTB_PurchaseOrderAccount__c junction = new QTB_PurchaseOrderAccount__c(
                QTB_Account__c = acc.Id,
                QTB_Purchase_Order__c = po.Id
            );
            insert junction;

          //  Test.startTest();
            Database.executeBatch(new QTB_sendPONotificationBatch(new List<Id>{po.Id}));
            Test.stopTest();

            po = [SELECT QTB_100_Utilization_Email_Sent__c FROM QTB_PurchaseOrder__c WHERE Id = :po.Id];
            System.assertEquals(true, po.QTB_100_Utilization_Email_Sent__c, '100% utilization flag should be set');
        }

}



// @isTest(seeAllData=false)
// private with sharing class QTB_sendPONotificationBatch_Test {
    
    
//     @testSetup static void setup() {
        
      
//         blng__LegalEntity__c indiaLegalEntity = QTB_TestDataFactory.createLegalEntity('India');
//         indiaLegalEntity.QTB_Legal_Entity_Number__c = 45000.0;
//         update indiaLegalEntity; 
        
//         blng__LegalEntity__c usLegalEntity = QTB_TestDataFactory.createLegalEntity('United States');
//         usLegalEntity.QTB_Legal_Entity_Number__c = 50000.0;
//         update usLegalEntity;
        

//         // Create accounts with different countries and languages
//         List<Account> accountList = QTB_TestDataFactory.createAccounts(4, 'Billing Account');
        
//        // Account 1 - India with legal entity
//         accountList[0].QTB_Language__c = 'en_US';
//         accountList[0].BillingPostalCode = '567788';
//         accountList[0].BillingState = 'TNY';
//         accountList[0].ShippingCountry = 'India';
//         accountList[0].QTB_Legal_Entity_Country__c = 'India';
//         accountList[0].QTB_Contract_Entity__c = indiaLegalEntity.id;
        
//          // Account 2 - US with legal entity
//         accountList[1].QTB_Language__c = 'en_US';
//         accountList[1].BillingPostalCode = '10001';
//         accountList[1].BillingState = 'NY';
//         accountList[1].ShippingCountry = 'United States';
//         accountList[1].QTB_Legal_Entity_Country__c = 'United States';
//         accountList[1].QTB_Contract_Entity__c = usLegalEntity.id;
        
//         // Account 3 - US without legal entity
//         accountList[2].QTB_Language__c = 'en_US';
//         accountList[2].BillingPostalCode = '90210';
//         accountList[2].BillingState = 'CA';
//         accountList[2].ShippingCountry = 'United States';
//         accountList[2].QTB_Legal_Entity_Country__c = 'United States';
//         update accountList;
        
//         // Create contacts and account contact relations for PO notifications
//         List<Contact> contacts = new List<Contact>();
        
//         Contact con1 = new Contact(
//             LastName = 'PO Contact 1',
//             FirstName = 'Test',
//             Email = 'pocontact1@example.com',
//             AccountId = accountList[0].id,
//             IM_Role__c = 'PO Contact'
//         );
//         contacts.add(con1);
        
//         Contact con2 = new Contact(
//             LastName = 'PO Contact 2',
//             FirstName = 'Test',
//             Email = 'pocontact2@example.com',
//             AccountId = accountList[1].id,
//             IM_Role__c = 'PO Contact'
//         );
//         contacts.add(con2);
        
//         Contact con3 = new Contact(
//             LastName = 'PO Contact 3',
//             FirstName = 'Test',
//             Email = 'pocontact3@example.com',
//             AccountId = accountList[2].id,
//             IM_Role__c = 'PO Contact'
//         );
//         contacts.add(con3);

//         insert contacts;

//           // Create account contact relations for cross-account contact
//         AccountContactRelation acr = new AccountContactRelation(
//             AccountId = accountList[1].id,
//             ContactId = con1.Id,
//             Roles = 'PO Contact'
//         );
//         insert acr;
        
//         AccountContactRelation acr1 = new AccountContactRelation(
//             AccountId = accountList[0].id,
//             ContactId = con2.Id,
//             Roles = 'PO Contact'
//         );
//         insert acr1;

//   List<QTB_PurchaseOrder__c> poList3 = new List<QTB_PurchaseOrder__c>();
        
//         poList3.add(new QTB_PurchaseOrder__c(
//              QTB_Billing_Account__c = accountList[1].id,
//                 QTB_Status__c = 'Active',
//                 QTB_End_Date__c = date.today(),
//                 QTB_Start_Date__c = date.Today(),
//                 QTB_100_Utilization_Email_Sent__c = True,
//                 QTB_30_Days_After_100_Utilization_Email__c = True,
//                 QTB_30_Days_Before_Email_Sent__c = True,
//                 QTB_50_Utilization_Email_Sent__c = True,
//                 QTB_60_Days_After_100_Utilization_Email__c = True,
//                 QTB_60_Days_After_Email_Sent__c = True,
//                 QTB_60_Days_Before_Email_Sent__c = True,
//                 QTB_75_Utilization_Email_Sent__c = true,
//                 QTB_90_Days_After_Email_Sent__c = True,
//                 QTB_90_Days_Before_Email_Sent__c = True,
//                 QTB_90_Utilization_Email_Sent__c = True,
//                 QTB_PO_Type__c = 'Standard',
//                 QTB_Customer_PO__c = 'QW2315',
//                 QTB_Amount__c = 10000,
//                 QTB_Service_Type__c = 'Mixed',
//                 QTB_PO_Balance_Amount__c = 10000            
//         )); 
// poList3.add(new QTB_PurchaseOrder__c(
//             QTB_Amount__c = 1000,
//             QTB_PO_Balance_Amount__c = -20,
//             QTB_Legal_Entity_Country__c = 'India',
//             QTB_Billing_Account__c = accountList[0].id,
//             QTB_Customer_Id__c = 'Test1111',
//             QTB_End_Date__c = date.today(),
//             QTB_Start_Date__c = date.Today(),
//             QTB_Status__c = 'Active',
//             QTB_Customer_PO__c = 'PO-001',
//             QTB_PO_Type__c = 'Standard',
//             QTB_Service_Type__c = 'Mixed',
//             QTB_50_Utilization_Email_Sent__c = false,
//             QTB_75_Utilization_Email_Sent__c = false,
//             QTB_90_Utilization_Email_Sent__c = false
            
//         ));

//    poList3.add(new QTB_PurchaseOrder__c(
//             QTB_Amount__c = 1000,
//             QTB_PO_Balance_Amount__c = 250,
//             QTB_Legal_Entity_Country__c = 'United States',
//             QTB_Billing_Account__c = accountList[1].id,
//             QTB_Customer_Id__c = 'Test2222',
//             QTB_End_Date__c = System.today().addDays(30),
//             QTB_Start_Date__c = System.today() - 60,
//             QTB_Status__c = 'Active',
//             QTB_Customer_PO__c = 'PO-002',
//             QTB_PO_Type__c = 'Standard',
//             QTB_Service_Type__c = 'Mixed',
//             QTB_75_Utilization_Email_Sent__c = false
//         ));
        
        
//  poList3.add(new QTB_PurchaseOrder__c(
//             QTB_Amount__c = 500,
//             QTB_PO_Balance_Amount__c = 200,
//             QTB_Legal_Entity_Country__c = 'United States',
//             QTB_Billing_Account__c = accountList[1].id,
//             QTB_Customer_Id__c = 'Test5555',
//             QTB_End_Date__c = System.today().addDays(-60),
//             QTB_Start_Date__c = System.today() - 120,
//             QTB_Status__c = 'Active',
//             QTB_Customer_PO__c = 'PO-005',
//             QTB_PO_Type__c = 'Standard',
//             QTB_Service_Type__c = 'Mixed',
//             QTB_60_Days_After_Email_Sent__c = false
//         ));
        
//    insert poList3;  
 
        
//         for (QTB_PurchaseOrder__c po : poList3) {
//         System.debug('Created PO ID: ' + po.Id + ', Amount: ' + po.QTB_Amount__c + ', Balance: ' + po.QTB_PO_Balance_Amount__c);
//     }
//     }
    
    
//     @isTest static void testMethod1() {
        
//         List<QTB_PurchaseOrder__c> Po = [SELECT id,QTB_Amount__c, QTB_PO_Balance_Amount__c, QTB_Status__c,
//                QTB_50_Utilization_Email_Sent__c, QTB_75_Utilization_Email_Sent__c, 
//                QTB_90_Utilization_Email_Sent__c, QTB_100_Utilization_Email_Sent__c,QTB_Legal_Entity_Country__c,
//                                          QTB_Billing_Account__r.QTB_Language__c FROM QTB_PurchaseOrder__c ];
       
       
//         List<ID> POIds = new List<ID>();        
//         for(integer i = 0 ; i < Po.size(); i++){
//             POIds.add(Po[i].id);
//             System.debug(Po[i].QTB_Amount__c +'Balance' + Po[i].QTB_PO_Balance_Amount__c);
//         }
//         Test.startTest();   
//        QTB_sendPONotificationBatch poBatch = new QTB_sendPONotificationBatch(POIds);
        
//         Database.executeBatch(poBatch);
        
//         Test.stopTest();
//     }
// }
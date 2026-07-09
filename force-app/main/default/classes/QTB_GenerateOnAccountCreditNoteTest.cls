/*****************************************************************************************************
* Class: QTB_GenerateOnAccountCreditNoteTest
* Author: Virtusa
* Purpose: Test Class for QTB_GenerateOnAccountCreditNote
* Requirement:
* Change History:
* Developer
* -------------------------------------------------------------------------------------------
* Thrinethra
*******************************************************************************************************/
@isTest
private class QTB_GenerateOnAccountCreditNoteTest {

    @isTest
    static void testCreateOnAccountCreditNoteSuccess(){
        //set up test data
        //Account creation
        Account testAccount = new Account();
        testAccount.Name = 'testAccount';
        testAccount.QTB_Legal_Entity_Country__c = 'United States';
        testAccount.QTB_SITAD__c = true;
        insert testAccount;

        //product creation
        Product2 testProduct = new Product2();
        testProduct.Name = 'Test Product';
        testProduct.ProductCode = 'TP001';
        insert testProduct;

        //Credit staging creation

        QTB_CreditStaging__c creditStaging = new QTB_CreditStaging__c();
        creditStaging.QTB_Account__c = testAccount.Id;
        creditStaging.QTB_Department_Code__c = 'DPT001';
        creditStaging.QTB_Purchase_Order__c = 'PO001';
        creditStaging.QTB_PreratedAmount__c = 100.00;
        creditStaging.QTB_PreratedQuantity__c = 5;
        creditStaging.QTB_Product__c = testProduct.Id;
        creditStaging.QTB_Is_CreditNote_Generated__c = false;
        creditStaging.QTB_EndDateTime__c = system.today();
        creditStaging.QTB_MatchingId__c= 'Match001';
        creditStaging.QTB_StartDateTime__c = system.today();
        creditStaging.QTB_MatchingAttribute__c = '12345';
        creditStaging.QTB_Product_Identifier_1__c = '25.OTHOTHERARMBK';
        insert creditStaging;

        //preparing input for the method
        List<string> stagingIds = new List<string>();
        stagingIds.add(creditStaging.Id);
        QTB_GenerateOnAccountCreditNote.StagingSelectedRecords selectedRecord = new QTB_GenerateOnAccountCreditNote.StagingSelectedRecords();
        List<QTB_GenerateOnAccountCreditNote.StagingSelectedRecords> selectedRecords = new List<QTB_GenerateOnAccountCreditNote.StagingSelectedRecords>();
        selectedRecord.stagingId = stagingIds;
        selectedRecords.add(selectedRecord);

        //Act
        Test.startTest();
        QTB_GenerateOnAccountCreditNote.createOnAccountCredit(selectedRecords);
        Test.stopTest();

        //Assert
        List<blng__CreditNote__c> creditNoteList = [SELECT Id, QTB_Credit_Staging__c, blng__Account__c, QTB_On_Account_Credit__c FROM blng__CreditNote__c
                                                        WHERE QTB_Credit_Staging__c  = :creditStaging.Id];
        system.Assert.areEqual(1, creditNoteList.size());
        system.Assert.areEqual(true, creditNoteList[0].QTB_On_Account_Credit__c);
        system.Assert.areEqual(testAccount.Id, creditNoteList[0].blng__Account__c);

        //Verify credit note lines are created
        List<blng__CreditNoteLine__c> creditNoteLines = [SELECT Id, blng__CreditNote__c, QTB_Credit_Quantity__c, blng__Subtotal__c, blng__Product__c 
                                                        FROM blng__CreditNoteLine__c WHERE blng__CreditNote__c = :creditNoteList[0].Id];
        system.Assert.areEqual(1, creditNoteLines.size(), 'One credit note line should be created');
        system.Assert.areEqual(creditStaging.QTB_PreratedQuantity__c, creditNoteLines[0].QTB_Credit_Quantity__c, 'Quantity should match');
        //system.Assert.areEqual(creditStaging.QTB_PreratedAmount__c, creditNoteLines[0].blng__Subtotal__c, 'Amount should match');
        system.Assert.areEqual(creditStaging.QTB_Product__c, creditNoteLines[0].blng__Product__c, 'Product should match');

        //verify the checkbox is set to true
        List<QTB_CreditStaging__c> creditStagingList = [SELECT Id, QTB_Is_CreditNote_Generated__c FROM QTB_CreditStaging__c WHERE Id = :creditStaging.Id];
        system.Assert.areEqual(true, creditStagingList[0].QTB_Is_CreditNote_Generated__c, 'Checkbox should be set to true');
    }

    @isTest
    static void testCreateOnAccountCreditNoteFailure(){
        //set up test data
        //Account creation
        Account testAccount = new Account();
        testAccount.Name = 'testAccount';
        testAccount.QTB_Legal_Entity_Country__c = 'United States';
        testAccount.QTB_SITAD__c = true;
        insert testAccount;

        //Product creation
        Product2 testProduct = new Product2();
        testProduct.Name = 'Test Product';
        testProduct.ProductCode = 'TP001';
        insert testProduct;

        //Credit Staging creation

        QTB_CreditStaging__c creditStaging = new QTB_CreditStaging__c();
        creditStaging.QTB_Account__c = testAccount.Id;
        creditStaging.QTB_Department_Code__c = null;
        creditStaging.QTB_Purchase_Order__c = null;
        creditStaging.QTB_PreratedAmount__c = 100.00;
        creditStaging.QTB_PreratedQuantity__c = 5;
        creditStaging.QTB_Product__c = testProduct.Id;
        creditStaging.QTB_Is_CreditNote_Generated__c = false;
        creditStaging.QTB_EndDateTime__c = system.today();
        creditStaging.QTB_MatchingId__c= 'Match001';
        creditStaging.QTB_StartDateTime__c = system.today();
        creditStaging.QTB_MatchingAttribute__c = '12345';
        creditStaging.QTB_Product_Identifier_1__c = '25.OTHOTHERARMBK';
        insert creditStaging;

        //preparing input for the method
        List<string> stagingIds = new List<string>();
        stagingIds.add(creditStaging.Id);
        QTB_GenerateOnAccountCreditNote.StagingSelectedRecords selectedRecord = new QTB_GenerateOnAccountCreditNote.StagingSelectedRecords();
        List<QTB_GenerateOnAccountCreditNote.StagingSelectedRecords> selectedRecords = new List<QTB_GenerateOnAccountCreditNote.StagingSelectedRecords>();
        selectedRecord.stagingId = stagingIds;
        selectedRecords.add(selectedRecord);

        //Act
        Test.startTest();
        QTB_GenerateOnAccountCreditNote.createOnAccountCredit(selectedRecords);
        Test.stopTest();

        //Assert
        List<blng__CreditNote__c> creditNoteList = [SELECT Id FROM blng__CreditNote__c
                                                        WHERE QTB_Credit_Staging__c  = :creditStaging.Id];
        system.Assert.areEqual(0, creditNoteList.size(), 'No Credit Note should be created due to validation Error');
        
        //verify check box is not set to true
        List<QTB_CreditStaging__c> creditStagingList = [SELECT Id, QTB_Is_CreditNote_Generated__c FROM QTB_CreditStaging__c WHERE Id = :creditStaging.Id];
        system.Assert.areEqual(false, creditStagingList[0].QTB_Is_CreditNote_Generated__c, 'Checkbox should not be set to true');
    }

    @isTest
    static void testCreateOnAccountCreditNoteWithExisingCreditNote(){
        //set up test data
        //Account creation
        Account testAccount = new Account();
        testAccount.Name = 'testAccount';
        testAccount.QTB_Legal_Entity_Country__c = 'United States';
        testAccount.QTB_SITAD__c = true;
        insert testAccount;

        //Product creation
        Product2 testProduct = new Product2();
        testProduct.Name = 'Test Product';
        testProduct.ProductCode = 'TP001';
        insert testProduct;

        //Credit Staging creation

        QTB_CreditStaging__c creditStaging = new QTB_CreditStaging__c();
        creditStaging.QTB_Account__c = testAccount.Id;
        creditStaging.QTB_Department_Code__c = 'DPT001';
        creditStaging.QTB_Purchase_Order__c = 'PO001';
        creditStaging.QTB_PreratedAmount__c = 100.00;
        creditStaging.QTB_PreratedQuantity__c = 5;
        creditStaging.QTB_Product__c = testProduct.Id;
        creditStaging.QTB_Is_CreditNote_Generated__c = true;
        creditStaging.QTB_EndDateTime__c = system.today();
        creditStaging.QTB_MatchingId__c= 'Match001';
        creditStaging.QTB_StartDateTime__c = system.today();
        creditStaging.QTB_MatchingAttribute__c = '12345';
        creditStaging.QTB_Product_Identifier_1__c = '25.OTHOTHERARMBK';
        insert creditStaging;

        //preparing input for the method
        List<string> stagingIds = new List<string>();
        stagingIds.add(creditStaging.Id);
        QTB_GenerateOnAccountCreditNote.StagingSelectedRecords selectedRecord = new QTB_GenerateOnAccountCreditNote.StagingSelectedRecords();
        List<QTB_GenerateOnAccountCreditNote.StagingSelectedRecords> selectedRecords = new List<QTB_GenerateOnAccountCreditNote.StagingSelectedRecords>();
        selectedRecord.stagingId = stagingIds;
        selectedRecords.add(selectedRecord);

        //Act
        Test.startTest();
        QTB_GenerateOnAccountCreditNote.createOnAccountCredit(selectedRecords);
        Test.stopTest();

        //Assert
        List<blng__CreditNote__c> creditNoteList = [SELECT Id FROM blng__CreditNote__c
                                                        WHERE QTB_Credit_Staging__c  = :creditStaging.Id];
        system.Assert.areEqual(0, creditNoteList.size(), 'No Credit Note should be created since it was already marked as generated');
    }

    @isTest
    static void testCreditNoteLineCreationFailure(){
        //set up test data
        //Account creation
        Account testAccount = new Account();
        testAccount.Name = 'testAccount';
        testAccount.QTB_Legal_Entity_Country__c = 'United States';
        testAccount.QTB_SITAD__c = true;
        insert testAccount;

        //Product creation
        Product2 testProduct = new Product2();
        testProduct.Name = 'Test Product';
        testProduct.ProductCode = 'TP001';
        insert testProduct;

        //Credit Staging creation

        QTB_CreditStaging__c creditStaging = new QTB_CreditStaging__c();
        creditStaging.QTB_Account__c = testAccount.Id;
        creditStaging.QTB_Department_Code__c = 'DPT001';
        creditStaging.QTB_Purchase_Order__c = 'PO001';
        creditStaging.QTB_PreratedAmount__c = 100.00;
        creditStaging.QTB_PreratedQuantity__c = 5;
        creditStaging.QTB_Is_CreditNote_Generated__c = false;
        creditStaging.QTB_EndDateTime__c = system.today();
        creditStaging.QTB_MatchingId__c= 'Match001';
        creditStaging.QTB_StartDateTime__c = system.today();
        creditStaging.QTB_MatchingAttribute__c = '12345';
        creditStaging.QTB_Product_Identifier_1__c = '25.OTHOTHERARMBK';
        insert creditStaging;

        //preparing input for the method
        List<string> stagingIds = new List<string>();
        stagingIds.add(creditStaging.Id);
        QTB_GenerateOnAccountCreditNote.StagingSelectedRecords selectedRecord = new QTB_GenerateOnAccountCreditNote.StagingSelectedRecords();
        List<QTB_GenerateOnAccountCreditNote.StagingSelectedRecords> selectedRecords = new List<QTB_GenerateOnAccountCreditNote.StagingSelectedRecords>();
        selectedRecord.stagingId = stagingIds;
        selectedRecords.add(selectedRecord);

        //Act
        Test.startTest();
        QTB_GenerateOnAccountCreditNote.createOnAccountCredit(selectedRecords);
        Test.stopTest();

        //Assert
        List<blng__CreditNote__c> creditNotes = [SELECT Id FROM blng__CreditNote__c
                                                        WHERE QTB_Credit_Staging__c  = :creditStaging.Id];
        system.Assert.areEqual(0, creditNotes.size(), 'The Credit Note should have been deleted due to failure in creditnote line creation');
        
        List<blng__CreditNoteLine__c> creditNoteLines = [SELECT Id FROM blng__CreditNoteLine__c
                                                        WHERE blng__CreditNote__c  = :creditNotes];
        system.Assert.areEqual(0, creditNoteLines.size(), 'No CreditNote Lines should have been created due to missing product in Credit Staging');

        //verify check box on the credit staging record is not updated
        List<QTB_CreditStaging__c> creditStagingList = [SELECT QTB_Is_CreditNote_Generated__c FROM QTB_CreditStaging__c WHERE Id = :creditStaging.Id];
        system.Assert.areEqual(false, creditStagingList[0].QTB_Is_CreditNote_Generated__c, 'Checkbox should not be set to true');

    }
}
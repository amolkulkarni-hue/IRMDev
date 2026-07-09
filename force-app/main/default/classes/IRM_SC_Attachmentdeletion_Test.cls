@isTest
private class IRM_SC_Attachmentdeletion_Test {
    private static Id imeScCaseRTId;
    private static Id imeScCaseResolvedRTId;
    private static Id standardCaseRTId;
     private static Case imeScCaseForHelper; 

    @testSetup
    static void setupTestData() {
        // Create custom settings for Trigger_Activation_Settings__c
        Trigger_Activation_Settings__c tasTrue = new Trigger_Activation_Settings__c(
            Name = 'IRM_SC_Attachmentdeletion_True',
            Object__c = 'Case',
            Trigger__c = 'IRM_SC_Attachmentdeletion',
            Value__c = 'TRUE'
        );
        insert tasTrue;

        /*Trigger_Activation_Settings__c tasFalse = new Trigger_Activation_Settings__c(
            Name = 'IRM_SC_Attachmentdeletion_False',
            Object__c = 'Case',
            Trigger__c = 'IRM_SC_Attachmentdeletion',
            Value__c = 'FALSE'
        );
        insert tasFalse;*/

        // Store Record Types for Case
         imeScCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IME SC Case')?.getRecordTypeId();
         imeScCaseResolvedRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IME SC Case Resolved')?.getRecordTypeId();
         standardCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Global Service Case')?.getRecordTypeId();
        Id CustomerTypeRId = Schema.SObjectType.IM_Customer_Account__c.getRecordTypeInfosByName().get('NA Customer Account').getRecordTypeId();
 
        // Add robust checks for RT IDs:
        if (imeScCaseRTId == null) {
            System.debug('ERROR: IME SC Case Record Type not found!');
        }
        if (imeScCaseResolvedRTId == null) {
            System.debug('ERROR: IME SC Case Resolved Record Type not found!');
        }
        if (standardCaseRTId == null) {
            System.debug('ERROR: Global Service Case Record Type not found! (Trying Standard)');
        }
        System.debug('Setup RT IDs: IME=' + imeScCaseRTId + ', Resolved=' + imeScCaseResolvedRTId + ', Standard=' + standardCaseRTId);

        //Creating Account, Contact & Market
        List<Account> acct=TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, False);
        cnt.Email='Testcnt@email.com';
        cnt.Survey_Opt_Out__c = true;
        insert cnt;
        System.debug('Inside Test-Account Id= '+acct[0].id+'ContactId= '+cnt.id);
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        
        //Creating Customer Account
        IM_Customer_Account__c ca=new IM_Customer_Account__c();
        ca.Name='Test Customer Account';
        ca.Source_System__c = 'SB NA';
        ca.Owning_District_Id__c = testMarket.Id;
        ca.IM_Account__c = acct[0].Id;
        ca.RecordTypeId = CustomerTypeRId;
        SYSTEM.debug('Value IM account' + acct[0].Id);
        ca.IM_Oracle_ID__c = '12345';
        insert ca;

        String usrId = UserInfo.getUserId();
        // Create Cases with different record types
        List<Case> casesToInsert = new List<Case>();
        Case imeScCase = new Case(Subject = 'Test IME SC Case', RecordTypeId = imeScCaseRTId, 
                                  OwnerId = usrId,
                                  AccountId = ca.IM_Account__c,
                                  Customer_ID__c = ca.Id,
                                  Origin = 'NAS_EM_Orders',
                                  Cut_Off__c='Rush',
                                  Order_team__C = 'Honeywell',   
                                  Description = 'Test',
                                  Priority = 'Low',
                                  NAS_Order_Number__c = '8990',
                                  ContactId= cnt.Id,
                                  NAS_Service_Line_Associated_to_Ask__c='Data Management',
                                  End_Time_Cutoff_SLA__c=system.now(),
                                  IME_SC_Category__c = 'Contract Issues',
                                  IME_SC_Sub_Category__c = 'Contract Remediation',
                                  IME_SC_Customer_AccountId__c = ca.id,
                                  IME_SC_Case_Cause__c='Finance',
                                  Status='Closed');
        casesToInsert.add(imeScCase);
        
        Case imeScResolvedCase = new Case(Subject = 'Test IME SC Resolved Case', RecordTypeId = imeScCaseResolvedRTId, 
                                          OwnerId = usrId,
                                          AccountId = ca.IM_Account__c,
                                          Customer_ID__c = ca.Id,
                                          Origin = 'NAS_EM_Orders',
                                          Cut_Off__c='Rush',
                                          Order_team__C = 'Honeywell',   
                                          Description = 'Test',
                                          Priority = 'Low',
                                          NAS_Order_Number__c = '8990',
                                          ContactId= cnt.Id,
                                          NAS_Service_Line_Associated_to_Ask__c='Data Management',
                                          Status='Closed');
        casesToInsert.add(imeScResolvedCase);

        Case standardCase = new Case(Subject = 'Test Standard Case', RecordTypeId = standardCaseRTId, 
                                     OwnerId = usrId,
                                     AccountId = ca.IM_Account__c,
                                     Customer_ID__c = ca.Id,
                                     Origin = 'NAS_EM_Orders',
                                     Cut_Off__c='Rush',
                                     Order_team__C = 'Honeywell',   
                                     Description = 'Test',
                                     Priority = 'Low',
                                     NAS_Order_Number__c = '8990',
                                     ContactId= cnt.Id,
                                     NAS_Service_Line_Associated_to_Ask__c='Data Management',
                                     Status='cancelled');
        casesToInsert.add(standardCase);

        // --- INSERT Cases and Check Results ---
        Database.SaveResult[] caseResults = Database.insert(casesToInsert, false); // Allow partial success

        for (Integer i = 0; i < caseResults.size(); i++) {
            if (caseResults[i].isSuccess()) {
                System.debug('DEBUG: Case inserted successfully: ' + casesToInsert[i].Subject + ' Id: ' + casesToInsert[i].Id);
            } else {
                System.debug('ERROR: Failed to insert Case: ' + casesToInsert[i].Subject);
                for (Database.Error err : caseResults[i].getErrors()) {
                    System.debug('ERROR: Field: ' + err.getFields() + ', Message: ' + err.getMessage() + ', Status: ' + err.getStatusCode());
                }
            }
        }
        // Query back the cases to ensure they are available for later use
        // Only query cases that were successfully inserted
        List<Case> successfullyInsertedCases = [SELECT Id, Subject, RecordTypeId FROM Case WHERE Id IN :casesToInsert AND Id != NULL];
        System.debug('DEBUG: Successfully inserted cases count: ' + successfullyInsertedCases.size());
        
        // Create EmailMessages associated with Cases
        EmailMessage imeScEmail = new EmailMessage(
            Subject = 'Email for IME SC Case',
            HtmlBody = 'Test Email',
            ParentId = imeScCase.Id,
            Status = '0' // Draft
        );
        insert imeScEmail;

        EmailMessage imeScResolvedEmail = new EmailMessage(
            Subject = 'Email for IME SC Resolved Case',
            HtmlBody = 'Test Email',
            ParentId = imeScResolvedCase.Id,
            Status = '0' // Draft
        );
        insert imeScResolvedEmail;

        EmailMessage standardCaseEmail = new EmailMessage(
            Subject = 'Email for Standard Case',
            HtmlBody = 'Test Email',
            ParentId = standardCase.Id,
            Status = '0' // Draft
        );
        insert standardCaseEmail;

        // Create Attachments for EmailMessages
        Attachment emailAttachmentIME = new Attachment(
            ParentId = imeScEmail.Id,
            Name = 'TestEmailAttachmentIME.txt',
            Body = Blob.valueOf('Test Content')
        );
        insert emailAttachmentIME;

        Attachment emailAttachmentIMEResolved = new Attachment(
            ParentId = imeScResolvedEmail.Id,
            Name = 'TestEmailAttachmentIMEResolved.txt',
            Body = Blob.valueOf('Test Content')
        );
        insert emailAttachmentIMEResolved;

        Attachment emailAttachmentStandard = new Attachment(
            ParentId = standardCaseEmail.Id,
            Name = 'TestEmailAttachmentStandard.txt',
            Body = Blob.valueOf('Test Content')
        );
        insert emailAttachmentStandard;

        // Create a non-email attachment for a Case
        Attachment caseAttachment = new Attachment(
            ParentId = imeScCase.Id,
            Name = 'TestCaseAttachment.txt',
            Body = Blob.valueOf('Test Content')
        );
        insert caseAttachment;

        // Create an attachment with null parentId (should be skipped by trigger)
        Attachment nullParentAttachment = new Attachment(
            Name = 'NullParentAttachment.txt',
            Body = Blob.valueOf('Test Content')
        );
    }
    // Helper method to update trigger activation setting
     private static void setTriggerActivationSetting(String triggerName, String value) {
        // Query the existing setting. In this setup, there should only be one for 'IRM_SC_Attachmentdeletion'.
        Trigger_Activation_Settings__c tas = [SELECT Id, Value__c FROM Trigger_Activation_Settings__c WHERE Trigger__c = :triggerName LIMIT 1];
        if (tas != null) {
            tas.Value__c = value;
            update tas;
        }
    }

    // Helper to create a fresh IME email attachment
    private static Attachment createIMEAttachment(String nameSuffix, Id parentCaseId) {
        System.debug('DEBUG_CREATE: Calling createIMEAttachment for suffix: ' + nameSuffix + ' with Parent Case ID: ' + parentCaseId);
        
        if (parentCaseId == null) {
            System.debug('ERROR: In createIMEAttachment, parentCaseId is null. Cannot create attachment.');
            return null;
        }
        
        EmailMessage imeScEmail = new EmailMessage(Subject = 'Email for IME SC Case ' + nameSuffix, HtmlBody = 'Test', ParentId = parentCaseId, Status = '0');
        insert imeScEmail;
        Attachment newAtt = new Attachment(ParentId = imeScEmail.Id, Name = 'TestEmailAttachmentIME_' + nameSuffix + '.txt', Body = Blob.valueOf('New Content'));
        insert newAtt;
        System.debug('DEBUG_CREATE: Created Attachment: ' + newAtt.Id);
        return newAtt;
    }


    @isTest
    static void testBlockingScenario() {
        // --- Setup for non-archiver user ---
        User nonArchiverUser = TestingUtils.createUser('nAu', true); // Ensure profile is NOT in Email_Archive_Profiles

        Test.startTest();
        // The custom setting `IRM_SC_Attachmentdeletion` is already 'TRUE' from @testSetup
        // and the user is a non-archiver, so deletion should be blocked.

        System.runAs(nonArchiverUser) {
            // Retrieve attachments (these were created in setupTestData)
            Attachment attachmentIME = [SELECT Id FROM Attachment WHERE Name = 'TestEmailAttachmentIME.txt' LIMIT 1];
            Attachment attachmentIMEResolved = [SELECT Id FROM Attachment WHERE Name = 'TestEmailAttachmentIMEResolved.txt' LIMIT 1];
            Attachment attachmentStandard = [SELECT Id FROM Attachment WHERE Name = 'TestEmailAttachmentStandard.txt' LIMIT 1];
            Attachment caseAttachment = [SELECT Id FROM Attachment WHERE Name = 'TestCaseAttachment.txt' LIMIT 1];

            // Attempt to delete IME SC Case email attachment (should be blocked)
            Database.DeleteResult resultIME = Database.delete(attachmentIME, false);
            System.assert(!resultIME.isSuccess(), 'IME SC Case email attachment deletion should be blocked.');
            System.assertEquals(System.Label.IME_SC_AttachmentDeletion, resultIME.getErrors()[0].getMessage());

            // Attempt to delete IME SC Resolved Case email attachment (should be blocked)
            Database.DeleteResult resultIMEResolved = Database.delete(attachmentIMEResolved, false);
            System.assert(!resultIMEResolved.isSuccess(), 'IME SC Resolved Case email attachment deletion should be blocked.');
            System.assertEquals(System.Label.IME_SC_AttachmentDeletion, resultIMEResolved.getErrors()[0].getMessage());

            // Attempt to delete Standard Case email attachment (should be allowed)
            Database.DeleteResult resultStandard = Database.delete(attachmentStandard, false);
            System.assert(resultStandard.isSuccess(), 'Standard Case email attachment deletion should be allowed.');
            System.assert(resultStandard.getErrors().isEmpty(), 'Standard Case email attachment should not have errors.');

            // Attempt to delete non-email attachment (should be allowed)
            Database.DeleteResult resultCaseAttachment = Database.delete(caseAttachment, false);
            System.assert(resultCaseAttachment.isSuccess(), 'Non-email attachment deletion should be allowed.');
            System.assert(resultCaseAttachment.getErrors().isEmpty(), 'Non-email attachment should not have errors.');
        } 
        Test.stopTest(); // End of this test method's test block
    }

/*   
    @isTest
    static void testArchiverAllowedScenario() {
        // --- Setup for archiver user ---
        User archiverUser = TestingUtil.createUser(); // Ensure profile IS in Email_Archive_Profiles

        Test.startTest();
        // The custom setting `IRM_SC_Attachmentdeletion` is already 'TRUE' from @testSetup
        // The user is an archiver, so deletion should be allowed.

        // Create a NEW attachment for this test, using the stored Case ID.
        Attachment attachmentIME_Archiver = createIMEAttachment('Archiver', imeScCaseForHelper.Id);
        System.assertNotEquals(null, attachmentIME_Archiver, 'IME Archiver Attachment should have been created.');

        System.runAs(archiverUser) {
            // Attempt to delete IME SC Case email attachment (should be allowed for archiver)
            Database.DeleteResult resultIME_Archiver = Database.delete(attachmentIME_Archiver, false);
            System.assert(resultIME_Archiver.isSuccess(), 'IME SC Case email attachment deletion should be allowed for archiver.');
            System.assert(resultIME_Archiver.getErrors().isEmpty(), 'IME SC Case email attachment should not have errors for archiver.');
        }
        Test.stopTest(); // End of this test method's test block
    }

    @isTest
    static void testSettingInactiveScenario() {
        Test.startTest();
        // Create NEW attachments for these tests using the stored Case ID.
        Attachment attachmentIME_False = createIMEAttachment('FalseSetting', imeScCaseForHelper.Id);
        System.assertNotEquals(null, attachmentIME_False, 'IME FalseSetting Attachment should have been created.');

        Attachment attachmentIME_NoSetting = createIMEAttachment('NoSetting', imeScCaseForHelper.Id);
        System.assertNotEquals(null, attachmentIME_NoSetting, 'IME NoSetting Attachment should have been created.');
        
        // --- Scenario A: Trigger inactive (deleteAttachment = FALSE) ---
        setTriggerActivationSetting('IRM_SC_Attachmentdeletion', 'FALSE');

        Database.DeleteResult resultIME_False = Database.delete(attachmentIME_False, false);
        System.assert(resultIME_False.isSuccess(), 'IME SC Case email attachment deletion should be allowed when setting is FALSE.');
        System.assert(resultIME_False.getErrors().isEmpty(), 'No errors expected when setting is FALSE.');

        // --- Scenario B: No matching custom setting (deleteAttachment = null) ---
        List<Trigger_Activation_Settings__c> existingSettings = [SELECT Id FROM Trigger_Activation_Settings__c WHERE Trigger__c = 'IRM_SC_Attachmentdeletion' LIMIT 1];
        if (!existingSettings.isEmpty()) {
            delete existingSettings;
        }

        Database.DeleteResult resultNoSetting = Database.delete(attachmentIME_NoSetting, false);
        System.assert(resultNoSetting.isSuccess(), 'Deletion should be allowed when no matching custom setting is found.');
        System.assert(resultNoSetting.getErrors().isEmpty(), 'No errors expected when no matching custom setting.');

        Test.stopTest();
    }
*/
}
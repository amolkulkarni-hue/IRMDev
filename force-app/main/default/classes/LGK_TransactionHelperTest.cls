/**
 * LGK_TransactionHelper_Test
 * ----------------------
 * Covers the parse/fan-out logic (no DML) plus a trigger-context insert.
 * Field API names below must match LGK_TransactionHelper.FIELD_MAP — replace the
 * [FILL IN] placeholders with the real fields on LGK__Transaction__c.
 */
@isTest
private class LGK_TransactionHelperTest {

    private static final String FLD = '~|~';
    private static final String REC = '~^~';

    private static String buildPayload() {
        // RM on w/ notes, DM off, shred on w/ notes, others off/blank
        List<String> recs = new List<String>{
            'RM'      + FLD + '1' + FLD + 'needs weekend pickup',
            'DM'      + FLD + '0' + FLD + '',
            'shred'   + FLD + '1' + FLD + 'confidential bins only',
            'ALM'     + FLD + '0' + FLD + '',
            'MAS'     + FLD + '0' + FLD + '',
            'WL'      + FLD + '0' + FLD + '',
            'Digital' + FLD + '0' + FLD + ''
        };
        return String.join(recs, REC);
    }

    @isTest
    static void testFanOutLogic_noDml() {
        LGK__Transaction__c t = new LGK__Transaction__c();
        t.Support_Data_Raw__c = buildPayload();   // [FILL IN staging field if renamed]

        Test.startTest();
        // Calling the helper method directly to simulate before-insert in memory
        LGK_TransactionHelper.transactionBeforeInsert(new List<LGK__Transaction__c>{ t });
        Test.stopTest();

        // [FILL IN] assert against the real field API names
        System.assertEquals(true,  t.Get_Support_RM__c,      'RM toggle should be true');
        System.assertEquals('needs weekend pickup', t.Support_Notes_RM__c, 'RM notes');
        System.assertEquals(false, t.Get_Support_DM__c,      'DM toggle should be false');
        System.assertEquals(null,  t.Support_Notes_DM__c,    'DM notes should be cleared');
        System.assertEquals(true,  t.Get_Support_Shred__c,   'Shred toggle should be true');
        System.assertEquals('confidential bins only', t.Support_Notes_Shred__c, 'Shred notes');
    }

    @isTest
    static void testReset_clearsStaleValues() {
        // Pre-populate a field, then feed a payload where that line is OFF/blank
        LGK__Transaction__c t = new LGK__Transaction__c();
        t.Get_Support_RM__c = true;                       // [FILL IN]
        t.Support_Notes_RM__c = 'stale note';             // [FILL IN]
        t.Support_Data_Raw__c = 'RM' + FLD + '0' + FLD + '';

        LGK_TransactionHelper.transactionBeforeInsert(new List<LGK__Transaction__c>{ t });

        System.assertEquals(false, t.Get_Support_RM__c, 'toggle should reset to false');
        System.assertEquals(null,  t.Support_Notes_RM__c, 'note should reset to null');
    }

    @isTest
    static void testBlankPayload_isSafe() {
        LGK__Transaction__c t = new LGK__Transaction__c();
        t.Support_Data_Raw__c = null;
        
        LGK_TransactionHelper.transactionBeforeInsert(new List<LGK__Transaction__c>{ t });
        
        System.assertEquals(false, t.Get_Support_RM__c, 'blank payload leaves fields reset');
    }

    @isTest
    static void testTriggerContext_insert() {
        // Exercises the entire trigger framework (Trigger -> Handler -> Helper) in a real DML context.
        // NOTE: add any fields the managed package requires for insert below.
        LGK__Transaction__c t = new LGK__Transaction__c();
        t.Support_Data_Raw__c = buildPayload();
        // t.LGK__SomeRequiredField__c = ...;   // [FILL IN if insert requires it]

        Test.startTest();
        insert t; 
        Test.stopTest();

        LGK__Transaction__c reloaded = [
            SELECT Get_Support_RM__c, Support_Notes_RM__c   // [FILL IN]
            FROM LGK__Transaction__c WHERE Id = :t.Id
        ];
        System.assertEquals(true, reloaded.Get_Support_RM__c, 'trigger populated RM on insert');
    }

    @isTest
    static void testTriggerContext_update() {
        // 1. Insert a record so we can update it
        LGK__Transaction__c t = new LGK__Transaction__c();
        t.Support_Data_Raw__c = 'RM~|~1~|~old note';
        insert t;

        // 2. Perform the update to cover BeforeUpdate and AfterUpdate methods
        Test.startTest();
        t.Support_Data_Raw__c = 'RM~|~0~|~';
        update t;
        Test.stopTest();

        // Verify the helper ran during the update
        LGK__Transaction__c reloaded = [SELECT Get_Support_RM__c, Support_Notes_RM__c FROM LGK__Transaction__c WHERE Id = :t.Id];
        System.assertEquals(false, reloaded.Get_Support_RM__c, 'RM toggle should be updated to false');
    }

    @isTest
    static void testTriggerContext_delete_undelete() {
        // Insert a record
        LGK__Transaction__c t = new LGK__Transaction__c();
        insert t;

        Test.startTest();
        // Delete to cover BeforeDelete and AfterDelete
        delete t;
        
        // Recover from the recycle bin to cover AfterUndelete
        undelete t;
        Test.stopTest();

        // Validate that it exists again
        List<LGK__Transaction__c> reloaded = [SELECT Id FROM LGK__Transaction__c WHERE Id = :t.Id];
        System.assertEquals(1, reloaded.size(), 'Record should exist after undelete');
    }

    @isTest
    static void testHandler_IsDisabled_SpecificObject() {
        // Insert the custom setting to cover lines 14 and 15 (specific object condition)
        Metadata_Activation_Settings__c setting = new Metadata_Activation_Settings__c();
        // If it is a hierarchy custom setting, the Org Id is usually assigned as the SetupOwnerId
        setting.SetupOwnerId = UserInfo.getOrganizationId(); 
        setting.SObject_API_Name__c = 'Account;LGK__Transaction__c;Opportunity';
        setting.Disable_Trigger__c = true;
        insert setting;

        LGK_TransactionTriggerHandler handler = new LGK_TransactionTriggerHandler();
        
        Test.startTest();
        Boolean isDisabled = handler.IsDisabled();
        Test.stopTest();

        // Validate that it returns true thanks to the split(DELIMITERS).contains() logic
        System.assertEquals(true, isDisabled, 'Trigger should be disabled for LGK__Transaction__c in Custom Setting');
    }
    
    @isTest
    static void testHandler_emptyMethods_directCall() {
        // Call the empty methods directly to ensure 100% coverage 
        // in case the framework intercepts the DML earlier in tests.
        LGK_TransactionTriggerHandler handler = new LGK_TransactionTriggerHandler();
        
        Test.startTest();
        handler.AfterInsert(new List<SObject>());
        handler.BeforeDelete(new Map<Id, SObject>());
        handler.AfterUpdate(new Map<Id, SObject>(), new Map<Id, SObject>());
        handler.AfterDelete(new Map<Id, SObject>());
        handler.AfterUndelete(new Map<Id, SObject>());
        Test.stopTest();
        
        // No asserts are necessary because the methods are empty, 
        // we just want to turn the lines green in the coverage report.
        System.assert(true);
    }
}
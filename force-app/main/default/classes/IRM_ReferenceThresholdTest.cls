/**
 * IRM_ReferenceThresholdTest
 * Reference_Threshold_Key_Flow: Unique_Key__c auto-generated on insert and update
 *
 * Flow under test: Reference_Threshold_Key_Flow (Before Save — Reference_Threshold__c)
 * Must be ACTIVE in Setup → Flows before running.
 *
 * Key formula: Financial_Year__c + '_' + Region__c + '_' + Cluster__c + '_' + Country__c + '_' + Volume_Profile__c
 *
 * Cluster__c valid values (restricted picklist): ANZ, APAC, CSE, DACH, France, India,
 *   LATAM, MENAT, NE, RUCIS, South Africa, UKI, WE
 * Tests use: NE (AMER cluster), WE (EMEA cluster), ANZ (APAC cluster)
 */
@IsTest
private class IRM_ReferenceThresholdTest {

    // ── Key generated on insert ───────────────────────────────────────────────

    @IsTest
    static void test_keyGeneratedOnInsert() {
        System.debug('TEST: Inserting Reference_Threshold__c with FY=FY2026, Region=AMER, Cluster=NE, Country=USA, Volume=Large. Expect Unique_Key__c populated.');

        Test.startTest();
        Reference_Threshold__c rt = new Reference_Threshold__c(
            Name = 'Test Threshold',
            Financial_Year__c = 'FY2026',
            Region__c         = 'APAC',
            Cluster__c        = 'NE',
            Country__c        = 'Australia',
            Volume_Profile__c = 'High Volume / High Value',
            Large_Deal__c     = 100000
        );
        insert rt;
        Test.stopTest();

        Reference_Threshold__c r = [SELECT Id, Unique_Key__c FROM Reference_Threshold__c WHERE Id = :rt.Id];
        System.debug('RESULT: Unique_Key__c=' + r.Unique_Key__c);

        System.assertNotEquals(null, r.Unique_Key__c,
            'Reference_Threshold_Key_Flow: Unique_Key__c should be auto-populated on insert. Got null. '
            + 'Check flow is active and Before Save fires on Reference_Threshold__c.');

        System.assert(r.Unique_Key__c.contains('FY2026'),
            'Key should contain FY2026. Got: ' + r.Unique_Key__c);
        System.assert(r.Unique_Key__c.contains('APAC'),
            'Key should contain APAC. Got: ' + r.Unique_Key__c);
        System.assert(r.Unique_Key__c.contains('NE'),
            'Key should contain NE (valid APAC cluster value). Got: ' + r.Unique_Key__c);
        System.assert(r.Unique_Key__c.contains('Australia'),
            'Key should contain USA. Got: ' + r.Unique_Key__c);
        System.assert(r.Unique_Key__c.contains('High_Volume'),
            'Key should contain High_Volume (from High Volume / High Value). Got: ' + r.Unique_Key__c);
    }

    // ── Key updates when a field changes ─────────────────────────────────────

    @IsTest
    static void test_keyUpdatesOnFinancialYearChange() {
        Reference_Threshold__c rt = new Reference_Threshold__c(
            Name = 'Key Update Test',
            Financial_Year__c = 'FY2025', Region__c = 'Europe',
            Cluster__c = 'WE', Country__c = 'United Kingdom', Volume_Profile__c = 'High Volume / Low Value',
            Large_Deal__c = 100000
        );
        insert rt;

        Reference_Threshold__c before = [SELECT Unique_Key__c FROM Reference_Threshold__c WHERE Id = :rt.Id];
        System.debug('PRE-UPDATE: Unique_Key__c=' + before.Unique_Key__c);

        Test.startTest();
        rt.Financial_Year__c = 'FY2026';
        update rt;
        Test.stopTest();

        Reference_Threshold__c r = [SELECT Unique_Key__c FROM Reference_Threshold__c WHERE Id = :rt.Id];
        System.debug('POST-UPDATE: Unique_Key__c=' + r.Unique_Key__c + ' (expect FY2026, not FY2025)');

        System.assert(r.Unique_Key__c.contains('FY2026'),
            'Key should reflect updated Financial_Year__c=FY2026. Got: ' + r.Unique_Key__c);
        System.assert(!r.Unique_Key__c.contains('FY2025'),
            'Old Financial_Year__c=FY2025 should not appear in updated key. Got: ' + r.Unique_Key__c);
    }

    @IsTest
    static void test_keyUpdatesOnRegionChange() {
        Reference_Threshold__c rt = new Reference_Threshold__c(
            Name = 'Region Update Test',
            Financial_Year__c = 'FY2026', Region__c = 'APAC',
            Cluster__c = 'ANZ', Country__c = 'New Zealand', Volume_Profile__c = 'Low Volume / Low Value',
            Large_Deal__c = 100000
        );
        insert rt;

        Reference_Threshold__c before = [SELECT Unique_Key__c FROM Reference_Threshold__c WHERE Id = :rt.Id];
        System.debug('PRE-UPDATE: Unique_Key__c=' + before.Unique_Key__c);

        Test.startTest();
        rt.Region__c = 'Europe';
        update rt;
        Test.stopTest();

        Reference_Threshold__c r = [SELECT Unique_Key__c FROM Reference_Threshold__c WHERE Id = :rt.Id];
        System.debug('POST-UPDATE: Unique_Key__c=' + r.Unique_Key__c);

        System.assert(r.Unique_Key__c.contains('Europe'),
            'Key should reflect updated Region__c=Europe. Got: ' + r.Unique_Key__c);
    }

    // ── Unique constraint enforced ────────────────────────────────────────────

    @IsTest
    static void test_duplicateKeyRejected() {
        insert new Reference_Threshold__c(
            Name = 'Original',
            Financial_Year__c = 'FY2026', Region__c = 'APAC',
            Cluster__c = 'NE', Country__c = 'Australia', Volume_Profile__c = 'High Volume / High Value',
            Large_Deal__c = 100000
        );

        Reference_Threshold__c first = [SELECT Unique_Key__c FROM Reference_Threshold__c LIMIT 1];
        System.debug('FIRST RECORD Unique_Key__c=' + first.Unique_Key__c);
        System.debug('TEST: Inserting second record with identical field values. Expect DML exception due to unique Unique_Key__c.');

        Test.startTest();
        Boolean rejected = false;
        String errorMsg = '';
        try {
            insert new Reference_Threshold__c(
                Name = 'Duplicate',
                Financial_Year__c = 'FY2026', Region__c = 'APAC',
                Cluster__c = 'NE', Country__c = 'Australia', Volume_Profile__c = 'High Volume / High Value',
                Large_Deal__c = 100000
            );
        } catch (DmlException e) {
            rejected = true;
            errorMsg = e.getMessage();
            System.debug('EXCEPTION CAUGHT (expected): ' + errorMsg);
        }
        Test.stopTest();

        System.debug('RESULT: rejected=' + rejected);

        System.assertEquals(true, rejected,
            'Unique_Key__c is a unique field — duplicate combination should be rejected. '
            + 'If not rejected, check Unique_Key__c field has Unique=true on Reference_Threshold__c. Got error: ' + errorMsg);
    }

    // ── Different combinations produce different keys ─────────────────────────

    @IsTest
    static void test_differentCombinationsProduceDifferentKeys() {
        Test.startTest();
        // NE = valid AMER cluster; WE = valid EMEA cluster
        Reference_Threshold__c rt1 = new Reference_Threshold__c(
            Name = 'RT1', Financial_Year__c = 'FY2026', Region__c = 'APAC',
            Cluster__c = 'NE', Country__c = 'Australia', Volume_Profile__c = 'High Volume / High Value',
            Large_Deal__c = 100000
        );
        Reference_Threshold__c rt2 = new Reference_Threshold__c(
            Name = 'RT2', Financial_Year__c = 'FY2026', Region__c = 'Europe',
            Cluster__c = 'WE', Country__c = 'United Kingdom', Volume_Profile__c = 'Low Volume / High Value',
            Large_Deal__c = 200000
        );
        insert rt1;
        insert rt2;
        Test.stopTest();

        Reference_Threshold__c r1 = [SELECT Unique_Key__c FROM Reference_Threshold__c WHERE Id = :rt1.Id];
        Reference_Threshold__c r2 = [SELECT Unique_Key__c FROM Reference_Threshold__c WHERE Id = :rt2.Id];

        System.debug('RT1 Unique_Key__c=' + r1.Unique_Key__c);
        System.debug('RT2 Unique_Key__c=' + r2.Unique_Key__c);

        System.assertNotEquals(r1.Unique_Key__c, r2.Unique_Key__c,
            'Two records with different field combinations should produce different Unique_Key__c values. '
            + 'RT1=' + r1.Unique_Key__c + ' | RT2=' + r2.Unique_Key__c);
    }
}
/**
 * IRM_OppAutoNameTest
 * US-AUTONAME: Opportunity Auto-Name on Create and TBD Recalculation on Update
 *
 * Flows under test:
 *   Opportunity_Auto_Name_Create_Flow (Before Save, Create)
 *   Opportunity_Auto_Name_Update_Flow (Before Save, Update — fires when Name contains TBD)
 * Invocable under test: IRM_OppNamingAction
 *
 * Note: Sales_Region__c is a read-only formula field in this org — its value is system-derived
 * and will resolve to TBD in the auto-generated name for test records.
 * Opp_Naming_Segment__c records are inserted in @TestSetup (custom object, DML allowed).
 * Both flows must be Active in Setup → Flows before running.
 */
@IsTest
private class IRM_OppAutoNameTest {

    @TestSetup
    static void setup() {
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );
        insert new Country_Settings__c(
            Name = 'United States', Object_Name__c = 'Opportunity',
            SetupOwnerId = UserInfo.getOrganizationId()
        );
        insert new List<Opportunity_Security__c>{
            new Opportunity_Security__c(Name = 'Primary CDE',         Field_Name__c = 'Primary_CDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Original Lead Owner', Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Primary BDE',         Field_Name__c = 'Primary_BDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
        };
        insert new OpportunityProductSelection__c(
            Name = 'CloudSolutionsProduct', Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions'
        );
        insert new List<SVStatus__c>{
            new SVStatus__c(Name = 'New Deal',  Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Renewal',   Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Add-On',    Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Expansion', Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId())
        };

        Account acc = new Account(
            Name = 'IRM Auto Name Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;

        // Naming segment config — mirrors the production seed data
        insert new List<Opp_Naming_Segment__c>{
            new Opp_Naming_Segment__c(Order__c = 1, Field_API_Name__c = '__ACCOUNT_NAME__', Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'),
            new Opp_Naming_Segment__c(Order__c = 2, Field_API_Name__c = '__QUARTER_YEAR__', Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'),
            new Opp_Naming_Segment__c(Order__c = 3, Field_API_Name__c = 'Type',             Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'),
            new Opp_Naming_Segment__c(Order__c = 4, Field_API_Name__c = 'Business_Unit__c', Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'),
            new Opp_Naming_Segment__c(Order__c = 5, Field_API_Name__c = 'Sales_Region__c',  Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All')
        };
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static Account getAccount() {
        return [SELECT Id, Name FROM Account LIMIT 1];
    }

    private static Id getStandardOppRTId() {
        return [SELECT Id FROM RecordType WHERE DeveloperName = 'Standard_Opportunity' AND SObjectType = 'Opportunity'].Id;
    }

    private static Id getFrameworkOppRTId() {
        Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName().get('Framework_Parent_Opportunity');
        if (rtInfo == null || !rtInfo.isAvailable()) { return null; }
        return rtInfo.getRecordTypeId();
    }

    private static String expectedQtrYear() {
        Integer q = (Integer) Math.ceil(Date.today().month() / 3.0);
        return 'Q' + q + ' ' + Date.today().year();
    }

    // ── US-AUTONAME AC1/AC2: Name auto-generated on Create — Standard RT ──

    @IsTest
    static void test_autoNameOnCreate_StandardRT() {
        Account acc = getAccount();
        Id rtId = getStandardOppRTId();
        // Sales_Region__c is read-only (formula) — will be blank → TBD in name
        String expectedName = acc.Name + ' – ' + expectedQtrYear() + ' – New – Digital – TBD';

        Test.startTest();
        Opportunity opp = new Opportunity(
            AccountId = acc.Id, Name = 'placeholder',
            RecordTypeId = rtId, StageName = 'Qualification', CloseDate = Date.today().addDays(30),
            Type = 'New', Business_Unit__c = 'Digital'
        );
        insert opp;
        Test.stopTest();

        Opportunity created = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(expectedName, created.Name,
            'US-AUTONAME AC1: Name should be auto-generated on Create for Standard_Opportunity RT. Got: ' + created.Name);
    }

    // ── US-AUTONAME: Name auto-generated on Create — Framework RT ────────

    @IsTest
    static void test_autoNameOnCreate_FrameworkRT() {
        Account acc = getAccount();
        Id rtId = getFrameworkOppRTId();
        if (rtId == null) {
            // Framework_Parent_Opportunity RT not available to running user's profile — skip
            System.assert(true, 'Framework_Parent_Opportunity RT not accessible; test skipped.');
            return;
        }
        String expectedName = acc.Name + ' – ' + expectedQtrYear() + ' – Framework – RIM – TBD';

        Test.startTest();
        Opportunity opp = new Opportunity(
            AccountId = acc.Id, Name = 'placeholder',
            RecordTypeId = rtId, StageName = 'Qualification', CloseDate = Date.today().addDays(30),
            Type = 'Framework', Business_Unit__c = 'RIM'
        );
        insert opp;
        Test.stopTest();

        Opportunity created = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(expectedName, created.Name,
            'US-AUTONAME: Framework_Parent_Opportunity RT should also auto-generate Name. Got: ' + created.Name);
    }

    // ── US-AUTONAME AC3: TBD placeholder when fields blank on Create ──────

    @IsTest
    static void test_tbdPlaceholderWhenFieldsBlank() {
        Account acc = getAccount();
        Id rtId = getStandardOppRTId();

        Test.startTest();
        Opportunity opp = new Opportunity(
            AccountId = acc.Id, Name = 'placeholder',
            RecordTypeId = rtId, StageName = 'Qualification', CloseDate = Date.today().addDays(30)
            // Type and Business_Unit__c intentionally blank
        );
        insert opp;
        Test.stopTest();

        Opportunity created = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        System.debug('TEST: Name with blank fields=' + created.Name);
        System.assert(created.Name.startsWith(acc.Name),
            'US-AUTONAME AC3: Name should start with Account Name. Got: ' + created.Name);
        System.assert(created.Name.contains('TBD'),
            'US-AUTONAME AC3: Blank segments should produce TBD placeholders. Got: ' + created.Name);
    }

    // ── US-AUTONAME: Other record types are NOT auto-named ───────────────

    @IsTest
    static void test_otherRecordTypeNotAutoNamed() {
        Account acc = getAccount();
        RecordType otherRT = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Opportunity'
              AND DeveloperName != 'Standard_Opportunity'
              AND DeveloperName != 'Framework_Parent_Opportunity'
            LIMIT 1
        ];

        Test.startTest();
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name = 'My Custom Name Should Not Change',
            RecordTypeId = otherRT.Id,
            StageName = 'Qualification', CloseDate = Date.today().addDays(30)
        );
        insert opp;
        Test.stopTest();

        Opportunity created = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('My Custom Name Should Not Change', created.Name,
            'US-AUTONAME: Non-target record types should not be auto-named. Got: ' + created.Name);
    }

    // ── US-AUTONAME AC4: Update recalculates Name when TBD present ───────

    @IsTest
    static void test_recalculatesOnUpdateWhenTBDPresent() {
        Account acc = getAccount();
        Id rtId = getStandardOppRTId();

        // Create with blank Type → TBD in name
        Opportunity opp = new Opportunity(
            AccountId = acc.Id, Name = 'placeholder',
            RecordTypeId = rtId, StageName = 'Qualification', CloseDate = Date.today().addDays(30),
            Business_Unit__c = 'Digital'
        );
        insert opp;
        Opportunity afterCreate = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        System.assert(afterCreate.Name.contains('TBD'),
            'Precondition: blank Type should produce TBD in Name. Got: ' + afterCreate.Name);

        // Fill in Type — update flow should recalculate
        Test.startTest();
        afterCreate.Type = 'New';
        update afterCreate;
        Test.stopTest();

        Opportunity afterUpdate = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        String expectedName = acc.Name + ' – ' + expectedQtrYear() + ' – New – Digital – TBD';
        System.assertEquals(expectedName, afterUpdate.Name,
            'US-AUTONAME AC4: Name should be recalculated after filling in Type while TBD is present. Got: ' + afterUpdate.Name);
    }

    // ── US-AUTONAME AC5: Manual override is preserved on update ──────────

    @IsTest
    static void test_manualOverridePreservedOnUpdate() {
        Account acc = getAccount();
        Id rtId = getStandardOppRTId();

        // Create (auto-generates name with TBD for region since Sales_Region__c is read-only)
        Opportunity opp = new Opportunity(
            AccountId = acc.Id, Name = 'placeholder',
            RecordTypeId = rtId, StageName = 'Qualification', CloseDate = Date.today().addDays(30),
            Type = 'New', Business_Unit__c = 'Digital'
        );
        insert opp;

        // Manually override Name (no TBD — seller takes ownership)
        Opportunity afterCreate = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        String manualName = 'Iron Mountain Corp Enterprise Deal 2026';
        afterCreate.Name = manualName;
        // Note: we intentionally do NOT change Type here to avoid unrelated SVStatus trigger issues.
        // The test purpose is purely to verify that a Name without TBD is NOT recalculated.

        Test.startTest();
        update afterCreate;
        Test.stopTest();

        Opportunity afterUpdate = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(manualName, afterUpdate.Name,
            'US-AUTONAME AC5: Manual override (no TBD) should be preserved and not recalculated. Got: ' + afterUpdate.Name);
    }

    // ── US-AUTONAME: Inactive segments are excluded ───────────────────────

    @IsTest
    static void test_inactiveSegmentExcluded() {
        Account acc = getAccount();
        Id rtId = getStandardOppRTId();

        // Deactivate the Business_Unit__c segment
        Opp_Naming_Segment__c buSeg = [
            SELECT Id FROM Opp_Naming_Segment__c WHERE Field_API_Name__c = 'Business_Unit__c'
        ];
        buSeg.Is_Active__c = false;
        update buSeg;

        Test.startTest();
        Opportunity opp = new Opportunity(
            AccountId = acc.Id, Name = 'placeholder',
            RecordTypeId = rtId, StageName = 'Qualification', CloseDate = Date.today().addDays(30),
            Type = 'New', Business_Unit__c = 'Digital'
        );
        insert opp;
        Test.stopTest();

        Opportunity created = [SELECT Name FROM Opportunity WHERE Id = :opp.Id];
        System.debug('TEST: Name with BU segment deactivated=' + created.Name);
        System.assert(!created.Name.contains('Digital'),
            'US-AUTONAME: Inactive segment should be excluded from Name. Got: ' + created.Name);
        System.assert(created.Name.contains('New'),
            'US-AUTONAME: Active Type segment should still appear. Got: ' + created.Name);
    }

    // ── US-AUTONAME: IRM_OppNamingAction — direct unit test ──────────────

    @IsTest
    static void test_invocableDirectly() {
        Account acc = getAccount();
        List<Opp_Naming_Segment__c> segments = [
            SELECT Order__c, Field_API_Name__c, Fallback_Value__c
            FROM Opp_Naming_Segment__c
            WHERE Is_Active__c = true
            ORDER BY Order__c
        ];

        Opportunity opp = new Opportunity(
            AccountId = acc.Id, Name = 'placeholder',
            StageName = 'Qualification', CloseDate = Date.today().addDays(30),
            Type = 'New', Business_Unit__c = 'Digital'
        );

        IRM_OppNamingAction.Request req = new IRM_OppNamingAction.Request();
        req.opportunity  = opp;
        req.accountName  = acc.Name;
        req.segments     = segments;

        Test.startTest();
        List<IRM_OppNamingAction.Response> responses =
            IRM_OppNamingAction.buildName(new List<IRM_OppNamingAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Should return exactly one response.');
        String name = responses[0].opportunityName;
        System.debug('TEST: directly built name=' + name);
        System.assert(name.startsWith(acc.Name), 'Name should start with Account Name. Got: ' + name);
        System.assert(name.contains('New'),      'Name should contain Type. Got: '         + name);
        System.assert(name.contains('Digital'),  'Name should contain BU. Got: '           + name);
    }
}
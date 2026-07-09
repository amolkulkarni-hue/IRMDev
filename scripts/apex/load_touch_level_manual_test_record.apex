// Manual/UI test data loader for Touch Level classification (v23.0 Apex recalculation).
// Run via: sf apex run --file scripts/apex/load_touch_level_manual_test_record.apex -o IRMDev
// Or paste into Developer Console > Debug > Open Execute Anonymous Window.
//
// Creates ONE reusable Opportunity you can drive by hand through the UI to see Touch Level
// calculate/recalculate live. Does NOT create any new Touch_Level_Criteria__c /
// Touch_Level_Condition__c records — it reuses the real, already-active criteria in this org
// (TLC-Q-HT-001/MT-002/LT-003 at Qualification, TLC-S-HT-001/MT-002 at Solutioning), which are
// purely Amount-driven in practice (their extra OR'd conditions reference Strategic_Account__c /
// Bid_RFP__c / Account_Segment__c, none of which exist on Opportunity in this org, so those
// branches are always false and silently skipped by the schema guard).
//
// Safe to re-run: deletes any prior run's records first (matched by name), so you can reset
// back to a clean starting state at any time.

// ── Clean up any prior run ──────────────────────────────────────────────────
delete [SELECT Id FROM Opportunity WHERE Name = 'QA Touch Level Manual Test Opp'];
delete [SELECT Id FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Name = 'QA Touch Level Test Account')];
delete [SELECT Id FROM Account WHERE Name = 'QA Touch Level Test Account'];

// ── Account ──────────────────────────────────────────────────────────────
Account acc = new Account(Name = 'QA Touch Level Test Account');
insert acc;

// ── Contacts (Champion / Economic Buyer / Problem Owner) ───────────────────
Contact champion      = new Contact(LastName = 'Champion',      FirstName = 'QA', AccountId = acc.Id);
Contact economicBuyer = new Contact(LastName = 'EconomicBuyer', FirstName = 'QA', AccountId = acc.Id);
Contact problemOwner  = new Contact(LastName = 'ProblemOwner',  FirstName = 'QA', AccountId = acc.Id);
insert new List<Contact>{ champion, economicBuyer, problemOwner };

Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

// ── Opportunity — starts at Qualification / Amount 50,000 => Low Touch ─────
// All "Qual_*_Required" stage-gate fields are pre-populated so you can freely advance the
// Stage picklist in the UI later without hitting a validation error.
Opportunity opp = new Opportunity(
    Name                               = 'QA Touch Level Manual Test Opp',
    AccountId                          = acc.Id,
    RecordTypeId                       = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
    Type                               = 'New', // NOT 'New Deal' -- see note below
    StageName                          = 'Qualification',
    CloseDate                          = Date.today().addDays(30),
    Pricebook2Id                       = standardPricebookId,
    Amount                             = 50000,
    Budget_Validated__c                = 'Yes',
    Business_Problem_Evidenced__c      = 'Improve Efficiency or Reduce Manual Work',
    Champion__c                        = champion.Id,
    Customer_Outcome_Predefined__c     = 'Reduce manual reconciliation effort.',
    Decision_Process_Defined__c        = true,
    Economic_Decision_Maker_Buyer__c   = economicBuyer.Id,
    Impact_Consequences_Identified__c  = 'No Clear Impact Identified Yet',
    Primary_Product_Line__c            = 'Secure Shredding',
    Business_Process_Problem_Owner__c  = problemOwner.Id,
    Service_Address__Street__s         = '123 Main St',
    Service_Address__City__s           = 'New York',
    Service_Address__StateCode__s      = 'NY',
    Service_Address__CountryCode__s    = 'US'
);
insert opp;

// ── Opportunity Contact Roles (org VR requires these before leaving Qualification) ──
insert new List<OpportunityContactRole>{
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = champion.Id,      Role = 'Champion'),
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = economicBuyer.Id, Role = 'Economic Decision Maker / Buyer'),
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = problemOwner.Id,  Role = 'Problem Owner')
};

Opportunity result = [SELECT Id, Name, Touch_Level__c, Touch_Level_Calculated__c, Touch_Level_Criteria_Matched__c
                       FROM Opportunity WHERE Id = :opp.Id];
System.debug('=== QA TOUCH LEVEL TEST RECORD READY ===');
System.debug('Opportunity Id: ' + result.Id);
System.debug('Touch_Level__c: ' + result.Touch_Level__c + ' (expect Low Touch)');
System.debug('Touch_Level_Calculated__c: ' + result.Touch_Level_Calculated__c);
System.debug('Touch_Level_Criteria_Matched__c: ' + result.Touch_Level_Criteria_Matched__c);
System.debug('Open in browser: /' + opp.Id);

// NOTE on Type='New': VR_Qual_ServiceAddress_Required (gated on Type IN ('New Deal','Upsell'))
// has a pre-existing platform bug that throws an internal Salesforce formula-engine error when
// evaluated on the Qualification->Solutioning stage transition. Using Type='New' avoids it.
// This is unrelated to Touch Level and was not introduced by this change -- see
// IRM_Touch_Level_SDD_Handoff.md for details.

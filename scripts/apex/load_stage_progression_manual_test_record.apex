// Manual/UI test data loader for demoing full Opportunity stage progression on a Standard
// Opportunity: Qualification -> Solutioning -> Negotiation -> Booking Verification.
// Run via: sf apex run --file scripts/apex/load_stage_progression_manual_test_record.apex -o IRMDev
// Or paste into Developer Console > Debug > Open Execute Anonymous Window.
//
// Mirrors load_touch_level_manual_test_record.apex's approach for the Qualification gate
// (all Qual_*_Required stage-gate fields pre-populated), then advances stage-by-stage with
// separate DML updates so each transition is a real, auditable stage change (LastStageChangeDate
// / OpportunityFieldHistory each update) rather than a single insert at the final stage.
//
// Bypass_Validation__c = true is set for the whole run as a safety-net bypass for any Opportunity
// validation rule this pre-populated data doesn't already satisfy -- the same sanctioned bypass
// field IRM_ExitValidationTest.makeOpp() uses to skip Opportunity-side validations during test
// setup. It is flipped back to false at the end so the resting record behaves normally in the UI
// (leaving it true would silently bypass validations for ANY future edit anyone makes to this
// record, which is not what we want for a record left behind after a demo).
//
// Safe to re-run: deletes any prior run's Opportunity first (matched by name), so you can reset
// back to a clean starting state at any time. Reuses the existing 'SummitEdge Technologies' QA
// Account/Contacts (Contact has an org-wide duplicate-name validation, so re-creating contacts
// with the same First/Last Name on a new Account fails -- these are shared, reusable test fixtures).

// ── Clean up any prior run ──────────────────────────────────────────────────
delete [SELECT Id FROM Opportunity WHERE Name = 'QA Stage Progression Manual Test Opp'];

// ── Reuse existing QA Account/Contacts (created for 006gP00000CTFG5QAP) ─────
Account acc = [SELECT Id FROM Account WHERE Name = 'SummitEdge Technologies' LIMIT 1];
Contact champion      = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND FirstName = 'QA' AND LastName = 'Champion' LIMIT 1];
Contact economicBuyer = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND FirstName = 'QA' AND LastName = 'EconomicBuyer' LIMIT 1];
Contact problemOwner  = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND FirstName = 'QA' AND LastName = 'ProblemOwner' LIMIT 1];

Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

// ── Opportunity — starts at Qualification ───────────────────────────────────
// All "Qual_*_Required" stage-gate fields are pre-populated (same recipe as the Touch Level
// test loader) so the Stage picklist can be advanced freely below without hitting a validation
// error. Bypass_Validation__c=true is the extra safety net for anything not covered by that.
Opportunity opp = new Opportunity(
    Name                               = 'QA Stage Progression Manual Test Opp',
    AccountId                          = acc.Id,
    RecordTypeId                       = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
    Type                               = 'New', // NOT 'New Deal' -- see note in Touch Level loader re: VR_Qual_ServiceAddress_Required
    StageName                          = 'Qualification',
    CloseDate                          = Date.today().addDays(30),
    Pricebook2Id                       = standardPricebookId,
    Amount                             = 500000,
    Budget_Validated__c                = 'Yes',
    Business_Problem_Evidenced__c      = 'Improve Efficiency or Reduce Manual Work',
    Customer_Outcome_Predefined__c     = 'Reduce manual reconciliation effort.',
    Decision_Process_Defined__c        = true,
    Impact_Consequences_Identified__c  = 'No Clear Impact Identified Yet',
    Primary_Product_Line__c            = 'Secure Shredding',
    Service_Address__Street__s         = '123 Main St',
    Service_Address__City__s           = 'New York',
    Service_Address__StateCode__s      = 'NY',
    Service_Address__CountryCode__s    = 'US',
    Bypass_Validation__c               = true
);
insert opp;

// ── Opportunity Contact Roles (org VR requires these before leaving Qualification) ──
insert new List<OpportunityContactRole>{
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = champion.Id,      Role = 'Champion'),
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = economicBuyer.Id, Role = 'Economic Decision Maker / Buyer'),
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = problemOwner.Id,  Role = 'Problem Owner')
};

System.debug('=== STEP 0: Qualification (insert) ===');
System.debug([SELECT StageName, LastStageChangeDate FROM Opportunity WHERE Id = :opp.Id]);

// ── Stage 2: Solutioning ─────────────────────────────────────────────────────
update new Opportunity(
    Id         = opp.Id,
    StageName  = 'Solutioning',
    NextStep   = 'Scope solution with technical team and prepare proposal'
);
System.debug('=== STEP 1: -> Solutioning ===');
System.debug([SELECT StageName, LastStageChangeDate FROM Opportunity WHERE Id = :opp.Id]);

// ── Stage 3: Negotiation ─────────────────────────────────────────────────────
// Final_Pricing_Terms_Proposed__c / Executed_Agreement_Uploaded__c populated here to match the
// field state seen on other Opportunities that have reached Negotiation cleanly in this org.
update new Opportunity(
    Id                                 = opp.Id,
    StageName                          = 'Negotiation',
    NextStep                           = 'Prepare & deliver solution proposal & pricing with executive sponsor',
    Final_Pricing_Terms_Proposed__c    = 'True',
    Executed_Agreement_Uploaded__c     = 'True'
);
System.debug('=== STEP 2: -> Negotiation ===');
System.debug([SELECT StageName, LastStageChangeDate FROM Opportunity WHERE Id = :opp.Id]);

// ── Stage 4: Booking Verification ───────────────────────────────────────────
update new Opportunity(
    Id         = opp.Id,
    StageName  = 'Booking Verification',
    NextStep   = 'Finalize booking verification checklist'
);
System.debug('=== STEP 3: -> Booking Verification ===');
System.debug([SELECT StageName, LastStageChangeDate FROM Opportunity WHERE Id = :opp.Id]);

// ── Reset Bypass_Validation__c so the resting record behaves normally in the UI ──
update new Opportunity(Id = opp.Id, Bypass_Validation__c = false);

System.debug('=== QA STAGE PROGRESSION TEST RECORD READY ===');
System.debug('Opportunity Id: ' + opp.Id);
System.debug('Open in browser: /' + opp.Id);

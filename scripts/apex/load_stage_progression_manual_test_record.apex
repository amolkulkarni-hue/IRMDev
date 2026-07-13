// Manual/UI test data loader for demoing full Opportunity stage progression on a Standard
// Opportunity: Qualification -> Solutioning -> Negotiation -> Booking Verification.
// Run via: sf apex run --file scripts/apex/load_stage_progression_manual_test_record.apex -o IRMDev
// Or paste into Developer Console > Debug > Open Execute Anonymous Window.
//
// The real stage-gate enforcement in this org is the active flow "NF Enforce Required
// Stakeholder Roles by Opportunity Stage": on any StageName change it looks up active
// Contact_Role_Requirement__mdt records for the new StageName (+ Type 'All' or matching Type)
// and blocks the save with a custom error if a required OpportunityContactRole is missing.
// Bypass_Validation__c does NOT suppress this flow (confirmed by testing) -- the only real way
// to "not hit the stage gate" is to satisfy it, so all required roles are attached to the
// Opportunity up front:
//   Qualification (Type=All):        Champion, Economic Decision Maker / Buyer, Problem Owner
//   Solutioning:                     (no requirement rows -- no contact-role gate)
//   Negotiation (Type=All):          Authorized Signatory
//   Booking Verification (Type=New): Billing Contact, Business User, Correspondence Contact
//
// Bypass_Validation__c = true is still set on insert as a safety-net for any other Opportunity
// validation rule, mirroring IRM_ExitValidationTest.makeOpp()'s sanctioned use of that field.
// Flipped back to false at the end so the resting record behaves normally in the UI.
//
// Safe to re-run: deletes any prior run's Opportunity first (matched by name), so you can reset
// back to a clean starting state at any time. Reuses the existing 'SummitEdge Technologies' QA
// Account/Contacts (created for 006gP00000CTFG5QAP) -- Contact has an org-wide duplicate-name
// validation, so re-creating contacts with the same First/Last Name on a new Account fails.

// ── Clean up any prior run ──────────────────────────────────────────────────
delete [SELECT Id FROM Opportunity WHERE Name = 'QA Stage Progression Manual Test Opp'];

// ── Reuse existing QA Account/Contacts (created for 006gP00000CTFG5QAP) ─────
Account acc = [SELECT Id FROM Account WHERE Name = 'SummitEdge Technologies' LIMIT 1];
Contact champion            = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND FirstName = 'QA' AND LastName = 'Champion' LIMIT 1];
Contact economicBuyer       = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND FirstName = 'QA' AND LastName = 'EconomicBuyer' LIMIT 1];
Contact problemOwner        = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND FirstName = 'QA' AND LastName = 'ProblemOwner' LIMIT 1];
Contact authorizedSignatory = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND FirstName = 'Emily'  AND LastName = 'Carter'   LIMIT 1];
Contact businessUser        = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND FirstName = 'Jordan' AND LastName = 'Ellis'    LIMIT 1];
Contact correspondenceCont  = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND FirstName = 'David'  AND LastName = 'Whitmore' LIMIT 1];
Contact billingContact      = [SELECT Id FROM Contact WHERE AccountId = :acc.Id AND FirstName = 'Rachel' AND LastName = 'Nguyen'   LIMIT 1];

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

// ── Opportunity Contact Roles — all 7 roles required across the 4 stages, attached up front ──
insert new List<OpportunityContactRole>{
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = champion.Id,            Role = 'Champion'),
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = economicBuyer.Id,       Role = 'Economic Decision Maker / Buyer'),
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = problemOwner.Id,        Role = 'Problem Owner'),
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = authorizedSignatory.Id, Role = 'Authorized Signatory'),
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = businessUser.Id,        Role = 'Business User'),
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = correspondenceCont.Id,  Role = 'Correspondence Contact'),
    new OpportunityContactRole(OpportunityId = opp.Id, ContactId = billingContact.Id,      Role = 'Billing Contact')
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

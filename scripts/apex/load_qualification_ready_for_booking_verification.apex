// Manual/UI test data loader: a NEW Standard Opportunity, on a NEW Account (distinct from the
// 'SummitEdge Technologies' one used by 006gP00000CTFG5QAP and the stage-progression loader),
// left sitting at Qualification but with every downstream stage-gate requirement already
// satisfied -- so it can be walked Qualification -> Solutioning -> Negotiation -> Booking
// Verification by hand in the UI later without ever hitting a validation error.
//
// Run via: sf apex run --file scripts/apex/load_qualification_ready_for_booking_verification.apex -o IRMDev
// Or paste into Developer Console > Debug > Open Execute Anonymous Window.
//
// The real stage-gate enforcement in this org is the active flow "NF Enforce Required
// Stakeholder Roles by Opportunity Stage": on any StageName change it looks up active
// Contact_Role_Requirement__mdt records for the new StageName (+ Type 'All' or matching Type)
// and blocks the save with a custom error if a required OpportunityContactRole is missing.
// Bypass_Validation__c does NOT suppress this flow -- the only way to guarantee a clean run
// through the UI is to pre-attach every role the metadata requires, across all 4 stages:
//   Qualification (Type=All):        Champion, Economic Decision Maker / Buyer, Problem Owner
//   Solutioning:                     (no requirement rows -- no contact-role gate)
//   Negotiation (Type=All):          Authorized Signatory
//   Booking Verification (Type=New): Billing Contact, Business User, Correspondence Contact
//
// Bypass_Validation__c = true is set on insert as a safety-net for any other Opportunity
// validation rule, mirroring IRM_ExitValidationTest.makeOpp()'s sanctioned use of that field,
// then flipped back to false so the record behaves normally when someone starts driving it
// through the UI.
//
// Safe to re-run: deletes any prior run's Account/Contacts/Opportunity first (matched by name),
// so you can reset back to a clean starting state at any time.

// ── Clean up any prior run ──────────────────────────────────────────────────
delete [SELECT Id FROM Opportunity WHERE Name = 'QA Qualification Ready-for-Progression Test Opp'];
delete [SELECT Id FROM Contact WHERE AccountId IN (SELECT Id FROM Account WHERE Name = 'Northfield Data Systems')];
delete [SELECT Id FROM Account WHERE Name = 'Northfield Data Systems'];

// ── Account (distinct from the SummitEdge Technologies fixture used previously) ─────
Account acc = new Account(Name = 'Northfield Data Systems');
insert acc;

// ── Contacts for all 7 stage-gate roles ─────────────────────────────────────
Contact champion            = new Contact(FirstName = 'Priya',   LastName = 'Desai',     AccountId = acc.Id);
Contact economicBuyer       = new Contact(FirstName = 'Marcus',  LastName = 'Chen',      AccountId = acc.Id);
Contact problemOwner        = new Contact(FirstName = 'Sara',    LastName = 'Whitfield', AccountId = acc.Id);
Contact authorizedSignatory = new Contact(FirstName = 'Derek',   LastName = 'Osei',      AccountId = acc.Id);
Contact businessUser        = new Contact(FirstName = 'Natalie', LastName = 'Kim',       AccountId = acc.Id);
Contact correspondenceCont  = new Contact(FirstName = 'Victor',  LastName = 'Alvarez',   AccountId = acc.Id);
Contact billingContact      = new Contact(FirstName = 'Helena',  LastName = 'Brooks',    AccountId = acc.Id);
insert new List<Contact>{
    champion, economicBuyer, problemOwner, authorizedSignatory, businessUser, correspondenceCont, billingContact
};

Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

// ── Opportunity — stays at Qualification ─────────────────────────────────────
// Qualification-gate fields (Budget_Validated__c, Business_Problem_Evidenced__c, etc.) and the
// Negotiation-stage fields seen populated on other Opportunities that reached Negotiation
// cleanly (Final_Pricing_Terms_Proposed__c / Executed_Agreement_Uploaded__c) are pre-populated
// now, so no field needs to be back-filled mid-progression later.
Opportunity opp = new Opportunity(
    Name                               = 'QA Qualification Ready-for-Progression Test Opp',
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
    Service_Address__Street__s         = '456 Corporate Pkwy',
    Service_Address__City__s           = 'Chicago',
    Service_Address__StateCode__s      = 'IL',
    Service_Address__CountryCode__s    = 'US',
    Final_Pricing_Terms_Proposed__c    = 'True',
    Executed_Agreement_Uploaded__c     = 'True',
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

// ── Reset Bypass_Validation__c so the record behaves normally when driven through the UI ──
update new Opportunity(Id = opp.Id, Bypass_Validation__c = false);

Opportunity result = [SELECT Id, Name, StageName FROM Opportunity WHERE Id = :opp.Id];
System.debug('=== QA QUALIFICATION READY-FOR-PROGRESSION TEST RECORD READY ===');
System.debug('Opportunity Id: ' + result.Id);
System.debug('StageName: ' + result.StageName + ' (expect Qualification)');
System.debug('Open in browser: /' + opp.Id);

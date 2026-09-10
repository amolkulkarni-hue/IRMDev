@IsTest
private class FreddyAcevedoAccessVerificationTest {
    // Verifies the real user freddy.acevedo@ironmountain.com.newprism's actual permission
    // set / profile grants against the real demo workflow (Opportunity Stage change -> Case
    // creation -> Case_Detail__c field edits -> Document_Checklist__c completion -> Case
    // closure), by running each user-facing step under System.runAs(Freddy) with explicit
    // USER_MODE enforcement (WITH USER_MODE on SOQL, AS USER on DML) so field-level security,
    // object CRUD, and sharing are genuinely checked — not just assumed from reading
    // permission set assignments. Case creation itself happens via a system-context trigger
    // and isn't gated on Freddy's CRUD; what matters here is whether he can see and act on
    // what that automation produces.

    private static User getFreddy() {
        return [SELECT Id FROM User WHERE Username = 'freddy.acevedo@ironmountain.com.newprism' LIMIT 1];
    }

    @TestSetup
    static void setup() {
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId());
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct', Product_Class_Name__c = 'Cloud Solutions', Product_Line_Name__c = 'Cloud Solutions');
        insert new SVStatus__c(Name = 'SVStatusPassed', OpptType__c = 'New Deal', Stage__c = 'Solutioning', Amount__c = 0);
    }

    @IsTest
    static void testFreddyCanRunFullRemarketingDemoFlow() {
        User freddy = getFreddy();

        Account acc = new Account(Name = 'FreddyAccessTest Account');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'FreddyAccessTest Opp', AccountId = acc.Id, OwnerId = freddy.Id,
            StageName = 'Draft', CloseDate = Date.today().addDays(30),
            Amount = 50000, Type = 'New Deal', Business_Unit__c = 'ALM', Remarketing_Required__c = 'Yes'
        );
        insert opp;

        Case_Creation_Rule__c rule = new Case_Creation_Rule__c(
            Case_Type__c = 'Remarketing', Stage__c = 'Solutioning', Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'Remarketing_Queue', Is_Active__c = true, Priority__c = 10,
            Logic_Expression__c = '1 AND 2 AND 3 AND 4'
        );
        insert rule;
        insert new List<Case_Creation_Condition__c>{
            new Case_Creation_Condition__c(Rule__c = rule.Id, Condition_Number__c = 1, Field_API_Name__c = 'Remarketing_Required__c', Operator__c = 'EQUALS', Value__c = 'Yes'),
            new Case_Creation_Condition__c(Rule__c = rule.Id, Condition_Number__c = 2, Field_API_Name__c = 'Amount', Operator__c = 'LESS_THAN', Value__c = '75000'),
            new Case_Creation_Condition__c(Rule__c = rule.Id, Condition_Number__c = 3, Field_API_Name__c = 'Business_Unit__c', Operator__c = 'EQUALS', Value__c = 'ALM'),
            new Case_Creation_Condition__c(Rule__c = rule.Id, Condition_Number__c = 4, Field_API_Name__c = 'Type', Operator__c = 'EQUALS', Value__c = 'New Deal')
        };

        // Step 1: Freddy changes his own Opportunity's Stage.
        Boolean step1Ok = false;
        String step1Error = '';
        System.runAs(freddy) {
            try {
                Opportunity oppAsFreddy = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id WITH USER_MODE];
                oppAsFreddy.StageName = 'Solutioning';
                update as user oppAsFreddy;
                step1Ok = true;
            } catch (Exception e) {
                step1Error = e.getMessage();
            }
        }
        System.debug('###STEP1_OPP_STAGE_CHANGE: ok=' + step1Ok + ' err=' + step1Error);

        // Step 2: can Freddy even SEE the Case the automation created?
        List<Case> createdCases = [SELECT Id, Type FROM Case WHERE Opportunity__c = :opp.Id AND Type = 'Remarketing'];
        System.debug('###SYSTEM_CONTEXT_CASE_COUNT: ' + createdCases.size());
        Id caseId = createdCases.isEmpty() ? null : createdCases[0].Id;

        Boolean step2Ok = false;
        String step2Error = '';
        Id caseIdSeenByFreddy = null;
        if (caseId != null) {
            System.runAs(freddy) {
                try {
                    List<Case> visibleCases = [SELECT Id FROM Case WHERE Id = :caseId WITH USER_MODE];
                    step2Ok = !visibleCases.isEmpty();
                    caseIdSeenByFreddy = step2Ok ? visibleCases[0].Id : null;
                } catch (Exception e) {
                    step2Error = e.getMessage();
                }
            }
        }
        System.debug('###STEP2_CAN_SEE_CASE: ok=' + step2Ok + ' err=' + step2Error);

        // Step 3: can Freddy see the Case_Detail__c child?
        Boolean step3Ok = false;
        String step3Error = '';
        Id detailIdSeenByFreddy = null;
        if (caseId != null) {
            System.runAs(freddy) {
                try {
                    List<Case_Detail__c> visibleDetails = [SELECT Id FROM Case_Detail__c WHERE Case__c = :caseId WITH USER_MODE];
                    step3Ok = !visibleDetails.isEmpty();
                    detailIdSeenByFreddy = step3Ok ? visibleDetails[0].Id : null;
                } catch (Exception e) {
                    step3Error = e.getMessage();
                }
            }
        }
        System.debug('###STEP3_CAN_SEE_CASE_DETAIL: ok=' + step3Ok + ' err=' + step3Error);

        // Step 4: can Freddy edit the Remarketing fields on Case_Detail__c (FLS check)?
        Boolean step4Ok = false;
        String step4Error = '';
        if (detailIdSeenByFreddy != null) {
            System.runAs(freddy) {
                try {
                    Case_Detail__c detailAsFreddy = new Case_Detail__c(
                        Id = detailIdSeenByFreddy,
                        RMKT_Asset_Type__c = 'Desktop',
                        RMKT_Nature_Of_Request__c = 'Bid',
                        RMKT_Condition_Notes__c = 'Used',
                        RMKT_Due_Date__c = Date.today().addDays(5),
                        RMKT_Request_Type__c = 'Freddy access test',
                        RMKT_Take_Out_Time_Frame__c = '30',
                        RMKT_Revenue_Share_Percentage__c = 10,
                        RMKT_Data_Destruction_Req__c = 'Wiping (Remarketing-ready)'
                    );
                    update as user detailAsFreddy;
                    step4Ok = true;
                } catch (Exception e) {
                    step4Error = e.getMessage();
                }
            }
        }
        System.debug('###STEP4_CAN_EDIT_CASE_DETAIL_FIELDS: ok=' + step4Ok + ' err=' + step4Error);

        // Step 5: can Freddy see and mark the Document Checklist rows Final?
        Boolean step5Ok = false;
        String step5Error = '';
        Integer docsVisibleToFreddy = 0;
        if (caseId != null) {
            System.runAs(freddy) {
                try {
                    List<Document_Checklist__c> docs = [SELECT Id FROM Document_Checklist__c WHERE Case__c = :caseId WITH USER_MODE];
                    docsVisibleToFreddy = docs.size();
                    for (Document_Checklist__c dc : docs) {
                        dc.Status__c = 'Final';
                        dc.Submitted_Date__c = Date.today();
                    }
                    if (!docs.isEmpty()) update as user docs;
                    step5Ok = true;
                } catch (Exception e) {
                    step5Error = e.getMessage();
                }
            }
        }
        System.debug('###STEP5_CAN_SEE_AND_FINALIZE_DOCS: ok=' + step5Ok + ' visibleCount=' + docsVisibleToFreddy + ' err=' + step5Error);

        // Step 6: can Freddy close the Case as Approved?
        Boolean step6Ok = false;
        String step6Error = '';
        if (caseIdSeenByFreddy != null) {
            System.runAs(freddy) {
                try {
                    Case caseAsFreddy = new Case(Id = caseIdSeenByFreddy, Status = 'Closed - Approved');
                    update as user caseAsFreddy;
                    step6Ok = true;
                } catch (Exception e) {
                    step6Error = e.getMessage();
                }
            }
        }
        System.debug('###STEP6_CAN_CLOSE_CASE: ok=' + step6Ok + ' err=' + step6Error);

        // No hard assertions — this test exists to surface Freddy's real access gaps via debug
        // log output, not to pass/fail the build. Assert only on the parts that must always be
        // true regardless of Freddy's permissions, so a real regression still fails the build.
        System.assertNotEquals(null, caseId, 'Sanity check: the automation itself must still create the Case regardless of Freddy\'s permissions.');
    }
}

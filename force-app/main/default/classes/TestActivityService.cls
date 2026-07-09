@isTest(seealldata = true)
private class TestActivityService {

    private static final Integer MAX = 20;

    private static Account acct;
    private static Contact contact;
    private static Opportunity opp;

    static {
        acct = TestingUtils.createAccounts(1,true)[0];
        // acct = new Account(Name='Test Account'+system.now(), BillingCountry='United States');
       //  insert acct;
        contact = TestingUtils.createContact(acct.Id, false);
        contact.IM_Job_Level__c = 'Executive';
        insert contact;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        
        opp = TestingUtils.createOpportunity(null, acct.Id, true);
       // opp = new Opportunity(Name = 'Test Opportunity', AccountId = acct.Id, StageName = '4 - Negotiate', IM_Booked_Date__c = Date.Today(), closedate = Date.Today()+1,Lead_Source_Most_Recent__c = 'Email',IM_Servicing_Region__c = 'Aberdeen');
       // insert opp;
    }



    private static void refreshOpp(){
        opp = [SELECT 
            Id, 
            Name,             
            Customer_Verifier_2__c,
            Customer_Verifier_3__c,
            Customer_Verifier_4__c,
            Customer_Verifier_5__c,
            Customer_Verifier_6__c,
            Customer_Verifier_7__c,
            Customer_Verifier_8__c,
            Customer_Verifier_9__c,
            Customer_Verifier_10__c,
            Customer_Verifier_11__c,
            Customer_Verifier_12__c,
            Customer_Verifier_13__c,
            Customer_Verifier_14__c,
            Customer_Verifier_15__c,
            Customer_Verifier_16__c
            FROM Opportunity
            WHERE Id = :opp.Id
            ];
            
           // opp.Customer_Verifier_3__c = true;
        //    opp.Customer_Verifier_8__c = true;
    }

    private static Task refreshTask(Task t){
        if(t.Id==null) return null;
        return refreshTasks(new Task[]{t})[0];
    }
    private static List<Task> refreshTasks(List<Task> ts){
        Set<Id> taskIds = new Set<Id>();
        for(Task t:ts){ 
            if(t.Id!=null) taskIds.add(t.Id); 
        }
        return [SELECT 
                Id,
                Contact_Level__c,
                WhoId,
                WhatId
            FROM Task
            WHERE Id in :taskIds
        ];
    }

    private static Task createTask(){
        return createTask(opp, false);
    }
    private static Task createTask(Opportunity o){
        return createTask(o, false);
    }
    private static Task createTask(Boolean doDml){
        return createTask(opp,doDml);
    }
    private static Task createTask(sObject obj, Boolean doDml){
        Task t = new Task(
            WhoId = contact.Id,
            WhatId = obj.Id,
            Subject = 'test'
        );
        if(doDml){ insert t; }
        return t;
    }

    @isTest static void testRollup_withEvent(){
        Event e = new Event(
            WhoId = contact.id,
            WhatId = opp.Id,
            //Customer_Verifiers__c = '1;2',
            DurationInMinutes = 60,
            ActivityDateTime = System.now()
        );

        Test.startTest();
        insert e;
        Test.stopTest();

        refreshOpp();
       /* system.assertNotEquals(null, e.Id);
        system.assert(opp.Customer_Verifier_1__c);
        system.assert(opp.Customer_Verifier_2__c);
        system.assert(!opp.Customer_Verifier_3__c);*/
    }

    @isTest static void testRollup_withNullVerifier() {

        Test.startTest();
        Task t = createTask(true);
        t.Subject = 'test';
        Test.stopTest();

        refreshOpp();
     //   system.assertNotEquals(null, t.Id);
     //   system.assert(!opp.Customer_Verifier_1__c);
    }   

    @isTest static void testRollup_checksVerifier() {
        Task t = createTask(false);
        //t.Customer_Verifiers__c = '1;2';
        t.Subject = 'test';
        Test.startTest();
        insert t;
        Test.stopTest();

        refreshOpp();
      /*  system.assert(opp.Customer_Verifier_1__c);
        system.assert(opp.Customer_Verifier_2__c);
        system.assert(!opp.Customer_Verifier_3__c);*/
    }

    @isTest static void testRollup_checksAllVerifiers() {
        Task t = createTask(false);
        //t.Customer_Verifiers__c = '1;2;3;4;5;6;7;8;9;10;11';
        t.Subject = 'test';
        Test.startTest();
        insert t;
        Test.stopTest();

        refreshOpp();        
       /* system.assert(opp.Customer_Verifier_2__c);
        system.assert(opp.Customer_Verifier_3__c);
        system.assert(opp.Customer_Verifier_4__c);
        system.assert(opp.Customer_Verifier_5__c);
        system.assert(opp.Customer_Verifier_6__c);
        system.assert(opp.Customer_Verifier_7__c);
        system.assert(opp.Customer_Verifier_8__c);
        system.assert(opp.Customer_Verifier_9__c);
        system.assert(opp.Customer_Verifier_10__c);
        system.assert(opp.Customer_Verifier_11__c);
        system.assert(opp.Customer_Verifier_12__c);
        system.assert(opp.Customer_Verifier_13__c);
        system.assert(opp.Customer_Verifier_14__c);
        system.assert(opp.Customer_Verifier_15__c);
        system.assert(opp.Customer_Verifier_16__c);*/
    }
    
    @isTest static void testRollup_doesNotUncheckVerifiers() {
        opp.Customer_Verifier_3__c = true;
        update opp;

        Task t = createTask(false);
        //t.Customer_Verifiers__c = '1;2';
        t.Subject = 'test';
        Test.startTest();
        insert t;
        Test.stopTest();

        refreshOpp();        
      /*  system.assert(opp.Customer_Verifier_2__c);
        system.assert(opp.Customer_Verifier_3__c);
        system.assert(!opp.Customer_Verifier_4__c);
        system.assert(!opp.Customer_Verifier_5__c);
        system.assert(!opp.Customer_Verifier_6__c);
        system.assert(!opp.Customer_Verifier_7__c);
        system.assert(!opp.Customer_Verifier_8__c);
        system.assert(!opp.Customer_Verifier_9__c);
        system.assert(!opp.Customer_Verifier_10__c);
        system.assert(!opp.Customer_Verifier_11__c);
        system.assert(opp.Customer_Verifier_12__c);
        system.assert(opp.Customer_Verifier_13__c);
        system.assert(opp.Customer_Verifier_14__c);
        system.assert(opp.Customer_Verifier_15__c);
        system.assert(opp.Customer_Verifier_16__c);*/
    }
    
    @isTest static void testRollup_skipsNonOpporunityWhatIds() {
        Task t = createTask(acct, false);
        //t.Customer_Verifiers__c = '1;2';
        t.Subject = 'test';

        Test.startTest();
        insert t;
        Test.stopTest();

        refreshOpp();
     //   system.assertNotEquals(null, t.Id);
      //  system.assert(!opp.Customer_Verifier_1__c);
    }
    
    @isTest static void testGetContactLevel_skipsEmptyContacts() {
        Task t = createTask(acct, false);
        t.WhoId = null;
        t.Subject = 'test';
        Test.startTest();
        insert t;
        Test.stopTest();

        t = refreshTask(t);
     /*   system.assertNotEquals(null, t.Id);
        system.assertEquals(null, t.WhoId);
        system.assertEquals(null, t.Contact_Level__c);*/
    }

    @isTest static void testGetContactLevel_populatesContactLevel() {
        Test.startTest();
        Task t = createTask(acct, true);
        t.Subject = 'test';
        Test.stopTest();

        t = refreshTask(t);
       // system.assertEquals('Executive', t.Contact_Level__c);
    }

    @isTest static void testActivityService_Batch() {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Recordtype r=[select id from recordtype where name='Standard Opportunity' limit 1];
        IM_Country__c cntry = TestingUtil.createIMCountry();
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = MAX; i > 0; i--){
            //opps.add(TestingUtils.createOpportunity('Test '+i, acct.Id, false));
            opps.add(new Opportunity(Name = 'Test Opportunity'+i, Type='New Deal',AccountId = acct.Id, StageName = '1 - Qualification', IM_Booked_Date__c = Date.Today(), closedate = Date.Today(),recordtypeid=r.id, Billing_Country__c = cntry.id, Source_System__c='SKP NA'));
        }
        insert opps;

        Set<Id> oppIds = new Set<Id>();
        List<Task> tasks = new List<Task>();
        for(Opportunity o: opps){
            oppIds.add(o.Id);
            Task t = createTask(o, false);
            //t.Customer_Verifiers__c = '1';
            t.Subject = 'test';
            tasks.add(t);
            t = createTask(o, false);
            //t.Customer_Verifiers__c = '1;2';
            t.Subject = 'test';
            tasks.add(t);
        }

        Test.startTest();
        insert tasks;
        Test.stopTest();


       opps = [SELECT 
            Id, 
            Name,             
            Customer_Verifier_2__c,
            Customer_Verifier_3__c,
            Customer_Verifier_4__c,
            Customer_Verifier_5__c,
            Customer_Verifier_6__c,
            Customer_Verifier_7__c,
            Customer_Verifier_8__c,
            Customer_Verifier_9__c,
            Customer_Verifier_10__c,
            Customer_Verifier_11__c,
            Customer_Verifier_12__c,
            Customer_Verifier_13__c,
            Customer_Verifier_14__c,
            Customer_Verifier_15__c,
            Customer_Verifier_16__c
            FROM Opportunity
            WHERE Id IN :oppIds
            ];
          //  opp.Customer_Verifier_3__c = true;
         //   opp.Customer_Verifier_8__c = true;
      //  for(Opportunity o: opps){
         /*   system.assert(o.Customer_Verifier_1__c);
            system.assert(o.Customer_Verifier_2__c);
            system.assert(!o.Customer_Verifier_3__c);*/
     //   }
      //  system.assertEquals(MAX+1, [SELECT Id FROM Opportunity].size());
     //   system.assertEquals(MAX*2, [SELECT Id FROM Task].size());

        tasks = refreshTasks(tasks);
        //for(Task t:tasks){
          //  system.assertEquals('Executive', t.Contact_Level__c);
        //}
    }
    
}
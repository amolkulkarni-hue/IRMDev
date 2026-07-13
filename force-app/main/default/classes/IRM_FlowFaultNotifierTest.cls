@IsTest
private class IRM_FlowFaultNotifierTest {

    @IsTest
    static void test_notifyFault_createsTaskAndSendsEmail() {
        Account acc = new Account(Name = 'Fault Test Co');
        insert acc;

        IRM_FlowFaultNotifier.Request req = new IRM_FlowFaultNotifier.Request();
        req.flowName     = 'Test_Flow_Alpha';
        req.faultMessage = 'Simulated fault for unit testing';
        req.recordId     = acc.Id;
        req.ownerId      = UserInfo.getUserId();

        Test.startTest();
        IRM_FlowFaultNotifier.notifyFault(new List<IRM_FlowFaultNotifier.Request>{ req });
        Test.stopTest();

        List<Task> tasks = [SELECT Subject, WhatId, Priority, Status FROM Task WHERE WhatId = :acc.Id];
        System.assertEquals(1, tasks.size(), 'One Task should be created on the fault record.');
        System.assertEquals('High',  tasks[0].Priority, 'Task priority should be High.');
        System.assertEquals('Open',  tasks[0].Status,   'Task status should be Open.');
        System.assert(tasks[0].Subject.contains('IRM Flow Error'),
            'Task subject should reference the IRM Flow Error. Got: ' + tasks[0].Subject);
    }

    @IsTest
    static void test_notifyFault_nullOwnerSkipsTask() {
        IRM_FlowFaultNotifier.Request req = new IRM_FlowFaultNotifier.Request();
        req.flowName     = 'Test_Flow_NoOwner';
        req.faultMessage = 'Fault with no owner configured';
        req.recordId     = null;
        req.ownerId      = null;

        Test.startTest();
        IRM_FlowFaultNotifier.notifyFault(new List<IRM_FlowFaultNotifier.Request>{ req });
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE Subject LIKE '%Test_Flow_NoOwner%'];
        System.assertEquals(0, tasks.size(),
            'No Task should be created when ownerId is null.');
    }

    @IsTest
    static void test_notifyFault_bulk5Requests() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Bulk Fault Co ' + i));
        }
        insert accounts;

        List<IRM_FlowFaultNotifier.Request> requests = new List<IRM_FlowFaultNotifier.Request>();
        for (Account a : accounts) {
            IRM_FlowFaultNotifier.Request r = new IRM_FlowFaultNotifier.Request();
            r.flowName     = 'Bulk_Fault_Flow';
            r.faultMessage = 'Bulk fault on ' + a.Id;
            r.recordId     = a.Id;
            r.ownerId      = UserInfo.getUserId();
            requests.add(r);
        }

        Test.startTest();
        IRM_FlowFaultNotifier.notifyFault(requests);
        Test.stopTest();

        List<Id> accountIds = new List<Id>();
        for (Account a : accounts) { accountIds.add(a.Id); }
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :accountIds];
        System.assertEquals(5, tasks.size(),
            '5 Tasks should be created for 5 fault requests.');
    }
}
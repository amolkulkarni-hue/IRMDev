@isTest
private class CleanupConfigLineItemsBatchTest {

    @testSetup
    static void setupTestData() {
        

        // --- BYPASS THE ACCOUNT TRIGGER ---
        // This prevents AccountHelper OpportunityHelper and the Country Validation from firing during the test
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        // Query the Profile
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        
        // Create the Test User
        User testAdminUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Alias = 'tadmin',
            Email = 'testadmin_' + DateTime.now().getTime() + '@example.com',
            Username = 'testadmin_' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = adminProfile.Id,
            Country = 'United States'
        );

        insert testAdminUser;

        //Query the Permission Set from 
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Sales_Operations_Business_Partner_PSG' LIMIT 1];
        
        //Assign the Permission Set to the newly created User
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testAdminUser.Id,
            PermissionSetId = ps.Id
        );
        insert psa;


        System.runAs(testAdminUser) {

        // 1. Create a Test Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // 2. Get the Standard Pricebook ID for the test context
        Id standardPricebookId = Test.getStandardPricebookId();

        IM_Country__c imContry = new  IM_Country__c(
        Name = 'United States',
        Originating_Org__c = 'Core',
        Region__c = 'North America',
        CurrencyIsoCode = 'USD',
        Active__c = true
        );

        insert imContry;


        Schema.DescribeFieldResult fieldResult = Opportunity.Primary_Product_Line__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        String validProductLine = ple[0].getValue();

        // 3. Create a Test Opportunity and associate the Pricebook
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAcc.Id,
            Pricebook2Id = standardPricebookId,
            //StageName = 'Prospecting', //1 - Qualification
            StageName = '1 - Qualification', //1 - Qualification
            CloseDate = System.today().addDays(30),
            //Primary_Product_Line__c = 'SITAD',
            Primary_Product_Line__c = validProductLine,
            Billing_Country__c = imContry.id,
            Bypass_Validation__c = true
        );
        insert testOpp;

        // 4. Create the Logik Transaction with all required relationship fields
        LGK__Transaction__c testTrans = new LGK__Transaction__c(
            LGK__AccountId__c = testAcc.Id,
            LGK__OpportunityId__c = testOpp.Id,
            LGK__Pricebook2Id__c = standardPricebookId
        );
        insert testTrans;


        List<LGK__TransactionLine__c> testTxLines = new List<LGK__TransactionLine__c>();
        
        testTxLines.add(new LGK__TransactionLine__c(
            LGK__ConfigurationId__c = 'CONFIG-VALID-123',
            LGK__TransactionId__c = testTrans.Id
        ));
        insert testTxLines;


        List<LGK__ConfigurationLineItem__c> testConfigs = new List<LGK__ConfigurationLineItem__c>();
        
        // Escenario A: VALID CONFIG, CONFIG LINES EXIST SHOULD BE NOT DELETED
        testConfigs.add(new LGK__ConfigurationLineItem__c(
            LGK__ConfigurationId__c = 'CONFIG-VALID-123'
        ));
        
        // Escenario B: INVALID CONFIG, CONFIG LINES EXIST SHOULD BE  DELETED
        testConfigs.add(new LGK__ConfigurationLineItem__c(
            LGK__ConfigurationId__c = 'CONFIG-ORPHAN-456'
        ));
        
        // Escenario C: NULL, CONFIG LINES EXIST SHOULD BE DELETED
        testConfigs.add(new LGK__ConfigurationLineItem__c(
            LGK__ConfigurationId__c = null
        ));
        
        insert testConfigs;
        }
    }

    @isTest
    static void testBatchExecution() {

        User testAdminUser = [SELECT Id FROM User WHERE Alias = 'tadmin' LIMIT 1];

        System.runAs(testAdminUser) {

        // Verificar que los 3 registros se crearon correctamente antes del proceso
        Assert.areEqual(3, [SELECT COUNT() FROM LGK__ConfigurationLineItem__c], 'Debería haber 3 registros iniciales.');

        // Test.startTest() y Test.stopTest() fuerzan a que el proceso asíncrono (Batch)
        // se ejecute de manera síncrona dentro del contexto de la prueba.
        Test.startTest();
        CleanupConfigLineItemsBatch batchJob = new CleanupConfigLineItemsBatch();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();

        // --- VERIFICACIÓN DE RESULTADOS ---
        
        // El huérfano y el nulo deben haber sido eliminados. Solo debe quedar 1 registro.
        List<LGK__ConfigurationLineItem__c> remainingConfigs = [
            SELECT Id, LGK__ConfigurationId__c 
            FROM LGK__ConfigurationLineItem__c
        ];
        
        Assert.areEqual(1, remainingConfigs.size(), 'Solo debería haber quedado 1 registro tras la limpieza.');
        Assert.areEqual('CONFIG-VALID-123', remainingConfigs[0].LGK__ConfigurationId__c, 'El registro restante debe ser el que tiene una transacción activa.');
        }
    }

    @isTest
    static void testSchedulableExecution() {
        User testAdminUser = [SELECT Id FROM User WHERE Alias = 'tadmin' LIMIT 1];

        System.runAs(testAdminUser) {

        String cronExp = '0 0 0 * * ?';
        
        Test.startTest();
        // Programar el Job
        String jobId = System.schedule(
            'Test Daily Cleanup Job', 
            cronExp, 
            new CleanupConfigLineItemsBatch()
        );
        Test.stopTest();

        // Verificar que el Job quedó correctamente en la cola de Salesforce
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, State 
            FROM CronTrigger 
            WHERE Id = :jobId
        ];
        
        Assert.areEqual(cronExp, ct.CronExpression, 'La expresión Cron debe coincidir con la configurada.');
        Assert.areEqual('WAITING', ct.State, 'El Job programado debe estar en estado de espera (WAITING).');
        }
    }
}
@isTest
private class TestQueryBuilder {
    static String closedStatusLabel;
    static String openStatusLabel;
    static Account testAct;
    static Opportunity testOpp;
    static Contact testContact;
    static Contact testContact2;
    static User testUser;
    static User testUser2;
    static Group testGroup;
    static {
        System.runAs(TestingUtils.ADMIN_USER) {
            testAct = TestingUtils.createAccounts(1, true)[0];
            testOpp = TestingUtils.createOpportunity('testOpp', testAct.Id, true);
            testContact = TestingUtils.createContact(testAct.Id, true);
            testContact2 = TestingUtils.createContact(testAct.Id, true);
            testUser = TestingUtil.createUsers(1, true)[0];
            testUser2 = TestingUtil.createUsers(1, true)[0];
        }

        List<Template_Name_For_Service_Line__c> caseLinkTemplate = Test.loadData(Template_Name_For_Service_Line__c.SObjectType,'TemplateNameForServiceLine');
        List<Customer_Onboarding_Images_And_Links__c> coImagesAndLinks = Test.loadData(Customer_Onboarding_Images_And_Links__c.SObjectType,'CustomerOnboardingImagesAndLinks');
    }

    static void setup() {
        List<CaseStatus> closedStatus = [Select Id, MasterLabel From CaseStatus Where IsClosed = true AND MasterLabel='Closed' LIMIT 1];
        System.assertEquals(1, closedStatus.size(), 'We did not get back a CaseStatus that is Closed called "Closed". Change query to look for an existing Closed CaseStatus');
        closedStatusLabel = closedStatus[0].MasterLabel;
        List<CaseStatus> openStatus = [Select Id, MasterLabel From CaseStatus Where IsClosed = false AND MasterLabel='New' LIMIT 1];
        System.assertEquals(1, openStatus.size(), 'We did not get back a CaseStatus that is Open called "New". Change query to look for an existing Open CaseStatus');
        openStatusLabel = openStatus[0].MasterLabel;
    
        List<Group> testGroups = [Select Id from Group where DeveloperName = :WelcomeEmailController.NCSP_QUEUE_NAME and Type = 'Queue' Limit 1];
        
        if( testGroups.isEmpty() )
        {
            testGroup = new Group(Name='NCSP FIFO', DeveloperName = 'NCSP_FIFO_First_in_First_out', Type = 'Queue');
            insert testGroup;
    
            QueueSobject testQueue = new QueueSObject(QueueId = testGroup.Id, SobjectType = 'Case');
            System.runAs(TestingUtils.ADMIN_USER) {
                insert testQueue;
            }
        }
        else{
            testGroup = testGroups[0];
        }
    }
        /*
    *   Case fieldset : (Id), CaseNumber, OwnerId, IsClosed, Date_welcome_call_completed__c, NCSP_Opportunity__c, NCSP_Service_line__c
    *   Contact fieldset : (Id), Email, Name, Phone
    *   Customer_Profile__c fieldset: (Id), Billing_Address__c, Billing_City__c, Billing_Country__c, Customer_Name__c
    */
    static testMethod void testQueryBuilder() {
        setup();
        Set<String> caseFields = new Set<String>{'OwnerId', 'Date_welcome_call_completed__c', 'NCSP_Opportunity__c', 'NCSP_Service_line__c'};
        Set<String> contactFields = new Set<String>{'Email', 'FirstName', 'LastName'};
        Set<String> customerProfileFields = new Set<String>{'Billing_Address__c', 'Billing_City__c', 'Billing_Country__c', 'Customer_Name__c'};

        List<Customer_Profile__c> testCPs = new List<Customer_Profile__c>();
        for (Integer i=0; i<4; i++) 
            testCPs.add(TestingUtils.createCustomerProfile(testOpp.Id, null, false));
        UnitTest.addData(testCPs).tag('Customer Profiles');
        UnitTest.get('Customer Profiles').insertAll();

        List<Contact> testContacts = new List<Contact>();
        for (Integer i=0; i<4; i++) 
            testContacts.add(TestingUtils.createContact(testAct.Id, false));
        UnitTest.addData(testContacts).tag('Contacts');
        UnitTest.get('Contacts').insertAll();

        List<Case> testCases = TestingUtils.createCases(100, testOpp, testContact, false);
        UnitTest.addData(testCases).tag('Cases').property('Customer_Profile__c').assignFrom('Customer Profiles')
                                                .property('ContactId').assignFrom('Contacts');
        UnitTest.get('Cases').insertAll();

        for (String field : caseFields) {
            try {
                UnitTest.get('Cases').getList()[0].get(field);
            } catch (SObjectException e) {
                System.assert(e.getMessage().contains(field), 'We are expecting to get an error message for trying to access field that was not queried for');
            }
        }

        // Give the fields value and then update
        UnitTest.get('Cases').property('OwnerId').assign(testUser.Id).property('Date_welcome_call_completed__c').assign(Date.newInstance(1999, 1, 19))
                             .property('NCSP_Opportunity__c').assign(testOpp.Id).property('NCSP_Service_line__c').assign('Shred');
        UnitTest.get('Contacts').property('Email').assign('test@bw.com').property('FirstName').assign('Homer').property('LastName').assign('Simpson');
        UnitTest.get('Customer Profiles').property('Billing_Address__c').assign('1 main st').property('Billing_City__c').assign('Boston').property('Customer_Name__c').assign('Bart Simpson');
        UnitTest.get('Cases').updateAll();
        UnitTest.get('Contacts').updateAll();
        UnitTest.get('Customer Profiles').updateAll();

        Test.startTest();
            QueryBuilder qb = new QueryBuilder(Case.SObjectType, new List<Id>(Pluck.ids(UnitTest.get('Cases').getList())));
            qb.addFields(caseFields).addFieldsToObject('Contact', contactFields).addFieldsToObject('Customer_Profile__c', customerProfileFields);
            List<Case> casesWithFields = (List<Case>) qb.runQuery();
        Test.stopTest();

        System.assertEquals(UnitTest.getIDs('Cases'), Pluck.ids(casesWithFields), 'We expect to get the same set of Ids from the query builder');
        for (Case actualCase : casesWithFields) {
            for (String field : caseFields) {
                System.assertEquals(UnitTest.analyze('Cases').selectByID(actualCase.Id).getPropertyValue(field), actualCase.get(field), 'We expect to have no problem accessing the case fields in the field set. We also expect the value to be what we set');
            }
            for (String field : contactFields) {
                System.assertEquals(UnitTest.analyze('Cases').selectByID(actualCase.Id).traverse('ContactId').getPropertyValue(field), actualCase.getSobject('Contact').get(field), 'We expect to have no problem accessing the contact fields in the field set. We also expect the value to be what we set');
            }
            for (String field : customerProfileFields) {
                System.assertEquals(UnitTest.analyze('Cases').selectByID(actualCase.Id).traverse('Customer_Profile__c').getPropertyValue(field), actualCase.getSobject('Customer_Profile__r').get(field), 'We expect to have no problem accessing the customer profile fields in the field set. We also expect the value to be what we set');
            }
        }
    }

    /*
    *   Case fieldset : (Id), CaseNumber, OwnerId, IsClosed, Date_welcome_call_completed__c, NCSP_Opportunity__c, NCSP_Service_line__c
    *   Contact fieldset : (Id), Email, Name, Phone
    *   Customer_Profile__c fieldset: (Id), Billing_Address__c, Billing_City__c, Billing_Country__c, Customer_Name__c
    */
    static testMethod void testQueryBuilderUsingFieldPaths() {
        setup();
        List<String> fieldPaths = new List<String>{'OwnerId', 'Date_welcome_call_completed__c', 'NCSP_Opportunity__c', 'NCSP_Service_line__c', 
                                                    'Contact.Email', 'Contact.FirstName', 'Contact.LastName', 
                                                    'Customer_Profile__r.Billing_Address__c', 'Customer_Profile__r.Billing_City__c', 'Customer_Profile__r.Billing_Country__c', 'Customer_Profile__r.Customer_Name__c'};
        Set<String> caseFields = new Set<String>{'OwnerId', 'Date_welcome_call_completed__c', 'NCSP_Opportunity__c', 'NCSP_Service_line__c'};
        Set<String> contactFields = new Set<String>{'Email', 'FirstName', 'LastName'};
        Set<String> customerProfileFields = new Set<String>{'Billing_Address__c', 'Billing_City__c', 'Billing_Country__c', 'Customer_Name__c'};

        List<Customer_Profile__c> testCPs = new List<Customer_Profile__c>();
        for (Integer i=0; i<4; i++) 
            testCPs.add(TestingUtils.createCustomerProfile(testOpp.Id, null, false));
        UnitTest.addData(testCPs).tag('Customer Profiles');
        UnitTest.get('Customer Profiles').insertAll();

        List<Contact> testContacts = new List<Contact>();
        for (Integer i=0; i<4; i++) 
            testContacts.add(TestingUtils.createContact(testAct.Id, false));
        UnitTest.addData(testContacts).tag('Contacts');
        UnitTest.get('Contacts').insertAll();

        List<Case> testCases = TestingUtils.createCases(100, testOpp, testContact, false);
        UnitTest.addData(testCases).tag('Cases').property('Customer_Profile__c').assignFrom('Customer Profiles')
                                                .property('ContactId').assignFrom('Contacts');
        UnitTest.get('Cases').insertAll();

        for (String field : caseFields) {
            try {
                UnitTest.get('Cases').getList()[0].get(field);
            } catch (SObjectException e) {
                System.assert(e.getMessage().contains(field), 'We are expecting to get an error message for trying to access field that was not queried for');
            }
        }

        // Give the fields value and then update
        UnitTest.get('Cases').property('OwnerId').assign(testUser.Id).property('Date_welcome_call_completed__c').assign(Date.newInstance(1999, 1, 19))
                             .property('NCSP_Opportunity__c').assign(testOpp.Id).property('NCSP_Service_line__c').assign('Shred');
        UnitTest.get('Contacts').property('Email').assign('test@bw.com').property('FirstName').assign('Homer').property('LastName').assign('Simpson');
        UnitTest.get('Customer Profiles').property('Billing_Address__c').assign('1 main st').property('Billing_City__c').assign('Boston').property('Customer_Name__c').assign('Bart Simpson');
        UnitTest.get('Cases').updateAll();
        UnitTest.get('Contacts').updateAll();
        UnitTest.get('Customer Profiles').updateAll();

        Test.startTest();
            QueryBuilder qb = new QueryBuilder(Case.SObjectType, new List<Id>(Pluck.ids(UnitTest.get('Cases').getList())));
            qb.addFieldsUsingFieldPaths(fieldPaths);
            List<Case> casesWithFields = (List<Case>) qb.runQuery();
        Test.stopTest();

        System.assertEquals(UnitTest.getIDs('Cases'), Pluck.ids(casesWithFields), 'We expect to get the same set of Ids from the query builder');
        for (Case actualCase : casesWithFields) {
            for (String field : caseFields) {
                System.assertEquals(UnitTest.analyze('Cases').selectByID(actualCase.Id).getPropertyValue(field), actualCase.get(field), 'We expect to have no problem accessing the case fields in the field set. We also expect the value to be what we set');
            }
            for (String field : contactFields) {
                System.assertEquals(UnitTest.analyze('Cases').selectByID(actualCase.Id).traverse('ContactId').getPropertyValue(field), actualCase.getSobject('Contact').get(field), 'We expect to have no problem accessing the contact fields in the field set. We also expect the value to be what we set');
            }
            for (String field : customerProfileFields) {
                System.assertEquals(UnitTest.analyze('Cases').selectByID(actualCase.Id).traverse('Customer_Profile__c').getPropertyValue(field), actualCase.getSobject('Customer_Profile__r').get(field), 'We expect to have no problem accessing the customer profile fields in the field set. We also expect the value to be what we set');
            }
        }
    }

    static testMethod void testQueryBuilderWithEmptyIdList() {
        List<String> fieldPaths = new List<String>{'OwnerId', 'Date_welcome_call_completed__c', 'NCSP_Opportunity__c', 'NCSP_Service_line__c', 
                                                    'Contact.Email', 'Contact.FirstName', 'Contact.LastName', 
                                                    'Customer_Profile__r.Billing_Address__c', 'Customer_Profile__r.Billing_City__c', 'Customer_Profile__r.Billing_Country__c', 'Customer_Profile__r.Customer_Name__c'};
        Test.startTest();
            QueryBuilder qb = new QueryBuilder(Case.SObjectType, new List<Id>());
            qb.addFieldsUsingFieldPaths(fieldPaths);
            List<Case> casesWithFields = (List<Case>) qb.runQuery();
        Test.stopTest();

        System.assert(casesWithFields.isEmpty(), 'runQuery should not error and it should return an empty list');
    }

    static Map<Integer, String> alphabet = new Map<Integer, String>{ 0=>'a', 1=>'b', 2=>'c', 3=>'d', 4=>'e',
                                                                     5=>'g', 6=>'h', 7=>'i', 8=>'j', 9=>'k'};

    static testMethod void testQueryBuilderOrderByDesc() {
        List<Contact> testContacts = new List<Contact>();
        Integer i;
        for (i=0; i<10; i++) 
            testContacts.add(TestingUtils.createContact(testAct.Id, false));

        i=0;
        for (Contact c : testContacts) 
            c.LastName = alphabet.get(i++);
        insert testContacts;

        Test.startTest();
            QueryBuilder qb = new QueryBuilder(Contact.SObjectType, new List<Id>(Pluck.ids(testContacts)));
            qb.addField('LastName').orderBy('LastName', false);
            List<Contact> contactsDesc = (List<Contact>) qb.runQuery();
        Test.stopTest();

        for (i=0; i<10; i++)
            System.assertEquals(alphabet.get(9-i), contactsDesc[i].LastName, 'Order should be descending by LastName'); 
    }

    static testMethod void testQueryBuilderOrderByAsc() {
        List<Contact> testContacts = new List<Contact>();
        Integer i;
        for (i=0; i<10; i++) 
            testContacts.add(TestingUtils.createContact(testAct.Id, false));

        i=0;
        for (Contact c : testContacts) 
            c.LastName = alphabet.get(i++);
        insert testContacts;

        Test.startTest();
            QueryBuilder qb = new QueryBuilder(Contact.SObjectType, new List<Id>(Pluck.ids(testContacts)));
            qb.addField('LastName').orderBy('LastName', true);
            List<Contact> contactsAsc = (List<Contact>) qb.runQuery();
        Test.stopTest();

        for (i=0; i<10; i++)
            System.assertEquals(alphabet.get(i), contactsAsc[i].LastName, 'Order should be ascending by LastName'); 
    }

}
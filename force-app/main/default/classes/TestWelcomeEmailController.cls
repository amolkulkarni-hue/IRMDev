@isTest
private class TestWelcomeEmailController {
    
    final static string TEST_BODY_TEMPLATE_DEV_NAME = 'Test_Body_Template';
    final static string TEST_BODY_TEMPLATE_NAME = 'Test Body Template';
    final static string TEST_BODY_TEMPLATE_BODY = 'Thank you for talking with us the other day. Here are the list of Cases: \n'+
        '{CaseLinkList} \n';
    final static string TEST_GREETING_TEMPLATE_DEV_NAME = 'Test_Greeting_Template';
    final static string TEST_GREETING_TEMPLATE_NAME = 'Test Greeting Template';
    final static string TEST_GREETING_TEMPLATE_BODY = 'Dear {CaseContactName}, \n';
    
    final static string TEST_SALUTATION_TEMPLATE_DEV_NAME = 'Test_Salutation_Template';
    final static string TEST_SALUTATION_TEMPLATE_NAME = 'Test Salutation Template';
    final static string TEST_SALUTATION_TEMPLATE_BODY = '{RepFirstName} {RepLastName}</strong></span><br />\n'+
        '<span> {RepTitle}, Iron Mountain<br /> \n'+
        '000.000.0000<br /> \n{RepEmail}';
    
    final static string PARENT_TEMPLATE_DEV_NAME = 'Test_Parent_Template';
    final static string PARENT_TEMPLATE_NAME = 'Test Parent Template';
    final static string PARENT_TEMPLATE_SUBJECT = 'Test Parent Template SUBJECT';
    final static string PARENT_TEMPLATE_BODY = '<img src=\'someimage.jpg\' />'+
        '<div>{GreetingSection}</div>'+
        '<img src=\'section2.jpg\' />'+
        '<span>This is you\'re next step</span>'+
        '{BodySection}'+
        '<hr /><div>{SalutationSection}</div>';
    
    final static string PARENT_TEMPLATE_HTML_BODY = '<img src=\'{IMG:header}\' />'+
        '<div>{section1}</div>'+
        '<img src=\'{LINK:footer}.jpg\' />'+
        '<span>This is you\'re next step</span>'+
        '{section2}'+
        '<hr /><div>{salutation}</div>'+
        '<small>{footer}</small>'+
        '<a href="https://{formURL}>hi</a>';
    
    static Account testAct;
    static Opportunity testOpp;
    static Contact testContact;
    static Contact testContact2;
    static User testUser;
    static User testUser2;
    static String closedStatusLabel;
    static String openStatusLabel;
    static Group testGroup;
    static IM_Country__c testCountry;
    static IM_Alternative_Country_Name__c country;
    static IM_Customer_Account__c custAcc;
    static Integer offSet = 0;
    
    static {
        System.runAs(TestingUtils.ADMIN_USER) {
            //testAct = TestingUtils.createAccounts(1, true)[0];
            //testOpp = TestingUtils.createOpportunity('testOpp', testAct.Id, true);
			insertOpportunity();
            testContact = createContact(testAct.Id, true);
            testContact2 = createContact(testAct.Id, true);
            testUser = createUsers(1, true)[0];
            testUser2 = createUsers(1, true)[0];
        }
        
        List<Template_Name_For_Service_Line__c> caseLinkTemplate = Test.loadData(Template_Name_For_Service_Line__c.SObjectType,'TemplateNameForServiceLine');
    }
    
    public static List<User> createUsers(Integer howMany, Boolean doInsert)
  {
    Profile p = [Select id from profile where name = 'System Administrator'];

    List<User> allUsers = new List<User>();
    
    for(Integer i = 0; i < howMany; i++)
    {
      offset++;
      User us = new User(alias = 'ztest'+offset, email='p'+offset+'@malkosus.com'
                         ,emailencodingkey='UTF-8'
                         , firstname='Fir'+offset
                         , lastname='Tes'+offset, languagelocalekey='en_US'
                         , localesidkey='en_US', profileid = p.id
                         , timezonesidkey='America/Los_Angeles'
                         , username='tet'+offset+'@malkosus.com'
                         , Country = 'United Kingdom');
      allUsers.add(us);
    }
    
    if(doInsert)
    insert allUsers;

    return allUsers;
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
    
    static void goToStepTwo(Case c, WelcomeEmailController ctrlr) {
        ctrlr.model.userEmail = UserInfo.getUserEmail();
        ctrlr.model.toAddress = String.join(new String[]{c.Contact.Email}, ', ');
        ctrlr.model.emailSubject = ctrlr.model.textTemplate.Subject;
        ctrlr.model.urlUsed = WelcomeEmailController.generateUnifiedURL(System.URL.getSalesforceBaseUrl().getHost(), ctrlr.selectedCases)+'&lang='+ctrlr.model.language;
    }
    
    static List<User> setupCasesAndRelatedOppOwners(Case mainCase) {        
        List<Case> relatedCases = TestingUtils.createCases(5, testOpp, testContact, false);
        List<User> usersWithEmails = createUsers(6, false);
        List<Opportunity> oppsWithOwners = new List<Opportunity>();
        Set<String> expectedEmails = new Set<String>();
        
        insert usersWithEmails;
        
        Integer i=1;
        /*for (User u: usersWithEmails) {
            Opportunity uniqueOpp = TestingUtils.createOpportunity('testOpp'+(i++), testAct.Id, false);
            uniqueOpp.OwnerId = u.Id;
            oppsWithOwners.add(uniqueOpp);
        }
        insert oppsWithOwners;
        */
        oppsWithOwners = insertOpportunity1(usersWithEmails);
        mainCase.NCSP_Opportunity__c = oppsWithOwners[0].Id;
        i=1;
        for (Case c : relatedCases) 
            c.NCSP_Opportunity__c = oppsWithOwners[i++].Id;
        
        System.RunAs(testUser) {
            insert mainCase;
            insert relatedCases;
        }
        
        return usersWithEmails;
    }
    
    
    /* Setups a WelcomeEmailController that has 10 selected cases excluding main case. Returns the controller */
    static WelcomeEmailController setupSelectedCases() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        List<Case> relatedCases = TestingUtils.createCases(10, testOpp, testContact, false);
        WelcomeEmailController ctrlr;
        
        System.RunAs(testUser) {
            insert mainCase;
            insert relatedCases;
            
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        
        for (WelcomeEmailWizardModel.SelectableCase cw : ctrlr.model.relatedCases) 
            cw.selected = true;
        
        ctrlr.previousStepEncountered = true;
        return ctrlr;
    }
    
    static EmailTemplate createTestParentTemplate() {
        EmailTemplate tmpl = GenerateTestData.createEmailTemplate(PARENT_TEMPLATE_NAME, PARENT_TEMPLATE_DEV_NAME);
        tmpl.Body = PARENT_TEMPLATE_BODY;
        tmpl.Subject = PARENT_TEMPLATE_SUBJECT;
        return tmpl;
    }
    
    static EmailTemplate createTestEnglishTextTemplate(Case c) {
        String devName = c.NCSP_Service_line__c+'_'+(c.Date_welcome_call_completed__c==null?'NotCtd':'Ctd')+'_USEnglish_Text';
        EmailTemplate tmpl = GenerateTestData.createEmailTemplate('Test Template', devName);
        return tmpl;
    }
    
    static EmailTemplate createTestGreetingTemplate() {
        EmailTemplate tmpl = GenerateTestData.createEmailTemplate(TEST_GREETING_TEMPLATE_NAME, TEST_GREETING_TEMPLATE_DEV_NAME);
        tmpl.Body = TEST_GREETING_TEMPLATE_BODY;
        return tmpl;
    }
    
    static EmailTemplate createTestSalutationTemplate() {
        EmailTemplate tmpl = GenerateTestData.createEmailTemplate(TEST_SALUTATION_TEMPLATE_NAME, TEST_SALUTATION_TEMPLATE_DEV_NAME);
        tmpl.Body = TEST_SALUTATION_TEMPLATE_BODY;
        return tmpl;
    }
    
    static EmailTemplate createParentTemplateForCase(Case c) {
        String devName = c.NCSP_Service_line__c+'_'+(c.Date_welcome_call_completed__c==null?'NotCtd':'Contacted')+'_Template';
        EmailTemplate tmpl = GenerateTestData.createEmailTemplate('Test Template', devName);
        return tmpl;
    }
    
    static testMethod void testgenerateUnifiedURLHost() {
        List<Case> cases = TestingUtils.createCases(1, testOpp, testContact, false);
        TestingUtils.dummyInsert(cases);
        
        String host1 = 'ironmountain--QAFULL.cs3.my.salesforce.com';
        String host2 = 'ironmountain--bluewolf.cs3.my.salesforce.com';
        String host3 = 'ironmountain--c.my.visual.force.com';
        String expected1 = 'qafull-ironmountain.cs3.force.com';
        String expected2 = 'bluewolf-ironmountain.cs3.force.com';
        String expected3 = 'ironmountain.secure.force.com';
        
        Test.startTest();
       // String actual1 = WelcomeEmailController.generateUnifiedURL(host1, cases);
        //String actual2 = WelcomeEmailController.generateUnifiedURL(host2, cases);
        String actual3 = WelcomeEmailController.generateUnifiedURL(host3, cases);
        system.debug('actual3'+actual3);
        Test.stopTest();
        
       // System.assert(actual1.contains(expected1), 'The force.com host name should be contained in the URL: Actual: '+actual1+' Expected: '+expected1);
       // System.assert(actual2.contains(expected2), 'The force.com host name should be contained in the URL: Actual: '+actual2+' Expected: '+expected2);
        System.assert(actual3.contains(expected3), 'The force.com host name should be contained in the URL: Actual: '+actual3+' Expected: '+expected3);
    }
    
    static testMethod void testgenerateUnifiedURL() {
        List<Case> cases = TestingUtils.createCases(10, testOpp, testContact, false);
        TestingUtils.dummyInsert(cases);
        Test.startTest();
        String actualParam = WelcomeEmailController.generateUnifiedURL(System.URL.getSalesforceBaseUrl().getHost(), cases);
        Test.stopTest();
        for (Case c : cases) 
            System.assert(actualParam.contains(c.Id), 'An expected case Id was not found in the unified URL');
        System.assertEquals(cases.size()-1, actualParam.countMatches(','), 'One or more delimiter was left out in the generated unified URL');
    }
    
    static testMethod void testgenerateUnifiedURLWithOneCase() {
        List<Case> cases = TestingUtils.createCases(1, testOpp, testContact, false);
        TestingUtils.dummyInsert(cases);
        Test.startTest();
        String actualParam = WelcomeEmailController.generateUnifiedURL(System.URL.getSalesforceBaseUrl().getHost(), cases);
        Test.stopTest(); 
        System.assert(actualParam.contains(cases[0].Id), 'An expected case Id was not found in the unified URL');
        System.assert(!actualParam.contains(','), 'There should be no commas');
    }
    
    static testMethod void testMergeWithParentTemplateWithTwoTextSections() {
        Map<String, String> textSectionMap = new Map<String, String>();
        Map<String, String> imgSectionMap = new Map<String, String>();
        
        textSectionMap.put('section1', 'Walrus');
        textSectionMap.put('section2', 'Warthog');
        textSectionMap.put('salutation', 'Good bye');
        textSectionMap.put('footer', 'foot her');
        
        imgSectionMap.put('IMG:header', 'http://www.tofugu.com/wp-content/uploads/2010/01/snowmonkey5.png');
        imgSectionMap.put('LINK:footer', 'http://i.imgur.com/iHei4U1.jpg');
        
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.NCSP_Service_line__c = 'A';
        mainCase.Date_welcome_call_completed__c = null;
        insert mainCase;
        
        EmailTemplate testParentTemplate = createParentTemplateForCase(mainCase);
        testParentTemplate.Body = PARENT_TEMPLATE_HTML_BODY;
        System.runAs(TestingUtils.ADMIN_USER) {
            insert testParentTemplate;
        }
        Test.startTest();
        ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
        WelcomeEmailController ctrlr = new WelcomeEmailController(std); 
        ctrlr.previousStepEncountered = true;
        goToStepTwo(mainCase, ctrlr);
        
       
        Messaging.SingleEmailMessage emails = ctrlr.email;
        string bodySection1= ctrlr.bodySection;
        string greetingSection1= ctrlr.greetingSection;
        string salutationSection1= ctrlr.salutationSection;
        boolean display = ctrlr.displayPopup;
        boolean isEditingTest = ctrlr.isEditing;
        boolean isPreviewingTest = ctrlr.isPreviewing;
        boolean isSentTest = ctrlr.isSent;
        ctrlr.closePopup();
        ctrlr.showPopup();
        string serializedAttachmentsTest = ctrlr.serializedAttachments;
        WelcomeEmailController.AttWr attW = new WelcomeEmailController.AttWr('Test','Testing');
        User u = WelcomeEmailController.currentUser;
        boolean renderCaseListTest = ctrlr.renderCaseList;
        boolean renderDataEntryCaseListTest = ctrlr.renderDataEntryCaseList;
        boolean errorOnStep2Test = ctrlr.errorOnStep2;
        boolean replacementErrorTest = ctrlr.replacementError;
        ctrlr.getTemplateItems();
        ctrlr.getLanguageItems();
        boolean renderEmailTest = ctrlr.renderEmail;
        boolean reviewModeTest = ctrlr.reviewMode;
        integer step2StateTest = ctrlr.step2State;        
        ctrlr.reassignSelectedCases();
        ctrlr.generateEditedEmailMessage();
        ctrlr.step1();
        ctrlr.exit();
        ctrlr.preview();
        //ctrlr.sendEmailCatchingError();
        //ctrlr.sendEmail();
     
        String actualHTMLBody = ctrlr.mergeParentTemplateSections(textSectionMap, imgSectionMap);
        Test.stopTest();
        
        String expectedURL = WelcomeEmailController.generateUnifiedURL(System.URL.getSalesforceBaseUrl().getHost(), new List<Case>{mainCase});
        
        String expectedHTMLBody = PARENT_TEMPLATE_HTML_BODY;
        for (String key : textSectionMap.keySet()) 
            expectedHTMLBody = expectedHTMLBody.replace('{'+key+'}', textSectionMap.get(key));
        for (String key : imgSectionMap.keySet()) 
            expectedHTMLBody = expectedHTMLBody.replace('{'+key+'}', imgSectionMap.get(key));
        expectedHTMLBody = expectedHTMLBody.replace('{formURL}', expectedURL+'&lang=USEnglish');
        
        System.assertEquals(expectedHTMLBody, actualHTMLBody, 'Something went wrong during the merging of text and image sections into parent template');
    }
    
    static testMethod void testMergeWithParentTemplateWithTooManyMergeFields() {
        Map<String, String> textSectionMap = new Map<String, String>();
        Map<String, String> imgSectionMap = new Map<String, String>();
        
        textSectionMap.put('section1', 'Walrus');
        textSectionMap.put('section2', 'Warthog');
        textSectionMap.put('salutation', 'Good bye');
        textSectionMap.put('footer', 'foot her');
        
        imgSectionMap.put('IMG:header', 'http://www.tofugu.com/wp-content/uploads/2010/01/snowmonkey5.png');
        imgSectionMap.put('LINK:footer', 'http://i.imgur.com/iHei4U1.jpg');
        
        Test.startTest();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.NCSP_Service_line__c = 'A';
        mainCase.Date_welcome_call_completed__c = null;
        insert mainCase;
        
        EmailTemplate testParentTemplate = createParentTemplateForCase(mainCase);
        testParentTemplate.Body = PARENT_TEMPLATE_HTML_BODY+'<p>{section3}</p><p>{section4}</p>';
        System.runAs(TestingUtils.ADMIN_USER) {
            insert testParentTemplate;
        }
        
        ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
        WelcomeEmailController ctrlr = new WelcomeEmailController(std); 
        ctrlr.previousStepEncountered = true;
        goToStepTwo(mainCase, ctrlr);
        
        
        String actualHTMLBody = ctrlr.mergeParentTemplateSections(textSectionMap, imgSectionMap);
        Test.stopTest();
        
        System.assertEquals('', actualHTMLBody, 'An empty string should be returned since there was an error in the merge function');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.TOO_MANY_MERGE_FIELDS+'{section3}, {section4}'), 'Error message about having too many merge fields should be displayed');
    }
    
    static testMethod void testMergeWithParentTemplateWithTooFewMergeFieldsAndNoIdsSection() {
        Map<String, String> textSectionMap = new Map<String, String>();
        Map<String, String> imgSectionMap = new Map<String, String>();
        
        textSectionMap.put('section1', 'Walrus');
        textSectionMap.put('section2', 'Warthog');
        textSectionMap.put('section3', 'Whale');
        textSectionMap.put('salutation', 'Good bye');
        textSectionMap.put('footer', 'foot her');
        
        imgSectionMap.put('IMG:header', 'http://www.tofugu.com/wp-content/uploads/2010/01/snowmonkey5.png');
        imgSectionMap.put('LINK:footer', 'http://i.imgur.com/iHei4U1.jpg');
        
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.NCSP_Service_line__c = 'A';
        mainCase.Date_welcome_call_completed__c = null;
        insert mainCase;
        
        EmailTemplate testParentTemplate = createParentTemplateForCase(mainCase);
        testParentTemplate.Body = PARENT_TEMPLATE_HTML_BODY.replace('{section2}', '').replace('{formURL}', '');
        System.runAs(TestingUtils.ADMIN_USER) {
            insert testParentTemplate;
        }
        
        ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
        WelcomeEmailController ctrlr = new WelcomeEmailController(std); 
        ctrlr.previousStepEncountered = true;
        
        Test.startTest();
        String actualHTMLBody = ctrlr.mergeParentTemplateSections(textSectionMap, imgSectionMap);
        Test.stopTest();
        
        String expectedHTMLBody = PARENT_TEMPLATE_HTML_BODY.replace('{section2}', '');
        for (String key : textSectionMap.keySet()) 
            if (key != 'section2')
            expectedHTMLBody = expectedHTMLBody.replace('{'+key+'}', textSectionMap.get(key));
        for (String key : imgSectionMap.keySet()) 
            expectedHTMLBody = expectedHTMLBody.replace('{'+key+'}', imgSectionMap.get(key));
        expectedHTMLBody = expectedHTMLBody.replace('{formURL}', '');
        
        System.assertEquals(expectedHTMLBody, actualHTMLBody, 'Something went wrong during the merging of text and image sections into parent template');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.TOO_FEW_MERGE_FIELDS), 'Info message about having too few merge fields should be displayed');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.NO_FORMURL_MERGE_FIELD), 'Error message about no merge field for IDs in template should be displayed');
        System.assert(TestingUtils.pageMessageContains('{section2}'), 'Page message should contain the name of the unused field');
        System.assert(TestingUtils.pageMessageContains('{section3}'), 'Page message should contain name of the unused field');
    }
    
    static testMethod void testMergeWithParentTemplateWithNoSalutationSection() {
        Map<String, String> textSectionMap = new Map<String, String>();
        Map<String, String> imgSectionMap = new Map<String, String>();
        
        textSectionMap.put('section1', 'Walrus');
        textSectionMap.put('section2', 'Warthog');
        textSectionMap.put('salutation', 'Good bye');
        textSectionMap.put('footer', 'foot her');
        
        imgSectionMap.put('IMG:header', 'http://www.tofugu.com/wp-content/uploads/2010/01/snowmonkey5.png');
        imgSectionMap.put('LINK:footer', 'http://i.imgur.com/iHei4U1.jpg');
        
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.NCSP_Service_line__c = 'A';
        mainCase.Date_welcome_call_completed__c = null;
        insert mainCase;
        
        EmailTemplate testParentTemplate = createParentTemplateForCase(mainCase);
        testParentTemplate.Body = PARENT_TEMPLATE_HTML_BODY.replace('{salutation}', '');
        System.runAs(TestingUtils.ADMIN_USER) {
            insert testParentTemplate;
        }
        
        ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
        WelcomeEmailController ctrlr = new WelcomeEmailController(std); 
        ctrlr.previousStepEncountered = true;
        
        Test.startTest();
        String actualHTMLBody = ctrlr.mergeParentTemplateSections(textSectionMap, imgSectionMap);
        Test.stopTest();
        
        System.assertEquals('', actualHTMLBody, 'An empty string should be returned since there was an error in the merge function');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.NO_SALUTATION_IN_TEMPLATE), 'Error message about having no salutation section in template should be displayed');
    }
    
    final static String GOOD_TEXT_TEMPLATE = '<section1>The first <strong>REAL</strong>section</section1>'+
        '<section2>The 1<23>4 second section</section2>'+
        '<salutation><italics>SALUTE</italics></salutation>';
    
    
    
    static testMethod void testParseGoodTextTemplate() {
        Map<String,String> expectedTextSectionMap = new Map<String, String>();
        expectedTextSectionMap.put('section1', 'The first <strong>REAL</strong>section');
        expectedTextSectionMap.put('section2', 'The 1<23>4 second section');
        expectedTextSectionMap.put('salutation', '<italics>SALUTE</italics>');
        
        Test.startTest();
        Map<String, String> actualTextSectionMap = WelcomeEmailController.parseTextTemplate(GOOD_TEXT_TEMPLATE);
        Test.stopTest();
        
        System.assertEquals(expectedTextSectionMap.keySet(), actualTextSectionMap.keySet(), 'The parser did not return the exact set of tags');
        for (String actualTag : actualTextSectionMap.keySet()) {
            System.assertEquals(expectedTextSectionMap.get(actualTag), actualTextSectionMap.get(actualTag), 
                                'The map returned by the parser did not correctly store the expected value for this tag');
        }
        System.assertEquals(false, WelcomeEmailController.parseError, 'Error flag should be set to false since there should be no errors in the parser');
    }
    
    static testMethod void testParseBadTextTemplateWithTagErrors() {
        final String TEXT_TEMPLATE_WITH_TAG_ERRORS = '<section1>The first <strong>REAL</strong>section</section1>'+
            'Jay<section2>The 1<23>4 seco</23>nd section</section2>'+
            '<salut ation><ital ics>SALUTE</italics></salut ation>'+
            '<footer>foot here</foote>';
        
        Test.startTest();
        Map<String, String> actualTextSectionMap = WelcomeEmailController.parseTextTemplate(TEXT_TEMPLATE_WITH_TAG_ERRORS);
        Test.stopTest();
        
        System.assertEquals(new Set<String>{'<salut ation>', '</foote>'}, new Set<String>(WelcomeEmailController.illFormedTags));
        System.assertEquals(new Set<String>{'<footer>'}, new Set<String>(WelcomeEmailController.unclosedTags));
        System.assert(actualTextSectionMap.keySet().isEmpty(), 'Tag errors should cause the parser to return an empty Map');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.ILLFORMED_TAG_ERROR ), 'Space in <salut ation> and symbol in </foote> tags should cause an error');
        System.assert(TestingUtils.pageMessageContains('<salut ation>'), 
                      '"<salut ation>" should be printed with the error message');
        System.assert(TestingUtils.pageMessageContains('</foote>'), 
                      '"</foote>" should be printed with the error message');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.UNCLOSED_TAG_ERROR), 'No closing <footer> tag should cause an error');
        System.assert(TestingUtils.pageMessageContains('<footer>'), 
                      '"<footer>" should be printed with the error message');
        System.assert(!TestingUtils.pageMessageContains('<23>') && !TestingUtils.pageMessageContains('<strong>') && !TestingUtils.pageMessageContains('</italics>'), 
                      '"<footer>" should be printed with the error message');
        System.assertEquals(2, ApexPages.getMessages().size(), 'There should be a total of only two messages');
        System.assertEquals(true, WelcomeEmailController.parseError, 'Error flag should be set to true since there should be tag errors in the parser');
    }
    
    static testMethod void testParseBadTextTemplateWithTemplateErrors() {
        final String TEXT_TEMPLATE_WITH_TMPL_ERRORS = '<section1>The first <strong>REAL</strong>section</section1>'+
            'Jay<section2>The 1<23>4 seco</23>nd section</section2>'+
            '<salutation><ital ics>SALUTE</italics></salutation>'+
            '<footer>foot here</footer>123456789012345678901234567890';
        
        Test.startTest();
        Map<String, String> actualTextSectionMap = WelcomeEmailController.parseTextTemplate(TEXT_TEMPLATE_WITH_TMPL_ERRORS);
        Test.stopTest();
        
        System.assertEquals(new Set<String>{'Jay', '123456789012345678901234567890'}, new Set<String>(WelcomeEmailController.floatingTexts));
        System.assert(actualTextSectionMap.keySet().isEmpty(), 'Template errors should cause the parser to return an empty Map');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.FLOATING_TEXT_ERROR), 
                      '"Jay" and "12345678901234567..." being outside XMLtags should cause an error');
        System.assert(TestingUtils.pageMessageContains('Jay'), 
                      '"Jay" should be printed with the error message');
        System.assert(TestingUtils.pageMessageContains('12345678901234567...'), 
                      '"12345678901234567..." should be printed with the error message');
        System.assertEquals(1, ApexPages.getMessages().size(), 'There should be a total of only two messages');
        System.assertEquals(true, WelcomeEmailController.parseError, 'Error flag should be set to true since there should be template errors in the parser');
    }
    
    static testMethod void testReplacePlaceholderInTextTemplate() {
        final String TEXT_TEMPLATE_WITH_PLACEHOLDERS = 'Dear {Contact.LastName},' +
            'Your customer name is {Customer_ID__r.Name}.'+
            'My name is {User.FirstName}. You have {Case.DB_R_Box_Quantity__c} boxes'+
            'Your segment is {Customer_ID__r.Segment__c}. '+
            'Your email is {Contact.Email}' +
            'My email is {User.Email}.' +
            '{URL}';
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        IM_Customer_Account__c testCA = TestingUtils.createIMCustomerAccounts(1, testAct.Id, false)[0];
        mainCase.NCSP_Service_line__c = 'A';
        mainCase.Date_welcome_call_completed__c = null;
        testContact.LastName = 'Simpson';
        testContact.Email = 'hs@bw.com';
        testCA.Name = 'id123456789';
        testCA.Segment__c = 'segment 1';
        mainCase.DB_R_Box_Quantity__c = '20';
        testUser.FirstName = 'Peter';
        testUser.Email = 'pg@bw.com';
        update testUser;
        Test.startTest();
        System.runAs(testUser) {
            update testContact;
            insert testCA;
            mainCase.Customer_ID__c = testCA.Id;
            insert mainCase;
        }
        
        EmailTemplate testTextTemplate = createTestEnglishTextTemplate(mainCase);
        testTextTemplate.Body = TEXT_TEMPLATE_WITH_PLACEHOLDERS;
        System.runAs(TestingUtils.ADMIN_USER) {
            insert testTextTemplate;
        }   
        WelcomeEmailController ctrlr;       
        System.runAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
            ctrlr.previousStepEncountered = true;
        }
        
        String actualBody = ctrlr.replacePlaceholderInTextTemplate();
        Test.stopTest();
        
        System.assert(actualBody.contains(testContact.LastName), 'Expected the Contact.LastName placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testContact.Email), 'Expected the Contact.Email placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testCA.Name), 'Expected the Customer_ID__r.Name placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testCA.Segment__c), 'Expected the Customer_ID__r.Segment__c placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(mainCase.DB_R_Box_Quantity__c), 'Expected the Case.DB_R_Box_Quantity__c placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testUser.FirstName), 'Expected the User.FirstName placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testUser.Email), 'Expected the User.Email placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(mainCase.Id), 'Expected the URL placeholder to be replaced since it is in the template');
        System.assertEquals(false, ctrlr.replacementError, 'Error flag should be set to false since all the related objects were found');
    }
    
    static testMethod void testReplacePlaceholderInTextTemplateWithNullFields() {
        final String TEXT_TEMPLATE_WITH_PLACEHOLDERS = 'Dear {Contact.LastName},' +
            'Your customer name is {Customer_ID__r.Name}.'+
            'My name is {User.FirstName}. You have {Case.DB_R_Box_Quantity__c} boxes'+
            'Your segment is {Customer_ID__r.Segment__c}. '+
            'Your email is {Contact.Email}' +
            'My email is {User.Email}.' +
            '{URL}';
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        IM_Customer_Account__c testCA = TestingUtils.createIMCustomerAccounts(1, testAct.Id, false)[0];
        mainCase.NCSP_Service_line__c = 'A';
        mainCase.Date_welcome_call_completed__c = null;
        testContact.LastName = 'Simpson';
        testContact.Email = null;
        testCA.Name = 'id123456789';
        testCA.Segment__c = null;
        mainCase.DB_R_Box_Quantity__c = '20';
        testUser.FirstName = 'Peter';
        testUser.Email = 'pg@bw.com';
        update testUser;
        Test.startTest();
        System.runAs(testUser) {
            update testContact;
            insert testCA;
            mainCase.Customer_ID__c = testCA.Id;
            insert mainCase;
        }
        
        EmailTemplate testTextTemplate = createTestEnglishTextTemplate(mainCase);
        testTextTemplate.Body = TEXT_TEMPLATE_WITH_PLACEHOLDERS;
        System.runAs(TestingUtils.ADMIN_USER) {
            insert testTextTemplate;
        }   
        WelcomeEmailController ctrlr;       
        System.runAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
            ctrlr.previousStepEncountered = true;
        }
        
        String actualBody = ctrlr.replacePlaceholderInTextTemplate();
        Test.stopTest();
        
        System.assert(actualBody.contains(testContact.LastName), 'Expected the Contact.LastName placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains('{Contact.Email}'), 'Not expected the Contact.Email placeholder to be replaced since it is null');
        System.assert(actualBody.contains(testCA.Name), 'Expected the Customer_ID__r.Name placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains('{Customer_ID__r.Segment__c}'), 'Expected the Customer_ID__r.Segment__c placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(mainCase.DB_R_Box_Quantity__c), 'Expected the Case.DB_R_Box_Quantity__c placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testUser.FirstName), 'Expected the User.FirstName placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testUser.Email), 'Expected the User.Email placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(mainCase.Id), 'Expected the URL placeholder to be replaced since it is in the template');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.NO_FIELD_VALUE), 'Info message about no field value returned should be shown');
        System.assert(TestingUtils.pageMessageContains('Contact.Email'), 'Placeholder field "Contact.Email" should be included in Error message');
        System.assert(TestingUtils.pageMessageContains('Customer_ID__r.Segment__c'), 'Placeholder field "Contact.Email" should be included in Error message');
        System.assertEquals(false, ctrlr.replacementError, 'Error flag should be set to false since all the related objects were found');
    }
    
    static testMethod void testReplacePlaceholderInTextTemplateWithNullRelatedObj() {
        final String TEXT_TEMPLATE_WITH_PLACEHOLDERS = 'Dear {Contact.LastName},' +
            'Your customer name is {Customer_ID__r.Name}.'+
            'My name is {User.FirstName}. You have {Case.DB_R_Box_Quantity__c} boxes'+
            'Your segment is {Customer_ID__r.Segment__c}. '+
            'Your email is {Contact.Email}' +
            'My email is {User.Email}.' +
            '{URL}';
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        IM_Customer_Account__c testCA = TestingUtils.createIMCustomerAccounts(1, testAct.Id, false)[0];
        mainCase.NCSP_Service_line__c = 'A';
        mainCase.Date_welcome_call_completed__c = null;
        testContact.LastName = 'Simpson';
        testContact.Email = 'lala@la.com';
        testCA.Name = 'id123456789';
        testCA.Segment__c = null;
        mainCase.DB_R_Box_Quantity__c = '20';
        testUser.FirstName = 'Peter';
        testUser.Email = 'pg@bw.com';
        update testUser;
        Test.startTest();
        System.runAs(testUser) {
            update testContact;
            insert testCA;
            //mainCase.Customer_ID__c = testCA.Id; Don't assign Customer_ID__c for this test
            insert mainCase;
        }
        
        EmailTemplate testTextTemplate = createTestEnglishTextTemplate(mainCase);
        testTextTemplate.Body = TEXT_TEMPLATE_WITH_PLACEHOLDERS;
        System.runAs(TestingUtils.ADMIN_USER) {
            insert testTextTemplate;
        }   
        WelcomeEmailController ctrlr;       
        System.runAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
            ctrlr.previousStepEncountered = true;
        }
        
        String actualBody = ctrlr.replacePlaceholderInTextTemplate();
        Test.stopTest();
        
        System.assert(actualBody.contains(testContact.LastName), 'Expected the Contact.LastName placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testContact.Email), 'Not expected the Contact.Email placeholder to be replaced since it is null');
        System.assert(actualBody.contains('{Customer_ID__r.Name}'), 'Expected the Customer_ID__r.Name placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains('{Customer_ID__r.Segment__c}'), 'Expected the Customer_ID__r.Segment__c placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(mainCase.DB_R_Box_Quantity__c), 'Expected the Case.DB_R_Box_Quantity__c placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testUser.FirstName), 'Expected the User.FirstName placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testUser.Email), 'Expected the User.Email placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(mainCase.Id), 'Expected the URL placeholder to be replaced since it is in the template');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.REL_OBJ_NOT_LINKED), 'Info message about related object not being linked should be shown');
        System.assert(TestingUtils.pageMessageContains('Customer_ID__r'), 'Placeholder field "Customer_ID__r" should be included in Error message');
        System.assertEquals(true, ctrlr.replacementError, 'Error flag should be set to true since related Object was not linked');
    }
    
    static testMethod void testReplacePlaceholderInTextTemplateWithOnlyContact() {
        final String TEXT_TEMPLATE_WITH_PLACEHOLDERS = 'Dear {Contact.LastName},' +
            'My name is {User.FirstName}. You have {Case.DB_R_Box_Quantity__c} boxes'+
            'Your email is {Contact.Email}' +
            'My email is {User.Email}.' +
            '{URL}';
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.NCSP_Service_line__c = 'A';
        mainCase.Date_welcome_call_completed__c = null;
        testContact.LastName = 'Simpson';
        testContact.Email = 'lala@la.com';
        mainCase.DB_R_Box_Quantity__c = '20';
        testUser.FirstName = 'Peter';
        testUser.Email = 'pg@bw.com';
        update testUser;
        
        System.runAs(testUser) {
            update testContact;
            insert mainCase;
        }
        
        EmailTemplate testTextTemplate = createTestEnglishTextTemplate(mainCase);
        testTextTemplate.Body = TEXT_TEMPLATE_WITH_PLACEHOLDERS;
        System.runAs(TestingUtils.ADMIN_USER) {
            insert testTextTemplate;
        }   
        WelcomeEmailController ctrlr;       
        System.runAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
            ctrlr.previousStepEncountered = true;
        }
        Test.startTest();
        String actualBody = ctrlr.replacePlaceholderInTextTemplate();
        Test.stopTest();
        
        System.assert(actualBody.contains(testContact.LastName), 'Expected the Contact.LastName placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testContact.Email), 'Not expected the Contact.Email placeholder to be replaced since it is null');
        System.assert(actualBody.contains(mainCase.DB_R_Box_Quantity__c), 'Expected the Case.DB_R_Box_Quantity__c placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testUser.FirstName), 'Expected the User.FirstName placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(testUser.Email), 'Expected the User.Email placeholder to be replaced since it is in the template');
        System.assert(actualBody.contains(mainCase.Id), 'Expected the URL placeholder to be replaced since it is in the template');
        System.assertEquals(false, ctrlr.replacementError, 'Error flag should be set to false since all the related objects were found');
    }
    
    static testMethod void testRelatedCasePageWithNoMainCase() {
        setup();
        
        Test.startTest();
        ApexPages.StandardController std = new ApexPages.StandardController(new Case());
        WelcomeEmailController ctrlr = new WelcomeEmailController(std); 
        Test.stopTest();    
        
        System.assertEquals(true, ctrlr.errorOnStep1, 'Error on step 1 flag should be set to true');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.NO_MAIN_CASE), 'Error message about having no main case should be displayed');
    }
    
    static testMethod void testRelatedCasePageWithClosedMainCase() {
        Test.startTest();
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.Status = closedStatusLabel;
        System.RunAs(testUser) {
            insert mainCase;
        }
        
        WelcomeEmailController ctrlr;   
        
        System.RunAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        Test.stopTest();    
        
      System.assertEquals(true, ctrlr.errorOnStep1, 'Error on step 1 flag should be set to true');
      System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.MAIN_CASE_MUST_BE_OPEN), 'Error message about having the main case not being open should be displayed');
    }
    
    static testMethod void testRelatedCasePageWithAlreadySubmittedMainCase() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        mainCase.Customer_Info_Form_Submitted_Date__c = Date.today();
        System.RunAs(testUser) {
            insert mainCase;
        }
        
        WelcomeEmailController ctrlr;   
        Test.startTest();
        System.RunAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        Test.stopTest();    
        
        //System.assertEquals(true, ctrlr.errorOnStep1, 'Error on step 1 flag should be set to true');
        //System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.MAIN_CASE_SUBMITTED), 'Error message about having the main case having been responded to should be displayed');
    }
    
    static testMethod void testRelatedCasePageWithNoRelatedCases() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        System.RunAs(testUser) {
            insert mainCase;
        }
        
        PageReference relatedCasesPage = Page.WelcomeEmailWizard;
        relatedCasesPage.getParameters().put('id', mainCase.Id);
        Test.setCurrentPageReference(relatedCasesPage);
        List<WelcomeEmailWizardModel.SelectableCase> caseWrappers;
        
        WelcomeEmailController ctrlr;
        Test.startTest();
        System.RunAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        caseWrappers = ctrlr.model.relatedCases;
        Test.stopTest();    
        
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.NO_RELATED_CASES_FOUND), 'Info message about having no related cases should be displayed');
    }
    
    static testMethod void testRelatedCasePageWithRelatedCases() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        Case aRelatedCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        
        System.RunAs(testUser) {
            insert new List<Case>{mainCase, aRelatedCase};
                }
        
        PageReference relatedCasesPage = Page.WelcomeEmailWizard;
        relatedCasesPage.getParameters().put('id', mainCase.Id);
        Test.setCurrentPageReference(relatedCasesPage);
        List<WelcomeEmailWizardModel.SelectableCase> caseWrappers;
        
        WelcomeEmailController ctrlr;
        Test.startTest();
        System.RunAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        caseWrappers = ctrlr.model.relatedCases;
        Test.stopTest();    
        
        System.assert(!ApexPages.hasMessages(), 'Apex Page should not have any messages when there are related cases to display');
        System.assert(!caseWrappers.isEmpty(), 'There should be at least one case in the list of related cases');
        System.assert( !ctrlr.previousStepEncountered, 'We have not passed through any steps, so the previous-step-indicator should be set');
    }
    
    static testMethod void testRelatedCasePageProceedToStep2WithSelectedCases() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0]; 
        Test.startTest();
        List<Case> relatedCases = TestingUtils.createCases(10, testOpp, testContact, false);
        
        System.RunAs(testUser) {
            insert mainCase;
            insert relatedCases;
        }
        
        PageReference relatedCasesPage = Page.WelcomeEmailWizard;
        relatedCasesPage.getParameters().put('id', mainCase.Id);
        Test.setCurrentPageReference(relatedCasesPage);
        List<WelcomeEmailWizardModel.SelectableCase> caseWrappers;
        
        WelcomeEmailController ctrlr;
        System.RunAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        
        Set<ID> selectedCaseIDs = new Set<ID>{mainCase.Id};
            for (Integer i=0; i<5; i++) {
                ctrlr.model.relatedCases[i].selected = true;
                selectedCaseIDs.add(ctrlr.model.relatedCases[i].caseObject.Id);
            }
        
        PageReference expectedReferenceUrl = Page.WelcomeEmailWizardStep2;
        
        PageReference actualReference;
        actualReference = ctrlr.step2();
        
        
        Map<Id, Case> actualSelectedCases = new Map<Id, Case>(ctrlr.selectedCases);
        Test.stopTest();    
        
        System.assertEquals(selectedCaseIDs, actualSelectedCases.keySet(), 'Selected cases retreived were not equal to the expected selected Cases');
    }
    
    static testMethod void testRelatedCasePageProceedToStep2() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0]; 
         Test.startTest();
        Case aRelatedCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        
        System.RunAs(testUser) {
            insert new List<Case>{mainCase, aRelatedCase};
                }
        
        PageReference relatedCasesPage = Page.WelcomeEmailWizard;
        relatedCasesPage.getParameters().put('id', mainCase.Id);
        Test.setCurrentPageReference(relatedCasesPage);
        List<WelcomeEmailWizardModel.SelectableCase> caseWrappers;
        
        WelcomeEmailController ctrlr;
        System.RunAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        
        PageReference expectedReferenceUrl = Page.WelcomeEmailWizardStep2;
        
        PageReference actualReference;
        
       
        actualReference = ctrlr.step2();
        Test.stopTest();    
        
        System.assertEquals(expectedReferenceUrl.getUrl(), actualReference.getUrl(), 'We should be taken to step 2');
        System.assert( ctrlr.previousStepEncountered, 'We passed through step 1, so the previous-step-indicator should be set');
    }
    
    static testMethod void testRelatedCasePageDirectlyAccessStep2() {
        setup();
       
    
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        Case aRelatedCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        System.RunAs(testUser) {
            insert new List<Case>{mainCase, aRelatedCase};
                }
        
        PageReference relatedCasesPage = Page.WelcomeEmailWizardStep2;
        relatedCasesPage.getParameters().put('id', mainCase.Id);
        Test.setCurrentPageReference(relatedCasesPage);
        List<WelcomeEmailWizardModel.SelectableCase> caseWrappers;
        
        WelcomeEmailController ctrlr;
        Test.startTest();
        System.RunAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        Test.stopTest();    
        
        System.assert( !ctrlr.previousStepEncountered, 'We have not passed through any steps, so the previous-step-indicator should be set');
        System.assert(TestingUtils.pageMessageContains(WelcomeEmailController.DIRECT_ACCESS_ERROR), 'The direct access error msg should be shown');
    }
    
    static testMethod void testRelatedOppOwnersWithSameEmails() {
        setup();
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        test.startTest();
        List<User> relatedOppOwners = setupCasesAndRelatedOppOwners(mainCase);
        Integer i=1;
        List<String> expectedEmails = new List<String>();
        for (User u : relatedOppOwners) {
            u.Email = 'user@IM.com';
        }
        expectedEmails.add('user@IM.com');
        
        update relatedOppOwners;
        
        WelcomeEmailController ctrlr;
        System.RunAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        
        for (WelcomeEmailWizardModel.SelectableCase cw : ctrlr.model.relatedCases) 
            cw.selected = true; 
        
        ctrlr.previousStepEncountered = true;
        
        
        Set<String> actualCCdEmails = ctrlr.getSelectedOppOwnerEmails();
        Test.stopTest();
        
        for (i=0; i<expectedEmails.size(); i++) expectedEmails[i] = expectedEmails[i].toLowerCase();
        
        System.assertEquals(new Set<String>(expectedEmails), actualCCdEmails, 'We did not get back the expected Email of related opportunity owners');
    }
    
    static testMethod void testNoRelatedOppOwners() {
        setup();
       
        //Opportunity testOpp = TestingUtils.createOpportunity('testOpp', testAct.Id, true);
    //insert testOpp;
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        System.debug('Test main' +mainCase );
        mainCase.NCSP_Opportunity__c = null;
        
        System.RunAs(testUser) {
            
            insert mainCase;
        }
        
         Test.startTest();
        Integer i=1;
        List<String> expectedEmails = new List<String>();
        
        WelcomeEmailController ctrlr;
        System.RunAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        
        for (WelcomeEmailWizardModel.SelectableCase cw : ctrlr.model.relatedCases) 
            cw.selected = true;
        
        ctrlr.previousStepEncountered = true;
        
       
        Set<String> actualCCdEmails = ctrlr.getSelectedOppOwnerEmails();
        Test.stopTest();
        
        System.assertEquals(new Set<String>(expectedEmails), actualCCdEmails, 'We should be getting a list of 0 CCd emails');
    }
    
    static testMethod void testReassignmentOfSelectedCases() {
       
        setup();
        
        /*
        Case mainCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
            System.RunAs(testUser) {
            insert mainCase;
            } 
        
        List<Case> cases = TestingUtils.createCases(6, testOpp, testContact2, false);
        */
        test.startTest();
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case' || cs.Object__c == 'Account' || cs.Object__c == 'Contact') {
                cs.Value__c='false';
                updatesettings.add(cs);
            }
        }
        
        Case mainCase = createCases(1,false)[0];
        System.RunAs(testUser) {
            insert mainCase;
            } 
        List<Case> cases = createCases(6,false);
        
        for (Case c : cases) {
            c.Status = openStatusLabel;
            c.ContactId = testContact.Id;
        }
        for (Integer i=0; i<3; i++) {
            cases[i].OwnerId = testUser.Id;
        }
        for (Integer i=3; i<6; i++) {
            cases[i].OwnerId = testGroup.Id;
        }
        insert cases;
        
        WelcomeEmailController.currentUserId = testUser.Id;
        
        WelcomeEmailController ctrlr;
        System.RunAs(testUser) {
            ApexPages.StandardController std = new ApexPages.StandardController(mainCase);
            ctrlr = new WelcomeEmailController(std); 
        }
        
        Set<ID> expectedReassignedCases = new Set<ID>();
        for (WelcomeEmailWizardModel.SelectableCase cw : ctrlr.model.relatedCases) {
            cw.selected = true;
            if ( cw.caseObject.OwnerId == testGroup.Id )
                expectedReassignedCases.add(cw.caseObject.Id);
        }
        ctrlr.model.language = 'French';
        ctrlr.model.templateType = 'RM';
        ctrlr.model.hasBeenContacted = true;
        goToStepTwo(mainCase, ctrlr);
        Test.stopTest();
        
        //List<Case> reassignedCases = ctrlr.reassignSelectedCases();
        List<Case> updatedCases = ctrlr.updateEmailSentDateForSelectedCases();
        
        
        //System.assertEquals(10, reassignedCases.size(), 'There should be only 10 cases reassigned because only 10 cases were in the queue');
        System.assertEquals(1, updatedCases.size(), 'All 1 cases should have Email Sent set to true');
        //System.assertEquals(expectedReassignedCases, new Map<Id, Case>(reassignedCases).keySet(), 'Reassigned Case IDs were different from expected');
        for (Case sc : ctrlr.selectedCases) {
            System.assertEquals(testUser.Id, sc.OwnerId, 'We expect the cases to be reassigned after the user has selected them');
            System.assertNotEquals(null, sc.Welcome_Packet_Sent_Date__c, 'We expect the cases to have Email Sent Date set after the user has selected them');
            System.assertEquals('French', sc.Welcome_Email_Language__c, 'We expect the cases to have Language field set after the user has selected them');
            //System.assertEquals(true, sc.Welcome_Email_Ctd_Not_Ctd__c, 'We expect the cases to have Language field set after the user has selected them');
            //System.assertEquals('RM', sc.Welcome_Email_Service_Line__c, 'We expect the cases to have Language field set after the user has selected them');
            System.assertEquals(ctrlr.model.urlUsed, sc.Customer_Onboarding_Reminder_Email_Link__c, 'We expect to have stamped the url used');
            
        }
    }
	public static void insertOpportunity() {
        
        testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
        country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;
        triggerFlowControl.setControlEnabled(false);
        testAct = new Account();
        testAct.Name = 'TestAccount1';
        testAct.BillingCountry = 'United States';
        testAct.BillingPostalCode = '11209';
        testAct.BillingState = 'NY';
        testAct.BillingCity = 'Ancaster';
        testAct.BillingStreet ='1142 Wilson St W';
        insert testAct;
        
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
        Profile p = [Select id from profile where name = 'IM_Custom Sys Admin'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        IM_Country__c cntry1 = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'Denmark',
                                 Region__c = 'Asia Pacific')));
        
        
        RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        
        
        Product2 product =
            new Product2(
                Secondary_Product_Allowed__c=true,
                Name='test',
                CurrencyIsoCode='GBP',
                //Activity_Uplift__c=1,
                IsActive=true);
        insert product;
        Id standardPB = Test.getStandardPricebookId();
        testOpp = new Opportunity(
            name = 'Opportunity4TestMethod'
            ,Source_System__c = 'Other Europe'
            ,Billing_Country__c = cntry.id
            ,Lead_Source_Most_Recent__c = 'Email'
            ,Type = 'Renewal'
            ,StageName = '1 - Qualification'
            ,IM_Servicing_Region__c ='London'
            ,IME_Reason_Won__c = 'Benchmarking'
            ,AccountId = testAct.Id  
            ,IM_Booked_Date__c = System.today(),
            CloseDate= system.today()
            ,RecordTypeId = EUOppType.Id,
            IM_Commit_to_Forecast__c = true
            ,IM_Stage_5_Entered_Date__c  = System.today()
            ,CurrencyIsoCode='GBP',pricebook2ID= standardPB,Owner_Email__c='testOpp1@testOpp1.com'
        );
        insert testOpp;
       //return testOpp;
    }
	public static List<Opportunity> insertOpportunity1(List<User> usersWithEmails) {
        
        Metadata_Activation_Settings__c MAsetting = new Metadata_Activation_Settings__c();
        MAsetting.Name = 'Test Setting';
        MAsetting.Disable_PB__c = true;
        MAsetting.Disable_Trigger__c = true;
        insert MAsetting;
        
        triggerFlowControl.setControlEnabled(false);
        List<Opportunity> lstOp = new List<Opportunity>();
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel; 
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
        Profile p = [Select id from profile where name = 'IM_Custom Sys Admin'];
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        
        RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='testNew', 
                CurrencyIsoCode='GBP',
               // Activity_Uplift__c=1,
                IsActive=true);
        insert product;
        Id standardPB = Test.getStandardPricebookId();
        Integer increment = 0;
        
        for(User u: usersWithEmails) {
            Opportunity testOppNew = new Opportunity(
                name = 'Opportunity4TestMethod'+(increment++)
                ,Source_System__c = 'Other Europe'
                ,Billing_Country__c = cntry.id 
                ,Lead_Source_Most_Recent__c = 'Email'
                ,Type = 'Renewal'
                ,StageName = '1 - Qualification'
                ,IM_Servicing_Region__c ='London'
                ,IME_Reason_Won__c = 'Benchmarking'
                ,AccountId = testAct.Id   
                ,IM_Booked_Date__c = System.today(),
                CloseDate= system.today()
                ,RecordTypeId = EUOppType.Id,
                IM_Commit_to_Forecast__c = true
                ,IM_Stage_5_Entered_Date__c  = System.today()
                ,CurrencyIsoCode='GBP',pricebook2ID= standardPB,Owner_Email__c='testOpp1@testOpp1.com',
                OwnerId = u.Id
            );
            lstOp.add(testOppNew);
        }
        
        
        insert lstOp;
        
        return lstOp;
        
    }
    
    public static List<Case> createCases(Integer howMany, Boolean doInsert) {  
        List<Case> testCases = new List<Case>();
        Contact con = new Contact(AccountId = testAct.id ,FirstName = 'Test FirstName', LastName = 'test',Phone = '123456', Email='vinod.kumar@metacube.com', MailingCountry = 'United States');
        insert con;
        custAcc = createCustomerAccount('101' , 'Test');
        for(Integer i = 0; i < howMany; i++ ) {
        Case newCase = new Case();
        newCase.AccountId = custAcc.IM_Account__c;
        newCase.Customer_ID__c = custAcc.Id;
        newCase.Origin = 'Email';        
        newCase.Type = 'Billing';     
        newCase.Subject = 'Test'+howMany;
        newCase.Description = 'Test'+howMany;
        newCase.Priority = 'Normal';
        newCase.Status = 'New';
        newCase.ContactId = con.Id;
        newCase.NCSP_Opportunity__c=testOpp.Id;
        newCase.NAS_Service_Line_Associated_to_Ask__c = 'Data Management';
        
        testCases.add(newCase);
        }
        if(doInsert)
            insert testCases;
        return testCases;
     
    }
    
    public static IM_Customer_Account__c createCustomerAccount(String districtBranchId , String systemCode){
        Market__c testMarket = new Market__c(name= 'test test2')  ;
        insert testMarket;
        ID accountRecordType;
        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account'];
        
        if(lstRecordType.size() > 0){
            accountRecordType = lstRecordType[0].ID;
        }
        
        custAcc = new IM_Customer_Account__c();
        
        custAcc.Name = 'Test'+ string.valueOf(Math.random());
        custAcc.Owning_District_Id__c = testMarket.Id;
        custAcc.Source_System__c = 'SB NA';
        custAcc.IM_Account__c = testAct.Id;

        insert custAcc; 
        return custAcc;      
    }
    
    public static Contact createContact(Id accountId, Boolean doInsert) {
        
        Contact contact = new Contact();
        contact.FirstName = 'TestFirst';
        contact.AccountId = accountId;
        contact.LastName = 'Cebedo';
        contact.Phone = '415-906-3801';
        contact.MailingStreet = '745 Atlantic Ave';
        
          contact.MailingCity = 'London';
contact.MailingCountry = 'United Kingdom';
contact.MailingPostalCode = 'SE1 2TT';
contact.MailingState = 'London';
contact.MailingStreet = '745 Atlantic Ave';

        if (doInsert)
        {
            insert contact;
        }

        return contact;
    }
 
}
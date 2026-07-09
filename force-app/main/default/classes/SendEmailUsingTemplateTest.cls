/********************************************************************************************************
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 07/16/2024 (MM/DD/YYYY) - Ramya S - Updated case creation criteria to 'IND_Email_CS', Added new methods - GitLab #17164
* 
********************************************************************************************************/
@isTest
public class SendEmailUsingTemplateTest {

       
    @istest static void test_method_Closed(){
        
        List<SendEmailUsingTemplate.DataWrapper> dw= new List<SendEmailUsingTemplate.DataWrapper>();
        
        SendEmailUsingTemplate.DataWrapper testdata = new SendEmailUsingTemplate.DataWrapper();
        Contact testContact = new Contact(LastName ='Test Contact', Email='simranjit.kaur.prtnr@ironmountain.com');
        insert testContact;
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'MYS_EMAIL_CS', IME_SC_Country__C= 'Malaysia');
        testCase.ContactId= testContact.Id;
        insert testCase;
        testdata.recordID=(testCase.Id);
        testdata.toAddress=(testContact.email);
		testdata.country = (testCase.IME_SC_Country__C);
        testdata.contactId=(testContact.Id);
        testdata.origin=(testCase.Origin);
        testdata.recordTypeName='Global Service Case';
        testdata.type='Closed';
        dw.add(testdata);

        SendEmailUsingTemplate.SendEmailTemplateWithTemplate(dw);
    
    }
    
      @istest static void test_method_Closed_Global_Orders(){
        
        List<SendEmailUsingTemplate.DataWrapper> dw= new List<SendEmailUsingTemplate.DataWrapper>();
        
        SendEmailUsingTemplate.DataWrapper testdata = new SendEmailUsingTemplate.DataWrapper();
        Contact testContact = new Contact(LastName ='Test Contact', Email='simranjit.kaur.prtnr@ironmountain.com');
        insert testContact;
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'HKG_EMAIL_CS', IME_SC_Country__C= 'Hong Kong');
        testCase.ContactId= testContact.Id;
        insert testCase;
        testdata.recordID=(testCase.Id);
        testdata.toAddress=(testContact.email);
		testdata.country = (testCase.IME_SC_Country__C);
        testdata.contactId=(testContact.Id);
        testdata.origin=(testCase.Origin);
        testdata.recordTypeName='Global Orders';
        testdata.type='Closed';
        dw.add(testdata);

        SendEmailUsingTemplate.SendEmailTemplateWithTemplate(dw);
    }
    
    @istest static void test_method_Reopened(){
        
        List<SendEmailUsingTemplate.DataWrapper> dw= new List<SendEmailUsingTemplate.DataWrapper>();
        
        SendEmailUsingTemplate.DataWrapper testdata = new SendEmailUsingTemplate.DataWrapper();
        Contact testContact = new Contact(LastName ='Test Contact', Email='simranjit.kaur.prtnr@ironmountain.com');
        insert testContact;
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'HKG_EMAIL_CS', IME_SC_Country__C= 'Hong Kong');
        testCase.ContactId= testContact.Id;
        insert testCase;
        testdata.recordID=(testCase.Id);
        testdata.toAddress=(testContact.email);
		testdata.country = (testCase.IME_SC_Country__C);
        testdata.contactId=(testContact.Id);
        testdata.origin=(testCase.Origin);
        testdata.type='Reopened';
        dw.add(testdata);

        SendEmailUsingTemplate.SendEmailTemplateWithTemplate(dw);
    
    }
    
    @istest static void test_method_New(){
        
        List<SendEmailUsingTemplate.DataWrapper> dw= new List<SendEmailUsingTemplate.DataWrapper>();
        
        SendEmailUsingTemplate.DataWrapper testdata = new SendEmailUsingTemplate.DataWrapper();
        Contact testContact = new Contact(LastName ='Test Contact', Email='simranjit.kaur.prtnr@ironmountain.com');
        insert testContact;
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'HKG_EMAIL_CS', IME_SC_Country__C= 'Hong Kong');
        testCase.ContactId= testContact.Id;
        insert testCase;
        testdata.recordID=(testCase.Id);
        testdata.toAddress=(testContact.email);
		testdata.country = (testCase.IME_SC_Country__C);
        testdata.contactId=(testContact.Id);
        testdata.origin=(testCase.Origin);
        testdata.type='New';
        dw.add(testdata);

        SendEmailUsingTemplate.SendEmailTemplateWithTemplate(dw);
    
    }
    @istest static void test_method_Closed_Default(){
        
        List<SendEmailUsingTemplate.DataWrapper> dw= new List<SendEmailUsingTemplate.DataWrapper>();
        
        SendEmailUsingTemplate.DataWrapper testdata = new SendEmailUsingTemplate.DataWrapper();
        Contact testContact = new Contact(LastName ='Test Contact', Email='simranjit.kaur.prtnr@ironmountain.com');
        insert testContact;
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'IND_Email_CS', IME_SC_Country__C= 'India');
        testCase.ContactId= testContact.Id;
        insert testCase;
        testdata.recordID=(testCase.Id);
        testdata.toAddress=(testContact.email);
		testdata.country = (testCase.IME_SC_Country__C);
        testdata.contactId=(testContact.Id);
        testdata.origin=(testCase.Origin);
        testdata.recordTypeName='Global Service Case';
        testdata.type='Closed';
        dw.add(testdata);
        SendEmailUsingTemplate.SendEmailTemplateWithTemplate(dw);
    }
    @istest static void test_method_Closed_Global_Orders_Default(){
        
        List<SendEmailUsingTemplate.DataWrapper> dw= new List<SendEmailUsingTemplate.DataWrapper>();
        
        SendEmailUsingTemplate.DataWrapper testdata = new SendEmailUsingTemplate.DataWrapper();
        Contact testContact = new Contact(LastName ='Test Contact', Email='simranjit.kaur.prtnr@ironmountain.com');
        insert testContact;
        Case testCase= new Case (Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'IND_Email_CS', IME_SC_Country__C= 'Hong Kong');
        testCase.ContactId= testContact.Id;
        insert testCase;
        testdata.recordID=(testCase.Id);
        testdata.toAddress=(testContact.email);
		testdata.country = (testCase.IME_SC_Country__C);
        testdata.contactId=(testContact.Id);
        testdata.origin=(testCase.Origin);
        testdata.recordTypeName='Global Orders';
        testdata.type='Closed';
        dw.add(testdata);

        SendEmailUsingTemplate.SendEmailTemplateWithTemplate(dw);
    }
	    // GitLab #17164 Created new method to improve code coverage
     @isTest
static void test_method_Closed_With_No_Template() {
    List<SendEmailUsingTemplate.DataWrapper> dw = new List<SendEmailUsingTemplate.DataWrapper>();
    SendEmailUsingTemplate.DataWrapper testdata = new SendEmailUsingTemplate.DataWrapper();
    
    Contact testContact = new Contact(LastName ='Test Contact', Email='ramya.s.prtnr@ironmountain.com');
    insert testContact;

    Case testCase = new Case(Subject='Test Case', Description='Test Case', Priority='Medium', Origin='NO_TEMPLATE_ORIGIN', IME_SC_Country__C='Unknown Country');
    testCase.ContactId = testContact.Id;
    insert testCase;

    testdata.recordID = testCase.Id;
    testdata.toAddress = testContact.Email;
    testdata.country = testCase.IME_SC_Country__C;
    testdata.contactId = testContact.Id;
    testdata.origin = testCase.Origin;
    testdata.recordTypeName = 'Global Service Case';
    testdata.type = 'Closed';
    dw.add(testdata);

    // Use System.assertThrows to check for exceptions
    Test.startTest();
    Exception thrownException;
    try {
        SendEmailUsingTemplate.SendEmailTemplateWithTemplate(dw);
    } catch (Exception e) {
        thrownException = e;
    }
    Test.stopTest();

    // Assert that the exception message contains 'List index out of bounds'
    System.assertNotEquals(null, thrownException, 'Expected an exception to be thrown');
    System.assert(thrownException.getMessage().contains('List index out of bounds'), 'Expected exception message not found');
}

// GitLab #17164 Created new method to improve code coverage 
    @isTest static void test_method_Reopened_Notification_Disabled() {
        List<SendEmailUsingTemplate.DataWrapper> dw = new List<SendEmailUsingTemplate.DataWrapper>();
        SendEmailUsingTemplate.DataWrapper testdata = new SendEmailUsingTemplate.DataWrapper();
        Contact testContact = new Contact(LastName ='Test Contact', Email='ramya.s.prtnr@ironmountain.com');
        insert testContact;

        Case testCase = new Case(Subject='Test Case', Description='Test Case', Priority = 'Medium', Origin= 'REOPENED_ORIGIN', IME_SC_Country__C= 'Hong Kong');
        testCase.ContactId = testContact.Id;
        insert testCase;

        testdata.recordID = testCase.Id;
        testdata.toAddress = testContact.Email;
        testdata.country = testCase.IME_SC_Country__C;
        testdata.contactId = testContact.Id;
        testdata.origin = testCase.Origin;
        testdata.recordTypeName = 'Global Service Case';
        testdata.type = 'Reopened';
        dw.add(testdata);

        // Simulate that no email should be sent
        SendEmailUsingTemplate.SendEmailTemplateWithTemplate(dw);
    }
}
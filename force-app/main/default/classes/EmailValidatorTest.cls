/********************************************************************************************************
* @Description: This Apex Class is test class for the class "EmailValidator"
* @Copyright: Iron Mountain
* @Author: Simranjit Kaur
* @Created on:  09/25/2024(MM/DD/YYYY)
* @MainClass Name: EmailValidator
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 09/25/2024 - Simranjit Kaur - Initial Development - GitLab #26421
* ===================================================
*
********************************************************************************************************/
@isTest
public class EmailValidatorTest {
    @isTest
    static void testValidateEmailAddresses() {
        // Test 1: All valid emails
        EmailValidator.EmailInput input1 = new EmailValidator.EmailInput();
        input1.toAddress = 'user1@example.com;user2@ironmountain.com';
        input1.ccAddress = 'user3@example.com';
        input1.bccAddress = 'user4@ironmountain.com';
        input1.contactDomain = 'example.com';

        // Test 2: Invalid email domain
        EmailValidator.EmailInput input2 = new EmailValidator.EmailInput();
        input2.toAddress = 'user5@invalid.com';
        input2.ccAddress = 'user6@ironmountain.com';
        input2.bccAddress = null; // No Bcc addresses
        input2.contactDomain = 'example.com';

        // Test 3: Mixed valid and invalid emails
        EmailValidator.EmailInput input3 = new EmailValidator.EmailInput();
        input3.toAddress = 'user7@example.com;user8@invalid.com';
        input3.ccAddress = 'user9@ironmountain.com';
        input3.bccAddress = 'user10@example.com';
        input3.contactDomain = 'example.com';

        // Add inputs to a list
        List<EmailValidator.EmailInput> emailInputs = new List<EmailValidator.EmailInput>{
            input1, input2, input3
        };

        // Execute the method
        List<EmailValidator.ValidationResult> results = EmailValidator.validateEmailAddresses(emailInputs);

        // Validate results
        System.assertEquals(3, results.size(), 'Should have 3 results for 3 inputs.');

        // Test 1: All valid emails
        System.assertEquals(true, results[0].isValid, 'Test 1 should be valid.');

        // Test 2: Invalid email domain
        System.assertEquals(false, results[1].isValid, 'Test 2 should be invalid.');

        // Test 3: Mixed valid and invalid emails
        System.assertEquals(false, results[2].isValid, 'Test 3 should be invalid due to one invalid email.');
    }
}
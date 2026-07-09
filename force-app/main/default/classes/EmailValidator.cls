/********************************************************************************************************
* @Description: This Apex Class is created to validate email addresses entered by agents while sending emails. It will stop checking after the first invalid email and return the result.
		It is getting used in Flow "Contact Escalation Emails to Non Contacts" API Name: "Contact_Escalation_Emails_to_Non_Contacts"
		It compares the email address with the Contact Domain and "ironmountain" keyword and returns boolean "IsValid" false when the criteria does not match.
* @Copyright: Iron Mountain
* @Author: Simranjit Kaur
* @Created on:  09/25/2024(MM/DD/YYYY)
* @TestClass Name: EmailValidatorTest
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 09/25/2024 - Simranjit Kaur - Initial Development - GitLab #26421
* ===================================================
*
********************************************************************************************************/
public class EmailValidator {
    @InvocableMethod(label='Validate Email Addresses' description='Validates and sums email addresses from To, Cc, and Bcc fields')
    public static List<ValidationResult> validateEmailAddresses(List<EmailInput> emailInputs) {
        List<ValidationResult> results = new List<ValidationResult>();
        
        for (EmailInput input : emailInputs) {
            ValidationResult result = new ValidationResult();
			result.isValid = true; // Assume valid until proven otherwise

            // Collect all email addresses and split them
            List<String> emailList = new List<String>();
            if(input.toAddress != null){ emailList.addAll(input.toAddress.split(';')); }
            if(input.ccAddress != null){ emailList.addAll(input.ccAddress.split(';')); }
            if(input.bccAddress != null){ emailList.addAll(input.bccAddress.split(';')); }

            // Iterate over the email addresses
            for (String email : emailList) {
                email = email.trim(); // Remove extra spaces
                String domain = email.substringAfter('@').toLowerCase();
                if (!(domain.endsWith(input.contactDomain) || domain.contains('ironmountain'))) {
                    result.isValid = false;
                    break; // Stop checking after the first invalid email
                }
            }
            results.add(result);
        }
        return results;
    }

    public class EmailInput {
        @InvocableVariable(label='To Addresses' description='Semicolon-separated list of email addresses for To field')
        public String toAddress;

        @InvocableVariable(label='Cc Addresses' description='Semicolon-separated list of email addresses for Cc field')
        public String ccAddress;

        @InvocableVariable(label='Bcc Addresses' description='Semicolon-separated list of email addresses for Bcc field')
        public String bccAddress;

        @InvocableVariable(label='Contact Domain' description='Email Domain of the Case contact to validate against')
        public String contactDomain;
    }

    public class ValidationResult {
        @InvocableVariable(label='Is Valid' description='Indicates if the validation passed')
        public Boolean isValid; // Boolean to indicate validation status
    }
}
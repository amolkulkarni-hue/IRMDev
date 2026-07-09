/**
 * 	Class:				CallExperienceTest
 * 
 * 	Author:			    Yashwant Verma (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for LanguageSetup apex class.
 * 
 * 	Requirements:		IMSLB-68
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@isTest
public class LanguageSetupTest {
    @isTest
    static void LanguageSetupTest1() {

        Transfer__c it = new Transfer__c();
        it.Transfer_Destination__c = '344';
        it.Transfer_Label__c = '544';
        it.Type__c ='Queue Transfer';
        it.Channel__c = 'LiveChatTranscript';
        insert it;
        
        Language_Setup__c ls = new Language_Setup__c();
        ls.Primary_Phone_Number__c = '12345678901';
        ls.Initial_Greeting_Prompt__c = 'test data';
        ls.Name = 'Test Setup';
        insert ls;
        
        Call_Experience__c ce = new Call_Experience__c();
        ce.Language_Setup__c = ls.id;
        ce.Language__c = 'English';
        ce.DTMF_Option__c = '1';
        ce.Is_Active__c = true;
        ce.Emergency_Prompt__c = '222';
        ce.Greeting_Prompt__c = 'HELLO';
        ce.Menu_Prompt__c = '12345';
        ce.Menu_Prompt_ARN__c = '123456';
        ce.Off_hours_Prompt__c ='8-6';
        ce.Working_Hours__c = null;
        ce.Immediate_Transfer_To__c = it.Id;
        insert ce;
        
        String responseReturned = LanguageSetup.LanguageSetup('12345678901');
        Assert.isTrue(responseReturned != null);
    }
    @isTest
    static void LanguageSetupTest2() {

        Transfer__c it = new Transfer__c();
        it.Transfer_Destination__c = '344';
        it.Transfer_Label__c = '544';
        it.Type__c ='Queue Transfer';
        it.Channel__c = 'LiveChatTranscript';
        insert it;
        
        Language_Setup__c ls = new Language_Setup__c();
        ls.Alternate_Phone_Number__c = '12345678901';
        ls.Primary_Phone_Number__c = '1234567890';
        ls.Initial_Greeting_Prompt__c = 'test data';
        ls.Name = 'Test Setup';
        insert ls;
        
        Call_Experience__c ce = new Call_Experience__c();
        ce.Language_Setup__c = ls.id;
        ce.Language__c = 'English';
        ce.DTMF_Option__c = '1';
        ce.Is_Active__c = true;
        ce.Emergency_Prompt__c = '222';
        ce.Greeting_Prompt__c = 'HELLO';
        ce.Menu_Prompt__c = '12345';
        ce.Menu_Prompt_ARN__c = '123456';
        ce.Off_hours_Prompt__c ='8-6';
        ce.Working_Hours__c = null;
        ce.Immediate_Transfer_To__c = it.Id;
        insert ce;
        
        String responseReturned = LanguageSetup.LanguageSetup('12345678901');
        Assert.isTrue(responseReturned != null);
    }
}
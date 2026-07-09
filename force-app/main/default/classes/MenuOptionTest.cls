/**
 * 	Class:				MenuOptionTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for MenuOption apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@isTest
public class MenuOptionTest {

    static SCVGoTestFactory testFactoryInstance = new SCVGoTestFactory();

    @isTest
    static void testGetMenuOptionObjectInstance(){
        Language_Setup__c ls = new Language_Setup__c();
        ls.Initial_Greeting_Prompt__c = 'Test Prompt';
        ls.Primary_Phone_Number__c = '+12345678901';
        ls.Alternate_Phone_Number__c = '+1234567890';
        insert ls;
        
        Call_Experience__c sampleIVRExp = new Call_Experience__c();
        sampleIVRExp.Is_Active__c = true;
        sampleIVRExp.Emergency_Prompt__c = '222';
        sampleIVRExp.Greeting_Prompt__c = 'HELLO';
        sampleIVRExp.Menu_Prompt__c = '12345';
        sampleIVRExp.Menu_Prompt_ARN__c = '123456';
        sampleIVRExp.Off_hours_Prompt__c = '8-6';
        sampleIVRExp.Working_Hours__c = null;
        sampleIVRExp.Immediate_Transfer_To__c = null;
        sampleIVRExp.Language__c = 'English';
        sampleIVRExp.Language_Selection_Prompt__c = 'Test Prompt';
        sampleIVRExp.Language_Setup__c = ls.Id;
		sampleIVRExp.DTMF_Option__c = '1';        
        insert sampleIVRExp;

        Menu_Option__c sampleMenu = new Menu_Option__c();
        sampleMenu.Sub_menu_Prompt__c = 'Press 1 for Order Placement. Press 2 for Order ETA.';
        sampleMenu.User_Choice__c = '1'; 
        sampleMenu.Type__c = 'Sub-menu';
        sampleMenu.Contact_Flow_ARN__c = '';
        sampleMenu.Self_service_Message__c = '';
        sampleMenu.Transfer_To__c = null;
        sampleMenu.Call_Experience__c = null;
        sampleMenu.Parent_Menu__c = null;
        sampleMenu.Call_Experience__c = sampleIVRExp.Id;
        insert sampleMenu;
        
        MenuOption m = new MenuOption(sampleMenu);
        Assert.areEqual(sampleIVRExp.Id, m.getMenuOptionObjectInstance().Call_Experience__c);
    }
}
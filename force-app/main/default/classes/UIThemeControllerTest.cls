@isTest
public class UIThemeControllerTest {
    
    static testMethod void getCurrentTheme() {
        UIThemeController theme = new UIThemeController();
        integer cnt = 0;
        string myTheme = UIThemeController.getUIThemeDescription();
        if (myTheme == 'Salesforce Classic') {
            cnt = cnt+1;
        }
        if (myTheme == 'Lightning Experience') {
            cnt = cnt+1;
        }
        if (myTheme == 'Salesforce1 Mobile') {
            cnt = cnt+1;
        }
		system.assertEquals(1, cnt);     
    }

}
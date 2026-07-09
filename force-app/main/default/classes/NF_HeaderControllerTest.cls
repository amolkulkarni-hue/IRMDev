/**
 * @description       : Test class for NF_HeaderController
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 10-28-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@isTest(seeAllData = true)
public class NF_HeaderControllerTest {
    @isTest
    static void getNavigationMenuItemsTest(){
        Test.startTest();

        String label = [SELECT MasterLabel FROM NavigationLinkSet LIMIT 1].MasterLabel;
        List<ConnectApi.NavigationMenuItem> response =
            NF_HeaderController.getNavigationMenuItems(null, label, true);
        System.assert(!response.isEmpty(), 'Response Not Empty');

        Test.stopTest();
    }

    @isTest
    static void getNetworkAndUserDetailsTest(){
        Test.startTest();

        Map<String, Object> response = NF_HeaderController.getNetworkAndUserDetails('["en_US"]');
        System.assert(response.get('selectedLanguage') == UserInfo.getLanguage(), 'Language retrieved.');

        Test.stopTest();
    }

    @isTest
    static void setUserLanguageTest(){
        Test.startTest();

        List<String> languages = new List<String>{'en_US', 'de', 'de_AB', 'ab_CD'};
        Boolean isError = false;

        for(String eachLanguage : languages){
            isError = NF_HeaderController.setUserLanguage(eachLanguage);
        }

        System.assert(isError, 'Error');

        Test.stopTest();
    }
}
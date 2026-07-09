/**
 * @description       : Test class for ExperienceSocialNavigationMenus
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 06-10-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@isTest(seeAllData = false)
public class ExperienceSocialNavigationMenusTest {
    @isTest
    public static void picklistValueTest(){
        Test.startTest();

        ExperienceSocialNavigationMenus objClass = new ExperienceSocialNavigationMenus();
        VisualEditor.DynamicPickListRows allPicklist = objClass.getValues();
        VisualEditor.DataRow defaultPicklistRecord = objClass.getDefaultValue();
        System.assertEquals('--None--', defaultPicklistRecord.getLabel(), 'Default label is --None--');
        System.assertEquals(true, allPicklist.size() > 0, 'At least the default option is present');

        Test.stopTest();
    }
}
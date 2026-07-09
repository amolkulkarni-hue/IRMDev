/**
 * @description       : Test class for ExperienceNavigationMenus
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 06-10-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
@isTest(seeAllData = false)
public class ExperienceNavigationMenusTest {
    @isTest
    public static void picklistValueTest(){
        Test.startTest();

        ExperienceNavigationMenus objClass = new ExperienceNavigationMenus();
        VisualEditor.DynamicPickListRows allPicklist = objClass.getValues();
        VisualEditor.DataRow defaultPicklistRecord = objClass.getDefaultValue();
        System.assertEquals('--None--', defaultPicklistRecord.getLabel(), 'Default label is --None--');

        allPicklist = objClass.getValues();
        System.assertEquals(true, allPicklist.size() > 1, 'More than one option available to choose from');

        Test.stopTest();
    }
}
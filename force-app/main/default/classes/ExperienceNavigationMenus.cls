/**
 * @description       : Returns a picklict of Main Menus for selection in experience builder
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 10-10-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
global without sharing class ExperienceNavigationMenus extends VisualEditor.DynamicPickList{
    /**
    * @description Method of the VisualEditor.DynamicPickList abstract class returning a default value
    * @author chayan.batabyal@neuraflash.com | 05-16-2022
    * @return VisualEditor.DataRow
    **/
    global override VisualEditor.DataRow getDefaultValue(){
        return getBlankRow();
    }

    /**
    * @description VisualEditor.DynamicPickList returning the picklist records to be displayed
    * @author chayan.batabyal@neuraflash.com | 05-16-2022
    * @return VisualEditor.DynamicPickListRows
    **/
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows picklistEntries = new VisualEditor.DynamicPickListRows();
        picklistEntries.addRow(getBlankRow());
        List<NavigationLinkSet> navs = [
            SELECT Id, MasterLabel, Network.Name FROM NavigationLinkSet
            WHERE NOT(MasterLabel Like '%Profile%')
        ];

        for(NavigationLinkSet eachNav : navs){
            VisualEditor.DataRow eachPicklistEntry = new VisualEditor.DataRow(
                eachNav.Network.Name + ' - ' + eachNav.MasterLabel, String.valueOf(eachNav.Id)
            );
            picklistEntries.addRow(eachPicklistEntry);
        }

        return picklistEntries;
    }

    /**
    * @description Creates blank option to be displayed on the experience builder
    * @author chayan.batabyal@neuraflash.com | 05-16-2022
    * @return VisualEditor.DataRow
    **/
    private VisualEditor.DataRow getBlankRow(){
        return new VisualEditor.DataRow('--None--', '', true);
    }
}
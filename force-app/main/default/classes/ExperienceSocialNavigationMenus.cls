/**
 * @description       : Returns a picklict of social menus for selection in experience builder
 * @author            : chayan.batabyal@neuraflash.com
 * @last modified on  : 06-10-2022
 * @last modified by  : chayan.batabyal@neuraflash.com
**/
global without sharing class ExperienceSocialNavigationMenus extends VisualEditor.DynamicPickList{
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
        Set<String> configNameSet = new Set<String>();

        for(EEC_Social_Navigation__mdt eachSocialMenuItem : [
            SELECT Footer_Config_Name__c
            FROM EEC_Social_Navigation__mdt
            WHERE Active__c = true
        ]){
            if(!configNameSet.contains(eachSocialMenuItem.Footer_Config_Name__c)){
                configNameSet.add(eachSocialMenuItem.Footer_Config_Name__c);
                VisualEditor.DataRow eachPicklistEntry = new VisualEditor.DataRow(
                    eachSocialMenuItem.Footer_Config_Name__c, eachSocialMenuItem.Footer_Config_Name__c
                );
                picklistEntries.addRow(eachPicklistEntry);
            }
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
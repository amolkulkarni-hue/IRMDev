/**
**Author: Paul R
**Date: 10/10/13
**Company: Bluewolf
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 10/10/2013; Paul R/Bluewolf; Cac Responsiblity Mass Create controller - Multiple row insertion for  Cac Responsiblity; Initial release
**/
public with sharing class CACResponsibilityController {
    public IME_SC_CAc_Responsibility__c cacResponsibility {get;set;}
    public PageReference returnPage {get;set;}
    public List<String> selections {get;set;}     
    public String error {get;set;}

    public CACResponsibilityController() {
        
        cacResponsibility = new IME_SC_CAc_Responsibility__c();     
        cacResponsibility.IME_SC_Contact__c = ApexPages.currentPage().getParameters().get('contactId');
        cacResponsibility.IME_SC_Customer_Account__c = ApexPages.currentPage().getParameters().get('caId');
        returnPage = new PageReference('/'+ApexPages.currentPage().getParameters().get('retUrl'));
        
    }
    public List<Schema.PicklistEntry> picker { 
        
        get{        
            Schema.DescribeFieldResult F = IME_SC_CAc_Responsibility__c.IME_CAc_Responsibility__c.getDescribe();
            List<Schema.PicklistEntry> picker = F.getPicklistValues();
            return picker;
        }       
        set;
    }
    
    public List<SelectOption> responsibilityOptions { 
        get{
            List<selectOption> responsibilityOptions = new List<selectOption>();
            Schema.DescribeFieldResult F = IME_SC_CAc_Responsibility__c.IME_CAc_Responsibility__c.getDescribe();
            List<Schema.PicklistEntry> pickerValues = F.getPicklistValues();
            for (Schema.PicklistEntry pickerValue : pickerValues){
                responsibilityOptions.add(new SelectOption(pickerValue.getValue(),pickerValue.getValue()));
            }           
            return responsibilityOptions;
        }
        set;
    }

    public PageReference save(){
        
        PageReference  pageRef = ApexPages.currentPage();
        List<IME_SC_CAc_Responsibility__c> newResponsibilities = new List<IME_SC_CAc_Responsibility__c>();
        List<IME_SC_CAc_Responsibility__c> existingResponsibilities = new List<IME_SC_CAc_Responsibility__c>();
        List<IME_SC_CAc_Responsibility__c> existingResponsibilitiesForOtherContacts = new List<IME_SC_CAc_Responsibility__c>();
        
        if (selections.isEmpty()){
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR ,Label.ERRMSG_Select_Reponsibility));           
            return null;
        }
        
        existingResponsibilities.addAll([Select id,IME_CAc_Responsibility__c from IME_SC_CAc_Responsibility__c where IME_SC_Contact__c = : cacResponsibility.IME_SC_Contact__c and IME_SC_Customer_Account__c = :cacResponsibility.IME_SC_Customer_Account__c ]);
        existingResponsibilitiesForOtherContacts.addAll([Select id,IME_CAc_Responsibility__c from IME_SC_CAc_Responsibility__c where IME_SC_Contact__c != : cacResponsibility.IME_SC_Contact__c and IME_SC_Customer_Account__c = :cacResponsibility.IME_SC_Customer_Account__c and IME_CAc_Responsibility__c in: selections]);
        
        for (IME_SC_CAc_Responsibility__c existingResponsibility :existingResponsibilitiesForOtherContacts){
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR ,existingResponsibility.IME_CAc_Responsibility__c +Label.ERRMSG_Contact_Responsibility_already_exists));
        }
        if (Apexpages.hasMessages()){
            return null;
        }
        
        Set<String> currentSelection = new Set<String>();
        for (IME_SC_CAc_Responsibility__c existingResponsibility :existingResponsibilities){
            currentSelection.add(existingResponsibility.IME_CAc_Responsibility__c);
        }

        for(String selection: selections){
            if (!currentSelection.contains(selection)){
                    newResponsibilities.add(new IME_SC_CAc_Responsibility__c(
                    IME_CAc_Responsibility__c = selection,
                    IME_SC_Contact__c =  cacResponsibility.IME_SC_Contact__c,
                    IME_SC_Customer_Account__c = cacResponsibility.IME_SC_Customer_Account__c
                ));
            }
        }
        if (!newResponsibilities.isEmpty()){

            try{
                insert newResponsibilities;                 
            } catch(Exception exc){
                error = exc.getMessage();
                if (exc.getMessage().contains(''+Label.ERRMSG_Select_Contact_for_Account)){
                    Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR ,Label.ERRMSG_Different_Account_Hierarchy));
                }else{
                    Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR ,exc.getMessage()));                    
                }
                return null;                
            }       
        }

        return returnPage;
    }
        
    public PageReference cancel(){
        
        return returnPage;

    }
}
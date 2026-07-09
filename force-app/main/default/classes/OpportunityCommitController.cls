/*
Auhtor      : Pratibh Prakash
Company     : Fujitsu America
Created Date: 14 Sep-2009
Modified    : 
Description : Controller class for VisualForce page 'OpportunityCommit'.
*/
public with sharing class OpportunityCommitController {
    private Boolean CustomHelpFlag;
    private Boolean SupressPopupFlag;
    private User curUser;
    public void setCustomHelpFlag(Boolean setterVal){ this.CustomHelpFlag = setterVal; } public Boolean getCustomHelpFlag(){ return this.CustomHelpFlag; }
    public void setSupressPopupFlag(Boolean setterVal){ this.SupressPopupFlag = setterVal; } public Boolean getSupressPopupFlag(){ return this.SupressPopupFlag; }
    
    //Constructor: getting Popup Supress field value
    public OpportunityCommitController(){
        curUser =[Select Suppress_Custom_Help_Popups__c from User where Id=: USerInfo.getUserId()];
        SupressPopupFlag = curUser.Suppress_Custom_Help_Popups__c;
    }
    //Method for committing Opportunity record. 
    public PageReference commit_uncommit_Opportunity(){
        try{
            Id oppId;
            oppId=ApexPages.currentPage().getParameters().get('oppId');
            Opportunity opp = [Select Id, IM_Commit_to_Forecast__c from Opportunity where Id=: oppId];
            if(opp.IM_Commit_to_Forecast__c == false){
                opp.IM_Commit_to_Forecast__c = true;
            }
            else{
                opp.IM_Commit_to_Forecast__c = false;
            }
        update opp;
        PageReference oppDetail = new PageReference('/'+oppId);
        oppDetail.setRedirect(true);
        return oppDetail;
        }
         catch(Exception e){
              //Apexpages.addMessages(e);
              //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Insufficient Privileges?'));
              //String error = e.getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Insufficient Privileges'));

              return null;          
        }
    }
    //Method updates Supress Custom Popups field on looged in user.
    public void updateUser(){
        //User curUser =[Select Suppress_Custom_Help_Popups__c from User where Id=: USerInfo.getUserId()];
        curUser.Suppress_Custom_Help_Popups__c = CustomHelpFlag;
        update curUser;
    }
}
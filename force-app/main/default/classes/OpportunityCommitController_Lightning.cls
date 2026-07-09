public with sharing class OpportunityCommitController_Lightning {
    private Boolean CustomHelpFlag;
    private Boolean SupressPopupFlag;
    private User curUser;
    public Id oppId{get;set;}
    public String type{get;set;}
    public void setCustomHelpFlag(Boolean setterVal){ this.CustomHelpFlag = setterVal; } public Boolean getCustomHelpFlag(){ return this.CustomHelpFlag; }
    public void setSupressPopupFlag(Boolean setterVal){ this.SupressPopupFlag = setterVal; } public Boolean getSupressPopupFlag(){ return this.SupressPopupFlag; }
    
    //Constructor: getting Popup Supress field value
    public OpportunityCommitController_Lightning(){
        curUser =[Select Suppress_Custom_Help_Popups__c from User where Id=: USerInfo.getUserId()];
        SupressPopupFlag = curUser.Suppress_Custom_Help_Popups__c;
        oppId=ApexPages.currentPage().getParameters().get('oppId');
        type=ApexPages.currentPage().getParameters().get('type');
        system.debug('oppid>>>'+oppId +'Type>>'+type);
    }
    //Method for committing Opportunity record. 
    public PageReference commit_uncommit_Opportunity(){
        try{
            //Id oppId;
            //oppId=ApexPages.currentPage().getParameters().get('oppId');
            system.debug('oppid>>>>>'+oppid);
            Opportunity opp = [Select Id, IM_Commit_to_Forecast__c from Opportunity where Id=: oppId];
            system.debug('IM_Commit_to_Forecast__c>>>'+opp.IM_Commit_to_Forecast__c);
            if(type=='add' && opp.IM_Commit_to_Forecast__c == false){
                opp.IM_Commit_to_Forecast__c = true;
            }
            else if(type=='remove' && opp.IM_Commit_to_Forecast__c == true){
                system.debug('test');
                opp.IM_Commit_to_Forecast__c = false;
            }
            else if(type=='add' && opp.IM_Commit_to_Forecast__c == true){
                CalloutException e = new CalloutException();
                e.setMessage('Opportunity has already been added to forecast.');
                throw e;
            }
            else if(type=='remove' && opp.IM_Commit_to_Forecast__c == false){
                CalloutException e = new CalloutException();
                e.setMessage('Opportunity has not yet been added to forecast.');
                throw e;
            }
            system.debug('IM_Commit_to_Forecast__c>>>'+opp.IM_Commit_to_Forecast__c);
            //update opp;
            Database.SaveResult sr = Database.update(opp, false);
            PageReference oppDetail;
            system.debug('sr.result>>>'+sr.getId());
            if(sr.isSuccess()) {
                oppDetail = new PageReference('/'+oppId);
                oppDetail.setRedirect(true);
            }
            return oppDetail;
        }
        catch(Exception e){
            system.debug('e>>'+e);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;          
        }
    }
        
    //Method updates Supress Custom Popups field on looged in user.
    public void updateUser(){
        //User curUser =[Select Suppress_Custom_Help_Popups__c from User where Id=: USerInfo.getUserId()];
        curUser.Suppress_Custom_Help_Popups__c = CustomHelpFlag;
        update curUser;
    }
    
    public pagereference Cancel(){
        PageReference oppDetail;
        //Id oppId;
        system.debug('entering cancel');
        User u = [select id,Suppress_Custom_Help_Popups__c from User where id=:UserInfo.getUserId()];
        if(u.Suppress_Custom_Help_Popups__c==false){
            //oppId = ApexPages.currentPage().getParameters().get('oppId');
            oppDetail = new PageReference('/apex/OpportunityCommitHelp_Lightning?oppid='+oppId);
            oppDetail.setRedirect(true);
        }
        else{
            oppDetail = new PageReference('/'+oppId);
            oppDetail.setRedirect(true);
        }
        return oppDetail;
    }
    public pagereference GoBack(){
        PageReference oppDetail;
            //Id oppId=ApexPages.currentPage().getParameters().get('oppId');
            oppDetail = new PageReference('/'+oppId);
            oppDetail.setRedirect(true);
        return oppDetail;
        }
}
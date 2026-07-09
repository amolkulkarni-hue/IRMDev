public with sharing class OppCustomerVerifiersContExt {

    public final Opportunity opp {get; set;}
    public final Boolean canEdit {get; private set;}
    public String mode {get; private set;}
    public String verifiers {
        get {
             String v = '';            
            if(opp.Customer_Verifier_2__c) v+='a';
            if(opp.Customer_Verifier_3__c) v+='f';
            if(opp.Customer_Verifier_4__c) v+='b';
            if(opp.Customer_Verifier_5__c) v+='c';
            if(opp.Customer_Verifier_6__c) v+='e';
            if(opp.Customer_Verifier_7__c) v+='j';
            if(opp.Customer_Verifier_8__c) v+='g';
            if(opp.Customer_Verifier_9__c) v+='l';
            if(opp.Customer_Verifier_10__c) v+='m';
            if(opp.Customer_Verifier_11__c) v+='n';
            if(opp.Customer_Verifier_12__c) v+='l';
            if(opp.Customer_Verifier_13__c) v+='k';
            if(opp.Customer_Verifier_14__c) v+='d';
            if(opp.Customer_Verifier_15__c) v+='h';
            if(opp.Customer_Verifier_16__c) v+='i';
            
            return v; 
        }
    }
    public String cv1 {get; private set;}
    public String cv2 {get; private set;}
    public String cv3 {get; private set;}
    public String cv4 {get; private set;}
    public String cv5 {get; private set;}
    public String cv6 {get; private set;}
    public String cv7 {get; private set;}
    public String cv8 {get; private set;}
    public String cv9 {get; private set;}
    public String cv10 {get; private set;}
    public String cv11 {get; private set;}
    public String cv12 {get; private set;}
    public String cv13 {get; private set;}
    public String cv14 {get; private set;}
    public String cv15 {get; private set;}
    

    /**
     * Utility function to add page messages
     */
    @TestVisible 
    private void addMessage(String message){
        addMessage('error',message);
    }
    
    @TestVisible 
    private void addMessage(String severity, String message){
        if(severity==null) severity = 'error';
        severity = severity.trim().toLowerCase();
        ApexPages.Severity sev = severity=='confirm' ? ApexPages.Severity.CONFIRM :
                                 severity=='error'   ? ApexPages.Severity.ERROR :
                                 severity=='fatal'   ? ApexPages.Severity.FATAL :
                                 severity=='info'    ? ApexPages.Severity.INFO :
                                 severity=='warning' ? ApexPages.Severity.WARNING :
                                                       ApexPages.Severity.ERROR;
        ApexPages.addMessage(new ApexPages.Message(sev, message));
    }

    public OppCustomerVerifiersContExt(ApexPages.StandardController stdController) {
        // normally, this would be accomplished by stdController.addFields()
        // however, because this page can be included in another VF page,
        // we can't add more fields this way (because the other controller
        // is already doing that).  So, back to the SOQL query method.
        Opportunity o = (Opportunity) stdController.getRecord();
        if(o.Id!=null){
            this.opp = [SELECT Id, Customer_Verifier_2__c, Customer_Verifier_3__c, Customer_Verifier_4__c, Customer_Verifier_5__c, Customer_Verifier_6__c, Customer_Verifier_7__c, Customer_Verifier_8__c, Customer_Verifier_9__c, Customer_Verifier_10__c, Customer_Verifier_11__c, Customer_Verifier_12__c, Customer_Verifier_13__c, Customer_Verifier_14__c, Customer_Verifier_15__c, Customer_Verifier_16__c FROM Opportunity WHERE Id=:stdController.getId()];
        }else{
            this.opp = o;
        }
        this.mode = 'view';
        
        cv1 = Opportunity.Customer_Verifier_2__c.getDescribe().getInlineHelpText();
        cv2 = Opportunity.Customer_Verifier_3__c.getDescribe().getInlineHelpText();
        cv3 = Opportunity.Customer_Verifier_4__c.getDescribe().getInlineHelpText();
        cv4 = Opportunity.Customer_Verifier_5__c.getDescribe().getInlineHelpText();
        cv5 = Opportunity.Customer_Verifier_6__c.getDescribe().getInlineHelpText();
        cv6 = Opportunity.Customer_Verifier_7__c.getDescribe().getInlineHelpText();
        cv7 = Opportunity.Customer_Verifier_8__c.getDescribe().getInlineHelpText();
        cv8 = Opportunity.Customer_Verifier_9__c.getDescribe().getInlineHelpText();
        cv9 = Opportunity.Customer_Verifier_10__c.getDescribe().getInlineHelpText();
        cv10 = Opportunity.Customer_Verifier_11__c.getDescribe().getInlineHelpText();
        cv11 = Opportunity.Customer_Verifier_12__c.getDescribe().getInlineHelpText();
        cv12 = Opportunity.Customer_Verifier_13__c.getDescribe().getInlineHelpText();
        cv13 = Opportunity.Customer_Verifier_14__c.getDescribe().getInlineHelpText();
        cv14 = Opportunity.Customer_Verifier_15__c.getDescribe().getInlineHelpText();
        cv15 = Opportunity.Customer_Verifier_16__c.getDescribe().getInlineHelpText();
        canEdit = true; // for now.  will replace with real security code when defined.
    }

    public void edit(){ 
        if(!canEdit){
            addMessage(Label.CustVerifierNoPermissions);
            this.mode = 'view';
            return;
        }else{
            this.mode = 'edit'; 
        }
    }
    public PageReference cancel(){ this.mode = 'view'; return null; }
    public void save(){ 
        if(canEdit && opp.Id != null){
            update opp; 
        } else if(!canEdit) {
            addMessage(Label.CustVerifierNoPermissions);
        } else {
            addMessage(Label.CustVerifierUneditable);
        }
        this.mode = 'view'; 
    }

}
public with sharing class OppRim360TrackerClass{

    public final Opportunity opp {get; set;}
    public String mode {get; private set;}
    public Boolean canEdit{get; set;}

    public String rim1 {get; private set;}
    public String rim2 {get; private set;}
   
    public OppRim360TrackerClass(ApexPages.StandardController stdController) {
       
        Opportunity opt = (Opportunity) stdController.getRecord();
        if(opt.Id!=null){
            this.opp = [SELECT Id, RIM360_1__c /* #16915, RIM360_2__c */ FROM Opportunity WHERE Id=:stdController.getId()];
        }else{
            this.opp = opt;
        }
        this.mode = 'view';
        
        rim1 = Opportunity.RIM360_1__c.getDescribe().getInlineHelpText();
        // #16915 rim2 = Opportunity.RIM360_2__c .getDescribe().getInlineHelpText();
      canEdit=true;
    }
    
    
    public void edit()
    {
        if(!canEdit){
             addMessage('error',Label.CustRIMNoPermissions);
            this.mode = 'view';
            return;
        }else{
            this.mode = 'edit'; 
        } 
    }
    
    public void save()
    {
        if(canEdit && opp.Id != null) {
            update opp; 
            
        } 
    /*    else if(opp.RIM360_1__c == false && opp.RIM360_2__c == false && opp.RIM360_3__c== false){
           addMessage('error','You must have at least one RIM360 option selected');
            this.mode = 'edit';
        } */
        else if(!canEdit) {
            addMessage('error',Label.CustRIMNoPermissions);
            
        } else{
            addMessage('error',Label.CustVerifierUneditable);
            }
        this.mode = 'view';
    }
    
    public PageReference cancel(){ 
    this.mode = 'view'; 
    return null; 
    }
     
    @TestVisible private void addMessage(String severity, String message){
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

}
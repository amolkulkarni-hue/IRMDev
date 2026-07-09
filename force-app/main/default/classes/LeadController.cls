public class LeadController {
    //Srinu: Commented out because no where using in the program.
    /*START*/
    //public boolean bolVal;
    //public boolean bolValNotification;
    //public boolean leadqueueerror=false;
    //public String strBody;
    /*END*/
    public String host;
    public String accname;
    public String opportunityname, sublead;
    public String strStage {get;set;}  
    //Srinu: Commented out because no where using in the program.
    /*START*/
    //OpportunityContactRole role;
    //AccountContactRole acrole;
    //Opportunity op;
    /*END*/
    //Ketan Benegal - Start    
     public String strAccountName{get;set{
        /*System.debug('1111calling strAccountName setter:' + c + '\t c.accountId'+ c.accountId); 
        Account tmp = [Select Name from Account where Id=: c.AccountId];*/
        System.debug('22222calling strAccountName setter:' + c + '\t c.account.name'+ c.account.name); 
     }
     }
    //Ketan Benegal - End
    private List<Account> dupeAccounts = null;
    private final Lead ld;
    private Lead ld1;
    private String strStatus;
    private String strSubject1;
    private String strAccount;
    private String strPriority;
    private Date dtDate;
    private String strDesciption;
    private DateTime dtDateTime;
    public  String AccountName;
    private Lead leadToConvert = null;    
    public String convertedStatus{get; set;} 
    
    Task tsk;
    Account ac; 
    Contact ac1;
    
    public List<SelectOption> getConvertStatusList() {    
        List<SelectOption> options = new List<SelectOption>();
        List<LeadStatus> lLs = [Select MasterLabel FROM LeadStatus WHERE IsConverted = true ORDER BY SortOrder ASC];       
        for( Integer i=0; i < lLs.size(); i++)
            options.add(new SelectOption(lLs[i].MasterLabel, lLs[i].MasterLabel));
        return options;
    }
   
    public LeadController(ApexPages.StandardController controller) { 
        ld= (Lead)controller.getRecord();
        System.debug('Lead Record from Controller: ' + ld);
        // Comment #15149 Start
        //ld1=[select Company,IM_Sales_Rep__r.Sales_Segment__c,IM_Original_Lead_Owner__r.Sales_Segment__c, (Select Id, CRMfusionDBR101__Lead__c From CRMfusionDBR101__Potential_Duplicates__r) from Lead where id= : ld.Id limit 1];
        // Comment #15149 End
        ld1=[select Company,IM_Sales_Rep__r.Sales_Segment__c,IM_Original_Lead_Owner__r.Sales_Segment__c from Lead where id= : ld.Id limit 1];
        System.debug('----------ld1:'+ld1);       
        
        //Below SOQL is Working one.
        //ld1=[select Company,OwnerId,IM_Sales_Rep__c,IM_Sales_Rep__r.Sales_Segment__c, IM_Original_Lead_Owner__c, IM_Original_Lead_Owner__r.Sales_Segment__c from Lead where id= : ld.Id limit 1];        
        //ld1 = [select Id,OwnerId,Company,IM_Sales_Rep__c,IM_Sales_Rep__r.Sales_Segment__c, IM_Original_Lead_Owner__c, IM_Original_Lead_Owner__r.Sales_Segment__c from Lead where Id =:ld.Id AND (IM_Sales_Rep__r.Sales_Segment__c =: 'Inside Sales - Physical' OR IM_Original_Lead_Owner__r.Sales_Segment__c =: 'Inside Sales - Physical') LIMIT 1];
        convertedStatus = 'Converted';
    }
  
    public Boolean showClientAgreement{
        get{
            if(showClientAgreement == null){
                showClientAgreement = False;
            }          
            return showClientAgreement;   
        }
        set;
    }  
    
    public Boolean showTaskNotification{
        get{
            if(showTaskNotification== null){
                showTaskNotification= false;
            }           
           
            return showTaskNotification;   
        }
        set;
    }
    public Boolean SentEmailToOwner{
        get{
            if(SentEmailToOwner== null){
                SentEmailToOwner= false;
               
            }           
           
            return SentEmailToOwner;   
        }
        set;
    } 
    public Boolean IsConverted{
       get{
           if(IsConverted != null){
               IsConverted = true;
           }
           return IsConverted;
       }
       set{
        IsConverted = true;
       }
    }

    public Task getTask(){
        if(tsk==null)
            tsk = new Task();
     
       this.strSubject1 = tsk.Subject;
       this.dtDate = tsk.ActivityDate;
       this.strPriority = tsk.Priority;
       this.strStatus = tsk.Status;
       this.strDesciption = tsk.Description;
       this.dtDateTime = tsk.ReminderDateTime;
          
        return tsk;
    }
    public String getAccname(){
        System.debug('----getaccname----ld1.company:'+ld1.company);
        return ld1.company;
    }
    public void setAccname(String accname){
        if(accname.contains('&')==true)
        {
            accname=accname.replace('&', '1x1');
        }
        if(accname.contains(';')==true)
        {
            accname=accname.replace(';', '2x2');
        }
        if(accname.contains('!')==true)
        {
            accname=accname.replace('!', '3x3');
        }
        if(accname.contains('@')==true)
        {               
            accname=accname.replace('@', '4x4');
        }
        if(accname.contains('%')==true)
        {
            accname=accname.replace('%', '5x5');
        }
        if(accname.contains('#')==true)
        {
            accname=accname.replace('#', '6x6');
        }
        if(accname.contains('-')==true)
        {
            accname=accname.replace('-', '7x7');    
        }
        
        this.accname=accname;
        System.debug('----this.accname:'+this.accname);
    }
    
    public String getOpportunityname()
    {
        System.debug('----getoptyname----ld1.company:'+ld1.company);
        return ld1.company;
    }
    public void setOpportunityname(String opportunityname)
    {
        if(opportunityname.contains('&')==true)
        {
            opportunityname=opportunityname.replace('&', '1x1');
        }
        if(opportunityname.contains(';')==true)
        {
            opportunityname=opportunityname.replace(';', '2x2');
        }
        if(opportunityname.contains('!')==true)
        {
            opportunityname=opportunityname.replace('!', '3x3');
        }
        if(opportunityname.contains('@')==true)
        {               
            opportunityname=opportunityname.replace('@', '4x4');
        }
        if(opportunityname.contains('%')==true)
        {
            opportunityname=opportunityname.replace('%', '5x5');
        }
        if(opportunityname.contains('#')==true)
        {
            opportunityname=opportunityname.replace('#', '6x6');
        }
        if(opportunityname.contains('-')==true)
        {
            opportunityname=opportunityname.replace('-', '7x7');    
        }
        this.opportunityname=opportunityname;
        System.debug('----this.opportunityname:'+this.opportunityname);
    }
    
    Contact c = new Contact();
    private string AccountId;
     /*
     public Contact getProxyObject() {
        //Ketan Benegal/Srinu - Added Account.Name in the query
         c=[Select AccountId, Account.Name From Contact where AccountId != null and (NOT Account.Name like 'IM_%') limit 1 ];
        strAccountName = c.Account.Name;
        system.debug('+++++++++++++++getProxyObject+++'+c +  '\t strAccountName: '+ strAccountName);
        
        return c;
     }
     */
    
    public List<SelectOption> getItems() { 
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('CreateNewAccount','Create New Account'));
          
        //options.add(new SelectOption('AddToExistingAccount','Add To Existing Account'));
          return options;
    }
         
    public PageReference ConvertLead(){
         
        PageReference accPage;
        
        try{
            host=ApexPages.currentPage().getHeaders().get('Host');
            system.debug('host'+host+'sendemail'+SentEmailToOwner);
            /*Ketan Benegal/Srinu - Commented the two lines and added the new line.*/
            //Account StrAccountName1 = [Select Name from Account where Id=: c.AccountId];
            //String leadaccountname=StrAccountName1.Name;
            //System.debug('----leadaccountname:'+leadaccountname);
            
            String leadaccountname;
            system.debug('+++++++++++string value++++++'+strStage+ '&&&&&leadaccountname:'+leadaccountname+'\t c:'+ c + '\t strAccountName:'+strAccountName);
            //if(strStage=='CreateNewAccount'){
                System.debug('--234----accname:'+accname);
                leadaccountname=accname;
                System.debug('--235----leadaccountname:'+leadaccountname);
            /*}else{            
                
                Account StrAccountName1 = [Select Name from Account where Id=: c.AccountId];                    
                leadaccountname=StrAccountName1.Name;
                
            }*/
            
            /*1/23/12 changes start
            if(leadaccountname.contains('&')==true)
            {
                leadaccountname=leadaccountname.replace('&', '1x1');
            }
            if(leadaccountname.contains(';')==true)
            {
                leadaccountname=leadaccountname.replace(';', '2x2');
            }
            if(leadaccountname.contains('!')==true)
            {
                leadaccountname=leadaccountname.replace('!', '3x3');
            }
            if(leadaccountname.contains('@')==true)
            {               
                leadaccountname=leadaccountname.replace('@', '4x4');
            }
            if(leadaccountname.contains('%')==true)
            {
                leadaccountname=leadaccountname.replace('%', '5x5');
            }
            if(leadaccountname.contains('#')==true)
            {
                leadaccountname=leadaccountname.replace('#', '6x6');
            }
            if(leadaccountname.contains('-')==true)
            {
                leadaccountname=leadaccountname.replace('-', '7x7');    
            }
            end*/
            
            system.debug('+++++++lead account name+++'+leadaccountname+'\t c:'+ c+ '\t c.Account.Name:'+c.Account.Name);
            if(leadaccountname.length()>2)
                sublead= leadaccountname.substring(0,3);            
            else
                sublead=leadaccountname;
            
            System.debug('------sublead:'+sublead);
            
            if(sublead=='IM_')
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Leads cannot have an account name beginning with IM_. Please go back and select a different account');
                ApexPages.addMessage(myMsg);
                accPage=null;
                System.debug('------inside if:');
            }
            else
            {
                   system.debug('------1st call-----straccname:'+c.AccountId +'\t ----leadid:'+ld.Id +'\t -----leadAccountName:'+leadaccountname +'\t ---strStage:'+strStage +'\t -----oppname:'+opportunityname +'\t ----status:'+convertedStatus +'\t ---ownerId:'+ld.OwnerId +'\t ----em:'+SentEmailToOwner);
                   //accPage = new PageReference('/apex/OppEntryPage?leadid='+ld.Id+'&straccname='+c.AccountId+'&leadAccountName='+leadaccountname+'&strStage='+strStage+'&oppname='+opportunityname+'&status='+convertedStatus+'&ownerId='+ld.OwnerId+'&em='+SentEmailToOwner);//+'&a='+strSubject1+'&b='+strStatus+'&c='+strPriority+'&d='+strDesciption+'&e='+showClientAgreement);
                   //Srinu:Added on 2-28-2013
                   accPage = new PageReference('/apex/OppEntryPage?leadid='+ld.Id+'&leadAccountName='+leadaccountname+'&strStage='+strStage+'&oppname='+opportunityname+'&status='+convertedStatus+'&ownerId='+ld.OwnerId+'&em='+SentEmailToOwner);
                   System.debug('------inside else----accPage:'+accPage);
            }
                      
               String s = ld.OwnerId;
               System.debug('----------s:'+s);
               
            System.debug('----------s.substring(0,3):'+s.substring(0,3));
            if(s.substring(0,3)== '00G')
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'You cannot convert a lead that is owned by a Queue.   Please hit “Cancel”, and change the owner of the lead');
                ApexPages.addMessage(myMsg);
                accPage=null;
                System.debug('------inside if:');
            }
            else
            {
                  if(sublead != 'IM_'){
                    system.debug('------2nd call-----straccname:'+c.AccountId +'\t ----leadid:'+ld.Id +'\t -----leadAccountName:'+leadaccountname +'\t ---strStage:'+strStage +'\t -----oppname:'+opportunityname +'\t ----status:'+convertedStatus +'\t ---ownerId:'+ld.OwnerId +'\t ----em:'+SentEmailToOwner);
                    //accPage = new PageReference('/apex/OppEntryPage?leadid='+ld.Id+'&straccname='+c.AccountId+'&leadAccountName='+leadaccountname+'&strStage='+strStage+'&oppname='+opportunityname+'&status='+convertedStatus+'&ownerId='+ld.OwnerId+'&em='+SentEmailToOwner);//+'&a='+strSubject1+'&b='+strStatus+'&c='+strPriority+'&d='+strDesciption+'&e='+showClientAgreement);
                    //Srinu:Added on 2-28-2013
                    accPage = new PageReference('/apex/OppEntryPage?leadid='+ld.Id+'&leadAccountName='+leadaccountname+'&strStage='+strStage+'&oppname='+opportunityname+'&status='+convertedStatus+'&ownerId='+ld.OwnerId+'&em='+SentEmailToOwner);
                  }
                  else
                        accPage = null;            
    
                System.debug('---238--inside else----:');
            }
     
        }catch(System.Exception e){
            ApexPages.addMessages(e); 
        }
        
        if(accPage != null){
             accPage.setRedirect(true);
        }
        return accPage ;        
       
    }
}
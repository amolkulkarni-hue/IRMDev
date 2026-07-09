/****************************** 
   Developer Name    : Madhu Paladugu
   Date              : 3/14/13
   Company Name      : CloudFountain Inc.
   Purpose           : This class is a scheduler for the batch class "BatchJobToChangeEmails".
   Method Invocation : Users has to schedule this class from UI.
   
   Test Class        : Test_BatchJobToChangeEmails
   
   Dependents        : Class           :Test_BatchJobToChangeEmails,BatchJobToChangeEmails
                       Custom settings : ChangeEmailToInvalid
                                  
 ********************************/  
    /* Comment - This class has been commented out as to not allow updation of emails in custom settings, case, contact
                    and Lead's email address. */

global class SchedulerOfChaingEmails implements Schedulable{
 
    public String ContactQuery='select id,';
    public String LeadQuery='select id,';
    public String CaseQuery='select id,';
    
    //Constructor for this class.
    
    /*public SchedulerOfChaingEmails(){
        Set<String> ContactFields=new set<String>();
        Set<String> CaseFields=new set<String>();
        Set<String> LeadFields=new set<String>();
        List<IME_SC_Country_CaseOrigins__c> updatecust=new List<IME_SC_Country_CaseOrigins__c>();
        //changing custom setting emails
        List<IME_SC_Country_CaseOrigins__c> custdata=[select id,Outbound_Email__c from IME_SC_Country_CaseOrigins__c where Outbound_Email__c!='invalid@ironmountain.com' ];
        
        for(IME_SC_Country_CaseOrigins__c cus:custdata){
            cus.Outbound_Email__c='invalid@ironmountain.com';
             updatecust.add(cus);
        }
        
        update updatecust;
        // Getting the email fileds from custom setting those are needs change to " invalid@ironmountain.com"
        
        List<ChangeEmailToInvalid__c> Cust_List=[select Object__c,Field__c from ChangeEmailToInvalid__c];
        for(ChangeEmailToInvalid__c c:Cust_List){
            if(c.Object__c=='Contact')
            ContactFields.add(c.Field__c);
            else if(c.Object__c=='Lead')
            LeadFields.add(c.Field__c);
            else if(c.Object__c=='Case')
            CaseFields.add(c.Field__c);
        }
        
        //dynamic query creation from the fileds which exist in custom setting
        
        List<String> ContactFieldsList=new List<String>(ContactFields);
        List<String> CaseFieldsList=new List<String>(CaseFields);
        List<String> LeadFieldsList=new List<String>(LeadFields); 
        for(String s:ContactFieldsList){
            ContactQuery+=s+',';
        }
        ContactQuery= ContactQuery.substring (0,ContactQuery.length()-1);
        ContactQuery+=' from Contact where email!=\'invalid@ironmountain.com\' and email!=null ';
        for(String s:LeadFieldsList){
             LeadQuery+=s+',';
        }
        LeadQuery= LeadQuery.substring (0,LeadQuery.length()-1);
        LeadQuery+=' from Lead where IsConverted=false';
        
        for(String s:CaseFieldsList){
             CaseQuery+=s+',';
        }
        CaseQuery= CaseQuery.substring (0,CaseQuery.length()-1);
        CaseQuery+=' from Case where status!=\'closed\'';
    }*/
    global void execute(SchedulableContext sc) {
        /*String URL_BASE=String.ValueOf(URL.getSalesforceBaseUrl());
         
        // checking this is production environment ot not. if it is don't cal the batch class.
        
        URL_BASE=URL_BASE.substringAfter('delegate=').removeEnd(']').toLowerCase();
        if(URL_BASE=='https://na29.salesforce.com' && !Test.isRunningTest()){
              system.debug('++++++++++ i am not executing because it is production environment+++++++');
        }
        else{
             database.executebatch(new BatchJobToChangeEmails(ContactQuery),200);
           // database.executebatch(new BatchJobToChangeEmails(LeadQuery),200);
            database.executebatch(new BatchJobToChangeEmails(CaseQuery),200);
        }*/
    }
}
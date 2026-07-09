public class IME_CreateCase_Lightning
{    
    public String OppId{get; set;}
    public String Type{get; set;}
    public Opportunity currentRecord{get; set;}
    public List<Case> ExistingCase{get; set;}
    public List<Case> contractCaseList{get; set;}
    public String caseNumber{get;set;}
    public Id casidnew {get;set;}
    
    public IME_CreateCase_Lightning()
    { 
        OppId = ApexPages.currentPage().getParameters().get('oppid');
        Type = ApexPages.currentPage().getParameters().get('Type');
        System.debug('Oppty Id>>>>'+OppId);
        System.debug('Type>>>>'+Type);
    }
    
    
    public void CreateCase(){
        //AccountSetUp button for lightning
        currentRecord = [SELECT Id,StageName,Name,AccountId FROM Opportunity WHERE Id = :OppId];
        if(Type=='AccountSetup'){
            String opportunityId = '%' + OppId + '%';
            if(currentRecord!=null){
                ExistingCase = [Select Id,Subject,accountId From Case where Subject = 'Account Setup' and accountId = : currentRecord.AccountId and url__c like :opportunityId Limit 1];
            }
            if(ExistingCase.size()>0)
            {
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,'An Account Setup case has already been requested for this opportunity'));
            }
            system.debug('testtesttest');
            if(ExistingCase.size()==0){
                system.debug('Entering CreateCase method for Acc setup');
                String AccSetupCaseId = createAccountSetupCase(oppid);
                List<Case> cs = [Select Id,CaseNumber from Case Where Id =:AccSetupCaseId];
                if(cs.size()>0)
                {
                    system.debug('Successs!!!'+cs);
                    caseNumber = cs[0].CaseNumber;
                    Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,'New case#'+caseNumber+System.Label.IME_SC_NEW_CASE)); 
                }
            }
        }
        //Request Contract Button for lightning
        else if(Type=='Request Contract')
        {
            System.debug('Request contract Condition Meet>>>');
            if(currentRecord.StageName =='Lost'||
               currentRecord.StageName =='Dead'||
               currentRecord.StageName =='Postponed'||
               currentRecord.StageName =='0 - Pre-Qualification'||
               currentRecord.StageName =='1 - Qualification'||
               currentRecord.StageName =='2 - Solution Developed'||
               currentRecord.StageName =='3 - Solution Agreed')
            {
                Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,'A contract request may only be created when the opportunity is in sales stage 4, 5 or 6'));
            }
            else
            {
                String opportunityId = '%' + OppId + '%'; 
                contractCaseList = [Select Id,Subject,accountId From Case where Subject = 'Contract Request' and accountId = : currentRecord.AccountId and url__c like :opportunityId Limit 1];
                System.debug('Contract List>>>'+contractCaseList.size());
                if(contractCaseList.size()>0)
                {
                    Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,'A contract request has already been created for this opportunity')); 
                }
                else
                {
                    String contractCase = createContractCase(oppid);
                    System.debug('Contract case Id>>>'+contractCase);
                    List<Case> cs = [Select Id,CaseNumber from Case Where Id =:contractCase];
                    if(cs.size()>0)
                    {
                        caseNumber = cs[0].CaseNumber;
                        Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,'New case#'+caseNumber+System.Label.IME_SC_NEW_CASE)); 
                    }
                }
            }
        }
    }
    
    public string createAccountSetupCase(ID op_id){ 
        
        String casidnew;
        Case casnw = new Case();
        RecordType rtyp = new RecordType();
        
        //Querying the Case Record Type
        rtyp = [Select Id From RecordType  Where SobjectType = 'Case' and name = 'IM Employees Support Case']; 
        
        //Querying the Queue
        Group grp = [select Id,Name from Group where Name = 'IME UK Account Setup' and Type = 'Queue']; 
        
        //Getting the List of Users from Current User
        List<User> usrLstnew = [SELECT Name, Id, Division FROM User WHERE Id = : UserInfo.getUserId()];
        
        //Querying the opportunity 
        Opportunity opp = [Select id, Name, account.name,accountid from opportunity where id=: op_id];
        
        //List<Case> casLstnew = new List<Case>();
        //Creating a Case
        for(User usrnew: usrLstnew)
        {
            casnw.OwnerId = UserInfo.getUserId();
            casnw.Related_To__c = 'Customer Account/Client Code';
            casnw.Issue__c  = 'Account Set Up';
            casnw.RecordTypeId = rtyp.id;
            casnw.Status = 'New';
            casnw.Origin = 'Internal';
            casnw.IM_Division__c = usrnew.Division;
            casnw.Priority = 'Medium';
            casnw.Subject = 'Account Setup';
            casnw.Description = 'Please Setup Account for the following Opportunity:'+opp.Name+System.label.IME_ServerURL+opp.id;
            casnw.AccountId = opp.accountid; 
            casnw.IM_Employee_Contact__c = UserInfo.getUserId();
            casnw.URL__c = System.label.IME_ServerURL+opp.id;
            
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            dmo.EmailHeader.TriggerUserEmail = true;
            casnw.setOptions(dmo);
            
        }   
        Insert casnw;
        casidnew = casnw.Id;
        return casidnew; 
    }  
    
    public string createContractCase(ID op_id)
    {         
        Case cas = new Case();
        RecordType rtype = new RecordType();
        
        //Querying the Case Record Type
        rtype = [Select Id From RecordType  Where SobjectType = 'Case' and name = 'IM Employees Support Case']; 
        
        //Querying the Queue
        Group grp = [select Id,Name from Group where Name = 'IME UK Account Setup' and Type = 'Queue']; 
        
        //Getting the List of Users from Current User
        List<User> usrLst = [SELECT Name, Id,Division FROM User WHERE Id = : UserInfo.getUserId()];
        
        //Querying the opportunity 
        Opportunity opp = [Select id, Name, account.name,accountid from opportunity where id=: op_id];
        System.debug('');
        
        //List<Case> casLst = new List<Case>();
        //Creating a Case
        for(User usr: usrLst)
        {
            
            cas.OwnerId = UserInfo.getUserId();
            cas.Related_To__c = 'Contracts';
            cas.Issue__c  = 'Request Contract';
            cas.RecordTypeId = rtype.id;
            cas.Status = 'New';
            cas.Origin = 'Internal';
            cas.IM_Division__c = usr.Division;
            cas.Priority = 'Medium';
            cas.Subject = 'Contract Request';
            cas.Description = 'Please Create Contract for the following Opportunity:'+opp.Name+System.label.IME_ServerURL+opp.id;
            cas.AccountId = opp.accountid; 
            cas.IM_Employee_Contact__c = UserInfo.getUserId();
            cas.URL__c = System.label.IME_ServerURL+opp.id;
            
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            cas.setOptions(dmo);
            
        }   
        Insert cas; 
        casidnew = cas.Id;
        return casidnew;     
    }
    
    public pagereference GoToOppty(){
        pagereference ref = new pagereference('/'+oppid);
        ref.setRedirect(true);
        return ref;
    } 
    
   /* public pagereference GoToCase(){
        pagereference ref = new pagereference('/'+casidnew);
        ref.setRedirect(true);
        return ref;
    } */
}
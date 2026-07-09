/**
     * Created By: Revathy Saminathan on 24-Jan-2020 
     *          -- Creating new class for the Contact role funtionality to lightning compatability
     *          -- Case # 11636859 Lightning Migration IME/IMLA
     *          --- Visualforce Name : AccountContactRoleDetails_Lightning
**/
public class AccountContactRolesController_Lightning
{ 
    private Contact ctemp = new Contact();
    
    private final Contact acr;
    String showAll = ApexPages.currentPage().getParameters().get('showAll');  
    integer tempLimit = 0;  
    integer currentCount = 0; 
    
    public Id conId{get;set;}
    public String conName{get;set;}
    public String param{get;set;}    
    
    public AccountContactRolesController_Lightning(ApexPages.StandardController controller)
    {
        if(showAll != '' && showAll =='Yes')
        {
            tempLimit = Integer.valueOf(1000);
        }
        else
        {
            tempLimit = Integer.valueOf(5);
        }    
        this.acr = (Contact)controller.getRecord();
        
        ctemp = [Select Name, Id, CreatedById From Contact where Id=:acr.Id];
        conId = ctemp.Id;
        conName = ctemp.Name;
        param = '/apex/AccountContactRole_Lightning?';
    }
    
    public List<AccountContactRole> acrs 
    {
        get {
            if (acrs == null) 
            {
                acrs = [Select id,Account.Name,Account.Type,Account.IM_Hierarchy_Level__c,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,
                        Role,IsPrimary,ContactId From AccountContactRole
                        Where ContactId=:acr.Id 
                        Order By Account.Name LIMIT : tempLimit];               
            }
            
            currentCount = acrs.size();
            return acrs;
        }
        private set;
    }
    
    public PageReference showMore() 
    {
        acrs = [Select id,Account.Name,Account.Type,Account.IM_Hierarchy_Level__c,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode,
                Role,IsPrimary,ContactId From AccountContactRole
                Where ContactId=:acr.Id 
                Order By Account.Name LIMIT : currentCount+2];   
        return null;
    }    
    public PageReference savenew()
    {
        PageReference newPage = new PageReference('/apex/AccountContactRole_Lightning/'+acr.id);
        return newpage;
    }
    
}
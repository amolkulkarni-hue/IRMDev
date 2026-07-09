/**
     * Created By: Revathy Saminathan on 24-Jan-2020 
     *          -- Creating new class for the Contact role funtionality to lightning compatability
     *          -- Case # 11636859 Lightning Migration IME/IMLA
     *          --- Visualforce Name : AccountContactRole_Lightning
**/
public with sharing class AccountContactRolesCont_Lightning
{
    private final Contact acr;
    public Id conId{get;set;}
    public AccountContactRole objAccConRole {get;set;}
    
    public AccountContactRolesCont_Lightning(ApexPages.StandardController controller)
    {
        objAccConRole = new AccountContactRole(); 
        conId = ApexPages.CurrentPage().getParameters().get('cid');
        
    }
    public PageReference save()
    {
        objAccConRole.ContactId = conId;
        system.debug('objAccConRole---'+objAccConRole);
        
        try
        {
            insert objAccConRole;
            
        }
        catch(exception e)
        { 
            Apexpages.addMessages(e); 
            return null;
        }
        PageReference redirecturl = new PageReference('/' + conId);
        return redirecturl;
        
    }
    public PageReference savenew()
    {
        objAccConRole.ContactId = conId;
        system.debug('objAccConRole---'+objAccConRole);
        try
        {
            insert objAccConRole;
        }
        catch(exception e)
        { 
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Invalid Input.');
            ApexPages.addMessage(myMsg);
            return null;
        }
        objAccConRole = new AccountContactRole();
        return null;
    }
    public PageReference cancel()
    {
        objAccConRole = new AccountContactRole();
        PageReference redirecturl = new PageReference('/' + conId);
        return redirecturl;
    }   
}
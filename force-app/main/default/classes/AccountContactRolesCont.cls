//Case #00548380 insert statements in save() and savenew() added in a try-catch to display error on the same page - Sandhya 12/9/2014

public with sharing class AccountContactRolesCont
{
    private final Contact acr;
    public Id conId{get;set;}
    public AccountContactRole objAccConRole {get;set;}
    public AccountContactRolesCont(ApexPages.StandardController controller)
    {
        objAccConRole = new AccountContactRole();
        
        conId = ApexPages.CurrentPage().getParameters().get('cid');
                
    }
    public PageReference save()
    {
        objAccConRole.ContactId = conId;
        system.debug('objAccConRole---'+objAccConRole);
        
        try{
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
        try{
        insert objAccConRole;
        }
        catch(exception e)
        {
          //   Apexpages.addMessages(e);
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
        return null;
    }   
}
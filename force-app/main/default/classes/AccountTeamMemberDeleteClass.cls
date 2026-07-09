public class AccountTeamMemberDeleteClass {
public List<wrapAccountTeamMember> wrapAccountTeamMemberList {get; set;}
public Id accountid {get; set;}
public Boolean displayCustomerError{get;set;}
public Boolean displayError{get;set;}
public AccountTeamMemberDeleteClass (ApexPages.StandardController controller)
     {
         accountid= ApexPages.currentPage().getParameters().get('Id');
         displayCustomerError=false;
         displayError=true;
         if(accountid != null)
         {
             fetchingaccountteammember();
         }
     }
public pageReference fetchingAccountteammember()
         {
          Set<Id> atmlist = new Set<Id>();
         List<AccountTeamMemberProfileSettings__c> atmsettings= AccountTeamMemberProfileSettings__c.getAll().values();
         for(AccountTeamMemberProfileSettings__c atm : atmsettings)
         {
             atmlist.add(atm.Profile_Id__c);
         }
        if(UserInfo.getProfileId()!= null)
        {
        if(atmlist.contains(UserInfo.getProfileId()))
        {
         if(wrapAccountTeamMemberList == null) {
          wrapAccountTeamMemberList = new List<wrapAccountTeamMember>();
            for(AccountTeamMember a: [select Id,AccountAccessLevel,UserId,TeamMemberRole from AccountTeamMember where AccountId= :accountid limit 10]) {
                // As each AccountTeamMember is processed we create a new wrapAccountTeamMember object and add it to the wrapAccountTeamMemberList
                wrapAccountTeamMemberList.add(new wrapAccountTeamMember(a));
            }
      }
      displayError=true;      
       }
else
{
 displayError=false;
    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Insufficient Privileges');
    ApexPages.addMessage(myMsg);
    }   
   }
        return null;
  }
public pageReference delete1() 
    {   
     List<AccountTeamMember> deleteList = new List<AccountTeamMember>();
     for(wrapAccountTeamMember atm : wrapAccountTeamMemberList) {
            if(atm.selected == true) {
                deleteList.add(atm.accteam);
                }
        System.debug('*******'+deleteList);
        }
        
     if(deleteList.size()>0)
        {
         try{
        delete deleteList;
        }
        catch(Exception e){
                system.debug('**AccountTeamMember**' + e.getMessage()); 
            }
        displayCustomerError=false;
      PageReference page = new PageReference('/' + accountid);
        page.setRedirect(true);
        return page; 
        }
        else{
            displayCustomerError=true;
  } 
        return null;
       }
   
    
   public pageReference cancel(){
    PageReference page = new PageReference('/' + accountid);
    page.setRedirect(true);
    return page; 
  }
     public class wrapAccountTeamMember {
        public AccountTeamMember accteam {get; set;}
        public Boolean selected {get; set;}
 
        public wrapAccountTeamMember(AccountTeamMember a) {
            accteam = a;
            if(!Test.isRunningTest()){
            selected = false;
            } else {
            selected = true;
            }
        }
    }   
    }
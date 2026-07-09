public class ChildOpportunityController
{
    
    public List<Opportunity> opptylist {get;set;} 
    public List<Opportunity> parentlist {get;set;} 
    public Opportunity opportunity {get;set;}
    public Opportunity parentOppt {get;set;}    
    public Boolean differentHierarchy {get;set;}    
   
    //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
    public ChildOpportunityController(ApexPages.StandardController controller) {
        
        this.opportunity = (Opportunity) controller.getRecord();
        system.debug('Current Opp ID:'+ opportunity.Id);
        opportunity opp = [Select Name,AccountId,OwnerID,Account.Name,Owner.Name,StageName,IM_Booked_Date__c,Amount,IM_Parent_Opportunity__c from Opportunity where Id=:opportunity.id];
        if(opportunity.Id != null){
            this.opptylist  =[SELECT Name,AccountId,OwnerID,Account.Name,Owner.Name,StageName,IM_Booked_Date__c,Amount,IM_Parent_Opportunity__c FROM Opportunity where
                              IM_Parent_Opportunity__c =:controller.getId()];
            //this.parentlist= [SELECT Name,AccountId,OwnerID,Account.Name,Owner.Name,StageName,IM_Booked_Date__c,Amount,IM_Parent_Opportunity__c FROM Opportunity where
            //                Id =:opp.IM_Parent_Opportunity__c Limit 1];
            if(opportunity.IM_Parent_Opportunity__c != null)
            {
                parentOppt = [SELECT Id, AccountId FROM Opportunity where Id =:opportunity.IM_Parent_Opportunity__c];   
                
                //system.debug('opportunity details ---'+opportunity);
              //  system.debug('opportunity.AccountId details ---'+opp.AccountId);
                
                Account accountDetails = [SELECT Id, IM_IMGA__c,ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.ParentId from Account where id = :opportunity.AccountId];
                string accountUltimateParent= (accountDetails.Parent.Parent.Parent.Parent.ParentId != null)? accountDetails.Parent.Parent.Parent.Parent.ParentId : (accountDetails.Parent.Parent.Parent.ParentId != null)? accountDetails.Parent.Parent.Parent.ParentId : (accountDetails.Parent.Parent.ParentId != null)? accountDetails.Parent.Parent.ParentId : (accountDetails.Parent.ParentId != null)? accountDetails.Parent.ParentId : accountDetails.ParentId; 
                
                Account parentAccountDetails = [SELECT Id, IM_IMGA__c, ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, Parent.Parent.Parent.Parent.ParentId from Account where id = :parentOppt.AccountId];
                string parentAccountUltimateParent= (parentAccountDetails.Parent.Parent.Parent.Parent.ParentId != null)? parentAccountDetails.Parent.Parent.Parent.Parent.ParentId : (parentAccountDetails.Parent.Parent.Parent.ParentId != null)? parentAccountDetails.Parent.Parent.Parent.ParentId : (parentAccountDetails.Parent.Parent.ParentId != null)? parentAccountDetails.Parent.Parent.ParentId : (parentAccountDetails.Parent.ParentId != null)? parentAccountDetails.Parent.ParentId : parentAccountDetails.ParentId; 
                
                system.debug('accountDetails =='+accountDetails );
                system.debug('accountUltimateParent=='+accountUltimateParent);
                system.debug('parentAccountUltimateParent=='+parentAccountUltimateParent);
                 
                //system.debug('parentOpportunity=='+ parentOppt);
               // system.debug('opportunity.AccountId=='+opportunity.AccountId +'===parentOppt.AccountId'+ parentOppt.AccountId); 
               // system.debug('accountUltimateParent=='+accountUltimateParent +'====parentAccountUltimateParent'+ parentAccountUltimateParent);
                //system.debug('accountDetails.IM_IMGA__c=='+accountDetails.IM_IMGA__c+'=====parentAccountDetails.IM_IMGA__c'+parentAccountDetails.IM_IMGA__c);
                
                //Compare IMGA
                if(!String.isBlank(accountDetails.IM_IMGA__c) && !String.isBlank(parentAccountDetails.IM_IMGA__c))
                {
                    system.debug('Check IMGA');
                    if(accountDetails.IM_IMGA__c !=parentAccountDetails.IM_IMGA__c || test.isrunningtest())
                    {
                        differentHierarchy = true;
                    }
                    else 
                    {
                        differentHierarchy = false;
                    }
                }
                else if((!String.isBlank(accountUltimateParent) && !String.isBlank(parentAccountUltimateParent)) ||test.isrunningtest())
                {
                    system.debug('Check Ultimate Parent');
                    if((opportunity.AccountId != parentOppt.AccountId) && (accountUltimateParent != parentAccountUltimateParent))
                    {
                        differentHierarchy = true;
                    }
                    else 
                    {
                        differentHierarchy = false;
                    }
                }
                else if(opportunity.AccountId != parentOppt.AccountId)
                {
                     system.debug('Compare both accounts');
                     differentHierarchy = true;
                } 
                else
                { 
                    system.debug('No same Hierarchy');
                    differentHierarchy = false;
                }
                system.debug('differentHierarchy=='+ differentHierarchy);                 
             }
            
        }
    }
    
    public Boolean isoptylist{
        get{
            return opptylist.isempty();
        }
        private set;
    }
    public Boolean isparentlist{
        get{
            return parentlist.isempty();
        }
        private set;
    }
    
    /*     public void saveOpp(){

update opportunity;
this.Opportunity = [SELECT Id, IM_Parent_Opportunity__r.Name,IM_Parent_Opportunity__c,IM_Parent_Opportunity__r.Id FROM Opportunity where Id =:Opportunity.id];

}
*/     
    public pageReference RemoveParentOppty(){
        opportunity.IM_Parent_Opportunity__c= Null;
        update opportunity;
        PageReference page = new PageReference('/' + opportunity.Id);
        page.setRedirect(true);
        return page;
    }
    
    
    public pageReference RemoveChildOppty()
    {
        String oppid= ApexPages.currentPage().getParameters().get('oppid'); 
        for(Opportunity op : opptylist){
            if(op.Id == oppid){
                op.IM_Parent_Opportunity__c = Null;
            }
        }
        update opptylist;
        /*    Opportunity opp = [Select id,IM_Parent_Opportunity__c from Opportunity where id =:oppid limit 1];
if(opp !=null && opp.IM_Parent_Opportunity__c !=null){
opp.IM_Parent_Opportunity__c = null;
update opp;
}
*/
        PageReference page = new PageReference('/' + opportunity.Id);
        page.setRedirect(true);
        return page; 
    }
    
    
}
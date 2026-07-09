/*Developer Name: Madhu Paladugu
  Company       : TheCloudFountain Inc.
  Description   : This trigger is defined on IM_Customer_Account__c to update the counter on the 
                  associated Account to reflect the "Number Of Customer Accounts".
  Date          : 12/3/12
  case number   : 00924109   */
/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 4/9/13
   
   Company Name      : CloudFountain Inc.
   
   Description       :  Added couple of triggers
                        Trigger: NumberOf_Cust_AtRisk_Count
                        purpose: Used to populate the Number of customers at risk for each rate table. 
                        
                        Trigger: PopulateRateTableRelationship
                        purpose: Used to populate the rate table lookup based on the Rate_Table_ID__c filed value.
                        
                        Trigger: PopulateHighestBillingCustomer
                        purpose: To sync highest billing to rate table
                        
   Test Class        : Test_NumberOf_Cust_AtRisk_Count
   
   Dependents        : Apex Class: test_CustomerAccountObject
   
   Case Number       : 00222919


    Updated Trigger to Flag Customer Accounts whose parent Accounts's Billing city is Recall flagged cities
    Case # 05049974
    Author : Vinutha
    Date : 27/04/2016
                                  
    Update Trigger to remove "PopulateRateTableRelationship", "NumberOf_Cust_AtRisk_Count","PopulateHighestBillingCustomer","runUpdateRateTablemin" functionality as part of Q2W decommission
    Case # 09517433
    Author : Vinutha Iyengar
    Date : 11/02/2019

 ********************************/ 
  //the logic of updating count filed on account has been changed to remove methods and all which exist in previous trigger as of case number :00924109
trigger CustomerAccountObject on IM_Customer_Account__c (after insert, after update, after delete, after undelete,before update,before insert) {
    public String numberOfCustomerAccounts=null;
    Boolean runnumberOfCustomerAccounts=false;
    public string FlagRecallCustAccountByCity='false';
    
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        System.debug('++++++++++83++++++++customsettings:'+customsettings);
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c=='IM_Customer_Account__c')
            {
                if(cs.Trigger__c == 'numberOfCustomerAccounts') {
                   numberOfCustomerAccounts= cs.Value__c;    
                }
                if(cs.Trigger__c == 'FlagRecallCustAccountByCity') {
                   FlagRecallCustAccountByCity= cs.Value__c.toLowerCase();    
                }
             }
         }
        
    Map<Id,Integer> AccounntMap=new Map<Id,Integer>();
    
    if(numberOfCustomerAccounts=='True'){
       runnumberOfCustomerAccounts=true; 
    }
     /*********** numberOfCustomerAccounts Start*************/
    if(runnumberOfCustomerAccounts && Trigger.isAfter ){
        
        System.debug('+++++++++Executing numberOfCustomerAccounts trigger++++');
        if( Trigger.IsInsert || Trigger.isUndelete  ){
            for(IM_Customer_Account__c ac:Trigger.new){
                if(AccounntMap.containsKey(ac.IM_Account__c)){
                    Integer num=AccounntMap.get(ac.IM_Account__c);
                    num=num+1;
                    AccounntMap.put(ac.IM_Account__c,num);
                }
                else{
                    AccounntMap.put(ac.IM_Account__c,1);
                }
            }
        }
        
        if( trigger.isDelete){
            for(IM_Customer_Account__c ac:Trigger.old){
                if(AccounntMap.containsKey(ac.IM_Account__c)){
                    integer num=AccounntMap.get(ac.IM_Account__c);
                    num=num-1;
                    AccounntMap.put(ac.IM_Account__c,num);
                }
                else{
                   AccounntMap.put(ac.IM_Account__c,-1); 
                }
            }
        }

        if( Trigger.isUpdate){
            for(Integer i=0;i<Trigger.new.size();i++){
                if(AccounntMap.containsKey(Trigger.new[i].IM_Account__c)){
                    integer num=AccounntMap.get(Trigger.new[i].IM_Account__c);
                    num=num+1;
                    AccounntMap.put(Trigger.new[i].IM_Account__c,num);
                }
                else{
                     AccounntMap.put(Trigger.new[i].IM_Account__c,1); 
                }
                if(AccounntMap.containsKey(Trigger.old[i].IM_Account__c)){
                    integer num=AccounntMap.get(Trigger.old[i].IM_Account__c);
                    num=num-1;
                    AccounntMap.put(Trigger.old[i].IM_Account__c,num);
                }
                else{
                     AccounntMap.put(Trigger.old[i].IM_Account__c,-1); 
                }
            }
        }
        System.debug('+++++++Account Map+++++++'+AccounntMap);
        if(!AccounntMap.isEmpty()){
            List<Account> acc=[select Id,CustomerAcctCounter__c  from Account where Id IN:AccounntMap.keySet()];
            List<Account> accNeedsUpdate=new List<Account>();
            for(Account a:acc){
                Decimal temp=a.CustomerAcctCounter__c+AccounntMap.get(a.Id);
                if(temp<0){
                   temp=0;
                }
            
                if(a.CustomerAcctCounter__c!=temp){
                    a.CustomerAcctCounter__c=temp;
                    accNeedsUpdate.add(a);
                }
            }
           update accNeedsUpdate;
        }
    }
    /******************End**********************/
    
   
}
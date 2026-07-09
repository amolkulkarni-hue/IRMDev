/****************************** 
   Developer Name    : Apurva Dutta
   
   Date              : 1/22/14
   
   Company Name      : Iron Mountain Service India Pvt. Ltd.
   
   Purpose           : This class is used as test class for checking that only one customer accounts can be linked with one contract.
   
   Test Class        : Test_ContractCusAccDuplicate
   
   Case Number       : 01590130
                                  
 ********************************/

trigger ContractCusAccDuplicate on Contract_Customer_Account__c (before insert, before update)
{
  List<Id> contrLst = new List<Id>();
  List<Id> cusAccLst = new List<Id>();
  
  for(Contract_Customer_Account__c Obj: trigger.new)
  {
    contrLst.add(Obj.IME_Contract_Id__c);
    cusAccLst.add(Obj.IME_Customer_Accounts_Id__c);
  }
  
  List<Contract_Customer_Account__c> junLst = [Select Id, IME_Contract_Id__c, IME_Customer_Accounts_Id__c from Contract_Customer_Account__c where IME_Contract_Id__c IN:contrLst and IME_Customer_Accounts_Id__c IN:cusAccLst];
  for(Contract_Customer_Account__c ObjJun: trigger.new)
  { 
      if(trigger.isInsert)
      {
        if(junLst.size()>0)
        {
          ObjJun.addError('This association is already set between the given Contract and Customer Account!');
        }
      }
      if(trigger.isUpdate)
      {
        if(junLst.size()>0)
        {
          ObjJun.addError('This association is already set between the given Contract and Customer Account!');
        }
      }
   }
}
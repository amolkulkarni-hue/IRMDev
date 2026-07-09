/**
    Developer Name : Apurva Dutta
    Company Name   : Iron Mountain India.
    Description    : This Class will Schedule the process of updating the contract renewal date 
                        based on Contract Type).
    Date           : 02/03/2014 
    Case Number    : 01590130

**/
global class IME_ContractDataCheck_SchdleClass implements Schedulable{
         
  global void execute(SchedulableContext sc) 
  {  
       IME_ContractDataCheck_BatchClass contrctschedule = new IME_ContractDataCheck_BatchClass();
       //Id batchId = database.executeBatch(contrctschedule);  
       database.executebatch(contrctschedule );  
   }
}
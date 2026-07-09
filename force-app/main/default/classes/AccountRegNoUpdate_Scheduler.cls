/*
This Schedulable class executes AccountRegNumberUpdateBatch which copies Account's - 'Registration Number' field to Contact, Opportunity, Customer Accounts
Case #: 05119686 
Author: Vinutha Iyengar
Date: 06/Feb/2019
*/

global class AccountRegNoUpdate_Scheduler implements Schedulable
{
  global void execute(SchedulableContext sc) {
    AccountRegNumberUpdateBatch batchClass = new AccountRegNumberUpdateBatch(); 
    database.executebatch(batchClass,50);
  }
}
/*Author       : Abhay Gupta
  Company      : Patni Computer Systems
  Created Date : 10-May-2011
  Description  : Wraper schedulable class for batch class Oppshare_delete_new_batch_class. Need to schedule from web GUI at  
                 specified/required time.Also includes the test coverage code for itself.*/

global class Scheduler_OppShareDeleteBatchClass implements schedulable
{
    //Schedule the executable part of class.
    global void execute(SchedulableContext sc)
    {
       Oppshare_delete_new_batch_class b = new Oppshare_delete_new_batch_class();
       id batched = database.executebatch(b,10000);
    }
    //Test class for the scheduler class.
    static testmethod void unitTest() 
    {
    test.starttest();
    Scheduler_OppShareDeleteBatchClass sco = new Scheduler_OppShareDeleteBatchClass();
    String sch = '0 0 23 * * ?';
    system.schedule('Opp Share Creates', sch, sco);
    test.stopTest();
    }
}//End of class.
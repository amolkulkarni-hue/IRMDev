/*Code written as part of Case 00443373
Author: Raj Gottipolu*/
global class Scheduler_CurrentForecast_batchclass implements schedulable{
    //Schedule the executable part of class.
    global void execute(SchedulableContext sc)
    {
       CurrentMonthForecast_Populate_batchclass b = new CurrentMonthForecast_Populate_batchclass();
       id batched = database.executebatch(b,200);
    }
    //Test class for the scheduler class.
    static testmethod void unitTest() 
    {
    test.starttest();
    Scheduler_CurrentForecast_batchclass sco = new Scheduler_CurrentForecast_batchclass();
    String sch = '0 0 23 1 * ?';
    system.schedule('Opp Share Creates', sch, sco);
    test.stopTest();
    }
}
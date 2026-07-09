/*Author           : Abhay Gupta
  Company          : Patni Computer Systems
  Created Date     : 11-May-2011
  Description      : Apex test class to test the coverage of apex batch class Oppshare_delete_new_batch_class by setting up test data. 
    
  CHANGE LOG       :
  [[Version; Date; Author; Project/Case; Description]]
  v1.0; 2013/05/07; Srinivasa Rao/Randstad; Reviewing code coverage for all components/Case#01367998; Initial release.
*/
@isTest
public class Test_OppShareDeleteBatchClass {
    static testMethod void runTest() {
        //Testing the coverage for execute section.
        Test.startTest();
        
        //calling batch class         
        Oppshare_delete_new_batch_class job = new Oppshare_delete_new_batch_class();    
        
        //Passing '200' records to start method, if it was called by test method.
        Id jobId = Database.executeBatch(job,10);
        
        Test.stopTest();   
    }
}
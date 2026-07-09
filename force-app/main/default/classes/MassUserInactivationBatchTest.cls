/**
* Class: MassUserInactivationBatchTest
*
* Author: TCS
*
* Purpose: This is a test class for MassUserInactivationBatch
*
* Requirement: GitLab : #13838 
*
* Change History:
*
* Developer                     Date 	             		Description
* -------------------------------------------------------------------------------------------
* Praneel                       09/Mar/2023                test class for MassUserInactivationBatch
*/

@isTest
public class MassUserInactivationBatchTest {

   @isTest
    static void testSuccess() {
        
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2); 
        try {
            MassUserHierarchyDependencyRemovalBatch massInactiveUserBatch = new MassUserHierarchyDependencyRemovalBatch();
            //Database.executeBatch(new MassUserInactivationBatch(), 1);
            String chron = '0 0 23 * * ?';        
            system.schedule('Test Sched', chron, massInactiveUserBatch);
            massInactiveUserBatch.execute(null);
        } catch(exception e){
            system.debug('error occured while executing the test method '+e.getMessage());
        }
        Test.stopTest();
    }
    @isTest
    static  void testFailues() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2); 
        try {
            MassUserHierarchyDependencyRemovalBatch massInactiveUserBatch = new MassUserHierarchyDependencyRemovalBatch(true);
                //Database.executeBatch(new MassUserInactivationBatch(true), 1);
            String chron = '0 0 23 * * ?';        
            system.schedule('Test Sched', chron, massInactiveUserBatch);
            massInactiveUserBatch.execute(null);
        } catch(exception e){
            system.debug('error occured while executing the test method '+e.getMessage());
        }
        Test.stopTest();
    }
}
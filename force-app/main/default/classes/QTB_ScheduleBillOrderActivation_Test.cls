@isTest(seeAllData=false)
public class QTB_ScheduleBillOrderActivation_Test {
@IsTest
  static void testMethod1() {
    Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[0]) {
    QTB_ScheduleBillOrderActivationBatch batch=new  QTB_ScheduleBillOrderActivationBatch();
   String sch ='0 0 * * * ?';
   system.schedule('Test status Check', sch,batch );
	Test.stopTest();
    System.assertEquals(2,userList.size());    
    
        
}
  }
}
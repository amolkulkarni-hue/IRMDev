@isTest(SeeAllData=true)
private class Test_IM_NotificationAndFieldUpdateBatch{
    static testMethod void testIM_NotificationAndFieldUpdateBatch()
    {
       String usrId = UserInfo.getUserId();
        test.startTest();
       
          Lead lead= new Lead();
           lead.Email='valid@ironmountain.com';
           lead.OwnerId=usrId ;
           lead.LastName='Testing';
           lead.Company='Testing Company';
           lead.Status='New';
           lead.IM_Lead_Stage__c = '3-Sales Accepted';
           lead.IM_Stage_3_Entered_Date__c= System.today()-12;
           lead.Send_Email_Alert__c=false;
           lead.StageComparisonDate__c=System.today()-12;
           lead.Send_Email_Alert__c= false;
           lead.IsConverted = false;
           insert lead;
           
           IM_NotificationAndFieldUpdateBatch batchemail= new IM_NotificationAndFieldUpdateBatch();
           batchemail.queryStr = 'SELECT Id , '+
                      'Owner.Email , '+
                      'IM_Lead_Stage__c , '+
                      'IM_Stage_3_Entered_Date__c, '+
                      'Most_Recent_Sales_Activity__c, '+
                      'StageComparisonDate__c, '+
                      'batch_Email_Formula__c, '+
                      'Batch_Field_Update__c, '+
                      'Send_Email_Alert__c, '+
                      'batch_field_check__c '+
                      'FROM Lead '+ 
                      'WHERE StageComparisonDate__c != null '+
                      'AND Id=\''+lead.Id+'\'';
           System.debug('batchemail.queryStr=='+batchemail.queryStr); 
           Database.executeBatch(batchemail);
           
           test.stopTest();  
    }
    
    static testMethod void testIM_NotificationAndFieldUpdateBatch1()
    {
       String usrId = UserInfo.getUserId();
        test.startTest();
       
          Lead lead= new Lead();
           lead.Email='valid@ironmountain.com';
           lead.OwnerId=usrId ;
           lead.LastName='Testing';
           lead.Company='Testing Company';
           lead.Status='New';
           lead.IM_Lead_Stage__c = '3-Sales Accepted';
           lead.IM_Stage_3_Entered_Date__c= System.today()-15;
           lead.Send_Email_Alert__c=false;
           lead.StageComparisonDate__c=System.today()-15;
           lead.Send_Email_Alert__c= false;
           lead.IsConverted = false;
           insert lead;
           
           IM_NotificationAndFieldUpdateBatch batchemail= new IM_NotificationAndFieldUpdateBatch();
           batchemail.queryStr = 'SELECT Id , '+
                      'Owner.Email , '+
                      'IM_Lead_Stage__c , '+
                      'IM_Stage_3_Entered_Date__c, '+
                      'Most_Recent_Sales_Activity__c, '+
                      'StageComparisonDate__c, '+
                      'batch_Email_Formula__c, '+
                      'Batch_Field_Update__c, '+
                      'Send_Email_Alert__c, '+
                      'batch_field_check__c '+
                      'FROM Lead '+ 
                      'WHERE StageComparisonDate__c != null '+
                      'AND Id=\''+lead.Id+'\'';
           System.debug('batchemail.queryStr=='+batchemail.queryStr); 
           Database.executeBatch(batchemail);
           
           test.stopTest();  
    }  
    
     static TestMethod void doTest2(){
       Schedule_NotificationAndFieldUpdateBatch b1=new Schedule_NotificationAndFieldUpdateBatch();
       //Test.starttest();   
       b1.execute(null);
       //Test.stoptest();
    }
    
}
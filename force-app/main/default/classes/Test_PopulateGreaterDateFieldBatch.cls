@isTest
public class Test_PopulateGreaterDateFieldBatch {
    @testSetup static void setup()
    {
        //Creating Lead
        List<Lead> leadList = new List<Lead>();
        Lead ld = new Lead(
            Email = 'abc@xyz.com',
            Status = 'New',
            FirstName = 'Lead',
            LastName = 'TestContact',
            IM_Lead_Stage__c = '0-Suspect',
            Company = 'XYZ',
            IM_Stage_3_Entered_Date__c = date.today(),
            Most_Recent_Sales_Activity__c = datetime.now(),
            StageComparisonDate__c = Date.today().toStartofWeek()
        ) ;
        leadList.add(ld);
        insert leadList;
        
    }
    
    Static TestMethod void givenLeadsWhenExecuteBatchThenPopulateStageComparisionDate(){
        Lead ld1 = [SELECT Id ,IM_Stage_3_Entered_Date__c,Most_Recent_Sales_Activity__c,StageComparisonDate__c
                    FROM Lead  
                    WHERE IM_Stage_3_Entered_Date__c != null
                    AND IsConverted = false LIMIT 1];
        IM_PopulateGreaterDateFieldBatch b=new IM_PopulateGreaterDateFieldBatch();
        Test.starttest();   
        Database.executeBatch(b,200);
        Test.stoptest();
        Lead updLd = [SELECT Id ,IM_Stage_3_Entered_Date__c,Most_Recent_Sales_Activity__c,StageComparisonDate__c
                      FROM Lead  
                      WHERE IM_Stage_3_Entered_Date__c != null
                      AND IsConverted = false AND Id = :ld1.Id  LIMIT 1];
        System.assertEquals(updLd.StageComparisonDate__c, ld1.IM_Stage_3_Entered_Date__c, 'Stage Comparision date is not populated with the date') ;
    }
    Static TestMethod void doTest1(){
        Schedule_PopulateGreaterDateFieldBatch b1=new Schedule_PopulateGreaterDateFieldBatch();
        Test.starttest();   
        b1.execute(null);
        Test.stoptest();
    }
    
    Static TestMethod void givenLeadsWhenExecuteBatchAndMostRecentSalesActivityIsNullThenPopulateStageComparisionDate(){
        Lead ld = [SELECT Id ,IM_Stage_3_Entered_Date__c,Most_Recent_Sales_Activity__c,StageComparisonDate__c
                   FROM Lead  
                   WHERE IM_Stage_3_Entered_Date__c != null
                   AND IsConverted = false LIMIT 1];
        ld.Most_Recent_Sales_Activity__c = NULL;
        update ld;
        IM_PopulateGreaterDateFieldBatch b=new IM_PopulateGreaterDateFieldBatch();
        Test.starttest();   
        Database.executeBatch(b,200);
        Test.stoptest();
        Lead updLd = [SELECT Id ,IM_Stage_3_Entered_Date__c,Most_Recent_Sales_Activity__c,StageComparisonDate__c
                      FROM Lead  
                      WHERE IM_Stage_3_Entered_Date__c != null
                      AND IsConverted = false AND Id = :ld.Id  LIMIT 1];
        System.assertEquals(updLd.StageComparisonDate__c, ld.IM_Stage_3_Entered_Date__c, 'Stage Comparision date is not populated with the date') ;
    }
    
}
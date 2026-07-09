@isTest
public class Test_AccountRegNumberUpdateBatch {
    
    public static void setup()
    {
        Trigger_Activation_Settings__c tas = new Trigger_Activation_Settings__c(Object__c ='Account',Name='CopyRegToRelatedObjects',Trigger__c='CopyRegToRelatedObjects', Value__c='True');
        insert tas;        
    }
    static TestMethod void testRegNoBatchClass()
    {
        IM_Country__c countryRec =  new IM_Country__c();
            countryRec.Iso31662Code__c ='US';
            countryRec.Iso31663Code__c ='USA';
            countryRec.Name ='United States';
            countryRec.Region__c ='North America';
            
            insert countryRec;
            IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='North America' and Name ='United States'];
            
            IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
            altcountry.IM_Country__c = retCountry.id;
            altcountry.Alternative_Name__c='United States'; 
            
            insert altcountry;
         RecordType EUOppType = [select id from RecordType where name = 'Standard Opportunity' and  sObjectType = 'Opportunity'];
            IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry( (new IM_Country__c(name = 'United States',Region__c = 'North America'))); 
           
           Account testAcc = TestingUtils.createAccounts(1, true)[0]; 
        testAcc.Registration_Number_Updated__c = true;
        update testAcc;
        
        contact testCont = TestingUtils.createContact(testAcc.Id, true);
 
         opportunity  testOpp = TestingUtils.createOpportunity('testOpp', testAcc.Id, false);
            
    
        
       /* Opportunity testOpp = new Opportunity(Name = 'Test Opp', AccountId = testAcc.id,  
                                              StageName = '1 - Qualification', CloseDate = System.today());
        insert testOpp;*/
        
        IM_Customer_Account__c testCustAcct = new IM_Customer_Account__c(Name='test Cust',IM_Account__c=testAcc.id,Risk_Status__c='At Risk',IM_Oracle_ID__c='123456',Rate_Table_ID__c='test rate table',Source_System__c='SKP NA');
        insert testCustAcct;
        
        AccountRegNoUpdate_Scheduler b1=new AccountRegNoUpdate_Scheduler();
        Test.starttest();   
        	b1.execute(null);
        Test.stoptest();
    }
    
}
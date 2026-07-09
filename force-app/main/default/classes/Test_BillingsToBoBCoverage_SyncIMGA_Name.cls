/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 8/1/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used as test utility for BillingsToBoBCoverage_SyncIMGA_Name batch job. 
   
   Case Number       : 01347129
                                  
 ********************************/  

 /* Commenting the entire code as part of Gitlab #24446 */
@isTest
public class Test_BillingsToBoBCoverage_SyncIMGA_Name {
    /*
    public static List<Billings__c> TestData=new List<Billings__c>();
    public static Account TestAccount=new Account();
    public static IM_Customer_Account__c testCustomerAccount=new IM_Customer_Account__c();
    public static final Id Billing_RecordType_ID =
            [ select id from recordtype
               where sobjecttype = 'Billings__c' and name = 'Standard Billings' ].Id;      
    public static void doInsetTestData(){
        TestAccount.Name='test Account';
        TestAccount.IM_IMGA_Indexed__c='TEST';
        insert TestAccount;
        
        testCustomerAccount.name = 'Test CustAcc';
        testCustomerAccount.IM_Account__c = TestAccount.Id;
        testCustomerAccount.IM_Source_System_Code__c = 'ABCDE'+System.today().format();
        testCustomerAccount.IM_District_Branch_Id__c = 'ABCDE';
        testCustomerAccount.IM_Inventory_System_Number__c = 'ABCDE'+System.today().format();
        
        insert testCustomerAccount;
        
        for(Integer i=0;i<10;i++){
            Billings__c b=new Billings__c();
            b.Business_Line__c='test'+i;
            b.Customer_Account__c=testCustomerAccount.id;
            b.Invoice_Date__c=Date.Today();
            b.RecordTypeId=Billing_RecordType_ID;
            b.Unit_Qty__c=2;
            b.Unit_Rate__c=25;
            TestData.add(b);
        }
        insert TestData;
    }
     static TestMethod void doTest(){
        
        doInsetTestData();
        BillingsToBoBCoverageJoins__c settings;         
    
        // instantiate a test Custom Setting
        settings = new BillingsToBoBCoverageJoins__c();
        
        // override its defaults as needed
        settings.Abort_Previous_Jobs__c     = true;                                   // ensure no competition       
        settings.Description__c             = 'Temporary unit test control set';
        settings.Log_Debug_Enabled__c       = true;
        settings.Focus_Start_Period__c      = 1;
        settings.Focus_End_Period__c        = 12;
        settings.Focus_Year__c              = String.valueOf(DateTime.now().year());
        settings.Name                       = 'test';
        settings.Chatter_Group__c           = 'M2 BoB Performance Reporting Updates';
        settings.RecordTypeId__c = 'AND RecordTypeId IN(\'01280000000UI9X\' ,\'01280000000UI9Y\')';
        // create that record
        try {
            insert settings;
        }                
        catch (Exception curse) {
            system.debug('BillingsToBoBCoverageJoins__c insert failed: ' + curse);
        }
        Test.StartTest();
        BillingsToBoBCoverage_SyncIMGA_Name testInstance=new BillingsToBoBCoverage_SyncIMGA_Name(settings.Name);
        DataBase.executeBatch(testInstance,2000);
        Test.stopTest();
        for(Integer i=0;i<TestData.size();i++){
            system.assertEquals(TestData[i].IMGA_Name_Text__c,TestData[i].IMGA_Name_Formula__c,'IMGA VALUES ARE NOT MATCHING');
        }
    }
    */
}
@isTest//(seeAllData=true)
public class Test_BillingsToBoBCoverage_Country_Sync {
    static TestMethod void doTest(){
        new BillingsToBoBCoverage_Country_Master();
        new BillingsToBoBCoverage_Country_Sync_Name();
        new BillingsToBoBCvrg_M4_Country_Associate();
        new BillingsToBoBCoverage_Country_Associate();
        new BillingsToBoBCoverage_Country_M4_Master();
        new BillingsToBobCoverage_Country_Model();
        new BillingsToBobCoverage_M4_Model(); 
        /*Begin Gitlab #24446 */ 
        new BillingsToBoBCoverage_Associate();
        new BillingsToBoBCoverage_Helper();
        new BillingsToBoBCoverage_Log();
        new BillingsToBoBCoverage_Master();
        new BobCoverageContExt();
		new BillingsToBoBCoverage_SyncIMGA_Name();
		new BillingsToBobCoverage_Model();
		new InboundStorageToBoBCoverage_Helper();
		new InboundStorageToBoBCoverage_Log();
		new M4BobCoverageContExt();
        /*End Gitlab #24446 */
        /*Begin Gitlab #24448 */
        new AccountPrioritizationBatch();
        new BatchInboundStorageAssignment();
        new EndingBalanceBatch();
        new M4AggregateStorageRevenueBatch();
        new ProspectingEntryCreationBatch();
        new TerritorySnapshotBatch();
        new M1_Physical_CDE_Batch();
        new TestTerritorySnapshotBatch();
        new AccountPrioritizationService();
        new InboundStorageAssignment();
        new EndingBalanceBatchModel();
        new M4AggregateStorageRevenueBatch_Finish();
        new M4AggregateStorageRevenueHelper();
        new TerritorySnapshotBatchModel();
        /*End Gitlab #24448 */
        /*Begin Gitlab #25402 */
        new BillingsToBoBCoverage_LauncherCont();
        new M4RevenueContExt();
        new QTB_BoBEligibleRenewals();
        /*End Gitlab #25402 */
        
    }
    /*public static final Id Billing_RecordType_ID =
            [ select id from recordtype
               where sobjecttype = 'Billings__c' and name = 'Country Parent' ].Id;
    public static final Id bob_RecordType_ID = [ select id from recordtype
               where sobjecttype = 'BoB_Coverage__c' and name = 'Country Parent' ].Id;
    public static final Id customeraccount_RecordType_ID = [ select id from recordtype
               where sobjecttype = 'IM_Customer_Account__c' and name = 'IME Customer Account' ].Id;
    public static Account TestAccount=new Account();
    public static IM_Customer_Account__c testCustomerAccount=new IM_Customer_Account__c();
    public static List<Billings__c> TestData=new List<Billings__c>();
 / *   
   static testMethod void myUnitTest() {  

        TestAccount.Name='test Account';
        TestAccount.IM_IMGA_Indexed__c='TEST';
        TestAccount.IM_Hierarchy_Level__c='Country Parent'; 
        insert TestAccount;
        
        testCustomerAccount.name = 'Test CustAcc';
        testCustomerAccount.IM_Account__c = TestAccount.Id;
        testCustomerAccount.IM_Source_System_Code__c = 'ABCDE'+System.today().format();
        testCustomerAccount.IM_District_Branch_Id__c = 'ABCDE';
        testCustomerAccount.IM_Inventory_System_Number__c = 'ABCDE'+System.today().format();
        
        insert testCustomerAccount;
        
        for(Integer i=0;i<5;i++){
            Billings__c b=new Billings__c();
            b.Business_Line__c='test'+i;
            b.Customer_Account__c=testCustomerAccount.id;
            b.Invoice_Date__c=Date.Today();
            b.Unit_Qty__c=2;
            b.Unit_Rate__c=25;
            b.Country_Parent_ID_Text__c=TestAccount.id;
            b.RecordTypeId = Billing_RecordType_ID;
            TestData.add(b);
        }
        insert TestData;  
       
      //  Bob_Coverage__c bobCoverage = TestingUtils.createBoBCoverages( 1, TestAccount.Id, 'TestBoB', 'Test Product', 'United Kingdom', true )[0];
        List<BoB_Coverage__c> testCoverages = new List<BoB_Coverage__c>();
        for( Integer i=0; i<1; i++ )
        {
            testCoverages.add( new BoB_Coverage__c( Account__c = TestAccount.Id, Country_Coverage__c = 'United Kingdom', Product_Coverage__c = 'Test Product', Name = 'TestBob' ,RecordTypeId=bob_RecordType_ID ) );
        }

        insert testCoverages;  
       
       BillingsToBoBCoverage_Country_Sync_Name csn = new BillingsToBoBCoverage_Country_Sync_Name('IME Production');         
       csn.start(null);
       csn.execute(null, TestData);
       csn.finish(null);  
       database.executeBatch(csn,100);

       BillingsToBoBCoverage_Country_Associate bca = new BillingsToBoBCoverage_Country_Associate('IME Production','12345');         
       bca.start(null);
       bca.execute(null, TestData);
       bca.finish(null);       
    } 


    public static List<Billings__c> TestData=new List<Billings__c>();
    public static Account TestAccount=new Account();
    public static IM_Customer_Account__c testCustomerAccount=new IM_Customer_Account__c();
   public static final Id Billing_RecordType_ID =
            [ select id from recordtype
               where sobjecttype = 'Billings__c' and developername = 'Country_Parent' ].Id;       
* /
    public static void doInsetTestData(){
        TestAccount.Name='test Account';
      //  TestAccount.IM_IMGA_Indexed__c='TEST';
      //  TestAccount.CountryParentIDText__c='TEST';
        TestAccount.IM_Hierarchy_Level__c ='Country Parent';
        insert TestAccount;
        
        testCustomerAccount.name = 'Test CustAcc';
        testCustomerAccount.IM_Account__c = TestAccount.Id;
        testCustomerAccount.IM_Source_System_Code__c = 'ABCDE'+System.today().format();
        testCustomerAccount.IM_District_Branch_Id__c = 'ABCDE';
        testCustomerAccount.IM_Inventory_System_Number__c = 'ABCDE'+System.today().format();
        testCustomerAccount.IM_Status__c='Active';
        testCustomerAccount.RecordTypeId=customeraccount_RecordType_ID;
        
        
        insert testCustomerAccount;
        
        for(Integer i=0;i<10;i++){
            Billings__c b=new Billings__c();
            b.Business_Line__c='test'+i;
            b.Customer_Account__c=testCustomerAccount.id;
            b.Invoice_Date__c=Date.Today();
            b.Unit_Qty__c=2;
            b.Unit_Rate__c=25;
            b.RecordTypeId=Billing_RecordType_ID;
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
        settings.RecordTypeId__c            = Billing_RecordType_ID;
    / *    settings.Query_Associate_Order_By__c = 'Id Desc';
        settings.Query_Associate_Select__c = 'Id, Country_Parent_ID_Text__c';
        settings.Query_Associate_Where__c = ' Id <> Null';  * /
        // create that record
        try {
            insert settings;
        }                
        catch (Exception curse) {
            system.debug('BillingsToBoBCoverageJoins__c insert failed: ' + curse);
        }
        Test.StartTest();
        BillingsToBoBCoverage_Country_Sync_Name testInstance=new BillingsToBoBCoverage_Country_Sync_Name(settings.Name);
        DataBase.executeBatch(testInstance,2000);
        Test.stopTest();
    }*/
 }
/* Commenting the entire code as part of Gitlab #24448 */
@isTest
private class M4AggregateStorageRevenueHelperTest {
   /*
    public static List<Billings__c> billings;
    public static Account acc;
    public static List<Parent_Billing_Market__c> pbms;
    public static List<Billing_Market__c> billingMarkets;
    
    public static void setup(){
        acc =  TestingUtils.createAccounts(1, false)[0];
        acc.IM_IMGA_Indexed__c = acc.name;
        insert acc;
        
        Product2 testProduct = TestingUtils.createProduct('IM Product 1', false);
        testProduct.IM_Product_Class__c = 'RM';
        insert testProduct;     
        
        List<IM_Customer_Account__c> customerAccounts = new List<IM_Customer_Account__c>();
        for (Integer i=0; i < 5; i++){
            customerAccounts.add(TestingUtils.createCustomerAccount(acc.id, false));
        }
        
        insert customerAccounts;
        
        pbms = TestingUtils.createParentBillingMarketRecords(3, true);
        
        billingMarkets = new List<Billing_Market__c>();
        
        billingMarkets.add(TestingUtils.createBillingMarket('Boston', 'Boston', pbms[0].id, false));
        billingMarkets.add(TestingUtils.createBillingMarket('Chicago', 'Chicago', pbms[1].id, false));
        billingMarkets.add(TestingUtils.createBillingMarket('Atlanta', 'Atlanta', pbms[2].id, false));
        
        insert billingMarkets;
        
        billings = new List<Billings__c>();
        for(IM_Customer_Account__c customerAccount : customerAccounts){
            for(Billing_Market__c billingMarket : billingMarkets){
                billings.add(IMGAUtilities.createTestBilling(customerAccount.Id, Date.today(), billingMarket.Id, testProduct.id));
            }
        }
        insert billings;
        
        billings = [Select Amount__c, Parent_Billing_Market__c, Country_Coverage__c, Parent_Billing_Market_ID__c,
                    IMGA_Name_Formula__c, Product_Class__c, Invoice_Date__c,
                    Billing_Market__r.Parent_Billing_Market__c, Customer_Account__c, Billing_Period__c
                    from Billings__c where ID IN: billings];
    }


    public static testMethod void buildM4HashesTest(){
        setup();
        
        Set<String> expectedHashes = new Set<String>();
        
        expectedHashes.add('TestAccount_0' + 'Test Parent Bill0');
        expectedHashes.add('TestAccount_0' + 'Test Parent Bill1');
        expectedHashes.add('TestAccount_0' + 'Test Parent Bill2');
        expectedHashes.add('TestAccount_0' + 'Canada');
        expectedHashes.add('TestAccount_0' + 'North America');
        
        
        
        Set<String> actualHashesReturned = new Set<String>();
        Test.startTest();
            actualHashesReturned = M4AggregateStorageRevenueHelper.buildM4Hashes(billings);
        Test.stopTest();
        
        System.AssertEquals(5, actualHashesReturned.size(), 'An incorrect number of hashes returned');
        System.AssertEquals(expectedHashes, actualHashesReturned, 'Incorrect hashes returned');
    }
    
    public static testMethod void findM4Test(){
        
        setup();
        
        M4_Revenue_Coverage__c m4coverageOne = new M4_Revenue_Coverage__c(Effective_Start_Period__c = '1');
        M4_Revenue_Coverage__c m4coverageTwo = new M4_Revenue_Coverage__c(Effective_Start_Period__c = '2');
        M4_Revenue_Coverage__c m4coverageThree = new M4_Revenue_Coverage__c(Effective_Start_Period__c = '3'); 
        
        Map<String, List<M4_Revenue_Coverage__c>> m4coverageMapOne = new Map<String, List<M4_Revenue_Coverage__c>>{
            'TestAccount_0' + 'Test Parent Bill0' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageOne},
            'TestAccount_0' + 'Test Parent Bill1' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageTwo},
            'TestAccount_0' + 'Test Parent Bill2' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageThree}
        };
        Map<String, List<M4_Revenue_Coverage__c>> m4coverageMapTwo = new Map<String, List<M4_Revenue_Coverage__c>>{
            'TestAccount_0' + 'North America' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageTwo},
            'TestAccount_0' + 'Test Parent Bill1' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageTwo},
            'TestAccount_0' + 'Test Parent Bill2' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageThree}
        };
        Map<String, List<M4_Revenue_Coverage__c>> m4coverageMapThree = new Map<String, List<M4_Revenue_Coverage__c>>{
            'TestAccount_0' + 'Canada' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageThree},
            'TestAccount_0' + 'Test Parent Bill1' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageTwo},
            'TestAccount_0' + 'Test Parent Bill2' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageThree}
        };
        Map<String, List<M4_Revenue_Coverage__c>> m4coverageMapFour = new Map<String, List<M4_Revenue_Coverage__c>>{
            'TestAccount_0' + 'Test Parent Bill1' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageTwo},
            'TestAccount_0' + 'Test Parent Bill2' + 'RM' => new List<M4_Revenue_Coverage__c>{m4coverageThree}
        };
        
    
        Billings__c bill = billings[0];
        
        Test.startTest();
            M4_Revenue_Coverage__c coverageOne = M4AggregateStorageRevenueHelper.findM4s(bill, m4coverageMapOne)[0];
            M4_Revenue_Coverage__c coverageTwo = M4AggregateStorageRevenueHelper.findM4s(bill, m4coverageMapTwo)[0];
            M4_Revenue_Coverage__c coverageThree =  M4AggregateStorageRevenueHelper.findM4s(bill, m4coverageMapThree)[0];
            List<M4_Revenue_Coverage__c> coverageFour = M4AggregateStorageRevenueHelper.findM4s(bill, m4coverageMapFour);
        Test.stopTest();
        
        System.AssertEquals(m4coverageOne, coverageOne, 'An incorrect coverage returned');
        System.AssertEquals(m4coverageTwo, coverageTwo, 'An incorrect coverage returned');
        System.AssertEquals(m4coverageThree, coverageThree, 'An incorrect coverage returned');
        System.AssertEquals(null, coverageFour, 'An incorrect coverage returned');
    }
    
    static testMethod void findAggregateTest(){
        setup();
        
        M4_Revenue_Coverage__c emptyCoverage, queriedCoverage, queriedIncrementedCoverage = new M4_Revenue_Coverage__c();
        queriedCoverage = ImgaUtilities.createTestM4(acc.id, pbms[0].id, 'Canada', 'RM');
        queriedIncrementedCoverage = ImgaUtilities.createTestM4(acc.id, pbms[0].id, 'Canada', 'RM');
        emptyCoverage = ImgaUtilities.createTestM4(acc.id, pbms[2].id, 'Zanzibar', 'RM');
        insert new List<M4_Revenue_Coverage__c>{emptyCoverage, queriedCoverage, queriedIncrementedCoverage};
        
         
        
        Aggregate_Storage_Revenue__c expectedqueriedRevenueWithNewAmount,expectedQueriedRevenueWithIncrementedAmount,
                                     queriedRevenueWithNewAmount, queriedRevenueWithIncrementedAmount, emptyRevenue,
                                     newRevenue, expectedNewRevenue, existingRevenueWithIncrementedAmount; 
        
        expectedqueriedRevenueWithNewAmount = new Aggregate_Storage_Revenue__c();
        expectedqueriedRevenueWithNewAmount.M4_Revenue_Coverage__c = queriedCoverage.id;
        expectedqueriedRevenueWithNewAmount.Parent_Billing_Market__c = pbms[0].id;
        expectedqueriedRevenueWithNewAmount.Product_Class__c = billings[0].Product_Class__c;
        expectedqueriedRevenueWithNewAmount.Aggregation_In_Progress__c = true;
        expectedqueriedRevenueWithNewAmount.amount__c = 0;
        expectedqueriedRevenueWithNewAmount.Customer_ID__c = billings[0].customer_Account__c;
        insert expectedqueriedRevenueWithNewAmount;
        
        
        
        Map<Id, M4_Revenue_Coverage__c> revenues = new Map<Id,M4_Revenue_Coverage__c>([Select Aggregate_Storage_Hash__c, id, Product_Coverage__c,
                                                (Select Product_Class__c, Id, Amount__c, Aggregation_in_Progress__c, Customer_ID__c, Billing_Period__c From Aggregate_Storage_Revenue__r) 
                                                from M4_Revenue_Coverage__c where ID =: queriedCoverage.id OR ID =: queriedIncrementedCoverage.id]);
        queriedCoverage = revenues.get(queriedCoverage.id);
        queriedIncrementedCoverage = revenues.get(queriedIncrementedCoverage.id);
        
        
         Map<String, Aggregate_Storage_Revenue__c> coverageHashToRevenue = new Map<String, Aggregate_Storage_Revenue__c>{
            queriedCoverage.Aggregate_Storage_hash__c + billings[0].Product_Class__c + queriedCoverage.id + billings[0].customer_Account__c + billings[0].billing_period__c =>
                                                    expectedqueriedRevenueWithNewAmount
        };
        Map<id, List<Aggregate_Storage_Revenue__c>> AggStorageRevMap = new Map<id, List<Aggregate_Storage_Revenue__c>>();
        for(M4_Revenue_Coverage__c coverage : [Select Aggregate_Storage_Hash__c, id, Product_Coverage__c,
                                                (Select Product_Class__c, Id, Amount__c, Aggregation_in_Progress__c, Customer_ID__c, Billing_Period__c,M4_Revenue_Coverage__c From Aggregate_Storage_Revenue__r) 
                                               from M4_Revenue_Coverage__c where ID =: queriedCoverage.id OR ID =: queriedIncrementedCoverage.id]){
                                               
         for(Aggregate_Storage_Revenue__c AST : coverage.Aggregate_Storage_Revenue__r){
            if(AggStorageRevMap.containsKey(AST.M4_Revenue_Coverage__c)){
               AggStorageRevMap.get(AST.M4_Revenue_Coverage__c).add(AST);
           }else{
               AggStorageRevMap.put(AST.M4_Revenue_Coverage__c, new List<Aggregate_Storage_Revenue__c>{AST});
           }
        }
       }
        
        Test.startTest();
            
            queriedRevenueWithNewAmount = M4AggregateStorageRevenueHelper.findAggregates(billings[0], new List<M4_Revenue_Coverage__c>{queriedCoverage}, coverageHashToRevenue,AggStorageRevMap)[0];
            
            expectedQueriedRevenueWithIncrementedAmount = expectedqueriedRevenueWithNewAmount.clone(true, true);
            expectedQueriedRevenueWithIncrementedAmount.Amount__c += 1;
            coverageHashToRevenue.put(queriedCoverage.Aggregate_Storage_hash__c + billings[0].Product_Class__c + queriedCoverage.id + billings[0].customer_Account__c + billings[0].billing_period__c,
                                                    expectedQueriedRevenueWithIncrementedAmount);
            
            
            queriedRevenueWithIncrementedAmount = M4AggregateStorageRevenueHelper.findAggregates(billings[0], new List<M4_Revenue_Coverage__c>{queriedCoverage}, coverageHashToRevenue,AggStorageRevMap)[0];
            
            newRevenue = M4AggregateStorageRevenueHelper.findAggregates(billings[0], new List<M4_Revenue_Coverage__c>{emptyCoverage}, coverageHashToRevenue,AggStorageRevMap)[0];
            emptyRevenue =  M4AggregateStorageRevenueHelper.findAggregates(billings[0], new List<M4_Revenue_Coverage__c>{emptyCoverage}, new Map<String, Aggregate_Storage_Revenue__c>(),AggStorageRevMap)[0];
        Test.stopTest();
        
        System.AssertEquals(11.0, queriedRevenueWithNewAmount.amount__c, 'An incorrect amount has been set on this revenue');
        System.AssertEquals(23.0, queriedRevenueWithIncrementedAmount.amount__c, 'An incorrect amount has been set on this revenue');
        System.AssertEquals(11.0, newRevenue.amount__c,'An incorrect amount has been set on this revenue');
        System.AssertEquals(11, emptyRevenue.amount__c,'An incorrect amount has been set on this revenue');
        
        
        
    }
    */
    
       
 
}
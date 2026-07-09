/**
**Author: Kenny W, Leo Z
**Date: 9/21/13
**Company: Bluewolf
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 09/30/2013; Kenny W/Bluewolf; Cac Responsiblity Viewer - Cac Responsiblity Viewer Unit Tests (Case # 01153062); Initial release
**/

@isTest
private class TestCustomerAccountViewerExt {
    
    static List<Account> testAccounts;
    static Contact testContact;
    
    
    static void setupSingle()
    {
        testAccounts = TestingUtils.createAccounts(3, true);
        update testAccounts[0];
        testContact = TestingUtils.createContact(testAccounts[0].Id, true);
    
        PageReference ref = Page.CustomerAccountViewer;
        ref.getParameters().put('id', testContact.Id);
        Test.setCurrentPage(ref);   
    }
    
    static testMethod void Test_generateSelectOptions_customerAccountList()
    {       
        CustomerAccountViewerExt cave;
        setupSingle();
        Test.startTest();
            cave = new CustomerAccountViewerExt();
            cave.generateSelectOptions();
        Test.stopTest();
        //System.assertEquals(CustomerAccountViewerExt.customerAcctSelectOptionMap.size()-3, cave.customerAccountList.size(), 'The customerAccountList should have the same number of values as the CustomerAcctSelectionOptionMap minus 3, 2 because there are no IMGA or Country parent in the hierarchy, and 1 more because only its a contact standard controller');
    }
    
    static testMethod void Test_generateSelectOptions_cacResponsibilityList_unique()
    {   
        final Integer NUM_OF_CACS = 3;
        CustomerAccountViewerExt cave;
        setupSingle();
        
        List<IM_Customer_Account__c> custList = TestingUtils.createCustomerAccounts (1, testAccounts[0].Id, true );
                
        TestingUtils.createCacs(NUM_OF_CACS, custList[0].Id, testContact.Id, true); 
        TestingUtils.createCacs(NUM_OF_CACS, custList[0].Id, testContact.Id, true);
        
        Test.startTest();
            cave = new CustomerAccountViewerExt();
            cave.generateSelectOptions();
        Test.stopTest();
        
        System.assertEquals(NUM_OF_CACS+1, cave.cacResponsiblityList.size() , 'The Cac responsibility list should have 1 + the number of cacs created (minus duplicates)');      
                    
    }
    
    static testMethod void Test_generateSelectOptions_cacResponsibilityList_none()
    {   
        final Integer ONE_ELEMENT_FOR_CHOICE_ALL = 1;
        CustomerAccountViewerExt cave;
        setupSingle();              
        Test.startTest();
            cave = new CustomerAccountViewerExt();
            cave.generateSelectOptions();
        Test.stopTest();
        
        System.assertEquals(ONE_ELEMENT_FOR_CHOICE_ALL, cave.cacResponsiblityList.size() , 'If there are no Cacs, then the list should have one element for the All choice');                       
    }
    
    static testMethod void Test_acctHierarchyGatherer()
    {
        CustomerAccountViewerExt cave;
        setupSingle();
        
        Account testAccountA = testAccounts[2];
        testAccountA.IM_Hierarchy_Level__c = 'Parent HQ';
        Account testAccountB = testAccounts[1];
        testAccountB.ParentId = testAccountA.Id;
        Account testAccountC = testAccounts[0];
        testAccountC.ParentId = testAccountB.Id;
        
        update testAccounts;
        
        Set<Id> acctIdsExpected = new Set<Id>();
        for(Account a : testAccounts)
        {
            acctIdsExpected.add(a.Id);
        }
        
        List<Id> acctIdsActual = new List<Id>();
        
        Test.startTest();
            cave = new CustomerAccountViewerExt();
            acctIdsActual = cave.acctHierarchyGatherer(testAccountC.Id, 'Parent HQ');
        Test.stopTest();
        
        for(Id id : acctIdsActual)
        {
            System.assert(acctIdsExpected.contains(id),'The ids in the list should contain the ids of the parents up to the Heirarchy Level');
        }
        
        System.assertEquals(acctIdsExpected.size(), acctIdsActual.size() , 'Both lists should be the same size');       
    }
    
    static testMethod void Test_acctHierarchyGatherer_OneAccountWithoutHierarchy()
    {
        final Integer ONE_ELEMENT_IN_LIST = 1;
        CustomerAccountViewerExt cave;
        setupSingle();
        
        testAccounts[0].IM_Hierarchy_Level__c = 'Parent HQ';
        update testAccounts[0];

        List<Id> acctIdsActual = new List<Id>();
        
        Test.startTest();
            cave = new CustomerAccountViewerExt();
            acctIdsActual = cave.acctHierarchyGatherer(testAccounts[0].Id, 'Parent HQ');
        Test.stopTest();
        
        System.assertEquals(testAccounts[0].Id, acctIdsActual[0], 'Account should be the same Id as in the list since the list should contain the account');
        System.assertEquals(ONE_ELEMENT_IN_LIST, acctIdsActual.size() , 'List should be size 1 since it should contain the account');
        
    }
    
    static testMethod void Test_selectNewContact()
    {
        CustomerAccountViewerExt cave;
        setupSingle();
        
        Contact newContact = TestingUtils.createContact(testAccounts[0].Id, false);
        newContact.LastName = 'Zis';
        
        insert newContact;
        
        cave = new CustomerAccountViewerExt();
        cave.newContactLookupDummy.IME_SC_Contact__c = newContact.Id;
        Test.startTest();
            Pagereference ref = cave.selectNewContact();    
        Test.stopTest();
        System.assertEquals(newContact.Id, ref.getParameters().get('id'), 'The contact should have changed to the new contact');
        
    }
    
    static testMethod void Test_queryCacs_noFilters()
    {
        final Integer NUM_OF_CACS = 3;
        CustomerAccountViewerExt cave;
        setupSingle();
        
        Contact testContact2 = TestingUtils.createContact(testAccounts[0].Id, true);
        
        List<IM_Customer_Account__c> custList = TestingUtils.createCustomerAccounts(1, testAccounts[0].Id, true );
                
        List<IME_SC_CAc_Responsibility__c> cacListExpected = TestingUtils.createCacs(NUM_OF_CACS, custList[0].Id, testContact.Id, true);
        
        //Create a CAc that is associated with another contact so it should not show up in the query result
        TestingUtils.createCacs(1, custList[0].Id, testContact2.Id, true);
        
        Test.startTest();
            cave = new CustomerAccountViewerExt();
            cave.queryCacs();
        Test.stopTest();
        
        List<IME_SC_CAc_Responsibility__c> cacListActual = new List<IME_SC_CAc_Responsibility__c>();
        for(CustomerAccountViewerExt.CacWrapper aWrapper : cave.visibleCacResponsibilities)
        {
            cacListActual.add(aWrapper.theCac);
        } 
        
        System.assert(containsAllCacs(cacListExpected,cacListActual), 'All the cacs created in the expected list should be returned by the query if there are no filters' );
        System.assertEquals(NUM_OF_CACS, cacListActual.size() , 'The query should return the three CAcs we created');   
    }
    
    //Testing the "Contact Account Customer Accounts" filter
    static testMethod void Test_queryCacs_contactAcctFilter()
    {
        CustomerAccountViewerExt cave;
        setupSingle();
        
        List<IM_Customer_Account__c> custList = TestingUtils.createCustomerAccounts(2, testAccounts[0].Id, true );
        //A customer account associated with a different account. This should not show up in the query results
        List<IM_Customer_Account__c> custList2 = TestingUtils.createCustomerAccounts(1, testAccounts[1].Id, true );  
                
        List<IME_SC_CAc_Responsibility__c> cacListExpected = new List<IME_SC_CAc_Responsibility__c>();
        
        cacListExpected.add(TestingUtils.createCacs(1, custList[0].Id, testContact.Id, true)[0]);
        cacListExpected.add(TestingUtils.createCacs(1, custList[1].Id, testContact.Id, true)[0]);
        
        //create a CAc that should not appear in the query result
        TestingUtils.createCacs(1, custList2[0].Id, testContact.Id, true);
        
        Test.startTest();
            cave = new CustomerAccountViewerExt();
            cave.customerAcctFilter = 'contactAcct';
            cave.queryCacs();
        Test.stopTest();
        
        List<IME_SC_CAc_Responsibility__c> cacListActual = new List<IME_SC_CAc_Responsibility__c>();
        for(CustomerAccountViewerExt.CacWrapper aWrapper : cave.visibleCacResponsibilities)
        {
            cacListActual.add(aWrapper.theCac);
        }
        
        System.assert(containsAllCacs(cacListExpected,cacListActual), 'All the cacs we created in the expected list should be returned by the query' );
    }

    static testMethod void setupAccountHierarchy()
    {
        final String STARTING_ACCOUNT = 'The Highest Level Account';
        final Integer ALL_ACCOUNTS = 7;
        List<Account> accounts = TestingUtils.createAccounts( 7, false );
        Account originalAccount = accounts[0];
        originalAccount.IM_Hierarchy_Level__c = STARTING_ACCOUNT;
        insert originalAccount;

        Account act1stLayerLeft = accounts[1];
        act1stLayerLeft.ParentId = originalAccount.Id;
        Account act1stLayerRight = accounts[2];
        act1stLayerRight.ParentId = originalAccount.Id;
        insert new List<Account>{act1stLayerLeft, act1stLayerRight};

        Account act2ndLayerRight = accounts[3];
        act2ndLayerRight.ParentId = originalAccount.Id;
        insert act2ndLayerRight;

        Account act3rdLayerRight = accounts[4];
        act3rdLayerRight.ParentId = act2ndLayerRight.Id;
        insert act3rdLayerRight;

        Account act4thLayerRight = accounts[5];
        act4thLayerRight.ParentId = act3rdLayerRight.Id;
        insert act4thLayerRight;

        Account act5thLayerRight = accounts[6];
        act5thLayerRight.ParentId = act4thLayerRight.Id;
        insert act5thLayerRight;

        Test.startTest();
            List<Id> umbrellaAccounts = CustomerAccountViewerExt.hierarchyGathererAllUmbrellaAccounts( act5thLayerRight.Id, STARTING_ACCOUNT );
        Test.stopTest();

        System.assertEquals( ALL_ACCOUNTS, umbrellaAccounts.size(), 'We expect all accounts belonging to the account to be in this list');
        Set<Id> actualAccountIds = new Set<Id>( umbrellaAccounts );
        for( Account act : accounts )
        {
            System.assertEquals( true, actualAccountIds.contains( act.Id ), 'we expect all accounts belonging to the ' + STARTING_ACCOUNT + ' to be in this list');
        }

    }
    
    //testing the "Contact Customer Accounts" filter
    static testMethod void Test_queryCacs_contactFilter()
    {
        CustomerAccountViewerExt cave;
        setupSingle();
        
        //Create another contact that should not show up in the query results
        Contact testContact2 = TestingUtils.createContact(testAccounts[0].Id, true);
        List<IM_Customer_Account__c> custList = TestingUtils.createCustomerAccounts(2, testAccounts[0].Id, true ); 
                
        List<IME_SC_CAc_Responsibility__c> cacListExpected = new List<IME_SC_CAc_Responsibility__c>();
        
        cacListExpected.add(TestingUtils.createCacs(1, custList[0].Id, testContact.Id, true)[0]);
        cacListExpected.add(TestingUtils.createCacs(1, custList[1].Id, testContact.Id, true)[0]);
        
        //create a CAc that should not appear in the query result because it is associated with a different contact
        TestingUtils.createCacs(1, custList[0].Id, testContact2.Id, true);
        
        Test.startTest();
            cave = new CustomerAccountViewerExt();
            cave.customerAcctFilter = 'contact';
            cave.queryCacs();
        Test.stopTest();
        
        List<IME_SC_CAc_Responsibility__c> cacListActual = new List<IME_SC_CAc_Responsibility__c>();
        for(CustomerAccountViewerExt.CacWrapper aWrapper : cave.visibleCacResponsibilities)
        {
            cacListActual.add(aWrapper.theCac);
        } 
        
        System.assert(containsAllCacs(cacListExpected,cacListActual), 'All the cacs we created in the Expected list should be returned by the query' );
    }
    
    //testing the "Country Parent Customer Accounts" filter
    static testMethod void Test_queryCacs_countryParentFilter()
    {
        CustomerAccountViewerExt cave;
        setupSingle();
    
        Account testAccountA = testAccounts[1];
        testAccountA.IM_Hierarchy_Level__c = 'Country Parent';
        Account testAccountB = testAccounts[0];
        testAccountB.ParentId = testAccountA.Id;
        
        update testAccounts;
        
        //Create another contact / customer account that should not show up in the query results
        Contact testContactOther = TestingUtils.createContact(testAccounts[2].Id, true);
        IM_Customer_Account__c testCustomerAccOther = TestingUtils.createCustomerAccounts(1, testAccounts[2].Id, true )[0]; 
            
        List<IM_Customer_Account__c> custList = new List<IM_Customer_Account__c>();
        
        custList.add(TestingUtils.createCustomerAccounts(1, testAccounts[0].Id, true)[0]); 
        custList.add(TestingUtils.createCustomerAccounts(1, testAccounts[1].Id, true)[0]);
            
        List<IME_SC_CAc_Responsibility__c> cacListExpected = new List<IME_SC_CAc_Responsibility__c>();
        
        cacListExpected.add(TestingUtils.createCacs(1, custList[0].Id, testContact.Id, true)[0]);
        cacListExpected.add(TestingUtils.createCacs(1, custList[1].Id, testContact.Id, true)[0]);
        
        //create a CAc that should not appear in the query result because it is associated with a different contact / account   
        TestingUtils.createCacs(1, testCustomerAccOther.Id, testContactOther.Id, true);
            
        Test.startTest();
            cave = new CustomerAccountViewerExt();
            cave.customerAcctFilter = 'countryParent';
            cave.queryCacs();
        Test.stopTest();
        
        List<IME_SC_CAc_Responsibility__c> cacListActual = new List<IME_SC_CAc_Responsibility__c>();
        for(CustomerAccountViewerExt.CacWrapper aWrapper : cave.visibleCacResponsibilities)
        {
            cacListActual.add(aWrapper.theCac);
        } 
        
        System.assert(containsAllCacs(cacListExpected,cacListActual), 'All the cacs we created in the cacListExpected should be returned by the query' );
    }
    
    //testing the "IMGA Customer Accounts" filter
    static testMethod void Test_queryCacs_imgaFilter()
    {
        CustomerAccountViewerExt cave;
        setupSingle();
                
        Account testAccountA = testAccounts[1];
        testAccountA.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
        Account testAccountB = testAccounts[0];
        testAccountB.ParentId = testAccountA.Id;
        
        update testAccounts;
        
        //Create another contact / customer account that should not show up in the query results
        Contact testContactOther = TestingUtils.createContact(testAccounts[2].Id, true);
        IM_Customer_Account__c testCustomerAccOther = TestingUtils.createCustomerAccounts(1, testAccounts[2].Id, true )[0]; 
            
        List<IM_Customer_Account__c> custList = new List<IM_Customer_Account__c>();
        
        custList.add(TestingUtils.createCustomerAccounts(1, testAccounts[0].Id, true)[0]); 
        custList.add(TestingUtils.createCustomerAccounts(1, testAccounts[1].Id, true)[0]);
            
        List<IME_SC_CAc_Responsibility__c> cacListExpected = new List<IME_SC_CAc_Responsibility__c>();
        
        cacListExpected.add(TestingUtils.createCacs(1, custList[0].Id, testContact.Id, true)[0]);
        cacListExpected.add(TestingUtils.createCacs(1, custList[1].Id, testContact.Id, true)[0]);
        
        //create a CAc that should not appear in the query result because it is associated with a different contact / account   
        TestingUtils.createCacs(1, testCustomerAccOther.Id, testContactOther.Id, true);
            
        Test.startTest();
            cave = new CustomerAccountViewerExt();
            cave.customerAcctFilter = 'imga';
            cave.queryCacs();
        Test.stopTest();
        
        List<IME_SC_CAc_Responsibility__c> cacListActual = new List<IME_SC_CAc_Responsibility__c>();
        for(CustomerAccountViewerExt.CacWrapper aWrapper : cave.visibleCacResponsibilities)
        {
            cacListActual.add(aWrapper.theCac);
        }
        
        //System.assert(containsAllCacs(cacListExpected,cacListActual), 'All the cacs we created in the cacListExpected should be returned by the query' );
    }


    //Returns true if all the CAcs in cacListExpected are also in CAcListActual
    public static Boolean containsAllCacs(List<IME_SC_CAc_Responsibility__c> cacListExpected,List<IME_SC_CAc_Responsibility__c> cacListActual)
    {
        for(IME_SC_CAc_Responsibility__c cacExpected : cacListExpected)
        {
            if(!containsCac(cacListActual, cacExpected))
            {
                return false;
            }
        }
        return true;
    }
    
    public static Boolean containsCac(List<IME_SC_CAc_Responsibility__c> cacList, IME_SC_CAc_Responsibility__c findCac)
    {
        for(IME_SC_CAc_Responsibility__c acac : cacList)
        {
            if(acac.Id == findCac.Id)
            {
                return true;
            }
        }
        return false;
    }
}
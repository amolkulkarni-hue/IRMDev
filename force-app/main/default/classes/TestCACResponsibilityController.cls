@isTest
private class TestCACResponsibilityController {
    static List<Account> testAccounts = new List<Account>();
    static List<IM_Customer_Account__c> customerAccounts = new List<IM_Customer_Account__c>();
    static Contact testContact;
    static Contact testDuplicateContact;
    static Integer NUM_OF_CUST_ACCOUNTS = 5;
    static IME_SC_CAc_Responsibility__c cacResponsibility {get;set;}
    static PageReference ref = Page.CACResponsibilityMassCreate;
    
    static void setupData()
    {
        testAccounts = TestingUtils.createAccounts(3, true);
        testContact = TestingUtils.createContact(testAccounts[0].Id, true);
        testDuplicateContact = TestingUtils.createContact(testAccounts[0].Id, true);
        customerAccounts = TestingUtils.createCustomerAccounts(NUM_OF_CUST_ACCOUNTS, testAccounts[0].id,true);
        ref = Page.CACResponsibilityMassCreate;
        Test.setCurrentPage(ref);   
    }

    static testMethod void Test_controllerInstantiation_customerAccount()
    {   
        setupData();            
        ref.getParameters().put('caId', customerAccounts[0].Id);
        ref.getParameters().put('retUrl', customerAccounts[0].Id);
        Test.startTest();
            CACResponsibilityController controller = new CACResponsibilityController();
        Test.stopTest();
        System.assertEquals(customerAccounts[0].Id,controller.cacResponsibility.IME_SC_Customer_Account__c, 'The controller is populated with the customer account id');      
        System.assertEquals(new PageReference('/'+customerAccounts[0].Id).getUrl(),controller.returnPage.getUrl(), 'The page returns to the customer acoount page');
        System.assertEquals(null,controller.cacResponsibility.IME_SC_Contact__c, 'The contact is not populated when the customer account is populated on initial entry');               
    }
    
   static testMethod void Test_controllerInstantiation_contact()
    {   
        setupData();
        ref.getParameters().put('contactId', testContact.Id);
        ref.getParameters().put('retUrl', testContact.Id);  
        Test.startTest();
            CACResponsibilityController controller = new CACResponsibilityController();
        Test.stopTest();
        System.assertEquals(testContact.Id,controller.cacResponsibility.IME_SC_Contact__c, 'The controller is populated with the contact id');          
        System.assertEquals(new PageReference('/'+testContact.Id).getUrl(),controller.returnPage.getUrl(), 'The page returns to the contact page'); 
        System.assertEquals(null,controller.cacResponsibility.IME_SC_Customer_Account__c, 'The customer account is not populated when the contact is populated on initial entry');           
    
    }
    
    static testMethod void Test_valid_createMultiplecacResponsibilities()
    {   

        setupData();
        ref.getParameters().put('contactId', testContact.Id);
        ref.getParameters().put('retUrl', testContact.Id);  
        ref.getParameters().put('caId', customerAccounts[0].Id);
        CACResponsibilityController controller = new CACResponsibilityController();
        List<SelectOption> responsibililtyOptions = controller.responsibilityOptions;
        List<String> selections = new List<String>();
        for (SelectOption option: responsibililtyOptions){
            selections.add(option.getValue());
        }
        controller.selections = selections;
        Test.startTest();
            controller.save();
        Test.stopTest();
        List<IME_SC_CAc_Responsibility__c> responsibilities = [Select Id,IME_CAc_Responsibility__c,IME_SC_Customer_Account__c,IME_SC_Contact__c 
                                                                        from IME_SC_CAc_Responsibility__c
                                                                        where IME_SC_Contact__c = : testContact.Id 
                                                                        and IME_SC_Customer_Account__c = : customerAccounts[0].Id
                                                                    ];
        System.assertEquals(selections.size(),responsibilities.size(),'All the responsibility selections were saved');
        Set<String> responsibilitySet = new Set<String>();
        Set<String> selectionsSet = new Set<String>();
        selectionsSet.addAll(selections);
        for (IME_SC_CAc_Responsibility__c responsibility :responsibilities){
            System.assert(selectionsSet.contains(responsibility.IME_CAc_Responsibility__c),'  ');
            responsibilitySet.add(responsibility.IME_CAc_Responsibility__c);                        
        }
        System.assertEquals(selections.size(),responsibilitySet.size(),'All the selections were saved and each responsibility value is unique');

    }
    
    static testMethod void Test_invalid_duplicatecacResponsibilities_seperateContactsSingleAcccount()
    {   
        setupData();
        
        Schema.DescribeFieldResult F = IME_SC_CAc_Responsibility__c.IME_CAc_Responsibility__c.getDescribe();
                
        List<Schema.PicklistEntry> picker = F.getPicklistValues();
        cacResponsibility = TestingUtils.createCac( customerAccounts[0].id, picker[0].getValue(),testContact.id, true   );
        String otherContactResponsibility = picker[0].getValue();       
        
        ref.getParameters().put('contactId', testDuplicateContact.Id);
        ref.getParameters().put('retUrl', testDuplicateContact.Id); 
        ref.getParameters().put('caId', customerAccounts[0].Id);
        CACResponsibilityController controller = new CACResponsibilityController();
        controller.selections = new List<String>();
        controller.selections.add(otherContactResponsibility);
        
        Test.startTest();
            controller.save(); 
        Test.stopTest();
        List<IME_SC_CAc_Responsibility__c> responsibilities = new List<IME_SC_CAc_Responsibility__c>([Select Id,IME_CAc_Responsibility__c,IME_SC_Customer_Account__c,IME_SC_Contact__c 
                                                                        from IME_SC_CAc_Responsibility__c
                                                                        where IME_SC_Customer_Account__c = : customerAccounts[0].Id
                                                                    ]);
        System.assertEquals(1,responsibilities.size(),'Existing responsibility on another contact stops multiple entries with a duplicate responsiblity from being saved');
        System.assert((''+ApexPages.getMessages()[0]).contains(otherContactResponsibility),'The error message contains the responsibility name that was rejected' );
        System.assert((''+ApexPages.getMessages()[0]).contains(''+Label.ERRMSG_Contact_Responsibility_already_exists),'The error message indicates that the responsibility already exists' );

    }
    
    static testMethod void Test_valid_othercacResponsibility_seperateContactsSingleAcccount()
    {   
        setupData();
        
        Schema.DescribeFieldResult F = IME_SC_CAc_Responsibility__c.IME_CAc_Responsibility__c.getDescribe();
                
        List<Schema.PicklistEntry> picker = F.getPicklistValues();
        cacResponsibility = TestingUtils.createCac( customerAccounts[0].id, picker[0].getValue(),testContact.id, true   );
        String otherContactResponsibility = picker[1].getValue();       
        
        ref.getParameters().put('contactId', testDuplicateContact.Id);
        ref.getParameters().put('retUrl', testDuplicateContact.Id); 
        ref.getParameters().put('caId', customerAccounts[0].Id);
        CACResponsibilityController controller = new CACResponsibilityController();
        controller.selections = new List<String>();
        controller.selections.add(otherContactResponsibility);
        
        Test.startTest();
            controller.save(); 
        Test.stopTest();
        List<IME_SC_CAc_Responsibility__c> responsibilities = new List<IME_SC_CAc_Responsibility__c>([Select Id,IME_CAc_Responsibility__c,IME_SC_Customer_Account__c,IME_SC_Contact__c 
                                                                        from IME_SC_CAc_Responsibility__c
                                                                        where IME_SC_Customer_Account__c = : customerAccounts[0].Id
                                                                    ]);
        System.assertEquals(2,responsibilities.size(),'Different responsibilities exist for seperate contacts on the same account');
        System.assertNotEquals(responsibilities[0].IME_CAc_Responsibility__c,responsibilities[1].IME_CAc_Responsibility__c,'Different responsibilities exist on the same account' );
        System.assertNotEquals(responsibilities[0].IME_SC_Contact__c,responsibilities[1].IME_SC_Contact__c,'Responsibilities exist for seperate contacts on the same account' );

    }
    
    static testMethod void Test_valid_othercacResponsibilities_seperateContactsSingleAcccount()
    {   
        setupData();
        
        Schema.DescribeFieldResult F = IME_SC_CAc_Responsibility__c.IME_CAc_Responsibility__c.getDescribe();                
        List<Schema.PicklistEntry> picker = F.getPicklistValues();
        cacResponsibility = TestingUtils.createCac( customerAccounts[0].id, picker[0].getValue(),testContact.id, true   );
        List<String> otherContactResponsibilities = new List<String>();
        for (integer i=1;  i < picker.size();i++){
            otherContactResponsibilities.add(picker[i].getValue());     
        }
        ref.getParameters().put('contactId', testDuplicateContact.Id);
        ref.getParameters().put('retUrl', testDuplicateContact.Id); 
        ref.getParameters().put('caId', customerAccounts[0].Id);
        CACResponsibilityController controller = new CACResponsibilityController();
        controller.selections = new List<String>();
        controller.selections.addAll(otherContactResponsibilities);
        
        Test.startTest();
            controller.save(); 
        Test.stopTest();
        
        Set<String> insertedSelectionsSet = new Set<String>();
        List<IME_SC_CAc_Responsibility__c> responsibilities = new List<IME_SC_CAc_Responsibility__c>([Select Id,IME_CAc_Responsibility__c,IME_SC_Customer_Account__c,IME_SC_Contact__c 
                                                                        from IME_SC_CAc_Responsibility__c
                                                                        where IME_SC_Customer_Account__c = : customerAccounts[0].Id
                                                                    ]);
        System.assertEquals(picker.size(),responsibilities.size(),'All the possible responsibilities have been inserted on the same account');
        List<IME_SC_CAc_Responsibility__c> testContactResponsibilities = new List<IME_SC_CAc_Responsibility__c>([Select Id,IME_CAc_Responsibility__c,IME_SC_Customer_Account__c,IME_SC_Contact__c 
                                                                        from IME_SC_CAc_Responsibility__c
                                                                        where IME_SC_Customer_Account__c = : customerAccounts[0].Id
                                                                        and IME_SC_Contact__c = : testContact.id
                                                                    ]);
        System.assertEquals(1,testContactResponsibilities.size(),'One responsibilty was inserted for testContact' );
        insertedSelectionsSet.add(testContactResponsibilities[0].IME_CAc_Responsibility__c);
        List<IME_SC_CAc_Responsibility__c> testDuplicateContactResponsibilities = new List<IME_SC_CAc_Responsibility__c>([Select Id,IME_CAc_Responsibility__c,IME_SC_Customer_Account__c,IME_SC_Contact__c 
                                                                        from IME_SC_CAc_Responsibility__c
                                                                        where IME_SC_Customer_Account__c = : customerAccounts[0].Id
                                                                        and IME_SC_Contact__c = : testDuplicateContact.id
                                                                    ]);
        System.assertEquals(picker.size()-1,testDuplicateContactResponsibilities.size(),'All the other Responsibilities are inserted for testDuplicateContact' );
        for (IME_SC_CAc_Responsibility__c resp :testDuplicateContactResponsibilities){      
            insertedSelectionsSet.add(resp.IME_CAc_Responsibility__c);
        }
        System.assertEquals(picker.size(),insertedSelectionsSet.size(),'All the available responsibilities are inserted ' );
        
    }
}
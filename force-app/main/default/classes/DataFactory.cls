public with sharing class DataFactory
{
    static Integer offSet = 0;
    public String profileMethod(String pfrName)
    {
        Profile pfr = [Select id,Name from profile where name =: pfrName];
        return pfr.Name;
    }
    public static List<User> usrMethdLst(Integer howMany)
    {
        Profile pfr = [Select id from profile where name = 'IM_Custom Sys Admin' LIMIT 1];
        List<User> usrLst = new List<User>();
        for(Integer i = 0; i < howMany; i++)
        {
            offset++;
            User usr = new User();
                 usr.alias = 'standt'+offset;
                 usr.email='u1'+offset+'@im.com';
                 usr.emailencodingkey='UTF-8';
                 usr.firstname='Testing'+offset;
                 usr.lastname='Invalid_1'+offset;
                 usr.languagelocalekey='en_US';
                 usr.localesidkey='en_US';
                 usr.profileid = pfr.id;
                 usr.timezonesidkey='America/Los_Angeles';
                 usr.username='hello1.test1'+offset+'@testorg.com';
                 usr.Country = 'USA';
             usrLst.add(usr);
        }
        insert usrLst;

        return usrLst;
    }
    
    public static List<User> createUsers(Integer howMany)
    {
        Profile p = [Select id from profile where name = 'IME_Custom Sys Admin' LIMIT 1];
        List<User> allUsers = new List<User>();
        
        for(Integer i = 0; i < howMany; i++)
        {
            User us = new User();
             us.alias = 'ztest';
             us.email='test1@invalid.com';
             us.emailencodingkey='UTF-8';
             us.firstname='Test1';
             us.lastname='Invalid1';
             us.languagelocalekey='en_US';
             us.localesidkey='en_US';
             us.profileid = p.id;
             us.timezonesidkey='America/Los_Angeles';
             us.username='testinvalidnew@test.com';
             us.Country = 'United Kingdom';
          allUsers.add(us);
        }
         insert allUsers;

         return allUsers;
    }
    
    public static List<User> createUsersLst(Integer howMany)
    {
        Profile pfr = [Select id from profile where name = 'System Administrator' LIMIT 1];
        UserRole usrrolId = [Select Name, Id From UserRole where Name LIKE '%CSR' LIMIT 1];
        List<User> allUsersLst = new List<User>();
        
        for(Integer i = 0; i < howMany; i++)
        {
            offset++;
            User usr = new User();
             usr.alias = 'ztest1'+offset;
             usr.email='test2'+offset+'@invalid.com';
             usr.emailencodingkey='UTF-8';
             usr.firstname='Test2'+offset;
             usr.lastname='Invalid2'+offset;
             usr.languagelocalekey='en_US';
             usr.localesidkey='en_US';
             usr.profileid = pfr.id;
             usr.timezonesidkey='America/Los_Angeles';
             usr.username='testinvalidnew1'+offset+'@test.com';
             usr.Country = 'United Kingdom';
             usr.ManagerId = null;
             usr.UserRoleId = usrrolId.Id;
          allUsersLst.add(usr);
        }
         insert allUsersLst;

         return allUsersLst;
    }
    
    public static ID getRecordTypeId(String ObjectType, String RecordTypeLabel)
    { 
        Map<String,Schema.RecordTypeInfo> RecordTypeMap = new Map<String,Schema.RecordTypeInfo>();
        SObject OBJ;
        // Describing Schema
        Schema.SObjectType Res = Schema.getGlobalDescribe().get(ObjectType);
        if (Res != null)
        {
            OBJ = Res.newSObject();
            // Describing Object 
            Schema.DescribeSObjectResult DesRes = OBJ.getSObjectType().getDescribe(); 
            if (DesRes != null)
            {
                RecordTypeMap = DesRes.getRecordTypeInfosByName();
                system.debug('RecordTypeMap----'+RecordTypeMap);
                if (RecordTypeMap != null) 
                {    
                    system.debug('ifenteringintoloop----');
                    system.debug('RecordTypeLabel----'+RecordTypeLabel);
                    Schema.RecordTypeInfo RecordTypeRes = RecordTypeMap.get(RecordTypeLabel);
                    system.debug('RecordTypeMap.get(RecordTypeLabel)----'+RecordTypeMap.get(RecordTypeLabel));
                    system.debug('RecordTypeRes----'+RecordTypeRes);
                    if (RecordTypeRes != null) 
                    {
                       system.debug('ifenteringintoloop--1--');
                       return RecordTypeRes.getRecordTypeId();
                       system.debug('RecordTypeRes.getRecordTypeId()----'+RecordTypeRes.getRecordTypeId());
                    }
                }
             }
        }
        return null;
    }
    
    public List<String> recordTypeMethd(String objName, String recName)
    {
        List<String> recTypeStrlst = new List<String>();
        List<RecordType> recTypeLst = [Select Id, Name from RecordType Where sObjectType =: objName];
        for(RecordType rect : recTypeLst)
        {
            recTypeStrlst.add(rect.Id);
        }
        return recTypeStrlst;
    }
    
    public IM_Country__c imContMethd(String imContName)
    {
        IM_Country__c IMCont = new IM_Country__c ();
        IMCont.Name = 'India';
        
        insert IMCont;
        return IMCont;
    }

    public List<Account> acctMethd(Integer numOfAccounts, String accName)
    {
        List<Account> testAccounts = new List<Account>();
        for ( Integer i = 0; i < numOfAccounts; i++ )
        {
            Account testAccount = new Account();
            testAccount.Name = 'Test Account';
            testAccount.BillingCountry = 'United States';
            testAccount.BillingPostalCode = '11209';
            testAccount.BillingState = 'NY';
            testAccount.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
            testAccounts.add ( testAccount );
        }
        insert testAccounts;
        return testAccounts;
    }
    
     public Contact contMethd(Id accountId)
     {
        Contact testcontact = new Contact();
        testcontact.AccountId = accountId;
        testcontact.LastName = 'Cebedo';
        testcontact.Phone = '415-906-3801';
        
        insert testcontact;
        return testcontact;
     }
     
     public List<Contact> contLstMethd(Integer numOfContacts, String accName ,Id accountId)
     {
         List<Contact> conLst = new List<Contact>();
         for( Integer i = 0; i < numOfContacts; i++)
         {
             Contact testContact = new Contact();
             testcontact.AccountId = accountId;
             testcontact.LastName = 'Cebedo';
             testcontact.Phone = '415-906-3801';
             conLst.add(testcontact);
         }
         insert conLst;
         return conLst;
     }
     
     public Opportunity opptyMethd(String name, Id actId)
     {
         Opportunity testOpportunity = new Opportunity();
         
         testOpportunity.CloseDate = Date.today();
         testOpportunity.StageName='0 - Pre-Qualification';
         testOpportunity.AccountId = actId;
         testOpportunity.Lead_Source_Most_Recent__c = 'Email';
         testOpportunity.IME_Reason_Won__c = 'Price';
         testOpportunity.Name = (name == null)? 'testOpp' : name;
         
         Insert testOpportunity;
         return testOpportunity;
     }
     
     public List<Opportunity> opptyLstMethd(String name, Id actId,Integer numOfOpportunity)
     {
         List<Opportunity> opptyLst = new List<Opportunity>();
         for( Integer i = 0; i < numOfOpportunity; i++)
         {
             Opportunity oppty = new Opportunity();
             
             oppty.CloseDate = Date.today();
             oppty.StageName='0 - Pre-Qualification';
             oppty.AccountId = actId;
             oppty.Lead_Source_Most_Recent__c = 'Email';
             oppty.IME_Reason_Won__c = 'Price';
             oppty.Name = (name == null)? 'testOpp-'+i : name+'-'+i;
             opptyLst.add(oppty);
         }
         Insert opptyLst;
         return opptyLst;
     }
     
     public Product2 productMethd(String name)
     {
         Product2 prod = new Product2();
         prod.Name = 'Test';
         prod.IsActive = True;
         
         insert prod;
         return prod;
     }
     
     public List<Product2> productLstMethd(String name, Integer numOfProducts)
    {
        List<Product2> prodLst = new List<Product2>();
        for( Integer i = 0; i < numOfProducts; i++)
        {
            Product2 prod = new Product2();
            prod.Name = 'Test-'+i;
            prod.IsActive = True;
             
            prodLst.add(prod);
        }
        Insert prodLst;
        Return prodLst;
    }
     
    public Pricebook2 priceBookMethd(String pbName, Boolean doInsert)
    {
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Name = pbName;
         
        insert pricebook;
        return pricebook;
    }
     
    public List<Pricebook2> priceBookMethdLst(String pbname, Integer numOfPriceBoooks)
    {
        List<Pricebook2> prcbkLst = new List<Pricebook2>();
        for( Integer i = 0; i <numOfPriceBoooks; i++ )
        {
            Pricebook2 prcbk = new Pricebook2();
            prcbk.Name = pbName;
            
            prcbkLst.add(prcbk);
        }
        Insert prcbkLst;
        Return prcbkLst;
    }
    
    public IM_Customer_Account__c createCustomerAccountMethd(Id accountId)
    {
        Market__c testMarket = new Market__c( name= 'testMarket' );
        insert testMarket;
        
        IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
        custAcc.Name = 'Test';
        custAcc.Owning_District_Id__c = testMarket.Id;
        custAcc.Source_System__c = 'SB NA';
        custAcc.IM_Account__c = accountId;
        
        insert custAcc;
        return custAcc;
    }
    
    public Case createCaseMthd(Id caseRecordType, Contact testContact, Account testaccount, User testUser, IM_Customer_Account__c test)
    {
        Case newCase = new Case();
        newCase.OwnerId = testUser.Id;
        newCase.RecordTypeId = caseRecordType;
        newCase.AccountId = testaccount.id;
        newCase.Customer_ID__c = test.id;
        newCase.ContactId = testContact.id;
        newCase.Origin = 'Email';        
        newCase.Type = 'Billing';     
        newCase.Subject = 'Test';
        newCase.Description = 'Test';
        newCase.Priority = 'Normal';
        newCase.Status = 'New';
        newCase.Reason__c = 'Completed';
        newCase.Is_Cloned__c = false;
        newCase.Recurring_Case__c = false;
        newCase.SLA_Days__c =1;
        DateTime dtInitialTargetDate = DateTime.now();
        newCase.Initial_Due_Date__c = dtInitialTargetDate.date();
        newCase.SLA_Target_Date__c = dtInitialTargetDate;
        insert newCase;
        return newCase;
    }
    
}
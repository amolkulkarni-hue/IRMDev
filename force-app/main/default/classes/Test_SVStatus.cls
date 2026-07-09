@isTest(seeAllData=true)
   private class Test_SVStatus{
    static testMethod void updatefields()
    {
        Map<id,Opportunity> oldmap = new Map<id,Opportunity>();
        ID rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        Account a = new Account(name='Account4TestMethod'+system.now(), BillingCountry = 'United States', BillingState = 'MA');
        insert a;
        
        Product2 product = 
        new Product2(
        Secondary_Product_Allowed__c=true, 
        Name='test', 
        CurrencyIsoCode='GBP', 
        IsActive=true);
        insert product;
        
         Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true limit 1];       
       
                      
  PricebookEntry pbe = new PricebookEntry(
  Pricebook2Id = standardPB.Id, 
  Product2Id = product.Id, 
  UnitPrice = 1, 
  IsActive = true,
  CurrencyIsoCode='USD', 
  UseStandardPrice = false);
  
  insert pbe;  
        
        List<Contact> contacts = new List<Contact>();
        Contact c1 = new Contact(LastName='TestContact1',
                                 Email='testemail@email.com',
                                 AccountId=a.Id,
                                 MailingCity = 'London', 
                                 //MailingCountry = 'England', 
                                 MailingCountry = 'United States',
                                 MailingPostalCode = 'SE1 2TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contacts.add(c1);
        insert contacts;
        
         //insert SV custom setting
        SVStatus__c sv = new SVStatus__c();
            sv.name = 'SVStatusPassed1';
            sv.Amount__c = 0;
            sv.Stage__c = '2 - Solution Developed';
            sv.OpptType__c = 'Up-Sell/Lift,New Deal';
            insert sv;
            
        
        //insert Trigger Activation Setting
        Trigger_Activation_Settings__c TAS = new Trigger_Activation_Settings__c();
            TAS.Name = 'OpportunitySVStatus1';
            TAS.Object__c ='Opportunity';
            TAS.Trigger__c = 'OpportunitySVStatus1';
            TAS.Value__c = 'TRUE';
            insert TAS;
   
        list<Opportunity> opp1 = new list<Opportunity>();
        Opportunity op = new opportunity();
        op = new opportunity(
        AccountId = a.Id,
        StageName = '2 - Solution Developed',
        RecordTypeID=rt,
        CloseDate = Date.today(),
        Name = 'Opportunity4TestMethod4',
        IM_Booked_Date__c = Date.today(),
        Type = 'New Deal',      
        SV_Status__c ='Queued');   
        opp1.add(op);
        
        op = new opportunity(
        AccountId = a.Id,
        StageName = '3 - Solution Agreed',
        RecordTypeID=rt,
        CloseDate = Date.today(),
        Name = 'Opportunity4TestMethod4',
        IM_Booked_Date__c = Date.today(),
        Type = 'Renewal',      
        SV_Status__c = 'Queued',
        Opportunity_Total_Annual_Amount_Test__c= false,
        Upsell_Lift_Sales_Cycle_Length_Test__c = false);
        opp1.add(op);

        op = new opportunity(
        AccountId = a.Id,
        StageName = '3 - Solution Agreed',
        RecordTypeID=rt,
        CloseDate = Date.today(),
        Name = 'Opportunity4TestMethod4',
        IM_Booked_Date__c = Date.today(),
        Type = 'Up-Sell/Lift', 
        IM_Up_Sell_Quantity__c = 2,
        IM_Up_Sell_Detail__c = 'Test',
        IM_Up_Sell_Sold_To__c = 'ABC',
        IM_Unit_of_Measure__c = 'Destruction',
        IM_Servicing_Region__c = 'Aberdeen', 
        SV_Status__c = 'Queued',
        Pricebook2Id = pbe.Pricebook2Id,
        Opportunity_Total_Annual_Amount_Test__c= false,
        Upsell_Lift_Sales_Cycle_Length_Test__c = false);
        opp1.add(op);
        
        insert opp1;
        OpportunityLineItem oli = new OpportunityLineItem(
      //  PricebookEntryId= pricebooks[1].Id,
      PricebookEntryId= pbe.Id,
        OpportunityId=op.id,
        Quantity=1,
        TotalPrice=1
        );
        
        insert oli;
        
        
        op.Type = 'New Deal';
        op.RecordTypeID = rt;
        op.Opportunity_Total_Annual_Amount_Test__c= true;
        op.SV_Status__c = 'Passed';
        

        Test.startTest();

        update op;
        Test.stopTest();
        
        
           if(op.SV_Status__c == 'Queued' && op.Type == 'Up-Sell/Lift' )
           {
                op.Opportunity_Total_Annual_Amount_Test__c= false;
                op.Upsell_Lift_Sales_Cycle_Length_Test__c = false;          
           }
                      
           if(op.RecordTypeId == rt && op.SV_Status__c == 'Passed' && op.Type == 'Up-Sell/Lift'  )
           {
                op.SV_Status__c = 'Queued';
                op.Opportunity_Total_Annual_Amount_Test__c= false;
                op.Upsell_Lift_Sales_Cycle_Length_Test__c = false;
                
                
           }
           if(op.RecordTypeId == rt && op.Type == 'Renewal' )
             {
                op.SV_Status__c = ''; 
            }
            
           if(op.StageName == '6 - Setup')
            {
                op.SV_Status__c = 'Queued';
            }
        
        update op;
           }
   }
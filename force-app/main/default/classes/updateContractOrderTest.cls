@isTest 
public class updateContractOrderTest {
    
    public static Account testAccount;
    public static Opportunity testopp;
    public static Contract testContract;
    
    public static void setup() {
         List<Country_Settings__c> countrySetting = new List<Country_Settings__c>();
        Country_Settings__c cS = new Country_Settings__c();
        cS.Name = 'Canada';
        cS.Object_Name__c = 'Account';
        countrySetting.add(cS);
        
        Country_Settings__c cS1 = new Country_Settings__c();
        cS1.Name = 'United States';
        cS1.Object_Name__c = 'Account';
        countrySetting.add(cS1);
        
        insert countrySetting;
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = [Select id from IM_Country__c where Region__c='Europe' and Name ='United Kingdom'];
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom'; 
        
        insert altcountry;
        
        Account testAccount = new Account();
        testAccount.name='Test Account';
        testAccount.Billingcity='Test';
        testAccount.BillingCountry = 'United Kingdom';
       insert testAccount;
        
        /*Recordtype r=[select id from recordtype where name='IME Standard Opportunity'  limit 1];
        
        CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        testopp= new Opportunity(Name = 'Test Opportunity', Type='New Deal',AccountId = testAccount.Id, StageName = '1 - Qualification', CloseDate = Date.Today(), IM_Booked_Date__c = Date.Today(),recordtypeid=r.id,
                                Group_Purchasing_Organization_GPO__c='HealthTrust',IME_Vended_Unvended__c='Unknown',IM_Servicing_Region__c='London',Source_System__c='SKP NA');
        insert testopp;*/
              
             
        Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        
        Profile p = [Select id from profile where name = 'System administrator']; 
        
        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com',
                          emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = p.id,timezonesidkey='America/Los_Angeles',
                          username='userwithrole@testorg.com',Country = 'United Kingdom',ISACTIVE=true);
        insert u;
        
        
        
        IM_Customer_Account__c cusAcc = new IM_Customer_Account__c();
        cusAcc.Name = 'testSold';
        cusAcc.IM_Account__c = testAccount.id;
        cusAcc.Source_System__c = 'Other Europe';
        
        
        //Create the opportunity
        Opportunity testopp = new Opportunity(name = 'c', AccountId = testAccount.id, Source_System__c = 'SKP', Billing_Country__c = countryRec.id 
                                        ,Lead_Source_Most_Recent__c = 'x'
                                        //,StageName = '7 - Closed'
                                        ,StageName = '1 - Qualification'
                                        ,RecordTypeId = IMERecordTypeId
                                        ,IM_Servicing_Region__c ='London'
                                        ,IM_Commit_to_Forecast__c = true
                                        ,IM_Stage_5_Entered_Date__c  = System.today()
                                        ,IME_Reason_Won__c = 'Price'
                                        ,IMGA_Owner__c = u.id
                                        ,IM_Up_Sell_Sold_To__c = 'testSold'
                                        ,CloseDate = System.today()
                                        ,Type = 'Up-Sell/Lift'
                                        ,tsu__c=u.Id
                                        ,IM_Up_Sell_Detail__c = 'details'
                                        ,IM_Up_Sell_Quantity__c = 2
                                        ,Upsell_Customer_ID__c = cusAcc.id
                                        ,IM_Unit_of_Measure__c = 'Data Restoration' 
                                        ,SKP_Opportunity_Sync_Date__c = null
                                        ,US_Federal_GSA_Pricing__c ='Yes'
                                        ,Amount=1000.00
                                        ,GSA_Eligibility__c = 'GSA Eligible'
                                        ,IM_Booked_Date__c=System.today()+2
                                       );                                 
        insert testopp;
        testContract = new Contract();
        testContract.RecordTypeid = '01280000000UJX3';
        testContract.AccountId = testopp.AccountId;
        testContract.Billing_Country__c = testopp.Billing_Country__c;
        testContract.StartDate = testopp.Effective_Date__c;
        testContract.Contract_Type__c = 'IM Standard';
        testContract.IME_Contract_Version__c = 'IMUK-CC-14.01';
        testContract.IME_Contract_Term_Type__c = 'Evergreen';
        testContract.ContractTerm = 12;
        testContract.IM_Renewal_Term__c = 12;
        testContract.IME_Expiration_Notice_days__c = 90;
        testContract.IME_Liability_Currency__c = 'GBP';
        testContract.IM_Liability__c = 1;
        testContract.IM_Max_Liability__c = 1000000;
        testContract.IME_MFP_Clause__c = 'NO';
        testContract.IME_Non_Standard_Clause__c = 'NO';
        testContract.IME_Price_Increase_Type_Storage__c = 'Regular Increase';
        testContract.IME_Fixed_Pricing_Period_months_Storage__c = 12;
        testContract.IME_Price_Increase_Type_Services__c = 'Regular Increase';
        testContract.IME_Fixed_Pricing_Period_months_Services__c = 12;
        testContract.IME_Price_Increase_Type_Transport__c = 'Regular Increase';
        testContract.IME_Fixed_Pricing_Period_months_Transp__c = 12;
        testContract.IME_Price_Increase_Type_Product_Sales__c = 'Regular Increase';
        testContract.IME_Fixed_Pricing_Period_months_Prod_S__c = 12;
        testContract.Standard_Contract__c = True;
        testContract.IME_Records_Management_RM__c = true;
        insert testContract; 
    }
    
    static testmethod void updatetestContractractOrdertestmethod()
    {
        setup();
        Test.startTest();
                
        DocsignAttachAccessProfileSettings__c  docAccess = new DocsignAttachAccessProfileSettings__c();
        docAccess.name='IME_Custom Sys Admin';
        docAccess.Profile_Id__c= '00e80000001OOVlAAO';
        insert docAccess;
        
        Profile imeProfile = [Select Id, Name from Profile where Name =: 'IME_Contracts' limit 1];
        
        User u = new User(Alias = 'standt', Email='updateContractOrder@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = '00e80000001OOVlAAO',
                          TimeZoneSidKey='America/Los_Angeles', UserName='updateContractOrder@testorg.com', Country = 'United Kingdom');
        
        system.debug('objeUser=='+u);
        
            IME_Signature_Information__c sig = new IME_Signature_Information__c();
            sig.IME_Internal_Signatories__c = 'Default Signatory';
            sig.IME_Contract__c = testContract.id;
            sig.IME_Email_Subject__c = 'Iron Mountain testContractract to Sign';
            insert sig;  
        
        system.runAs(u)
        {
            
            Attachment attach=new Attachment();    
            attach.Name='contract Attachment';
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            attach.body=bodyBlob;
            attach.parentId=sig.id;
            insert attach; 
            
            updateContractOrder.updateContractFileOrder(sig.id);            
        }
        Test.stopTest();
    }
    
}
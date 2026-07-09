@isTest 
public class IME_Send_for_SignatureTest {
    public static Account testAccount;
    public static Account testAccount01;
    public static Contact testContact;
    public static Contact testContact01;
    public static Opportunity testOpp;
    public static Opportunity testOpp01;
    public static OpportunityContactRole opptContRole;
    public static OpportunityContactRole opptContRole01;
    public static Contract testContract;
    public static Contract testContract01;     
    public static IME_Signature_Information__c si;
    public static IME_Signature_Information__c si01;
    public static IME_Signatory_Contact__c sc;
    public static IME_Signatory_Contact__c sc01;
    public static Attachment AttachmentDoc;
    public static Attachment AttachmentDoc01;
        
    public static void setup()
    {   
       Profile prof = [select Id from profile where Name='System Administrator'];
       User u = new User(alias = 'standt', email='standarduser@testorg.com',
                          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/Los_Angeles', username='hello.test1@testorg.com', CurrencyIsoCode='USD');
        insert u;    
     	System.runAs(u){ 
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;
            
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United States');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
                      
        testAccount = new Account(name='Test Acct',Billing_County__c='United States',IMGA_Owner__c= u.id,
							           BillingCountry='United States');       
        insert testAccount;
        
        testContact= new Contact(LastName='TestContact1',
                                 FirstName='TestFirstName',
                                 Email='testemail@email.com',
                                 AccountId=testAccount.Id,
                                 MailingCity = 'Malden',                            
                                 MailingCountry ='United States',
                                 MailingPostalCode = '02148', 
                                 MailingState = 'MA',  
                                 MailingStreet = '745 Atlantic Ave');        
        insert testContact;       
        Recordtype r=[Select Id from recordtype where name='IME Standard Opportunity' and sObjectType = 'Opportunity' limit 1];
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
        
        Id standardPB = Test.getStandardPricebookId();
        
        testOpp= new Opportunity(Name = 'Test Opportunity',pricebook2ID= standardPB, Type='New Deal',AccountId = testAccount.Id, StageName = '1 - Qualification', IM_Booked_Date__c = System.today(), closedate = System.today(),recordtypeid=r.Id,
                                 Group_Purchasing_Organization_GPO__c='HealthTrust',IME_Vended_Unvended__c='Unknown',Contracting_Country__c='Netherlands',IM_Servicing_Region__c='London',Source_System__c='SKP NA',CurrencyIsoCode='GBP',Owner_Email__c='testOpp1@testOpp1.com',
                                 Initial_Period__c='12', Contract_Term__c='12',Billing_Country__c = testCountry.Id,
                                 Lead_Source_Most_Recent__c='Email',IME_Reason_Won__c = 'Benchmarking',IM_Commit_to_Forecast__c = true,IM_Stage_5_Entered_Date__c  = System.today() );
        insert testOpp; 
                        
        testContract = new Contract(AccountId =testAccount.Id,Billing_Country__c=testCountry.Id,ContractTerm=3,Status='Draft',
                                    StartDate=System.today(),IM_Contract_Category__c='MSA',
                                    Contract_Type__c='IM Standard',Standard_Contract__c = true);
        insert testContract;
                
        si = new IME_Signature_Information__c(Carbon_Copy_Signer__c = 'TBD',IME_Email_Message__c ='test',sent_for_signature__c = true,
                                              IME_Email_Subject__c='Test',IME_ExpireVoid__c=true,IME_ExpireNDays__c='10',IME_Internal_Signatories__c='Default Signatory',
                                              IME_EnableReminders__c=true,IME_ReminderRepeatDays__c	='3',IME_ReminderDays__c='3',IME_Signing_Order__c='IM signs first',
                                              Standard_Contract__c=true,IME_ExpireWarnNDays__c='4',IME_Contract__c=testContract.Id);
        insert si;
        
        sc = new IME_Signatory_Contact__c(IME_DocuSign_Contract_Envelope__c=si.Id,IME_Contact__c=testContact.Id,IME_Routing_Order__c=1);
        insert sc;        
    }
    }
  
    public static void setup00()
    {                
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];  
        User u = new User(alias = 'standt', email='standarduser@testorg.com',
                          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/Los_Angeles', username='hello.test1@testorg.com', CurrencyIsoCode='USD');
        insert u;
        System.runAs(u){
        IM_Country__c testCountry = new IM_Country__c(Name='United Kingdom');
        insert testCountry;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United Kingdom');
        insert country;
        
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United Kingdom';
        setting.object_name__c = 'Account';
        insert setting;
      
        testAccount01 = new Account(name='Test Acct',Billing_County__c='United Kingdom',IMGA_Owner__c= u.id,
						BillingCountry='United Kingdom', Account_Sub_Segment__c = 'Healthcare');
        insert testAccount01;
             
        testContact01= new Contact(LastName='TestContact1',
                                 FirstName='TestFirstName',
                                 Email='testemail@email.com',
                                 AccountId=testAccount01.Id,
                                 MailingCity = 'Malden', 
                                 MailingCountry ='United Kingdom',
                                 MailingPostalCode = '02148', 
                                 MailingState = 'MA',  
                                 MailingStreet = '745 Atlantic Ave');
        insert testContact01;
        
        Recordtype r=[Select Id from recordtype where name='IME Standard Opportunity' and sObjectType = 'Opportunity' limit 1];
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test', 
                CurrencyIsoCode='GBP', 
                IsActive=true);
        insert product;
        
        Id standardPB = Test.getStandardPricebookId();
        
        testOpp01= new Opportunity(Name = 'Test Opportunity',pricebook2ID= standardPB, Type='New Deal',
                                 AccountId = testAccount01.Id, StageName = '1 - Qualification', IM_Booked_Date__c = System.today(), closedate = System.today(),recordtypeid=r.Id,
                                 Group_Purchasing_Organization_GPO__c='HealthTrust',IME_Vended_Unvended__c='Unknown',Contracting_Country__c='Netherlands',IM_Servicing_Region__c='London',Source_System__c='SKP NA',CurrencyIsoCode='GBP',Owner_Email__c='testOpp1@testOpp1.com',
                                 Initial_Period__c='12',Contract_Term__c='12',Billing_Country__c = testCountry.Id,Lead_Source_Most_Recent__c='Email',IME_Reason_Won__c = 'Benchmarking',IM_Commit_to_Forecast__c = true,IM_Stage_5_Entered_Date__c  = System.today() );
        insert testOpp01;           
        
        testContract01 = new Contract(AccountId = testAccount01.Id,Billing_Country__c=testCountry.Id,ContractTerm=3,
                                      Status='Draft',
                                      StartDate=System.today(),IM_Contract_Category__c='MSA',
                                      Contract_Type__c='IM Non Standard',Standard_Contract__c = false);
        insert testContract01;
        
        si01 = new IME_Signature_Information__c(Carbon_Copy_Signer__c = 'TBD',IME_Email_Message__c ='test',
                                                IME_Email_Subject__c='Test',IME_ExpireVoid__c=true,IME_ExpireNDays__c='10',IME_Internal_Signatories__c='High Level Signatory',
                                                IME_EnableReminders__c=true,IME_ReminderRepeatDays__c	='3',IME_ReminderDays__c='3',IME_Signing_Order__c='Client signs first',
                                                Standard_Contract__c=true,IME_ExpireWarnNDays__c='4',IME_Contract__c=testContract01.Id);
        insert si01;
        
        sc01 = new IME_Signatory_Contact__c(IME_DocuSign_Contract_Envelope__c=si01.Id,IME_Contact__c= testContact01.Id,
                                            IME_Routing_Order__c=2);
        insert sc01;           
        }
    }
    
    static testmethod void TestSendForSignatureForSandbox() 
    {
        setup();
        
        PageReference result = Page.IME_Send_for_Signature;
        Test.setCurrentPage(result);
        result.getParameters().put('id',String.valueOf(si.Id));
        
        ApexPages.StandardController sc00 = new ApexPages.standardController(si);
        System.debug('Signature Information>>>>> '+si);
        IME_Send_for_Signature ime00 = new IME_Send_for_Signature(sc00);
        
        ime00.isSandbox = true;
        ime00.IME_Send_for_Signature();
        ime00.isValidReminder();
        ime00.isValidRecipient();
        ime00.isValidAttachment();
        ime00.validateCriteria();
        ime00.confirmSending();
        ime00.confirmAlert();
        ime00.cancel();        
    }
    
    static testmethod void TestSendForSignatureForProd() 
    {
        setup00();
        Test.startTest(); 
        PageReference result = Page.IME_Send_for_Signature;
        Test.setCurrentPage(result);
        result.getParameters().put('id',String.valueOf(si01.Id));
        
        ApexPages.StandardController sc01 = new ApexPages.standardController(si01);
        System.debug('Signature Information>>>>> '+si01);
        IME_Send_for_Signature ime = new IME_Send_for_Signature(sc01);
        
        ime.isSandbox = false;
        ime.IME_Send_for_Signature();
        ime.isValidReminder();
        ime.confirmSending();
        ime.isValidRecipient();
        ime.isValidAttachment();
        ime.validateCriteria();
        ime.confirmAlert();         
        
        Test.stopTest();
    }
    
    static testmethod void TestmforCancel()
    {
        setup();
        PageReference result = Page.IME_Send_for_Signature;
        Test.setCurrentPage(result);
        result.getParameters().put('id',String.valueOf(si.Id));
        result.setRedirect(true);
        
        ApexPages.StandardController scCancel = new ApexPages.standardController(si);
        IME_Send_for_Signature imeCancel = new IME_Send_for_Signature(scCancel);
        imeCancel.cancel();
    }
}
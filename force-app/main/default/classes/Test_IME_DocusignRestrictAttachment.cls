@isTest(seeAllData=true)
public class Test_IME_DocusignRestrictAttachment
{

  public static testmethod void dotest()
  {
  
   List<DocsignAttachAccessProfileSettings__c> customsettings = DocsignAttachAccessProfileSettings__c.getall().values();
   Profile p = [SELECT Id FROM Profile WHERE Name='IME_Custom Sys Admin'];
  
   User userToCreate = new User();
   
    userToCreate.FirstName='Bonface';
    userToCreate.LastName = 'Kambona';
    userToCreate.Email = 'bnfc+kmbna@gmail.com';
    userToCreate.Username = 'amby-xxxx@gmail.com';
    userToCreate.Alias = 'fatty';
    userToCreate.ProfileId = p.Id;
    userToCreate.Country='India';
    userToCreate.TimeZoneSidKey    = 'America/Denver';
    userToCreate.LocaleSidKey      = 'en_GB';
    userToCreate.EmailEncodingKey  = 'UTF-8';
    userToCreate.LanguageLocaleKey = 'en_GB';
    insert userToCreate;
  
  
  
      Account acc=new account();
      acc.Name='IBM BC&RS';
      acc.CurrencyIsoCode='EUR';
      acc.Division='02d8000000000kY';
      insert acc;
      
      contract con=new contract();
      con.AccountId=Acc.Id;
      con.Billing_Country__c='a0q800000011ojB';
      con.Status='Draft';
      con.IME_Contract_Term_Type__c = 'Fixed term';
      con.IM_Renewal_Term__c = 12;
      //con.StartDate= Date.ValueOf(1/1/2010);
      con.StartDate=date.today();
      con.ContractTerm=12;
      con.IM_Contract_Category__c='MSA';
      con.Contract_Type__c='Customer';
      con.IME_Records_Management_RM__c = true;
      insert con;
  
    System.RunAs(userToCreate)
    {
      IME_Signature_Information__c Sig= new IME_Signature_Information__c();
      
      sig.IME_Contract__c=con.id;
      sig.IME_Internal_Signatories__c = 'High Level Signatory';      
      insert Sig;
  
    
   
         Attachment attach=new Attachment();    
         attach.Name='Unit Test Attachment';
         Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
         attach.body=bodyBlob;
         attach.parentId=Sig.id;
         attach.OwnerId =userToCreate.id;
         insert attach;
        
         attach.Name='test';
         update attach;
        
        attach.Name='test';
        delete attach;
     }
 
   }
 }
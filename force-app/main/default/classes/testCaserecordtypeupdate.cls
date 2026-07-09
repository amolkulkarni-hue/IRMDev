@isTest
public class testCaserecordtypeupdate{
    
    static testmethod void testNASrecordtypeupdate(){
        
        List<Id> cid = new List<Id>();
        List<Profile> prof = [select id from profile where name LIKE '%NAS Support Agent%' ];
        
        User u = new User(Alias = 'unt', Email='test@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Test', 
        LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = prof[0].Id, 
        TimeZoneSidKey='America/New_York', Country='United States', UserName='nas@testorg.com');
        
        insert u;
        
        
         Id nasrectypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NAS General Support Case').getRecordTypeId();
         Id nascrectypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NAS Community Support Case').getRecordTypeId();
         
         System.runas(u){
             Case c= new Case();
             c.Recordtypeid=nascrectypeid;
             c.Type='Account Support';
             c.NAS_Root_cause_reason__c='BBB Complaint';
             
             insert c;
             cid.add(c.Id);
             
             
             CaseRecordtypeupdate.NASrecordtypeupdate(cid);
              
         }
    
    }
    
    static testmethod void testIMErecordtypeupdate(){
        
        List<Id> cid = new List<Id>();
        List<Profile> prof = [select id from profile where name LIKE '%IME_SC_Representative%'];
        
        User u = new User(Alias = 'unt1', Email='test@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Test', 
        LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = prof[0].Id, 
        TimeZoneSidKey='America/New_York', Country='United States', UserName='nas1@testorg.com');
        
        insert u;
               
        Id nasrectypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NAS General Support Case').getRecordTypeId();
        Id nascrectypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NAS Community Support Case').getRecordTypeId();
        System.runas(u){
            Case c= new Case();
            c.Recordtypeid=nascrectypeid;
            c.Type='Account Support';
            c.NAS_Root_cause_reason__c='BBB Complaint';
             
            insert c;
            cid.add(c.Id);
                     
            CaseRecordtypeupdate.NASrecordtypeupdate(cid);
            
      }
    
  }
    
	static testmethod void testIMErecordtypeupdateforIMLAProfiles(){
        
        List<Id> cid = new List<Id>();
        List<Profile> prof = [select id from profile where name LIKE '%IMLA_SC_Representative%'];
        
        User u = new User(Alias = 'unt1', Email='test@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', FirstName='Test', 
        LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = prof[0].Id, 
        TimeZoneSidKey='America/New_York', Country='United States', UserName='nas1@testorg.com');
        
        insert u;
               
        Id nasrectypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NAS General Support Case').getRecordTypeId();
        Id nascrectypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NAS Community Support Case').getRecordTypeId();
        System.runas(u){
            Case c= new Case();
            c.Recordtypeid=nascrectypeid;
            c.Type='Account Support';
            c.NAS_Root_cause_reason__c='BBB Complaint';
             
            insert c;
            cid.add(c.Id);
                     
            CaseRecordtypeupdate.NASrecordtypeupdate(cid);
            
      }
    
  }
    
    
}
/**
    Developer  : Sandhya Ramesh/IMS
    Date       : 05/15/2015
    Case       : 03704707
    Description: Test class for createWalkerCase trigger

	Developer  : Arun Rajendran / BCT
    Date       : 25 Apr 2019
    Case       : 09797722 (Qualtrics Integration Wave 1)
    Description: Test class for createQualtricsCase trigger
	
	Case       : 10060044 (Qualtrics Integration Wave 2)
	Date 	   : 30 Aug 2019
	Change	   : Added new method for NAS and handled new validation rules for both NAS and IME
    
**/
@isTest
public class Test_CreateQualtricsCase {

    //Commenting code as part of #24270
/*static testMethod void createNewCx(){
        Account acc= new Account(
            Name='Woolton Village', Division='02d8000000000kTAAQ'
        );
        insert acc;
        
        Contact con = new Contact(FirstName = 'Eleanor', LastName = 'Rigby', Email = 'eleanor@beatles.com', AccountId=acc.id, MailingCountry='Ireland');
    	Contact con1 = new Contact(FirstName = 'Arun', LastName = 'Rajendran', Email = 'arajendran@beatles.com', AccountId=acc.id, MailingCountry='Ireland');
        insert con;
    	insert con1;
    	
    	Market__c mkt = new Market__c(District_NAME__c	= 'woburn', Division_Name__c='Cramilton');
    	insert mkt;
    	IM_Customer_Account__c custAcc = new IM_Customer_Account__c(Name = 'New Customer Account', IM_Account__c = acc.id , Source_System__c ='SKP Europe',  Owning_District_Id__c = mkt.id);
        insert custAcc;
    
        CX_Survey_Details__c cx = new CX_Survey_Details__c(
             Program__c='Program', Contact__c=con.id, FollowUp_Reason__c='Bad Response', country__c = 'HUN', Source_Sys_Customer_ID__c = custAcc.id,
            Respondent_ID__c = 007008, SS_Template_ID__c = 008007, FollowUp_Type__c='Manual', To_Be_Contacted__c=true, Survey_Type__c ='Global Transactional Customer Care'
            
        );
    
    	
        insert cx;    	
    
    system.debug('CX Survey 1 --> ' + cx);
        
    }
    /*
     * Test method to create CX Survey record for testing NAS follow up case.
     * 
     */
  /* static testMethod void createNewNASCx(){
        Account acc= new Account(
            Name='Woolton Village', Division='02d8000000000kTAAQ'
        );
        insert acc;
        
        Contact con = new Contact(FirstName = 'Eleanor', LastName = 'Rigby', Email = 'eleanor@beatles.com', AccountId=acc.id, MailingCountry='Ireland');
    	Contact con1 = new Contact(FirstName = 'Arun', LastName = 'Rajendran', Email = 'arajendran@beatles.com', AccountId=acc.id, MailingCountry='Ireland');
        insert con;
    	insert con1;
    	
    	Market__c mkt = new Market__c(District_NAME__c	= 'woburn', Division_Name__c='Cramilton');
    	insert mkt;
    	IM_Customer_Account__c custAcc = new IM_Customer_Account__c(Name = 'New Customer Account', IM_Account__c = acc.id , Source_System__c ='SKP Europe',  Owning_District_Id__c = mkt.id);
        insert custAcc;
      	
      	
      Map<String, Schema.RecordTypeInfo> caseRecordTypeIdMap = IRM_SC_SelectRecordType.getRecordType();
	  Id imeCaseRecordTypeID = caseRecordTypeIdMap.get('NAS General Support Case').getRecordTypeId();
      
      Case caseRec1 = new Case(RecordTypeId = imeCaseRecordTypeID, ContactId = con1.id, Status = 'New', NAS_Service_market__c = 'Boston', NAS_Service_Line_Associated_to_Ask__c = 'Data Management' );
    	insert caseRec1;
        CX_Survey_Details__c cx = new CX_Survey_Details__c(
             Program__c='Program', Contact__c=con.id, FollowUp_Reason__c='Bad Response', country__c = 'USA', Source_Sys_Customer_ID__c = custAcc.id,Original_Case_Number__c = caseRec1.id,
            Respondent_ID__c = 007008, SS_Template_ID__c = 008007, FollowUp_Type__c='Manual', To_Be_Contacted__c=true, Survey_Type__c ='Global Transactional Customer Care'
            
        );
    
    	
        insert cx;
    
    	
    
    system.debug('CX Survey 1 --> ' + cx);
        
    } */
  
 }
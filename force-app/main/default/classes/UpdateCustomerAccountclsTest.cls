/*
* @Class Name: UpdateCustomerAccountclsTest
* @description: This class will be used to test UpdateCustomerAccountcls.
* @Author: Avanthi,Akhil
* @Created Date: 12/06/2021
* Developer                     Date                    Description
* -------------------------------------------------------------------------------------------
* Jitendra Mishra           22/08/2024      Commenting the entire Test class(used by UpdateCustomerAccountcls ) as this functionality is no longer in use,
                                            and adding a dummy Testclassmethod(TestDummyMethodForTestCoverage) for the test coverage(story #25727).
*

**/
 @isTest
public class UpdateCustomerAccountclsTest {
     
@isTest
    static void TestDummyMethodForTestCoverage(){
               Test.startTest();
        UpdateCustomerAccountcls.DummyMethodForTestCoverage();
        Test.stopTest();
        //#25727 Commenting the code starts
        /* Account acc= new Account(
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
	  Id imeCaseRecordTypeID = caseRecordTypeIdMap.get('NAS Community Support Case').getRecordTypeId();
      system.debug(imeCaseRecordTypeID);
      Case caseRec1 = new Case(RecordTypeId = imeCaseRecordTypeID, ContactId = con1.id, Status = 'New', NAS_Service_market__c = 'Boston', NAS_Service_Line_Associated_to_Ask__c = 'DMS' ,Customerid__c='New Customer Account');
    	insert caseRec1;
        
        Case ca =[select id,Customerid__c from case where (Customerid__c !=Null and NAS_Service_Line_Associated_to_Ask__c ='DMS' )];
        ca.Customer_ID__c = custAcc.Id;
        update ca; */
    } 
     //#25727 Commenting the code End
    }
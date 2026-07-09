@isTest
public class TestRequestIntakeForm {
    
    static testMethod void testRequestForm1()
    {       
        Corporate_Request__c req1 = new Corporate_Request__c (Name = 'Corporate Request 1');
        insert req1;
        
        ApexPages.StandardController sc = new ApexPages.standardController(req1);
        requestIntakeForm cls = new requestIntakeForm(sc);
        cls.getRequestsOptions();
        cls.setRecordType();
        cls.saveAndSuccess();
    }
    
    static testMethod void testRequestForm2()
    {       
        Corporate_Request__c req1 = new Corporate_Request__c (Name = 'Corporate Request 1');
        insert req1;        
        ApexPages.StandardController sc = new ApexPages.standardController(req1);
        requestIntakeForm cls = new requestIntakeForm(sc);
        
        String[] recTypes = new String[]{'Corp', 'Customer', 'Employment', 'General', 'Intellectual','Litigation','Tuck','Privacy', 'Real Estate','Vendor'};            
            for (String rec : recTypes) 
        {            
            cls.requestTypes=rec;
            cls.setRecordType();
        }
        
    }
    
    static testMethod void testRequestSuccess1()
    {        
        Corporate_Request__c req1 = new Corporate_Request__c (Name = 'Corporate Request 1');
        insert req1;
        
        Test.StartTest();
        
        ApexPages.StandardController sc = new ApexPages.standardController(req1);      
        PageReference pageRef = Page.requestIntakeSuccess;
        pageRef.getParameters().put('id', String.valueOf(req1.Id));
        Test.setCurrentPage(pageRef);
        requestAttachmentUpload cls = new requestAttachmentUpload(sc);        
        cls.upload();
        
        Test.stopTest();
    }
    
}
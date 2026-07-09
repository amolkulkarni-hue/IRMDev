/************************
Developer Name: Madhu Paladugu
Case Number   : 01814315
Date          : 10/8/13
purpose       : Test Utility for IRM_SC_fetchUpdateQueue class.
***********************/
@isTest(seeAllData=true)
public class Test_IRM_SC_fetchUpdateQueue{
    
    static testMethod void doTest(){
       
        //Creation of IM Country record
        IM_Country__c country = new IM_Country__c(Name = 'Australia');
        insert country;
        
        //Creation of Account
        Account testAccount = new Account(Name='Test Account', BillingCountry = 'Australia');
        insert testAccount;
        
        
        //Creation of Customer Account
        IM_Customer_Account__c caseCustomerAccount1 = new IM_Customer_Account__c(Name = '123', IM_Account_Manager__c = userInfo.getUserId(), 
                                                     Billing_Country__c = country.Id, IM_Account__c = testAccount.id);
        
        insert caseCustomerAccount1 ;
        
        Group queue = [Select g.Name, g.Id From Group g where Name Like 'IME SC %queue%' LIMIT 1];
        
        system.debug('Queue: '+queue);
        
        RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
              
        //insert Case
        Case newCase = new Case();
        newCase.Origin = 'AUS_EMAIL_NSW';
        newCase.RecordTypeId = caseRecordType.id;
        newCase.IME_SC_Category__c= 'Order Enquiry';
        newCase.IME_SC_Sub_Category__c = 'Change an order';
        newCase.IME_SC_Request_Type__c = 'Order';
        newCase.IME_SC_Number_of_Line_Items__c = 1;
        newCase.IME_SC_Customer_AccountId__c = caseCustomerAccount1.id;
        newCase.IME_SC_Country__c='Australia';
        if(queue!=null)
        newcase.ownerid=queue.id;
        insert newCase;
        
        List<Case> updateCase=new List<case>();
        
        Map<id,case> oldcaseMap=new Map<Id,case>();
        oldcaseMap.put(newcase.id,newcase);
        
        newcase.ownerId=userinfo.getUserId();
        update newcase;
        updateCase.add(newcase);
        
        IRM_SC_fetchUpdateQueue instance=new IRM_SC_fetchUpdateQueue ();
        instance.UpdateQueueName(updateCase,oldcaseMap,true);
        
        
        
        
        
    }
}
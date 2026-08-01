/**
    Developer  : Sandhya Ramesh/IMS
    Date       : 05/15/2015
    Case       : 03704707
    Description: Test class for createWalkerCase trigger
    
**/

@isTest

public class Test_CreateWalkerCase{

    static testMethod void createNewCx(){
        Account acc= new Account(
            Name='Woolton Village', Division='02d8000000000kTAAQ'
        );
        insert acc;
        
        Contact con = new Contact(
            FirstName = 'Eleanor', LastName = 'Rigby', Email = 'eleanor@beatles.com', AccountId=acc.id, MailingCountry='Ireland'
        
        );
        insert con;
        
        CX_Survey_Details__c cx = new CX_Survey_Details__c(
            Program__c='Program', Contact__c=con.id, FollowUp_Reason__c='Bad Response',
            Respondent_ID__c = 007008, SS_Template_ID__c = 008007, Survey_Type__c='Relationship', FollowUp_Type__c='Manual'

        );
        insert cx;
        
    }

}
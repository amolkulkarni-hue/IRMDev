/*****************************************************************************************************
* Class: QTB_ChageUsageRating_Test
* Author: Accenture
* Purpose: This is a test class for QTB_ChageUsageRating
* Change History: 7/23/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   
*******************************************************************************************************/
@isTest(seealldata=false)
public with sharing class QTB_ChageUsageRating_Test {
    
    static testmethod void test1(){
         List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        Test.startTest();
        system.runas(userList[0]) { 
        blng__BillingConfig__c config = new blng__BillingConfig__c();
        config.name = 'USAGE_RATING_PROCESS';
        insert config;
        List<String> strings = new List<string>{'By Process'};
        QTB_ChangeUsageRating usageRating = new QTB_ChangeUsageRating();
        QTB_ChangeUsageRating.changeUsageRating(strings);
        Test.stopTest();
        system.assertEquals('USAGE_RATING_PROCESS',config.name);
        }
        
    }
    

}
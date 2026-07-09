/*****************************************************************************************************
* Class: QTB_ScheduleUsageRating_Test
* Author: Accenture
* Purpose: This is a test class for QTB_ScheduleUsageRating
* Change History: 7/23/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   
*******************************************************************************************************/
@isTest(seealldata=false)
public with sharing class QTB_ScheduleUsageRating_Test {
    
    static testMethod void test1(){
       		 List<User> userList = QTB_TestDataFactory.usrMethdLst(1); 
        	Test.startTest();
         	system.runas(userList[0]) { 
       		blng__BillingConfig__c config = new blng__BillingConfig__c();
        	config.name = 'USAGE_RATING_PROCESS';
       		insert config;
        	List<integer> integers = new List<integer>{1,2,3};
            QTB_ScheduleUsageRating scheduleRate = new QTB_ScheduleUsageRating();
        	QTB_ScheduleUsageRating.scheduleUsageRating(integers);
        	Test.stopTest();
        	system.assertEquals('USAGE_RATING_PROCESS',config.name);
         }
    }

}
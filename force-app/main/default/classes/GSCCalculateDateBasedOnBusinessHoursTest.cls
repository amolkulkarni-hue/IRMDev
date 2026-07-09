/********************************************************************************************************
* @Description: This Apex Class is test class for the class "GSCCalculateDateBasedOnBusinessHours"
* @Copyright: Iron Mountain
* @Author: Simranjit Kaur
* @Created on:  04/19/2024(MM/DD/YYYY)
* @MainClass Name: GSCCalculateDateBasedOnBusinessHours
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 04/19/2024 - Simranjit Kaur - Initial Development - GitLab #22253
* ===================================================
*
********************************************************************************************************/
@isTest
public class GSCCalculateDateBasedOnBusinessHoursTest {
    @isTest static void test_method_default(){
		//Creating Test Data
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault =:true]; 
        // Perform test
        Test.startTest();
      	Datetime nextDay = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh.id, 3);
        System.debug('The Next Date'+ nextDay);
        Test.stopTest();
    }
    @isTest static void test_method(){
		//Creating Test Data
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name =: 'BH_IND' LIMIT 1]; 
        // Perform test
        Test.startTest();
      	Datetime nextDay = GSCCalculateDateBasedOnBusinessHours.calculateFollowUpDateMethod(bh.id, 7);
        System.debug('The Next Date'+ nextDay);
        Test.stopTest();
    }
}
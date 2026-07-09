/*
* @Class Name: PayMyBillPopupControllerTest
* @description: This class will be used as A test class for PayMyBillPopupController.
* @Author: Piyush Yadav
* @Created Date: 23/09/2021
* @Ticket: #5420
**/
@isTest
public with sharing class PayMyBillPopupControllerTest {
    /********************************
    * @Method:   public static Boolean getUrlBasedOnLocationTest()
    * @description: Method to test getUrlBasedOnLocation
    * @Author: Piyush Yadav.
    * *****************************/
    @isTest
    static void getUrlBasedOnLocationTest(){
        Test.startTest();
        List<PayMyBillPopupController.URLWrapper> flag = PayMyBillPopupController.getUrlBasedOnLocation();
        Test.stopTest();
        system.assertNotEquals(flag, null);
    }
}
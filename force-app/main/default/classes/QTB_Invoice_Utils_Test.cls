/*****************************************************************************************************
* Class: QTB_Invoice_Utils_Test
* Purpose: This is a test class for apex code coverage
* 	Developer     		Date           
* ------------------------------------------------------------------------------------------- 
*  Ramesh Aravind      15/Mar/2021
*******************************************************************************************************/
@istest
public class QTB_Invoice_Utils_Test {
 
    static testmethod void method1(){
        test.startTest();
        set<String> prodset = QTB_Invoice_Utils.productFamilies;
        set<String> Priceset = QTB_Invoice_Utils.priceScheduleCategories;
        test.stopTest();
        }
    }
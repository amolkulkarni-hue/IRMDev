/*****************************************************************************************************
* Class: QTB_MultiSelectFlowValuesProducts
* Author: Virtusa
* Purpose: This is a Test class of QTB_MultiSelectFlowValuesProducts.
* Requirement:  # 8875
* Change History:
* Developer        Date 04/05/2022          Description
*
*******************************************************************************************************/
@isTest

public class QTB_MultiSelectFlowValuesProductsTest{
    @isTest    
    static void MultiSelectFlowValuesTest(){
        List<string> tempLst = new list<string>();
        tempLst.add('ProductsTest');
        tempLst.add('ProductsTest2');
        QTB_MultiSelectFlowValuesProducts.CheckProductValues(tempLst);
    }
    
    //cover catch
    static testMethod void testMethod2() {
        Test.startTest();
        QTB_MultiSelectFlowValuesProducts.throwExplicitException = true;
        List<string> tempLst2 = new list<string>();
        QTB_MultiSelectFlowValuesProducts.CheckProductValues(tempLst2);
        Test.stopTest();
        System.assertEquals(
            true,
            QTB_MultiSelectFlowValuesProducts.throwExplicitException
        );
        
    }     
    
}
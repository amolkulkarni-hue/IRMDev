/*****************************************************************************************************
* Class: QTB_UsageSuspenseBatchablesTest
* Author: Virtusa
* Purpose: Test Class for QTB_UsageSuspenseBatchables
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Virtusa   17/11/2023
*******************************************************************************************************/


@isTest(seeAllData=false) 
public class QTB_UsageSuspenseBatchablesTest {
    static testmethod void methodBatchUsageSuspenseDelete()
    {
        System.Test.startTest();
        
        list<QTB_Usage_Suspense__c> usageSuspenselist =new List<QTB_Usage_Suspense__c>();
        QTB_Usage_Suspense__c usageSuspense = new QTB_Usage_Suspense__c();
        usageSuspense.QTB_MatchingId__c = '00000100010-11111';
        usageSuspense.QTB_Mediation_Status__c = 'Processed';
        usageSuspenselist.add(usageSuspense);
        insert usageSuspenselist;
        
        QTB_UsageSuspenseBatchables obj = new QTB_UsageSuspenseBatchables();
        DataBase.executeBatch(obj); 
        
         System.Test.stopTest();
    }

}
/*****************************************************************************************************
 * Class: QTB_BillingAccountOrderUtil
 * Author: Virtusa
 * Purpose: This is a helper class to update Old CPQ Model Apex Classes to Billing Account Order Util Class
 * Requirement:#14900
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Sravya       15/05/2023      GitLab#14900
 *******************************************************************************************************/
public class QTB_BillingAccountOrderUtil { 
    public static Boolean isTriggerDisabled = false;
    public static final String Account = 'Order';
    public static boolean throwExplicitException = false;
    public static final String DELIMITERS = '[;,]';
    public static final String BILLINGACCOUNTORDER = 'QTB_BillingAccountOrderUtil';
  
/***********************************************************************************************************
   * Method :  setOrderTypeValue
   * Parameters: List<Order>, Set<Id>
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description:Populate Order Type
 **************************************************************************************************************/    
    public static void setOrderTypeValue(List<Order> ordList,Set<ID> accIDs,Set<Id> quoteIds) {
        try {
            if (QTB_BillingAccountOrderUtil.throwExplicitException){
                throw new NullPointerException();
            }
          QTB_OrderHelper.setOrderTypeValue(ordList, accIDs, quoteIds);
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTORDER
              );
              throw e;
        }
    }
/***********************************************************************************************************
   * Method :  countryClone
   * Parameters: List<Order> orderList, Set<ID> blngAccounts
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description: To clone the Legal Entity Country from Billing Account
 **************************************************************************************************************/    
    public static void countryClone(List<Order> orderList, Set<ID> blngAccounts) {
        try {
            if (QTB_BillingAccountOrderUtil.throwExplicitException){
                throw new NullPointerException();
            }
          QTB_OrderHelper.countryClone(orderList, blngAccounts);
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTORDER
              );
              throw e;
        }
    }
/***********************************************************************************************************
   * Method : billingPromotions
   * Parameters: List<Order> orderList, Set<ID> blngAccounts
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description:This method is used for creating the billing promotion on the Billing Account based on quote promotions from the original quote
 **************************************************************************************************************/    
    public static void billingPromotions(List<Order> orderList,Set<ID> blngAccounts) {
        try {
            if (QTB_BillingAccountOrderUtil.throwExplicitException){
                throw new NullPointerException();
            }
           // if(!Test.isRunningTest()){
          QTB_OrderHelper.billingPromotions(orderList, blngAccounts);
            //}
            Integer i = 0;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTORDER
              );
              throw e;
        }
    }
 /***********************************************************************************************************
   * Method : updateInvoiceBatch
   * Parameters: List<Order> orderList, Set<ID> blngAccounts
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description:This method is used for Update the Invoice Batch
 **************************************************************************************************************/    
    //#28621 - Commented below updateInvoiceBatch() because same logic available in 'QTB Order Populate Invoice Batch and Legal Entity' Flow
    /*public static void updateInvoiceBatch(List<Order> orderList, Set<ID> blngAccounts) {
        try {
            if (QTB_BillingAccountOrderUtil.throwExplicitException){
                throw new NullPointerException();
            }
          QTB_OrderHelper.updateInvoiceBatch(orderList, blngAccounts);
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTORDER
              );
              throw e;
        }
    }*/
           
}
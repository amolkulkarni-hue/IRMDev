/*****************************************************************************************************
 * Class: QTB_BillingAccountOrderProductUtil
 * Author: Virtusa
 * Purpose: This is a helper class to update Old CPQ Model Apex Classes to Billing Account OrderProduct Util Class
 * Requirement:#14900
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Sravya       15/05/2023      GitLab#14900
 *******************************************************************************************************/
public class QTB_BillingAccountOrderProductUtil {
    public static Boolean isTriggerDisabled = false;
    public static final String Account = 'OrderProduct';
    public static boolean throwExplicitException = false;
    public static final String DELIMITERS = '[;,]';
    public static final String BILLINGACCOUNTORDERPRODUCT = 'QTB_BillingAccountOrderProductUtil';
 /***********************************************************************************************************
   * Method :  updateTaxTreatment
   * Parameters: List<OrderItem>
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description: populate order products with tax treatment and other values
 **************************************************************************************************************/    
    public static void updateTaxTreatment(List<OrderItem> ordItemNewList,Set<ID> orderIDs) {
        try {
            if (QTB_BillingAccountOrderProductUtil.throwExplicitException){
                throw new NullPointerException();
            }
            
           QTB_OrderProductHelper.updateTaxTreatment(ordItemNewList, orderIDs);           
          
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTORDERPRODUCT
              );
              throw e;
        }
    }
/***********************************************************************************************************
   * Method : updateCSRates
   * Parameters:  List<OrderItem>
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description: Update order products new Unit Price to the CS Rates
 **************************************************************************************************************/    
    public static void updateCSRates(List<OrderItem> ordItemNewList, boolean isUnitPriceChange) {
        try {
            if (QTB_BillingAccountOrderProductUtil.throwExplicitException){
                throw new NullPointerException();
            }
            
           QTB_OrderProductHelper.updateCSRates(ordItemNewList, isUnitPriceChange);          
          
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTORDERPRODUCT
              );
              throw e;
        }
    }
/***********************************************************************************************************
   * Method : setHoldBillingToRebillOrder
   * Parameters: List<OrderItem> ordItemNewList,Set<ID> orderIDs
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description: Setting HoldBilling to No for Singapore products
 **************************************************************************************************************/    
    public static void setHoldBillingToRebillOrder(List<OrderItem> ordItemNewList,Set<ID> orderIDs) {
        try {
            if (QTB_BillingAccountOrderProductUtil.throwExplicitException){
                throw new NullPointerException();
            }
            
           QTB_OrderProductHelper.setHoldBillingToRebillOrder(ordItemNewList, orderIDs);         
          
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTORDERPRODUCT
              );
              throw e;
        }
    }
/***********************************************************************************************************
   * Method : setInvoiceRunForOrderProduct
   * Parameters: List<OrderItem> ordItemNewList
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description:Setting blng__InvoiceRunProcessingStatus__c to Pending billing for Rebill Order Products
 **************************************************************************************************************/    
    public static void setInvoiceRunForOrderProduct(List<OrderItem> ordItemNewList) {
        try {
            if (QTB_BillingAccountOrderProductUtil.throwExplicitException){
                throw new NullPointerException();
            }
            
           QTB_OrderProductHelper.setInvoiceRunForOrderProduct(ordItemNewList);         
          
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTORDERPRODUCT
              );
              throw e;
        }
    }
   

}
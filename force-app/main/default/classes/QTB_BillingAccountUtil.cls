/*****************************************************************************************************
 * Class: QTB_BillingAccountUtil
 * Author: Virtusa
 * Purpose: This is a helper class to update Old CPQ Model Apex Classes to Billing Account Util Class
 * Requirement:#14900
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Sravya       15/05/2023      GitLab#14900
 *******************************************************************************************************/
public class QTB_BillingAccountUtil {
    
    public static Boolean isTriggerDisabled = false;
    public static final String Account = 'Account';
    public static boolean throwExplicitException = false;
    public static final String DELIMITERS = '[;,]';
    public static final String BILLINGACCOUNTUTIL = 'QTB_BillingAccountUtil';


/***********************************************************************************************************
   * Method : updateBillingAccountName
   * Parameters: List<Account>,Map<Id,Account>
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description: Method to add a Prefix to Billing Account Names and make the Name field Read Only once created
   *              and clone Standard Name to Billing Account Invoice Name field
   **************************************************************************************************************/    
 public static void updateBillingAccountName(List<Account> accNewList, Map<Id, Account> oldAccountMap) {
        try {
            if (QTB_BillingAccountUtil.throwExplicitException) {
                throw new NullPointerException();
            }
            
           QTB_AccountHelper.updateBillingAccountName(accNewList,oldAccountMap);
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTUTIL
              );
              throw e;
        }
    }
 /***********************************************************************************************************
   * Method : GenerateEvergreenRecords
   * Parameters: List<Account>,Map<Id,Account>,String
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa 
   * Description:Generate billing records on billing account creation or association
   * Event: this method invoked on after insert and after update events from Account Trigger
   **************************************************************************************************************/ 
  public static void GenerateEvergreenRecords(List<Account> newAccList,Map<Id, Account> oldAccountMap,String evntStr){
        try {
            if (QTB_BillingAccountUtil.throwExplicitException) {
                throw new NullPointerException();
            }
            
            QTB_AccountHelper.GenerateEvergreenRecords(newAccList,oldAccountMap,evntStr);
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTUTIL
              );
              throw e;
        }
    }
 /***********************************************************************************************************
   * Method : validateMandatoryAccountFields
   * Parameters: List<Account>
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description:This method used for validate Account address mandatory and Non Mandatory fields on Billing Account.
   **************************************************************************************************************/ 
  public static void validateMandatoryAccountFields(List<Account> accsNewList) {
        try {
            if (QTB_BillingAccountUtil.throwExplicitException) {
                throw new NullPointerException();
            }
            
            QTB_AccountHelper.validateMandatoryAccountFields(accsNewList);
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTUTIL
              );
              throw e;
        }
    }
 /***********************************************************************************************************
   * Method : validateIndianStateValue
   * Parameters: List<Account> 
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author :  Virtusa
   * Description:This method is used for validate the values of billing and shipping states of India, when the
                  legal entity and billing country are both India
 **************************************************************************************************************/    
    public static void validateIndianStateValue(List<Account> accsNewList) {
        try {
            if (QTB_BillingAccountUtil.throwExplicitException) {
                throw new NullPointerException();
            }
            
            //QTB_AccountHelper.validateIndianStateValue(accsNewList);
           } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTUTIL
              );
              throw e;
        }
    }
 /***********************************************************************************************************
   * Method : createSalesBillingAccountRelations
   * Parameters: List<FlowInputs>
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description:create Sales Billing Account Relationship record when a billing account is created
 **************************************************************************************************************/ 
    public static void createSalesBillingAccountRelations(Map<Id, Id> mapOfBillingAccountToSalesOpportunityId) {
        try {
            if (QTB_BillingAccountUtil.throwExplicitException) {
                throw new NullPointerException();
            }
            
            QTB_AccountHelper.createSalesBillingAccountRelations(mapOfBillingAccountToSalesOpportunityId);
            } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTUTIL
              );
              throw e;
        }
    }


/***********************************************************************************************************
   * Method : billingOraclePlatformEvent
   * Parameters: List<Account>
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description:Publish Platform Event on billing account creation or association
   * Event: this method invoked on after insert and after update events from AccountContactRelation Trigger
 **************************************************************************************************************/ 
    public static void billingOraclePlatformEvent(Set<Id> sourceIdSet) {
        try {
            if (QTB_BillingAccountUtil.throwExplicitException) {
                throw new NullPointerException();
            }
            
            QTB_AccountContactRelationHelper.billingOraclePlatformEvent(sourceIdSet);
            } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTUTIL
              );
              throw e;
        }
    }

 /***********************************************************************************************************
   * Method : primaryContactInsertion
   * Parameters:List<AccountContactRelation>, map<ID,AccountContactRelation>
   * Requirement : #14900
   * Start Date : 15/05/2023 
   * Author : Virtusa
   * Description: Function to check the status of primary field on a Contact
   * Event: this method invoked on before insert events from AccountContactRelation Trigger
 **************************************************************************************************************/ 
    public static void primaryContactInsertion(Set<Id> accIDSet2,set<Id> contactidset,List<AccountContactRelation> accNewList) {
        try {
            if (QTB_BillingAccountUtil.throwExplicitException) {
                throw new NullPointerException();
            }
            
            QTB_AccountContactRelationHelper.primaryContactInsertion(accIDSet2, contactidset, accNewList);
            } Catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                BILLINGACCOUNTUTIL
              );
              throw e;
        }
    }
}
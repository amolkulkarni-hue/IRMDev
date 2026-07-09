/*****************************************************************************************************
* Class: QTB_QueueableAccountUpdate 
* Author: Accenture
* Purpose: This is a Queueable class to call batch apex to modify large no of order products.
* Requirement: SFCPQBLG-66, SFCPQBLG-67
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*           27/4/2020
*******************************************************************************************************/
public with sharing class QTB_QueueableAccountUpdate implements Queueable{
public static boolean throwExplicitException = false;
    List<Account> accountList = new List<Account>();    
    public QTB_QueueableAccountUpdate(List<Account> accList){
        accountList =accList ;
    }//Constructor to get list of accounts from trigger
  /*********************************************************************************************************
    Method Name: execute
    Parameters: QueueableContext
    Return Type: void
    Requirement: SFCPQBLG-66, SFCPQBLG-67
    Description: call batch apex to modify large no of order products
    **********************************************************************************************************/
  public void execute(QueueableContext context) {
    try {
      if (throwExplicitException) {
        throw new NullpointerException();
      }
      Database.executeBatch(
        new QTB_TaxTreatmentPopulationBatch(accountList),
        200
      );
    } catch (Exception e) {
      QTB_ExceptionLogger.createLog(
        e.getLineNumber(),
        e.getStackTraceString(),
        e.getMessage(),
        e.getTypeName(),
        QTB_QueueableAccountUpdate.class.getname()
      );
    }
  }
}
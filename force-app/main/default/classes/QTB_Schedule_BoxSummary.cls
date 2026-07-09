/*****************************************************************************************************
* Class: QTB_Schedule_BoxSummary
* Author: Lokesh Tewari
* Purpose: GitLab #26362 To link Box Summary record with EOM invoices
* Requirement: GitLab #26362 To link Box Summary record with EOM invoices 
* Change History: 14/10/2024
* Developer                         Date                    Description
* ------------------------------------------------------------------------------------------- 
Lokesh Tewari      14/10/2024     GitLab #26362 To link Box Summary record with EOM invoices
*******************************************************************************************************/
global class QTB_Schedule_BoxSummary implements Schedulable{
    Private static final String CLASSNAME = QTB_Schedule_BoxSummary.class.getName();
    public static boolean throwExplicitException = false;
    global void execute(SchedulableContext sc) {
        try{
            if( QTB_Schedule_BoxSummary.throwExplicitException){
                throw new NullPointerException();
            }
            
            Integer batchSize=Integer.ValueOf(System.Label.QTB_QTB_Batch_InvoiceUpdateForBoxSummarySize);
            // Calling Batch Class to Link Box Summary record and Update Invoice with Type EOM 
            QTB_Batch_InvoiceUpdateForBoxSummary batch = new QTB_Batch_InvoiceUpdateForBoxSummary();
            Database.executeBatch(batch,batchSize);  
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
        }
    }
}
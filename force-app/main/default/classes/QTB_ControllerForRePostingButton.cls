/*****************************************************************************************************
* Class: QTB_Regenerate_Custom_Invc_No
* Author: Virtusa (Lokesh Tewari)
* Purpose: Story 25611 Controller class which get called when button get clicked through QTB_RepPosting_Comp class
* Requirement: Story 25611 Controller class which get called when button get clicked through QTB_RepPosting_Comp class
* Created: 8/30/2024
* Developer        Date           Description
**************************************************************************************************/ 
public class QTB_ControllerForRePostingButton {
    private static final String CLASSNAME = QTB_ControllerForRePostingButton.class.getName();
    public static boolean throwExplicitException = false;
    
    /*****************************************************************************************************
* Method: callReadyForIntBatch
* Author: Virtusa (Lokesh Tewari)
* Purpose: Story 25611 Controller class which get called when button get clicked through QTB_RepPosting_Comp class
* Requirement: Story 25611 Controller class which get called when button get clicked through QTB_RepPosting_Comp class
* Created: 8/30/2024
* Developer        Date           Description
**************************************************************************************************/ 
    @AuraEnabled
    public static String callReadyForIntBatch(string recordId) {
        set<id> invcId = new set<id>();
        string result = 'Pass';
        try{
            if( QTB_ControllerForRePostingButton.throwExplicitException){
                throw new NullPointerException();
            }
            // Update QTB_Ready_for_Integration_Status__c so that we will make the button disappearonce clicked
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.id = recordId;
            invoice.QTB_Ready_for_Integration_Status__c = 'Post In Progress';            
            invcId.add(recordId);
                update invoice; 
                // Calling ready for integration batch to update Ready for integration checkbox true
                QTB_Ready_for_Integration_Batch b=new QTB_Ready_for_Integration_Batch(invcId);
                Database.executeBatch(b);
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
        // Return some value based on your logic
        return result; // Example return value
    }
}
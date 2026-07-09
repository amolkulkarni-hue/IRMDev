@isTest
public class Test_Validator_cls{
private static boolean blnAlreadyDone = false;    
private static boolean emailBatchJobDone = false; 
private static boolean emailArchiveJobExecuting = false; 
private static boolean blnAlreadyCalled = false; 
private static boolean blnAlreadyExecuted = false;  
/* down below 3 variables added by muzeeb */
private static boolean OCRfirstRun = true;    
private static boolean PROSBatchJobDone = false; 
private static boolean PROSJobExecuting = false;  
    

static testmethod void dotest1(){
     Validator_cls.hasAlreadyDone();
    Validator_cls.setAlreadyDone();
     Validator_cls.isOCRfirstRun();
     Validator_cls.isOCRfirstRun();
    Validator_cls.setAlreadyDoneToFalse();
    Validator_cls.isArchiveBatchJobDone();
    Validator_cls.isArchiveJobExecuting();
    Validator_cls.setArchiveBatchJobDone();
    Validator_cls.setArchiveJobExecuting();
    boolean flag = Validator_cls.hasAlreadyCalled();
    boolean AE = Validator_cls.hasAlreadyExecuted();
    Validator_cls.setAlreadyCalled();
    Validator_cls.setAlreadyExecuted();
    Validator_cls.setAlreadyExecutedFalse();
    boolean Pb = Validator_cls.isPROSBatchJobDone();
    boolean Pe = Validator_cls.isPROSJobExecuting();
    Validator_cls.setPROSBatchJobDone();
    Validator_cls.setPROSJobExecuting();
    
    
    Validator_cls.isaddingProduct();
    Validator_cls.setaddingProduct();

}

}
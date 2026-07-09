/******************************************************
    Developer Name : Venkateswarlu Avula,Muzeeb Shaik
    Company Name   : Iron Mountain India.
    Description    : This Class is basiclly for putting a controlling check so that trigger should 
                        not run more than 1 time.
    Date           : 31st-May-2019
    Case Number(s) : 02411596,08029723 
*********************************************************/

global class Validator_cls
{ 
    
    private static boolean OCRfirstRun = true;
    private static boolean blnAlreadyDone = false; 
    private static boolean emailBatchJobDone = false; 
    private static boolean emailArchiveJobExecuting = false; 
    
    private static boolean PROSBatchJobDone = false; 
    private static boolean PROSJobExecuting = false; 
    
    private static boolean blnAlreadyCalled = false; 
    private static boolean blnAlreadyExecuted = false; 
    
    
    private static boolean addingProduct = false; 
        
    public static boolean hasAlreadyDone(){return blnAlreadyDone;}
    
    public static boolean isOCRfirstRun(){
    	if(OCRfirstRun){
      	OCRfirstRun = false;
      	return true;
    	}else{
        return OCRfirstRun;
    	}
    }
    

    public static void setAlreadyDone() 
    {
        blnAlreadyDone = true;
    } 
    public static void setAlreadyDoneToFalse() 
    { 
        blnAlreadyDone = false;
    }
    
    public static boolean isArchiveBatchJobDone(){return emailBatchJobDone;}
    public static boolean isArchiveJobExecuting(){return emailArchiveJobExecuting;}

    public static void setArchiveBatchJobDone() 
    {
        emailBatchJobDone = true;
    } 
    public static void setArchiveJobExecuting() 
    {
        emailArchiveJobExecuting = true;
    } 
    
    public static boolean hasAlreadyCalled(){return blnAlreadyCalled;}
    public static boolean hasAlreadyExecuted(){return blnAlreadyExecuted;}

    public static void setAlreadyCalled() 
    {
        blnAlreadyCalled = true;
    } 
    public static void setAlreadyExecuted() 
    {
        blnAlreadyExecuted = true;
    } 
    public static void setAlreadyExecutedFalse() 
    {
        blnAlreadyExecuted = false;
    } 
    
    public static boolean isPROSBatchJobDone(){return PROSBatchJobDone;}
    public static boolean isPROSJobExecuting(){return PROSJobExecuting;}

    public static void setPROSBatchJobDone() 
    {
        PROSBatchJobDone = true;
    } 
    public static void setPROSJobExecuting() 
    {
        PROSJobExecuting = true;
    } 
    
    public static void setaddingProduct()
    {
        addingProduct = true;
    }
    
    public static boolean isaddingProduct(){return addingProduct;}
    
}
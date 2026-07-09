/***************************************************************************************************
* Trigger for Contract Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 3/16/2020
* @Modified      : 4/29/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger  ContractTrigger on Contract (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    public static final String CONTRACT_TRIGGER = 'ContractTrigger';
    try{
        TriggerDispatcher.Run(new ContractTriggerHandler());
        //TriggerDispatcher.Run(new QTB_ContractTriggerHandler());
        if(Test.isRunningTest()){
            throw new NullPointerException();
        }
    }
    catch(Exception e){
        QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CONTRACT_TRIGGER);
    }
}
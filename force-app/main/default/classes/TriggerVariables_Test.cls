@istest
private class TriggerVariables_Test {

    @istest
    static void testmethod1(){
        TriggerVariables vars = new TriggerVariables();
        
        TriggerVariables.RunQLIBeforeTrigger = false;
        TriggerVariables.RunQLIAfterTrigger = false;
        TriggerVariables.RunQuoteAfterTrigger = false;
    }
}
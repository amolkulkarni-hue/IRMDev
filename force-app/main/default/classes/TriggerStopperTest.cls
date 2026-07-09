@IsTest
public class TriggerStopperTest {

    @IsTest
    static void testTriggerStopperInitialization() {
        // The simple act of referencing the class ensures it is loaded 
        // and initialized, which covers the static variable declarations.
        
        // Assertions are technically not necessary for coverage, 
        // but it's good practice to verify the initial state.
        System.assert(TriggerStopper.stopOpp == false, 'stopOpp should be initialized to false');
        System.assert(TriggerStopper.stopQuote == false, 'stopQuote should be initialized to false');
        System.assert(TriggerStopper.stopOppLine == false, 'stopOppLine should be initialized to false');
        System.assert(TriggerStopper.stopQuoteLine == false, 'stopQuoteLine should be initialized to false');

        // You can also cover setting a value, though the declaration is the main part
        // for initial coverage.
        TriggerStopper.stopOpp = true;
        System.assertEquals(true, TriggerStopper.stopOpp, 'stopOpp should be settable to true');
    }
}
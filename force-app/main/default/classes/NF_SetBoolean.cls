public without sharing class NF_SetBoolean {

    public class Output {
        @InvocableVariable
        public Boolean trueValue;
        
        @InvocableVariable
        public Boolean falseValue;
    }
    
	@InvocableMethod(label='NF - Set Boolean')
    public static List<Output> setBoolean() {
        Output output = new Output();
        output.trueValue = true;
        output.falseValue = false;
        return new List<Output> { output };
    }
}
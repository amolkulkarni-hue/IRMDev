/**
 * @description       : Business Hours Check for chatbot escalation
 * @author            : Kunal Ramteke (NeuraFlash LLC)
 * @group             : 
 * @last modified on  : 18-06-2024
 * @last modified by  : Kunal Ramteke (NeuraFlash LLC)
**/
public with sharing class NF_BusinessHoursCheck {
    public class Output{

        @InvocableVariable(Required=true)
        public Boolean inBusinessHours = false;

    }

    @InvocableMethod(Label='Neuraflash - In Business Hours?')
    public static List<Output> inBusinessHours(List<String> businessHourName) {
        List<Output> result = new List<Output>();
        Output output = new Output();
        try{
            List<BusinessHours> hours = [SELECT Id,TimeZoneSidKey,FridayStartTime, FridayEndTime  
                                        FROM BusinessHours 
                                        WHERE Name = :businessHourName[0]];

            if(hours.size() > 0) {
                Datetime myDateTime = Datetime.now();
                System.debug('myDateTime' +myDateTime);

                Datetime currentTime = System.now();

                output.inBusinessHours =  BusinessHours.isWithin(hours[0].Id, currentTime);
            }
            else {
                output.inBusinessHours = false;
            }
            result.add(output);
            
        }catch(Exception e){
            System.debug('Exception in Business Hours check: ' + e);
        }
        
        return result;
    }
    
}
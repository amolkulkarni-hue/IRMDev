/**
 * @description       : Test class for NF_BusinessHoursCheck
 * @author            : Kunal Ramteke (NeuraFlash LLC)
 * @group             : 
 * @last modified on  : 18-06-2024
 * @last modified by  : Kunal Ramteke (NeuraFlash LLC)
**/
@IsTest
private class NF_BusinessHoursCheckTest {
    @IsTest
    static void testBusinessHoursFound() {
        
        Test.startTest();
        List<BusinessHours> defaultBusinessHour = [SELECT Id, Name, TimeZoneSidKey,FridayStartTime, FridayEndTime  
                                    FROM BusinessHours 
                                    WHERE IsDefault = false];
        List<String> businessHourName = new List<String>{'Default'};

        System.assertNotEquals(null,NF_BusinessHoursCheck.inBusinessHours(businessHourName)[0].inBusinessHours);
        Test.stopTest();
    }

    @IsTest
    static void testBusinessHoursNotFound() {

        Test.startTest();
        List<BusinessHours> defaultBusinessHour = [SELECT Id, Name, TimeZoneSidKey,FridayStartTime, FridayEndTime  
                                    FROM BusinessHours 
                                    WHERE IsDefault = false];
        List<String> businessHourName = new List<String>{'RandomString'};

        System.assertEquals(false,NF_BusinessHoursCheck.inBusinessHours(businessHourName)[0].inBusinessHours);
        Test.stopTest();

    }

}
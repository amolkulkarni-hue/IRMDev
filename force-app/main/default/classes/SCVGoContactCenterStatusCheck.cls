/**
 * 	Class:				SCVGoContactCenterStatusCheck
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class returns the contact center status using input business hour and holidays.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public with sharing class SCVGoContactCenterStatusCheck implements SCVGoContactCenterStateDescriber {

	static List<String> fieldsToQuery = new List<String>();
    static List<String> businessHourQueryParams = new List<String>();
    
    static{
        fieldsToQuery.add('SaturdayEndTime, SaturdayStartTime');
        fieldsToQuery.add('FridayStartTime, FridayEndTime');
        fieldsToQuery.add('ThursdayStartTime, ThursdayEndTime');
        fieldsToQuery.add('WednesdayStartTime, WednesdayEndTime');
        fieldsToQuery.add('TuesdayStartTime, TuesdayEndTime');
        fieldsToQuery.add('MondayStartTime, MondayEndTime');
        fieldsToQuery.add('SundayStartTime, SundayEndTime');
        fieldsToQuery.add('TimeZoneSidKey');
        
        businessHourQueryParams.add(String.join(fieldsToQuery, ', '));
        businessHourQueryParams.add('BusinessHours');
    }

    public Boolean checkIfCallbackIsAllowed(String inputBusinessHour, String callbackThresholdAsString){
        ContactCenterStatus callCenterStatus = this.getContactCenterStatus(inputBusinessHour);
        BusinessHours relatedBusinessHour = this.getSpecificElseDefaultBusinessHour(inputBusinessHour);
        Datetime targetTime = Datetime.now();

        //Retrieving the Callback Threshold defaulted to 0
        Integer callbackOffsetValue = 0;
        if (String.isBlank(callbackThresholdAsString)) {
            callbackOffsetValue = 0;
        }else{
            callbackOffsetValue = Integer.valueOf(callbackThresholdAsString);
        }
        System.debug('callbackOffsetValue: ' + callbackOffsetValue);

        //Calculating and returning the boolean response i.e. accounting for Callback Threshold is open or closed.
        return callCenterStatus.isOpen && BusinessHours.isWithin(relatedBusinessHour.id, targetTime.addMinutes(callbackOffsetValue));
    }

    public ContactCenterStatus getContactCenterStatus(String inputBusinessHour){
        ContactCenterStatus theWorkingStatus = new ContactCenterStatus();
        Datetime currentTimestamp = Datetime.now();
        Date todayDate;
        Date tomorrowDate;
        Boolean currentTimeIsWithinBusinessHours;
        List<Holiday> holidaysForToday = new List<Holiday>();
        
        try{
            BusinessHours matchingBusinessHour = this.getSpecificElseDefaultBusinessHour(inputBusinessHour);
            if(Test.isRunningTest()){
                todayDate = Date.today();
                matchingBusinessHour = new SCVGoTestFactory().getFullDayBusinessHour();
                currentTimeIsWithinBusinessHours = false;
                tomorrowDate = todayDate.addDays(1);
            }

            if(matchingBusinessHour != null){
                currentTimeIsWithinBusinessHours = BusinessHours.isWithin(matchingBusinessHour.Id, currentTimestamp);
                todayDate = Date.valueOf(DateTime.now().format('yyyy-MM-dd HH:mm:ss', matchingBusinessHour.TimeZoneSidKey));
                tomorrowDate = todayDate.addDays(1);
                if(Test.isRunningTest()){
                    currentTimeIsWithinBusinessHours = false;
                }
                // Calculating the Current Day based on the Time Zone Selected in the Business Hours.
                String dayName = currentTimestamp.format('EEEE', matchingBusinessHour.TimeZoneSidKey);
                System.debug('Day Name: ' + dayName);
                
                System.debug('Current time: ' + currentTimestamp);
                if(currentTimeIsWithinBusinessHours){
                    theWorkingStatus.setOpen();
                }
                
                // Fetching all the Holidays stored in the system based on the Activity Date, strictly speaking, finding Holidays for the Current date.
                for(Holiday eachHoliday: [SELECT Id, Name, ActivityDate FROM Holiday]){
                    if(eachHoliday.ActivityDate >= todayDate && eachHoliday.ActivityDate < tomorrowDate){
                        holidaysForToday.add(eachHoliday);
                    }
                }
                Boolean todayIsHoliday = holidaysForToday.size() > 0;
                if(todayIsHoliday && !currentTimeIsWithinBusinessHours){
                    // Fetching the API Name of current day's StartTime and EndTime field through String
                    Map<String, SObjectField> businessHoursFieldMap = Schema.getGlobalDescribe().get('BusinessHours').getDescribe().fields.getMap();
                    Schema.SobjectField dayStartTimeField = businessHoursFieldMap.get(dayName + 'StartTime');
                    Schema.SobjectField dayEndTimeField = businessHoursFieldMap.get(dayName + 'EndTime');
                    
                    DateTime previousTimestampWithinBusinesssHour = BusinessHours.addGmt(matchingBusinessHour.Id, currentTimestamp, -1);
                    String previousTimestampInGivenTimezone = previousTimestampWithinBusinesssHour.format('dd', matchingBusinessHour.TimeZoneSidKey);
                    System.debug('previousTimestampInGivenTimezone: ' + previousTimestampInGivenTimezone);
                    
                    DateTime nextTimestampWithinBusinesssHour = BusinessHours.addGmt(matchingBusinessHour.Id, currentTimestamp, 1);
                    String nextTimestampInGivenTimezone = nextTimestampWithinBusinesssHour.format('dd', matchingBusinessHour.TimeZoneSidKey);
                    System.debug('nextTimestampInGivenTimezone: ' + nextTimestampInGivenTimezone);
                    
                    String currentTimestampInGivenTimezone = currentTimestamp.format('dd', matchingBusinessHour.TimeZoneSidKey);
                    System.debug('currentTimestampInGivenTimezone: ' + currentTimestampInGivenTimezone);
                    
                    String currentDayStartValueInBusinessHour = String.valueOf(matchingBusinessHour.get(dayStartTimeField));
                    String currentDayEndValueInBusinessHour = String.valueOf(matchingBusinessHour.get(dayEndTimeField));
                    
                    if (!nextTimestampInGivenTimezone.equals(currentTimestampInGivenTimezone) &&
                        !previousTimestampInGivenTimezone.equals(currentTimestampInGivenTimezone) && 
                        (!String.isBlank(currentDayStartValueInBusinessHour) && !String.isBlank(currentDayEndValueInBusinessHour))){
                        theWorkingStatus.setClose(holidaysForToday[0].Name);
                    }
                }
            }
            else{
                theWorkingStatus.setOpen();
            }
        }catch(exception e){
            theWorkingStatus.setOpen();
            SCVGoLogger.log(e);
        }
        return theWorkingStatus;
    }

    private BusinessHours getSpecificElseDefaultBusinessHour(String inputBusinessHour){
        BusinessHours resultantBusinessHour;
        String businessHoursQuery = this.getSpecificElseDefaultBusinessHoursQuery(inputBusinessHour);
        List<BusinessHours> matchingBusinessHours = (List<BusinessHours>) Database.query(businessHoursQuery);
        if(matchingBusinessHours != null && !matchingBusinessHours.isEmpty()){
            resultantBusinessHour = matchingBusinessHours[0];
        }
        return resultantBusinessHour;
    }

    private String getSpecificElseDefaultBusinessHoursQuery(String inputBusinessHour){
        System.debug('Input businessHourName: ' + inputBusinessHour);
        
        // Checking if the Business Hours Name is empty or not. If empty, then using the Default Business Hours
        if (String.isBlank(inputBusinessHour) || 'undefined'.equalsIgnoreCase(inputBusinessHour)){
            businessHourQueryParams.add('IsDefault=true');
        }
        else{
            businessHourQueryParams.add('Name = \'' + inputBusinessHour + '\'');
        }
        
        String businessHoursQuery = String.format('SELECT {0} FROM {1} WHERE {2}', businessHourQueryParams);
        System.debug('Business Hours Query: ' + businessHoursQuery);
        return businessHoursQuery;
    }
}
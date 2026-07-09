public without sharing  class Util {
  
  public static List<Holiday> holidays;
  public static BusinessHours bh;
  public static List<Holiday__c> custholiday;
  public static set<date> Holidayset=new Set<Date>();

 public static DateTime getDueDateTime(String slaType, Integer minutes, Id businessHoursId,Id ownerid) {
    String country='';
    system.debug('++++++++business hours id++++'+businessHoursId);
    if(slaType == 'Clock') {
      return Datetime.now().addMinutes(minutes);
    }
    else if(slaType == 'Business') {
      Datetime startDt =  system.now();
      System.debug('+++++++Time at trigger started++++++ '+startDt);
      try{
        user u=[select id,country from user where id=:ownerid];
        country=u.country;
      }
      catch(Exception e){
        system.debug('+++++++do nothing+++++++');
        
      }
      
      // Populate Business Hours object for business hours id passed
      if(bh == null && businessHoursId != null ) {
        bh = [Select b.WednesdayStartTime, b.WednesdayEndTime, b.TuesdayStartTime, b.TuesdayEndTime, b.ThursdayStartTime, 
                b.ThursdayEndTime, b.SystemModstamp, b.SundayStartTime, b.SundayEndTime, b.SaturdayStartTime, b.SaturdayEndTime, 
                b.Name, b.MondayStartTime, b.MondayEndTime, b.IsDefault, b.IsActive, b.Id, b.FridayStartTime, b.FridayEndTime 
                From BusinessHours b where id = : businessHoursId];
      }
      // Populate holidays list
      if(custholiday==null){
         custholiday=[Select h.OwnerId, h.Name, h.Holiday_Date__c From Holiday__c h where h.Holiday_Date__c>=TODAY and Country__c=:country];
      }
      
     /* if(holidays == null)
        holidays = [Select id, ActivityDate, IsAllDay, StartTimeInMinutes, EndTimeInMinutes from Holiday where ActivityDate>=TODAY]; */
       
       for(Holiday__c h: custholiday ){
        Holidayset.add(h.Holiday_Date__c);
       }
       
       System.debug('--25----holidays:'+Holidayset);
      DateTime returnDt = getNextBusinessDueDate(startDt, minutes);
      System.debug('+++++final date++++++++'+returnDt);
      return returnDt;
    }
    return null;
  }
  
  public static DateTime getNextBusinessDueDate(DateTime startDt, Integer minutes){
      System.debug('+++37++++Executing getNextBusinessDueDate Method+++++++startDt:'+startDt);
      DateTime endDateTime = startDt;
      Integer minToCal = minutes;
      
      //If non working today
      if(!isWorkingDay(endDateTime)){
        system.debug('+++++++++inside not an working day condition in getNextBusinessDueDate method++++');
         endDateTime = getNextWorkingDay(endDateTime);
      }
      system.debug('+++++++++++++due date after checking today is working day or not++++++'+endDateTime);
      // Day of week to get start and end business hours
      String endDay = endDateTime.format('EEEE');
      Time dayStartTime = getDayStartTime(endDay);
      Time dayEndTime = getDayEndTime(endDay);
      system.debug('+++++++++start time++++++'+dayStartTime.hour());
      system.debug('+++++++++++end time+++++++++'+dayEndTime.hour());
          
      DateTime tempStartDateTime = DateTime.newInstance(endDateTime.year(), endDateTime.month(), endDateTime.day(), dayStartTime.hour(), dayStartTime.minute(), dayStartTime.second());
      DateTime tempEndDateTime = DateTime.newInstance(endDateTime.year(), endDateTime.month(), endDateTime.day(), dayEndTime.hour(), dayEndTime.minute(), dayEndTime.second());
      system.debug('++++++++start time date++++++'+tempStartDateTime);
      system.debug('++++++++end time date++++++'+tempEndDateTime);
      // If after business hours today, move to next day      
      if(endDateTime > tempEndDateTime){
         endDateTime = getNextWorkingDay(endDateTime); 
         System.debug('+++inside today is after working hours+++++');
      } // If less than end of the date, add the minute difference to minutes
      else if(endDateTime > tempStartDateTime){         
         Integer initialMinuteDiff = getBusinessMinutesDifference(tempStartDateTime, endDateTime);
         minToCal = minToCal + initialMinuteDiff;
         System.debug('+++++inside in between working dayand add time sl time+++++'+minToCal);
      }
      // setting the time to start of the day
      endDateTime = Datetime.newInstance(endDateTime.year(), endDateTime.month(), endDateTime.day(), tempStartDateTime.hour(), tempStartDateTime.minute(), tempStartDateTime.second());
      
      System.debug('++++++due date before entering in the while loop+++++++'+endDateTime);
      
      while(minToCal > 0){
         endDay = endDateTime.format('EEEE');
         dayStartTime = getDayStartTime(endDay);
         dayEndTime = getDayEndTime(endDay);         
         
         tempStartDateTime = DateTime.newInstance(endDateTime.year(), endDateTime.month(), endDateTime.dayGmt(), dayStartTime.hour(), dayStartTime.minute(), dayStartTime.second());
         tempEndDateTime = DateTime.newInstance(endDateTime.year(), endDateTime.month(), endDateTime.dayGmt(), dayEndTime.hour(), dayEndTime.minute(), dayEndTime.second());
         
         Integer minuteDiff = getBusinessMinutesDifference(tempStartDateTime, tempEndDateTime);
         System.debug('--96---minuteDiff:'+minuteDiff);
         if(minuteDiff > 0  && minToCal > minuteDiff){
            system.debug('+++++++inside min diff ceck condition+++++++');
            minToCal = minToCal - minuteDiff;
            System.debug('---99---minToCal:'+minToCal);
            endDateTime = getNextWorkingDay(endDateTime);
            System.debug('---101---endDateTime:'+endDateTime);
            continue;
         }
         else
           break;
      }
      
      // need to add minutes left in the end
      system.debug('+++++++++endate time bfore it return and min++++++'+endDateTime+minToCal);
      endDateTime = endDateTime.addMinutes(minToCal);    
      return endDateTime;
  }
  
  public static Integer getBusinessMinutesDifference(Datetime startDt, Datetime endDt){
      Long miliSecondDiff = BusinessHours.diff(bh.id, startDt, endDt);
      Integer minuteDiff = ((miliSecondDiff)/1000/60).intValue();
      return minuteDiff;
  }
  
  public static Boolean checkHoliday(Datetime dt) {
    System.debug('+++124++++Executing checkHoliday Method+++++++dt:'+dt);
    Date currentdate=dt.dateGMT();
     system.debug('+++++++++++date current++++++++'+currentdate);
    if(Holidayset.contains(currentdate)){
        System.debug('+++++++yes this is a holiday++++++');
        return true;
    }
    else{
        return false;
    }
  }
  
  public static DateTime getNextWorkingDay(Datetime dt) {
    System.debug('+++157++++Executing getNextWorkingDay Method+++++++dt:'+dt);
    DateTime nextWorkingDate = dt;
    //(holidays == null)
     // holidays = [Select id, IsAllDay, ActivityDate, StartTimeInMinutes, EndTimeInMinutes from Holiday ];
    while(true){
        nextWorkingDate = nextWorkingDate.addDays(1);
        if(nextWorkingDate.format('EEEE') == 'Saturday' || nextWorkingDate.format('EEEE') == 'Sunday' || checkHoliday(nextWorkingDate))
            continue;
        else
            break;
    }   
    // Set time to days business hours start time
    String thisDay = nextWorkingDate.format('EEEE');
    Time busStartTime = getDayStartTime(thisDay);
    nextWorkingDate = DateTime.newInstance(nextWorkingDate.year(), nextWorkingDate.month(), nextWorkingDate.day(), busStartTime.hour(), busStartTime.minute(), busStartTime.second());      
    
    return nextWorkingDate;
  }
  
   private static Boolean isWorkingDay(Datetime dt) {
    System.debug('Executing isWorkingDay Method+++++++'+dt);
    //if(holidays == null)
       // holidays = [Select id, IsAllDay, ActivityDate, StartTimeInMinutes, EndTimeInMinutes from Holiday ];
    if(dt.format('EEEE') == 'Saturday' || dt.format('EEEE') == 'Sunday' || checkHoliday(dt)){
        return false;
    }
    return true;
  }
  
  /*public static Integer getBusinessDaysDiff(Date startDt, Date endDt){
    Integer diff = 0;
    if(endDt <= startDt){
        return diff;
    }
    DateTime tempDate = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day());
    while(tempDate.date() < endDt){
        tempDate = getNextWorkingDay(tempDate);
        if(tempDate.date() <= endDt)
           diff ++;
    }
    return diff;
  }*/
 /* public static Decimal getBusinessDaysDiff(DateTime startDt, DateTime endDt){
    System.debug('+++200++++Executing getBusinessDaysDiff Method+++++++startDt:'+startDt +'\t endDt:'+endDt);
    Decimal diff = 0.0;     
    if(endDt <= startDt){
        return diff;
    }
    long difference_miliseconds = endDt.getTime()-startDt.getTime();
    long differenceHour = difference_miliseconds / 3600000;
    DateTime tempDate = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day());
    system.debug('differenceHourrrrrrrrrrr='+differenceHour);
    while(differenceHour > 24 ){
        DateTime nextWorkingDate = tempDate;
        if(holidays == null)
            holidays = [Select id, IsAllDay, ActivityDate, StartTimeInMinutes, EndTimeInMinutes from Holiday ];
        while(true){
            nextWorkingDate = nextWorkingDate.addDays(1);
            differenceHour = differenceHour -24;
            if(nextWorkingDate.format('EEEE') == 'Saturday' || nextWorkingDate.format('EEEE') == 'Sunday' || checkHoliday(nextWorkingDate))
                continue;
            else
                break;
        }   
        tempDate = nextWorkingDate;
        diff =diff +1.0;
    }
    if(differenceHour > 0){
        Decimal decHour= Decimal.valueOf(differenceHour); 
        diff = diff + (decHour / 24.0);
    }
    System.debug('------228------------diff.setScale(2):'+diff.setScale(2));
    return diff.setScale(2);
  } */
  public static Time getDayStartTime(String day) {
    System.debug('+++231++++Executing getDayStartTime Method+++++++day:'+day);
    if(day.toUpperCase() == 'SUNDAY')
      return bh.SundayStartTime;
    if(day.toUpperCase() == 'MONDAY')
      return bh.MondayStartTime;
    if(day.toUpperCase() == 'TUESDAY')
      return bh.TuesdayStartTime;
    if(day.toUpperCase() == 'WEDNESDAY')
      return bh.WednesdayStartTime;
    if(day.toUpperCase() == 'THURSDAY')
      return bh.ThursdayStartTime;
    if(day.toUpperCase() == 'FRIDAY')
      return bh.FridayStartTime;
    if(day.toUpperCase() == 'SATURDAY')
      return bh.SaturdayStartTime;
    System.debug('------246------------bh.MondayStartTime:'+bh.MondayStartTime);
    return bh.MondayStartTime;
  }
  
  public static Time getDayEndTime(String day) {
    System.debug('+++231++++Executing getDayEndTime Method+++++++day:'+day);
    if(day.toUpperCase() == 'SUNDAY')
      return bh.SundayEndTime;
    if(day.toUpperCase() == 'MONDAY')
      return bh.MondayEndTime;
    if(day.toUpperCase() == 'TUESDAY')
      return bh.TuesdayEndTime;
    if(day.toUpperCase() == 'WEDNESDAY')
      return bh.WednesdayEndTime;
    if(day.toUpperCase() == 'THURSDAY')
      return bh.ThursdayEndTime;
    if(day.toUpperCase() == 'FRIDAY')
      return bh.FridayEndTime;
    if(day.toUpperCase() == 'SATURDAY')
      return bh.SaturdayEndTime;
    System.debug('------266------------bh.MondayEndTime:'+bh.MondayEndTime);
    return bh.MondayEndTime;
  }
  //madhu added test method
/*  static testMethod void doTest(){
      user u=[select id from user where id=:userInfo.getUserId()];
      BusinessHours bh1=[select id from BusinessHours where name='CAC-Retention' limit 1];
      Integer sltime=1440;
      string businessType='Clock';
      string businessType1='Business';
      getDueDateTime(businessType,sltime,bh1.id,u.id);
      getDueDateTime(businessType1,sltime,bh1.id,u.id);
  } */
  @future
  public static void logError(String componentName, String methodName,String queryParams, String errorMessage, String stackTrace, String userId) {
       
    /*     Community_Site_Configuration__mdt csConfig = [
        SELECT Logger_Enabled__c 
        FROM Community_Site_Configuration__mdt 
        WHERE Label = 'Source Systems' 
        AND Functionality_Type__c = 'Orders_Invoice'
        LIMIT 1
    ]; 
    if(csConfig.Logger_Enabled__c){  }else {
        system.debug('CSC Logger skipped - Community_Site_Configuration__mdt');
      }    */ 
       
       System.debug('logging started...');
            Community_Error_Log__c errorLog = new Community_Error_Log__c();
            errorLog.Component_Name__c = componentName;
            errorLog.Method__c = methodName;
            errorLog.Customer_ID__c = queryParams;
            errorLog.User__c = userId;
            if(errorMessage =='success'){
              	errorLog.Status__c = 'Success';
            }else{
              	errorLog.Status__c = 'Fail';
                errorLog.Error_Message__c = errorMessage;
                errorLog.Stack_Trace__c = stackTrace;
            }           
          try {
            // insert errorLog;
           Database.SaveResult result = Database.insert(errorLog, false);
          if (!result.isSuccess()) {
             for (Database.Error err : result.getErrors()) {
             System.debug('Failed to log error: ' + err.getMessage());
            }
          }else{
              System.debug('Logged successfully');
            }
        } catch (Exception e) {
            System.debug('ERROR: Failed to save error log: ' + e.getMessage());
            System.debug('Original Error: Component=' + componentName + ', Method=' + methodName + ', Message=' + errorMessage);
        }
      
    }
  
}
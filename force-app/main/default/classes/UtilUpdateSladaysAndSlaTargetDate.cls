public with sharing class UtilUpdateSladaysAndSlaTargetDate {
  private static Map<Id,IM_Customer_Account__c> customerAccounts;
  private static Map<Id,Holiday_Schedule__c> holidaySchedules ;  
  private static Map<Id,Service_Location__c> caseServiceLocation;
  private static Map<ID,string> caseCreatorTimeZoneName ;
  
  public static void GetCaseCustomerAccountAndHolidaySchedule(List<Case> cases){
    Set<Id> customerAccountIds = new Set<Id>();
    Set<ID> serviceLocationID = new Set<id>();
    Set<ID> caseCreatorIDs = new Set<ID>(); // to store casecreatorid
    for(Case cse : cases){
        customerAccountIds.add(cse.Customer_ID__c);  
        serviceLocationID.add(cse.Service_Location__c);
        if(cse.CreatedById != null){
          caseCreatorIDs.add( cse.CreatedById);
        }
      }
    // add CurrentUserID into case creator id 
    caseCreatorIDs.add(UserInfo.getUserId());
    if(customerAccounts == null || holidaySchedules == null){
      customerAccounts = new Map<Id,IM_Customer_Account__c>();
      holidaySchedules = new Map<Id,Holiday_Schedule__c>();  
      if(customerAccountIds != null && customerAccountIds.size() > 0){        
      customerAccounts = new Map<Id,IM_Customer_Account__c>([Select Id, Owning_District_Id__c,Owning_District_Id__r.Holiday_Schedule__c,Owning_District_Id__r.Time_Zone__c,
                                 Owning_District_Id__r.Time_Zone__r.Off_Set_Hours__c,Owning_District_Id__r.Time_Zone__r.Time_Zone_ID__c,Owning_District_Id__r.Time_Zone__r.Name, 
                                 Owning_District_Id__r.Time_Zone__r.Use_Daylight_Savings__c,Owning_District_Id__r.Time_Zone__r.Id 
                                 From IM_Customer_Account__c 
                                 WHERE Id IN :customerAccountIds]);
      }    
      Set<Id> holidayScheduleIds = new set<Id>();  
      for(IM_Customer_Account__c customerAccount :customerAccounts.values()){
        if(customerAccount.Owning_District_Id__c != null)
          holidayScheduleIds.add(customerAccount.Owning_District_Id__r.Holiday_Schedule__c);
      }    
        if(holidayScheduleIds != null && holidayScheduleIds.size() > 0){
            holidaySchedules = new Map<Id,Holiday_Schedule__c>([Select Id,(Select Id,Name,Holiday__r.Holiday_Date__c FROM Holiday_Schedule_Lines__r) FROM Holiday_Schedule__c WHERE Id IN : holidayScheduleIds]);
        }
      }
    // get  case related Service_location__c -> time zone     
    if(caseServiceLocation == null && (serviceLocationID != null && serviceLocationID.size() > 0)){        
        caseServiceLocation = new MAp<ID,Service_Location__c>([Select Id,Svc_District_Id__c,
                            Svc_District_Id__r.Time_Zone__c , 
                            Svc_District_Id__r.Time_Zone__r.Off_Set_Hours__c,
                            Svc_District_Id__r.Time_Zone__r.Use_Daylight_Savings__c from Service_Location__c 
                            where ID IN: serviceLocationID and  Svc_District_Id__c != null ]);        
    }
    // Case creator time zone
    if(caseCreatorTimeZoneName == null ){
      caseCreatorTimeZoneName = new Map<ID,string>();     
      List<User> lstUser = [Select id,TimeZoneSidKey From User where id in:caseCreatorIDs];
      for(User u : lstUser){
        caseCreatorTimeZoneName.put(u.id,u.TimeZoneSidKey );        
      }
    }
    
  } 
  
  // get sla target date of given casses
  public static Map<ID,DateTime> getSlaTargetDateForCases(List<Case> cases,Boolean isInsert){
    Map<ID,DateTime> mapSlaTargetDate = new Map<ID,DateTime>();      
    for(Case cse : cases){
      mapSlaTargetDate.put(cse.Id,getSlaTargetDateForSingleCase(cse));
    }
    return mapSlaTargetDate;
  }
  // get sla target date of single case 
  public static DateTime getSlaTargetDateForSingleCase(Case cse){
    Double slaDay = cse.SLA_Days__c != null? cse.SLA_Days__c : 0.0;
    //DateTime createdDate =  DateTime.now() ;
    DateTime createdDate = cse.ID != null? cse.CreatedDate : DateTime.now() ;
    //***** get market or service location time zone
    List<Integer>lstTimeZone = getMarketOrServiceLocationTimeZoneHour(cse);
    integer intMarketLocationtimeZone = 0;
    integer intTimeZoneMinutes = 0;
    if(lstTimeZone != null && lstTimeZone.size() > 1){
      intMarketLocationtimeZone = lstTimeZone[0];
      intTimeZoneMinutes = lstTimeZone[1];
    }  
    // Convert creadted date according to market or service location time zone
    createdDate = createdDate.addHours(intMarketLocationtimeZone);
    createdDate = createdDate.addMinutes(intTimeZoneMinutes);  
    //********
    DateTime slaDate; 
    IM_Customer_Account__c customerAccount = customerAccounts.get(cse.Customer_ID__c);
    if( customerAccount != null && customerAccount.Owning_District_Id__r.Holiday_Schedule__c != null && holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r != null){
        slaDate = calSlaTargetDateUsingMinutes(createdDate,slaDay,holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r);
      }
      else{
        List<Holiday_Schedule_Line__c> hsLine = new List<Holiday_Schedule_Line__c>();
        slaDate = calSlaTargetDateUsingMinutes(createdDate,slaDay,hsLine);
      }
      //convert date according to selected time zone  
      sladate = sladate.addHours((-1*intMarketLocationtimeZone)); 
    sladate = sladate.addMinutes((-1*intTimeZoneMinutes));
    //*****************/      
    return slaDate;
  } 
  // Initial Due date on Holiday Or not for list of cases
  /*public static Map<Date,Boolean> isInitialDueDateOnHoliday(List<Case> cases){
    Map<Date,Boolean> mapInitialDueDateOnHoliday = new Map<Date,Boolean>();
    for(Case cse : cases){// Check the initial due date is on a week end or on a holiday  
      IM_Customer_Account__c customerAccount = customerAccounts.get(cse.Customer_ID__c);
      if(customerAccount.Owning_District_Id__r.Holiday_Schedule__c != null && holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r != null){
        
        DateTime dtinitialDate = DateTime.newInstance(cse.Initial_Due_Date__c.year(), cse.Initial_Due_Date__c.month(), cse.Initial_Due_Date__c.day(), 0, 0, 0);
        if(!isWorkingDay(dtinitialDate,holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r)){
              mapInitialDueDateOnHoliday.put(cse.Initial_Due_Date__c,True);
            }              
            
          }
    }
    return mapInitialDueDateOnHoliday;
  }*/
  // Initial Due date on Holiday Or not for single case
  public static Boolean isInitialDueDateOnHoliday(Case cse){
    Map<Date,Boolean> mapInitialDueDateOnHoliday = new Map<Date,Boolean>();
    Boolean isOnHoilday = false;
    // Check the initial due date is on a week end or on a holiday  
    IM_Customer_Account__c customerAccount = customerAccounts.get(cse.Customer_ID__c);
    if(customerAccount.Owning_District_Id__r.Holiday_Schedule__c != null && holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r != null){
      
      DateTime dtinitialDate = DateTime.newInstance(cse.Initial_Due_Date__c.year(), cse.Initial_Due_Date__c.month(), cse.Initial_Due_Date__c.day(), 0, 0, 0);
      if(!isWorkingDay(dtinitialDate,holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r)){
          isOnHoilday = true;
        }   
      }    
    return isOnHoilday;
  }
  // Not in  use  
  /*private static DateTime calSlaTargetDate(DateTime startDt, Integer slaDay,List<Holiday_Schedule_Line__c> holidayLines){
    DateTime endDateTime = startDt;
    Integer minTotal = 0;
    Integer hourTotal=0;
    DateTime tempStartDateTime = DateTime.newInstance(endDateTime.year(), endDateTime.month(), endDateTime.day(), 8,0,0);
    DateTime tempEndDateTime = DateTime.newInstance(endDateTime.year(), endDateTime.month(), endDateTime.day(), 17, 0, 0);
    // If non working today or after business hours today, move to next day      
    if(endDateTime > tempEndDateTime || !isWorkingDay(endDateTime,holidayLines)){
      endDateTime = getNextWorkingDay(endDateTime,holidayLines); 
      hourTotal = 9;
      slaDay = slaDay-1;
    } // If less than end of the date, add the minute difference to minutes
    else if(endDateTime > tempStartDateTime){     
      hourTotal = endDateTime.hour() - tempStartDateTime.hour();
      minTotal =  endDateTime.minute() - tempStartDateTime.minute();        
    }
    else if(endDateTime <= tempStartDateTime){
      hourTotal = 9;
      slaDay = slaDay-1;
    }
    // setting the time to start of the day
    endDateTime = Datetime.newInstance(endDateTime.year(), endDateTime.month(), endDateTime.day(), 8, 0, 0);
    while(slaDay > 0){
      endDateTime = getNextWorkingDay(endDateTime,holidayLines);
      slaDay = slaDay - 1;
    }      
    // need to add minutes and hour 
    endDateTime = endDateTime.addHours(hourTotal);  
    endDateTime = endDateTime.addMinutes(minTotal);     
    return endDateTime;
  }*/
  ////
  private static DateTime calSlaTargetDateUsingMinutes(DateTime startDt, double slaDay,List<Holiday_Schedule_Line__c> holidayLines){
    Decimal dMinutes = 540*slaDay;    
    Integer totalMinutes = dMinutes.round(System.RoundingMode.CEILING).intValue();
    Integer hourTotal=0;    
    DateTime sladate;
    DateTime tempStartDateTime = DateTime.newInstanceGmt(startDt.year(), startDt.month(), startDt.day(), 8,0,0);
    DateTime tempEndDateTime = DateTime.newInstanceGmt(startDt.year(), startDt.month(), startDt.day(), 17, 0, 0);
    sladate= tempStartDateTime;
    DateTime dtCurrentUser = DateTime.newInstanceGmt(startDt.year(), startDt.month(), startDt.day(), 8,0,0);
    // If non working today or after business hours today, move to next day      
    if(startDt >= tempEndDateTime  || !isWorkingDay(startDt,holidayLines)){
      // stsrt date is after the end of working day
      sladate = getNextWorkingDay(tempStartDateTime,holidayLines); 
      
    } // If less than end of the date, add the minute difference to minutes
    else if(startDt > tempStartDateTime ){ 
      // stsrt date is in bitween the working day
      hourTotal = tempEndDateTime.hour()- startDt.hour();  
      integer totlaMinutesWorkToday = ( hourTotal*60) - startDt.minute();
      if(totalMinutes > totlaMinutesWorkToday){
        totalMinutes = totalMinutes - totlaMinutesWorkToday;
        sladate = getNextWorkingDay(tempStartDateTime,holidayLines); 
      }
      else
      {
        
        sladate =    startDt; 
      }
    }
    system.debug('sladate datebefore adding sla minutes='+startDt);
    while(totalMinutes > 540){
      sladate = getNextWorkingDay(sladate,holidayLines);
      totalMinutes = totalMinutes - 540;
    }      
    // need to add minutes and hour 
    if(totalMinutes >0)
    {
      sladate = sladate.addMinutes(totalMinutes);    
    }    
    return sladate;
  }
  
  public static Map<DAteTime,DAteTime> GetSlaTargetDateForClonedCase(List<Case> cases){
    Map<DateTime,DAteTime> mapSlatargetDate = new Map<DateTime,DAteTime>();
    GetCaseCustomerAccountAndHolidaySchedule(cases);
    for(Case cse : cases){      
      IM_Customer_Account__c customerAccount = customerAccounts.get(cse.Customer_ID__c);
      if(customerAccount.Owning_District_Id__r.Holiday_Schedule__c != null && holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r != null){
        if(!isWorkingDay(cse.SLA_Target_Date__c,holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r)){
              DateTime dtSlaTargetDate = getNextWorkingDay(cse.SLA_Target_Date__c,holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r);
              mapSlatargetDate.put(cse.SLA_Target_Date__c,dtSlaTargetDate);
            }
          }
    }
    return mapSlatargetDate;
  }
  
  public static DAteTime GetSlaTargetDateForClonedCase(Case cse ){    
    DateTime dtSlaTargetDate = cse.SLA_Target_Date__c;
            
    IM_Customer_Account__c customerAccount = customerAccounts.get(cse.Customer_ID__c);
    if( customerAccount != null && customerAccount.Owning_District_Id__r.Holiday_Schedule__c != null && holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r != null){
      if(!isWorkingDay(cse.SLA_Target_Date__c,holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r)){        
          dtSlaTargetDate = getNextWorkingDay(cse.SLA_Target_Date__c,holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r);
        }
      }
      else{
        List<Holiday_Schedule_Line__c> hsLine = new List<Holiday_Schedule_Line__c>();
        if(!isWorkingDay(cse.SLA_Target_Date__c,hsLine)){
          dtSlaTargetDate = getNextWorkingDay(cse.SLA_Target_Date__c,hsLine);
        }        
      }    
    return dtSlaTargetDate;
  }
  private static Boolean isWorkingDay(Datetime dt,List<Holiday_Schedule_Line__c> holidayLines) {       
    if(dt.format('EEEE') == 'Saturday' || dt.format('EEEE') == 'Sunday')
    return false;
    //checking for holidays
    for(Holiday_Schedule_Line__c holidayLine : holidayLines) {
      if(holidayLine.Holiday__r.Holiday_Date__c == dt.date()){        
      return false;
      }
    }
    return true;
  }
  private static DateTime getNextWorkingDay(Datetime dt,List<Holiday_Schedule_Line__c> holidayLines) {
    DateTime nextWorkingDate = dt;
    
    while(true){
      nextWorkingDate = nextWorkingDate.addDays(1);
      if(isWorkingDay(nextWorkingDate,holidayLines))
      break;
    }    
    return nextWorkingDate;
  }
  // not in use
  @TestVisible
  private static DateTime getLastWorkingDay(Datetime dt,List<Holiday_Schedule_Line__c> holidayLines) {
    DateTime nextWorkingDate = dt;
    while(true){
      nextWorkingDate = nextWorkingDate.addDays(-1);
      if(isWorkingDay(nextWorkingDate,holidayLines))
      break;
    }    
    return nextWorkingDate;
  }
  // not in used
  /*public static Date addSlaDaysIntoCreatedDate(Case cse, integer slaDay,date dateCreated){
      DateTime slaDate = DateTime.newInstance(dateCreated.year(), dateCreated.month(), dateCreated.day(), 8,0,0); 
      IM_Customer_Account__c customerAccount = customerAccounts.get(cse.Customer_ID__c);    
      List<Holiday_Schedule_Line__c> hsLine = new List<Holiday_Schedule_Line__c>();
          if(customerAccount.Owning_District_Id__r.Holiday_Schedule__c != null && holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r != null){
            hsLine = holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r;
          }
          if(!isWorkingDay(slaDate,hsLine)){
        slaDate = getNextWorkingDay(slaDate,hsLine); 
      }
          while(slaDay > 0){
              slaDate = getNextWorkingDay(slaDate,hsLine);
              slaDay = slaDay-1;
            }
    
    return slaDate.date();
  }*/
  
  public static Date getSlaTargetDateForSingleCase(Case cse, Double slaDay , DateTime createdDate){
    Map<ID,DateTime> mapSlaTargetDate = new Map<ID,DateTime>();      
    DateTime slaDate; 
    //***** get market or service location time zone
    List<Integer>lstTimeZone = getMarketOrServiceLocationTimeZoneHour(cse);
    integer intMarketLocationtimeZone = 0;
    integer intTimeZoneMinutes = 0;
    if(lstTimeZone != null && lstTimeZone.size() > 1){
      intMarketLocationtimeZone = lstTimeZone[0];
      intTimeZoneMinutes = lstTimeZone[1];
    }  
    //convert created date according to market or service location time zone
    createdDate = createdDate.addHours(intMarketLocationtimeZone);
    createdDate = createdDate.addHours(intTimeZoneMinutes);    
    //********
    IM_Customer_Account__c customerAccount = customerAccounts.get(cse.Customer_ID__c);
    if(customerAccount.Owning_District_Id__r.Holiday_Schedule__c != null && holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r != null){
        slaDate = calSlaTargetDateUsingMinutes(createdDate,slaDay,holidaySchedules.get(customerAccount.Owning_District_Id__r.Holiday_Schedule__c).Holiday_Schedule_Lines__r);
      }
      else{
        List<Holiday_Schedule_Line__c> hsLine = new List<Holiday_Schedule_Line__c>();
        slaDate = calSlaTargetDateUsingMinutes(createdDate,slaDay,hsLine);            
      }  
      //convert date according to selected time zone      
    sladate = sladate.addHours((-1*intMarketLocationtimeZone)); 
    sladate = sladate.addMinutes((-1*intTimeZoneMinutes));
    //*****************/  
    return slaDate.date();
  } 
  // To get service location time zone hour or market time zone hour
  public static List<Integer> getMarketOrServiceLocationTimeZoneHour(case cse){
    
    IM_Customer_Account__c customerAccount = customerAccounts.get(cse.Customer_ID__c);
    Service_Location__c ServiceLocationWithTimeZone;
    Integer intMarketLocationtimeZone = null;
    List<Integer> lstTimeZone = new  List<Integer>();
    if(caseServiceLocation.containsKey(cse.Service_Location__c)){
       ServiceLocationWithTimeZone = caseServiceLocation.get(cse.Service_Location__c);
    }  
    if(ServiceLocationWithTimeZone != null && ServiceLocationWithTimeZone.Svc_District_Id__c != null && ServiceLocationWithTimeZone.Svc_District_Id__r.Time_Zone__c != null){
      // Use service location time zone
      intMarketLocationtimeZone = Integer.valueOf(ServiceLocationWithTimeZone.Svc_District_Id__r.Time_Zone__r.Off_Set_Hours__c);
      lstTimeZone.add(intMarketLocationtimeZone);
      lstTimeZone.add(0);
      
    }
    else if( customerAccount != null && customerAccount.Owning_District_Id__c != null && customerAccount.Owning_District_Id__r.Time_Zone__c != null && customerAccount.Owning_District_Id__r.Time_Zone__r.Off_Set_Hours__c != null){
          // Use market time zone
          intMarketLocationtimeZone =  Integer.valueOf(customerAccount.Owning_District_Id__r.Time_Zone__r.Off_Set_Hours__c);
          lstTimeZone.add(intMarketLocationtimeZone);  
          lstTimeZone.add(0);           
         }
         else{
           // Use Case Creator Time Zone               
      intMarketLocationtimeZone=0;
      ID caseCreatorId = cse.CreatedById != null? cse.CreatedById : UserInfo.getUserId();      
      if(caseCreatorTimeZoneName.containsKey(caseCreatorId)){
        lstTimeZone = GetCaseCreatorTimeZone(caseCreatorTimeZoneName.get(caseCreatorId));         
      }
         }
    return lstTimeZone;
  }
  // Get Case Creator Time Zone 
  public static List<Integer> GetCaseCreatorTimeZone(string timeZone){
    Schema.DescribeFieldResult F = User.TimeZoneSidKey.getDescribe();
        List<Schema.PicklistEntry> timeZonePiclList = F.getPicklistValues();
        string strTimeZone ='';
        List<Integer> lstTimeZone;
        for(Schema.PicklistEntry entry : timeZonePiclList){
            if(entry.getValue() == timeZone){
                strTimeZone= entry.getLabel().substring(entry.getLabel().indexOf('GMT')+3,entry.getLabel().indexOf(')'));
                break;
               }
        }
        if(strTimeZone !=''){
          String[] strHourMinutes = strTimeZone.split(':');
          if(strHourMinutes.size()>1){
            lstTimeZone = new List<Integer>();
        if(strHourMinutes[0].indexOf('+') >=0){
          // time is plus GMT
          lstTimeZone.add(Integer.valueOf(strHourMinutes[0].substring(strHourMinutes[0].indexOf('+')+1)));
          lstTimeZone.add(Integer.valueOf(strHourMinutes[1]));
        }
        else{
          // time is minus GMT
          lstTimeZone.add( Integer.valueOf(strHourMinutes[0]));
          lstTimeZone.add((Integer.valueOf(strHourMinutes[1])) *-1);
        }
      }
        }
                              System.debug('queries used: ' + Limits.getQueries());
        
        return lstTimeZone;
  }
 
}
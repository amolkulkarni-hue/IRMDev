/* 
*********************************************************************************************************************
Name            : IRM_SC_CaclulateSLAClass
Test Class		: IRM_SC_CaclulateSLAClassTest
Description     : 1. Calculate SLA as per case Category and Sub Category
                  2. Set SLA and Calculate SLA time remaining
Copyright       : HCL Technologies
Author          : Sejal Shah
Date Created 	: 15-Mar-2012

Modification Log:
Date 				Author							Story Number		Description
18-Oct-2022			Arjun Sankar					#11278				Stop adding country values in caseSLASelection - moving to custom settings IME_SC_Country_List__c	

********************************************************************************************************************
*/

public with sharing class IRM_SC_CaclulateSLAClass {
    
    List<IME_SC_SLA_Matrix__c> caseSLATime = IME_SC_SLA_Matrix__c.getAll().values();
    
    static Boolean isSLAActive = true;
    static Boolean firstRun = true;
    public Integer customSLATime;
    FINAL Integer DEFAULT_TIME_ELAPSED = 0;
    FINAL Integer DEFAULT_COMPLAINTS_SLA = 4;
    FINAL Integer DEFAULT_ORDER_SLA_DAY = 1;
    FINAL Integer SLA_VALUE_24_HOURS = 24;
    Map<Id, BusinessHours> businessHoursMap;
    Map<Id, Boolean> calculateSLAMap = new Map<Id, Boolean>();
    String calculate_50_Percent;
    Integer SLA_50_Percent;
    String calculate_75_Percent;
    Integer SLA_75_Percent;
    String calculate_125_Percent;
    Integer SLA_125_Percent;
    Datetime newDate;
    
    public void setSLA(List<Case> newTriggerCaseList, Map<Id,Case> oldTriggerCaseMap)
    { 
        
        system.debug(logginglevel.info, '++++ caseSLA Time' + caseSLATime + ' Size:' + caseSLATime.size());
        //calsulate SLA by calling a function
        Map<Id, Integer> caseSLAMap = caseSLASelection(newTriggerCaseList);
        system.debug(logginglevel.info, '++++ newTriggerCaseList' + newTriggerCaseList);
        system.debug(logginglevel.info, '++++ caseSLAMap' + caseSLAMap);
        Integer SLAValue;
        Integer totalOnHoldTime;
        Boolean calculateSLA;
        Datetime onHoldTimeAfterCuttOff;
        Datetime resumeTimeAfterCutOff;
        Boolean IsIMLACase = false;
        for(Case newCase: newTriggerCaseList)
        {
            //For cut off time
            if(newCase.IME_SC_SLA_Missed__c != true)
            {
                // Code added by Pratap
                 List<IME_SC_Toggle_Country_Features__c> toggleFeaturesCustomSetting = IME_SC_Toggle_Country_Features__c.getall().values();
                for(IME_SC_Toggle_Country_Features__c toggleFeature : toggleFeaturesCustomSetting){
                    if((toggleFeature.Feature_Name__c.equalsIgnoreCase('SLA Calc for Onhold Internal status') && (toggleFeature.Country__c.equalsIgnoreCase(newCase.IME_SC_Country__c))
                        &&(toggleFeature.Is_Active__c))){
                            IsIMLACase = true;
                        }
                    
                } 
                // End of code added by Pratap
                
                if(newCase.IME_SC_Cut_Off_Time__c != null)
                {
                    if(newCase.IME_SC_SLA_Trigger_Time__c != null)
                    {
                        newCase.IME_SC_SLA_Trigger_Time__c = null;
                        newCase.IME_SC_Initial_SLA_Start_Time__c = null;
                    }
                }
                else
                {
                    SLAValue = caseSLAMap.get(newCase.Id);
                   // system.debug(logginglevel.info, '++++ 58 SLAValue' + SLAValue + ' Business Hours:'+ businessHoursMap.get(newCase.BusinessHoursId).Name);
                   // system.debug('newCase.Rush__c:'+ newCase.Rush__c);
                    if(SLAValue != null && newCase.BusinessHoursId != null && 
                        !(businessHoursMap.get(newCase.BusinessHoursId).Name).startsWith('8:30')
                        && newCase.Rush__c == false)
                    {
                        system.debug(logginglevel.info, '++++ does not start with 8.30');
                        if(calculateSLAMap != null && !calculateSLAMap.isEmpty())
                        {
                            calculateSLA = calculateSLAMap.get(newCase.Id);
                            system.debug(logginglevel.info,'+++ calculate sla '+ calculateSLA);
                            SLACalculation(SLAValue, calculateSLA);
                            if(calculateSLA == false)
                            {
                                try{
                                        newCase.IME_SC_Initial_SLA_Start_Time__c = BusinessHours.add(newCase.BusinessHoursId, newCase.CreatedDate, 1000L);
                                        system.debug(logginglevel.info, '++++++ 1+++++ IME_SC_Initial_SLA_Start_Time__c ++' + newCase.IME_SC_Initial_SLA_Start_Time__c );
                                   }
                                catch(System.Nullpointerexception NE)
                                {
                                    newCase.IME_SC_Initial_SLA_Start_Time__c = BusinessHours.add(newCase.BusinessHoursId, system.now(), 1000L);
                                    system.debug(logginglevel.info, '++++++ 2 +++++ IME_SC_Initial_SLA_Start_Time__c ++' + newCase.IME_SC_Initial_SLA_Start_Time__c );
                                }
                                    newCase.IME_SC_SLA_Trigger_Time__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_Initial_SLA_Start_Time__c, SLAValue * 60 * 1000L);
                            }
                            else// if(calculateSLA == true)
                            {
                                try{
                                    newCase.IME_SC_Initial_SLA_Start_Time__c = BusinessHours.add(newCase.BusinessHoursId, newCase.CreatedDate, 1000L);
                                     system.debug(logginglevel.info, '++++++ 3 +++++ IME_SC_Initial_SLA_Start_Time__c ++' + newCase.IME_SC_Initial_SLA_Start_Time__c );
                                }
                                catch(System.Nullpointerexception NE)
                                {
                                    newCase.IME_SC_Initial_SLA_Start_Time__c = BusinessHours.add(newCase.BusinessHoursId, System.NOW(), 1000L);
                                     system.debug(logginglevel.info, '++++++ 4 +++++ IME_SC_Initial_SLA_Start_Time__c ++' + newCase.IME_SC_Initial_SLA_Start_Time__c );
                                } 
                                //for case status 'New', 'Validated', 'Assigned', 'In Progress' without going on Hold.
                                if(newCase.IME_SC_SLA_Hold_Time__c == null && newCase.IME_SC_SLA_Resume_Time__c == null && ((newCase.Status == 'New') ||
                                  (newCase.Status == 'Validated') || (newCase.Status == 'Assigned') || (newCase.Status == 'In Progress') || (newCase.Status == 'Resolved') ||
                                                                                                                           ((newCase.Status == 'On Hold - Internal') && (IsIMLACase== true))))
                                {   
                                     newCase.IME_SC_SLA_Time_Elapsed__c = BusinessHours.diff(newCase.BusinessHoursId,newCase.IME_SC_Initial_SLA_Start_Time__c, System.now())/60000;
                                     newCase.IME_SC_SLA_Time_Remaining__c = SLAValue - newCase.IME_SC_SLA_Time_Elapsed__c;
                                     newCase.IME_SC_SLA_Trigger_Time__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_Initial_SLA_Start_Time__c, SLAValue * 60 * 1000L);
                                     if(calculateSLA == true)
                                     {  
                                        newCase.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_Initial_SLA_Start_Time__c, SLA_50_percent * 60 * 1000L);
                                        newCase.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_Initial_SLA_Start_Time__c, SLA_75_percent * 60 * 1000L);
                                        newCase.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_Initial_SLA_Start_Time__c, SLAValue * 60 * 1000L);
                                         system.debug(logginglevel.info, '++++ newCase.BusinessHoursId ++' + newCase.BusinessHoursId);
                                         system.debug(logginglevel.info, '++++ newCase.IME_SC_Initial_SLA_Start_Time__c ++' + newCase.IME_SC_Initial_SLA_Start_Time__c);
                                         system.debug(logginglevel.info, '++++ SLAValue ++ '+ SLAValue);
                                         system.debug(logginglevel.info, '++++ SLAValue * 60 * 1000L ++' + SLAValue * 60 * 1000L);
                                        newCase.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_Initial_SLA_Start_Time__c, SLA_125_percent * 60 * 1000L);
                                     }
                                     system.debug(logginglevel.info, '++++++ 5 +++++ IME_SC_End_Time_100_Percent_SLA__c ++' + newCase.IME_SC_End_Time_100_Percent_SLA__c );
                                }
                                else if((((newCase.Status == 'On Hold - Internal') && (IsIMLACase== false))|| (newCase.Status == 'On Hold - Customer')) && newCase.IME_SC_SLA_Hold_Time__c == null)
                                {
                                    newCase.IME_SC_SLA_Hold_Time__c = System.now();
                                    newCase.IME_SC_SLA_Time_Elapsed__c = BusinessHours.diff(newCase.BusinessHoursId,newCase.IME_SC_Initial_SLA_Start_Time__c, newCase.IME_SC_SLA_Hold_Time__c)/60000;
                                    newCase.IME_SC_SLA_Time_Remaining__c = SLAValue - newCase.IME_SC_SLA_Time_Elapsed__c;
                                    newCase.IME_SC_SLA_Trigger_Time__c = null;
                                    newCase.IME_SC_End_Time_50_Percent_SLA__c = null;
                                    newCase.IME_SC_End_Time_75_Percent_SLA__c = null;
                                    newCase.IME_SC_End_Time_100_Percent_SLA__c = null;
                                    newCase.IME_SC_End_Time_125_Percent_SLA__c = null;
                                }
                            
                                //when case is resumed from on hold Status
                                else if(((newCase.Status == 'In Progress') || (newCase.Status == 'Resolved') ||((newCase.Status == 'On Hold - Internal') && (IsIMLACase== true))) && newCase.IME_SC_SLA_Hold_Time__c != null && oldTriggerCaseMap != null
                                          && (!oldTriggerCaseMap.isEmpty())
                                        && (((oldTriggerCaseMap.get(newCase.Id).Status == 'On Hold - Internal' ) && (IsIMLACase== false)) || oldTriggerCaseMap.get(newCase.Id).Status == 'On Hold - Customer'))
                                { 
                                    system.debug('oldTriggerCaseMap.isEmpty():'+ oldTriggerCaseMap.isEmpty() + ' oldTriggerCaseMap.get(newCase.Id).Status:'+ oldTriggerCaseMap.get(newCase.Id).Status + 'newCase.BusinessHoursId: '+ newCase.BusinessHoursId);
                                    newCase.IME_SC_SLA_Resume_Time__c = System.now();
                                    newCase.IME_SC_SLA_Time_Remaining__c = SLAValue - newCase.IME_SC_SLA_Time_Elapsed__c;                        
                                    Integer slaTime = Integer.valueOf(newCase.IME_SC_SLA_Time_Remaining__c);
                                    newCase.IME_SC_SLA_Trigger_Time__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_SLA_Resume_Time__c, slaTime * 60 * 1000L);
                                    newCase.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_SLA_Resume_Time__c, 
                                                                                Long.valueof(String.valueof((SLA_50_Percent * 60 * 1000L)- (newCase.IME_SC_SLA_Time_Elapsed__c*60*1000L))));
                                    newCase.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_SLA_Resume_Time__c,
                                                                                Long.valueof(String.valueof((SLA_75_percent * 60 * 1000L)- (newCase.IME_SC_SLA_Time_Elapsed__c*60*1000L))));
                                    newCase.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_SLA_Resume_Time__c,
                                                                                 slaTime * 60 * 1000L);
                                    newCase.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(newCase.BusinessHoursId, newCase.IME_SC_SLA_Resume_Time__c,
                                                                                 Long.valueof(String.valueof((SLA_125_percent * 60 * 1000L)- (newCase.IME_SC_SLA_Time_Elapsed__c*60*1000L))));
                                    
                                system.debug(logginglevel.info, '++++++ 6 +++++ IME_SC_End_Time_100_Percent_SLA__c ++' + newCase.IME_SC_End_Time_100_Percent_SLA__c  );
                                }
                                
                                //When the case fields other than Status are edited
                                else if(((newCase.Status == 'In Progress') || (newCase.Status == 'Resolved') ||((newCase.Status == 'On Hold - Internal') && (IsIMLACase== true))) && oldTriggerCaseMap!= null && !oldTriggerCaseMap.isEmpty()
                                        && ((oldTriggerCaseMap.get(newCase.Id).Status == 'In Progress')
                                        || (oldTriggerCaseMap.get(newCase.Id).Status == 'Resolved') ||((oldTriggerCaseMap.get(newCase.Id).Status == 'On Hold - Internal') && (IsIMLACase== true))) && newCase.IME_SC_SLA_Hold_Time__c != null)
                                {
                                    if(isSLAActive == true)
                                    {
                                        newCase.IME_SC_SLA_Time_Elapsed__c = newCase.IME_SC_SLA_Time_Elapsed__c + 
                                                                             BusinessHours.diff(newCase.BusinessHoursId,newCase.LastModifiedDate, System.now())/60000;
                                        newCase.IME_SC_SLA_Time_Remaining__c = SLAValue - newCase.IME_SC_SLA_Time_Elapsed__c;
                                        isSLAActive = false;
                                    }
                                    system.debug(logginglevel.info, '++++++ 7 +++++ IME_SC_Initial_SLA_Start_Time__c ++' + newCase.IME_SC_Initial_SLA_Start_Time__c );
                                }
                                //When the case Status is again changed to OnHold from in Progress
                                else if((((newCase.Status == 'On Hold - Internal') && (IsIMLACase== false)) ||  (newCase.Status == 'On Hold - Customer')) && (oldTriggerCaseMap != null) && 
                                        !oldTriggerCaseMap.isEmpty() && (oldTriggerCaseMap.get(newCase.Id).Status == 'In Progress') && newCase.IME_SC_SLA_Resume_Time__c != null)
                                {
                                    newCase.IME_SC_SLA_Hold_Time__c = System.now();
                                    newCase.IME_SC_SLA_Time_Elapsed__c = newCase.IME_SC_SLA_Time_Elapsed__c + 
                                                                         BusinessHours.diff(newCase.BusinessHoursId, /*newCase.IME_SC_SLA_Resume_Time__c*/newCase.LastModifiedDate, newCase.IME_SC_SLA_Hold_Time__c)/60000;
                                    newCase.IME_SC_SLA_Time_Remaining__c = SLAValue - newCase.IME_SC_SLA_Time_Elapsed__c;
                                    
                                    newCase.IME_SC_SLA_Trigger_Time__c = null;
                                    newCase.IME_SC_End_Time_50_Percent_SLA__c = null;
                                    newCase.IME_SC_End_Time_75_Percent_SLA__c = null;
                                    newCase.IME_SC_End_Time_100_Percent_SLA__c = null;
                                    newCase.IME_SC_End_Time_125_Percent_SLA__c = null;
                                    newCase.IME_SC_SLA_Resume_Time__c = null;
                                }
                            }
                            newCase.End_Time_Cutoff_SLA__c = newCase.IME_SC_SLA_Trigger_Time__c;
                            system.debug(logginglevel.info, '++++++ 8 +++++ IME_SC_End_Time_100_Percent_SLA__c ++' + newCase.IME_SC_End_Time_100_Percent_SLA__c );
                        }
                    }
                }
                if(newCase.IME_SC_SLA_Time_Remaining__c <= 0)
                {
                    newCase.IME_SC_SLA_Time_Remaining__c = 0;
                }
            }
            if(oldTriggerCaseMap!= null && !oldTriggerCaseMap.isEmpty() && firstRun != false/*&& newCase.Status != 'New'*/)
            {
                if(newCase.IME_SC_SLA_Missed__c != false)
                {
                    if(((newCase.Status == 'On Hold - Internal') && (IsIMLACase== false)) || (newCase.Status == 'On Hold - Customer') && 
                        oldTriggerCaseMap.get(newCase.Id).Status == 'In Progress')
                    {
                        newCase.IME_SC_SLA_Hold_Time__c = BusinessHours.add(newCase.BusinessHoursId, system.now(), 1000L);
                        if(newCase.IME_SC_SLA_Resume_Time__c != null)
                        {
                            newCase.IME_SC_SLA_Resume_Time__c = null;
                        }
                    }
                    else if((newCase.Status == 'In Progress') && (oldTriggerCaseMap.get(newCase.Id).Status == 'On Hold - Customer' || 
                       (( oldTriggerCaseMap.get(newCase.Id).Status == 'On Hold - Internal') && (IsIMLACase== false))
                       ))
                    {
                        newCase.IME_SC_SLA_Resume_Time__c = BusinessHours.add(newCase.BusinessHoursId, system.now(), 1000L);
                    }
                }
                
                //to calculate total on hold time
                if((newCase.Status == 'In Progress' && ( ((oldTriggerCaseMap.get(newCase.Id).Status == 'On Hold - Internal') && (IsIMLACase== false)) || 
                    oldTriggerCaseMap.get(newCase.Id).Status == 'On Hold - Customer')) &&
                    newCase.IME_SC_SLA_Hold_Time__c != null && newCase.IME_SC_SLA_Resume_Time__c != null && newCase.IME_SC_Total_On_Hold_Time__c != null)
                {
                    newCase.IME_SC_Total_On_Hold_Time__c = newCase.IME_SC_Total_On_Hold_Time__c +
                                                            BusinessHours.diff(newCase.BusinessHoursId,newCase.IME_SC_SLA_Hold_Time__c, newCase.IME_SC_SLA_Resume_Time__c)/60000;                   
                }
                else if((newCase.Status == 'In Progress' && ( ((oldTriggerCaseMap.get(newCase.Id).Status == 'On Hold - Internal') && (IsIMLACase== false))|| 
                        oldTriggerCaseMap.get(newCase.Id).Status == 'On Hold - Customer')) && newCase.IME_SC_SLA_Resume_Time__c != null
                        && newCase.IME_SC_SLA_Hold_Time__c != null && newCase.IME_SC_Total_On_Hold_Time__c == null)
                {
                    newCase.IME_SC_Total_On_Hold_Time__c = BusinessHours.diff(newCase.BusinessHoursId,newCase.IME_SC_SLA_Hold_Time__c, newCase.IME_SC_SLA_Resume_Time__c)/60000;
                }
                firstRun = false;
            }
        }
    }
    
    //SLA selection on the basis of category and subcategory
    public Map<Id, Integer> caseSLASelection(List<Case> newTriggerCaseList)
    {
        system.debug('+++ in case sla selection');
        Map<Id, Integer> caseMapToPass = new Map<Id, Integer>();
        Set<Id> caseBusinessHoursIdSet = new Set<Id>();
        String SLAPeriod;
        Integer SLAValue;
        Boolean calculateSLA;
        Integer endHour;
        Integer endMinute;
        Integer endSecond;
        DateTime SLATime;
        Long totalSLA;
        
        // #11278 starts
		Set<string> setIsIndexingSLACountry= new Set<string> ();
		List<IME_SC_Country_List__C> lstCountryList = IME_SC_Country_List__C.getall().values();
        
        for(IME_SC_Country_List__C cList :lstCountryList ){
            if(cList.Is_Indexing_SLA__c){
                setIsIndexingSLACountry.add(cList.Country_Name__c.toUppercase());
            }
		}
        // #11278 ends
        
        for(Case newCase: newTriggerCaseList)
        {
            businessHoursMap = IRM_SC_UtilityClass.getBusinessHours();
            if(newCase.IME_SC_Cut_Off_Time__c == null)
            {
                if(newCase.IME_SC_Category__c == null && newCase.IME_SC_Sub_Category__c == null && newCase.BusinessHoursId != null && newCase.IME_SC_Rush__c == false)
                {
                   if(newCase.IME_SC_Country__c!=null && setIsIndexingSLACountry.contains(newCase.IME_SC_Country__c.toUppercase())){ // #11278 removed list of countries from if condition and added from custom settings
                        newCase.IME_SC_Category__c = 'Email';
                        newCase.IME_SC_Sub_Category__c = 'Email';
                        calculateSLA = false;
                        newCase.IME_SC_Indexing__C = true;
                    }
                }
                if(newCase.IME_SC_Category__c != null && newCase.IME_SC_Sub_Category__c != null && newCase.BusinessHoursId != null 
                    && newCase.IME_SC_Rush__c == false)
                //else
                {
                    if(!(newCase.IME_SC_Category__c.equalsIgnoreCase('Email')) && !(newCase.IME_SC_Sub_Category__c.equalsIgnoreCase('Email')))
                    {
                        newCase.IME_SC_Indexing__C = false;
                    }
                    for(IME_SC_SLA_Matrix__c customSLA: caseSLATime)
                    {
                        if(newCase.BusinessHoursId != null && (newCase.IME_SC_Country__c).equalsIgnoreCase(customSLA.Country__c) && 
                             (newCase.IME_SC_Category__c).equalsIgnoreCase(customSLA.Category__c) &&
                           (newCase.IME_SC_Sub_Category__c).equalsIgnoreCase(customSLA.Sub_Category__c) && customSLA.Is_SLA_Active__c == true)
                        {
                            system.debug(logginglevel.info, '++++ 263++++ Country in custom settings');   
                            if((customSLA.SLA_Period_Type__c.toLowerCase()).contains('hour'))
                            {
                                if(customSLA.SLA_Value__c >= SLA_VALUE_24_HOURS)
                                {
                                    SLAValue = ((customSLA.SLA_Value__c.divide(24,1)) * (calculateSLAForDays(newCase.BusinessHoursId))).intValue();
                                    system.debug(logginglevel.info, '+++ 269 ++ SLAValue > 24' + SLAValue);
                                }
                                else
                                {
                                    SLAValue = Integer.valueOf(customSLA.SLA_Value__c) * 60;
                                    system.debug(logginglevel.info, '+++ 274 ++ SLAValue not > 24' + SLAValue);
                                }
                                calculateSLA = true;
                            }
                            else if((customSLA.SLA_Period_Type__c.toLowerCase()).contains('minute'))
                            {
                                SLAValue = Integer.valueOf(customSLA.SLA_Value__c);
                                system.debug(logginglevel.info, '+++ 281 ++ SLAValue has minute' + SLAValue);
                                calculateSLA = false;
                            }
                            else if((customSLA.SLA_Period_Type__c.toLowerCase()).contains('rush'))
                            {
                                //newCase.IME_SC_Rush__c = true;
                                calculateSLA = false;
                                //SLAValue = Integer.valueOf(customSLA.SLA_Value__c);
                                break;
                            }
                            else if((customSLA.SLA_Period_Type__c.toLowerCase()).contains('day'))
                            {
                                calculateSLA = true;
                                SLAValue = Integer.valueOf(customSLA.SLA_Value__c) * 
                                          (calculateSLAForDays(newCase.BusinessHoursId));
                                system.debug(logginglevel.info, '+++ 296 ++ SLAValue contains day' + SLAValue);
                            }
                            else if((customSLA.SLA_Period_Type__c.toLowerCase()).contains('month'))
                            {
                                Datetime currentDate;
                                if(newCase.CreatedDate != null)
                                {
                                    currentDate = newCase.CreatedDate;
                                }
                                else
                                {
                                    currentDate = System.now();
                                }
                                calculateSLA = true;
                                Datetime nextDate = currentDate.addMonths(Integer.valueOf(customSLA.SLA_Value__c));
                                Long monthDiff = BusinessHours.diff(newCase.BusinessHoursId, currentDate, nextDate)/60000;
                                SLAValue = Integer.valueOf(String.valueOf(monthDiff));
                                system.debug(logginglevel.info, '+++ 313 ++ SLAValue contains month' + SLAValue);
                            }
                            if(customSLA.Category__c.equalsIgnoreCase('Email') && customSLA.Sub_Category__c.equalsIgnoreCase('Email'))
                            {
                                calculateSLA = false;
                            }
                        }
                        else if(newCase.BusinessHoursId != null && (newCase.IME_SC_Category__c).equalsIgnoreCase('Complaints') 
                                && newCase.IME_SC_Rush__c == false && SLAValue == null)
                        {
                            SLAValue = DEFAULT_COMPLAINTS_SLA * 60;
                            calculateSLA = true;
                            system.debug(logginglevel.info, '+++ 325 ++ SLAValue complaints category' + SLAValue);
                        }
                        else if(newCase.BusinessHoursId != null && newCase.IME_SC_Request_Type__c != null &&
                               (newCase.IME_SC_Request_Type__c).equalsIgnoreCase('Order') && SLAValue == null && newCase.IME_SC_Rush__c == false)
                        {
                            SLAValue = (DEFAULT_ORDER_SLA_DAY) * (calculateSLAForDays(newCase.BusinessHoursId));
                            calculateSLA = true;
                            system.debug(logginglevel.info, '+++ 332 ++ country not in matrix and correct value ' + SLAValue);
                        }
                        else if(SLAValue == null && newCase.IME_SC_Category__c != null)
                        {
                            Datetime todaysDate = BusinessHours.add(newCase.BusinessHoursId , System.now(), 1000L);
                            system.debug(logginglevel.info, '+++ 351 ++ todaysDate' + todaysDate);
                            Datetime caseCreatedDate;
                            Integer todaysMonth = todaysDate.month();
                            Integer todaysYear = todaysDate.year();
                            Integer todaysDay= todaysDate.day();
                            Integer todaysHour = todaysDate.hour();
                            Integer todaysMinute =  todaysDate.minute();
                            String dayof = todaysDate.format('EEE');
                            Time dayEnd = IRM_SC_CaseTriggerClass.endTimeBH(dayof, businessHoursMap.get(newCase.BusinessHoursId));
                            system.debug(logginglevel.info, '+++ 351 ++ businessHoursMap' + businessHoursMap);
                            system.debug(logginglevel.info, '+++ 351 ++ businessHoursMap.get(newCase.BusinessHoursId)' + businessHoursMap.get(newCase.BusinessHoursId));
                            system.debug(logginglevel.info, '+++ 351 ++ dayEnd' + dayEnd);
                            
                            if(dayEnd!= null) 
                            {          
                                endHour  = dayEnd.hour();
                                endMinute  = dayEnd.minute();
                                endSecond  = dayEnd.second();
                                SLATime = Datetime.newInstance(todaysYear, todaysMonth, todaysDay, endHour, endMinute, endSecond);
                                system.debug(logginglevel.info, 'date time is +++ '+ todaysYear+' +++ '+ todaysMonth+' +++ '+ todaysDay+' +++ '+ endHour+' +++ '+endMinute+' +++ '+ endSecond);
                                system.debug(logginglevel.info, '+++ 352 ++ sla time' + SLATime);
                            }
                            try{
                                    caseCreatedDate = BusinessHours.add(newCase.BusinessHoursId, newCase.CreatedDate, 1000L);
                                    system.debug(logginglevel.info, '+++ 362 try ++ caseCreatedDate' + caseCreatedDate);
                               }
                            catch(System.Nullpointerexception NE)
                            {
                                caseCreatedDate = BusinessHours.add(newCase.BusinessHoursId, system.now(), 1000L);
                                system.debug(logginglevel.info, '+++ 367 catch ++ caseCreatedDate' + caseCreatedDate);
                            }
                            if(SLATime != null)
                            {
                                totalSLA = BusinessHours.diff(newCase.BusinessHoursId, caseCreatedDate, SLATime)/60000;
                                system.debug(logginglevel.info, '+++ 372 ++ totalSLA' + totalSLA);
                                SLAValue = Integer.valueOf(String.valueOf(totalSLA));
                                calculateSLA = true;
                                system.debug(logginglevel.info, '+++ 366 ++ sla value not null' + SLAValue);
                            }
                            else
                            {
                                SLAValue = null;
                                calculateSLA = false;
                            }
                        }
                    }
                    if((newCase.IME_SC_Category__c == 'Email') && (newCase.IME_SC_Sub_Category__c == 'Email'))
                    {
                        newCase.IME_SC_Category__c = null;
                        newCase.IME_SC_Sub_Category__c = null;
                    }
                }
            }
            calculateSLAMap.put(newCase.Id, calculateSLA);
            caseMapToPass.put(newCase.Id, SLAValue);
        }
        return caseMapToPass;
    }
    
    //calculate 50%, 75%, 125% SLA
    private void SLACalculation(Integer calculatedSLA, Boolean calculateSLA)
    {
        if(calculateSLA == true)
        {
            calculate_50_Percent = String.valueOf((0.5 * calculatedSLA).intValue());
            SLA_50_percent =  Integer.valueof(calculate_50_Percent);
            calculate_75_Percent = String.valueOf((0.75 * calculatedSLA).intValue());
            SLA_75_percent = Integer.valueof(calculate_75_Percent);
            calculate_125_Percent = String.valueOf((1.25 * calculatedSLA).intValue());
            SLA_125_percent = Integer.valueof(calculate_125_Percent);
        }
    }
    
    //calculate SLA value in minutes for 24 hours
    private Integer calculateSLAForDays(Id caseBusinessHourId)
    {
        BusinessHours caseBusinessHour = businessHoursMap.get(caseBusinessHourId);
        Integer SLAValueHour;
        Integer SLAValueMinute;
        Integer value;
        if(caseBusinessHour != null)
        {
            SLAValueHour = (caseBusinessHour.MondayEndTime.hour() - caseBusinessHour.MondayStartTime.hour());
            SLAValueMinute = (caseBusinessHour.MondayEndTime.minute() - caseBusinessHour.MondayStartTime.minute());
            value = SLAValueMinute + (SLAValueHour * 60);
        }
        else{
            value = 0;
        }
        return value;
    }
}
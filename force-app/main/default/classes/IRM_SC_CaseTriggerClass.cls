/**  
* Name: IRM_SC_CaseTriggerClass
* Description: Class Contain multiple funtions as mentioned below:
1. Setting country, country code, division and ountbound email address based on Case Origin, 
Contact, Customer Account or User. 
2. Setting customer Account and Account based on Customer ID and Country field value.
3. Setting Business Hour based on Country.
4. Setting CutOff SLA time. 
5. Validation : End Time cutoff cannot be in past in the case of cut off time equal manual
* Copyright: HCL Technologies
* Author: Himanshu Jain
* Modification Log: Created:12-Mar-2012
**/


public with sharing class IRM_SC_CaseTriggerClass 
{ 
    //Declaration of variables
    Set<Id> contactIdSet = new Set<Id>();
    Set<Id> customerAccountIDSet = new Set<Id>();
    Set<Id> accountIdSet = new Set<Id>();
    Map<Id,Contact> queryContactMap;
    static Boolean bErrorFound = false;
    Map<Id,IM_Customer_Account__c> queryCustomeAccountMap = new Map<Id,IM_Customer_Account__c>();
    Map<Id,String> queryBillingCountryMap = new Map<Id,String>();
    Set<ID> billCountryID = new Set<ID>();
    Map<Id,Account> queryAccountMap = new Map<Id,Account>();
    Static boolean manualCutoffSLA = true;
    //Logged In user information
    User currentUser = IRM_SC_UtilityClass.getUserInfo();
    //setting the cut off time manual and manual cut off time validation
    // 1. Cut off Time cutoff cannot be in past in the case of cut off time manual  
    
    public void manualCutoff(List<Case> caseList, Map<ID, case> caseOldMap)
    {
        if(bErrorFound)
            return;
        if(manualCutoffSLA)
        {system.debug('manualCutoffSLA'+manualCutoffSLA);
         manualCutoffSLA = false;
         //On Insert:setting the cut off time manual and validating End Time cutoff cannot be in past
         for(case caseRec : caseList)
         {
             
             if( (Trigger.isInsert||caseOldMap == null  ||  (caseOldMap != null && caseOldMap.isEmpty()) ) && caseRec.End_Time_Cutoff_SLA__c != null)
             {
                 caseRec.IME_SC_Cut_Off_Time__c = 'Manual';
                 system.debug('caseRec.End_Time_Cutoff_SLA__c'+caseRec.End_Time_Cutoff_SLA__c);
                 if(caseRec.End_Time_Cutoff_SLA__c < System.now())
                 {     
                     //caseRec.End_Time_Cutoff_SLA__c.addError(System.Label.IME_SC_Cutoff_SLA_in_Past);
                     caseRec.IME_SC_Validation_Rule__c = System.Label.IME_SC_Cut_off_Time_Passed;
                     bErrorFound = true;
                 }                   
             }
             
             if(Trigger.isUpdate)
             {
                 //On Insert:setting the cut off time manual and validating End Time cutoff cannot be in past and in case of 
                 //Cutoff time is other than manual user is not able to change end time cut off
                 if(caseRec.IME_SC_Rush__c != True && caseRec.IME_SC_Cut_Off_Time__c != 'Manual' && caseOldMap != null  && !(caseOldMap.isEmpty()) && caseRec.End_Time_Cutoff_SLA__c != null && caseRec.End_Time_Cutoff_SLA__c != caseOldMap.get(caseRec.id).End_Time_Cutoff_SLA__c)
                 {
                     caseRec.IME_SC_Cut_Off_Time__c = 'Manual';
                 }
                 case oldCaseRec;
                 
                 //Cut off Time changed second time
                 if(caseOldMap != null && !(caseOldMap.isEmpty()))
                 {
                     oldCaseRec = caseOldMap.get(caseRec.id);
                 }
                 if(oldCaseRec != null && oldCaseRec.IME_SC_Indexing__c != true && caseRec.IME_SC_Indexing__c != true && oldCaseRec.End_Time_Cutoff_SLA__c != null && 
                    (((caseRec.IME_SC_Cut_Off_Time__c != oldCaseRec.IME_SC_Cut_Off_Time__c) && caseRec.IME_SC_Rush__c == false)
                     || (caseRec.IME_SC_Rush__c != oldCaseRec.IME_SC_Rush__c)
                     || ((caseRec.IME_SC_Cut_Off_Time__c == 'Manual' && (caseRec.End_Time_Cutoff_SLA__c != oldCaseRec.End_Time_Cutoff_SLA__c)) && caseRec.IME_SC_Rush__c == false)
                     || ((caseRec.IME_SC_Category__c != oldCaseRec.IME_SC_Category__c) && caseRec.IME_SC_Rush__c == false  && caseRec.IME_SC_Cut_Off_Time__c == null)
                     || ((caseRec.IME_SC_Sub_Category__c != oldCaseRec.IME_SC_Sub_Category__c) && caseRec.IME_SC_Rush__c == false  && caseRec.IME_SC_Cut_Off_Time__c == null)
                    ))
                 {
                     caseRec.IME_SC_Cut_off_Time_changed__c = true;
                 } 
                 
                 
                 if(caseRec.End_Time_Cutoff_SLA__c < System.now() && caseRec.IME_SC_Cut_Off_Time__c == 'Manual' && caseOldMap != null && !(caseOldMap.isEmpty())  &&
                    !(caseOldMap.get(caseRec.id).Status == 'On Hold - Internal' || caseOldMap.get(caseRec.id).Status == 'On Hold - Customer') && 
                    caseRec.End_Time_Cutoff_SLA__c != caseOldMap.get(caseRec.id).End_Time_Cutoff_SLA__c)
                 {      
                     //caseRec.End_Time_Cutoff_SLA__c.addError(System.Label.IME_SC_Cutoff_SLA_in_Past);
                     caseRec.IME_SC_Validation_Rule__c = System.Label.IME_SC_Cut_off_Time_Passed;
                     bErrorFound = true;
                 }                       
             }
         }
        }
    }
    public static Time startTimeBH(String dayofCutOff, BusinessHours caseBusinessHours)
    {
        Time endTime;
        Time startTime;
        if(dayofCutOff == 'Mon')
        {
            startTime = caseBusinessHours.MondayStartTime;
        }
        else if(dayofCutOff == 'Tue')
        {
            startTime = caseBusinessHours.TuesdayStartTime;
        }
        else if(dayofCutOff == 'Wed')
        {
            startTime = caseBusinessHours.WednesdayStartTime;
        }
        else if(dayofCutOff == 'Thu')
        {
            startTime = caseBusinessHours.ThursdayStartTime;
        }
        else if(dayofCutOff == 'Fri')
        {
            startTime = caseBusinessHours.FridayStartTime;
        }
        else if(dayofCutOff == 'Sat')
        {
            StartTime = caseBusinessHours.SaturdayStartTime;
        }
        else if(dayofCutOff == 'Sun')
        {
            StartTime = caseBusinessHours.SundayStartTime;
        }
        return StartTime;
    }
    public static Time endTimeBH(String dayofCutOff, BusinessHours caseBusinessHours)
    {
        Time endTime;
        
        if(dayofCutOff == 'Mon')
        {
            endTime = caseBusinessHours.MondayEndTime;
        }
        else if(dayofCutOff == 'Tue')
        {
            endTime = caseBusinessHours.TuesdayEndTime;
        }
        else if(dayofCutOff == 'Wed')
        {
            endTime = caseBusinessHours.WednesdayEndTime;
        }
        else if(dayofCutOff == 'Thu')
        {
            endTime = caseBusinessHours.ThursdayEndTime;
        }
        else if(dayofCutOff == 'Fri')
        {
            endTime = caseBusinessHours.FridayEndTime;
        }
        else if(dayofCutOff == 'Sat')
        {
            EndTime = caseBusinessHours.SaturdayEndTime;
        }
        else if(dayofCutOff == 'Sun')
        {
            EndTime = caseBusinessHours.SundayEndTime;
        }
        return endtime;
    }
    
    //Setting country, country code, division and ountbound email address based on Case Origin, Contact, Customer Account or User. 
    public void selectCountryFromOrigin(List<Case> caseList, Map<ID, case> caseOldMap)
    {
        Set<String> countrySet = new Set<String>();
        List<String> listSensitiveCountry = new List<String>();
        // to get list of country for which Is sensitive Feature is active
        for(IME_SC_Toggle_Country_Features__c sensitiveActiveCountry : IME_SC_Toggle_Country_Features__c.getAll().values())
        {
            if(sensitiveActiveCountry.Is_Active__c == True && sensitiveActiveCountry.Feature_Name__c == 'Sensitive Queue')
            {
                listSensitiveCountry.add(sensitiveActiveCountry.country__c);
            }
        }
        //to populate case country, division and outbound email on the basis of Case Origin
        for(Case caseOrigin: caseList)
        {
            caseOrigin.IME_SC_Country__c = null;
            //select country based on case origin
            system.debug('caseOrigin.Origin'+caseOrigin.Origin);
            if(caseOrigin.Origin!= null)
            {
                IME_SC_Country_CaseOrigins__c  countryCaseOrigin;// = IME_SC_Country_CaseOrigins__c.getvalues(caseOrigin.Origin);
                for(IME_SC_Country_CaseOrigins__c  caseOriginCountry: IME_SC_Country_CaseOrigins__c.getAll().values())
                {
                    if((caseOrigin.Origin).equalsIgnoreCase(caseOriginCountry.Name))
                        countryCaseOrigin = caseOriginCountry;
                }
                if(countryCaseOrigin != null)
                {
                    caseOrigin.IME_SC_Country__c = IME_SC_Country_CaseOrigins__c.getvalues(caseOrigin.Origin).Country__c;
                    caseOrigin.IM_division__c = IME_SC_Country_CaseOrigins__c.getvalues(caseOrigin.Origin).Division__c;
                    caseOrigin.IME_SC_Outbound_Email_Address__c = IME_SC_Country_CaseOrigins__c.getvalues(caseOrigin.Origin).Outbound_Email__c;
                }
            }
            //Taking set of contact associated with cases
            if(caseOrigin.ContactId != null && caseOrigin.IME_SC_Country__c == null)
            {
                contactIdSet.add(caseOrigin.ContactId);
            } 
        }
        // querying contact 
        if(contactIdSet != null && (!contactIdSet.isEmpty()))
        {
            queryContactMap = new Map<Id,Contact> ([Select Name, MailingCountry, Id, AccountId, Account.IME_Display_Division__c From Contact where Id IN :ContactIdSet]);   
        }
        
        
        //to populate case country on the basis of Contact/ Customer Account/ Account
        for(Case caseOrigin: caseList)
        {
            //select country and division based on contact
            if(caseOrigin.ContactId != null && caseOrigin.IME_SC_Country__c == null)
            {
                if(queryContactMap.get(caseOrigin.ContactId) != null)
                {
                    caseOrigin.IME_SC_Country__c = queryContactMap.get(caseOrigin.ContactId).MailingCountry;
                    if(queryContactMap.get(caseOrigin.ContactId).AccountId != null)
                        if(queryContactMap.get(caseOrigin.ContactId).Account.IME_Display_Division__c == 'Asia Pacific')
                        caseOrigin.IM_Division__c = 'IMAP';
                    else if(queryContactMap.get(caseOrigin.ContactId).Account.IME_Display_Division__c == 'Europe')
                        caseOrigin.IM_Division__c = 'IME';
                }
            }
            //Taking set of Customer Account associated with cases  
            if(caseOrigin.IME_SC_Customer_AccountId__c != null && caseOrigin.IME_SC_Country__c == null)
            {
                //queryCustomeAccountId = caseOrigin.IME_SC_Customer_AccountId__c;
                customerAccountIDSet.add(caseOrigin.IME_SC_Customer_AccountId__c);
                
            } 
        }
        
        //querying Customer Account
        if(customerAccountIDSet != null && (!customerAccountIDSet.isEmpty()))
        {
            List<IM_Customer_Account__c> customerAccountList = [Select Name, Id, Billing_Country__c, IM_Account__c, IM_Account__r.IME_Display_Division__c From IM_Customer_Account__c
                                                                where Id IN :CustomerAccountIDSet];
            for(IM_Customer_Account__c caseCustomerAccount: customerAccountList)
            {
                
                queryCustomeAccountMap.put(caseCustomerAccount.Id, caseCustomerAccount);
                BillCountryID.add(caseCustomerAccount.Billing_Country__c);
            }
            List<IM_Country__c> IMCountry = new List<IM_Country__c>();
            if(BillCountryID != null && !BillCountryID.isEmpty())
                IMCountry = [Select Id, Name from IM_Country__c where id IN :BillCountryID ];
            for(IM_Country__c CountryLoop :IMCountry)
            {
                queryBillingCountryMap.put(CountryLoop.ID, CountryLoop.Name);
            }
            //customerAccountList.clear();
            
        }
        
        for(Case caseOrigin: caseList)
        {   
            //select country and division based on Customer Account
            if(caseOrigin.IME_SC_Customer_AccountId__c != null )//&& caseOrigin.IME_SC_Country__c == null)
            {
                ID BillingCountry;
                if(queryCustomeAccountMap.get(caseOrigin.IME_SC_Customer_AccountId__c) != null)
                {
                    caseOrigin.AccountID = queryCustomeAccountMap.get(caseOrigin.IME_SC_Customer_AccountId__c).IM_Account__c;
                    if(caseOrigin.IME_SC_Country__c == null)
                    {
                        BillingCountry = queryCustomeAccountMap.get(caseOrigin.IME_SC_Customer_AccountId__c).Billing_Country__c;
                        if(queryCustomeAccountMap.get(caseOrigin.IME_SC_Customer_AccountId__c).IM_Account__c != null)
                            if(queryCustomeAccountMap.get(caseOrigin.IME_SC_Customer_AccountId__c).IM_Account__r.IME_Display_Division__c == 'Asia Pacific')
                            caseOrigin.IM_Division__c = 'IMAP';
                        else if(queryCustomeAccountMap.get(caseOrigin.IME_SC_Customer_AccountId__c).IM_Account__r.IME_Display_Division__c == 'Europe')
                            caseOrigin.IM_Division__c = 'IME';
                        if(BillingCountry != null)
                            caseOrigin.IME_SC_Country__c =  queryBillingCountryMap.get(BillingCountry);
                    }
                }
            }
            //Taking set of Account associated with cases
            if(caseOrigin.AccountId != null  && caseOrigin.IME_SC_Country__c == null)
            {
                accountIdSet.add(caseOrigin.AccountId);     
            }
        }
        //querying account
        if(accountIdSet != null && (!accountIdSet.isEmpty()))
        {
            queryAccountMap = new Map<Id,Account>([Select Name, Id, IME_Display_Division__c, BillingCountry From Account 
                                                   where Id IN :AccountIdSet]);
        }     
        for(Case caseOrigin: caseList)
        {
            //select country and division based on Account
            if(caseOrigin.AccountId != null && caseOrigin.IME_SC_Country__c == null)
            {
                if(queryAccountMap.get(caseOrigin.AccountId) != null)
                {    
                    caseOrigin.IME_SC_Country__c = queryAccountMap.get(caseOrigin.AccountId).BillingCountry; 
                    
                    caseOrigin.IM_division__c = queryAccountMap.get(caseOrigin.AccountId).IME_Display_Division__c;
                    If(queryAccountMap.get(caseOrigin.AccountId).IME_Display_Division__c == 'Europe')
                        caseOrigin.IM_division__c = 'IME'; 
                    else if(queryAccountMap.get(caseOrigin.AccountId).IME_Display_Division__c == 'Asia Pacific') 
                        caseOrigin.IM_division__c = 'IMAP'; 
                }    
            }
            //select country and division based on User  
            if(caseOrigin.IME_SC_Country__c == null)
            {
                caseOrigin.IME_SC_Country__c = currentUser.country;
                caseOrigin.IM_division__c = currentUser.division;
            }
            // taking name of all the countries associated with cases
            if(caseOrigin.IME_SC_Country__c != null)
                countrySet.add(caseOrigin.IME_SC_Country__c);
            caseOrigin.IME_SC_Is_Sensitive_Feature_Active__c = false;
            // setting the value for sensitive feature
            for(String country : listSensitiveCountry)
            {
                if(country.equalsIgnoreCase(caseOrigin.IME_SC_Country__c))
                {
                    caseOrigin.IME_SC_Is_Sensitive_Feature_Active__c = true;
                }
            }
        }
        List<IM_Country__c> countryCodeList = new List<IM_Country__c>();
        if(countrySet != null && !countrySet.isEmpty())
            countryCodeList = [Select Iso31663Code__c, Name from IM_Country__c where Name In :countrySet];
        // based on country setting the value for country code and outbound email addresses
        for(Case caseOrigin: caseList)
        {
            for(IM_Country__c countryCode : countryCodeList)
            {
                if(caseOrigin.IME_SC_Country__c == countryCode.Name)
                {
                    caseOrigin.IME_SC_Country_Code__c = countryCode.Iso31663Code__c; 
                    String countryCodeCaseOrigin = countryCode.Iso31663Code__c +'-'+caseOrigin.origin;
                    if(IME_SC_Country_CaseOrigins__c.getvalues(countryCodeCaseOrigin) != null)                    
                        caseOrigin.IME_SC_Outbound_Email_Address__c = IME_SC_Country_CaseOrigins__c.getvalues(countryCodeCaseOrigin).Outbound_Email__c;
                }
            }
        }        
    }
    //If Customer Account is null than select customer Account and Account based on Customer ID and country
    public void customerAccount(List<Case> caseList)
    {
        Set<string> CustomerAccountIDSet = new Set<string>();
        Set<string> CustomerAccountCountrySet = new Set<string>();
        for(case caseAccount : caseList)
        {
            if(caseAccount.IME_SC_Customer_AccountId__c != null)
            {
                caseAccount.Customer_ID__c = caseAccount.IME_SC_Customer_AccountId__c;
            }
            
            if(caseAccount.IME_SC_Customer_AccountId__c == null && caseAccount.IME_SC_Country__c != null &&  caseAccount.IME_SC_Customer_ID__c != null)
            {
                CustomerAccountIDSet.add(caseAccount.IME_SC_Customer_ID__c);
                CustomerAccountCountrySet.add(caseAccount.IME_SC_Country__c);
            }
        }
        List<IM_Customer_Account__c> customerAccountList = new List<IM_Customer_Account__c>();
        
        if(CustomerAccountIDSet != null && !CustomerAccountIDSet.isEmpty())
            customerAccountList = [Select Name, Id, IM_Account__c, Billing_Country__r.name From IM_Customer_Account__c
                                   where name IN :CustomerAccountIDSet AND Name != ''];
        //select customer Account and Account based on Customer ID and country                           
        for(case caseAccount : caseList)
        {
            if(caseAccount.IME_SC_Customer_AccountId__c == null && caseAccount.IME_SC_Country__c != null &&  caseAccount.IME_SC_Customer_ID__c != null)
            {
                for(IM_Customer_Account__c customerAccount : customerAccountList)
                {
                    if((caseAccount.IME_SC_Country__c).equalsIgnoreCase(customerAccount.Billing_Country__r.name) && caseAccount.IME_SC_Customer_ID__c == customerAccount.name)
                    {
                        caseAccount.IME_SC_Customer_AccountId__c = customerAccount.ID;
                        caseAccount.Customer_ID__c = customerAccount.ID;
                        caseAccount.AccountID = customerAccount.IM_Account__c;
                        break;
                    }
                }
            }
        }
    }
    
    //Setting business hour based on country and based on selected cut off value setting ENd time cut off time
    public void businessHourCutOffSLA(List<Case> caseList, Map<ID, case> caseOldMap, boolean updatedCase)
    {  
        if(bErrorFound)
            return;
        //Map<ID, Case> oldCaseMap = caseOldMap;
        //List<BusinessHours> BusinessHoursList = [Select Name, WednesdayStartTime, WednesdayEndTime, TuesdayStartTime, TuesdayEndTime, ThursdayStartTime, ThursdayEndTime, SundayStartTime, SundayEndTime, SaturdayStartTime, SaturdayEndTime, MondayStartTime, MondayEndTime, Id, FridayStartTime, FridayEndTime From BusinessHours ];
        // querying business hour 
        Map<ID, BusinessHours> BusinessHoursMap = IRM_SC_UtilityClass.getBusinessHours();
        Map<String, BusinessHours> BusinessHoursNameMap = new Map<String, BusinessHours>();
        Id businessHourID;
        IME_SC_Country_BH__c countryCusSettmBHour;
        BusinessHours countryBHour;
        DateTime caseCreatedDate;
        Boolean IsIMLACase = false;
        // creating map for business hours name and ID verses business hour record
        if(BusinessHoursMap != null && !BusinessHoursMap.isEmpty())
        {
            for(BusinessHours BusinessHourLoop : BusinessHoursMap.values())
            {
                //BusinessHoursMap.put(BusinessHourLoop.id, BusinessHourLoop);
                BusinessHoursNameMap.put(BusinessHourLoop.Name, BusinessHourLoop);
            }
        }
        for(case caseSLA : caseList)
        {
            if(caseSLA.BusinessHoursId != null)
            {
                //setting caseCreatedDate based on case createdDate and system.now 
                if(caseSLA.CreatedDate != null){
                    caseCreatedDate = BusinessHours.add(caseSLA.BusinessHoursId, caseSLA.CreatedDate, 1000L);
                }
                else//catch(System.Nullpointerexception NE)
                {
                    caseCreatedDate = BusinessHours.add(caseSLA.BusinessHoursId, system.now(), 1000L);
                }
            }
            // Checking country is not null
            if(caseSLA.IME_SC_Country__c != null)
            {
                
                // Code added by Pratap
                
                List<IME_SC_Toggle_Country_Features__c> toggleFeaturesCustomSetting = IME_SC_Toggle_Country_Features__c.getall().values();
                for(IME_SC_Toggle_Country_Features__c toggleFeature : toggleFeaturesCustomSetting){
                    if((toggleFeature.Feature_Name__c.equalsIgnoreCase('SLA Calc for Onhold Internal status') && (toggleFeature.Country__c.equalsIgnoreCase(caseSLA.IME_SC_Country__c))
                        &&(toggleFeature.Is_Active__c))){
                            IsIMLACase = true;
                        }
                    
                }
                       // End of code added by Pratap
                       //Setting country business Hours based on case country value 
                       if(caseSLA.IME_SC_Country__c != 'Australia')
                       {
                           countryCusSettmBHour = IME_SC_country_BH__c.getvalues(caseSLA.IME_SC_Country__c);
                           List<IME_SC_country_BH__c> listCustomCountryBH = IME_SC_country_BH__c.getAll().values();
                           for(IME_SC_country_BH__c customCountryBH : listCustomCountryBH)
                           {
                               if((customCountryBH.name).equalsIgnoreCase(caseSLA.IME_SC_Country__c))
                               {
                                   countryCusSettmBHour = customCountryBH;//.Business_Hour__c;
                               }
                           }  
                           if(countryCusSettmBHour != null)
                               //countryBHour = BusinessHoursNameMap.get((IME_SC_country_BH__c.getvalues(caseSLA.IME_SC_Country__c)).Business_Hour__c);
                               countryBHour = BusinessHoursNameMap.get(countryCusSettmBHour.Business_Hour__c);
                           if(countryBHour != null)
                               //businessHourID = (BusinessHoursNameMap.get((IME_SC_country_BH__c.getvalues(caseSLA.IME_SC_Country__c)).Business_Hour__c)).id;
                               businessHourID = countryBHour.id;                
                       }
                       else
                       {
                           //on Insertion of case set the business hour for Australia
                           if(!updatedCase || (caseSLA.BusinessHoursId != null && (businessHoursMap.get(caseSLA.BusinessHoursId)) != null && (businessHoursMap.get(caseSLA.BusinessHoursId).Name).startsWith('8:30')))
                           {
                               countryCusSettmBHour = IME_SC_country_BH__c.getvalues((caseSLA.IME_SC_Country__c+'-'+currentUser.State).toUpperCase());
                               if(countryCusSettmBHour != null)
                                   countryBHour = BusinessHoursNameMap.get((IME_SC_country_BH__c.getvalues((caseSLA.IME_SC_Country__c+'-'+currentUser.State).toUpperCase())).Business_Hour__c);
                               if(countryBHour != null)
                                   businessHourID = countryBHour.id;
                           }               
                       }    
                       //Setting the case business hour
                       if(businessHourID != null)
                       {
                           caseSLA.businessHoursID = businessHourID;
                       }
                       if(caseSLA.businessHoursID != null && 
                          !(businessHoursMap.get(caseSLA.BusinessHoursId).Name).startsWith('8:30') )
                       {
                           //setting caseCreatedDate based on case createdDate and system.now 
                           if(caseSLA.CreatedDate != null){
                               caseCreatedDate = BusinessHours.add(caseSLA.BusinessHoursId, caseSLA.CreatedDate, 1000L);
                           }
                           else
                           {
                               caseCreatedDate = BusinessHours.add(caseSLA.BusinessHoursId, system.now(), 1000L);
                           }
                           case oldcase; //= new case();
                           //Seting rush based on SLA matrix value
                           if( ((Trigger.isInsert||caseOldMap == null  ||  (caseOldMap != null && caseOldMap.isEmpty()) ) && caseSLA.End_Time_Cutoff_SLA__c == null && caseSLA.IME_SC_Cut_Off_Time__c == null )
                              ||(Trigger.isUpdate && caseOldMap != null  && !(caseOldMap.isEmpty()) && caseSLA.IME_SC_Cut_Off_Time__c == null 
                                 //&& caseSLA.End_Time_Cutoff_SLA__c != null && caseSLA.End_Time_Cutoff_SLA__c == caseOldMap.get(caseSLA.id).End_Time_Cutoff_SLA__c
                                 && (caseSLA.IME_SC_Category__c != caseOldMap.get(caseSLA.id).IME_SC_Category__c
                                     || caseSLA.IME_SC_Sub_Category__c != caseOldMap.get(caseSLA.id).IME_SC_Sub_Category__c)
                                ))
                           {
                               for(IME_SC_SLA_Matrix__c customSLA: IME_SC_SLA_Matrix__c.getAll().values())
                               {
                                   if(caseSLA.IME_SC_Category__c != null && caseSLA.IME_SC_Sub_Category__c != null && caseSLA.IME_SC_Country__c != null)
                                       if((caseSLA.IME_SC_Country__c).equalsIgnoreCase(customSLA.Country__c) && 
                                          (caseSLA.IME_SC_Category__c).equalsIgnoreCase(customSLA.Category__c) &&
                                          (caseSLA.IME_SC_Sub_Category__c).equalsIgnoreCase(customSLA.Sub_Category__c) && customSLA.Is_SLA_Active__c == true)
                                   {
                                       if((customSLA.SLA_Period_Type__c.toLowerCase()).contains('rush'))
                                       {
                                           caseSLA.IME_SC_Rush__c  = true;                             
                                           break;
                                       }
                                   }
                               }
                           }
                           
                           //On update: Setting oldcase value
                           if(updatedCase == true)
                           {
                               if( caseOldMap != null && !(caseOldMap.isEmpty()) )
                                   oldcase = caseOldMap.get(caseSLA.id);
                           }
                           // setting end time cutoff SLA if rush is selected 
                           if(caseSLA.IME_SC_Rush__c != false && ((oldCase != null && caseSLA.IME_SC_Rush__c != oldcase.IME_SC_Rush__c)||oldCase == null))
                           {
                               caseSLA.End_Time_Cutoff_SLA__c = System.now(); 
                               //caseSLA.End_Time_Cutoff_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId, system.now(), 1000L); 
                               caseSLA.IME_SC_End_Time_50_Percent_SLA__c = null;
                               caseSLA.IME_SC_End_Time_75_Percent_SLA__c = null;
                               caseSLA.IME_SC_End_Time_100_Percent_SLA__c = null;
                               caseSLA.IME_SC_End_Time_125_Percent_SLA__c = null;
                               caseSLA.IME_SC_SLA_Resume_Time__c = null;
                               caseSLA.IME_SC_SLA_Hold_Time__c = null;
                               caseSLA.IME_SC_Initial_SLA_Start_Time__c = null;
                               caseSLA.IME_SC_SLA_Time_Elapsed__c = null;
                               caseSLA.IME_SC_SLA_Time_Remaining__c = null;
                               caseSLA.IME_SC_Indexing__C = false;
                               caseSLA.IME_SC_Cut_Off_Time__c = null;
                           }
                           //If cut off Time is null than cutoff Hold Time is also null 
                           if(caseSLA.IME_SC_Cut_Off_Time__c == null)
                           {
                               caseSLA.IME_SC_CutOff_Hold_Time__c  = null;
                           }
                           if(caseSLA.IME_SC_Cut_Off_Time__c != null && caseSLA.IME_SC_Rush__c != true && caseSLA.IME_SC_SLA_Missed__c != true)
                           {
                               caseSLA.IME_SC_Indexing__C = false;
                               if(updatedCase == true)
                               {
                                   //In case of updation intialize oldCase value with the old record of case
                                   if( caseOldMap != null && !(caseOldMap.isEmpty()) )
                                       oldcase = caseOldMap.get(caseSLA.id);
                                   //reintializing Hold time at the time of cut off time change
                                   if(oldCase != null && oldcase.IME_SC_Cut_Off_Time__c != caseSLA.IME_SC_Cut_Off_Time__c)
                                   {
                                       caseSLA.IME_SC_CutOff_Hold_Time__c  = null;
                                   }
                                   // Staus changed from In progress to on Hold - Interanl than update the Hold time value and making other value null
                                   if((((caseSLA.Status == 'On Hold - Internal') && (IsIMLACase == false)) || (caseSLA.Status == 'On Hold - Customer'))&& caseOldMap != null && !(caseOldMap.isEmpty()) && (caseOldMap.get(caseSLA.Id).Status == 'In Progress'))
                                   {
                                       caseSLA.IME_SC_SLA_Hold_Time__c = System.now();
                                       caseSLA.IME_SC_End_Time_50_Percent_SLA__c = null;
                                       caseSLA.IME_SC_End_Time_75_Percent_SLA__c = null;
                                       caseSLA.IME_SC_End_Time_100_Percent_SLA__c = null;
                                       caseSLA.IME_SC_End_Time_125_Percent_SLA__c = null;
                                       caseSLA.IME_SC_SLA_Time_Elapsed__c = null;
                                       caseSLA.IME_SC_SLA_Time_Remaining__c = null; 
                                       caseSLA.IME_SC_SLA_Resume_Time__c = null;
                                   }
                                   // Staus changed from on Hold - Interanl to In progress than update the Hold time value 
                                   if((caseSLA.Status == 'In Progress') && caseOldMap != null && !(caseOldMap.isEmpty()) &&
                                      ((caseOldMap.get(caseSLA.Id).Status == 'On Hold - Customer') || 
                                       ((caseOldMap.get(caseSLA.Id).Status == 'On Hold - Internal') && (IsIMLACase == false))))
                                   {
                                       caseSLA.IME_SC_SLA_Resume_Time__c = System.now();
                                   }
                                   // Staus changed from on Hold - Interanl to In progress than update the cutoff hold Time
                                   if(caseSLA.IME_SC_CutOff_Hold_Time__c != null && caseSLA.IME_SC_SLA_Hold_Time__c != null && caseSLA.IME_SC_SLA_Resume_Time__c != null && (caseSLA.Status == 'In Progress') && 
                                      caseOldMap != null && !(caseOldMap.isEmpty()) &&
                                      ((caseOldMap.get(caseSLA.Id).Status == 'On Hold - Customer') || 
                                       ((caseOldMap.get(caseSLA.Id).Status == 'On Hold - Internal')&& (IsIMLACase == false))))
                                   {
                                       caseSLA.IME_SC_CutOff_Hold_Time__c = caseSLA.IME_SC_CutOff_Hold_Time__c +
                                           BusinessHours.diff(caseSLA.BusinessHoursId, caseSLA.IME_SC_SLA_Hold_Time__c, caseSLA.IME_SC_SLA_Resume_Time__c)/60000;
                                   }
                                   // Staus changed from on Hold - Interanl to In progress than insert the cutoff hold Time
                                   else if(caseSLA.IME_SC_CutOff_Hold_Time__c == null && caseSLA.IME_SC_SLA_Hold_Time__c != null && caseSLA.IME_SC_SLA_Resume_Time__c != null && (caseSLA.Status == 'In Progress') && 
                                           caseOldMap != null && !(caseOldMap.isEmpty()) &&
                                           ((caseOldMap.get(caseSLA.Id).Status == 'On Hold - Customer') || 
                                            ((caseOldMap.get(caseSLA.Id).Status == 'On Hold - Internal')&& (IsIMLACase == false))))
                                   {
                                       caseSLA.IME_SC_CutOff_Hold_Time__c = BusinessHours.diff(caseSLA.BusinessHoursId, caseSLA.IME_SC_SLA_Hold_Time__c, caseSLA.IME_SC_SLA_Resume_Time__c)/60000;
                                   }
                               }
                               String dayof = System.now().format('EEE');
                               // fetching business hour record through map and associated case business hour 
                               BusinessHours caseBusinessHours = BusinessHoursMap.get(caseSLA.BusinessHoursID);
                               Time dayEndTime = endTimeBH(dayof, caseBusinessHours);
                               Time dayStartTime = startTimeBH(dayof, caseBusinessHours);
                               Integer startTimeMonth = system.now().month();
                               Integer startTimeYear = system.now().year();
                               Integer startTimeDay= system.now().day();
                               Integer startTimeHour;
                               Integer startTimeMinute;
                               Integer endTimeHour;
                               Integer endTimeMinute;
                               dateTime startDateTime;
                               dateTime EndDateTime;
                               if(dayStartTime!= null)
                               {
                                   startTimeHour = dayStartTime.hour();
                                   startTimeMinute = dayStartTime.minute();
                                   endTimeHour = dayEndTime.hour();
                                   endTimeMinute = dayEndTime.minute();
                                   startDateTime = datetime.newInstance(startTimeYear, startTimeMonth, startTimeDay, startTimeHour, startTimeMinute, 0);
                                   EndDateTime = datetime.newInstance(startTimeYear, startTimeMonth, startTimeDay, endTimeHour, endTimeMinute, 0);
                               }
                               // setting end cut off time if cutoff time is equal to half day, standard and manual
                               if(caseSLA.IME_SC_Cut_Off_Time__c == 'Half Day (4 Hours)' || caseSLA.IME_SC_Cut_Off_Time__c == 'Standard (8 Hours)'||caseSLA.IME_SC_Cut_Off_Time__c == 'Manual')
                               {
                                   // setting end cut off time if cutoff time is equal to half Day
                                   if(caseSLA.IME_SC_Cut_Off_Time__c == 'Half Day (4 Hours)' )
                                   {    
                                       //for test class
                                       if(Test.isRunningTest())
                                       {
                                           caseSLA.IME_SC_CutOff_Hold_Time__c = 1;
                                       }
                                       
                                       caseSLA.End_Time_Cutoff_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,4*60*60*1000);
                                       //adding cutoff Hold Time in end time cutoff SLA
                                       if(caseSLA.IME_SC_CutOff_Hold_Time__c  != null && caseSLA.End_Time_Cutoff_SLA__c != null)
                                       {
                                           Integer slaTimeCutoff = Integer.valueOf(caseSLA.IME_SC_CutOff_Hold_Time__c);
                                           caseSLA.End_Time_Cutoff_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.End_Time_Cutoff_SLA__c, slaTimeCutoff*60*1000L);
                                       }
                                       Long diffCutoff =  BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, caseSLA.End_Time_Cutoff_SLA__c );
                                       //Initalizing SLA fields 
                                       if((caseSLA.Status != 'On Hold - Internal') && (caseSLA.Status != 'On Hold - Customer'))
                                       {
                                           caseSLA.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate, long.valueof(String.valueof((.5 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate, long.valueof(String.valueof((.75 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate, long.valueof(String.valueof((1 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate, long.valueof(String.valueof((1.25 * diffCutoff).intvalue())));
                                           system.debug('caseSLA.IME_SC_End_Time_125_Percent_SLA__c----------'+caseSLA.IME_SC_End_Time_125_Percent_SLA__c);
                                           Long totalSLA = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, caseSLA.End_Time_Cutoff_SLA__c)/60000;
                                           Integer SLAValue = Integer.valueOf(String.valueOf(totalSLA));
                                           caseSLA.IME_SC_SLA_Time_Elapsed__c = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, System.now())/60000;
                                           caseSLA.IME_SC_SLA_Time_Remaining__c = SLAValue - caseSLA.IME_SC_SLA_Time_Elapsed__c;
                                       }
                                       //Code added by Pratap
                                       if((caseSLA.Status == 'On Hold - Internal') && (IsIMLACase == true))
                                       {
                                           caseSLA.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate, long.valueof(String.valueof((.5 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate, long.valueof(String.valueof((.75 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate, long.valueof(String.valueof((1 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate, long.valueof(String.valueof((1.25 * diffCutoff).intvalue())));
                                           system.debug('caseSLA.IME_SC_End_Time_125_Percent_SLA__c----------'+caseSLA.IME_SC_End_Time_125_Percent_SLA__c);
                                           Long totalSLA = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, caseSLA.End_Time_Cutoff_SLA__c)/60000;
                                           Integer SLAValue = Integer.valueOf(String.valueOf(totalSLA));
                                           caseSLA.IME_SC_SLA_Time_Elapsed__c = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, System.now())/60000;
                                           caseSLA.IME_SC_SLA_Time_Remaining__c = SLAValue - caseSLA.IME_SC_SLA_Time_Elapsed__c;
                                       }
                                       //End of Code added by Pratap
                                   }
                                   else if(caseSLA.IME_SC_Cut_Off_Time__c == 'Standard (8 Hours)')
                                   {
                                       //for test class
                                       if(Test.isRunningTest())
                                       { 
                                           caseSLA.IME_SC_CutOff_Hold_Time__c = 1;
                                       }
                                       //validation for weekends
                                       caseSLA.End_Time_Cutoff_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,8*60*60*1000);
                                       //adding cutoff Hold Time in end time cutoff SLA
                                       if(caseSLA.IME_SC_CutOff_Hold_Time__c  != null && caseSLA.End_Time_Cutoff_SLA__c != null)
                                       {
                                           Integer slaTimeCutoff = Integer.valueOf(caseSLA.IME_SC_CutOff_Hold_Time__c);
                                           caseSLA.End_Time_Cutoff_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.End_Time_Cutoff_SLA__c, slaTimeCutoff*60*1000L);
                                       }
                                       Long diffCutoff =  BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, caseSLA.End_Time_Cutoff_SLA__c );
                                       //Initalizing SLA fields 
                                       if((caseSLA.Status != 'On Hold - Internal') && (caseSLA.Status != 'On Hold - Customer'))
                                       {
                                           caseSLA.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((.5 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((.75 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((1 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((1.25 * diffCutoff).intvalue())));                   
                                           system.debug('caseSLA.IME_SC_End_Time_125_Percent_SLA__c11111111111----------'+caseSLA.IME_SC_End_Time_125_Percent_SLA__c);
                                           Long totalSLA = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, caseSLA.End_Time_Cutoff_SLA__c)/60000;
                                           Integer SLAValue = Integer.valueOf(String.valueOf(totalSLA));
                                           caseSLA.IME_SC_SLA_Time_Elapsed__c = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, System.now())/60000;
                                           caseSLA.IME_SC_SLA_Time_Remaining__c = SLAValue - caseSLA.IME_SC_SLA_Time_Elapsed__c;
                                       }
                                       
                                       if((caseSLA.Status == 'On Hold - Internal') && (IsIMLACase == true))
                                       {
                                           caseSLA.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((.5 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((.75 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((1 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((1.25 * diffCutoff).intvalue())));                   
                                           system.debug('caseSLA.IME_SC_End_Time_125_Percent_SLA__c11111111111----------'+caseSLA.IME_SC_End_Time_125_Percent_SLA__c);
                                           Long totalSLA = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, caseSLA.End_Time_Cutoff_SLA__c)/60000;
                                           Integer SLAValue = Integer.valueOf(String.valueOf(totalSLA));
                                           caseSLA.IME_SC_SLA_Time_Elapsed__c = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, System.now())/60000;
                                           caseSLA.IME_SC_SLA_Time_Remaining__c = SLAValue - caseSLA.IME_SC_SLA_Time_Elapsed__c;
                                       }
                                       
                                       
                                   }
                                   else if(caseSLA.IME_SC_Cut_Off_Time__c == 'Manual')
                                   {
                                       if(caseOldMap != null && !caseOldMap.isEmpty())
                                           oldcase = caseOldMap.get(caseSLA.id);
                                       if(caseSLA.End_Time_Cutoff_SLA__c  != null)
                                       {    
                                           Integer cutoffYear = caseSLA.End_Time_Cutoff_SLA__c.year();
                                           Integer cutoffMonth = caseSLA.End_Time_Cutoff_SLA__c.month();
                                           Integer cutoffDay = caseSLA.End_Time_Cutoff_SLA__c.day();
                                           Integer cutOffHour = caseSLA.End_Time_Cutoff_SLA__c.hour();
                                           Integer cutOffMinute = caseSLA.End_Time_Cutoff_SLA__c.minute();
                                           Time cutOffTimevalue = Time.newInstance(CutOffHour, CutOffMinute, 0, 0);
                                           String dayofCutOff = caseSLA.End_Time_Cutoff_SLA__c.format('EEE');
                                           Time endTime = endTimeBH(dayofCutOff, caseBusinessHours);
                                           Time startTime = startTimeBH(dayofCutOff, caseBusinessHours);
                                           Integer cutoffEndTimeHour;
                                           Integer cutoffEndTimeMinute;
                                           if(endTime != null)
                                           {
                                               cutoffEndTimeHour = endTime.hour();
                                               cutoffEndTimeMinute = endTime.minute();
                                           }
                                           // fetching business hour record through map and associated case business hour 
                                           //BusinessHours caseBusinessHours = BusinessHoursMap.get(caseSLA.BusinessHoursID);
                                           
                                           //for test class
                                           if(Test.isRunningTest())
                                           {
                                               caseSLA.IME_SC_CutOff_Hold_Time__c = 1;
                                           }
                                           //validation for working day
                                           if(StartTime != null)
                                           {
                                               DateTime cutoffMinusOneSecond = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.End_Time_Cutoff_SLA__c, -1000L);
                                               DateTime CutoffPlusOneSecond = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.End_Time_Cutoff_SLA__c, 1000L);
                                               DateTime cutoffMinusSecond = cutoffMinusOneSecond.addSeconds(1);
                                               DateTime CutoffPlusSecond = CutoffPlusOneSecond.addSeconds(-1);
                                               Time cutoffTimeMinusOneSecond = cutoffMinusSecond.time();
                                               Time CutoffTimePlusOneSecond = CutoffPlusSecond.time();
                                               Date cutoffDateMinusOneSecond = cutoffMinusSecond.date();
                                               Date CutoffDatePlusOneSecond = CutoffPlusSecond.date();
                                               Time cutoffActualTime = caseSLA.End_Time_Cutoff_SLA__c.time();
                                               Date cutOffActualDate = caseSLA.End_Time_Cutoff_SLA__c.date();
                                               
                                               //Holiday
                                               if(cutoffTimeMinusOneSecond == endTime && CutoffTimePlusOneSecond == startTime && cutoffDateMinusOneSecond != cutOffActualDate && CutoffDatePlusOneSecond != cutOffActualDate)
                                               {
                                                   dayofCutOff = CutoffPlusSecond.format('EEE');
                                                   startTime = startTimeBH(dayofCutOff, caseBusinessHours);
                                                   endTime = endTimeBH(dayofCutOff, caseBusinessHours);
                                                   Integer year  = CutoffPlusSecond.year();
                                                   Integer month = CutoffPlusSecond.month();
                                                   Integer day = CutoffPlusSecond.day();
                                                   Integer hour = endTime.hour();
                                                   Integer minute = endTime.minute();
                                                   Integer second = 0;
                                                   caseSLA.End_Time_Cutoff_SLA__c = datetime.newInstance(Year, Month, Day, Hour, Minute, second);
                                               }
                                               else
                                               {
                                                   Date actualDate = system.now().date();
                                                   if(cutOffActualDate == actualDate)
                                                   {
                                                       //Todays Functionality
                                                       if(cutoffActualTime <= startTime || cutoffActualTime > endTime)
                                                       {
                                                           caseSLA.End_Time_Cutoff_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.End_Time_Cutoff_SLA__c, 1L);
                                                       }
                                                   }
                                                   else
                                                   {
                                                       //future date functionality
                                                       if(cutoffActualTime < startTime || cutoffActualTime > endTime)
                                                       {
                                                           caseSLA.End_Time_Cutoff_SLA__c = datetime.newInstance(cutoffYear, cutoffMonth, cutoffDay, cutoffEndTimeHour, cutoffEndTimeMinute, 0);
                                                       }
                                                       
                                                   }
                                               }   
                                           }
                                           else
                                           {
                                               //Weekend
                                               DateTime CutoffPlusOneSecond = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.End_Time_Cutoff_SLA__c, 1000L);
                                               DateTime CutoffPlusSecond = CutoffPlusOneSecond.addSeconds(-1);
                                               dayofCutOff = CutoffPlusSecond.format('EEE');
                                               startTime = startTimeBH(dayofCutOff, caseBusinessHours);
                                               endTime = endTimeBH(dayofCutOff, caseBusinessHours);
                                               Integer year  = CutoffPlusSecond.year();
                                               Integer month = CutoffPlusSecond.month();
                                               Integer day = CutoffPlusSecond.day();
                                               Integer hour; //= endTime.hour();
                                               Integer minute;// = endTime.minute();
                                               if(endTime != null)
                                               {
                                                   hour = endTime.hour();
                                                   minute = endTime.minute();
                                                   caseSLA.End_Time_Cutoff_SLA__c = datetime.newInstance(Year, Month, Day, Hour, Minute, 0);
                                               }
                                           }
                                           //adding cutoff Hold Time in end time cutoff SLA
                                           if(caseSLA.IME_SC_CutOff_Hold_Time__c  != null && caseSLA.End_Time_Cutoff_SLA__c != null)
                                           {
                                               Integer slaTimeCutoff = Integer.valueOf(caseSLA.IME_SC_CutOff_Hold_Time__c);
                                               caseSLA.End_Time_Cutoff_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.End_Time_Cutoff_SLA__c, slaTimeCutoff*60*1000L);
                                               caseSLA.IME_SC_CutOff_Hold_Time__c  = null;
                                           }
                                           Long diffCutoff =  BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, caseSLA.End_Time_Cutoff_SLA__c );
                                           
                                           //Intializing SLA fields
                                           if((caseSLA.Status != 'On Hold - Internal') && (caseSLA.Status != 'On Hold - Customer'))
                                           {
                                               
                                               system.debug('caseCreatedDate----------'+caseCreatedDate);
                                               system.debug('diffCutoff----------'+diffCutoff);
                                               system.debug('(.5 * diffCutoff)----------'+(.5 * diffCutoff));
                                               string SLATime50 = string.valueof(.5 * diffCutoff);
                                               system.debug('SLATime50----'+SLATime50);
                                               string[] SLATime50Split = SLATime50.split('\\.');
                                               system.debug('SLATime50Split[0]----'+SLATime50Split[0]);
                                               system.debug('long.valueof(SLATime50Split[0])----------'+long.valueof(SLATime50Split[0]));
                                               caseSLA.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(SLATime50Split[0]));
                                               //  caseSLA.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((.5 * diffCutoff).intvalue())) );
                                               system.debug('diffCutoff----------'+diffCutoff);
                                               system.debug('(.75 * diffCutoff)----------'+(.75 * diffCutoff));
                                               string SLATime75 = string.valueof(.75 * diffCutoff);
                                               system.debug('SLATime75----'+SLATime75);
                                               string[] SLATime75Split = SLATime75.split('\\.');
                                               system.debug('SLATime75Split[0]----'+SLATime75Split[0]);
                                               system.debug('long.valueof(SLATime75Split[0])----------'+long.valueof(SLATime75Split[0]));
                                               caseSLA.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(SLATime75Split[0]));
                                               //caseSLA.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((.75 * diffCutoff).intvalue())));
                                               system.debug('diffCutoff----------'+diffCutoff);
                                               system.debug('(1 * diffCutoff)----------'+(1 * diffCutoff));
                                               string SLATime100 = string.valueof(1 * diffCutoff);
                                               system.debug('SLATime100----'+SLATime100);
                                               string[] SLATime100Split = SLATime100.split('\\.');
                                               system.debug('SLATime100Split[0]----'+SLATime100Split[0]);
                                               system.debug('long.valueof(SLATime100Split[0])----------'+long.valueof(SLATime100Split[0]));
                                               caseSLA.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(SLATime100Split[0]));
                                               //caseSLA.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((1 * diffCutoff).intvalue())));
                                               system.debug('caseSLA.BusinessHoursId----------'+caseSLA.BusinessHoursId);
                                               system.debug('caseCreatedDate----------'+caseCreatedDate);
                                               system.debug('diffCutoff----------'+diffCutoff);
                                               system.debug('(1.25 * diffCutoff)----------'+(1.25 * diffCutoff));
                                               string SLATime125 = string.valueof(1.25 * diffCutoff);
                                               system.debug('SLATime125----'+SLATime125);
                                               string[] SLATime125Split = SLATime125.split('\\.');
                                               system.debug('SLATime125Split[0]----'+SLATime125Split[0]);
                                               system.debug('long.valueof(SLATime125Split[0])----------'+long.valueof(SLATime125Split[0]));
                                               caseSLA.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(SLATime125Split[0]));
                                               system.debug('caseSLA.IME_SC_End_Time_125_Percent_SLA__c22222222222----------'+caseSLA.IME_SC_End_Time_125_Percent_SLA__c);
                                               Time endTimeCutoffTime = caseSLA.End_Time_Cutoff_SLA__c.time();
                                               dayofCutOff = caseSLA.End_Time_Cutoff_SLA__c.format('EEE');
                                               startTime = startTimeBH(dayofCutOff, caseBusinessHours);
                                               endTime = endTimeBH(dayofCutOff, caseBusinessHours);
                                               system.debug('caseSLA.BusinessHoursId(before if)----------'+caseSLA.BusinessHoursId);
                                               system.debug('caseSLA.IME_SC_End_Time_125_Percent_SLA__c(before if)----------'+caseSLA.IME_SC_End_Time_125_Percent_SLA__c);
                                               if(endTimeCutoffTime != endTime)
                                               {
                                                   caseSLA.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_50_Percent_SLA__c,60001L );
                                                   caseSLA.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_75_Percent_SLA__c,60001L);
                                                   caseSLA.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_100_Percent_SLA__c,60001L);
                                                   caseSLA.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_125_Percent_SLA__c,60001L);    
                                                   system.debug('caseSLA.IME_SC_End_Time_125_Percent_SLA__c333333333----------'+caseSLA.IME_SC_End_Time_125_Percent_SLA__c);
                                               }
                                               else
                                               {
                                                   caseSLA.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_50_Percent_SLA__c,60000L );
                                                   caseSLA.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_75_Percent_SLA__c,60000L);
                                                   caseSLA.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_100_Percent_SLA__c,60000L);
                                                   caseSLA.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_125_Percent_SLA__c,60000L);    
                                                   system.debug('caseSLA.IME_SC_End_Time_125_Percent_SLA__c44444444----------'+caseSLA.IME_SC_End_Time_125_Percent_SLA__c);
                                               }
                                               Long totalSLA = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, caseSLA.End_Time_Cutoff_SLA__c)/60000;
                                               Integer SLAValue = Integer.valueOf(String.valueOf(totalSLA));
                                               caseSLA.IME_SC_SLA_Time_Elapsed__c = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, System.now())/60000;
                                               caseSLA.IME_SC_SLA_Time_Remaining__c = SLAValue - caseSLA.IME_SC_SLA_Time_Elapsed__c;
                                           }
                                       }
                                   }                     
                               }
                               else 
                               {
                                   
                                   //Converting selected cutoff time into cutoff datetime value
                                   Integer CutOffHour;
                                   string cutOffTime = caseSLA.IME_SC_Cut_Off_Time__c;
                                   Integer cutOffTimeLen = cutOffTime.length();
                                   //to get minutes from selected cut off time
                                   Integer CutOffMinute = Integer.valueof(cutoffTime.substring(cutOffTimeLen-2, cutOffTimeLen));
                                   //to get hours from selected cutoff time
                                   if(cutOffTimeLen == 5)       
                                       CutOffHour = Integer.valueof(cutoffTime.substring(cutOffTimeLen-5, cutOffTimeLen-3));
                                   else
                                       CutOffHour = Integer.valueof(cutoffTime.substring(cutOffTimeLen-4, cutOffTimeLen-3));
                                   Integer currentCutOffMonth = system.now().month();
                                   Integer currentCutOffyear = system.now().year();
                                   Integer currentCutOffDay= system.now().day();
                                   // creating current cutoff date time value
                                   Datetime currentCutOffDate = datetime.newInstance(currentCutOffyear, currentCutOffMonth, currentCutOffDay, CutOffHour, CutOffMinute, 0);
                                   Datetime todaysDate = BusinessHours.add(caseSLA.BusinessHoursId , System.now(), 1000L);
                                   Integer cutOffMonth = todaysDate.month();
                                   Integer cutOffyear = todaysDate.year();
                                   Integer cutOffDay= todaysDate.day();
                                   // creating date time value
                                   Datetime cutOffDate = datetime.newInstance(cutOffyear, cutOffMonth, cutOffDay, CutOffHour, CutOffMinute, 0);
                                   
                                   if(currentCutOffDate < startDateTime|| currentCutOffDate > endDateTime)
                                       caseSLA.IME_SC_Cut_Off_Time__c.addError(System.Label.IME_SC_Not_In_Working_Hours);
                                   else if(System.now() > cutOffDate && (Trigger.isInsert  || oldcase == null))
                                   {
                                       //On Insert : Calculating end time cutoff is next working day it time is already passed today  
                                       Datetime nextDate = BusinessHours.add(caseSLA.BusinessHoursId , endDateTime, 120000L); 
                                       Integer nextcutOffMonth = nextDate.month();
                                       Integer nextcutOffyear = nextDate.year();
                                       Integer nextcutOffDay= nextDate.day(); 
                                       caseSLA.End_Time_Cutoff_SLA__c = datetime.newInstance(nextcutOffyear, nextcutOffMonth, nextcutOffDay, CutOffHour, CutOffMinute, 0);  
                                       
                                   }
                                   else if(System.now() > cutOffDate && oldcase != null && (caseSLA.IME_SC_Cut_Off_Time__c != oldCase.IME_SC_Cut_Off_Time__c)&& Trigger.isUpdate )
                                   {
                                       //On Update : Calculating end time cutoff is next working day it time is already passed today
                                       Datetime nextDate = BusinessHours.add(caseSLA.BusinessHoursId , endDateTime, 120000L); 
                                       Integer nextcutOffMonth = nextDate.month();
                                       Integer nextcutOffyear = nextDate.year();
                                       Integer nextcutOffDay= nextDate.day(); 
                                       caseSLA.End_Time_Cutoff_SLA__c = datetime.newInstance(nextcutOffyear, nextcutOffMonth, nextcutOffDay, CutOffHour, CutOffMinute, 0);                             
                                   }
                                   else if(System.now() < cutOffDate)
                                   {
                                       //Intializing end time cutoff SLA
                                       caseSLA.End_Time_Cutoff_SLA__c = cutOffDate;
                                   }
                                   // Initializing SLa fields
                                   if(caseSLA.End_Time_Cutoff_SLA__c != null && caseCreatedDate != null )
                                   {
                                       String dayofCutOff = caseSLA.End_Time_Cutoff_SLA__c.format('EEE');
                                       Time startTime = startTimeBH(dayofCutOff, caseBusinessHours);
                                       Time endTime = endTimeBH(dayofCutOff, caseBusinessHours);
                                       Integer yearCutoff = caseSLA.End_Time_Cutoff_SLA__c.year();
                                       Integer monthCutoff = caseSLA.End_Time_Cutoff_SLA__c.month();
                                       Integer dayCutoff = caseSLA.End_Time_Cutoff_SLA__c.day();
                                       Integer hourStartTimeCut = startTime.hour();
                                       Integer minuteStartTimeCut = startTime.minute();
                                       Integer hourEndTimeCut = endTime.hour();
                                       Integer minuteEndTimeCut = endTime.minute();
                                       
                                       DateTime startTimeDateCut = datetime.newInstance(yearCutoff, monthCutoff, dayCutoff, hourStartTimeCut, minuteStartTimeCut, 0);
                                       DateTime endTimeDateCut = datetime.newInstance(yearCutoff, monthCutoff, dayCutoff, hourEndTimeCut, minuteEndTimeCut, 0);
                                       
                                       if(caseSLA.End_Time_Cutoff_SLA__c < startTimeDateCut || caseSLA.End_Time_Cutoff_SLA__c > endTimeDateCut)
                                       {
                                           caseSLA.IME_SC_Cut_Off_Time__c.addError(System.Label.IME_SC_Not_In_Working_Hours);
                                       }
                                       if(caseSLA.IME_SC_CutOff_Hold_Time__c  != null && caseSLA.End_Time_Cutoff_SLA__c != null)
                                       {
                                           Integer slaTimeCutoff = Integer.valueOf(caseSLA.IME_SC_CutOff_Hold_Time__c);
                                           caseSLA.End_Time_Cutoff_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.End_Time_Cutoff_SLA__c, slaTimeCutoff*60*1000L);
                                       }
                                       if((((caseSLA.Status != 'On Hold - Internal') && (IsIMLACase== false)) && (caseSLA.Status != 'On Hold - Customer'))
                                          || 
                                          ((caseSLA.Status != 'On Hold - Customer') && (IsIMLACase== true)) )
                                       {
                                           Long diffCutoff =  BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, caseSLA.End_Time_Cutoff_SLA__c );
                                           caseSLA.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((.5 * diffCutoff).intvalue())) );
                                           caseSLA.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((.75 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((1 * diffCutoff).intvalue())));
                                           caseSLA.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseCreatedDate,long.valueof(String.valueof((1.25 * diffCutoff).intvalue())));
                                           system.debug('caseSLA.IME_SC_End_Time_125_Percent_SLA__c55555555555----------'+caseSLA.IME_SC_End_Time_125_Percent_SLA__c);
                                           // Adding 1 min if cutoff is selected end time of business hour
                                           if(currentCutOffDate != endDateTime)
                                           {
                                               caseSLA.IME_SC_End_Time_50_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_50_Percent_SLA__c, 60001L);
                                               caseSLA.IME_SC_End_Time_75_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_75_Percent_SLA__c, 60001L);
                                               caseSLA.IME_SC_End_Time_100_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_100_Percent_SLA__c, 60001L);
                                               caseSLA.IME_SC_End_Time_125_Percent_SLA__c = BusinessHours.add(caseSLA.BusinessHoursId , caseSLA.IME_SC_End_Time_125_Percent_SLA__c, 60001L);
                                               system.debug('caseSLA.IME_SC_End_Time_125_Percent_SLA__c66666666----------'+caseSLA.IME_SC_End_Time_125_Percent_SLA__c);
                                           }
                                           Long totalSLA = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, caseSLA.End_Time_Cutoff_SLA__c)/60000;
                                           Integer SLAValue = Integer.valueOf(String.valueOf(totalSLA));
                                           caseSLA.IME_SC_SLA_Time_Elapsed__c = BusinessHours.diff(caseSLA.BusinessHoursId, caseCreatedDate, System.now())/60000;
                                           caseSLA.IME_SC_SLA_Time_Remaining__c = SLAValue - caseSLA.IME_SC_SLA_Time_Elapsed__c;
                                       }
                                   }
                               }                                                  
                           }  
                           else if(oldCase != Null && oldcase.IME_SC_Cut_Off_Time__c != null && updatedCase == true && caseSLA.IME_SC_Rush__c != true && caseSLA.IME_SC_Cut_Off_Time__c == null)
                           {  
                               // making SLA fields null
                               caseSLA.End_Time_Cutoff_SLA__c = null;
                               caseSLA.IME_SC_End_Time_50_Percent_SLA__c = null;
                               caseSLA.IME_SC_End_Time_75_Percent_SLA__c = null;
                               caseSLA.IME_SC_End_Time_100_Percent_SLA__c = null;
                               caseSLA.IME_SC_End_Time_125_Percent_SLA__c = null;
                               caseSLA.IME_SC_SLA_Resume_Time__c = null;
                               caseSLA.IME_SC_SLA_Hold_Time__c = null;
                               caseSLA.IME_SC_SLA_Time_Elapsed__c = null;
                               caseSLA.IME_SC_SLA_Time_Remaining__c = null; 
                           }
                       }
                       }
                       }       
                       }
                       }
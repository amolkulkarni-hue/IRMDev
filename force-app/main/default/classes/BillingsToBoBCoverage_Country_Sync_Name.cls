/****************************** 
   Developer Name    : Vijay/Rajesh
   
   Date              : 03/19/2015
   
   Purpose           : This class is used to sync CountryParent Formula filed value with CountryParent Text filed value. 
   
   Test Class        : Test_BillingsToBoBCovrg_SyncCountry .
   
   Case Number       : 03340776
                                  
 ********************************/ 
global class BillingsToBoBCoverage_Country_Sync_Name{public BillingsToBoBCoverage_Country_Sync_Name(){string t='1';}}
/*global class BillingsToBoBCoverage_Country_Sync_Name implements Database.Batchable<sObject>,Database.Stateful {
   String  UseThisCustomSetting;
   public String QUERY_TO_EXECUTE='select id,Country_Parent_ID_Formula__c,Country_Parent_ID_Text__c from Billings__c where Country_Parent_ID_Change__c=\'TRUE\'';
   Integer ToatalRecords=0;
   Integer TotalErrors=0;
   Id CountryParentId;

   public BillingsToBoBCoverage_Helper helper; 
      
    global BillingsToBoBCoverage_Country_Sync_Name (String CustomsettingName){
       UseThisCustomSetting=CustomsettingName;
   }
   
   global Database.QueryLocator start(Database.BatchableContext BC){
        BillingsToBoBCoverageJoins__c Commonsettings=BillingsToBoBCoverageJoins__c.getInstance(UseThisCustomSetting);
    / *  Date CurrentDate=Date.Today();
        String CurrentYear=string.ValueOf(CurrentDate.Year());
        String PreviousYear=string.ValueOf(CurrentDate.Year()-1);
     * /
     // Case: 06288633,Current Year is determined by the custom Setting's 'Effective Year' instead of the actual date.
        String CurrentYear=string.ValueOf(Commonsettings.Focus_Year__c);
        String PreviousYear=string.ValueOf(Integer.valueOf(Commonsettings.Focus_Year__c)-1);
        QUERY_TO_EXECUTE+=' AND (Billing_Year__c=\''+CurrentYear+'\''+'  or Billing_Year__c=\''+PreviousYear+'\')';
        if(Commonsettings != null)
        QUERY_TO_EXECUTE+='AND RecordTypeId =\''+Commonsettings.RecordTypeId__c+'\'';
        system.debug('+++++++++QUERY_TO_EXECUTE in BillingsToBoBCoverage_SyncCountry_Name++++++++'+QUERY_TO_EXECUTE);
                 
        return Database.getQueryLocator(QUERY_TO_EXECUTE);
    }
    
    
    //execute method
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        System.debug('Coming in execute');
   
        //block of code to copy formula value into text filed
        List<sObject> updateList=new List<sObject>();
        System.debug('scope=='+scope);
        for(SObject sObj:scope){
        String CountryParentText=(String) sObj.get('Country_Parent_ID_Formula__c');
        if(CountryParentText != null && CountryParentText != 'NOT LINKED TO HIERARCHY / MISSING COUNTRY PARENT'){
         CountryParentId = CountryParentText;
        }
        else{
         CountryParentId = null; 
        }
        sObj.put('Country_Parent_ID_Text__c',CountryParentId);
        updateList.add(sObj);
         }
         ToatalRecords+=scope.size();
          // are there join records to be inserted? 
          Database.SaveResult[] results=Database.update(updateList, false);  
          if (results != null  &&  !results.isEmpty()) {   
            // evaluate the outcome for each record
            for (Integer lpcnt = 0; lpcnt < results.size(); lpcnt++) {
                // unsuccessful?
                if (!results[lpcnt].isSuccess()) {
                    // keep count of all failures as errors
                    TotalErrors++;                            
                } 
            }
          } 
         
    }
    // finish methodcontains logic to sena out an email to user who scheduled this class with sucess/failure report.
   
    global void finish(Database.BatchableContext BC){
       helper=new BillingsToBoBCoverage_Helper(UseThisCustomSetting);
       BillingsToBoBCoverageJoins__c settings=BillingsToBoBCoverageJoins__c.getInstance(UseThisCustomSetting); 
       String jobSummary=   '\n    Total Batch Size:           ' + ToatalRecords.format().leftPad(7)          +        
                            '\n    Number Of Errors on Update: ' + TotalErrors.format().leftPad(7); 
                            
        // create a Chatter post summarizing the outcome of this run
        if(settings != null)
        helper.postToChatterGroup(settings.Chatter_Group__c, 
            'The BillingsToBoBCoverage_Country_Sync_Name batch job has completed.' + jobSummary);        
           
                           
    }
}*/
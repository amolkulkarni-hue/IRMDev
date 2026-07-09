public with sharing class M4RevenueContExt {
    
    /* Commenting the entire code as part of Gitlab #25402 */
    
    public M4RevenueContExt(){
        
    }
/*
    public final M4_Revenue_Coverage__c revenue;
    public final M4_Revenue_Coverage__c revenue1;
    public list<double> pastYearTotals {get;set;}
    public list<double> currentYearTotals {get;set;}
    public list<double> currentYearQuotas {get;set;} 
    public list<double> currentYearActuals {get;set;}
    public list<double> currentYearPercentages {get;set;}
    
    public Double currentYearSum {get;set;}
    public Double pastYearSum {get;set;}
    public Double currentQuotasSum {get;set;}
    public Double overallYearPercentage {get;set;}
    public Double overallYearActuals {get;set;}
    public Double YTDPerformance {get;set;}
    public Double MonthlyPYAvg{get;set;}
    public Double PYMonthlyAverageM4Quota{get;set;}
    public string message {get;set;}
    public String Profilename {get;set;}
    public String currencycode{get;set;}
    public String symbol{get;set;}

    public M4RevenueContExt(ApexPages.StandardController stdController) {
        
    User user = [select u.Profile.Name,u.DefaultCurrencyIsoCode  from User u where u.id = :Userinfo.getUserId()];
    currencycode=user.DefaultCurrencyIsoCode;

    this.revenue =  [Select convertCurrency(PY_May__c),convertCurrency(PY_Mar__c),convertCurrency(PY_Jun__c), 
              convertCurrency(PY_Jul__c),convertCurrency(PY_Jan__c),convertCurrency(PY_Feb__c),
              convertCurrency(PY_Dec__c),convertCurrency(PY_Sep__c),convertCurrency(PY_Aug__c),
              convertCurrency(PY_Apr__c),convertCurrency(PY_Oct__c), convertCurrency(PY_Nov__c),
              convertCurrency(M4_Quota_Sep__c),convertCurrency(M4_Quota_Oct__c),convertCurrency(M4_Quota_Apr__c),
              convertCurrency(M4_Quota_Nov__c),convertCurrency(M4_Quota_May__c),convertCurrency(M4_Quota_Mar__c),
              convertCurrency(M4_Quota_Jun__c),convertCurrency(M4_Quota_Jul__c),convertCurrency(M4_Quota_Jan__c),
              convertCurrency(M4_Quota_Feb__c),convertCurrency(M4_Quota_Dec__c),convertCurrency(M4_Quota_Aug__c),
              convertCurrency(CY_Sep__c),convertCurrency(CY_Oct__c),convertCurrency(CY_Nov__c), convertCurrency(CY_Apr__c),
              convertCurrency(CY_May__c),convertCurrency(CY_Mar__c),convertCurrency(CY_Jun__c),convertCurrency(CY_Jul__c),
              convertCurrency(CY_Jan__c),convertCurrency(CY_Feb__c),convertCurrency(CY_Dec__c),convertCurrency(CY_Aug__c),
              convertCurrency(PY_BoB_Total__c),convertCurrency(M4_YTD_Quota__c), convertCurrency(CY_YTD_Amount__c)
              From M4_Revenue_Coverage__c where id =: stdController.getID() limit 1];
              
    /* due to SOQL Selecting Too many fields issue,created one more Query *//*
    this.revenue1=  [Select convertCurrency(YTD_Performance__c),convertCurrency(Monthly_PY_Avg__c),convertCurrency(PY_Monthly_Average_M4_Quota__c)
               From M4_Revenue_Coverage__c where id =: stdController.getID() limit 1]; 

        message = String.valueof(revenue.PY_Jan__c);
        
        pastYearTotals = new list<double>{
            revenue.PY_Jan__c,
            revenue.PY_Feb__c, 
            revenue.PY_Mar__c, 
            revenue.PY_Apr__c, 
            revenue.PY_May__c, 
            revenue.PY_Jun__c, 
            revenue.PY_Jul__c, 
            revenue.PY_Aug__c, 
            revenue.PY_Sep__c, 
            revenue.PY_Oct__c, 
            revenue.PY_Nov__c, 
            revenue.PY_Dec__c
        };
                        
        currentYearTotals =  new list<double>{
            revenue.CY_Jan__c,
            revenue.CY_Feb__c, 
            revenue.CY_Mar__c, 
            revenue.CY_Apr__c, 
            revenue.CY_May__c, 
            revenue.CY_Jun__c, 
            revenue.CY_Jul__c, 
            revenue.CY_Aug__c, 
            revenue.CY_Sep__c, 
            revenue.CY_Oct__c, 
            revenue.CY_Nov__c, 
            revenue.CY_Dec__c
        };
                        
        currentYearQuotas = new list<double>{
            revenue.M4_Quota_Jan__c,
            revenue.M4_Quota_Feb__c, 
            revenue.M4_Quota_Mar__c, 
            revenue.M4_Quota_Apr__c, 
            revenue.M4_Quota_May__c, 
            revenue.M4_Quota_Jun__c, 
            revenue.M4_Quota_Jul__c, 
            revenue.M4_Quota_Aug__c, 
            revenue.M4_Quota_Sep__c, 
            revenue.M4_Quota_Oct__c, 
            revenue.M4_Quota_Nov__c, 
            revenue.M4_Quota_Dec__c
        };
        
        currentQuotasSum= revenue.M4_YTD_Quota__c;
        currentYearSum= revenue.CY_YTD_Amount__c;
        pastYearSum= revenue.PY_BoB_Total__c;
        if(revenue1 != null){
        YTDPerformance=revenue1.YTD_Performance__c; 
        MonthlyPYAvg=revenue1.Monthly_PY_Avg__c;
        PYMonthlyAverageM4Quota=revenue1.PY_Monthly_Average_M4_Quota__c;
        }  
        overallYearActuals = currentYearSum - currentQuotasSum;
        overallYearPercentage = currentQuotasSum == 0 ? 0 : (currentYearSum / currentQuotasSum) * 100 ; 
        
        currentYearActuals = new list<double>();
        currentYearPercentages = new list<double>();
        
        for (integer i = 0; i < 12; i++){
            currentYearActuals.add(currentYearTotals.get(i) - currentYearQuotas.get(i));
            if(currentYearQuotas.get(i) == 0){
                currentYearPercentages.add(0);
            } else {
                currentYearPercentages.add((currentYearTotals.get(i) / currentYearQuotas.get(i)) * 100);    
            }
        }  
        if(currencycode =='GBP'){ 
        symbol='£';
        }else if(currencycode =='EUR'){
        symbol='€';
        }
        else if(currencycode =='USD'){
        symbol='$';
   }     
    }
*/
}
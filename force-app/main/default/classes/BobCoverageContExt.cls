/* Commenting the entire code as part of Gitlab #24446 */
public with sharing class BobCoverageContExt {
    public BobCoverageContExt(){
        
    }
/*
  public final Bob_Coverage__c bob;
  public final Bob_Coverage__c bob1;
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
  public Double PYMonthlyAverageM2Quota{get;set;}
  public Double MonthlyPYAvg{get;set;}
  public string message {get;set;}
  public String Profilename {get;set;}
  public String currencycode{get;set;}
  public String symbol{get;set;}
  

  public BobCoverageContExt(ApexPages.StandardController stdController) {
      
    User user = [select u.Profile.Name,u.DefaultCurrencyIsoCode  from User u where u.id = :Userinfo.getUserId()];
    currencycode=user.DefaultCurrencyIsoCode;
    Profilename= user.Profile.Name;
    System.debug('Profilename=='+Profilename);  
 //   if(Profilename.startsWith('IME_'))
 //   {       
    this.bob =  [Select convertCurrency(PY_May__c),convertCurrency(PY_Mar__c),convertCurrency(PY_Jun__c), 
              convertCurrency(PY_Jul__c),convertCurrency(PY_Jan__c),convertCurrency(PY_Feb__c),
              convertCurrency(PY_Dec__c),convertCurrency(PY_Sep__c),convertCurrency(PY_Aug__c),
              convertCurrency(PY_Apr__c),convertCurrency(PY_Oct__c), convertCurrency(PY_Nov__c),
              convertCurrency(M2_Quota_Sep__c),convertCurrency(M2_Quota_Oct__c),convertCurrency(M2_Quota_Apr__c),
              convertCurrency(M2_Quota_Nov__c),convertCurrency(M2_Quota_May__c),convertCurrency(M2_Quota_Mar__c),
              convertCurrency(M2_Quota_Jun__c),convertCurrency(M2_Quota_Jul__c),convertCurrency(M2_Quota_Jan__c),
              convertCurrency(M2_Quota_Feb__c),convertCurrency(M2_Quota_Dec__c),convertCurrency(M2_Quota_Aug__c),
              convertCurrency(CY_Sep__c),convertCurrency(CY_Oct__c),convertCurrency(CY_Nov__c), convertCurrency(CY_Apr__c),
              convertCurrency(CY_May__c),convertCurrency(CY_Mar__c),convertCurrency(CY_Jun__c),convertCurrency(CY_Jul__c),
              convertCurrency(CY_Jan__c),convertCurrency(CY_Feb__c),convertCurrency(CY_Dec__c),convertCurrency(CY_Aug__c),
              convertCurrency(PY_BoB_Total__c),convertCurrency(M2_YTD_Quota_Summary__c), convertCurrency(CY_YTD_Amount__c)
              From BoB_Coverage__c where id =: stdController.getID() limit 1];
        
              
    /* due to SOQL Selecting Too many fields issue,created one more Query * /
    this.bob1=  [Select convertCurrency(YTD_Performance__c),convertCurrency(Monthly_PY_Avg__c),convertCurrency(PY_Monthly_Average_M2_Quota__c)
               From BoB_Coverage__c where id =: stdController.getID() limit 1];
 
    message = String.valueof(bob.PY_Jan__c);
    
    pastYearTotals = new list<double>{bob.PY_Jan__c,
      bob.PY_Feb__c, 
      bob.PY_Mar__c, 
      bob.PY_Apr__c, 
      bob.PY_May__c, 
      bob.PY_Jun__c, 
      bob.PY_Jul__c, 
      bob.PY_Aug__c, 
      bob.PY_Sep__c, 
      bob.PY_Oct__c, 
      bob.PY_Nov__c, 
      bob.PY_Dec__c};
            
    currentYearTotals =  new list<double>{bob.CY_Jan__c,
      bob.CY_Feb__c, 
      bob.CY_Mar__c, 
      bob.CY_Apr__c, 
      bob.CY_May__c, 
      bob.CY_Jun__c, 
      bob.CY_Jul__c, 
      bob.CY_Aug__c, 
      bob.CY_Sep__c, 
      bob.CY_Oct__c, 
      bob.CY_Nov__c, 
      bob.CY_Dec__c};
            
    currentYearQuotas = new list<double>{bob.M2_Quota_Jan__c,
      bob.M2_Quota_Feb__c, 
      bob.M2_Quota_Mar__c, 
      bob.M2_Quota_Apr__c, 
      bob.M2_Quota_May__c, 
      bob.M2_Quota_Jun__c, 
      bob.M2_Quota_Jul__c, 
      bob.M2_Quota_Aug__c, 
      bob.M2_Quota_Sep__c, 
      bob.M2_Quota_Oct__c, 
      bob.M2_Quota_Nov__c, 
      bob.M2_Quota_Dec__c};
    
    currentQuotasSum= bob.M2_YTD_Quota_Summary__c;
    currentYearSum= bob.CY_YTD_Amount__c;
    if(bob1 != null)
    {
    YTDPerformance=bob1.YTD_Performance__c;
    PYMonthlyAverageM2Quota=bob1.PY_Monthly_Average_M2_Quota__c;
    MonthlyPYAvg=bob1.Monthly_PY_Avg__c;
    }
    pastYearSum= bob.PY_BoB_Total__c;
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
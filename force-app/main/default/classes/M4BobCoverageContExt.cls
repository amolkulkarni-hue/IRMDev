/* Commenting the entire code as part of Gitlab #24446 */
public with sharing class M4BobCoverageContExt {
    public M4BobCoverageContExt(){
        
    }
/*
    public final BoB_Coverage_Eligible__c bob;
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
    public string message {get;set;}
    

    public M4BobCoverageContExt(ApexPages.StandardController stdController) {
        this.bob =  [Select PY_May__c,PY_Mar__c,PY_Jun__c, 
                            PY_Jul__c,PY_Jan__c,PY_Feb__c,
                            PY_Dec__c,PY_Sep__c,PY_Aug__c,
                            PY_Apr__c,PY_Oct__c, PY_Nov__c,
                            M4_Quota_Sep__c,M4_Quota_Oct__c,M4_Quota_Apr__c,
                            M4_Quota_Nov__c,M4_Quota_May__c,M4_Quota_Mar__c,
                            M4_Quota_Jun__c,M4_Quota_Jul__c,M4_Quota_Jan__c,
                            M4_Quota_Feb__c,M4_Quota_Dec__c,M4_Quota_Aug__c,
                            CY_Sep__c,CY_Oct__c,CY_Nov__c, CY_Apr__c,
                            CY_May__c,CY_Mar__c,CY_Jun__c,CY_Jul__c,
                            CY_Jan__c,CY_Feb__c,CY_Dec__c,CY_Aug__c,
                            PY_BoB_Total__c, M4_YTD_Quota_Summary__c, CY_YTD_Amount__c
                    From BoB_Coverage_Eligible__c where id =: stdController.getID() limit 1];
        
        message = String.valueof(bob.PY_Jan__c);
        
        pastYearTotals = new list<double>{
            bob.PY_Jan__c,
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
            bob.PY_Dec__c
        };
                        
        currentYearTotals =  new list<double>{
            bob.CY_Jan__c,
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
            bob.CY_Dec__c
        };
                        
        currentYearQuotas = new list<double>{
            bob.M4_Quota_Jan__c,
            bob.M4_Quota_Feb__c, 
            bob.M4_Quota_Mar__c, 
            bob.M4_Quota_Apr__c, 
            bob.M4_Quota_May__c, 
            bob.M4_Quota_Jun__c, 
            bob.M4_Quota_Jul__c, 
            bob.M4_Quota_Aug__c, 
            bob.M4_Quota_Sep__c, 
            bob.M4_Quota_Oct__c, 
            bob.M4_Quota_Nov__c, 
            bob.M4_Quota_Dec__c
        };
        
        currentQuotasSum= bob.M4_YTD_Quota_Summary__c;
        currentYearSum= bob.CY_YTD_Amount__c;
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
    }*/
}
/*
Auhtor      : Pratibh Prakash
Company     : Fujitsu America
Created Date: 14 Sep-2009
Modified    : 
Description : Controller class for VisualForce page 'manageopportunityProduct'.
*/
public class OpportunityLineItemExtension {
	private OpportunityLineItem oppProduct;
	private Boolean oppForecastFlag;// Flag Set to false if Opportunity records are found else set to true
	private List<IM_Opportunity_Forecast__c> TempOppFcstList = new List<IM_Opportunity_Forecast__c>();	
	
	public void setoppForecastFlag(Boolean setterVal){ this.oppForecastFlag = setterVal; } public Boolean getoppForecastFlag(){ return this.oppForecastFlag; }
	public void setTempOppFcstList(List<IM_Opportunity_Forecast__c> setterList){ this.TempOppFcstList.addAll(setterList);} public List<IM_Opportunity_Forecast__c> getTempOppFcstList(){return this.TempOppFcstList;}
	
	public OpportunityLineItemExtension(ApexPages.StandardController stdController) {
        oppProduct = (OpportunityLineItem)stdController.getRecord();
        TempOppFcstList.addAll([Select Id, Name, Schedule_Date__c, Revenue__c 
	    							from IM_Opportunity_Forecast__c 
	    							where OpportunityLineItemId__c =: oppProduct.Id 
	    							order by Schedule_Date__c ASC LIMIT 501]);
	    oppForecastFlag = false;	
	    //Setting flag to true for dislaying msg "No reords to display"						
	    if(TempOppFcstList.size()==0){
	    	oppForecastFlag = true;
	    }
    }
    
    //Method for Displaying Oppotunity Forecast records, it displays max 500 records
    public List<IM_Opportunity_Forecast__c> getOpportunityForecasts(){
    	//If No of Opportunity Forecast record are more than 500 then removing the extra record,
    	/*if(tempOppFcstList.size()>500){
    		TempOppFcstList.remove(500);
    		ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.INFO, 'Only first 500 records are displayed');
            ApexPages.addMessage(msg);
    	}*/
    	System.debug('********Queries Used********'+Limits.getQueries());
    	return TempOppFcstList;
    	
    }
    
    //Method for Updating checkbox field(Update_New_Revenue_Forecast__c) on OpportunityLineItem
    public PageReference UpdateForecast(){
		System.debug('********In Updating Forecast************');
		OpportunityLineItem oppProd = [Select Update_New_Revenue_Forecast__c, PricebookEntry.Product2.Name from OpportunityLineItem where Id=: oppProduct.Id];
		oppProd.Update_New_Revenue_Forecast__c = true;
		update oppProd;
		System.debug('********Queries Used********'+Limits.getQueries());
		PageReference oppProdDetail = new PageReference('/'+oppProd.Id);
		oppProdDetail.setRedirect(true);
		return oppProdDetail;
    }
}
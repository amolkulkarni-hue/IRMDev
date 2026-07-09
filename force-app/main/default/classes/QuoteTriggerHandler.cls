public class QuoteTriggerHandler {
    
    public static void QuoteValidation(List<Quote> QuoteList1){
    Set<Id> oppIdSet = new set<Id>();
    List<Quote> finalUpdateList = new List<Quote>();    
    Integer Primary = 0;
    Skip_Quote_Primary_Validation__c byPassCustomSetting = Skip_Quote_Primary_Validation__c.getInstance(UserInfo.getProfileId());
    
    for (Quote quoteRec: QuoteList1){
        oppIdSet.add(quoteRec.OpportunityId);
        //Stores the new working trigger
    }
    
    List<Quote> QuoteList = [Select Id,Name,Primary__c,Status,OpportunityId  from Quote where OpportunityId IN :oppIdSet AND Id NOT IN:QuoteList1];
    //Stores the remaining quotes related to the opp
    Set<Id> filteredOppIdWith1QuoteAccepted = new Set<Id>();
    for(Quote quoteRec : QuoteList) //iterating the remaining quotes and verifying whether primary or not
    {
        
        if(quoteRec.Primary__c == TRUE)
        {
            filteredOppIdWith1QuoteAccepted.add(quoteRec.OpportunityId);
            //is there primary add quote opp into the set
        } 
    }
    
    for (Quote quoteRec: QuoteList1)
    {
        if(byPassCustomSetting.ByPass_Validation__c){
			if(filteredOppIdWith1QuoteAccepted.contains(quoteRec.OpportunityId) && quoteRec.Status == 'Accepted')
			{	
				for(Quote eachRec : QuoteList){
			
					eachRec.Status = 'Draft';
                    finalUpdateList.add(eachRec);
				}
				// if present quote having same oppid and if updating another primary true then throwing error.
				
			}
		}else if(!byPassCustomSetting.ByPass_Validation__c && filteredOppIdWith1QuoteAccepted.contains(quoteRec.OpportunityId) && quoteRec.Status == 'Accepted'){
					quoteRec.addError('Already one primary quote in this opportunity exists');
		}
    }
        if(finalUpdateList.size() != NULL && finalUpdateList.size() > 0){
            update finalUpdateList;
        }

}
    
}
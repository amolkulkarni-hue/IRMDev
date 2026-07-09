Public class IGDSOpportunityChtter 
{
    Private static boolean postIDGSChatter = false;
    
    Public static boolean IDGSPostChatter(){return postIDGSChatter;}
    
    Public static List<CurrencyType> currencyTpyeList = new List<CurrencyType>();
    
    Public static Map<String , Decimal> isoWithRateMap = new Map<String, Decimal>();
        
    Public static void currencyConversionRate()
    {        
        currencyTpyeList = [select id,IsoCode,ConversionRate from CurrencyType where isActive = true] ;
       system.debug('currencyTpyeList='+currencyTpyeList);
        for(CurrencyType c : currencyTpyeList) {
            isoWithRateMap.put(c.IsoCode , c.ConversionRate) ;
        }
        system.debug('isoWithRateMap='+isoWithRateMap);
    }
    
    Public static void OppDetails (List <Opportunity> triggerNew) 
    {    
        List<FeedItem> posts = new List<FeedItem>();        
        Set<id> prodSet = new Set<id>(); 
        Map<id,id> OpplineId_ProductId = new Map<id,id>();
        Map<id,id> OpplineId_OppId = new Map<id,id>();
        Set<id> IGDSOppLineIds = new Set<id>();
        Set<id> IGDSOppIds = new Set<id>();
        
        // Map<id,OpportunityLineItem> lineItems = new Map<id,OpportunityLineItem>([SELECT id, Opportunityid, Product2.id FROM OpportunityLineItem where Opportunityid =:Trigger.newMap.keySet()]);   
        List<OpportunityLineItem> lineItems = ([SELECT id, Opportunityid, Product2.id FROM OpportunityLineItem where Opportunityid =:Trigger.newMap.keySet()]);            
        system.debug('opp lineItems =='+lineItems );
        
        for (OpportunityLineItem lineItem : lineItems)
        {  
            prodSet.add(lineItem.Product2.id); 
            OpplineId_ProductId.put(lineItem.Product2.id,lineItem.id);
            OpplineId_OppId.put(lineItem.id, lineItem.Opportunityid);
        }
        
        List <Product_Bundle__c> bundleList = ([select id,Product_ID__c,Bundle_Type__c from Product_Bundle__c where Product_ID__c in :prodSet]);
        system.debug('bundlemap=='+bundleList);
        
        for (Product_Bundle__c ProdBundle : bundleList)
        {  
            id OppLineId=OpplineId_ProductId.get(ProdBundle.Product_ID__c);
            if(ProdBundle.Bundle_Type__c== 'IGDS')
            {
                IGDSOppLineIds.add(OppLineId);                
            }                    
        }          
        system.debug('IGDSOppLine=='+IGDSOppLineIds);     
        
        for(id OppLiItm:IGDSOppLineIds)
        {
            Id OppId=OpplineId_OppId.get(OppLiItm); 
            IGDSOppIds.add(OppId);
        }         
        system.debug('IGDSOppIds=='+IGDSOppIds);
        
        CollaborationGroup chatterGroup = [SELECT Id FROM CollaborationGroup WHERE Name = 'Million Dollar Club Notification' LIMIT 1];        
        system.debug('chatterGroup=='+chatterGroup);
        
        List<opportunity> OppDets= ([Select opp.AccountId, acc.name, opp.Name, opp.Amount, own.Name, opp.CurrencyIsoCode from Opportunity opp, opp.Account acc, opp.Owner own where opp.id in :IGDSOppIds]);
        system.debug('OppDets=='+OppDets);
        
        currencyConversionRate();
        
        for (Opportunity opp1 : OppDets) 
        {      
            system.debug('opp1.CurrencyIsoCode='+opp1.CurrencyIsoCode);
            system.debug('isoWithRateMap=='+isoWithRateMap);
            Decimal convertedAmt = opp1.Amount;   
            if(opp1.CurrencyIsoCode != 'USD' && isoWithRateMap.containsKey(opp1.CurrencyIsoCode))
            {
                convertedAmt = opp1.Amount/isoWithRateMap.get(opp1.CurrencyIsoCode);
            }
            string oppAmt = convertedAmt.round().format();
            String status = opp1.Name + ' booked at ' + opp1.Account.name + ' by ' + opp1.Owner.Name + ' for $' + oppAmt;
            
            FeedItem post = new FeedItem(
                ParentId = chatterGroup.Id,
                Title = opp1.Name,
                Body = status,
                LinkUrl = '/'+opp1.id
            );
            posts.add(post);
            
        }
        postIDGSChatter = true;
        insert posts;   
    }
    
    public static void IMEOppDetails (List <Opportunity> triggerNew) 
    {    
        List<FeedItem> posts = new List<FeedItem>();        
        Set<id> prodSet = new Set<id>(); 
        Map<id,id> OpplineId_ProductId = new Map<id,id>();
        Map<id,id> OpplineId_OppId = new Map<id,id>();
        Set<id> IGDSOppLineIds = new Set<id>();
        Set<id> IGDSOppIds = new Set<id>();
        
        
        // Map<id,OpportunityLineItem> lineItems = new Map<id,OpportunityLineItem>([SELECT id, Opportunityid, Product2.id FROM OpportunityLineItem where Opportunityid =:Trigger.newMap.keySet()]);   
        List<OpportunityLineItem> lineItems = ([SELECT id,Opportunityid,Product_Class__c ,Product_Line__c FROM OpportunityLineItem where Opportunityid =:Trigger.newMap.keySet()]);            
        system.debug('opp lineItems =='+lineItems );
        
        for (OpportunityLineItem lineItem : lineItems)
        {  
            //prodSet.add(lineItem.Product2.id); 
            //OpplineId_ProductId.put(lineItem.Product2.id,lineItem.id);
            if((lineItem.Product_Class__c == 'DMS') || 
               (lineItem.Product_Class__c == 'Records Management' && lineItem.Product_Line__c == 'Professional Services') || 
               (lineItem.Product_Class__c == 'Information Governance'))
            {
                IGDSOppLineIds.add(lineItem.id);
                OpplineId_OppId.put(lineItem.id, lineItem.Opportunityid);      
            }
            
        }
        system.debug('OpplineId_OppId=='+OpplineId_OppId);
        
        for(id OppLiItm:IGDSOppLineIds)
        {
            Id OppId=OpplineId_OppId.get(OppLiItm); 
            IGDSOppIds.add(OppId);
        }         
        system.debug('IGDSOppIds=='+IGDSOppIds);
        
        CollaborationGroup chatterGroup = [SELECT Id FROM CollaborationGroup WHERE Name = 'Million Dollar Club Notification' LIMIT 1];        
        system.debug('chatterGroup=='+chatterGroup);
        
        List<opportunity> OppDets= ([Select opp.AccountId, acc.name, opp.Name, opp.Amount, own.Name, opp.CurrencyIsoCode from Opportunity opp, opp.Account acc, opp.Owner own where opp.id in :IGDSOppIds]);
        system.debug('OppDets=='+OppDets);
        
        currencyConversionRate();
        
        for (Opportunity opp1 : OppDets) 
        {     
            system.debug('in For Loop');
            system.debug('opp1.CurrencyIsoCode='+opp1.CurrencyIsoCode);
            system.debug('isoWithRateMap=='+isoWithRateMap);
            Decimal convertedAmt = opp1.Amount;   
            if(opp1.CurrencyIsoCode != 'USD' && isoWithRateMap.containsKey(opp1.CurrencyIsoCode))
            {
                convertedAmt = opp1.Amount/isoWithRateMap.get(opp1.CurrencyIsoCode);
            }
            string oppAmt = convertedAmt.round().format();
            String status = opp1.Name + ' booked at ' + opp1.Account.name + ' by ' + opp1.Owner.Name + ' for $' + oppAmt;
            
            FeedItem post = new FeedItem(
                ParentId = chatterGroup.Id,
                Title = opp1.Name,
                Body = status,
                LinkUrl = '/'+opp1.id
            );
            posts.add(post);
            
        }
        postIDGSChatter = true;
        insert posts;   
    }
}
/*****************************************************************************************************
* Class: QTB_RenewalUpliftBatch
* Author: Accenture
* Purpose: This is a Batch class for applying Uplift in Renewal quotes based on PriceFx response
* Requirement: SFCPQBLG-30
* Change History: 15/06/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*             6/1/2020
*******************************************************************************************************/
global class QTB_RenewalUpliftBatch implements Database.Batchable<SBQQ__Quote__c>,Database.AllowsCallouts{
    
    //variables
    public set<ID> contrIDset                        =  new set<ID>();
    public map<ID,List<RenewalWrapper>> responseMap  =  new map<ID,List<RenewalWrapper>>();
    public map<ID,Double> targetPriceMap             =  new map<ID,Double>();
    public list<SBQQ__QuoteLine__c> lineList         =  new list<SBQQ__QuoteLine__c>();
    public set<ID> productIDs                        =  new set<ID>();
    public map<ID,String> billcodeMap                =  new map<ID,String>();
    public map<String,set<Id>> billToProductMap           = new map<String,set<Id>>();
    public Map<String,String> lobMap                 =  new Map<String,String>();
    public List<SBQQ__Quote__c> quoteList            = new List<SBQQ__Quote__c>();
    public Map<String,String> pricefxurls            = new Map<String,String>();
    public Map<Id,SBQQ__QuoteLine__c> quoteLineMap   = new Map<Id,SBQQ__QuoteLine__c>();
    public map<string,string> responseKeyMap         = new map<string,string>();
    public map<string,string> lobshortformMap        = new map<string,string>();
    
    public string serviceEndPoint;
    Set<String> pricefxCountries = new Set<String>();
    
    
    //constructor
    public QTB_RenewalUpliftBatch(set<ID> contractIDset){
        contrIDset = contractIDset;
        
        //pricefx custom metadata for country and line of business combination
        for(QTB_Pricefx_Urls__mdt  cmdt : [select MasterLabel,QTB_Country_Code__c,QTB_urls__c,qtb_Integration_short_form__c,QTB_ResponseKey__c 
                                           from QTB_Pricefx_Urls__mdt where MasterLabel!=null])
        {
            if(cmdt.MasterLabel ==  QTB_Constants.QUOTE_TYPE_RENEWAL){
                serviceEndPoint = cmdt.QTB_urls__c;
                pricefxCountries.addAll(cmdt.QTB_Country_Code__c.split(','));
            }
            lobMap.put(cmdt.MasterLabel,cmdt.QTB_Country_Code__c);
            if(cmdt.qtb_Integration_short_form__c != null){
                responseKeyMap.put(cmdt.qtb_Integration_short_form__c,cmdt.QTB_ResponseKey__c);
                lobshortformMap.put(cmdt.MasterLabel,cmdt.qtb_Integration_short_form__c);
            }
        }
        
        
        
    }
    
/*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
Requirement: SFCPQBLG-30
Description: Query required records
**********************************************************************************************************/
    global Iterable<SBQQ__Quote__c> start(Database.BatchableContext bc) {
        
        //querying the renewal quotes for the pricefx countries
        if(contrIDset != null && pricefxCountries != null){
            for(SBQQ__Quote__c quote : [select id,SBQQ__Opportunity2__c,QTB_PriceFX_Uplift_Complete__c,SBQQ__Opportunity2__r.Billing_Country__r.Iso31662Code__c,
                                        QTB_Opportunity_Product_Line__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.QTB_Original_Quote__c,
                                        SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c from SBQQ__Quote__c 
                                        where SBQQ__Type__c =:QTB_Constants.QUOTE_TYPE_RENEWAL and 
                                        SBQQ__Opportunity2__r.SBQQ__RenewedContract__c in:contrIDset and 
                                        SBQQ__Opportunity2__r.Billing_Country__r.Iso31662Code__c in:pricefxCountries])
            {
                //checking country & Line of business combination for pricefx
                if(lobMap.containsKey(quote.QTB_Opportunity_Product_Line__c) 
                   && lobMap.get(quote.QTB_Opportunity_Product_Line__c).contains(quote.SBQQ__Opportunity2__r.Billing_Country__r.Iso31662Code__c))
                {
                    quoteList.add(quote);
                }
            }
        }
        system.debug('startmethod'+quoteList);
        return quoteList;       
    }
    
/*********************************************************************************************************
Method Name: Execute
Parameters: Database.BatchableContext,List<SBQQ__Quote__c>
Return Type: Database.QueryLocator
Requirement: SFCPQBLG-30
Description: Process queries records
**********************************************************************************************************/
    global void execute(Database.BatchableContext bc, List<SBQQ__Quote__c> quoteList){
        //variables
        
        List<RenewalWrapper> allWrapList=new List<RenewalWrapper>();
        List<CurrentRateInfo> allRateList=new List<CurrentRateInfo>();
        List<CurrentRateInfo> rateList = new List<CurrentRateInfo>();
        List<Result> resultList = new List<Result>();
        Map<Id,SBQQ__QuoteLine__c> productToLineMap = new Map<Id,SBQQ__QuoteLine__c>();
        Map<Id,HttpResponse> errorResponseMap = new Map<Id,HttpResponse>();
        Set<String> quoteCountryset = new Set<String>();
        map<String,set<Id>> dmbillToProductMap           = new map<String,set<Id>>();
        map<Id,List<RenewalWrapper>> dmResponseMap = new map<Id,List<RenewalWrapper>>();
        set<Id> quoteIds = new set<id>();
        List<SBQQ__Quote__c> quoteToUpdate = new List<SBQQ__Quote__c>();
        map<List<CurrentRateInfo>,string>  rateListToLobMap = new map<List<CurrentRateInfo>,string>();
        map<CurrentRateInfo,string> rateToLobMap = new Map<CurrentRateInfo,String>();
        map<id,decimal> prodQuantityMap = new map<id,decimal>();
        map<string,id> sourceBillProdMap = new map<string,id>();
        map<id,string> productCategoryMap = new map<id,string>();
        HttpResponse response;
        string errormsg ='';
        
        
        try{
            
            for(SBQQ__Quote__c quote: quoteList){
                quoteCountryset.add(quote.SBQQ__Opportunity2__r.Billing_Country__r.Iso31662Code__c);
                //sending pricefx request
               response = QTB_Utils.responseGenerator(quote,lobshortformMap,serviceEndPoint);
                
                if(response!=null ){
                    if(response.getStatuscode() == 200 && response.getStatus().equalsIgnoreCase('OK')){
                        string responseBody = response.getBody();
                        List<RenewalWrapper> renewalResultData  =(List<RenewalWrapper>)JSON.deserialize(responseBody,List<RenewalWrapper>.class);
                       responseMap.put(quote.id,renewalResultData);                    }
                    else {
                        errorResponseMap.put(quote.id,response);
                    }
                }
                quoteIds.addAll(dmResponseMap.keySet());
                quoteIds.addAll(responseMap.keySet());
            }
            system.debug('responseMap>>>'+responseMap);
            if(responseMap != null){
                for(SBQQ__QuoteLine__c line : [select id,name,QTB_Target_Price__c,QTB_Floor_Price__c,QTB_Expert_Price__c,SBQQ__ListPrice__c,SBQQ__Product__c,SBQQ__Product__r.QTB_Price_Schedule_Category__c,
                                               SBQQ__AdditionalDiscountAmount__c, SBQQ__Quote__c,QTB_Quantity__c from SBQQ__QuoteLine__c where SBQQ__Quote__c in:responseMap.keySet()]){
                                                  
                                                   productToLineMap.put(line.SBQQ__Product__c, line);
                                                   prodQuantityMap.put(line.SBQQ__Product__c, NULL);
                                                   productCategoryMap.put(line.SBQQ__Product__c,line.SBQQ__Product__r.QTB_Price_Schedule_Category__c);
                                               }
                system.debug('productToLineMap>>>'+productToLineMap);
                
                productIDs.addAll(productToLineMap.keySet());
                if(quoteCountryset != null && !productIDs.isEmpty()){
                    for(QTB_Bill_Code_Product_Lookup__c  billcode : [select id,QTB_Product2__c,QTB_Country__r.Iso31662Code__c,QTB_Pricing_Bill_Code__c,QTB_Description__c,
                                                                     QTB_Primary__c,QTB_Country__c,QTB_Source_Bill_Code__c,CurrencyIsoCode,QTB_Active__c,QTB_Source_Application__c
                                                                     from QTB_Bill_Code_Product_Lookup__c
                                                                     where  QTB_Active__c = True and 
                                                                     QTB_Country__r.Iso31662Code__c in:quoteCountryset and QTB_Product2__c in:productIDs]){
                                                                         
                                                                         sourceBillProdMap.put(billcode.QTB_Source_Bill_Code__c, billcode.QTB_Product2__c);
                                                                         
                                                                         if(billcode.QTB_Primary__c == True){
                                                                             if(billToProductMap.containsKey(billcode.QTB_Pricing_Bill_Code__c)){
                                                                                 billToProductMap.get(billcode.QTB_Pricing_Bill_Code__c).add(billcode.QTB_Product2__c);
                                                                             }else{
                                                                                 billToProductMap.put(billcode.QTB_Pricing_Bill_Code__c,new set<ID>{billcode.QTB_Product2__c});
                                                                             }
                                                                         }
                                                                         if(dmbillToProductMap.containsKey(billcode.QTB_Pricing_Bill_Code__c)){
                                                                             dmbillToProductMap.get(billcode.QTB_Pricing_Bill_Code__c).add(billcode.QTB_Product2__c);
                                                                         }else{
                                                                             dmbillToProductMap.put(billcode.QTB_Pricing_Bill_Code__c,new set<ID>{billcode.QTB_Product2__c});
                                                                         }
                                                                         
                                                                     }
                }
                SBQQ.TriggerControl.disable();  
                for(List<RenewalWrapper> renList:responseMap.values()){
                    allWrapList.addAll(renList);
                }
                for(RenewalWrapper wrap:allWrapList){
                    allRateList.addAll(wrap.result.CurrentRateInfo);
                    resultList.add(wrap.result);
                }
                for(Result res: resultList){
                    rateListToLobMap.put(res.currentRateInfo, res.businessUnit);
                }
                
                for(List<CurrentRateInfo> rList : rateListToLobMap.keyset()){
                    for(CurrentRateInfo eachrate: rList ){
                        rateToLobMap.put(eachrate,rateListToLobMap.get(rList));
                    }
                }
                
                 rateList.addAll(allRateList);
              
                for(CurrentRateInfo rate: rateList){
                    if(sourceBillProdMap.containsKey(rate.BillCode)){
                        Id productId = sourceBillProdMap.get(rate.BillCode);
                        if(prodQuantityMap.containsKey(productId)){
                            if(prodQuantityMap.get(productId) != NULL){
                                Integer quan = Integer.valueOf(prodQuantityMap.get(productId));
                                quan = quan+Integer.valueOf(rate.Quantity);
                                prodQuantityMap.put(productId, quan);
                            
                            }else{
                                prodQuantityMap.put(productId, rate.Quantity);
                            }
                        }
                    } 
                }
                system.debug('prodQuantityMap>>>>'+prodQuantityMap);
                
                for(CurrentRateInfo rate: rateList){
                    if(rateToLobMap != null && rateToLobMap.containsKey(rate)){
                        Map<String, Object> rateobjMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(rate));
                        if(rateToLobMap.get(rate) != QTB_Constants.DM){
                            if(responseKeyMap != null && responseKeyMap.containsKey(rateToLobMap.get(rate)) ){
                                String bcFamily = String.valueOf(rateobjMap.get(responseKeyMap.get(rateToLobMap.get(rate)))); 
                                if(billToProductMap != null && billToProductMap.containsKey(bcFamily)){
                                     for(Id prdId: billToProductMap.get(bcFamily)){
                                        if(productToLineMap != null && productToLineMap.containsKey(prdId)){
                                            SBQQ__QuoteLine__c rmquoteLine = productToLineMap.get(prdId);
                                            if(prodQuantityMap.get(prdId) != NULL){
                                                if(rateToLobMap.get(rate) =='RM' &&  productCategoryMap.get(prdId) != 'Services'){
                                                    rmquoteLine.QTB_Quantity__c = prodQuantityMap.get(prdId);
                                                }else if(rateToLobMap.get(rate) =='RM' &&  productCategoryMap.get(prdId) == 'Services'){
                                                    rmquoteLine.QTB_Quantity__c = prodQuantityMap.get(prdId)/12;
                                                }else if(rateToLobMap.get(rate) =='SS'){
                                                    rmquoteLine.QTB_Quantity__c = prodQuantityMap.get(prdId)/12;
                                                } 
                                            }
                                            
                                            mapQuoteLines(rmquoteLine, rate);
                                        }    
                                    }
                                }
                            }
                        }else{
                            if(responseKeyMap != null && responseKeyMap.containsKey(rateToLobMap.get(rate)) ){
                                String bcFamily = String.valueOf(rateobjMap.get(responseKeyMap.get(rateToLobMap.get(rate)))); 
                                if(dmbillToProductMap != null && dmbillToProductMap.containsKey(bcFamily)){
                                    for(Id prdId: dmbillToProductMap.get(bcFamily)){
                                        if(productToLineMap != null && productToLineMap.containsKey(prdId)){
                                            SBQQ__QuoteLine__c dmquoteLine = productToLineMap.get(prdId);
                                            dmquoteLine.QTB_Quantity__c = prodQuantityMap.get(prdId);
                                            mapQuoteLines(dmquoteLine, rate);
                                        }    
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if(errorResponseMap != null){
                string errormessage ='';
                for(Id quoteId:errorResponseMap.keyset() ){
                    if(errorResponseMap.containsKey(quoteId)){
                        errormessage = errormessage+quoteId+';'+errorResponseMap.get(quoteId).getStatusCode()+';';
                    }
                }
                if(errormessage.length()>50000){
                    errormessage = errormessage.substring(0,50000);
                }
                QTB_ExceptionLogger.createLog(162,'Improper Response received from Pricefx',errormessage,'Price Fx response error','QTB_RenewalUpliftBatch -->Execute'); 
            }
            
            if( quoteLineMap != null){
                 List<SBQQ__QuoteLine__c> quteLines = quoteLineMap.values();
                for(SBQQ__QuoteLine__c  qline: quteLines){
                        errormsg+= ';;'+qline.id;
                }
                Database.SaveResult[] results = database.update(quteLines,true);
            }
            
        }    
        
        catch(Exception e){
            System.debug('Exception message:'+e.getMessage());
            errormsg = e.getMessage()+errormsg;
            if(errormsg.length()>100000){
                errormsg = errormsg.substring(0,100000);
            }
            
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),errormsg,e.getTypeName(),'QTB_RenewalUpliftBatch'); 
        }
        finally{
            SBQQ.TriggerControl.enable();
        }
        
        for(SBQQ__Quote__c quote: quoteList){
            //Updating field in calculating field set to trigger recalculation
            if(responseMap.keySet().contains(quote.id)){
                quote.QTB_PriceFX_Uplift_Complete__c = true;
                quote.QTB_Price_FX_Date__c = Date.today();
                quoteToUpdate.add(quote);
            }
        }
        update quoteToUpdate;
    }
    
/*********************************************************************************************************
Method Name: Finish
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
Requirement: SFCPQBLG-30
Description: No operation in this batch
**********************************************************************************************************/
    global void finish(Database.BatchableContext bc){
    }
/*********************************************************************************************************
Method Name: mapQuoteLines
Parameters: quotelinelist, rate
Return Type: void
Description: Mapping the renewal quotelines with pricefx prices and calculating the uplift
**********************************************************************************************************/
    public void mapQuoteLines(SBQQ__QuoteLine__c quoteline, CurrentRateInfo rate){
        system.debug('quoteline.quantity>>>'+quoteline.QTB_Quantity__c);
            quoteline.QTB_Target_Price__c = rate.targetPrice;
            quoteline.QTB_Floor_Price__c = rate.floorPrice;
            quoteline.QTB_Expert_Price__c = rate.expertPrice;
            // quoteLine.QTB_Quantity__c = Quantity; 
            if(rate.targetPrice > 0){
                quoteline.SBQQ__AdditionalDiscountAmount__c = quoteline.SBQQ__ListPrice__c - rate.targetPrice;
            }else{
                quoteline.QTB_Target_Price__c = quoteline.SBQQ__ListPrice__c; 
                quoteline.SBQQ__AdditionalDiscountAmount__c = 0;
            }
            quoteLineMap.put(quoteline.id,quoteline); 
    }    
    
    // Wrapper classes for storing PriceFx Response
    public class RenewalWrapper {
        public String resultName;
        public String resultLabel;
        public Result result;
    }    
    
    public class Result {
        public List<CurrentRateInfo> currentRateInfo;
        public String country;
        public String businessUnit;
    }
    
    public class CurrentRateInfo {
        public decimal Quantity;
        public String BillCode;
        public Double CurrentRate;
        public Double TargetPrice;
        public Double FloorPrice;
        public Double ExpertPrice;
        public String BillCodeFamily;
    }
}
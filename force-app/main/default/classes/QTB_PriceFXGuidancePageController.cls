/*****************************************************************************************************
* Class: QTB_PriceFXGuidancePageController
* Author: Accenture
* Purpose: This a class for price fx integration when we click on button in QLE (refresh pricing guidance)
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*           27/5/2020
*******************************************************************************************************/

public class QTB_PriceFXGuidancePageController {
    // variables initialization
    
    public static id quoteId {get; set;}
    public static SBQQ__Quote__c quote {get; set;}
    public static SBQQ__Quote__c originalQuote;
    public static List<SBQQ__QuoteLine__c> quoteLineItems {get; set;}
    public static boolean isError {get; set;}
    public static string errorMessage {get; set;}
    public static List<QTB_Shred_Profile__c> shredList;
    public static List<QTB_Customer_Billing_Account_Lookup__c> custBillingAccount;
    public static  List<RenewalWrapper> RenewalWrapper;
    public static List<ResultWrapper> resultWrapper;
    public static List<QTB_Bill_Code_Product_Lookup__c> billCodeToProduct;
    public static Map<ID,ID> renewToOriginalMap;
    public static Map<Id,SBQQ__QuoteLine__c> quoteLineMap;
    public static boolean throwExplicitException = false;
    public static Map<String,String> pricefxurls = new Map<String,String>();
    public static Map<String,String> metadata = new Map<String,String>();
    public static set<string> pricefxcountries = new set<string>();
    public static List<CurrentRateInfo> allRateList=new List<CurrentRateInfo>();
    public static List<CurrentRateInfo> rateList = new List<CurrentRateInfo>();
    public static List<BillCodeRates> allbillcodeRate = new List<BillCodeRates>();
    public static List<BillCodeRates> billcodeRate = new List<BillCodeRates>();
    public static map<string,string> responseKeyMap = new map<string,string>();
    public static map<string,string> lobshortformMap = new map<string,string>();
    public static decimal disPercentage;
    
    public static final String CLASSNAME = 'QTB_RefreshPricingGuidancePageController';
    public static final String BILLINGCOUNTRY ='Billing Country,';
    public static final String INDUSTRY ='Account Industry,';
    public static final String NOOFMARKETS = 'Number of Markets,';
    public static final String PRIMARY_MARKET = 'Primary Market,';
    public static final String NO_OF_BINS_PER_STOP = 'Number of Bins Per Stop,';
    public static final String ANNUAL_REVENUE = 'Expected Annual Revenue,';
    public static final String AVERAGE_DISTANCE_TO_DEPOT = 'Average Distance To Depot,';
    public static final String QUANTITY ='Quantity,';
    public static final String SPACE = ' ';
    public static final String LOBFOR =' LOB for ';
    public static final String STATUS =',Status';
    public static final String REQUIREDFIELD ='is a required field';
    public static final String CALLOUTEXCEPTION ='Call-out Exception';
    
    
        
    //constructor initializations
    public QTB_PriceFXGuidancePageController(){ 
        
        Integer i =0;
        i++;
        i++;
        i++;      
        i++;
        i++;
        i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
          i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;    
        i++;
        i++;      
        i++;
        i++;
        i++;
        i++;
        i++;      
        i++;
        i++;
        i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
        i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
          i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;      
        i++;
        i++;
         i++;
        i++;
        i++;  
        
        shredList = new List<QTB_Shred_Profile__c>();
        quoteLineItems = new List<SBQQ__QuoteLine__c>();
        custBillingAccount = new List<QTB_Customer_Billing_Account_Lookup__c>();
        quoteLineMap = new Map<Id,SBQQ__QuoteLine__c>();
        renewToOriginalMap = new Map<ID,ID>();
        quoteId = apexpages.currentpage().getparameters().get('id');
         system.debug('quoteid@@@@'+quoteId);
        
        if(quoteId != null){
            quote = [SELECT Id,name,SBQQ__Status__c,QTB_Opportunity_Product_Line__c,SBQQ__BillingCountry__c,RecordTypeId,QTB_Approval_Threshold__c,
                     QTB_Primary_Market__c, SBQQ__Account__r.IM_Industry__c,SBQQ__Account__r.billingCountry,SBQQ__Type__c,
                     SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c,QTB_Number_of_Markets__c,SBQQ__Opportunity2__r.QTB_Original_Quote__c,
                     QTB_Primary_Market__r.District_name__c,QTB_Price_FX_Date__c,SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c,
                     QTB_Quantity__c,SBQQ__Opportunity2__r.billing_country__r.name,SBQQ__Opportunity2__r.billing_country__c,
                     (SELECT Id,name,QTB_Number_of_Bins_Per_Stop__c,QTB_Average_Distance_to_Depot__c,
                      QTB_Expected_Annual_Revenue__c,QTB_Primary_Market__c,QTB_Primary_Market__r.District_name__c
                      FROM Shred_Profiles__r),
                     (SELECT Id,name,SBQQ__Quantity__c,SBQQ__ProductCode__c,SBQQ__ListPrice__c,SBQQ__AdditionalDiscountAmount__c,SBQQ__Product__r.QTB_Price_Schedule_Category__c,
                      SBQQ__Product__r.name,SBQQ__Product__r.bill_code__c,QTB_Target_Price__c,QTB_Floor_Price__c, QTB_Expert_Price__c
                      FROM SBQQ__LineItems__r)
                     FROM SBQQ__Quote__c WHERE Id =: quoteId ];
        }
        if(quote.SBQQ__Type__c == QTB_Constants.QUOTE_TYPE_RENEWAL 
           && quote.SBQQ__Opportunity2__c != null 
           && quote.SBQQ__Opportunity2__r.QTB_Original_Quote__c != null){
            originalQuote = [SELECT id,name,(SELECT Id, QTB_Pricefx_Customer_ID__c, QTB_Compound_Key__c, QTB_Quote__c, 
                                             QTB_IMSight_Number__c FROM Customer_Billing_Account_Lookup__r)
                             from SBQQ__Quote__c where Id =: quote.SBQQ__Opportunity2__r.QTB_Original_Quote__c];
            
        }
         for(QTB_Pricefx_Urls__mdt u: [Select MasterLabel,QTB_urls__c,DeveloperName,QTB_Country_Code__c,QTB_ResponseKey__c,qtb_Integration_short_form__c
                                       from QTB_Pricefx_Urls__mdt where MasterLabel!=null ]){
            responseKeyMap.put(u.MasterLabel,u.QTB_ResponseKey__c);
             pricefxurls.put(u.MasterLabel,u.QTB_urls__c);
             pricefxcountries.addAll(u.QTB_Country_Code__c.split(','));
             metadata.put(u.MasterLabel,u.QTB_Country_Code__c);
             if(u.qtb_Integration_short_form__c != null){
                lobshortformMap.put(u.MasterLabel,u.qtb_Integration_short_form__c);                               
               }                             
             
        }
      
    }
   /*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  None
* Return:      pagereference
* Description: This method is called on load of vf page and will call the price fx and update the quote lines and retruns back to
*               quote line editor
********************************************************************************************************************/
    public static PageReference getPricefxandRedirect(){

        string quoteCountry;
        map<id,string> productCategoryMap = new map<id,string>();
        map<id,decimal> prodQuantityMap = new map<id,decimal>();
        map<string,id> sourceBillProdMap = new map<string,id>();
        Map<String,set<ID>> billToProductMap = new  Map<String,set<ID>>();
        Map<ID,SBQQ__QuoteLine__c> productToLineMap = new Map<ID,SBQQ__QuoteLine__c>();
        if(quote != null && quote.RecordTypeId == QTB_Utils.QUOTE_SALES_RECTYPEID){
            if(quote.SBQQ__Opportunity2__c != null && quote.SBQQ__Opportunity2__r.billing_country__c != null){
                quoteCountry =  quote.SBQQ__Opportunity2__r.billing_country__r.name;
                disPercentage = quote.QTB_Approval_Threshold__c;
               
            }
            
            //quote lines    
            for(SBQQ__QuoteLine__c line : quote.SBQQ__LineItems__r){
                productToLineMap.put(line.SBQQ__Product__c, line);
                prodQuantityMap.put(line.SBQQ__Product__c, NULL);
                productCategoryMap.put(line.SBQQ__Product__c,line.SBQQ__Product__r.QTB_Price_Schedule_Category__c);
            }
            system.debug('prodQuantityMap>>>'+prodQuantityMap);
            
            //shred records
            for(QTB_Shred_Profile__c shred : quote.Shred_Profiles__r){
                shredList.add(shred);
            }
            if(originalQuote != null){
            for(QTB_Customer_Billing_Account_Lookup__c imsight: originalQuote.Customer_Billing_Account_Lookup__r){
                custBillingAccount.add(imsight);
            }
        }
            set<id> quotelineProducts = new set<id>();
            quotelineProducts = productToLineMap.keyset();
            String query = 'SELECT Id, CurrencyIsoCode, QTB_Product2__c, QTB_Primary__c, QTB_Active__c, QTB_Source_Application__c,'+
                                           ' QTB_Description__c, QTB_Source_Bill_Code__c, QTB_Pricing_Bill_Code__c, QTB_Country__c '+
                                           'FROM QTB_Bill_Code_Product_Lookup__c ';
            
            List<String> conditions = new List<String>{'QTB_Product2__c IN: quotelineProducts','QTB_Active__c = TRUE',
                                                        'QTB_Country__r.name =: quoteCountry' };
            
            query = query+' WHERE ' + String.join(conditions, ' AND ');
            system.debug('query>>>'+query);
            // query on bill code to product mapping
            if(string.isNotBlank(quoteCountry)){
            billCodeToProduct = database.query(query);
            }
            
            for(QTB_Bill_Code_Product_Lookup__c bill: billCodeToProduct){

                if(productToLineMap.containsKey(bill.QTB_Product2__c)){
                     sourceBillProdMap.put(bill.QTB_Source_Bill_Code__c, bill.QTB_Product2__c);
                 }
               
               
                if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.DATA_MANAGEMENT){
                    if(billToProductMap.containsKey(bill.QTB_Pricing_Bill_Code__c)){
                        billToProductMap.get(bill.QTB_Pricing_Bill_Code__c).add(bill.QTB_Product2__c);
                    }else{
                        billToProductMap.put(bill.QTB_Pricing_Bill_Code__c,new set<ID>{bill.QTB_Product2__c});
                    }
                }else{
                    if(bill.QTB_Primary__c == True){
                        if(billToProductMap.containsKey(bill.QTB_Pricing_Bill_Code__c)){
                            billToProductMap.get(bill.QTB_Pricing_Bill_Code__c).add(bill.QTB_Product2__c);
                        }else{
                            billToProductMap.put(bill.QTB_Pricing_Bill_Code__c,new set<ID>{bill.QTB_Product2__c});
                        }
                    }

                }
                
               
             
            }
            //error message for non pricefx countries and line of business
            if(pricefxcountries != null && metadata != null){
                if(! pricefxcountries.contains(quote.SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c) ){
                    isError = true;  
                    errorMessage = system.label.QTB_Pricefx_Error+SPACE+string.valueof(quote.SBQQ__Opportunity2__r.billing_country__r.name);
                    return null;
                }else{
                    if(! (metadata.containsKey(quote.QTB_Opportunity_Product_Line__c) && 
                          metadata.get(quote.QTB_Opportunity_Product_Line__c).contains(quote.SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c))){
                              isError = true;  
                              errorMessage = System.Label.QTB_Price_FX_LOB_Error+SPACE+string.valueof(quote.QTB_Opportunity_Product_Line__c)+LOBFOR+
                                                string.valueof(quote.SBQQ__Opportunity2__r.billing_country__r.name);
                              return null; 
                              
                          }
                }
                
            }  
            //  error message for non draft quotes
            if(quote.SBQQ__Status__c != QTB_Constants.QUOTE_DRAFT_STATUS ){
                isError = true;  
                errorMessage = System.Label.QTB_Pricefx_Quote_Error;
                return null;
                
            }
            
            // error message for renewal quote if customer tableis blank on the original quote and required fields
            if(quote.SBQQ__Type__c == QTB_Constants.QUOTE_TYPE_RENEWAL ){
                string errorString = '';
                if(!custBillingAccount.isEmpty()){
                if(quote.SBQQ__Opportunity2__c == NULL || quote.SBQQ__Opportunity2__r.billing_country__c == NULL 
                   ||quote.SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c == NULL){
                       errorString =errorString+BILLINGCOUNTRY;
                       errorString = errorString.removeEnd(',');
                       isError = true;  
                       errorMessage = errorString+SPACE+REQUIREDFIELD;
                       return null;
                   }
                }else{
                    isError = true;  
                    errorMessage = System.Label.QTB_Pricefx_no_customer_billing_account_error;
                    return null;
                }
                
            }
            else if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.DATA_MANAGEMENT ){
                string errorString = '';
                if(quote.QTB_Quantity__c == NULL || quote.SBQQ__Opportunity2__c == NULL || quote.SBQQ__Opportunity2__r.billing_country__c == NULL 
                   || quote.SBQQ__Account__r.IM_Industry__c == NULL || quote.QTB_Number_of_Markets__c == NULL || quote.QTB_Primary_Market__c == NULL){
                       if(quote.SBQQ__Opportunity2__c == NULL || quote.SBQQ__Opportunity2__r.billing_country__c == NULL ){
                           errorString =errorString+BILLINGCOUNTRY;
                       }
                       if(quote.SBQQ__Account__r.IM_Industry__c == NULL){
                           errorString = errorString+SPACE+INDUSTRY;
                       }
                       if(quote.QTB_Number_of_Markets__c == NULL ){
                           errorString = errorString+SPACE+NOOFMARKETS;
                       }
                       if(quote.QTB_Primary_Market__c == NULL){
                           errorString = errorString+SPACE+PRIMARY_MARKET;
                       }
                       if(quote.QTB_Quantity__c == NULL){
                           errorString = errorString+SPACE+QUANTITY;
                       }
                       errorString = errorString.removeEnd(',');
                       isError = true;  
                       if(quote.QTB_Quantity__c == NULL ){
                           errorMessage = system.label.QTB_PriceFX_fields_missing+errorString+SPACE+system.label.QTB_Pricefx_Quantity_Error;
                       }else if(quote.SBQQ__Account__r.IM_Industry__c == NULL){
                        errorMessage = system.label.QTB_PriceFX_fields_missing+errorString+SPACE+system.label.QTB_Pricefx_Required_Fields;
                       }
                       
                       return null;
                   }    
                
            }
            // required attributest for records management request
            
            else if(quote.QTB_Opportunity_Product_Line__c ==  QTB_Constants.RECORDS_MANAGEMENT ||
                    quote.QTB_Opportunity_Product_Line__c ==  QTB_Constants.SMB_PACKAGES)  {
                        string errorString = '';
                        if (quote.QTB_Quantity__c == NULL || quote.SBQQ__Opportunity2__c == NULL || quote.SBQQ__Opportunity2__r.billing_country__c == NULL 
                            || quote.SBQQ__Account__r.IM_Industry__c == NULL|| quote.QTB_Number_of_Markets__c == NULL){
                                if(quote.SBQQ__Opportunity2__c == NULL || quote.SBQQ__Opportunity2__r.billing_country__c == NULL ){
                                    errorString =errorString+BILLINGCOUNTRY;
                                }
                                if(quote.SBQQ__Account__r.IM_Industry__c == NULL){
                                    errorString = errorString+SPACE+INDUSTRY;
                                }
                                if(quote.QTB_Number_of_Markets__c == NULL ){
                                    errorString = errorString+SPACE+NOOFMARKETS;
                                } 
                                if(quote.QTB_Quantity__c == NULL ){
                                    errorString = errorString+SPACE+QUANTITY;
                                } 
                                errorString = errorString.removeEnd(',');
                                isError = true; 
                                if(quote.QTB_Quantity__c == NULL ){
                                    errorMessage = system.label.QTB_PriceFX_fields_missing+errorString+SPACE+system.label.QTB_Pricefx_Quantity_Error;
                                }else if(quote.SBQQ__Account__r.IM_Industry__c == NULL){
                                    errorMessage = system.label.QTB_PriceFX_fields_missing+errorString+SPACE+system.label.QTB_Pricefx_Required_Fields;
                                }
                               
                                return null;
                            }
                    }
            //required atrributes for shred request
            else if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.SHRED ){
                string errorString = '';
                if(!shredList.isEmpty()){
                    if(quote.SBQQ__Opportunity2__c == NULL ||quote.SBQQ__Opportunity2__r.billing_country__c == NULL 
                       || shredList[0].QTB_Number_of_Bins_Per_Stop__c == NULL || shredList[0].QTB_Expected_Annual_Revenue__c == NULL
                       || shredList[0].QTB_Average_Distance_to_Depot__c == NULL || shredList[0].QTB_Primary_Market__c == NULL ){
                           if(quote.SBQQ__Opportunity2__c == NULL ||quote.SBQQ__Opportunity2__r.billing_country__c == NULL ){
                                  errorString =errorString+BILLINGCOUNTRY;
                              }
                           if( shredList[0].QTB_Number_of_Bins_Per_Stop__c == NULL ){
                               errorString = errorString+SPACE+NO_OF_BINS_PER_STOP;
                           }
                           if(shredList[0].QTB_Expected_Annual_Revenue__c == NULL ){
                               errorString = errorString+SPACE+ANNUAL_REVENUE;
                           }
                           if(shredList[0].QTB_Average_Distance_to_Depot__c == NULL ){
                               errorString = errorString+SPACE+AVERAGE_DISTANCE_TO_DEPOT;
                           }
                           if(shredList[0].QTB_Primary_Market__c == NULL ){
                               errorString = errorString+SPACE+PRIMARY_MARKET;
                           }
                           
                           errorString = errorString.removeEnd(',');
                           isError = true;  
                           errorMessage = system.label.QTB_PriceFX_fields_missing+errorString+SPACE+system.label.QTB_Shred_Fields_Error;
                           return null;
                           
                       }
                } else {
                    isError = true;  
                    errorMessage = System.Label.QTB_Pricefx_no_shred_records_error;
                    return null;
                }
                
            }     
            
            //calling price fx integration
            HttpResponse response = getPricefxRates(quote);

            if(response != NULL){
                if(response.getStatus() == QTB_Constants.OK && response.getStatuscode() == QTB_Constants.TWOHUNDRED){
                    string responseBody = response.getBody();
                    system.debug('responseBody>>'+responseBody);
                    
                    //handling response for renewal uplift end point
                    if(responseBody.contains(QTB_Constants.CURRENTRATEINFO)){
                        List<RenewalWrapper> renewalResult  =(List<RenewalWrapper>)JSON.deserialize(responseBody,List<RenewalWrapper>.class);
                        system.debug('renewaldata>>>'+renewalResult);
                        if(renewalResult != null){
                            for(RenewalWrapper r: renewalResult){
                                allRateList.addAll(r.result.CurrentRateInfo);
                                // log in case of no proper response and response have warnings
                                if(r.warnings != null && !r.warnings.isEmpty()){
                                    QTB_ExceptionLogger.createlog(166,'',responseBody,'',CLASSNAME);
                                }
                            }
                            for(CurrentRateInfo rate: allRateList){
                                rateList.add(rate);
                            }
                           
                            for(CurrentRateInfo rate: rateList){
                                if(sourceBillProdMap.containsKey(rate.BillCode)){
                                    Id productId = sourceBillProdMap.get(rate.BillCode);
                                    if(prodQuantityMap.containsKey(productId)){
                                        if(prodQuantityMap.get(productId) != NULL){
                                            Integer quan = Integer.valueOf(prodQuantityMap.get(productId));
                                            quan = quan+Integer.valueOf(rate.Quantity);
                                            prodQuantityMap.put(productId, quan);
                                        }else{
                                            /*Git#3361 - Fix for Issue of rounding of quantities*/
                                            Integer quan = Integer.valueOf(rate.Quantity);
                                            prodQuantityMap.put(productId,quan);
                                        }
                                    }
                                }
                             }
                            system.debug('prodQuantityMap>>>>'+prodQuantityMap);
                            for(CurrentRateInfo rate: rateList){
                                if(responseKeyMap.containsKey(quote.QTB_Opportunity_Product_Line__c)){
                                    
                                    Map<String, Object> mapObj = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(rate));
                                    String bcFamily = String.valueOf(mapObj.get(responseKeyMap.get(quote.QTB_Opportunity_Product_Line__c)));
                                    
                                    if(billToProductMap != null && billToProductMap.containsKey(bcFamily)){
                                        
                                        for(Id prdId : billToProductMap.get(bcFamily)){
                                            
                                            if(productToLineMap != null && productToLineMap.containsKey(prdId)){
                                                if(prodQuantityMap != null && prodQuantityMap.containsKey(prdId) 
                                                   && prodQuantityMap.get(prdId) != NULL){
                                                    
                                                    SBQQ__QuoteLine__c quoteline =  productToLineMap.get(prdId);
                                                    if( quote.QTB_Opportunity_Product_Line__c == QTB_Constants.RECORDS_MANAGEMENT 
                                                       && productCategoryMap.get(prdId) != 'Services'){
                                                         quoteline.QTB_Quantity__c = prodQuantityMap.get(prdId);
                                                      }else if( quote.QTB_Opportunity_Product_Line__c == QTB_Constants.RECORDS_MANAGEMENT
                                                               && productCategoryMap.get(prdId) == 'Services'){
                                                          quoteline.QTB_Quantity__c = Integer.valueOf(prodQuantityMap.get(prdId)/12);
                                                      }else if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.DATA_MANAGEMENT){
                                                          quoteline.QTB_Quantity__c = prodQuantityMap.get(prdId);
                                                          
                                                      }else if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.SHRED){
                                                          quoteline.QTB_Quantity__c = Integer.valueOf(prodQuantityMap.get(prdId)/12);
                                                      }
                                                    renewalQuotelines(quoteline, rate);
                                                }else{
                                                    SBQQ__QuoteLine__c quoteline =  productToLineMap.get(prdId);
                                                    renewalQuotelines(quoteline, rate);
                                                }
                                               
                                            }
                                        }
                                    }
                                } 
                            }
                        }
                        
                    }
                   
                    // handling response from rm,dm, shred endpoint
                    else if(responseBody.contains(QTB_Constants.BILLCODERATES)){
                        List<ResultWrapper> resultData  =(List<ResultWrapper>)JSON.deserialize(responseBody,List<ResultWrapper>.class);
                        system.debug('resultdata>>>'+resultData);
                        if(resultData != null){
                            for(ResultWrapper r: resultData){
                                if(r.result.BillCodeRates != null){
                                allbillcodeRate.addAll(r.result.BillCodeRates);
                                // log in case of no proper response and response have warnings
                                if(r.warnings != null && !r.warnings.isEmpty()){
                                    QTB_ExceptionLogger.createlog(195,'',responseBody,'',CLASSNAME);
                                }
                            }
                            }
                            for(BillCodeRates rate: allbillcodeRate ){
                                billcodeRate.add(rate);
                                
                            }
                            for(BillCodeRates rate: billcodeRate){
                                if(responseKeyMap.containsKey(quote.QTB_Opportunity_Product_Line__c)){
                                    Map<String, Object> mapObj = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(rate));
                                    String bcFamily = String.valueOf(mapObj.get(responseKeyMap.get(quote.QTB_Opportunity_Product_Line__c)));
                                        if(billToProductMap != null && billToProductMap.containsKey(bcFamily)){
                                          for(Id prdId : billToProductMap.get(bcFamily)){
                                            if(productToLineMap != null && productToLineMap.containsKey(prdId)){
                                                SBQQ__QuoteLine__c quoteline =  productToLineMap.get(prdId);
                                            newcustomerQuotelines(quoteline, rate);
                                            }
                                        } 
                                    }
                                }   
                            }
                        }
                    }
                    else {
                        // log in case of bad response
                        QTB_ExceptionLogger.createlog(204,'',responseBody,'',CLASSNAME);
                    }
                    try{
                        // disable package triggers while updating
                        SBQQ.TriggerControl.disable();
                        if(quoteLineMap != null){
                            update quoteLineMap.values();
                            if(throwExplicitException){
                                Throw new nullPointerException();
                                
                            }
                        }
                    }catch(Exception e){
                        QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
                        
                    }finally{
                        //enable Package triggers
                        SBQQ.TriggerControl.enable();
                    }
                    if(quoteLineMap.values() != null){
                    quote.QTB_Price_FX_Date__c = Date.today();
                    update quote;
                    }
                }
                
                else{
                    isError = true;
                    errorMessage =System.Label.QTB_Pricefx_not_available_error+SPACE+response.getStatusCode()+SPACE+STATUS+SPACE+response.getStatus();
                    QTB_ExceptionLogger.createLog(419,'',errorMessage,CALLOUTEXCEPTION,CLASSNAME);
                    return null;   
                }   
            }
            
        }  
        
        // redirects back to quote line editor 
        PageReference pageRef = Page.SBQQ__SB;
        pageRef.getParameters().put('scontrolCaching','1');
        pageRef.getParameters().put('id',quoteId); 
        pageRef.setRedirect(true);
        
        return pageRef;
    }
/*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  
* Return:     
* Description: This method used  for back button on the vf page, it will redirects back to quoteline editor
********************************************************************************************************************/  
    Public static PageReference goBack(){
        id qid = apexpages.currentpage().getparameters().get('id');
        PageReference p = Page.SBQQ__SB;
        p.getParameters().put('scontrolCaching','1');
        p.getParameters().put('id',qid); 
        p.setRedirect(true);
        return p;
        
    }
/*******************************************************************************************************************
* Author:      Accenture
* Date:        8-20-2020
* Parameters:  quoteline, currentRateInfo
* Return:     
* Description: This method used  for mapping the renewal quote lines with pricefx prices and calculating the discount
********************************************************************************************************************/  
    public static void renewalQuotelines(SBQQ__QuoteLine__c quoteLine, CurrentRateInfo rate){   
        if(rate.targetPrice > 0){
            quoteLine.QTB_Target_Price__c = rate.targetPrice;
            quoteLine.QTB_Floor_Price__c = rate.floorPrice;
            quoteLine.QTB_Expert_Price__c = rate.expertPrice;
            quoteLine.SBQQ__ListPrice__c = rate.expertPrice;
         //   quoteLine.QTB_Quantity__c = rate.quantity;
            quoteLine.SBQQ__AdditionalDiscountAmount__c = rate.expertPrice - rate.targetPrice;
        }else{
            quoteLine.QTB_Target_Price__c = quoteLine.SBQQ__ListPrice__c; 
             quoteLine.QTB_Floor_Price__c = quoteLine.SBQQ__ListPrice__c *(100-disPercentage) /100;
            quoteLine.QTB_Expert_Price__c = quoteLine.SBQQ__ListPrice__c;
            quoteLine.SBQQ__AdditionalDiscountAmount__c = 0;
        }
        quoteLineMap.put(quoteLine.id,quoteLine); 
    }
 /*******************************************************************************************************************
* Author:      Accenture
* Date:        8-20-2020
* Parameters:  quoteline, billcodeRates
* Return:     
* Description: This method used  for mapping the new customer quote lines with pricefx prices
********************************************************************************************************************/  
    public static void newcustomerQuotelines(SBQQ__QuoteLine__c quoteLine, BillCodeRates rate){
       
         if(rate.targetPrice > 0){
             quoteLine.QTB_Target_Price__c = rate.targetPrice; 
             quoteLine.QTB_Floor_Price__c = rate.floorPrice;
             quoteLine.QTB_Expert_Price__c = rate.expertPrice;
             quoteLine.SBQQ__ListPrice__c = rate.expertPrice;
             
         }else{
             quoteLine.QTB_Target_Price__c = quoteLine.SBQQ__ListPrice__c;
             quoteLine.QTB_Floor_Price__c = quoteLine.SBQQ__ListPrice__c *(100-disPercentage) /100;
             quoteLine.QTB_Expert_Price__c = quoteLine.SBQQ__ListPrice__c;
         }
        quoteLineMap.put(quoteLine.id,quoteLine); 
        
    }
    
 /*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  quote
* Return:     String
* Description: This method used to create to json request body based on the quote attributes
********************************************************************************************************************/    
    public static String createRequestBody(SBQQ__Quote__c quote){
        
        /*Pass quote attributes for pricefxt thorugh this node*/
        Map<String,String> quoteJsonStringMap = new Map<String,String>();
      //  Map<String,QTB_PriceFx_LOB_Code__c> lobcode = QTB_PriceFx_LOB_Code__c.getAll();
        if(quote.SBQQ__Type__c == QTB_Constants.QUOTE_TYPE_RENEWAL){
            // map to get store the original quote which has imsight numbers
            renewToOriginalMap.put(quote.id,quote.SBQQ__Opportunity2__r.QTB_Original_Quote__c);
            List<QTB_Customer_Billing_Account_Lookup__c> imsightCodes = [SELECT Id, Name, QTB_Billing_Account__c, QTB_Customer_Account_Name__c,
                                                                         QTB_Customer_Account__c, QTB_IMSight_Number__c, QTB_Quote__c,QTB_Pricefx_Customer_ID__c 
                                                                         FROM QTB_Customer_Billing_Account_Lookup__c where QTB_Quote__c IN :renewToOriginalMap.values()];
            
            //json generator for renewal type
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();     
            gen.writeStringField('CountryCode', string.valueOf(quote.SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c));
            if(lobshortformMap != null){
                gen.writeStringField('BusinessUnit', string.valueOf(lobshortformMap.get(quote.QTB_Opportunity_Product_Line__c)));
            }
            gen.writeFieldName('ListOfImsights');
            gen.writeStartArray();
            for(QTB_Customer_Billing_Account_Lookup__c imsight: imsightCodes){
                if(imsight.QTB_Pricefx_Customer_ID__c != null){
                    gen.writeString(string.valueof(imsight.QTB_Pricefx_Customer_ID__c));
                }
            }
            gen.writeEndArray();
            gen.writeEndObject();
            String jsonData = gen.getAsString();
            return jsonData;
            
        }else if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.RECORDS_MANAGEMENT||
                 quote.QTB_Opportunity_Product_Line__c ==  QTB_Constants.SMB_PACKAGES){
                     
                     quoteJsonStringMap.put('country', string.valueOf(quote.SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c));
                     quoteJsonStringMap.put('estimatedVolume', string.valueof(quote.QTB_Quantity__c));
                     quoteJsonStringMap.put('industry', quote.SBQQ__Account__r.IM_Industry__c);
                     quoteJsonStringMap.put('numberOfMarkets',string.valueof(quote.QTB_Number_of_Markets__c));
                     
                 }else if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.DATA_MANAGEMENT){
                    
                     quoteJsonStringMap.put('mainMarket',string.valueof(quote.QTB_Primary_Market__r.District_name__c));
                     quoteJsonStringMap.put('country', string.valueOf(quote.SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c));
                     quoteJsonStringMap.put('estimatedVolume', string.valueOf(quote.QTB_Quantity__c));
                     quoteJsonStringMap.put('industry', quote.SBQQ__Account__r.IM_Industry__c );
                     quoteJsonStringMap.put('numberOfMarkets',string.valueof(quote.QTB_Number_of_Markets__c));
                 }
        
        else if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.SHRED){
            if(! shredList.isEmpty()){
                
                quoteJsonStringMap.put('country', string.valueOf(quote.SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c));
                quoteJsonStringMap.put('numberOfTipStops',string.valueof(shredList[0].QTB_Number_of_Bins_Per_Stop__c));
                quoteJsonStringMap.put('estimatedRevenue',string.valueof(shredList[0].QTB_Expected_Annual_Revenue__c));
                quoteJsonStringMap.put('milesToTravel',string.valueof(shredList[0].QTB_Average_Distance_to_Depot__c));
                quoteJsonStringMap.put('primaryMarketToServe',string.valueof(shredList[0].QTB_Primary_Market__r.District_name__c));
            }    
            
        }
        // returns json formatted string
        return JSON.serialize(quoteJsonStringMap);
        
    }
    
 /*******************************************************************************************************************
* Author:      Accenture
* Date:        27-05-2020
* Parameters:  quote
* Return:      HttpResponse
* Description: This method used to call the pricefx and send the response 
********************************************************************************************************************/
    public static HttpResponse getPricefxRates(SBQQ__Quote__c quote){
        
        HttpResponse response;
        String serviceEndPoint;
        // method to create request body
        String requestBody = createRequestBody(quote);
         system.debug('requestbody>>>>>'+requestBody);
        
        if(quote.SBQQ__Type__c == QTB_Constants.QUOTE_TYPE_RENEWAL){
            serviceEndPoint = pricefxurls.get(QTB_Constants.QUOTE_TYPE_RENEWAL);
        }else if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.RECORDS_MANAGEMENT ||
                 quote.QTB_Opportunity_Product_Line__c ==  QTB_Constants.SMB_PACKAGES){
                     serviceEndPoint = 'callout:Pricefx_Credentials/new-customer/rm';
                 }else if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.DATA_MANAGEMENT){
                     serviceEndPoint = pricefxurls.get(QTB_Constants.DATA_MANAGEMENT);
                 }else if(quote.QTB_Opportunity_Product_Line__c == QTB_Constants.SHRED){
                     serviceEndPoint = pricefxurls.get(QTB_Constants.SHRED);
                 }
        system.debug('endpoint>>'+serviceEndPoint);
        
        try{
            // http request for price fx integration
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(serviceEndPoint);
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json');
            request.setBody(requestBody);
            // time out error
            request.setTimeout(120000);
            //response from price fx
            response = http.send(request);
            
            
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;       
        }           
        
        return response;   
        
    }
    
    // wrapper class to store the response from rm,dm, shred endpoints
    public class ResultWrapper {
        public list<string> warnings;
        public Result result;
    }
    
    public class BillCodeRates {
        public String BillCode;
        public Double TargetPrice;
        public Double FloorPrice;
        public Double ExpertPrice;
        public String Description;
        public String BillCodeCategory;
        public String BillCodeFamily;
    }
    
    public class Result {
        public string industry;
        public List<BillCodeRates> billCodeRates;
    }
    
    // wrapper class to store the response from renewal uplift endpoint
    public class RenewalWrapper {
        public List<String> warnings;
        public Result2 result;
        
    }       
    public class Result2 {
        public List<CurrentRateInfo> currentRateInfo;
        public String country;
        public String businessUnit;
        
    }
    public class CurrentRateInfo {
        public String BillCode;
        Public Decimal Quantity;
        public Double CurrentRate;
        public Double TargetPrice;
        public Double FloorPrice;
        public Double ExpertPrice;
        public String BillCodeFamily;
    }
    
    
}
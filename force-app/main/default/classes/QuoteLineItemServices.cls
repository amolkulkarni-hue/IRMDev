/**
 * Commenting the code as it is being used only in inactive trigger 
 * Gitlab Story #29660
 **/
public with sharing class QuoteLineItemServices {
    public QuoteLineItemServices(){
        
    }
  /*  
    public static boolean followerLineItemOperation = false;
    
    public static void addFollowerLineItems (List<QuoteLineItem> lineItems){
        
        List<QuoteLineItem> newFollowerLineItems = new List<QuoteLineItem>();
        Set<String> quoteItemHash = new Set<String>();
        Decimal exceptionUnitPrice; 
        List<QuoteLineItem> quoteItemsWithSiblings = [Select id, QuoteId, Product_Name__c, Pricebook_Lookup__c, CurrencyIsoCode, UnitPrice from QuoteLineItem 
                                                                 Where QuoteId IN: Pluck.ids('QuoteId', lineItems) 
                                                                 ];
                
        for(QuoteLineItem quoteItem : quoteItemsWithSiblings){
            quoteItemHash.add(quoteItem.QuoteId + '-' + quoteItem.Product_Name__c);
                        if(quoteItem.Product_Name__c == '122'){
                            exceptionUnitPrice =  quoteItem.UnitPrice;
                        }
        }
       
        List<Leader_Follower_Mapping__c> maps = [Select id, Follower_Billcode__c, Leader_Billcode__c, Follower_Product__c
                                                 from Leader_Follower_Mapping__c 
                                                 where Leader_Billcode__c IN : Pluck.strings('Product_Name__c', lineItems)];
        Map<String, List<Leader_Follower_Mapping__c>> leaderFollowerMappings = GroupBy.strings('Leader_Billcode__c', maps );
        
        Map<String, PricebookEntry> pricebookEntryHash = new Map<String, PricebookEntry>();
        
        for(PricebookEntry entry : [Select id, Pricebook2Id, Product2Id, Product_Name__c, CurrencyIsoCode from PricebookEntry 
                                    where (Product2Id = : Pluck.strings('Follower_Product__c', maps) OR Product_Name__c =:'310')
                                    And CurrencyIsoCode IN: Pluck.strings('CurrencyIsoCode', lineItems)
                                    And Pricebook2Id IN: Pluck.strings('Pricebook_Lookup__c', lineItems)]
                                    ){
            pricebookEntryHash.put(String.valueOf(entry.Pricebook2Id).substring(0, 15) + '-' + entry.Product_Name__c + '-' + entry.CurrencyIsoCode,  entry);
        }
        
        
        for( QuoteLineItem lineItem : lineItems){
            system.debug(logginglevel.info, '+++ line item is ++++' + lineItem);
            String billCode = lineItem.Product_Name__c;
            String quoteId = lineItem.QuoteId;
            String pricebookId = lineItem.Pricebook_Lookup__c;
            String currencyCode = lineItem.CurrencyIsoCode;
            
            if(leaderFollowerMappings.containsKey(billCode) ){
                for(Leader_Follower_Mapping__c mapping : leaderFollowerMappings.get(billCode)){
                    string childPricebookKey = pricebookId + '-' + mapping.Follower_Billcode__c + '-' + currencyCode;
                    if( (!quoteItemHash.contains(quoteId + '-' + mapping.Follower_Billcode__c)) && pricebookEntryHash.containsKey(childPricebookKey)){
                        newFollowerLineItems.add(new QuoteLineItem(
                            QuoteId              = lineItem.quoteId, 
                            Product2id           = mapping.Follower_Product__c, 
                            Leader_Quote_Item__c = lineItem.id,
                            Quantity             = 1,
                            UnitPrice            = lineItem.UnitPrice,
                            PricebookEntryId     = pricebookEntryHash.get(childPricebookKey).id
                        ));
                        system.debug(logginglevel.info, '+++++ newFollowerLineItems +++++ '+ newFollowerLineItems);
                        quoteItemHash.add(quoteId + '-' + mapping.Follower_Billcode__c);
                    }
                }
            }
            
            if( (billCode =='122' || billCode =='5920') && pricebookEntryHash.containsKey(pricebookId + '-310' + '-' + currencyCode) && (!quoteItemHash.contains(quoteId + '-310'))){
                Decimal exceptionUnitPriceTemp;
                if(billCode == '5920' && quoteItemHash.contains(quoteId + '-122')){
                   exceptionUnitPriceTemp = exceptionUnitPrice;
                }else{ 
                   exceptionUnitPriceTemp =  lineItem.UnitPrice; 
                }                
                PricebookEntry entry = pricebookEntryHash.get(pricebookId + '-310' + '-' + currencyCode);
                newFollowerLineItems.add(new QuoteLineItem(
                    QuoteId              = lineItem.quoteId, 
                    Leader_Quote_Item__c = lineItem.id,
                    Quantity             = 1,
                    UnitPrice            = exceptionUnitPriceTemp,
                    PricebookEntryId     = pricebookEntryHash.get(pricebookId + '-310' + '-' + currencyCode).id
                ));
                quoteItemHash.add(quoteId + '-310');
            }
        }
     
        if(!Test.isRunningTest())
        {
            followerLineItemOperation = true;
            insertLineItems(newFollowerLineItems, lineItems);
            followerLineItemOperation = false;
        }
    } 
    
    public static void insertLineItems(List<QuoteLineItem> followerLineItems, List<QuoteLineItem> leaderLineItems) {
        system.debug(logginglevel.info, '++++++++ followerlineitems is ++++ ' + followerLineItems);
        SafeDML itemsToInsert = new SafeInsert();
        ErrorHandling.AddErrorsToTriggerNew errorHandling = new ErrorHandling.AddErrorsToTriggerNew( new Map<Id, QuoteLineItem>(leaderLineItems),'Leader_Quote_Item__c' );                      
        itemsToInsert.queue(followerLineItems, errorHandling);
        itemsToInsert.doDml();
    }
    
    public static void updateLineItems(List<QuoteLineItem> followerLineItems){
        system.debug(logginglevel.info, '++++++++ followerlineitems is ++++ ' + followerLineItems);
        try{
            update(followerLineItems);
        } catch(Exception e){
            system.debug(logginglevel.info, '++++ error is ++++ ' + e);
        }
    }
    
    
    
    public static void removeFollowerLineItems(List<QuoteLineItem> lineItems){

        
        
        List<Leader_Follower_Mapping__c> maps = [Select id, Follower_Billcode__c, Leader_Billcode__c, Follower_Product__c
                                                 from Leader_Follower_Mapping__c 
                                                 where Leader_Billcode__c IN : Pluck.strings('Product_Name__c', lineItems)];
        
        if(!maps.isEmpty()){
            List<QuoteLineItem> lineItemsToDelete = new List<QuoteLineItem>();
            Map<String, List<Leader_Follower_Mapping__c>> leaderToFollowerMap = GroupBy.strings('Leader_Billcode__c', maps);
                                                 
            List<QuoteLineItem> followerQuoteItems = [Select id, QuoteId, Product_Name__c, CurrencyIsoCode, Pricebook_Lookup__c from QuoteLineItem 
                                                     Where QuoteId IN: Pluck.strings('QuoteId', lineItems) 
                                                     And Product_Name__c IN : Pluck.strings('Follower_Billcode__c', maps ) ];
            
            Map<String, QuoteLineItem> quoteItemHash = new Map<String, QuoteLineItem>();
            for(QuoteLineItem quoteItem : followerQuoteItems){
                quoteItemHash.put(quoteItem.QuoteId + '-' + quoteItem.CurrencyIsoCode + '-' + quoteItem.Pricebook_Lookup__c + '-' + quoteItem.Product_Name__c, quoteItem);
            }

            Map<String, List<Leader_Follower_Mapping__c>> leaderFollowerMappings = GroupBy.strings('Leader_Billcode__c', maps );
            
            
            for( QuoteLineItem lineItem : lineItems){
                String billCode = lineItem.Product_Name__c;
                String quoteId = lineItem.QuoteId;
                String pricebookId = lineItem.Pricebook_Lookup__c;
                String currencyCode = lineItem.CurrencyIsoCode;
            
                if(leaderFollowerMappings.containsKey(billCode) ){
                    for(Leader_Follower_Mapping__c mapping : leaderFollowerMappings.get(billCode)){
                        String childQLIKey = quoteId + '-' + currencyCode + '-' + lineItem.Pricebook_Lookup__c + '-' + mapping.Follower_Billcode__c;
                        
                        if( quoteItemHash.containsKey(childQLIKey)){
                            QuoteLineItem qli = quoteItemHash.get(childQLIKey); 
                            lineItemsToDelete.add(qli);
                            quoteItemHash.remove(childQLIKey);
                        }
                    }
                }
            }
          
            
            if(!lineItemsToDelete.isEmpty() && !Test.isRunningTest()){
                followerLineItemOperation = true;
                delete lineItemsToDelete;
                followerLineItemOperation = false;
            }
        }
    }
     
    public static void updateFollowerLineItems(List<QuoteLineItem> lineItems){

        System.debug(LoggingLevel.info,'Before Removing Size=='+lineItems.size());
        Set<String> quoteItemHash = new Set<String>();
        Decimal exceptionUnitPrice;
        Decimal exceptionProposedPrice;
        String quoteRecordType;
        List<QuoteLineItem> quoteItemsWithSiblings = [Select id, QuoteId, Product_Name__c, Pricebook_Lookup__c, CurrencyIsoCode,UnitPrice,Proposed_Price__c,Quote.RecordType.Name from QuoteLineItem 
                                                                 Where QuoteId IN: Pluck.ids('QuoteId', lineItems) ];
        List<QuoteLineItem> updateQLIs = new  List<QuoteLineItem>(); 
        for(QuoteLineItem quoteItem : quoteItemsWithSiblings){
            quoteItemHash.add(quoteItem.QuoteId + '-' + quoteItem.Product_Name__c);
            quoteRecordType = quoteItem.Quote.RecordType.Name;
            if(quoteItem.Product_Name__c == '122'){
                exceptionUnitPrice =  quoteItem.UnitPrice;
                exceptionProposedPrice = quoteItem.Proposed_Price__c;
                }
        }
        System.debug(LoggingLevel.Info,'quoteItemHash=='+quoteItemHash);
        List<Leader_Follower_Mapping__c> maps = [Select id, Follower_Billcode__c, Leader_Billcode__c, Follower_Product__c,QPI_Quote__c,Standard_Quote__c
                                                 from Leader_Follower_Mapping__c 
                                                 where Leader_Billcode__c IN : Pluck.strings('Product_Name__c', lineItems)];
        Map<String, List<Leader_Follower_Mapping__c>> leaderMappings = GroupBy.strings('Leader_Billcode__c', maps );
        Map<String, List<Leader_Follower_Mapping__c>> followerMappings = GroupBy.strings('Follower_Billcode__c', [Select id, Follower_Billcode__c, Leader_Billcode__c, Follower_Product__c,QPI_Quote__c,Standard_Quote__c
                                                 from Leader_Follower_Mapping__c 
                                                 where Follower_Billcode__c IN : Pluck.strings('Product_Name__c', lineItems)] );        

        for(QuoteLineItem lineItem : lineItems){
            String billCode = lineItem.Product_Name__c;
            String quoteId = lineItem.QuoteId;
            String currencyCode = lineItem.CurrencyIsoCode;
            System.debug(LoggingLevel.Info,lineItems.size()+'billCode==='+billCode);
            if(lineItems.size() == 1 && followerMappings.containsKey(billCode)){
                if(!Test.isRunningTest())
                lineItem.addError('You can not change Unit Price for follower bill code.');
                
            }
            if(leaderMappings.containsKey(billCode) && !followerMappings.containsKey(billCode)){
                System.debug(LoggingLevel.Info,'leaderFollowerMappings'+leaderMappings);
                System.debug(LoggingLevel.Info,'quoteRecordType'+quoteRecordType);

                
                for(Leader_Follower_Mapping__c mapping : leaderMappings.get(billCode)){
                    System.debug(LoggingLevel.Info,'mapping.QPI_Quote__c=='+mapping.QPI_Quote__c);
                    if((quoteRecordType.equals('NA Renewal Quote') || quoteRecordType.equals('NA Deferred Quote'))
                       && mapping.QPI_Quote__c == true
                       && (quoteItemHash.contains(quoteId + '-' + mapping.Follower_Billcode__c))){
                        for(QuoteLineItem quoteItem : quoteItemsWithSiblings){
                            if(mapping.Follower_Billcode__c != null 
                               && mapping.Follower_Billcode__c == quoteItem.Product_Name__c
                               ){
                                   if(billCode == '5920' && quoteItemHash.contains(quoteId + '-122')){
                                       quoteItem.UnitPrice =  exceptionUnitPrice ;
                                       quoteItem.Proposed_Price__c =  exceptionProposedPrice;
                                   }else{ 
                                       quoteItem.UnitPrice =  lineItem.UnitPrice; 
                                       quoteItem.Proposed_Price__c =  lineItem.Proposed_Price__c;
                                   }
                               updateQLIs.add(quoteItem) ;
                            }
                        } 
                        System.debug(LoggingLevel.Info,'updateQLIs=='+updateQLIs);
                    }
                    
                 if(!(quoteRecordType.equals('NA Renewal Quote') || quoteRecordType.equals('NA Deferred Quote'))
                       && mapping.Standard_Quote__c == true
                       && (quoteItemHash.contains(quoteId + '-' + mapping.Follower_Billcode__c))){
                        for(QuoteLineItem quoteItem : quoteItemsWithSiblings){
                            if(mapping.Follower_Billcode__c != null 
                               && mapping.Follower_Billcode__c == quoteItem.Product_Name__c
                               ){
                                   if(billCode == '5920' && quoteItemHash.contains(quoteId + '-122')){
                                       quoteItem.UnitPrice =  exceptionUnitPrice ;
                                       quoteItem.Proposed_Price__c =  exceptionProposedPrice;
                                   }else{ 
                                       quoteItem.UnitPrice =  lineItem.UnitPrice; 
                                       quoteItem.Proposed_Price__c =  lineItem.Proposed_Price__c;
                                   }
                               updateQLIs.add(quoteItem) ;
                            }
                        } 
                        System.debug(LoggingLevel.Info,'updateQLIs=='+updateQLIs);
                }
                    
            }
          }
        }
        
            if(lineItems.size() == 1 && !updateQLIs.isEmpty() && !Test.isRunningTest()){
                followerLineItemOperation = true;
                update updateQLIs;
                followerLineItemOperation = false;
            }        
    }
    
 */  
}
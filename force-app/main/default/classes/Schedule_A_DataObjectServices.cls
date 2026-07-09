public with sharing class Schedule_A_DataObjectServices {

    public static Pricebook2 PRICEBOOK_NORTH_AMERICA
    {
        get
        {
            if(PRICEBOOK_NORTH_AMERICA == null){
                return [SELECT Id, Name FROM PriceBook2 WHERE Name =:'North America'];
            }
            else{ return PRICEBOOK_NORTH_AMERICA; }
        }
        set;
    } 
    
    public static boolean acceptScheduleAData
    {
        get
        {
            return acceptScheduleAData;
        }
        private set;
    }
    
    public static boolean filterScheduleAData(Id oppId)
    {
        List<dsfs__DocuSign_Status__c> listDocuSignStatus = [SELECT Id, dsfs__Envelope_Status__c FROM dsfs__DocuSign_Status__c Where dsfs__Opportunity__c =: oppId]; 
        for(dsfs__DocuSign_Status__c aDocuSignStatus : listDocuSignStatus)
        {
            if(aDocuSignStatus.dsfs__Envelope_Status__c.equalsIgnoreCase('Completed')){
                return true;
                break;
            }
        }
        return false;
    }
    
    /**
      * Creates the Schedule A Document(Quote) from the Json string 
      * when the Schedule_A_Data__c object is inserted
      * @param the Schedule_A_Data__c object that is inserted.
      * @ Creates a Schedule A Document(Quote) and its corresponding schedule A line items (QLI).
    */  
    public static void buildScheduleA(List<Schedule_A_Data__c> scheduleAData)
    {
        String scheduleAJSON = null;
        String scheduleALineItemJSON = null;
        
        Integer index = 0;
        
        List<Quote> quotesToBeInserted = new List<Quote>(); 
        Map<Integer, Quote> mapIdToQuote = new Map<Integer, Quote>();
        List<SchedDataToQuoteWrapper> scheduleADataQuoteWrapperList = new List<SchedDataToQuoteWrapper>();
        for(Schedule_A_Data__c aScheduleAData : scheduleAData)
        {
            
            if(String.isNotBlank(aScheduleAData.Schedule_A__c))
            {
                    scheduleAJSON = aScheduleAData.Schedule_A__c;
                    Quote scheduleAToBeInserted = new Quote();
                    Id oppId = null;
                    Map<String, Object> deserializedScheduleA = (Map<String, Object>)JSON.deserializeUntyped(scheduleAJSON);
                    oppId = (ID)String.valueOf(deserializedScheduleA.get('Opportunity'));
                    acceptScheduleAData = filterScheduleAData(oppId);
                    if(acceptScheduleAData)
                    {
                        String effcDate = String.valueOf(deserializedScheduleA.get('Effective_Date__c'));
						System.debug('Eff Date Before converting'+effcDate);      
						System.debug('Eff Date After converting'+covertStringToDate(effcDate));                         
                        
						System.debug(LoggingLevel.Info,'Eff Date Before converting'+effcDate);      
						System.debug(LoggingLevel.Info,'Eff Date After converting'+covertStringToDate(effcDate));                         
                        scheduleAToBeInserted.Effective_Date__c = covertStringToDate(effcDate);
                        scheduleAToBeInserted.Name = String.valueOf(deserializedScheduleA.get('Name'));
                        scheduleAToBeInserted.Service_Line__c = String.valueOf(deserializedScheduleA.get('Service_Line__c'));
                        scheduleAToBeInserted.Schedule_A_Contract_Length__c = String.valueOf( deserializedScheduleA.get('Contract_Length__c'))!=''?(Decimal.valueOf(String.valueOf( deserializedScheduleA.get('Contract_Length__c')))): 12;
                        scheduleAToBeInserted.OpportunityId = oppId;
                        scheduleAToBeInserted.Pricebook2Id = PRICEBOOK_NORTH_AMERICA.Id;
                        quotesToBeInserted.add(scheduleAToBeInserted);
                        SchedDataToQuoteWrapper aSDQuoteWrapper = new SchedDataToQuoteWrapper(aScheduleAData, scheduleAToBeInserted);
                        scheduleADataQuoteWrapperList.add(aSDQuoteWrapper);
                    }
            }
        }
        try
        {
            insert quotesToBeInserted;
                            
        }
        catch( System.DmlException ex )
        {
            for( Integer errorIndex = 0; errorIndex < ex.getNumDml(); errorIndex++ )
            {
                    SchedDataToQuoteWrapper wrap = scheduleADataQuoteWrapperList[ex.getDmlIndex(errorIndex)];
                    wrap.theSchedAData.Quote_Creation_Error__c = ex.getDmlMessage(errorIndex);
            }
        }
        
        List<QuoteLineItem> scheduleALineitemsToInsert = new List<QuoteLineItem>();
        
        Map<Id, PriceBookEntry> productIdToPriceBookEntryMap = new Map<Id, PriceBookEntry>();
        List<PriceBookEntry> priceBookEntries = [Select product2Id, Id, Pricebook2Id from PriceBookEntry where Pricebook2Id = :PRICEBOOK_NORTH_AMERICA.Id];
        for(PriceBookEntry apriceBookEntry : priceBookEntries)
            productIdToPriceBookEntryMap.put(apriceBookEntry.product2Id,apriceBookEntry);
        
        for(SchedDataToQuoteWrapper aScheduleADataQuoteWrap : scheduleADataQuoteWrapperList)
        {
            if(acceptScheduleAData){
                Quote scheduleA = aScheduleADataQuoteWrap.theQuote;
                if(String.isNotBlank(aScheduleADataQuoteWrap.theSchedAData.Schedule_A_Line_Item__c))
                {
                    scheduleALineItemJSON = aScheduleADataQuoteWrap.theSchedAData.Schedule_A_Line_Item__c;
                    
                    List<ScheduleALineItemWrapper> listOfScheduleALineItems = (List<ScheduleALineItemWrapper>)System.JSON.deserialize(scheduleALineItemJSON, List<ScheduleALineItemWrapper>.class);
                    for(ScheduleALineItemWrapper childObj : listOfScheduleALineItems)
                    {
                            QuoteLineItem scheduleALineItemToBeInserted = new QuoteLineItem();
                            scheduleALineItemToBeInserted.Product2Id = (Id)childObj.ProductId;
                            scheduleALineItemToBeInserted.UnitPrice = childObj.UnitPrice!=''? Decimal.valueOf(childObj.UnitPrice):0.00;
                            scheduleALineItemToBeInserted.Quantity = childObj.Quantity!=''?Integer.valueOf(childObj.Quantity):1;
                            scheduleALineItemToBeInserted.Base_Quantity__c = childObj.BaseQty!=''?Integer.valueOf(childObj.BaseQty):null;
                            scheduleALineItemToBeInserted.Base_Amount__c = childObj.BaseAmount!=''?Decimal.valueOf(childObj.BaseAmount):null;
                            scheduleALineItemToBeInserted.Unit_Quantity__c = childObj.UnitQty!=''?Integer.valueOf(childObj.UnitQty):null;
                            scheduleALineItemToBeInserted.Unit_Rate__c = childObj.UnitRate!=''?Decimal.valueOf(childObj.UnitRate):null;                            
                            scheduleALineItemToBeInserted.QuoteId = scheduleA.Id;
                            scheduleALineItemToBeInserted.PricebookEntryId = productIdToPriceBookEntryMap.get((Id)childObj.ProductId).Id;
                            scheduleALineitemsToInsert.add(scheduleALineItemToBeInserted);
                    }
                }
            }
        }
        try{
            insert scheduleALineitemsToInsert;
        }
        catch(System.DmlException ex) {
            for (Integer errorIndex = 0; errorIndex < ex.getNumDml(); errorIndex++) {
                SchedDataToQuoteWrapper wrap = scheduleADataQuoteWrapperList[ex.getDmlIndex(errorIndex)];
                wrap.theSchedAData.Quote_Creation_Error__c = ex.getDmlMessage(errorIndex);
            }
        }
    }
    
    
    /**
      * Return a Date after formating the input string 
      * @param an unformatted date String for the format (MMDDYYYY)
    */
    public static Date covertStringToDate(String dateStr)
    {
        date myDate;
        String finalStr ='';
        if(dateStr.length() == 8)
        {
            for(integer i = 0,j=0; i < 2;i++)
            {
                finalStr = finalStr + (dateStr.subString(j, j+2));
                finalStr = finalStr + '/';
                j+=2;
            }
 		/*	for(integer i = 0,j=2; i < 2;i++)
            {
                finalStr = finalStr + (dateStr.subString(j, j+2));
                finalStr = finalStr + '/';
                j-=2;
            }    */        
            finalStr = finalStr + dateStr.subString(4, dateStr.length());
            myDate = date.parse(finalStr);
        }
        return myDate;  
    }
    
    /**
      * Wrapper class that holds all the fields of the Schedule A line item (QLI)
     */  
    public class ScheduleALineItemWrapper 
    {
        public String ProductId;
        public String UnitPrice;
        public String Quantity;
        public String BaseQty;
        public String BaseAmount; 
        public String UnitQty;
        public String UnitRate;        
    }
    
    public class SchedDataToQuoteWrapper
    {
        public Schedule_A_Data__c theSchedAData;
        public Quote theQuote;
        
        public SchedDataToQuoteWrapper ( Schedule_A_Data__c theSchedAData, Quote theQuote)
        {
            this.theSchedAData = theSchedAData;
            this.theQuote = theQuote;
        }   
    }
}
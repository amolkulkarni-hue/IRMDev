public with sharing class DocuSignStatusService {

    public static Map<Id, dsfs__DocuSign_Status__c> mapScheduleDataIdToDocuSignStatus;	
    public static List<SchedDataToQuoteWrapper> scheduleADataQuoteWrapperList;
	public static Pricebook2 PRICEBOOK_NORTH_AMERICA
	{
		get
		{
			if(PRICEBOOK_NORTH_AMERICA == null)
				return [SELECT Id, Name FROM PriceBook2 WHERE Name =:'North America'];
			else 
				return PRICEBOOK_NORTH_AMERICA; 
		}
		set;
	} 
	
	public static List<dsfs__DocuSign_Status__c> filterDocuSignStatusChanged(List<dsfs__DocuSign_Status__c> updatedDocuSignList , Map<Id, dsfs__DocuSign_Status__c> oldMap)
	{
		List<dsfs__DocuSign_Status__c> filteredDocuSignList = new List<dsfs__DocuSign_Status__c>();
		for(dsfs__DocuSign_Status__c aDocuSign : updatedDocuSignList)
		{
			if( aDocuSign.dsfs__Envelope_Status__c.equalsIgnoreCase('Completed') && !(aDocuSign.dsfs__Envelope_Status__c.equalsIgnoreCase(oldMap.get(aDocuSign.Id).dsfs__Envelope_Status__c)))
				filteredDocuSignList.add(aDocuSign);
		}
		return filteredDocuSignList;
	}
	
	
	public static List<Schedule_A_Data__c> retrieveScheduleAData(List<dsfs__DocuSign_Status__c> listDocuSignStatus)
	{
		mapScheduleDataIdToDocuSignStatus = new Map<Id, dsfs__DocuSign_Status__c>();
		List<Schedule_A_Data__c> retrievedScheduleAData = new List<Schedule_A_Data__c>();
		Set<Id> scheduleADataIds = new Set<Id>();
		for(dsfs__DocuSign_Status__c aDocuSign : listDocuSignStatus)
		{
			if(aDocuSign.Schedule_A_Data__c != null)
			{
				mapScheduleDataIdToDocuSignStatus.put(aDocuSign.Schedule_A_Data__c, aDocuSign);
				scheduleADataIds.add(aDocuSign.Schedule_A_Data__c);
			}
		}
		
		retrievedScheduleAData = [SELECT Id, Schedule_A__c, Schedule_A_Line_Item__c, Opportunity__c FROM Schedule_A_Data__c WHERE Id IN : scheduleADataIds ];
		System.debug(LoggingLevel.Info,'Test here=='+retrievedScheduleAData);
		return retrievedScheduleAData;
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
			}     */       
			finalStr = finalStr + dateStr.subString(4, dateStr.length());
			myDate = date.parse(finalStr);
		}
		System.debug(LoggingLevel.Info,'with Info==Date=='+myDate);        
        System.debug('with debug==Date=='+myDate);
		return myDate;	
	}
	
	
	/**
      * Creates the Schedule A Document(Quote) from the Json string 
      * when the Schedule_A_Data__c object is inserted
      * @param the Schedule_A_Data__c object that is inserted.
      * @ Creates a Schedule A Document(Quote).
    */  
	public static void buildScheduleA(List<Schedule_A_Data__c> scheduleAData)
	{
		String scheduleAJSON = null;
		//String scheduleALineItemJSON = null;
		
		Integer index = 0;
		
		List<Quote> quotesToBeInserted = new List<Quote>(); 
		Map<Integer, Quote> mapScheduleADataIdToQuote = new Map<Integer, Quote>();
		scheduleADataQuoteWrapperList = new List<SchedDataToQuoteWrapper>();
		for(Schedule_A_Data__c aScheduleAData : scheduleAData)
		{
			
			if(String.isNotBlank(aScheduleAData.Schedule_A__c))
			{
					scheduleAJSON = aScheduleAData.Schedule_A__c;
					Quote scheduleAToBeInserted = new Quote();
					Id oppId = null;
					Map<String, Object> deserializedScheduleA = (Map<String, Object>)JSON.deserializeUntyped(scheduleAJSON);
					oppId = (ID)String.valueOf(deserializedScheduleA.get('Opportunity'));
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
		updateQuotes(scheduleADataQuoteWrapperList, quotesToBeInserted);
		/*try
		{
			insert quotesToBeInserted;
							
		}
		catch( System.DmlException ex )
		{
			List<Schedule_A_Data__c> listScheduleADataToBeUpdated = new List<Schedule_A_Data__c>();
			for( Integer errorIndex = 0; errorIndex < ex.getNumDml(); errorIndex++ )
            {
                    SchedDataToQuoteWrapper wrap = scheduleADataQuoteWrapperList[ex.getDmlIndex(errorIndex)];
                    wrap.theSchedAData.Quote_Creation_Error__c = ex.getDmlMessage(errorIndex);
                    listScheduleADataToBeUpdated.add(wrap.theSchedAData);
            }
            update listScheduleADataToBeUpdated;
		}*/
		
		
		buildScheduleALineItems(scheduleADataQuoteWrapperList);
		
	}
	
	/**
      * Creates the Schedule A Document Line Items(Quote Line Items) from the Json string 
      * when the DocuSign Status object is updated and its envelope status set to completed.
      * @param the SchedDataToQuoteWrapper that maps the ScheduleAData to the Quote.
      * @ Creates a Schedule A Document Line Items(Quote Line Items).
    */
	public static void buildScheduleALineItems(List<SchedDataToQuoteWrapper> scheduleADataQuoteWrapperList1)
	{
		try
		{
			String scheduleALineItemJSON = null;
			List<QuoteLineItem> scheduleALineitemsToInsert = new List<QuoteLineItem>();
			Map<Id, PriceBookEntry> productIdToPriceBookEntryMap = new Map<Id, PriceBookEntry>();
			List<PriceBookEntry> priceBookEntries = [Select product2Id, Id, Pricebook2Id from PriceBookEntry where Pricebook2Id = :PRICEBOOK_NORTH_AMERICA.Id];
			for(PriceBookEntry apriceBookEntry : priceBookEntries)
				productIdToPriceBookEntryMap.put(apriceBookEntry.product2Id,apriceBookEntry);
			System.debug(LoggingLevel.Info,'Final List here =='+scheduleADataQuoteWrapperList1);	
			for(SchedDataToQuoteWrapper aScheduleADataQuoteWrap : scheduleADataQuoteWrapperList1)
			{
					Quote scheduleA = aScheduleADataQuoteWrap.theQuote;
                	System.debug(LoggingLevel.Info,'aScheduleADataQuoteWrap.theSchedAData.Schedule_A_Line_Item__c');
					if(String.isNotBlank(aScheduleADataQuoteWrap.theSchedAData.Schedule_A_Line_Item__c))
					{
						scheduleALineItemJSON = aScheduleADataQuoteWrap.theSchedAData.Schedule_A_Line_Item__c;
						
						List<ScheduleALineItemWrapper> listOfScheduleALineItems = (List<ScheduleALineItemWrapper>)System.JSON.deserialize(scheduleALineItemJSON, List<ScheduleALineItemWrapper>.class);
						System.debug(LoggingLevel.Info,'listOfScheduleALineItems==='+listOfScheduleALineItems);                        
						for(ScheduleALineItemWrapper childObj : listOfScheduleALineItems)
						{
								QuoteLineItem scheduleALineItemToBeInserted = new QuoteLineItem();
								System.debug(LoggingLevel.Info,'(Id)childObj.ProductId'+(Id)childObj.ProductId);                                                    
                                System.debug(LoggingLevel.Info,'childObj.UnitPrice'+childObj.UnitPrice);                                                    
                                System.debug(LoggingLevel.Info,'childObj.Quantity'+childObj.Quantity);                                                    
                                System.debug(LoggingLevel.Info,'childObj.BaseQty'+childObj.BaseQty);                                                    
                                System.debug(LoggingLevel.Info,'childObj.BaseAmount'+childObj.BaseAmount); 
                                System.debug(LoggingLevel.Info,'childObj.UnitQty'+childObj.UnitQty);                                                    
                                System.debug(LoggingLevel.Info,'childObj.UnitRate'+childObj.UnitRate);                                                    
                                System.debug(LoggingLevel.Info,'scheduleA.Id'+scheduleA.Id);                                                    
                                System.debug(LoggingLevel.Info,'productIdToPriceBookEntryMap.get((Id)childObj.ProductId).Id'+productIdToPriceBookEntryMap.get((Id)childObj.ProductId).Id);                             
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
								System.debug(LoggingLevel.Info,'scheduleALineitemsToInsert inside loop==='+scheduleALineitemsToInsert);                                                                
						}
					}
			}
			System.debug(LoggingLevel.Info,'scheduleALineitemsToInsert==='+scheduleALineitemsToInsert);                                    
			updateQuotesLineItems(scheduleALineitemsToInsert);
		}
		catch(System.NullPointerException ex)
		{
			List<dsfs__DocuSign_Status__c> listScheduleADataToBeUpdated = new List<dsfs__DocuSign_Status__c>();
            System.debug(LoggingLevel.Info,'mapScheduleDataIdToDocuSignStatus=='+mapScheduleDataIdToDocuSignStatus);
            System.debug(LoggingLevel.Info,'mapScheduleDataIdToDocuSignStatus=='+mapScheduleDataIdToDocuSignStatus);
			mapScheduleDataIdToDocuSignStatus.get(scheduleADataQuoteWrapperList1[0].theSchedAData.Id).Quote_Creation_Error__c = 'No pricebookentry found';
		    listScheduleADataToBeUpdated.add(mapScheduleDataIdToDocuSignStatus.get(scheduleADataQuoteWrapperList1[0].theSchedAData.Id));			
            //update listScheduleADataToBeUpdated;
		}
		catch(System.JSONException ex)
		{
		    List<dsfs__DocuSign_Status__c> listScheduleADataToBeUpdated = new List<dsfs__DocuSign_Status__c>();
			mapScheduleDataIdToDocuSignStatus.get(scheduleADataQuoteWrapperList1[0].theSchedAData.Id).Quote_Creation_Error__c = 'Quote Line Item Json not valid';
		    listScheduleADataToBeUpdated.add(mapScheduleDataIdToDocuSignStatus.get(scheduleADataQuoteWrapperList1[0].theSchedAData.Id));			
            //update listScheduleADataToBeUpdated;
		}
		/*try{
			
			insert scheduleALineitemsToInsert;
		}
		catch(System.DmlException ex) {
			List<Schedule_A_Data__c> listScheduleADataToBeUpdated = new List<Schedule_A_Data__c>();
		    for (Integer errorIndex = 0; errorIndex < ex.getNumDml(); errorIndex++) {
		    	SchedDataToQuoteWrapper wrap = scheduleADataQuoteWrapperList[ex.getDmlIndex(errorIndex)];
                wrap.theSchedAData.Quote_Creation_Error__c = ex.getDmlMessage(errorIndex);
                listScheduleADataToBeUpdated.add(wrap.theSchedAData);
		    }
		    update listScheduleADataToBeUpdated;
		}*/
	}
	
	/*
	* Single Method that does the DML updates
	*/
	public static void updateQuotes(List<SchedDataToQuoteWrapper> scheduleADataQuoteWrapperList1, List<Quote> quotesToBeInserted)
	{
	    try
		{
			insert quotesToBeInserted;
							
		}
		catch( System.DmlException ex )
		{
			List<dsfs__DocuSign_Status__c> listScheduleADataToBeUpdated = new List<dsfs__DocuSign_Status__c>();
			for( Integer errorIndex = 0; errorIndex < ex.getNumDml(); errorIndex++ )
            {
                    SchedDataToQuoteWrapper wrap = scheduleADataQuoteWrapperList1[ex.getDmlIndex(errorIndex)];
                    dsfs__DocuSign_Status__c testDoc = mapScheduleDataIdToDocuSignStatus.get(wrap.theSchedAData.Id);
                    testDoc.Quote_Creation_Error__c = ex.getDmlMessage(errorIndex);
                    //wrap.theSchedAData.Quote_Creation_Error__c = ex.getDmlMessage(errorIndex);
                    listScheduleADataToBeUpdated.add(testDoc);
            }
            //update listScheduleADataToBeUpdated;
		}
		/*
		Database.SaveResult[] srList = Database.insert(quotesToBeInserted, false);
		List<dsfs__DocuSign_Status__c> listScheduleADataToBeUpdated = new List<dsfs__DocuSign_Status__c>();
		for(Integer i = 0; i< srList.size(); i++)
		{
		    if(srList[i].isSuccess()){
		        continue;
		    }
		    else
		    {
		        SchedDataToQuoteWrapper wrap = scheduleADataQuoteWrapperList[i];
                dsfs__DocuSign_Status__c testDoc = mapScheduleDataIdToDocuSignStatus.get(wrap.theSchedAData.Id);
                testDoc.Quote_Creation_Error__c = srList[i].getErrors()[0].getMessage();
                listScheduleADataToBeUpdated.add(testDoc);
		    }
		}*/
		//update listScheduleADataToBeUpdated;
	}
	
	/*
	* Single Method that does the DML updates
	*/
	public static void updateQuotesLineItems(List<QuoteLineItem> scheduleALineitemsToInsert)
	{
	    Database.SaveResult[] srList = Database.insert(scheduleALineitemsToInsert, false);
		List<dsfs__DocuSign_Status__c> listScheduleADataToBeUpdated = new List<dsfs__DocuSign_Status__c>();
		for(Integer i = 0; i< srList.size(); i++)
		{
		    if(srList[i].isSuccess()){
		        continue;
		    }
		    else
		    {
		    	dsfs__DocuSign_Status__c testDoc;
		    	Id quoteId = scheduleALineitemsToInsert[i].QuoteId;
		    	for(SchedDataToQuoteWrapper aWrap : scheduleADataQuoteWrapperList)
		    	{
		    	    if(aWrap.theQuote.Id == quoteId)
		    	    {
                        testDoc = mapScheduleDataIdToDocuSignStatus.get(aWrap.theSchedAData.Id);
                        testDoc.Quote_Creation_Error__c = srList[i].getErrors()[0].getMessage();
                        listScheduleADataToBeUpdated.add(testDoc);
			    	}
		    	}
		        //SchedDataToQuoteWrapper wrap = scheduleADataQuoteWrapperList[i];
		    }
		}
		//update listScheduleADataToBeUpdated;
	
	}
	
	/**
      * Single method that does all the method calls to create the Schedule A Document(Quote) and Schedule A Doc Line Items(Quote Line Items)
      * when the DocuSign Status object is updated and its envelope status set to completed.
      * @param the List of DocuSign Status objects that are updated and the oldMap.
    */
	public static void processDocuSignUpdates(List<dsfs__DocuSign_Status__c> updatedDocuSignList , Map<Id, dsfs__DocuSign_Status__c> oldMap)
	{
        System.debug(LoggingLevel.Info,'Coming here on update');
	    List<Schedule_A_Data__c> retrivedScheduleAData = new List<Schedule_A_Data__c>();
		List<dsfs__DocuSign_Status__c> filteredDocuSignList = filterDocuSignStatusChanged(updatedDocuSignList , oldMap);
		if(filteredDocuSignList.size() != 0)
		    retrivedScheduleAData = retrieveScheduleAData(filteredDocuSignList);
		    if(retrivedScheduleAData.size() != 0)
		        buildScheduleA(retrivedScheduleAData);
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
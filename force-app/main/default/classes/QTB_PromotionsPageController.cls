/*****************************************************************************************************
 * Class: QTB_PromotionsPageController
 * Author: Accenture
 * Purpose: This a class to show all the active promotions applicable to the quote when we click on "Select Promotions" button in QLE
 * Requirement: Gitlab#378, 486, 1504
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *           24/12/2020
 *******************************************************************************************************/
public class QTB_PromotionsPageController {
	@TestVisible
    public static final string CLASSNAME = 'QTB_PromotionsPageController';
	private String quoteId { get; set; }
	private static String hasPromo;
	public List<PromoWrapper> promotions { get; set; }
	private Map<Id, SBQQ__QuoteLine__c> mapOfQuoteLinebyProductId;
	public SBQQ__Quote__c record { get; set; }
	private Map<Id, SBQQ__QuoteLine__c> quoteLinesToUpdateById;

	// get Existing Promotions on Quote
	private Map<Id, QTB_Quote_Promotion__c> existingPromotions;

	public QTB_PromotionsPageController() {
		quoteId = ApexPages.currentPage().getParameters().get('id').escapeHtml4();
		quoteLinesToUpdateById = new Map<Id, SBQQ__QuoteLine__c>();
		
		if (quoteId != null) {
			try {
				record = this.getQuoteDetails(Id.valueOf(quoteId));
				this.existingPromotions = this.getExistingQuotePromotions(Id.valueOf(this.quoteId));
				if (record?.SBQQ__Status__c == QTB_Constants.QUOTE_DRAFT_STATUS && record?.SBQQ__Type__c != QTB_Constants.QUOTE_TYPE_AMEND) {
					promotions = new List<PromoWrapper>();
					for (QTB_Promotion__c promo : this.getPromotionDetails(record)) {
						promotions.add(
							new PromoWrapper(
								promo,
								this.existingPromotions.containsKey(promo.Id),
								this.existingPromotions.get(promo.Id)?.QTB_Promo_Applied__c
							)
						);
					}
				}
               
    //In case of amendment, user should be able to see the valid promotions along with the selected promotions which are carried over
    //from sales quote            
                if (record?.SBQQ__Status__c == QTB_Constants.QUOTE_DRAFT_STATUS && record?.SBQQ__Type__c == QTB_Constants.QUOTE_TYPE_AMEND) {
				  promotions = new List<PromoWrapper>();             
                  //To store promotions applicable for amendment quote
                  List<QTB_Promotion__c> promoList = this.getPromotionDetails(record);                   
                  Map<String,QTB_Promotion__c> mapOfQTBPromotion = new Map<String,QTB_Promotion__c>(); 
                  //To fetch salequote id which will then be used to retrieve sales quote promotions
                  Id salesQuoteId = record?.SBQQ__MasterContract__r?.SBQQ__Quote__c;            
                  set<String> qpSet = new set<String>();  
                  
                  for (QTB_Quote_Promotion__c qp : [select QTB_Promo_Code__c 
                                                    from QTB_Quote_Promotion__c 
                                                    where QTB_Quote__c =:salesQuoteId]) 
					{
    				 qpSet.add(qp.QTB_Promo_Code__c);
					}				      
                	//Retrieving detailed information of selected Sale Quote promotion on Amendment
                    for(QTB_Promotion__c pr : [select id,Name,QTB_Country__c,QTB_Start_Date__c,QTB_End_Date__c,QTB_Product__c,
                                                 QTB_Quote_Type__c,QTB_Promo_Inactive__c,QTB_Promo_Code__c,QTB_Promo_Description__c,
                                                 QTB_Promo_Percent__c,QTB_Promo_Amount__c,QTB_Promo_Term__c,
                                                 CurrencyIsoCode,QTB_Minimum_Quote__c from QTB_Promotion__c
                                                 WHERE QTB_Promo_Code__c IN: qpSet]) 
                    {
                      mapOfQTBPromotion.put(pr.QTB_Promo_Code__c,pr);
                    }
                   // Retriveing Quote Promotions for Amendment Quote
                    for(QTB_Quote_Promotion__c qp : [select id,QTB_Store_Promotion_Name__c,QTB_Promotion_Name__c,QTB_Promo_Code__c,
                                                     QTB_Promotion_Start_Date__c,QTB_Promotion_End_Date__c 
                                                     from QTB_Quote_Promotion__c where QTB_Quote__c =:quoteId]) 
                 	{
                     //Validation & Insertion of Promotion Records for Amended Quote   
                     if(mapOfQTBPromotion.containsKey(qp.QTB_Promo_Code__c))
                     	{
                         if(!promoList.contains(mapOfQTBPromotion.get(qp.QTB_Promo_Code__c))){
                         promoList.add(mapOfQTBPromotion.get(qp.QTB_Promo_Code__c));
                     	}
                     }
                        
                    }                        
                    
					for (QTB_Promotion__c promo : promoList) {
						promotions.add(
							new PromoWrapper(
								promo,
								this.existingPromotions.containsKey(promo.Id),
								this.existingPromotions.get(promo.Id)?.QTB_Promo_Applied__c
							)
						);
					}
				}
                
			} catch (QueryException e) {
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
          }
		}
	}

	 /***********************************************************************************************************
     * Method :      getQuoteDetails 
     * Parameters:   Id
     * Return Type : SBQQ__Quote__c
     * Requirement : Gitlab#378 
     * Description:  This method is used to get the quote details
     **************************************************************************************************************/  
 
    private SBQQ__Quote__c getQuoteDetails(Id quoteId) {
		if (quoteId == null || String.valueOf(quoteId).length() <= 15) {
			return null;
		}
		return [
			SELECT
				Id,
                SBQQ__MasterContract__r.SBQQ__Quote__c,
                SBQQ__Status__c,
				SBQQ__NetAmount__c,
				QTB_IM_Country__c,
				SBQQ__Type__c,
				SBQQ__StartDate__c,
				CurrencyIsoCode,
				QTB_Has_Promo__c,
				Name,
				SBQQ__LineItemCount__c
			FROM SBQQ__Quote__c
			WHERE Id = :quoteId 
		];
	}

    /***********************************************************************************************************
     * Method :      getProductsFromQuote 
     * Parameters:   Id
     * Return Type : Set<Id>
     * Requirement : Gitlab#378 
     * Description:  This method is used to get all the product Ids for this particular quote from QuoteLine
     **************************************************************************************************************/  
 
	private Set<Id> getProductsFromQuote(Id quoteId) {
		mapOfQuoteLinebyProductId = new Map<Id, SBQQ__QuoteLine__c>();
		for (SBQQ__QuoteLine__c ql : [
			SELECT id, SBQQ__Product__c
			FROM SBQQ__QuoteLine__c
			WHERE SBQQ__Quote__c = :quoteId
		]) {
			mapOfQuoteLinebyProductId.put(ql.SBQQ__Product__c, ql);
		}
      
		return new Set<Id>(mapOfQuoteLinebyProductId.keySet());
	}

    /***********************************************************************************************************
     * Method :      getExistingQuotePromotions 
     * Parameters:   Id
     * Return Type : Map<Id, QTB_Quote_Promotion__c>
     * Requirement : Gitlab#378 
     * Description:  This method is used to get all the existing Quote Promotion records on Quote
     **************************************************************************************************************/  
 
	private Map<Id, QTB_Quote_Promotion__c> getExistingQuotePromotions(Id quoteId) {
		Map<Id, QTB_Quote_Promotion__c> mapOfPromoIdToUniqueId = new Map<Id, QTB_Quote_Promotion__c>();
		for (QTB_Quote_Promotion__c quotePromo : [
			SELECT Id, QTB_Promotion_Name__c, QTB_Quote__c, QTB_Promo_Applied__c, QTB_Targets_Quote__c
			FROM QTB_Quote_Promotion__c
			WHERE QTB_Quote__c = :quoteId
		]) {
			mapOfPromoIdToUniqueId.put(quotePromo.QTB_Promotion_Name__c, quotePromo);
		}
		return mapOfPromoIdToUniqueId;
	}

     /***********************************************************************************************************
     * Method :      getPromotionDetails 
     * Parameters:   SBQQ__Quote__c
     * Return Type : List<QTB_Promotion__c>
     * Requirement : Gitlab#378 
     * Description:  This method is used to show the Promotion records on Select Promotion window which are valid for 
     *               this particular quote based on certain filter criteria
     **************************************************************************************************************/  
 
	private List<QTB_Promotion__c> getPromotionDetails(SBQQ__Quote__c quote) {
		Set<Id> productIds = getProductsFromQuote(quote.Id);
       //Adding null value to the set, Since quote level promotion will not have any product associated with it i.e. Promotion Product will be blank for this
       productIds.add(null);
		return [
			SELECT
				Id,
				Name,
				QTB_Country__c,
				QTB_Start_Date__c,
				QTB_End_Date__c,
				QTB_Product__c,
				QTB_Quote_Type__c,
				QTB_Promo_Inactive__c,
				QTB_Promo_Code__c,
				QTB_Promo_Description__c,
				QTB_Promo_Percent__c,
				QTB_Promo_Amount__c,
				QTB_Promo_Term__c,
				CurrencyIsoCode,
				QTB_Minimum_Quote__c
			FROM QTB_Promotion__c
			WHERE
				QTB_Promo_Inactive__c = FALSE
				AND QTB_Quote_Type__c = :quote.SBQQ__Type__c    
				AND (QTB_Country__c = :quote.QTB_IM_Country__c
				OR QTB_Country__c = NULL)
				AND QTB_Start_Date__c <= :quote.SBQQ__StartDate__c
				AND QTB_End_Date__c >= :quote.SBQQ__StartDate__c
				AND QTB_Product__c IN :productIds
				AND CurrencyIsoCode = :quote.CurrencyIsoCode
				AND (QTB_Minimum_Quote__c = NULL
				OR QTB_Minimum_Quote__c <= :quote.SBQQ__NetAmount__c)
		];
	}
       
      
    /***********************************************************************************************************
     * Method :      setPromotionOnQuoteLine 
     * Parameters:   PromoWrapper
     * Return Type : void
     * Requirement : Gitlab#820/486 - promotion calculation and backing out
     * Description:  This method is used to copy Promotion Term from Promotion to QuoteLine when user selects product level promotion
     **************************************************************************************************************/  
 
    @TestVisible
    private void setPromotionOnQuoteLine(PromoWrapper promowrap) {
        SBQQ__QuoteLine__c qline = mapOfQuoteLinebyProductId.get(promowrap.record.QTB_Product__c);
		if (qline == null)
			return;
        
        qline.QTB_Promotion_Term__c = promowrap.record.QTB_Promo_Term__c;  
        quoteLinesToUpdateById.put(qline.Id, qline);
        system.debug('Test11 - ' + quoteLinesToUpdateById);
    }

     /***********************************************************************************************************
     * Method :      resetPromotionOnQuoteLine 
     * Parameters:   PromoWrapper
     * Return Type : void
     * Requirement : Gitlab#820/486 - promotion calculation and backing out
     * Description:  When user deselects product level promotion, then reset quote line fields to null
     **************************************************************************************************************/  

  @TestVisible    
	private void resetPromotionOnQuoteLine(PromoWrapper promowrap) {
		SBQQ__QuoteLine__c qline = mapOfQuoteLinebyProductId.get(promowrap.record.QTB_Product__c);
		if (qline == null)
			return;
       
		qline.QTB_Promo_Amount__c = null;
		qline.QTB_Promo_Percent__c = null;
        qline.SBQQ__AdditionalDiscountAmount__c = null;
        /* Start - To get consumption bundle work properly setting this field to '0'*/
        qline.SBQQ__Discount__c = 0;
        /*End*/
		qline.QTB_Promo_Code__c = null;
        qline.QTB_Promotion_Name__c = null;
        qline.QTB_Promotion_Start_Date__c = null;
        qline.QTB_Promotion_End_Date__c = null;
        
		// only reset those Quote Lines which does not exist in the Quote Lines to Set list
		// suppose we have a Quote Line where promotion was selected
		// user deselected that promotion and applied another one for the same product
		// we want to directly set the new promotion, instead of resetting it
		if (!quoteLinesToUpdateById.containsKey(qline.Id)) {
			quoteLinesToUpdateById.put(qline.Id, qline);
		}
	}

    /***********************************************************************************************************
     * Method :      setPromotionOnQuote 
     * Parameters:   PromoWrapper
     * Return Type : void
     * Requirement : Gitlab#820/486 - promotion calculation and backing out
     * Description:  When user selects quote level promotion, copy quote's QTB_Promo_Code__c and QTB_Promotion_Term__c fields 
     *               from promotion fields
     **************************************************************************************************************/  
    
	private void setPromotionOnQuote(PromoWrapper promowrap) {
        
		this.record.QTB_Promo_Code__c = promowrap.record.QTB_Promo_Code__c;
        this.record.QTB_Promotion_Term__c = promowrap.record.QTB_Promo_Term__c; 
    }

    /***********************************************************************************************************
     * Method :      resetPromotionOnQuote 
     * Parameters:   parameterless
     * Return Type : void
     * Requirement : Gitlab#820/486 - promotion calculation and backing out
     * Description:   When user deselects quote level promotion, set quote fields to null and quote line fields to null
     **************************************************************************************************************/  

    @TestVisible
	private void resetPromotionOnQuote() {
        this.record.QTB_Promo_Percent__c = null;
        
        for (SBQQ__QuoteLine__c ql : [
			SELECT id, SBQQ__Product__c
			FROM SBQQ__QuoteLine__c
			WHERE SBQQ__Quote__c = :quoteId
		]) {
          
        SBQQ__QuoteLine__c qline = mapOfQuoteLinebyProductId.get(ql.SBQQ__Product__c);       
		if (qline == null)
			return;
        qline.QTB_Promo_Percent_Quote__c = null;
		qline.QTB_Promo_Code__c = null;
        /* Start - To get consumption bundle work properly setting this field to '0'*/ 
         qline.SBQQ__Discount__c = 0;                       
        /*End*/    
        qline.SBQQ__AdditionalDiscountAmount__c = null;  
        qline.QTB_Promotion_Name__c = null;
        qline.QTB_Promotion_Start_Date__c = null;
        qline.QTB_Promotion_End_Date__c = null;
		// only reset those Quote Lines which does not exist in the Quote Lines to Set list
		// suppose we have a Quote Line where promotion was selected
		// user deselected that promotion and applied another one for the same product
		// we want to directly set the new promotion, instead of resetting it
		if (!quoteLinesToUpdateById.containsKey(qline.Id)) {
			quoteLinesToUpdateById.put(qline.Id, qline);
		}
        } 
    }

     /***********************************************************************************************************
     * Method :      save 
     * Parameters:   parameterless
     * Return Type : Pagereference
     * Requirement : Gitlab#378,486
     * Description:  This method is executed when user clicks on "Apply Promotion" button on Select Promotions window.
     *               If the records selected are correct then it will save Quote Promotion records respective to each promotion 
     *               selected,otherwise throw error.
     **************************************************************************************************************/  
    
	public Pagereference save() {
		Boolean quoteLevelPromoApplied = false;
        Boolean pageToreturn = false;
		hasPromo = System.Label.QTB_No;
		// Save to Quote Promotion
		
		List<QTB_Quote_Promotion__c> selectedPromotions = new List<QTB_Quote_Promotion__c>();
        List<QTB_Quote_Promotion__c> deselectedPromotions = new List<QTB_Quote_Promotion__c>();
        
        //Get data into Quote Promotion from Promotion
		List<QTB_Field_Mapping__mdt> metadatas = QTB_Utils.GetFieldMapMetadata(
			'QTB_Promotion__c',
			'QTB_Quote_Promotion__c',
			'Promotions'
		);
        
        //This Map is used to increment the counter value to show error message on Select Promotion window when user selects
        // more than one promotion for Quote level or more than one promotion for the same product
        Map<String,String> counterMap = new  Map<String,String>();
        Integer Pcounter = 0;
        Integer Qcounter = 0;
        
        for (PromoWrapper promo : this.promotions) {
            
			if (promo.selected && existingPromotions.get(promo.record.Id) == null) {
                //To identify duplicate product level promotion       
                if(promo.record.QTB_Product__c <> null){
                    if(counterMap.containsKey(promo.record.QTB_Product__c)){
                        Pcounter++;
      
                    }
                       //Storing in map, if unique product level promotion is selected
                       else{
                        counterMap.put(promo.record.QTB_Product__c,'promo');   
                       }
                }    
                //To identify duplicate quote level promotion       
                else if(promo.record.QTB_Product__c == null){
                    if(counterMap.containsKey('Quote')){
                        Qcounter++;
                    }
                       //Storing in map, if unique quote level promotion is selected
                       else{
                           counterMap.put('Quote','promo');   
                       }
                }
            }
            else if (promo.selected && existingPromotions.get(promo.record.Id) <> null) {
				
                if(promo.record.QTB_Product__c <> null){
                    if(counterMap.containsKey(promo.record.QTB_Product__c)){
                       Pcounter++;
                    }
                       else{
                        counterMap.put(promo.record.QTB_Product__c,'promo');   
                       }
                }    
                else if(promo.record.QTB_Product__c == null){
                    if(counterMap.containsKey('Quote')){
                       Qcounter++; 
                    }
                       else{
                           counterMap.put('Quote','promo');   
                       }
                }
        }
       }
        
        //Show error message when user selects more than one quote level promotion and more than one promotion for same product
        if(Pcounter <> 0 && Qcounter <> 0){
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.QTB_Product_Level_Promotion_Validation +'<br/>'+ Label.QTB_Quote_Level_Promotion_Validation));  
                        pageToreturn = true;
        } 
        //Show error message when user selects more than one quote level promotion
        else if(Qcounter <> 0){
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.QTB_Quote_Level_Promotion_Validation));  
                        pageToreturn = true;
        }
        //Show error message when user selects more than one promotion for same product
        else if(Pcounter <> 0){
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.QTB_Product_Level_Promotion_Validation));  
                        pageToreturn = true;
        }
        //When error is thrown user should be in same page i.e. select promotion window
         if(pageToreturn == true){
		   return null;
        }
        
        //When duplicate promotions are not selected then only insert Quote promotion records
        if(Pcounter == 0 && Qcounter == 0){
            
        for (PromoWrapper promo : this.promotions) {
            //When promotion is selected, insert corresponding Quote-Promotion record
			if (promo.selected && existingPromotions.get(promo.record.Id) == null) {
			    hasPromo = System.Label.QTB_Yes;
				QTB_Quote_Promotion__c quotepromo = new QTB_Quote_Promotion__c();
				quotepromo.QTB_Quote__c = Id.valueOf(quoteId);
                quotepromo.QTB_Promo_Code__c = promo.record.QTB_Promo_Code__c;
				quotepromo.Name = promo.record.Name;
				quotepromo.QTB_Promotion_Name__c = promo.record.Id;
                quotepromo.QTB_Promotion_Start_Date__c = promo.record.QTB_Start_Date__c ;
                quotepromo.QTB_Promotion_End_Date__c = promo.record.QTB_End_Date__c;
                QTB_Utils.MapSourceFldValuetoDestFldVal(quotepromo, promo.record, metadatas);
                
                selectedPromotions.add(quotepromo);
                                
               //When quote level promotion is applied then set quote fields from promotion else set quote line fields 
               //for product level promotion    
				if (promo.record.QTB_Product__c == null) {
					setPromotionOnQuote(promo);
					quoteLevelPromoApplied = true;
				} 
                // Set promotion term in quoteline
                else{
                    setPromotionOnQuoteLine(promo);
                }
             
			} 
            //Recent deselected promotions are validated against old set of existing promotions for exclusion
            else if (!promo.selected && existingPromotions.get(promo.record.Id) <> null) {
				deselectedPromotions.add(existingPromotions.get(promo.record.Id));
               
                //When promotion is deselected by the user, then reset quoteline fields to null
				if (!quoteLevelPromoApplied && existingPromotions.get(promo.record.Id).QTB_Targets_Quote__c) {
					resetPromotionOnQuote();                 
                  } else {
					resetPromotionOnQuoteLine(promo);
                  }
			} else if (promo.selected && existingPromotions.get(promo.record.Id) <> null) {
				hasPromo = System.Label.QTB_Yes;
               
			}
		}
       
       //Insert the Quote Promotion records with respect to each promotion selected with additional duplicate 
       //insertion avoidance
       
        Map<String, QTB_Quote_Promotion__c> mapOfExistingQTBPromotion = new Map<String, QTB_Quote_Promotion__c>();
        List<QTB_Quote_Promotion__c> selectedapplicablePromotions = new List<QTB_Quote_Promotion__c>();
         
        for(QTB_Quote_Promotion__c qp : [select id,QTB_Store_Promotion_Name__c,QTB_Promotion_Name__c,QTB_Promo_Code__c,
                                                     QTB_Promotion_Start_Date__c,QTB_Promotion_End_Date__c 
                                                     from QTB_Quote_Promotion__c where QTB_Quote__c =:quoteId]){
         mapOfExistingQTBPromotion.put(qp.QTB_Promo_Code__c,qp);
        }
		
		for (QTB_Quote_Promotion__c qqp: selectedPromotions){            
          	if (!mapOfExistingQTBPromotion.containsKey(qqp.QTB_Promo_Code__c)){            
				selectedapplicablePromotions.add(qqp);
				}  
           }    
       
        if (selectedapplicablePromotions.size() > 0) {
			try {
				insert selectedapplicablePromotions;
               
			} catch (DmlException e) {
                 QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
                 ApexPages.addMessages(e);
				return null;
			}
            
		}
       //Promotion records which are deselected by the user, delete respective Quote Promotion records     
		if (deselectedPromotions.size() > 0) {
			try {
				delete deselectedPromotions;
			} catch (DmlException e) {
                 QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
                 ApexPages.addMessages(e);
				return null;
			}
		}
		if (quoteLinesToUpdateById.size() > 0) {
            //To apply promotion in a single transaction we are disabling package trigger calculation service so that both 
            //product level and quote level promotion will be applied at a time and update the respective fields
			SBQQ.TriggerControl.disable();
			update quoteLinesToUpdateById.values();
			SBQQ.TriggerControl.enable();
		}

		// if there are no existing Promos (hasPromo = false) but now it is true
		// or hasPromo = false now and existing Promos
		if (hasPromo <> record.QTB_Has_Promo__c || selectedapplicablePromotions.size() > 0) {
			record.QTB_Has_Promo__c = hasPromo;
		}
		try {
            /*This field is set to true when promotion is applied so that our price rule logic for nullifying promotion and 
              price adjustment fields will not fail i.e, when promotion is not applied on sales quote and I'm renewing quote and
              applying promotion.In this case, our price rule will fire and instead of showing promotion amount/percent on qle
              it will override and display null */
            record.QTB_Renewal_YN__c = true;
            //This field is used to forcefully trigger the promotion calculation whenever this field is changed.
            //This field is included in Calculating field set
            record.QTB_Promo_Last_Applied_On__c = System.now();
			update record;
		} catch (DmlException e) {
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            ApexPages.addMessages(e);
			return null;
		}
       }  //pcounter qcounter if block closing
       
        
        return this.toQuoteLineEditor();  
	}

     /***********************************************************************************************************
     * Method :      cancel 
     * Parameters:   parameterless
     * Return Type : Pagereference
     * Requirement : Gitlab#378
     * Description:   When user clicks on Cancel button, user should be redirected to QLE page
     **************************************************************************************************************/  

	public Pagereference cancel() {
		return this.toQuoteLineEditor();
	}

    /***********************************************************************************************************
     * Method :      toQuoteLineEditor 
     * Parameters:   parameterless
     * Return Type : Pagereference
     * Requirement : Gitlab#378
     * Description:   When user clicks on Cancel button, user should be redirected to QLE page
     **************************************************************************************************************/  

	private Pagereference toQuoteLineEditor() {
		// redirects back to quote line editor
		PageReference qleURL = Page.SBQQ__SB;
		qleURL.getParameters().put('scontrolCaching', '1');
		qleURL.getParameters().put('id', Id.valueOf(this.quoteId));
		qleURL.setRedirect(true);
		return qleURL;
	}

     /***********************************************************************************************************
     * Class :      PromoWrapper 
     * Requirement : Gitlab#378
     * Description:  Wraps over the promotion data based on its selection and deselection
     **************************************************************************************************************/  

	public with sharing class PromoWrapper {
		public Boolean selected { get; set; }
		public QTB_Promotion__c record { get; private set; }
		public Boolean applied { get; private set; }

		public PromoWrapper(QTB_Promotion__c promotion, Boolean exists, Boolean appliedAlready) {
			this.record = promotion;
			this.selected = exists;
			this.applied = appliedAlready == null ? false : appliedAlready;
		}
	}
}
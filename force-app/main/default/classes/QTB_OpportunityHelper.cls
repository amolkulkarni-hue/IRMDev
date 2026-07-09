/*****************************************************************************************************
 * Class: QTB_OpportunityHelper
 * Author: Accenture
 * Purpose: This is a helper class for all business logic related to Opportunity object
 * Requirement:
 * Change History: 8/4/2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *
 *******************************************************************************************************/
public with sharing class QTB_OpportunityHelper {
public static boolean SingleTon = true;
private static final String CLASSNAME = QTB_OpportunityHelper.class.getName();
/***********************************************************************************************************
 * Method : process
 * Parameters: List<Opportunity>, Map<Id,Opportunity>,Map<Id,Opportunity>,System.TriggerOperation
 * Return Type: void
 * Description: Generic method to handle all operations on the Opp Records
 **************************************************************************************************************/
public static void process(
  List<Opportunity> newItems,
  Map<Id, Opportunity> newMap,
  Map<Id, Opportunity> oldItems,
  System.TriggerOperation operationType
) {
  // Storage
  Set<Id> listOfContractIdOnAmendmentOpportunity = new Set<Id>();
  List<QTB_Utils.Mapping> amendmentMappings = new List<QTB_Utils.Mapping>();
  Set<Id> listOfContractIdOnRenewalOpportunity = new Set<Id>();
  List<QTB_Utils.Mapping> renewalMappings = new List<QTB_Utils.Mapping>();
  /***********************************/
  /* populateOriginalQuote */
  Map<Id, Id> contractwithOriginalQuoteMap = new Map<Id, Id>();
  Set<Id> allContractIdSet = new Set<Id>();
  List<Opportunity> nonNewOpportunityList = new List<Opportunity>();
  /**********************************/
  /* updateDeferralCheckboxonQuote */
  Map<ID, Boolean> optyIdDeferredMap = new Map<ID, Boolean>();
  /*********************************/
  /* primaryProductLineValidation */
  Set<id> oppSet = new Set<id>();
  List<String> billingCountry = new List<String>();
  List<String> oppsCurrency = new List<String>();
  List<String> prodLine = new List<String>();
  /********************************/
  /* popoulateLatestOpportunityOnContract */
  ID salesAmendConId;
  ID latestOptyId;
  List<Contract> contractToBeUpdated = new List<Contract>();
  
  /************************/

  for (Opportunity eachOpp : newItems) {
    // Add your logic here
    // TODO: get the record from olmap instead of using it all over the place
    switch on operationType {
      when BEFORE_INSERT {
        // Check amend opportunity creation which is on global sales opp
        if (
          String.isNotBlank(eachOpp.SBQQ__AmendedContract__c) &&
          String.isNotEmpty(eachOpp.SBQQ__AmendedContract__c)
        ) {
          eachOpp.Type = QTB_Constants.OPP_TYPE_RATE_CHANGE;
          listOfContractIdOnAmendmentOpportunity.add(
            eachOpp.SBQQ__AmendedContract__c
          );
          amendmentMappings.add(
            new QTB_Utils.Mapping(eachOpp.SBQQ__AmendedContract__c, eachOpp)
          );
        }
        // Check Renew opportunity creation which is on global sales opp
        if (
          String.isNotBlank(eachOpp.SBQQ__RenewedContract__c) &&
          String.isNotEmpty(eachOpp.SBQQ__RenewedContract__c)
        ) {
          eachOpp.StageName = QTB_Constants.STAGEVALUE_ONESETUP;
          eachOpp.Type = QTB_Constants.TYPE_RENEWAL;
          listOfContractIdOnRenewalOpportunity.add(
            eachOpp.SBQQ__RenewedContract__c
          );
          renewalMappings.add(
            new QTB_Utils.Mapping(eachOpp.SBQQ__RenewedContract__c, eachOpp)
          );
        }
        // populate original opportunity
        if (
          (eachOpp.Type == QTB_Constants.OPP_TYPE_RATE_CHANGE ||
          eachOpp.Type == QTB_Constants.OPP_TYPE_UP_SELL) &&
          eachOpp.SBQQ__AmendedContract__c != null
        ) {
          allContractIdSet.add(eachOpp.SBQQ__AmendedContract__c);
          nonNewOpportunityList.add(eachOpp);
          //ALM Defect-251 Default booked date to FirstBillDate-1
          //eachOpp.IM_Booked_Date__c = eachOpp.CloseDate - 1;
          eachOpp.IM_Booked_Date__c = eachOpp.CloseDate;
          eachOpp.CloseDate = eachOpp.CloseDate -1;
        }
        // populate original opportunity
        if (
          eachOpp.Type == QTB_Constants.TYPE_RENEWAL &&
          eachOpp.SBQQ__RenewedContract__c != null
        ) {
          allContractIdSet.add(eachOpp.SBQQ__RenewedContract__c);
          nonNewOpportunityList.add(eachOpp);
          //ALM Defect-251 Default booked date to FirstBillDate-1
          //eachOpp.IM_Booked_Date__c = eachOpp.CloseDate - 1;
          eachOpp.IM_Booked_Date__c = eachOpp.CloseDate;
          eachOpp.CloseDate = eachOpp.CloseDate -1;
        }
        if (eachOpp.isClone()) {
          eachOpp.QTB_DM_Source_ID__c = null;
          eachOpp.QTB_DM_Source_System__c = null;
        }
      }
      when BEFORE_UPDATE {
          
              // updateDeferralCheckboxonQuote
        if (
          eachOpp.RecordTypeId == QTB_Utils.OPP_SALES_RECTYPEID &&
          eachOpp.Type == QTB_Constants.OPP_TYPE &&
          (oldItems.get(eachOpp.id).QTB_Deferred_Renewal_Opportunity__c !=
          eachOpp.QTB_Deferred_Renewal_Opportunity__c)
        ) {
          optyIdDeferredMap.put(
            eachOpp.id,
            eachOpp.QTB_Deferred_Renewal_Opportunity__c
          );
        }
        // populate original opportunity
        if (
          (eachOpp.Type == QTB_Constants.OPP_TYPE_RATE_CHANGE ||
          eachOpp.Type == QTB_Constants.OPP_TYPE_UP_SELL) &&
          eachOpp.SBQQ__AmendedContract__c != null
        ) {
          allContractIdSet.add(eachOpp.SBQQ__AmendedContract__c);
          nonNewOpportunityList.add(eachOpp);
          if (eachOpp.CloseDate != oldItems.get(eachOpp.Id).CloseDate) {
            //ALM Defect-251 Default booked date to FirstBillDate-1
            // eachOpp.IM_Booked_Date__c = eachOpp.CloseDate - 1;
            eachOpp.IM_Booked_Date__c = eachOpp.CloseDate;
            eachOpp.CloseDate = eachOpp.CloseDate -1;
          }
        }
        // populate original opportunity
        if (
          eachOpp.Type == QTB_Constants.TYPE_RENEWAL &&
          eachOpp.SBQQ__RenewedContract__c != null
        ) {
          allContractIdSet.add(eachOpp.SBQQ__RenewedContract__c);
          nonNewOpportunityList.add(eachOpp);
          if (eachOpp.CloseDate != oldItems.get(eachOpp.Id).CloseDate) {
            //ALM Defect-251 Default booked date to FirstBillDate-1
            //eachOpp.IM_Booked_Date__c = eachOpp.CloseDate - 1;
            eachOpp.IM_Booked_Date__c = eachOpp.CloseDate;
            eachOpp.CloseDate = eachOpp.CloseDate -1;
          }
        }
        // primaryProductLineValidation
        if (
          eachOpp.RecordTypeId == QTB_Utils.OPP_SALES_RECTYPEID &&
          (oldItems.get(eachOpp.id).Primary_Product_Line__c !=
          eachOpp.Primary_Product_Line__c ||
          oldItems.get(eachOpp.id).Billing_Country__c !=
          eachOpp.Billing_Country__c ||
          oldItems.get(eachOpp.id).CurrencyIsoCode != eachOpp.CurrencyIsoCode)
        ) {
          billingCountry.add(eachOpp.QTB_Billing_Country_Name__c);
          oppSet.add(eachOpp.id);
          oppsCurrency.add(eachOpp.CurrencyIsoCode);
          prodLine.add(eachOpp.Primary_Product_Line__c);            
          
        }
      }
      when AFTER_UPDATE {
      }
      when else {
      }
    }
  }
  // post processing
      if (listOfContractIdOnAmendmentOpportunity <> null) {
    autoPopulate(
      listOfContractIdOnAmendmentOpportunity,
      amendmentMappings,
      QTB_Constants.TYPE_AMENDMENT
    );
  }
  if (listOfContractIdOnRenewalOpportunity <> null) {
    autoPopulate(
      listOfContractIdOnRenewalOpportunity,
      renewalMappings,
      QTB_Constants.TYPE_RENEWAL
    );
  }
  // populate original Quote
  if (!allContractIdSet.isEmpty()) {
    populateOriginalQuote(allContractIdSet, nonNewOpportunityList);
  }
  // update reset to original price Checkbox on Quote
  if (!optyIdDeferredMap.isEmpty()) {
    updateDeferralCheckboxonQuote(optyIdDeferredMap);
  }
  // validate primary product line change
  if (!oppSet.isEmpty()) {
    primaryProductLineValidation(oppSet, oldItems, newMap , billingCountry , oppsCurrency , prodLine);
  }

}


/***********************************************************************************************************
 * Method :      updateDeferralCheckboxonQuote
 * Parameters:   Map<ID,Boolean>
 * Return Type : void
 * Requirement : JIRA# SFCPQBLG-10
 * Start Date :  5/28/2020
 * Description:  This method updates the reset to original price checkbox on primary quote
 *         when Deferred is checked on Opportunity
 **************************************************************************************************************/
public static void updateDeferralCheckboxonQuote(
  Map<ID, Boolean> optyIdDeferredMap
) {
  try {
    if (OpportunityTriggerHandler.throwExplicitException) {
      throw new NullPointerException();
    }
    List<SBQQ__Quote__c> qteDefList = new List<SBQQ__Quote__c>();
    for (SBQQ__Quote__c qte : [
      SELECT id, QTB_Reset_to_Original_Prices__c, SBQQ__Opportunity2__c
      FROM SBQQ__Quote__c
      WHERE
        SBQQ__Primary__c = TRUE
        AND QTB_Reset_to_Original_Prices__c = FALSE
        AND SBQQ__Opportunity2__c IN :optyIdDeferredMap.keySet()
    ]) {
      qte.QTB_Reset_to_Original_Prices__c = optyIdDeferredMap.get(
        qte.SBQQ__Opportunity2__c
      );
      qteDefList.add(qte);
    }
    if (!qteDefList.isEmpty()) {
      update qteDefList;
    }
  } catch (Exception e) {
    QTB_ExceptionLogger.createLog(
      e.getLineNumber(),
      e.getStackTraceString(),
      e.getMessage(),
      e.getTypeName(),
      CLASSNAME
    );
    throw e;
  }
}

// temporary method to be refactored
/***********************************************************************************************************
 * Method : autoPopulate
 * Parameters:  Set<Id> , List<QTB_Utils.Mapping> , String
 * Return Type : void
 * Requirement :
 * Start Date :
 * Description:
 **************************************************************************************************************/
public static void autoPopulate(
  Set<Id> setOfIds,
  List<QTB_Utils.Mapping> mappings,
  String event
) {
  try {
    if (OpportunityTriggerHandler.throwExplicitException) {
      throw new NullPointerException();
    }
    QTB_Utils.fieldUpdate(
      setOfIds,
      mappings,
      QTB_Constants.TYPE_CONTRACT,
      QTB_Constants.TYPE_OPPORTUNITY,
      event
    );
  } catch (Exception e) {
    QTB_ExceptionLogger.createLog(
      e.getLineNumber(),
      e.getStackTraceString(),
      e.getMessage(),
      e.getTypeName(),
      CLASSNAME
    );
    throw e;
  }
}


/***********************************************************************************************************
 * Method : primaryProductLineValidation
 * Requirement : SFCPQBLG-582
 * Author : Accenture
 * Description: Throw error when primary product line is changed on opportunity
 **************************************************************************************************************/
public static void primaryProductLineValidation(
  Set<id> oppSet,
  Map<Id, Opportunity> oldItems,
  Map<Id, Opportunity> newItems,
  List<String> billingCountry,
  List<String> oppsCurrency,
  List<String> prodLine
) {
  try {
    if (OpportunityTriggerHandler.throwExplicitException) {
      throw new NullPointerException();
    }
    for (Opportunity oppty : [
      SELECT
        id,
        Primary_Product_Line__c,
        Billing_Country__c,
        (SELECT id, SBQQ__Opportunity2__c FROM sbqq__quotes2__r LIMIT 1)
      FROM Opportunity
      WHERE id IN :oppSet
    ]) {
      if (!oppty.sbqq__Quotes2__r.isEmpty()) {
        //logic for adding error
        if (
          oldItems.get(oppty.id).Billing_Country__c !=
          newItems.get(oppty.id).Billing_Country__c &&
          oldItems.get(oppty.id).Primary_Product_Line__c !=
          newItems.get(oppty.id).Primary_Product_Line__c
        ) {
          String error =
            System.Label.QTB_add_validation_on_oppty +
            '\n' +
            System.Label.QTB_add_validation_on_oppty_Billing_Country;
          newItems.get(oppty.Id).addError(error);
        } else if (
          oldItems.get(oppty.id).Primary_Product_Line__c !=
          newItems.get(oppty.id).Primary_Product_Line__c
        ) {
          newItems.get(oppty.Id)
            .addError(System.Label.QTB_add_validation_on_oppty);
        } else if (
          oldItems.get(oppty.id).Billing_Country__c !=
          newItems.get(oppty.id).Billing_Country__c
        ) {
          newItems.get(oppty.Id)
            .addError(
              System.Label.QTB_add_validation_on_oppty_Billing_Country
            );
        }
      }
    }
     //**GITLAB #375 - Logic to show validation if Sales User does not find the product with the guven Billing Country ,Product Line & Currency.
    Map<Id,Id> prodgrpToPBE = new Map<Id,Id>();
    Set<Id> pricebookIds = new Set<Id>();
    Map<Id,Opportunity> oppsToPB = new Map<Id,Opportunity>();
    for(Opportunity opps : newItems.values()){
    for(Pricebook2 pb: [SELECT QTB_Country__c , Id from Pricebook2 WHERE IsActive = true AND QTB_Country__c in : billingCountry ]){
        if(opps.QTB_Billing_Country_Name__c.equals(pb.QTB_Country__c)) 
      oppsToPB.put(pb.Id,opps);
      }
    }
    
    //Fetch Price Book Entry from the Price Book and put it in the Map prodgrpToPBE 
    for(PricebookEntry PBE : [SELECT Pricebook2Id , ID , Product2Id 
                              FROM PricebookEntry
                              WHERE Pricebook2Id in :oppsToPB.keySet() AND CurrencyIsoCode in :oppsCurrency ]){                               
                              prodgrpToPBE.put(PBE.Product2Id,PBE.Pricebook2Id);
                              }
    //Fetch Product for the matching Billing Country , Primary Product Line & Currency
    for(SBQQ__ProductOption__c POs : [select Id,SBQQ__ConfiguredSKU__r.Name,SBQQ__OptionalSKU__c 
                                    from SBQQ__ProductOption__c 
                                    WHERE SBQQ__OptionalSKU__c in (select Product2Id from pricebookentry 
                                    WHERE Pricebook2Id in :oppsToPB.keySet() AND CurrencyIsoCode in :oppsCurrency) 
                                    AND SBQQ__ConfiguredSKU__r.Family in :prodLine]){
                                    if(prodgrpToPBE.containskey(POs.SBQQ__OptionalSKU__c)){
                                    pricebookIds.add(prodgrpToPBE.get(POs.SBQQ__OptionalSKU__c));
                                    }
                                    }
          //Throw Validation for the Opportunity which dont have product available with the Billing Country/Currency/Product Line 
    for(Id pbID:  oppsToPB.keyset() ){
    if(!pricebookIds.contains(pbID) && !Test.isRunningTest()){
      newItems.get(oppsToPB.get(pbID).Id).addError(
      System.Label.QTB_add_validation_on_oppty_productline
    );
        }
          
      
    }
      } catch (Exception e) {
    QTB_ExceptionLogger.createLog(
      e.getLineNumber(),
      e.getStackTraceString(),
      e.getMessage(),
      e.getTypeName(),
      CLASSNAME
    );
    throw e;
  }
}

    /***********************************************************************************************************
    * Method : opportunityQuoteValidation
    * Requirement : GitLab-6235
    * Author : Sairam Kumar
    * Description: Throw error when converting the opportunity with quotes
    **************************************************************************************************************/
    public static void opportunityQuoteValidation(Set<id> optyIds, Map<Id, Opportunity> newItems) {
        try{
            if(OpportunityTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            for(Opportunity oppty : [select id,Primary_Product_Line__c,Billing_Country__c,
                                     (select id, SBQQ__Opportunity2__c from sbqq__quotes2__r LIMIT 1)
                                     from Opportunity where id IN: optyIds]) {
              if (!oppty.sbqq__Quotes2__r.isEmpty()){
                        newItems.get(oppty.Id).addError(System.Label.QTB_quote_validation_on_oppty);
                } 
          }
        }
		catch (Exception e) {
    QTB_ExceptionLogger.createLog(
      e.getLineNumber(),
      e.getStackTraceString(),
      e.getMessage(),
      e.getTypeName(),
      CLASSNAME
    );
    throw e;
  }
	}
/***********************************************************************************************************
 * Method        : populateOriginalQuote
 * Parameters    : Set<Id> , List<Opportunity>
 * Return Type   : void
 * Requirement   : JIRA# SFCPQBLG-49, SFCPQBLG-386, SFCPQBLG-398
 * Start Date    : 6/03/2020
 * Description   : This method updates Orginal Opportunity details on Amend & Renewal opportunity.
 * Event         : This method is invoked on before update/insert of Opportunity object
 **************************************************************************************************************/
public static void populateOriginalQuote(
  Set<Id> allContractIdSet,
  List<Opportunity> newOpportunityList
) {
  try {
    if (OpportunityTriggerHandler.throwExplicitException) {
      throw new NullPointerException();
    }
    Map<Id, Id> contractwithOriginalQuoteMap = new Map<Id, Id>();
    for (Contract temp : [
      SELECT
        Id,
        Name,
        SBQQ__Opportunity__c,
        sbqq__quote__c,
        SBQQ__Opportunity__r.QTB_Original_Quote__c
      FROM Contract
      WHERE
        Id IN :allContractIdSet
        AND RecordTypeId = :QTB_Utils.CONTRACT_SALES_RECTYPEID
        AND SBQQ__Opportunity__c != NULL
    ]) {
      contractwithOriginalQuoteMap.put(
        temp.Id,
        temp.SBQQ__Opportunity__r.QTB_Original_Quote__c != null
          ? temp.SBQQ__Opportunity__r.QTB_Original_Quote__c
          : temp.sbqq__quote__c
      );
    }

    if (contractwithOriginalQuoteMap.size() > 0) {
      for (Opportunity temp : newOpportunityList) {
        if (temp.RecordTypeId == QTB_Utils.OPP_SALES_RECTYPEID) {
          if (
            temp.Type == QTB_Constants.TYPE_RENEWAL &&
            temp.SBQQ__RenewedContract__c != null &&
            contractwithOriginalQuoteMap.containsKey(
              temp.SBQQ__RenewedContract__c
            ) &&
            contractwithOriginalQuoteMap.get(temp.SBQQ__RenewedContract__c) !=
            null
          ) {
            temp.QTB_Original_Quote__c = contractwithOriginalQuoteMap.get(
              temp.SBQQ__RenewedContract__c
            );
          }
        }
        if (temp.RecordTypeId == QTB_Utils.OPP_SALES_RECTYPEID) {
          if (
            (temp.Type == QTB_Constants.OPP_TYPE_RATE_CHANGE ||
            temp.Type == QTB_Constants.OPP_TYPE_UP_SELL) &&
            temp.SBQQ__AmendedContract__c != null &&
            contractwithOriginalQuoteMap.containsKey(
              temp.SBQQ__AmendedContract__c
            ) &&
            contractwithOriginalQuoteMap.get(temp.SBQQ__AmendedContract__c) !=
            null
          ) {
            temp.QTB_Original_Quote__c = contractwithOriginalQuoteMap.get(
              temp.SBQQ__AmendedContract__c
            );
          }
        }
      }
    }
  } catch (Exception e) {
    QTB_ExceptionLogger.createLog(
      e.getLineNumber(),
      e.getStackTraceString(),
      e.getMessage(),
      e.getTypeName(),
      CLASSNAME
    );
    throw e;
  }
}
}
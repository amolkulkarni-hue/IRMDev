/********************************************************************************************************************************
* Class: QTB_QuoteHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to Quote object
* Requirement: SFCPQBLG-50,SFCPQBLG-10,SFCPQBLG-14,SFCPQBLG-163,ALM-467
* Change History: 5/29/2020
* Developer     Date            Description
* -------------------------------------------------------------------------------------------
*               3/16/2020
* Accenture     7/16/2020       updated to throw exception back to the user after logging
* Accenture    10/23/2020    fixed user not able to approve issue
* Accenture    03/03/2021    GitLab # 1369 - Fixed batch calling future method
* TCS          20/04/2023    GitLab # 14932 - Changes to optimize recurring SOQL query to avoid 101 SOQL Exception in Test class
* Virtusa      05/15/2023    GitLab #12300 - Update Late Fee from Amend/Renewal/API Uplift to Billing Account
**********************************************************************************************************************************/
public without sharing class QTB_QuoteHelper {
    public static final string CLASSNAME = 'QTB_QuoteHelper';
    public static final string PRICE_QUOTE = QTB_Constants.DRAFT_PRICE;
    public static List<String> fieldList = new List<String>();
    public static List<String> deltaFieldList = new List<String>();
    public static List<String> restrictAcceptedQteList = new List<String>();
    public static boolean skipFromBOBBulkApprovals = true;
    static {
        QTB_Quote_Field_Validations__c custSetting = QTB_Quote_Field_Validations__c.getAll()
            .Values();
        fieldList = custSetting.QTB_Field_List__c.split(',');
        deltaFieldList = custSetting.QTB_Delta_Fields__c.split(',');
        restrictAcceptedQteList = custSetting.QTB_Restrict_on_Accepted_Quote__c.split(
            ','
        );
    }
    
    /******************************************************************************************************************************
* Method :      process
* Parameters:   List<SBQQ__Quote__c>,Map<Id, SBQQ__Quote__c>,System.TriggerOperation
* Return Type : void
* Description:  This method loops over the list of records to be processed
* Change History: 04/20/2023
* Developer     Date            Description
* -------------------------------------------------------------------------------------------
* TCS           20/04/2023      GitLab # 14932 - Changes to optimize recurring SOQL query to avoid 101 SOQL Exception in Test class
************************************************************************************************************************************/
    public static void process(
        List<SBQQ__Quote__c> newItems,
        Map<Id, SBQQ__Quote__c> oldItems,
        System.TriggerOperation operationType
    ){
        //Changes to optimize the recurrsive SOQL query consumption
        ID draftQuoteTemplateId = ID.valueOf(System.Label.QTB_Draft_PriceQuote_TemplateId);
        
        //Map of Quote Id to List of Wrapper Object
        Map<ID, List<QTB_OpportunityTeamHelper.shareObjectData>> quoteIdToshareObjectDataListMap = new Map<ID, List<QTB_OpportunityTeamHelper.shareObjectData>>();
        //storage
        Set<Id> listOfOppIdOnAmendmentQuote = new Set<Id>();
        List<QTB_Utils.Mapping> amendmentMappings = new List<QTB_Utils.Mapping>();
        Set<Id> listOfOppIdOnRenewalQuote = new Set<Id>();
        List<QTB_Utils.Mapping> renewalMappings = new List<QTB_Utils.Mapping>();
        Map<Id, id> conmapAmend = new Map<Id, id>();
        List<Id> accId = new List<Id>();
        Map<Id, id> conmapRenew = new Map<Id, id>();
        List<SBQQ__Quote__c> amend = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> renew = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> deltaNewList = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> toAcceptQuoteList = new List<SBQQ__Quote__c>();
        Map<ID, List<ID>> oppIDToQuoteIDListMap = new Map<ID, List<ID>>();
        Set<Id> renewAmendQuoteIdSet = new Set<Id>();
        Map<Id, Id> originalToRenewalAmendMap = new Map<Id, Id>();
        Map<Id, Id> originalToAmendMap = new Map<Id, Id>();
        Set<Id> amendQuoteIdSet = new Set<Id>();
        List<Contract> contractToBeUpdated = new List<Contract>();

        
        List<SBQQ__Quote__c> draftQuoteList = new List<SBQQ__Quote__c>(); //ALM-456
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        String countryLOb;
        // created as part of SFCPQBLG - 1035
        Map<Id, Decimal> mapOfOpportunityMinimumStorageCharge = new Map<Id, Decimal>();
        List<Id> listOfQuoteIdsOnProductServices = new List<Id>();
        List<QTB_Country_Threshold__c> discountSetting = QTB_Country_Threshold__c.getAll()
            .values();
        Map<string, decimal> settingMap = new Map<string, decimal>();
        for (QTB_Country_Threshold__c eachD : discountSetting) {
            string mapKey =
                string.valueof(eachD.QTB_Country__c).trim() +
                string.valueof(eachD.QTB_Line_of_Business__c).trim();
            settingMap.put(mapKey.toLowerCase(), eachD.QTB_Threshold_Percent__c);
        }
        //process
        
        for (SBQQ__Quote__c eachQuote : newItems) {
            System.debug('eachQuote' +eachQuote);
            switch on operationType {
                when BEFORE_INSERT {
                    if (
                        String.isNotBlank(eachQuote.SBQQ__Opportunity2__c)
                    ) {
                        eachQuote.recordtypeId = QTB_Utils.QUOTE_SALES_RECTYPEID;
                        if (eachQuote.SBQQ__Type__c == QTB_Constants.TYPE_AMENDMENT) {
                            listOfOppIdOnAmendmentQuote.add(eachQuote.SBQQ__Opportunity2__c);
                            amendmentMappings.add(
                                new QTB_Utils.Mapping(
                                    eachQuote.SBQQ__Opportunity2__c,
                                    eachQuote
                                )
                            );
                        }
                        if (eachQuote.SBQQ__Type__c == QTB_Constants.TYPE_RENEWAL) {
                            listOfOppIdOnRenewalQuote.add(eachQuote.SBQQ__Opportunity2__c);
                            renewalMappings.add(
                                new QTB_Utils.Mapping(
                                    eachQuote.SBQQ__Opportunity2__c,
                                    eachQuote
                                )
                            );
                        }
                        eachQuote.SBQQ__QuoteTemplateId__c = draftQuoteTemplateId; //Default to Draft/Price Quote
                        eachQuote.SBQQ__WatermarkShown__c = true; //Show Watermark on Draft quote
                    }
                    
                    if (
                        String.isNotBlank(eachQuote.QTB_Opportunity_Billing_Country__c) &&
                        String.isNotBlank(eachQuote.QTB_Opportunity_Product_Line__c)
                    ) {
                        countryLob =
                            string.valueOf(eachQuote.QTB_Opportunity_Billing_Country__c)
                            .trim() +
                            string.valueOf(eachQuote.QTB_Opportunity_Product_Line__c).trim();
                        System.debug('countryLob.toLowerCase()' +countryLob.toLowerCase());
                        if (settingMap.containsKey(countryLob.toLowerCase())) {
                            eachQuote.QTB_Approval_Threshold__c = settingMap.get(
                                countryLob.toLowerCase()
                            );
                            
                        }
                    }
                }
                when AFTER_INSERT {
                    if (eachQuote.SBQQ__Account__c != null) {
                        accId.add(eachQuote.SBQQ__Account__c);
                    }
                    
                    if (eachQuote.SBQQ__Opportunity2__c != null) {
                        System.debug('eachQuote.SBQQ__Opportunity2__c' +eachQuote.SBQQ__Opportunity2__c);
                        if (
                            oppIDToQuoteIDListMap.containsKey(eachQuote.SBQQ__Opportunity2__c)
                        ) {
                            oppIDToQuoteIDListMap.get(eachQuote.SBQQ__Opportunity2__c)
                                .add(eachQuote.id);
                        } else {
                            oppIDToQuoteIDListMap.put(
                                eachQuote.SBQQ__Opportunity2__c,
                                new List<ID>{ eachQuote.id }
                            );
                        }
                    }
                    if (eachQuote.isClone() && eachQuote.getCloneSourceId() != null) {
                        originalToRenewalAmendMap.put(
                            eachQuote.getCloneSourceId(),
                            eachQuote.id
                        );
                        originalToAmendMap.put(eachQuote.getCloneSourceId(), eachQuote.id);
                    }
                    if (
                        eachQuote.SBQQ__Type__c == QTB_Constants.TYPE_RENEWAL ||
                        eachQuote.SBQQ__Type__c == QTB_Constants.TYPE_AMENDMENT
                    ) {
                        renewAmendQuoteIdSet.add(eachQuote.id);
                    }
                    if (eachQuote.SBQQ__Type__c == QTB_Constants.TYPE_AMENDMENT) {
                        amendQuoteIdSet.add(eachQuote.id);
                    }
                    
                    
                    
                }
                when BEFORE_UPDATE {
                    if (
                        (eachQuote.SBQQ__Status__c == QTB_Constants.ACCEPTED_STATUS &&
                         eachQuote.SBQQ__Status__c !=
                         oldItems.get(eachQuote.id).SBQQ__Status__c &&
                         eachQuote.SBQQ__Opportunity2__c != null)
                    ) {
                        toAcceptQuoteList.add(eachQuote);
                        eachQuote.SBQQ__QuoteTemplateId__c = ''; //Remove defaulted price quote option
                        eachQuote.SBQQ__WatermarkShown__c = false; //Hide Watermark on Price Quote/Schedule
                    } else if (
                        eachQuote.SBQQ__Status__c == QTB_Constants.APPROVED_STATUS &&
                        //eachQuote.SBQQ__Status__c != oldItems.get(eachQuote.id).SBQQ__Status__c &&
                        eachQuote.SBQQ__Opportunity2__c != null &&
                        eachQuote.RecordTypeId == QTB_Utils.QUOTE_APPROVED_RECTYPEID
                    ) {
                        //SFCPQBLG-1026
                        quoteList.add(eachQuote);
                        eachQuote.SBQQ__QuoteTemplateId__c = draftQuoteTemplateId; //Default to Price Quote;
                        eachQuote.SBQQ__WatermarkShown__c = false; //Hide Watermark on Price Quote
                    } else if (
                        (eachQuote.SBQQ__Status__c == QTB_Constants.REJECTED_STATUS ||
                         eachQuote.SBQQ__Status__c == QTB_Constants.IN_REVIEW_STATUS ||
                         eachQuote.SBQQ__Status__c == QTB_Constants.QUOTE_EXPIRED_STATUS ||
                         eachQuote.SBQQ__Status__c == QTB_Constants.DENIED_STATUS) &&
                        eachQuote.SBQQ__Status__c !=
                        oldItems.get(eachQuote.id).SBQQ__Status__c &&
                        eachQuote.SBQQ__Opportunity2__c != null
                    ) {
                        eachQuote.SBQQ__QuoteTemplateId__c = draftQuoteTemplateId; //Default to Draft/Price Quote
                        eachQuote.SBQQ__WatermarkShown__c = true; //Show Watermark on Draft quote
                    }
                    
                    //SFCPQBLG-1026
                    if (
                        eachQuote.SBQQ__Status__c == QTB_Constants.ACCEPTED_STATUS &&
                        eachQuote.RecordTypeId == QTB_Utils.QUOTE_APPROVED_RECTYPEID
                    ) {
                        for (String str : restrictAcceptedQteList) {
                            if (oldItems.get(eachQuote.id).get(str) != eachQuote.get(str)) {
                                eachQuote.addError(System.Label.QTB_Accepted_Quote_Message);
                            }
                        }
                    }
                    if (eachQuote.SBQQ__Type__c == QTB_Constants.TYPE_AMENDMENT) {
                        if (eachQuote.SBQQ__EndDate__c != null) {
                            eachQuote.SBQQ__SubscriptionTerm__c = eachQuote.SBQQ__StartDate__c.monthsBetween(
                                eachQuote.SBQQ__EndDate__c
                            );
                            if (
                                eachQuote.SBQQ__EndDate__c.Day() >
                                eachQuote.SBQQ__StartDate__c.Day()
                            )
                                eachQuote.SBQQ__SubscriptionTerm__c++;
                        }
                    }
                    
                }
                when AFTER_UPDATE {
                    if (
                        eachQuote.SBQQ__Primary__c == true &&
                        eachQuote.SBQQ__LastCalculatedOn__c != null &&
                        oldItems.get(eachQuote.id).SBQQ__LastCalculatedOn__c != null &&
                        eachQuote.SBQQ__LastCalculatedOn__c !=
                        oldItems.get(eachQuote.id).SBQQ__LastCalculatedOn__c
                    ) {
                        listOfQuoteIdsOnProductServices.add(eachQuote.Id);
                    }
                    //#Git-1114 Start
                    if (
                        eachQuote.SBQQ__Type__c == QTB_Constants.QUOTE_TYPE_AMEND &&
                        eachQuote.SBQQ__Ordered__c == true &&
                        oldItems.get(eachQuote.Id).SBQQ__Ordered__c != true
                      ) {
                        Contract tempContract = new Contract();
                        tempContract.Id = eachQuote.SBQQ__MasterContract__c;
                        tempContract.QTB_Latest_Opportunity__c = eachQuote.SBQQ__Opportunity2__c;
                        contractToBeUpdated.add(tempContract);
                        }
                    //#Git-1114 End
                    
                }
                when else {
                }
            }
        }
        if(!contractToBeUpdated.isEmpty()){
            popoulateLatestOpportunityOnContract(contractToBeUpdated);
        }
        
        if (listOfOppIdOnAmendmentQuote <> null && !listOfOppIdOnAmendmentQuote.isEmpty()) {
            autoPopulate(
                listOfOppIdOnAmendmentQuote,
                amendmentMappings,
                QTB_Constants.TYPE_AMENDMENT
            );
        }
        if (listOfOppIdOnRenewalQuote <> null && !listOfOppIdOnRenewalQuote.isEmpty()) {
            autoPopulate(
                listOfOppIdOnRenewalQuote,
                renewalMappings,
                QTB_Constants.TYPE_RENEWAL
            );
        }
        if (!oppIDToQuoteIDListMap.isEmpty()) {
            shareQuoteWithOpportunityTeam(oppIDToQuoteIDListMap);
        }
        if (
            !originalToRenewalAmendMap.isEmpty() || !renewAmendQuoteIdSet.isEmpty()
        ) {
            shredProfilesFromOriginalQuote(
                originalToRenewalAmendMap,
                renewAmendQuoteIdSet
            );
        }
        if (!toAcceptQuoteList.isEmpty()) {
            acceptedQuoteValidation(toAcceptQuoteList, oldItems, true);
        }
        if (!quoteList.isEmpty()) {
            validateApprovedQuote(quoteList, oldItems);
            acceptedQuoteValidation(quoteList, oldItems, false);
        }
        if (
            !listOfQuoteIdsOnProductServices.isEmpty() &&
            !system.isBatch() &&
            skipFromBOBBulkApprovals == true
        ) {
            // GitLab # 1369 - Guard against batch or future calling this method
            Set<Quiddity> notAllowedContexts = new Set<Quiddity>{
                Quiddity.BATCH_ACS,
                    Quiddity.BATCH_APEX,
                    Quiddity.BATCH_CHUNK_PARALLEL,
                    Quiddity.BATCH_CHUNK_SERIAL,
                    Quiddity.FUTURE
                    };
                        Quiddity context = System.Request.getCurrent().getQuiddity();
            if (!notAllowedContexts.contains(context)) {
                overrideOpportunityProductUnitPriceFutureHandler(
                    listOfQuoteIdsOnProductServices
                );
            }
            System.debug(context);
        }
        if (!originalToAmendMap.isEmpty() || !amendQuoteIdSet.isEmpty()) {
            amendmentQuotePromotions(originalToAmendMap, amendQuoteIdSet);
        }
    }
    /***********************************************************************************************************
   * Method : popoulateLatestOpportunityOnContract
   * Requirement : Git-1114
   * Start Date : 04/12/2021
   * Author : Accenture
   * Description: Populate Latest Opportunity on contract
   **************************************************************************************************************/
  public static void popoulateLatestOpportunityOnContract(
    List<Contract> contractToBeUpdated
  ) {
    try {
      if (QTB_QuoteHandler.throwExplicitException) 
      {
        throw new NullPointerException();
      }
      SBQQ.TriggerControl.Disable();
      update contractToBeUpdated;
      SBQQ.TriggerControl.Enable();
 
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
* Method :      shareQuoteWithOpportunityTeam
* Parameters:   Map<ID,List<ID>>
* Return Type : void
* Requirement : SFCPQBLG-50
* Description:  This method is used in After insert of Quote Trigger to share quote with Oppty Team with Edit Access
**************************************************************************************************************/
    public static void shareQuoteWithOpportunityTeam(
        Map<ID, List<ID>> oppIDToQuoteIDListMap
    ) {
        Map<ID, List<QTB_OpportunityTeamHelper.shareObjectData>> quoteIdToshareObjectDataListMap = new Map<ID, List<QTB_OpportunityTeamHelper.shareObjectData>>();
        try {
            if (QTB_QuoteHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            //Loop on OTM to construct Map of Quote Id to List of Wrapper Object
            for (OpportunityTeamMember optyTeam : [
                SELECT id, UserId, OpportunityId
                FROM OpportunityTeamMember
                WHERE
                OpportunityId IN :oppIDToQuoteIDListMap.keySet()
                AND OpportunityAccessLevel = :QTB_Constants.OPPTY_ACCESSLEVEL
            ]) {
                QTB_OpportunityTeamHelper.shareObjectData objWrap = new QTB_OpportunityTeamHelper.shareObjectData();
                objWrap.userId = optyTeam.UserId;
                objWrap.isEdit = true;
                for (ID qteId : oppIDToQuoteIDListMap.get(optyTeam.OpportunityId)) {
                    if (quoteIdToshareObjectDataListMap.containskey(qteId)) {
                        quoteIdToshareObjectDataListMap.get(qteId).add(objWrap);
                    } else {
                        quoteIdToshareObjectDataListMap.put(
                            qteId,
                            new List<QTB_OpportunityTeamHelper.shareObjectData>{ objWrap }
                        );
                    }
                }
            }
            //Call generic method from OTM Handler to insert/delete records in Quote share object
            if (!quoteIdToshareObjectDataListMap.isEmpty()) {
                QTB_OpportunityTeamHelper.updateQuoteAccess(
                    quoteIdToshareObjectDataListMap
                );
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
* Method :      resetPriceDeferredRenewalQuote
* Parameters:   Map<ID,SBQQ__Quote__c>
* Return Type : void
* Requirement : SFCPQBLG-10
* Description:  This method is used To update Reset to Original Price when deferred Renewal Oppty is true
**************************************************************************************************************/
    public static void resetPriceDeferredRenewalQuote(
        Map<ID, SBQQ__Quote__c> newMap
    ) {
        List<SBQQ__Quote__c> qteList = new List<SBQQ__Quote__c>();
        try {
            if (QTB_QuoteHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            for (SBQQ__Quote__c qte : [
                SELECT Id
                FROM SBQQ__Quote__c
                WHERE
                SBQQ__Primary__c = TRUE
                AND SBQQ__Type__c = :QTB_Constants.TYPE_RENEWAL
                AND QTB_Reset_to_Original_Prices__c = FALSE
                AND RecordTypeId = :QTB_Utils.QUOTE_SALES_RECTYPEID
                AND SBQQ__Opportunity2__r.QTB_Deferred_Renewal_Opportunity__c = TRUE
                AND Id IN :newMap.keySet()
            ]) {
                SBQQ__Quote__c qteObj = new SBQQ__Quote__c();
                qteObj.Id = qte.Id;
                qteObj.QTB_Reset_to_Original_Prices__c = true;
                qteList.add(qteObj);
            }
            if (!qteList.isEmpty()) {
                update qteList;
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
* Method :      autoPopulate
* Parameters:   Set<Id>,List<QTB_Utils.Mapping,String
* Return Type : void
* Requirement : SFCPQBLG-14
* Description:  This method is used to update the fields on Quote Object
**************************************************************************************************************/
    public static void autoPopulate(
        Set<Id> setOfIds,
        List<QTB_Utils.Mapping> mappings,
        String event
    ) {
        try {
            if (QTB_QuoteHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            QTB_Utils.fieldUpdate(
                setOfIds,
                mappings,
                QTB_Constants.TYPE_OPPORTUNITY,
                QTB_Constants.TYPE_SBQQ_QUOTE,
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
* Method :      shredProfilesFromOriginalQuote
* Parameters:   Map<Id, Id>, Set<Id>
* Return Type : void
* Requirement : SFCPQBLG-163
* Description:  This method is used to clone shred profile related list from original quote to new quote
**************************************************************************************************************/
    public static void shredProfilesFromOriginalQuote(
        Map<Id, Id> originalToRenewalAmendMap,
        Set<Id> renewAmendQuoteIdSet
    ) {
        try {
            if (QTB_QuoteHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            List<QTB_Shred_Profile__c> shredList = new List<QTB_Shred_Profile__c>();
            
            if (
                originalToRenewalAmendMap != null &&
                renewAmendQuoteIdSet != null &&
                renewAmendQuoteIdSet.size() > 0 &&
                Schema.sObjectType.SBQQ__Quote__c.isAccessible() &&
                Schema.sObjectType.Contract.isAccessible()
            ) {
                for (SBQQ__Quote__c quote : [
                    SELECT
                    Id,
                    sbqq__type__c,
                    SBQQ__MasterContract__r.sbqq__quote__c,
                    SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c
                    FROM SBQQ__Quote__c
                    WHERE Id IN :renewAmendQuoteIdSet
                ]) {
                    // preparing map for renewal and amendement quote - original quote
                    if (
                        quote.SBQQ__Type__c == QTB_Constants.TYPE_RENEWAL &&
                        quote.SBQQ__Opportunity2__c != null &&
                        quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c != null &&
                        quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__c !=
                        null
                    ) {
                        originalToRenewalAmendMap.put(
                            quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__c,
                            quote.id
                        );
                    } else if (
                        quote.SBQQ__Type__c == QTB_Constants.TYPE_AMENDMENT &&
                        quote.SBQQ__MasterContract__c != null &&
                        quote.SBQQ__MasterContract__r.sbqq__quote__c != null
                    ) {
                        originalToRenewalAmendMap.put(
                            quote.SBQQ__MasterContract__r.sbqq__quote__c,
                            quote.id
                        );
                    }
                }
            }
            
            if (
                originalToRenewalAmendMap != null &&
                !originalToRenewalAmendMap.IsEmpty()
            ) {
                //shred records from original quotes
                for (QTB_Shred_Profile__c s : [
                    SELECT
                    id,
                    name,
                    QTB_Expected_Annual_Revenue__c,
                    QTB_Average_Distance_to_Depot__c,
                    QTB_Quote__c,
                    QTB_Number_of_Bins_Per_Stop__c,
                    QTB_Primary_Market__c,
                    CurrencyIsoCode
                    FROM QTB_Shred_Profile__c
                    WHERE QTB_Quote__c IN :originalToRenewalAmendMap.keyset()
                ]) {
                    if (originalToRenewalAmendMap.containsKey(s.QTB_Quote__c)) {
                        //shred records for new quotes
                        QTB_Shred_Profile__c s1 = new QTB_Shred_Profile__c();
                        s1 = s.clone();
                        s1.qtb_quote__c = originalToRenewalAmendMap.get(s.QTB_Quote__c);
                        shredList.add(s1);
                    }
                }
            }
            if (!shredList.IsEmpty()) {
                insert shredList;
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
* Method :      amendmentQuotePromotions
* Parameters:   Map<Id, Id>, Set<Id>
* Return Type : void
* Requirement : GITLAB-487
* Description:  This method is used to clone quote promotions related list from original quote to new quote
**************************************************************************************************************/
    public static void amendmentQuotePromotions(
        Map<Id, Id> originalToAmendMap,
        Set<Id> amendmentQuoteIdSet
    ) {
        List<QTB_Quote_Promotion__c> qpromotionList = new List<QTB_Quote_Promotion__c>();
        try {
            if (QTB_QuoteHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            System.debug(' originalToAmendMap' + originalToAmendMap);
            System.debug(' Schema.sObjectType.Contract.isAccessible()'+ Schema.sObjectType.Contract.isAccessible());
            
            if (
                originalToAmendMap != null &&
                amendmentQuoteIdSet != null &&
                amendmentQuoteIdSet.size() > 0 &&
                Schema.sObjectType.SBQQ__Quote__c.isAccessible() &&
                Schema.sObjectType.Contract.isAccessible()
            ) {
                System.debug('amendmentQuoteIdSet' +amendmentQuoteIdSet);
                for (SBQQ__Quote__c quote : [
                    SELECT
                    Id,
                    sbqq__type__c,
                    SBQQ__MasterContract__r.sbqq__quote__c,
                    SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c
                    FROM SBQQ__Quote__c
                    WHERE Id IN :amendmentQuoteIdSet
                ]) {
                    // preparing map for amendement quote - original quote
                    System.debug('QTB_Constants.TYPE_AMENDMENT'+quote.SBQQ__Type__c);
                    System.debug(' quote.SBQQ__MasterContract__c' + quote.SBQQ__MasterContract__c);
                    System.debug('quote.SBQQ__MasterContract__r.sbqq__quote__c' +quote.SBQQ__MasterContract__r.sbqq__quote__c);
                    if (
                        quote.SBQQ__Type__c == QTB_Constants.TYPE_AMENDMENT &&
                        quote.SBQQ__MasterContract__c != null &&
                        quote.SBQQ__MasterContract__r.sbqq__quote__c != null
                    ) {
                        originalToAmendMap.put(
                            quote.SBQQ__MasterContract__r.sbqq__quote__c,
                            quote.id
                        );
                    }
                }
            }
            for (QTB_Quote_Promotion__c QP : [
                SELECT
                id,
                QTB_Quote__c,
                QTB_Promotion_Name__c,
                QTB_Promo_Product__c,
                QTB_Promo_Term__c,
                QTB_Promo_Amount__c,
                QTB_Promo_Percent__c,
                QTB_Promo_Code__c,
                Name,
                QTB_Store_Promotion_Name__c,
                QTB_Promotion_Start_Date__c,
                QTB_Promotion_End_Date__c,
                QTB_Promo_Description__c
                FROM QTB_Quote_Promotion__c
                WHERE QTB_Quote__c IN :originalToAmendMap.keyset()
            ]) {
                
                if (originalToAmendMap.containsKey(QP.QTB_Quote__c)) {
                    //Quote promotions for new quotes
                    QTB_Quote_Promotion__c QP1 = new QTB_Quote_Promotion__c();
                    QP1 = QP.clone();
                    QP1.qtb_quote__c = originalToAmendMap.get(QP.QTB_Quote__c);
                    qpromotionList.add(QP1);
                }
            }
            if (!qpromotionList.isEmpty()) {
                insert qpromotionList;
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
* Method :      acceptedQuoteValidation
* Parameters:   List<SBQQ__Quote__c>
* Return Type : void
* Requirement : ALM-467
* Description:  This method is used for validation of having only 1 accepted quote and set it as primary
**************************************************************************************************************/
    public static void acceptedQuoteValidation(List<SBQQ__Quote__c> toAcceptQuoteList,Map<Id, SBQQ__Quote__c> oldItems,Boolean isAccepted ) {
        try {
            if (QTB_QuoteHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Map<ID, SBQQ__Quote__c> acceptedQuoteMap = new Map<ID, SBQQ__Quote__c>(
                [
                    SELECT
                    Id,
                    SBQQ__Primary__c,
                    SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c,
                    SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__r.SBQQ__Status__c
                    FROM SBQQ__Quote__c
                    WHERE Id IN :toAcceptQuoteList
                ]
            );
            if (!acceptedQuoteMap.isEmpty()) {
                for (SBQQ__Quote__c qte : toAcceptQuoteList) {
                    if (isAccepted) {
                        if (acceptedQuoteMap.get(qte.id).SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c == null ||
                            (qte.id !=acceptedQuoteMap.get(qte.id).SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c &&
                             acceptedQuoteMap.get(qte.id).SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__r.SBQQ__Status__c != QTB_Constants.ACCEPTED_STATUS)
                           ) {
                               qte.SBQQ__Primary__c = true;
                           } else if (qte.id != acceptedQuoteMap.get(qte.id).SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c) 
                           {
                               qte.addError(label.QTB_AcceptedQuoteValidation);
                           }
                        // Start of GIT-1114
                        if(!String.isEmpty(qte.QTB_Opportunity_Product_Line__c) && qte.QTB_Opportunity_Product_Line__c.containsIgnoreCase('Special Projects'))
                        {
                            qte.QTB_OrderCategory__c =QTB_Constants.ORDCATEGORY_SPECIALPROJECTS;
                            
                        }
                        else if( !String.isEmpty(qte.QTB_Opportunity_Product_Line__c) && qte.QTB_Opportunity_Product_Line__c.containsIgnoreCase('Shred') 
                                && qte.QTB_NoOfOneTimeQL__c == qte.SBQQ__LineItemCount__c)
                        {
                            qte.QTB_OrderCategory__c =QTB_Constants.ORDCATEGORY_ONETIMESHRED;
                        }
                        else if (!String.isEmpty(qte.QTB_Customer_Care_Quote_Type__c) && qte.QTB_Customer_Care_Quote_Type__c.containsIgnoreCase('Retention'))
                        {
                            qte.QTB_OrderCategory__c =QTB_Constants.ORDCATEGORY_RETENTION;
                        }
                        else if (!String.isEmpty(qte.QTB_Customer_Care_Quote_Type__c) && qte.QTB_Customer_Care_Quote_Type__c.containsIgnoreCase('Termination'))
                        {
                            qte.QTB_OrderCategory__c =QTB_Constants.ORDCATEGORY_TERMINATION;
                        }
                        else
                        {
                            qte.QTB_OrderCategory__c =QTB_Constants.ORDCATEGORY_EVERGREEN;
                        }
                        //End of GIT-1114
                    } else if (acceptedQuoteMap.get(qte.id).SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__r.SBQQ__Status__c ==
                               QTB_Constants.ACCEPTED_STATUS && qte.SBQQ__Primary__c != oldItems.get(qte.Id).SBQQ__Primary__c)
                    {
                        qte.addError(label.QTB_AcceptedQuoteValidation);
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
    
    /***********************************************************************************************************
* Method :      validateApprovedQuote
* Parameters:   List<SBQQ__Quote__c>,Map<Id,SBQQ__Quote__c>
* Return Type : void
* Requirement : ALM-537/SFCPQBLG-1026
* Description:  This method is used for validation of Date fields on Approved Quote
**************************************************************************************************************/
    public static void validateApprovedQuote(
        List<SBQQ__Quote__c> quoteList,
        Map<Id, SBQQ__Quote__c> oldItems
    ) {
        String type = QTB_Constants.SOBJECT_QUOTE;
        String dateFields = '';
        String mindatefield = '';
        String blankfield = '';
        String blankoutfield = '';
        String finalerrormessage = '';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType quoteSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = quoteSchema.getDescribe()
            .fields.getMap();
        List<Profile> PROFILE = [
            SELECT Id, Name
            FROM Profile
            WHERE Id = :userinfo.getProfileId()
            LIMIT 1
        ];
        String profileName = PROFILE[0].Name;
        List<String> profileLabels = System.Label.QTB_profile_labels.Split(',');
        boolean isValid_profile = true;
        if (!profileLabels.contains(profileName)) {
            isValid_profile = false;
        }
        
        for (SBQQ__Quote__c eachQuote : quoteList) {
            System.debug('eachQuote' +eachQuote);
            System.debug('isValid_profile' +isValid_profile);
            System.debug('eachQuote.SBQQ__Status__c' +eachQuote.SBQQ__Status__c);
            if (
                isValid_profile == false &&
                eachQuote.SBQQ__Status__c == oldItems.get(eachQuote.id).SBQQ__Status__c
            ) {
                eachQuote.addError(System.Label.QTB_Profile_Error);
            } else {
                //Allow user to update start date within 90 days
                if (
                    eachQuote.SBQQ__StartDate__c !=
                    oldItems.get(eachQuote.id).SBQQ__StartDate__c &&
                    (oldItems.get(eachQuote.id).SBQQ__StartDate__c)
                    .daysBetween(eachQuote.SBQQ__StartDate__c) >
                    Integer.ValueOf(System.Label.QTB_Duration_of_Quote_Start_Date)
                ) {
                    eachQuote.addError(
                        System.Label.QTB_Quote_Start_Date_Duration_Message +
                        ' ' +
                        System.Label.QTB_Duration_of_Quote_Start_Date +
                        ' ' +
                        System.Label.QTB_Quote_Start_Date_Duration_End_Message
                    );
                }
                Integer i = 0;
                if (!fieldList.isEmpty()) {
                    for (String str : fieldList) {
                        //To store the original delta values from start date
                        if (
                            eachQuote.get(str) != null &&
                            eachQuote.SBQQ__StartDate__c != null &&
                            eachQuote.SBQQ__Status__c !=
                            oldItems.get(eachQuote.id).SBQQ__Status__c
                        ) {
                            eachQuote.put(
                                deltaFieldList[i],
                                eachQuote.SBQQ__StartDate__c.daysBetween(
                                    (Date) eachQuote.get(str)
                                )
                            );
                        }
                        
                        if (
                            eachQuote.get(str) != oldItems.get(eachQuote.id).get(str) ||
                            eachQuote.SBQQ__StartDate__c !=
                            oldItems.get(eachQuote.Id).SBQQ__StartDate__c
                        ) {
                            if (
                                oldItems.get(eachQuote.id).get(str) == null &&
                                eachQuote.get(str) != null
                            ) {
                                blankfield =
                                    blankfield +
                                    fieldMap.get(str).getDescribe().getLabel() +
                                    ',';
                            }
                            if (
                                oldItems.get(eachQuote.id).get(str) != null &&
                                eachQuote.get(str) == null
                            ) {
                                blankoutfield =
                                    blankoutfield +
                                    fieldMap.get(str).getDescribe().getLabel() +
                                    ',';
                            }
                            
                            if (
                                eachQuote.get(deltaFieldList[i]) != null &&
                                eachQuote.get(str) != null &&
                                oldItems.get(eachQuote.id).get(str) != null &&
                                eachQuote.SBQQ__StartDate__c.daysBetween(
                                    (Date) eachQuote.get(str)
                                ) > Integer.ValueOf(eachQuote.get(deltaFieldList[i]))
                            ) {
                                dateFields =
                                    dateFields +
                                    fieldMap.get(str).getDescribe().getLabel() +
                                    ',';
                            }
                        }
                        i++;
                    }
                    
                    if (dateFields != '') {
                        dateFields = dateFields.removeEnd(',');
                        finalerrormessage +=
                            dateFields +
                            ' ' +
                            System.Label.QTB_Delta_Difference_Message +
                            '\r\n';
                    }
                    
                    if (blankfield != '') {
                        blankfield = blankfield.removeEnd(',');
                        finalerrormessage +=
                            blankfield +
                            ' ' +
                            System.Label.QTB_Blank_Field_Message +
                            '\r\n';
                    }
                    if (blankoutfield != '') {
                        blankoutfield = blankoutfield.removeEnd(',');
                        finalerrormessage +=
                            blankoutfield +
                            ' ' +
                            System.Label.QTB_BlankOut_Field_Message +
                            '\r\n';
                    }
                    
                    if (finalerrormessage != '') {
                        finalerrormessage = finalerrormessage.removeEnd(',');
                        eachQuote.addError(finalerrormessage);
                    }
                }
            }
        }
    }
    @future
    public static void overrideOpportunityProductUnitPriceFutureHandler(
        List<Id> listOfQuoteIds
    ) {
        List<OpportunityLineItem> listOfLinesToUpdate = new List<OpportunityLineItem>();
        for (List<OpportunityLineItem> chunk : [
            SELECT
            Id,
            UnitPrice,
            SBQQ__QuoteLine__r.SBQQ__ProductCode__c,
            SBQQ__QuoteLine__r.QTB_Display_in_Price_Schedule__c,
            SBQQ__QuoteLine__r.QTB_Forecastable_Lines__c,
            SBQQ__QuoteLine__r.QTB_Annual_Forecastable_Value__c,
            SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c,
            SBQQ__QuoteLine__r.SBQQ__Quote__r.QTB_PendingMinimumStorageCharge__c
            FROM OpportunityLineItem
            WHERE SBQQ__QuoteLine__r.SBQQ__Quote__c IN :listOfQuoteIds
            FOR UPDATE
        ]) {
            system.debug('3-->' + chunk.size());
            for (OpportunityLineItem eachLineItem : chunk) {
                // if not minimum storage charges product, override unit price to annual forecastable value per unit
                System.debug('eachLineItem.SBQQ__QuoteLine__r.SBQQ__ProductCode__c' +eachLineItem.SBQQ__QuoteLine__r.SBQQ__ProductCode__c);
                if (
                    eachLineItem.SBQQ__QuoteLine__r.SBQQ__ProductCode__c <>
                    Label.QTB_Minimum_Storage &&
                    eachLineItem.SBQQ__QuoteLine__r.QTB_Annual_Forecastable_Value__c <>
                    null &&
                    eachLineItem.SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c <> null
                ) {
                    eachLineItem.UnitPrice = (eachLineItem.SBQQ__QuoteLine__r.QTB_Annual_Forecastable_Value__c ==
                                              0 ||
                                              eachLineItem.SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c == 0 ||
                                              !eachLineItem.SBQQ__QuoteLine__r.QTB_Display_in_Price_Schedule__c ||
                                              !eachLineItem.SBQQ__QuoteLine__r.QTB_Forecastable_Lines__c)
                        ? 0
                        : eachLineItem.SBQQ__QuoteLine__r.QTB_Annual_Forecastable_Value__c /
                            eachLineItem.SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c;
                } else /* else override unit price by pending minimum storage charges to make up */ {
                    eachLineItem.UnitPrice = eachLineItem.SBQQ__QuoteLine__r.SBQQ__Quote__r.QTB_PendingMinimumStorageCharge__c;
                }
                System.debug(
                    System.LoggingLevel.INFO,
                    '### Price Overriden for ###' +
                    eachLineItem.SBQQ__QuoteLine__r.SBQQ__ProductCode__c
                );
            }
            listOfLinesToUpdate.addAll(chunk);
        }
        System.debug('listOfLinesToUpdate.isEmpty()'+listOfLinesToUpdate.isEmpty());
        if (!listOfLinesToUpdate.isEmpty()) {
            try {
                SBQQ.TriggerControl.disable();
                update listOfLinesToUpdate;
                SBQQ.TriggerControl.enable();
            } catch (System.DmlException e) {
                throw e;
            } catch (Exception e) {
                throw e;
            }
        }
    }
}
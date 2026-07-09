/*****************************************************************************************************
 * Class: QTB_PurchaseOrderHelper
 * Author: Accenture
 * Purpose: This is a helper class for all business logic related to Purchase Order object
 * Requirement: sFCPQBLG-519
 * Change History: 10-06-2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *             10-06-2020
 * Virtusa     06/09/2022       Gitlab #9110 - Duplicate Purchase Orders (Start and End Date are overlapping)
 * Virtusa     06/12/2022       Gitlab #9089 - Added Country check,For Eligible Countries --> recalculating PO
 * Divya B     13/12/2022       Gitlab #12087 - Added storeSentEmailAlertsOnInsert and storeSentEmailAlertsOnUpdate --> To update the TypeOfNotificationSent field with the sent alerts fields names.
 * Parth		  16/05/2024	   Gitlab #22654 - bypassing validation error to create PO with different service type with overlapping dates and validate that new PO with service type services or
storage can only be created if billing account split invoice flag is true
     * Virtusa     02-12-2024       Gitlab #26901 - Added new method validatePostedInvoicesOrCredits to restirct user from updating PO if PO is associated with posted invoice or creditnote and Added logic in before insert or before update user is restricted from adding value less than or equal to 0 on Amount field

 *******************************************************************************************************/
public with sharing class QTB_PurchaseOrderHelper {
    
    public static final string PURCHASEORDER_HELPER='QTB_PurchaseOrderHelper';
    public static final String STATUS_POSTED = QTB_Constants.INVOICE_STATUS_POSTED; //PO num
    public static final String STATUS_DRAFT = QTB_Constants.INVOICE_STATUS_DRAFT;//Added for story #26900
    /***********************************************************************************************************
     * Method : trigController
     * Parameters: List<Order>, Map<Id,Order>,System.TriggerOperation
     * Requirement :
     * Start Date :
     * Author : Accenture
     * Description: Generic method to handle all operations on the Order Records
     **************************************************************************************************************/
    public static void trigController(List<QTB_PurchaseOrder__c> ordNewList,Map<Id,QTB_PurchaseOrder__c>ordOldMap,
    System.TriggerOperation operationType)
        
    {
        // Calling custom Setting for Deactivating Validation Rule
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        //Collect Purchase Order IDs
        // Gitlab #32158 starts
        Set<Id> purchaseOrderNewIdSet = new Set<Id>();
        for (QTB_PurchaseOrder__c po : ordNewList) {
            purchaseOrderNewIdSet.add(po.Id);
        }
        Map<Id, QTB_PurchaseOrder__c> purchaseOrderNewMap = new Map<Id, QTB_PurchaseOrder__c>();
        if (!purchaseOrderNewIdSet.isEmpty()){
            purchaseOrderNewMap = new Map<Id, QTB_PurchaseOrder__c>( [SELECT Id, QTB_Legal_Entity_Country__c,QTB_Service_Type__c
                                                                        FROM QTB_PurchaseOrder__c
                                                                        WHERE Id IN :purchaseOrderNewIdSet WITH SYSTEM_MODE]);
        }
        //Bulk aggregate query for counts
        Map<Id, Integer> purchaseOrderAccountCountMap = new Map<Id, Integer>();
        if (!purchaseOrderNewIdSet.isEmpty()) {
            AggregateResult[] aggregateResults = [ SELECT QTB_Purchase_Order__c purchaseOrderId, COUNT(Id) counted
                                            FROM QTB_PurchaseOrderAccount__c
                                            WHERE QTB_Purchase_Order__c IN :purchaseOrderNewIdSet WITH SYSTEM_MODE
                                            GROUP BY QTB_Purchase_Order__c ];
            for (AggregateResult ar : aggregateResults) {
                Id purchaseOrderId = (Id) ar.get('purchaseOrderId');
                Integer count = (Integer) ar.get('counted');
                purchaseOrderAccountCountMap.put(purchaseOrderId, count);
            }
        }
        //Check Account with split flag checked
        // GITLAB - #32158
        Map<Id, QTB_PurchaseOrderAccount__c> purchaseOrderToAccountMap = new Map<Id, QTB_PurchaseOrderAccount__c>();
        
        if (!purchaseOrderNewIdSet.isEmpty()) {
            List<QTB_PurchaseOrderAccount__c> poAccountList = [SELECT Id, QTB_Account__c, QTB_Purchase_Order__c 
                                                                FROM QTB_PurchaseOrderAccount__c 
                                                                WHERE QTB_Purchase_Order__c IN :purchaseOrderNewIdSet AND QTB_Account__r.QTB_Split_Invoice_Flag__c = false WITH SYSTEM_MODE];
            for (QTB_PurchaseOrderAccount__c poAcc : poAccountList) {
                purchaseOrderToAccountMap.put(poAcc.QTB_Purchase_Order__c, poAcc);
            }
        }
        // Gitlab #32158 ends
        for(QTB_PurchaseOrder__c po :ordNewList){
            SWITCH ON operationType{
                WHEN BEFORE_INSERT{
                    if(po.QTB_Amount__c != null && po.QTB_Amount__c <= 0 ) // Gitlab 26901
                    {
                        po.addError(System.label.QTB_ValidatingPOAmountNegative);
                    }
                    if(po.QTB_Legal_Entity_Country__c != 'Hong Kong') // Gitlab 33801
                    {
                        validateStraitsPO(new List<QTB_PurchaseOrder__c>{ po });
                    }
                    /// Gitlab #22654- validate that new PO with service type services or storage can only be created if billing account split invoice flag is true
                    // MOVING The below logic to POA
                    /*  if((po.QTB_Split_Invoice_Flag__c == false) &&  (po.QTB_Service_Type__c == 'Storage' || po.QTB_Service_Type__c == 'Service')){
                        po.addError('Cannot create '+po.QTB_Service_Type__c+' type PO as billing account Spit invoice flag is unchecked');
                    } */
                }
                WHEN BEFORE_UPDATE{
                    if(po.QTB_Amount__c != null && po.QTB_Amount__c <= 0 ) // Gitlab 26901
                    {
                        po.addError(System.label.QTB_ValidatingPOAmountNegative);
                    }
                    // Gitlab #22654- validate that new PO with service type services or storage can only be created if billing account split invoice flag is true
                    // MOVING The below logic to POA
                    /*   if(po.QTB_Service_Type__c != ordOldMap.get(po.Id).QTB_Service_Type__c &&
                    ((po.QTB_Split_Invoice_Flag__c == false) && (po.QTB_Service_Type__c == 'Storage' || po.QTB_Service_Type__c == 'Service'))){
                        po.addError('Cannot create '+po.QTB_Service_Type__c+' type PO as billing account Spit invoice flag is unchecked');
                    } */
                    
                    // GITLAB - #31878 - Check if Legal Entity Country changed compared to old record and whether the PO has related POA records
                    //// upgraded during 32158
                    if (ordOldMap.get(po.Id).QTB_Legal_Entity_Country__c != po.QTB_Legal_Entity_Country__c) {
                        if(po.QTB_Legal_Entity_Country__c != 'Hong Kong') // Gitlab 33801
                        {
                            validateStraitsPO(new List<QTB_PurchaseOrder__c>{ po });
                        }
                        // Use pre-calculated count map (0 if not present)
                        Integer relatedPOACount = purchaseOrderAccountCountMap.containsKey(po.Id) ? purchaseOrderAccountCountMap.get(po.Id) : 0;
                        if (relatedPOACount > 0) {
                            po.addError(System.label.QTB_POValidationOnLegalEntityChange);
                        }
                    }
                    //GITLAB - #32158 - Check if user attempts to update the service type from Mixed to Service/Storage at PO level associated accounts have the split invoice flag set to False and whether the PO has related POA records
                    if ((ordOldMap.get(po.Id).QTB_Service_Type__c == 'Mixed')
                        && (po.QTB_Service_Type__c == 'Service' || po.QTB_Service_Type__c == 'Storage')
                    && (purchaseOrderToAccountMap.containsKey(po.ID))) {
                        
                        po.addError(System.label.QTB_POValidationOnServiceTypeChange);
                    }
                    //GITLAB - #32158 ends
                    // Filter only those Purchase Orders where Start or End date changed
                    List<QTB_PurchaseOrder__c> poDateChangedList = new List<QTB_PurchaseOrder__c>();
                    for(QTB_PurchaseOrder__c pOrder : ordNewList){
                        QTB_PurchaseOrder__c oldPo = ordOldMap.get(pOrder.Id);
                        if(oldPo != null &&
                        (pOrder.QTB_Start_Date__c != oldPo.QTB_Start_Date__c || pOrder.QTB_End_Date__c != oldPo.QTB_End_Date__c)){
                            poDateChangedList.add(pOrder);
                        }
                    }
                    if(!poDateChangedList.isEmpty()) {
                        // Call your existing overlap validation method here
                        // validatePurchaseOrderDateOverlap(poDateChangedList);
                    }
                    
                }
            }
        }
        SWITCH ON operationType {
            WHEN BEFORE_INSERT {
                if(!ordNewList.isEmpty()) {
                    /* commenting the below methods. As per new design there won't be Billing Account reference at purchase order level to
                    fetch legal entity country and PO contact for validation check.*/
                        //   countryClone(ordNewList); Moving to POA
                    //    isPoContactPresent(ordNewList); Moving to POA
                    /*      if(QTB_RecursiveHandlerCheck.afterUpdateCheck)
                    {   Moving to POA
                        QTB_RecursiveHandlerCheck.afterUpdateCheck=false;
                        duplicatetimeperiod(ordNewList);
                    } */
                    
                    //It is required to send email alert as part of new design based on utilized amount
                    storeSentEmailAlertsOnInsert(ordNewList);
                    calculatingPOBalanceAmount(ordNewList); // This method is required to calculate PO balance as part of new design
                }
                
            }
            
            WHEN BEFORE_UPDATE {
                if(!ordNewList.isEmpty()) {
                    //  isPoContactPresent(ordNewList);
                    //    duplicateUpdateTimePeriod(ordNewList,ordOldMap);
                    storeSentEmailAlertsOnUpdate(ordNewList,ordOldMap);
                    reCalculatePOBalance(ordNewList, ordOldMap, false);
                    poAmountChange(ordNewList,ordOldMap);
                    // Account reference is moved to PO junction object the validation will be handled by taking reference from
                    // junction object
                    validatePostedInvoicesOrCredits(ordNewList,ordOldMap);
                }
                
            }
            WHEN AFTER_UPDATE {
                if(!ordNewList.isEmpty()) {
                    //Logic to check if the Purchase Order balance needs to re-calculated
                    //  reCalculatePOBalance(ordNewList, ordOldMap, false);
                    
                }
            }
        }
    }
    
    /***********************************************************************************************************
     * Method : countryClone
     * Parameters: List<QTB_PurchaseOrder__c>
     * Requirement : SFCPQBLG-519
     * Start Date :
     * Author : Accenture
     * Description: To clone legal entity country from the billing account to purchase order object
     **************************************************************************************************************/
    /* public static void countryClone(List<QTB_PurchaseOrder__c> purchaseList){
        try{
            if(QTB_PurchaseOrderTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(purchaseList == NULL) { return; }
            List<Id> billingAccount = new List<Id>();
            for(QTB_PurchaseOrder__c purchase: purchaseList ){
                billingAccount.add(purchase.QTB_Billing_Account__c);
            }
            Map<Id,Account> accountToCountryMap = new Map<Id,Account>([Select id,QTB_Legal_Entity_Country__c 
                                                                       from Account where id in:  billingAccount]);
            for(QTB_PurchaseOrder__c purchase: purchaseList ){
                if(accountToCountryMap.containsKey(purchase.QTB_Billing_Account__c)) {
                    System.debug('##### Setting Legal Entity Country #####');
                    purchase.QTB_Legal_Entity_Country__c = accountToCountryMap.get(purchase.QTB_Billing_Account__c).QTB_Legal_Entity_Country__c;
                    System.debug('##### Legal Entity Country set as : ' + purchase.QTB_Legal_Entity_Country__c + ' #####');
                }
            }
        } catch(Exception e) {
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
            QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
    } */
    
    /******************************************************************************************************************
     * Method : isPoContactPresent
     * Parameters: List<QTB_PurchaseOrder__c> purchaseList
     * Requirement : Gitlab #2959
     * Start Date :
     * Author : TCS
     * Description: To validate if the billing account tagged in the Purchase order have contact with role as PO Contact
     ********************************************************************************************************************/
    /*   public static void isPoContactPresent(List<QTB_PurchaseOrder__c> purchaseOrderList)
    {
        try{
            if(QTB_PurchaseOrderTriggerHandler.throwExplicitException)
            {
                throw new NullPointerException();
            }
            if(purchaseOrderList == NULL)
            {
                return;
            }
            //Fetch all billing accounts related to the purchase orders and create billing account list
            list<Id> billingAccounts = new list<Id>();
            for(QTB_PurchaseOrder__c po: purchaseOrderList)
            {
                if (po.QTB_Status__c == QTB_Constants.ACTIVE)
                {
                    billingAccounts.add(po.QTB_Billing_Account__c);
                }
            }
            
            //Fetching all the AccountContactRelation records for the eligible billing accounts
            list<AccountContactRelation> acntCntRlns = [Select id,Roles,Accountid,Contactid,QTB_Primary__c
                                                        from AccountContactRelation Where Accountid in: billingAccounts];
            Map<ID, list<ID>> billingAcntPoCntMap = new Map<ID, list<String>>();
            for(AccountContactRelation antCnt :acntCntRlns)
            {
                //Logic to check whether PO Contact is associated with the Billing Account
                
                if (antCnt.Roles <> null && String.valueOf(antCnt.Roles).contains('PO Contact')) {
                    if (billingAcntPoCntMap.get(antCnt.Accountid) != null) {
                        list<ID> contactIds = billingAcntPoCntMap.get(antCnt.Accountid);
                        contactIds.add(antCnt.Contactid);
                        billingAcntPoCntMap.put(antCnt.Accountid, contactIds);
                    } else {
                        billingAcntPoCntMap.put(antCnt.Accountid, new list<ID>{antCnt.Contactid});
                    }
                }
            }
            for(QTB_PurchaseOrder__c po: purchaseOrderList)
            {
                //Logic to stop saving the Purchase order if the associated Billing Account doesn't have PO Contact
                if(billingAcntPoCntMap.get(po.QTB_Billing_Account__c) == null && po.QTB_Status__c == QTB_Constants.ACTIVE)
                {
                    
                    po.addError(system.label.QTB_PurchaseOrder_Error);
                }
            }
        }
        catch(Exception e)
        {
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
            QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
    } */
    
    /******************************************************************************************************************
     * Method : duplicatetimeperiod
     * Parameters: List<QTB_PurchaseOrder__c> purchaseList
     * Requirement : Gitlab #3773
     * Start Date :
     * Author : TCS - Ramesh Aravind
     * Description: To validate the new purchase order record with the same billing account has the already existing time period
    Gitlab #22654 - bypassing validation error to create PO with different service type with overlapping dates
         ********************************************************************************************************************/
    /*  public static void duplicatetimeperiod(List<QTB_PurchaseOrder__c> purchaseOrderList)
    {
        try{
            if(QTB_PurchaseOrderTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(purchaseOrderList == NULL){
                return;
            }
            list<Id> billingAccounts = new list<Id>();
            Map<id,List<QTB_PurchaseOrder__c>> AccountIdNewPOMap = new Map<id,List<QTB_PurchaseOrder__c>>();
            //Get all the PO Newly Inserted wrt Account Id
            for(QTB_PurchaseOrder__c po: purchaseOrderList){
                //Check Active PO
                if (po.QTB_Status__c == QTB_Constants.ACTIVE){
                    billingAccounts.add(po.QTB_Billing_Account__c);
                }
            }
            system.debug('billingaccount'+billingaccounts);
            
            //Fetch all the purchase order related to the billing account
            list<QTB_PurchaseOrder__c> polist = [Select id,QTB_Service_Type__c,QTB_Billing_Account__c,Name,QTB_Start_Date__c, QTB_End_Date__c,QTB_PO_Type__c from QTB_PurchaseOrder__c where QTB_Billing_Account__c in : billingAccounts and QTB_Status__c =: QTB_Constants.ACTIVE];
            
            Map<id,List<QTB_PurchaseOrder__c>> AccountIdPOMap = new Map<id,List<QTB_PurchaseOrder__c>>();
            //Get all the Existing PO wrt Account Id
            for(QTB_PurchaseOrder__c po : polist){
                if(AccountIdPOMap.containsKey(po.QTB_Billing_Account__c)){
                    AccountIdPOMap.get(po.QTB_Billing_Account__c).add(po);
                }else{
                    AccountIdPOMap.put(po.QTB_Billing_Account__c, new List<QTB_PurchaseOrder__c>{po});
                }
            }
            //Check if the above condition not matching
            for(QTB_PurchaseOrder__c curInsetPO : purchaseOrderList){
                //Check if Any Existing PO is present or not
                if(AccountIdPOMap.containsKey(curInsetPO.QTB_Billing_Account__c)){
                    for(QTB_PurchaseOrder__c d : AccountIdPOMap.get(curInsetPO.QTB_Billing_Account__c)){
                        //Gitlab #22654 -If service type is different then allow to create PO with overlapping dates
                        If((curInsetPO.QTB_Service_Type__c == d.QTB_Service_Type__c && curInsetPO.QTB_PO_Type__c == d.QTB_PO_Type__c)){
                            if((curInsetPO.QTB_Start_Date__c  < d.QTB_Start_Date__c && curInsetPO.QTB_Start_Date__c  < d.QTB_End_Date__c) &&
                                (curInsetPO.QTB_End_Date__c > d.QTB_Start_Date__c && curInsetPO.QTB_End_Date__c < d.QTB_End_Date__c) ||   // Mix
                                // Mix
                            ((curInsetPO.QTB_Start_Date__c  > d.QTB_Start_Date__c && curInsetPO.QTB_Start_Date__c  < d.QTB_End_Date__c) &&
                                (curInsetPO.QTB_End_Date__c > d.QTB_Start_Date__c && curInsetPO.QTB_End_Date__c > d.QTB_End_Date__c)) ||
                                // Inside
                            ((curInsetPO.QTB_Start_Date__c  > d.QTB_Start_Date__c && curInsetPO.QTB_Start_Date__c  < d.QTB_End_Date__c) &&
                                (curInsetPO.QTB_End_Date__c > d.QTB_Start_Date__c && curInsetPO.QTB_End_Date__c < d.QTB_End_Date__c))   ||
                                // Outside
                            ((curInsetPO.QTB_Start_Date__c  < d.QTB_Start_Date__c && curInsetPO.QTB_Start_Date__c  < d.QTB_End_Date__c) &&
                                (curInsetPO.QTB_End_Date__c > d.QTB_Start_Date__c && curInsetPO.QTB_End_Date__c > d.QTB_End_Date__c)) ||
                                // Only Start date Present
                            (curInsetPO.QTB_Start_Date__c > d.QTB_Start_Date__c && CurInsetPO.QTB_Start_Date__c < d.QTB_End_Date__c) ||
                                // Only End date Present
                            (curInsetPO.QTB_End_Date__c > d.QTB_Start_Date__c && curInsetPO.QTB_End_Date__c < d.QTB_End_Date__c))
                                
                            {
                                //Throw Error
                                curInsetPO.adderror(system.label.QTB_PO_Overlapping_TypeValidation+'  for PO Record: '+d.Name);
                                break;
                            }
                            //Allowing  PO With same date range but should have different PO Types or Service Type //23922
                            if((curInsetPO.QTB_PO_Type__c == d.QTB_PO_Type__c && curInsetPO.QTB_Service_Type__c == d.QTB_Service_Type__c )
                                && (curInsetPO.QTB_Start_Date__c == d.QTB_Start_Date__c || curInsetPO.QTB_End_Date__c == d.QTB_End_Date__c
                                || curInsetPO.QTB_Start_Date__c == d.QTB_End_Date__c || curInsetPO.QTB_End_Date__c == d.QTB_Start_Date__c))
                            {
                                System.debug('elseiffstartdate');
                                curInsetPO.adderror(system.label.QTB_PO_Overlapping_TypeValidation);
                            }
                        }
                    }
                }
            }
        }
        catch(Exception e)
        {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
            e.getStackTraceString(),
            e.getMessage(),
            e.getTypeName(),
            QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
        
    } */
    /***********************************************************************************************************
     * Method : Calculate PO Balance Amount
     * Parameters: List<QTB_PurchaseOrder__c>
     * Requirement : SFCPQBLG-519
     * Start Date : 27-Feb-2024
     * Author : Virtusa
     * Description: Calculating the PO Balance Amount as same as PO Amount.
     **************************************************************************************************************/
    public static void calculatingPOBalanceAmount(List<QTB_PurchaseOrder__c> purchaseOrderList){
        try{
            for(QTB_PurchaseOrder__c po:purchaseOrderList)
            {
                if(po!=null && po.QTB_Amount__c !=null)
                {
                    po.QTB_PO_Balance_Amount__c = po.QTB_Amount__c; // Calculating the PO Balance Amount as same as PO Amount
                }
            }
            
        }
        catch(Exception e)
        {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
            QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
    }
    /******************************************************************************************************************
     * Method : PO Amount change
     * Parameters: List<QTB_PurchaseOrder__c> purchaseList
     * Requirement : Gitlab #3772
     * Start Date : 27-Feb-2024
     * Author : Virtusa
     * Description:  Validating the PO Amount , start date and end date OF PURCHASE ORDER whenever user changes.
     ********************************************************************************************************************/
    public static void poAmountChange(List<QTB_PurchaseOrder__c> poList,Map<Id,QTB_PurchaseOrder__c> ordOldMap)
    {
        Map<id,blng__CreditNote__c> mapCreditNote;
        List<id> poID = new List<id>();
        Set<Id> purchaseOrderId =new Set<id>();
        try
        {
            for(QTB_PurchaseOrder__c po : poList)
            {
                //Validating the PO Amount change
                if(ordOldMap.get(po.id).QTB_Amount__c != po.QTB_Amount__c && po.QTB_PO_Utilized_Amount__c !=null && po.QTB_Amount__c !=null && po.QTB_Amount__c < Decimal.valueOf(po.QTB_PO_Utilized_Amount__c))
                {
                    po.addError(System.label.QTB_ValidatingPOAmountChange);
                }
                
                //Validating the PO Amount should be greater than PO Balance
                if(ordOldMap.get(po.id).QTB_Amount__c != po.QTB_Amount__c && po.QTB_PO_Balance_Amount__c !=null && po.QTB_Amount__c != null && po.QTB_Amount__c < po.QTB_PO_Balance_Amount__c)
                {
                    po.addError(System.label.QTB_ValidatePOAmountGreaterThanBalance);
                }
                //checking any user changing the start date ,end date , active flag and amount && throw error if there is any posted invoice or creditnote
                
                poID.add(po.id);
                
                
                
                
            }
            
            //Fetching the Invoice with respect to purchase order
            Map<id,blng__Invoice__c> mapInvoice = new Map<id,blng__Invoice__c>([Select Id, blng__TotalAmount__c, blng__Account__c,QTB_PurchaseOrder__c ,blng__InvoiceDate__c from blng__Invoice__c 
                                                                                where QTB_PurchaseOrder__c IN:poID AND blng__InvoiceStatus__c =: STATUS_DRAFT]);//changed to STATUS_DRAFT for #26900
            //Fetching the CreditNote  with respect to purchase order
            
            mapCreditNote = new Map<id,blng__CreditNote__c>([Select id, blng__TotalAmount__c,blng__Status__c,QTB_Purchase_Order__c,blng__CreditNoteDate__c, blng__Account__c,QTB_CreditNote_Posted_Date__c from blng__CreditNote__c
                                                             where QTB_Purchase_Order__c IN:poID AND blng__Status__c =: STATUS_DRAFT]); //changed to STATUS_DRAFT for #26900
            
            for(QTB_PurchaseOrder__c po : poList)
            {
                //#25652 Removing End date and Status from Firing Valdation as per the users request
                if(ordOldMap.get(po.id).QTB_Start_Date__c != po.QTB_Start_Date__c && (mapInvoice.size() > 0 || mapCreditNote.size() > 0))
                {
                    po.addError(System.label.QTB_ValidatingPORecords);
                }
                
                //Calculating a Utilized amount
                if(po.QTB_PO_Balance_Amount__c !=null && po.QTB_Amount__c != null)
                {
                    po.QTB_PO_Utilized_Amount__c = String.valueOf(po.QTB_Amount__c - po.QTB_PO_Balance_Amount__c);
                    System.debug('>>po.QTB_PO_Utilized_Amount__c' + po.QTB_PO_Utilized_Amount__c);
                }
            }
            
            
        }
        catch (Exception e)
        {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
            QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
    }
    
    /******************************************************************************************************************
     * Method : reCalculatePOBalance
     * Parameters: List<QTB_PurchaseOrder__c> purchaseList
     * Requirement : Gitlab #3772
     * Start Date :
     * Author : TCS
     * Description: To re-calculate PO balance
     ********************************************************************************************************************/
    public static void reCalculatePOBalance(List<QTB_PurchaseOrder__c> purchaseOrderList, Map<Id, QTB_PurchaseOrder__c> poOrdOldMap, Boolean isInsertCase){
        Set<Id> poIDSet =new Set<id>();
        try{
            if(QTB_PurchaseOrderTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            for(QTB_PurchaseOrder__c po: purchaseOrderList){
                poIDSet.add(po.id);
            }
            if(!poIDSet.isEmpty()){
                Map<Id,List<blng__Invoice__c>> getInvoicesByPOId = new Map<Id,List<blng__Invoice__c>>();
                Map<Id,List<blng__CreditNote__c>> getCreditNotesByPOId = new Map<Id,List<blng__CreditNote__c>>();
                //Invoice with Purchase Order
                for(blng__Invoice__c invObj: [Select Id, blng__TotalAmount__c, blng__Account__c,QTB_PurchaseOrder__c ,blng__InvoiceStatus__c,blng__InvoiceDate__c from blng__Invoice__c 
                                                                                where QTB_PurchaseOrder__c IN : poIDSet AND blng__InvoiceStatus__c =: STATUS_POSTED]){
                    if(getInvoicesByPOId.containsKey(invObj.QTB_PurchaseOrder__c)){
                        getInvoicesByPOId.get(invObj.QTB_PurchaseOrder__c).add(invObj);
                    }else{
                        getInvoicesByPOId.put(invObj.QTB_PurchaseOrder__c, new List<blng__Invoice__c>{invObj});
                    }
                }
                //Credit Note with Purchase Order
                for(blng__CreditNote__c cNObj: [Select id, blng__TotalAmount__c,blng__Status__c,QTB_Purchase_Order__c,blng__CreditNoteDate__c, blng__Account__c,QTB_CreditNote_Posted_Date__c from blng__CreditNote__c
                                                             where QTB_Purchase_Order__c IN : poIDSet AND blng__Status__c =: STATUS_POSTED]){
                    if(getCreditNotesByPOId.containsKey(cNObj.QTB_Purchase_Order__c)){
                        getCreditNotesByPOId.get(cNObj.QTB_Purchase_Order__c).add(cNObj);
                    }else{
                        getCreditNotesByPOId.put(cNObj.QTB_Purchase_Order__c, new List<blng__CreditNote__c>{cNObj});
                    }
                }
                
                for(QTB_PurchaseOrder__c po : purchaseOrderList){
                    if(poOrdOldMap != null
                        && poOrdOldMap.get(po.Id) != null
                        && (!getInvoicesByPOId.isEmpty() || !getCreditNotesByPOId.isEmpty())
                        && (getInvoicesByPOId.containsKey(po.Id) || getCreditNotesByPOId.containsKey(po.Id))
                        && System.Label.QTB_POEligibleCountries.contains(po.QTB_Legal_Entity_Country__c)
                        && po.QTB_Amount__c != null
                        && po.QTB_PO_Balance_Amount__c != null
                        && poOrdOldMap.get(po.Id).QTB_Amount__c != null
                    && poOrdOldMap.get(po.Id).QTB_Amount__c != po.QTB_Amount__c){
                        Double additionalAmt = po.QTB_Amount__c - poOrdOldMap.get(po.Id).QTB_Amount__c;
                        po.QTB_PO_Balance_Amount__c =  po.QTB_PO_Balance_Amount__c + additionalAmt;
                        
                    }
                    else if(poOrdOldMap != null
                        && poOrdOldMap.get(po.Id) != null
                        && System.Label.QTB_POEligibleCountries.contains(po.QTB_Legal_Entity_Country__c)
                        && po.QTB_Amount__c != null
                        && po.QTB_PO_Balance_Amount__c != null
                        && poOrdOldMap.get(po.Id).QTB_Amount__c != null
                    && poOrdOldMap.get(po.Id).QTB_Amount__c <> po.QTB_Amount__c){
                        po.QTB_PO_Balance_Amount__c = po.QTB_Amount__c;
                    }
                }
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
            QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
    }
    /******************************************************************************************************************
     * Method : duplicateupdatetimeperiod
     * Parameters: List<QTB_PurchaseOrder__c> purchaseList,  Map<id,QTB_PurchaseOrder__c> POoldMap
     * Requirement : Gitlab #3773
     * Start Date :
     * Author : TCS - Ramesh Aravind
     * Description: To validate the new purchase order record with the same billing account has the already existing time period
    Gitlab #22654 - bypassing validation error to create PO with different service type with overlapping dates
         ********************************************************************************************************************/
    /*  public static void duplicateUpdateTimePeriod(List<QTB_PurchaseOrder__c> purchaseOrderList, Map<id,QTB_PurchaseOrder__c> POoldMap)
    {
        try{
            if(QTB_PurchaseOrderTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(purchaseOrderList == NULL){
                return;
            }
            list<Id> billingAccounts = new list<Id>();
            //Get all the PO Newly Inserted wrt Account Id
            for(QTB_PurchaseOrder__c po: purchaseOrderList){
                //Check Active PO
                if (po.QTB_Status__c == QTB_Constants.ACTIVE){
                    billingAccounts.add(po.QTB_Billing_Account__c);
                }
            }
            //Fetch all the purchase order related to the billing account except the record triggered  the update process to capture in validation
            list<QTB_PurchaseOrder__c> polist = [Select id,QTB_Service_Type__c,QTB_Billing_Account__c,Name,QTB_Start_Date__c, QTB_End_Date__c,QTB_PO_Type__c from QTB_PurchaseOrder__c where QTB_Billing_Account__c in : billingAccounts and id <>: POoldmap.keyset() and QTB_Status__c =: QTB_Constants.ACTIVE];
            Map<id,List<QTB_PurchaseOrder__c>> AccountIdPOMap = new Map<id,List<QTB_PurchaseOrder__c>>();
            //Get all the Existing PO wrt Account Id
            for(QTB_PurchaseOrder__c po : polist){
                if(AccountIdPOMap.containsKey(po.QTB_Billing_Account__c)){
                    AccountIdPOMap.get(po.QTB_Billing_Account__c).add(po);
                }else{
                    AccountIdPOMap.put(po.QTB_Billing_Account__c, new List<QTB_PurchaseOrder__c>{po});
                }
            }
            //Check if any Start date or End date matches or not wrt Account POs
            List<String> PurchaseName = new List<string>();
            for(QTB_PurchaseOrder__c curInsetPO : purchaseOrderList){
                if(AccountIdPOMap.containsKey(curInsetPO.QTB_Billing_Account__c)){
                    for(QTB_PurchaseOrder__c d : AccountIdPOMap.get(curInsetPO.QTB_Billing_Account__c)){
                        // Gitlab #22654 - If service type is different then allow to create PO with overlapping dates
                        If((curInsetPO.QTB_Service_Type__c == d.QTB_Service_Type__c && curInsetPO.QTB_PO_Type__c == d.QTB_PO_Type__c)){
                            if((// Inside
                                curInsetPO.QTB_End_Date__c > d.QTB_Start_Date__c && curInsetPO.QTB_End_Date__c < d.QTB_End_Date__c)||
                                // outside
                            (curInsetPO.QTB_Start_Date__c < d.QTB_Start_Date__c &&curInsetPO.QTB_End_Date__c > d.QTB_End_Date__c) ||
                                // Startdate in the middle
                            (curInsetPO.QTB_Start_Date__c > d.QTB_Start_Date__c && curInsetPO.QTB_Start_Date__c < d.QTB_End_Date__c)
                                )
                            {
                                curInsetPO.adderror(system.label.QTB_PO_Overlapping_TypeValidation+'  for PO Record: '+d.Name);
                                break;
                            }
                            
                            //Allowing  PO With same date range but should have different PO Types //23922 in update scenario
                            if((curInsetPO.QTB_PO_Type__c == d.QTB_PO_Type__c && curInsetPO.QTB_Service_Type__c == d.QTB_Service_Type__c) && (curInsetPO.QTB_Start_Date__c == d.QTB_Start_Date__c || curInsetPO.QTB_End_Date__c == d.QTB_End_Date__c
                                || curInsetPO.QTB_Start_Date__c == d.QTB_End_Date__c || curInsetPO.QTB_End_Date__c == d.QTB_Start_Date__c))
                            {
                                curInsetPO.adderror(system.label.QTB_PO_Overlapping_TypeValidation);
                            }
                            
                        }
                    }
                }
            }
        }
        catch(Exception e)
        {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
            e.getStackTraceString(),
            e.getMessage(),
            e.getTypeName(),
            QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
    } */
    
    /***********************************************************************************************************
     * Method : storeSentEmailAlertsOnInsert
     * Parameters: List<QTB_PurchaseOrder__c>
     * Requirement :Gitlab #12087
     * Start Date :
     * Author : TCS
     * Description:  To Store the TypeOfNotificationSent field with the sent alerts field names to use in report.
     **************************************************************************************************************/
    public static void storeSentEmailAlertsOnInsert(List<QTB_PurchaseOrder__c> purchaseList){
        try{
            if(QTB_PurchaseOrderTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(purchaseList == NULL) { return; }
            
            String type='QTB_PurchaseOrder__c';
            System.debug('I am called');
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType purchaseSchema = schemaMap.get(type);
            Map<String, Schema.SObjectField> fieldMap = purchaseSchema.getDescribe().fields.getMap();
            System.debug('I am called fieldMap  '+fieldMap);
            
            
            for(QTB_PurchaseOrder__c purchase: purchaseList ){
                if(purchase.QTB_100_Utilization_Email_Sent__c){
                    //     String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ ) :
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_100_Utilization_Email_Sent__c').getDescribe().getLabel()) : (fieldMap.get('QTB_100_Utilization_Email_Sent__c').getDescribe().getLabel());
                    
                } if(purchase.QTB_30_Days_After_100_Utilization_Email__c){
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+fieldMap.get('QTB_30_Days_After_100_Utilization_Email__c').getDescribe().getLabel() ) :(fieldMap.get('QTB_30_Days_After_100_Utilization_Email__c').getDescribe().getLabel());
                    
                } if(purchase.QTB_30_Days_Before_Email_Sent__c){
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+fieldMap.get('QTB_30_Days_Before_Email_Sent__c').getDescribe().getLabel() ) :(fieldMap.get('QTB_30_Days_Before_Email_Sent__c').getDescribe().getLabel());
                    
                } if(purchase.QTB_50_Utilization_Email_Sent__c){
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_50_Utilization_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_50_Utilization_Email_Sent__c').getDescribe().getLabel());
                    
                } if(purchase.QTB_60_Days_After_100_Utilization_Email__c){
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+fieldMap.get('QTB_60_Days_After_100_Utilization_Email__c').getDescribe().getLabel() ) :(fieldMap.get('QTB_60_Days_After_100_Utilization_Email__c').getDescribe().getLabel());
                    
                } if(purchase.QTB_60_Days_After_Email_Sent__c){
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_60_Days_After_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_60_Days_After_Email_Sent__c').getDescribe().getLabel());
                    
                } if(purchase.QTB_60_Days_Before_Email_Sent__c){
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_60_Days_Before_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_60_Days_Before_Email_Sent__c').getDescribe().getLabel());
                    
                } if(purchase.QTB_75_Utilization_Email_Sent__c){
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_75_Utilization_Email_Sent__c').getDescribe().getLabel() ) :(fieldMap.get('QTB_75_Utilization_Email_Sent__c').getDescribe().getLabel());
                    
                } if(purchase.QTB_90_Days_After_Email_Sent__c){
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_90_Days_After_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_90_Days_After_Email_Sent__c').getDescribe().getLabel());
                    
                } if(purchase.QTB_90_Days_Before_Email_Sent__c){
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_90_Days_Before_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_90_Days_Before_Email_Sent__c').getDescribe().getLabel());
                    
                } if(purchase.QTB_90_Utilization_Email_Sent__c){
                    purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_90_Utilization_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_90_Utilization_Email_Sent__c').getDescribe().getLabel());
                    
                }
            }
            
        } catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
    }
    
    /***********************************************************************************************************
     * Method : storeSentEmailAlertsOnUpdate
     * Parameters: List<QTB_PurchaseOrder__c> purchaseList,  Map<id,QTB_PurchaseOrder__c> POoldMap
     * Requirement :Gitlab #12087
     * Start Date :
     * Author : TCS
     * Description: To update the TypeOfNotificationSent field with the sent alerts field names to use in report.
     **************************************************************************************************************/
    public static void storeSentEmailAlertsOnUpdate(List<QTB_PurchaseOrder__c> purchaseOrderList, Map<id,QTB_PurchaseOrder__c> POoldMap){
        try{
            if(QTB_PurchaseOrderTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(purchaseOrderList == NULL){
                return;
            }
            
            String type='QTB_PurchaseOrder__c';
            System.debug('I am called');
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType leadSchema = schemaMap.get(type);
            Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
            System.debug('I am called fieldMap  '+fieldMap);
            
            
            for(QTB_PurchaseOrder__c purchase: purchaseOrderList ){
                
                if((purchase.QTB_100_Utilization_Email_Sent__c != POoldMap.get(purchase.id).QTB_100_Utilization_Email_Sent__c) ||
                    (purchase.QTB_30_Days_After_100_Utilization_Email__c != POoldMap.get(purchase.id).QTB_30_Days_After_100_Utilization_Email__c) ||
                    (purchase.QTB_30_Days_Before_Email_Sent__c != POoldMap.get(purchase.id).QTB_30_Days_Before_Email_Sent__c)||
                    (purchase.QTB_50_Utilization_Email_Sent__c != POoldMap.get(purchase.id).QTB_50_Utilization_Email_Sent__c) ||
                    (purchase.QTB_60_Days_After_100_Utilization_Email__c != POoldMap.get(purchase.id).QTB_60_Days_After_100_Utilization_Email__c) ||
                    (purchase.QTB_60_Days_After_Email_Sent__c != POoldMap.get(purchase.id).QTB_60_Days_After_Email_Sent__c) ||
                    (purchase.QTB_60_Days_Before_Email_Sent__c != POoldMap.get(purchase.id).QTB_60_Days_Before_Email_Sent__c) ||
                    (purchase.QTB_75_Utilization_Email_Sent__c != POoldMap.get(purchase.id).QTB_75_Utilization_Email_Sent__c) ||
                    (purchase.QTB_90_Days_After_Email_Sent__c != POoldMap.get(purchase.id).QTB_90_Days_After_Email_Sent__c) ||
                    (purchase.QTB_90_Days_Before_Email_Sent__c != POoldMap.get(purchase.id).QTB_90_Days_Before_Email_Sent__c) ||
                    (purchase.QTB_90_Utilization_Email_Sent__c != POoldMap.get(purchase.id).QTB_90_Utilization_Email_Sent__c)
                ){
                    purchase.Type_of_Notification_Sent__c = '';
                    if(purchase.QTB_100_Utilization_Email_Sent__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_100_Utilization_Email_Sent__c').getDescribe().getLabel()) : (fieldMap.get('QTB_100_Utilization_Email_Sent__c').getDescribe().getLabel());
                    }
                    if(purchase.QTB_30_Days_After_100_Utilization_Email__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+fieldMap.get('QTB_30_Days_After_100_Utilization_Email__c').getDescribe().getLabel() ) :(fieldMap.get('QTB_30_Days_After_100_Utilization_Email__c').getDescribe().getLabel());
                    }
                    if(purchase.QTB_30_Days_Before_Email_Sent__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+fieldMap.get('QTB_30_Days_Before_Email_Sent__c').getDescribe().getLabel() ) :(fieldMap.get('QTB_30_Days_Before_Email_Sent__c').getDescribe().getLabel());
                    }
                    if(purchase.QTB_50_Utilization_Email_Sent__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_50_Utilization_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_50_Utilization_Email_Sent__c').getDescribe().getLabel());
                    }
                    if(purchase.QTB_60_Days_After_100_Utilization_Email__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+fieldMap.get('QTB_60_Days_After_100_Utilization_Email__c').getDescribe().getLabel() ) :(fieldMap.get('QTB_60_Days_After_100_Utilization_Email__c').getDescribe().getLabel());
                    }
                    if(purchase.QTB_60_Days_After_Email_Sent__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_60_Days_After_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_60_Days_After_Email_Sent__c').getDescribe().getLabel());
                    }
                    if(purchase.QTB_60_Days_Before_Email_Sent__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_60_Days_Before_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_60_Days_Before_Email_Sent__c').getDescribe().getLabel());
                    }
                    if(purchase.QTB_75_Utilization_Email_Sent__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_75_Utilization_Email_Sent__c').getDescribe().getLabel() ) :(fieldMap.get('QTB_75_Utilization_Email_Sent__c').getDescribe().getLabel());
                    }
                    if(purchase.QTB_90_Days_After_Email_Sent__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_90_Days_After_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_90_Days_After_Email_Sent__c').getDescribe().getLabel());
                    }
                    if(purchase.QTB_90_Days_Before_Email_Sent__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_90_Days_Before_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_90_Days_Before_Email_Sent__c').getDescribe().getLabel());
                    }
                    if(purchase.QTB_90_Utilization_Email_Sent__c){
                        purchase.Type_of_Notification_Sent__c = String.isNotBlank(purchase.Type_of_Notification_Sent__c)? (purchase.Type_of_Notification_Sent__c+','+ fieldMap.get('QTB_90_Utilization_Email_Sent__c').getDescribe().getLabel()) :(fieldMap.get('QTB_90_Utilization_Email_Sent__c').getDescribe().getLabel());
                    }
                }
                
            }
            
        } catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
    }
    
    /******************************************************************************************************************
     * Method : validatePostedInvoicesOrCredits
     * Parameters: List<QTB_PurchaseOrder__c> purchaseList
     * Requirement : Gitlab #26901
     * Start Date : 11-nov-2024
     * Author : Virtusa
     * Description:  Validating the PO Amount, status, start date and end date for associated posted invoice or credit note OF PURCHASE ORDER whenever user changes.
     *              This remains on the PO level and shouldnt be moved to POA as the validation is on the PO itself
     ********************************************************************************************************************/
    public static void validatePostedInvoicesOrCredits(List<QTB_PurchaseOrder__c> poList,Map<Id,QTB_PurchaseOrder__c> ordOldMap)
    {
        try
        {
            Set<id> poID = new Set<id>();
            for(QTB_PurchaseOrder__c po : poList)
            {
                poID.add(po.id);
            }
            
            //Fetching the Invoice with respect to purchase order
            Map<id,blng__Invoice__c> mapInvoice = new Map<id,blng__Invoice__c>([Select Id, blng__TotalAmount__c, blng__Account__c,QTB_PurchaseOrder__c ,blng__InvoiceDate__c from blng__Invoice__c 
                                                                                where QTB_PurchaseOrder__c IN:poID AND blng__InvoiceStatus__c =: STATUS_POSTED]);
            //Fetching the CreditNote  with respect to purchase order
            Map<id,blng__CreditNote__c> mapCreditNote = new Map<id,blng__CreditNote__c>([Select id, blng__TotalAmount__c,blng__Status__c,QTB_Purchase_Order__c,blng__CreditNoteDate__c, blng__Account__c,QTB_CreditNote_Posted_Date__c from blng__CreditNote__c
                                                                                         where QTB_Purchase_Order__c IN:poID AND blng__Status__c =: STATUS_POSTED]);
            
            // Not allowing to edit if purchase order is respective to posted invoice or creditnote
            for(QTB_PurchaseOrder__c po : poList)
            {
                if(ordOldMap.get(po.id).QTB_Start_Date__c != po.QTB_Start_Date__c && (mapInvoice.size() > 0 || mapCreditNote.size() > 0))
                {
                    po.addError(System.label.QTB_ValidatingPOStartDate);
                }
                else if(ordOldMap.get(po.id).QTB_Linked_Sales_Account__c != po.QTB_Linked_Sales_Account__c && (mapInvoice.size() > 0 || mapCreditNote.size() > 0))
                {
                    po.addError(System.label.QTB_ValidatingPOBillingAccount);
                }
                else if(ordOldMap.get(po.id).QTB_PO_Type__c != po.QTB_PO_Type__c && (mapInvoice.size() > 0 || mapCreditNote.size() > 0))
                {
                    po.addError(System.label.QTB_ValidatingPOType);
                }
                else if(ordOldMap.get(po.id).QTB_Service_Type__c != po.QTB_Service_Type__c && (mapInvoice.size() > 0 || mapCreditNote.size() > 0))
                {
                    po.addError(System.label.QTB_ValidatingPOServiceType);
                }
            }
        }
        catch (Exception e)
        {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
            QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
    }
    /******************************************************************************************************************
     * Method : validateStraitsPO
     * Parameters: List<QTB_PurchaseOrder__c> poList
     * Requirement : Gitlab #33801
     * Start Date : 09-oct-2025
     * Author : Virtusa
     * Description:  Restricting Strait member users from creating or updating purchase order other than Hong Kong
     ********************************************************************************************************************/
    public static void validateStraitsPO(List<QTB_PurchaseOrder__c> poList) {
        try
        {
            Id currentUserId = UserInfo.getUserId();
            List<String> labelValues = System.Label.QTB_Straits_and_China_Member.split(',');
            // Check if user is in the group
            List<GroupMember> gmList = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :currentUserId AND Group.Name IN :labelValues];
            Boolean isInStraitsGroup = gmList.size() > 0;
            if(isInStraitsGroup) {
                for(QTB_PurchaseOrder__c po : poList) {
                    if(po.QTB_Legal_Entity_Country__c != null && po.QTB_Legal_Entity_Country__c != 'Hong Kong') {
                        po.addError(System.Label.QTB_Error_PO_LegalEntity_NotHK);
                    }
                }
            }
        }
        catch (Exception e)
        {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
            QTB_PurchaseOrderHelper.class.getname());
            throw e;
        }
    }
    
}
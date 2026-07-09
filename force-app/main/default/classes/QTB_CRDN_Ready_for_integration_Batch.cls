/*****************************************************************************************************
* Class: QTB_CRDN_Ready_for_integration_Batch
* Author: kullayappa A
* Purpose: This is a Batch class containing logic for the CreditNote lines which are in draft even after CreditNotes are posted
* Requirement: To iterate on the draft CreditNote lines which is called after 5mins from the scheduler 
* Change History: 05/05/2024
* Developer                         Date                    Description
* ------------------------------------------------------------------------------------------- 
* kullayappa A      26/06/2024     Creation of new Batch class for posting the draft creditnote lines
*******************************************************************************************************/
global class QTB_CRDN_Ready_for_integration_Batch implements Database.Batchable < sObject > , Database.AllowsCallouts, Database.Stateful {
    // Variable to get the class name
    private static final String CLASSNAME = QTB_CRDN_Ready_for_integration_Batch.class.getName();
    // variable to store Draft recordtype id
    //Public static final Id draftInvRecTypeId = QTB_Utils.CREDITNOTE_POSTED_RECTYPEID;
    // variable to store Draft recordtype id
    Public static final Id PostedInvRecTypeId = QTB_Utils.CREDITNOTE_POSTED_RECTYPEID;
    // Variable to throw exception for catch block
    public static boolean throwExplicitException = false;
    // List of Creditnote Ids which are passed from QTB_Creditnotehelper class
    public Set < Id > crdtIdLst = new Set < Id > ();
    public List < Id > crdtIdFinalLst = new List < Id > ();
    public List < QTB_CustomInvoiceNumber__c > customSettingUpdate = new List < QTB_CustomInvoiceNumber__c > ();
    //Construction for the batch QTB_CRDN_Ready_for_integration_Batch
    global QTB_CRDN_Ready_for_integration_Batch(Set < Id > processedCrdtIds,
                                                List<QTB_CustomInvoiceNumber__c> invCustomSettToUpdate) { //added new parameter as part of epic - 2980
        try {
            if (QTB_CRDN_Ready_for_integration_Batch.throwExplicitException) {
                throw new NullPointerException();
            }
            //Check if the Creditnote received has values or not
            if (!processedCrdtIds.isEmpty()) {
                crdtIdLst.addAll(processedCrdtIds);
            }
            // added as part of epic -2980
             if (!invCustomSettToUpdate.isEmpty()) {
                customSettingUpdate.addAll(invCustomSettToUpdate);
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),
            e.getStackTraceString(),
            e.getMessage(),
            e.getTypeName(),
            CLASSNAME);
        }
    }
    /*********************************************************************************************************
    Method Name: start
    Parameters: Database.BatchableContext
    Return Type: Database.QueryLocator
    **********************************************************************************************************/
    global List < blng__CreditNote__c > start(Database.BatchableContext BC) {
        //added below as part of epic -2980
        if(customSettingUpdate != null && customSettingUpdate.size()>0){
        Map<String, QTB_CustomInvoiceNumber__c> lastCreditNoteNumMap = QTB_CustomInvoiceNumber__c.getAll();
		final String nonDigits = '\\D'; //any non-digit character
        String finalValue = lastCreditNoteNumMap.get(customSettingUpdate[0].Name).QTB_Next_Sequence_Number__c;
		String finalNumber = finalValue.replaceAll(nonDigits, '');
        String customSettingValue= customSettingUpdate[0].QTB_Next_Sequence_Number__c;
        String finalCustomNumber = customSettingValue.replaceAll(nonDigits, '');    
        Long numVal =Long.valueOf(finalNumber);
        Long currentNum = Long.valueOf(finalCustomNumber);
            if(numVal < currentNum){
             update customSettingUpdate;
        }
       }
        //Querying for all the Creditnotethat are Posted in QTB_InvoiceBatch
        List < blng__CreditNote__c > lstCrdt = [select id, QTB_Credit_Note_Type__c,blng__Account__r.QTB_Legal_Entity_Country__c, QTB_Custom_Invoice_Number__c, QTB_Custom_Invoice_ID__c, QTB_CreditNoteRecordType__c, name, blng__Status__c, blng__Account__r.QTB_Contract_Entity__c, blng__Account__r.BillingCountry, blng__Account__r.QTB_Customer_Number__c,
        blng__Account__r.QTB_Contract_Entity__r.blng__Country__c, QTB_Transferred_To_Oracle__c, blng__Account__r.QTB_Hold_Invoice__c, blng__Account__r.BillingState, QTB_Tax_Override_Amount__c,
        blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c, QTB_Transferred_to_Invoice_Compliance__c, QTB_Purchase_Order__c , blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
        recordTypeId, blng__Account__r.QTB_Market__r.QTB_State__c, QTB_Ready_for_Integration__c, QTB_Ready_for_Integration_Status__c FROM blng__CreditNote__c where id in: crdtIdLst
        ];
        return lstCrdt;
    }
    /*********************************************************************************************************
    Method Name: execute
    Parameters: Database.BatchableContext,List<blng__CreditNote__c>
    Return Type: void
    **********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List < blng__CreditNote__c > scope) {
        string errorIds = '';
        try {
            
            // Map to store Custom Creditnote Number is empty and create new Custom Creditnote number
            Map < string, blng__CreditNote__c > mapemptycustmNoCrdtId = new Map < string, blng__CreditNote__c > ();
            // Map to store Custom Creditnote Number and CreditnoteId for Duplicate check
            Map < string, id > mapCustmCrdtNoCrdtId = new Map < string, id > ();
            // Set to store Creditnoteid whose Creditnotelines are in Draft status
            set < id > setCrdtId = new set < id > ();
            // Map to store CreditnoteLine as  key and Creditnoteid as a value for Product based 
            map < id, id > mapCrdtLineIdAndCrdtId = new map < id, id > ();
            // Set to store Creditnoteid from Tax Detail for Flat Rate 
            Set < id > stCrdtIdOfTaxDetailFlatRate = new Set < id > (); // not user
            // Set to store Creditnoteid from Tax Detail for Product 
            Set < id > stCrdtIdOfTaxDetailProduct = new Set < id > (); // not use
            // Map to store Creditnote id and Tax Override amount for Flat Rate
            Map < id, Decimal > mapCrdtTaxOverAmtForFlat = new Map < id, Decimal > ();
            // Map to store Creditnote id and Tax Override amount for Product
            Map < id, Decimal > mapCrdtIdTaxOverAmtForProduct = new Map < id, Decimal > ();
            // Set to store Creditnoteid for Flat Rate
            Set < Id > setCrdtIdForFlatRate = new set < id > ();
            // List to store Creditnotefor draft update
            List < blng__CreditNote__c > crdtUpdateToDraft = new List < blng__CreditNote__c > ();
            // List of Tax Detail record that need to be deleted for Draft lines 
            List < QTB_Tax_Detail__c > lstTaxDetailDelete = new List < QTB_Tax_Detail__c > ();
            // List to Creditnoteid for duplicate custom Creditnotenumber
            set < id > duplicatecustCrdtId = new Set < Id > ();
            // List to update Custom setting for Custom Creditnotenumber
            List < QTB_CustomInvoiceNumber__c > lstCustmStngCustmCrdtNo = new List < QTB_CustomInvoiceNumber__c > ();
            // List to update Creditnotehaving duplicate custom Creditnotenumber
            List < blng__CreditNote__c > lstUpdatedCrdtList = new List < blng__CreditNote__c > ();
            // Set to store Creditnotehaving duplicate custom Creditnotenumber
            // Set to store country
            Set < String > setCountry = new Set < string > ();
            Set<id> accId = new Set<id>();
            Set < blng__CreditNote__c > stUpdatedCrdtList = new Set < blng__CreditNote__c > ();
            if (QTB_CRDN_Ready_for_integration_Batch.throwExplicitException) {
            throw new NullPointerException();
            }
                if (!scope.isEmpty()) {
                // Map to store Custom CreditnoteNumber and CreditnoteId for Duplicate check
                set<Id> crditId=new set<Id>();
                for (blng__CreditNote__c crdtNote: scope) {
                    errorIds += ';;' + crdtNote.id;
                    mapCustmCrdtNoCrdtId.put(crdtNote.QTB_Custom_Invoice_Number__c, crdtNote.id);
                    setCountry.add(crdtNote.blng__Account__r.QTB_Legal_Entity_Country__c);
                    accId.add(crdtNote.blng__Account__c);
                }
                    if (!mapCustmCrdtNoCrdtId.keyset().isEmpty()) {
                    // Query all Creditnotelines from the scope
                    for (blng__CreditNoteLine__c crdtNoteLine: [select id, blng__TaxAmount__c, blng__Status__c,
                    QTB_Tax_Override_Amount__c,
                    blng__CreditNote__r.id, blng__Subtotal__c,
                    blng__TaxPercentageApplied__c, blng__CreditNote__r.blng__Subtotal__c,
                    blng__LegalEntity__r.Id, blng__CreditNote__r.blng__Status__c,
                    blng__CreditNote__r.QTB_Transferred_to_Invoice_Compliance__c,
                    blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                    blng__CreditNote__c, LastModifiedDate,
                    blng__CreditNote__r.QTB_Custom_Invoice_Number__c,
                    blng__CreditNote__r.QTB_Ready_for_Integration__c,
                    blng__CreditNote__r.QTB_Ready_for_Integration_Status__c,
                    blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                    blng__CreditNote__r.blng__Account__r.QTB_Customer_Number__c
                    from blng__CreditNoteLine__c where blng__CreditNote__r.blng__Status__c = 'Posted'
                    and
                    blng__CreditNote__c in: mapCustmCrdtNoCrdtId.values()
                    ]) {
                        // Condition to check wether Draft Lines present for an Creditnote
                        if (crdtNoteLine.blng__Status__c == 'Draft') {
                            if (!setCrdtId.contains(crdtNoteLine.blng__CreditNote__c)) {
                                setCrdtId.Add(crdtNoteLine.blng__CreditNote__c);
                            }
                        }
                        // Flat Rate and Product based out of Draft condition as some of the lines may be Posted
                        //Condition to check account Tax Applicability is Flat Rate 
                        if (crdtNoteLine.blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c != 'Hong Kong') {
                            if (crdtNoteLine.blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_TYPE_FLAT &&
                            !setCrdtIdForFlatRate.contains(crdtNoteLine.blng__CreditNote__c)) {
                            // Store CreditnoteIds
                                setCrdtIdForFlatRate.Add(crdtNoteLine.blng__CreditNote__c);
                            }
                            //Condition to check account Tax Applicability is Product Based Rate 
                            else if (crdtNoteLine.blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_PRODUCT_BASED) {
                                mapCrdtLineIdAndCrdtId.put(crdtNoteLine.Id, crdtNoteLine.blng__CreditNote__c);
                            }
                        }
                    }
                    if (!setCrdtIdForFlatRate.isEmpty() || !mapCrdtLineIdAndCrdtId.isEmpty() || Test.isRunningTest()) {
                        //Fetching all the Tax details related to the Creditnote and Creditnote lines for the comparison
                        List < QTB_Tax_Detail__c > lstTaxDetail = [select id, Name, QTB_Credit_Note__c, QTB_Tax_Override_Amount__c,
                                                                   QTB_Credit_Note__r.blng__Account__r.QTB_Special_Tax_Condition__c,
                                                                   QTB_Credit_Note_Line__c,QTB_Credit_Note_Line__r.blng__creditNote__c
                                                                    from QTB_Tax_Detail__c
                                                                    where QTB_Credit_Note__c IN: setCrdtIdForFlatRate OR 
                                                                   QTB_Credit_Note_Line__c IN: mapCrdtLineIdAndCrdtId.keyset()];
                        
                      
                       //Created map which will store credit note id and list of taxdetails records       #Issues/30167
                       Map<Id, List<QTB_Tax_Detail__c>> CrdIdFlatTaxAmt = new Map<Id, List<QTB_Tax_Detail__c>>();                       
                        if (!lstTaxDetail.isEmpty()) {
                            for (QTB_Tax_Detail__c taxDetail: lstTaxDetail) {
                                Decimal taxAmt = 0;
                                
                                // List of Tax Detail linked with Draft Credit Note/Creditnotelines
                                if (setCrdtId.contains(taxDetail.QTB_Credit_Note__c) || setCrdtId.contains(mapCrdtLineIdAndCrdtId.get(taxDetail.QTB_Credit_Note_Line__c))) {
                                    //|| setCrdtIdForFlatRate.contains(taxDetail.QTB_Credit_Note__c) || mapCrdtLineIdAndCrdtId.ContainsKey(taxDetail.QTB_Credit_Note_Line__c)) {
                                    lstTaxDetailDelete.add(taxDetail);
                                    /*if(taxDetail.QTB_Credit_Note__c != null){
                                        setCrdtId.add(taxDetail.QTB_Credit_Note__c);
                                    }else{
                                        setCrdtId.add(taxDetail.QTB_Credit_Note_Line__r.blng__creditNote__c);
                                    }*/
                                    
                                } //Checking for Flat Rate Credit Note Ids with Tax details -> Tax Override Amount match
                                else if (setCrdtIdForFlatRate.contains(taxDetail.QTB_Credit_Note__c) &&
                                        taxDetail.QTB_Credit_Note_Line__c == Null) {
                                        taxAmt = taxDetail.QTB_Tax_Override_Amount__c != null ? taxDetail.QTB_Tax_Override_Amount__c : 0;
                                    if (mapCrdtTaxOverAmtForFlat.ContainsKey(taxDetail.QTB_Credit_Note__c)) {
                                        taxAmt = taxAmt + mapCrdtTaxOverAmtForFlat.get(taxDetail.QTB_Credit_Note__c);
                                    }
                                    mapCrdtTaxOverAmtForFlat.put(taxDetail.QTB_Credit_Note__c, taxAmt);
                                    //Instead of adding single replacing existing taxdetail record in CrdIdFlatTaxAmt map store list of taxdetails    #Issues/30167
                                    //This logic we are creating so that If credit note went into Error status due to incorrect data present of tax details then delete all tax details 
                                    //so that when we Click on Retry Ready for integration button then it will resolved the problem 
                                    // Check if the map contains the credit note ID
                                    if (CrdIdFlatTaxAmt !=null && CrdIdFlatTaxAmt.containsKey(taxDetail.QTB_Credit_Note__c)) {
                                        // Add tax detail to existing list
                                        CrdIdFlatTaxAmt.get(taxDetail.QTB_Credit_Note__c).add(taxDetail);
                                    } else {
                                        // Initialize new list and add tax detail
                                        CrdIdFlatTaxAmt.put(taxDetail.QTB_Credit_Note__c, new List<QTB_Tax_Detail__c>{ taxDetail });
                                    }

                                }

                                //Else for Product based check from CreditNote Lines
                                else {
                                    if (mapCrdtLineIdAndCrdtId.ContainsKey(taxDetail.QTB_Credit_Note_Line__c)) {
                                        Id crdtNoteId = mapCrdtLineIdAndCrdtId.get(taxDetail.QTB_Credit_Note_Line__c);
                                        taxAmt = taxDetail.QTB_Tax_Override_Amount__c != null ? taxDetail.QTB_Tax_Override_Amount__c : 0;
                                    if (mapCrdtIdTaxOverAmtForProduct.containsKey(crdtNoteId)) {
                                        taxAmt = taxAmt + mapCrdtIdTaxOverAmtForProduct.get(crdtNoteId);
                                    }
                                    mapCrdtIdTaxOverAmtForProduct.put(crdtNoteId, taxAmt);
                                      //Instead of adding single replacing existing taxdetail record in CrdIdFlatTaxAmt map store list of taxdetails    #Issues/30167
                                      //This logic we are creating so that If credit note went into Error status due to incorrect data present of tax details then delete all tax details 
                                      //so that when we Click on Retry Ready for integration button then it will resolved the problem 
                                      // Check if the map contains the credit note ID
                                    if (CrdIdFlatTaxAmt !=null && CrdIdFlatTaxAmt.containsKey(taxDetail.QTB_Credit_Note_Line__r.blng__CreditNote__c)) {
                                        // Add tax detail to existing list
                                        CrdIdFlatTaxAmt.get(taxDetail.QTB_Credit_Note_Line__r.blng__CreditNote__c).add(taxDetail);
                                    } else {
                                        // Initialize new list and add tax detail
                                        CrdIdFlatTaxAmt.put(taxDetail.QTB_Credit_Note_Line__r.blng__CreditNote__c, new List<QTB_Tax_Detail__c>{ taxDetail });
                                    }

                                    }
                                }
                            }
                        }
                        // If Creditnote/ CreditnoteLines doesn't have Tax Deatil then store the Creditnoteid in Creditnote Reposting set
                        if (!mapCrdtTaxOverAmtForFlat.isEmpty() || !mapCrdtIdTaxOverAmtForProduct.isEmpty() || Test.isRunningTest()) {
                            for (blng__CreditNote__c crdtNote: scope) {
                                 //As a part of Git issues/33351 Need to Round of total sum of all tax detail QTB_Tax_Override_Amount__c related to credit note
                                if ((!mapCrdtTaxOverAmtForFlat.containsKey(crdtNote.id) && !mapCrdtIdTaxOverAmtForProduct.containsKey(crdtNote.id) && !setCrdtId.contains(crdtNote.id)) ||
                                (mapCrdtTaxOverAmtForFlat.ContainsKey(crdtNote.Id) && (mapCrdtTaxOverAmtForFlat.get(crdtNote.Id)).setScale(2, System.RoundingMode.HALF_UP) != crdtNote.QTB_Tax_Override_Amount__c.setScale(2, System.RoundingMode.HALF_UP)) ||
                                (mapCrdtIdTaxOverAmtForProduct.containsKey(crdtNote.Id) && mapCrdtIdTaxOverAmtForProduct.get(crdtNote.Id).setScale(2, System.RoundingMode.HALF_UP) != crdtNote.QTB_Tax_Override_Amount__c.setScale(2, System.RoundingMode.HALF_UP))) {
                                    setCrdtId.add(crdtNote.id);
                                   // lstTaxDetailDelete.add(CrdIdFlatTaxAmt.get(crdtNote.id));   #Issues/30167
                                   // Putting Null check and  Replaced add function with addAll as a part of   #Issues/30167
                                   if(CrdIdFlatTaxAmt !=null){
                                       lstTaxDetailDelete.addAll(CrdIdFlatTaxAmt.get(crdtNote.id));  
                                   }
                                   
                                }
                            }
                        }
                            // Delete Draft Lines related Tax Detail record
                            if (!lstTaxDetailDelete.isEmpty() || Test.isRunningTest()) {
                                Delete lstTaxDetailDelete;
                                lstTaxDetailDelete.clear();
                                lstTaxDetail.clear();
                                mapCrdtLineIdAndCrdtId.clear();
                            }
                    }
                }
                    /********Added by yogesh
                    if (!setCrdtId.isEmpty()) {
                        //Update those Creditnotestatus to Draft which has no Tax Details and CreditnoteLines are in Draft,
                        //let me verify this It's not possible  
                        for (Id CrdtNoteId: setCrdtId) {
                            blng__CreditNote__c Creditnote = new blng__CreditNote__c();
                            Creditnote.id = CrdtNoteId;
                            Creditnote.blng__Status__c = QTB_Constants.CREDITNOTE_STATUS_DRAFT;
                            Creditnote.QTB_CreditNote_Posted_Date__c = null;
                            //Creditnote.RecordTypeId = '';
                            Creditnote.QTB_Transferred_to_Invoice_Compliance__c = System.today();
                            crdtUpdateToDraft.add(Creditnote);
                        }
                        system.debug('555555' + crdtUpdateToDraft);
                        if (!crdtUpdateToDraft.isEmpty()) {
                            SBQQ.TriggerControl.disable();
                            system.debug('666666' + crdtUpdateToDraft);
                            update crdtUpdateToDraft;
                            system.debug('666666' + crdtUpdateToDraft);
                            SBQQ.TriggerControl.enable();
                            system.debug('666666' + crdtUpdateToDraft);
                        }
                        system.debug('666666' + crdtUpdateToDraft);
                        List<blng__CreditNote__c> postCRDN=new list<blng__CreditNote__c>();
                        //Updating Drafted CreditNote back to Posted
                        if (!crdtUpdateToDraft.isEmpty()) {
                            for (blng__CreditNote__c crdt: crdtUpdateToDraft) {
                                crdt.blng__Status__c = QTB_Constants.CREDITNOTE_STATUS_POSTED;
                                //crdt.RecordTypeId = PostedInvRecTypeId;
                                crdt.QTB_CreditNote_Posted_Date__c = System.today();
                                crdt.QTB_Transferred_to_Invoice_Compliance__c = null;
                                //postCRDN.add(crdt);
                            }
                            SBQQ.TriggerControl.disable();
                            update crdtUpdateToDraft;
                            SBQQ.TriggerControl.enable();
                            crdtUpdateToDraft.clear();
                        }
                    
                    }*/
                   
                    Map<Id,blng__CreditNote__c> duplicatecreditnotemap=new Map<Id,blng__CreditNote__c>();
                    // Check and Add Creditnoteid having duplicate custom Creditnotenumber in existing Creditnote
                    // Altered query as part of epic - 2980 removed Id condition
                    for (blng__CreditNote__c crdtNote: [select id,QTB_Credit_Note_Type__c, blng__Account__r.QTB_Legal_Entity_Country__c, QTB_Custom_Invoice_Number__c
                    from blng__CreditNote__c where blng__Status__c = 'Posted'
                    and QTB_Custom_Invoice_Number__c in: mapCustmCrdtNoCrdtId.KeySet()
                    and blng__Account__r.QTB_Legal_Entity_Country__c in :setCountry order by Createddate ASC
                    ]) {
                        if (mapCustmCrdtNoCrdtId.containsKey(crdtNote.QTB_Custom_Invoice_Number__c)) {
                        //duplicatecustCrdtId.add(mapCustmCrdtNoCrdtId.get(crdtNote.QTB_Custom_Invoice_Number__c)); //commented as part of epic-2980
                        duplicatecustCrdtId.add(crdtNote.Id); //added as part of epic-2980
                        }
                    }
                    
                    //Querying the Account record
                    Account acc = [Select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                                          QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,
                                          QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c 
                                          FROM Account WHERE ID in :accId];
                    Map<Id,blng__CreditNote__c> duplicateMapCreditNote = new Map<Id,blng__CreditNote__c>();
                    //Fetch the Creditnoterecord with required fields to assing new custom Creditnotenumber
                    if (!duplicatecustCrdtId.isEmpty() && duplicatecustCrdtId.size()>1) {
                        for (blng__CreditNote__c crdtNote: [select id,blng__CreditNote__c.QTB_Custom_Invoice_Number__c, name,QTB_Credit_Note_Type__c, blng__Account__c, blng__Account__r.QTB_Customer_Number__c, blng__Account__r.QTB_Contract_Entity__c, 
                        blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c, blng__Account__r.QTB_Market__r.QTB_State__c, blng__Account__r.QTB_Contract_Entity__r.blng__Country__c from 
                        blng__CreditNote__c where id In: duplicatecustCrdtId order by QTB_Custom_Invoice_Number__c ASC
                        ]) 
                        {
                            duplicateMapCreditNote.put(crdtNote.Id,crdtNote); // added as part of epic - 2980
                            // Calling QTB_CreditNoteIDGeneration class to assign new custom Creditnotenumber to duplicate ones
                            //QTB_CreditNoteIDGeneration.updateCreditNoteID(crdtNote,acc);
                            //lstUpdatedCrdtList.add(crdtNote);  
                            //stUpdatedCrdtList = mapcrdtNoteCstmSetngForCustmcrdtNoteNo.keySet();
                            //lstUpdatedCrdtList.addAll(stUpdatedCrdtList);                            
                            //lstUpdatedCrdtList=new List<blng__CreditNote__c>(mapcrdtNoteCstmSetngForCustmcrdtNoteNo.keySet());
                            //lstCustmStngCustmCrdtNo.add(mapcrdtNoteCstmSetngForCustmcrdtNoteNo.Values());
                        }
                        //Added below if condition as part of epic - 2980
                       if(duplicateMapCreditNote!=null){
                            blng__CreditNote__c newCred =new blng__CreditNote__c();
                            QTB_CreditNoteIDGeneration.updateCreditNoteID(newCred,acc,duplicateMapCreditNote);
                        }
                    }
                    // Update invoices having duplicate custom Creditnotenumber
                  if (!lstUpdatedCrdtList.isEmpty()) {
                    SBQQ.TriggerControl.disable();
                    update lstUpdatedCrdtList;
                    update lstCustmStngCustmCrdtNo;
                    SBQQ.TriggerControl.enable();
                    stUpdatedCrdtList.clear();
                    lstUpdatedCrdtList.clear();
                    lstCustmStngCustmCrdtNo.clear();
                    duplicatecustCrdtId.clear();
                  } 
            }

        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000) {
                errorIds = errorIds.substring(0, 100000);
            }
            QTB_ExceptionLogger.createLog(
            e.getLineNumber(),
            e.getStackTraceString(),
            errorIds, e.getTypeName(),
            CLASSNAME);
        }
    }
    /*********************************************************************************************************
    Method Name: finish
    Parameters: Database.BatchableContext
    Return Type: void
    **********************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
    //Updating the status for those Duplicate creditnote to Error and Ready for integration as False
        try {
            if (QTB_CRDN_Ready_for_integration_Batch.throwExplicitException) {
            throw new NullPointerException();
            }
            if (crdtIdLst != null && !crdtIdLst.isEmpty()) {
                //Calling of another batch with 5 mins delay
                Datetime dt1 = Datetime.now();
                Datetime dt = dt1.addminutes(5);
                Integer seconds = dt.second();
                Integer minutes = dt.minute();
                Integer hours = dt.hour();
                Integer dayOfMonth = dt.day();
                Integer month = dt.month();
                Integer year = dt.year();
                // Constructing the cron expression
                String cronExpression = seconds + ' ' + minutes + ' ' + hours + ' ' +
                dayOfMonth + ' ' + month + ' ? ' + year;
                //Scheduler that calls the new batch for Posting the Draft lines 
                crdtIdFinalLst.addAll(crdtIdLst);
                List<CronTrigger> jobRecords = new List<CronTrigger>(); //Epic 2999 hypercare2
                Id firstId =  crdtIdFinalLst[0];
                String jobName = 'ReadyForSuccessErrorIntgeration_'+ firstId; //Epic 2999 hypercare2
                QTB_CRDN_ReadyForInt_SuccError_Scheduler b1 = new QTB_CRDN_ReadyForInt_SuccError_Scheduler(crdtIdLst);
                //Querying the existing scheduled jobs ////Epic 2999 hypercare2
                jobRecords = [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, CronExpression, NextFireTime, State
                                                FROM CronTrigger where CronJobDetail.Name LIKE :jobName + '%' and State IN('WAITING','ACQUIRED','EXECUTING')];
                if(jobRecords.isEmpty())
                {
                    System.schedule(jobName+' '+cronExpression,cronExpression,b1);
                    
                }     
                //Epic 2999 hypercare2 closing
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
            e.getLineNumber(),
            e.getStackTraceString(),
            e.getMessage(),
            e.getTypeName(),
            CLASSNAME);
            
            if(e.getMessage().contains('is already scheduled for execution')){
				updateCreditNoteStatusAsError(crdtIdLst);                
            }
        }
    }
    //Credit Note - Ready For Integration changes 
    //Added by Yogesh Sharma
    public static void updateCreditNoteStatusAsError(Set<Id> creditNoteIdSet){
        List<blng__CreditNoteLine__c> creditNoteLineList = [SELECT Id, blng__Status__c FROM blng__CreditNoteLine__c Where blng__CreditNote__c IN : creditNoteIdSet AND blng__Status__c != 'Draft'];
        List<blng__CreditNoteLine__c> creditNoteLineListToUpdate = new List<blng__CreditNoteLine__c>();
        List<blng__CreditNote__c> creditNoteListToUpdate = new List<blng__CreditNote__c>();
        
        //Updating all related creditNoteLines Status as Draft
        for(blng__CreditNoteLine__c cnlObj : creditNoteLineList){
			cnlObj.blng__Status__c = 'Draft';
	        creditNoteLineListToUpdate.add(cnlObj);
        }
        if(!creditNoteLineListToUpdate.isEmpty()){
            SBQQ.TriggerControl.disable();
            update creditNoteLineListToUpdate;
            SBQQ.TriggerControl.Enable();                
        } 
        
        //Updating the CreditNote Status as Error 
        for(Id creditNoteId : creditNoteIdSet){   
            blng__CreditNote__c creditNoteObj = new blng__CreditNote__c();
            creditNoteObj.Id= creditNoteId;
            creditNoteObj.blng__Status__c ='Error';
            creditNoteObj.QTB_Ready_for_Integration_Status__c = 'Ready for integration batch has been already scheduled. please retry after sometime.';
            creditNoteListToUpdate.add(creditNoteObj);
        }
        if(!creditNoteListToUpdate.isEmpty()){
            SBQQ.TriggerControl.disable();
            update creditNoteListToUpdate;
            SBQQ.TriggerControl.Enable();                
        }
    }
}
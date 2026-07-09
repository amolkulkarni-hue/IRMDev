/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*   QTB-44a
*   Batch class containing logic for pasting Custom Invoice Id when credit is posted
*
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture; Virtusa
* @Created       : 5/04/2020
* @Modified      : 5/08/2020; 4/18/2023
Modified      : GIT # 15023 changes made in order to generate credit note number based on accounts market state 
instead of billing state
Last Modified - Manila ON 17-07-2023 // Change for Story 2980
* ──────────────────────────────────────────────────────────────────────────────────────────────────
*/
public class QTB_CreditNoteIDGeneration {
    //Initialize static variables from constants utils
    //Remove - Initialize static variables from constants utils
    public static Final String DRAFT = QTB_Constants.INVOICE_STATUS_DRAFT;
    public static Final String POSTED = QTB_Constants.INVOICE_STATUS_POSTED;
    public static Final String SWEDEN = QTB_Constants.INVOICE_COUNTRY_SWEDEN;
    public static Final String SWEDEN_CREDIT = QTB_Constants.CREDIT_COUNTRY_SWEDEN;
    public static Final String FINLAND = QTB_Constants.INVOICE_COUNTRY_FINLAND;
    public static Final String FINLAND_CREDIT = QTB_Constants.CREDIT_COUNTRY_FINLAND;
    public static Final String DENMARK = QTB_Constants.INVOICE_COUNTRY_DENMARK;
    public static Final String DENMARK_CREDIT = QTB_Constants.CREDIT_COUNTRY_DENMARK;
    public static Final String NORWAY = QTB_Constants.INVOICE_COUNTRY_NORWAY;
    public static Final String NORWAY_CREDIT = QTB_Constants.CREDIT_COUNTRY_NORWAY;
    public static Final String INDIA = QTB_Constants.INVOICE_COUNTRY_INDIA;
    public static Final String INDIA_CREDIT = QTB_Constants.CREDIT_COUNTRY_INDIA;
    public static Final String TAIWAN = QTB_Constants.INVOICE_COUNTRY_TAIWAN;
    public static Final String TAIWAN_CREDIT = QTB_Constants.CREDIT_COUNTRY_TAIWAN;
    public static Final String THAILAND = QTB_Constants.INVOICE_COUNTRY_THAILAND;
    public static Final String THAILAND_CREDIT = QTB_Constants.CREDIT_COUNTRY_THAILAND;
    public static Final String MALAYSIA = QTB_Constants.INVOICE_COUNTRY_MALAYSIA;
    public static Final String MALAYSIA_CREDIT = QTB_Constants.CREDIT_COUNTRY_MALAYSIA;
    public static Final String HONGKONG = QTB_Constants.INVOICE_COUNTRY_HONGKONG;
    public static Final String HONGKONG_CREDIT = QTB_Constants.CREDIT_COUNTRY_HONGKONG;
    public static Final String SINGAPORE = QTB_Constants.INVOICE_COUNTRY_SINGAPORE;
    public static Final String SINGAPORE_CREDIT = QTB_Constants.CREDIT_COUNTRY_SINGAPORE;
    //#23288 Added as part of Cluster 2 (FRA,BEL,NLD)
    public static Final String FRANCE = QTB_Constants.INVOICE_COUNTRY_FRANCE;
    public static Final String FRANCE_CREDIT = QTB_Constants.CREDIT_COUNTRY_FRANCE;
    public static Final String BELGIUM = QTB_Constants.INVOICE_COUNTRY_BELGIUM;
    public static Final String BELGIUM_CREDIT = QTB_Constants.CREDIT_COUNTRY_BELGIUM;
    public static Final String NETHERLANDS = QTB_Constants.INVOICE_COUNTRY_NETHERLANDS;
    public static Final String NETHERLANDS_CREDIT = QTB_Constants.CREDIT_COUNTRY_NETHERLANDS;
    //Added as part of Cluster 3 countries
    public static Final String ROMANIA = QTB_Constants.INVOICE_COUNTRY_ROMANIA;
    public static Final String ROMANIA_CREDIT = QTB_Constants.CREDIT_COUNTRY_ROMANIA;
    public static Final String SLOVAKIA = QTB_Constants.INVOICE_COUNTRY_SLOVAKIA;
    public static Final String SLOVAKIA_CREDIT = QTB_Constants.CREDIT_COUNTRY_SLOVAKIA;
    public static Final String GREECE = QTB_Constants.INVOICE_COUNTRY_GREECE;
    public static Final String GREECE_CREDIT = QTB_Constants.CREDIT_COUNTRY_GREECE;
    public static Final String CZECHREPUBLIC = QTB_Constants.INVOICE_COUNTRY_CZECH_REPUBLIC;
    public static Final String CZECHREPUBLIC_CREDIT = QTB_Constants.CREDIT_COUNTRY_CZECH_REPUBLIC;
    public static Final String AUSTRIA = QTB_Constants.INVOICE_COUNTRY_AUSTRIA;
    public static Final String AUSTRIA_CREDIT = QTB_Constants.CREDIT_COUNTRY_AUSTRIA;
    public static Final String SPAIN = QTB_Constants.INVOICE_COUNTRY_SPAIN;
    public static Final String SPAIN_CREDIT = QTB_Constants.CREDIT_COUNTRY_SPAIN;
public static Final String GERMANY = QTB_Constants.INVOICE_COUNTRY_GERMANY;
public static Final String GERMANY_CREDIT = QTB_Constants.CREDIT_COUNTRY_GERMANY;
    //Gitlab #27336 - Added for UK & Ireland
    public static Final String UNITEDKINGDOM = QTB_Constants.INVOICE_COUNTRY_UNITEDKINGDOM;
    public static Final String UNITEDKINGDOM_CREDIT = QTB_Constants.CREDIT_COUNTRY_UNITEDKINGDOM;
    public static Final String IRELAND = QTB_Constants.INVOICE_COUNTRY_IRELAND;
    public static Final String IRELAND_CREDIT = QTB_Constants.CREDIT_COUNTRY_IRELAND;
    //#30973 #31259 Cluster 4 countries Turkey, New Zealand,Australia
    //#34738 Commeneted below turkey Assignments
    //public static Final String TURKEY = QTB_Constants.INVOICE_COUNTRY_TURKEY;
    //public static Final String TURKEY_CREDIT = QTB_Constants.CREDIT_COUNTRY_TURKEY;
    public static Final String AUSTRALIA = QTB_Constants.INVOICE_COUNTRY_AUSTRALIA;
    public static Final String AUSTRALIA_CREDIT = QTB_Constants.CREDIT_COUNTRY_AUSTRALIA;
    public static Final String NEWZEALAND = QTB_Constants.INVOICE_COUNTRY_NEW_ZEALAND;
    public static Final String NEWZEALAND_CREDIT = QTB_Constants.CREDIT_COUNTRY_NEW_ZEALAND;
    //Gitlab #27336 - End
    public static boolean throwExplicitException = false;   
    // Find duplicate creditnote id to capture the ids in set 
    public static Set<Id> postedIds;
    public static void processCreditNote( List<blng__CreditNote__c> PostedCreditNotes,set<ID> AccountID)
    {
        try{
            if(throwExplicitException){
                throw new NullPointerException();
            }
            //#30973 #31259 Cluster 4 Custom Inv numbering Turkey Quiered QTB_Invoice_Delivery_Options__c
            Map<ID,Account> mapOfAccount= new Map<ID,Account>([select id,name,QTB_Contract_Entity__c,QTB_Customer_Number__c,BillingState,BillingCountry,QTB_Legal_Entity_Country__c,
                                                               QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Contract_Entity__r.blng__Country__c,QTB_Market__r.QTB_State__c,QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c,QTB_Invoice_Delivery_Options__c from Account where
                                                               id in :AccountID]);
            system.debug('>>mapOfAccount'+mapOfAccount);
            postedIds=new set<id>();
            for(blng__CreditNote__c eachCreditNote : PostedCreditNotes){
                postedIds.add(eachCreditNote.id);
                updateCreditNoteID(eachCreditNote,mapOfAccount.get(eachCreditNote.blng__Account__c),null);//added extra parameter as part of epic -2980
                System.debug('>>updateCreditNoteID'+eachCreditNote);
            }
            
        }
        catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), QTB_CreditNoteIDGeneration.class.getName());
            throw e;
        }
    }
    
    public static void updateCreditNoteID (blng__CreditNote__c infoPostedCreditNote, Account billTo, Map<Id,blng__CreditNote__c> duplicateMapCreditNote)
    {
        List<blng__CreditNote__c> crNote = new List<blng__CreditNote__c>();
        try{
            if(throwExplicitException){
                throw new NullPointerException();
            }         
            //#25889 Added map key as name of Custom setting value and value as Custom Setting Number data
            Map<String, QTB_CustomInvoiceNumber__c> lastCreditNoteNumMap = QTB_CustomInvoiceNumber__c.getAll();
            //#25889 Created Map as key as CustomSetting's Name and Value as Custom Setting Sequence Number
            Map<String,String> invSettingLastNumberMap=new map<String,String>();
            //#25889 Created List for Updating the CustomSettings's Sequence NUmber value after adding plus 1 to existing Custom Setting's Seq Number
            List<QTB_CustomInvoiceNumber__c> invCustomSettToUpdate=new List<QTB_CustomInvoiceNumber__c>();
            List<blng__CreditNote__c> creditNoteToUpdate=new List<blng__CreditNote__c>();
            //Custom creditnote logic for each record based on billing country from Account
            if(billTo.QTB_Contract_Entity__r.blng__Country__c != NULL)
            {
                String blngCountry =billTo.QTB_Contract_Entity__r.blng__Country__c; 
                
                switch on blngCountry.toLowerCase()
                {
                    //#23288 Added as part of Cluster 2 (FRA,BEL,NLD)
                    WHEN 'france' {
                        // Creating one Long Number to Store the Sequence Number of each country
                        Long franceLastNumber =0; 
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(FRANCE) && lastCreditNoteNumMap != null)
                        {
                            //getting the Seq Number from Map to store the Last Seq Number
                            franceLastNumber=Long.valueOf(lastCreditNoteNumMap.get(FRANCE).QTB_Next_Sequence_Number__c);
                            franceLastNumber =franceLastNumber+1;
                            //Assigning respective values based upon Requirement
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.FRANCE_PREFIX +String.valueOf(franceLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.FRANCE_PREFIX +String.valueOf(franceLastNumber);
                            //Adding the Sequence Number plus 1 to update the Cjustom Setting record of that Particular Country
                            
                            //checking whether the Seq Number Updated or not and adding to Map to update the Sequence Number of respective country
                            if(lastCreditNoteNumMap.get(FRANCE).QTB_Next_Sequence_Number__c != String.valueOf(franceLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(FRANCE);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(franceLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(FRANCE_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(FRANCE_CREDIT);
                            franceLastNumber=Long.valueOf(lastCreditNoteNumMap.get(FRANCE_CREDIT).QTB_Next_Sequence_Number__c);
                            if(postedIds != null) // added if condition as part of epic - 2980
                            {
                                franceLastNumber =franceLastNumber+1;
                                //Assigning respective values based upon Requirement
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.FRANCE_CREDIT_PREFIX +String.valueOf(franceLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.FRANCE_CREDIT_PREFIX +String.valueOf(franceLastNumber);
                                
                                //checking whether the Seq Number Updated or not and adding to Map to update the Sequence Number of respective country
                                if(lastCreditNoteNumMap.get(FRANCE_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(franceLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(franceLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                            
                            else{
                                String tempVal = QTB_Constants.FRANCE_CREDIT_PREFIX +String.valueOf(franceLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                         if(i==0){
                                            franceLastNumber =franceLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.FRANCE_CREDIT_PREFIX +String.valueOf(franceLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.FRANCE_CREDIT_PREFIX +String.valueOf(franceLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(franceLastNumber);
                                            franceLastNumber =franceLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                }
                            }
                           invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        }
                    }
                    WHEN 'belgium' {
                        Long belgiumLastNumber =0; 
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(BELGIUM) && lastCreditNoteNumMap != null)
                        {
                            belgiumLastNumber=Long.valueOf(lastCreditNoteNumMap.get(BELGIUM).QTB_Next_Sequence_Number__c);
                            belgiumLastNumber =belgiumLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.BELGIUM_PREFIX +String.valueOf(belgiumLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.BELGIUM_PREFIX +String.valueOf(belgiumLastNumber);
                            if(lastCreditNoteNumMap.get(BELGIUM).QTB_Next_Sequence_Number__c != String.valueOf(belgiumLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(BELGIUM);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(belgiumLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(BELGIUM_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(BELGIUM_CREDIT);
                            belgiumLastNumber=Long.valueOf(lastCreditNoteNumMap.get(BELGIUM_CREDIT).QTB_Next_Sequence_Number__c);
                                     
                            if(postedIds != null)
                            {
                                belgiumLastNumber =belgiumLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.BELGIUM_CREDIT_PREFIX +String.valueOf(belgiumLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.BELGIUM_CREDIT_PREFIX +String.valueOf(belgiumLastNumber);
                                if(lastCreditNoteNumMap.get(BELGIUM_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(belgiumLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(belgiumLastNumber);
                                }
                            }
                            else{
                                String tempVal = QTB_Constants.BELGIUM_CREDIT_PREFIX +String.valueOf(belgiumLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            belgiumLastNumber =belgiumLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal !=null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.BELGIUM_CREDIT_PREFIX +String.valueOf(belgiumLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.BELGIUM_CREDIT_PREFIX +String.valueOf(belgiumLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(belgiumLastNumber);
                                            belgiumLastNumber =belgiumLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                    
                                }
                            }
                            system.debug('invSettingLastNumberMap ' +invSettingLastNumberMap);
                            invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        }
                    }
                    WHEN 'netherlands' {
                        Long netherlandsLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(NETHERLANDS) && lastCreditNoteNumMap != null)
                        {
                            netherlandsLastNumber=Long.valueOf(lastCreditNoteNumMap.get(NETHERLANDS).QTB_Next_Sequence_Number__c);
                            netherlandsLastNumber =netherlandsLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.NETHERLANDS_PREFIX +String.valueOf(netherlandsLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.NETHERLANDS_PREFIX +String.valueOf(netherlandsLastNumber);
                            
                            if(lastCreditNoteNumMap.get(NETHERLANDS).QTB_Next_Sequence_Number__c != String.valueOf(netherlandsLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(NETHERLANDS);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(netherlandsLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(NETHERLANDS_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(NETHERLANDS_CREDIT);
                            netherlandsLastNumber=Long.valueOf(lastCreditNoteNumMap.get(NETHERLANDS_CREDIT).QTB_Next_Sequence_Number__c);
                                        
                            if(postedIds != null)
                            {
                                netherlandsLastNumber =netherlandsLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.NETHERLANDS_CREDIT_PREFIX +String.valueOf(netherlandsLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.NETHERLANDS_CREDIT_PREFIX +String.valueOf(netherlandsLastNumber);
                               
                                if(lastCreditNoteNumMap.get(NETHERLANDS_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(netherlandsLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(netherlandsLastNumber);
                                }
                            }
                            else{
                                String tempVal = QTB_Constants.NETHERLANDS_CREDIT_PREFIX +String.valueOf(netherlandsLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                   for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            netherlandsLastNumber =netherlandsLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.NETHERLANDS_CREDIT_PREFIX +String.valueOf(netherlandsLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c =QTB_Constants.NETHERLANDS_CREDIT_PREFIX +String.valueOf(netherlandsLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(netherlandsLastNumber);
                                            netherlandsLastNumber =netherlandsLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                }
                            }
                           invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        }
                        
                    }
                    //Gitlab #27336 - Added for UK & Ireland to update Custom Invoice Number
                    WHEN 'united kingdom' {
                        Long unitedkingdomLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(UNITEDKINGDOM) && lastCreditNoteNumMap != null)
                        {
                            unitedkingdomLastNumber=Long.valueOf(lastCreditNoteNumMap.get(UNITEDKINGDOM).QTB_Next_Sequence_Number__c);
                            unitedkingdomLastNumber =unitedkingdomLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.UNITEDKINGDOM_PREFIX +String.valueOf(unitedkingdomLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.UNITEDKINGDOM_PREFIX +String.valueOf(unitedkingdomLastNumber);
                            
                            if(lastCreditNoteNumMap.get(UNITEDKINGDOM).QTB_Next_Sequence_Number__c != String.valueOf(unitedkingdomLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(UNITEDKINGDOM);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(unitedkingdomLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(UNITEDKINGDOM_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(UNITEDKINGDOM_CREDIT);
                            unitedkingdomLastNumber=Long.valueOf(lastCreditNoteNumMap.get(UNITEDKINGDOM_CREDIT).QTB_Next_Sequence_Number__c);
                            if(postedIds != null)
                            {
                                unitedkingdomLastNumber =unitedkingdomLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.UNITEDKINGDOM_CREDIT_PREFIX +String.valueOf(unitedkingdomLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.UNITEDKINGDOM_CREDIT_PREFIX +String.valueOf(unitedkingdomLastNumber);
                                if(lastCreditNoteNumMap.get(UNITEDKINGDOM_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(unitedkingdomLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(unitedkingdomLastNumber);
                                }
                            }
                            else{
                                String tempVal = QTB_Constants.UNITEDKINGDOM_CREDIT_PREFIX +String.valueOf(unitedkingdomLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            unitedkingdomLastNumber =unitedkingdomLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.UNITEDKINGDOM_CREDIT_PREFIX +String.valueOf(unitedkingdomLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.UNITEDKINGDOM_CREDIT_PREFIX +String.valueOf(unitedkingdomLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(unitedkingdomLastNumber);
                                            unitedkingdomLastNumber =unitedkingdomLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                }
                            }
                         invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        }
                    }
                    WHEN 'ireland' {
                        Long irelandLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(IRELAND) && lastCreditNoteNumMap != null)
                        {
                            irelandLastNumber=Long.valueOf(lastCreditNoteNumMap.get(IRELAND).QTB_Next_Sequence_Number__c);
                            irelandLastNumber =irelandLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.IRELAND_PREFIX +String.valueOf(irelandLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.IRELAND_PREFIX +String.valueOf(irelandLastNumber);
                            
                            if(lastCreditNoteNumMap.get(IRELAND).QTB_Next_Sequence_Number__c != String.valueOf(irelandLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(IRELAND);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(irelandLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(IRELAND_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(IRELAND_CREDIT);
                            irelandLastNumber=Long.valueOf(lastCreditNoteNumMap.get(IRELAND_CREDIT).QTB_Next_Sequence_Number__c);
                            if(postedIds != null)
                            {
                                irelandLastNumber =irelandLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.IRELAND_CREDIT_PREFIX +String.valueOf(irelandLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.IRELAND_CREDIT_PREFIX +String.valueOf(irelandLastNumber);
                                if(lastCreditNoteNumMap.get(IRELAND_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(irelandLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(irelandLastNumber);
                                }
                            }
                            else{
                                String tempVal = QTB_Constants.IRELAND_CREDIT_PREFIX +String.valueOf(irelandLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            irelandLastNumber =irelandLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.IRELAND_CREDIT_PREFIX +String.valueOf(irelandLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c =QTB_Constants.IRELAND_CREDIT_PREFIX +String.valueOf(irelandLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(irelandLastNumber);
                                            irelandLastNumber =irelandLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                               }
                            }
                           invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        }
                    }
                    //Gitlab #27336 - End
                    //Added as part of Cluster 3 countries
                    WHEN 'romania' {
                        Long romaniaLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(ROMANIA) && lastCreditNoteNumMap != null)
                        {
                            romaniaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(ROMANIA).QTB_Next_Sequence_Number__c);
                            romaniaLastNumber =romaniaLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.ROMANIA_PREFIX +String.valueOf(romaniaLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.ROMANIA_PREFIX +String.valueOf(romaniaLastNumber);
                            
                            if(lastCreditNoteNumMap.get(ROMANIA).QTB_Next_Sequence_Number__c != String.valueOf(romaniaLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(ROMANIA);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(romaniaLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(ROMANIA_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(ROMANIA_CREDIT);
                            romaniaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(ROMANIA_CREDIT).QTB_Next_Sequence_Number__c);
                            if(postedIds != null)
                            {   
                                romaniaLastNumber =romaniaLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.ROMANIA_CREDIT_PREFIX +String.valueOf(romaniaLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.ROMANIA_CREDIT_PREFIX +String.valueOf(romaniaLastNumber);
                                if(lastCreditNoteNumMap.get(ROMANIA_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(romaniaLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(romaniaLastNumber);
                                }
                            }
                            else{
                                String tempVal = QTB_Constants.ROMANIA_CREDIT_PREFIX +String.valueOf(romaniaLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            romaniaLastNumber =romaniaLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.ROMANIA_CREDIT_PREFIX +String.valueOf(romaniaLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.ROMANIA_CREDIT_PREFIX +String.valueOf(romaniaLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(romaniaLastNumber);
                                            romaniaLastNumber =romaniaLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                               }
                            }
                           invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        }
                    }
                    WHEN 'slovakia' {
                        Long slovakiaLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(SLOVAKIA) && lastCreditNoteNumMap != null)
                        {
                            slovakiaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(SLOVAKIA).QTB_Next_Sequence_Number__c);
                            slovakiaLastNumber =slovakiaLastNumber+1;
                            //#28513 As per the requirement for Slovakia there should be no prefix as per like other countries, so removing Prefix
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= String.valueOf(slovakiaLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = String.valueOf(slovakiaLastNumber);
                            
                            if(lastCreditNoteNumMap.get(SLOVAKIA).QTB_Next_Sequence_Number__c != String.valueOf(slovakiaLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(SLOVAKIA);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(slovakiaLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(SLOVAKIA_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(SLOVAKIA_CREDIT);
                            slovakiaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(SLOVAKIA_CREDIT).QTB_Next_Sequence_Number__c);
                            if(postedIds != null)
                            {       
                                slovakiaLastNumber =slovakiaLastNumber+1;
                                //#28513 As per the requirement for Slovakia there should be no prefix as per like other countries, so removing Prefix
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= String.valueOf(slovakiaLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = String.valueOf(slovakiaLastNumber);
                                if(lastCreditNoteNumMap.get(SLOVAKIA_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(slovakiaLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(slovakiaLastNumber);
                                }
                            }
                            else{
                                String tempVal = String.valueOf(slovakiaLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                   for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            slovakiaLastNumber =slovakiaLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = String.valueOf(slovakiaLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = String.valueOf(slovakiaLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(slovakiaLastNumber);
                                            slovakiaLastNumber =slovakiaLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                 }
                            }
                           invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        }
                    }
                    WHEN 'greece' {
                        Long greeceLastNumber =0; 
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(GREECE) && lastCreditNoteNumMap != null)
                        {
                            greeceLastNumber=Long.valueOf(lastCreditNoteNumMap.get(GREECE).QTB_Next_Sequence_Number__c);
                            greeceLastNumber =greeceLastNumber+1;
                            //#28513 As per the requirement for Greece there should be no prefix as per like other countries, so removing Prefix
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= String.valueOf(greeceLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = String.valueOf(greeceLastNumber);
                            
                            if(lastCreditNoteNumMap.get(GREECE).QTB_Next_Sequence_Number__c != String.valueOf(greeceLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(GREECE);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(greeceLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(GREECE_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(GREECE_CREDIT);
                            greeceLastNumber=Long.valueOf(lastCreditNoteNumMap.get(GREECE_CREDIT).QTB_Next_Sequence_Number__c);
                            if(postedIds != null)
                            {   
                                greeceLastNumber =greeceLastNumber+1;
                                //#28513 As per the requirement for Greece there should be no prefix as per like other countries, so removing Prefix 
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= String.valueOf(greeceLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = String.valueOf(greeceLastNumber);
                                
                                if(lastCreditNoteNumMap.get(GREECE_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(greeceLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(greeceLastNumber);
                                }
                            }
                            else{
                                String tempVal = String.valueOf(greeceLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i =0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            greeceLastNumber =greeceLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = String.valueOf(greeceLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = String.valueOf(greeceLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(greeceLastNumber);
                                            greeceLastNumber =greeceLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                }
                            }
                          invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        }
                    }
                    WHEN 'czech republic' {
                        system.debug('Inside czech republic country');
                        Long czechRepublicLastNumber =0; 
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(CZECHREPUBLIC) && lastCreditNoteNumMap != null)
                        {
                            czechRepublicLastNumber=Long.valueOf(lastCreditNoteNumMap.get(CZECHREPUBLIC).QTB_Next_Sequence_Number__c);
                            czechRepublicLastNumber =czechRepublicLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.CZECH_REPUBLIC_PREFIX +String.valueOf(czechRepublicLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.CZECH_REPUBLIC_PREFIX +String.valueOf(czechRepublicLastNumber);
                            if(lastCreditNoteNumMap.get(CZECHREPUBLIC).QTB_Next_Sequence_Number__c != String.valueOf(czechRepublicLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(CZECHREPUBLIC);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(czechRepublicLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(CZECHREPUBLIC_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(CZECHREPUBLIC_CREDIT);
                            czechRepublicLastNumber=Long.valueOf(lastCreditNoteNumMap.get(CZECHREPUBLIC_CREDIT).QTB_Next_Sequence_Number__c);
                            if(postedIds != null)
                            { 
                                czechRepublicLastNumber =czechRepublicLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.CZECH_REPUBLIC_CREDIT_PREFIX +String.valueOf(czechRepublicLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.CZECH_REPUBLIC_CREDIT_PREFIX +String.valueOf(czechRepublicLastNumber);
                                
                                if(lastCreditNoteNumMap.get(CZECHREPUBLIC_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(czechRepublicLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(czechRepublicLastNumber);
                                }
                            }
                            else{
                                String tempVal = QTB_Constants.CZECH_REPUBLIC_CREDIT_PREFIX +String.valueOf(czechRepublicLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            czechRepublicLastNumber =czechRepublicLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.CZECH_REPUBLIC_CREDIT_PREFIX +String.valueOf(czechRepublicLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.CZECH_REPUBLIC_CREDIT_PREFIX +String.valueOf(czechRepublicLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(czechRepublicLastNumber);
                                            czechRepublicLastNumber =czechRepublicLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                }
                            }
                          invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        }
                    }
                    WHEN 'hungary' {
                        Long hungaryLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false){
                            //#28025 Created Key for Country;LegalEntitynumber combo to generate seq no based upon legal Entity wise
                            String key= billTo.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+String.valueOf(billTo.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c);
                            if(lastCreditNoteNumMap.ContainsKey(key) && lastCreditNoteNumMap != null)
                            {
                                hungaryLastNumber=Long.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                hungaryLastNumber =hungaryLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.HUNGARY_PREFIX +String.valueOf(hungaryLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.HUNGARY_PREFIX +String.valueOf(hungaryLastNumber);
                                
                                if(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c != String.valueOf(hungaryLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(key);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(hungaryLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True) {
                            //#28025 Created Key for Country;LegalEntitynumber;credit combo to generate seq no based upon legal Entity wise
                            String key= billTo.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+String.valueOf(billTo.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c)+';'+'credit';
                            if(lastCreditNoteNumMap.ContainsKey(key) && lastCreditNoteNumMap != null)
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(key);
                                hungaryLastNumber=Long.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                    
                                if(postedIds != null)
                                { 
                                    hungaryLastNumber =hungaryLastNumber+1;
                                    infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.HUNGARY_CREDIT_PREFIX +String.valueOf(hungaryLastNumber);
                                    infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.HUNGARY_CREDIT_PREFIX +String.valueOf(hungaryLastNumber);
                                    system.debug('hungaryLastNumber:'+hungaryLastNumber);
                                    if(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c != String.valueOf(hungaryLastNumber))
                                    {
                                        lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(hungaryLastNumber);
                                    }
                                }
                                else{
                                    String tempVal = QTB_Constants.HUNGARY_CREDIT_PREFIX +String.valueOf(hungaryLastNumber);
                                    if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                    {
                                        Integer i=0;
                                        for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                        {
                                            if(i==0){
                                                hungaryLastNumber =hungaryLastNumber+1;
                                                i++;
                                            }
                                            else if(tempVal != null || Test.isRunningTest()){
                                                cred.QTB_Custom_Invoice_Number__c = QTB_Constants.HUNGARY_CREDIT_PREFIX +String.valueOf(hungaryLastNumber);
                                                cred.QTB_Custom_Invoice_ID__c = QTB_Constants.HUNGARY_CREDIT_PREFIX +String.valueOf(hungaryLastNumber);
                                                lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(hungaryLastNumber);
                                                hungaryLastNumber =hungaryLastNumber+1;
                                                creditNoteToUpdate.add(cred);
                                            }
                                        }
                                    }
                                }
                              invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                    }
                    WHEN 'spain' {
                        Long spainLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(SPAIN) && lastCreditNoteNumMap != null)
                        {
                            spainLastNumber=Long.valueOf(lastCreditNoteNumMap.get(SPAIN).QTB_Next_Sequence_Number__c);
                            spainLastNumber =spainLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.SPAIN_PREFIX_INVOICE +String.valueOf(spainLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.SPAIN_PREFIX_INVOICE +String.valueOf(spainLastNumber);
                            
                            if(lastCreditNoteNumMap.get(SPAIN).QTB_Next_Sequence_Number__c != String.valueOf(spainLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(SPAIN);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(spainLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(SPAIN_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(SPAIN_CREDIT);
                                spainLastNumber=Long.valueOf(lastCreditNoteNumMap.get(SPAIN_CREDIT).QTB_Next_Sequence_Number__c);
                                
                            if(postedIds != null)
                            { 
                                spainLastNumber =spainLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.SPAIN_PREFIX_CREDIT_NOTE +String.valueOf(spainLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.SPAIN_PREFIX_CREDIT_NOTE +String.valueOf(spainLastNumber);
                                if(lastCreditNoteNumMap.get(SPAIN_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(spainLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(spainLastNumber);
                                }
                            }
                            else{
                                String tempVal =String.valueOf(spainLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            spainLastNumber =spainLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.SPAIN_PREFIX_CREDIT_NOTE +String.valueOf(spainLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c =QTB_Constants.SPAIN_PREFIX_CREDIT_NOTE +String.valueOf(spainLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(spainLastNumber);
                                            spainLastNumber =spainLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                }
                            }
                           invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                         }
                    }
                    WHEN 'austria' {
                        Long austriaLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(AUSTRIA) && lastCreditNoteNumMap != null)
                        {
                            austriaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(AUSTRIA).QTB_Next_Sequence_Number__c);
                            austriaLastNumber =austriaLastNumber+1;// Change for Story 2980
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.AUSTRIA_PREFIX +String.valueOf(austriaLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.AUSTRIA_PREFIX +String.valueOf(austriaLastNumber);
                            
                            if(lastCreditNoteNumMap.get(AUSTRIA).QTB_Next_Sequence_Number__c != String.valueOf(austriaLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(AUSTRIA);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(austriaLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(AUSTRIA_CREDIT) && lastCreditNoteNumMap != null)
                        {   
                            // Change for Story 2980 - Start - AUSTRIA
                            if(postedIds != null){
                                austriaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(AUSTRIA_CREDIT).QTB_Next_Sequence_Number__c);
                                austriaLastNumber =austriaLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.AUSTRIA_CREDIT_PREFIX +String.valueOf(austriaLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.AUSTRIA_CREDIT_PREFIX +String.valueOf(austriaLastNumber);
                                if(lastCreditNoteNumMap.get(AUSTRIA_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(austriaLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(AUSTRIA_CREDIT);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(austriaLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                            
                            else{
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(AUSTRIA_CREDIT);
                                austriaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(AUSTRIA_CREDIT).QTB_Next_Sequence_Number__c);
                                String tempVal = QTB_Constants.AUSTRIA_CREDIT_PREFIX +String.valueOf(austriaLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            austriaLastNumber =austriaLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.AUSTRIA_CREDIT_PREFIX +String.valueOf(austriaLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.AUSTRIA_CREDIT_PREFIX +String.valueOf(austriaLastNumber);
                                           lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(austriaLastNumber);
                                            austriaLastNumber =austriaLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }// Change for Story 2980 - END - AUSTRIA
                        }
                    }
                    WHEN 'germany' {
                        Long germanyLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false) 
                        {
                            String key= billTo.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+String.valueOf(billTo.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c);
                            If(lastCreditNoteNumMap.ContainsKey(key) && lastCreditNoteNumMap != null) {
                                //#28513 Created Key for Country;LegalEntitynumber combo to generate seq no based upon legal Entity wise
                                germanyLastNumber=Long.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                germanyLastNumber =germanyLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.GERMANY_PREFIX +String.valueOf(germanyLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.GERMANY_PREFIX +String.valueOf(germanyLastNumber);
                                
                                if(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c != String.valueOf(germanyLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(key);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(germanyLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                        }
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True) 
                        {
                            //#28513 Created Key for Country;LegalEntitynumber combo to generate seq no based upon legal Entity wise
                            String key= billTo.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+String.valueOf(billTo.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c)+';'+'credit';
                            if(lastCreditNoteNumMap.ContainsKey(key) && lastCreditNoteNumMap != null)
                            {
                                // Change for Story 2980 - Start - GERMANY
                                if(postedIds != null){
                                    germanyLastNumber=Long.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                    germanyLastNumber =germanyLastNumber+1;
                                    infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.GERMANY_PREFIX_CREDIT_NOTE +String.valueOf(germanyLastNumber);
                                    infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.GERMANY_PREFIX_CREDIT_NOTE +String.valueOf(germanyLastNumber);
                                    
                                    if(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c != String.valueOf(germanyLastNumber))
                                    {
                                        QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(key);
                                        lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(germanyLastNumber);
                                        invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                    }
                                }
                                else{
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(key);
                                    germanyLastNumber=Long.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                    String tempVal = QTB_Constants.GERMANY_PREFIX_CREDIT_NOTE +String.valueOf(germanyLastNumber);
                                    if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                    {
                                        Integer i=0;
                                       for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                        {
                                            if(i==0){
                                                germanyLastNumber =germanyLastNumber+1;
                                                i++;
                                            }
                                            else if(tempVal != null || Test.isRunningTest()){
                                                cred.QTB_Custom_Invoice_Number__c = QTB_Constants.GERMANY_PREFIX_CREDIT_NOTE +String.valueOf(germanyLastNumber);
                                                cred.QTB_Custom_Invoice_ID__c = QTB_Constants.GERMANY_PREFIX_CREDIT_NOTE +String.valueOf(germanyLastNumber);
                                                lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(germanyLastNumber);
                                                germanyLastNumber =germanyLastNumber+1;
                                                creditNoteToUpdate.add(cred);
                                            }
                                        }
                                        invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                    }
                                } // Change for Story 2980 - END - GERMANY
                            }
                            
                            
                        }
                    } 
                    WHEN 'norway' {
                        Long NorwayLastNumber =0; 
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(NORWAY) && lastCreditNoteNumMap != null )
                        {
                            Integer checkDigt = QTB_Utils.checkDigitforNorwayDenmark(lastCreditNoteNumMap.get(NORWAY).QTB_Next_Sequence_Number__c+String.valueOf(billTo.QTB_Customer_Number__c));
                            norwayLastNumber =Long.valueOf(lastCreditNoteNumMap.get(NORWAY).QTB_Next_Sequence_Number__c)+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c=lastCreditNoteNumMap.get(NORWAY).QTB_Next_Sequence_Number__c+String.valueOf(billTo.QTB_Customer_Number__c)+String.valueOf(checkDigt);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c= QTB_Constants.NORWAY_PREFIX_ISO +lastCreditNoteNumMap.get(NORWAY).QTB_Next_Sequence_Number__c;
                            if(lastCreditNoteNumMap.get(NORWAY).QTB_Next_Sequence_Number__c != String.valueOf(norwayLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(NORWAY);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(norwayLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(NORWAY_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            if(postedIds != null){
                                Integer checkDigt = QTB_Utils.checkDigitforNorwayDenmark(lastCreditNoteNumMap.get(NORWAY_CREDIT).QTB_Next_Sequence_Number__c+String.valueOf(billTo.QTB_Customer_Number__c));
                                norwayLastNumber =Long.valueOf(lastCreditNoteNumMap.get(NORWAY_CREDIT).QTB_Next_Sequence_Number__c)+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c=lastCreditNoteNumMap.get(NORWAY_CREDIT).QTB_Next_Sequence_Number__c+String.valueOf(billTo.QTB_Customer_Number__c)+String.valueOf(checkDigt);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c= QTB_Constants.NORWAY_CREDIT_PREFIX +lastCreditNoteNumMap.get(NORWAY_CREDIT).QTB_Next_Sequence_Number__c;
                                if(lastCreditNoteNumMap.get(NORWAY_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(norwayLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(NORWAY_CREDIT);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(norwayLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                            else{
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(NORWAY_CREDIT);
                                norwayLastNumber=Long.valueOf(lastCreditNoteNumMap.get(NORWAY_CREDIT).QTB_Next_Sequence_Number__c);
                                String tempVal =QTB_Constants.NORWAY_CREDIT_PREFIX +String.valueOf(norwayLastNumber);
                                system.debug('>> ' + tempVal);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            norwayLastNumber =norwayLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.NORWAY_CREDIT_PREFIX +String.valueOf(norwayLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.NORWAY_CREDIT_PREFIX +String.valueOf(norwayLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(norwayLastNumber);
                                            norwayLastNumber =norwayLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                        }
                    }
                    WHEN 'finland'{
                        Long finlandLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(FINLAND) && lastCreditNoteNumMap != null)
                        {
                            Integer checkDigt = QTB_Utils.checkDigitforFinland(lastCreditNoteNumMap.get(FINLAND).QTB_Next_Sequence_Number__c);    
                            finlandLastNumber =Long.valueOf(lastCreditNoteNumMap.get(FINLAND).QTB_Next_Sequence_Number__c)+1;                       
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c=lastCreditNoteNumMap.get(FINLAND).QTB_Next_Sequence_Number__c+String.valueOf(checkDigt);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c=QTB_Constants.FINLAND_PREFIX_ISO+lastCreditNoteNumMap.get(FINLAND).QTB_Next_Sequence_Number__c;
                            if(lastCreditNoteNumMap.get(FINLAND).QTB_Next_Sequence_Number__c != String.valueOf(finlandLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(FINLAND);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(finlandLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(FINLAND_CREDIT) && lastCreditNoteNumMap != null)
                        {  
                            if(postedIds != null){      
                                Integer checkDigt = QTB_Utils.checkDigitforFinland(lastCreditNoteNumMap.get(FINLAND_CREDIT).QTB_Next_Sequence_Number__c);    
                                finlandLastNumber =Long.valueOf(lastCreditNoteNumMap.get(FINLAND_CREDIT).QTB_Next_Sequence_Number__c)+1;                       
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c=lastCreditNoteNumMap.get(FINLAND_CREDIT).QTB_Next_Sequence_Number__c+String.valueOf(checkDigt);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c=QTB_Constants.FINLAND_CREDIT_PREFIX+lastCreditNoteNumMap.get(FINLAND_CREDIT).QTB_Next_Sequence_Number__c;
                                if(lastCreditNoteNumMap.get(FINLAND_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(finlandLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(FINLAND_CREDIT);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(finlandLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                            else{
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(FINLAND_CREDIT);
                                finlandLastNumber=Long.valueOf(lastCreditNoteNumMap.get(FINLAND_CREDIT).QTB_Next_Sequence_Number__c);
                                String tempVal = QTB_Constants.FINLAND_CREDIT_PREFIX +String.valueOf(finlandLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            finlandLastNumber =finlandLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.FINLAND_CREDIT_PREFIX +String.valueOf(finlandLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.FINLAND_CREDIT_PREFIX +String.valueOf(finlandLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(finlandLastNumber);
                                            finlandLastNumber =finlandLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                        }
                    }
                    WHEN 'denmark'{
                        Long denmarkLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(DENMARK) && lastCreditNoteNumMap != null)
                        {
                            Integer checkDigt = QTB_Utils.checkDigitforNorwayDenmark(lastCreditNoteNumMap.get(DENMARK).QTB_Next_Sequence_Number__c);
                            denmarkLastNumber =Long.valueOf(lastCreditNoteNumMap.get(DENMARK).QTB_Next_Sequence_Number__c)+1;                        
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c=QTB_Constants.DENMARK_PREFIX+lastCreditNoteNumMap.get(DENMARK).QTB_Next_Sequence_Number__c+String.valueOf(checkDigt)+QTB_Constants.DENMARK_POSTFIX;
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c=QTB_Constants.DENMARK_PREFIX_ISO+lastCreditNoteNumMap.get(DENMARK).QTB_Next_Sequence_Number__c;
                            if(lastCreditNoteNumMap.get(DENMARK).QTB_Next_Sequence_Number__c != String.valueOf(denmarkLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(DENMARK);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(denmarkLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(DENMARK_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            if(postedIds != null){   
                                Integer checkDigt = QTB_Utils.checkDigitforNorwayDenmark(lastCreditNoteNumMap.get(DENMARK_CREDIT).QTB_Next_Sequence_Number__c);
                                denmarkLastNumber =Long.valueOf(lastCreditNoteNumMap.get(DENMARK_CREDIT).QTB_Next_Sequence_Number__c)+1;                        
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c=QTB_Constants.DENMARK_PREFIX+lastCreditNoteNumMap.get(DENMARK_CREDIT).QTB_Next_Sequence_Number__c+String.valueOf(checkDigt)+QTB_Constants.DENMARK_POSTFIX;
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c=QTB_Constants.DENMARK_CREDIT_PREFIX+lastCreditNoteNumMap.get(DENMARK_CREDIT).QTB_Next_Sequence_Number__c;
                                if(lastCreditNoteNumMap.get(DENMARK_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(denmarkLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(DENMARK_CREDIT);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(denmarkLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                            else{
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(DENMARK_CREDIT);
                                denmarkLastNumber=Long.valueOf(lastCreditNoteNumMap.get(DENMARK_CREDIT).QTB_Next_Sequence_Number__c);
                                String tempVal = QTB_Constants.DENMARK_CREDIT_PREFIX +String.valueOf(denmarkLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {Integer i =0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            denmarkLastNumber =denmarkLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.DENMARK_CREDIT_PREFIX +String.valueOf(denmarkLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.DENMARK_CREDIT_PREFIX +String.valueOf(denmarkLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(denmarkLastNumber);
                                            denmarkLastNumber =denmarkLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                        }
                    } 
                    WHEN 'sweden'{
                        Long swedenLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(SWEDEN) && lastCreditNoteNumMap != null)
                        {
                            swedenLastNumber=Long.valueOf(lastCreditNoteNumMap.get(SWEDEN).QTB_Next_Sequence_Number__c);
                            swedenLastNumber =swedenLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.SWEDEN_PREFIX +String.valueOf(swedenLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.SWEDEN_PREFIX +String.valueOf(swedenLastNumber);
                            if(lastCreditNoteNumMap.get(SWEDEN).QTB_Next_Sequence_Number__c != String.valueOf(swedenLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(SWEDEN);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(swedenLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(SWEDEN_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            if(postedIds != null){  
                                swedenLastNumber=Long.valueOf(lastCreditNoteNumMap.get(SWEDEN_CREDIT).QTB_Next_Sequence_Number__c);
                                swedenLastNumber =swedenLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.SWEDEN_CREDIT_PREFIX +String.valueOf(swedenLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.SWEDEN_CREDIT_PREFIX +String.valueOf(swedenLastNumber);
                                if(lastCreditNoteNumMap.get(SWEDEN_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(swedenLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(SWEDEN_CREDIT);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(swedenLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                            else{
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(SWEDEN_CREDIT);
                                swedenLastNumber=Long.valueOf(lastCreditNoteNumMap.get(SWEDEN_CREDIT).QTB_Next_Sequence_Number__c);
                                String tempVal = QTB_Constants.SWEDEN_CREDIT_PREFIX +String.valueOf(swedenLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i = 0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            swedenLastNumber =swedenLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal !=null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.SWEDEN_CREDIT_PREFIX +String.valueOf(swedenLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c =  QTB_Constants.SWEDEN_CREDIT_PREFIX +String.valueOf(swedenLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(swedenLastNumber);
                                            swedenLastNumber =swedenLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                        }
                    }
                    WHEN 'india'{
                        Long indiaLastNumber =0;
                        //comparing the key(contains state and legalentity num) accordingly updating the custom invoice number for INDIA
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false )
                        {
                            String key= billTo.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+billTo.QTB_Market__r.QTB_State__c.toLowerCase().replaceAll( '\\s+', '')+';'+String.valueOf(billTo.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c);
                            if(lastCreditNoteNumMap.ContainsKey(key) && lastCreditNoteNumMap != null){
                                Integer strLen = lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c.length(); 
                                String invSettingName = lastCreditNoteNumMap.get(key).Name;
                                indiaLastNumber = Long.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c.substring(2,strLen))+1;  
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c = QTB_Constants.INDIA_PREFIX_ISO+String.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.INDIA_PREFIX_ISO+String.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                String lpString = String.valueOf(indiaLastNumber).leftPad(strLen-2, '0');
                                String strNextNumber = lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c.substring(0,2) + lpString;  
                                invSettingLastNumberMap.put(invSettingName,strNextNumber);
                            }
                        } 
                        else if (billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True)
                        {
                            String key= billTo.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+billTo.QTB_Market__r.QTB_State__c.toLowerCase().replaceAll( '\\s+', '')+';'+String.valueOf(billTo.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c)+';'+'credit';
                            if(lastCreditNoteNumMap.ContainsKey(key) && lastCreditNoteNumMap != null)
                            {
                                if(postedIds != null){ 
                                    Integer strLen = lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c.length(); 
                                    String invSettingName = lastCreditNoteNumMap.get(key).Name;
                                    system.debug('lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c '+lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                    indiaLastNumber = Long.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c.substring(2,strLen))+1;  
                                    String lpString = String.valueOf(indiaLastNumber).leftPad(strLen-2, '0');
                                    String strNextNumber = lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c.substring(0,2) + lpString;  
                                    infoPostedCreditNote.QTB_Custom_Invoice_ID__c = QTB_Constants.INDIA_CREDIT_PREFIX+String.valueOf(strNextNumber);
                                    infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.INDIA_CREDIT_PREFIX+String.valueOf(strNextNumber);
                                    invSettingLastNumberMap.put(invSettingName,strNextNumber);
                                }
                                else{
                                   //String tempVal = QTB_Constants.INDIA_CREDIT_PREFIX +String.valueOf(indiaLastNumber);
                                   if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                    {
                                        Integer i=0;
                                       for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                        {
                                            String keyAccount= cred.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+ cred.blng__Account__r.QTB_Market__r.QTB_State__c.toLowerCase().replaceAll( '\\s+', '')+';'+String.valueOf( cred.blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c)+';'+'credit';
                                            String invSettingName = lastCreditNoteNumMap.get(keyAccount).Name;
                                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(keyAccount);
                                            Integer strLen = lastCreditNoteNumMap.get(keyAccount).QTB_Next_Sequence_Number__c.length();
                                            //indiaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(keyAccount).QTB_Next_Sequence_Number__c.substring(2,strLen));
                                            if(invSettingLastNumberMap.containsKey(lastCrd.name) || Test.isRunningTest())
                                            {
                                                String tempValue =invSettingLastNumberMap.get(lastCrd.name);
                                                indiaLastNumber = Long.valueOf(lastCreditNoteNumMap.get(keyAccount).QTB_Next_Sequence_Number__c.substring(2,strLen))+i;  
                                                String lpString = String.valueOf(indiaLastNumber).leftPad(strLen-2, '0');
                                                String strNextNumber = lastCreditNoteNumMap.get(keyAccount).QTB_Next_Sequence_Number__c.substring(0,2) + lpString;  
                                                cred.QTB_Custom_Invoice_ID__c = QTB_Constants.INDIA_CREDIT_PREFIX+String.valueOf(strNextNumber);
                                                cred.QTB_Custom_Invoice_Number__c = QTB_Constants.INDIA_CREDIT_PREFIX+String.valueOf(strNextNumber);
                                                invSettingLastNumberMap.put(invSettingName,strNextNumber);
                                                creditNoteToUpdate.add(cred);
                                                i++;
                                            }
                                            else{
                                                indiaLastNumber = Long.valueOf(lastCreditNoteNumMap.get(keyAccount).QTB_Next_Sequence_Number__c.substring(2,strLen))+i;  
                                                cred.QTB_Custom_Invoice_ID__c = QTB_Constants.INDIA_CREDIT_PREFIX+String.valueOf(lastCreditNoteNumMap.get(keyAccount).QTB_Next_Sequence_Number__c);
                                                cred.QTB_Custom_Invoice_Number__c = QTB_Constants.INDIA_CREDIT_PREFIX+String.valueOf(lastCreditNoteNumMap.get(keyAccount).QTB_Next_Sequence_Number__c);
                                                i++;
                                                String lpString = String.valueOf(indiaLastNumber).leftPad(strLen-2, '0');
                                                String strNextNumber = lastCreditNoteNumMap.get(keyAccount).QTB_Next_Sequence_Number__c.substring(0,2) + lpString;  
                                                invSettingLastNumberMap.put(invSettingName,strNextNumber);
                                                creditNoteToUpdate.add(cred);
                                            }
                                            //invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                        }
                                    }
                                }
                            }
                        }
                    } 
                    WHEN 'taiwan'{
                        Long taiwanLastNumber =0; 
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(TAIWAN) && lastCreditNoteNumMap != null)
                        {
                            taiwanLastNumber=Long.valueOf(lastCreditNoteNumMap.get(TAIWAN).QTB_Next_Sequence_Number__c);
                            taiwanLastNumber =taiwanLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.TAIWAN_PREFIX +String.valueOf(taiwanLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.TAIWAN_PREFIX +String.valueOf(taiwanLastNumber);
                            if(lastCreditNoteNumMap.get(TAIWAN).QTB_Next_Sequence_Number__c != String.valueOf(taiwanLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(TAIWAN);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(taiwanLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(TAIWAN_CREDIT) && lastCreditNoteNumMap != null)
                        { 
                            if(postedIds != null){ 
                                taiwanLastNumber=Long.valueOf(lastCreditNoteNumMap.get(TAIWAN_CREDIT).QTB_Next_Sequence_Number__c);
                                taiwanLastNumber =taiwanLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.TAIWAN_CREDIT_PREFIX +String.valueOf(taiwanLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.TAIWAN_CREDIT_PREFIX +String.valueOf(taiwanLastNumber);
                                
                                if(lastCreditNoteNumMap.get(TAIWAN_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(taiwanLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(TAIWAN_CREDIT);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(taiwanLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                            else{
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(TAIWAN_CREDIT);
                                taiwanLastNumber=Long.valueOf(lastCreditNoteNumMap.get(TAIWAN_CREDIT).QTB_Next_Sequence_Number__c);
                                String tempVal = QTB_Constants.TAIWAN_CREDIT_PREFIX +String.valueOf(taiwanLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            taiwanLastNumber =taiwanLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.TAIWAN_CREDIT_PREFIX +String.valueOf(taiwanLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.TAIWAN_CREDIT_PREFIX +String.valueOf(taiwanLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(taiwanLastNumber);
                                            taiwanLastNumber =taiwanLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                        }
                    }
                    WHEN 'thailand'{
                        Long thailandLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(THAILAND) && lastCreditNoteNumMap != null)
                        {
                            thailandLastNumber=Long.valueOf(lastCreditNoteNumMap.get(THAILAND).QTB_Next_Sequence_Number__c);
                            thailandLastNumber =thailandLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.THAILAND_PREFIX +String.valueOf(thailandLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.THAILAND_PREFIX +String.valueOf(thailandLastNumber);
                            
                            if(lastCreditNoteNumMap.get(THAILAND).QTB_Next_Sequence_Number__c != String.valueOf(thailandLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(THAILAND);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(thailandLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(THAILAND_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            if(postedIds != null){ 
                                thailandLastNumber=Long.valueOf(lastCreditNoteNumMap.get(THAILAND_CREDIT).QTB_Next_Sequence_Number__c);
                                thailandLastNumber =thailandLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.THAILAND_CREDIT_PREFIX +String.valueOf(thailandLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.THAILAND_CREDIT_PREFIX +String.valueOf(thailandLastNumber);
                                
                                if(lastCreditNoteNumMap.get(THAILAND_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(thailandLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(THAILAND_CREDIT);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(thailandLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                            else{
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(THAILAND_CREDIT);
                                thailandLastNumber=Long.valueOf(lastCreditNoteNumMap.get(THAILAND_CREDIT).QTB_Next_Sequence_Number__c);
                                String tempVal = QTB_Constants.THAILAND_CREDIT_PREFIX +String.valueOf(thailandLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            thailandLastNumber =thailandLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.THAILAND_CREDIT_PREFIX +String.valueOf(thailandLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c =QTB_Constants.THAILAND_CREDIT_PREFIX +String.valueOf(thailandLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(thailandLastNumber);
                                            thailandLastNumber =thailandLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                        }
                    } 
                    WHEN 'malaysia'{
                        Long malaysiaLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(MALAYSIA) && lastCreditNoteNumMap != null)
                        {
                            malaysiaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(MALAYSIA).QTB_Next_Sequence_Number__c);
                            malaysiaLastNumber =malaysiaLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.MALAYSIA_PREFIX +String.valueOf(malaysiaLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.MALAYSIA_PREFIX +String.valueOf(malaysiaLastNumber);
                            
                            if(lastCreditNoteNumMap.get(MALAYSIA).QTB_Next_Sequence_Number__c != String.valueOf(malaysiaLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(MALAYSIA);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(malaysiaLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(MALAYSIA_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            if(postedIds != null){ 
                                malaysiaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(MALAYSIA_CREDIT).QTB_Next_Sequence_Number__c);
                                malaysiaLastNumber =malaysiaLastNumber+1;    
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.MALAYSIA_CREDIT_PREFIX +String.valueOf(malaysiaLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.MALAYSIA_CREDIT_PREFIX +String.valueOf(malaysiaLastNumber);
                                
                                if(lastCreditNoteNumMap.get(MALAYSIA_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(malaysiaLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(MALAYSIA_CREDIT);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(malaysiaLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                            else{
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(MALAYSIA_CREDIT);
                                malaysiaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(MALAYSIA_CREDIT).QTB_Next_Sequence_Number__c);
                                String tempVal = QTB_Constants.MALAYSIA_CREDIT_PREFIX +String.valueOf(malaysiaLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            malaysiaLastNumber =malaysiaLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.MALAYSIA_CREDIT_PREFIX +String.valueOf(malaysiaLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.MALAYSIA_CREDIT_PREFIX +String.valueOf(malaysiaLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(malaysiaLastNumber);
                                            malaysiaLastNumber =malaysiaLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                        }
                    } 
                    WHEN 'hong kong'{
                        Long hongkongLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(HONGKONG) && lastCreditNoteNumMap != null)
                        {
                            hongkongLastNumber=Long.valueOf(lastCreditNoteNumMap.get(HONGKONG).QTB_Next_Sequence_Number__c);
                            hongkongLastNumber =hongkongLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.HONGKONG_PREFIX +String.valueOf(hongkongLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.HONGKONG_PREFIX +String.valueOf(hongkongLastNumber);
                            
                            if(lastCreditNoteNumMap.get(HONGKONG).QTB_Next_Sequence_Number__c != String.valueOf(hongkongLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(HONGKONG);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(hongkongLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(HONGKONG_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            if(postedIds != null)
                            {
                                hongkongLastNumber=Long.valueOf(lastCreditNoteNumMap.get(HONGKONG_CREDIT).QTB_Next_Sequence_Number__c);
                                hongkongLastNumber =hongkongLastNumber+1;   
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.HONGKONG_CREDIT_PREFIX +String.valueOf(hongkongLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.HONGKONG_CREDIT_PREFIX +String.valueOf(hongkongLastNumber);
                                
                                if(lastCreditNoteNumMap.get(HONGKONG_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(hongkongLastNumber))
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(HONGKONG_CREDIT);
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(hongkongLastNumber);
                                    invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                }
                            }
                            else{
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(HONGKONG_CREDIT);
                            hongkongLastNumber=Long.valueOf(lastCreditNoteNumMap.get(HONGKONG_CREDIT).QTB_Next_Sequence_Number__c);
                            String tempVal = QTB_Constants.HONGKONG_CREDIT_PREFIX +String.valueOf(hongkongLastNumber);
                            if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                            {
                                Integer i =0;
                                for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                {
                                    if(i==0){
                                        hongkongLastNumber =hongkongLastNumber+1;
                                        i++;
                                    }
                                    else if(tempVal != null || Test.isRunningTest()){
                                        cred.QTB_Custom_Invoice_Number__c = QTB_Constants.HONGKONG_CREDIT_PREFIX +String.valueOf(hongkongLastNumber);
                                         cred.QTB_Custom_Invoice_ID__c = QTB_Constants.HONGKONG_CREDIT_PREFIX +String.valueOf(hongkongLastNumber);
                                        lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(hongkongLastNumber);
                                        hongkongLastNumber =hongkongLastNumber+1;
                                        creditNoteToUpdate.add(cred);
                                    }
                                }
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        }
                        
                    }
                    //#30973 #31259 Cluster 4 countries Turkey, New Zealand,Australia
                    WHEN 'australia'{
                        Long australiaLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(AUSTRALIA) && lastCreditNoteNumMap != null)
                        {
                            australiaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(AUSTRALIA).QTB_Next_Sequence_Number__c);
                            australiaLastNumber =australiaLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.AUSTRALIA_PREFIX +String.valueOf(australiaLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.AUSTRALIA_PREFIX +String.valueOf(australiaLastNumber);
                            
                            if(lastCreditNoteNumMap.get(AUSTRALIA).QTB_Next_Sequence_Number__c != String.valueOf(australiaLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(AUSTRALIA);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(australiaLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(AUSTRALIA_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(AUSTRALIA_CREDIT);
                            australiaLastNumber=Long.valueOf(lastCreditNoteNumMap.get(AUSTRALIA_CREDIT).QTB_Next_Sequence_Number__c);
                                
                            if(postedIds != null)
                            {
                                australiaLastNumber =australiaLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.AUSTRALIA_PREFIX_CREDIT_NOTE +String.valueOf(australiaLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.AUSTRALIA_PREFIX_CREDIT_NOTE +String.valueOf(australiaLastNumber);
                                if(lastCreditNoteNumMap.get(AUSTRALIA_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(australiaLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(australiaLastNumber);
                                }
                            }
                            else{
                                String tempVal = QTB_Constants.AUSTRALIA_PREFIX_CREDIT_NOTE +String.valueOf(australiaLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                   for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                        australiaLastNumber =australiaLastNumber+1;
                                        i++;
										}
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.AUSTRALIA_PREFIX_CREDIT_NOTE +String.valueOf(australiaLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.AUSTRALIA_PREFIX_CREDIT_NOTE +String.valueOf(australiaLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(australiaLastNumber);
                                            australiaLastNumber =australiaLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                }
                            }
                          invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        }
                    }
                    
                    WHEN 'new zealand'{
                        Long newZealandLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(NEWZEALAND) && lastCreditNoteNumMap != null)
                        {
                            newZealandLastNumber=Long.valueOf(lastCreditNoteNumMap.get(NEWZEALAND).QTB_Next_Sequence_Number__c);
                            newZealandLastNumber =newZealandLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.NEW_ZEALAND_PREFIX +String.valueOf(newZealandLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.NEW_ZEALAND_PREFIX +String.valueOf(newZealandLastNumber);
                            if(lastCreditNoteNumMap.get(NEWZEALAND).QTB_Next_Sequence_Number__c != String.valueOf(newZealandLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(NEWZEALAND);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(newZealandLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(NEWZEALAND_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(NEWZEALAND_CREDIT);
                            newZealandLastNumber=Long.valueOf(lastCreditNoteNumMap.get(NEWZEALAND_CREDIT).QTB_Next_Sequence_Number__c);
                                
                            if(postedIds != null)
                            {       
                                newZealandLastNumber =newZealandLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.NEW_ZEALAND_PREFIX_CREDIT_NOTE +String.valueOf(newZealandLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.NEW_ZEALAND_PREFIX_CREDIT_NOTE +String.valueOf(newZealandLastNumber);
                                
                                if(lastCreditNoteNumMap.get(NEWZEALAND_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(newZealandLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(newZealandLastNumber);
                               }
                            }
                            else{
                                String tempVal = QTB_Constants.NEW_ZEALAND_PREFIX_CREDIT_NOTE +String.valueOf(newZealandLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                        newZealandLastNumber =newZealandLastNumber+1;
                                        i++;
										}
                                        if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.NEW_ZEALAND_PREFIX_CREDIT_NOTE +String.valueOf(newZealandLastNumber);
                                            cred.QTB_Custom_Invoice_ID__c = QTB_Constants.NEW_ZEALAND_PREFIX_CREDIT_NOTE +String.valueOf(newZealandLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(newZealandLastNumber);
                                            newZealandLastNumber =newZealandLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                }
                            }
                         invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                
                        }
                    }
                    //#34738 Changing the Turkey Invoice Number sequence as per this story like diff sequencing for both E fatura and E Arsive Credit Notes
                    WHEN 'turkey'{
                        Long turkeyLastNumber =0;
                        if(billTo.QTB_Invoice_Delivery_Options__c != Null && billTo.QTB_Contract_Entity__r.blng__Country__c != Null){
                            if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false)
                            {
                                String key = billTo.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+billTo.QTB_Invoice_Delivery_Options__c;
                                if(billTo.QTB_Invoice_Delivery_Options__c == QTB_Constants.TURKEY_FATURA_DELIVERY_OPTION && 
                                   lastCreditNoteNumMap.ContainsKey(key) && lastCreditNoteNumMap != null){
                                        turkeyLastNumber=Long.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                        turkeyLastNumber =turkeyLastNumber+1;
                                        infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.TURKEY_FATURA_PREFIX +String.valueOf(turkeyLastNumber);
                                        infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.TURKEY_FATURA_PREFIX +String.valueOf(turkeyLastNumber);
                                        
                                        if(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c != String.valueOf(turkeyLastNumber))
                                        {
                                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(key);
                                            lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(turkeyLastNumber);
                                            invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                        }
                                }
                                else if (billTo.QTB_Invoice_Delivery_Options__c == QTB_Constants.TURKEY_ARSIV_DELIVERY_OPTION && 
                                   lastCreditNoteNumMap.ContainsKey(key) && lastCreditNoteNumMap != null){
                                    turkeyLastNumber=Long.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                    turkeyLastNumber =turkeyLastNumber+1;
                                    infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.TURKEY_ARSIV_PREFIX +String.valueOf(turkeyLastNumber);
                                    infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.TURKEY_ARSIV_PREFIX +String.valueOf(turkeyLastNumber);
                                    
                                    if(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c != String.valueOf(turkeyLastNumber))
                                    {
                                        QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(key);
                                        lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(turkeyLastNumber);
                                        invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                    }
                                }
                            }
                            else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True){
                                system.debug('Inside true condition');
                                String key = billTo.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+billTo.QTB_Invoice_Delivery_Options__c+';'+'credit';
                                if(lastCreditNoteNumMap.ContainsKey(key) && lastCreditNoteNumMap != null)
                                {
                                    QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(key);
                                    turkeyLastNumber=Long.valueOf(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c);
                                    if(postedIds != null)
                                    {
                                        if(billTo.QTB_Invoice_Delivery_Options__c == QTB_Constants.TURKEY_FATURA_DELIVERY_OPTION){
                                        
                                            turkeyLastNumber =turkeyLastNumber+1;
                                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.TURKEY_FATURA_PREFIX_CREDIT_NOTE +String.valueOf(turkeyLastNumber);
                                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.TURKEY_FATURA_PREFIX_CREDIT_NOTE +String.valueOf(turkeyLastNumber);
                                        
                                            if(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c != String.valueOf(turkeyLastNumber))
                                            {
                                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(turkeyLastNumber);
                                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                            }
                                        }
                                        else if(billTo.QTB_Invoice_Delivery_Options__c == QTB_Constants.TURKEY_ARSIV_DELIVERY_OPTION){
                                            turkeyLastNumber =turkeyLastNumber+1;
                                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.TURKEY_ARSIV_PREFIX_CREDIT_NOTE +String.valueOf(turkeyLastNumber);
                                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.TURKEY_ARSIV_PREFIX_CREDIT_NOTE +String.valueOf(turkeyLastNumber);
                                        
                                            if(lastCreditNoteNumMap.get(key).QTB_Next_Sequence_Number__c != String.valueOf(turkeyLastNumber))
                                            {
                                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(turkeyLastNumber);
                                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                            }
                                        }
                                    }
                                    else
                                    {
                                        if(billTo.QTB_Invoice_Delivery_Options__c == QTB_Constants.TURKEY_FATURA_DELIVERY_OPTION)
                                        {
                                            // Change for Story 2980 - START TURKEY
                                            String tempVal = QTB_Constants.TURKEY_FATURA_PREFIX_CREDIT_NOTE +String.valueOf(turkeyLastNumber);
                                            if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                            {
                                                Integer i=0;
                                                for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                                {
                                                    if(i==0){
                                                        turkeyLastNumber =turkeyLastNumber+1;
                                                        i++;
                                                    }
                                                    else if(tempVal != null || Test.isRunningTest()){
                                                        cred.QTB_Custom_Invoice_Number__c = QTB_Constants.TURKEY_FATURA_PREFIX_CREDIT_NOTE +String.valueOf(turkeyLastNumber);
                                                        cred.QTB_Custom_Invoice_ID__c =  QTB_Constants.TURKEY_FATURA_PREFIX_CREDIT_NOTE +String.valueOf(turkeyLastNumber);
                                                        lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(turkeyLastNumber);
                                                        turkeyLastNumber =turkeyLastNumber+1;
                                                        creditNoteToUpdate.add(cred);
                                                    }
                                                }
                                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                            }
                                        }
                                        else if(billTo.QTB_Invoice_Delivery_Options__c == QTB_Constants.TURKEY_ARSIV_DELIVERY_OPTION)
                                        {
                                            String tempVal = QTB_Constants.TURKEY_FATURA_PREFIX_CREDIT_NOTE +String.valueOf(turkeyLastNumber);
                                            if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                            {
                                                Integer i=0;
                                                for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                                {
                                                    if(i==0){
                                                        turkeyLastNumber =turkeyLastNumber+1;
                                                        i++;
                                                    }
                                                    else if(tempVal != null){
                                                        cred.QTB_Custom_Invoice_Number__c = QTB_Constants.TURKEY_FATURA_PREFIX_CREDIT_NOTE +String.valueOf(turkeyLastNumber);
                                                        cred.QTB_Custom_Invoice_ID__c = QTB_Constants.TURKEY_FATURA_PREFIX_CREDIT_NOTE +String.valueOf(turkeyLastNumber);
                                                        lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(turkeyLastNumber);
                                                        turkeyLastNumber =turkeyLastNumber+1;
                                                        creditNoteToUpdate.add(cred);
                                                    }
                                                }
                                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                                            }
                                            
                                        } 
                                    } // Change for Story 2980 - END TURKEY
                                }
                            }
                        }
                    }
                    WHEN 'singapore'{
                        Long singaporeLastNumber =0;
                        if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == false &&
                           lastCreditNoteNumMap.ContainsKey(SINGAPORE) && lastCreditNoteNumMap != null)
                        {
                            singaporeLastNumber=Long.valueOf(lastCreditNoteNumMap.get(SINGAPORE).QTB_Next_Sequence_Number__c);
                            singaporeLastNumber =singaporeLastNumber+1;
                            infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.SINGAPORE_PREFIX +String.valueOf(singaporeLastNumber);
                            infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.SINGAPORE_PREFIX +String.valueOf(singaporeLastNumber);
                            if(lastCreditNoteNumMap.get(SINGAPORE).QTB_Next_Sequence_Number__c != String.valueOf(singaporeLastNumber))
                            {
                                QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(SINGAPORE);
                                lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(singaporeLastNumber);
                                invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                            }
                        }
                        else if(billTo.QTB_Contract_Entity__r.QTB_Separate_Inv_Crd_Seq__c == True &&
                                lastCreditNoteNumMap.ContainsKey(SINGAPORE_CREDIT) && lastCreditNoteNumMap != null)
                        {
                            QTB_CustomInvoiceNumber__c lastCrd = lastCreditNoteNumMap.get(SINGAPORE_CREDIT);
                            singaporeLastNumber=Long.valueOf(lastCreditNoteNumMap.get(SINGAPORE_CREDIT).QTB_Next_Sequence_Number__c);
                            // Change for Story 2980 - START SINGAPORE
                            if(postedIds != null){
                                singaporeLastNumber =singaporeLastNumber+1;
                                infoPostedCreditNote.QTB_Custom_Invoice_ID__c= QTB_Constants.SINGAPORE_CREDIT_PREFIX +String.valueOf(singaporeLastNumber);
                                infoPostedCreditNote.QTB_Custom_Invoice_Number__c = QTB_Constants.SINGAPORE_CREDIT_PREFIX +String.valueOf(singaporeLastNumber);
                                if(lastCreditNoteNumMap.get(SINGAPORE_CREDIT).QTB_Next_Sequence_Number__c != String.valueOf(singaporeLastNumber))
                                {
                                    lastCrd.QTB_Next_Sequence_Number__c = String.valueOf(singaporeLastNumber);
                                }
                            }
                            else{
                                String tempVal = QTB_Constants.SINGAPORE_CREDIT_PREFIX +String.valueOf(singaporeLastNumber);
                                if(!duplicateMapCreditNote.isEmpty() && duplicateMapCreditNote!=null)
                                {
                                    Integer i=0;
                                    for(blng__CreditNote__c cred : duplicateMapCreditNote.values())
                                    {
                                        if(i==0){
                                            singaporeLastNumber =singaporeLastNumber+1;
                                            i++;
                                        }
                                        else if(tempVal != null || Test.isRunningTest()){
                                            cred.QTB_Custom_Invoice_Number__c = QTB_Constants.SINGAPORE_CREDIT_PREFIX +String.valueOf(singaporeLastNumber);
                                             cred.QTB_Custom_Invoice_ID__c =QTB_Constants.SINGAPORE_CREDIT_PREFIX +String.valueOf(singaporeLastNumber);
                                            lastCrd.QTB_Next_Sequence_Number__c =String.valueOf(singaporeLastNumber);
                                            singaporeLastNumber =singaporeLastNumber+1;
                                            creditNoteToUpdate.add(cred);
                                        }
                                    }
                                }
                            }
                          invSettingLastNumberMap.put(lastCrd.name,lastCrd.QTB_Next_Sequence_Number__c);
                        } // Change for Story 2980 - END SINGAPORE
                    }    
                    WHEN else{
                        infoPostedCreditNote.QTB_Custom_Invoice_ID__c=infoPostedCreditNote.name;    
                        //Defect No GIT #5966 
                        infoPostedCreditNote.QTB_Custom_Invoice_Number__c=infoPostedCreditNote.name;
                    }
                }
                
            } 
            system.debug('invSettingLastNumberMap' +invSettingLastNumberMap);
            //Update custom setting if it's respected state's sequence number is updated
            //modified as part of epic- 2980
            for(String str : invSettingLastNumberMap.keySet())
            {
                if(lastCreditNoteNumMap.containsKey(str))
                {
                    QTB_CustomInvoiceNumber__c invCustomSettingRec = lastCreditNoteNumMap.get(str);
                    invCustomSettingRec.QTB_Next_Sequence_Number__c= invSettingLastNumberMap.get(str);
                    invCustomSettingRec.QTB_Date_Time__c = System.now();
                    invCustomSettToUpdate.add(invCustomSettingRec);
                }
            }
            //added as part of epic - 2980
            if(!creditNoteToUpdate.isEmpty()){
                update creditNoteToUpdate;
            }
            if(postedIds==null && !invCustomSettToUpdate.isEmpty()){
                System.debug('invCustomSettToUpdate ' +invCustomSettToUpdate);
                update invCustomSettToUpdate;
            }
            
            System.debug('postedIds' +postedIds);
            System.debug('infoPostedCreditNote' +infoPostedCreditNote);
            
            if(postedIds!=null && postedIds.size()>0 && !postedIds.isempty() && infoPostedCreditNote!=null && 
               infoPostedCreditNote.QTB_Custom_Invoice_Number__c != null && postedIds.contains(infoPostedCreditNote.id)){
                   
                   Datetime dt1 = Datetime.now();
                   Datetime dt = dt1.addminutes(2);
                   Integer seconds = dt.second();
                   Integer minutes = dt.minute();
                   Integer hours = dt.hour();
                   Integer dayOfMonth = dt.day();
                   Integer month = dt.month();
                   Integer year = dt.year();
                   // Constructing the cron expression
                   String cronExpression = seconds + ' ' + minutes + ' ' + hours + ' ' +dayOfMonth + ' ' + month + ' ? ' + year;
                   system.debug('cronExpression >>> ' + cronExpression);
                   //Scheduler that calls the new batch for Posting the Draft lines 
                   //added 1 more parameter as part of epic - 2980
                    QTB_CRDN_Ready_for_Int_Scheduler b1 = new QTB_CRDN_Ready_for_Int_Scheduler(postedIds,invCustomSettToUpdate);
                    Id firstId = new List<Id> (postedIds).get(0); 
                    system.debug('firstId' +firstId);
                    System.schedule('Ready For Intgeration '+firstId+' ' + cronExpression, cronExpression, b1);
               }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), QTB_CreditNoteIDGeneration.class.getName());
            throw e;
        }
    }
    public class CustomException extends Exception {}
}
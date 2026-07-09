/*****************************************************************************************************
* Class		 : QTB_Generate_Creditnote_Ctrl
* Test Class : QTB_Generate_Creditnote_Ctrl_Test
* Purpose	 : This class containing logic for generating txt file for APIX Credit note
* Jira Ticket: SFCPQBLG-962
* Developer             Date           
* ------------------------------------------------------------------------------------------- 
* Vinutha Iyengar      7/21/2020
* Pragathi BV          4/6/2023  Updation made for Nordics 
* kullayappa A         6/18/2024 updated made for Nordics(Instead of Invoice Qty,Subtotal update from Credit Note and credit Notelines)
* Shailesh(Virtusa)    07/03/2024 Gitlab US#24329,24844 -- Handling the Apix Extract for large no. of usages 
*******************************************************************************************************/
public class QTB_Generate_Creditnote_Ctrl 
{
    public HeaderLines Header {get;set;}      
    public List<LineItems> CrLineItems {get; set;}
    //NordicsBilling country wrappers
    public List<usagewrapper> lstusagewrapper {get; set;}
    public Map<String, String> accountLanguage = new Map<String, String>();
    // Map of  Value vs Translated label of price schedule category
    public Map<String, String> prScCategoryTranslation = new Map<String, String>();
    //Credit Note Billing Status for Draft and Posted Credit Notes
    public static final String CREDITNOTE_DRAFT_BILLING_STATUS = 'PRC';
    public static final String CREDITNOTE_POSTED_BILLING_STATUS = 'CRE';
    //#13894 NordicBilling Country specific Bill Code population
    public Boolean nordicBillingCountriesPresent {get; set;}
    //#15993 On Account Credit check 
    public Boolean nordicsOnAccountCheck {get; set;}
    
    //Sending Invoice Presentment to aura component
    @AuraEnabled
    public static String getinvoicepresentment(String recordID)  {
        try
        {
            //#15993 Addition of QTB_On_Account_Credit__c in the query
            List<blng__CreditNote__c> creditNotes = [select name,QTB_Last_Credit_Note_Sent__c,QTB_Custom_Invoice_Number__c,id,
                                                     blng__Status__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_On_Account_Credit__c
                                                     from blng__CreditNote__c where id =: recordID];
            if(creditNotes[0].blng__Status__c != null && creditNotes.size()>0){
                list<QTB_Invoice_Presentment_Settings__mdt> invoicePresentSettings = [Select id, QTB_Billing_Country__c, QTB_Invoice_Presentment_System__c from QTB_Invoice_Presentment_Settings__mdt
                                                                                      where QTB_Billing_Country__c =: creditNotes[0].blng__Account__r.QTB_Legal_Entity_Country__c limit 1];
                system.debug('InvoicePresentment'+invoicePresentSettings);
                //Gitlab US#24860 -- return the message for non-applicable apix extract country
                string InvoicePresentmentsystem = !invoicePresentSettings.isEmpty() 
                    ? invoicePresentSettings[0].QTB_Invoice_Presentment_System__c
                    : creditNotes[0].blng__Account__r.QTB_Legal_Entity_Country__c + ' country is not applicable for Apix presentment.';  
                return InvoicePresentmentsystem;
            } else {
                string InvoicePresentmentsystem ='Presentmentcheck';
                return InvoicePresentmentsystem;
            }
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
        }catch(Exception e) {
            QTB_ExceptionLogger.enable(); //Gitlab US#24844
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApexExtractCTRL.getStatus');
            throw e;
        }
    }
    
    public QTB_Generate_Creditnote_Ctrl()
    {
        try{
            string recID = ApexPages.currentPage()?.getParameters().get('Id');//Gitlab US#24844
            string isUsageWithinLimit = ApexPages.currentPage()?.getParameters().get('isUsageWithinLimit');//Gitlab US#24844
            //Gitlab US#24844 -- basedd on isUsageWithinLimit param value, either using the existing code or using the new logic
            //Gitlab US#24844 -- removed comments & system.debug logs
            
            If(String.isNotBlank(recID) && isUsageWithinLimit == 'true'){
                System.debug('QTB_Generate_Creditnote_Ctrl_if@@');
                String[] InvoiceNumbers = New String[]{};
                Map<Id,String> invoiceMap=new Map<Id,String>();
                nordicBillingCountriesPresent = false;
                nordicsOnAccountCheck = false;
                CrLineItems = new List<LineItems>();
                accountLanguage.put('no', 'NOR');
                accountLanguage.put('fi', 'FIN');
                accountLanguage.put('da', 'DAN');
                accountLanguage.put('sv', 'SVE');
                accountLanguage.put('en_US', 'ENG');
                accountLanguage.put('th', 'Thai');
                accountLanguage.put('zh_TW', 'Chinese Traditional');
                accountLanguage.put('en_GB', 'English(UK)');
                List<blng__CreditNoteLine__c> creditNoteLineItems = new List<blng__CreditNoteLine__c>();
                
                //translated value of price schedule category
                Schema.DescribeFieldResult statusOptions = product2.QTB_Price_Schedule_Category__c.getDescribe();
                for(Schema.PicklistEntry p : statusOptions.getPicklistValues()){
                    prScCategoryTranslation.put(String.valueOf(p.getValue()), String.valueOf(p.getLabel()));
                }
                
                //Query for CreditNote related information
                //15993 Addition of QTB_On_Account_Credit__c in the query
                //#21361 Addition of override fields
                //#28136 for partual credit note issue adding QTB_Credit_Note_Type__c in query 
                List<blng__CreditNote__c> creditNotes = [select id,name,QTB_Credit_Note_Type__c,blng__Status__c,blng__Notes__c,QTB_Custom_Invoice_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingPostalCode,blng__Account__r.BillingCountry,blng__Account__r.QTB_Language__c,blng__CreditNoteDate__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Bank_Name__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Account_Number__c,blng__Account__r.QTB_EDI_Identifier__c, blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IBAN__c, blng__Account__r.QTB_Invoice_Notes__c,blng__Subtotal__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__TotalAmount__c,QTB_Total_Amount_with_Tax_Override__c,CurrencyIsoCode,QTB_On_Account_Credit__c from blng__CreditNote__c where id =: recID];
                system.debug('recID >>> '+recID);
                system.debug('creditNotes >>> '+creditNotes);
                
                //Query for AccountContactRelation related to Credit Note account
                List<AccountContactRelation> billingCont= [select ContactId,QTB_Primary__c,Roles from AccountContactRelation where QTB_Primary__c = true and AccountId=:creditNotes[0].blng__Account__c and Roles includes ('Billing')];
                String ContactEmail;
                if(billingCont != null && billingCont.size()>0 && billingCont[0].ContactId != null)
                {              
                    Contact BillingContact = [select name,email,Phone from contact where id=:billingCont[0].ContactId];
                    ContactEmail = BillingContact.email;
                }
                
                String legalEntCountry = creditNotes[0].blng__Account__r.QTB_Contract_Entity__r.blng__Country__c;    
                String ISOCode ='';
                
                if(legalEntCountry!=null && legalEntCountry!='')
                {
                    List<IM_Country__c> CRCountry = [select Iso31662Code__c from IM_Country__c where Name = :legalEntCountry and Active__c = true];
                    ISOCode = CRCountry[0].Iso31662Code__c;
                }
                
                //#15993 - On_Account Credit note Items querying for Nordic Billing countries 
                AggregateResult[] creditLines;
                //-------Start of logic to check Nordic country Git #13894-----/
                List<String> nordicCountries = System.Label.QTB_NordicBillingOnlyCountries.Split(',');
                for(String country:nordicCountries)
                {
                    if(creditNotes[0].blng__Account__r.QTB_Legal_Entity_Country__c == country){
                        nordicBillingCountriesPresent = true;
                        break;
                    }
                }
                //#15993 On Account check 
                if(creditNotes[0].QTB_On_Account_Credit__c == TRUE ){
                    nordicsOnAccountCheck = true;
                }
                //-------End of logic to check Nordic country Git #13894-----/
                
                //git ticket #28136
                //query invoice subtotal from credit line related to credit note
                List<blng__CreditNoteLine__c > creditlineWithInvAmt=new  List<blng__CreditNoteLine__c >();
                if(nordicBillingCountriesPresent && creditNotes[0].QTB_On_Account_Credit__c == FALSE )
                {
                    creditlineWithInvAmt = [SELECT Id,QTB_Invoice__r.blng__Subtotal__c FROM blng__CreditNoteLine__c WHERE QTB_Invoice__r.blng__Subtotal__c !=null and blng__CreditNote__c =: creditNotes[0].Id limit 1];
                }
                
                //git ticket #28136
                //putting OR conditon to run same query we are running for on account credit note for partial manual credit note
                if((nordicBillingCountriesPresent && creditNotes[0].QTB_On_Account_Credit__c == TRUE) ||
                   (nordicBillingCountriesPresent && creditNotes[0].QTB_On_Account_Credit__c == FALSE && !creditlineWithInvAmt.isEmpty() && creditNotes[0].blng__Subtotal__c !=null
                    && creditlineWithInvAmt[0].QTB_Invoice__r.blng__Subtotal__c !=creditNotes[0].blng__Subtotal__c && /*String.isBlank(creditNotes[0].QTB_Credit_Note_Type__c) Gitlab - 30332 */ creditNotes[0].QTB_Credit_Note_Type__c == 'Manual Credit')
                  ){
                    system.debug('On Account Query >>> ');
                    creditLines = [Select CurrencyIsoCode currCode, sum(QTB_Credit_Quantity__c) Qty,sum(QTB_Subtotal__c) subTotal, QTB_Invoice__r.QTB_Custom_Invoice_Number__c InvNum, blng__Product__r.QTB_Price_Schedule_Category__c scheduleCategory, blng__Product__r.Name ProdName, sum(blng__InvoiceLine__r.QTB_Unit_Price__c) unitPrice, QTB_Product_Identifier_1__c productIdentifier,QTB_Custom_Invoice_Display__c CusInvDisplay  from blng__CreditNoteLine__c where blng__CreditNote__c = :creditNotes[0].id GROUP BY CurrencyIsoCode, blng__Product__r.QTB_Price_Schedule_Category__c,QTB_Invoice__r.QTB_Custom_Invoice_Number__c, blng__Product__r.Name, QTB_Product_Identifier_1__c,QTB_Custom_Invoice_Display__c]; 
                }
                else{
                    //Query for Credit Line Items related to Credit Note group by Currency, Product Schedule, Product, Invoice
                    system.debug('Non - On Account Query >>> '+InvoiceNumbers); 
                    creditLines = [Select CurrencyIsoCode currCode, sum(QTB_Credit_Quantity__c) Qty,sum(QTB_Subtotal__c) subTotal, QTB_Invoice__r.QTB_Custom_Invoice_Number__c InvNum, blng__Product__r.QTB_Price_Schedule_Category__c scheduleCategory, blng__Product__r.Name ProdName, sum(blng__InvoiceLine__r.QTB_Unit_Price__c) unitPrice from blng__CreditNoteLine__c where blng__CreditNote__c = :creditNotes[0].id GROUP BY CurrencyIsoCode, blng__Product__r.QTB_Price_Schedule_Category__c,QTB_Invoice__r.QTB_Custom_Invoice_Number__c, blng__Product__r.Name]; 
                }
                
                set<string> ProductNames = new set<string>();
                String Language = creditNotes[0].blng__Account__r.QTB_Language__c;
                
                for(AggregateResult ar: creditLines){
                    if(!InvoiceNumbers.contains(String.valueOf(ar.get('InvNum'))))
                        InvoiceNumbers.add(String.valueOf(ar.get('InvNum')));  
                }
                //#15993 QTB_On_Account_Credit__c check for nordics billing countries
                //Putting subtotal of credit note and invoice subtotal conditions so that Partial credit note should not be go inside this
                if(nordicBillingCountriesPresent && creditNotes[0].QTB_On_Account_Credit__c == FALSE
                   && (!creditlineWithInvAmt.isEmpty()  && creditNotes[0].blng__Subtotal__c !=null
                       && creditlineWithInvAmt[0].QTB_Invoice__r.blng__Subtotal__c == creditNotes[0].blng__Subtotal__c && /* !String.isBlank(creditNotes[0].QTB_Credit_Note_Type__c)  Gitlab - 30332 */ creditNotes[0].QTB_Credit_Note_Type__c != 'Manual Credit')
                  )
                {
                    lstusagewrapper = new List<usagewrapper>();
                    // # 2300 updated Query
                    creditNoteLineItems = [select id,QTB_Invoice__r.QTB_Custom_Invoice_Number__c,blng__Product__r.Name,blng__Product__c,blng__CreditNote__c,blng__Subtotal__c,blng__InvoiceLine__c,QTB_Credit_Quantity__c, blng__InvoiceLine__r.blng__UsageSummary__c,blng__CreditNote__r.QTB_Country__c from blng__CreditNoteLine__c where blng__CreditNote__c =: creditNotes[0].id];
                    set<string> usageSummaries = new set<string>();
                Map<Id,blng__CreditNoteLine__c> prdQty=new Map<Id,blng__CreditNoteLine__c>();
                Map<Id,blng__CreditNoteLine__c> uniqInvoice=new Map<Id,blng__CreditNoteLine__c>();
                    if(creditNoteLineItems.size()>0 && creditNoteLineItems != null) {   
                        for(blng__CreditNoteLine__c Crdline:creditNoteLineItems){
                            usageSummaries.add(Crdline.blng__InvoiceLine__r.blng__UsageSummary__c);
                            if(Crdline.blng__InvoiceLine__r.blng__UsageSummary__c != null && !invoiceMap.containskey(Crdline.blng__InvoiceLine__r.blng__UsageSummary__c)){
                                invoiceMap.put(Crdline.blng__InvoiceLine__r.blng__UsageSummary__c,Crdline.QTB_Invoice__r.QTB_Custom_Invoice_Number__c); 
                            }
                            // # 2300 capture the Usage summary and creditnoteline
                            if(!prdQty.containskey(Crdline.blng__Product__c)){
                                prdQty.put(Crdline.blng__InvoiceLine__r.blng__UsageSummary__c,Crdline);
                            }
                        }
                        //Remove blanks and nulls
                        usageSummaries.remove('');
                        usageSummaries.remove(null);
                    }

                    //Query for Usages related to invoice's usageSummaries with a proper Order 'QTB_Department_Code__c','QTB_Division_Code__c','QTB_Price_Schedule_Category__c' & 'product2.Name'
                    //#13521
                    List<blng__Usage__c> usages = new List<blng__Usage__c>();
                    if(!usageSummaries.isEmpty()){
                        
                        usages = [Select blng__UsageSummary__c,blng__OrderProduct__r.Product2.Name ,blng__OrderProduct__r.product2.ProductCode,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c ,QTB_Division_Code__c ,QTB_Department_Code__c ,QTB_Rated_Amount__c ,blng__UsageSummary__r.blng__UnitPrice__c,blng__UnitPrice__c,blng__UsageSummary__r.blng__SummaryStartDate__c,blng__Subtotal__c,blng__Account__c,blng__OrderProduct__c,
                                  QTB_Department_Name__c,QTB_Custom_Invoice_Display__c,blng__Account__r.QTB_Display_Custom_Product_Names__c,blng__Account__r.QTB_Language__c ,QTB_Level_1_Name__c ,QTB_Level_1_Code__c,QTB_Division_Name__c,QTB_Rated_Unit_Price__c ,QTB_Invoice_Quantity__c,blng__PreratedQuantity__c,blng__PreratedAmount__c, blng__Quantity__c,QTB_Term__c,QTB_Work_Order_ID__c,QTB_Requestor__c,blng__OrderProduct__r.Product2.Id,QTB_Legal_Entity_Country__c,QTB_Prerated_Unit_Price__c,QTB_Product_Identifier_1__c,QTB_Price_Tier__c from blng__Usage__c where blng__UsageSummary__c in :usageSummaries order by QTB_Level_1_Code__c NULLS LAST, QTB_Division_Code__c NULLS LAST,QTB_Department_Code__c NULLS LAST, blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c NULLS LAST,QTB_Work_Order_ID__c NULLS LAST,blng__OrderProduct__r.product2.Name NULLS LAST];
                    }
                    Map<string,GroupWrapperCls> groupWrapperMap = new Map<string,GroupWrapperCls>();
                    List<Map<string,GroupWrapperCls>> usagesWrapperList = new List<Map<string,GroupWrapperCls>>();
                    
                    for(blng__Usage__c usg : usages){
                        string keyString = '';
                        //#21175 Level 1 code addition
                        if(usg.QTB_Level_1_Code__c != null){
                            keyString = usg.QTB_Level_1_Code__c;
                        }else{
                            keyString = 'Null';
                        }
                        //#21175 Level 1 code (+)
                        if(usg.QTB_Department_Code__c != null){
                            keyString += usg.QTB_Department_Code__c;
                        }else{
                            keyString += 'Null';
                        }
                        if(usg.QTB_Division_Code__c != null){
                            keyString += usg.QTB_Division_Code__c;
                        }else{
                            keyString += 'Null';
                        }
                        if(usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c != null){
                            keyString += usg.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c;
                        }
                        else{
                            keyString += 'Null';
                        }
                        if(usg.QTB_Product_Identifier_1__c != null){
                            keyString += usg.QTB_Product_Identifier_1__c;
                        }else{
                            keyString += 'Null';
                        }
                        //2300 Adding Invoice number
                        if(invoiceMap.get(usg.blng__UsageSummary__c) != null){
                            keyString +=invoiceMap.get(usg.blng__UsageSummary__c);
                        }else{
                            keyString += 'Null';
                        }
                        //#20247 Addition of Price tier for grouping
                        if(usg.QTB_Price_Tier__c != null){
                            keyString += usg.QTB_Price_Tier__c;
                        }else{
                            keyString += 'Null';
                        }
                        if(usg.blng__OrderProduct__r.product2.Name != null){
                            keyString += usg.blng__OrderProduct__r.product2.Name;
                        }else{
                            keyString += 'Null';
                        }
                    
                        //Create Map based on Key and add map to the List for maintaining the 'Proper Order/ Sequence'
                        if(usagesWrapperList.size() > 0){
                            boolean addMapToList = true;
                            for(Map<string,GroupWrapperCls> wrpMap : usagesWrapperList){
                                //Already key exist
                                if(wrpMap.containskey(keyString)){
                                    addMapToList = false;
                                    GroupWrapperCls wrp = wrpMap.get(keyString);
                                    //Over ride the map 
                                    wrpMap.put(keyString,new GroupWrapperCls(usg,wrp));
                                }
                            }
                            if(addMapToList){
                                groupWrapperMap = new Map<string,GroupWrapperCls>();
                                //Create new Map, so pass null
                                groupWrapperMap.put(keyString,new GroupWrapperCls(usg,null));
                                usagesWrapperList.add(groupWrapperMap);
                            }
                        }else{
                            groupWrapperMap = new Map<string,GroupWrapperCls>();
                            //Create new Map, so pass null 
                            groupWrapperMap.put(keyString,new GroupWrapperCls(usg,null));
                            usagesWrapperList.add(groupWrapperMap);
                        }
                    }
                    //Variable Declaration
                    String[] usageCodes = New String[]{};
                        set<string> usageLevelCode = new set<string>();
                    set<string> accProductNames = new set<string>();
                    Map<string, integer>    L1L2L3GrpMap = new Map<string, integer>();
                    //#13521 New map to hold keystring without product identifier value
                    Map<string, integer>    L1L2L3L4GrpMap = new Map<string, integer>();
                    List<GroupWrapperCls> finalGroupedUsagesTemp = new List<GroupWrapperCls>();
                    List<GroupWrapperCls> finalGroupedUsages = new List<GroupWrapperCls>();
                    List<GroupWrapperCls> tempOrderList = new List<GroupWrapperCls>();
                    List<GroupWrapperCls> tempOrderListFinal = new List<GroupWrapperCls>();
                    set<string> checkDup = new set<string>();
                    Map<string, integer> L1L2L3GrpCompareMap = new Map<string, integer>();
                    //3 level of grouping
                    //Grouping based on certain field values(lev1code, divisionCode, departmentCode,workOrderId(Nordea))
                    if(!usages.isEmpty()){
                        //Iterate all the wrapper records
                        for(Map<string,GroupWrapperCls> wrpMap : usagesWrapperList){
                            for(GroupWrapperCls ar : wrpMap.values()){
                                //Add all the wrapper records to a Final Wrapper List 
                                finalGroupedUsagesTemp.add(ar);
                                usageLevelCode.add(String.valueOf(ar.lev1code));
                                accProductNames.add(String.valueOf(ar.productCode));
                                string grpKeyString = '';
                                string grpKeyOrder = '';
                                if(ar.lev1code != null){
                                    grpKeyString += ar.lev1code;
                                    usageCodes.add(String.valueOf(ar.lev1code));
                                }
                                if(ar.divisionCode != null){
                                    grpKeyString += ar.divisionCode;
                                    
                                    usageCodes.add(String.valueOf(ar.divisionCode));
                                }
                                if (ar.departmentCode != null){
                                    grpKeyString += ar.departmentCode;
                                    
                                    usageCodes.add(String.valueOf(ar.departmentCode));
                                }
                                //#13521 Addition of keystring to the new map for Subtotal calculation
                                if(grpKeyString != ''){
                                    if(L1L2L3L4GrpMap.containsKey(grpKeyString)){
                                        L1L2L3L4GrpMap.put(grpKeyString,L1L2L3L4GrpMap.get(grpKeyString)+1);
                                    }else{
                                        L1L2L3L4GrpMap.put(grpKeyString,1);
                                    }
                                }
                                if (ar.productIdentifier != null){
                                    grpKeyString += ar.productIdentifier;
                                    usageCodes.add(String.valueOf(ar.productIdentifier));
                                }
                                //#20247 Addition of Price Tier 
                                if (ar.priceTier != null){
                                    grpKeyString += ar.priceTier;
                                    usageCodes.add(String.valueOf(ar.priceTier));
                                }
                                
                                System.Debug('<<<<GrpKeyString>>>>'+grpKeyString);
                                //Add to Grouping Map which contains Number of records fr each Group(Key).
                                if(grpKeyString != ''){
                                    if(L1L2L3GrpMap.containsKey(grpKeyString)){
                                        L1L2L3GrpMap.put(grpKeyString,L1L2L3GrpMap.get(grpKeyString)+1);
                                    }else{
                                        L1L2L3GrpMap.put(grpKeyString,1);
                                    }
                                }
                            }
                        }
                        //Keep all the schedule category in a Order manner
                        for(GroupWrapperCls ar : finalGroupedUsagesTemp){
                            string grpKeyString = '';
                            
                            if(ar.lev1code != null){
                                grpKeyString += ar.lev1code;
                                
                            }
                            if(ar.divisionCode != null){
                                grpKeyString += ar.divisionCode;
                                
                            }
                            if (ar.departmentCode != null){
                                grpKeyString += ar.departmentCode;
                                
                            }
                            if (ar.productIdentifier != null){
                                grpKeyString += ar.productIdentifier;
                            }
                            //#20247 Addition of Price Tier
                            if (ar.priceTier != null){
                                grpKeyString += ar.priceTier;
                            }
                            //Add to Grouping Map
                            if(grpKeyString != ''){
                                if(L1L2L3GrpCompareMap.containsKey(grpKeyString)){
                                    L1L2L3GrpCompareMap.put(grpKeyString,L1L2L3GrpCompareMap.get(grpKeyString)+1);
                                }else{
                                    L1L2L3GrpCompareMap.put(grpKeyString,1);
                                }
                            }else{
                                //These are the records where we don't have L1/L2/L3
                                finalGroupedUsages.add(ar);
                            }
                            //Grouping key present or not
                            if(L1L2L3GrpMap.containsKey(grpKeyString)){
                                //Grouping number matches means the grouping is already having the full records for this group
                                if(L1L2L3GrpMap.get(grpKeyString) == L1L2L3GrpCompareMap.get(grpKeyString)){
                                    system.debug('Number matches---**'+L1L2L3GrpMap.get(grpKeyString)+ '  '+ ar.productName);
                                    //Multiple records are there in the group
                                    if(tempOrderListFinal.size() > 0){
                                        //As we have added the current record so need to Sort/Order for the schedule catagory
                                        if(checkDup.contains(ar.schedulecategory)){
                                            for(integer i=0; i< tempOrderList.size() ; i++){
                                                if(tempOrderList[i].schedulecategory == ar.schedulecategory){
                                                    tempOrderListFinal.add(i,ar);
                                                    break;
                                                }
                                            }
                                            tempOrderList.clear();
                                            tempOrderList.addAll(tempOrderListFinal);
                                        }else{
                                            checkDup.add(ar.schedulecategory);
                                            tempOrderList.add(ar);
                                            tempOrderListFinal.add(ar);
                                        }
                                        
                                        finalGroupedUsages.addAll(tempOrderListFinal);
                                    }else{//First time number matches
                                        // Only 1 record present for that Group
                                        finalGroupedUsages.add(ar);
                                    }
                                    checkDup = new set<string>();
                                    tempOrderList = new List<GroupWrapperCls>();
                                    tempOrderListFinal = new List<GroupWrapperCls>();
                                }else{//Grouping number not matches
                                    //Already present the key// More number of records in the grouping
                                    //Start Order/Sort for Schedule Category for all the records for that group
                                    if(checkDup.contains(ar.schedulecategory)){
                                        for(integer i=0; i< tempOrderList.size() ; i++){
                                            if(tempOrderList[i].schedulecategory == ar.schedulecategory){
                                                tempOrderListFinal.add(i,ar);
                                                break;
                                            }
                                        }
                                        tempOrderList.clear();
                                        tempOrderList.addAll(tempOrderListFinal);
                                        //First time the record came to the group
                                    }else{
                                        checkDup.add(ar.schedulecategory);
                                        tempOrderList.add(ar);
                                        tempOrderListFinal.add(ar);
                                    }
                                }
                                
                            }
                        }
                        
                    }
                    integer invnum = 1;
                    Map<string, integer> L1L2L3GrpCompareMap1 = new Map<string, integer>();
                    Map<string, Decimal> L1L2L3GrpSubTotalMap = new Map<string, Decimal>();
                    //w.header6 = '20';
                    for(GroupWrapperCls ar : finalGroupedUsages){
                        usagewrapper w = new usagewrapper();
                        w.inv_linenum = invnum++;
                        w.usageproduct = ar.CusInvDisplay;
                        if(prdQty.containskey(ar.USrecordId) && prdQty.keyset().size() > 0){
                            w.lineqty=String.valueOf(prdQty.get(ar.USrecordId).QTB_Credit_Quantity__c.setScale(2, RoundingMode.HALF_UP)*(-1));
                            //w.lineqty=String.valueOf(prdQty.get(ar.USrecordId).QTB_Credit_Quantity__c.setScale(2, RoundingMode.HALF_UP)*(-1));//25338
                            w.lineqty=ar.preratequantity !=null ?String.valueOf(ar.preratequantity.setScale(2, RoundingMode.HALF_UP)*(-1)): null; //25338
                            
                        }
                        //Addition of POGR
                        w.POGR = creditNotes[0].blng__Account__r.QTB_EDI_Identifier__c != null? creditNotes[0].blng__Account__r.QTB_EDI_Identifier__c : '';
                        //when credit note is posted then we have to take value from rated amount instead of pre rated amount.
                        //as when we have rated amount is present then we have to take that.
                        //in below condition we are taking data from usage instead of creditline as a part of //25338
                        if(creditNotes[0].blng__Status__c == 'Posted'){
                            Decimal usageratedamount = double.valueof(ar.ratedAmount);
                            w.invlineamount= usageratedamount !=null ?String.valueOf(usageratedamount.setScale(2, RoundingMode.HALF_UP)*(-1)): null; //25338
                        }else if(creditNotes[0].blng__Status__c == 'Draft' && ar.prerateamount != 0.0 ){
                            Decimal usagepreamount = double.valueof(ar.prerateamount);
                            //in Draft credit note value should alaways coming from pre rated amount only from Usage level as a part of //25338
                            w.invlineamount=ar.prerateamount !=null ?String.valueOf(ar.prerateamount.setScale(2, RoundingMode.HALF_UP)*(-1)): null; //25338
                        }else{
                            //when quantity is not null then usagesummary quantity should be multiply by usage summary unit price 
                            if(String.valueOf(ar.usQuantity) != null && String.valueOf(ar.usSumUnitprice) != null){
                                w.invlineamount = String.valueOf(Decimal.valueof(double.valueOf(ar.usQuantity)*double.valueOf(ar.usSumUnitprice)).setScale(2, RoundingMode.HALF_UP)*(-1)); // # 2300
                                System.debug(' w.invlineamount  else = ' + w.invlineamount );
                            }
                        }
                        //For both Draft and Posted
                        Decimal usageunitprice =0;
                        //US 2704 production issue related to unit price Fix start 
                        if(ar.prerateamount !=null && ar.prerateamount > 0){
                            if(w.lineqty != null && decimal.valueOf(w.lineqty) != 0 && w.invlineamount !=null){
                                usageunitprice = double.valueof(decimal.valueOf(w.invlineamount)/decimal.valueOf(w.lineqty));
                                w.unitamt = String.valueOf(usageunitprice.setScale(4, RoundingMode.HALF_UP));
                            }
                        }
                        else{
                            w.unitamt = ar.preratedUnitPrice !=null ? String.valueOf(ar.preratedUnitPrice.setScale(4, RoundingMode.HALF_UP)) : '';

                        }
                        //US 2704 production issue related to unit price Fix end 
                        if(ar.scheduleCategory!= null){
                            w.usg_category = ar.scheduleCategory;  
                        }
                        
                        //Check the records for grouping and adding line 40th Line at the proper place
                        usageSubtotalWrapper usWrapSub = new usageSubtotalWrapper();
                        //New Grouping logic based on Level1/ level2/ level3/ workorder id
                        string grpKeyString = '';
                        
                        if(ar.lev1code != null){
                            grpKeyString += ar.lev1code;
                            
                        }
                        if(ar.divisionCode != null){
                            grpKeyString += ar.divisionCode;
                            
                        }
                        if (ar.departmentCode != null){
                            grpKeyString += ar.departmentCode;
                        }
                        if(grpKeyString != ''){
                            if(L1L2L3GrpCompareMap1.containsKey(grpKeyString)){
                                L1L2L3GrpCompareMap1.put(grpKeyString,L1L2L3GrpCompareMap1.get(grpKeyString)+1);
                            }else{
                                    L1L2L3GrpCompareMap1.put(grpKeyString,1);
                            }
                        }
                        
                        //Check if the number of records for grouping is same or not?
                        //Grouping number matches, then add Line No 40(Subtotal)
                        if(L1L2L3L4GrpMap.containsKey(grpKeyString)){
                            if(L1L2L3L4GrpMap.get(grpKeyString) == L1L2L3GrpCompareMap1.get(grpKeyString)){
                                //Multiple records are there in the group
                                if(L1L2L3GrpSubTotalMap.containskey(grpKeyString)){
                                   // usWrapSub.subtotal40thLine = (L1L2L3GrpSubTotalMap.get(grpKeyString)  + decimal.valueOf(w.invlineamount)*(-1)).setScale(2, RoundingMode.HALF_UP);25338
                                   //in above commented code -1 is before setscale but it should be multiply after  sescale to achive requirement as other places also same thing is implemented
                                    usWrapSub.subtotal40thLine = (L1L2L3GrpSubTotalMap.get(grpKeyString)  + decimal.valueOf(w.invlineamount)).setScale(2, RoundingMode.HALF_UP)*(-1);
                                    w.usageSubtotal = usWrapSub;
                                }else{
                                    //Match in first time(only one occurance)
                                    usWrapSub.subtotal40thLine = decimal.valueOf(w.invlineamount).setScale(2, RoundingMode.HALF_UP)*(-1);
                                    w.usageSubtotal = usWrapSub;
                                    //Just keep the map in the sync // Not required to add the amount
                                    L1L2L3GrpSubTotalMap.put(grpKeyString, decimal.valueOf(w.invlineamount));
                                }
                            }else{//Grouping number not matches
                                //Already present the key// More number of records in the grouping
                                if(L1L2L3GrpSubTotalMap.containskey(grpKeyString)){
                                    L1L2L3GrpSubTotalMap.put(grpKeyString,L1L2L3GrpSubTotalMap.get(grpKeyString) + decimal.valueOf(w.invlineamount));
                                }else{
                                    //First time key
                                    L1L2L3GrpSubTotalMap.put(grpKeyString, decimal.valueOf(w.invlineamount));
                                }
                                System.debug('<<AfterL1L2L3GrpSubTotalMap>> '+L1L2L3GrpSubTotalMap.size()+'<<usWrapSub.subtotal40thLine>> '+usWrapSub.subtotal40thLine);
                            }
                        }
                        //Adding negative symbol for all nordics country
                        usageSubtotalWrapper usageSubtotalVar=new usageSubtotalWrapper();
                        if(w!=null && w.usageSubtotal !=null){
                            usageSubtotalVar= w.usageSubtotal;
                            usageSubtotalVar.subtotal40thLine= usageSubtotalVar.subtotal40thLine*(-1);
                            w.usageSubtotal=usageSubtotalVar;
                        }
                        lstusagewrapper.add(w);  
                    }
                } 
                //git ticket #28136 logic 
                //For partial manual creit note data should be come from credit lines instead of getting from usages 
                //adding partial manual credit note same as on account credit note 
                else
                {
                    for(AggregateResult ar : creditLines)
                    {
                        ProductNames.add(String.valueOf(ar.get('ProdName')));
                    }
                    //Get translations of the product names in the account language
                    List<SBQQ__Localization__c> localization;
                    map<string,string> mapLocalization = new map<string,string>();
                    if(!ProductNames.isEmpty())
                    {
                        localization = [select id,SBQQ__Text__c,SBQQ__Product__r.Name,SBQQ__APIName__c,SBQQ__Language__c from SBQQ__Localization__c Where SBQQ__Product__r.Name IN:ProductNames and SBQQ__Language__c =:Language and SBQQ__APIName__c = 'Name'];  
                        
                        for(SBQQ__Localization__c loc:localization)
                        {
                            maplocalization.put(loc.SBQQ__Product__r.Name,loc.SBQQ__Text__c);
                        }
                    }
                    //Credit Note Line items mapping
                    integer row = 1;
                    for(AggregateResult ar : creditLines)
                    {
                        system.debug('ar=='+ar);
                        if(!InvoiceNumbers.contains(String.valueOf(ar.get('InvNum'))))
                            InvoiceNumbers.add(String.valueOf(ar.get('InvNum')));  
                        
                        LineItems li = new LineItems();   
                        li.RowNum=String.valueOf(row);
                        
                        if(ar.get('qty') != '' && ar.get('qty') != null){
                            Decimal Qty = double.valueof(ar.get('qty'))*-1;
                            li.crLIQty = String.valueOf(Qty);
                        }
                        if(ar.get('subTotal') != '' && ar.get('subTotal') != null){
                            Decimal subTotal = double.valueof(ar.get('subTotal'));
                            subTotal = subTotal*-1;
                            li.crLISubTotal = String.valueOf(subTotal.setScale(2, RoundingMode.HALF_UP));
                        }
                        
                        if((nordicBillingCountriesPresent && creditNotes[0].QTB_On_Account_Credit__c == TRUE)
                           || (nordicBillingCountriesPresent && creditNotes[0].QTB_On_Account_Credit__c == FALSE && !creditlineWithInvAmt.isEmpty()  && creditNotes[0].blng__Subtotal__c !=null
                               && creditlineWithInvAmt[0].QTB_Invoice__r.blng__Subtotal__c !=creditNotes[0].blng__Subtotal__c && /*String.isBlank(creditNotes[0].QTB_Credit_Note_Type__c) Gitlab - 30332 */ creditNotes[0].QTB_Credit_Note_Type__c == 'Manual Credit') ){
                            if(ar.get('scheduleCategory') != '' && ar.get('scheduleCategory') != null ){
                                li.ProdScheduleCateg = String.valueOf(ar.get('scheduleCategory'));
                            }
                            if(ar.get('CusInvDisplay') != '' && ar.get('CusInvDisplay') != null){
                                li.ProdName = String.valueOf(ar.get('CusInvDisplay'));
                            }
                            if(ar.get('qty') != 0 && ar.get('qty') != null){
                                /*Gitlab 28417 The formula field 'blng__CreditNoteLine__c.QTB_Unit_Price__c' gives incorrect values in aggregate queries due to grouping. 
									To fix this, we calculate UnitPrice as Subtotal/Quantity after grouping*/
                                Decimal unitPrice = double.valueOf(decimal.valueOf(li.crLISubTotal)/decimal.valueOf(li.crLIQty));
                                li.crLIUnitPrice = String.valueOf(unitPrice.setScale(3, RoundingMode.HALF_UP)); 
                            }
                            li.POGR =  creditNotes[0].blng__Account__r.QTB_EDI_Identifier__c != null? creditNotes[0].blng__Account__r.QTB_EDI_Identifier__c : '';
                        }
                        else{
                            if(ar.get('scheduleCategory') != '' && ar.get('scheduleCategory') != null && prScCategoryTranslation.containsKey(String.valueOf(ar.get('scheduleCategory'))) && !nordicBillingCountriesPresent){
                                li.ProdScheduleCateg = prScCategoryTranslation.get(String.valueOf(ar.get('scheduleCategory')));
                            }
                            if(ar.get('ProdName') != '' && ar.get('ProdName') != null && !nordicBillingCountriesPresent){
                                string ProdName = String.valueOf(ar.get('ProdName'));
                                if(maplocalization.containsKey(ProdName))
                                {
                                    li.ProdName = maplocalization.get(ProdName);
                                }
                                else
                                {
                                    li.ProdName = ProdName;                    
                                }
                            }
                            if(ar.get('unitPrice') != '' && ar.get('unitPrice') != null){
                                Decimal unitPrice = double.valueOf(ar.get('unitPrice'));
                                li.crLIUnitPrice = String.valueOf(unitPrice.setScale(3, RoundingMode.HALF_UP));
                            }
                        }  
                        CrLineItems.add(li);
                        row++;
                    }  
                }
                //git ticket #28136 end 
                
                
                
                this.Header = new HeaderLines(creditNotes[0],ContactEmail,InvoiceNumbers,ISOCode,accountLanguage.get(Language)); 
            }
            else if(String.isNotBlank(recID) && isUsageWithinLimit == 'false'){ //Gitlab US#24844 
                System.debug('QTB_Generate_Creditnote_Ctrl_else_if@@');
                List<blng__CreditNote__c> credList = [SELECT Id,NAME, blng__Account__r.QTB_Legal_Entity_Country__c,QTB_On_Account_Credit__c,
                                                      QTB_StoreApixHeaderExtract__c,QTB_StoreApixCreditNoteLineExtract__c,
                                                      QTB_StoreApixUsageExtract1__c,QTB_StoreApixUsageExtract2__c,QTB_StoreApixUsageExtract3__c,
                                                      QTB_StoreApixUsageExtract4__c,QTB_StoreApixUsageExtract5__c,QTB_StoreApixUsageExtract6__c
                                                      FROM blng__CreditNote__c
                                                      WHERE Id =: recID];
                //-------Start of logic to check Nordic country Git #13894-----/
                List<String> nordicCountries = System.Label.QTB_NordicBillingOnlyCountries.Split(',');
                for(String country:nordicCountries)
                {
                    if(credList[0].blng__Account__r.QTB_Legal_Entity_Country__c == country){
                        nordicBillingCountriesPresent = true;
                        break;
                    }
                }
                //#15993 On Account check 
                if(credList[0].QTB_On_Account_Credit__c == TRUE ){
                    nordicsOnAccountCheck = true;
                }
                Header =  (HeaderLines) JSON.deserialize(credList[0].QTB_StoreApixHeaderExtract__c, HeaderLines.class);
                CrLineItems = new List<LineItems>();
                CrLineItems = (List<LineItems>) JSON.deserialize(credList[0].QTB_StoreApixCreditNoteLineExtract__c, List<LineItems>.class);
                if(credList[0].QTB_StoreApixUsageExtract1__c !=null){
                    String usageExtract = credList[0].QTB_StoreApixUsageExtract1__c;
                    if (credList[0].QTB_StoreApixUsageExtract2__c != null) {
                        usageExtract += credList[0].QTB_StoreApixUsageExtract2__c;
                    }
                    if (credList[0].QTB_StoreApixUsageExtract3__c != null) {
                        usageExtract += credList[0].QTB_StoreApixUsageExtract3__c;
                    }
                    if (credList[0].QTB_StoreApixUsageExtract4__c != null) {
                        usageExtract += credList[0].QTB_StoreApixUsageExtract4__c;
                    }
                    if (credList[0].QTB_StoreApixUsageExtract5__c != null) {
                        usageExtract += credList[0].QTB_StoreApixUsageExtract5__c;
                    }
                    if (credList[0].QTB_StoreApixUsageExtract6__c != null) {
                        usageExtract += credList[0].QTB_StoreApixUsageExtract6__c;
                    }
                    lstusagewrapper = (List<usagewrapper>) JSON.deserialize(usageExtract, List<usagewrapper>.class);
                }
            }
        }catch(Exception e) {
            QTB_ExceptionLogger.enable(); //Gitlab US#24844
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_Generate_Creditnote_Ctrl');
        }
    }
    
    //Credit Note Header Mapping
    public class HeaderLines{
        public string crNtNum{get; set;}
        public string crNtLayout{get; set;}
        public String crNtInvNum{get; set;}
        public string Language{get; set;}
        public string crNtDate{get; set;}
        public string crNtCustNum{get; set;}   
        public string crNtTaxId{get;set;}
        public string crNtAcctStreet{get;set;}
        public string crNtAcctZip{get;set;}
        public string crNtAcctCity{get;set;}
        public string crNtAcctCountry{get;set;}
        //#13894 Nordics Service from and to dates
        public string print_from_date{get;set;}
        public string print_to_date{get;set;}
        public string legalEntPhone{get;set;}
        public string BlgContEmail{get;set;}
        public string crNtInvNotes{get;set;}
        public string crNtSubtotal{get;set;}
        public string crNtTax{get;set;}
        public string crNtTotalAmount{get;set;}
        public string legalEntBank{get;set;}
        public string legalEntAccNo{get;set;}
        public string legalEntIban{get;set;}
        //Swift code addition for nordics
        public string swiftCode{get; set;}
        public string legalEntCountry{get;set;} 
        public string crNtAcctInvName{get;set;} 
        public string crNtCurrency{get;set;}   
        public string ReportDate{get;set;}
        public string ReportTime{get;set;}
        public string crNtInvNos{get;set;}
        public string crNtCustNote{get;set;}
        //Changes for differentiate between 'Draft' and 'Posted' Credit Notes - Story #742
        public string crNtStatus{get;set;}
        
        
        public HeaderLines(blng__CreditNote__c creditnote,string ContactEmail,String[] InvoiceNumbers, String isoCode, String lang)
        {   
            try{
                //-------Start of logic to check Nordic country Git #13894-----/
                Boolean nordicBillingCountriesPresent =false;
                List<String> nordicCountries = System.Label.QTB_NordicBillingOnlyCountries.Split(',');
                for(String country:nordicCountries)
                {
                    if(creditnote.blng__Account__r.QTB_Legal_Entity_Country__c == country){
                        nordicBillingCountriesPresent = true;
                        break;
                    }
                }
                //-------End of logic to check Nordic country Git #13894-----/
                crNtNum = creditnote.Name;
                crNtLayout = isoCode + 'IDS';
                if(creditnote.blng__Status__c=='Posted')
                {
                    crNtInvNum = creditnote.QTB_Custom_Invoice_Number__c;                
                }
                else if(creditnote.blng__Status__c=='Draft')
                {
                    crNtInvNum = 'TEMP-'+creditnote.Name;
                }
                Language = lang;
                if(creditnote.blng__CreditNoteDate__c!=null)
                {
                    Date print_invoice_date = creditnote.blng__CreditNoteDate__c;
                    crNtDate = DateTime.newInstance(print_invoice_date.year(),print_invoice_date.month(),print_invoice_date.day()).format('dd/MM/YYYY');
                }
                crNtCustNum = creditnote.blng__Account__r.QTB_Customer_Number__c;
                crNtTaxId = creditnote.blng__Account__r.QTB_Tax_ID__c;
                crNtAcctStreet = creditnote.blng__Account__r.BillingStreet;
                crNtAcctZip = creditnote.blng__Account__r.BillingPostalCode;
                crNtAcctCity = creditnote.blng__Account__r.BillingCity;
                crNtAcctCountry = creditnote.blng__Account__r.BillingCountry;
                legalEntPhone = creditnote.blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c;
                BlgContEmail = ContactEmail;
                crNtInvNotes = creditnote.blng__Account__r.QTB_Invoice_Notes__c;
                double crSubtotal = creditnote.blng__Subtotal__c.setScale(2);
                crNtSubtotal = String.valueOf(crSubtotal*-1);
                //#21361 Override fields addition
                double crTax=creditnote.QTB_Tax_Override_Amount__c.setScale(2);
                crNtTax = String.valueOf(crTax*-1);
                double CRTotal = creditnote.QTB_Total_Amount_with_Tax_Override__c.setScale(2);
                crNtTotalAmount = String.valueOf(CRTotal*-1);
                legalEntBank = creditnote.blng__Account__r.QTB_Contract_Entity__r.QTB_Bank_Name__c;
                legalEntAccNo = creditnote.blng__Account__r.QTB_Contract_Entity__r.QTB_Account_Number__c;
                legalEntCountry = creditnote.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c;    
                legalEntIban = creditnote.blng__Account__r.QTB_Contract_Entity__r.QTB_IBAN__c;
                
                //Swift code Addition in the Apix extract for Nordics 
                swiftCode = creditnote.blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c != null? creditnote.blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c : '';
                crNtAcctInvName = creditnote.blng__Account__r.QTB_Billing_Account_Invoice_Name__c;    
                crNtCurrency = creditnote.CurrencyIsoCode; 
                ReportDate = DateTime.newInstance(system.today().year(),system.today().month(),system.today().day()).format('dd/MM/YYYY');
                ReportTime = String.valueOf(datetime.now().time());
                crNtInvNos = string.join(InvoiceNumbers,',');
                crNtCustNote = string.valueOf(creditnote.blng__Notes__c);  
                //Changes for differentiate between 'Draft' and 'Posted' Credit Notes - Story #742
                crNtStatus = QTB_Generate_Creditnote_Ctrl.CREDITNOTE_POSTED_BILLING_STATUS;
                if (creditnote.blng__Status__c != null && String.valueOf(creditnote.blng__Status__c) == QTB_Constants.CREDITNOTELINE_STATUS_DRAFT) {
                    crNtStatus = QTB_Generate_Creditnote_Ctrl.CREDITNOTE_DRAFT_BILLING_STATUS;
                }
                /*--- #13894 Start of Nordics Service date ---*/
                if(!InvoiceNumbers.isEmpty()){
                    if(nordicBillingCountriesPresent && creditNote.QTB_On_Account_Credit__c == FALSE){
                        date invoiceLineStartdate;
                        date invoiceLineEnddate;// Print to date update for nordics
                        List<blng__InvoiceLine__c> invoiceLineItems = new List<blng__InvoiceLine__c>();
                        
                        invoiceLineItems = [select id,blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__StartDate__c,blng__EndDate__c ,blng__Invoice__r.blng__InvoiceDate__c from blng__InvoiceLine__c where blng__Invoice__r.QTB_Custom_Invoice_Number__c =:InvoiceNumbers ];
                        
                        if(invoiceLineItems.size()>0 && invoiceLineItems != null) {   
                            for(blng__InvoiceLine__c invLin:invoiceLineItems){
                                if(invoiceLineStartdate == null && invLin.blng__StartDate__c != null){
                                    invoiceLineStartdate = invLin.blng__StartDate__c;
                                }
                                if(invoiceLineEnddate == null && invLin.blng__EndDate__c != null){
                                    invoiceLineEnddate = invLin.blng__EndDate__c;
                                }
                            }
                            if(invoiceLineStartdate != null && invoiceLineEnddate != null){
                                print_from_date = DateTime.newInstance(invoiceLineStartdate.year(),invoiceLineStartdate.month(),invoiceLineStartdate.day()).format('dd/MM/yyyy');
                                print_to_date = invoiceLineEnddate != null? DateTime.newInstance(invoiceLineEnddate.year(),invoiceLineEnddate.month(),invoiceLineEnddate.day()).format('dd/MM/yyyy') : ''; 
                            }
                        }
                    }
                    else{
                        print_from_date = '';
                        print_to_date = '';
                    }
                }
                /*--- #13894 End of Nordics Service date ---*/
                //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            }catch(Exception e) {
                QTB_ExceptionLogger.enable(); //Gitlab US#24844
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_Generate_Creditnote_Ctrl.HeaderLines');
            }
        }    
    }
    
    public class LineItems{
        public String RowNum{get; set;}
        public string ProdScheduleCateg{get; set;}
        public String ProdName{get; set;} 
        public String POGR{get; set;} 
        public string crLIQty{get;set;}  
        public string crLIUnitPrice{get;set;}
        public string crLISubTotal{get;set;}
    }
    public class GroupWrapperCls{
        public string productName;
        public string productCode;
        public String scheduleCategory;
        public string divisionCode;
        public string departmentCode;
        //#13521
        public string productIdentifier;
        //#20247
        public string priceTier;
        //#15071 Addition of POGR
        public string POGR;
        public decimal ratedAmount;
        public decimal usSumUnitprice;
        public string departmentname;
        public boolean displayPnameCheck;
        public string AccLanguage;
        public string lev1name;
        public string lev1code;
        public string divisionname;
        public decimal ratedunitPrice;
        public decimal quantity;
        public decimal preratequantity;
        public decimal prerateamount;
        public decimal preratedUnitPrice;
        public decimal usQuantity;
        public string CusInvDisplay;
        public Date startdate;
        public Date enddate;
        public integer term;
        //Extra field for Invoice Line
        public decimal unitPriceLine;
        public decimal subtotalLine;
        //This is to identify if the record is a Usage record or a Invoice Line reocrd// Only Usage records will have the Id, else null
        public string recordId;
        public string USrecordId;
        public string productId; 
        public GroupWrapperCls(blng__Usage__c usge,GroupWrapperCls exitingWraper){
            this.productName = usge.QTB_Custom_Invoice_Display__c;
            this.productCode = usge.blng__OrderProduct__r.Product2.productCode;
            this.productId = usge.blng__OrderProduct__r.Product2.Id;
            this.scheduleCategory = usge.blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c;
            this.divisionCode = usge.QTB_Division_Code__c;
            this.departmentCode = usge.QTB_Department_Code__c;
            this.departmentname = usge.QTB_Department_Name__c;
            this.displayPnameCheck = usge.blng__Account__r.QTB_Display_Custom_Product_Names__c;
            this.AccLanguage = usge.blng__Account__r.QTB_Language__c;
            this.lev1name = usge.QTB_Level_1_Name__c;
            this.lev1code = usge.QTB_Level_1_Code__c;
            //#13521
            this.productIdentifier = usge.QTB_Product_Identifier_1__c;
            //#20247
            this.priceTier = usge.QTB_Price_Tier__c;
            this.divisionname = usge.QTB_Division_Name__c;
            this.ratedunitPrice = usge.QTB_Rated_Unit_Price__c;
            this.usSumUnitprice = usge.blng__UsageSummary__r.blng__UnitPrice__c!= null? usge.blng__UsageSummary__r.blng__UnitPrice__c:0;
            this.CusInvDisplay = usge.QTB_Custom_Invoice_Display__c;
            this.startdate = usge.QTB_Start_Date_MRC__c;
            this.enddate = usge.QTB_End_Date_MRC__c;
            if(usge.QTB_Term__c != null){
                this.term = Integer.valueOf(usge.QTB_Term__c);
            }
            //This is to identify if the record is a Usage record or a Invoice Line reocrd
            this.recordId = usge.id;
            this.USrecordId =usge.blng__UsageSummary__c;
            //Extra field for Invoice Line
            if(usge.id == null){
                //Assign the values from the temporary Usages instances to Wrapper variables
                this.productName = usge.blng__MatchingAttribute__c;
                this.productCode = usge.blng__ErrorMessage__c;
                this.unitPriceLine = usge.blng__UnitPrice__c;
                this.subtotalLine = usge.blng__Subtotal__c;
                this.displayPnameCheck = usge.QTB_UsedforRerate__c;
                this.AccLanguage = usge.QTB_Service_District__c;
            }
            //Already existing record for the Grouping, get the existing value and add it/agreegate values
            if(exitingWraper!= null){
                this.ratedAmount = (usge.QTB_Rated_Amount__c!= null? usge.QTB_Rated_Amount__c:0)+exitingWraper.ratedAmount; 
                this.quantity = (usge.QTB_Invoice_Quantity__c!= null? usge.QTB_Invoice_Quantity__c:0)+(exitingWraper.quantity); 
                this.preratequantity = (usge.blng__PreratedQuantity__c!= null? usge.blng__PreratedQuantity__c:0)+exitingWraper.preratequantity; 
                this.prerateamount = (usge.blng__PreratedAmount__c!= null? usge.blng__PreratedAmount__c:0)+exitingWraper.prerateamount; 
                this.preratedUnitPrice = (usge.QTB_Prerated_Unit_Price__c!= null? usge.QTB_Prerated_Unit_Price__c:0)+exitingWraper.preratedUnitPrice; 
                this.usQuantity = (usge.blng__Quantity__c!= null? usge.blng__Quantity__c:0)+exitingWraper.usQuantity; 
            }else{//Fresh record for the Grouping, keep the value else, values as '0'
                this.ratedAmount = usge.QTB_Rated_Amount__c!= null? usge.QTB_Rated_Amount__c:0;
                this.quantity = usge.QTB_Invoice_Quantity__c!= null? (usge.QTB_Invoice_Quantity__c):0;
                this.preratedUnitPrice = usge.QTB_Prerated_Unit_Price__c!= null? usge.QTB_Prerated_Unit_Price__c:0;
                this.preratequantity = usge.blng__PreratedQuantity__c!= null? usge.blng__PreratedQuantity__c:0;
                this.prerateamount = usge.blng__PreratedAmount__c!= null? usge.blng__PreratedAmount__c:0;
                this.usQuantity = usge.blng__Quantity__c!= null? usge.blng__Quantity__c:0;
            }
        }
    }
    //wrapper class for usage
    public class usagewrapper{
        public string usageproduct {get; set;}
        public string invlineamount {get; set;}
        public string unitamt {get; set;}
        public string lineqty {get; set;}
        public integer inv_linenum {get; set;}
        public string usg_category {get; set;}
        //#15071 Addition of POGR 
        public string POGR {get; set;}
        public usageSubtotalWrapper usageSubtotal {get;set;}
    }
    //wrapper class for getting the 40th Line Record.
    public class usageSubtotalWrapper{
        public decimal subtotal40thLine{get;set;}
        public usageSubtotalWrapper(){
            
        }
    }
    //This method is called from the Lightning component to generate the APIX credit note extract and attach it to the credit note record 
    @AuraEnabled
    public static void generateFile(String recordID) {
        try{
            List<blng__CreditNote__c> creditNotes = [select name,QTB_Last_Credit_Note_Sent__c,QTB_Custom_Invoice_Number__c,id,QTB_PO_Number__c,QTB_Credit_Note_Type__c,blng__Account__r.QTB_SITAD__c, //25446 added QTB_PO_Number__c,QTB_Site_Number__c,QTB_Credit_Note_Type__c
                                                     blng__Status__c,blng__Notes__c ,blng__Account__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c,
                                                     blng__Account__r.QTB_Language__c,CurrencyIsoCode,blng__Account__r.blng__BillToContact__r.Email,
                                                     blng__Account__r.QTB_Invoice_Delivery_Options__c,blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Account_Balance__c,
                                                     blng__CreditNoteDate__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IRM_Contact_Details__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.QTB_PAN_NO__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Email__c,
                                                     blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__TotalAmount__c,QTB_Total_Amount_with_Tax_Override__c,blng__Account__r.QTB_Legal_Entity__r.blng__Street1__c,
                                                     blng__Account__r.QTB_Legal_Entity__r.blng__Street2__c,blng__Account__r.QTB_Legal_Entity__r.blng__City__c,
                                                     blng__Account__r.QTB_Legal_Entity__r.blng__State__c,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Customer_Classification__c,
                                                     blng__Account__r.QTB_Legal_Entity__r.blng__ZipPostalCode__c,blng__Account__r.BillingStreet,
                                                     blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.BillingCountry,
                                                     blng__Account__r.QTB_Consolidation_Flag__c,blng__Account__r.QTB_HoldInd__c,blng__Account__r.QTB_HoldRequester__c,
                                                     blng__Account__r.QTB_IMCompany__c,blng__Account__r.QTB_Legal_Entity_Country__c,
                                                     //QTB_LateFee__c,QTB_SiteAdjustmentTotal__c,QTB_SiteLateFeeAmount__c,QTB_SiteNumberTotal__c,QTB_PaymentsRcvd__c,QTB_AdjustmentsRcvdAmt__c,
                                                     //QTB_PastDueBalanceTotal__c,QTB_CurrentTotalAmount__c,QTB_TotalAdjustmentAmount__c,
                                                     blng__Account__r.QTB_ContractNumber__c,blng__Account__r.QTB_CageCode__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c,blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c,
                                                     blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c,QTB_On_Account_Credit__c,
                                                     (Select id,QTB_Invoice__c,blng__Product__c,QTB_Credit_Quantity__c,blng__Product__r.QTB_Price_Schedule_Category__c,
                                                      //blng__UsageSummary__c,blng__Invoice__c,blng__UsageSummary__r.blng__SummaryEndDate__c,blng__UnitPrice__c,blng__ChargeType__c,
                                                      //QTB_HasConsumptionSchedule__c,
                                                      blng__InvoiceLine__r.blng__UsageSummary__r.blng__SummaryEndDate__c,QTB_Subtotal__c,
                                                      blng__Product__r.ProductCode,blng__TotalAmount__c,blng__TaxAmount__c,Name,blng__Subtotal__c,
                                                      blng__CreditNote__r.blng__Account__c,QTB_Invoice__r.QTB_Custom_Invoice_Number__c,blng__InvoiceLine__r.blng__UsageSummary__c,
                                                      blng__InvoiceLine__r.blng__UnitPrice__c, blng__InvoiceLine__r.Name,blng__InvoiceLine__r.blng__Product__r.Name,
                                                      blng__InvoiceLine__r.QTB_Charge_Type__c,blng__InvoiceLine__r.QTB_Inc_Quantity__c,blng__InvoiceLine__r.QTB_Unit_Price__c,
                                                      blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__CreditNote__r.QTB_On_Account_Credit__c,blng__Product__r.Name,
                                                      QTB_Account__r.QTB_Language__c,blng__CreditNote__r.blng__Account__r.QTB_SITAD__c, blng__CreditNote__r.QTB_Credit_Note_Type__c,blng__CreditNote__r.QTB_Site_Number__c,QTB_Unit_Price__c // Gitlab #28417 //25446 added blng__CreditNote__r.blng__Account__r.QTB_SITAD__c, blng__CreditNote__r.QTB_Credit_Note_Type__c,blng__CreditNote__r.QTB_Site_Number__c   //Gitlab US#22996 
                                                      /*,QTB_Subtotal_WithNegative__c Gitlab-22532*/ 
                                                      from blng__CreditNoteCreditLines__r)
                                                     from blng__CreditNote__c 
                                                     where id =: recordID];
            //Billtrust XML file generation logic starts
            //Logic to check Invoice presentment system
            if (creditNotes != null && creditNotes.size() > 0) {
                //Fetching all the Invoice presentment custom meta records
                list<QTB_Invoice_Presentment_Settings__mdt> invoicePresentSettings = [Select id, QTB_Billing_Country__c, QTB_Invoice_Presentment_System__c from QTB_Invoice_Presentment_Settings__mdt
                                                                                      where QTB_Billing_Country__c =: creditNotes[0].blng__Account__r.QTB_Legal_Entity_Country__c limit 1];
                System.debug('invoicePresentSettings>>>'+invoicePresentSettings);
                //Logic to check whether Invoice presentment is Billtrust or Apix
                if (invoicePresentSettings.size() > 0 && invoicePresentSettings[0].QTB_Invoice_Presentment_System__c != null &&
                    invoicePresentSettings[0].QTB_Invoice_Presentment_System__c == QTB_GenerateBillTrustExtractCTRL.INVOICE_PRESENTMENT_BILLTRUST) {
                        if (creditNotes[0].QTB_Last_Credit_Note_Sent__c != null) {
                            throw new AuraHandledException('The credit note is already generated'); 
                        } else {
                            QTB_GenerateCreditNoteXmlExtractCTRL.generateBillTrustXml(creditNotes, null, null);
                            
                            //Logic to update the Invoice Last Sent date
                            list<blng__CreditNote__c> creditNotesToUpdate = new list<blng__CreditNote__c>();
                            for (blng__CreditNote__c crdNt: creditNotes) {
                                if (crdNt.blng__Status__c == QTB_Constants.INVOICE_STATUS_POSTED) {
                                    blng__CreditNote__c crdNtToUpd = new blng__CreditNote__c();
                                    crdNtToUpd.id = crdNt.id;
                                    crdNtToUpd.QTB_Last_Credit_Note_Sent__c = DateTime.now();
                                    creditNotesToUpdate.add(crdNtToUpd);
                                }
                            }
                            
                            if (creditNotesToUpdate.size() > 0) {
                                update creditNotesToUpdate;
                            }
                            return;
                        }
                    }
            }
            //Billtrust XML file generation logic ends
            
            //Gitlab US#24844 -- get the usages associated with creditnotelines
            Set<Id> usageSummaryIdSet = new Set<Id>();
            for(blng__CreditNoteLine__c crdline : creditNotes[0].blng__CreditNoteCreditLines__r){
                if(crdline.blng__InvoiceLine__r.blng__UsageSummary__c != null){
                    usageSummaryIdSet.add(crdline.blng__InvoiceLine__r.blng__UsageSummary__c);
                }
            }
            Integer usageCount = 0;
            if(!usageSummaryIdSet.isEmpty()){
                usageCount = [SELECT Count() FROM blng__Usage__c WHERE blng__UsageSummary__c IN: usageSummaryIdSet]; 
            }  
            
            //Gitlab US#24844 - if usageCount is less than the limit mentioned in custom label -- QTB_ApixExtractUsageLimit, then following the existing process
            if(usageCount < Integer.valueOf(System.Label.QTB_ApixExtractUsageLimit)){
                PageReference vfPg = new PageReference ('/apex/QTB_Generate_Creditnote_Extract');
                vfPg.getParameters().put('Id',recordID);
                vfPg.getParameters().put('Lang',creditNotes[0].blng__Account__r.QTB_Language__c); 
                vfPg.getParameters().put('isUsageWithinLimit','true');//Gitlab US#24844
                Blob pageData;
                if(Test.isRunningTest()) { 
                    pageData = blob.valueOf('Unit Test');
                } else {
                    pageData = vfPg.getContent();
                } 
                
                ContentVersion conVer = new ContentVersion();
                conVer.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                if(creditNotes[0].blng__Status__c=='Posted')
                {
                    conVer.PathOnClient = 'IRM_CRN_'+creditNotes[0].QTB_Custom_Invoice_Number__c+'.txt';      
                    conVer.Title = 'IRM_CRN_'+creditNotes[0].QTB_Custom_Invoice_Number__c+'.txt'; // Display name of the files     
                }
                else
                {
                    conVer.PathOnClient = 'IRM_CRN_'+creditNotes[0].name+'.txt';       
                    conVer.Title = 'IRM_CRN_'+creditNotes[0].name+'.txt'; // Display name of the files
                }
                conVer.VersionData = pageData;//File content
                insert conVer;
                Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
                
                //Create ContentDocumentLink
                ContentDocumentLink cDe = new ContentDocumentLink();
                cDe.ContentDocumentId = conDoc;
                cDe.LinkedEntityId = recordID; // you can use objectId,GroupId etc
                cDe.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cDe.Visibility = 'InternalUsers'; //AllUsers, InternalUsers, SharedUsers
                insert cDe;
                Id  docId = cDe.Id;
                //Gitlab US#25594 -- for posted creditnote only set lastCreditNoteSent value
                if(docId != NULL && creditNotes[0].blng__Status__c=='Posted'){
                    creditNotes[0].QTB_Last_Credit_Note_Sent__c = datetime.now();  
                    update  creditNotes[0];
                }
            }
            else{ //Gitlab US#24844
                QTB_GenerateApixCreditNoteExtractBatch creditNoteExtractBatch = new QTB_GenerateApixCreditNoteExtractBatch(creditNotes[0].Id);
                database.executeBatch(creditNoteExtractBatch,1);//scope must be 1
            }
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
        }catch(Exception e) {
            QTB_ExceptionLogger.enable(); //Gitlab US#24844
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_Generate_Creditnote_Ctrl.generateFile');
        }        
    }
}
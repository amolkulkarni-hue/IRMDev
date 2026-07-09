/*****************************************************************************************************
* Class: QTB_Regenerate_Custom_Invc_No
* Author: Virtusa
* Purpose:
* Requirement: 
* Change History: 5/29/2020
* Developer        Date           Description
**************************************************************************************************/
public class QTB_Regenerate_Custom_Invc_No {
    private static final String CLASSNAME = QTB_Regenerate_Custom_Invc_No.class.getName();
    public static boolean throwExplicitException = false;
    
    public static Map<List<blng__Invoice__c>, List<QTB_CustomInvoiceNumber__c>> generateNewCustomInvoiceNumber(List<blng__Invoice__c> lstInvoice,Map<ID,blng__Invoiceline__c> legacyUSumryIDInvLineMap){
        //#30236 Added return statement if both are Null
        if ((lstInvoice == null || lstInvoice.isEmpty()) && (legacyUSumryIDInvLineMap == null || legacyUSumryIDInvLineMap.isEmpty())) { return null; }
        Map<List<blng__Invoice__c>, List<QTB_CustomInvoiceNumber__c>> mapInvcCstmSetngForCustmInvcNo = new Map<List<blng__Invoice__c>, List<QTB_CustomInvoiceNumber__c>>();
        Map<String, QTB_CustomInvoiceNumber__c> lastInvoiceNumMap = QTB_CustomInvoiceNumber__c.getAll();
        List<blng__Invoice__c> lstUpdateInvoice=new List<blng__Invoice__c>();
        try{ 
            if( QTB_Regenerate_Custom_Invc_No.throwExplicitException){
                throw new NullPointerException();
            }
            //initialize database.state variables
            Long norwayLastNumber =0;
            Long finlandLastNumber =0;
            Long denmarkLastNumber =0;
            Long swedenLastNumber =0;  
            Long taiwanLastNumber =0;
            Long thailandLastNumber =0;
            Long malaysiaLastNumber =0;
            Long hongkongLastNumber =0;
            Long singaporeLastNumber =0;
            Long franceLastNumber =0;
            Long belgiumLastNumber =0;
            Long netherlandsLastNumber =0;
            Long romaniaLastNumber =0;
            Long slovakiaLastNumber =0;
            Long greeceLastNumber =0;
            Long czechRepublicLastNumber =0;
            Long hungaryLastNumber =0;
            Long austriaLastNumber =0;
            Long spainLastNumber =0;
            Long germanyLastNumber =0;
            Integer IndiaLastNumber =0;
            //Gitlab #27336 - Added for UK & Ireland
            Long unitedkingdomLastNumber = 0;
            Long irelandLastNumber = 0;
            //Gitlab #27336 - End
            //#30973 #31259 Cluster 4 Custom Inv numbering Turkey,Australia,New Zealand
            Long turkeyLastNumber = 0;
            Long australiaLastNumber = 0;
            Long newZealandLastNumber = 0;
            Map<String,String> mapOfIndStateInv=new map<String,String>();
            Map<Id,QTB_CustomInvoiceNumber__c> mapOfCustSt = new map<id,QTB_CustomInvoiceNumber__c>();
            //30236 Requirement : For Legacy Invoices the Custom Invoice Number and KID value to be populated from Usage Source Invoice Reference
            //30236 Initializing the variables as per the requirement
            Map<Id,String> usSummryIDWithStringValueMap = new map<Id,String>();
            Map<Id,String> invoiceIdWithUsageStringValueMap = new map<Id,String>();
            List<blng__InvoiceLine__c> invL = new List<blng__InvoiceLine__c>();
            //30236 ends
            //initialize next sequence numbers from custom settings
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_NORWAY))
                norwayLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NORWAY).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_FINLAND))     
                finlandLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_FINLAND).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_DENMARK))               
                denmarkLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_DENMARK).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_SWEDEN))
                swedenLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SWEDEN).QTB_Next_Sequence_Number__c);     
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_TAIWAN))       
                taiwanLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_TAIWAN).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_THAILAND))      
                thailandLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_THAILAND).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_MALAYSIA))        
                malaysiaLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_MALAYSIA).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_HONGKONG))        
                hongkongLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_HONGKONG).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_SINGAPORE))     
                singaporeLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SINGAPORE).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_FRANCE))       
                franceLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_FRANCE).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_BELGIUM))        
                belgiumLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_BELGIUM).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_NETHERLANDS))  
                netherlandsLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NETHERLANDS).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_ROMANIA))      
                romaniaLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_ROMANIA).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_SLOVAKIA))    
                slovakiaLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SLOVAKIA).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_GREECE))      
                greeceLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_GREECE).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_CZECH_REPUBLIC))      
                czechRepublicLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_CZECH_REPUBLIC).QTB_Next_Sequence_Number__c);
            //#28025 commented out the lines as that is not required
            /*if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_HUNGARY))     
                hungaryLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_HUNGARY).QTB_Next_Sequence_Number__c);*/
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_AUSTRIA))     
                austriaLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_AUSTRIA).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_SPAIN))     
                spainLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SPAIN).QTB_Next_Sequence_Number__c);
            //#28513 commented out the lines as that is not required
            /*if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_GERMANY))      
                germanyLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_GERMANY).QTB_Next_Sequence_Number__c);*/
            //Gitlab #27336 - Added for UK & Ireland
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_UNITEDKINGDOM))      
                unitedkingdomLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_UNITEDKINGDOM).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_IRELAND))      
                irelandLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_IRELAND).QTB_Next_Sequence_Number__c);
            //#30973 #31259 Cluster 4 Custom Inv numbering Turkey,Australia,New Zealand
            //#34738 Commeneted below turkey loop
            /*if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_TURKEY))      
                turkeyLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_TURKEY).QTB_Next_Sequence_Number__c);*/
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_AUSTRALIA))      
                australiaLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_AUSTRALIA).QTB_Next_Sequence_Number__c);
            if(lastInvoiceNumMap.ContainsKey(QTB_Constants.INVOICE_COUNTRY_NEW_ZEALAND))      
                newZealandLastNumber=Long.valueOf(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NEW_ZEALAND).QTB_Next_Sequence_Number__c);
            //Gitlab #27336 - End
            //30236 Starts
            if(legacyUSumryIDInvLineMap != null && !legacyUSumryIDInvLineMap.IsEmpty()){
                //Quering the usage from respective Usage Summary KeySet Ids and Source Inv Ref != Null and getting one value as source Inv ref will be same value on all usages 
                    for(blng__Usage__c us : [SELECT ID,blng__UsageSummary__c,QTB_Source_Invoice_Reference__c 
                                             FROM blng__Usage__c WHERE blng__UsageSummary__c IN : legacyUSumryIDInvLineMap.keyset() AND
                                             QTB_Source_Invoice_Reference__c != Null LIMIT 50000]){
                        //Adding to Map with Id as Usage Summary Id and Value as Usage Source Inv Ref String Value and will add only one value to Map
                        if(!usSummryIDWithStringValueMap.containsKey(us.blng__UsageSummary__c)){
                            usSummryIDWithStringValueMap.put(us.blng__UsageSummary__c,us.QTB_Source_Invoice_Reference__c);
                        }
                    }
                //Iterating the KeySet of usageSummryToInvLineMap KeySet and adding the Invoice Lines to a List
                system.debug('usSummryIDWithStringValueMap:'+usSummryIDWithStringValueMap);
                if(usSummryIDWithStringValueMap != Null && !usSummryIDWithStringValueMap.IsEmpty()){
                    for(id usid : usSummryIDWithStringValueMap.keySet()){
                        if (legacyUSumryIDInvLineMap.containskey(usId)) {
                            
                            invL.add(legacyUSumryIDInvLineMap.get(usId));
                        }
                    }
                }
                //Iterating the Invoice Lines to store in the Map as Id as Invoice id Ref and Value as The String taht needs to be stamped for Custom Inv Number and KID 
                for(blng__InvoiceLine__c invo : invL){
                    if(!invoiceIdWithUsageStringValueMap.ContainsKey(invo.blng__Invoice__c) && usSummryIDWithStringValueMap.containsKey(invo.blng__UsageSummary__c)) {
                        //Adding as invoiceId as key and one string Value from any Usage Summary Map as required only one Unique value that needs to be stamped
                        invoiceIdWithUsageStringValueMap.put(invo.blng__Invoice__c, usSummryIDWithStringValueMap.get(invo.blng__UsageSummary__c));
                    }
                }
                usSummryIDWithStringValueMap.clear();
                invL.clear();
                ////30236 Ends
            }
            if(!lstInvoice.IsEmpty()){
                for(blng__Invoice__c invoice : lstInvoice){
                    Long custRecordNumber = 0 ;
                    // variable to store country of an invoice
                    String blngCountry =invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c;
                    Decimal legalEntityNo = invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c;
                    
                    List<blng__Invoice__c> invCompare = new List<blng__Invoice__c>();
                    if(!Test.isRunningTest()){
                        // Fetch Latest Custom Invoice Number
                        if(blngCountry == 'India'){
                            QTB_CustomInvoiceNumber__c lastInvesIndiaQueryChk=new QTB_CustomInvoiceNumber__c();
                            String tempIndiaString1 = '';
                            String customInvcPrefix = '';
                            String keyStr=invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+invoice.blng__Account__r.QTB_Market__r.QTB_State__c.toLowerCase().replaceAll( '\\s+', '') +';'+String.valueOf(integer.valueOf(invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c));
                            lastInvesIndiaQueryChk = lastInvoiceNumMap.get(keyStr);
                            tempIndiaString1 = lastInvesIndiaQueryChk.QTB_Next_Sequence_Number__c;
                            Integer indiaNumLen1 = tempIndiaString1.length();
                            String indiaStringpart1=tempIndiaString1.substring(0,indiaNumLen1-7);customInvcPrefix =  QTB_Constants.INDIA_PREFIX_ISO + indiaStringpart1 + '%';
                            string state = invoice.blng__Account__r.QTB_Market__r.QTB_State__c;
                            if(legalEntityNo != Null && state != Null){
                                invCompare = [select id,QTB_Custom_Invoice_Number__c,blng__Account__r.QTB_Market__r.QTB_State__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,
                                              blng__Account__r.QTB_Contract_Entity__r.blng__Country__c from blng__Invoice__c where blng__Account__r.QTB_Contract_Entity__r.blng__Country__c=:blngCountry and
                                              blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c =:legalEntityNo and
                                              blng__Account__r.QTB_Market__r.QTB_State__c =:state and QTB_Custom_Invoice_Number__c !=null and (NOT QTB_Custom_Invoice_Number__c LIKE 'INV-%') and (NOT QTB_Custom_Invoice_Number__c like '%IND1313%') and
                                              QTB_Custom_Invoice_Number__c like :customInvcPrefix and
                                              QTB_Invoice_Type__c != 'Legacy Invoice' order by QTB_Custom_Invoice_Number__c desc limit 1];
                            }
                        }else{
                            if(legalEntityNo != Null){
                                invCompare = [select id,QTB_Custom_Invoice_Number__c,blng__Account__r.QTB_Market__r.QTB_State__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,
                                              blng__Account__r.QTB_Contract_Entity__r.blng__Country__c from blng__Invoice__c 
                                              where blng__Account__r.QTB_Contract_Entity__r.blng__Country__c=:blngCountry and QTB_Custom_Invoice_Number__c !=null and (NOT QTB_Custom_Invoice_Number__c LIKE 'INV-%') AND
                                              (NOT QTB_Custom_Invoice_Number__c like 'FIN9%') AND blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c =:legalEntityNo And
                                              QTB_Invoice_Type__c != 'Legacy Invoice' order by QTB_Custom_Invoice_Number__c desc limit 1];
                            }   
                        }
                        if(!invCompare.isEmpty()){
                            if(!string.isBlank(invCompare[0].QTB_Custom_Invoice_Number__c)){
                                String custNo = invCompare[0].QTB_Custom_Invoice_Number__c;
                                String regex = '\\D';String custRecordNo = custNo.replaceAll(regex, '');
                                custRecordNumber = Long.valueOf(custRecordNo);
                            }
                        }
                    }
                    //#23168 Legacy Invoice - Custom invoice numbering                      
                    if(invoice.QTB_Invoice_Type__c != 'Legacy Invoice'){
                        switch on blngCountry.toLowerCase()
                        {
                            //Update Norway custom invoice number
                            WHEN 'norway' {
                                if(invoice.blng__Account__r.QTB_Customer_Number__c != NULL)
                                {
                                    if(custRecordNumber >= norwayLastNumber){
                                        norwayLastNumber = custRecordNumber + 1 ;
                                    }
                                    Integer checkDigt = QTB_Utils.checkDigitforNorwayDenmark(String.valueOf(norwayLastNumber)+String.valueOf(invoice.blng__Account__r.QTB_Customer_Number__c));
                                    invoice.QTB_KID__c=String.valueOf(norwayLastNumber)+String.valueOf(invoice.blng__Account__r.QTB_Customer_Number__c)+String.valueOf(checkDigt);
                                    invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.NORWAY_PREFIX_ISO +string.valueOf(NorwayLastNumber);
                                    norwayLastNumber =norwayLastNumber+1;
                                    lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NORWAY).QTB_Next_Sequence_Number__c = String.valueOf(norwayLastNumber);
                                    mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NORWAY).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NORWAY));
                                }
                            }
                            //Update Finland custom invoice number
                            WHEN 'finland'{
                                if(custRecordNumber >= finlandLastNumber){
                                    finlandLastNumber = custRecordNumber + 1 ;
                                }
                                Integer checkDigt = QTB_Utils.checkDigitforFinland(String.valueOf(finlandLastNumber));    
                                invoice.QTB_KID__c=String.valueOf(finlandLastNumber)+String.valueOf(checkDigt);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.FINLAND_PREFIX_ISO+string.valueOf(finlandLastNumber);
                                finlandLastNumber =finlandLastNumber+1;
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_FINLAND).QTB_Next_Sequence_Number__c = String.valueOf(finlandLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_FINLAND).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_FINLAND));
                            }
                            //Update Denmark custom invoice number
                            WHEN 'denmark'{
                                if(custRecordNumber >= denmarkLastNumber){
                                    denmarkLastNumber = custRecordNumber + 1 ;
                                }
                                Integer checkDigt = QTB_Utils.checkDigitforNorwayDenmark(String.valueOf(denmarkLastNumber));
                                invoice.QTB_KID__c=QTB_Constants.DENMARK_PREFIX +String.valueOf(denmarkLastNumber)+String.valueOf(checkDigt)+QTB_Constants.DENMARK_POSTFIX;
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.DENMARK_PREFIX_ISO+string.valueOf(denmarkLastNumber);
                                denmarkLastNumber =denmarkLastNumber+1;  
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_DENMARK).QTB_Next_Sequence_Number__c = String.valueOf(denmarkLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_DENMARK).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_DENMARK));
                            }
                            //Update Sweden custom invoice number
                            WHEN 'sweden'{
                                if(custRecordNumber >= swedenLastNumber){
                                    swedenLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c=QTB_Constants.SWEDEN_PREFIX+String.valueOf(swedenLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.SWEDEN_PREFIX+string.valueOf(swedenLastNumber);
                                swedenLastNumber =swedenLastNumber+1;  
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SWEDEN).QTB_Next_Sequence_Number__c = String.valueOf(swedenLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SWEDEN).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SWEDEN));
                            }
                            //Update India custom invoice number
                            WHEN 'india'{
                                if(invoice.blng__Account__r.QTB_Contract_Entity__c !=null && invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c != null && invoice.blng__Account__r.QTB_Market__r.QTB_State__c!=null || Test.isRunningTest())
                                {    
                                    QTB_CustomInvoiceNumber__c lastInvesIndia=new QTB_CustomInvoiceNumber__c();
                                    String keyStr=invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+invoice.blng__Account__r.QTB_Market__r.QTB_State__c.toLowerCase().replaceAll( '\\s+', '') +';'+String.valueOf(integer.valueOf(invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c));
                                    String tempIndiaString='';
                                    
                                    String custNo1 = lastInvoiceNumMap.get(keyStr).QTB_Next_Sequence_Number__c;
                                    Integer indiaNumLen1=custNo1.length();
                                    String indiaStringpart1=custNo1.substring(0,indiaNumLen1-7);
                                    String regex1 = '\\D';String custNo2 = custNo1.replaceAll(regex1, '');
                                    Long indiaCustNo = Long.valueOf(custNo2);integer lenCheck = custNo2.length();
                                    if(custRecordNumber >= indiaCustNo){
                                        indiaCustNo = custRecordNumber + 1 ;
                                    }
                                    string indiaString = string.valueOf(indiaCustNo);
                                    if(lenCheck == 7){
                                        indiaString = indiaStringpart1+string.valueOf(indiaCustNo).leftPad(7, '0');
                                    }else{
                                        indiaString = string.valueOf(indiaCustNo).leftPad(9, '0');
                                    }
                                    
                                    if(mapOfIndStateInv.containsKey(keyStr))
                                    {
                                        tempIndiaString=mapOfIndStateInv.get(keyStr);
                                    }else{
                                        if(lastInvoiceNumMap.containsKey(keyStr))
                                        {
                                            if(!String.isBlank(indiaString)){
                                                tempIndiaString = indiastring;
                                            }else{
                                            lastInvesIndia=lastInvoiceNumMap.get(keyStr);tempIndiaString=lastInvesIndia.QTB_Next_Sequence_Number__c;
                                            }
                                        }
                                    }
                                    if(String.isNotBlank(tempIndiaString))
                                    {
                                        Integer indiaNumLen=tempIndiaString.length();
                                        indiaLastNumber=Integer.valueOf(tempIndiaString.substring(indiaNumLen-7,indiaNumLen));
                                        if(indiaLastNumber != 0)
                                        {                                   
                                            String indiaStringpart=tempIndiaString.substring(0,indiaNumLen-7);
                                            invoice.QTB_KID__c=QTB_Constants.INDIA_PREFIX_ISO+indiaStringpart+string.valueOf(indiaLastNumber).leftPad(7, '0');
                                            invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.INDIA_PREFIX_ISO+indiaStringpart+string.valueOf(indiaLastNumber).leftPad(7, '0');
                                            indiaLastNumber =indiaLastNumber+1; 
                                            mapOfIndStateInv.put(keyStr,indiaStringpart+string.valueOf(indiaLastNumber).leftPad(7, '0')); 
                                            QTB_CustomInvoiceNumber__c lastInvesIndia1 = lastInvoiceNumMap.get(keyStr);
                                            lastInvesIndia1.QTB_Next_Sequence_Number__c=mapOfIndStateInv.get(keyStr);
                                            mapOfCustSt.put(lastInvoiceNumMap.get(keyStr).Id,lastInvesIndia1);
                                        }
                                    }
                                }
                            } 
                            //Update Taiwan custom invoice number
                            WHEN 'taiwan'{
                                if(custRecordNumber >= taiwanLastNumber){
                                    taiwanLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c=QTB_Constants.TAIWAN_PREFIX+String.valueOf(taiwanLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.TAIWAN_PREFIX+string.valueOf(taiwanLastNumber);
                                taiwanLastNumber =taiwanLastNumber+1;  
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_TAIWAN).QTB_Next_Sequence_Number__c = String.valueOf(taiwanLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_TAIWAN).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_TAIWAN));
                            }
                            //Update Thailand custom invoice number
                            WHEN 'thailand'{
                                if(custRecordNumber >= thailandLastNumber){
                                    thailandLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c=QTB_Constants.THAILAND_PREFIX+String.valueOf(thailandLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.THAILAND_PREFIX+string.valueOf(thailandLastNumber);
                                thailandLastNumber =thailandLastNumber+1; 
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_THAILAND).QTB_Next_Sequence_Number__c = String.valueOf(thailandLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_THAILAND).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_THAILAND));
                            }
                            //Update Malaysia custom invoice number
                            WHEN 'malaysia'{
                                if(custRecordNumber >= malaysiaLastNumber){
                                    malaysiaLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c=QTB_Constants.MALAYSIA_PREFIX+String.valueOf(malaysiaLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.MALAYSIA_PREFIX+string.valueOf(malaysiaLastNumber);
                                malaysiaLastNumber =malaysiaLastNumber+1;
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_MALAYSIA).QTB_Next_Sequence_Number__c = String.valueOf(malaysiaLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_MALAYSIA).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_MALAYSIA));
                            }
                            //Update Hong Kong custom invoice number
                            WHEN 'hong kong'{
                                if(custRecordNumber >= hongkongLastNumber){
                                    hongkongLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c=QTB_Constants.HONGKONG_PREFIX+String.valueOf(hongkongLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.HONGKONG_PREFIX+string.valueOf(hongkongLastNumber);
                                hongkongLastNumber =hongkongLastNumber+1; 
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_HONGKONG).QTB_Next_Sequence_Number__c = String.valueOf(hongkongLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_HONGKONG).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_HONGKONG));
                            }
                            //Update Singapore custom invoice number
                            WHEN 'singapore'{
                                if(custRecordNumber >= singaporeLastNumber)
                                {
                                    singaporeLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.SINGAPORE_PREFIX +String.valueOf(singaporeLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.SINGAPORE_PREFIX+string.valueOf(singaporeLastNumber);
                                singaporeLastNumber =singaporeLastNumber+1;
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SINGAPORE).QTB_Next_Sequence_Number__c = String.valueOf(singaporeLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SINGAPORE).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SINGAPORE));
                            }
                            //Update France custom invoice number
                            WHEN 'france'{
                                if(custRecordNumber >= franceLastNumber)
                                {
                                    franceLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.FRANCE_PREFIX +String.valueOf(franceLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.FRANCE_PREFIX+string.valueOf(franceLastNumber);
                                franceLastNumber =franceLastNumber+1; 
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_FRANCE).QTB_Next_Sequence_Number__c = String.valueOf(franceLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_FRANCE).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_FRANCE));
                            }
                            //Update Belgium custom invoice number
                            WHEN 'belgium'{
                                if(custRecordNumber >= belgiumLastNumber){
                                    belgiumLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.BELGIUM_PREFIX +String.valueOf(belgiumLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.BELGIUM_PREFIX+string.valueOf(belgiumLastNumber);
                                belgiumLastNumber =belgiumLastNumber+1; 
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_BELGIUM).QTB_Next_Sequence_Number__c = String.valueOf(belgiumLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_BELGIUM).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_BELGIUM));
                            }
                            //Update Netherlands custom invoice number
                            WHEN 'netherlands'{
                                if(custRecordNumber >= netherlandsLastNumber){
                                    netherlandsLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.NETHERLANDS_PREFIX +String.valueOf(netherlandsLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.NETHERLANDS_PREFIX+string.valueOf(netherlandsLastNumber);
                                netherlandsLastNumber =netherlandsLastNumber+1;  
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NETHERLANDS).QTB_Next_Sequence_Number__c = String.valueOf(netherlandsLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NETHERLANDS).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NETHERLANDS));
                            }
                            //Cluster 3 countries
                            //Update Romania custom invoice number
                            WHEN 'romania'{
                                if(custRecordNumber >= romaniaLastNumber)
                                {
                                    romaniaLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.ROMANIA_PREFIX +String.valueOf(romaniaLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.ROMANIA_PREFIX+string.valueOf(romaniaLastNumber);
                                romaniaLastNumber =romaniaLastNumber+1;    
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_ROMANIA).QTB_Next_Sequence_Number__c = String.valueOf(romaniaLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_ROMANIA).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_ROMANIA));
                            }
                            //Update Slovakia custom invoice number
                            WHEN 'slovakia'{
                                if(custRecordNumber >= slovakiaLastNumber){
                                    slovakiaLastNumber = custRecordNumber + 1 ;
                                }
                                 //#28513 As per the requirement for Slovakia there should be no prefix as per like other countries, so removing Prefix
                                invoice.QTB_KID__c= String.valueOf(slovakiaLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=string.valueOf(slovakiaLastNumber);
                                slovakiaLastNumber =slovakiaLastNumber+1; 
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SLOVAKIA).QTB_Next_Sequence_Number__c = String.valueOf(slovakiaLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SLOVAKIA).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SLOVAKIA));
                            }
                            //Update Greece custom invoice number
                            WHEN 'greece'{
                                if(custRecordNumber >= greeceLastNumber)
                                {
                                    greeceLastNumber = custRecordNumber + 1 ;
                                }
                                //#28513 As per the requirement for Greece there should be no prefix as per like other countries, so removing Prefix
                                invoice.QTB_KID__c= String.valueOf(greeceLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=string.valueOf(greeceLastNumber);
                                greeceLastNumber =greeceLastNumber+1;  
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_GREECE).QTB_Next_Sequence_Number__c = String.valueOf(greeceLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_GREECE).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_GREECE));
                            }
                            //Update Czech Republic custom invoice number
                            WHEN 'czech republic'{
                                if(custRecordNumber >= czechRepublicLastNumber)
                                {
                                    czechRepublicLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.CZECH_REPUBLIC_PREFIX +String.valueOf(czechRepublicLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.CZECH_REPUBLIC_PREFIX+string.valueOf(czechRepublicLastNumber);
                                czechRepublicLastNumber =czechRepublicLastNumber+1; 
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_CZECH_REPUBLIC).QTB_Next_Sequence_Number__c = String.valueOf(czechRepublicLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_CZECH_REPUBLIC).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_CZECH_REPUBLIC));
                            }
                            //Cluster 3A countries
                            //Update Hungary custom invoice number
                            WHEN 'hungary'{
                                //28025 Added key as Country;LegalEntityNumber to get the value based upon the combo for generating the Custom Seq no based upon legal entity
                                string keystr = invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+String.valueOf(integer.valueOf(invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c));
                                hungaryLastNumber = Long.valueOf(lastInvoiceNumMap.get(keystr).QTB_Next_Sequence_Number__c);
                                if(custRecordNumber >= hungaryLastNumber)
                                {
                                    hungaryLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.HUNGARY_PREFIX +String.valueOf(hungaryLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.HUNGARY_PREFIX+string.valueOf(hungaryLastNumber);
                                hungaryLastNumber =hungaryLastNumber+1; 
                                lastInvoiceNumMap.get(keystr).QTB_Next_Sequence_Number__c = String.valueOf(hungaryLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(keystr).Id,lastInvoiceNumMap.get(keystr));
                            }
                            //Update Austria custom invoice number
                            WHEN 'austria'{
                                if(custRecordNumber >= austriaLastNumber)                                {
                                    austriaLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.AUSTRIA_PREFIX +String.valueOf(austriaLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.AUSTRIA_PREFIX+string.valueOf(austriaLastNumber);
                                austriaLastNumber =austriaLastNumber+1; 
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_AUSTRIA).QTB_Next_Sequence_Number__c = String.valueOf(austriaLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_AUSTRIA).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_AUSTRIA));
                            }
                            //Update Spain custom invoice number
                            WHEN 'spain'{
                                if(custRecordNumber >= spainLastNumber){
                                    spainLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.SPAIN_PREFIX_INVOICE +String.valueOf(spainLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.SPAIN_PREFIX_INVOICE+string.valueOf(spainLastNumber);
                                spainLastNumber =spainLastNumber+1;  
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SPAIN).QTB_Next_Sequence_Number__c = String.valueOf(spainLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SPAIN).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_SPAIN));
                            }
                            //Update Germany custom invoice number
                            WHEN 'germany'{
                                //28513 Added key as Country;LegalEntityNumber to get the value based upon the combo for generating the Custom Seq no based upon legal entity
                                string keystr = invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+String.valueOf(integer.valueOf(invoice.blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c));
                                germanyLastNumber = Long.valueOf(lastInvoiceNumMap.get(keystr).QTB_Next_Sequence_Number__c);
                                if(custRecordNumber >= germanyLastNumber){
                                    germanyLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.GERMANY_PREFIX +String.valueOf(germanyLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.GERMANY_PREFIX+string.valueOf(germanyLastNumber);
                                germanyLastNumber =germanyLastNumber+1;  
                                lastInvoiceNumMap.get(keystr).QTB_Next_Sequence_Number__c = String.valueOf(germanyLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(keystr).Id,lastInvoiceNumMap.get(keystr));
                            }
                                      //Gitlab #27336 - Update UK custom invoice number
                           WHEN 'united kingdom'{
                                if(custRecordNumber >= unitedkingdomLastNumber){
                                    unitedkingdomLastNumber = custRecordNumber + 1;  
                                }
                                 invoice.QTB_KID__c= QTB_Constants.UNITEDKINGDOM_PREFIX +String.valueOf(unitedkingdomLastNumber);
                                 invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.UNITEDKINGDOM_PREFIX+string.valueOf(unitedkingdomLastNumber);
                                 unitedkingdomLastNumber =unitedkingdomLastNumber+1;  
                                 lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_UNITEDKINGDOM).QTB_Next_Sequence_Number__c = String.valueOf(unitedkingdomLastNumber);
                                 mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_UNITEDKINGDOM).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_UNITEDKINGDOM));      
                            }
                            //Gitlab #27336 - Update Ireland custom invoice number
                            WHEN 'ireland'{
                                if(custRecordNumber >= irelandLastNumber){
                                    irelandLastNumber = custRecordNumber + 1;
                                }
                                 invoice.QTB_KID__c= QTB_Constants.IRELAND_PREFIX +String.valueOf(irelandLastNumber);
                                 invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.IRELAND_PREFIX+string.valueOf(irelandLastNumber);
                                 irelandLastNumber =irelandLastNumber+1;  
                                 lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_IRELAND).QTB_Next_Sequence_Number__c = String.valueOf(irelandLastNumber);
                                 mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_IRELAND).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_IRELAND));                             
                            }
                            //#30973 #31259 Cluster 4 Custom Inv numbering Turkey,Australia,New Zealand
                            //#34738 Changing the Turkey Invoice Number sequence as per this story like diff sequencing for both E fatura and E Arsive invoices
                            WHEN 'turkey'{
                                if(invoice.blng__Account__r.QTB_Invoice_Delivery_Options__c != Null && invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c != Null ){
                                    if(custRecordNumber >= turkeyLastNumber){
                                        turkeyLastNumber = custRecordNumber + 1 ;
                                    }
                                    String keystr = invoice.blng__Account__r.QTB_Contract_Entity__r.blng__Country__c.toLowerCase()+';'+invoice.blng__Account__r.QTB_Invoice_Delivery_Options__c;
                                    if(invoice.blng__Account__r.QTB_Invoice_Delivery_Options__c == QTB_Constants.TURKEY_FATURA_DELIVERY_OPTION){
                                        turkeyLastNumber = Long.valueOf(lastInvoiceNumMap.get(keystr).QTB_Next_Sequence_Number__c);
                                        invoice.QTB_KID__c= QTB_Constants.TURKEY_FATURA_PREFIX +String.valueOf(turkeyLastNumber);
                                        invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.TURKEY_FATURA_PREFIX+string.valueOf(turkeyLastNumber);
                                        turkeyLastNumber =turkeyLastNumber+1; 
                                        lastInvoiceNumMap.get(keystr).QTB_Next_Sequence_Number__c = String.valueOf(turkeyLastNumber);
                                        mapOfCustSt.put(lastInvoiceNumMap.get(keystr).Id,lastInvoiceNumMap.get(keystr));
                                    }
                                    else if (invoice.blng__Account__r.QTB_Invoice_Delivery_Options__c == QTB_Constants.TURKEY_ARSIV_DELIVERY_OPTION){
                                        turkeyLastNumber = Long.valueOf(lastInvoiceNumMap.get(keystr).QTB_Next_Sequence_Number__c);
                                        invoice.QTB_KID__c= QTB_Constants.TURKEY_ARSIV_PREFIX +String.valueOf(turkeyLastNumber);
                                        invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.TURKEY_ARSIV_PREFIX +String.valueOf(turkeyLastNumber);
                                        turkeyLastNumber =turkeyLastNumber+1;  
                                        lastInvoiceNumMap.get(keystr).QTB_Next_Sequence_Number__c = String.valueOf(turkeyLastNumber);
                                        mapOfCustSt.put(lastInvoiceNumMap.get(keystr).Id,lastInvoiceNumMap.get(keystr));                         
                                    }
                                }
                            }
                            WHEN 'australia'{
                                if(custRecordNumber >= australiaLastNumber)                                {
                                    australiaLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.AUSTRALIA_PREFIX +String.valueOf(australiaLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.AUSTRALIA_PREFIX+string.valueOf(australiaLastNumber);
                                australiaLastNumber =australiaLastNumber+1; 
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_AUSTRALIA).QTB_Next_Sequence_Number__c = String.valueOf(australiaLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_AUSTRALIA).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_AUSTRALIA));
                            }
                            
                            WHEN 'new zealand'{
                                if(custRecordNumber >= newZealandLastNumber)                                {
                                    newZealandLastNumber = custRecordNumber + 1 ;
                                }
                                invoice.QTB_KID__c= QTB_Constants.NEW_ZEALAND_PREFIX +String.valueOf(newZealandLastNumber);
                                invoice.QTB_Custom_Invoice_Number__c=QTB_Constants.NEW_ZEALAND_PREFIX+string.valueOf(newZealandLastNumber);
                                newZealandLastNumber =newZealandLastNumber+1; 
                                lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NEW_ZEALAND).QTB_Next_Sequence_Number__c = String.valueOf(newZealandLastNumber);
                                mapOfCustSt.put(lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NEW_ZEALAND).Id,lastInvoiceNumMap.get(QTB_Constants.INVOICE_COUNTRY_NEW_ZEALAND));
                            }
                            //Gitlab #27336 - End
                            WHEN else{
                                invoice.QTB_KID__c=invoice.name;  
                                invoice.QTB_Custom_Invoice_Number__c = invoice.name;
                            }
                        }
                    }
                    //#23168 Legacy Invoice - Custom invoice numbering
                    else{
                        //30236 Checking invoiceIdWithUsageStringValueMap Map Size > o and stamping the Custom Inv Number and KId value as Usage Invoice Souce Ref value
                        if(invoiceIdWithUsageStringValueMap != Null && !invoiceIdWithUsageStringValueMap.IsEmpty() && invoiceIdWithUsageStringValueMap.containsKey(invoice.id)){
                            invoice.QTB_Custom_Invoice_Number__c = invoiceIdWithUsageStringValueMap.get(invoice.id);
                            invoice.QTB_KID__c = invoiceIdWithUsageStringValueMap.get(invoice.id);
                        }
                        //Else if that Map has no value then stamping the OOTB Number generation
                        else{
                            invoice.QTB_Custom_Invoice_Number__c = invoice.name;
                            invoice.QTB_KID__c = invoice.name;
                        } 
                        //30236 Ends
                    } 
                    lstUpdateInvoice.add(invoice);
                }
                invoiceIdWithUsageStringValueMap.clear();
               if(!lstUpdateInvoice.isEmpty()){ 
                   
                    if(!mapOfCustSt.isEmpty()){
                        List<QTB_CustomInvoiceNumber__c> customInvoiceNumbers = new List<QTB_CustomInvoiceNumber__c>(mapOfCustSt.values());
                        mapInvcCstmSetngForCustmInvcNo.put(lstUpdateInvoice,customInvoiceNumbers);
                    }
                    else{
                        mapInvcCstmSetngForCustmInvcNo.put(lstUpdateInvoice,new List<QTB_CustomInvoiceNumber__c>());
                    }
                    // Get the values from mapOfCustSt and store them in a list
                }
            }
        }
        catch(Exception e){
            e.getLineNumber();
            e.getStackTraceString();
            e.getMessage();
            e.getStackTraceString();
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME);
        }
        return mapInvcCstmSetngForCustmInvcNo;
    }
}
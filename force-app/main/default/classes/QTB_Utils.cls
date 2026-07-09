/*****************************************************************************************************
* Class: QTB_Utils
* Author: Accenture
* Change History: 06/10/2020
* Change History: 06/12/2022 - For Story #12122 logic to avoid billing frequency override for Ad-hoc orders
* Change History: 07/12/2022 - For Story #11924 To avoid setting hold billing 'No' for Ad Hoc orders
* Change History: 05/04/2024 - For Story #22533 To correctly populate Tax rule based on Treatment
* Purpose: This is a generic utility class
*******************************************************************************************************/
public class QTB_Utils {
    public static final String UTILCLASS = 'QTB_Utils';
    public static final String PE_PRICESCHEDULE = 'Price Schedule Platform Event';
    public static final String PE_BILLINGACCOUNT = 'Billing Account OS Platform Event';
    public static final String SEMI_COLON = ';';
    public static final String SEVEN_CONSTANT = '7';
    
    //Account record type ids
    public static final Id ACCOUNT_BILL_RECTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('QTB_Billing_Account')
        .getRecordTypeId();
    public static final ID ACCOUNT_STANDARD_RECTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Standard_Account')
        .getRecordTypeId();
    public static final Id ACCOUNT_OPERATIONAL_RECTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Operational_Account')
        .getRecordTypeId();
    public static final Id ACCOUNT_IMGA_RECTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('IMGA_Record_Type')
        .getRecordTypeId();
    
    
    //Opportunity record type ids
    public static final Id OPP_BILL_RECTYPEID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('CPQ_Billing_Opportunity')
        .getRecordTypeId();
    public static final Id OPP_SALES_RECTYPEID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('CPQ_Sales_Opportunity')
        .getRecordTypeId();
    public static final ID OPP_STANDARD_RECTYPEID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Standard_Opportunity')
        .getRecordTypeId();
    
    //Quote record type ids
    public static final Id QUOTE_BILL_RECTYPEID = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName()
        .get('QTB_Billing_Quote')
        .getRecordTypeId();
    public static final Id QUOTE_SALES_RECTYPEID = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName()
        .get('QTB_Sales')
        .getRecordTypeId();
    public static final Id QUOTE_APPROVED_RECTYPEID = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName()
        .get('QTB_Sales_Quote_Approved')
        .getRecordTypeId();
    public static final Id QUOTE_REVIEW_RECTYPEID = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName()
        .get('QTB_Sales_Quote_In_Review')
        .getRecordTypeId();
    
    //Contract record type ids
    public static final Id CONTRACT_SALES_RECTYPEID = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
        .get('CPQ_Contract')
        .getRecordTypeId();
    public static final Id CONTRACT_BILL_RECTYPEID = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
        .get('QTB_Billing_Contract')
        .getRecordTypeId();
    
    //Invoice record type ids
    public static final Id INVOICE_POSTED_RECTYPEID = Schema.SObjectType.blng__Invoice__c.getRecordTypeInfosByDeveloperName()
        .get('QTB_Posted_Invoice')
        .getRecordTypeId();
    public static final Id INVOICE_DRAFT_RECTYPEID = Schema.SObjectType.blng__Invoice__c.getRecordTypeInfosByDeveloperName()
        .get('QTB_Draft_Invoice')
        .getRecordTypeId();
    
    //Order record type ids
    public static final Id ORDER_BILL_RECTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('QTB_Billing_Order')
        .getRecordTypeId();
    public static final Id ORDER_SALES_RECTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('QTB_Sales_Order').getRecordTypeId();
    
    //product record type ids
    public static final Id GLOBAL_SALES_RECTYPEID = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
        .get('QTB_Global_Sales_Product')
        .getRecordTypeId();
    
    // credit note record type ids
    public static final Id CREDITNOTE_POSTED_RECTYPEID = Schema.SObjectType.blng__CreditNote__c.getRecordTypeInfosByDeveloperName()
        .get(Label.QTB_Credit_Note_Posted_Record_Type)
        .getRecordTypeId();
    
    // credit note line record type ids
    public static final Id CREDITNOTELINE_POSTED_RECTYPEID = Schema.SObjectType.blng__CreditNoteLine__c.getRecordTypeInfosByDeveloperName()
        .get(Label.QTB_CreditNoteLineRecordType_Posted)
        .getRecordTypeId();
    
    /***********************************************************************************************************
* Method : getEmailIdList
* Parameters: N/A
* ReturnType: List<String>
* Requirement : Git#8,9,15
* Author : Accenture
* Description: Used to collect email Ids list from Custom Metadata
**************************************************************************************************************/
    public static List<String> getEmailIdList() {
        List<String> EmailIdList = new List<String>();
        try {
            if (QTB_QueueRenewalBilling.throwExplicitException) {
                throw new NullPointerException();
            }
            for (QTB_Email_Address__mdt temp : [
                SELECT
                Id,
                DeveloperName,
                MasterLabel,
                Label,
                QualifiedApiName,
                QTB_Email_ID__c
                FROM QTB_Email_Address__mdt
                WHERE DeveloperName = :QTB_Constants.BILLING_ERROR_LOG_IDS
            ]) {
                if (temp.QTB_Email_ID__c != null) {
                    EmailIdList.addAll(temp.QTB_Email_ID__c.Split(','));
                }
            }
        } catch (Exception exx) {
            EmailIdList = new List<String>();
            QTB_ExceptionLogger.createLog(
                exx.getLineNumber(),
                exx.getStackTraceString(),
                exx.getMessage(),
                exx.getTypeName(),
                'ContractHelper'
            );
        }
        return EmailIdList;
    }
    
    /***********************************************************************************************************
* Method : sendErrorLogMail
* Parameters: List<String> , String
* ReturnType: void
* Requirement : git#8,9,10
* Author : Accenture
* Description: Used to send error log mail for failed dml records.
**************************************************************************************************************/
    public static void sendErrorLogMail(
        Set<String> failedRecordIds,
        String processName
    ) {
        try {
            if (QTB_QueueRenewalBilling.throwExplicitException) {
                throw new NullPointerException();
            }
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> to_Addresses = getEmailIdList();
            if (to_Addresses.size() > 0) {
                //used to get org baseUrl
                String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
                email.setSenderDisplayName('IRM Support');
                system.debug('to_Addresses>>>'+to_Addresses);
                email.setToAddresses(to_Addresses);
                email.setSubject(processName);
                //Generating Email body
                String EmailBody =
                    'Hello, <br/><br/>This is the system generated mail to notify you about error caused while processing ' +
                    processName +
                    ' records.Here is the list of records failed to process <br/>';
                String EmailRecordIDBody = '';
                String EmailFooter = '<br/><br/>Regards<br/> Developer';
                
                for (Id temp : failedRecordIds) {
                    EmailRecordIDBody +=
                        '<a href="' +
                        baseUrl +
                        '/' +
                        temp +
                        '">' +
                        baseUrl +
                        '/' +
                        temp +
                        '</a><br/>';
                }
                email.setHtmlBody(EmailBody + EmailRecordIDBody + EmailFooter);
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
                system.debug('response>>'+ Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email }));
            }
        } catch (exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'QTB_RenewalBillingBatchHelper'
            );
        }
    }
    /***********************************************************************************************************
* Method : GetFieldMapMetadata
* Parameters: String,String,String
* Return Type :  List<QTB_Field_Mapping__mdt>
* Requirement :Generic
* Author : Accenture
* Description: Return QTB_Field_Mapping__mdt custom metadata records
**************************************************************************************************************/
    public static List<QTB_Field_Mapping__mdt> GetFieldMapMetadata(
        String source,
        String destination,
        String metadataCondition
    ) {
        List<QTB_Field_Mapping__mdt> metaRecs;
        if (
            String.isNotBlank(source) &&
            String.isNotBlank(destination) &&
            String.isNotBlank(metadataCondition)
        ) {
            metaRecs = new List<QTB_Field_Mapping__mdt>();
            for (QTB_Field_Mapping__mdt metadata : [
                SELECT
                QTB_ChildObjectFieldAPIName__c,
                QTB_ChildRelationshipName__c,
                QTB_Destination_Field_API_Name__c,
                QTB_Destination_Object_API_Name__c,
                QTB_IsSubQuery__c,
                QTB_Source_Field_API_Name__c,
                QTB_Condition__c,
                QTB_Source_Object_API_Name__c
                FROM QTB_Field_Mapping__mdt
            ]) {
                if (
                    metadata.QTB_Source_Object_API_Name__c == source &&
                    metadata.QTB_Destination_Object_API_Name__c == destination &&
                    metadata.QTB_Condition__c == metadataCondition
                ) {
                    metaRecs.add(metadata);
                }
            }
        }
        return metaRecs;
    }
    /***********************************************************************************************************
* Method : ReturnSourceRecordQuery
* Parameters: Metadata
* Return Type : String
* Requirement :Generic
* Author : Accenture
* Description: Return subquery framed on metadata passed
**************************************************************************************************************/
    public static String ReturnSourceRecordQuery(
        List<QTB_Field_Mapping__mdt> metadataRecList
    ) {
        String subQuery = '';
        if (!metadataRecList.isEmpty()) {
            for (Integer i = 0; i < metadataRecList.size(); i++) {
                if (i == 0) {
                    subQuery =
                        'SELECT ' + metadataRecList[i].QTB_Source_Field_API_Name__c;
                } else {
                    subQuery += ' ,' + metadataRecList[i].QTB_Source_Field_API_Name__c;
                }
                if (i == metadataRecList.size() - 1) {
                    if (
                        metadataRecList[i].QTB_Condition__c ==
                        QTB_Constants.Billing_OS_PE_COND
                    ) {
                        subQuery += ' ,(Select id,contact.Name,accountId,contactId from AccountContactRelations order by createdDate desc limit 1)';
                    }
                    subQuery +=
                        ' FROM ' + metadataRecList[i].QTB_Source_Object_API_Name__c;
                }
            }
        }
        return subQuery;
    }
    /***********************************************************************************************************
* Method : MapSourceFldValuetoDestFldVal
* Parameters: sObject,sObject,List<QTB_Field_Mapping__mdt>
* Return Type : void
* Requirement : Generic
* Author : Accenture
* Description: Generic method that maps source field value to destination field value
**************************************************************************************************************/
    public static sObject MapSourceFldValuetoDestFldVal(
        sObject dest,
        sObject sourcSobj,
        List<QTB_Field_Mapping__mdt> metadataRecList
    ) {
        for (QTB_Field_Mapping__mdt metadataRec : metadataRecList) {
            // initializing a temporary copy of the sourcerecord, not to be overridden later
            SObject tempSource = sourcSobj;
            if (String.isNotBlank(metadataRec.QTB_Destination_Field_API_Name__c)) {
                //Dynamically get data of source value irrespective of number of levels depth
                String[] splitSourceField = metadataRec.QTB_Source_Field_API_Name__c.split(
                    '\\.'
                );
                
                for (
                    Integer i = 0;
                    i < (splitSourceField.size() - 1) &&
                    tempSource != null;
                    i++
                ) {
                    if (tempSource.getSObject(splitSourceField[i]) == null) {
                        tempSource = null;
                        break;
                    }
                    tempSource = tempSource.getSObject(splitSourceField[i]);
                }
                //Get source field value and map it to respective destination field
                if (
                    tempSource != null &&
                    tempSource.get(splitSourceField.get(splitSourceField.size() - 1)) !=
                    null
                ) {
                    //dest.put(metadataRec.QTB_Destination_Field_API_Name__c, tempSource.get(splitSourceField.get(splitSourceField.size() - 1)));
                    if (
                        metadataRec.QTB_Destination_Field_API_Name__c ==
                        QTB_Constants.SEND_STATEMENT
                    ) {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            string.ValueOf(
                                tempSource.get(
                                    splitSourceField.get(splitSourceField.size() - 1)
                                )
                            )
                        );
                    } else if (
                        metadataRec.QTB_Destination_Field_API_Name__c ==
                        QTB_Constants.SEND_DUNNING
                    ) {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            string.valueOf(
                                tempSource.get(
                                    splitSourceField.get(splitSourceField.size() - 1)
                                )
                            )
                        );
                    } else if (
                        metadataRec.QTB_Destination_Field_API_Name__c ==
                        QTB_Constants.PRIMARY_FIELD
                    ) {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            string.valueOf(
                                tempSource.get(
                                    splitSourceField.get(splitSourceField.size() - 1)
                                )
                            )
                        );
                    } else if (
                        metadataRec.QTB_Destination_Field_API_Name__c ==
                        QTB_Constants.ACCOUNT_RM
                    ) {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            string.valueOf(
                                tempSource.get(
                                    splitSourceField.get(splitSourceField.size() - 1)
                                )
                            )
                        );
                    } else if (
                        metadataRec.QTB_Destination_Field_API_Name__c ==
                        QTB_Constants.ACCOUNT_SCAN
                    ) {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            string.valueOf(
                                tempSource.get(
                                    splitSourceField.get(splitSourceField.size() - 1)
                                )
                            )
                        );
                    } else if (
                        metadataRec.QTB_Destination_Field_API_Name__c ==
                        QTB_Constants.ACCOUNT_SHRED
                    ) {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            string.valueOf(
                                tempSource.get(
                                    splitSourceField.get(splitSourceField.size() - 1)
                                )
                            )
                        );
                    } else if (
                        metadataRec.QTB_Destination_Field_API_Name__c ==
                        QTB_Constants.ACCOUNT_DM
                    ) {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            string.valueOf(
                                tempSource.get(
                                    splitSourceField.get(splitSourceField.size() - 1)
                                )
                            )
                        );
                    } else if (
                        metadataRec.QTB_Destination_Field_API_Name__c ==
                        QTB_Constants.LEGAL_ENTITY
                    ) {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            string.valueOf(
                                tempSource.get(
                                    splitSourceField.get(splitSourceField.size() - 1)
                                )
                            )
                        );
                    } else if (
                        metadataRec.QTB_Destination_Field_API_Name__c ==
                        QTB_Constants.CUSTOMER_NUMBER
                    ) {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            string.valueOf(
                                tempSource.get(
                                    splitSourceField.get(splitSourceField.size() - 1)
                                )
                            )
                        );
                    } else if (
                        metadataRec.QTB_Destination_Field_API_Name__c ==
                        QTB_Constants.PARENT_PAYABLE_MODEL
                    ) {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            string.valueOf(
                                tempSource.get(
                                    splitSourceField.get(splitSourceField.size() - 1)
                                )
                            )
                        );
                    } else {
                        dest.put(
                            metadataRec.QTB_Destination_Field_API_Name__c,
                            tempSource.get(splitSourceField.get(splitSourceField.size() - 1))
                        );
                        if (
                            metadataRec.QTB_Condition__c == 'BillingAccountOS' &&
                            metadataRec.QTB_Condition__c != 'OraclePlatformEvent' &&
                            sourcSobj.getSobjects('AccountContactRelations') != null
                        ) {
                            dest.put(
                                'QTB_Contact_Name__c',
                                sourcSobj.getSobjects('AccountContactRelations')
                                .get(0)
                                .getSobject('Contact')
                                .get('Name')
                            );
                            system.debug(
                                'Contact Name' +
                                sourcSobj.getSobjects('AccountContactRelations')
                                .get(0)
                                .getSobject('Contact')
                                .get('Name')
                            );
                        }
                    }
                }
            }
        }
        return dest;
    }
    /***********************************************************************************************************
* Method : fieldupd
* Parameters: List<Sobject>,Map<id,id>, String,String, String
* Requirement :
* Start Date :
* Author : Accenture
* Description: Dynamic field mapping framework that can be used to flow data from source object field to
*  destination object field which was mapped in custom metadata:QTB_Field_Mapping
**************************************************************************************************************/
    public static void fieldUpdate(
        Set<Id> listofSourceIds,
        List<Mapping> mappings,
        String source,
        String destination,
        String metadataCondition
    ) {
        // Check if passed parameters were not blank
        if (
            !listofSourceIds.isEmpty() &&
            !mappings.isEmpty() &&
            String.isNotBlank(source) &&
            String.isNotBlank(destination) &&
            String.isNotBlank(metadataCondition)
        ) {
            List<QTB_Field_Mapping__mdt> metadataRecList;
            //Query metadata field mapping records in context
            metadataRecList = QTB_Utils.getFieldMapMetadata(
                source,
                destination,
                metadataCondition
            );
            //Get source records from dynamic query
            String finalQuery =
                QTB_Utils.returnSourceRecordQuery(metadataRecList) +
                ' WHERE id IN :listofSourceIds';
            
            if (String.isNotBlank(finalQuery)) {
                Map<Id, Sobject> mapOfSourceRecords = new Map<Id, Sobject>(
                    (List<Sobject>) Database.query(finalQuery)
                );
                //Iterate over destination records and map field values from source dynamically
                for (Mapping eachMapping : mappings) {
                    if (mapOfSourceRecords.containsKey(eachMapping.sourceRecordId)) {
                        eachMapping.source = mapOfSourceRecords.get(
                            eachMapping.sourceRecordId
                        );
                        QTB_Utils.mapSourceFldValuetoDestFldVal(
                            eachMapping.destination,
                            eachMapping.source,
                            metadataRecList
                        );
                    }
                }
            }
        }
    }
    /***********************************************************************************************************
* Method : updateTaxTreatmentOrderProducts
* Parameters: Set<Id> ,Map <Id,Account> ,List<OrderItem>
* Requirement :
* Start Date :
* Author : Virtusa
* Change History: 06/12/2022 - For Story #12122 logic to avoid billing frequency override for Ad-hoc orders
* Change History: 07/12/2022 - For Story #11924 To avoid setting hold billing 'No' for Ad Hoc orders
* Change History: 05/04/2024 - For Story #22533 To correctly populate Tax rule based on Treatment 
* Description: Logic for Tax Treatment Population on Order Product
**************************************************************************************************************/
    public static List<OrderItem> updateTaxTreatmentOrderProducts(
        Set<Id> legalEntityIds,
        Map<Id, Account> accMap,
        List<OrderItem> billingOrderItem
    ) {
        Set<ID> orderIDs = new Set<ID>();
        List<Order> orderList = new List<Order>();
        Map<String, Id> tempMap = new Map<String, Id>();
        //Gitlab #22533 Map to store tax treatment and its related tax rule Id  
        Map<Id,Id>treatmentTaxRuleMap = new Map<Id,Id>();
        
        for (orderItem ordProd : billingOrderItem) {
            orderIDs.add(ordProd.OrderID);
        }
        
        if (!legalEntityIds.isEmpty()) {
            for (blng__TaxTreatment__c trt : [
                SELECT
                Id,
                name,
                QTB_Special_Tax_Condition__c,
                blng__TaxCode__c,
                QTB_Taxable__c,
                blng__TaxLegalEntity__c,
                QTB_TaxCountry__c,
                blng__TaxRule__c, //Adding blng__TaxRule__c & blng__TaxRule__r.blng__TaxableYesNo__c for defect #13233
                blng__TaxRule__r.blng__TaxableYesNo__c,createdDate
                FROM blng__TaxTreatment__c
                WHERE
                blng__TaxLegalEntity__c IN :LegalEntityIds
                AND blng__Active__c = TRUE Order by createdDate desc] 
                ) {
                    //Creating Map with key as a special combination unique to each tax treatment and value as tax treatment ID
                    // Added Null check (trt.QTB_TaxCountry__c) as part of # 20604
                    if(trt.QTB_TaxCountry__c != Null){
                        TempMap.put(
                            trt.blng__TaxLegalEntity__c +
                            trt.QTB_Taxable__c +
                            trt.QTB_Special_Tax_Condition__c +
                            trt.QTB_TaxCountry__c.toLowerCase(),
                            trt.Id
                        );
                    }
                    treatmentTaxRuleMap.put(trt.Id,trt.blng__TaxRule__c);
                }
        }
        
        if (!orderIDs.isEmpty()) {
            orderList = [
                SELECT
                id,
                AccountID,
                QTB_OrderCategory__c,// Adding the category for Story #12122 to avoid billing frequency override for Ad-hoc orders
                Account.QTB_Contract_Entity__c,
          SBQQ__PaymentTerm__c, QTB_Legal_Entity_Country__c
                FROM order
                WHERE id IN :orderIDs
            ];
        }
        Map<ID, Order> orderMap = new Map<ID, Order>(orderList);
        
        for (OrderItem ord : billingOrderItem) {
            //Loop to assign values to order product
            String str;
            if (
                orderMap.containsKey(ord.OrderID) &&
                orderMap.get(ord.OrderID).AccountID != null &&
                accMap.containsKey(OrderMap.get(ord.OrderID).AccountID)
            ) {
                if (
                    accMap.get(orderMap.get(ord.orderID).AccountID).QTB_Legal_Entity_Country__c !=
                    null
                ) {
                    str =
                        orderMap.get(ord.OrderID).Account.QTB_Contract_Entity__c +
            ((accMap.get(OrderMap.get(ord.orderID).AccountID)
                .SBQQ__TaxExempt__c == 'Yes')
              ? 'No'
              : 'Yes') +
                        accMap.get(orderMap.get(ord.orderID).AccountID)
                        .QTB_Special_Tax_Condition__c +
                        // As part of  # 20604 Updated Shipping Country to Legal Entity Country
                        accMap.get(orderMap.get(ord.orderID).AccountID)
                        .QTB_Legal_Entity_Country__c.toLowerCase();
                    // recreating unique combination to fetch tax treatment for this order product
                } /*else {
str =
orderMap.get(ord.OrderID).Account.QTB_Contract_Entity__c +
((accMap.get(OrderMap.get(ord.orderID).AccountID)
.SBQQ__TaxExempt__c == 'Yes')
? 'No'
: 'Yes') +
accMap.get(orderMap.get(ord.orderID).AccountID)
.QTB_Special_Tax_Condition__c +
// As part of  # 20604 Updated Shipping Country to Legal Entity Country
accMap.get(orderMap.get(ord.orderID).AccountID).QTB_Legal_Entity_Country__c;
system.debug('test6'+str);
// recreating unique combination to fetch tax treatment for this order product
}*/
                
                ord.blng__TaxTreatment__c = tempMap.get(str);
                system.debug('final test treat'+ord.blng__TaxTreatment__c);
                if(ord.blng__TaxTreatment__c != null){
                    ord.blng__TaxRule__c = treatmentTaxRuleMap.get(ord.blng__TaxTreatment__c);
                }
                // As part of  # 20604 Updated Shipping Country to Legal Entity Country
                ord.blng__TaxCountry__c = accMap.get(
                    orderMap.get(ord.orderID).AccountID
                )
                    .QTB_Legal_Entity_Country__c;
                String s = orderMap.get(ord.orderID).SBQQ__PaymentTerm__c;
                ord.QTB_Payment_Term__c = s.substring(s.indexOf(' ') + 1);
                ord.blng__LegalEntity__c = orderMap.get(ord.OrderID)
                    .Account.QTB_Contract_Entity__c;
                // for Story #12122 logic to avoid billing frequency override for Ad-hoc orders
                if(orderMap.get(ord.OrderID).QTB_OrderCategory__c != QTB_Constants.ORDCATEGORY_ADHOC) 
                {
                    ord.SBQQ__BillingFrequency__c = (ord.SBQQ__ChargeType__c ==
                                                     QTB_Constants.CHARGE_TYPE_RECURRING ||
                                                     ord.SBQQ__ChargeType__c == QTB_Constants.CHARGE_TYPE_USAGE)
                        ? accMap.get(OrderMap.get(ord.orderID).AccountID)
                        .QTB_Billing_Frequency__c
                        : null;
                }        
                if (
                    ord.SBQQ__ChargeType__c == QTB_Constants.CHARGE_TYPE_RECURRING && ord.QTB_OriginalConsumptionID__c ==null &&
                    ord.blng__BillableUnitPrice__c != null &
                    ord.UnitPrice != null &&
                    ord.blng__BillableUnitPrice__c == 0 &
                    ord.UnitPrice == 0 &&
                    orderMap.get(ord.OrderID).QTB_OrderCategory__c != QTB_Constants.ORDCATEGORY_ADHOC //For Story #11924 To avoid setting hold billing 'No' for Ad Hoc orders
                ) {
                    ord.blng__HoldBilling__c = 'Yes';
                } else {
                    ord.blng__HoldBilling__c = (accMap.get(
                        OrderMap.get(ord.orderID).AccountID
                    )
                                                .QTB_Hold_Billing__c == true)
                        ? 'Yes'
                        : 'No';
                }
            }
        }
        
        return billingOrderItem;
    }
    
    /***********************************************************************************************************
* Method : checkDigitforNorwayDenmark
* Parameters: String
* Requirement :
* Start Date :
* Author : Accenture
* Description: Logic for determining check digit for different Norway Denmark
**************************************************************************************************************/
    public static integer checkDigitforNorwayDenmark(String invoicePlusBilling) {
        string checkDigitString = invoicePlusBilling.Trim(); //checkDigitString=108006871622001370
        integer stringLen = checkDigitString.length(); //stringLen=18
        integer multiplier = 2;
        decimal weightedSumTotal = 0;
        integer stringNum = 0;
        decimal weigntedSum = 0;
        integer i = 0;
        integer checkDigit = 0;
        
        while (stringLen > 0) {
            stringNum = Integer.valueOf(
                checkDigitString.substring(stringLen - 1, stringLen)
            ); //stringNum=1
            if (stringNum > 0) {
                weigntedSum = stringNum * multiplier; //weigntedSum=1*2=2
                if (weigntedSum < 10) {
                    weightedSumTotal = weigntedSum + weightedSumTotal; //weightedSumTotal=2
                } else {
                    weightedSumTotal =
                        Integer.valueOf(String.ValueOf(weigntedSum).substring(1, 2)) +
                        Integer.valueOf(String.ValueOf(weigntedSum).substring(0, 1)) +
                        weightedSumTotal;
                    //weigntedSumTotal=2+1+0=3
                }
            }
            if (multiplier == 2) {
                //Need to check
                multiplier = 1;
            } else {
                multiplier = 2;
            }
            i++;
            stringLen = stringLen - 1;
        }
        decimal digit1 = 10 - (weightedSumTotal / 10); //digit1=10-0.3=9.7
        digit1 = digit1.SetScale(1);
        checkDigit = Integer.ValueOf(string.valueOf(digit1).substringAfter('.'));
        return checkDigit;
    }
    
    /***********************************************************************************************************
* Method : checkDigitforFinland
* Parameters: String
* Requirement :
* Start Date :
* Author : Accenture
* Description: Logic for determining check digit for different Finland
**************************************************************************************************************/
    public static integer checkDigitforFinland(String InvoiceNumber) {
        String Invoice_No = '' + InvoiceNumber;
        Invoice_No = Invoice_No.trim();
        Integer Invoice_Length = Invoice_No.length();
        Integer Pos = 0;
        Integer Weight_Flag = 1;
        Integer CheckDigitSum = 0;
        Integer CheckDigit = 0;
        Integer Weight = 1; //issue
        String TEMP_FIN; //NO IDEA why we are using this
        
        for (Integer i = Invoice_Length; i > 0; i--) {
            String Invoice_Digit = Invoice_No.substring(Pos, Pos + 1);
            Integer temp = Integer.valueOf(Invoice_Digit);
            switch on Weight_Flag {
                when 1 {
                    Weight = 7;
                }
                when 2 {
                    Weight = 1;
                }
                when 3 {
                    Weight = 3;
                }
                when else {
                }
            }
            temp = temp * Weight;
            CheckDigitSum = CheckDigitSum + temp;
            TEMP_FIN = '' + CheckDigitSum;
            if (Weight_Flag == 3) {
                Weight_Flag = 1;
            } else {
                Weight_Flag++;
            }
            Pos++;
        }
        Integer Reminder = Math.mod(CheckDigitSum, 10);
        Integer CheckDigitSum1;
        if (Reminder == 0) {
            CheckDigitSum1 = CheckDigitSum;
        } else {
            Reminder = 10 - Reminder;
            CheckDigitSum1 = CheckDigitSum + Reminder;
        }
        CheckDigit = CheckDigitSum1 - CheckDigitSum;
        //LET $CHK_DGT = EDIT(#CHK_DGT, '9')
        //If we get more more then one digit number then bellow is the logic to truncate rest of the number;
        String SingleDigit = ('' + CheckDigit).substring(0, 1);
        Invoice_No = Invoice_No + SingleDigit;
        return Integer.valueOf(SingleDigit);
    }
    
    /*********************************************************************************************************
*Method Name: preBillBatches
*Parameters: void
*Return Type: Set<String>
*Author : Accenture
*Description: Checks if the difference between Today and Invoice Scheduler Next Fire Date is 1
and returns their Invoice Batches.
**********************************************************************************************************/
    public static Map<String, Date> preBillBatches() {
        Map<String, Date> mapBatchesToDate = new Map<String, Date>();
        Set<Id> cId = new Set<Id>();
        List<blng__InvoiceScheduler__c> schedulerList = new List<blng__InvoiceScheduler__c>();
        
        // List<CronTrigger> ctList = [Select Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType,NextFireTime
        //                            FROM CronTrigger WHERE CronJobDetail.JobType = : SEVEN_CONSTANT and NextFireTime = TOMORROW  ];
        
        cId = (new Map<id, CronTrigger>(
            [
                SELECT
                Id,
                CronJobDetail.Id,
                CronJobDetail.Name,
                CronJobDetail.JobType,
                NextFireTime
                FROM CronTrigger
                WHERE
                CronJobDetail.JobType = :SEVEN_CONSTANT
                AND NextFireTime = TOMORROW
            ]
        ))
            .keySet();
        /*   for(CronTrigger crTg: ctList){
Date d1;
DateTime dt = crTg.NextFireTime;

if(dt!=null){
d1 = date.newinstance(dT.year(), dT.month(), dT.day());
if(d1!=null && (Date.today()).daysBetween(d1) == 1){
cId.add(crTg.Id);
}

}
} */
        if (cId != null && !cId.isEmpty()) {
            schedulerList = [
                SELECT Id, blng__InvoiceBatches__c, blng__TargetDate__c
                FROM blng__InvoiceScheduler__c
                WHERE blng__ApexJobId__c IN :cId
            ];
            for (blng__InvoiceScheduler__c insch : schedulerList) {
                Set<String> invoiceBatches = new Set<String>();
                invoiceBatches.addAll(insch.blng__InvoiceBatches__c.split(SEMI_COLON));
                if (!invoiceBatches.isEmpty() && invoiceBatches != null) {
                    for (string batch : invoiceBatches)
                        mapBatchesToDate.put(batch, insch.blng__TargetDate__c);
                }
                //  System.debug('mapp>>'+mapBatchesToDate);
            }
            System.debug('final mapp>>' + mapBatchesToDate);
        }
        
        return mapBatchesToDate;
    }
    
    /***********************************************************************************************************
* Method : publishPriceScheduleEvents
* Parameters: List<Contract>
* Requirement : SFCPQBLG-45
* Start Date : 06/10/2020
* Author : Accenture
* Description: Method to get the list of contract and subscription values to fire platform event
**************************************************************************************************************/
    public static void publishPriceScheduleEvents(
        Set<Id> quoteId,
        String whereCond
    ) {
        List<QTB_Price_Schedule__e> priceScheduleList = new List<QTB_Price_Schedule__e>();
        
        String finalQuery = '';
        //Get metadata records
        List<QTB_Field_Mapping__mdt> metadataRecList = GetFieldMapMetadata(
            QTB_Constants.SOBJECT_QUOTE_LINE,
            QTB_Constants.PRICE_SCHEDULE_PE,
            QTB_Constants.PRICE_PE_COND
        );
        //Get source record query
        
        finalQuery = ReturnSourceRecordQuery(metadataRecList) + whereCond;
        system.debug('finalQuery of PS' + finalQuery);
        if (String.isNotBlank(finalQuery)) {
            Map<Id, sObject> mapOfSourceIdRec = new Map<Id, sObject>(
                Database.query(finalQuery)
            );
            system.debug('mapOfSourceIdRec of PS' + mapOfSourceIdRec);
            for (Id con : mapOfSourceIdRec.keyset()) {
                QTB_Price_Schedule__e dest = new QTB_Price_Schedule__e();
                if (mapOfSourceIdRec.containsKey(con)) {
                    system.debug('mapOfSourceIdRec11 of PS' + mapOfSourceIdRec);
                    sObject priceSchedule = mapOfSourceIdRec.get(con);
                    dest = (QTB_Price_Schedule__e) MapSourceFldValuetoDestFldVal(
                        dest,
                        priceSchedule,
                        metadataRecList
                    );
                    dest.QTB_Catalog_Code__c = QTB_Constants.CATALOG_CODE;
                    dest.QTB_Flat_Flee_Flag__c = QTB_Constants.FLAT_FLEE;
                    if (dest.QTB_EndDate__c != null) {
                        dest.QTB_Fee_Schedule_Renewal_Date__c = dest.QTB_EndDate__c + 1;
                    }
                    if (dest.QTB_Name__c != null) {
                        dest.QTB_Fee_Schedule_Description__c = dest.QTB_Name__c;
                    }
                    priceScheduleList.add(dest);
                    system.debug('priceScheduleList' + priceScheduleList);
                }
            }
        }
        if (priceScheduleList.size() > 0) {
            List<Database.SaveResult> results = EventBus.publish(priceScheduleList);
            system.debug('results of PS' + results);
        }
    }
    /***********************************************************************************************************
* Method : publishBillingAccountEvent
* Parameters: List<Account>
* Requirement : SFCPQBLG-48
* Start Date : 06/10/2020
* Author : Accenture
* Description: Method to get the list of Account and Contact values to fire platform event
**************************************************************************************************************/
    
    public static void publishBillingAccountEvent(
        Set<Id> accIdSet,
        String whereCond
    ) {
        List<QTB_Billing_Account_OS__e> billingAccountOSList = new List<QTB_Billing_Account_OS__e>();
        
        String finalQuery = '';
        
        //Get metadata records
        List<QTB_Field_Mapping__mdt> metadataRecList = GetFieldMapMetadata(
            QTB_Constants.SOBJECT_ACCOUNT,
            QTB_Constants.BILLING_OS_PE,
            QTB_Constants.BILLING_OS_PE_COND
        );
        //Get source record query
        
        finalQuery = ReturnSourceRecordQuery(metadataRecList) + whereCond;
        system.debug('finalQuery of OS' + finalQuery);
        if (String.isNotBlank(finalQuery)) {
            Map<Id, sObject> mapOfSourceIdRec = new Map<Id, sObject>(
                Database.query(finalQuery)
            );
            system.debug('mapOfSourceIdRec of OS' + mapOfSourceIdRec);
            for (Id con : mapOfSourceIdRec.keyset()) {
                QTB_Billing_Account_OS__e dest = new QTB_Billing_Account_OS__e();
                if (mapOfSourceIdRec.containsKey(con)) {
                    system.debug('mapOfSourceIdRec11 of OS' + mapOfSourceIdRec);
                    sObject billingAccountOS = mapOfSourceIdRec.get(con);
                    dest = (QTB_Billing_Account_OS__e) MapSourceFldValuetoDestFldVal(
                        dest,
                        billingAccountOS,
                        metadataRecList
                    );
                    billingAccountOSList.add(dest);
                    system.debug('billingAccountOSList' + billingAccountOSList);
                }
            }
        }
        system.debug('billingAccountOSList11' + billingAccountOSList);
        if (billingAccountOSList.size() > 0) {
            system.debug('billingAccountOSList22' + billingAccountOSList);
            List<Database.SaveResult> results = EventBus.publish(
                billingAccountOSList
            );
            system.debug('results of billing account OS' + results);
            Map<Id, QTB_Billing_Account_OS__e> billMap = new Map<Id, QTB_Billing_Account_OS__e>();
            List<Account> accAdd = new List<Account>();
            for (QTB_Billing_Account_OS__e billOs : billingAccountOSList) {
                billMap.put(billOs.QTB_Account_ID__c, billOs);
            }
            if (billMap != null) {
                List<Account> accList = [
                    SELECT
                    id,
                    QTB_Level_1__c,
                    QTB_Level_2__c,
                    QTB_Division__c,
                    QTB_Department__c,
                    QTB_Customer_District__c
                    FROM Account
                    WHERE id IN :billMap.keySet()
                ];
                
                for (Account acc : accList) {
                    acc.QTB_Level_1__c = '';
                    acc.QTB_Level_2__c = '';
                    acc.QTB_Division__c = '';
                    acc.QTB_Department__c = '';
                    //acc.QTB_Customer_District__c = ''; //commented for SIT fix
                    String str = '';
                    if (billMap.get(acc.Id).QTB_Data_Management__c != null) {
                        str += QTB_Constants.DATA_MANAGEMENT + SEMI_COLON;
                    }
                    if (billMap.get(acc.Id).QTB_Records_Management__c != null) {
                        str += QTB_Constants.RECORDS_MANAGEMENT + SEMI_COLON;
                    }
                    if (billMap.get(acc.Id).QTB_scan__c != null) {
                        str += QTB_Constants.SCAN + SEMI_COLON;
                    }
                    if (billMap.get(acc.Id).QTB_shred__c != null) {
                        str += QTB_Constants.SHRED + SEMI_COLON;
                    }
                    str = str.removeEnd(SEMI_COLON);
                    acc.QTB_Platform_BillingOS__c = str;
                    accAdd.add(acc);
                }
                if (!accAdd.isEmpty()) {
                    update accAdd;
                }
            }
        }
    }
    
    /***********************************************************************************************************
* Method : publishBillingAccountOracleOS
* Parameters: List<Account>, List<Contact>
* Requirement : SFCPQBLG-646
* Start Date : 06/14/2020
* Author : Accenture
* Description: Method to get the list of account and its contact values to fire platform event
**************************************************************************************************************/
    public static void publishBillingAccountOracleOS(
        Set<Id> sourceIdSet,
        String whereCond
    ) {
        List<QTB_Billing_Account_Oracle__e> billingAccountOracleList = new List<QTB_Billing_Account_Oracle__e>();
        
        String finalQuery = '';
        //Get metadata records
        List<QTB_Field_Mapping__mdt> metadataRecList = GetFieldMapMetadata(
            QTB_Constants.ACCOUNTCONTACTRELATION,
            QTB_Constants.ORACLE_PE,
            QTB_Constants.BILLING_ORACLE_PE_COND
        );
        //Get source record query
        set<id> parentId = new Set<id>();
        finalQuery = ReturnSourceRecordQuery(metadataRecList) + whereCond;
        system.debug('finalQuery' + finalQuery);
        if (String.isNotBlank(finalQuery)) {
            Map<Id, sObject> mapOfSourceIdRec = new Map<Id, sObject>(
                Database.query(finalQuery)
            );
            system.debug('mapOfSourceIdRec' + mapOfSourceIdRec);
            for (Id con : mapOfSourceIdRec.keyset()) {
                QTB_Billing_Account_Oracle__e dest = new QTB_Billing_Account_Oracle__e();
                if (mapOfSourceIdRec.containsKey(con)) {
                    system.debug('mapOfSourceIdRec' + mapOfSourceIdRec);
                    sObject billingAccountOracle = mapOfSourceIdRec.get(con);
                    dest = (QTB_Billing_Account_Oracle__e) MapSourceFldValuetoDestFldVal(
                        dest,
                        billingAccountOracle,
                        metadataRecList
                    );
                    dest.QTB_Statement_Cycle__c = QTB_Constants.IM_MONTHLY;
                    dest.QTB_Account_Status__c = QTB_Constants.ACTIVE;
                    dest.QTB_SITE_USE_CODE__c = QTB_Constants.BILLTO;
                    dest.QTB_Constant__c = QTB_Constants.DETAIL;
                    dest.QTB_Source__c = QTB_Constants.SALESFORCE;
                    if (dest.QTB_BillingCity__c != null) {
                        dest.QTB_bill_to_location__c = dest.QTB_BillingCity__c;
                    }
                    system.debug('dest' + dest);
                    billingAccountOracleList.add(dest);
                    //parentId.add(dest.QTB_Parent_Account_SFDC__c);
                }
            }
        }
        //if(ParentId!=null)
        //account acc = [select id,qtb_payable_customer_model__c from account where id in: ParentId];
        system.debug('billingAccountOracleList' + billingAccountOracleList);
        if (billingAccountOracleList.size() > 0) {
            List<Database.SaveResult> results = EventBus.publish(
                billingAccountOracleList
            );
            system.debug('results of billing Oracle' + results);
        }
    }
    
    /***********************************************************************************************************
* Method : responseGenerator
* Parameters: SBQQ__Quote__c,map<ID,list<String>> ,Map<String,QTB_ISO_Setting__c>,String
* Requirement :
* Start Date :
* Author : Accenture
* Description: Method to generate a response
**************************************************************************************************************/
    public static HttpResponse responseGenerator(
        SBQQ__Quote__c q,
        Map<String, String> lobshortformMap,
        String serviceEndPoint
    ) {
        List<String> imSightIdList = new List<String>();
        List<QTB_Customer_Billing_Account_Lookup__c> imsightCodes = [
            SELECT
            Id,
            Name,
            QTB_Billing_Account__c,
            QTB_Customer_Account_Name__c,
            QTB_Customer_Account__c,
            QTB_Pricefx_Customer_ID__c,
            QTB_Quote__c
            FROM QTB_Customer_Billing_Account_Lookup__c
            WHERE QTB_Quote__c = :q.SBQQ__Opportunity2__r.QTB_Original_Quote__c
        ];
        HttpResponse response;
        String arrayofImsightId;
        //Generating JSON Request
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        if (lobshortformMap.keySet() != null) {
            gen.writeStringField(
                'CountryCode',
                q.SBQQ__Opportunity2__r.Billing_Country__r.Iso31662Code__c
            );
            gen.writeStringField(
                'BusinessUnit',
                lobshortformMap.get(q.QTB_Opportunity_Product_Line__c)
            );
        }
        gen.writeFieldName('ListOfImsights');
        gen.writeStartArray();
        for (QTB_Customer_Billing_Account_Lookup__c imsight : imsightCodes) {
            gen.writeString(string.valueof(imsight.QTB_Pricefx_Customer_ID__c));
        }
        
        gen.writeEndArray();
        gen.writeEndObject();
        String jsonData = gen.getAsString();
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(serviceEndPoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(jsonData);
            // time out error
            request.setTimeout(120000);
            response = http.send(request);
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                UTILCLASS
            );
        }
        return response;
    }
    // custom class to hold the record mappings
    // used for dynamic field mapping framework
    public without sharing class Mapping {
        // all getters setters for properties
        public SObject source {
            get {
                return this.source;
            }
            set {
                this.source = value;
            }
        }
        public SObject destination {
            get {
                return this.destination;
            }
            set {
                this.destination = value;
            }
        }
        public Id sourceRecordId {
            get {
                return this.sourceRecordId;
            }
            set {
                this.sourceRecordId = String.isNotBlank(value)
                    ? value
                    : this.sourceRecordId;
            }
        }
        public Id destinationRecordId {
            get {
                return this.destinationRecordId;
            }
            set {
                this.destinationRecordId = String.isNotBlank(value)
                    ? value
                    : this.destinationRecordId;
            }
        }
        // do not allow any instance without parameters
        private Mapping() {
        }
        // mapping support for record to record
        public Mapping(SObject fromThis, SObject toThis) {
            this.source = fromThis;
            this.destination = toThis;
            this.sourceRecordId = this.source.Id;
            this.destinationRecordId = this.destination.Id;
        }
        // mapping support for id to record
        public Mapping(Id sourceRecordId, SObject toThis) {
            this.destination = toThis;
            this.sourceRecordId = sourceRecordId;
            this.destinationRecordId = this.destination.Id;
        }
        // mapping support for id to id
        public Mapping(Id sourceRecordId, Id destinationRecordId) {
            this.sourceRecordId = sourceRecordId;
            this.destinationRecordId = destinationRecordId;
        }
    }
}
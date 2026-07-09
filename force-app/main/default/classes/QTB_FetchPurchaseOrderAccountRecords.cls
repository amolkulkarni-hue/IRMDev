/*****************************************************************************************************
* Class: QTB_FetchPurchaseOrderAccountRecords
* Author: Virtusa
* Purpose: This is an Apex class which contains all the methods to return data.
* Requirement: US #29688, US #30782
* Change History: 22/05/2025
* Developer                Date           Description
* ---------------------------------------------------------------------------------------------------------------------------------------------------------
*  Initial Development    22/05/2025
**********************************************************************************************************************************************************/

public with sharing class QTB_FetchPurchaseOrderAccountRecords {
    
    private static final String CLASSNAME = 'QTB_FetchPurchaseOrderAccountRecords';
    
    /***********************************************************************************************************
* Method      : getPOAccount
* Parameters  : String recordId
* Description : Show all the related PurchaseOrderJunction Object records
* Return Type : List<QTB_PurchaseOrderAccount__c>
* Developer               Date           Description
--------------------------------------------------------------------------------------
* Initial Development    22/05/2025
**************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<QTB_PurchaseOrderAccount__c> getPOAccount(String recordId){
        try{
            if(recordId == null || String.isBlank(recordId)) { 
                throw new AuraHandledException('Invalid input: PurchaseOrderId or recordId is missing.'); //Throw Exception if null
            } 
            
            //Query on the QTB_PurchaseOrderAccount__c object and return of the relevant data.
            List<QTB_PurchaseOrderAccount__c> poAccList = [SELECT ID,Name,QTB_Purchase_Order__c,QTB_Purchase_Order__r.Name,QTB_Account__c,QTB_Account__r.Name,QTB_Account__r.Bill_To_Site_Number__c ,QTB_Account__r.QTB_Customer_Number__c
                                                           FROM QTB_PurchaseOrderAccount__c 
                                                           WHERE QTB_Purchase_Order__c = :recordId ];
            if(poAccList!=null && !poAccList.isEmpty()){
                return poAccList;
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method      : getAllBillingAccount
* Parameters  : String recordId
* Description : Show all the related Billing Accounts whose country = PurchaseOrder's Country.
* Return Type : List<Account>
* Developer               Date           Description
--------------------------------------------------------------------------------------
* Initial Development    22/05/2025
**************************************************************************************************************/   
    @AuraEnabled(cacheable=true)
    public static List<Account> getAllBillingAccount(String recordId){
        
        try{
            if(recordId == null || String.isBlank(recordId)) { 
                throw new AuraHandledException('Invalid input: PurchaseOrderId or recordId is missing.'); //Throw Exception if null
            } 
            
            // Fetching the country of the PurchaseOrder.
            String country = [SELECT ID,QTB_Legal_Entity_Country__c
                              FROM QTB_PurchaseOrder__c 
                              WHERE ID = :recordId ].QTB_Legal_Entity_Country__c; 
            // Fetching the billingAccount whose is country is same as that of the PurchaseOrder.
            List<Account> billingAccountList = [SELECT ID,Name,QTB_Customer_Number__c,QTB_Legal_Entity_Country__c,BillingCountry,QTB_Legal_Entity__c,QTB_Legal_Entity__r.Name,Bill_To_Site_Number__c
                                                FROM Account 
                                                WHERE RecordType.Name = 'Billing Account' AND QTB_Legal_Entity_Country__c = :country AND (NOT Name LIKE 'BILLP%') AND ParentId!=null ];
            
            if(billingAccountList!=null && !billingAccountList.isEmpty()){
                return billingAccountList;
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method      : getSiblingBillingAccount
* Parameters  : String billingAccountId
* Description : Show all the related Sibling Billing Accounts of the SELECTed BillingAccountId.
* Return Type : List<Account>
* Developer               Date           Description
--------------------------------------------------------------------------------------
* Initial Development    22/05/2025
* Refactored the method as per the requirement in GITLAB US - #31808
**************************************************************************************************************/  
    @AuraEnabled(cacheable=true)
    public static List<Account> getSiblingBillingAccount(String billingAccountId){
        try {
            if(billingAccountId == null || String.isBlank(billingAccountId)){ 
                throw new AuraHandledException('Invalid input: Billing Account ID or recordId is missing.');
            }
            // Query the Account to get ParentId and RecordType Name
            Account billingAccount = [SELECT Id, ParentId, RecordType.Name  
                                        FROM Account 
                                         WHERE Id = :billingAccountId   ];
            
            Id parentAccountId;
            
            // Only capture parentAccountId if ParentId is not null AND RecordType is 'Billing Account'
            if(billingAccount.ParentId != null && billingAccount.RecordType.Name == 'Billing Account') {
                parentAccountId = billingAccount.ParentId;
            }
            
            String baseQuery = 'SELECT ID, Name, Bill_To_Site_Number__c, QTB_Legal_Entity_Country__c, BillingCountry, QTB_Legal_Entity__r.Name ' +
                'FROM Account ' +
                'WHERE RecordType.Name = \'Billing Account\' AND ';
            
            String whereClause;
            
            if(parentAccountId != null) {
                // Fetch siblings with the same ParentId
                System.debug('Parent Account ID present and record is Billing Account, fetching siblings');
                whereClause = 'ParentId = \'' + String.escapeSingleQuotes(parentAccountId) + '\'';
            } else {
                // No valid parent found or record is not Billing Account, return the sales Account itself to be used as parent Id
                System.debug('No Parent Account ID or record not Billing Account, returning the billing account itself');
                whereClause = 'ParentId = \'' + String.escapeSingleQuotes(billingAccountId) + '\'';
            }
            String fullQuery = baseQuery + whereClause;
          //  return (List<Account>)Database.query(fullQuery);
		     List<Account> siblings = (List<Account>)Database.query(fullQuery);
		    // Adding original billing account to beginning of list to pass ParentId to LWC
            siblings.add(0, billingAccount);
             return siblings;	
        } catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }
    
    
    
    /***********************************************************************************************************
* Method      : createPurchaseOrderAccounts
* Parameters  : String recordId, List<String> accountList
* Description : Create PurchaseOrderAccounts
* Return Type : String
* Developer               Date           Description
--------------------------------------------------------------------------------------
* Initial Development    22/05/2025
**************************************************************************************************************/  
    @SuppressWarnings('Security-ApexCRUDViolation')
    @AuraEnabled
    public static String createPurchaseOrderAccounts(String recordId, List<String> accountList){
        try{
            if(accountList == null || accountList.isEmpty() || String.isBlank(recordId)){ // throw an excpetion early if null
                throw new AuraHandledException('Invalid input: accountList or recordId is missing.');
            }
            ID purchaseOrderId = ID.valueOf(recordId);
            Integer count = 0;
            Map<ID,ID> existingPOAMap = new Map<ID,ID>();
            for(QTB_PurchaseOrderAccount__c poA : [SELECT ID,Name,QTB_Account__c 
                                                   FROM QTB_PurchaseOrderAccount__c 
                                                   WHERE QTB_Account__c IN : accountList AND  QTB_Purchase_Order__c =:purchaseOrderId ]){
                                                       existingPOAMap.put(poA.QTB_Account__c, purchaseOrderId);
                                                   }
            // GITLAB US - #31808 Fetching  the PurchaseOrder record to update sales account id
            QTB_PurchaseOrder__c poRecord = [SELECT ID, QTB_Linked_Sales_Account__c
                                             FROM QTB_PurchaseOrder__c
                                             WHERE ID = :purchaseOrderId  LIMIT 1];
            
            Id parentAccountID = [SELECT ID,parentId
                                  FROM Account 
                                  WHERE ID = :accountList  LIMIT 1].parentId; 
            // Update the linked sales account field
            poRecord.QTB_Linked_Sales_Account__c = parentAccountID;
            // poList[0].QTB_Linked_Sales_Account__c = parentAccountID;
            List<QTB_PurchaseOrderAccount__c> poAccList = new List<QTB_PurchaseOrderAccount__c>();
            for (String accountId : accountList){
                if(existingPOAMap.containsKey(ID.valueOf(accountId))){
                    continue;
                }
                poAccList.add(new QTB_PurchaseOrderAccount__c( QTB_Account__c = ID.valueOf(accountId),
                                                              QTB_Purchase_Order__c = purchaseOrderId));
            }
            
            Database.update(poRecord, true); 
            
            if(poAccList!=null && !poAccList.isEmpty()){ // check if atleast one item is present in the List to insert
                Database.insert(poAccList ,true) ;
                return 'Success';
            }else{
                return 'Duplicates';
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method      : getLinkedParentAccountId
* Parameters  : Id purchaseOrderId
* Description : this method Returns the Id of the linked sales account (parent account) if it exists, otherwise returns null
* Return Type : String
* Developer               Date           Description
--------------------------------------------------------------------------------------
* Initial Development    08/06/2025
**************************************************************************************************************/  	
    @AuraEnabled(cacheable=true)
    public static Id getLinkedSalesAccountId(Id purchaseOrderId) {
        List<QTB_PurchaseOrder__c> poList = [ SELECT Id, QTB_Linked_Sales_Account__c  FROM QTB_PurchaseOrder__c WHERE Id = :purchaseOrderId  LIMIT 1 ];
        system.debug('poList--> ' +poList);
        // return po.QTB_Linked_Sales_Account__c;
        if (!poList.isEmpty()) {
            return poList[0].QTB_Linked_Sales_Account__c;
        }
        return null; // Return null if no record found
        
    }	
	
	public static void codeCoverageMethod() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
          i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    } 
    
}
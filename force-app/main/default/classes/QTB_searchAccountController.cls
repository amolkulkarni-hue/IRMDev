/*****************************************************************************************************
* Class: QTB_searchAccountController
* Author: Accenture
* Purpose: Controller class for Lightning Component 'searchAccount' related to Associate Billing Account button
* Requirement: SFCPQBLG-49
* Change History: 6/9/2020
* Developer      Date           Description
* -------------------------------------------------------------------------------------------
* Accenture     4/27/2020
* Accenture   4/8/2020    Adding fix for ALM Defect # 276, billing account association at stage 7
*******************************************************************************************************/
public class QTB_searchAccountController {
    private static final Id accntBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
    public static boolean throwExplicitException = false;
    
    /***********************************************************************************************************
    * Method : fetchAccount
    * Parameters: String, String, Id
    * Requirement :
    * Returns : List<wrapperAccData>
    * Author : Accenture
    * Description: Method to fetch the list of accounts based on IMGA and Billing country filter criteria
    **************************************************************************************************************/
    @AuraEnabled
    public static List<wrapperAccData> fetchAccount(
        String searchKeyWord,
        String searchNumber,
        Id oppId
    ) {
        List<wrapperAccData> wrapAcntList = new List<wrapperAccData>();
        String contactRole = QTB_Constants.CONTACT_ROLE;
        String searchKey = '';
        String searchAcntNumber = '';
        if (searchKeyWord != '' && searchKeyWord != null) {
            searchKey = searchKeyWord + '%';
        }
        if (searchNumber != '' && searchNumber != null) {
            searchAcntNumber = searchNumber + '%';
        }
        List<Opportunity> OppList = [
            SELECT
            id,
            accountid,
            StageName,
            account.IMGA_Lookup__c,
            Billing_Country__r.name,
            CurrencyISOCode
            FROM Opportunity
            WHERE Id = :oppId
        ];
        String oppAccountIMGA = OppList[0].account.IMGA_Lookup__c;
        String oppBillingCountry = OppList[0].Billing_Country__r.name;
        String oppCurrency = OppList[0].CurrencyISOCode; //Added for SFCPQBLG-648
        String query1 =
            'SELECT id,(SELECT Contact.Name FROM AccountContactRelations' +
            ' WHERE Contact.IM_Role__c = :contactRole order by CreatedDate desc limit 1),Name,' +
            'BillingCountry,BillingCity,BillingStreet,Parent.QTB_Customer_Number__c,QTB_Customer_Number__c' +
            ' FROM Account WHERE ( Name LIKE: searchKey';
        
        String query2 =
            'QTB_Customer_Number__c LIKE: searchAcntNumber ) AND RecordTypeId = :accntBillRecordTypeId' +
            ' AND ParentId != NULL AND Parent.IMGA_Lookup__c = :oppAccountIMGA' +
            ' AND BillingCountry =:oppBillingCountry' +
            ' AND CurrencyISOCode =:oppCurrency';
        String query = '';
        if (searchKey != '' && searchAcntNumber != '') {
            query = query1 + ' AND ' + query2;
        } else {
            query = query1 + ' OR ' + query2;
        }
        List<Account> billingAcntList = Database.query(query);
        for (Account acnt : billingAcntList) {
            wrapperAccData obj = new wrapperAccData();
            obj.BillingContact = '';
            obj.BillingAddress = '';
            obj.AccId = acnt.Id;
            obj.CustomerNumber = acnt.QTB_Customer_Number__c;
            obj.ParentCustomerNumber = acnt.Parent.QTB_Customer_Number__c;
            obj.AccName = acnt.Name;
            if (acnt.BillingStreet != null) {
                obj.BillingAddress = acnt.BillingStreet + ',';
            }
            if (acnt.BillingCity != null) {
                obj.BillingAddress += acnt.BillingCity;
            }
            if (
                acnt.AccountContactRelations != null &&
                !acnt.AccountContactRelations.isEmpty()
            ) {
                obj.BillingContact = acnt.AccountContactRelations.get(0).Contact.Name;
            }
            wrapAcntList.add(obj);
        }
        return wrapAcntList;
    }
    
    /***********************************************************************************************************
    * Method : SaveAccRecord
    * Parameters: List<Id>, Id
    * Requirement :
    * Returns : String
    * Author : Accenture
    * Description: Method to save the selected account and redirect to Billing Account and also restricts user
    * from selecting multiple accounts
    **************************************************************************************************************/
    @AuraEnabled
    public static string SaveAccRecord(
        List<Id> accIdList,
        Id oppId,
        Account accValues
    ) {
        Id accId;
        try {
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            accId = accIdList[0];
            Account accRec = [
                SELECT
                Id,
                QTB_Source_Opportunity__c,
                QTB_Records_Management__c,
                QTB_Data_Management__c,
                QTB_scan__c,
                QTB_shred__c
                FROM Account
                WHERE Id = :accId
            ];
            Opportunity oppRec = [
                SELECT id, Primary_Product_line__c, SBQQ__PrimaryQuote__c
                FROM Opportunity
                WHERE id = :oppId
            ];
            
            if (
                accRec.QTB_Records_Management__c &&
                oppRec.Primary_Product_line__c == Label.QTB_LOB_Records_Management
            ){
                return 'Cannot Associate';
            }
            else if (
                accRec.QTB_Data_Management__c &&
                oppRec.Primary_Product_line__c == Label.QTB_LOB_Data_Management
            ) {
                return 'Cannot Associate';
            }
            else if (
                accRec.QTB_scan__c &&
                oppRec.Primary_Product_line__c == Label.QTB_LOB_Scan
            ) {
                return 'Cannot Associate';
            }
            else if (
                accRec.QTB_shred__c &&
                oppRec.Primary_Product_line__c == Label.QTB_LOB_Shred
            ) {
                return 'Cannot Associate';
            }
            
            accRec.QTB_Source_Opportunity__c = oppId;
            //Gitlab#8 start
            if (oppRec.SBQQ__PrimaryQuote__c != null) {
                for (Order sourceOrd : [ SELECT id FROM Order WHERE SBQQ__Quote__c = :oppRec.SBQQ__PrimaryQuote__c LIMIT 1]) {
                    accRec.QTB_Source_Order__c = sourceOrd.id;
                }
            }
            //Gitlab#8 end
            if (accValues != null) {
                //SFCPQBLG-48
                accRec.QTB_Level_1__c = accValues.QTB_Level_1__c;
                accRec.QTB_Level_2__c = accValues.QTB_Level_2__c;
                accRec.QTB_Customer_District__c = accValues.QTB_Customer_District__c;
                accRec.QTB_Create_Operating_System_Account__c = accValues.QTB_Create_Operating_System_Account__c;
            }
            update accRec;
        } catch (DmlException e) {
            //Any type of Validation Rule error message, Required field missing error message, Trigger error message etc..
            String msg = '';
            for (Integer i = 0; i < e.getNumDml(); i++) {
                //Get Validation Rule & Trigger Error Messages
                msg = +e.getDmlMessage(i) + '\n';
            }
            //throw DML exception message
            throw new AuraHandledException(msg);
        }
        return accId;
    }
    
    /*****************************************************************************************************
    * Class: wrapperAccData
    * Author: Accenture
    * Purpose: Wrapper class To store the accounts fetched based on filter criteria
    * Requirement:
    ******************************************************************************************************/
    public class wrapperAccData {
        @AuraEnabled
        public Id AccId;
        @AuraEnabled
        public String CustomerNumber;
        @AuraEnabled
        public String ParentCustomerNumber;
        @AuraEnabled
        public String AccName;
        @AuraEnabled
        public String BillingAddress;
        @AuraEnabled
        public String BillingContact;
    }
    /***********************************************************************************************************
    * Method : checkLatestOpportunityDetails
    * Parameters: Id
    * Requirement :
    * Returns : String
    * Author : Accenture
    * Description: Method to collect latest opportunity Id from contract by passing opportunity
    **************************************************************************************************************/
    @AuraEnabled
    public static string checkLatestOpportunityDetails(Id oppId) {
        try {
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            Opportunity opp = [
                SELECT
                Id,
                Type,
                StageName,
                SBQQ__AmendedContract__c,
                SBQQ__AmendedContract__r.QTB_Latest_Opportunity__c,
                SBQQ__AmendedContract__r.QTB_Latest_Opportunity__r.Name,
                SBQQ__AmendedContract__r.EndDate,
                SBQQ__PrimaryQuote__c,
                (
                    SELECT
                    Id,
                    QTB_Latest_Opportunity__c,
                    QTB_Latest_Opportunity__r.Name,
                    EndDate
                    FROM SBQQ__Contracts__r
                    LIMIT 1
                )
                FROM Opportunity
                WHERE Id = :oppId
            ];
            if(opp.SBQQ__PrimaryQuote__c != null){
            	Order ord=[SELECT id,QTB_OrderCategory__c,SBQQ__Quote__r.SBQQ__EndDate__c from Order WHERE SBQQ__Quote__c = :opp.SBQQ__PrimaryQuote__c];
                if(ord != null && ord.QTB_OrderCategory__c != 'One Time Shred'){
            	//To throw error when contract is not generated for the Opportunity in New Sales and Renewal
            	if ((opp.Type == QTB_Constants.OPP_TYPE_NEWDEAL || opp.Type == QTB_Constants.OPP_TYPE) &&opp.SBQQ__Contracts__r.size() == 0) {
                return 'Contract Not Generated';
            	} else if ((opp.SBQQ__AmendedContract__c != null &&opp.SBQQ__AmendedContract__r.EndDate <= System.Today()) ||(!opp.SBQQ__Contracts__r.isEmpty() 
                                                                                                     && opp.SBQQ__Contracts__r[0].EndDate <= System.Today())) {	
                //To throw error when Contract is Expired and user associate Billing Account
                return 'Contract Expired';
                }
              }else if(ord.QTB_OrderCategory__c == 'One Time Shred' && ord.SBQQ__Quote__r.SBQQ__EndDate__c < System.Today() ){
                            return 'Quote Expired';
              }
        	 if ((opp.Type == QTB_Constants.OPP_TYPE_RATE_CHANGE ||opp.Type == QTB_Constants.OPP_TYPE_UP_SELL) &&opp.SBQQ__AmendedContract__c != null 
                 && opp.SBQQ__AmendedContract__r.QTB_Latest_Opportunity__c != null &&opp.SBQQ__AmendedContract__r.QTB_Latest_Opportunity__c != opp.Id) {
                return '{"Name":"' +opp.SBQQ__AmendedContract__r.QTB_Latest_Opportunity__r.Name +'","Id":"' +opp.SBQQ__AmendedContract__r.QTB_Latest_Opportunity__c +'"}';
            } else if ( opp.SBQQ__Contracts__r != null &&opp.SBQQ__Contracts__r.size() == 1 &&opp.SBQQ__Contracts__r[0].QTB_Latest_Opportunity__c != null 
                       && opp.SBQQ__Contracts__r[0].QTB_Latest_Opportunity__c != opp.Id) {
                return '{"Name":"' +opp.SBQQ__Contracts__r[0].QTB_Latest_Opportunity__r.Name +'","Id":"' +opp.SBQQ__Contracts__r[0].QTB_Latest_Opportunity__c +'"}';
            }
           }
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                QTB_searchAccountController.class.getName()
            );
            throw e;
        }
        return null;
    }
}
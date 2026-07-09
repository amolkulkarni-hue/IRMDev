/*****************************************************************************************************
* Class: QTB_AccountContactRelationHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to AccountContactRelation object
* Requirement: SFCPQBLG-646
* Change History: 6/14/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*               6/14/2020
* Accenture 02/25/2021      Changes made to publish events if contact created for billing account only
*                               GitLab # 1366
*******************************************************************************************************/
public with sharing class QTB_AccountContactRelationHelper {
    public static final String CLASSNAME_LOG = 'QTB_AccountContactRelationHelper';
    //public static final String CONTACT_ROLE_TYPE  = QTB_Constants.CONTACT_ROLE;
    //
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public static void process(
        List<AccountContactRelation> newItems,
        Map<Id, AccountContactRelation> accOldMap,
        System.TriggerOperation operationType
    ) {
        Set<Id> sourceIdSet = new Set<Id>();
        set<Id> accset = new Set<Id>();
        Set<Id> accIDSet2 = new Set<Id>();
        Set<Id> accIDset = new Set<Id>();
        set<Id> contactIDset = new Set<Id>();
        for (AccountContactRelation acRel : newItems) {
            switch on operationType {
                when BEFORE_INSERT {
                    accIDSet2.add(acRel.accountId);
                    contactIDset.add(acRel.contactId);
                }
                when BEFORE_UPDATE {
              //9295 US logic
                    if (acRel.QTB_Primary__c == true && accOldMap.get(acRel.id).QTB_Primary__c == acRel.QTB_Primary__c) {
                        accIDset.add(acRel.accountid);
                    }
                    else if(acRel.QTB_Primary__c == true && accOldMap.get(acRel.id).QTB_Primary__c != acRel.QTB_Primary__c)
                        {
                          accIDset.add(acRel.accountid);  
                        }
                    
                    if(acRel.QTB_Primary__c==true)
                    {
                        
                      acRel.QTB_Checked_by_Trigger__c=false;  
                     
                    }
                    //9295 logic ends
                    //------9295updation--------
                    if (acRel.QTB_Primary__c !=null && acRel.Roles!=null && acRel.QTB_Primary__c == false && accOldMap.get(acRel.id).QTB_Primary__c != acRel.QTB_Primary__c && 
                        acRel.QTB_Checked_by_Trigger__c == false && acRel.Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES) && accOldMap.get(acRel.id).Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES) ) {
                            system.debug('errormessage'+ acRel);
                            system.debug('errormessage1'+ accOldMap);
                        acRel.addError(System.Label.QTB_Uncheck_Primary_Message);
                    }
                    
                    
                    system.debug('primary'+acRel.QTB_Primary__c);
                    system.debug('primary@#'+accOldMap);
                    
                    //Removing the Billing Role scenario--
                    
                    if(acRel.QTB_Primary__c!=null && acRel.Roles!=null && acRel.QTB_Primary__c==false && accOldMap.get(acRel.id).QTB_Primary__c==true && accOldMap.get(acRel.id).Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES)&& !acRel.Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES))
                    {
                       acRel.addError(System.Label.QTB_RemovingBillingRole); 
                    }
                    //13306
                   if(accOldMap.get(acRel.id).QTB_Primary__c != acRel.QTB_Primary__c && acRel.QTB_Primary__c==false && accOldMap.get(acRel.id).Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES) && acRel.Roles==null)
                   {
                       
                       acRel.addError(System.Label.QTB_RemovingBillingRole);
                   }
                     
                    //13306 logic ends
                        
                    if(acRel.QTB_Primary__c != null && acRel.QTB_Primary__c == true &&
                       accOldMap.get(acRel.id).QTB_Primary__c != null && accOldMap.get(acRel.id).QTB_Primary__c == true &&
                      ( acRel.Roles == null ||!acRel.Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES)) &&
                       accOldMap.get(acRel.id).Roles != null && accOldMap.get(acRel.id).Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES))   //13306US
                    {
                        System.debug('rmv'+acRel.Roles);
                        acRel.addError(System.Label.QTB_RemovingBillingRole);  
                    }
                    
                }
                when AFTER_INSERT {
                    sourceIdSet.add(acRel.Id);
                    accset.add(acRel.accountId);
                }
                when else {
                }
            }
        }
        switch on operationType {
            when BEFORE_INSERT {
                if (!accIDSet2.isEmpty() && !contactIDset.isEmpty()) {
                    QTB_BillingAccountUtil.primaryContactInsertion(accIDSet2, contactIDset, newItems);
                }
            }
            when BEFORE_UPDATE {
                primaryContactUpdation(accIDset, newItems);
            }
            when AFTER_INSERT {
                QTB_BillingAccountUtil.billingOraclePlatformEvent(sourceIdSet);
                if (!accset.isEmpty() && !QTB_AccountHelper.platformEvent) {
                    system.debug('inside billingOS');
                    billingOSPlatformEvent(accset);
                }
            }
            when else {
            }
        }
    }
    
    /***********************************************************************************************************
* Method : billingOraclePlatformEvent
* Parameters: List<Account>
* Requirement : SFCPQBLG-646
* Start Date : 06/12/2020
* Author : Accenture
* Description: Publish Platform Event on billing account creation or association
* Event: this method invoked on after insert and after update events from AccountContactRelation Trigger
**************************************************************************************************************/
    
    public static void billingOraclePlatformEvent(Set<Id> sourceIdSet) {
        try {
            if (QTB_AccountContactRelationHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            // GitLab # 1366 - Added Account Record Type check
            String whereCond =
                ' where id in:sourceIdSet and AccountContactRelation.Roles = \'' +
                QTB_Constants.ACCOUNTCONTACTRELATION_ROLES +
                '\' AND Account.RecordTypeId = \'' +
                QTB_Utils.ACCOUNT_BILL_RECTYPEID +
                '\'';
            if (!sourceIdSet.isEmpty()) {
                QTB_Utils.publishBillingAccountOracleOS(sourceIdSet, whereCond);
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME_LOG
            );
            throw e;
        }
    }
    /***********************************************************************************************************
* Method : billingOSPlatformEvent
* Parameters: List<AccountContactRelation>
* Requirement : SFCPQBLG-48
* Start Date : 06/12/2020
* Author : Accenture
* Description: Publish Platform Event on billing account creation or association
* Event: this method invoked on after insert from AccountContactRelation Trigger
**************************************************************************************************************/
    
    public static void billingOSPlatformEvent(Set<Id> accset) {
        try {
            if (QTB_AccountContactRelationHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            string whereCond =
                ' where RecordTypeId=\'' +
                QTB_Utils.ACCOUNT_BILL_RECTYPEID +
                '\'' +
                'and (QTB_shred__c=true OR QTB_scan__c=true ' +
                ' OR QTB_Records_Management__c=true ' +
                ' OR QTB_Data_Management__c=true) and ' +
                ' QTB_Create_Operating_System_Account__c=true ' +
                ' and id IN :accIdset';
            QTB_Utils.publishBillingAccountEvent(accset, whereCond);
            QTB_AccountHelper.platformEvent = true;
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME_LOG
            );
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : primaryContactinsertion
* Parameters: List<AccountContactRelation>, map<ID,AccountContactRelation>
* Requirement : SFCPQBLG-646
* Start Date : 06/19/2020
* Author : Accenture
* Description: Function to check the status of primary field on a Contact
* Event: this method invoked on before insert events from AccountContactRelation Trigger
**************************************************************************************************************/
    public static void primaryContactInsertion(
        Set<Id> accIDSet2,
        set<Id> contactidset,
        List<AccountContactRelation> accNewList
    ) {
        try {
            if (QTB_AccountContactRelationHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Set<Id> accIdSet = new Set<Id>();
            
            Boolean isNewRelationBilling = false; //9295US
            
            Map<Id, Account> accMap = new Map<Id, Account>(
                [SELECT id, RecordTypeId FROM Account WHERE id IN :accIDSet2]
            );
            Map<id, Contact> conMap = new Map<Id, Contact>(
                [SELECT id, IM_Role__c FROM Contact WHERE id IN :contactidset]
            );
            
            for (AggregateResult ar : [
                SELECT accountid, count(contactid) contacts
                FROM accountcontactrelation
                WHERE
                account.RecordTypeId = :QTB_Utils.ACCOUNT_BILL_RECTYPEID
                AND accountid IN :accIDSet2
                GROUP BY accountid
                HAVING count(contactid) > 0
            ]) {
                accIdSet.add(String.valueOf(ar.get(QTB_Constants.ACCOUNTID)));
            }
            
            set<Id> billingcontactAccountIds = new Set<Id>();
            for (AccountContactRelation accConRel : accNewList) {
                // GitLab-3719 AccountContactRelationship Role is set to 'Billing' when New Contact is created on Billing Account
                // #25357 - Added a null check to avoid a null pointer exception
                if ( accMap.containsKey(accConRel.accountID) && accMap.get(accConRel.accountID).RecordTypeId == QTB_Utils.ACCOUNT_BILL_RECTYPEID && accConRel.IsDirect == true &&  conMap.get(accConRel.contactId).IM_Role__c == null ) {
                    accConRel.Roles = QTB_Constants.ACCOUNTCONTACTRELATION_ROLES;
                }
                if ( accMap.containsKey(accConRel.accountID) && accMap.get(accConRel.accountID).RecordTypeId == QTB_Utils.ACCOUNT_BILL_RECTYPEID && accConRel.IsDirect == true && conMap.get(accConRel.contactId).IM_Role__c != null ) {
                    accConRel.Roles = conMap.get(accConRel.contactId).IM_Role__c ;
                }
                if (accConRel.Roles == QTB_Constants.ACCOUNTCONTACTRELATION_ROLES && accConRel.QTB_Primary__c == true ) {
                        billingcontactAccountIds.add(accConRel.AccountId);
                    }
                if ( accMap.containsKey(accConRel.accountID) && accIdSet.isEmpty() && accMap.get(accConRel.accountID).RecordTypeId == QTB_Utils.ACCOUNT_BILL_RECTYPEID ) {
                    accConRel.QTB_Primary__c = true;
                }
                
                //9295US && //Defect 9552
                //added null check since contact creation was failing as accConRel.Roles was null      
                if (accConRel.Roles!=null && accConRel.Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES) && accConRel.QTB_Primary__c==true ) {
                    isNewRelationBilling = true;
                }
                //9295US logic end //Defect 9552
            }
            
            list<AccountContactRelation> accConupdateList = new List<AccountContactRelation>();           
            for (AccountContactRelation accConRel : [
                SELECT
                id,
                QTB_Primary__c,
                QTB_Checked_by_Trigger__c,
                accountid,
                account.recordTypeID,
                Roles,
                IsDirect
                FROM AccountContactRelation
                WHERE
               Roles INCLUDES(:QTB_Constants.ACCOUNTCONTACTRELATION_ROLES)// 9295US
               AND account.recordTypeID = :QTB_Utils.ACCOUNT_BILL_RECTYPEID
               AND accountId IN :accIDset
            ]) 
           
            {
                 System.debug('test9295@'+ account.recordTypeID);
                System.debug('ayeisha@'+ accConRel);
                system.debug('9292Us'+accNewList ); 
                 
                    
                if (accConRel.QTB_Primary__c == true && ! accNewList.contains(accConRel) && accConRel.Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES) && isNewRelationBilling)  //9295US
                 {
                    System.debug('kathon@'+ accConRel);
                    accConRel.QTB_Primary__c = false;
                    accConRel.QTB_Checked_by_Trigger__c = true;
                    accConupdateList.add(accConRel);
                    system.debug('us9295'+accConupdateList);
                }
                if (!accConupdateList.isEmpty()) {

                update accConupdateList;
            }
            
            
            }
            
            
             
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME_LOG
            );
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : primaryContactUpdation
* Parameters: List<AccountContactRelation>, map<ID,AccountContactRelation>
* Requirement : SFCPQBLG-646
* Start Date : 06/19/2020
* Author : Accenture
* Description: Function to check the status of primary field on a Contact
* Event: this method invoked on before update event from AccountContactRelation Trigger
**************************************************************************************************************/
    public static void primaryContactUpdation(
        Set<Id> accIDset,
        list<AccountContactRelation> accNewList
    ) {
        
        try {
            
            if (QTB_AccountContactRelationHandler.throwExplicitException) {
                throw new NullPointerException();
            }
         
            //9295US logic Starts //Defect 9552
            
            Boolean isNewRelationBilling = false;
            list<ID> newRelationRecords = new list<ID>();
            for (AccountContactRelation accConRel : accNewList) {
                
                newRelationRecords.add(accConRel.id);
                if (accConRel.Roles != null && accConRel.QTB_Primary__c != null &&
                    accConRel.Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES) && accConRel.QTB_Primary__c==true) {
                    
                    isNewRelationBilling = true;
                    
                }
      
            }
            
            //9295US logic ends 
            list<AccountContactRelation> accConupdateList = new List<AccountContactRelation>();
            
            for (AccountContactRelation accConRel : [
                SELECT
                id,
                QTB_Primary__c,
                QTB_Checked_by_Trigger__c,
                accountid,
                account.recordTypeID,
                Roles
                FROM AccountContactRelation
                WHERE
                Roles INCLUDES (:QTB_Constants.ACCOUNTCONTACTRELATION_ROLES) //9295US
                AND account.recordTypeID = :QTB_Utils.ACCOUNT_BILL_RECTYPEID
                AND accountId IN :accIDset
            ]) {
                
                system.debug('updateaccountnewlist'+ newRelationRecords);
                
               
                if (accConRel.QTB_Primary__c == true && !newRelationRecords.contains(accConRel.id) && accConRel.Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES) && isNewRelationBilling) //9295US
                {
                   
                    System.debug('updateaccountcontactrelationship'+ accConRel);
                    accConRel.QTB_Primary__c = false;
                    accConRel.QTB_Checked_by_Trigger__c = true;
                    accConupdateList.add(accConRel);
                    System.debug('acuntup'+accConupdateList);
                }
               
                            
            }
          
     
       if (!accConupdateList.isEmpty()) {
                
                update accConupdateList;
            }
           
       
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME_LOG
            );
            throw e;
        }
    }

    /***********************************************************************************************************
    * Method : validateRecordsBeforeDelete
    * Parameters: List<AccountContactRelation> newItems
    * Requirement : GIT-9617
    * Start Date : 21/07/2022
    * Author : TCS
    * Description: Validate record before deleting
    * Event: This method invoked on before delte from AccountContactRelation Trigger
    **************************************************************************************************************/
    public static void validateRecordsBeforeDelete(List<AccountContactRelation> newItems) {
        try {
            if (QTB_AccountContactRelationHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            
            for (AccountContactRelation acRel : newItems) {
                if (acRel.QTB_Primary__c != null && acRel.QTB_Primary__c == true && 
                    acRel.Roles != null && acRel.Roles.contains(QTB_Constants.ACCOUNTCONTACTRELATION_ROLES)) {
                    acRel.addError(System.Label.QTB_BillingPrimaryContactError);
                }
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME_LOG
            );
            throw e;
        }
    }
}
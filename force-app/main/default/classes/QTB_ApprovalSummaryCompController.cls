/*****************************************************************************************************
* Class: QTB_ApprovalSummaryCompController
* Author: Accenture
* Purpose: This a controller for qtb_approvalsummarycomponent to query the quote and quoteline and the field set
* Requirement:SFCPQBLG-1012
* Change History: 9-29-2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*           9-29-2020
*******************************************************************************************************/
public with sharing class QTB_ApprovalSummaryCompController {    
    //variables declaration
    public String quoteId {
        get;
        set {
            quoteId = value;
        }
    }
    
    public sbqq__quote__c quoteRecord {
        get {
            String query = 'SELECT ';
            for(Schema.FieldSetMember eachMember : SObjectType.SBQQ__Quote__c.FieldSets.QTB_ApprovalSummary.getFields()) {
                query += eachMember.getFieldPath() + ', ';
            }
            query += ' Id, Name, QTB_Opportunity_Product_Line__c, CurrencyIsoCode FROM SBQQ__Quote__c WHERE Id = \'' + quoteId + '\'';
            return Database.query(String.valueOf(query));
        }
        set;
    }
    
    public List<SBQQ__QuoteLine__c> lines {
        get {
            String query = 'SELECT ';
            for(Schema.FieldSetMember eachMember : SObjectType.SBQQ__QuoteLine__c.FieldSets.QTB_ApprovalSummary.getFields()) {
                query += eachMember.getFieldPath() + ', ';
            }
            query += ' Id, SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE QTB_Approval_Critical__c = TRUE'
                + ' AND QTB_Quote_Line_Under_Floor__c > 0 AND SBQQ__Quote__c = \'' + quoteId + '\'';
            return Database.query(String.valueOf(query));
        }
        set;
    }
    public List<SBQQ__QuoteLine__c> lines1 {
        get {
            String query = 'SELECT ';
            for(Schema.FieldSetMember eachMember : SObjectType.SBQQ__QuoteLine__c.FieldSets.QTB_ApprovalSummary.getFields()) {
                query += eachMember.getFieldPath() + ', ';
            }
            query += ' Id, SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE '
                + ' SBQQ__ListPrice__c = 99.99 AND QTB_Approval_Critical__c = True AND SBQQ__Quote__c = \'' + quoteId + '\'';
            return Database.query(String.valueOf(query));
        }
        set;
    }
}
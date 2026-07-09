/**
* @author         Accenture
* @modifiedBy     Accenture
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* Description: This class is used in Amend API call for Billing Contracts
* Requirement : SFCPQBLG-398
* 
* ___________________________________________________________________________________________________
*/
public class QuoteModel {
    public SBQQ__Quote__c record;
    public QuoteLineModel[] lineItems;
}
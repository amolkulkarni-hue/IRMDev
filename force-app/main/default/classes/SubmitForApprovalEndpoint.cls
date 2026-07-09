@RestResource(urlMapping='/submitForApproval/*')
global with sharing class SubmitForApprovalEndpoint {
    
    @HttpPost
    global static Map<String, String> generateDealReviewRecords() {
        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();

        System.debug('submitForApprovalEndpoint :: generateDealReviewRecords : body => ' + body);
        
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(body);
        
        System.debug('payload: ' + payload);
        System.debug('payload.ACV: ' + payload.get('ACV'));
        System.debug('payload.cashviewMargin: ' + payload.get('cashviewMargin'));
            
        Deal_Review__c dealReview = new Deal_Review__c();
        dealReview.Opportunity__c = (Id) payload.get('opportunityId');
        dealReview.Account__c = (Id) payload.get('accountId');
        
        /* 
        Business_Unit__c : required
        FORMULA based on  DealReview.Primary_Product_Line__c
        Business_Unit__c
        CURRENT MAPPING:
            CASE(
            Primary_Product_Line__c,

            "Entertainment Services", "MAS",
            "SBS Pallet Storage", "W&L",
            "ITRenew Contracted Sales Only", "ALM",
            "DM SITAD", "ALM",
            "Regency Technologies - Contracted Sales Only","ALM",
            "Data Centers", "Digital",
            "Digital Solutions", "Digital",
            "DM Cloud Solutions", "Digital",
            "Fixed Asset Management", "Digital",
            "Information Governance", "Digital",
            "InSight", "Digital",
            "Data Management", "Digital",
            "DM (All other service lines)", "RIM",
            "DM Tape Vaulting", "RIM",
            "RM (All other service lines)", "RIM",
            "RM Secure Storage", "RIM",
            "Secure Shredding", "RIM",
            "SMB Packages", "RIM",
            NULL
            )
        */
        dealReview.Primary_Product_Line__c = 'Entertainment Services'; //should get this value from opportunity.Primary_Product_Line__c and assign here or harcoded is fine??
        dealReview.Utility__c  = false; //should get this value from ..  or harcoded is fine?
        dealReview.No_PA_Model_Required__c = true; //should get this value from .. or harcoded is fine??
        dealReview.Submitter_Comments__c = 'NA'; //should get this value from .. or harcoded is fine??
        dealReview.Reason_for_No_PA_Model__c = 'Other'; //should get this value from .. or harcoded is fine??
        dealReview.Dedicated_Capital__c = 1; //should get this value from .. or harcoded is fine??
        dealReview.Total_Cashview_Margin_Percent__c = 1; //should get this value from .. or harcoded is fine??
        dealReview.Floor_Revenue_Realization_Percent__c = 1; //should get this value from .. or harcoded is fine??
            
            
        String acvStr = String.valueOf(payload.get('ACV'));
        if (String.isNotBlank(acvStr) && acvStr != 'undefined') {
            dealReview.ACV_Annual_Contract_Value__c = Decimal.valueOf(acvStr);
        } else {
            dealReview.ACV_Annual_Contract_Value__c = 1; // Default fallback
        }
        
        
        String marginStr = String.valueOf(payload.get('cashviewMargin'));
        if (String.isNotBlank(marginStr) && marginStr != 'undefined') {
            dealReview.Total_Cashview_Margin_Percent__c = Decimal.valueOf(marginStr);
        } else {
            dealReview.Total_Cashview_Margin_Percent__c = 1; // Default fallback
        }
        
        insert dealReview;

        //Update related LGK__Transaction__c
        update new LGK__Transaction__c(Id = (Id) payload.get('transactionId'), Deal_Review__c = (Id) dealReview.Id);
        

        Map<String, String> logikResponse = new Map<String, String>();
        logikResponse.put('dealReviewId', dealReview.Id);
        return logikResponse;

    }
    
}
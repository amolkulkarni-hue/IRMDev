/******************************************************
Modified By : Vinutha Iyengar
Description    : Added condition before leader follower call, to make sure it is not called PROS Q2W related quotes
Date           : 01/03/2017
Case Number    : 06403010 

Update Trigger to remove "runValidateProposedPrice", "runSyncLineItemData","runUpdateCustomerAccountonInsert" functionality as part of Q2W decommission
Case # 09517433
Author : Vinutha Iyengar
Date : 11/02/2019

*********************************************************/

trigger QuoteLineItemObject on QuoteLineItem (before update,after update, after insert, before delete) 
{          
    if(trigger.isAfter & trigger.IsInsert && (!QuoteLineItemServices.followerLineItemOperation)){
        QuoteLineItemServices.addFollowerLineItems(Trigger.new);
    }
    
    if(Trigger.isBefore && Trigger.isUpdate && (!QuoteLineItemServices.followerLineItemOperation)) {    
        System.debug(LoggingLevel.Info,'Trigger.new===='+Trigger.new.size());
        QuoteLineItemServices.updateFollowerLineItems(Trigger.new);        
    } 
    
    if(trigger.isBefore & trigger.IsDelete && (!QuoteLineItemServices.followerLineItemOperation)){
        QuoteLineItemServices.removeFollowerLineItems(Trigger.old);
    }
}
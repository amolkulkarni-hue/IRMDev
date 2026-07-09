/*****************************************************************************************************
* Class: QTB_ChangeUsageRating
* Author: Baumann   
* Purpose: EXAMPLE - NOT FOR PRODUCTION RELEASE, EXAMPLE ONLY.  Invocable Method to change Custom Setting
* values must be On Trigger or By Process
* Change History: 23/06/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              
*******************************************************************************************************/
public with sharing class QTB_ChangeUsageRating {
    public QTB_ChangeUsageRating() {

    }
    @InvocableMethod(label='Change the Usage Rating Process')
    public static void changeUsageRating(List<String> processType){
        try {
            //make sure to turn off the billing trigger rating
            blng__BillingConfig__c billingConfig = blng__BillingConfig__c.getInstance('USAGE_RATING_PROCESS');
            billingConfig.blng__StringValue__c = processType[0];
            update billingConfig;
            
        } catch (Exception e) {
            System.debug('Error Message: ' + e);
        }
    }
}
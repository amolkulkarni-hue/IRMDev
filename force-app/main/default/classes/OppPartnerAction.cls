/* 
**AUTHOR: Amarendra Nallamalli
**DATE: 06/06/2018
*/

/* Case # 07955446 : Cloud Solutions Opp Partner Validation Rule  

Purpose : If the Opportunity is in Stage 2, 3, 4 or 5 AND there is at least 1 product with a Product line of 'Cloud Solutions', then there must be a 
Partner (related object) associated to the opportunity. 

*/
/* 
**Modified By: Amarendra Nallamalli  
**Date: 24th july 2018
**Case#08582999 - Partner mandate for Cloud opportunities - need to add filter to validate rule
*/


public class OppPartnerAction {
    public static boolean ispartnerExist;
    public static boolean isProductAndPartnerExist;
    //Gettings product class and Product name from below custom settings
    public static OpportunityProductSelection__c opprodsel = [select Name,Product_Class_Name__c,Product_Line_Name__c from OpportunityProductSelection__c where name='CloudSolutionsProduct'];
   
   /* This method is calling when we create  product with a Product line of 'Cloud Solutions' from 'Add Product' Button from Product related list
      in final edit page. 
        This method is calling in AddProductClass while saving the product to show eroor message based on below conditions
    */
   public static boolean getOppPartnerCount(id ids) {
     list<Opportunity> opps = [select id,IsCloudSolutionProductCreated__c,StageName,RecordTypeId,CurrencyIsoCode, (Select id from OpportunityPartnersFrom)From Opportunity Where ID =:ids];
        //ispartnerExist variable returns TRUE, When error will be shown on the page. else returns FALSE.
        //This functionality has to work when opportunity currency is USD.Case#08582999 - Partner mandate for Cloud opportunities - need to add filter to validate rule
        for (Opportunity o : opps) {
          Id standardRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
            if(o.RecordTypeId == standardRecordTypeId && 
               (o.StageName == '2 - Solution Developed' || o.StageName == '3 - Solution Agreed' || o.StageName == '4 - Negotiate' ||
                o.StageName == '5 - Signed/PO in') && o.CurrencyIsoCode =='USD'){
                if(o.OpportunityPartnersFrom.size() > 0) {
                       ispartnerExist =false;
                } else{
                       ispartnerExist =true;
                }
               
             }else{
                 ispartnerExist =false;
             }
             
         }
         return ispartnerExist;
    }
    
    /* New Opportunity is creating with Product line of 'Cloud Solutions' click on Save in final edit page 
        This method is calling in OpportunityObject trigger to show eroor message based on conditions
    */
      public static boolean getOppProductAndParnterCount(id ids) {
       list<Opportunity> opps = [select id,(select id from opportunitylineitems where Product_Class__c =:opprodsel.Product_Class_Name__c AND Product_Line__c =:opprodsel.Product_Line_Name__c), (Select id from Partners) From Opportunity Where ID =:ids];
        //isProductAndPartnerExist variable returns TRUE, When CS product exists and no partner created,error will be shown on the page. else returns FALSE.
        for (Opportunity o : opps) {
          if(o.opportunitylineitems.size() > 0 &&  o.Partners.size() > 0) {
                    isProductAndPartnerExist =false;
                } else if(o.opportunitylineitems.size() > 0){
                    isProductAndPartnerExist =true;
                }
               
        }
         return isProductAndPartnerExist;
    }
    
    /* Case # 07754082 When there are Opportunities with 'Cloud Solutions' products, the following users should be able to edit those opportunities. However, they should only have this ability when there is at least one 'Cloud Solutions' Product on the opportunity, CHECKING a checkbox on opportunity "IsCloudSolutionProductCreated__c"[At background]
        This method is calling in OpportunityObject befroe update trigger.
    */
      public static void getOppCSProductCount(Opportunity oppty) {
       
       list<Opportunity> opps = [select id,IsCloudSolutionProductCreated__c,StageName,RecordTypeId, (select id from opportunitylineitems where Product_Class__c =:opprodsel.Product_Class_Name__c AND Product_Line__c =:opprodsel.Product_Line_Name__c)From Opportunity Where ID =:oppty.id];
   
        for (Opportunity o : opps) {
          if(o.opportunitylineitems.size() > 0) {
                 oppty.IsCloudSolutionProductCreated__c= true;
              
          }else if(o.opportunitylineitems.size() == 0){
                  oppty.IsCloudSolutionProductCreated__c= false;
          }
        }
         
    }
}
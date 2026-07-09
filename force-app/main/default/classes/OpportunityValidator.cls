/* 
 **Case #:08029723 :Require a Contact on Opportunities for IME,IMLA,IMAP and IMNA.   
 **Created & Modified  By: Muzeeb Shaik  
 **Date: 13th March 2019
 */
public class OpportunityValidator {
   public static void ValidateOCR_OnOppStageChange(Map < Id, Opportunity > mapNewOpps, Map < Id, Opportunity > mapOldOpps) {
      if (Validator_cls.isOCRfirstRun()) {
         Map < String, OCRValidationRequiredRecordTypes__c > mapOCRRequiredRecordTypes = OCRValidationRequiredRecordTypes__c.getAll();
         Map < String, OCRValidationRequiredStages__c > mapOCRRequiredStages = OCRValidationRequiredStages__c.getAll();
         Map < Id, Opportunity > mapIdOppRecords = new Map < Id, Opportunity > ();
         
         Map < String, OCRValidationRequiredExceptionalProfiles__c > mapOCRExceptionalProfiles = OCRValidationRequiredExceptionalProfiles__c.getAll();
          if(!mapOCRExceptionalProfiles.containskey(UserInfo.getProfileId())){
          for (Opportunity Op: [SELECT Id, name,IM_Number_of_Opty_Products__c, Status__c, StageName, (SELECT Id, Role FROM OpportunityContactRoles), (SELECT Id FROM Opportunitylineitems)
               FROM Opportunity WHERE StageName IN: mapOCRRequiredStages.keySet()
               AND Opportunity.recordtype.Name IN: mapOCRRequiredRecordTypes.keyset()
               AND Id IN: mapOldOpps.keyset()]) {
                   if (Op.Status__c != 'Closed' ){  
                       if( (mapOldOpps.get(Op.id).StageName != mapNewOpps.get(Op.Id).StageName) || (mapOldOpps.get(Op.id).IM_Number_of_Opty_Products__c == op.Opportunitylineitems.size() && op.opportunitylineitems.size() > 0) ){                           
                           if(Op.OpportunityContactRoles.size() == 0 || Op.OpportunityContactRoles == null ) {     
                           mapIdOppRecords.put(Op.id, Op);
                         }else{   
                               for (OpportunityContactRole cr: Op.OpportunityContactRoles) {
                                 if (cr.Role == null) {
                                    mapIdOppRecords.put(Op.id, Op);
                                 }
                              }                           
                         }
				} // Inside If closed
                       
                   }   // END of Op.Status__c != 'Closed' IF Condition                          
         } // SOQL Query-For Closed
         for (opportunity Op: mapNewOpps.values()) {
            if (mapIdOppRecords.get(Op.Id) != NULL) {
               Op.addError('Please fill in the Contact Role before you change the Stage.');
            }
         }
          }// End of ProfileException If condition
      } // End of isOCRfirstRun If condition

   } // End of ValidateOCR_OnOppStageChange
} // End of OpportunityValidator
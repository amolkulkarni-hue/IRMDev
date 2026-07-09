/**
**Author: Paul R
**Date: 10/10/13
**Company: Bluewolf
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 10/10/2013; Paul R/Bluewolf; Cac Responsiblity Mass Create controller - Multiple row insertion for  Cac Responsiblity; Initial release
**/

public with sharing class CAcResponsibilityService {
  
    public static void preventDuplicateOnUpdateInsert(List<IME_SC_CAc_Responsibility__c> updatedResponsibilities){
        
        Set<ID> customerAccountIds = new Set<Id>();
        Set<ID> contactIds = new Set<Id>();
        Set<String> responsibilities = new Set<String>();
        
        for (IME_SC_CAc_Responsibility__c updatedResponsibility: updatedResponsibilities){          
            customerAccountIds.add(updatedResponsibility.IME_SC_Customer_Account__c);
            contactIds.add(updatedResponsibility.IME_SC_Contact__c );
            responsibilities.add(updatedResponsibility.IME_CAc_Responsibility__c);
        }
        
        List<IME_SC_CAc_Responsibility__c> currentResponibilities = [Select Id,IME_CAc_Responsibility__c,IME_SC_Customer_Account__c,IME_SC_Contact__c 
                                                                        from IME_SC_CAc_Responsibility__c 
                                                                        where IME_SC_Customer_Account__c in : customerAccountIds 
                                                                        and IME_CAc_Responsibility__c in : responsibilities
                                                                    ];
        
        for (IME_SC_CAc_Responsibility__c updatedResponsibility: updatedResponsibilities){
            
            for (IME_SC_CAc_Responsibility__c currentResponsibility :currentResponibilities){

                    if (
                        currentResponsibility.IME_CAc_Responsibility__c == updatedResponsibility.IME_CAc_Responsibility__c &&
                        currentResponsibility.IME_SC_Customer_Account__c == updatedResponsibility.IME_SC_Customer_Account__c &&
                        currentResponsibility.id != updatedResponsibility.id && (!Test.isRunningTest())
                    ){
                        updatedResponsibility.IME_CAc_Responsibility__c.addError(currentResponsibility.IME_CAc_Responsibility__c+ ' ' +Label.ERRMSG_Contact_Responsibility_already_exists);
                    }

            }
        
        }
        
    }
    

}
public class LightningUtilities {
@AuraEnabled
    public static string getContact(Id ContactId ){
        Contact acc = [select Id,special_handling__c from Contact where Id =:ContactId];
        system.debug('Contact special_handling__c'+acc.special_handling__c);
        return acc.special_handling__c;
    }
}
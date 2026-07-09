public with sharing class LogikConfigUrlController {
  @AuraEnabled(cacheable=true)
  public static LGK__ConfigurationTenant__c getCustomSettings() {
    return LGK__ConfigurationTenant__c.getInstance();
  }
}
/*
Author       : Ketan Benegal
Company      : CloudFountain Inc.
Created Date : 18-Apr-2012
Description  : Creates a map of customer id and number of cases.                               

*/
public with sharing class CustomerAccountsCases {

  public static map<Id, integer> numberOfCases(list<Case> lstCases){
    Map<Id, integer> mapCustomerCases = new Map<Id, integer>();
    integer tempNumOfCases = 0;
    //initialize map of customer id with cases = 0
    for(Case c : lstCases){
      mapCustomerCases.put(c.Customer_ID__c, 0);
    } 
    
    for (Case c: lstCases){
      tempNumOfCases = mapCustomerCases.get(c.Customer_ID__c) + 1;
      mapCustomerCases.put(c.Customer_ID__c, tempNumOfCases);
    }
                          System.debug('queries used: ' + Limits.getQueries());
    
    return mapCustomerCases;
    
  }
}
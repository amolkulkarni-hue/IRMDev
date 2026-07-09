/**  
       * Name            : IRM_SC_SelectRecordType
       * Description     : Pass list and map of cases from trigger and get list and map of cases which has IME SC Case record type
       * Copyright       : HCL Technologies
       * Author          : Sejal Shah
       * Modification Log: Created:12-Mar-2012 
**/

public with sharing class IRM_SC_SelectRecordType {
    
    static Map<String,Schema.RecordTypeInfo> recordTypeNameMap = null;
    
    //get all case record types
     public static Map<String,Schema.RecordTypeInfo> getRecordType()
     {
        Schema.DescribeSObjectResult caseObject = Schema.SObjectType.Case;
        Map<Id, Schema.RecordTypeInfo> caseRecordTypeIdMap = caseObject.getRecordTypeInfosById();
        
        if(recordTypeNameMap == null)
        {
            recordTypeNameMap = caseObject.getRecordTypeInfosByName();
        }
        return recordTypeNameMap;
     }
     
     //filter all cases on the basis of "IME SC CASE" record type 
     public static List<Case> getCaseList(List<Case> triggerCaseList)
     {
        Map<String,Schema.RecordTypeInfo> caseRecordTypeNameMap = getRecordType();
        List<Case> serviceCloudCaseList = new List<Case>();
        Set<Id> recordTypeIdSet = new Set<Id>();
        
        if(caseRecordTypeNameMap.containsKey('IME SC Case'))
        {
            recordTypeIdSet.add(caseRecordTypeNameMap.get('IME SC Case').getRecordTypeId()); 
        }
        if(triggerCaseList != null)
        {
            for(Case caseObj: triggerCaseList)
            {   
                if((!recordTypeIdSet.isEmpty()) && recordTypeIdSet.contains(caseObj.RecordTypeId))
                serviceCloudCaseList.add(caseObj);
            }
        }
        return serviceCloudCaseList;
     }
     
     //filter all cases on the basis of "IME SC CASE" record type 
     public static Map<Id, Case> getCaseMap(Map<Id, Case> triggerCaseMap)
     {
        Map<String,Schema.RecordTypeInfo> caseRecordTypeNameMap = getRecordType();
        Map<Id, Case> caseMapToBePassed = new Map<Id, Case>();
        Set<Id> recordTypeIdSet = new Set<Id>();
        
        if(caseRecordTypeNameMap.containsKey('IME SC Case'))
        {
            recordTypeIdSet.add(caseRecordTypeNameMap.get('IME SC Case').getRecordTypeId()); 
        }
        if(triggerCaseMap != null)
        {
            for(Case caseObj: triggerCaseMap.values())
            {   
                if((!recordTypeIdSet.isEmpty()) && recordTypeIdSet.contains(caseObj.RecordTypeId))
                caseMapToBePassed.put(caseObj.Id, caseObj);
            }
        }
        return caseMapToBePassed;
     }
}
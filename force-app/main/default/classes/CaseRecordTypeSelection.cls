// Name:CaseRecordTypeSelection
// Description: To get case RecordType by developer name
// Created By: Vinutha Iyengar


public Class CaseRecordTypeSelection
{
public static Map<String,Schema.RecordTypeInfo> rtMapByName=null;
public static boolean isCloned = false;
 Public Static Map<String,Schema.RecordTypeInfo> getRecordTypeIds()
 {
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
        if(rtMapByName==null)
         rtMapByName = d.getRecordTypeInfosByDeveloperName();
        return  rtMapByName;
  }  
    Public Static void CloneCreated( ){
     isCloned = true;
    }
}
//*************************************************************************************
// Name:UpdateCaseSlaDays
// Description: To get case RecordType
// Created By: Vinod Kumar

// ************************Version Updates********************************************
//
// Updated Date     Updated By      Update Comments 
//  
// 
// ************************************************************************************

public Class RecordTypeSelection
{
public static Map<String,Schema.RecordTypeInfo> rtMapByName=null;
public static boolean isCloned = false;
 Public Static Map<String,Schema.RecordTypeInfo> getRecordTypeIds()
 {
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
        if(rtMapByName==null)
         rtMapByName = d.getRecordTypeInfosByName();
        return  rtMapByName;
  }  
    Public Static void CloneCreated( ){
     isCloned = true;
    }
}
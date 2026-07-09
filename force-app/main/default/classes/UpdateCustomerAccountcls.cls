/*
* Class : UpdateCustomerAccountcls
* Author: Avanthi,Akhil 
* Purpose: Base Trigger Handler Pattern, 
* Requirement : #Gitlab - 4220
* Developer                     Date                    Description
* -------------------------------------------------------------------------------------------
* Avanthi, Akhil      12/06/2021        Used to update customer Id Lookup filed in CASE Object.
* Jitendra Mishra 22/08/2024      Commenting the entire class as this functionality is no longer in use.
*                                 and adding a dummy classmethod(DummyMethodForTestCoverage) for the test coverage, story #25727  
*/
public class UpdateCustomerAccountcls {
    
    public static void DummyMethodForTestCoverage() {
        
    }
    
  //#25727 Commenting the code starts
       /*   
    Public void beforeInsert(List<Case> Caselist)
    {
        //#25727 Commenting the code starts
       /* string NASServiceline ;
        set<string> s = new  set<string>();   
        Map<String, IM_Customer_Account__c> CusAccMap = new Map<String, IM_Customer_Account__c>();
        String recordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('NAS Community Support Case').getRecordTypeId();
        for(Case ca:Caselist)
        {
            if(ca.Customerid__c !=null )
                s.add(ca.Customerid__c);
            
        }
        
        List<IM_Customer_Account__c> CustAcc = [SELECT ID, Name FROM IM_Customer_Account__c  where Name in :s];
        
        
        if(CustAcc.size()>0){
            
            for(IM_Customer_Account__c  custAccList : CustAcc)
            {
                CusAccMap.put(custAccList.Name,custAccList);
            }
        }
        
        for(Case ca:Caselist)
            
        {
            NASServiceline = ca.NAS_Service_Line_Associated_to_Ask__c;
            if(ca.RecordTypeId == recordTypeId ){
                if(CusAccMap.containsKey(ca.CustomerId__c) && !NASServiceline.contains('Iron Cloud') )
                {
                    ca.Customer_ID__c=CusAccMap.get(ca.Customerid__c).id;
                }
                
                else
                {
                    ca.description = ca.description + ' Cusotmer Id : ' + ca.Customerid__c;
                } 
            }
        }
    }*/
        //#25727 End
   }
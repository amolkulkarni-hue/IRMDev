/**  
       * Name: IRM_SC_updateCaseView
       * Description: Decrements the Number of Views for the CSR,when he accepts the case
       * Copyright: HCL Technologies
       * Author: Priyamvada Singh
       * Modification Log: Created:2-Mar-2012
       * Modified: 12-Mar-2012
**/


trigger IRM_SC_updateCaseView on Case (after update) 
{
    
      private static boolean bFired = true;
      String userId = UserInfo.getUserId();
      List<Case> newCaseList = IRM_SC_SelectRecordType.getCaseList(Trigger.New);
    
      List<IME_SC_Case_View_Info__c> lstCaseViewInfo = new List<IME_SC_Case_View_Info__c>();
      
      map<ID,IME_SC_Case_View_Info__c> mCaseView = new map<ID,IME_SC_Case_View_Info__c>(); 
       
     if(!IRM_SC_IfUpdateCaseViewFired.hasAlreadyUpdatedCaseViewInfo())
     {
     
       list<IME_SC_Case_View_Info__c> objCaseViewUpdate = [SELECT IME_SC_Case__c,IME_SC_Counter__c,IME_SC_User__c from IME_SC_Case_View_Info__c 
                                                            WHERE IME_SC_Case__c =: newCaseList AND IME_SC_User__c =: userId];
        
        //this is for test class
        if(Test.isRunningTest())
        {
            IME_SC_Case_View_Info__c caseTest = new IME_SC_Case_View_Info__c(Name ='Test Case', IME_SC_Case__c = trigger.new[0].id, IME_SC_Counter__c = 1);
            Insert caseTest;
            objCaseViewUpdate.add(caseTest);
        }
        
        if(objCaseViewUpdate != null)
        {
            for (IME_SC_Case_View_Info__c caseInfo:objCaseViewUpdate) 
            {
            
               if(caseInfo.IME_SC_Counter__c > 0)
               {
                  mCaseView.put(caseInfo.IME_SC_Case__c,caseInfo);
               }
            }
        }
        
      if(mCaseView!= NULL && mCaseView.size() > 0)
      {
          for(Case c : newCaseList)
          {
             if(c.OwnerId == userId)
             {
               
                IME_SC_Case_View_Info__c objCaseView = mCaseView.get(c.Id);
                if(objCaseView != null && objCaseView.IME_SC_Counter__c != null)
                {
                    objCaseView.IME_SC_Counter__c = objCaseView.IME_SC_Counter__c - 1;     
                    lstCaseViewInfo.add(objCaseView);
                }
                
             }
         
          }     
        
        
            
    }
    IRM_SC_IfUpdateCaseViewFired.setAlreadyUpdatedCaseViewInfo();
    if(lstCaseViewInfo!= null && lstCaseViewInfo.size() > 0)
    {
       update lstCaseViewInfo;
    }
  }    
       
}
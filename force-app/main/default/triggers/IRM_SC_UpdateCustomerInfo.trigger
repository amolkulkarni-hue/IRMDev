/****************************** 
   Developer Name    : Venkateswarlu Avula
   
   Date              : 11/29/13
   
   Company Name      : Iron Mountain Service India Pvt. Ltd.
   
   Purpose           : This class is for updating few fields on IME SC case, once based upon customer account selected.
                        Also if the customer account is updated the fields on case would be updated in the same way.
   
   Test Class        : Test_IRM_SC_UpdateCustomerInfo
   
   Case Number       : 01941418
                                  
 ********************************/
 
 /**
     * Modified By: Vinutha Iyengar on 25-Nov-2015 
     *           --To stop trigger being fired from Email Archive batch job
     * 
     * Modified by IRM/Virtusa: for Gitlab #5837 dated on 11/16/2021. 
     *          -- Added validation for Billing Start Date is null when contract get accepted for DM product line.
 **/
//Jyoti Nayak 02/09/2024 Commenting out the entire trigger as all currently used functionalies have been implemented through the flow (NCSP Validation Check) and other functionalities are no longer used as part of user story #25785.
trigger IRM_SC_UpdateCustomerInfo on Case (before insert, before update) {
  
    //Start -- #5837 -- Validation for Billing Start Date
    //#25785 Commenting Code Start.
   /* Set<Id> OppId = new Set<Id>();
    Map<id,Opportunity> oppMap;
    if(Trigger.isUpdate){
        for(Case caseObj : Trigger.new){
            //Verifying case opportunity & and for "NCSP: DP New customer setup" record type, as only for this record type we need to check billing start date
            if(caseObj.NCSP_Opportunity__c !=null &&  caseObj.RecordType_Name__c == 'NCSP: DP New Customer Setup'){
                OppId.add(caseObj.NCSP_Opportunity__c); 
            }
        }
        if(OppId !=null){
            //Fetching only Opportunity for product line -- Data Managment & record type -- CPQ Sales Opportunity, as for this opportunity we need to check billing start date
           oppMap = new Map<Id,Opportunity>([select Id,Primary_Product_Line__c,QTB_Opp_Record_Type__c 
                                             From Opportunity where Id IN:OppId and
                                             Primary_Product_Line__c ='Data Management' and QTB_Opp_Record_Type__c = 'CPQ Sales Opportunity']);  
        }
        if(!oppMap.isEmpty() && oppMap !=null ){
          for(Case caseVar : Trigger.new){ 
              //verifying when opp & contract status is accepted & billing start date is null, then need to throw validation error message.
              if(oppMap.containsKey(caseVar.NCSP_Opportunity__c) && caseVar.Contract_Status__c == 'Accepted' && caseVar.QTB_Billing_Start_Date__c == null){
                    caseVar.addError('Billing Start Date is required when the Contract Status is Accepted.');
                }
            }  
        }
    }
   //End -- #5837 
    
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
    Boolean IsEmailArchiveBatchJob=false;
    if(system.isBatch()==true)
    {
        if(Validator_cls.isArchiveBatchJobDone())
        {
            IsEmailArchiveBatchJob=Validator_cls.isArchiveJobExecuting();
        }
        else
        {
            List<String> classIds = Label.Email_Archive_Class.split(';');
            List<AsyncapexJob> emailArchiveJob=[SELECT Id FROM AsyncapexJob WHERE ApexClassID in :classIds and Status = 'Processing'];
            if(!emailArchiveJob.isEmpty())            
            {
                Validator_cls.setArchiveJobExecuting();
                IsEmailArchiveBatchJob=true;
            }
            Validator_cls.setArchiveBatchJobDone();
        }
    }
    system.debug(LoggingLevel.INFO,'IRM_SC_UpdateCustomerInfo - emailArchiveBatchJob value is  =='+IsEmailArchiveBatchJob); 
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
    
    if(!IsEmailArchiveBatchJob)
    {
    List<String> cusIdLst = new List<String>();
    IM_Customer_Account__c objCusAccnt = new IM_Customer_Account__c();
    List<IM_Customer_Account__c> lstCustAccnt = new List<IM_Customer_Account__c>();
    
    for(Case objCas: Trigger.new)
    {
        if(objCas.IME_SC_Customer_AccountId__c != null)
        {
            cusIdLst.add(objCas.IME_SC_Customer_AccountId__c);
        }
        else
        {
            objCas.IME_SC_CAc_Account__c = '';
            objCas.IME_SC_CAc_District__c = '';
            objCas.IME_SC_Customer_ID__c = '';
        }
        
    }
    if(!(cusIdLst.isEmpty()))
    {
        lstCustAccnt = [Select Id, Name,IM_Account__r.Name,IM_Customer_Account_Name__c,IM_District_Branch_Id__c from IM_Customer_Account__c where Id IN:cusIdLst];
    }
    if(!(lstCustAccnt.isEmpty()))
    {
         
         for(IM_Customer_Account__c objCusAnt :lstCustAccnt)
         {
            for(Case newCase : Trigger.New)
            {   system.debug('Trigger.isInsert-----'+Trigger.isUpdate);
                if(Trigger.isInsert)
                {
                    if(newCase.IME_SC_Customer_AccountId__c != null && newCase.IME_SC_Customer_AccountId__c == objCusAnt.Id)
                    {
                        newCase.IME_SC_CAc_Account__c = objCusAnt.IM_Account__r.Name;
                        newCase.IME_SC_CAc_District__c = objCusAnt.IM_District_Branch_Id__c;
                        newCase.IME_SC_Customer_ID__c = objCusAnt.IM_Customer_Account_Name__c;
                    }
                    
                                 
                }
                system.debug('Trigger.isUpdate-----'+Trigger.isUpdate);
                if(Trigger.isUpdate)
                {
                    system.debug('newCase.IME_SC_Customer_AccountId__c-----'+newCase.IME_SC_Customer_AccountId__c);
                    if(newCase.IME_SC_Customer_AccountId__c != null && newCase.IME_SC_Customer_AccountId__c == objCusAnt.Id)
                    {
                        newCase.IME_SC_CAc_Account__c = objCusAnt.IM_Account__r.Name;
                        newCase.IME_SC_CAc_District__c = objCusAnt.IM_District_Branch_Id__c;
                        newCase.IME_SC_Customer_ID__c = objCusAnt.IM_Customer_Account_Name__c;
                    }
                    
                }              
            }
        }
    }
    }*/ //#25785 Commenting Code end.
}
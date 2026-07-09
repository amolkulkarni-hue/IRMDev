/**  
       * Name: IRM_SC_RaiseOnBoardingCase
       * Description: Creating a new case to internal ‘on-boarding ’ team if Case.RecordType = “IM Employees Support Case”,
              Case.Status = “Closed”, Case.Issue__c = “Account Set Up”, Case.Related_To__c = “Customer Account/Client Code”, 
              Case.IM_Division__c = “IME” or “IMAP”
       * Copyright: HCL Technologies
       * Author: Himanshu Jain
       * Modification Log: Created:6-Mar-2012
**/
trigger IRM_SC_RaiseOnBoardingCase on Case (before update) 
{
    Static Integer integerCount = 0;
    Set<String> caseCountry = new Set<String>();
    Set<String> countryRiskIsActive = new set<String>();
    List<Case> caseOnBoardingList = new List<Case>();
    List<Case> onBoardingCaseList = new List<Case>();
    Map<Id, Case> caseOldCaseList = new Map<Id, Case>();
    List<IME_SC_Toggle_Country_Features__c> lstCountryFeature = IME_SC_Toggle_Country_Features__c.getAll().values();
    Map<String, Schema.RecordTypeInfo> caseRecordTypeIdMap = IRM_SC_SelectRecordType.getRecordType();
    Id imeCaseRecordTypeID = caseRecordTypeIdMap.get('IM Employees Support Case').getRecordTypeId();
    //Fetching the assignment rules on case
    for(IME_SC_Toggle_Country_Features__c toggleFeaturesList: IME_SC_Toggle_Country_Features__c.getAll().values())
    {
        if((toggleFeaturesList.Feature_Name__c).equalsIgnoreCase('On-boarding') && toggleFeaturesList.Is_Active__c == true)
            countryRiskIsActive.add(toggleFeaturesList.country__c);
    }
    
    for(case caseOldCase : Trigger.Old)
    {
        caseOldCaseList.put(caseOldCase.id, caseOldCase);
    }
    
    for(Case caseOnboarding : Trigger.new)
    {
        Case oldcase = caseOldCaseList.get(caseOnboarding.id);
        //checking the cases for on baording cases
        
        if(oldcase.RecordTypeId == imeCaseRecordTypeID)
        {
            if(caseOnboarding.Status == 'Closed' && oldcase.RecordTypeID == imeCaseRecordTypeID && oldcase.RecordTypeID != caseOnboarding.RecordTypeID && caseOnboarding.Issue__c == 'Account Set Up' && caseOnboarding.Related_To__c == 'Customer Account/Client Code' && (caseOnboarding.IM_Division__c == 'IME' || caseOnboarding.IM_Division__c == 'IMAP'))
            {    
                for(String countryRisk : countryRiskIsActive)
                {
                    if(caseOnboarding.IM_Employee_Country__c != null)
                    {
                        if((caseOnboarding.IM_Employee_Country__c).equalsIgnoreCase(countryRisk))
                        {
                            caseOnBoardingList.add(caseOnboarding);
                        }
                    }
                }
            }
        }
    }
               
    for(Case onBoardingCase : caseOnBoardingList)
    {   
        Case newOnBoardingCase = new Case();
        newOnBoardingCase.Related_To__c =  'Customer Account';
        newOnBoardingCase.Issue__c = 'Onboard Customer';  
        newOnBoardingCase.Origin = 'Internal';
        newOnBoardingCase.RecordTypeId = imeCaseRecordTypeID;
        newOnBoardingCase.IM_Division__c = onBoardingCase.IM_Division__c;
        //newOnBoardingCase.Customer_ID__c = onBoardingCase.Customer_ID__c;
        newOnBoardingCase.Customer_ID__c = onBoardingCase.Customer_ID__c;
        newOnBoardingCase.Status = 'New';
        newOnBoardingCase.Priority = 'Medium';
        newOnBoardingCase.AccountId = onBoardingCase.AccountId;
        newOnBoardingCase.ContactId = onBoardingCase.ContactId;
        newOnBoardingCase.IM_Employee_Contact__c = onBoardingCase.IM_Employee_Contact__c;
        newOnBoardingCase.IME_SC_Country__c = onBoardingCase.IM_Employee_Country__c;
        newOnBoardingCase.Subject = System.Label.IME_SC_New_Onboarding_Request;//'New Onboarding Request';
        newOnBoardingCase.Description = onBoardingCase.Description;
        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        //dmlOpts.assignmentRuleHeader.assignmentRuleId= assignmentRule.id;
        dmlOpts.assignmentRuleHeader.useDefaultRule = true;
        dmlOpts.EmailHeader.triggerUserEmail = true;

        newOnBoardingCase.setOptions(dmlOpts); 
        onBoardingCaseList.add(newOnBoardingCase);      
    }    
        
    if(onBoardingCaseList != NULL && onBoardingCaseList.size() > 0)
    {  
        if(integerCount == 0)
        { 
            //creating a new case for on boarding
            Insert onBoardingCaseList;  
            integerCount = 1;
        }
    } 
  
}
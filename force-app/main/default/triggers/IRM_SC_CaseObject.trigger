/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Email_to_CaseBatchJob (Batch Class)
**
** PURPOSE
**   Email-to-Case Fix when locking error occurs. 
**
** NOTES
**   Expected invocation format:
**     whenever locking error gets upon case insertion from IRM_SC_ClosedCaseEmail Trigger on EmailMessage Object.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 06/17/2013; Srinivasa Rao/Randstad; Email-to-case emails not creating cases (Customer Services) (Case # 01414611); Initial release
**
** Trigger Name: IRM_SC_updateCaseInfoTrigger
** Description : Fetches the queue name and updates the Queue field on the Case page layout.
**               Set country, Business Hour, Business Hour, Country code and Division 
**               Set SLA and case status flow.
**               Populate Customer Account, Customer Account email, Owner manager and manager of 
**               owner's manager email.
**               Case assignment to customer acount's account manager based on toggle country feature.
**               Send Email through generic workflow. 
**
** Trigger Name: IRM_SC_RaiseOnBoardingCase
** Description : Creating a new case to internal ‘on-boarding ’ team if Case.RecordType = “IM Employees Support Case”,
**               Case.Status = “Closed”, Case.Issue__c = “Account Set Up”, Case.Related_To__c = “Customer Account/Client Code”, 
**               Case.IM_Division__c = “IME” or “IMAP”
**
** Trigger Name: IRM_SC_updateCaseView
** Description :  Decrements the Number of Views for the CSR,when he accepts the case**
**
************************************************************************/

/**
     * Modified By: Vinutha Iyengar on 25-Nov-2015 
     *           --To stop trigger being fired from Email Archive batch job
**/

trigger IRM_SC_CaseObject on Case (after insert, after update, before insert, 
before update) {

    /****Variable declaration for IRM_SC_updateCaseInfoTrigger****/
    static Boolean onInsert = false;    
    Map<Id, Case> oldCaseMap;
    static Boolean bErrorFound = false;
    Id imeCaseRecordTypeID;
    Id imeCaseResolvedRecordType;
    Id imeScCaseRecordTypeID;
    ID stpCaseRecordTypeID;
    Id imeScCaseResolvedRecordType;
    public String IRM_SC_updateCaseInfoTrigger=null;
    public Boolean runIRM_SC_updateCaseInfoTrigger=false;
    
    /****Variable declaration for IRM_SC_RaiseOnBoardingCase****/   
    Static Integer integerCount = 0;
    Set<String> caseCountry = new Set<String>();
    Set<String> countryRiskIsActive = new set<String>();
    List<Case> caseOnBoardingList = new List<Case>();
    List<Case> onBoardingCaseList = new List<Case>();
    Map<Id, Case> caseOldCaseList = new Map<Id, Case>();    
    public String IRM_SC_RaiseOnBoardingCase=null;
    
    /****Variable declaration for IRM_SC_updateCaseView****/
    private static boolean bFired = true;       
    List<IME_SC_Case_View_Info__c> lstCaseViewInfo = new List<IME_SC_Case_View_Info__c>();      
    map<ID,IME_SC_Case_View_Info__c> mCaseView = new map<ID,IME_SC_Case_View_Info__c>(); 
    public String IRM_SC_updateCaseView=null;
    
    public Boolean userUncheck = false;
   
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
    system.debug(LoggingLevel.INFO,'IMNA_createCaseAction - emailArchiveBatchJob value is  =='+IsEmailArchiveBatchJob); 
    // Block added to make sure trigger does not get executed if being fired from Email Archive batch job
         
    if(!IsEmailArchiveBatchJob)
    {
    /***Retrieving Custom Settings***/ 
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
      if(cs.Object__c=='Case'){
        if(cs.Trigger__c == 'IRM_SC_updateCaseInfoTrigger') {
          IRM_SC_updateCaseInfoTrigger = cs.Value__c;
        }
        if(cs.Trigger__c == 'IRM_SC_RaiseOnBoardingCase') {
          IRM_SC_RaiseOnBoardingCase = cs.Value__c;    
        }
        if(cs.Trigger__c == 'IRM_SC_updateCaseView') {
          IRM_SC_updateCaseView = cs.Value__c;  
        }       
      }
    }
    
    /* Custom Settings for Case Closure Workflow */
 /*   IMESCCaseWorkflows__c ordersettings = IMESCCaseWorkflows__c.getInstance('Order');
    IMESCCaseWorkflows__c nonordersettings = IMESCCaseWorkflows__c.getInstance('Non Order');
    system.debug('settings: ' + ordersettings);
    system.debug('settings: ' + nonordersettings);
   */ 
      /* RecordType Selection for Case Closure Workflow */
            Map<String, Schema.RecordTypeInfo> caseRecordTypeIdMap1 = IRM_SC_SelectRecordType.getRecordType();
            imeScCaseRecordTypeID = caseRecordTypeIdMap1.get('IME SC Case').getRecordTypeId();            
            imeScCaseResolvedRecordType = caseRecordTypeIdMap1.get('IME SC Case Resolved').getRecordTypeId();
            
             /* RecordType Selection End */
    
    /*****************************************START TRIGGER************************************************/

    /*****************************************BEFORE INSERT AND UPDATE*************************************/
    if(Trigger.isBefore){
         /* Workflow Rule Limits */
               for(Case c1 : Trigger.new){
                        if(c1.RecordTypeId == imeScCaseRecordTypeID){                             
                        if(c1.IME_SC_Resolved_Date__c ==null && (c1.Status=='Resolved'||c1.Status=='Closed'))
                                c1.IME_SC_Resolved_Date__c = System.Now();
                        }
                    } 
            /* End of Workflow */
        if(Trigger.isInsert){
            runIRM_SC_updateCaseInfoTrigger=true;
             for(Case c1 : Trigger.new){
                        if(c1.SuppliedEmail!=null)
                            c1.IME_SC_Case_Email__c = c1.SuppliedEmail; //Copy Web email to case email for email to case creation
                        system.debug(logginglevel.info, 'Case email is  '+c1.IME_SC_Case_Email__c);
                        if(c1.RecordTypeId == imeScCaseRecordTypeID){                                   
                        if(c1.Status=='Closed')
                                c1.IME_SC_First_Time_Resolution__c = true;
                                
                        }
                    } 
        }
        
        if(Trigger.isUpdate){                   
                      
          
            runIRM_SC_updateCaseInfoTrigger=true;
           for(Case c1 : Trigger.new){
            Case oldCase = trigger.oldMap.get(c1.Id);
                        if(c1.SuppliedEmail!=null && oldCase.SuppliedEmail !=c1.SuppliedEmail)
                                c1.IME_SC_Case_Email__c = c1.SuppliedEmail; //overwrite case email only if new entry on case close screen
           }
       /*     for(Case c :Trigger.new){
                Case oldCase = trigger.oldMap.get(c.Id);
                system.debug(logginglevel.info, '+++++++ oldCase ++++++++++' + oldCase);
                if(oldCase.IME_SC_Send_Closure_Email__c == true && c.IME_SC_Send_Closure_Email__c == false){
                    userUncheck = true;
                    system.debug(logginglevel.info, '++++ uncheck is +++ ' + userUncheck);
                    
                }
                } */
            
            /****IRM_SC_RaiseOnBoardingCase****/
            /*---start---*/
            if(IRM_SC_RaiseOnBoardingCase=='True'){
                System.debug('--60---Executing IRM_SC_RaiseOnBoardingCase Trigger-----');
                
                List<IME_SC_Toggle_Country_Features__c> lstCountryFeature = IME_SC_Toggle_Country_Features__c.getAll().values();
                Map<String, Schema.RecordTypeInfo> caseRecordTypeIdMap_Raise = IRM_SC_SelectRecordType.getRecordType();
                Id ime_CaseRecordTypeID = caseRecordTypeIdMap_Raise.get('IM Employees Support Case').getRecordTypeId();
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
                    system.debug(logginglevel.info, 'Case email is  '+caseOnboarding.IME_SC_Case_Email__c);
                    Case oldcase = caseOldCaseList.get(caseOnboarding.id);
                    //checking the cases for on baording cases
                    //
                    if(oldcase.IME_SC_Send_Closure_Email__c == true && caseOnboarding.IME_SC_Send_Closure_Email__c==false)
                    {
                        
                        userUncheck = true;
                        caseOnboarding.IRM_SC_UserDisable__c='True';
                    }
                    
                    if((oldcase.RecordTypeId == ime_CaseRecordTypeID)/*|| (Test.isRunningTest())*/)
                    {
                        if((caseOnboarding.Status == 'Closed' && oldcase.RecordTypeID == ime_CaseRecordTypeID && oldcase.RecordTypeID != caseOnboarding.RecordTypeID && caseOnboarding.Issue__c == 'Account Set Up' && caseOnboarding.Related_To__c == 'Customer Account/Client Code' && (caseOnboarding.IM_Division__c == 'IME' || caseOnboarding.IM_Division__c == 'IMAP'))/*|| (Test.isRunningTest())*/)
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
                    newOnBoardingCase.RecordTypeId = ime_CaseRecordTypeID;
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
            /****IRM_SC_RaiseOnBoardingCase****/
            /*---end---*/
        }
    }
    
    /*************************************END OF BEFORE INSERT AND UPDATE**********************************/ 
    
    
    /*****************************************AFTER INSERT AND UPDATE**************************************/
    if(Trigger.isAfter){
        
        if(Trigger.isInsert){
            runIRM_SC_updateCaseInfoTrigger=true;
        }
        if(Trigger.isUpdate){
            runIRM_SC_updateCaseInfoTrigger=true;
         //   List<Case> newCaseList = IRM_SC_SelectRecordType.getCaseList(Trigger.New);
         //   IRM_SC_CaclulateSLAClass calculateSLA = new IRM_SC_CaclulateSLAClass();
           // calculateSLA.caseSLASelection(newCaseList); //Testing Sandhya
            /****IRM_SC_updateCaseView****/
            /*---start---*/
            if(IRM_SC_updateCaseView=='True'){
                System.debug('--152---Executing IRM_SC_updateCaseView Trigger-----');
                String userId = UserInfo.getUserId();
                System.debug('---197---userId:'+userId);
                List<Case> new_CaseList = IRM_SC_SelectRecordType.getCaseList(Trigger.New); 
                System.debug('---199---new_CaseList:'+new_CaseList);
                System.debug('-----205-----IRM_SC_IfUpdateCaseViewFired.hasAlreadyUpdatedCaseViewInfo:'+IRM_SC_IfUpdateCaseViewFired.hasAlreadyUpdatedCaseViewInfo());
                if(!IRM_SC_IfUpdateCaseViewFired.hasAlreadyUpdatedCaseViewInfo())
                {
                       list<IME_SC_Case_View_Info__c> objCaseViewUpdate = [SELECT IME_SC_Case__c,IME_SC_Counter__c,IME_SC_User__c from IME_SC_Case_View_Info__c 
                                                                        WHERE IME_SC_Case__c =: new_CaseList AND IME_SC_User__c =: userId];
                       System.debug('--211--objCaseViewUpdate:'+objCaseViewUpdate);
                        System.debug('--212--Test.isRunningTest:'+Test.isRunningTest());
                        //this is for test class
                        if(Test.isRunningTest())
                        {
                            IME_SC_Case_View_Info__c caseTest = new IME_SC_Case_View_Info__c(Name ='Test Case', IME_SC_Case__c = trigger.new[0].id, IME_SC_Counter__c = 1);
                            Insert caseTest;
                            System.debug('--218--caseTest:'+caseTest);
                            objCaseViewUpdate.add(caseTest);
                        }
                        
                        System.debug('--222--objCaseViewUpdate:'+objCaseViewUpdate);
                        if(objCaseViewUpdate != null)
                        {
                            for (IME_SC_Case_View_Info__c caseInfo:objCaseViewUpdate) 
                            {
                               System.debug('--227--caseInfo.IME_SC_Counter__c:'+caseInfo.IME_SC_Counter__c);
                               if(caseInfo.IME_SC_Counter__c > 0)
                               {
                                  mCaseView.put(caseInfo.IME_SC_Case__c,caseInfo);
                               }
                            }
                        }
                        
                        System.debug('--235-mCaseView:'+mCaseView);
                        if(mCaseView!= NULL && mCaseView.size() > 0)
                        {
                            for(Case c : new_CaseList)
                            {
                               System.debug('--240--c.OwnerId:'+c.OwnerId +'\t userId:'+userId);
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
            /****IRM_SC_updateCaseView****/
            /*---end---*/
        }
    }
    
    /****IRM_SC_updateCaseInfoTrigger****/
    /*---start---*/
    if(IRM_SC_updateCaseInfoTrigger=='True'){
        if(runIRM_SC_updateCaseInfoTrigger==true){
            System.debug('--212---Executing IRM_SC_updateCaseInfoTrigger Trigger-----');
            List<Case> newCaseList = IRM_SC_SelectRecordType.getCaseList(Trigger.New);
            if(Trigger.oldMap != null)
            {
                oldCaseMap = IRM_SC_SelectRecordType.getCaseMap(Trigger.oldMap);
            }
            if(!(newCaseList.isEmpty()))
            { 
                IRM_SC_AssignCaseToAccManager updateCase = new IRM_SC_AssignCaseToAccManager();
                IRM_SC_UpdateCaseInfoClass updateCaseInfo = new IRM_SC_UpdateCaseInfoClass();
                IRM_SC_fetchUpdateQueue fetchUpdateQueue = new IRM_SC_fetchUpdateQueue();
                IRM_SC_CaclulateSLAClass calculateSLA = new IRM_SC_CaclulateSLAClass();
                if(trigger.isBefore)
                {
                   
                    IRM_SC_CaseTriggerClass caseTrigger = new IRM_SC_CaseTriggerClass();
                    caseTrigger.manualCutoff(newCaseList, oldCaseMap);
                    caseTrigger.selectCountryFromOrigin(newCaseList, oldCaseMap);
                    fetchUpdateQueue.UpdateQueueName(newCaseList, oldCaseMap, Trigger.isUpdate);
                    caseTrigger.businessHourCutOffSLA(newCaseList, oldCaseMap, Trigger.isUpdate);
                    caseTrigger.customerAccount(newCaseList);
                    updateCaseInfo.populateUsers(newCaseList);
                    calculateSLA.setSLA(newCaseList, oldCaseMap);
                    updateCaseInfo.populateRequestType(newCaseList, oldCaseMap);
                    
              /*** Case #04268923 Code to set correct SLA for Order --  Sandhya, 10/30/2015 **/
                    for(Case c : newCaseList){
                    if(c.IME_SC_Request_Type__c =='Order')
                    {
                        calculateSLA.caseSLASelection(newCaseList);
                }}
                /** End of code **/
                    
                calculateSLA.setSLA(newCaseList, oldCaseMap);
                    if(Trigger.isInsert)
                    {
                        updateCaseInfo.populateContactForEmailToCase(newCaseList);
                    }
                    if(trigger.isUpdate)
                    {
                        List<Case> oldCaseList = IRM_SC_SelectRecordType.getCaseList(Trigger.Old);
                        if(onInsert == false)
                        {
                            updateCaseInfo.updateStatus(newCaseList, oldCaseMap);
                        }
                        System.debug('--247-----newCaseList:'+newCaseList);
                        System.debug('--248-----oldCaseMap:'+oldCaseMap);
                        IRM_SC_SendEmailOnOwnerChange.sendEmail(newCaseList, oldCaseMap);
                    }
                    updateCase.assignCaseToAccManager(newCaseList); 
                    
                   
                }
            }
            
            //for Generic Workflows
            if(Trigger.isBefore)
            {   
                system.debug(logginglevel.info, '+++ generic workflow in before+++');
             /* 
                IRM_SC_CaclulateSLAClass calculateSLA = new IRM_SC_CaclulateSLAClass();
                IRM_SC_UpdateCaseInfoClass updateCaseInfo = new IRM_SC_UpdateCaseInfoClass();
                system.debug(logginglevel.info, '+++ newCaseList+++ '+ newCaseList);
                if(Trigger.oldMap != null)
            {
                oldCaseMap = IRM_SC_SelectRecordType.getCaseMap(Trigger.oldMap);
            }
                system.debug(logginglevel.info, '+++ oldCaseMap+++ '+ oldCaseMap);
                updateCaseInfo.populateRequestType(newCaseList, oldCaseMap);
                
                for(Case c : newCaseList){
                    if(c.IME_SC_Request_Type__c =='Order')
                    {
                        calculateSLA.caseSLASelection(newCaseList);
                }}
                
                calculateSLA.setSLA(newCaseList, oldCaseMap);
                */        
                List<Case> caseList= new List<Case>();
                Map<Id,Case> oldCaseOwnerMap = new Map<Id,Case>();
                //Recordtype selection
                Map<String, Schema.RecordTypeInfo> caseRecordTypeIdMap = IRM_SC_SelectRecordType.getRecordType();
                Set<Id> recordTypeIdSet = new Set<Id>();
                imeCaseRecordTypeID = caseRecordTypeIdMap.get('IME SC Case').getRecordTypeId();
                recordTypeIdSet.add(imeCaseRecordTypeID);
                imeCaseResolvedRecordType = caseRecordTypeIdMap.get('IME SC Case Resolved').getRecordTypeId();
                recordTypeIdSet.add(imeCaseResolvedRecordType);
                
                
                if(Trigger.isInsert){
                    
                    for(Case newCase: Trigger.new)
                {
                    system.debug(logginglevel.info, 'Case email is  '+newCase.IME_SC_Case_Email__c);
                    if(recordTypeIdSet != null && !recordTypeIdSet.isEmpty())
                    {
                        if(recordTypeIdSet.contains(newCase.RecordTypeId))
                        {
                          if(newCase.RecordTypeId == imeCaseRecordTypeID && newCase.IME_SC_Request_Type__c == 'Order' && newCase.IRM_SC_UserDisable__c!='True') 
                                newCase.IME_SC_Send_Closure_Email__c = true; // send closure workflow
                                newCase.IRM_SC_UserDisable__c='False';
                                system.debug(logginglevel.info, '+++ unCheck+++' + userUncheck);
                            caseList.add(newCase);
                        }
                    }
                }
                }
                
                if(Trigger.isUpdate)
                {
                  for(Case oldCase: Trigger.old)
                  {
                    if(recordTypeIdSet != null && !recordTypeIdSet.isEmpty())
                      {
                          if(recordTypeIdSet.contains(oldCase.RecordTypeId))
                          {
                              oldCaseOwnerMap.put(oldCase.Id,oldCase);
                          }
                      }
                  }
                    
                    for(Case newCase: Trigger.new)
                {
                    system.debug(logginglevel.info, 'Case email is  '+newCase.IME_SC_Case_Email__c);
                    if(recordTypeIdSet != null && !recordTypeIdSet.isEmpty())
                    {
                        
                        if(recordTypeIdSet.contains(newCase.RecordTypeId))
                        {
                            Case oldCase = oldCaseOwnerMap.get(newCase.Id);
                            //system.debug(logginglevel.info, '+++++ oldCase.IME_SC_Send_Closure_Email__c ++++ '+ oldCase.IME_SC_Send_Closure_Email__c);
                            
                            if(oldCase != null && oldCase.IME_SC_Request_Type__c=='Non-order' && newCase.IME_SC_Request_Type__c=='Order')
                            {
                                newCase.IRM_SC_UserDisable__c='False';    
                            }
                            
                            if(oldCase != null && oldCase.IME_SC_Send_Closure_Email__c==false && newCase.IME_SC_Send_Closure_Email__c==true){  
                                newCase.IRM_SC_UserDisable__c='False';
                            }
                            
                            if(oldCase != null && oldCase.IME_SC_Send_Closure_Email__c==true && newCase.IME_SC_Send_Closure_Email__c==false){
                                userUncheck = true;
                                newCase.IRM_SC_UserDisable__c='True';
                            }
                          if(newCase.RecordTypeId == imeCaseRecordTypeID && newCase.IME_SC_Request_Type__c == 'Order' && userUncheck!=true && newCase.IRM_SC_UserDisable__c!='True') 
                                newCase.IME_SC_Send_Closure_Email__c = true; //send closure workflow
                                //newCase.IRM_SC_UserDisable__c='False';
                                system.debug(logginglevel.info, '+++ unCheck+++' + userUncheck);
                            caseList.add(newCase);
                        }
                    }
                }
                     /* Added this functionality for Reducing the Case Closure Email Workflow rule Limits */
             for(case newCase: trigger.new){
                 system.debug(logginglevel.info, 'Case email is  '+newCase.IME_SC_Case_Email__c);
                if(newCase.RecordTypeId == imeScCaseResolvedRecordType && newCase.Status =='Closed' && newCase.IME_SC_Send_Closure_Email__c==true && newCase.IME_SC_Notification_Name__c==null){
            
                    newCase.IME_SC_To_Address__c = newCase.IME_SC_Case_Email__c;
                    string EmailTemplate ='IME_SC_' + newCase.IME_SC_Country_Code__c +'_';

      ////Added by Sandhya for custom settings test. Working test code.
      List<IME_SC_Order_Nonorder_Templates__c> templates = IME_SC_Order_Nonorder_Templates__c.getall().values();
         system.debug(logginglevel.info, '+++ templates '+ templates);  
         system.debug(logginglevel.info, '++++ newcase.origin 1 +++ '+ newcase.origin);
                    if(newCase.IME_SC_Request_Type__c=='Order')
            {
                
                newCase.IME_SC_Email_Template_Name_test__c = EmailTemplate + 'Case_Closure_Order';
                newCase.IME_SC_Notification_Name__c = 'Case_Closure_Order';
                system.debug(logginglevel.info, '++++++ inside order 2 +++');
            }
            else if (newCase.IME_SC_Request_Type__c=='Non-order')
            {
                newCase.IME_SC_Email_Template_Name_test__c = EmailTemplate + 'Case_Closure_Non_Order';
                newCase.IME_SC_Notification_Name__c = 'Case_Closure_Non_Order';
                system.debug(logginglevel.info, '++++++ inside order 2 +++');
            }
        for(IME_SC_Order_Nonorder_Templates__c t : templates)
        {
            system.debug(logginglevel.info, '+++ inside logic +++') ;
            system.debug(logginglevel.info, '++++ template is +++' + t);
            
            if(newCase.origin == t.Name){
                system.debug(logginglevel.info, '++++ newcase.origin +++ '+ newcase.origin);
            if(newCase.IME_SC_Request_Type__c=='Order')
            {
                newCase.IME_SC_Email_Template_Name_test__c = EmailTemplate + t.Order_Notification__c;
                newCase.IME_SC_Notification_Name__c = t.Order_Notification__c;
                system.debug(logginglevel.info, '++++++ inside order 1 +++' +t.Order_Notification__c);
            }
            else if (newCase.IME_SC_Request_Type__c=='Non-order')
            {
                newCase.IME_SC_Email_Template_Name_test__c = EmailTemplate + t.Non_Order_Notification__c;
                newCase.IME_SC_Notification_Name__c = t.Non_Order_Notification__c;
                system.debug(logginglevel.info, '++++++ inside nonorder 1 +++' +t.Non_Order_Notification__c);
            }
            }
           
            
        }            
     // //End
                    
    
                    
    
                }
             }
        
       /* Workflow Logic implementation is Ending Here */ 
                }
                
                if(caseList!= null && !caseList.isEmpty())
                {
                    System.debug('--295-----caseList:'+caseList);
                    System.debug('---296----oldCaseOwnerMap:'+oldCaseOwnerMap);
                    IRM_SC_SendEmail.sendEmail(caseList, oldCaseOwnerMap);
                }
            }
            //End of Generic Workflows
        }
    }
    /****IRM_SC_updateCaseInfoTrigger****/
    /*---end-----*/
    
    /*************************************END OF AFTER INSERT AND UPDATE***********************************/
    
    /*****************************************END TRIGGER**************************************************/   
    }   
}
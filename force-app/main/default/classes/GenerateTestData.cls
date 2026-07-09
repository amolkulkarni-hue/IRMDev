/*****************************************************************************************************************************
Name : GenerateTestData
Created By : Reena
Created Date : 17th Sept , 2010
Usages : Create dummy data for test classes..
* Modified By     : TCS
2022/06/08; #8989 Delete 10 case field deletion :- Part 1;  
Part of the #8989 story commented cid_provided__c the field reference.

*Modified By: Arjun Sankar for Story # 10469 and 10364 - Date 6th Octber 2022
* Modified By     : TCS
2022/16/12; #8989 Delete 10 case field deletion :- Part 1;  
*****************************************************************************************************************************/
@IsTest
public class GenerateTestData{
    
    public static case createCase(Id caseRecordType , ID custAccID){
       
        ID accountRecordType;
        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account'];
        
        if(lstRecordType.size() > 0){
            
            accountRecordType = lstRecordType[0].ID;
            
        }
        
           
        if(caseRecordType == null){
            List<RecordType> lstRecordType2 =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Case' and isActive = true];
            
            if(lstRecordType2.size() > 0){
                caseRecordType = lstRecordType2[0].ID;
            }
        }        
        
               
        Account acc = new Account(Name = 'testAccount1', BillingCountry= 'United States', IM_Hierarchy_Level__c='Sales (Site)');
        insert acc; 
        //W-000680
        Contact con = new Contact(AccountId=acc.id ,FirstName='Test Contact', LastName = 'test',Phone = '123456', Email='vinod.kumar@metacube.com', OtherCountry ='Canada',MailingCountry='United States');
        insert con;
        //
        list<IM_Customer_Account__c> lstCustAccount = [Select id,IM_Account__c from IM_Customer_Account__c where id = :custAccID ];
        if(lstCustAccount.size() >0 ){
            IM_Customer_Account__c custAcc = lstCustAccount[0];
            custAcc.IM_Account__c = acc.id;
            update custAcc;         
        }      
        // Create 
        Case newCase = new Case();
       
        String usrId = UserInfo.getUserId();
        newCase.OwnerId = usrId;
        newCase.RecordTypeId = caseRecordType;
        newCase.AccountId = acc.Id;
        newCase.Customer_ID__c = custAccId;
        newCase.ContactId = con.Id;
        newCase.Origin = 'Email';        
        newCase.Type = 'Billing';     
        newCase.Subject = 'Test';
        newCase.Description = 'Test';
        newCase.Priority = 'Normal';
        newCase.Status = 'New';
        // 
        newCase.Reason__c = 'Completed';
        newCase.Is_Cloned__c = false;
        newCase.Recurring_Case__c = false;
        //newCase.Recurring_Frequency__c = c.Recurring_Frequency__c;
        newCase.SLA_Days__c =1;
        DateTime dtInitialTargetDate = DateTime.now();
        newCase.Initial_Due_Date__c = dtInitialTargetDate.date();
        newCase.SLA_Target_Date__c = dtInitialTargetDate;
        insert newCase;
        return newCase;
    }
   
    public static IM_Customer_Account__c createCustomerAccount(String districtBranchId , String systemCode){
        Market__c testMarket = new Market__c(name= 'test test2')  ;
        insert testMarket;
        ID accountRecordType;
        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account' AND DeveloperName = 'Standard_Account' ];
        
        if(lstRecordType.size() > 0){
            
            accountRecordType = lstRecordType[0].ID;
            
        }
        //W-000680
        Account acc = new Account(Name = 'testAccount1',RecordTypeId =accountRecordType, BillingCountry= 'United States');
        insert acc; 
        IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
        
        custAcc.Name = 'Test'+ string.valueOf(Math.random());
        custAcc.Owning_District_Id__c = testMarket.Id;
        //custAcc.IM_Customer_Account_Name__c = 'Test Account Name';
        //custAcc.IM_District_Branch_Id__c = '101';
        custAcc.Source_System__c = 'SB NA';
        custAcc.IM_Account__c = acc.Id;
        insert custAcc; 
        return custAcc;      
       
        
    }
     public static IM_Customer_Account__c createCustomerAccountWithoutInsert(String districtBranchId , String systemCode){
        Market__c testMarket = new Market__c(name= 'test')  ;
        insert testMarket;
        IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
        custAcc.Name = 'Test'+ string.valueOf(Math.random());
        custAcc.IM_Customer_Account_Name__c = 'Test Account Name';
        ID accountRecordType;
        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account' AND DeveloperName != 'QTB_Billing_Account'];
        if(lstRecordType.size() > 0){
            
            accountRecordType = lstRecordType[0].ID;
            
        }
        //W-000680
        Account acc = new Account(Name = 'testAccount1', BillingCountry= 'United States', IM_Hierarchy_Level__c='Sales (Site)', RecordTypeId = accountRecordType);
        System.debug('acc===>'+acc);
         insert acc;
        //custAcc.IM_District_Branch_Id__c = districtBranchId ;//'101';
        //custAcc.IM_Source_System_Code__c = systemCode;//'Test';
        custAcc.Owning_District_Id__c = testMarket.Id;
        custAcc.Source_System__c = 'SB NA';
        custAcc.IM_Account__c = acc.Id;
        return custAcc;
    }
    
    public Static Task_Details__c createTaskDetail(){
        Task_Details__c taskDetail = new Task_Details__c();
        taskDetail.Unique_Task__c = 'ub';
        taskDetail.Business_area__c = 'ba';
        taskDetail.Sub_Area__c = 'sa';
        taskDetail.Subject__c = '^^$$##Sub';
        taskDetail.Description__c = 'Description';
        taskDetail.Service_Line__c = 'Sl';
        taskDetail.Dashboard_Bar_Name__c = 'Dashboard';       
        taskDetail.Include_In_Dashboard__c = true;
        taskDetail.Instructions__c = 'Instruction';
        taskDetail.Group_Name__c = 'TestG';
        taskDetail.Mandatory_Task__c = true;
        taskDetail.SLA_Time_Type__c = 'Clock';
        taskDetail.SLA__c = 2;     
        insert taskDetail; 
        return taskDetail;  
    }
    
    public static Task createTask(){
        Task task = new Task();
        task.Subject =  '^^$$##Sub';
        task.Due_Date__c = System.now();
        insert task;
        return task;
    }
    public static Task createTaskWithoutInsert(Id taskRecordType){
        Task task = new Task();
        task.Subject =  '^^$$##Sub';
        task.Due_Date__c = System.now();
        task.RecordTypeId = taskRecordType;       
        return task;
    }
    public static Closure_Action__c createClosureAction(ID taskDetailID , String actionType){
        Closure_Action__c curAct = new Closure_Action__c();
        curAct.Value_To_Assign__c = 'test';
        curAct.Task_ID__c = taskDetailId;        
        curAct.Case_Field_Data_Type__c = 'String';
        curAct.Case_Field_API_Name__c = 'City__c';
        curAct.Action_Type__c = actionType;
        curAct.Task_Action_Id__c ='testAct';
        insert curAct; 
        return curAct;
    }
    
    public static Event createEvent(id whatID){
        Event evt = new Event();
        evt.Mandatory_Task__c = true;
        evt.WhatId = whatID ;     
        evt.DurationInMinutes = 2940;
        evt.ActivityDateTime =  DateTime.now();
        insert evt;
        return evt;
    }
    
    public static Account createAccount(){
        Account act = new Account();
        act.Name = 'Test';
        insert act;
        return act;
    }
    
    public static SLA_Matrix__c createSLAMatrix(ID recordTypeID){
        SLA_Matrix__c slaMatrix = new SLA_Matrix__c();
        slaMatrix.Type__c = 'Billing';
        slaMatrix.SLA_Days__c = 2;
        slaMatrix.Case_Subtype__c = '3rd Party';
        slaMatrix.Record_Type__c = recordTypeID;
        insert slaMatrix;
        return slaMatrix;
    }
    public static Case createCaseObjectWithoutInsert(Id caseRecordType , IM_Customer_Account__c custAcc){
           
        /*ID accountRecordType;
        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account'];
        
        if(lstRecordType.size() > 0){
            
            accountRecordType = lstRecordType[0].ID;
            
        }*/
        
           
        if(caseRecordType == null){
            List<RecordType> lstRecordType2 =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Case' ];
            
            if(lstRecordType2.size() > 0){
                caseRecordType = lstRecordType2[0].ID;
            }
        }        
        
               
       /* Account acc = new Account(Name = 'testAccount1',RecordTypeId =accountRecordType);
        insert acc;  */
        //W-000680
        Contact con = new Contact(FirstName= 'Test Contact', AccountId=custAcc.IM_Account__c , LastName = 'test',Phone = '123456', Email='vinod.kumar@metacube.com',OtherCountry ='Canada'/*MailingCountry = 'United States',MailingStreet='10945 Leconte',MailingState='CA',MailingPostalCode='90095',MailingCity='Los Angeles'*/);//10469 and 10364 added mailing address values
        insert con;
        //Update the customer account's account id
       /* custAcc.IM_Account__c = acc.id;
        update custAcc;  */     
        // Create 
        Case newCase = new Case();
       
        String usrId = UserInfo.getUserId();
        newCase.OwnerId = usrId;
        newCase.RecordTypeId = caseRecordType;
        newCase.AccountId = custAcc.IM_Account__c;
        newCase.Customer_ID__c = custAcc.id;
        newCase.ContactId = con.Id;
        newCase.Origin = 'Email';        
        newCase.Type = 'Billing';     
        newCase.Subject = 'Test';
        newCase.Description = 'Test';
        newCase.Priority = 'Normal';
        newCase.Status = 'New';
        newCase.Is_Cloned__c = false;
        newCase.Recurring_Case__c = false;
        //newCase.Recurring_Frequency__c = c.Recurring_Frequency__c;
        newCase.SLA_Days__c =1;
        DateTime dtInitialTargetDate = DateTime.now();
        newCase.Initial_Due_Date__c = dtInitialTargetDate.date();
        newCase.SLA_Target_Date__c = dtInitialTargetDate;    
        
        newCase.Contract_Status__c = 'Test';
        newcase.Contract_Type__c = 'TestType';
        //#8989 Delete 10 case field deletion :- Part 1;
        //newcase.CID_Provided__c = 'TestCID';
        newcase.Date_Reviewed_Ncsp__c = datetime.now();   
        return newCase;
    }
    public static CaseComment createCaseComment(ID caseId){
        CaseComment cComment = new CaseComment();
        cComment.ParentId =  caseId;
        cComment.CommentBody = 'TestCase';
        insert cComment;
        return cComment;
    }

    public static EmailTemplate createEmailTemplate(String name, String developerName) {
        return createEmailTemplate(name, developerName, 'Text');
    }

    /* If templateType is specified as 'Visualforce', .Markup field must be assigned in testMethod in order to insert the template. 
    *   .Markup field must contain <messaging:emailTemplate> tag and either <messaging:plainTextBody> or <messaging:htmlBody> tag */
    public static EmailTemplate createEmailTemplate(String name, String developerName, String temptype) {
        System.assert(temptype=='Text' || temptype=='Visualforce', 'Only Test Email Templates of templateType of "Text" and "Visualforce" can be generated');
        Folder f = [Select Id From Folder Where Name='BW Email Templates' Limit 1];
        EmailTemplate tmpl = new EmailTemplate(
                                    DeveloperName=developerName,
                                    Name=name,
                                    TemplateType=temptype,
                                    FolderId=f.Id );
        return tmpl;

    }

    public static Customer_Onboarding_Criteria__c createTestCriteria( String serviceLine, 
                                                                      String dealType, 
                                                                      String upsellType,
                                                                      Boolean suppliesOrderRequried, Boolean doInsert ) {
        Customer_Onboarding_Criteria__c testCriteria = 
            new Customer_Onboarding_Criteria__c( Service_Line__c = serviceLine,
                                                    Deal_Type__c = dealType,
                                                  Upsell_Type__c = upsellType,
                                      Supplies_Order_Required__c = suppliesOrderRequried );
        if (doInsert) insert testCriteria;
        return testCriteria;
    }

    public static List<Customer_Onboarding_Field__c> createTestOnboardingFields( Integer howMany, 
                                                                                 Id criteria,
                                                                                 String apiName, 
                                                                                 String displayLabel, 
                                                                                 String relatedObj, Boolean doInsert ) {
        List<Customer_Onboarding_Field__c> testFields = new List<Customer_Onboarding_Field__c>();
        for (Integer i=0; i<howMany; i++) {
            Customer_Onboarding_Field__c testField = createTestOnboardingField( criteria, apiName+i, displayLabel+i, i, relatedObj, false );
            testFields.add(testField);
        }
        if (doInsert) insert testFields;
        return testFields;
    }

    public static List<Customer_Onboarding_Field__c> createTestOnboardingFields( Integer howMany, 
                                                                                 Id criteria,
                                                                                 String apiName, 
                                                                                 String displayLabel, 
                                                                                 String displayLabelFrench, 
                                                                                 String relatedObj, Boolean doInsert ) {
        List<Customer_Onboarding_Field__c> testFields = new List<Customer_Onboarding_Field__c>();
        for (Integer i=0; i<howMany; i++) {
            Customer_Onboarding_Field__c testField = createTestOnboardingField( criteria, apiName+i, displayLabel+i, i, relatedObj, false );
            testField.Field_Display_Label_French__c = displayLabelFrench;
            testFields.add(testField);
        }
        if (doInsert) insert testFields;
        return testFields;
    }


    public static Customer_Onboarding_Field__c createTestOnboardingField( Id criteria,
                                                                          String apiName, 
                                                                          String displayLabel, 
                                                                          Integer sortOrder,
                                                                          String relatedObj, Boolean doInsert ) {
        Customer_Onboarding_Field__c testField = new Customer_Onboarding_Field__c( Field_API_Name__c = apiName,
                                                                              Field_Display_Label__c = displayLabel,
                                                                                       Sort_Order__c = sortOrder,
                                                                                   Related_Object__c = relatedObj,
                                                                     Customer_Onboarding_Criteria__c = criteria );
        if (doInsert) insert testField;
        return testField;
    }

    public static Customer_Onboarding_Field__c createTestOnboardingField( Id criteria,
                                                                          String apiName, 
                                                                          String displayLabel, 
                                                                          String displayLabelFrench,
                                                                          Integer sortOrder,
                                                                          String relatedObj, Boolean doInsert ) {
        Customer_Onboarding_Field__c testField = new Customer_Onboarding_Field__c( Field_API_Name__c = apiName,
                                                                              Field_Display_Label__c = displayLabel,
                                                                       Field_Display_Label_French__c = displayLabelFrench,
                                                                                       Sort_Order__c = sortOrder,
                                                                                   Related_Object__c = relatedObj,
                                                                     Customer_Onboarding_Criteria__c = criteria );
        if (doInsert) insert testField;
        return testField;
    }

    public static Case_Field_History__c createTestCaseFieldHistory( Id caseId,
                                                                    String fieldChanged,
                                                                    String currentVal,
                                                                    String prevVal, Boolean doInsert ) {
        Case_Field_History__c testHistory = new Case_Field_History__c( Case_Lookup__c = caseId,
                                                                       Field_Changed__c=fieldChanged,
                                                                       Current_Value__c=currentVal,
                                                                       Previous_Value__c=prevVal );
        if (doInsert) insert testHistory;
        return testHistory;
    }

    //public static Case createTestCaseThatMatchesCriteria(Customer_Onboarding_Criteria__c testCriteria) {
    //    Account testAct = TestingUtils.createAccounts(1, true)[0];
    //    Contact testContact = TestingUtils.createContact(testAct.Id, true);
    //    Opportunity testOppWithDT = TestingUtils.createOpportunity('testOpp', testAct.Id, false);
    //    testOppWithDT.Type = testCriteria.Deal_Type__c;
    //    insert testOppWithDT;
    //    Case testCase = TestingUtils.createCases(1, testOppWithDT, testContact, false)[0];
    //    testCase.NCSP_Service_line__c = testCriteria.Service_Line__c;
    //    testCase.NCSP_Upsell_Type__c = testCriteria.Upsell_Type__c;
    //    testCase.Supplies_Order_Required__c = (testCriteria.Supplies_Order_Required__c?'Yes':'No');
    //    testCase.putSObject('NCSP_Opportunity__r',testOppWithDT);
    //    testCase.getSObject('NCSP_Opportunity__r').put('Type', testCriteria.Deal_Type__c);
    //    return testCase;
    //}

    public static Case createTestCaseThatMatchesCriteria(Customer_Onboarding_Criteria__c testCriteria) {
        Account testAct = TestingUtils.createAccounts(1, true)[0];
        Contact testContact = TestingUtils.createContact(testAct.Id, false);
        testContact.firstName = 'testFirstName';
        insert testContact;
        Opportunity testOppWithDT = TestingUtils.createOpportunity('testOpp', testAct.Id, false);
        testOppWithDT.Type = testCriteria.Deal_Type__c;
        testOppWithDT.Lead_Source_Most_Recent__c = 'Email';
        //insert testOppWithDT;
        //Commented above by CARE team for case Creation
        try
        { 
        insert testOppWithDT;
        }
        catch(Exception e){}
        Case testCase = TestingUtils.createCases(1, testOppWithDT, testContact, false)[0];
        testCase.NCSP_Service_line__c = testCriteria.Service_Line__c;
        testCase.NCSP_Upsell_Type__c = testCriteria.Upsell_Type__c;
        testCase.Deal_Type__c = testCriteria.Deal_Type__c;
        testCase.Supplies_Order_Required__c = (testCriteria.Supplies_Order_Required__c?'Yes':'No');
        testCase.NCSP_Opportunity__c = testOppWithDT.Id;
        return testCase;
    }

    //public static Case createTestCaseThatMatchesCriteria(Customer_Onboarding_Criteria__c testCriteria, Contact testContact, Opportunity testOpp) {
    //    Case testCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
    //    testCase.NCSP_Service_line__c = testCriteria.Service_Line__c;
    //    testCase.NCSP_Upsell_Type__c = testCriteria.Upsell_Type__c;
    //    testCase.Supplies_Order_Required__c = (testCriteria.Supplies_Order_Required__c?'Yes':'No');
    //    testCase.putSObject('NCSP_Opportunity__r', testOpp);
    //    testCase.getSObject('NCSP_Opportunity__r').put('Type', testOpp.Type);
    //    return testCase;
    //}

    public static Case createTestCaseThatMatchesCriteria(Customer_Onboarding_Criteria__c testCriteria, Contact testContact, Opportunity testOpp) {
        Case testCase = TestingUtils.createCases(1, testOpp, testContact, false)[0];
        testCase.NCSP_Service_line__c = testCriteria.Service_Line__c;
        testCase.NCSP_Upsell_Type__c = testCriteria.Upsell_Type__c;
        testCase.Deal_Type__c = testCriteria.Deal_Type__c;
        testCase.Supplies_Order_Required__c = (testCriteria.Supplies_Order_Required__c?'Yes':'No');
        testCase.NCSP_Opportunity__c = testOpp.Id;
        return testCase;
    }
    
    /*  Method     : createIMCountry
   *  Description : This method is used to create IM Country for test data
   *   Return    : returns IM Country record
   */
     public static IM_Country__c createIMCountry(){
        IM_Country__c contry = new IM_Country__c();
        contry.Name = 'United States';
        return contry;
    }
    
   
    /*  Method     : createIMEContract
   *  Description : This method is used to create Contract for test data
   *  Param     : acctId - Account Id, IMCountryId - IM_Country__c Id, recordTypeId - Contract RecordType Id, contractTermType - Contract Term Type(Fixed term/Evergreen/Evergreen (open rolling))
   *  Return    : returns Contract record
   */
    public static Contract createIMEContract(Id acctId,Id IMCountryId,Id recordTypeId,String contractTermType){
           Contract contrct = new Contract();
           contrct.Name = 'test contract new';
           contrct.AccountId = acctId;
           contrct.recordTypeId = recordTypeId;
           contrct.Billing_Country__c = IMCountryId;
           contrct.Status = 'Draft';
           contrct.StartDate = Date.today();
           contrct.IME_Contract_Term_Type__c = contractTermType;
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Price_Increase_Type_Storage__c='Other';
           contrct.IME_Special_Terms_Other_Storage__c='Other Conent';        
           contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           contrct.IME_Index_Storage__c = 'CPI';
           contrct.IME_Capped_Percentage_Storage__c = 12;
           contrct.IME_End_of_Fixed_Pricing_Period_Storage__c = system.today();
           return contrct;
    }
}
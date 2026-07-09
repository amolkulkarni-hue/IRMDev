/*COMBINATION OF ALL TRIGGERS ON CASE OBJECT 
**IN REFERNCE TO CASE 00501518
**AUTHOR: RAJ GOTTIPOLU/KETAN BENEGAL/SRINIVASA RAO MANDALAPU
**DATE: 06/05/2012
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/05/07; Srinivasa Rao/Randstad; Local Market Setup Opportunities/Case 01308481; Initial release
**   2022/06/08; TCS ; #8989 Delete 10 case field deletion :- Part 1;  
Part of the #8989 story commented Contract_Admin_Response_Date__c,proposal_attempt_date_1__c the field reference.
** 2022/05/30; TCS ; #8977 11 NCSP case field deletion :- Part 1;  
Part of the #8977 story commented  Service_Reschedule_Date__c the field reference.

modified lines: Removed the reference of the fields x2nd_sales_resubmission_date__c,service_location_not_found__c,date_2nd_restricted_party_screening__c
date_2nd_order_fulfillment_sent__c,date_1st_restricted_party_screening__c

*Modified By: Arjun Sankar for Story # 10469 and 10364 - Date 6th Octber 2022

* Modified By: Simranjit Kaur on 12-Sept-2024
---Commenting out the lines as the functionalities are transferred via ValidationRules. For reference, check user story #25718 on Gitlab.

* Modified By: Simranjit Kaur on 10-Oct-2024
---Commenting out the lines as the functionalities are transferred via ValidationRules. For reference, check user story #26355 on Gitlab.

* Modified By: Simranjit Kaur on 17-Oct-2024
---Commenting out the lines as the functionalities are transferred via ValidationRules. For reference, check user story #26943 on Gitlab.

* Modified By: Simranjit Kaur on 25-Oct-2024
---Commenting out the lines as the functionalities are transferred via Flows. For reference, check user story #27066 on Gitlab.

* Modified By: Simranjit Kaur on 4-Nov-2024
---Commenting out the lines as the functionalities are transferred via Flows. For reference, check user story #27072 on Gitlab.

* Modified By: Simranjit Kaur on 15-Nov-2024
---Test Methods added to improve code coverage. For reference, check user story #27422 on Gitlab.
*/
@isTest(seeAllData=true)
private class Test_CaseObjectTrigger { 
    public static String NCSPCaseClosedDateTime=null;
    public static String CheckMandatoryTaskForTheCase=null;
    public static String ValidateDateSentToClosure=null;
    public static String CloneCaseIfRecurringCaseChecked2=null;
    public static String NCSP_OpportunityUpdate_Case=null;
    public static String CACDateValidationRules=null;
    //public static String SetOriginalfields=null;
    public static String NCSPDateValidationRulesTrigger=null;
    public static String Issue_TaskRequire_CaseComment_FollowUpNote=null;
    //public static String NCSP_Prevent_ParentCase_Closure=null;
    //public static String UpdateAccountId=null;
    public static String UpdateSlaDaysSlaTargetDateAndValidateInitialDuedate=null;
    public static String updateInternalCaupdateInternalCaseTeamseTeam=null;
    public static String updateInternalCaseTeamIMNA=null;
    //public static String UpdateNCSPStatus=null;
    
    
    public static case createCase(Id caseRecordType){
        // Create  
        Case newCase = new Case();
        //     Account Ac = new Account(name='Account4TestMethod');
        //     insert Ac;
        //   IM_Customer_Account__c custAcc = [Select Id, IM_Account__c From IM_Customer_Account__c Where RecordTypeId = '01280000000UHF0AAO' limit 1];
        /*Start*/
        /*      IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
custAcc.IM_Customer_Account_Name__c = 'Test Account Name';
custAcc.IM_District_Branch_Id__c = '101';
custAcc.IM_Source_System_Code__c = 'Test';
custAcc.IM_Account__c = ac.id;
custAcc.Source_System__c = 'SB NA';
insert custAcc; */
        /*End*/
        IM_Customer_Account__c custAcc = createCustomerAccount('101' , 'Test');
        if(caseRecordType == null){
            List<RecordType> lstRecordType2 =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Case' AND DeveloperName = 'CAC_SKP_RM'];
            
            if(lstRecordType2.size() > 0){
                caseRecordType = lstRecordType2[0].ID;
            }
        }
        
        String usrId = UserInfo.getUserId();
        newCase.OwnerId = usrId;
        newCase.RecordTypeId = caseRecordType;
        newCase.AccountId = custAcc.IM_Account__c;
        newCase.Customer_ID__c = custAcc.Id;
        newCase.Origin = 'Email';        
        newCase.Type = 'Billing';     
        newCase.Subject = 'Test';
        newCase.Description = 'Test';
        newCase.Priority = 'Normal';
        newCase.Status = 'New';
        newCase.Reason__c = 'Completed';
        newCase.Is_Cloned__c = false;
        newCase.Recurring_Case__c = false;
        newCase.SLA_Days__c =1;
        DateTime dtInitialTargetDate = DateTime.now();
        newCase.Initial_Due_Date__c = dtInitialTargetDate.date();
        newCase.SLA_Target_Date__c = dtInitialTargetDate;
        /*Start
newCase.Service_Order_Required__c = 'No';
newCase.Reason_No_Service__c = 'Local Market Handling'; 
End*/
        system.debug('before return of create case ');
        return newCase;
        
    }
    
    static testMethod void testCloseCaseRecurring() {
        ID caseRecordType ;        
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();        
        if(rtMapByName.containsKey('Retention'))
            caseRecordType = rtMapByName.get('Retention').getRecordTypeId();        
        
        
        Case newCase = createCase(caseRecordType);
        newCase.Status = 'Open';
        newCase.Recurring_Case__c = true;
        newcase.SLA_Days__c =2.0;
        newcase.Type ='xyz';
        newCase.Is_Cloned__c = false;
        newCase.Recurring_Frequency__c = 'Weekly';
        newCase.Initial_Due_Date__c = Date.newInstance(2019, 5,2);
        newCase.IM_Case_Sub_Type__c = 'xyz';
        insert newCase;
        CaseComment cComment = GenerateTestData.createCaseComment(newCase.id); 
        newCase.Status = 'Closed';
        Test.startTest();
        update newCase;
        Test.stopTest();
    }
    static testMethod void TestCaseComment_FollowUpNote() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='False';
                updatesettings.add(cs);
            }
        }
        update updatesettings;
        
        // TO DO: implement unit test
        ID caseRecordType ;        
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();        
        if(rtMapByName.containsKey('Retention'))
            caseRecordType = rtMapByName.get('Retention').getRecordTypeId();        
        
        
        Case newCase = createCase(caseRecordType);
        
        insert newCase; 
        newCase.Status = 'Closed';
        newCase.Reason__c= 'Completed';         
        try{
            update  newCase;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('Internal Comments are required if Case Status is Closed'));
        }
        
    }
    /*static testMethod void testCheckMendatoryTaskForTheCase (){
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='False';
                updatesettings.add(cs);
            }
        }
        Test.startTest();
        update updatesettings; 
        Test.stopTest();
        //W-000685
        IM_Country__c mainName = new IM_Country__c(Name='United States4');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States4');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States4';
        setting.object_name__c = 'Account';
        insert setting;
        Account acc= new Account();
        acc.name= 'Test Account New';
        acc.BillingCountry = 'United States4';
        acc.BillingPostalCode = '11209';
        acc.BillingState = 'NY';
        acc.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert acc;         
        Contact con = new Contact(AccountId=acc.id ,FirstName = 'Test FirstName', LastName = 'test',Phone = '123456', Email='vinod.kumar@metacube.com');
        insert con;
        Case newCase = createCase(null);
        //W-000685
        newCase.Authorized_User__c = 'No';
        newcase.AccountId = acc.Id;
        newCase.ContactId = con.Id; 
        
        //Nandini Mishra:6/3/2022 Start
        //newCase.Estimated_Pay_Date__c=System.today()+3;
        //Nandini Mishra:6/3/2022 End
        insert newCase; 
        
        //Task task = GenerateTestData.createTask();
        Task task = new Task();
        task.Subject ='Contact Validated';
        task.Due_Date__c = System.now();
        task.WhoId=con.id;
        task.WhatId=acc.id;
        insert task;
        
        task.Mandatory_Task__c = true;
        // Add comment for closed case
        CaseComment cComment = GenerateTestData.createCaseComment(newCase.id);         
        try{
            newCase.Status = 'Closed';
            update newCase;
        }catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Cannot close a case with uncompleted tasks or event') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        } 
    } */
    /*static testMethod void testCheckMendatoryTaskForTheCase2 (){
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='False';
                updatesettings.add(cs);
            }
        }
        Test.startTest();
        update updatesettings; 
        Test.stopTest();
        ID caseRecordType ;
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();
        if(rtMapByName.containsKey('Retention'))
            caseRecordType = rtMapByName.get('Retention').getRecordTypeId();
        //W-000685
        IM_Country__c mainName = new IM_Country__c(Name='United States21');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States21');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States21';
        setting.object_name__c = 'Account';
        insert setting;
        Account acc= new Account();
        acc.name= 'Test Account New';
        acc.BillingCountry = 'United States21';
        acc.BillingPostalCode = '11609';
        acc.BillingState = 'NY';
        acc.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert acc;         
        Contact con = new Contact(AccountId=acc.id ,FirstName = 'Test FirstName Test', LastName = 'test',Phone = '123456', Email='vinod.kumar@metacube.com');
        insert con;
        Case newCase = createCase(caseRecordType);
        //W-000685
        /*  newCase.Authorized_User__c = 'No';
newcase.AccountId = acc.Id;
newCase.ContactId = con.Id; 

//Nandini Mishra:6/3/2022 Start
newCase.Estimated_Pay_Date__c=System.today()+3;
//Nandini Mishra:6/3/2022 End
insert newCase;   
        
        //Task task = GenerateTestData.createTask();
        Task task = new Task();
        task.Subject ='Contact Validated';
        task.Due_Date__c = System.today()+3;
        task.WhoId=con.id;
        insert task;
        task.Mandatory_Task__c = true;
        task.WhatID = newCase.ID;
        update task;
        
        newCase.Status = 'Closed';
        try{
            update newCase;
        }catch(Exception ex){
            //system.assert(ex.getMessage().contains('Date sent to Closure cannot be populated when there are open tasks.
        } 
    } */
    
    static testMethod void testDeleteCases() {
        ID caseRecordType ;
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();
        
        if(rtMapByName.containsKey('Retention'))
            caseRecordType = rtMapByName.get('Retention').getRecordTypeId();
        
        Case newCase = createCase(caseRecordType);
        insert newCase;
        
        Test.startTest();
        delete newCase;
        Test.stopTest();
    }
    /* static testMethod void testValidateDateSentToClosure (){
List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
for(Trigger_Activation_Settings__c cs : customsettings){
if(cs.Object__c == 'Case') {
cs.Value__c='False';
updatesettings.add(cs);
}
}
update updatesettings;
ID caseRecordType ;
Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();

if(rtMapByName.containsKey('Retention'))
caseRecordType = rtMapByName.get('Retention').getRecordTypeId();

IM_Country__c mainName = new IM_Country__c(Name='United States8');
insert mainName;
IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States8');
insert country;
Country_Settings__c setting = new Country_Settings__c();
setting.Name = 'United States8';
setting.object_name__c = 'Account';
insert setting;
Account acc= new Account();
acc.name= 'Test Account New';
acc.BillingCountry = 'United States8';
acc.BillingPostalCode = '11209';
acc.BillingState = 'NY';
acc.IM_Hierarchy_Level__c = 'Sales (Site)';
insert acc; 

Contact con = new Contact(AccountId=acc.id ,FirstName = 'Test FirstName', LastName = 'test',Phone = '123456', Email='vinod.kumar@metacube.com');
insert con;
Case newCase = createCase(caseRecordType);
//insert newCase;
//Task task = GenerateTestData.createTask();
Task task = new Task();
task.Subject ='Contact Validated';
task.Due_Date__c = System.now();
task.WhoId=con.id;
task.WhatId=acc.id;
insert task;

task.WhatID = newCase.ID;
update task;    

newCase.Date_Sent_To_Closures__c = Date.today();
newCase.Retained__c = 'No';

try{
update newCase;
}
catch(exception ex){
//system.assert(ex.getMessage().contains('Date sent to Closure cannot be populated when there are open tasks. Please close all the open activities and then set the date sent to closure'));
}

}  */
    
    /* static testmethod void testCACDateValidationRulesCase(){

List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
for(Trigger_Activation_Settings__c cs : customsettings){
if(cs.Object__c == 'Case') {
cs.Value__c='True';
updatesettings.add(cs);
}
}
update updatesettings;

Map<String,Schema.RecordTypeInfo> rtMapByName = CaseRecordTypeSelection.getRecordTypeIds();
ID caseRecordType ;

if(rtMapByName.containsKey('CAC_SKP_RM'))
caseRecordType = rtMapByName.get('CAC_SKP_RM').getRecordTypeId();

Case newCase1 = createCase(caseRecordType);

newCase1.Contract_Type__c  = 'Standard';
newCase1.Owning_Group__c = 'EAM';
newCase1.Contract_Renewal_Date__c = System.now().AddDays(1);
newCase1.Annual_Revenue__c = 12;  

//newCase1.Date_Inventory_Status_Confirmed__c  = system.now().AddDays(1);
newCase1.Date_Followed_Up_W_Customer__c = system.now();

/*try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Date Inventory status confirmed must be today\'s date'));
} 
newCase1.Date_Inventory_Status_Confirmed__c  = system.now();
/*W-000616
newCase1.Date_Invoice_Created__c = system.now().AddDays(1);

try{
insert  newCase1;
}
catch(Exception ex){
// System.assert(ex.getMessage().contains('Date Invoice Created must be current or past date'));
} 
//newCase1.Date_Invoice_Details_Package_Sent__c  = system.now().AddDays(1);
/*W-000616
newCase1.Date_Invoice_Created__c = system.now();

try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Date Invoice details package sent must be today\'s date'));
} 
newCase1.Date_Invoice_Details_Package_Sent__c  = system.now();

try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date of Audit Approval must be current or past date'));
}   
/*W-000616
newCase1.Date_of_Invoice_Confirmation__c  = system.now().AddDays(1);

try{
insert  newCase1;
}
catch(Exception ex){  
/*W-000616
System.assert(ex.getMessage().contains('Date of Invoice confirmation must be today\'s date'));
} 
/*W-000616
newCase1.Date_of_Invoice_Confirmation__c  = system.now();
newCase1.Date_Ops_Confirmed_For_Timeline__c = system.now().AddDays(1);

try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date Ops confirmed for timeline must be current or past date'));
}


//newCase1.Date_Ops_emailed_for_timeline__c  = system.now().AddDays(1);
newCase1.Date_Ops_Confirmed_For_Timeline__c = system.now();

/* try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date Ops emailed for timeline must be today\'s date'));
}

newCase1.Date_Ops_emailed_for_timeline__c  = system.now();
/*newCase1.Date_PDL_Approval_Received__c = system.now().AddDays(1);        
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date PDL Approval Received must be current or past date'));
}

//newCase1.Date_PDL_Sent_to_Customer__c  = system.now().AddDays(1);
newCase1.Date_PDL_Approval_Received__c = system.now();        
/*try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date PDL Sent to customer must be current'));
} 

newCase1.Date_PDL_Sent_to_Customer__c  = system.now();
/*newCase1.Date_PW_Order_Created__c = system.now().AddDays(1);        
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date PW Order Created must be current or past date'));
} 
/*W-000616
newCase1.Date_PW_SR_Requested__c  = system.now().AddDays(1);
newCase1.Date_PW_Order_Created__c = system.now();        
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date PW SR Requested must be today\'s date'));
}            
/*W-000616
newCase1.Date_PW_SR_Requested__c  = system.now();
newCase1.Date_Revised_Cost_Summary_Sent__c = system.now().AddDays(1);*/        
    /*  try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date revised cost summary sent must be today\'s date'));
} 
/*W-000616
newCase1.Date_Worksheet_Created__c  = system.now().AddDays(1);
newCase1.Date_Revised_Cost_Summary_Sent__c = system.now();       
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date Worksheet Created must be current or past date'));
}
/* W-000616
newCase1.Date_Worksheet_Created__c  = system.now();
newCase1.Invoice_Request_Date__c = system.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Invoice Request Date must be today\'s date'));
} 
/*W-000616
newCase1.Date_Worksheet_Created__c  = system.now().AddDays(1);
newCase1.Invoice_Request_Date__c = system.now();
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date Worksheet Created must be current or past date'));
} 
/*W-000616
newCase1.Date_Worksheet_Created__c  = system.now();
newCase1.Local_Leadership_response_date__c = system.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Local Leadership response date must be current or past date'));
} 

/*newCase1.Notify_Collections__c = system.now().AddDays(1);
/*W-000616
newCase1.Local_Leadership_response_date__c = system.now();
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Notify Collections must be today\'s date'));
}

newCase1.Notify_Collections__c = system.now();
/*newCase1.Order_completion_date__c = system.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Order completion date must be current or past date'));
}       

newCase1.Order_completion_date__c = system.now();
newCase1.Order_Scheduled_date__c = system.now();
/*newCase1.Payment_Confirmation_Date__c = system.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Payment Confirmation Date must be current or past date'));
}
//newCase1.Payment_Follow_Up__c = system.now().AddDays(1);
newCase1.Payment_Confirmation_Date__c = system.now();
/*try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Payment follow up must be today\'s date'));
}
newCase1.Payment_Follow_Up__c = system.now();
/*newCase1.PDL_Follow_up_Date__c = system.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('PDL Follow up Date must be today\'s date'));
}
}*/
    
    
    /*static testmethod void testCACDateValidationRules (){

List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
for(Trigger_Activation_Settings__c cs : customsettings){
if(cs.Object__c == 'Case') {
cs.Value__c='True';
updatesettings.add(cs);
}
}
update updatesettings;

Map<String,Schema.RecordTypeInfo> rtMapByName = CaseRecordTypeSelection.getRecordTypeIds();
ID caseRecordType ;

if(rtMapByName.containsKey('CAC_SKP_RM'))
caseRecordType = rtMapByName.get('CAC_SKP_RM').getRecordTypeId();

Case newCase1 = createCase(caseRecordType);

newCase1.Contract_Type__c  = 'Standard';
newCase1.Owning_Group__c = 'EAM';
newCase1.Contract_Renewal_Date__c = System.now().AddDays(1);
newCase1.Annual_Revenue__c = 12;  
/* W-000616
newCase1.CAC_First_Customer_Contact_Date__c = System.now().AddDays(1);

try{
insert  newCase1;
}
catch(Exception ex){
//System.assert(ex.getMessage().contains('CAC First Customer Contact Date must be today\'s date. It cannot be in the Past or the Future'));
}
/* W-000616
newCase1.CAC_Intro_Date__c = System.now().AddDays(1);
newCase1.CAC_First_Customer_Contact_Date__c = System.now();
try{
insert  newCase1;
}
catch(Exception ex){
//System.assert(ex.getMessage().contains('CAC Intro Date must be today\'s date. It cannot be in the Past or the Future'));
}
/* W-000616
newCase1.CAC_Intro_Date__c = System.now();
newCase1.CAC_Second_Customer_Contact_Date__c = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){
//System.assert(ex.getMessage().contains('CAC Second Customer Contact Date must be today\'s date. It cannot be in the Past or the Future'));
}
/*W-000616
newCase1.CAC_Second_Customer_Contact_Date__c = System.now();
newCase1.CAC_Third_Customer_Contact_Date__c = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){
//System.assert(ex.getMessage().contains('CAC Third Customer Contact Date must be today\'s date. It cannot be in the Past or the Future'));
}
/* W-000616
newCase1.CAC_Third_Customer_Contact_Date__c = System.now();
newCase1.Cost_Summary_Attempt_1__c =  System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){
//System.assert(ex.getMessage().contains('Cost Summary Attempt 1 must be today\'s date. It cannot be in the Past or the Future.'));
}
newCase1.Cost_Summary_Attempt_1__c =  System.now();
newCase1.Cost_Summary_Attempt2__c =  System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Cost Summary Attempt 2 must be today\'s date. It cannot be in the Past or the Future.'));
}        

newCase1.Cost_Summary_Attempt2__c =  System.now();
newCase1.Cost_Summary_Attempt3__c =  System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Cost Summary Attempt 3 must be today\'s date. It cannot be in the Past or the Future.'));
}

newCase1.Cost_Summary_Attempt3__c =  System.now();
/*W-000616
newCase1.Customer_Update_Date__c = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){
//System.assert(ex.getMessage().contains('Customer Update Date must be today\'s date. It cannot be in the Past or the Future'));
}  
/*W-000616
newCase1.Customer_Update_Date__c = System.now();
newCase1.Date_Account_Inactivated__c = system.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Date Account Inactivated must be current or past date.  It cannot be in the Future'));
} 

newCase1.Date_Account_Inactivated__c = system.now();
/* Begin - Case field deletion : 10373
newCase1.Date_Cancelled__c = system.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Date Cancelled must be today\'s date. It cannot be in the Past or the Future'));
} 

newCase1.Date_Cancelled__c = system.now();
try{
insert  newCase1;
}
catch(Exception ex){
//System.assert(ex.getMessage().contains('Date Collections Marks Term Paid must be current or past date.'));
}        
End - Case field deletion : 10373 
newCase1.Date_Customer_Approval_Received__c = system.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Date Customer Approval Received must be current or past date'));
} 

newCase1.Date_Customer_Approval_Received__c = system.now();
//newCase1.Date_Destruction_Order_Created__c = system.now().AddDays(1);

try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Date Destruction Order Created must be current or past date'));
}  
/*W-000616
newCase1.Date_Destruction_SR_Requested__c  = system.now().AddDays(1);
newCase1.Date_Destruction_Order_Created__c = system.now();

try{
insert  newCase1;
}
catch(Exception ex){
//System.assert(ex.getMessage().contains('Date Destruction SR Requested must be today\'s date'));
}
/*W-000616
newCase1.Date_Destruction_SR_Requested__c  = system.now();
//newCase1.Date_Email_Sent_To_Contracts_Admin__c = system.now().AddDays(1);

try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Date email sent to Contracts Admin must be today\'s date'));
}    
/* W-000616
newCase1.Date_Email_Sent_To_Local_Leadership__c  = system.now().AddDays(1);        
//newCase1.Date_Email_Sent_To_Contracts_Admin__c = system.now();

try{
insert  newCase1;
}
catch(Exception ex){
//System.assert(ex.getMessage().contains('Date email sent to Local Leadership must be today\'s date'));
}  

/*W-000616
newCase1.Date_Email_Sent_To_Local_Leadership__c  = system.now();
newCase1.Date_Followed_Up_W_Customer__c = system.now().AddDays(1);

try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Date Followed Up W Customer must be today\'s date'));
} 

} */
    
  /*  static testmethod void testCACDateValidationRules1 (){
        
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='True';
                updatesettings.add(cs);
            }
        }
        update updatesettings; 
        ID caseRecordType ;
        Map<String,Schema.RecordTypeInfo> rtMapByName = CaseRecordTypeSelection.getRecordTypeIds();
        
        if(rtMapByName.containsKey('CAC_SKP_Shred'))
            caseRecordType = rtMapByName.get('CAC_SKP_Shred').getRecordTypeId();        
        //Test.startTest();
        Case newCase1 = createCase(caseRecordType);
        newCase1.Contract_Type__c  = 'Standard';
        newCase1.Owning_Group__c = 'EAM';
        newCase1.Contract_Renewal_Date__c = System.now().AddDays(1);
        newCase1.Annual_Revenue__c = 12;       
        /*newCase1.Date_Final_Order_Created_in_SKP__c  = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){
System.assert(ex.getMessage().contains('Date Final Order created in SKP must be today\'s date.'));
}
        
        newCase1.Date_Final_Order_Created_in_SKP__c  = System.now();
        
        /*W-000616
newCase1.Date_Sent_To_Shared_services__c  = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){      

//System.assert(ex.getMessage().contains('Date Sent to Shared Services must be today\'s date'));
}

newCase1.Date_Service_Confirmation__c  = System.now().AddDays(1);
/*W-000616
newCase1.Date_Sent_To_Shared_services__c  = System.now();
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date Service confirmation must be today\'s date'));
}
        
        newCase1.Date_Service_Confirmation__c  = System.now(); 
        /*newCase1.Date_Service_To_Be_Completed__c  = System.now().AddDays(-1);

try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date Service To Be Completed must be current or future date.'));
}
        
        newCase1.Date_Service_To_Be_Completed__c  = System.now();
        
        /*newCase1.Date_Termination_Request_Sent_Contracts__c  = System.now().AddDays(1);

try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date Termination Request Sent Contracts must be today\'s date'));
}
        
        newCase1.Date_Termination_Request_Sent_Contracts__c  = System.now();
        try{
            insert  newCase1;
        }
        catch(Exception ex){        
            //System.assert(ex.getMessage().contains('Date Visit Profile Inactivated must be today\'s date'));
        }
        
        /*newCase1.Date_Visit_Profile_To_Be_Inactivated__c  = System.now().AddDays(-1);

try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date Visit Profile to be inactivated must be current or future date.'));
}
        
        newCase1.Date_Visit_Profile_To_Be_Inactivated__c  = System.now();
        
        //newCase1.Date_Confirmed_by_Contracts__c  = System.now().AddDays(1);
        newCase1.Rescheduled_Date__c   = System.now();
        /*try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date Confirmed by contracts must be current or Past date'));
}
        
        newCase1.Date_Confirmed_by_Contracts__c  = System.now();
        /*newCase1.Final_Customer_Contact_Date__c = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Final Customer Contact Date must be today\'s date'));
}
        
        if(rtMapByName.containsKey('CAC_DP_Closure'))
            caseRecordType = rtMapByName.get('CAC_DP_Closure').getRecordTypeId();   
        Test.startTest();
        newCase1 = createCase(caseRecordType);
        newCase1.Contract_Type__c  = 'Standard';
        newCase1.Owning_Group__c = 'EAM';
        newCase1.Contract_Renewal_Date__c = System.now().AddDays(1);
        newCase1.Annual_Revenue__c = 12;       
        /*newCase1.Confirm_Final_Service__c   = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Confirm Final Service must be current or past date'));
}*/
        
        //newCase1.Confirm_Final_Service__c = System.now();
        /*newCase1.Date_Closure_Complete__c = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date Closure Complete must be current or past date'));
}*/
        
        /*W-000616
newCase1.Date_Contracts_Respond__c = System.now().AddDays(1);
newCase1.Date_Closure_Complete__c = System.now();
try{
insert  newCase1;
}
catch(Exception ex){        
System.assert(ex.getMessage().contains('Date Contracts Respond must be current or past date'));
}
*/
        
        /*W-000616
newCase1.Date_Contracts_Respond__c = System.now();
//newCase1.Date_Email_Sent_To_Contracts_Admin__c = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date email sent to Ops must be today\'s date'));
}
//newCase1.Date_Email_Sent_To_Contracts_Admin__c = System.now();

newCase1.Date_Final_Service_Order_Created__c = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date Final Service Order Created must be today\'s date'));
} 
        
        
        newCase1.Date_Final_Service_Order_Created__c = System.now();
        
        /*newCase1.Date_Moved_on_Call__c = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date Moved on Call must be today\'s date'));
}
        
        newCase1.Date_Moved_on_Call__c = System.now();    
        
        /*newCase1.Date_Ops_Confirms_SB_Clean__c = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date Ops confirms SB clean must be current or past date'));
}*/
        
        
        /*W-000616
newCase1.Date_Resubmitted_to_Contracts__c = System.now().AddDays(1);
        newCase1.Date_Ops_Confirms_SB_Clean__c = System.now();
        try{
            insert  newCase1;
        }
        catch(Exception ex){        
            //System.assert(ex.getMessage().contains('Date Ops confirms SB clean must be current or past date'));
        }
        
        
        /*W-000616
newCase1.Date_Resubmitted_to_Contracts__c = System.now();
newCase1.Date_Sent_to_Contracts_US__c  = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date Sent to Contracts US must be today\'s date'));
}
        
        newCase1.Date_Sent_to_Ops__c = System.now().AddDays(1);
        /*W-000616
newCase1.Date_Sent_to_Contracts_US__c  = System.now();
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Date sent to Ops must be today\'s date'));
}
        
        newCase1.Date_Sent_to_Ops__c = System.now();      
        newCase1.Date_to_be_Moved_on_Call__c  = System.now();
        try{
            insert  newCase1;
        }
        catch(Exception ex){        
            //System.assert(ex.getMessage().contains('Ops Confirmation Date must be current or past date'));
        }
        
        
        
        /* #8991 Delete 10 case field deletion :- Part 3 "OTO_Created_Date__c" */
        /*newCase1.OTO_Created_Date__c = System.now().AddDays(1);
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('OTO Created Date must be today\'s date'));
}*/
        //newCase1.Update_Sent_To_Operations__c = System.now().AddDays(1);
        /* #8991 Delete 10 case field deletion :- Part 3 "OTO_Created_Date__c" */
        /*newCase1.OTO_Created_Date__c = System.now();
try{
insert  newCase1;
}
catch(Exception ex){        
//System.assert(ex.getMessage().contains('Update Sent To Operations must be today\'s date'));
}
        
        test.stopTest();
        
    } */
    
    
    static testMethod void testInternalCaseTeamTest() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='True';
                updatesettings.add(cs);
            }
        }
        update updatesettings;
        List<User> lUser1 = new List<USer>([Select Id from User where IsActive = true LIMIT 5]);
        
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        User lUser = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
                              emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
                              localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                              timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert lUser; 
        IM_Country__c mainName = new IM_Country__c(Name='United States9');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States9');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States9';
        setting.object_name__c = 'Account';
        insert setting;
        Account A= new Account();
        A.name= 'Test Account New';
        A.BillingCountry = 'United States9';
        A.BillingPostalCode = '11209';
        A.BillingState = 'NY';
        A.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert A;
        
        Opportunity opp = new Opportunity();
        opp.OwnerId = lUser.Id;
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'Renewal';
        opp.Lead_Source_Most_Recent__c = 'Email';
        opp.NCSP_Status__c='Service Scheduled';
        opp.IM_Reason_Lost__c=null;
        opp.Service_Completed_Entered_Date__c=null;
        opp.Billing_Country__c=mainName.id;// Added by Arjun - Billing country required
        // insert the new opp
        insert opp;
        
        Test.startTest();  
        Case c1 = new Case();
        
        system.debug('before case insert');
        c1.OwnerId = lUser.Id;
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: DMS').getRecordTypeId();
        c1.AccountId = A.Id;
        c1.Related_To__c = 'Accounts';
        c1.IM_Employee_Contact__c = lUser.Id;
        c1.Status = 'New';
        c1.NSCP_Case_Creator_Name__c=lUser.Id;
        c1.Origin = 'Web';
        c1.Contract_Status__c = 'Rejected with amendments'; 
        /* newcase.Case_Type__c = 'Other';
newcase.Contract_Type__c = 'Other';
newCase.SOW_Number__c = '4535fasf34';*/
        //c1.Contract_Status__c = 'Rejected';
        c1.Priority = 'Low';
        c1.IM_Division__c = 'Digital';
        c1.Subject = 'Test';
        c1.Description = 'Test';
        c1.NCSP_Opportunity__c = opp.id;
        c1.NCSP_Service_line__c='DB&R';
        insert c1;
        system.debug('NSCP_Case_Creator_Name__c----'+c1.NSCP_Case_Creator_Name__c );
        
        c1.Contract_Status__c = 'Rejected';
        c1.Rejection_Comments__c= 'Not required';
        c1.Primary_Contract_Rejection_Reason__c = 'Done';
        c1.Primary_Contract_Rejection_Reason_Detail__c ='Not required';
        Update c1;    
        Test.stopTest();
        
    } 
    
    
    static testMethod void testIMNA_InternalCaseTeamTest() {
        List<Trigger_Activation_Settings__c> customsettingsnew = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettingsnew = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c tcs : customsettingsnew){
            if(tcs.Object__c == 'Case') {
                tcs.Value__c='True';
                updatesettingsnew.add(tcs);
            }
        }
        update updatesettingsnew;
        Test.startTest();  
        Case cas = new Case();
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        User lUser = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
                              emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
                              localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                              timezonesidkey='America/New_York', username='srinuty565.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert lUser; 
        
        User lUser1 = new User(alias = 'Test', email='TestOrg@testorg.com',
                               emailencodingkey='UTF-8', lastname='Test Name1', languagelocalekey='en_US',
                               localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                               timezonesidkey='America/New_York', username='Testyhjyj123Org@testorg.com', CurrencyIsoCode='USD');
        insert lUser1; 
        
        
        //List<User> lstUser = new List<USer>([Select Id from User where IsActive = true LIMIT 5]);
        IM_Country__c mainName = new IM_Country__c(Name='United States10');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States10');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States10';
        setting.object_name__c = 'Account';
        insert setting;
        Account acc= new Account();
        acc.name= 'Test Account New';
        acc.BillingCountry = 'United States10';
        acc.BillingPostalCode = '11209';
        acc.BillingState = 'NY';
        acc.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert acc; 
        system.debug('before case insert');
        cas.OwnerId = lUser.Id;
        cas.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IM Customer Data Management (CDM)').getRecordTypeId();
        cas.AccountId = acc.Id;
        cas.Related_To__c = 'Accounts';
        cas.IM_Employee_Contact__c = lUser1.Id;
        cas.Status = 'New';
        cas.Origin = 'NAS_EMAIL';
        cas.NSCP_Case_Creator_Name__c=lUser.Id;
        cas.Priority = 'Low';
        cas.IM_Division__c = 'IME';
        cas.Subject = 'Test';
        cas.Description = 'Test';
        insert cas;
        
        system.debug('NSCP_Case_Creator_Name__c----'+cas.NSCP_Case_Creator_Name__c );
        
        cas.IM_Employee_Contact__c = lUser.Id;
        update cas;
        
        
        cas.IM_Employee_Contact__c = lUser1.Id;
        update cas;
        
        Test.stopTest();
        
    }
    
    
    
    // Function to test NonRecuringCase
    
    static testMethod void TestUpdateSlaDaysSlaTargetDateForNonRecuringCase() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='True';
                updatesettings.add(cs);
            }
        }
        update updatesettings;
        
        // TO DO: implement unit test
        triggerFlowControl.setControlEnabled(false);
        //Making test data        
        // insert sla matrix record
        
        SLA_Matrix__c  sla = new SLA_Matrix__c();
        sla.SLA_Days__c = 2.0;
        sla.Type__c = 'xyz';
        sla.Case_Subtype__c ='xyz';
        sla.Record_Type__c = 'Retention';
        sla.CurrencyIsoCode = 'USD';        
        insert sla;
        Case newcase = NewCreateCase();
        
        
        newcase.SLA_Days__c =2.0;
        newcase.Type ='xyz';
        newCase.Is_Cloned__c = false;
        newCase.Recurring_Frequency__c = null;
        newCase.Initial_Due_Date__c = null;
        newCase.IM_Case_Sub_Type__c = 'xyz';
        insert newCase;
        //Case insertedcase = [select id , SLA_Days__c from case where id=:newcase.id limit 1];       
        system.assertEquals(newCase.SLA_Days__c,2.0);        
        // Update case
        sla.Case_Subtype__c ='TexIdTest';
        sla.SLA_Days__c = 5.0;
        update sla;
        //SLA_Matrix__c updatedSla = [select id,Case_Subtype__c,SLA_Days__c from SLA_Matrix__c where id = :sla.id];
        newCase.IM_Case_Sub_Type__c = 'TexIdTest';
        update newcase;
        //insertedcase = [select id , SLA_Days__c,IM_Case_Sub_Type__c from case where id=:newcase.id limit 1];
        system.assertEquals(newcase.SLA_Days__c,2.0);
        // Convert non recuring case into recuring
        List<Holiday__c> lstHDay = [Select id, Holiday_Date__c from Holiday__c where Holiday_Date__c >=:Date.today()  ];
        Date todayDate = System.today();
        DateTime notHoliday =  DateTime.newInstance(todayDate.year(), todayDate.month(), todayDate.day()).adddays(20);
        for(Holiday__c hDay :lstHDay){
            boolean  isWeekEnd = false;
            if(notHoliday.format('EEEE') == 'Saturday' || notHoliday.format('EEEE') == 'Sunday'){
                isWeekEnd = true;
            }           
            if(hDay.Holiday_Date__c != notHoliday.date() && !isWeekEnd){
                break ;
            }
            else{
                notHoliday = notHoliday.adddays(2);
            }
        }
        newCase.Recurring_Frequency__c = 'Daily';
        //W-000685
        newCase.Initial_Due_Date__c = notHoliday.date(); 
        newCase.SLA_Days__c =0.0;
        newCase.Recurring_Case__c = true;  
        update newCase;
        
    }
    
    // Function to test RecuringCase
    static testMethod void TestUpdateSlaDaysSlaTargetDateForRecuringCase() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='True';
                updatesettings.add(cs);
            }
        }
        update updatesettings;
        
        // TO DO: implement unit test
        triggerFlowControl.setControlEnabled(false);
        
        //Making test data      
        
        Case newRecCase = NewCreateCase();
        newRecCase.SLA_Days__c =0.0;
        newRecCase.Is_Cloned__c = true; 
        
        
        insert newRecCase;
        
        newRecCase.Recurring_Case__c = true;
        newRecCase.Recurring_Frequency__c = 'Daily';
        newRecCase.Initial_Due_Date__c = Date.today();
        
        
        Holiday__c hDay = [Select id from Holiday__c where Holiday_Date__c =:Date.today() Limit 1 ];
        boolean  isWeekEnd = false;
        if(DateTime.now().format('EEEE') == 'Saturday' || DateTime.now().format('EEEE') == 'Sunday'){
            isWeekEnd = true;
        }
        
        if(hDay != null || isWeekEnd){           
            
            /* try{
insert newRecCase;
}
catch(Exception e){             
system.assert(e.getMessage().contains('The initial due date you entered falls on a market holiday'),'The initial due date you entered falls on a market holiday');
}
*/
            
            
            //newRecCase.Initial_Due_Date__c = Date.today().adddays(1);
            //
            List<Holiday__c> lstHDay = [Select id, Holiday_Date__c from Holiday__c where Holiday_Date__c >=: Date.today().adddays(1)  ];
            
            DateTime notHoliday =  DateTime.newInstance(2019, 5, 2).addDays(1);
            while(true){
                if(notHoliday.format('EEEE') != 'Saturday' && notHoliday.format('EEEE') != 'Sunday'){               
                    break;
                }
                notHoliday = notHoliday.adddays(1);
            }
            for(Holiday__c hhDay :lstHDay){
                isWeekEnd = false;
                if(notHoliday.format('EEEE') == 'Saturday' || notHoliday.format('EEEE') == 'Sunday'){
                    isWeekEnd = true;
                }           
                if(hhDay.Holiday_Date__c != notHoliday.date() && !isWeekEnd){
                    break ;
                }
                else{
                    notHoliday = notHoliday.adddays(1);
                }
            }
            
            newRecCase.Initial_Due_Date__c = notHoliday.date(); 
            
            try{
                update newRecCase;
            }
            catch(Exception e){  }
            
        }
        else
        {
            insert newRecCase;
        }
        
        date today= date.today();
        newRecCase.Recurring_Frequency__c = 'Weekly';
        newRecCase.Initial_Due_Date__c = today.addDays(1);
        
        
        
        CaseComment cComment = new CaseComment();
        cComment.ParentId =  newRecCase.id;
        cComment.CommentBody = 'TestCase';
        insert  cComment;                
        newRecCase.Status = 'Closed';
        newRecCase.Close_Reason__c = 'Completed'; 
        newRecCase.Reason__c = 'Completed';   
        
        RecordTypeSelection.isCloned=false;                  
        try{
            update newRecCase;
        }
        catch(Exception e){             
        }
        //
        List<case> lstCase = new list<case>();
        lstCase.add(newRecCase);
        UtilUpdateSladaysAndSlaTargetDate.GetSlaTargetDateForClonedCase(lstCase);
        // Convert recurring case into non recurring
        SLA_Matrix__c  sla = new SLA_Matrix__c();
        sla.SLA_Days__c = 2.0;
        sla.Type__c = 'xyz1';
        sla.Case_Subtype__c ='xyz1';
        sla.Record_Type__c = 'Retention';
        sla.CurrencyIsoCode = 'USD';        
        insert sla;
        newRecCase.SLA_Days__c =0.0;
        newRecCase.Type ='xyz1';
        newRecCase.Is_Cloned__c = false;
        newRecCase.Recurring_Frequency__c = null;
        newRecCase.Initial_Due_Date__c = null;
        newRecCase.IM_Case_Sub_Type__c = 'xyz1';
        newRecCase.Recurring_Case__c = false;
        newRecCase.Status = 'New';
        update newRecCase;
        //Case insertedcase = [select id , SLA_Days__c from case where id=:newRecCase.id limit 1];       
        system.assertEquals(newRecCase.SLA_Days__c,0.0);          
    }
    public static Case NewCreateCase(){
        Test.startTest();
        ID caseRecordType;
        ID accountRecordType;
        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account'];
        
        if(lstRecordType.size() > 0){
            
            accountRecordType = lstRecordType[0].ID;
            
        }
        List<RecordType> lstRecordType2 =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Case' and name = 'Retention']; //Check
        
        if(lstRecordType2.size() > 0){
            caseRecordType = lstRecordType2[0].ID;
        }
        
        Holiday__c hday = new Holiday__c();
        hday.Holiday_Date__c = Date.today();
        hday.Name = 'testHoliday';
        hday.OwnerId = userInfo.getUserId();
        insert hday;
        
        Holiday_Schedule__c hSchedule = new Holiday_Schedule__c ();
        hSchedule.Name ='TestHoloiday';
        hSchedule.OwnerId = UserInfo.getUserId();
        insert hSchedule;
        
        Market__c mkt = new Market__c();
        mkt.Holiday_Schedule__c = hSchedule.id;
        mkt.District_NAME__c = 'TestDistrict';
        mkt.Owning_District_Id__c = 'TestOwningDistrictId';
        insert mkt;
        
        Holiday_Schedule_Line__c hSLine = new Holiday_Schedule_Line__c();
        hSLine.Holiday__c =  hday.id;
        hSLine.Holiday_Schedule__c = hSchedule.id;
        hSchedule.Name ='TestHLine';
        hSchedule.OwnerId = userinfo.getUserId();
        insert hSLine;        
        //RecordTypeId =accountRecordType, 
        IM_Country__c mainName = new IM_Country__c(Name='United States5');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States5');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States5';
        setting.object_name__c = 'Account';
        insert setting;
        Account acc = new Account();
        acc.Name = 'Test Account New';
        acc.BillingCountry = 'United States5';
        acc.BillingPostalCode = '11209';
        acc.BillingState = 'NY';
        acc.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert acc;      
        //Account acc = new Account(Name = 'eotuer'+system.now(),);
        //insert acc;
        //W-000685         
        Contact con = new Contact(AccountId=acc.id ,FirstName = 'Test FirstName', LastName = 'test',Phone = '123456', Email='vinod.kumar@metacube.com');
        insert con;
        IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
        custAcc.Name = 'Test cust account';
        custAcc.IM_Customer_Account_Name__c = 'Test Account Name';
        custAcc.IM_District_Branch_Id__c = '101';
        custAcc.IM_Source_System_Code__c = 'Test';
        custAcc.Owning_District_Id__c = mkt.Id;
        custAcc.IM_Account__c = acc.id;
        custAcc.Source_System__c = 'SB NA';
        insert custAcc;        
        // Create 
        Case newCase = new Case();
        
        String usrId = UserInfo.getUserId();
        newCase.OwnerId = usrId;
        newCase.RecordTypeId = caseRecordType;
        newCase.AccountId = acc.Id;
        newCase.Customer_ID__c = custAcc.Id;
        newCase.ContactId = con.Id;
        newCase.Origin = 'Email';                     
        newCase.Subject = 'Test';
        newCase.Description = 'Test';
        newCase.Priority = 'Normal';
        newCase.Status = 'New';
        newCase.Is_Cloned__c = true;
        newCase.Recurring_Case__c = false;
        newCase.SLA_Days__c =1;
        DateTime dtInitialTargetDate = DateTime.now();
        newCase.Initial_Due_Date__c = dtInitialTargetDate.date();
        newCase.SLA_Target_Date__c = dtInitialTargetDate;
        Test.stopTest();
        return newCase;
    }
    
   /* static testMethod void Test_NCSPDateValidationRulesTrigger1() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='False';
                updatesettings.add(cs);
            }
        }
        update updatesettings;
        
        // TO DO: implement unit test
        ID caseRecordType1 ;
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds(); 
        
        if(rtMapByName.containsKey('NCSP: DMS'))
            caseRecordType1 = rtMapByName.get('NCSP: DMS').getRecordTypeId();
        
        Case newCase = createCase(caseRecordType1);
        
        // #04
        /*newCase.Date_On_Boarder_CSA_Assigned__c = DateTime.now().addDays(-1);
try{
System.debug('22222');
insert  newCase;
}
catch(Exception ex){
System.debug('1Message: ' + ex.getMessage());
System.assertEquals(ex.getTypeName(), 'System.DmlException');
}
        // #05
        newCase.Date_On_Boarder_CSA_Assigned__c = DateTime.now();
        /*newCase.Date_Welcome_Call_Attempt_1__c = DateTime.now().addDays(-1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('2Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #06
        newCase.Date_Welcome_Call_Attempt_1__c = DateTime.now();
        /*newcase.Date_Welcome_Call_Attempt_2__c = DateTime.now().addDays(-1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('3Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #07
        newCase.Date_Welcome_Call_Attempt_3__c = DateTime.now().addDays(-1);
        newcase.Date_Welcome_Call_Attempt_2__c = DateTime.now();
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('4Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #08
        newCase.Date_Welcome_Call_Attempt_3__c = DateTime.now();
        newcase.Date_welcome_call_completed__c = DateTime.now().addDays(-1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('5Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #09
        newCase.Date_welcome_call_completed__c = DateTime.now();
        newcase.IMC_Login_sent_to_customer__c = DateTime.now().addDays(-1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('6Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #10
        newCase.IMC_Login_sent_to_customer__c = DateTime.now();
        newcase.IMC_Setup_Date__c = DateTime.now().addDays(-1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('7Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #11
        newCase.IMC_Setup_Date__c = DateTime.now();
        newcase.Initial_Supply_Order_Date__c = DateTime.now().addDays(-1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('8Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #12
        newCase.Initial_Supply_Order_Date__c = DateTime.now();
        newcase.Rejected_Contract_Resubmission_Date__c = DateTime.now().addDays(-1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('9Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #13
        newCase.Rejected_Contract_Resubmission_Date__c = DateTime.now();
        newcase.Service_Completion_Date__c = DateTime.now().addDays(2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('10Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #14
        newCase.Service_Completion_Date__c = DateTime.now();
        newcase.Service_Order_Date__c = DateTime.now().addDays(2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('11Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #15
        newCase.Service_Order_Date__c = DateTime.now();
        newcase.Service_Schedule_Date__c = DateTime.now().addDays(-2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('12Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
            
        }
        // #16
        newCase.Service_Schedule_Date__c = DateTime.now().addDays(2);
        newcase.Date_Shred_Visit_Profile_Created__c = DateTime.now().addDays(-2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('13Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #17
        
        newcase.Date_Shred_Visit_Profile_Created__c = DateTime.now();
        newcase.Transition_Date__c = DateTime.now().addDays(2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('14Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
            
        }
        // #18
        newCase.Transition_Date__c = DateTime.now();
        newcase.Welcome_Packet_Sent_Date__c = DateTime.now().addDays(2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Welcome_Packet_Sent_Date__c :'+ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        newcase.Welcome_Packet_Sent_Date__c = DateTime.now();
        
        // #20
        // #8990 Delete 11 case field deletion :- Part 2 "cid_request_date__c"
        //newCase.CID_Request_Date__c = DateTime.now();
        newcase.Date_Contract_Signed__c = DateTime.now().addDays(2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Date_Contract_Signed__c'+ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        
        // #22
        //newCase.Date_Paperwork_Received__c = DateTime.now().addDays(2);
        newcase.Date_Contract_Signed__c = DateTime.now().addDays(-2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Date_Paperwork_Received__c'+ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #23
        newCase.Date_Paperwork_Received__c = DateTime.now();
        newcase.Date_Reviewed_Ncsp__c = DateTime.now().addDays(2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Date_Reviewed_Ncsp__c'+ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        
        // #27
        newCase.Service_Reschedule_Date__c = DateTime.now().addDays(-2);
        newcase.Date_Reviewed_Ncsp__c = DateTime.now();
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Date_Contract_Signed__c'+ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #28
        newCase.Service_Reschedule_Date__c = DateTime.now();
        //newcase.Supplies_Delivered_Date__c = DateTime.now().addDays(2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Supplies_Delivered_Date__c'+ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #29
        newCase.Supplies_Scheduled_Date__c = DateTime.now().addDays(-2);
        newcase.Supplies_Delivered_Date__c = DateTime.now();
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Supplies_Scheduled_Date__c'+ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #30
        newCase.Supplies_Scheduled_Date__c = DateTime.now();
        //#8977 Delete 11 NCSP case field deletion (6/3/2022) :- Part 1 "Supply_Reschedule_Date__c" commented by Nandini Mishra to remove field dependency for this field
        /* newcase.Supply_Reschedule_Date__c = DateTime.now().addDays(-2);
try{
insert  newCase;
}
catch(Exception ex){

// system.debug('Supply_Reschedule_Date__c'+ex.getMessage());
System.assertEquals(ex.getTypeName(), 'System.DmlException');
} 
        //#8977 Delete 11 NCSP case field deletion (6/3/2022) :- Part 1 "Supply_Reschedule_Date__c" commented by Nandini Mishra to remove field dependency for this field
        // newcase.Supply_Reschedule_Date__c = DateTime.now();
        newcase.Contract_Status__c = 'Accepted'; // Re Review
        newcase.Case_Type__c = 'Other';
        newcase.Contract_Type__c = 'Other';
        newCase.SOW_Number__c = '4535fasf34';
        Update newcase;
        
    } */
  /*  static testMethod void Test_NCSPDateValidationRulesTrigger2() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='False';
                updatesettings.add(cs);
            }
        }
        update updatesettings;
        ID caseRecordType2 ;
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();
        
        if(rtMapByName.containsKey('NCSP: SKP New Customer Setup'))
            caseRecordType2 = rtMapByName.get('NCSP: SKP New Customer Setup').getRecordTypeId();
        
        Case newCase = createCase(caseRecordType2);
        // #01
         newCase.X2nd_Sales_Resubmission_Date__c = DateTime.now().addDays(1);
try{
insert newCase;
}
catch(Exception ex){
System.debug('15Message: ' + ex.getMessage());
System.assertEquals(ex.getTypeName(), 'System.DmlException');
} 
        // #02
        
        //newCase.Contract_Admin_Response_Date__c = DateTime.now();
        //newCase.Date_Sent_to_Contracts_Admin__c = DateTime.now().addDays(1);
        //newCase.Date_On_Boarder_CSA_Assigned__c = DateTime.now().addDays(1);
        newcase.Contract_Status__c = 'Rejected with amendments'; // Nandini 14409
        newcase.Case_Type__c = 'Other';
        newcase.Contract_Type__c = 'Other';
        newCase.SOW_Number__c = '4535fasf34';
        insert newcase;//Nandini 14409
        
        try{
            insert  newCase;
        }
        catch(Exception ex){
            //System.assert(ex.getMessage().contains('Date Sent to Contracts Admin must be a current date only (cannot be a past or future)'));
            System.debug('16Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        newCase.Date_Contract_Approved__c = DateTime.now().addDays(1);
        newCase.Date_Sent_to_Contracts_Admin__c = DateTime.now();
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('17 Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // End of changes made by vinod for PR-08567
        // #21
        newCase.Date_Contract_Approved__c = DateTime.now();
        //newCase.Contract_Admin_Status__c = 'Research';
        //newCase.Date_Contracts_CSA_Assigned__c = DateTime.now().addDays(-1);
        newCase.NCSP_CSA__c = UserInfo.getUserId();
        
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('18Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #24
        //newCase.Sales_Resubmission_Date__c = DateTime.now().addDays(1);
        newCase.Date_Contracts_CSA_Assigned__c = DateTime.now();
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('19Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        system.debug('queries used in NCSP:'+Limits.getQueries());
        
        
    }*/
    /*static testMethod void NCSPDateValidation3() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='False';
                updatesettings.add(cs);
            }
        }
        update updatesettings;
        IM_Customer_Account__c custAcc = createCustomerAccount('101' , 'Test');
        ID caseRecordType3,caseRecordType ;
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();
        
        if(rtMapByName.containsKey('NCSP: New Customer Setup'))
            caseRecordType3 = rtMapByName.get('NCSP: New Customer Setup').getRecordTypeId();
        
        Case newCase = GenerateTestData.createCaseObjectWithoutInsert(caseRecordType3 , custAcc);
        // #25
        newCase.SecureSync_Setup_Date__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('20Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        // #26
        newCase.SecureSync_Setup_Date__c = DateTime.now();
        newCase.SecureSync_Training_Completed__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('21Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        
        Billing_Cut_Off_Schedule__c bcos = new Billing_Cut_Off_Schedule__c();
        
        bcos.Billing_Cut_Off_Date__c = Date.today();
        bcos.Invoice_Mailing_Date__c = Date.today();
        bcos.Service_Line__c ='test';
        bcos.Name='test1';
        bcos.Year__c = '2014';
        insert bcos;
        
        newCase.SecureSync_Training_Scheduled__c = DateTime.now();
        //insert newCase;
        if(rtMapByName.containsKey('NCSP: SKP Department Add Only'))
            caseRecordType = rtMapByName.get('NCSP: SKP Department Add Only').getRecordTypeId();
        newCase.RecordTypeId = caseRecordType;
        //Case newCase1 = GenerateTestData.createCaseObjectWithoutInsert(caseRecordType , custAcc);
        // #22 Updated for Dept add only
        //newCase.Date_Paperwork_Received__c = DateTime.now().addDays(2);        
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('22Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        newCase.Date_Paperwork_Received__c = DateTime.now();     
        update newCase;
        
    } */    
   /* static testMethod void NCSPDateValidation4() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='False';
                updatesettings.add(cs);
            }
        }
        update updatesettings;
        ID caseRecordType4 ;
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();
        
        if(rtMapByName.containsKey('NCSP: Tech Services New Customer Setup'))
            caseRecordType4 = rtMapByName.get('NCSP: Tech Services New Customer Setup').getRecordTypeId();
        
        Test.startTest();
        Case newCase = createCase(caseRecordType4);
        // #25
        /*  newCase.X2nd_Sales_Resubmission_Date__c = DateTime.now().addDays(1);
try{
insert  newCase;
}
catch(Exception ex){
system.debug('X2nd_Sales_Resubmission_Date__c'+ex.getMessage());
System.assertEquals(ex.getTypeName(), 'System.DmlException');
} 
        
        
        newCase.Date_Sent_to_Contracts_Admin__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Date_Sent_to_Contracts_Admin__c'+ex.getMessage());
            //System.assert(ex.getMessage().contains('Date Sent to Contracts Admin must be a current date only (cannot be a past or future)'));
            System.assertEquals(ex.getTypeName(),'System.DmlException');
        }
        
        newCase.Date_Sent_to_Contracts_Admin__c = DateTime.now();
        newCase.Date_Contract_Approved__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Date_Contract_Approved__c: '+ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
            
        }
        
        newCase.Date_Contract_Approved__c = DateTime.now();
        /*newCase.Date_Welcome_Call_Attempt_1__c = DateTime.now().addDays(2);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('23Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        
        newCase.Date_Welcome_Call_Attempt_1__c = DateTime.now();
        /*newCase.Date_Welcome_Call_Attempt_2__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('24Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        
        // Date Welcome Call Attempt 2 must be today's date. It cannot be in the Past or the Future.
        
        newCase.Date_Welcome_Call_Attempt_2__c = DateTime.now();
        /*newCase.Date_Welcome_Call_Attempt_3__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Date_Welcome_Call_Attempt_3__c'+ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        
        newCase.Date_Welcome_Call_Attempt_3__c = DateTime.now();
        /*newCase.Date_welcome_call_completed__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            system.debug('Date_welcome_call_completed__c'+ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        
        newCase.Date_welcome_call_completed__c = DateTime.now();
        /*newCase.Transition_Date__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('25Message: ' + ex.getMessage());
            System.assertEquals(ex.getTypeName(), 'System.DmlException');
        }
        
        newCase.Transition_Date__c = DateTime.now();
        /*newCase.Welcome_Packet_Sent_Date__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('26Message: ' + ex.getMessage());
            //   System.assert(ex.getMessage().contains('Welcome Packet Sent Date must be today\'s date. It cannot be in the Past or the Future')); 
        }
        
        newCase.Welcome_Packet_Sent_Date__c = DateTime.now();
        /*newCase.Date_Contract_Signed__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('27Message: ' + ex.getMessage());
            //    System.assert(ex.getMessage().contains('Date Contract Signed cannot be a date in the Future.'));
        }
        
        newCase.Date_Contract_Signed__c = DateTime.now();
        /*newCase.Date_Contracts_CSA_Assigned__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('28Message: ' + ex.getMessage());
            //    System.assert(ex.getMessage().contains('Date Contracts CSA Assigned cannot be a date in the past.'));
        }
        
        newCase.Date_Contracts_CSA_Assigned__c = DateTime.now();
        /*newCase.Date_Reviewed_Ncsp__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('29Message: ' + ex.getMessage());
            //    System.assert(ex.getMessage().contains('Date Reviewed - NCSP must be today\'s date.  It cannot be in the Past or the Future.'));
        }
        
        newCase.Date_Reviewed_Ncsp__c = DateTime.now();
        /*newCase.Sales_Resubmission_Date__c = DateTime.now().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('30Message: ' + ex.getMessage());
            //   System.assert(ex.getMessage().contains('Sales Resubmission Date cannot be a date in the Future.'));
        }
        
        // newCase.Sales_Resubmission_Date__c = DateTime.now();
        //newCase.Date_1st_Restricted_Party_Screening__c = date.today().addDays(1);
        /*try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('31Message: ' + ex.getMessage());
            //    System.assert(ex.getMessage().contains('Date 1st Restricted Party Screening Date cannot be a date in the Future.'));
        }
        
        //newCase.Date_1st_Restricted_Party_Screening__c = date.today();
        // newCase.Date_2nd_Restricted_Party_Screening__c = date.today().addDays(1);
        /*try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('32Message: ' + ex.getMessage());
            //    System.assert(ex.getMessage().contains('Date 2nd Restricted Party Screening Date cannot be a date in the Future.'));
        }
        
        // newCase.Date_2nd_Restricted_Party_Screening__c = date.today();
        newCase.Date_Order_Fulfillment_Sent__c = date.today().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('33Message: ' + ex.getMessage());
            //    System.assert(ex.getMessage().contains('Date Order Fulfillment Sent Date cannot be a date in the Past or Future.'));
        }
        
        newCase.Date_Order_Fulfillment_Sent__c = date.today();
        //newCase.Date_2nd_Order_Fulfillment_Sent__c =date.today().addDays(1);
        /*try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('34Message: ' + ex.getMessage());
            //   System.assert(ex.getMessage().contains('Date 2nd Order Fulfillment Sent Date cannot be a date in the Future.'));
        }
        
        //newCase.Date_2nd_Order_Fulfillment_Sent__c = date.today();
        newCase.Date_Confirmation_Fulfillment_Received__c = date.today().addDays(1);
        try{
            insert  newCase;
        }
        catch(Exception ex){
            System.debug('35Message: ' + ex.getMessage());
            // System.assert(ex.getMessage().contains('Date Confirmation Fulfillment Received Date cannot be a date in the Future.'));
        }
        
        Test.stopTest();
        
    } */
    
    /*commented as part of user story #27072
    static testMethod void Test_UpdateNCSPStatus() {
        
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
            if(cs.Object__c == 'Case') {
                cs.Value__c='False';
                updatesettings.add(cs);
            }
        }
        update updatesettings;
        
        //Seeting up test data
        
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        //Create a new User
        User U = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
                          emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert U; 
        
        //Create a new Account
        IM_Country__c mainName = new IM_Country__c(Name='United States11');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States11');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States11';
        setting.object_name__c = 'Account';
        insert setting;
        Account A= new Account();
        A.name= 'Test Account New';
        A.BillingCountry = 'United States11';
        A.BillingPostalCode = '11209';
        A.BillingState = 'NY';
        A.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert A;  
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.OwnerId = U.Id;
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'Renewal';
        opp.Lead_Source_Most_Recent__c = 'Email';
        opp.NCSP_Status__c='Custom Setup';
        opp.Billing_Country__c=mainName.id;// Added by Arjun - Billing country required
        // insert the new opp
        insert opp;
        System.debug('----2282---queries used: ' + Limits.getQueries());
        
        Billing_Cut_Off_Schedule__c bcos = new Billing_Cut_Off_Schedule__c();
        
        bcos.Billing_Cut_Off_Date__c = Date.today();
        bcos.Invoice_Mailing_Date__c = Date.today();
        bcos.Service_Line__c ='test';
        bcos.Name='test1';
        bcos.Year__c = '2014';
        insert bcos;
        
        Case c1 = new Case();        
        system.debug('-----before case insert'); 
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: SKP Department Add Only').getRecordTypeId();
        c1.OwnerId = U.Id;        
        c1.AccountId = A.Id;
        c1.NCSP_Service_line__c='DMS';
        c1.Status = 'New';
        c1.Origin = 'Web';
        c1.Priority = 'Low';
        c1.IM_Division__c = 'Digital';
        c1.Subject = 'Test';
        c1.Description = 'Test';
        c1.Sales_Person_Name_Account_Manager__c = U.Id;
        c1.Setup_Type__c='Standard';
        c1.Date_Paperwork_Received__c=System.Now();
        c1.Transition_Date__c=System.now();   
        c1.NCSP_Opportunity__c= opp.Id;
        c1.Contract_Status__c = 'Rejected'; // Nandini 14409
        c1.Case_Type__c = 'Other';
        c1.Contract_Type__c = 'Other';
        c1.SOW_Number__c = '4535fasf34';
        date sysToday = date.today();
        c1.Service_Schedule_Date__c=null;//Nandini 14409
        
        
        //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Service_Order_Required__c"
        //c1.Service_Order_Required__c = 'No';
        //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Reason_No_Service__c" 
        //c1.Reason_No_Service__c = 'Local Market Handling';   
        insert c1;
        
        Opportunity updatedOpp = [Select Id, NCSP_Status__c From Opportunity Where Id=: opp.Id];
        //System.assertEquals('Local Market Handling', updatedOpp.NCSP_Status__c);
        System.debug('---2307---updatedOpp.NCSP_Status__c:'+updatedOpp.NCSP_Status__c);
        test.startTest();
        //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Service_Order_Required__c"
        // c1.Service_Order_Required__c = 'No';
        //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Reason_No_Service__c"
        //c1.Reason_No_Service__c = 'Special Projects';        
        update c1;
        Opportunity updatedOpp2 = [Select Id, NCSP_Status__c From Opportunity Where Id=: opp.Id];
        //System.assertEquals('Special Projects', updatedOpp.NCSP_Status__c);
        test.stopTest(); 
    }*/ //commented as part of user story #27072
    
    /*static testMethod void Test_CAC_DP_Closure() {
        
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        //Create a new User
        User U = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
                          emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert U; 
        
        //Create a new Account
        IM_Country__c mainName = new IM_Country__c(Name='United States6');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States6');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States6';
        setting.object_name__c = 'Account';
        insert setting;
        Account A= new Account();
        A.name= 'Test Account New';
        A.BillingCountry = 'United States6';
        A.BillingPostalCode = '11209';
        A.BillingState = 'NY';
        A.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert A;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.OwnerId = U.Id;
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'Renewal';
        opp.Lead_Source_Most_Recent__c = 'Email';
        opp.NCSP_Status__c='Custom Setup'; 
        opp.Billing_Country__c=mainName.id;// Added by Arjun - Billing country required
        // insert the new opp
        insert opp;
        System.debug('----2282---queries used: ' + Limits.getQueries());
        
        test.startTest();
        Case c1 = new Case();        
        system.debug('-----before case insert'); 
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CAC_SKP_RM').getRecordTypeId();
        c1.OwnerId = U.Id;        
        c1.AccountId = A.Id;
        c1.NCSP_Service_line__c='DMS';
        c1.Status = 'New';
        c1.Origin = 'Web';
        c1.Priority = 'Low';
        c1.IM_Division__c = 'Digital';
        c1.Subject = 'Test';
        c1.Description = 'Test';
        c1.Sales_Person_Name_Account_Manager__c = U.Id;
        c1.Setup_Type__c='Standard';
        c1.Date_Paperwork_Received__c=System.Now();
        c1.Transition_Date__c=System.now();   
        c1.NCSP_Opportunity__c= opp.Id;
        //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Service_Order_Required__c"
        //c1.Service_Order_Required__c = 'No';
        //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Reason_No_Service__c"
        //c1.Reason_No_Service__c = 'Local Market Handling';   
        
        Date dtToday = Date.today();
        Date dtTomo = dtToday.addDays(1);
        Date dtYest = dtToday.addDays(-1);
        /* W-000616
c1.CAC_First_Customer_Contact_Date__c = dtTomo;
c1.CAC_Intro_Date__c = dtTomo;
c1.CAC_Second_Customer_Contact_Date__c = dtTomo;
c1.CAC_Third_Customer_Contact_Date__c = dtTomo;*/
        //c1.Cost_Summary_Attempt_1__c = dtTomo;
        //c1.Cost_Summary_Attempt2__c = dtTomo;
        //c1.Cost_Summary_Attempt3__c = dtTomo;
        /*W-000616
c1.Customer_Update_Date__c = dtTomo;*/
        //c1.Date_Account_Inactivated__c = dtTomo;
        /* Begin - Case field deletion : 10373
c1.Date_Cancelled__c = dtTomo;
End - Case field deletion : 10373 */
        //c1.Date_Customer_Approval_Received__c = dtTomo;
        /*W-000616
c1.Date_Destruction_SR_Requested__c = dtTomo;*/
        //c1.Date_Destruction_Order_Created__c = dtTomo;
        /*W-000616
c1.Date_Email_Sent_To_Local_Leadership__c = dtTomo;*/
        //c1.Date_Followed_Up_W_Customer__c = dtTomo;
        //c1.Date_Inventory_Status_Confirmed__c = dtTomo;
        /*W-000616
c1.Date_Invoice_Created__c = dtTomo;*/
        //c1.Date_Invoice_Details_Package_Sent__c = dtTomo;
        /*W-000616
c1.Date_of_Invoice_Confirmation__c = dtTomo;
        //c1.Date_Ops_Confirmed_For_Timeline__c = dtTomo;
        
        c1.Confirm_Final_Service__c = dtTomo;
        /* W-000616
c1.Date_Owner_Established__c = dtTomo;

        c1.Date_Closure_Complete__c = dtTomo;
        //c1.Order_Scheduled_date__c = dtYest;
        //c1.Customer_Request_Received_Date__c = dtTomo;
        /* W-000616
c1.Date_Sent_To_Closures__c = dtTomo;
        c1.CAC_Inactivate_Request__c = dtTomo;
        //c1.Estimated_Pay_Date__c = dtYest;
        //c1.Inactive_request_sent_to_Contracts_Admin__c = dtTomo;        
        c1.Rescheduled_Date__c = dtYest;    
        //c1.Estimated_Pay_Date__c = dtYest;    
        //c1.Order_Scheduled_date__c = dtYest;             
        c1.Date_Service_To_Be_Completed__c = dtYest;           
        c1.Date_Visit_Profile_To_Be_Inactivated__c = dtYest;   
        c1.Date_to_be_Moved_on_Call__c = dtYest;         
        
        try{
            insert  c1;
        }
        catch(Exception ex)
        {          
            System.assertEquals(ex.getTypeName(), 'System.DmlException');            
        }
        
        test.stopTest(); 
    }*/
    
    
  /*  static testMethod void Test_ValidateDateSentToClosure() 
    {
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        IM_Country__c mainName = new IM_Country__c(Name='Hello3');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='Hello3');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Hello3';
        setting.object_name__c = 'Account';
        insert setting;
        Account testAccount = new Account();
        testAccount.Name = 'Test Account New';
        testAccount.BillingCountry = 'Hello3';
        testAccount.BillingPostalCode = '11209';
        testAccount.BillingState = 'NY';
        testAccount.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert testAccount;
        //Account A = new Account(name='Account4TestMethod'+system.now());
        //insert A;
        //W-000685
        Contact con = new Contact(AccountId=testAccount.id ,FirstName = 'Test Name', LastName = 'test data',Phone = '12345678', Email='testdata@test.com');
        insert con;
        date sysToday = date.today();
        
        test.startTest();
        Case c1 = new Case();        
        system.debug('-----before case insert'); 
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CLAS - RM').getRecordTypeId();
        //c1.OwnerId = U.Id;        
        c1.AccountId = testAccount.Id;
        //c1.Date_Sent_To_Closures__c = sysToday;
        c1.Retained__c = 'No';
        c1.ContactId = con.id;
        c1.Authorized_User__c = 'No';
        //Nandini Mishra:6/3/2022 
        //c1.Estimated_Pay_Date__c=System.today()+3;
        //Nandini Mishra:6/3/2022 End 
        insert  c1;
        
        c1.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: SKP New Customer Setup').getRecordTypeId();
        // c1.X2nd_Sales_Resubmission_Date__c = sysToday.addDays(1);
        //c1.Date_Sent_to_Contracts_Admin__c= sysToday.addDays(1);
        c1.Date_Contract_Approved__c= sysToday.addDays(1);
        //c1.Date_On_Boarder_CSA_Assigned__c= sysToday.addDays(-1);
        //c1.Date_Paperwork_Received__c= sysToday.addDays(1);
        //c1.Date_Reviewed_Ncsp__c= sysToday.addDays(1);
        //c1.Sales_Resubmission_Date__c= sysToday.addDays(1);
        //c1.SecureSync_Setup_Date__c= sysToday.addDays(1);
        //c1.SecureSync_Training_Completed__c= sysToday.addDays(1);
        //c1.Service_Reschedule_Date__c= sysToday.addDays(-1);
        //c1.Supplies_Delivered_Date__c= sysToday.addDays(1);
        //c1.Supplies_Scheduled_Date__c= sysToday.addDays(-1);
        //#8977 Delete 11 NCSP case field deletion (6/3/2022) :- Part 1 "Supply_Reschedule_Date__c" commented by Nandini Mishra to remove field dependency for this field
        // c1.Supply_Reschedule_Date__c= sysToday.addDays(-1);
        //c1.Date_Welcome_Call_Attempt_1__c= sysToday.addDays(1);        
        //c1.Shred_Date_Visit_Profile_Modified__c= sysToday.addDays(1);
        //c1.Date_Welcome_Call_Attempt_2__c= sysToday.addDays(1);
        //c1.Date_Welcome_Call_Attempt_3__c= sysToday.addDays(1);
        //c1.Date_welcome_call_completed__c= sysToday.addDays(1);
        //c1.IMC_Login_sent_to_customer__c= sysToday.addDays(1);
        //c1.IMC_Setup_Date__c= sysToday.addDays(1);
        //c1.Initial_Supply_Order_Date__c= sysToday.addDays(1);
        //c1.Rejected_Contract_Resubmission_Date__c= sysToday.addDays(1);
        //c1.Service_Completion_Date__c= sysToday.addDays(1);
        //c1.Service_Order_Date__c= sysToday.addDays(1);
        //c1.Service_Schedule_Date__c= sysToday.addDays(-1);
        //c1.Date_Shred_Visit_Profile_Created__c= sysToday.addDays(1);
        //c1.Transition_Date__c= sysToday.addDays(1);
        //c1.Invoice_Review_date__c= sysToday.addDays(1);
        //c1.Welcome_Packet_Sent_Date__c= sysToday.addDays(1);
        //c1.Date_Contract_Signed__c= sysToday.addDays(1);
        //c1.Date_Contracts_CSA_Assigned__c= sysToday.addDays(-1);    
        // c1.Date_1st_Restricted_Party_Screening__c= sysToday.addDays(1);
        //c1.Date_2nd_Restricted_Party_Screening__c= sysToday.addDays(1);
        c1.Date_Order_Fulfillment_Sent__c= sysToday.addDays(1);
        //c1.Date_2nd_Order_Fulfillment_Sent__c= sysToday.addDays(1);
        c1.Date_Confirmation_Fulfillment_Received__c= sysToday.addDays(1);
        //c1.Date_TCM_User_Created__c= sysToday.addDays(1);    
        //c1.Date_TCM_Setup_Completed__c= sysToday.addDays(1);   
        
        try{                
            update c1;
        }
        catch(Exception e){}
        
        
        c1.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: New Customer Setup').getRecordTypeId();
        //  c1.X2nd_Sales_Resubmission_Date__c = sysToday.addDays(1);
        //c1.Date_Sent_to_Contracts_Admin__c= sysToday.addDays(1);
        //c1.Date_Contract_Approved__c= sysToday.addDays(1);
        //c1.Date_On_Boarder_CSA_Assigned__c= sysToday.addDays(-1);
        //c1.Date_Paperwork_Received__c= sysToday.addDays(1);
        //c1.Date_Reviewed_Ncsp__c= sysToday.addDays(1);
        //c1.Sales_Resubmission_Date__c= sysToday.addDays(1);
        //c1.SecureSync_Setup_Date__c= sysToday.addDays(1);
        //c1.SecureSync_Training_Completed__c= sysToday.addDays(1);
        //c1.Service_Reschedule_Date__c= sysToday.addDays(-1);
        //c1.Supplies_Delivered_Date__c= sysToday.addDays(1);
        //c1.Supplies_Scheduled_Date__c= sysToday.addDays(-1);
        //#8977 Delete 11 NCSP case field deletion (6/3/2022) :- Part 1 "Supply_Reschedule_Date__c" commented by Nandini Mishra to remove field dependency for this field
        //c1.Supply_Reschedule_Date__c= sysToday.addDays(-1);
        //c1.Date_Welcome_Call_Attempt_1__c= sysToday.addDays(1);        
        //c1.Shred_Date_Visit_Profile_Modified__c= sysToday.addDays(1);
        //c1.Date_Welcome_Call_Attempt_2__c= sysToday.addDays(1);
        //c1.Date_Welcome_Call_Attempt_3__c= sysToday.addDays(1);
        //c1.Date_welcome_call_completed__c= sysToday.addDays(1);
        //c1.IMC_Login_sent_to_customer__c= sysToday.addDays(1);
        //c1.IMC_Setup_Date__c= sysToday.addDays(1);
        //c1.Initial_Supply_Order_Date__c= sysToday.addDays(1);
        //c1.Rejected_Contract_Resubmission_Date__c= sysToday.addDays(1);
        //c1.Service_Completion_Date__c= sysToday.addDays(1);
        //c1.Service_Order_Date__c= sysToday.addDays(1);
        //c1.Service_Schedule_Date__c= sysToday.addDays(-1);
        //c1.Date_Shred_Visit_Profile_Created__c= sysToday.addDays(1);
        //c1.Transition_Date__c= sysToday.addDays(1);
        //c1.Invoice_Review_date__c= sysToday.addDays(1);
        //c1.Welcome_Packet_Sent_Date__c= sysToday.addDays(1);
        //c1.Date_Contract_Signed__c= sysToday.addDays(1);
        //c1.Date_Contracts_CSA_Assigned__c= sysToday.addDays(-1);    
        //c1.Date_1st_Restricted_Party_Screening__c= sysToday.addDays(1);
        //c1.Date_2nd_Restricted_Party_Screening__c= sysToday.addDays(1);
        c1.Date_Order_Fulfillment_Sent__c= sysToday.addDays(1);
        //c1.Date_2nd_Order_Fulfillment_Sent__c= sysToday.addDays(1);
        c1.Date_Confirmation_Fulfillment_Received__c= sysToday.addDays(1);
        //c1.Date_TCM_User_Created__c= sysToday.addDays(1);    
        //c1.Date_TCM_Setup_Completed__c= sysToday.addDays(1);     
        
        try{                
            update c1;
        }
        catch(Exception e){}
        
        c1.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: Tech Services New Customer Setup').getRecordTypeId();
        //  c1.X2nd_Sales_Resubmission_Date__c = sysToday.addDays(1);
        //c1.Date_Sent_to_Contracts_Admin__c= sysToday.addDays(1);
        c1.Date_Contract_Approved__c= sysToday.addDays(1);
        //c1.Date_On_Boarder_CSA_Assigned__c= sysToday.addDays(-1);
        //c1.Date_Paperwork_Received__c= sysToday.addDays(1);
        //c1.Date_Reviewed_Ncsp__c= sysToday.addDays(1);
        //c1.Sales_Resubmission_Date__c= sysToday.addDays(1);
        //c1.SecureSync_Setup_Date__c= sysToday.addDays(1);
        //c1.SecureSync_Training_Completed__c= sysToday.addDays(1);
        //c1.Service_Reschedule_Date__c= sysToday.addDays(-1);
        //c1.Supplies_Delivered_Date__c= sysToday.addDays(1);
        //c1.Supplies_Scheduled_Date__c= sysToday.addDays(-1);
        //#8977 Delete 11 NCSP case field deletion (6/3/2022) :- Part 1 "Supply_Reschedule_Date__c" commented by Nandini Mishra to remove field dependency for this field
        //c1.Supply_Reschedule_Date__c= sysToday.addDays(-1);
        //c1.Date_Welcome_Call_Attempt_1__c= sysToday.addDays(1);        
        //c1.Shred_Date_Visit_Profile_Modified__c= sysToday.addDays(1);
        //c1.Date_Welcome_Call_Attempt_2__c= sysToday.addDays(1);
        //c1.Date_Welcome_Call_Attempt_3__c= sysToday.addDays(1);
        //c1.Date_welcome_call_completed__c= sysToday.addDays(1);
        //c1.IMC_Login_sent_to_customer__c= sysToday.addDays(1);
        //c1.IMC_Setup_Date__c= sysToday.addDays(1);
        //c1.Initial_Supply_Order_Date__c= sysToday.addDays(1);
        //c1.Rejected_Contract_Resubmission_Date__c= sysToday.addDays(1);
        //c1.Service_Completion_Date__c= sysToday.addDays(1);
        //c1.Service_Order_Date__c= sysToday.addDays(1);
        //c1.Service_Schedule_Date__c= sysToday.addDays(-1);
        //c1.Date_Shred_Visit_Profile_Created__c= sysToday.addDays(1);
        //c1.Transition_Date__c= sysToday.addDays(1);
        //c1.Invoice_Review_date__c= sysToday.addDays(1);
        //c1.Welcome_Packet_Sent_Date__c= sysToday.addDays(1);
        //c1.Date_Contract_Signed__c= sysToday.addDays(1);
        //c1.Date_Contracts_CSA_Assigned__c= sysToday.addDays(-1);    
        //c1.Date_1st_Restricted_Party_Screening__c= sysToday.addDays(1);
        //c1.Date_2nd_Restricted_Party_Screening__c= sysToday.addDays(1);
        c1.Date_Order_Fulfillment_Sent__c= sysToday.addDays(1);
        //c1.Date_2nd_Order_Fulfillment_Sent__c= sysToday.addDays(1);
        c1.Date_Confirmation_Fulfillment_Received__c= sysToday.addDays(1);
        //c1.Date_TCM_User_Created__c= sysToday.addDays(1);    
        //c1.Date_TCM_Setup_Completed__c= sysToday.addDays(1);     
        try{                
            update c1;
        }
        catch(Exception e){}
        
        c1.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: New Customer Setup').getRecordTypeId();
        //  c1.X2nd_Sales_Resubmission_Date__c = sysToday.addDays(1);
        //c1.Date_Sent_to_Contracts_Admin__c= sysToday.addDays(1);
        c1.Date_Contract_Approved__c= sysToday.addDays(1);
        //c1.Date_On_Boarder_CSA_Assigned__c= sysToday.addDays(-1);
        //c1.Date_Paperwork_Received__c= sysToday.addDays(1);
        //c1.Date_Reviewed_Ncsp__c= sysToday.addDays(1);
        //c1.Sales_Resubmission_Date__c= sysToday.addDays(1);
        //c1.SecureSync_Setup_Date__c= sysToday.addDays(1);
        //c1.SecureSync_Training_Completed__c= sysToday.addDays(1);
        //c1.Service_Reschedule_Date__c= sysToday.addDays(-1);
        //c1.Supplies_Delivered_Date__c= sysToday.addDays(1);
        //c1.Supplies_Scheduled_Date__c= sysToday.addDays(-1);
        //#8977 Delete 11 NCSP case field deletion (6/3/2022) :- Part 1 "Supply_Reschedule_Date__c" commented by Nandini Mishra to remove field dependency for this field
        // c1.Supply_Reschedule_Date__c= sysToday.addDays(-1);
        //c1.Date_Welcome_Call_Attempt_1__c= sysToday.addDays(1);        
        //c1.Shred_Date_Visit_Profile_Modified__c= sysToday.addDays(1);
        //c1.Date_Welcome_Call_Attempt_2__c= sysToday.addDays(1);
        //c1.Date_Welcome_Call_Attempt_3__c= sysToday.addDays(1);
        //c1.Date_welcome_call_completed__c= sysToday.addDays(1);
        //c1.IMC_Login_sent_to_customer__c= sysToday.addDays(1);
        //c1.IMC_Setup_Date__c= sysToday.addDays(1);
        //c1.Initial_Supply_Order_Date__c= sysToday.addDays(1);
        //c1.Rejected_Contract_Resubmission_Date__c= sysToday.addDays(1);
        //c1.Service_Completion_Date__c= sysToday.addDays(1);
        //c1.Service_Order_Date__c= sysToday.addDays(1);
        //c1.Service_Schedule_Date__c= sysToday.addDays(-1);
        //c1.Date_Shred_Visit_Profile_Created__c= sysToday.addDays(1);
        //c1.Transition_Date__c= sysToday.addDays(1);
        //c1.Invoice_Review_date__c= sysToday.addDays(1);
        //c1.Welcome_Packet_Sent_Date__c= sysToday.addDays(1);
        //c1.Date_Contract_Signed__c= sysToday.addDays(1);
        //c1.Date_Contracts_CSA_Assigned__c= sysToday.addDays(-1);    
        //c1.Date_1st_Restricted_Party_Screening__c= sysToday.addDays(1);
        //c1.Date_2nd_Restricted_Party_Screening__c= sysToday.addDays(1);
        c1.Date_Order_Fulfillment_Sent__c= sysToday.addDays(1);
        //c1.Date_2nd_Order_Fulfillment_Sent__c= sysToday.addDays(1);
        c1.Date_Confirmation_Fulfillment_Received__c= sysToday.addDays(1);
        //c1.Date_TCM_User_Created__c= sysToday.addDays(1);    
        //c1.Date_TCM_Setup_Completed__c= sysToday.addDays(1);     
        try{                
            update c1;
        }
        catch(Exception e){}
        
        test.stopTest();     
    } */ 
    
   /* static testMethod void Test_ValidateDateforCAC_RM() 
    {
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        
        IM_Country__c mainName = new IM_Country__c(Name='United States12');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States12');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States12';
        setting.object_name__c = 'Account';
        insert setting;
        Account A= new Account();
        A.name= 'Test Account New';
        A.BillingCountry = 'United States12';
        A.BillingPostalCode = '11209';
        A.BillingState = 'NY';
        A.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert A;
        //W-000685
        Contact con = new Contact(AccountId=A.id ,FirstName = 'Test Name', LastName = 'test data',Phone = '12345678', Email='testdata@test.com');
        insert con;
        date sysToday = date.today().addDays(1);
        
        test.startTest();
        Case newCase = new Case();        
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CLAS - RM').getRecordTypeId();
        newCase.AccountId = A.Id;
        newCase.Retained__c = 'No';
        newCase.ContactId = con.id;
        newCase.Authorized_User__c = 'No';
        //Nandini Mishra:6/3/2022 Start
        //newCase.Estimated_Pay_Date__c=System.today()+3;
        //Nandini Mishra:6/3/2022 End        
        insert  newCase;
        
        newCase.AM_Response_Date__c = sysToday.addDays(1);
        /* W-000616
newCase.CAC_First_Customer_Contact_Date__c = sysToday.addDays(1);
        newCase.CAC_Inactivate_Request__c = sysToday.addDays(1);
        /* W-000616
newCase.CAC_Intro_Date__c = sysToday.addDays(1);
newCase.CAC_Second_Customer_Contact_Date__c = sysToday.addDays(1);
newCase.CAC_Third_Customer_Contact_Date__c = sysToday.addDays(1);
        newCase.Confirm_Final_Service__c = sysToday.addDays(1);
        //newCase.Contract_Admin_Response_Date__c = sysToday.addDays(1);
        //newCase.Cost_Summary_Attempt_1__c = sysToday.addDays(1);
        //newCase.Cost_Summary_Attempt2__c = sysToday.addDays(1);
        //newCase.Cost_Summary_Attempt3__c = sysToday.addDays(1);
        //newCase.Customer_Request_Received_Date__c = sysToday.addDays(1);
        /*W-000616
newCase.Customer_Update_Date__c = sysToday.addDays(1);
        //newCase.Date_Account_Inactivated__c = sysToday.addDays(1);
        newCase.Date_Approval_Received__c = sysToday.addDays(1);
        /* Begin - Case field deletion : 10373
newCase.Date_Cancelled__c = sysToday.addDays(1);
End - Case field deletion : 10373 
        newCase.Date_Closure_Complete__c = sysToday.addDays(1);
        newCase.Date_Confirmed_by_Contracts__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Contracts_Respond__c = sysToday.addDays(1);*/
        //newCase.Date_Customer_Approval_Received__c = sysToday.addDays(1);
        //newCase.Date_Destruction_Order_Created__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Destruction_SR_Requested__c = sysToday.addDays(1);
        //newCase.Date_Email_Sent_To_Contracts_Admin__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Email_Sent_To_Local_Leadership__c = sysToday.addDays(1);
        newCase.Date_Final_Order_Created_in_SKP__c = sysToday.addDays(1);
        newCase.Date_Final_Service_Order_Created__c = sysToday.addDays(1);
        newCase.Date_First_Customer_Contact_Attempt__c = sysToday.addDays(1);
        //newCase.Date_Followed_Up_W_Customer__c = sysToday.addDays(1);
        //newCase.Date_Inventory_Status_Confirmed__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Invoice_Created__c = sysToday.addDays(1);
        //newCase.Date_Invoice_Details_Package_Sent__c = sysToday.addDays(1);
        //newCase.Date_Loyalty_Specialist_Assigned__c = sysToday.addDays(1);
        newCase.Date_Moved_on_Call__c = sysToday.addDays(1);
        newCase.Date_of_Account_Update_Review_Completed__c = sysToday.addDays(1);
        /* #8991 Delete 10 case field deletion :- Part 3 "Date_of_Customer_Response__c" */
        //newCase.Date_of_Customer_Response__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_of_Invoice_Confirmation__c = sysToday.addDays(1);
        newCase.Date_of_Overall_Account_Review_Completed__c = sysToday.addDays(1);
        /* #8991 Delete 10 case field deletion :- Part 3 "Date_Of_Resubmission__c" 
        //newCase.Date_Of_Resubmission__c = sysToday.addDays(1);
        newCase.Date_Of_Resubmission_To_Contracts_Admin__c = sysToday.addDays(1);
        //newCase.Date_Ops_Confirmed_For_Timeline__c = sysToday.addDays(1);
        newCase.Date_Ops_Confirms_SB_Clean__c = sysToday.addDays(1);
        newCase.Date_Ops_emailed_for_timeline__c = sysToday.addDays(1);
        /* W-000616
newCase.Date_Owner_Established__c = sysToday.addDays(1);

        newCase.Date_Package_Sent_To_Contracts_Admin__c = sysToday.addDays(1);
        //newCase.Date_PDL_Approval_Received__c = sysToday.addDays(1);
        //newCase.Date_PDL_Sent_to_Customer__c = sysToday.addDays(1);
        newCase.Date_Proposal_Approval_Requested__c = sysToday.addDays(1);
        //newCase.Date_PW_Order_Created__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_PW_SR_Requested__c = sysToday.addDays(1);
newCase.Date_Resubmitted_to_Contracts__c = sysToday.addDays(1);
newCase.Date_Revised_Cost_Summary_Sent__c = sysToday.addDays(1);
        newCase.Date_Second_Customer_Contact_Attempt__c = sysToday.addDays(1);
        newCase.Date_Sent_to_AM__c = sysToday.addDays(1);
        /* W-000616
newCase.Date_Sent_To_Closures__c = sysToday.addDays(1);
newCase.Date_Sent_to_Contracts_US__c = sysToday.addDays(1);
        newCase.Date_Sent_to_Ops__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Sent_To_Shared_services__c = sysToday.addDays(1);
        newCase.Date_Service_Confirmation__c = sysToday.addDays(1);
        newCase.Date_Service_To_Be_Completed__c = sysToday.addDays(1);
        newCase.Date_Termination_Request_Sent_Contracts__c = sysToday.addDays(1);
        newCase.Date_Third_Customer_Contact_Attempt__c = sysToday.addDays(1);
        newCase.Date_to_be_Moved_on_Call__c = sysToday.addDays(1);
        newCase.Date_Visit_Profile_To_Be_Inactivated__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Worksheet_Created__c = sysToday.addDays(1);
        //newCase.Estimated_Pay_Date__c = sysToday.addDays(1);
        newCase.Final_Customer_Contact_Date__c = sysToday.addDays(1);
        //newCase.Inactive_request_sent_to_Contracts_Admin__c = sysToday.addDays(1);
        newCase.Intro_Date__c = sysToday.addDays(1);
        //newCase.Invoice_Request_Date__c = sysToday.addDays(1);
        /*W-000616
newCase.Local_Leadership_response_date__c = sysToday.addDays(1);
        //newCase.Notify_Collections__c = sysToday.addDays(1);
        //newCase.Order_completion_date__c = sysToday.addDays(1);
        //newCase.Order_Scheduled_date__c = sysToday.addDays(1);
        /* #8991 Delete 10 case field deletion :- Part 3 "OTO_Created_Date__c" 
        //newCase.OTO_Created_Date__c = sysToday.addDays(1);
        newCase.Outstanding_Invoice_Payment_Date__c = sysToday.addDays(1);
        //newCase.Payment_Confirmation_Date__c = sysToday.addDays(1);
        newCase.Payment_Follow_Up__c = sysToday.addDays(1);
        //newCase.PDL_Follow_up_Date__c = sysToday.addDays(1);
        //newCase.Proposal_Attempt_Date_1__c = sysToday.addDays(1);
        //newCase.Proposal_Attempt_Date_2__c = sysToday.addDays(1);
        //newCase. = sysToday.addDays(1);
        //newCase.Proposal_Created_Date__c = sysToday.addDays(1);
        /*W-000616
newCase.Proposal_Sent_to_Customer__c = sysToday.addDays(1);
        newCase.PW_Order_Completed__c = sysToday.addDays(1);
        newCase.Rescheduled_Date__c = sysToday.addDays(1);
        newCase.Support_Specialist_Assigned_Date__c = sysToday.addDays(1);
        newCase.Update_Sent_To_Operations__c = sysToday.addDays(1);
        
        try{                
            update newCase;
        }
        catch(Exception e){}
        
        test.stopTest();     
    } */
    
   /* static testMethod void Test_ValidateDateforCAC_DP() 
    {
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        
        IM_Country__c mainName = new IM_Country__c(Name='United States13');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States13');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States13';
        setting.object_name__c = 'Account';
        insert setting;
        Account acc= new Account();
        acc.name= 'Test Account New';
        acc.BillingCountry = 'United States13';
        acc.BillingPostalCode = '11209';
        acc.BillingState = 'NY';
        acc.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert acc;
        //W-000685
        Contact con = new Contact(AccountId=acc.id ,FirstName = 'Test Name', LastName = 'test data',Phone = '12345678', Email='testdata@test.com');
        insert con;
        date sysToday = date.today();
        
        test.startTest();
        Case newCase = new Case();        
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CAC - DP Closure').getRecordTypeId();
        newCase.AccountId = acc.Id;
        newCase.Retained__c = 'No';
        newCase.ContactId = con.id;
        // Edidted by Shashi Bhushan on 06th June 2022
        //newCase.Estimated_Pay_Date__c =system.today() + 3;
        // Edidted by Shashi Bhushan on 06th June 2022 end
        newCase.Authorized_User__c = 'No';        
        insert  newCase;
        
        newCase.AM_Response_Date__c = sysToday.addDays(1);
        /* W-000616
newCase.CAC_First_Customer_Contact_Date__c = sysToday.addDays(1);
        newCase.CAC_Inactivate_Request__c = sysToday.addDays(1);
        /*W-000616
newCase.CAC_Intro_Date__c = sysToday.addDays(1);
newCase.CAC_Second_Customer_Contact_Date__c = sysToday.addDays(1);
newCase.CAC_Third_Customer_Contact_Date__c = sysToday.addDays(1);*/
        //newCase.Confirm_Final_Service__c = sysToday.addDays(1);
        //newCase.Contract_Admin_Response_Date__c = sysToday.addDays(1);
        //newCase.Cost_Summary_Attempt_1__c = sysToday.addDays(1);
        //newCase.Cost_Summary_Attempt2__c = sysToday.addDays(1);
        //newCase.Cost_Summary_Attempt3__c = sysToday.addDays(1);
        //newCase.Customer_Request_Received_Date__c = sysToday.addDays(1);
        /*W-000616
newCase.Customer_Update_Date__c = sysToday.addDays(1);
        //newCase.Date_Account_Inactivated__c = sysToday.addDays(1);
        newCase.Date_Approval_Received__c = sysToday.addDays(1);
        /* Begin - Case field deletion : 10373
newCase.Date_Cancelled__c = sysToday.addDays(1);
End - Case field deletion : 10373 
        //newCase.Date_Closure_Complete__c = sysToday.addDays(1);
        newCase.Date_Confirmed_by_Contracts__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Contracts_Respond__c = sysToday.addDays(1);*/
        //newCase.Date_Customer_Approval_Received__c = sysToday.addDays(1);
        //newCase.Date_Destruction_Order_Created__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Destruction_SR_Requested__c = sysToday.addDays(1);
        //newCase.Date_Email_Sent_To_Contracts_Admin__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Email_Sent_To_Local_Leadership__c = sysToday.addDays(1);
        newCase.Date_Final_Order_Created_in_SKP__c = sysToday.addDays(1);
        //newCase.Date_Final_Service_Order_Created__c = sysToday.addDays(1);
        newCase.Date_First_Customer_Contact_Attempt__c = sysToday.addDays(1);
        //newCase.Date_Followed_Up_W_Customer__c = sysToday.addDays(1);
        //newCase.Date_Inventory_Status_Confirmed__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Invoice_Created__c = sysToday.addDays(1);
        //newCase.Date_Invoice_Details_Package_Sent__c = sysToday.addDays(1);
        //newCase.Date_Loyalty_Specialist_Assigned__c = sysToday.addDays(1);
        //newCase.Date_Moved_on_Call__c = sysToday.addDays(1);
        newCase.Date_of_Account_Update_Review_Completed__c = sysToday.addDays(1);
        /* #8991 Delete 10 case field deletion :- Part 3 "Date_of_Customer_Response__c" 
        //newCase.Date_of_Customer_Response__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_of_Invoice_Confirmation__c = sysToday.addDays(1);
        newCase.Date_of_Overall_Account_Review_Completed__c = sysToday.addDays(1);
        /* #8991 Delete 10 case field deletion :- Part 3 "Date_Of_Resubmission__c" 
        //newCase.Date_Of_Resubmission__c = sysToday.addDays(1);
        newCase.Date_Of_Resubmission_To_Contracts_Admin__c = sysToday.addDays(1);
        //newCase.Date_Ops_Confirmed_For_Timeline__c = sysToday.addDays(1);
        //newCase.Date_Ops_Confirms_SB_Clean__c = sysToday.addDays(1);
        newCase.Date_Ops_emailed_for_timeline__c = sysToday.addDays(1);
        /* W-000616
newCase.Date_Owner_Established__c = sysToday.addDays(1);

        newCase.Date_Package_Sent_To_Contracts_Admin__c = sysToday.addDays(1);
        //newCase.Date_PDL_Approval_Received__c = sysToday.addDays(1);
        //newCase.Date_PDL_Sent_to_Customer__c = sysToday.addDays(1);
        newCase.Date_Proposal_Approval_Requested__c = sysToday.addDays(1);
        //newCase.Date_PW_Order_Created__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_PW_SR_Requested__c = sysToday.addDays(1)
newCase.Date_Resubmitted_to_Contracts__c = sysToday.addDays(1);
newCase.Date_Revised_Cost_Summary_Sent__c = sysToday.addDays(1);
        newCase.Date_Second_Customer_Contact_Attempt__c = sysToday.addDays(1);
        newCase.Date_Sent_to_AM__c = sysToday.addDays(1);
        /* W-000616
newCase.Date_Sent_To_Closures__c = sysToday.addDays(1);
newCase.Date_Sent_to_Contracts_US__c = sysToday.addDays(1);
        //newCase.Date_Sent_to_Ops__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Sent_To_Shared_services__c = sysToday.addDays(1);
        newCase.Date_Service_Confirmation__c = sysToday.addDays(1);
        newCase.Date_Service_To_Be_Completed__c = sysToday.addDays(1);
        newCase.Date_Termination_Request_Sent_Contracts__c = sysToday.addDays(1);
        newCase.Date_Third_Customer_Contact_Attempt__c = sysToday.addDays(1);
        //newCase.Date_to_be_Moved_on_Call__c = sysToday.addDays(1);
        newCase.Date_Visit_Profile_To_Be_Inactivated__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Worksheet_Created__c = sysToday.addDays(1);
        //newCase.Estimated_Pay_Date__c = sysToday.addDays(1);
        newCase.Final_Customer_Contact_Date__c = sysToday.addDays(1);
        //newCase.Inactive_request_sent_to_Contracts_Admin__c = sysToday.addDays(1);
        newCase.Intro_Date__c = sysToday.addDays(1);
        //newCase.Invoice_Request_Date__c = sysToday.addDays(1);
        /*W-000616
newCase.Local_Leadership_response_date__c = sysToday.addDays(1);
        //newCase.Notify_Collections__c = sysToday.addDays(1);
        //newCase.Order_completion_date__c = sysToday.addDays(1);
        //newCase.Order_Scheduled_date__c = sysToday.addDays(1);
        /* #8991 Delete 10 case field deletion :- Part 3 "OTO_Created_Date__c" 
        //newCase.OTO_Created_Date__c = sysToday.addDays(1);
        newCase.Outstanding_Invoice_Payment_Date__c = sysToday.addDays(1);
        //newCase.Payment_Confirmation_Date__c = sysToday.addDays(1);
        newCase.Payment_Follow_Up__c = sysToday.addDays(1);
        //newCase.PDL_Follow_up_Date__c = sysToday.addDays(1);
        //newCase.Proposal_Attempt_Date_1__c = sysToday.addDays(1);
        //newCase.Proposal_Attempt_Date_2__c = sysToday.addDays(1);
        //#8990 Delete 11 case field deletion :- Part 2 "Proposal_Attempt_Date_3__c"
        //newCase.Proposal_Attempt_Date_3__c = sysToday.addDays(1);
        //newCase.Proposal_Created_Date__c = sysToday.addDays(1);
        /* W-000616
newCase.Proposal_Sent_to_Customer__c = sysToday.addDays(1);
        newCase.PW_Order_Completed__c = sysToday.addDays(1);
        newCase.Rescheduled_Date__c = sysToday.addDays(1);
        newCase.Support_Specialist_Assigned_Date__c = sysToday.addDays(1);
        //newCase.Update_Sent_To_Operations__c = sysToday.addDays(1);
        
        try{                
            update newCase;
        }
        catch(Exception e){}
        
        test.stopTest();     
    } */
    //W-000685, NOT IN USE
    /*static testMethod void Test_ValidateDateforCAC_Insert() 
{
Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];

Account A = new Account(name='Account4TestMethod'+system.now());
insert A;
Contact con = new Contact(AccountId=A.id , LastName = 'test data',Phone = '12345678', Email='testdata@test.com');
insert con;
date sysToday = date.today();

test.startTest();
Case newCase = new Case();        
newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CAC - DP Closure').getRecordTypeId();
newCase.AccountId = A.Id;
newCase.Retained__c = 'No';
newCase.ContactId = con.id;
newCase.Authorized_User__c = 'No';          
newCase.AM_Response_Date__c = sysToday.addDays(1);
newCase.CAC_First_Customer_Contact_Date__c = sysToday.addDays(1);
newCase.CAC_Inactivate_Request__c = sysToday.addDays(1);
newCase.CAC_Intro_Date__c = sysToday.addDays(1);
newCase.CAC_Second_Customer_Contact_Date__c = sysToday.addDays(1);
newCase.CAC_Third_Customer_Contact_Date__c = sysToday.addDays(1);
newCase.Confirm_Final_Service__c = sysToday.addDays(1);
newCase.Contract_Admin_Response_Date__c = sysToday.addDays(1);
newCase.Cost_Summary_Attempt_1__c = sysToday.addDays(1);
newCase.Cost_Summary_Attempt2__c = sysToday.addDays(1);
newCase.Cost_Summary_Attempt3__c = sysToday.addDays(1);
newCase.Customer_Request_Received_Date__c = sysToday.addDays(1);
newCase.Customer_Update_Date__c = sysToday.addDays(1);
newCase.Date_Account_Inactivated__c = sysToday.addDays(1);
newCase.Date_Approval_Received__c = sysToday.addDays(1);
newCase.Date_Cancelled__c = sysToday.addDays(1);
newCase.Date_Closure_Complete__c = sysToday.addDays(1);
newCase.Date_Confirmed_by_Contracts__c = sysToday.addDays(1);
newCase.Date_Contracts_Respond__c = sysToday.addDays(1);
newCase.Date_Customer_Approval_Received__c = sysToday.addDays(1);
newCase.Date_Destruction_Order_Created__c = sysToday.addDays(1);
newCase.Date_Destruction_SR_Requested__c = sysToday.addDays(1);
newCase.Date_Email_Sent_To_Contracts_Admin__c = sysToday.addDays(1);
newCase.Date_Email_Sent_To_Local_Leadership__c = sysToday.addDays(1);
newCase.Date_Final_Order_Created_in_SKP__c = sysToday.addDays(1);
newCase.Date_Final_Service_Order_Created__c = sysToday.addDays(1);
newCase.Date_First_Customer_Contact_Attempt__c = sysToday.addDays(1);
newCase.Date_Followed_Up_W_Customer__c = sysToday.addDays(1);
newCase.Date_Inventory_Status_Confirmed__c = sysToday.addDays(1);
newCase.Date_Invoice_Created__c = sysToday.addDays(1);
newCase.Date_Invoice_Details_Package_Sent__c = sysToday.addDays(1);
newCase.Date_Loyalty_Specialist_Assigned__c = sysToday.addDays(1);
newCase.Date_Moved_on_Call__c = sysToday.addDays(1);
newCase.Date_of_Account_Update_Review_Completed__c = sysToday.addDays(1);
newCase.Date_of_Customer_Response__c = sysToday.addDays(1);
newCase.Date_of_Invoice_Confirmation__c = sysToday.addDays(1);
newCase.Date_of_Overall_Account_Review_Completed__c = sysToday.addDays(1);
newCase.Date_Of_Resubmission__c = sysToday.addDays(1);
newCase.Date_Of_Resubmission_To_Contracts_Admin__c = sysToday.addDays(1);
newCase.Date_Ops_Confirmed_For_Timeline__c = sysToday.addDays(1);
newCase.Date_Ops_Confirms_SB_Clean__c = sysToday.addDays(1);
newCase.Date_Ops_emailed_for_timeline__c = sysToday.addDays(1);
newCase.Date_Owner_Established__c = sysToday.addDays(1);
newCase.Date_Package_Sent_To_Contracts_Admin__c = sysToday.addDays(1);
newCase.Date_PDL_Approval_Received__c = sysToday.addDays(1);
newCase.Date_PDL_Sent_to_Customer__c = sysToday.addDays(1);
newCase.Date_Proposal_Approval_Requested__c = sysToday.addDays(1);
newCase.Date_PW_Order_Created__c = sysToday.addDays(1);
newCase.Date_PW_SR_Requested__c = sysToday.addDays(1);
newCase.Date_Resubmitted_to_Contracts__c = sysToday.addDays(1);
newCase.Date_Revised_Cost_Summary_Sent__c = sysToday.addDays(1);
newCase.Date_Second_Customer_Contact_Attempt__c = sysToday.addDays(1);
newCase.Date_Sent_to_AM__c = sysToday.addDays(1);
newCase.Date_Sent_To_Closures__c = sysToday.addDays(1);
newCase.Date_Sent_to_Contracts_US__c = sysToday.addDays(1);
newCase.Date_Sent_to_Ops__c = sysToday.addDays(1);
newCase.Date_Sent_To_Shared_services__c = sysToday.addDays(1);
newCase.Date_Service_Confirmation__c = sysToday.addDays(1);
newCase.Date_Service_To_Be_Completed__c = sysToday.addDays(1);
newCase.Date_Termination_Request_Sent_Contracts__c = sysToday.addDays(1);
newCase.Date_Third_Customer_Contact_Attempt__c = sysToday.addDays(1);
newCase.Date_to_be_Moved_on_Call__c = sysToday.addDays(1);
newCase.Date_Visit_Profile_To_Be_Inactivated__c = sysToday.addDays(1);
newCase.Date_Worksheet_Created__c = sysToday.addDays(1);
newCase.Estimated_Pay_Date__c = sysToday.addDays(1);
newCase.Final_Customer_Contact_Date__c = sysToday.addDays(1);
newCase.Inactive_request_sent_to_Contracts_Admin__c = sysToday.addDays(1);
newCase.Intro_Date__c = sysToday.addDays(1);
newCase.Invoice_Request_Date__c = sysToday.addDays(1);
newCase.Local_Leadership_response_date__c = sysToday.addDays(1);
newCase.Notify_Collections__c = sysToday.addDays(1);
newCase.Order_completion_date__c = sysToday.addDays(1);
newCase.Order_Scheduled_date__c = sysToday.addDays(1);
newCase.OTO_Created_Date__c = sysToday.addDays(1);
newCase.Outstanding_Invoice_Payment_Date__c = sysToday.addDays(1);
newCase.Payment_Confirmation_Date__c = sysToday.addDays(1);
newCase.Payment_Follow_Up__c = sysToday.addDays(1);
newCase.PDL_Follow_up_Date__c = sysToday.addDays(1);
newCase.Proposal_Attempt_Date_1__c = sysToday.addDays(1);
newCase.Proposal_Attempt_Date_2__c = sysToday.addDays(1);
//#8990 Delete 11 case field deletion :- Part 2 "Proposal_Attempt_Date_3__c"
//newCase.Proposal_Attempt_Date_3__c = sysToday.addDays(1);
newCase.Proposal_Created_Date__c = sysToday.addDays(1);
newCase.Proposal_Sent_to_Customer__c = sysToday.addDays(1);
newCase.PW_Order_Completed__c = sysToday.addDays(1);
newCase.Rescheduled_Date__c = sysToday.addDays(1);
newCase.Support_Specialist_Assigned_Date__c = sysToday.addDays(1);
newCase.Update_Sent_To_Operations__c = sysToday.addDays(1);

try{      
UtilCacDateValidation.validationRuleForRetentionType(newCase);
}
catch(Exception e){}

test.stopTest();     
}*/ 
    
   /* static testMethod void Test_ValidateDateforCAC_Shred() 
    {
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        
        IM_Country__c mainName = new IM_Country__c(Name='United States14');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States14');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States14';
        setting.object_name__c = 'Account';
        insert setting;
        Account A= new Account();
        A.name= 'Test Account New';
        A.BillingCountry = 'United States14';
        A.BillingPostalCode = '11209';
        A.BillingState = 'NY';
        A.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert A;
        //W-000685
        Contact con = new Contact(AccountId=A.id ,FirstName = 'Test Name', LastName = 'test data',Phone = '12345678', Email='testdata@test.com');
        insert con;
        date sysToday = date.today();
        
        //test.startTest();
        Case newCase = new Case();        
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CLAS - Shred').getRecordTypeId();
        newCase.AccountId = A.Id;
        newCase.Retained__c = 'No';
        newCase.ContactId = con.id;
        newCase.Authorized_User__c = 'No';        
        insert  newCase;
        
        newCase.AM_Response_Date__c = sysToday.addDays(1);
        /* W-000616
newCase.CAC_First_Customer_Contact_Date__c = sysToday.addDays(1);
        newCase.CAC_Inactivate_Request__c = sysToday.addDays(1);
        /* W-000616
newCase.CAC_Intro_Date__c = sysToday.addDays(1);
newCase.CAC_Second_Customer_Contact_Date__c = sysToday.addDays(1);
newCase.CAC_Third_Customer_Contact_Date__c = sysToday.addDays(1);
        newCase.Confirm_Final_Service__c = sysToday.addDays(1);
        //newCase.Contract_Admin_Response_Date__c = sysToday.addDays(1);
        //newCase.Cost_Summary_Attempt_1__c = sysToday.addDays(1);
        //newCase.Cost_Summary_Attempt2__c = sysToday.addDays(1);
        //newCase.Cost_Summary_Attempt3__c = sysToday.addDays(1);
        //newCase.Customer_Request_Received_Date__c = sysToday.addDays(1);
        /*W-000616
newCase.Customer_Update_Date__c = sysToday.addDays(1);
        //newCase.Date_Account_Inactivated__c = sysToday.addDays(1);
        newCase.Date_Approval_Received__c = sysToday.addDays(1);
        /* Begin - Case field deletion : 10373
newCase.Date_Cancelled__c = sysToday.addDays(1);
End - Case field deletion : 10373 
        newCase.Date_Closure_Complete__c = sysToday.addDays(1);
        newCase.Date_Confirmed_by_Contracts__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Contracts_Respond__c = sysToday.addDays(1);
        //newCase.Date_Customer_Approval_Received__c = sysToday.addDays(1);
        //newCase.Date_Destruction_Order_Created__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Destruction_SR_Requested__c = sysToday.addDays(1);
        //newCase.Date_Email_Sent_To_Contracts_Admin__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Email_Sent_To_Local_Leadership__c = sysToday.addDays(1);
        newCase.Date_Final_Order_Created_in_SKP__c = sysToday.addDays(1);
        newCase.Date_Final_Service_Order_Created__c = sysToday.addDays(1);
        newCase.Date_First_Customer_Contact_Attempt__c = sysToday.addDays(1);
        //newCase.Date_Followed_Up_W_Customer__c = sysToday.addDays(1);
        //newCase.Date_Inventory_Status_Confirmed__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Invoice_Created__c = sysToday.addDays(1);
        //newCase.Date_Invoice_Details_Package_Sent__c = sysToday.addDays(1);
        //newCase.Date_Loyalty_Specialist_Assigned__c = sysToday.addDays(1);
        newCase.Date_Moved_on_Call__c = sysToday.addDays(1);
        newCase.Date_of_Account_Update_Review_Completed__c = sysToday.addDays(1);
        /* #8991 Delete 10 case field deletion :- Part 3 "Date_of_Customer_Response__c" 
        //newCase.Date_of_Customer_Response__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_of_Invoice_Confirmation__c = sysToday.addDays(1);
        newCase.Date_of_Overall_Account_Review_Completed__c = sysToday.addDays(1);
        /* #8991 Delete 10 case field deletion :- Part 3 "Date_Of_Resubmission__c" 
        //newCase.Date_Of_Resubmission__c = sysToday.addDays(1);
        newCase.Date_Of_Resubmission_To_Contracts_Admin__c = sysToday.addDays(1);
        //newCase.Date_Ops_Confirmed_For_Timeline__c = sysToday.addDays(1);
        newCase.Date_Ops_Confirms_SB_Clean__c = sysToday.addDays(1);
        newCase.Date_Ops_emailed_for_timeline__c = sysToday.addDays(1);
        /* W-000616
newCase.Date_Owner_Established__c = sysToday.addDays(1);

        newCase.Date_Package_Sent_To_Contracts_Admin__c = sysToday.addDays(1);
        //newCase.Date_PDL_Approval_Received__c = sysToday.addDays(1);
        //newCase.Date_PDL_Sent_to_Customer__c = sysToday.addDays(1);
        newCase.Date_Proposal_Approval_Requested__c = sysToday.addDays(1);
        //newCase.Date_PW_Order_Created__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_PW_SR_Requested__c = sysToday.addDays(1);
newCase.Date_Resubmitted_to_Contracts__c = sysToday.addDays(1);
newCase.Date_Revised_Cost_Summary_Sent__c = sysToday.addDays(1);
        newCase.Date_Second_Customer_Contact_Attempt__c = sysToday.addDays(1);
        newCase.Date_Sent_to_AM__c = sysToday.addDays(1);
        /* W-000616
newCase.Date_Sent_To_Closures__c = sysToday.addDays(1);
newCase.Date_Sent_to_Contracts_US__c = sysToday.addDays(1);
        newCase.Date_Sent_to_Ops__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Sent_To_Shared_services__c = sysToday.addDays(1);
        newCase.Date_Service_Confirmation__c = sysToday.addDays(1);
        newCase.Date_Service_To_Be_Completed__c = sysToday.addDays(1);
        newCase.Date_Termination_Request_Sent_Contracts__c = sysToday.addDays(1);
        newCase.Date_Third_Customer_Contact_Attempt__c = sysToday.addDays(1);
        newCase.Date_to_be_Moved_on_Call__c = sysToday.addDays(1);
        newCase.Date_Visit_Profile_To_Be_Inactivated__c = sysToday.addDays(1);
        /*W-000616
newCase.Date_Worksheet_Created__c = sysToday.addDays(1);
        //newCase.Estimated_Pay_Date__c = sysToday.addDays(1);
        newCase.Final_Customer_Contact_Date__c = sysToday.addDays(1);
        //newCase.Inactive_request_sent_to_Contracts_Admin__c = sysToday.addDays(1);
        newCase.Intro_Date__c = sysToday.addDays(1);
        //newCase.Invoice_Request_Date__c = sysToday.addDays(1);
        /*W-000616
newCase.Local_Leadership_response_date__c = sysToday.addDays(1);
        //newCase.Notify_Collections__c = sysToday.addDays(1);
        //newCase.Order_completion_date__c = sysToday.addDays(1);
        //newCase.Order_Scheduled_date__c = sysToday.addDays(1);
        /* #8991 Delete 10 case field deletion :- Part 3 "OTO_Created_Date__c" 
        //newCase.OTO_Created_Date__c = sysToday.addDays(1);
        newCase.Outstanding_Invoice_Payment_Date__c = sysToday.addDays(1);
        //newCase.Payment_Confirmation_Date__c = sysToday.addDays(1);
        newCase.Payment_Follow_Up__c = sysToday.addDays(1);
        //newCase.PDL_Follow_up_Date__c = sysToday.addDays(1);
        //newCase.Proposal_Attempt_Date_1__c = sysToday.addDays(1);
        //newCase.Proposal_Attempt_Date_2__c = sysToday.addDays(1);
        //#8990 Delete 11 case field deletion :- Part 2 "Proposal_Attempt_Date_3__c"
        //newCase.Proposal_Attempt_Date_3__c = sysToday.addDays(1);
        //newCase.Proposal_Created_Date__c = sysToday.addDays(1);
        /* W-000616
newCase.Proposal_Sent_to_Customer__c = sysToday.addDays(1);
        newCase.PW_Order_Completed__c = sysToday.addDays(1);
        newCase.Rescheduled_Date__c = sysToday.addDays(1);
        newCase.Support_Specialist_Assigned_Date__c = sysToday.addDays(1);
        newCase.Update_Sent_To_Operations__c = sysToday.addDays(1);
        
        try{                
            update newCase;
        }
        catch(Exception e){}
        
        // test.stopTest();     
    } */
    /* commented as part of user story #27072
    static testMethod void Test_NCSP_Prevent_ParentCase_Closure() 
    {
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        //Create a new User
        User U = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
                          emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert U; 
        
        //Create a new Account
        IM_Country__c mainName = new IM_Country__c(Name='United States15');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States15');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States15';
        setting.object_name__c = 'Account';
        insert setting;
        Account A= new Account();
        A.name= 'Test Account New';
        A.BillingCountry = 'United States15';
        A.BillingPostalCode = '11209';
        A.BillingState = 'NY';
        A.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert A;
        date sysToday = date.today();
        
        test.startTest();
        Case c1 = new Case();        
        system.debug('-----before case insert'); 
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: DMS').getRecordTypeId();
        c1.OwnerId = U.Id;        
        c1.AccountId = A.Id;
        /* W-000616
c1.Date_Sent_To_Closures__c = date.today();*
        c1.Retained__c = 'No';
        
        insert  c1;
        
        Case c2 = new Case();        
        system.debug('-----before case insert'); 
        c2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: DMS').getRecordTypeId();
        c2.OwnerId = U.Id;        
        c2.AccountId = A.Id;
        /* W-000616
c2.Date_Sent_To_Closures__c = date.today();*
        c2.Retained__c = 'No';
        c2.ParentId = c1.id;
        
        insert c2;
        
        c1.Status='Closed';
        try{                
            update c1;
        }
        catch(Exception e){}
    }*/ //commented as part of user story #27072
    
    static testMethod void Test_CloneCaseIfRecurringCaseChecked2() 
    {
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        //Create a new User
        User U = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
                          emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert U; 
        
        //Create a new Account
        IM_Country__c mainName = new IM_Country__c(Name='United States7');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States7');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States7';
        setting.object_name__c = 'Account';
        insert setting;
        Account A= new Account();
        A.name= 'Test Account New';
        A.BillingCountry = 'United States7';
        A.BillingPostalCode = '11209';
        A.BillingState = 'NY';
        A.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert A;
        date sysToday = date.today();
        try{
            test.startTest();
            Case c1 = new Case();        
            system.debug('-----before case insert'); 
            c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Retention').getRecordTypeId();
            c1.OwnerId = U.Id;        
            c1.AccountId = A.Id;
            /* W-000616
c1.Date_Sent_To_Closures__c = date.today();*/
            c1.Retained__c = 'No';
            c1.Initial_Due_Date__c = date.today();
            
            insert  c1;                
            
            c1.Recurring_Case__c=true;
            c1.Recurring_Frequency__c='Daily';
            c1.Status='Closed';
            
            update c1;
        }
        catch(Exception e){}
    }
    
    static testMethod void Test_NCSP_OpportunityUpdate_Case() 
    {
        //Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        ////Create a new User
        //User U = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
        //                  emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
        //                  localesidkey='en_US', profileid = prof.Id, Country = 'USA',
        //                  timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        //insert U; 
        
        //Create a new Account
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        IM_Country__c mainName = new IM_Country__c(Name='United States16');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States16');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States16';
        setting.object_name__c = 'Account';
        insert setting;
        Account A= new Account();
        A.name= 'Test Account New';
        A.BillingCountry = 'United States16';
        A.BillingPostalCode = '11209';
        A.BillingState = 'NY';
        A.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert A;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        //opp.OwnerId = U.Id;
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'Renewal';
        opp.Lead_Source_Most_Recent__c = 'Email';
        opp.NCSP_Status__c='Custom Setup';
        opp.Billing_Country__c=mainName.id;// Added by Arjun - Billing country required
        opp.IME_Vended_Unvended__c='Both';
        insert opp;
        
        Billing_Cut_Off_Schedule__c bcos = new Billing_Cut_Off_Schedule__c();
        
        bcos.Billing_Cut_Off_Date__c = Date.today();
        bcos.Invoice_Mailing_Date__c = Date.today();
        bcos.Service_Line__c ='test';
        bcos.Name='test1';
        bcos.Year__c = '2014';
        insert bcos;
        
        Case c1 = new Case();        
        system.debug('-----before case insert'); 
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: SKP New Customer Setup').getRecordTypeId();
        //c1.OwnerId = U.Id;        
        c1.AccountId = A.Id;
        /* W-000616
c1.Date_Sent_To_Closures__c = date.today();*/
        c1.Retained__c = 'No';
        c1.Initial_Due_Date__c = date.today();
        c1.NCSP_Opportunity__c = opp.id;
        insert  c1;            
        
        Test.startTest();
        c1.Service_Completion_Date__c=date.today();
        update c1;      
        
        c1.Project_Start_Date__c = date.today();
        /* #8991 Delete 10 case field deletion :- Part 3 "Implementation_Manager_Email__c, Implementation_Manager__c" */
        //c1.Implementation_Manager_Email__c = 'test@test.com';
        //c1.Implementation_Manager__c ='Test';
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: DMS').getRecordTypeId();
        update c1;
        
        c1.Project_Completion_Date__c = date.today();
        update c1;
        
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: Tech Services New Customer Setup').getRecordTypeId();
        update c1;
        Test.stopTest();
        
    }
    //Gitlab user Story #27422 start Test Methods added to improve code coverage
	@isTest
    public static void TestNCSPCaseContractApproved() 
    {   
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Test.startTest();
        //Create a new Account
        Account A= new Account();
        A.name= 'Test Account New';
        insert A;
        
        Contact testContact = new contact();
        testContact.FirstName ='test Contact';
        testContact.LastName ='test Contact';
        testContact.AccountId =a.id;
        testContact.Email='test@test.com';
        insert testContact;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'New Deal';
        opp.Primary_Product_Line__c='Data Centers';
        opp.Amount=1;
        opp.US_Federal_GSA_Pricing__c ='No';
        opp.CurrencyIsoCode ='USD';
        //opp.Pricebook2Id =testPricebook.id;
        //opp.Manager_Approval_Needed__c = 'No';
        insert opp;
        
       	Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            Username = 'testuser7878555577@example.com',
            CommunityNickname = 'testuser77',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'Test',
            FirstName = 'User',
            CompanyName = 'Test Company',
            Phone = '555-555-5555',
            Country ='test'
        );
        
        insert testUser;
        
        Case testCase = new Case();        
        system.debug('-----before case insert'); 
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: Tech Services New Customer Setup').getRecordTypeId();
        testCase.NCSP_Service_line__c ='CDR';       
        testCase.AccountId = A.Id;
        testCase.NCSP_Cust_Name__c ='Test Name';
        testCase.Origin='Update';
        testCase.Sales_Person_Name_Account_Manager__c =testUser.id;
        testCase.Date_Contract_Signed__c =Date.Today();
        testCase.Date_Paperwork_Received__c =Date.Today();
        testCase.ContactId=testContact.id;
        testCase.Address__c='test';
        testCase.state__C ='test';
        testCase.Zip__c ='123456';
        testCase.City__c ='test';
        testCase.Country__c='USA';
        testCase.Billing_Contact_Email__c ='test@test.com';		
        
        insert testCase;             
        
        testCase.NCSP_Opportunity__c = opp.id;
        update testCase;
        
        testCase.Contract_Status__c='Accepted';
        testCase.Contract_Type__c ='GSA';
        testCase.Case_Type__c ='Other';
        update testCase;      
        Test.stopTest();
        
    }
    @isTest
	public static void TestNCSPCaseContractRejected() 
    {   
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Test.startTest();
        //Create a new Account
        Account A= new Account();
        A.name= 'Test Account New';
        insert A;
        
        Contact testContact = new contact();
        testContact.FirstName ='test Contact';
        testContact.LastName ='test Contact';
        testContact.AccountId =a.id;
        testContact.Email='test@test.com';
        insert testContact;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'New Deal';
        opp.Primary_Product_Line__c='Data Centers';
        opp.Amount=1;
        opp.US_Federal_GSA_Pricing__c ='No';
        opp.CurrencyIsoCode ='USD';
        //opp.Pricebook2Id =testPricebook.id;
        //opp.Manager_Approval_Needed__c = 'No';
        insert opp;
        
       	Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            Username = 'testuser7878555577@example.com',
            CommunityNickname = 'testuser77',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'Test',
            FirstName = 'User',
            CompanyName = 'Test Company',
            Phone = '555-555-5555',
            Country ='test'
        );
        
        insert testUser;
        
        Case testCase2 = new Case();        
        system.debug('-----before case insert'); 
        testCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: Tech Services New Customer Setup').getRecordTypeId();
        testCase2.NCSP_Service_line__c ='CDR';       
        testCase2.AccountId = A.Id;
        testCase2.NCSP_Cust_Name__c ='Test Name';
        testCase2.Origin='Update';
        testCase2.Sales_Person_Name_Account_Manager__c =testUser.id;
        testCase2.Date_Contract_Signed__c =Date.Today();
        testCase2.Date_Paperwork_Received__c =Date.Today();
        testCase2.ContactId=testContact.id;
        testCase2.Address__c='test';
        testCase2.state__C ='test';
        testCase2.Zip__c ='123456';
        testCase2.City__c ='test';
        testCase2.Country__c='USA';
        testCase2.Billing_Contact_Email__c ='test@test.com';		
        
        insert testCase2;             
        
        testCase2.NCSP_Opportunity__c = opp.id;
        update testCase2;
        
        testCase2.Contract_Status__c='Rejected';
		testCase2.Primary_Contract_Rejection_Reason__c ='Autopay';
        testCase2.Primary_Contract_Rejection_Reason_Detail__c ='Autopay not received';
        testCase2.Rejection_Comments__c = 'test';
        update testCase2;      
        Test.stopTest();
        
    }
    @isTest
	public static void TestNCSPCaseDateConfirmationFulfillment() 
    {   
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Test.startTest();
        //Create a new Account
        Account A= new Account();
        A.name= 'Test Account New';
        insert A;
        
        Contact testContact = new contact();
        testContact.FirstName ='test Contact';
        testContact.LastName ='test Contact';
        testContact.AccountId =a.id;
        testContact.Email='test@test.com';
        insert testContact;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'New Deal';
        opp.Primary_Product_Line__c='Data Centers';
        opp.Amount=1;
        opp.US_Federal_GSA_Pricing__c ='No';
        opp.CurrencyIsoCode ='USD';
        //opp.Pricebook2Id =testPricebook.id;
        //opp.Manager_Approval_Needed__c = 'No';
        insert opp;
        
       	Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            Username = 'testuser7878566555@example.com',
            CommunityNickname = 'testuser77',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'Test',
            FirstName = 'User',
            CompanyName = 'Test Company',
            Phone = '555-555-5555',
            Country ='test'
        );
        
        insert testUser;
        
        Case testCase2 = new Case();        
        system.debug('-----before case insert'); 
        testCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: Tech Services New Customer Setup').getRecordTypeId();
        testCase2.NCSP_Service_line__c ='CDR';       
        testCase2.AccountId = A.Id;
        testCase2.NCSP_Cust_Name__c ='Test Name';
        testCase2.Origin='Update';
        testCase2.Sales_Person_Name_Account_Manager__c =testUser.id;
        testCase2.Date_Contract_Signed__c =Date.Today();
        testCase2.Date_Paperwork_Received__c =Date.Today();
        testCase2.ContactId=testContact.id;
        testCase2.Address__c='test';
        testCase2.state__C ='test';
        testCase2.Zip__c ='123456';
        testCase2.City__c ='test';
        testCase2.Country__c='USA';
        testCase2.Billing_Contact_Email__c ='test@test.com';		
        
        insert testCase2;             
        
        testCase2.NCSP_Opportunity__c = opp.id;
        update testCase2;
        
        testCase2.Date_Confirmation_Fulfillment_Received__c = Date.Today();
        update testCase2;     
        Test.stopTest();
        
    }
    @isTest
	public static void TestNCSPCaseDateOrderFulfillment() 
    {   
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Test.startTest();
        //Create a new Account
        Account A= new Account();
        A.name= 'Test Account New';
        insert A;
        
        Contact testContact = new contact();
        testContact.FirstName ='test Contact';
        testContact.LastName ='test Contact';
        testContact.AccountId =a.id;
        testContact.Email='test@test.com';
        insert testContact;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'New Deal';
        opp.Primary_Product_Line__c='Data Centers';
        opp.Amount=1;
        opp.US_Federal_GSA_Pricing__c ='No';
        opp.CurrencyIsoCode ='USD';
        //opp.Pricebook2Id =testPricebook.id;
        //opp.Manager_Approval_Needed__c = 'No';
        insert opp;
        
       	Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            Username = 'testuse77r78785555@example.com',
            CommunityNickname = 'testuser77',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'Test',
            FirstName = 'User',
            CompanyName = 'Test Company',
            Phone = '555-555-5555',
            Country ='test'
        );
        
        insert testUser;
        
        Case testCase2 = new Case();        
        system.debug('-----before case insert'); 
        testCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: Tech Services New Customer Setup').getRecordTypeId();
        testCase2.NCSP_Service_line__c ='CDR';       
        testCase2.AccountId = A.Id;
        testCase2.NCSP_Cust_Name__c ='Test Name';
        testCase2.Origin='Update';
        testCase2.Sales_Person_Name_Account_Manager__c =testUser.id;
        testCase2.Date_Contract_Signed__c =Date.Today();
        testCase2.Date_Paperwork_Received__c =Date.Today();
        testCase2.ContactId=testContact.id;
        testCase2.Address__c='test';
        testCase2.state__C ='test';
        testCase2.Zip__c ='123456';
        testCase2.City__c ='test';
        testCase2.Country__c='USA';
        testCase2.Billing_Contact_Email__c ='test@test.com';		
        
        insert testCase2;             
        
        testCase2.NCSP_Opportunity__c = opp.id;
        update testCase2;
        
        testCase2.Date_Order_Fulfillment_Sent__c = Date.Today();
        testCase2.PO_Number__c ='12345';
        testCase2.PO_Amount__c = 55;
        update testCase2;     
        Test.stopTest();        
    }
    @isTest
	public static void TestNCSPCaseNonConversion() 
    {   
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        //Create a new Account
        Account A= new Account();
        A.name= 'Test Account New';
        insert A;
        
        Contact testContact = new contact();
        testContact.FirstName ='test Contact';
        testContact.LastName ='test Contact';
        testContact.AccountId =a.id;
        testContact.Email='test@test.com';
        insert testContact;
        
        Id testStandardPriceBook = Test.getStandardPricebookId();
        Id rt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
        Product2 testProd = new Product2(Name = '9999',
                                         recordTypeId=rt, 
                                         IsActive= true,
                                         Bill_Code_Classification__c='Storage');
        insert testProd;
        
        Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
        
        PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = testProd.Id, 
                                                                Pricebook2Id = testStandardPriceBook, 
                                                                UnitPrice = 1, IsActive = true, 
                                                                UseStandardPrice = false);
        insert testPriceBookEntry;
        
        PricebookEntry pbe_01 = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = testProd.Id,
            UnitPrice = 12000, IsActive = true);
        insert pbe_01;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'New Deal';
        opp.Primary_Product_Line__c='Data Centers';
        opp.Amount=1;
        opp.US_Federal_GSA_Pricing__c ='No';
        opp.CurrencyIsoCode ='USD';
        //opp.Pricebook2Id =testPricebook.id;
        //opp.Manager_Approval_Needed__c = 'No';
        insert opp;
        
        OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = opp.Id, unitPrice = 1,Product_Class__c ='Records Management',Product_Line__c='storage');
        insert oppProd;
        
        OpportunityContactRole OCR =  new OpportunityContactRole( OpportunityId = opp.Id, ContactId = testContact.id, Role ='Business User');
        insert OCR;
        
        ContentVersion cv1 = new ContentVersion(
            Title = 'File1',
            PathOnClient = 'TestFile1.pdf',
            VersionData = Blob.valueOf('Test file content 1'),
            FirstPublishLocationId = opp.Id
        );
        ContentVersion cv2 = new ContentVersion(
            Title = 'File2',
            PathOnClient = 'TestFile2.pdf',
            VersionData = Blob.valueOf('Test file content 2'),
            FirstPublishLocationId = opp.Id
        );

        insert new List<ContentVersion>{ cv1, cv2 };  
        
        opp.StageName = '5 - Signed/PO in';
        opp.IM_Servicing_Region__c = 'Aston';
        opp.IME_Reason_Won__c = 'test';
        opp.IM_Booked_Date__c = Date.Today();
        update opp;
        
       	Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            Username = 'testuser7878775555@example.com',
            CommunityNickname = 'testuser77',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'Test',
            FirstName = 'User',
            CompanyName = 'Test Company',
            Phone = '555-555-5555',
            Country ='test'
        );
        
        insert testUser;
        Test.startTest();
        Case testCase2 = new Case();        
        system.debug('-----before case insert'); 
        testCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: Tech Services New Customer Setup').getRecordTypeId();
        testCase2.NCSP_Service_line__c ='CDR';       
        testCase2.AccountId = A.Id;
        testCase2.NCSP_Cust_Name__c ='Test Name';
        testCase2.Origin='Update';
        testCase2.Sales_Person_Name_Account_Manager__c =testUser.id;
        testCase2.Date_Contract_Signed__c =Date.Today();
        testCase2.Date_Paperwork_Received__c =Date.Today();
        testCase2.ContactId=testContact.id;
        testCase2.Address__c='test';
        testCase2.state__C ='test';
        testCase2.Zip__c ='123456';
        testCase2.City__c ='test';
        testCase2.Country__c='USA';
        testCase2.Billing_Contact_Email__c ='test@test.com';		
        testCase2.Status = 'Welcome';
        insert testCase2;  
        testCase2.Date_Welcome_Call_Attempt_1__c = System.now();
        testCase2.NCSP_Opportunity__c = opp.id;    
       	testCase2.Status ='Non Conversion';
        testCase2.Non_Conversion_Reason__c ='Not Ready';
        testCase2.Case_Cancelled_Reason__c = 'Other';
        update testCase2;     
        Test.stopTest();        
    }
    @isTest
	public static void TestNCSPCaseAccutrac() 
    {   
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Test.startTest();
        //Create a new Account
        Account A= new Account();
        A.name= 'Test Account New';
        insert A;
        
        Contact testContact = new contact();
        testContact.FirstName ='test Contact';
        testContact.LastName ='test Contact';
        testContact.AccountId =a.id;
        testContact.Email='test@test.com';
        insert testContact;
        
        IM_Customer_Account__c testCustomer = new IM_Customer_Account__c();
        testCustomer.Name = 'Test';
        testCustomer.IM_Account__c = a.id;
        testCustomer.Source_System__c = 'ESS';
        testCustomer.IM_Inventory_System_Number__c ='123456';
        insert testCustomer;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'New Deal';
        opp.Primary_Product_Line__c='Data Centers';
        opp.Amount=1;
        opp.US_Federal_GSA_Pricing__c ='No';
        opp.CurrencyIsoCode ='USD';
        //opp.Pricebook2Id =testPricebook.id;
        //opp.Manager_Approval_Needed__c = 'No';
        insert opp;
        
       	Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            Username = 'testuser7878577555@example.com',
            CommunityNickname = 'testuser77',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'Test',
            FirstName = 'User',
            CompanyName = 'Test Company',
            Phone = '555-555-5555',
            Country ='test'
        );
        
        insert testUser;
        
        Case testCase2 = new Case();        
        system.debug('-----before case insert'); 
        testCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: New Customer Setup').getRecordTypeId();
        testCase2.NCSP_Service_line__c ='Accutrac';       
        testCase2.AccountId = A.Id;
        testCase2.NCSP_Cust_Name__c ='Test Name';
        testCase2.Origin='Update';
        testCase2.Sales_Person_Name_Account_Manager__c =testUser.id;
        testCase2.Date_Contract_Signed__c =Date.Today();
        testCase2.Date_Paperwork_Received__c =Date.Today();
        testCase2.ContactId=testContact.id;
        testCase2.Address__c='test';
        testCase2.state__C ='test';
        testCase2.Zip__c ='123456';
        testCase2.City__c ='test';
        testCase2.Country__c='USA';
        testCase2.Billing_Contact_Email__c ='test@test.com';		
        insert testCase2; 
        
        testCase2.Customer_ID__c = testCustomer.id;
        testCase2.NCSP_Opportunity__c = opp.id;
        update testCase2;
        Test.stopTest();        
    }
    @isTest
	public static void TestNCSPCaseServiceScheduleDate() 
    {   
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        //Create a new Account
        Account A= new Account();
        A.name= 'Test Account New';
        insert A;
        
        Billing_Cut_Off_Schedule__c bcos = new Billing_Cut_Off_Schedule__c();
        bcos.Billing_Cut_Off_Date__c = Date.today();
        bcos.Invoice_Mailing_Date__c = Date.today();
        bcos.Service_Line__c ='RM';
        bcos.Name='test1';
        bcos.Year__c = '2024';
        insert bcos;
        
        Contact testContact = new contact();
        testContact.FirstName ='test Contact';
        testContact.LastName ='test Contact';
        testContact.AccountId =a.id;
        testContact.Email='test@test.com';
        insert testContact;
        
        Id testStandardPriceBook = Test.getStandardPricebookId();
        Id rt = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
        Product2 testProd = new Product2(Name = '9999',
                                         recordTypeId=rt, 
                                         IsActive= true,
                                         Bill_Code_Classification__c='Storage');
        insert testProd;
        
        Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
        
        PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = testProd.Id, 
                                                                Pricebook2Id = testStandardPriceBook, 
                                                                UnitPrice = 1, IsActive = true, 
                                                                UseStandardPrice = false);
        insert testPriceBookEntry;
        
        PricebookEntry pbe_01 = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = testProd.Id,
            UnitPrice = 12000, IsActive = true);
        insert pbe_01;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'New Deal';
        opp.Primary_Product_Line__c='Data Centers';
        opp.Amount=1;
        opp.US_Federal_GSA_Pricing__c ='No';
        opp.CurrencyIsoCode ='USD';
        //opp.Pricebook2Id =testPricebook.id;
        //opp.Manager_Approval_Needed__c = 'No';
        insert opp;
        
        OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = pbe_01.Id, OpportunityId = opp.Id, unitPrice = 1,Product_Class__c ='Records Management',Product_Line__c='storage');
        insert oppProd;
        
        OpportunityContactRole OCR =  new OpportunityContactRole( OpportunityId = opp.Id, ContactId = testContact.id, Role ='Business User');
        insert OCR;
        
        ContentVersion cv1 = new ContentVersion(
            Title = 'File1',
            PathOnClient = 'TestFile1.pdf',
            VersionData = Blob.valueOf('Test file content 1'),
            FirstPublishLocationId = opp.Id
        );
        ContentVersion cv2 = new ContentVersion(
            Title = 'File2',
            PathOnClient = 'TestFile2.pdf',
            VersionData = Blob.valueOf('Test file content 2'),
            FirstPublishLocationId = opp.Id
        );

        insert new List<ContentVersion>{ cv1, cv2 };        
        
        opp.StageName = '5 - Signed/PO in';
        opp.IM_Servicing_Region__c = 'Aston';
        opp.IME_Reason_Won__c = 'test';
        opp.IM_Booked_Date__c = Date.Today();
        update opp;
        
       	Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];
        
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            Username = 'testuser778785555@example.com',
            CommunityNickname = 'testuser77',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'Test',
            FirstName = 'User',
            CompanyName = 'Test Company',
            Phone = '555-555-5555',
            Country ='test'
        );
        
        insert testUser;
        
        Case testCase2 = new Case();        
        system.debug('-----before case insert'); 
        testCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: DP New Customer Setup').getRecordTypeId();
        testCase2.NCSP_Service_line__c ='CDR';       
        testCase2.AccountId = A.Id;
        testCase2.NCSP_Cust_Name__c ='Test Name';
        testCase2.Origin='Update';
        testCase2.Sales_Person_Name_Account_Manager__c =testUser.id;
        testCase2.Date_Contract_Signed__c =Date.Today();
        testCase2.Date_Paperwork_Received__c =Date.Today();
        testCase2.ContactId=testContact.id;
        testCase2.Address__c='test';
        testCase2.state__C ='test';
        testCase2.Zip__c ='123456';
        testCase2.City__c ='test';
        testCase2.Country__c='USA';
        testCase2.Billing_Contact_Email__c ='test@test.com';		
        Test.startTest();
        insert testCase2;  
        
        testCase2.Service_Schedule_Date__c = Date.Today();
        testCase2.NCSP_Opportunity__c = opp.id;
        update testCase2;   
        Test.stopTest();
    }
	//Gitlab user Story #27422 end
    public static IM_Customer_Account__c createCustomerAccount(String districtBranchId , String systemCode){
        Market__c testMarket = new Market__c(name= 'test test2')  ;
        insert testMarket;
        ID accountRecordType;
        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account'];
        
        if(lstRecordType.size() > 0){
            
            accountRecordType = lstRecordType[0].ID;
            
        }
        IM_Country__c mainName = new IM_Country__c(Name='Test');
        insert mainName;
        //IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States');
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='Test');
        
        insert country;
        Account acc = new Account();
        acc.Name = 'Test Account New';
        acc.BillingCountry = 'Test';
        acc.BillingPostalCode = '11209';
        acc.BillingState = 'NY';
        acc.IM_Hierarchy_Level__c = 'Sales (Site)';
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
    
   /* static testMethod void Test_CAC_Case_DM_RecordType() {
        
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        //Create a new User
        User U = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
                          emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
        insert U; 
        
        /*List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
for(Trigger_Activation_Settings__c cs : customsettings){
if(cs.Object__c == 'Case') {
cs.Value__c='true';
updatesettings.add(cs);
}
}
update updatesettings; 
        
        //Create a new Account
        IM_Country__c mainName = new IM_Country__c(Name='Hello');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='Hello');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Hello';
        setting.object_name__c = 'Account';
        insert setting;
        Account A = new Account();
        A.Name = 'Test Account New';
        A.BillingCountry = 'Hello';
        A.BillingPostalCode = '11209';
        A.BillingState = 'NY';
        A.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert A;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.OwnerId = U.Id;
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'Renewal';
        opp.Lead_Source_Most_Recent__c = 'Email';
        opp.NCSP_Status__c='Custom Setup';
        opp.Billing_Country__c=mainName.id;// Added by Arjun - Billing country required 
        // insert the new opp
        insert opp;
        System.debug('----2282---queries used: ' + Limits.getQueries());
        
        test.startTest();
        Case c1 = new Case();        
        system.debug('-----before case insert'); 
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_DM').getRecordTypeId();
        c1.OwnerId = U.Id;        
        c1.AccountId = A.Id;
        c1.NCSP_Service_line__c='DMS';
        c1.Status = 'New';
        c1.Origin = 'Web';
        c1.Priority = 'Low';
        c1.IM_Division__c = 'Digital';
        c1.Subject = 'Test';
        c1.Description = 'Test';
        c1.Sales_Person_Name_Account_Manager__c = U.Id;
        c1.Setup_Type__c='Standard';
        c1.Date_Paperwork_Received__c=System.Now();
        c1.Transition_Date__c=System.now();   
        c1.NCSP_Opportunity__c= opp.Id;
        //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Service_Order_Required__c"
        //c1.Service_Order_Required__c = 'No';
        //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Reason_No_Service__c"
        //c1.Reason_No_Service__c = 'Local Market Handling';   
        
        Date dtToday = Date.today();
        Date dtTomo = dtToday.addDays(1);
        Date dtYest = dtToday.addDays(-1);
        /* W-000616
c1.CAC_First_Customer_Contact_Date__c = dtTomo;
c1.CAC_Intro_Date__c = dtTomo;
c1.CAC_Second_Customer_Contact_Date__c = dtTomo;
c1.CAC_Third_Customer_Contact_Date__c = dtTomo;*/
        //c1.Cost_Summary_Attempt_1__c = dtTomo;
        //c1.Cost_Summary_Attempt2__c = dtTomo;
        //c1.Cost_Summary_Attempt3__c = dtTomo;
        /*W-000616
c1.Customer_Update_Date__c = dtTomo;*/
        //c1.Date_Account_Inactivated__c = dtTomo;
        /* Begin - Case field deletion : 10373
c1.Date_Cancelled__c = dtTomo;
End - Case field deletion : 10373 */
        //c1.Date_Customer_Approval_Received__c = dtTomo;
        /*W-000616
c1.Date_Destruction_SR_Requested__c = dtTomo;*/
        //c1.Date_Destruction_Order_Created__c = dtTomo;
        /*W-000616
c1.Date_Email_Sent_To_Local_Leadership__c = dtTomo;*/
        //c1.Date_Followed_Up_W_Customer__c = dtTomo;
        //c1.Date_Inventory_Status_Confirmed__c = dtTomo;
        /*W-000616
c1.Date_Invoice_Created__c = dtTomo;*/
        //c1.Date_Invoice_Details_Package_Sent__c = dtTomo;
        /*W-000616
c1.Date_of_Invoice_Confirmation__c = dtTomo;
        //c1.Date_Ops_Confirmed_For_Timeline__c = dtTomo;
        
        c1.Confirm_Final_Service__c = dtTomo;
        /* W-000616
c1.Date_Owner_Established__c = dtTomo;

        c1.Date_Closure_Complete__c = dtTomo;
        //c1.Order_Scheduled_date__c = dtYest;
        c1.Customer_Request_Received_Date__c = dtTomo;
        /* W-000616
c1.Date_Sent_To_Closures__c = dtTomo;
        c1.CAC_Inactivate_Request__c = dtTomo;
        //c1.Estimated_Pay_Date__c = dtYest;
        //c1.Inactive_request_sent_to_Contracts_Admin__c = dtTomo;        
        c1.Rescheduled_Date__c = dtYest;    
        //c1.Estimated_Pay_Date__c = dtYest;    
        //c1.Order_Scheduled_date__c = dtYest;             
        c1.Date_Service_To_Be_Completed__c = dtYest;           
        c1.Date_Visit_Profile_To_Be_Inactivated__c = dtYest;   
        c1.Date_to_be_Moved_on_Call__c = dtYest;         
        
        try{
            insert  c1;
        }
        catch(Exception ex)
        {          
            System.assertEquals(ex.getTypeName(), 'System.DmlException');            
        }
        
        test.stopTest(); 
    }*/
    
    static testMethod void Testcodeincrease(){
        User U = [Select Id from User where id='00534000009jcZ5'];
        
        //Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];
        //Create a new User
        /*User U = new User(alias = 'smanda', email='srinu.mandalapu@testorg.com',
emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US',
localesidkey='en_US', profileid = prof.Id, Country = 'USA',
timezonesidkey='America/New_York', username='srinu.mandalapu@testorg.com', CurrencyIsoCode='USD');
insert U; */
        
        /*List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
for(Trigger_Activation_Settings__c cs : customsettings){
if(cs.Object__c == 'Case') {
cs.Value__c='true';
updatesettings.add(cs);
}
}
update updatesettings; */
        
        Group grp2 = [Select Type, Name, Id From Group where type='queue' and name = 'Data Entry'];
        //Create a new Account
        IM_Country__c mainName = new IM_Country__c(Name='Hello2');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='Hello2');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Hello';
        setting.object_name__c = 'Account';
        insert setting;
        Account A = new Account();
        A.Name = 'Test Account New';
        A.BillingCountry = 'Hello2';
        A.BillingPostalCode = '11209';
        A.BillingState = 'NY';
        A.IM_Hierarchy_Level__c = 'Sales (Site)';
        insert A;
        
        //Create a new Opportunity
        Opportunity opp = new Opportunity();
        opp.OwnerId = U.Id;
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.Type = 'Renewal';
        opp.Lead_Source_Most_Recent__c = 'Email';
        opp.NCSP_Status__c='Sent to NCSP';  
        opp.Billing_Country__c=mainName.id;
        // insert the new opp
        insert opp;
        System.debug('----2282---queries used: ' + Limits.getQueries());
        
        
        test.startTest();
        Case c1 = new Case();        
        system.debug('-----before case insert'); 
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('NCSP_Upsell').getRecordTypeId();
        c1.OwnerId = U.Id;        
        c1.AccountId = A.Id;
        c1.NCSP_Service_line__c='NSCP';
        c1.Status = 'New';
        c1.Origin = 'Email';
        c1.Priority = 'Low';
        c1.IM_Division__c = 'Digital';
        c1.Subject = 'Test';
        c1.Description = 'Test';
        c1.Sales_Person_Name_Account_Manager__c = U.Id;
        c1.Setup_Type__c='Standard';
        c1.Date_Paperwork_Received__c=System.Now();
        c1.Transition_Date__c=System.now();   
        c1.NCSP_Opportunity__c= opp.Id;
        //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Service_Order_Required__c"
        //c1.Service_Order_Required__c = 'No';
        //#8977 Delete 11 NCSP case field deletion (6/2/2022) :- Part 1 "Reason_No_Service__c"
        //c1.Reason_No_Service__c = 'Local Market Handling';   
        
        Date dtToday = Date.today();
        Date dtTomo = dtToday.addDays(1);
        Date dtYest = dtToday.addDays(-1);
        /* W-000616
c1.CAC_First_Customer_Contact_Date__c = dtTomo;
c1.CAC_Intro_Date__c = dtTomo;
c1.CAC_Second_Customer_Contact_Date__c = dtTomo;
c1.CAC_Third_Customer_Contact_Date__c = dtTomo;*/
        //c1.Cost_Summary_Attempt_1__c = dtTomo;
        //c1.Cost_Summary_Attempt2__c = dtTomo;
        //c1.Cost_Summary_Attempt3__c = dtTomo;
        /*W-000616
c1.Customer_Update_Date__c = dtTomo;*/
        //c1.Date_Account_Inactivated__c = dtTomo;
        /* Begin - Case field deletion : 10373
c1.Date_Cancelled__c = dtTomo;
End - Case field deletion : 10373 */
        //c1.Date_Customer_Approval_Received__c = dtTomo;
        /*W-000616
c1.Date_Destruction_SR_Requested__c = dtTomo;*/
        //c1.Date_Destruction_Order_Created__c = dtTomo;
        /*W-000616
c1.Date_Email_Sent_To_Local_Leadership__c = dtTomo;*/
        //c1.Date_Followed_Up_W_Customer__c = dtTomo;
        //c1.Date_Inventory_Status_Confirmed__c = dtTomo;
        /*W-000616
c1.Date_Invoice_Created__c = dtTomo;*/
        //c1.Date_Invoice_Details_Package_Sent__c = dtTomo;
        /*W-000616
c1.Date_of_Invoice_Confirmation__c = dtTomo;*/
        //c1.Date_Ops_Confirmed_For_Timeline__c = dtTomo;
        
        c1.Confirm_Final_Service__c = dtTomo;
        /* W-000616
c1.Date_Owner_Established__c = dtTomo;
*/
        c1.Date_Closure_Complete__c = dtTomo;
        //c1.Order_Scheduled_date__c = dtYest;
        c1.Customer_Request_Received_Date__c = dtTomo;
        /* W-000616
c1.Date_Sent_To_Closures__c = dtTomo;*/
        c1.CAC_Inactivate_Request__c = dtTomo;
        //c1.Estimated_Pay_Date__c = dtYest;
        //c1.Inactive_request_sent_to_Contracts_Admin__c = dtTomo;        
        c1.Rescheduled_Date__c = dtYest;    
        //c1.Estimated_Pay_Date__c = dtYest;    
        //c1.Order_Scheduled_date__c = dtYest;             
        c1.Date_Service_To_Be_Completed__c = dtYest;           
        c1.Date_Visit_Profile_To_Be_Inactivated__c = dtYest;   
        c1.Date_to_be_Moved_on_Call__c = dtYest;
        c1.Date_Sent_to_Contracts_Admin__c= dtToday;
        c1.Date_Contract_Approved__c=dtToday;
        c1.Date_Welcome_Call_Attempt_1__c = DateTime.now().addDays(-1);
        
        
        
        try{
            insert  c1;
        }
        catch(Exception ex)
        {          
            Boolean flag =  ex.getMessage().contains('Script-thrown exception') ? true : false;
            System.assertEquals(flag, false);       
            
        }
        
        try{
            c1.Date_Contract_Approved__c=dtToday;
            
            update c1;
        }
        catch(Exception ex)
        {          
            Boolean flag =  ex.getMessage().contains('Script-thrown exception') ? true : false;
            System.assertEquals(flag, false);       
            
        }
        
        test.stopTest(); 
        
    }
    
}
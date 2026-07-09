// Name:TestClosureActionController
// Description: This class contains unit tests for validating the behavior of ClosureActionController class
// Created By: Vinod Kumar
// Created date : 21 September 2010
// ************************Version Updates********************************************
//
// Updated Date     Updated By      Update Comments 
//  
// 
// ************************************************************************************ 
@isTest
private class TestClosureActionController {

    static testMethod void myTestActionTypeTask() {
        // TO DO: implement unit test
        // Create a task detail
       ID bHourID;
       List<BusinessHours> lstBHour =[Select b.Id From BusinessHours b Limit 1];
       if(lstBHour.size() > 0){        	
        	bHourID = lstBHour[0].ID;        	
        }             
       //insert a task detail
       Task_Details__c td = new Task_Details__c();
       td.Business_area__c = 'Business';
       td.SLA_Time_Type__c = 'Business';
       td.Unique_Task__c = 'TestTaskDetail';
       td.Subject__c = 'TestTaskDetail';
       td.SLA__c = 10.0;
       td.Business_Hours__c = bHourID;       
       insert td;   
        Closure_Action__c testClosure = new Closure_Action__c();
        ApexPages.StandardController std = new ApexPages.StandardController(testClosure);
        ClosureActionController cActionCtl = new ClosureActionController(std);
        List<SelectOption> lstOptCaseField = cActionCtl.getCaseFields();
        List<SelectOption> lstOptCaseFieldDatType= cActionCtl.getDataTypes();  
        string s1 = cActionCtl.dateTimeString;
        string s2 = cActionCtl.dateString;
        /*Begin - Added as part of API verion upgradation code coverage issue */
        String selAPIName = cActionCtl.selectedAPIName;
        String seldataType = cActionCtl.selectedDatatype;
        String selText = cActionCtl.selectedText;
        String selPicklistVal = cActionCtl.selectedPicklistValue;
        String selDate = cActionCtl.dateSelected;
        String selValueLookup = cActionCtl.selectedValueLookup;
        String selLookupId = cActionCtl.selectedLookupId;
        String actionId = cActionCtl.actionId;
        String tempStr = cActionCtl.tempStr;
        String dateTimesel = cActionCtl.dateTimeSelected;
        /* End -  Added as part of API verion upgradation code coverage issue  */
        Pagereference pager = page.createClosureAction;
        test.setCurrentPage(pager);
        PageReference p = cActionCtl.submit();   
        testClosure.Action_Type__c = 'Task'; 
        testClosure.Task_ID__c = td.id;
        testClosure.Task_Action_Id__c ='';    
        std = new ApexPages.StandardController(testClosure);
        cActionCtl = new ClosureActionController(std);
        p = cActionCtl.submit(); 
        system.assertEquals(cActionCtl.isTaskAction,true);       
        testClosure.Task_Action_Id__c ='TestAction';   
        std = new ApexPages.StandardController(testClosure);
        cActionCtl = new ClosureActionController(std);
        p = cActionCtl.submit(); 
        
    }
   static testMethod void myTestActionTypeCaseFieldUpdate() {
        // TO DO: implement unit test
        // Create a task detail
       ID bHourID;
       List<BusinessHours> lstBHour =[Select b.Id From BusinessHours b Limit 1];
       if(lstBHour.size() > 0){        	
        	bHourID = lstBHour[0].ID;        	
        } 
            
       //insert a task detail
       Task_Details__c td = new Task_Details__c();
       td.Business_area__c = 'Business';
       td.SLA_Time_Type__c = 'Business';
       td.Unique_Task__c = 'TestTaskDetail';
       td.Subject__c = 'TestTaskDetail';
       td.SLA__c = 10.0;
       td.Business_Hours__c = bHourID;       
       insert td;   
        Closure_Action__c testClosure = getClosure(td);
              
        ApexPages.StandardController std = new ApexPages.StandardController(testClosure);
        ClosureActionController cActionCtl = new ClosureActionController(std);
        List<SelectOption> lstOptCaseField = cActionCtl.getCaseFields();
        List<SelectOption> lstOptCaseFieldDatType= cActionCtl.getDataTypes();
       	
        PageReference p = cActionCtl.submit();
        testClosure.Case_Field_API_Name__c = 'City__c';
        testClosure.Case_Field_Data_Type__c = 'STRING';
         //testClosure.Value_To_Assign__c = DateTime.now();       
        std = new ApexPages.StandardController(testClosure);
        cActionCtl = new ClosureActionController(std);
        p = cActionCtl.submit();
         // DateTime 
        testClosure = getClosure(td);
        testClosure.Case_Field_API_Name__c = 'Date_of_Final_Service__c';
        testClosure.Case_Field_Data_Type__c = 'DATETIME';
        //testClosure.Value_To_Assign__c = Date.today();
        std = new ApexPages.StandardController(testClosure);
        cActionCtl = new ClosureActionController(std);
        // for date field
        testClosure = getClosure(td); 
        testClosure.Case_Field_API_Name__c = 'CAC_Inactivate_Request__c';
        testClosure.Case_Field_Data_Type__c = 'Date';
        //testClosure.Value_To_Assign__c = Date.today();
         std = new ApexPages.StandardController(testClosure);
        cActionCtl = new ClosureActionController(std);
        p = cActionCtl.submit();
        // bolean field
        testClosure = getClosure(td);
        testClosure.Case_Field_API_Name__c = 'Escalation__c';
        testClosure.Case_Field_Data_Type__c = 'BOOLEAN';
        //testClosure.Value_To_Assign__c = Date.today();
        std = new ApexPages.StandardController(testClosure);
        cActionCtl = new ClosureActionController(std);
        p = cActionCtl.submit();
         // MultiPickList field
        testClosure = getClosure(td);
        testClosure.Case_Field_API_Name__c = 'Contract_Admin_Rejection_Reason_NCSP__c';
        testClosure.Case_Field_Data_Type__c = 'MULTIPICKLIST';
        //testClouser.Value_To_Assign__c = Date.today();
        std = new ApexPages.StandardController(testClosure);
        cActionCtl = new ClosureActionController(std);
        p = cActionCtl.submit();
        // PickList field
        testClosure.Case_Field_API_Name__c = 'Inactivate_Request__c';
        testClosure.Case_Field_Data_Type__c = 'PICKLIST';
        //testClouser.Value_To_Assign__c = Date.today();
        std = new ApexPages.StandardController(testClosure);
        cActionCtl = new ClosureActionController(std);
        p = cActionCtl.submit();
       
        //DOUBLE  
        testClosure = getClosure(td);
        testClosure.Case_Field_API_Name__c = 'SLA_Days__c';
        testClosure.Case_Field_Data_Type__c = 'DOUBLE';
        //testClosure.Value_To_Assign__c = Date.today();
        std = new ApexPages.StandardController(testClosure);
        cActionCtl = new ClosureActionController(std);
        // Refrence
        testClosure = getClosure(td);
        
        ID accountRecordType;
        List<RecordType> lstRecordType =[Select r.SobjectType, r.Id From RecordType r where sobjectType ='Account' and r.name='Standard Account'];
        
        if(lstRecordType.size() > 0){
        	
        	accountRecordType = lstRecordType[0].ID;
        	
        }
       	
       	IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;
       
        Account acc = new Account(Name = 'testAccount1',RecordTypeId =accountRecordType,BillingCountry = 'United States');
        insert acc; 
        IM_Customer_Account__c custAcc = new IM_Customer_Account__c();
        custAcc.Name = 'Test'+ string.valueOf( Math.random());
        custAcc.IM_Customer_Account_Name__c = 'Test Account Name';
        custAcc.IM_District_Branch_Id__c = '101';
        custAcc.IM_Source_System_Code__c = 'Test';
        custAcc.Source_System__c = 'SB NA';
        custAcc.IM_Account__c = acc.Id;
        insert custAcc;   
        testClosure.Case_Field_API_Name__c = 'Customer_ID__c';
        testClosure.Case_Field_Data_Type__c = 'REFRENCE';
       // testClosure.Value_To_Assign__c = custAcc.ID;
       // testClosure;
        std = new ApexPages.StandardController(testClosure);
        cActionCtl = new ClosureActionController(std);
    }
    public static Closure_Action__c getClosure( Task_Details__c td)
    {
    	Closure_Action__c testClosure = new Closure_Action__c();
        testClosure.Action_Type__c = 'Case field Update';
        testClosure.Task_Action_Id__c = 'TestTask';
        testClosure.Task_ID__c =  td.id;
        testClosure.Name = 'testClosure';
    	return testClosure;
    }
    public static Closure_Action__c getClosureToCoverError( Task_Details__c td)
    {
    	Closure_Action__c testClosure = new Closure_Action__c();
      //  testClosure.Action_Type__c = 'Case field Update';
        testClosure.Task_Action_Id__c = 'TestTask';
        testClosure.Task_ID__c =  td.id;
        testClosure.Name = 'testClosure';
    	return testClosure;
    }
}
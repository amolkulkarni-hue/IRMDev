/****************************** 
Developer Name    : Madhu Paladugu

Date              : 6/27/13

Company Name      : CloudFountain Inc.

Purpose           : This class is used as test utility for class "ChatterActionOnCaseController"

Case Number       : 01512696

********************************/  

@isTest(seeAllData=false)
public class Test_ChatterActionOnCaseController{
    
    public static case testCase;
    
    public static void setup() 
    {         
        ID r =  DataFactory.getRecordTypeId('Case','IM Customer Data Management (CDM)');
        
        //insert test data
        testCase=new case();        
        testCase.Related_To__c='Cases';
        testCase.Issue__c='Enhancement';
        testCase.recordtypeId=r;
        testCase.Status='New';
        testCase.Subject='test case';
        testCase.Description='test desciption';
        //#8989 Delete 10 case field deletion :- Part 1;
        //testCase.Estimated_IT_Dev_Effort_hrs__c=50;
        /* #8991 Delete 10 case field deletion :- Part 3 "IM_Division_Impacted__c" */
        //testCase.IM_Division_Impacted__c='Global';
        testCase.Development_Status__c='1.new';
        
        insert testCase;
    }
    
    
    static testMethod void doTest(){
        
        setup();
        //create standard controller
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        
        //create contriller instance
        ChatterActionOnCaseController controller=new ChatterActionOnCaseController(sc);
        
        controller.ApproveUAT();
        controller.ApproveProd();
        controller.Cancel();
        
        try
        {      
            //for more coverage
            testCase.Status='Closed';
            update testCase;
        }
        catch(Exception ex)
        {
        }
        ApexPages.StandardController sc1 = new ApexPages.StandardController(testCase);
        
        //create contriller instance
        ChatterActionOnCaseController controller1=new ChatterActionOnCaseController(sc1);                
    }
    
    @isTest(SeeAllData=true)
    static void doTest1()
    {       
        setup();
        test.startTest();
        User testUsr = TestingUtils.createUser('cr',true);
        testCase.NSCP_Case_Creator_Name__c=testUsr.id;
        testCase.IM_Employee_Contact__c=testUsr.id;
        testCase.Contract_Status__c='Rejected';
        update testCase;
        //create standard controller
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        
        //create contriller instance
        ChatterActionOnCaseController controller=new ChatterActionOnCaseController(sc);
        
        controller.SubmitToIT();
        
        test.stopTest();
    }
   
    @isTest(SeeAllData=true)
    static void doTest2()
    {
        setup();        
        ID r1 =  DataFactory.getRecordTypeId('Case','NCSP: DMS');
        testCase.Contract_Status__c='Accepted';
        update testCase;
        test.startTest();           
            testCase.recordtypeId=r1;
            User testUsr = TestingUtils.createUser('cr',true);
            testCase.NSCP_Case_Creator_Name__c=testUsr.id;
            testCase.IM_Employee_Contact__c=testUsr.id;
            testCase.Contract_Status__c='Rejected';
            testCase.Rejection_Comments__c='Test';
            testCase.Primary_Contract_Rejection_Reason__c='Wrong Contract Version';
            testCase.Primary_Contract_Rejection_Reason_Detail__c='Incorrect dates';
            update testCase;
            //create standard controller
            ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
            
            //create contriller instance
            ChatterActionOnCaseController controller=new ChatterActionOnCaseController(sc);        
            controller.SubmitToIT();        
        test.stopTest();
    }
}
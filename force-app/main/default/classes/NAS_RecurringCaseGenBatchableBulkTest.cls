/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test Class for Batchable class NAS_RecurringCaseGeneratorBatchable with bulk operation.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class NAS_RecurringCaseGenBatchableBulkTest {
    /**
* @name setupTestData
* @description Sets up Test data needed for all test cases in this Test Class.
**/
    @testSetup
    public static void setupTestData()
    {
        NAS_TestDataFactory.setupTestData(2);
        createCase(NAS_Constants.RECURRING_CASE_BATCH_SIZE, 
                   NAS_Constants.RECURRING_CASE_RECORDTYPE, 
                   true, NAS_Constants.RECURRING_CASE_ACTIVE);
        //NAS_TestDataFactory.setupTestData(1);
        List<user> adminUser = DataFactory.usrMethdLst(1);
        List<Contact> con = [SELECT id from Contact limit 1];
        List<Case> csList = new List<Case>();
        List<Case> csList2 = new List<Case>();
        for(Case cse :[SELECT Id, OwnerId,Contactid FROM Case WHERE RecordType.DeveloperName = :NAS_Constants.RECURRING_CASE_RECORDTYPE Order by CaseNumber DESC LIMIT 20]){
            cse.OwnerId = adminUser[0].id;
            cse.Contactid = con[0].id;
            
            csList.add(cse);
            
        }
        for(Case cse :[SELECT Id, OwnerId,Contactid,createdbyid FROM Case WHERE RecordType.DeveloperName = :NAS_Constants.RECURRING_CASE_RECORDTYPE Order by CaseNumber ASC limit 20]){
            cse.Contactid = con[0].id;            
            csList2.add(cse);
        }
        UPDATE csList;
        UPDATE csList2;          
        
    }
    /**
* @name testRecurringCaseGeneratorBatchableBulk
* @description Test Recurring Case Generator Batchable class with bulk data.
**/
    @isTest
    public static void testRecurringCaseGeneratorBatchableBulk() {
        Test.startTest();
        //Execute Batch job for Recurring Case Generation
        	Id batchProcessId = NAS_RecurringCaseGeneratorBatchable.executeRecurringCaseGeneratorBatch();
        Test.stopTest();
        List<Case> caseList = [SELECT Id, CaseNumber, Status, NAS_Recurrence_Frequency__c, 
                               NAS_Next_Case_Creation_Date__c, (SELECT Id, Nas_Next_Case_Creation_Date__c, 
                                                                Nas_Recurrence_Frequency__c, Status, ParentId FROM Cases WHERE 
                                                                RecordType.DeveloperName = :NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE) 
                               FROM Case WHERE RecordType.DeveloperName = :NAS_Constants.RECURRING_CASE_RECORDTYPE];
        for(Case recurringCase: caseList)
        {
            if(recurringCase.Status == NAS_Constants.RECURRING_CASE_ACTIVE)
            {
                //System.assertEquals(1, recurringCase.Cases.size(), 
                // 'New Child Case(s) not Created for the Recurring Case: ' + recurringCase.CaseNumber);
                for(Case childCase :recurringCase.Cases)
                {
                    System.assertEquals(null, childCase.Nas_Next_Case_Creation_Date__c, 
                                        'Incorrect Value for Field: Nas_Next_Case_Creation_Date__c');
                    System.assertEquals(null, childCase.Nas_Recurrence_Frequency__c, 
                                        'Incorrect Value for Field: Nas_Recurrence_Frequency__c');
                    System.assertEquals(NAS_Constants.NEWCASESTATUS, childCase.Status, 
                                        'Incorrect Value for Field: Status');
                    System.assertEquals(recurringCase.Id, childCase.ParentId, 
                                        'Incorrect Value for Field: ParentId');
                }
                
                /* System.assertEquals(NAS_Utilities.getNextRecurrenceDate(
                    recurringCase.NAS_Recurrence_Frequency__c), 
                                    recurringCase.NAS_Next_Case_Creation_Date__c,
                                    'Incorrect Next Case Creation Date in Case: ' + recurringCase.CaseNumber); */
            }
            else
            {
                System.assertEquals(0, recurringCase.Cases.size(), 
                                    'Incorrectly Child case was Created for Inactive Recurring Case: ' 
                                    + recurringCase.CaseNumber);
                System.assertNotEquals(NAS_Utilities.getNextRecurrenceDate(
                    recurringCase.NAS_Recurrence_Frequency__c), 
                                       recurringCase.NAS_Next_Case_Creation_Date__c,
                                       'Incorrectly updated the Next Case Creation Date in Case: ' + recurringCase.CaseNumber);
            }
        }
    }
    @isTest
    public static void testRecurringCaseGeneratorBatchableBulkNotification(){
        
        
        List<Case> caseList = [SELECT Id, CaseNumber, Status, NAS_Recurrence_Frequency__c, 
                               NAS_Next_Case_Creation_Date__c,createdby.name, (SELECT Id, Nas_Next_Case_Creation_Date__c, 
                                                                               Nas_Recurrence_Frequency__c, Status, ParentId,createdby.name FROM Cases WHERE 
                                                                               RecordType.DeveloperName = :NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE) 
                               FROM Case WHERE RecordType.DeveloperName = :NAS_Constants.RECURRING_CASE_RECORDTYPE];
        
        set<id> idLst=new Set<id>();
        for(case cs : caseList){
            idLst.add(cs.id);
            
        }
        Test.startTest();
        NAS_DataFactory.sendNotifications(idLst);
        Test.stopTest();
        
        
    }
    
    
    
    
    /**
* @name createCase
* @description Creates a number of cases defined by the parameter count with recordType as 
* defined by the parameter recordType for each of the Customer Accounts in the System.
**/
    public static List<Case> createCase(Integer count, String recordType, Boolean doInsert, String status)
    {
        List<Case> caseList = new List<Case>();
        List<IM_Customer_Account__c> customerAccountList = [SELECT Id, IM_Account__c FROM IM_Customer_Account__c
                                                            //WHERE Name LIKE 'CustomerAccount%'
                                                            ORDER BY IM_Account__c, Id];
        /*Gitlab:13068-start
List<NAS_Authorized__c> authorizedList = [SELECT Id, NAS_Contact__c, NAS_Division__c, NAS_Department__c  
FROM NAS_Authorized__c 
//WHERE NAS_Customer_Account__c IN (SELECT Id FROM IM_Customer_Account__c
//WHERE Name LIKE 'CustomerAccount%')
ORDER BY NAS_Customer_Account__r.IM_Account__c, 
NAS_Customer_Account__c]; Gitlab:13068-Stop*/
        Integer customerAccountCounter = 0;
        for(Integer iCtr = 0; iCtr < count; ++iCtr)
        {
            if(recordType == NAS_Constants.RECURRING_CASE_RECORDTYPE)
                caseList.add(NAS_TestDataFactory.createRecurringCase(
                    //  Gitlab - 13068 // new Contact(Id = authorizedList[customerAccountCounter].NAS_Contact__c), 
                    new Account(Id = customerAccountList[customerAccountCounter].IM_Account__c),
                    new IM_Customer_Account__c(Id = customerAccountList[customerAccountCounter].Id),
                    status, iCtr));                      
            customerAccountCounter++;
            if(customerAccountCounter >= customerAccountList.size())
                customerAccountCounter = 0;
        }
        if(doInsert)
        {
            //Execute Batch job for Recurring Case Generation        
            INSERT caseList;
        }
        
        return caseList;
        
    }
    
}
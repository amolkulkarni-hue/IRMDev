/**
* Class: ContractHelperTest
*
* Author: Vidya Sagar Hadpad
*
* Date Created: 06.19.2020
*
* Purpose: This class is used as test class for ContractTrigger,ContractTriggerHandler.cls and ContractHelper.cls
* 
*/
@isTest
public class ContractHelperTest {
    
    /*	Method 		: datasetup
	 *  Description : This method is used to create test data
	 */
    @TestSetup
    static void datasetup()
    {
        test.startTest();
        Account acct = GenerateTestData.createAccount();
        IM_Country__c IMCountry = GenerateTestData.createIMCountry();
        insert IMCountry;
        List<Contract> IMEContrat_List = new List<Contract>();
        IMEContrat_List.add(GenerateTestData.createIMEContract(acct.Id,IMCountry.Id,App_Constants.RT_ID_IME_ADDENDUM_CONTRACT,App_Constants.CONTRACT_TERM_FIXED_TERM));
        IMEContrat_List.add(GenerateTestData.createIMEContract(acct.Id,IMCountry.Id,App_Constants.RT_ID_IME_ADDENDUM_CONTRACT,App_Constants.CONTRACT_TERM_EVERGREEN));
        IMEContrat_List.add(GenerateTestData.createIMEContract(acct.Id,IMCountry.Id,App_Constants.RT_ID_IME_ADDENDUM_CONTRACT,App_Constants.CONTRACT_TERM_EVERGREEN_OPEN_ROLLING));
        IMEContrat_List[2].ContractTerm = null; // according to validation rule for evergreen open rolling contract term type, contract term and renewal term should be null
        IMEContrat_List[2].IM_Renewal_Term__c = null;
        insert IMEContrat_List;
        test.stopTest();
    }
    
    static testmethod void IMEContractTest(){        
        test.startTest();
        list<Contract> IMContracts = [select id,IME_Expiration_Notice_days__c,IME_Expiration_Notice_Date__c,IME_Contract_Term_Type__c,IME_Index_Storage__c,IME_Capped_Percentage_Storage__c,IME_End_of_Fixed_Pricing_Period_Storage__c from Contract];
        IMContracts[0].IME_Expiration_Notice_days__c = null;
		IMContracts[1].IME_Expiration_Notice_days__c = null;
        IMContracts[2].IME_Expiration_Notice_days__c = null;
        update IMContracts;  
        system.assertNotEquals(IMContracts[0].IME_Expiration_Notice_Date__c, null);
        system.assertNotEquals(IMContracts[1].IME_Expiration_Notice_Date__c, null);
        IMContracts[0].IM_Renewal_Term__c = null;
		IMContracts[2].IM_Renewal_Term__c = null;
        IMContracts[1].ContractTerm = 1;
        IMContracts[1].startdate = system.today()-40;
        update IMContracts;
        system.assertEquals(IMContracts[2].IME_Expiration_Notice_Date__c, null);
        IMContracts[0].IME_Expiration_Notice_days__c = 60;
		IMContracts[1].IME_Expiration_Notice_days__c = 60;
        IMContracts[2].IME_Expiration_Notice_days__c = 60;
        IMContracts[1].startdate = system.today() - 30;
        update IMContracts;
        IMContracts[1].startdate = system.today()-40;
        IMContracts[1].IM_Renewal_Term__c = 0;
        IMContracts[1].IME_Expiration_Notice_days__c = null;
        update IMContracts[1];
        system.assertEquals(IMContracts[0].IM_Renewal_Term__c, null);
        delete IMContracts;      
        // deleted contracts Restored
        undelete IMContracts;
        test.stopTest(); 
    }
    
     @isTest
    static void testCreateContract() {
        // Create a test RecordTypeId
        RecordType recType = [SELECT Id FROM RecordType WHERE SObjectType = 'Contract' AND DeveloperName = 'IM_Contract' LIMIT 1];
        
        // Call the CreateContract method
        Contract resultContract = ContractHelperClass.CreateContract(recType.Id);
        
            }
}
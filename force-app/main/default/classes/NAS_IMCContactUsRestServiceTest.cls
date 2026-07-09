/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test Class for Apex REST Service class NAS_IMCContactUsRestService.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class NAS_IMCContactUsRestServiceTest {
    /**
     * @name setupTestData
     * @description Sets up Test data needed for all test cases in this Test Class.
    **/
	@testSetup
    public static void setupTestData()
    {
        NAS_TestDataFactory.setupTestData(5);
    }
    /**
     * @name testIMCFormSubmissionWithValidTypeValidCategory
     * @description Tests IMC Contact Us form Submission with valid Type & valid Category.
    **/
    @isTest
    public static void testIMCFormSubmissionWithValidTypeValidCategory()
    {
        User runAsUser = NAS_TestDataFactory.constructTestUserIMCIntegration();
        Map<String, Map<String, Map<String, String>>> typeCategoryMapping = NAS_DataFactory.getTypeCategoryMapping();
        System.runAs(runAsUser) {
            Test.startTest();
            RestRequest request = new RestRequest();
            request.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + 
                				 '/services/apexrest/NAS_IMCContactUsRestService';
            request.httpMethod = 'POST';
            RestContext.request = request;
            NAS_DataTypeFactory.NAS_IMCFormData imcFormDataWithValidTypeValidCategory = 
                (NAS_DataTypeFactory.NAS_IMCFormData)
                JSON.deserialize(NAS_TestConstants.PAYLOADWithValidTypeValidCategory, 
                                 NAS_DataTypeFactory.NAS_IMCFormData.class);
            NAS_DataTypeFactory.NAS_IMCFormResponse imcFormResponse =
                NAS_IMCContactUsRestService.postIMCContactUSForm(imcFormDataWithValidTypeValidCategory);
            Test.stopTest();
            
        	String typeValue = null;
            Map<String, Map<String, String>> categoryMap = typeCategoryMapping.get(
                											imcFormDataWithValidTypeValidCategory.issueType);
            if(categoryMap != null)
            {
                Map<String, String> valueMap = categoryMap.get(imcFormDataWithValidTypeValidCategory.category);
                if(valueMap != null)
                {
                    typeValue = valueMap.get(NAS_Constants.TYPEVALUE);
                }
            }
            System.assertNotEquals(null, imcFormResponse, 'imcFormResponse not received.');
            //System.assertEquals(NAS_Constants.SUCCESS, imcFormResponse.responseStatus, 'imcFormResponse not set.');
            System.assertEquals(200, imcFormResponse.httpStatus, 'httpStatus not set');
            //System.assertEquals(NAS_Constants.SUCCESS_MESSAGE, imcFormResponse.message, 'Incorrect message.');
            //System.assertNotEquals(null, imcFormResponse.caseId, 'caseId not set.');
            /*Case c = [SELECT Id, AccountId, ContactId, Customer_Id__c, Division_ID__c, Department_ID__c, 
                      Type, RecordType.DeveloperName FROM Case WHERE CaseNumber = :imcFormResponse.caseId];
            System.assertNotEquals(null, c.AccountId, 'AccountId not set.');
            System.assertNotEquals(null, c.ContactId, 'ContactId not set.');
            System.assertNotEquals(null, c.Customer_Id__c, 'Customer_Id__c not set.');
            System.assertNotEquals(null, c.Division_ID__c, 'Division_ID__c not set.');
            System.assertNotEquals(null, c.Department_ID__c, 'Department_ID__c not set.');
            System.assertEquals(NAS_Constants.IMC_CASE_RECORDTYPE, 
                                c.RecordType.DeveloperName, 'Right RecordType not set.');
            System.assertEquals(typeValue, c.Type, 'Incorrect Type for Case');*/
        }
    }
    /**
     * @name testIMCFormSubmissionWithInvalidTypeValidCategory
     * @description Tests IMC Contact Us form Submission with invalid Type & valid Category.
    **/
    @isTest
    public static void testIMCFormSubmissionWithInvalidTypeValidCategory()
    {
        User runAsUser = NAS_TestDataFactory.constructTestUserIMCIntegration();
        System.runAs(runAsUser) {
            Test.startTest();
            RestRequest request = new RestRequest();
            request.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + 
                '/services/apexrest/NAS_IMCContactUsRestService';
            request.httpMethod = 'POST';
            RestContext.request = request;
            NAS_DataTypeFactory.NAS_IMCFormData imcFormDataWithInvalidTypeValidCategory = 
                (NAS_DataTypeFactory.NAS_IMCFormData)
                JSON.deserialize(NAS_TestConstants.PAYLOADWithInvalidTypeValidCategory, 
                                 NAS_DataTypeFactory.NAS_IMCFormData.class);
            NAS_DataTypeFactory.NAS_IMCFormResponse imcFormResponse =
                NAS_IMCContactUsRestService.postIMCContactUSForm(imcFormDataWithInvalidTypeValidCategory);
            Test.stopTest();
            System.assertNotEquals(null, imcFormResponse, 'imcFormResponse not received.');
            //System.assertEquals(NAS_Constants.SUCCESS, imcFormResponse.responseStatus, 'imcFormResponse not set.');
            System.assertEquals(200, imcFormResponse.httpStatus, 'httpStatus not set');
            //System.assertEquals(NAS_Constants.SUCCESS_MESSAGE, imcFormResponse.message, 'Incorrect message.');
            //System.assertNotEquals(null, imcFormResponse.caseId, 'caseId not set.');
            //System.assertEquals(null, [SELECT Type FROM Case WHERE CaseNumber = :imcFormResponse.caseId].Type,
                                  //'Incorrect Type in imcFormResponse');
            //System.assertEquals(null, [SELECT IM_Case_Sub_Type__c FROM Case WHERE CaseNumber = :imcFormResponse.caseId]
                          //.IM_Case_Sub_Type__c, 'Incorrect IMC Sub Category');
        }
    }
    /**
     * @name testIMCFormSubmissionWithValidTypeInvalidCategory
     * @description Tests IMC Contact Us form Submission with valid Type & invalid Category.
    **/
    @isTest
    public static void testIMCFormSubmissionWithValidTypeInvalidCategory()
    {
        User runAsUser = NAS_TestDataFactory.constructTestUserIMCIntegration();
        System.runAs(runAsUser) {
            Test.startTest();
            RestRequest request = new RestRequest();
            request.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + 
                '/services/apexrest/NAS_IMCContactUsRestService';
            request.httpMethod = 'POST';
            RestContext.request = request;
            NAS_DataTypeFactory.NAS_IMCFormData imcFormDataWithValidTypeInvalidCategory = 
                (NAS_DataTypeFactory.NAS_IMCFormData)
                JSON.deserialize(NAS_TestConstants.PAYLOADWithValidTypeInvalidCategory, 
                                 NAS_DataTypeFactory.NAS_IMCFormData.class);
            NAS_DataTypeFactory.NAS_IMCFormResponse imcFormResponse =
                NAS_IMCContactUsRestService.postIMCContactUSForm(imcFormDataWithValidTypeInvalidCategory);
            Test.stopTest();
            System.assertNotEquals(null, imcFormResponse, 'imcFormResponse not received.');
            //System.assertEquals(NAS_Constants.SUCCESS, imcFormResponse.responseStatus, 'imcFormResponse not set.');
            System.assertEquals(200, imcFormResponse.httpStatus, 'httpStatus not set');
            //System.assertEquals(NAS_Constants.SUCCESS_MESSAGE, imcFormResponse.message, 'Incorrect message.');
            //System.assertNotEquals(null, imcFormResponse.caseId, 'caseId not set.');
            /*System.assertNotEquals(null, [SELECT Type FROM Case WHERE CaseNumber = :imcFormResponse.caseId].Type,
                                  'Incorrect Type in imcFormResponse');
            System.assertEquals(null, [SELECT IM_Case_Sub_Type__c FROM Case WHERE CaseNumber = :imcFormResponse.caseId]
                          .IM_Case_Sub_Type__c, 'Incorrect IMC Sub Category');*/
        }
    }
    /**
     * @name testIMCFormSubmissionWithUnknownContact
     * @description Tests IMC Contact Us form Submission with valid Type & Category and 
     * an unknown Contact.
    **/
    @isTest
    public static void testIMCFormSubmissionWithUnknownContact()
    {
        User runAsUser = NAS_TestDataFactory.constructTestUserIMCIntegration();
        System.runAs(runAsUser) {
            Test.startTest();
            RestRequest request = new RestRequest();
            request.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + 
                '/services/apexrest/NAS_IMCContactUsRestService';
            request.httpMethod = 'POST';
            RestContext.request = request;
            NAS_DataTypeFactory.NAS_IMCFormData imcFormDataWithUnknownContact = 
                (NAS_DataTypeFactory.NAS_IMCFormData)
                JSON.deserialize(NAS_TestConstants.PAYLOADWithUnknownContact, 
                                 NAS_DataTypeFactory.NAS_IMCFormData.class);
            NAS_DataTypeFactory.NAS_IMCFormResponse imcFormResponse =
                NAS_IMCContactUsRestService.postIMCContactUSForm(imcFormDataWithUnknownContact);
            Test.stopTest();
            System.assertNotEquals(null, imcFormResponse, 'imcFormResponse not received.');
            //System.assertEquals(NAS_Constants.SUCCESS, imcFormResponse.responseStatus, 'imcFormResponse not set.');
            System.assertEquals(200, imcFormResponse.httpStatus, 'httpStatus not set');
            //System.assertEquals(NAS_Constants.SUCCESS_MESSAGE, imcFormResponse.message, 'Incorrect message.');
            //System.assertNotEquals(null, imcFormResponse.caseId, 'caseId not set.');
        }
    }
    /**
     * @name testIMCFormSubmissionWithUnknownCustomer
     * @description Tests IMC Contact Us form Submission with valid Type & Category and 
     * an unknown Customer Account.
    **/
    @isTest
    public static void testIMCFormSubmissionWithUnknownCustomer()
    {
        User runAsUser = NAS_TestDataFactory.constructTestUserIMCIntegration();
        System.runAs(runAsUser) {
            Test.startTest();
            RestRequest request = new RestRequest();
            request.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + 
                '/services/apexrest/NAS_IMCContactUsRestService';
            request.httpMethod = 'POST';
            RestContext.request = request;
            NAS_DataTypeFactory.NAS_IMCFormData imcFormDataWithUnknownCustomer = 
                (NAS_DataTypeFactory.NAS_IMCFormData)
                JSON.deserialize(NAS_TestConstants.PAYLOADWithUnknownCustomer, 
                                 NAS_DataTypeFactory.NAS_IMCFormData.class);
            NAS_DataTypeFactory.NAS_IMCFormResponse imcFormResponse =
                NAS_IMCContactUsRestService.postIMCContactUSForm(imcFormDataWithUnknownCustomer);
            Test.stopTest();
            System.assertNotEquals(null, imcFormResponse, 'imcFormResponse not received.');
            System.assertEquals(NAS_Constants.SUCCESS, imcFormResponse.responseStatus, 'imcFormResponse not set.');
            System.assertEquals(200, imcFormResponse.httpStatus, 'httpStatus not set');
            System.assertEquals(NAS_Constants.SUCCESS_MESSAGE, imcFormResponse.message, 'Incorrect message.');
            System.assertNotEquals(null, imcFormResponse.caseId, 'caseId not set.');
        }
    }
}
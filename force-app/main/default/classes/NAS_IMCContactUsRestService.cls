/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Apex REST class designed to process inboud request from Iron Mountain Connect and create a
* Salesforce Case. 
*
* Properties & Methods:
* •	Post method to receive the contact us form data
* •	Inner Class IMCFormData to deserialize the Contact Us form Data
* •	Inner Class IMCFormResponse to prepare the response
* •	Create Case method to create case from deserialized IMCFormData
*
* URL Mapping: /NAS_IMCContactUsRestService
*
* HTTP Verbs Handled:
*
*   POST    -   A Post request to this Rest Resource accepts IMC Form Data and calls a Service 
*               class to Create a Case in Salesforce.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@RestResource(urlMapping='/NAS_IMCContactUsRestService')
global without sharing class NAS_IMCContactUsRestService {
    /**
     * @name postIMCContactUSForm
     * @description Implementation of Http Post method for receiving Contact Us form data from IMC. 
     * Returns NAS_IMCFormResponse
    **/
    @HttpPost
    global static NAS_DataTypeFactory.NAS_IMCFormResponse postIMCContactUSForm(NAS_DataTypeFactory.NAS_IMCFormData imcFormData) {
        NAS_DataTypeFactory.NAS_IMCFormResponse imcFormResponse = new NAS_DataTypeFactory.NAS_IMCFormResponse();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        NAS_DataFactory.createIMCSupportCase(imcFormData, imcFormResponse);
        return imcFormResponse;
    }
}
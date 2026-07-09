/*****************************************************************************************************
* Class		: QTB_IRMVertexServiceConstant
* Author	: IRM
* Purpose	: This is class holds constant values used for IRM to Vertex Integration
* Requirement: Gitlab #
* Change History: 07/07/2021
* Developer       Date            Description
* ------------------------------------------------------------------------------------------- 
* Virtusa         07/07/2021      #857, Vertex Integration    
* Virtusa         11/08/2021      #6056  Change login credential
*******************************************************************************************************/
public with sharing class QTB_IRMVertexServiceConstant {
    public static String USERNAME = 'SALESFORCE3';//'admin';
    public static String PASSWORD = 'Salesforce2021';//'vertex';
    public static string DataManagment = 'Data Managment';
    public static string RecordManagment = 'Record Managment';
    public static String TAX_APPLICATION_VERTEX = 'Vertex';
    public static String APPROVED = 'Approved';
    public static final String TRANSCATION_TYPE = 'SALE';
    public static final String SOAP_REQUEST_HEADER = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:vertexinc:o-series:tps:8:0">'+
        '<soapenv:Header/>'+
        '<soapenv:Body>'+
        '<urn:VertexEnvelope>';
    public static final string SOAP_REQUEST_HEADER_END = '</urn:VertexEnvelope></soapenv:Body></soapenv:Envelope>';
}
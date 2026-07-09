/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Apex class to implement Get Communicator & Transportation Zone Functionality. On Save of a 
* NAS General Support Case if a Order Number or Zip Code & Country is provided, the associated
* Service Market & Transportation Zone details is requested by invoking a SKP API and updated in
* the case record.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class NAS_GetServiceMarketNTransportationZone {
    /**
    * @name getServiceAndMarketTransportationZone
    * @description Invocable method to to callout to SKP API and update the case record with the 
    * Service market and transportation zone. Get Service Market And Transportation Zone from SKP 
    * using provided Order Number or Zip Code.
    **/
    @AuraEnabled
    public static NAS_DataTypeFactory.SKPAPIResponse getServiceAndMarketTransportationZone(Id caseId) {
        NAS_DataTypeFactory.SKPAPIResponse returnValue = new NAS_DataTypeFactory.SKPAPIResponse();
        List<Case> caseList = NAS_DataFactory.getCaseListForServiceMarketUpdate(caseId);
        if(!caseList.isEmpty())
        {
            Case cs = caseList[0];
            Map<String, Object> requestJSON = NAS_RequestParamBuilder.getServiceMarket(cs);
            String errorMessage = String.valueOf(requestJSON.get('errorMessage'));
            if(errorMessage == null) {
                Map<String, Object> getServiceMarketJSON = NAS_RequestFactory.postSKPHttpRequest(NAS_Constants.RQTYPE_SKP_API_GET_SERVICE_MARKET, 
                                                                                                 requestJSON);
                if(getServiceMarketJSON.get('statusCode') == 200 && getServiceMarketJSON.get('success') == true)
                {
                    cs.NAS_Service_Market_Id__c = String.valueOf(getServiceMarketJSON.get('districtId'));
                    cs.NAS_Service_Market__c = String.valueOf(getServiceMarketJSON.get('districtName'));
                    List<Object> transportationZoneInfo = (List<Object>) getServiceMarketJSON.get('transportationZoneInfo');
                    if(transportationZoneInfo != null && !transportationZoneInfo.isEmpty())
                    {
                        Map<String, Object> serviceMarket = (Map<String, Object>) transportationZoneInfo[0];
                        cs.NAS_Transportation_Zone__c = String.valueOf(serviceMarket.get('zoneName'));
                    }
                    else {
                        cs.NAS_Transportation_Zone__c = null;
                    }
                    update cs;
                    returnValue.isSuccess =  true;
                }
                else {
                    cs.NAS_Service_Market_Id__c = null;
                    cs.NAS_Service_Market__c = null;
                    cs.NAS_Transportation_Zone__c = null;
                    update cs;
                    returnValue.isSuccess =  false;
                }
                NAS_TransformationFactory.updateSKPAPIReponse(getServiceMarketJSON, returnValue);
            }
            else {
                returnValue.isError = true;
                returnValue.errorMessage = errorMessage;
            }
        }
        else {
            returnValue.isError = true;
            returnValue.errorMessage = NAS_Constants.NAS_DATA_NOT_AVAILABLE;
        }
        return returnValue;
    }
}
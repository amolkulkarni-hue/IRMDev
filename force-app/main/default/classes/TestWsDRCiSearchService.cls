@isTest
global class TestWsDRCiSearchService {


    static testMethod void runTest() {
    Test.setMock(WebServiceMock.class, new MockCalloutClass());
            WsDRCiSearchService searchSvc = new WsDRCiSearchService();
            WsDRCiSearchService.SearchServiceSoap docSearch = new WsDRCiSearchService.SearchServiceSoap();
            
            WsDRCiSearchService.DisplayFieldType dt = new WsDRCiSearchService.DisplayFieldType();
            WsDRCiSearchService.HitsType a = new WsDRCiSearchService.HitsType();
            WsDRCiSearchService.HitType b = new WsDRCiSearchService.HitType();
            WsDRCiSearchService.SearchRequest_element c = new WsDRCiSearchService.SearchRequest_element();
            
            //Set the SearchFields
            WsDRCiSearchService.SearchFieldsType SearchF = new WsDRCiSearchService.SearchFieldsType();
            WsDRCiSearchService.SearchFieldType[] SearchFields  = new  WsDRCiSearchService.SearchFieldType[2];
            WsDRCiSearchService.SearchFieldType searchField = new WsDRCiSearchService.SearchFieldType();
            WsDRCiSearchService.SearchFieldType searchField2 = new WsDRCiSearchService.SearchFieldType();
            
            searchField.name = 'Country Code';
            searchField.Operator = 'Equal';
            searchField.Value1 = 'x';
            SearchFields[0] = searchField;
            searchField2.name = 'Contract Number';
            searchField2.Operator = 'Equal';
            searchField2.Value1 = 'b';
            SearchFields[1] = searchField2;
            
            SearchF.SearchField = SearchFields;
            
            //Instanciate the QueryType object and set the Folder
            WsDRCiSearchService.QueryType query = new WsDRCiSearchService.QueryType();
            query.Folder = 'x';
            //add the search fields
            query.SearchFields = SearchF;
           
            WsDRCiSearchService.SearchResponse_element searchRes = new WsDRCiSearchService.SearchResponse_element();
            searchRes 
              = docSearch.Search('d', query, 'b');
              
    }
    
    global class MockCalloutClass implements WebServiceMock {
   
     global   void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
           WsDRCiSearchService.SearchResponse_element searchRes = 
               new WsDRCiSearchService.SearchResponse_element();
           response.put('response_x', searchRes);
    }

  }
}
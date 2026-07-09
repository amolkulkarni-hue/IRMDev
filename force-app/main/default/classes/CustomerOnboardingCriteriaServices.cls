public with sharing class CustomerOnboardingCriteriaServices {
    
    /* Return the list of questions for given criteria, sorted in order */
    public static List<Customer_Onboarding_Field__c> getOnboardingFields( String serviceLine, 
                                                                          String dealType, 
                                                                          String upsellType,
                                                                          Boolean suppliesOrderRequried ) {
        String criteriaQuery;
        system.debug('In x');
        if (dealType != 'Up-Sell/Lift') {
          criteriaQuery = 'SELECT Id FROM Customer_Onboarding_Criteria__c WHERE ' +
                                                                   ' Service_Line__c = \'' + serviceLine + '\' AND ' +
                                                                      ' Deal_Type__c = \'' + dealType + '\' AND ' +
                                                        ' Supplies_Order_Required__c = '   + suppliesOrderRequried + ' LIMIT 1';
        } else {
          criteriaQuery = 'SELECT Id FROM Customer_Onboarding_Criteria__c WHERE ' +
                                                                   ' Service_Line__c = \'' + serviceLine + '\' AND ' +
                                                                      ' Deal_Type__c = \'' + dealType + '\' AND ' +
                                                                    ' Upsell_Type__c = \'' + upsellType + '\' AND ' +
                                                        ' Supplies_Order_Required__c = '   + suppliesOrderRequried + ' LIMIT 1';
        }
        Customer_Onboarding_Criteria__c criteria;
        try {
          criteria = database.query(criteriaQuery);
        } catch (QueryException e) {
          criteria = null;
        }

        List<Customer_Onboarding_Field__c> onbaordingFields;
        if (criteria != null) {
          onbaordingFields = [SELECT Id, Field_API_Name__c, Field_Display_Label__c, Field_Display_Label_French__c, Sort_Order__c, Related_Object__c 
                                FROM Customer_Onboarding_Field__c 
                               WHERE Customer_Onboarding_Criteria__c = :criteria.Id 
                            ORDER BY Sort_Order__c Asc];
        } else {
          onbaordingFields = new List<Customer_Onboarding_Field__c>();
        }
        return onbaordingFields;
    }

    @testVisible
    static String generateCriteriaValueHash(Case c) {
      //String dealType = (c.NCSP_Opportunity__r.Type=='Up-Sell/Lift'?'Upsell':c.NCSP_Opportunity__r.Type);
      String sl = (c.NCSP_Service_line__c==null?'':c.NCSP_Service_line__c);
      String dt = (c.Deal_Type__c==null?'':c.Deal_Type__c);
      String ut = (c.NCSP_Upsell_Type__c==null||dt!='Upsell'?'':c.NCSP_Upsell_Type__c);
      String sr = (c.Supplies_Order_Required__c==null?'':c.Supplies_Order_Required__c);
      system.debug('Case +++++======'+sl.toUpperCase()+'.'+dt.toUpperCase()+'.'+ut.toUpperCase()+'.'+sr.toUpperCase());
      return sl.toUpperCase()+'.'+
             dt.toUpperCase()+'.'+
             ut.toUpperCase()+'.'+
             sr.toUpperCase();
      // i.e. "SL1.DT2.UT1.YES" 
    }

    @testVisible
    static String generateCriteriaValueHash(Customer_Onboarding_Criteria__c c) {
      String sl = (c.Service_Line__c==null?'':c.Service_Line__c);
      String dt = (c.Deal_Type__c==null?'':c.Deal_Type__c);
      String ut = (c.Upsell_Type__c==null?'':c.Upsell_Type__c);
      String sr = (c.Supplies_Order_Required__c==null?'':(c.Supplies_Order_Required__c?'YES':'NO'));
      system.debug('Customer_Onboarding_Criteria__c ======'+sl.toUpperCase()+'.'+dt.toUpperCase()+'.'+ut.toUpperCase()+'.'+sr);
      return sl.toUpperCase()+'.'+
             dt.toUpperCase()+'.'+
             ut.toUpperCase()+'.'+
             sr; 
      // i.e. "sl1.dt2.YES"
    }

    // returns '' if any of the criteria values are empty (i.e. (hash="sl1..ut2.YES") ==> '')
    @testVisible
    static String generateClauseFromHash(String hash) {
      String[] criteriaVals = hash.split('\\.', 4);
      String sl = criteriaVals[0];
      String dt = criteriaVals[1];
      String ut = criteriaVals[2];
      String sr = criteriaVals[3];
      system.debug('11%%%'+sl +'==='+dt +'=='+ut +'=='+sr );
      List<String> clauses = new List<String>();
      if (String.isBlank(sl)||String.isBlank(dt)||String.isBlank(sr)||(dt=='Upsell' && String.isBlank(ut))) 
        return '';
      system.debug('Went inside#####' );
      clauses.add('Service_Line__c=\''+sl+'\'');
      clauses.add('Deal_Type__c=\''+dt+'\'');
      if (dt=='Upsell') clauses.add('Upsell_Type__c=\''+ut+'\'');
      clauses.add('Supplies_Order_Required__c='+(sr=='YES'?'true':'false'));
    system.debug('clauses #####'+clauses );
      return '('+String.join(clauses, ' AND ')+')'; // i.e. (Service_Line__c = 'sl1' AND Deal_Type__c = 'dt1' AND Supplies_Order_Req__c = 'YES')
    }

    /*
    *   Cases whose criteria values don't match any Customer_Onboarding_Criteria__c records will not be included in this Map
    *     - Caller of this function should deal with notifying user that criterias were not found for those cases
    */
    @testVisible
    static Map<Id, List<Id>> getMapOfCriteria2CaseIDs( List<Case> cases ) {
      // Create map of hashkey to case IDs (1 TO MANY)
      Map<String, List<Id>> hash2CaseIds = new Map<String, List<Id>>();
      for (Case c : cases) {
        String hash = generateCriteriaValueHash(c);
        system.debug('11+++++===='+hash);
        if (!hash2CaseIds.containsKey(hash))
          hash2CaseIds.put(hash, new List<Id>());
        hash2CaseIds.get(hash).add(c.Id);
      }
        system.debug('hash2CaseIds=='+hash2CaseIds);
      // Query for list of all unique criteria that are found in the list of cases
      List<String> clauseList = new List<String>();
      for (String hash : hash2CaseIds.keySet()) {
      system.debug('hash==='+hash);
        String clause = generateClauseFromHash(hash);
        system.debug('%%%%%%%'+clause);
        if (!String.isEmpty(clause))
          clauseList.add(clause);
      }
      
      String criteriaQuery = 'SELECT Id, Service_Line__c, Deal_Type__c, Upsell_Type__c, Supplies_Order_Required__c FROM Customer_Onboarding_Criteria__c WHERE ' +
                              String.join(clauseList, ' OR ');
      system.debug('criteriaQuery==='+criteriaQuery);
      List<Customer_Onboarding_Criteria__c> criteriaList;
      try {
        criteriaList = database.query(criteriaQuery);
      } catch (QueryException e) {
        // Remove Assert if not debugging
        //System.assert(false, e.getMessage());
        return new Map<Id, List<Id>>();
      }
      // Create a map of criteria ids to caseId Lists by essentially replacing the keys of the map of criteria hashes to caseId lists with the 
      // corresponding criteria Ids
      Map<Id, List<Id>> criteria2CaseIds = new Map<Id, List<Id>>();
      for (Customer_Onboarding_Criteria__c coc : criteriaList) {
        List<Id> caseIDsWithSameCriteria = hash2CaseIds.get(generateCriteriaValueHash(coc));
        criteria2CaseIds.put(coc.Id, caseIDsWithSameCriteria);
      }

      return criteria2CaseIds;
      // e.g. { " a00351503510" => {"500A38F3AWWA0", "500A38F3AWWA1"}, " a00351503511" => {"500A38F3AWWA2"}, " a00351503512" => {"500A38F3AWWA3"} }
    }

    static List<String> generateQuotedList(Set<Id> ids) {
      List<String> quotedList = new List<String>();
      for (Id id : ids) 
        quotedList.add('\''+id+'\'');
      return quotedList;
    }

    /* 
    *   Invariant: Returned map has a key,value pair for each case in cases. Cases that don't have matching criteria, or has matching
    *               criteria but no fields will be mapped to an empty list
    */
    public static Map<Id, List<Customer_Onboarding_Field__c>> getOnboardingFieldSets( List<Case> cases ){
      // Generate Map of Criteria to Case IDs
      Map<Id, List<Id>> criteria2CaseIds = getMapOfCriteria2CaseIDs(cases);
      // Query for all fields
      List<Customer_Onboarding_Field__c> allFields = 
          [SELECT Id, Field_API_Name__c, Field_Display_Label__c, Field_Display_Label_French__c, Sort_Order__c, Related_Object__c, Customer_Onboarding_Criteria__c
                      FROM Customer_Onboarding_Field__c 
                      WHERE Customer_Onboarding_Criteria__c in :new List<Id>(criteria2CaseIds.keySet())
                      ORDER BY Sort_Order__c Asc];
      Map<Id, List<Customer_Onboarding_Field__c>> criteria2fields = GroupBy.ids('Customer_Onboarding_Criteria__c', allFields);
      // File them into the correct case
      Map<Id, List<Customer_Onboarding_Field__c>> caseId2Fields = new Map<Id, List<Customer_Onboarding_Field__c>>();
      for (Id criteriaId : criteria2fields.keySet()) {
        for (Id caseId : criteria2CaseIds.get(criteriaId)) {
          caseId2Fields.put(caseId, criteria2fields.get(criteriaId));
        }
      }

      // For the invalid ones, put an empty list
      for (Case c : cases) {
        if (!caseId2Fields.containsKey(c.Id))
          caseId2Fields.put(c.Id, new List<Customer_Onboarding_Field__c>());
      }

      return caseId2Fields;
    }
}
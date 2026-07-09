public without sharing class ActivityService {

    private static Map<Id, Opportunity> opps;
    private static Map<Id, Opportunity> oppsToUpdate;
    
    public static void rollUp(sObject source) {
        Opportunity opp = opps.get((Id) source.get('WhatId'));
        if(opp==null) return;
        String customerVerifiers = (String) source.get('Customer_Verifiers__c');
        if(customerVerifiers==null) return;
        // Comment out #16914
        /*Set<String> verifiers = new Set<String>();
        for(String s: customerVerifiers.split(';')){
            verifiers.add(s.trim());
        }
      
        Boolean changed = false;
        if(verifiers.contains('1')){
            if(opp.Customer_Verifier_2__c != true) changed = true;
            opp.Customer_Verifier_2__c = true;
        }
        if(verifiers.contains('2')){
            if(opp.Customer_Verifier_4__c != true) changed = true;
            opp.Customer_Verifier_4__c = true;
        }
        if(verifiers.contains('3')){
            if(opp.Customer_Verifier_5__c != true) changed = true;
            opp.Customer_Verifier_5__c = true;
        }
        if(verifiers.contains('4')){
            if(opp.Customer_Verifier_14__c != true) changed = true;
            opp.Customer_Verifier_14__c = true;
        }
        if(verifiers.contains('5')){
            if(opp.Customer_Verifier_6__c != true) changed = true;
            opp.Customer_Verifier_6__c = true;
        }
        if(verifiers.contains('6')){
            if(opp.Customer_Verifier_3__c != true) changed = true;
            opp.Customer_Verifier_3__c = true;
        }
        if(verifiers.contains('7')){
            if(opp.Customer_Verifier_8__c != true) changed = true;
            opp.Customer_Verifier_8__c = true;
        }
        if(verifiers.contains('8')){
            if(opp.Customer_Verifier_15__c != true) changed = true;
            opp.Customer_Verifier_15__c = true;
        }
        if(verifiers.contains('9')){
            if(opp.Customer_Verifier_16__c != true) changed = true;
            opp.Customer_Verifier_16__c = true;
        }
        if(verifiers.contains('10')){
            if(opp.Customer_Verifier_7__c != true) changed = true;
            opp.Customer_Verifier_7__c = true;
        }
        if(verifiers.contains('11')){
            if(opp.Customer_Verifier_13__c != true) changed = true;
            opp.Customer_Verifier_13__c = true;
        }
        if(verifiers.contains('12')){
            if(opp.Customer_Verifier_12__c != true) changed = true;
            opp.Customer_Verifier_12__c = true;
        }
        if(verifiers.contains('13')){
            if(opp.Customer_Verifier_9__c != true) changed = true;
            opp.Customer_Verifier_9__c = true;
        }
        if(verifiers.contains('14')){
            if(opp.Customer_Verifier_10__c != true) changed = true;
            opp.Customer_Verifier_10__c = true;
        }
        if(verifiers.contains('15')){
            if(opp.Customer_Verifier_11__c != true) changed = true;
            opp.Customer_Verifier_11__c = true;
        }        
        if(changed == true){
            opp.Bypass_Validation__c = true;
            oppsToUpdate.put(opp.Id, opp);
        }*/
    }

     public static void rollUpRimTracker(sObject source) {
        Opportunity opp = opps.get((Id) source.get('WhatId'));
        if(opp==null) return;
        String rimtracker = (String) source.get('RIM360__c');
        if(rimtracker==null) return;
        // Comment out #16914
        /*Set<String> trackers = new Set<String>();
        
        for(String s: rimtracker.split(';')){
            trackers.add(s.trim());
        }
        Boolean changed = false;        
        if(trackers.contains('1')){
           if(opp.RIM360_1__c == null || opp.RIM360_1__c == 'No') changed = true;
            opp.RIM360_1__c = 'Yes';
        }
        if(trackers.contains('2')){
           if(opp.RIM360_2__c == null || opp.RIM360_2__c == 'No') changed = true;
            opp.RIM360_2__c = 'Yes';
        }
         if(trackers.contains('3')){
           if(opp.RIM360_1__c == null || opp.RIM360_1__c == 'Yes') changed = true;
            opp.RIM360_1__c = 'No';
        }
        if(changed == true){
            opp.Bypass_Validation__c = true;
            oppsToUpdate.put(opp.Id, opp);
        }*/
    }  
    public static void rollUp(List<sObject> sourceList) {
        Set<Id> whatIds = new Set<Id>();
        for(sObject o: sourceList){
            whatIds.add((Id) o.get('WhatId'));
        }
        opps = new Map<Id, Opportunity>([
            SELECT 
                Id, 
                Customer_Verifier_2__c,
                Customer_Verifier_3__c,
                Customer_Verifier_4__c,
                Customer_Verifier_5__c,
                Customer_Verifier_6__c,
                Customer_Verifier_7__c,
                Customer_Verifier_8__c,
                Customer_Verifier_9__c,
                Customer_Verifier_10__c,
                Customer_Verifier_11__c,
                Customer_Verifier_12__c,
                Customer_Verifier_13__c,
                Customer_Verifier_14__c,
                Customer_Verifier_15__c,
                Customer_Verifier_16__c,
                RIM360_1__c
               //#16915 RIM360_2__c
            FROM Opportunity
            WHERE Id IN :whatIds
        ]);
        oppsToUpdate = new Map<Id, Opportunity>();
        for(sObject o: sourceList){
            rollUp(o);
            rollUpRimTracker(o);
        }
        update oppsToUpdate.values();
    }

    public static void getContactLevel(List<sObject> sourceList){
        Set<Id> whoIds = new Set<Id>();
        for(sObject o: sourceList){
            whoIds.add((Id) o.get('WhoId'));
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>([
            SELECT
                Id,
                IM_Job_Level__c
            FROM Contact
            WHERE Id IN :whoIds

        ]);
        for(sObject o: sourceList){
            Contact c = contacts.get((Id) o.get('WhoId'));
            if(c==null) continue;
            o.put('Contact_Level__c', c.IM_Job_Level__c);
        }
    }

}
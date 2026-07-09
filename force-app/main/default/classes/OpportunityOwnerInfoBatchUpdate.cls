/*
Auhtor             : Nagesh Ganji
Created Date       : Apr 16, 2010
Description        : Batch Apex class for populating Owner info on Opportunities where Owner info is not
                     according to OwnerId. This batchable class, along with OpportunityOwnerInfoScheduler, 
                     can be used for scheduling daily job to update all Opportunities.
CHANGE LOG         :
  [[Version; Date; Author; Project/Case; Description]]
  v1.0; 2013/05/07; Srinivasa Rao/Randstad; Reviewing code coverage for all components/Case#01367998; Initial release.
  Description      : Added a condition to reduce execution time when it's running through batch class.
*/

global class OpportunityOwnerInfoBatchUpdate implements Database.Batchable<sObject>, Database.Stateful {

    global static final String objName = 'Opportunity';
    public static final String initialQuery = 'SELECT Id FROM ' + objName + ' WHERE CreatedDate >= YESTERDAY';
    //Srinu: Commenetd out
    //public final String Query{get; private set;} 
    //Srinu: Added on 05-07
    public String Query{get; private set;}
    public Integer RecordsProcessed{get; private set;}
    public Integer RecordsUpdated{get; private set;}     
    
    Map<Id, String> ownerFirstName = new Map<Id, String>();
    Map<Id, String> ownerLastName = new Map<Id, String>();
    Map<Id, String> ownerEmail = new Map<Id, String>();   

    public OpportunityOwnerInfoBatchUpdate (){
        this(null);
    }

    public OpportunityOwnerInfoBatchUpdate (String query){
        this.Query = (query!=null)? query : initialQuery;
        recordsProcessed = 0;
        recordsUpdated = 0;
        fetchUserInfo();
    }
  
    global Database.QueryLocator start(Database.BatchableContext BC){
        //If it's executed by test method, query will take 20 records. Otherwise it will take records satisfied by by query in 'else' condition.
        if(Test.isRunningTest()){
            Query='select id from opportunity  LIMIT 20';
        }else{
            Query='SELECT Id FROM ' + objName + ' WHERE CreatedDate >= YESTERDAY and opportunity.RecordType.Name!=\'NA Renewal\'';
        }
        return Database.getQueryLocator(Query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Opportunity> optyList4Update = new List<Opportunity>();
        Set<Id> sObjIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        List<SObject> sObjsToUpdate = database.query('Select Id From ' + objName + ' Limit 0');
        
        for(sObject sObj : scope){
            sObjIds.add(sObj.Id);
        }
        
        try {
            List<Opportunity> optyList = new List<Opportunity>();    
            optyList = [SELECT Id, OwnerId, Owner_Email__c,  Owner_First_Name__c, Owner_Last_Name__c
                       FROM Opportunity
                       WHERE Id IN :sObjIds];   
            
            //Apply Owner information
            for(Integer i=0; i<optyList.size(); i++) {
                Opportunity opp = optyList.get(i);
                if ( opp.Owner_Email__c != ownerEmail.get(opp.OwnerId) ) {
                    System.debug(Logginglevel.FINEST,'-------OLD: '+opp.Owner_Email__c);
                    System.debug(Logginglevel.FINEST,'-------NEW: '+ownerEmail.get(opp.OwnerId));                
                    opp.Owner_First_Name__c = ownerFirstName.get(opp.OwnerId);
                    opp.Owner_Last_Name__c = ownerLastName.get(opp.OwnerId);
                    opp.Owner_Email__c = ownerEmail.get(opp.OwnerId);
                    optyList4Update.add(opp);
                    System.debug(Logginglevel.FINEST,'-------Updated Opportunity ID: '+opp.Id);             
                    //updateRecord = true;                    
                }                                 
            }
            
            if(optyList4Update.size()>0) {
                update optyList4Update;
                System.debug('++++++++++++++++++++++++ LIST SIZE UPDATED+++++++++++++++++++++++++++++++:'+ optyList4Update.size());                                     
            }        

        }
        catch(DMLException dmlex){
            System.debug('@@@@@@@@@@@@@@@@@'+'Failed to update Opportunity OwnerInfo:  '+dmlEx.getDmlId(0)+' Error: '+dmlex.getMessage()+'@@@@@@@@@@@@@@@@@');
                    
        }
        catch(Exception ex){
            System.debug('@@@@@@@@@@@@@@@@@'+'Unexpected ERROR on Opportunity Owner update:'+ex.getMessage()+'@@@@@@@@@@@@@@@@@');
            
        }
        recordsProcessed = recordsProcessed + scope.size();
        recordsUpdated = recordsUpdated + optyList4Update.size();
        //optyList4Update.clear();
        System.debug('^^^^^^^^^^^^^^^^^^^^ Total Records Processed: ' + recordsProcessed);
        System.debug('^^^^^^^^^^^^^^^^^^^^ Total Records Updated: ' + recordsUpdated);
    }
  
    global void fetchUserInfo(){
        System.debug('============== fetchUserInfo() method ========================');
        //Capture Owner information
        for (User ownerInfo : [SELECT Id, FirstName, LastName, email FROM User]) {
            ownerFirstName.put( ownerInfo.Id, ownerInfo.FirstName);
            ownerLastName.put( ownerInfo.Id, ownerInfo.LastName);
            ownerEmail.put( ownerInfo.Id, ownerInfo.email);             
        }       
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('============== finish(0 method ========================');
    }
	
    //Test Mehtod
   
//////////////////////////////////////////////////////////////////////////////////////////
/*
    global static final Integer QUERY_BATCH_SIZE = 200;
    global static final String objName = 'Opportunity';
    public static final String initialQuery = 'SELECT Id FROM ' + objName;
    public final String Query{get; private set;}
    public Integer RecordsProcessed{get; private set;}
    public Integer RecordsUpdated{get; private set;}     
  
    public OpportunityOwnerInfoBatchUpdate (){
        this(null);
    }

    public OpportunityOwnerInfoBatchUpdate (String query){
        this.Query = (query!=null)? query : initialQuery;
        recordsProcessed = 0;
        recordsUpdated = 0;
    }
  
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Opportunity> optyList4Update = new List<Opportunity>();
        Set<Id> sObjIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        for(sObject sObj : scope){
            //Break up the table for querying batches as per SFDC R&D recommendation
            sObjIds.add(sObj.Id);
        }
         
        List<Opportunity> optyList = new List<Opportunity>();    
        optyList = [SELECT Id, OwnerId, Owner_Email__c,  Owner_First_Name__c, Owner_Last_Name__c
                   FROM Opportunity
                   WHERE Id IN :sObjIds];
                   
        for(Integer i=0; i< optyList.size(); i++)
            ownerIds.add(optyList.get(i).OwnerId);         
                          
        Boolean updateRecord = false;
        if ( ownerIds.size() > 0) {

            Map<Id, String> ownerFirstName = new Map<Id, String>();
            Map<Id, String> ownerLastName = new Map<Id, String>();
            Map<Id, String> ownerEmail = new Map<Id, String>();         

            //Capture Owner information
            for (User ownerInfo : [SELECT Id, FirstName, LastName, email FROM User 
                                    WHERE Id in :ownerIds]) {
                ownerFirstName.put( ownerInfo.Id, ownerInfo.FirstName);
                ownerLastName.put( ownerInfo.Id, ownerInfo.LastName);
                ownerEmail.put( ownerInfo.Id, ownerInfo.email);             
            }
    
            //Apply Owner information
            for(Integer i=0; i<optyList.size(); i++) {
                Opportunity opp = optyList.get(i);
                if ( opp.Owner_Email__c != ownerEmail.get(opp.OwnerId) ) {
                    opp.Owner_First_Name__c = ownerFirstName.get(opp.OwnerId);
                    opp.Owner_Last_Name__c = ownerLastName.get(opp.OwnerId);
                    opp.Owner_Email__c = ownerEmail.get(opp.OwnerId);   
                    optyList4Update.add(opp);
                    updateRecord = true;                    
                }                                 
            }
        }
        if(updateRecord)
            update optyList4Update;
    
        recordsProcessed = recordsProcessed + scope.size();
        recordsUpdated = recordsUpdated + optyList4Update.size();
        System.debug('^^^^^^^^^^^^^^^^^^^^ Total Records Processed: ' + recordsProcessed);
        System.debug('^^^^^^^^^^^^^^^^^^^^ Total Records Updated: ' + recordsUpdated);
    }
  
    global void finish(Database.BatchableContext BC){
        System.debug('============== finish method ========================');
    }
*/
/////////////////////////////////////////////////////////////////////////////////////////
}
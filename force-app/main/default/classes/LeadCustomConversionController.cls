/*
Auhtor       : Nagesh Ganji
Created Date : Aug 31, 2010
Description  : Controller class for VisualForce page 'LeadCustomConversion'.
*/
public class LeadCustomConversionController {    
    private Lead leadObj;
    public Boolean leadDupeFlag{get; set;}// Flag Set to false if matching Lead records are found else set to true
    public Boolean conDupeFlag{get; set;}// Flag Set to false if matching Contacts Lead records are found else set to true
    public Boolean accDupeFlag{get; set;}// Flag Set to false if duplicate Lead records are found else set to true  
    
    //17-04-2013
    public Boolean isIMEProfileUser {get {if(isIMEProfileUser == NULL)
                                     {
                                        return false;
                                     }
                                     else{return isIMEProfileUser;}}  set;}
    //public Boolean getisIMEProfileUser(){return isIMEProfileUser;}
    // Comment #15149 Start
    //private List<CRMfusionDBR101__Potential_Duplicate__c> leadDupeList = new List<CRMfusionDBR101__Potential_Duplicate__c>();    
    // Comment #15149 End
    public Set<Id> contactIds = new Set<Id>();
    public Set<Id> accountIds = new Set<Id>();

    
    
    public Lead    leadRecord    = new Lead();
    public List<Contact> matchingContactList = new List<Contact>(); 
    public List<Account> matchingAccountList = new List<Account>(); 
 
    public void setLeadRecord(Lead rec){ this.leadRecord = rec;} 
    
    public Lead getLeadRecord(){ return this.leadRecord; }  
  	// Comment #15149 Start
    //public void setLeadDupeList(List<CRMfusionDBR101__Potential_Duplicate__c> setterList){ this.leadDupeList.addAll(setterList);} 
    
    //public List<CRMfusionDBR101__Potential_Duplicate__c> getLeadDupeList(){ return this.leadDupeList;} 
    // Comment #15149 End
    public void setMatchingContactList(List<Contact> setterList){ this.matchingContactList.addAll(setterList); } 
    
    public List<Contact> getMatchingContactList(){ return this.matchingContactList;}
  
    public void setMatchingAccountList(List<Account> setterList){ this.matchingAccountList.addAll(setterList); } 
    
    public List<Account> getMatchingAccountList(){ return this.matchingAccountList; }
    
  
    public LeadCustomConversionController (ApexPages.StandardController stdController) {
        System.debug('--inside constructor ----');
        leadObj = (Lead)stdController.getRecord();        
           
          leadRecord = [SELECT l.City, l.Company, l.Country, l.Description, l.Disposition__c, l.DoNotCall, 
                        l.Email, l.FirstName, l.HasOptedOutOfEmail, l.Id, l.IM_Additional_Account_Manager__c, 
                        l.IM_External_ID__c, l.IM_Functional_Area__c, l.IM_How_Hear_About_Us__c, l.State, 
                        l.IM_Industry__c, l.IM_Job_Level__c, l.IM_Lead_Source_Most_Recent__c, 
                        l.IM_Lead_Stage__c, l.IM_Original_Lead_Owner__c, l.RecordTypeId, 
                        l.IM_Sales_Rep__c, l.IM_Time_Zone__c, l.LastName, l.LeadSource, l.MobilePhone, 
                        l.NumberOfEmployees, l.OwnerId, l.Phone, l.PostalCode, l.Status, l.Title, l.Street 
                        FROM Lead l WHERE l.Id = :leadObj.Id];
            
        
        // Changes begin
        // 2011-02-07   Added this to handle multiple non NA Lead record types. Previously, only
        //              IME Lead would be handled, but with the introduction of new record types
        //              a more extendable solution is required. Instead, a Set holds IDs of
        //              record types (retrieved via Schema and Retrieve objects) that we want 
        //              to be handled in a non-NA way. Later, rather than comparing to one 
        //              variable, the Set is checked to see if a value matches. Other record types
        //              for other regions can be added below.
        //Id imeRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('IME Lead').getRecordTypeId(); 
        // 2011-06-07    MJ - added IMLA
        
        Schema.DescribeSObjectResult leadDescribeInfo = Schema.SObjectType.Lead;
        Map<String, Schema.RecordTypeInfo> leadRecordTypes = leadDescribeInfo.getRecordTypeInfosByName();
        
        Set<ID> recordTypeIDs = new Set<ID>();
        if(leadRecordTypes.containsKey('IME Lead'))
            recordTypeIDs.add(leadRecordTypes.get('IME Lead').getRecordTypeId());
        if(leadRecordTypes.containsKey('IMAP Lead'))
            recordTypeIDs.add(leadRecordTypes.get('IMAP Lead').getRecordTypeId());
        if(leadRecordTypes.containsKey('IMLA Lead'))
            recordTypeIDs.add(leadRecordTypes.get('IMLA Lead').getRecordTypeId());
                
        // End changes
        
        //if(leadRecord.RecordTypeId == imeRecTypeId ) { // 2011-02-07 Removed as outlined above        
        // Comment #15149 start
        /*if(recordTypeIDs.contains(leadRecord.RecordTypeId)) { // 2011-02-07 Added as outlined above
            leadDupeList.addAll([SELECT c.Id , c.CRMfusionDBR101__Duplicate_Warning__c, c.CRMfusionDBR101__Scenario_Type__c
                    FROM CRMfusionDBR101__Potential_Duplicate__c c  
                    WHERE c.CRMfusionDBR101__Lead__c =: leadObj.Id AND c.CRMfusionDBR101__Duplicate_Warning__r.CRMfusionDBR101__Scenario__r.Name like 'IME -%' LIMIT 999]);
            System.debug('------80------leadDupeList+++:'+leadDupeList);
        } else {
            System.debug('--82--inside else---');
            leadDupeList.addAll([SELECT c.Id , c.CRMfusionDBR101__Duplicate_Warning__c, c.CRMfusionDBR101__Scenario_Type__c
                    FROM CRMfusionDBR101__Potential_Duplicate__c c
                    WHERE c.CRMfusionDBR101__Lead__c =: leadObj.Id AND c.CRMfusionDBR101__Duplicate_Warning__r.CRMfusionDBR101__Scenario__r.Name like 'NA -%' LIMIT 999]);
            System.debug('------84------leadDupeList+++:'+leadDupeList);
        }*/
        // Comment #15149 End
        //System.debug('------86------leadDupeList+++:'+leadDupeList);                       
		// Comment #15149 Start
        /*for(Integer i=0; i<leadDupeList.size(); i++) {
            System.debug('---91---leadDupeList.get(i).CRMfusionDBR101__Scenario_Type__c:'+leadDupeList.get(i).CRMfusionDBR101__Scenario_Type__c);
            if ( leadDupeList.get(i).CRMfusionDBR101__Scenario_Type__c == 'Lead to Contact') {
                for(CRMfusionDBR101__Potential_Duplicate__c c : [Select CRMfusionDBR101__Contact__c
                    from CRMfusionDBR101__Potential_Duplicate__c 
                    where (CRMfusionDBR101__Duplicate_Warning__c = :leadDupeList.get(i).CRMfusionDBR101__Duplicate_Warning__c) AND
                        CRMfusionDBR101__Contact__c != NULL LIMIT 999] ) {
                    contactIds.add(c.CRMfusionDBR101__Contact__c);
                    System.debug('-----98-----contactIds+++:'+contactIds);
                }
            }
            else if ( leadDupeList.get(i).CRMfusionDBR101__Scenario_Type__c == 'Lead to Account') {
                for(CRMfusionDBR101__Potential_Duplicate__c c : [Select  CRMfusionDBR101__Account__c
                    from CRMfusionDBR101__Potential_Duplicate__c 
                    where (CRMfusionDBR101__Duplicate_Warning__c = :leadDupeList.get(i).CRMfusionDBR101__Duplicate_Warning__c) AND
                        CRMfusionDBR101__Account__c != NULL LIMIT 999] ) {
                    accountIds.add(c.CRMfusionDBR101__Account__c);
                    System.debug('----102-------accountIds+++:'+accountIds);                    
                }
            }
        }*/
        // Comment #15149 End
        conDupeFlag = contactIds.size()> 0 ? false : true ;
        accDupeFlag = accountIds.size()> 0 ? false : true ;

        System.debug('----109-----Flags:'+conDupeFlag+' ----'+accDupeFlag);
        
        if(conDupeFlag == false) 
            matchingContactList.addAll([SELECT c.AccountId, c.Email, c.Id, c.MailingCity, c.MailingCountry, 
                                        c.MailingPostalCode, c.MailingState, c.MailingStreet, c.Name, c.Phone
                                        FROM Contact c
                                        WHERE c.Id IN :contactIds]);
            
        if(accDupeFlag == false) 
            matchingAccountList.addAll([SELECT Id, Name, BillingStreet, BillingCity, BillingState, 
                                        BillingCountry, BillingPostalCode, IM_IMGA_Indexed__c, IM_Hierarchy_Level__c
                                        FROM Account
                                        WHERE Id IN :accountIds]);

        if (conDupeFlag == false || accDupeFlag == false)
            leadDupeFlag = false;
        else
            leadDupeFlag = true;
                                                    
        System.debug('---128-----Matching Contacts+++++:'+matchingContactList.size());
        System.debug('---129------Matching Contacts+++++:'+matchingContactList);
        System.debug('---130----Matching Accounts+++++:'+matchingAccountList.size());        
        System.debug('---131----Matching Accounts+++++:'+matchingAccountList);  
        
        //17-04-2013
        /*Start*/    
        Profile p = [Select Id, Name From Profile Where Id=: UserInfo.getProfileId()];
        String CUR_USR_PROF_NAME = p.Name; 
        System.debug('--146---CUR_USR_PROF_NAME:'+CUR_USR_PROF_NAME);      
        List<Opportunity_Product_Wizard_Settings__c> customsettings = Opportunity_Product_Wizard_Settings__c.getall().values();
        for(Opportunity_Product_Wizard_Settings__c cs : customsettings){
            System.debug('---149--cs.Profile_Name__c:'+cs.Profile_Name__c +'\t CUR_USR_PROF_NAME:'+CUR_USR_PROF_NAME);
            if(cs.Profile_Name__c == CUR_USR_PROF_NAME) {
               isIMEProfileUser = true; 
               System.debug('---152----isIMEProfileUser:'+isIMEProfileUser);  
           } 
        }
        /*End*/     
    }
     public PageReference convert()
     {
        System.debug('--142----inside convert');
        integer i=0;
        PageReference p1;
            List<Opportunity_Product_Wizard_Settings__c> wizardsettings = Opportunity_Product_Wizard_Settings__c.getall().values();
            Profile prof = [Select Name from Profile where id =: UserInfo.getProfileId()];
            String profilename = prof.Name;
            system.debug('----142----UserInfo.getProfileId()'+UserInfo.getProfileId());
            system.debug('-----143----profilename'+profilename);
            for(Opportunity_Product_Wizard_Settings__c ops : wizardsettings){
                system.debug('----145----ops.Profile_Name__c'+ops.Profile_Name__c +'----profilename:'+profilename);
                if(profilename == ops.Profile_Name__c) {                  
                   i++;
                }
            }
            System.debug('--150---i:'+i);
            if(i>0){
                System.debug('---158----inside if--executing Lead Account Select page to find Potential Matching Accounts and contacts');
                // p1 = new PageReference('/apex/CustomLeadConvert?id='+leadObj.Id);
                p1 = new PageReference('/apex/LeadAccountSelect?id='+leadObj.Id);
                System.debug('---155-------p1:'+p1);                
            }
            else{
                System.debug('---164---inside else--executing leadConvert page');
                p1 = new PageReference('/lead/leadconvert.jsp?retURL=/'+leadObj.Id+'&id='+leadObj.Id+'&nooverride=1');
                System.debug('---166-------p1:'+p1); 
            }
            System.debug('---168-------p1:'+p1);
        return p1;
     }     
}
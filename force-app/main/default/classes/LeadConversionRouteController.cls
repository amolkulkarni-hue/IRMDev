/*
Auhtor       : Nagesh Ganji
Created Date : Aug 31, 2010
Description  : Controller class for VisualForce page 'LeadCustomConversionRouterController'.

Modified by  : Nagesh Earanti
Modified date: Oct 06, 2011
Description  : Modified to lookup Related contact is existing or not if yes forwarding to LeadCustomMerge.

Modified by  : Amarendra Nallamalli
Modified date: Jul 02, 2018
Case: 08393450 : Account ID on Lead functionality to convert Lead to pre identified Salesforce.com Account
Description  : Modified to lookup Related account is existing or not if yes forwarding to LeadCustomMerge.

Modified by  : Vinutha Iyengar
Modified Date: June 05, 2019
Case: 09154470 - Lighting Pilot 
Description: Lightning NA users will not be redirected to Opportunity add wizard.
*/

public class LeadConversionRouteController {

    Integer dupeCounter = 0;
    public Lead leadObj{get; set;}
    public Boolean goBack {get; set;} 
    public String msg {get; set;}   
    
    private Set<ID> recordTypeIDs = new Set<ID>(); // 2011-02-07    Added as part of the changes explained in constructor
    
    public LeadConversionRouteController (ApexPages.StandardController stdController) {
        leadObj = (Lead)stdController.getRecord();   
        System.debug('Inside Constructor: LeadConversionRouteController()');
        goBack = false;
        msg = '';
        
        // Changes begin
        // 2011-02-07   Added this to handle multiple non NA Lead record types. Previously, only
        //              IME Lead would be handled, but with the introduction of new record types
        //              a more extendable solution is required. Instead, a Set holds IDs of
        //              record types (retrieved via Schema and Retrieve objects) that we want 
        //              to be handled in a non-NA way. Later, rather than comparing to one 
        //              variable, the Set is checked to see if a value matches. Other record types
        //              for other regions can be added below.
        // 2011-06-07   MJ - added code to include IMLA
        // 2015-11-25  Added North America functionality to prevent conversion with address is not entered -- Sandhya #04170301
        
        Schema.DescribeSObjectResult leadDescribeInfo = Schema.SObjectType.Lead;
        Map<String, Schema.RecordTypeInfo> leadRecordTypes = leadDescribeInfo.getRecordTypeInfosByName();
        
        if(leadRecordTypes.containsKey('IME Lead'))
            recordTypeIDs.add(leadRecordTypes.get('IME Lead').getRecordTypeId());
        if(leadRecordTypes.containsKey('IMAP Lead'))
            recordTypeIDs.add(leadRecordTypes.get('IMAP Lead').getRecordTypeId());
        if(leadRecordTypes.containsKey('IMLA Lead'))
            recordTypeIDs.add(leadRecordTypes.get('IMLA Lead').getRecordTypeId());
        if(leadRecordTypes.containsKey('Standard Lead'))
            recordTypeIDs.add(leadRecordTypes.get('Standard Lead').getRecordTypeId());
        if(leadRecordTypes.containsKey('NA Account Management Lead'))
            recordTypeIDs.add(leadRecordTypes.get('NA Account Management Lead').getRecordTypeId());
            
        // Changes end
    }
    
    public PageReference route() 
    {
        System.debug('Inside method: route()');                 
        PageReference p1;
        
        //check if user is using lightning or classic
        boolean isLightningUser = false;
        for (User u: [SELECT Id, UserPreferencesLightningExperiencePreferred FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1])
        {
            isLightningUser = u.UserPreferencesLightningExperiencePreferred;
        }
        
        system.debug('isLightningExperience=='+isLightningUser);
        
        if(isLightningUser)
        {
            p1 = new PageReference('/lead/leadconvert.jsp?retURL='+ leadObj.Id + '&id=' + leadObj.Id);
            p1.getParameters().put('nooverride', '1');
            p1.setRedirect(false);
        }
        else
        {
            Id imnaRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('NA Account Management Lead').getRecordTypeId();
            Id stdRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId();
            
            //Get the ID for IME Lead Record type
            //Id imeRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('IME Lead').getRecordTypeId(); // 2011-02-07 Removed as outlined above        
            Lead lRec = [SELECT Id,Related_Contact__c,Related_Account__c, Related_Contact__r.Account.Name,Related_Account__r.Name, RecordTypeId, Street, City, State, PostalCode, Country FROM Lead WHERE Id =:leadObj.Id];
            // added MJ 2011-06-10 so that IMLA countries can avoid having to add postalcode
            Set<String> countriesToIgnore = new Set<String>{'IRELAND','ARGENTINA', 'BRAZIL','CHILE','COLOMBIA','MEXICO','PERU','HONG KONG'};
                
                /************ Start Case: 08393450 : Account ID,Contact ID on Lead functionality to convert Lead to pre identified Salesforce.com Account ***********/
                if(lRec.Related_Contact__c != null){
                    if(lRec.Related_Account__c == null){
                        p1 = new PageReference('/apex/LeadCustomMerge?lId='+leadObj.Id+'&cId='+lRec.Related_Contact__c);
                    }else if((lRec.Related_Contact__r.Account.Name != lRec.Related_Account__r.Name )){
                        p1 = new PageReference('/apex/LeadCustomMerge?lId='+leadObj.Id+'&cId='+lRec.Related_Contact__c);
                    }else if(((lRec.Related_Contact__r.Account.Name == lRec.Related_Account__r.Name))){
                        p1 = new PageReference('/apex/LeadCustomMerge?lId='+leadObj.Id+'&aId='+lRec.Related_Account__c);
                    }
                }else if(lRec.Related_Account__c != null && lRec.Related_Contact__c == null){
                    p1 = new PageReference('/apex/LeadCustomMerge?lId='+leadObj.Id+'&aId='+lRec.Related_Account__c);
                }
            /************ End Case: 08393450 : Account ID,Contact ID on Lead functionality to convert Lead to pre identified Salesforce.com Account ***********/
            else{
                //Address validation for IME leads
                // 2011-02-07   Added as part of the changes explained in constructor, check if record type
                //              is a non-NA record type
                //if(lRec.RecordTypeId == imeRecTypeId ) { // Old Line
                
                if(recordTypeIDs.contains(lRec.RecordTypeId)) { // New Line
                    if ( lRec.Street == null) { goBack = true; msg = msg + 'Street, ';}
                    if ( lRec.City == null) { goBack = true; msg = msg + 'City, ';}
                    if ( lRec.PostalCode == null) { 
                        if( lRec.Country != null && countriesToIgnore.contains(lRec.Country.toUpperCase())) {/* IRELAND doesn't use POSTCODES and IMLA it's not universal*/}
                        else {
                            goBack = true; 
                            msg = msg + 'Postal Code, ';
                        }
                    }
                    if ( lRec.Country == null) { goBack = true; msg = msg + 'Country, ';}
                    if(lRec.State== null && (lRec.RecordTypeId==imnaRecTypeId||lRec.RecordTypeId == stdRecTypeId))  {goBack = true; msg = msg + 'State';}                                   
                    if ( goBack == true)                  
                        return null;
                    // Comment #15149 Start
                    /*dupeCounter = [SELECT count()
                                   FROM CRMfusionDBR101__Potential_Duplicate__c c  
                                   WHERE CRMfusionDBR101__Lead__c =: leadObj.Id AND c.CRMfusionDBR101__Duplicate_Warning__r.CRMfusionDBR101__Scenario__r.Name like 'IME -%'];*/
                	// Comment #15149 End
                } // Comment #15149 Start
                /*else {     
                    //dupeCounter = [Select count() FROM CRMfusionDBR101__Potential_Duplicate__c 
                    //                     WHERE CRMfusionDBR101__Lead__c =: leadObj.Id];
                    dupeCounter = [SELECT count()
                                   FROM CRMfusionDBR101__Potential_Duplicate__c c  
                                   WHERE CRMfusionDBR101__Lead__c =: leadObj.Id AND c.CRMfusionDBR101__Duplicate_Warning__r.CRMfusionDBR101__Scenario__r.Name like 'NA -%'];
                }*/ // Comment #15149 End
                System.debug('Counter = '+dupeCounter );       
                
                if (dupeCounter > 0)
                    p1 = new PageReference('/apex/LeadCustomConversion?id='+leadObj.Id);
                else
                {
                    integer i=0;
                    List<Opportunity_Product_Wizard_Settings__c> wizardsettings = Opportunity_Product_Wizard_Settings__c.getall().values();
                    Profile prof = [Select Name from Profile where id =: UserInfo.getProfileId()];
                    String profilename = prof.Name;
                    system.debug('UserInfo.getProfileId()'+UserInfo.getProfileId());
                    system.debug('profilename'+profilename);
                    for(Opportunity_Product_Wizard_Settings__c ops : wizardsettings){
                        system.debug('ops.Profile_Name__c'+ops.Profile_Name__c);
                        if(profilename == ops.Profile_Name__c) {                  
                            i++;
                        }
                    }
                    if(i>0){
                        p1 = new PageReference('/apex/CustomLeadConvert?id='+leadObj.Id);
                        
                        
                    }
                    else{
                        p1 = new PageReference('/lead/leadconvert.jsp?retURL='+ leadObj.Id + '&id=' + leadObj.Id);
                        p1.getParameters().put('nooverride', '1');
                        p1.setRedirect(false);
                    }
                }
                
            }
        }
        return p1;
    }                  
}
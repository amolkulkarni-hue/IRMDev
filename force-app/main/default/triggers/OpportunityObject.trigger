/*COMBINATION OF TWO TRIGGERS ON OPPORTUNITY OBJECT 
**IN REFERNCE TO CASE 00662466
**AUTHOR: SRINIVASA RAO MANDALAPU
**DATE: 06/26/2012

/* 
**Modified By: Keerthi Senthilnathan, Vinutha Iyengar  
**Date: 6th Nov 2017
**Case: #06462026
       -Update Address and Comapany fields from related Account
       -Updated field on Contract Number based on IME_contract on Opportunity,
       -Mark related dsfs__DocuSign_Status__c as void when Opportunity lost 
       

/* 
**Modified By: Amarendra Nallamalli  
**Date: 6th june 2018
**Case: 07955446 : Cloud Solutions Opp Partner Validation Rule
**Case: 07754082 : Read/write ability For Cloud Solutions Opportunities
       

/* 
**Modified By: Amarendra Nallamalli  
**Date: 24th july 2018
**Case#08582999 - Partner mandate for Cloud opportunities - need to add filter to validate rule


/* 
**Modified By: Vinutha Iyengar  
**Date: 14 Nov 2018
**Case# 08861942 -IGDS Automated Chatter Post to Chatter Group


/* 
**Modified By: Vinutha Iyengar  
**Date: 15 Mar 2019
**Case# 09524211 - IGDS Automated Chatter Post to Chatter Group for IME


/* 
**Modified By: Vinutha Iyengar  
**Date: 09 May 2019
**Convert currency before checking for million dollar club


/* 
**Modified By: Vinutha Iyengar  
**Date: 21 August 2019
**Removed reverted (commented) code for case # 07428675
*/


trigger OpportunityObject on Opportunity (after insert, after update,before insert, before update) {
  /*
    System.debug('111 trigger OpportunityObject start' + '\t Trigger.isAfter:' + Trigger.isAfter + '\t Trigger.isBefore:' + Trigger.isBefore +'\t Trigger.isInsert:'+Trigger.isInsert +'\t Trigger.isUpdate'+Trigger.isUpdate);
    /****Variable declaration for 'populateOptyOwnerInfo' Trigger***
    public String populateOptyOwnerInfo = null;
    List<Id> optyOwnerIds = new List<Id> ();
    
    /****Variable declaration for 'OpportunityOwnerLinkTrg' Trigger***
    public String OpportunityOwnerLinkTrg = null;
    public Boolean runOpportunityOwnerLinkTrg = false;
    
    /****Variable declaration for 'UpdateOppotunityOwnerEmailTrigger' Trigger***
    public String UpdateOppotunityOwnerEmailTrigger = null;
    Set<Id> validUserIdSet = new Set<Id>();    
    List<Opportunity_Competitor__c> OpportunityCompetitorsToUpdate = new List<Opportunity_Competitor__c>{};
    
    
    /****Variable declaration for 'syncOppScheduleDate_Fix' Trigger***
    public String syncOppScheduleDate_Fix = null;
    /****Variable declaration for 'SVStatus' Trigger***
    public String OpportunitySVStatus = null;
    // Get opportunities and the differencein days.
    Map<Id, Date> oppIds4SyncOptyDateFix = new Map<Id, Date>();
    Integer l = 0, k = 0;
    //List<OpportunityLineItem> OpportunityLineItems = new List<OpportunityLineItem>();
    
    //Map<Id, Date> mapOppID_CloseDate = new Map<Id, Date>();
    //Integer l = 0, k = 0;
    Integer icount=0, diffDates=0, diffDates30 = 0;
    date newdate ;
    //map of opp line id and list of schedules.
  //  Map<Id, List<OpportunityLineItemSchedule>> mOppLine_Sch = new Map<Id, List<OpportunityLineItemSchedule>>();
    Map<id,OpportunityLineItem> mapOppLine = new map<id,OpportunityLineItem> ();
 
    List<OpportunityLineItem> lstUpdateOppLines = new list<OpportunityLineItem>();
   
    /****Variable declaration for 'CreateOptyShare' Trigger***
    public String CreateOptyShare = null;
    Set<String> Account_Id = new Set<String>();
    Set <String> Opty_fields = new Set <String>();
    List <String> Opty_fields_list = new List <String>();
    Set <String> Account_fields = new Set <String>();
    List <String> Account_fields_list = new List <String>();
    Set <String> Postal_Code_fields = new Set <String>();
    List <String> Postal_Code_fields_list = new List <String>();
    Set<string> country = new  Set<string>();
    Map<String, String> Visibility_setting = new Map<String, String>();
    Map<String, List<String>> acc_opty_map = new Map<String, List<String>>();
    List<OpportunityShare> Opty_share = new List<OpportunityShare>();
    List<OpportunityShare> Opty_share_insert = new List<OpportunityShare>();
    List <Country_Settings__c> country_list = Country_Settings__c.getall().values();
    List<Opportunity_Security__c> Opty = Opportunity_Security__c.getall().values();
    string Opty_query_fields ='';
    string Account_query_fields ='';
    string Postal_Code_query_fields ='';
    string country_query ='';
    List<String> Opty_ids = new List<string>();
    string opty_id_list = '';
    string account_id_list = '';
    Set<String> optyshare_userid = new Set<String>();
    Map<Id, User> Optyshare_activeuser = new Map<Id, User>();
    Map<String,String> opty_owner = new Map<String,String>();
    
    /****Variable declaration for 'OpportunitySubmitForApproval' Trigger***
    public String OpportunitySubmitForApproval = null;
    public Boolean runOpportunitySubmitForApproval = false;
    Set<Id> recordTypeIds = new Set<Id>(); 
    Set<Id> EUrecordTypeIds = new Set<Id>();
    String runSendAccountInfoToCDM=null; 
    String SKPOpportunitySync=null;
    Boolean isOppChanged = false;
    
    /****Variable declaration for 'ValidateOpportunityPartner' Trigger***
    public String ValidateOpportunityPartner = null;
    
    Public String IGDSMillionDollarPost = null;
    Public Final Decimal millionDollar = 1000000;
    
    /******Variable declaration for 'OCR Validation' Trigger***
    Boolean OCR_Validation = FALSE;
    
    /***Retrieving Custom Settings**
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    System.debug('++++++++++83++++++++customsettings:'+customsettings);
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Opportunity')
        {
            if(cs.Trigger__c == 'populateOptyOwnerInfo') {
                populateOptyOwnerInfo = cs.Value__c;    
            }            
            if(cs.Trigger__c == 'OpportunityOwnerLinkTrg') {
                OpportunityOwnerLinkTrg = cs.Value__c;    
            }
            if(cs.Trigger__c == 'UpdateOppotunityOwnerEmailTrigger') {
                UpdateOppotunityOwnerEmailTrigger = cs.Value__c;    
            }            
            if(cs.Trigger__c == 'syncOppScheduleDate_Fix') {
                syncOppScheduleDate_Fix = cs.Value__c;    
            }
            if(cs.Trigger__c == 'CreateOptyShare') {
                CreateOptyShare = cs.Value__c;    
            }
            if(cs.Trigger__c == 'OpportunitySubmitForApproval') {
                OpportunitySubmitForApproval = cs.Value__c;    
            }
            if(cs.Trigger__c == 'SendAccountInfoToCDM') {
                runSendAccountInfoToCDM = cs.Value__c;    
            }
            if(cs.Trigger__c == 'SKPOpportunitySync') {
                SKPOpportunitySync = cs.Value__c;    
            }
            if(cs.Trigger__c == 'OpportunitySVStatus') {
                OpportunitySVStatus = cs.Value__c;    
            }
            if(cs.Trigger__c == 'ValidateOpportunityPartner') {
                ValidateOpportunityPartner = cs.Value__c;    
            }
            if(cs.Trigger__c == 'IGDSMillionDollarPost') {
                IGDSMillionDollarPost = cs.Value__c;    
            }
            if(cs.Trigger__c == 'OCR_Validation') {
                OCR_Validation = Boolean.valueOf(cs.Value__c);   
            }           
        }
    }
    
/*****************************************START TRIGGER************************************************

    
    System.debug('+++++121+++++++++++Trigger.isBefore:'+Trigger.isBefore);
    if(Trigger.isBefore){
        
        /**GSA Eligibility based on US Federal/ GSA Pricing Starts*
        for (Opportunity opp : Trigger.new)
        {
            if(Trigger.isUpdate && trigger.oldmap.get(opp.id).US_Federal_GSA_Pricing__c != trigger.newmap.get(opp.id).US_Federal_GSA_Pricing__c)
            {           
                if(opp.US_Federal_GSA_Pricing__c=='Yes')opp.GSA_Eligibility__c='GSA Eligible';
                else if(opp.US_Federal_GSA_Pricing__c=='No')opp.GSA_Eligibility__c='Standard Pricing Applies';                
            }
            else if(Trigger.isInsert)
            {        
                if(opp.US_Federal_GSA_Pricing__c=='Yes')opp.GSA_Eligibility__c='GSA Eligible';
                else if(opp.US_Federal_GSA_Pricing__c=='No')opp.GSA_Eligibility__c='Standard Pricing Applies';                  
            }
        }       
        /**GSA Eligibility based on US Federal/ GSA Pricing Ends*
        
        
        /*****Code logic added by Sandhya Ramesh for #02768856 start **
        
        Set<id> accIds = new set<id>();
        for (Opportunity opp : Trigger.new)
        {
            accIds.add(opp.AccountId);
        }
          
        if(accIds != null && accIds.size() > 0 && !Test.isRunningTest()){
         Map<id, Account> imgas = new Map<id, Account>([select IMGA_Owner__c from Account where Id in :accIds]); 
            System.debug('imgas==='+imgas);
            for (Opportunity opp : Trigger.new){
             //   if(imgas != null && imgas.size() > 0)
                  if(!imgas.isEmpty() && imgas.get(opp.AccountId) != null)
                    opp.IMGA_Owner__c = imgas.get(opp.AccountId).IMGA_Owner__c;
            }    
        }   
        
        /**** Code end ***
        
        
        if(Trigger.isUpdate)
        {
            /* Case#08029723 
            if(OCR_Validation){
             OpportunityValidator.ValidateOCR_OnOppStageChange(Trigger.newmap,Trigger.oldmap);
            } // End of Case#08029723
            
            Decimal conversionrate;
            Decimal opportunityamount;
            Map<String,Decimal> currencymap = new Map<String,Decimal>();
            List<CurrencyType> currencylist =[SELECT IsoCode,ConversionRate FROM CurrencyType];
            for(CurrencyType c: currencylist){
            currencymap.put(c.IsoCode,c.ConversionRate);
            }
            for(Opportunity op: Trigger.new){
                   conversionrate= currencymap.get(op.CurrencyIsoCode);
                   if(op.Amount != null){
                       opportunityamount = op.Amount / conversionrate ;
                       if(!(opportunityamount != null && opportunityamount >= 30000)){
                           op.Global_Chatter__c = false;
                       }
                   }
             System.debug('oppamount'+op.Amount);
             System.debug('oppamount1'+opportunityamount);
             system.debug('oppglobalchange'+op.Global_Chatter__c);
            }
            
          /******** Start of Cloud Solutions Opp Partner Validation Rule,Read/write ability For Cloud Solutions Opportunities ****  
            
          /* Case # 07955446 : Cloud Solutions Opp Partner Validation Rule 
            Id standardRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
            for(Opportunity opp:trigger.new ){
                
                if(ValidateOpportunityPartner == 'true' && opp.RecordTypeId == standardRecordTypeId)
                {
                //Added below AND condition for the Case#08582999 - Partner mandate for Cloud opportunities - need to add filter to validate rule
                   if((trigger.oldmap.get(opp.id).StageName != trigger.newmap.get(opp.id).StageName)  && opp.CurrencyIsoCode =='USD')
                    {
                       if(((trigger.newmap.get(opp.id).StageName == '2 - Solution Developed')||(trigger.newmap.get(opp.id).StageName == '3 - Solution Agreed')||
                         (trigger.newmap.get(opp.id).StageName == '4 - Negotiate')|| (trigger.newmap.get(opp.id).StageName == '5 - Signed/PO in')))
                         {
                           
                           //OppPartnerAction.getOppProductAndParnterCount(opp.id);
                           
                           if(OppPartnerAction.getOppProductAndParnterCount(opp.id) == true){
                                
                               trigger.newMap.get(opp.id).addError(System.Label.Cloud_Solution_Product_Line_Label);
                           }
                         }
                     }else{
                             /* Case # 07754082 : Read/write ability For Cloud Solutions Opportunities
                             OppPartnerAction.getOppCSProductCount(opp);
                             
                          }
                }
                else{
                    /* Case # 07754082 : Read/write ability For Cloud Solutions Opportunities
                    /* For other record types with cloud solution product : user try change recordtype from untabbed opportunity
                    if( opp.IsCloudSolutionProductCreated__c== true){
                             opp.IsCloudSolutionProductCreated__c= false;
                     }
                
               }
            }
            
            /******** End of Cloud Solutions Opp Partner Validation Rule,Read/write ability For Cloud Solutions Opportunities **** 
            
            if(!Validator_OpportunityObjectTrigger.hasAlreadyDone()|| Test.isRunningTest()){
                System.debug('+++++++++ Executing trigger for before update++++++++ '+Validator_OpportunityObjectTrigger.hasAlreadyDone());
                system.debug('++++++++++ is it running from test method ++++'+Test.isRunningTest());
                Validator_OpportunityObjectTrigger.setAlreadyDone();
                System.debug('++++123++++++++++Trigger.isUpdate:'+Trigger.isUpdate);
                runOpportunityOwnerLinkTrg=true; 
                System.debug('+++124+++++runOpportunityOwnerLinkTrg:'+runOpportunityOwnerLinkTrg);
                /****populateOptyOwnerInfo***
                /*---start---
                System.debug('------Executing populateOptyOwnerInfo Trigger:'+populateOptyOwnerInfo);
                if(populateOptyOwnerInfo == 'True'){
                   System.debug('+++154+++++populateOptyOwnerInfo:'+populateOptyOwnerInfo);
                   if(triggerFlowControl.triggerRunCount('populateOptyOwnerInfo') <= 1 ){
                    try {
                            List<Opportunity> optyList4Update = new List<Opportunity>();
                            for(Integer i=0; i<Trigger.new.size(); i++) {
                                if( Trigger.new[i].Ownerid != trigger.old[i].OwnerId) {
                                    optyOwnerIds.add(Trigger.new[i].OwnerId);
                                    OptyList4Update.add(Trigger.new[i]);
                                }
                            }
                
                            if ( optyOwnerIds.size() > 0) {
                
                                Map<Id, String> ownerFirstName = new Map<Id, String>();
                                Map<Id, String> ownerLastName = new Map<Id, String>();
                                Map<Id, String> ownerEmail = new Map<Id, String>();         
                
                                List<User> usrList = [SELECT Id, FirstName, LastName, email FROM User 
                                                        WHERE Id in :optyOwnerIds];
                
                                //Capture Owner information
                                for (User ownerInfo : usrList) {
                                    ownerFirstName.put( ownerInfo.Id, ownerInfo.FirstName);
                                    ownerLastName.put( ownerInfo.Id, ownerInfo.LastName);
                                    ownerEmail.put( ownerInfo.Id, ownerInfo.email);             
                                }
                        
                                //Apply Owner information
                                for(Integer i=0; i<OptyList4Update.size(); i++) {
                                    Opportunity opp = OptyList4Update[i];
                                    opp.Owner_First_Name__c = ownerFirstName.get(opp.OwnerId);
                                    System.debug('+++++183+++++opp.Owner_First_Name__c:'+opp.Owner_First_Name__c);
                                    opp.Owner_Last_Name__c = ownerLastName.get(opp.OwnerId);
                                    System.debug('+++++185+++++opp.Owner_Last_Name__c :'+opp.Owner_Last_Name__c );
                                    opp.Owner_Email__c = ownerEmail.get(opp.OwnerId);
                                    //System.debug(Logginglevel.FINE,'Opportunity['+i+'] = '+opp.Id);
                                    System.debug('+++++188+++++opp.Owner_Email__c :'+opp.Owner_Email__c );                     
                                }
                            }       
                        
                    }
                    catch(DMLException dmlex){
                        Trigger.new[0].addError('Failed to Fetch Opportunity Owner Information'+dmlEx.getDmlId(0)+' Error: '+dmlex.getMessage());
                    }
                    catch(Exception ex){
                        Trigger.new[0].addError('Failed to Fetch Opportunity Owner Information!'+ex.getMessage());          
                    }
                   }
                }                
            
                  /****populateOptyOwnerInfo***

            }else{
                System.debug('1111 Trigger Code not executed....');
            }
        }/*Ketan Benegal -- isUpdate ends here
        if(Trigger.isInsert){
            System.debug('+++++205+++++++Trigger.isInsert:'+Trigger.isInsert);
           for(Opportunity opp: Trigger.new){
            opp.Global_Chatter__c= true; 
           }
            runOpportunityOwnerLinkTrg=true;  
            System.debug('+++++207+++++++runOpportunityOwnerLinkTrg:'+runOpportunityOwnerLinkTrg);
                          
            /****populateOptyOwnerInfo***
            /*---start---
            System.debug('------Executing populateOptyOwnerInfo Trigger in before insert:'+populateOptyOwnerInfo);
            if(populateOptyOwnerInfo == 'True'){ 
               System.debug('######212#####populateOptyOwnerInfo:'+populateOptyOwnerInfo);
            
               if(triggerFlowControl.triggerRunCount('populateOptyOwnerInfo') <= 1 ){ 
                System.debug('++++215++++++:');
                    try { 
                            for(Integer i=0; i<Trigger.new.size(); i++) {
                                optyOwnerIds.add(Trigger.new[i].OwnerId);
                            }
                
                            if ( optyOwnerIds.size() > 0) {
                
                                Map<Id, String> ownerFirstName = new Map<Id, String>();
                                Map<Id, String> ownerLastName = new Map<Id, String>();
                                Map<Id, String> ownerEmail = new Map<Id, String>();         
                
                                //Capture Owner information
                                for (User ownerInfo : [SELECT Id, FirstName, LastName, email FROM User 
                                                        WHERE Id in :optyOwnerIds]) {
                                    ownerFirstName.put( ownerInfo.Id, ownerInfo.FirstName);
                                    ownerLastName.put( ownerInfo.Id, ownerInfo.LastName);
                                    ownerEmail.put( ownerInfo.Id, ownerInfo.email);             
                                }
                        
                                //Apply Owner information
                                for(Integer i=0; i<Trigger.new.size(); i++) {
                                    Opportunity opp = Trigger.new[i];
                                    opp.Owner_First_Name__c = ownerFirstName.get(opp.OwnerId);
                                    System.debug('#####239#######opp.Owner_First_Name__c:'+opp.Owner_First_Name__c);
                                    opp.Owner_Last_Name__c = ownerLastName.get(opp.OwnerId);
                                    System.debug('######241#######opp.Owner_Last_Name__c :'+opp.Owner_Last_Name__c );
                                    opp.Owner_Email__c = ownerEmail.get(opp.OwnerId);   
                                    //System.debug(Logginglevel.FINE,'Opportunity['+i+'] Name = '+opp.Name); 
                                    System.debug('#######244########opp.Owner_Email__c :'+opp.Owner_Email__c );                                
                                }
                            }
                                        
                    }
                    catch(DMLException dmlex){
                        Trigger.new[0].addError('Failed to Fetch Opportunity Owner Information'+dmlEx.getDmlId(0)+' Error: '+dmlex.getMessage());
                    }
                    catch(Exception ex){
                        Trigger.new[0].addError('Failed to Fetch Opportunity Owner Information!'+ex.getMessage());          
                    }          
               }     
            }
            /****populateOptyOwnerInfo***
            /*---End---
        }
    }
/*************************************END OF BEFORE INSERT AND UPDATE**************************
    
    
/*********************************************AFTER INSERT AND UPDATE**************************************    
    //System.debug('+++++301+++++++++++Trigger.isAfter:'+Trigger.isAfter);
    
    if(Trigger.isAfter){ 
        System.debug('+++++267++++++Trigger.isAfter:'+Trigger.isAfter); /*if(Trigger.isAfter)
        if(Trigger.isInsert){
            System.debug('++++268+++++Trigger.isInsert:'+Trigger.isInsert);
            //runOpportunitySubmitForApproval=true; 
            //System.debug('+++276+++++runOpportunitySubmitForApproval:'+runOpportunitySubmitForApproval);
            if(OpportunitySubmitForApproval == 'True'){ 
                fillRecordTypeIds(); 
                for (Integer i = 0; i < Trigger.new.size(); i++) {
                    if(recordTypeIds != Null && recordTypeIds.contains(Trigger.new[i].RecordTypeId)){
                            System.debug('---282----Trigger.new[i].GSA_Eligibility__c:'+Trigger.new[i].GSA_Eligibility__c);
                            if ( Trigger.new[i].GSA_Eligibility__c == 'GSA Eligible' ) {
                                // create the new approval request to submit
                                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                                req.setComments('Submitted for approval. Please approve.');
                                req.setObjectId(Trigger.new[i].Id);
                                
                                // submit the approval request for processing
                                Approval.ProcessResult result = Approval.process(req);
                                
                                // display if the reqeust was successful
                                System.debug('-----293-------Submitted for approval successfully from trigger when inserting a record: '+result.isSuccess());
                            }
                    }
                }
            }
            
             
            /****CreateOptyShare***
            /*---start---
            System.debug('------Executing CreateOptyShare Trigger:'+CreateOptyShare);
            if(CreateOptyShare == 'True'){
                System.debug('$$$$$$$$$275$$$$$$$$$CreateOptyShare:'+CreateOptyShare);
                try{                        
                    for (Country_Settings__c c: country_list){
                        if(!country.contains(c.Name))
                        {
                            country.add(c.Name);
                            country_query += '\''+c.Name+'\',';
                        }
                        //system.debug('$$$$$$$$$$$$$$country_query:' + country_query);
                    }
                    for (Opportunity op: trigger.new)
                    {        
                        opty_ids.add (op.id);
                    }
                    for(Opportunity_Security__c op: Opty){
                        if (op.Object_name__c=='Opportunity')
                        {
                            if(!Opty_fields.contains(op.Field_Name__c)){    
                                Opty_fields.add(op.Field_Name__c);
                                Opty_query_fields += ' '+op.Field_name__c +',';
                                Visibility_setting.put(op.Field_name__c, op.Visibility_Access_Level__c);
                                Opty_fields_list.add(op.Field_Name__c);
                            }
                        }
                        
                        if (op.Object_name__c=='Postal_Code')
                        {
                            if(!Postal_Code_fields.contains(op.Field_Name__c))
                            {    
                                Postal_Code_fields.add('Postal_Code2__r.'+op.Field_Name__c);
                                Postal_Code_query_fields += 'Postal_Code2__r.'+op.Field_name__c +',';
                                Visibility_setting.put('Postal_Code2__r.'+op.Field_name__c, op.Visibility_Access_Level__c);
                                Postal_Code_fields_list.add(op.Field_Name__c);
                            }
                        }
                        
                        if (op.Object_name__c=='Account')
                        {
                            if(!Account_fields.contains(op.Field_Name__c))
                            {    
                                Account_fields.add(op.Field_Name__c);
                                Account_query_fields += ' '+op.Field_name__c +',';
                                Visibility_setting.put(op.Field_name__c, op.Visibility_Access_Level__c);
                                Account_fields_list.add(op.Field_Name__c);
                            }
                        }
                    }
                     /*Developer Name: Madhu Paladugu
                      Description   : added if conditions to remove out of bound index problem
                    
                    if(Opty_query_fields!=null && Opty_query_fields!='')
                    Opty_query_fields = Opty_query_fields.substring (0,Opty_query_fields.length()-1);
                    if(country_query!=null && country_query!='')
                    country_query = country_query.substring (0,country_query.length()-1);
                    if(Postal_Code_query_fields!=null && Postal_Code_query_fields!='')
                    Postal_Code_query_fields = Postal_Code_query_fields.substring (0,Postal_Code_query_fields.length()-1);
                    if(Account_query_fields!=null && Account_query_fields!='')
                    Account_query_fields = Account_query_fields.substring (0,Account_query_fields.length()-1);
                    
                    for(integer i=0;i<opty_ids.size();i++)
                    {
                        opty_id_list += '\''+opty_ids[i]+'\',';
                    }
                    opty_id_list = opty_id_list.substring (0,opty_id_list.length()-1);
                                       
                    //string database_query = 'select Id,OwnerId,AccountId,'+opty_query_fields +' from Opportunity where ID IN (' +opty_id_list +') and Opportunity.Account.BillingCountry IN (' +country_query +')';
                    /*Developer Name: Madhu Paladugu
                      Description   : modified formation of SOQL to remove out of bound index problem
                    
                    string database_query = 'select Id,OwnerId,AccountId';
                    if(opty_query_fields!=null && opty_query_fields!=''){
                        database_query=database_query+','+opty_query_fields+' from Opportunity where ID IN (' +opty_id_list +') and Opportunity.Account.BillingCountry IN (' +country_query +')'; 
                    }
                    else{
                       database_query=database_query+' from Opportunity where ID IN (' +opty_id_list +') and Opportunity.Account.BillingCountry IN (' +country_query +')'; 
                    }
                    system.debug('+++334++++++database_query:' + database_query);
                    List<sObject> List_Opty = Database.query(database_query);
                    for(SObject optyRecord : List_Opty)
                    {    
                        for(integer i=0;i<Opty_fields_list.size();i++)
                        {
                            OpportunityShare optyshare = new OpportunityShare();
                            optyshare.OpportunityId = string.valueof(optyrecord.get('Id'));
                            optyshare.UserOrGroupId = string.valueof(optyRecord.get(Opty_fields_list[i]));
                            if(Visibility_setting.get(Opty_fields_list[i]) =='R')
                                optyshare.OpportunityAccessLevel = 'Read';
                            if(Visibility_setting.get(Opty_fields_list[i]) =='W')
                                optyshare.OpportunityAccessLevel = 'Edit';
                                Opty_share.add(optyshare);
                         }
                            account_id_list += '\''+string.valueof(optyrecord.get('AccountId'))+'\',';
                            opty_owner.put(string.valueof(optyrecord.get('Id')),string.valueof(optyrecord.get('OwnerId')));
                            if(!acc_opty_map.containskey(string.valueof(optyrecord.get('AccountId'))))
                            {
                                List<String> opty_id = new list<String>();
                                opty_id.add(string.valueof(optyrecord.get('Id')));
                                acc_opty_map.put(string.valueof(optyrecord.get('AccountId')),opty_id); 
                            }
                            else
                            {
                                List<String> opty_id = acc_opty_map.get(string.valueof(optyrecord.get('AccountId')));
                                opty_id.add(string.valueof(optyrecord.get('Id')));
                                acc_opty_map.put(string.valueof(optyrecord.get('AccountId')),opty_id); 
                            }
                       // }
                    }
                    if(account_id_list != '')
                    account_id_list = account_id_list.substring (0,account_id_list.length()-1);
                    system.debug('$$$$$$$366$$$$$$$$$account_id_list:'+ account_id_list + '\t acc_opty_map:' + acc_opty_map + '\t opty_owner:' +opty_owner);
                      /*Developer Name: Madhu Paladugu
                      Description   : added if conditions to remove out of bound index problem
                    
                    String database_query1;
                    if(account_id_list != ''){
                    //database_query = 'select Id,Postal_Code__c,'+account_query_fields +','+postal_code_query_fields +' from Account where ID IN (' +account_id_list +')';
                      database_query1 = 'select Id,Postal_Code2__c';
                      if(account_query_fields!=null && account_query_fields!=''){
                          database_query1=database_query1+','+account_query_fields;
                          if(postal_code_query_fields!=null && postal_code_query_fields!=''){
                          database_query1=database_query1+','+postal_code_query_fields+' from Account where ID IN (' +account_id_list +')';
                          }
                          else{
                          database_query1=database_query1+' from Account where ID IN (' +account_id_list +')';
                          }
                      }
                      else{
                          if(postal_code_query_fields!=null && postal_code_query_fields!=''){
                            database_query1=database_query1+','+postal_code_query_fields+' from Account where ID IN (' +account_id_list +')';
                          }
                          else{
                              database_query1=database_query1+' from Account where ID IN (' +account_id_list +')';
                          }
                      }
                     
                    }
                    system.debug('$$$$$$$371$$$$$$$database_query:'+database_query1);
                    List<sObject> List_Account = new List<sObject>();
                    if(database_query1!=null && database_query1!='')
                    List_Account =Database.query(database_query1);
                    for(SObject acctRecord : List_Account)
                    { 
                    
                        for(integer i=0;i<Account_fields_list.size();i++)
                        {
                            
                            for( string optyid: acc_opty_map.get(string.valueof(acctrecord.get('Id'))))
                            {
                                OpportunityShare optyshare = new OpportunityShare();
                                optyshare.OpportunityId = optyid;
                                optyshare.UserOrGroupId = string.valueof(acctRecord.get(Account_fields_list[i]));
                                if(Visibility_setting.get(Account_fields_list[i]) =='R')
                                optyshare.OpportunityAccessLevel = 'Read';
                                if(Visibility_setting.get(Account_fields_list[i]) =='W')
                                optyshare.OpportunityAccessLevel = 'Edit';
                                Opty_share.add(optyshare);
                            }
                        }
                        
                        for(integer i=0;i<Postal_Code_fields_list.size();i++)
                        {
                            SObject postal_code = acctRecord.getSObject('Postal_Code2__r');
                            if(acctrecord.get('Postal_Code2__c') != Null)
                            {
                                for( string optyid: acc_opty_map.get(string.valueof(acctrecord.get('Id'))))
                                {
                                    OpportunityShare optyshare = new OpportunityShare();
                                    optyshare.OpportunityId = optyid;
                                    optyshare.UserOrGroupId = string.valueof(postal_code.get(Postal_Code_fields_list[i]));
                                    if(Visibility_setting.get('Postal_Code2__r.'+Postal_Code_fields_list[i]) =='R')
                                    optyshare.OpportunityAccessLevel = 'Read';
                                    if(Visibility_setting.get('Postal_Code2__r.'+Postal_Code_fields_list[i]) =='W')
                                        optyshare.OpportunityAccessLevel = 'Edit';
                                        Opty_share.add(optyshare);
                                }
                            }
                        }
                    }
                    for(OpportunityShare opshare: opty_share)
                    {
                        optyshare_userid.add(opshare.userorgroupid);
                    }
                    
                    List<User> uLst = [select id, isactive from user where id in: optyshare_userid and isactive = true];
                     
                    for(User u: uLst)
                    {
                        optyshare_activeuser.put(u.Id, u);
                    }
                    for(OpportunityShare opshare: opty_share)
                    {
                        system.debug('$$$$$$$$$424$$$$$$$$$$opshare.userorgroupid:'+ opshare.userorgroupid);
                        if(optyshare_activeuser.containskey(opshare.userorgroupid)&& opty_owner.get(opshare.OpportunityId) != opshare.userorgroupid)
                        opty_share_insert.add(opshare);
                    }
                    system.debug('$$$$$$$$$$428$$$$$$$$$$$$total_optyshare:' + opty_share_insert);
                    insert Opty_share_insert;
                    
                }catch(exception e){
                    for (Opportunity op: trigger.new)
                    {  op.adderror('An issue occured in creating sharing rule for Opportunity: '+e.getMessage());
                    }       
                }
                
}
            /****CreateOptyShare***
            /*---End---
            
                      
        } 
        System.debug('++++439+++++++++Trigger.isUpdate:'+Trigger.isUpdate);
        if(Trigger.isUpdate){ 
        for(Opportunity opp: Trigger.new){
        System.debug('Flow Chatter'+ opp.Global_Chatter__c );
        System.debug('Flow Chatters'+ opp.Amount );
        }
            //Added on 4/22/13 to handle issues with system update done by sfdc internally 
            if(Validator_OpportunityObjectTrigger.CloseDataOnOpportunity==false){
                for(Integer i=0;i<Trigger.new.size();i++){
                    if(Trigger.new[i].CloseDate!=Trigger.Old[i].CloseDate){
                        system.debug('++++++++inside logic making trigger to execute update logic on close date change++++++');
                        Validator_OpportunityObjectTrigger.CloseDataOnOpportunity=true;
                        break;
                    }
                }
            }
          
           if(!Validator_OpportunityObjectTrigger.hasAlreadyDoneForAfterUpdate() || Test.isRunningTest()|| Validator_OpportunityObjectTrigger.CloseDataOnOpportunity){
                System.debug('+++++++++ Executing trigger for after update++++++++ ');
                system.debug('++++++++++ is it running from test method ++++'+Test.isRunningTest());
                Validator_OpportunityObjectTrigger.setAlreadyDoneForAfterUpdate();
                /* Book to Billing- Web Service Callout Start 
                    system.debug('++B2B_Integration.firstRun++'+B2B_Integration.firstRun);    
                    if(SKPOpportunitySync == 'True' && B2B_Integration.firstRun && (!system.isFuture()) && (!system.isBatch())){
                    system.debug('++B2B_Integration.firstRun++'+B2B_Integration.firstRun);
                    Set<String> customerids = new Set<String>();
                    Map<String, IM_Customer_Account__c> customeracctMap = new Map<String,IM_Customer_Account__c>();
                    system.debug(' 0001 --InTrigger--Limits.getQueries:--- '+ Limits.getQueries());
                    List<Opportunity> opportunitylist=[ Select Id,Owner.Name,Status__c,IM_Booked_Date__c,Name,Type,StageName,Commissionable_Window_Close_Date__c,
                         IMGA_Name__c,First_Bill_Booked_Date__c,Upsell_Customer_ID__c,Upsell_Customer_ID__r.Source_System__c,Customer_Account_Number__c ,IM_Up_Sell_Sold_To__c,RecordTypeId,SKP_Opportunity_Sync_Date__c,
                        (Select Id,Customer_ID__c,CaseNumber from Cases1__r where RecordType.Name IN ('NCSP: SKP New Customer Setup','NCSP: DMS'))
                        from Opportunity where Id IN :Trigger.newMap.keySet()];
                    for(Opportunity op: opportunitylist){
                        customerids.add(op.IM_Up_Sell_Sold_To__c);
                    }
                    system.debug('++customerids++'+customerids);  
                    List<IM_Customer_Account__c> custlist = [select Name,Source_System__c from IM_Customer_Account__c where Name in :customerids AND Source_System__c ='SKP Europe' AND IME_Display_Division__c = 'Europe'];
                    for(IM_Customer_Account__c ima: custlist)
                        customeracctMap.put(ima.Name,ima);
                    system.debug('++customeracctMap++'+customeracctMap);
                    for(Opportunity op: opportunitylist){
                        fillRecordTypeIds();
                        String customerId;
                        system.debug('+++Cases1__r++'+ op.Cases1__r.size());
                        system.debug('+++recordTypeIds++'+ recordTypeIds);
                        system.debug('+++EUrecordTypeIds++'+ EUrecordTypeIds);
                        if(op.Type=='New Deal'){
                           if(recordTypeIds != Null && recordTypeIds.contains(op.RecordTypeId)){
                              if(op.Cases1__r.size()>0){
                                 for(Case ca:op.Cases1__r ){
                                     customerId=ca.Customer_ID__c; 
                                     system.debug('+++customerId++'+ customerId);
                                    }
                                } 
                              } 
                              else if(EUrecordTypeIds != Null && EUrecordTypeIds.contains(op.RecordTypeId)){
                                      customerId=op.Customer_Account_Number__c;
                                      system.debug('+++customerId++'+ customerId);
                                      }
                          } 
                          else if(op.Type=='Up-Sell/Lift'){             
                               if((recordTypeIds != Null && recordTypeIds.contains(op.RecordTypeId) && op.Upsell_Customer_ID__r.Source_System__c =='SKP NA')){
                                          customerId = op.Upsell_Customer_ID__c;
                                  }
                               else if(EUrecordTypeIds != Null && EUrecordTypeIds.contains(op.RecordTypeId) && op.IM_Up_Sell_Sold_To__c != null && !customeracctMap.isEmpty()){
                                         system.debug('op.IM_Up_Sell_Sold_To__c'+ op.IM_Up_Sell_Sold_To__c); 
                                          customerId = customeracctMap.get(op.IM_Up_Sell_Sold_To__c.toupperCase()).Name;
                                      }
                                          system.debug('+++customerId++'+ customerId);
                                 }
                        
                    if(((op.Type=='New Deal' && (op.StageName=='6 - Setup' || op.StageName=='7 - Closed')  && customerId != null)||(op.Type=='Up-Sell/Lift' && (op.StageName=='5 - Signed/PO in' ||op.StageName=='6 - Setup' ||op.StageName=='7 - Closed') &&  customerId != null)) && (op.Commissionable_Window_Close_Date__c >= system.today() || op.Commissionable_Window_Close_Date__c == null) && op.SKP_Opportunity_Sync_Date__c== null){
                      if(!Test.isRunningTest())
                      B2B_Integration.create_opportunity(op.Id,true); 
                      B2B_Integration.firstRun=false;
                      system.debug('+++create opportunity++'+ customerId);
                     }
                     else if(((op.Type=='New Deal' && (op.StageName=='6 - Setup' || op.StageName=='7 - Closed') && customerId != null)||(op.Type=='Up-Sell/Lift' && (op.StageName=='5 - Signed/PO in' ||op.StageName=='6 - Setup' ||op.StageName=='7 - Closed') && customerId != null)) && (op.Commissionable_Window_Close_Date__c >= system.today() || op.Commissionable_Window_Close_Date__c == null) && op.SKP_Opportunity_Sync_Date__c!= null
                            &&(Trigger.oldMap.get(op.Id).Type !=Trigger.newMap.get(op.Id).Type || Trigger.oldMap.get(op.Id).StageName !=Trigger.newMap.get(op.Id).StageName ||Trigger.oldMap.get(op.Id).Customer_Account_Number__c !=Trigger.newMap.get(op.Id).Customer_Account_Number__c || Trigger.oldMap.get(op.Id).Upsell_Customer_ID__c !=Trigger.newMap.get(op.Id).Upsell_Customer_ID__c ||
                              Trigger.oldMap.get(op.Id).Commissionable_Window_Close_Date__c !=Trigger.newMap.get(op.Id).Commissionable_Window_Close_Date__c || Trigger.oldMap.get(op.Id).IM_Booked_Date__c !=Trigger.newMap.get(op.Id).IM_Booked_Date__c || Trigger.oldMap.get(op.Id).Status__c !=Trigger.newMap.get(op.Id).Status__c || Trigger.oldMap.get(op.Id).Name !=Trigger.newMap.get(op.Id).Name || 
                              Trigger.oldMap.get(op.Id).OwnerId !=Trigger.newMap.get(op.Id).OwnerId || Trigger.oldMap.get(op.Id).IMGA_Name__c !=Trigger.newMap.get(op.Id).IMGA_Name__c || Trigger.oldMap.get(op.Id).First_Bill_Booked_Date__c !=Trigger.newMap.get(op.Id).First_Bill_Booked_Date__c)){
                      if(!Test.isRunningTest())
                      B2B_Integration.update_opportunity(op.Id,false);
                      B2B_Integration.firstRun=false;
                      system.debug('+++update opportunity++'+ customerId);
                        }
                      }     
                  }
                /* Book to Billing- Web Service Callout End 
                if(OpportunitySubmitForApproval == 'True'){ 
                    system.debug('+++++++++++executing OpportunitySubmitForApproval trigger on update++++');
                    fillRecordTypeIds(); 
                    for (Integer i = 0; i < Trigger.new.size(); i++) {
                        if(recordTypeIds != Null && recordTypeIds.contains(Trigger.new[i].RecordTypeId)){
                                System.debug('----588--------Trigger.New:'+Trigger.New);
                                System.debug('----589----Trigger.old[i].GSA_Eligibility__c:'+Trigger.old[i].GSA_Eligibility__c +'\t Trigger.new[i].GSA_Eligibility__c:'+Trigger.new[i].GSA_Eligibility__c);
                                if(Trigger.old[i].GSA_Eligibility__c != 'GSA Eligible' && Trigger.new[i].GSA_Eligibility__c == 'GSA Eligible'){
                                    // create the new approval request to submit
                                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                                    req.setComments('Submitted for approval. Please approve.');
                                    req.setObjectId(Trigger.new[i].Id);
                                    try{
                                        // submit the approval request for processing
                                        Approval.ProcessResult result = Approval.process(req);
                                        // display if the reqeust was successful
                                        System.debug('----599--------Submitted for approval successfully when Adding Products to an oppty: '+result.isSuccess());
                                    }catch(Exception e){
                                        System.debug('-----601-----e.getMessage:'+e.getMessage());
                                    }
                                }
                        }
                    }
                } 
                /****syncOppScheduleDate_Fix***
                /*---start---
            
                  
                /****syncOppScheduleDate_Fix***
                /*---End---
                
                
             
            
            
            
                /****UpdateOppotunityOwnerEmailTrigger***
                /*---start---
                System.debug('------Executing UpdateOppotunityOwnerEmailTrigger Trigger:'+UpdateOppotunityOwnerEmailTrigger);
                if(UpdateOppotunityOwnerEmailTrigger == 'True' && Trigger.isUpdate && Trigger.isAfter){
                    System.debug('^^^^^579^^^^^^^^^UpdateOppotunityOwnerEmailTrigger:'+UpdateOppotunityOwnerEmailTrigger);
                    System.debug('-------Checking the SOQL limits Limits.getQueries:' + Limits.getQueries());
                    System.debug('-------Checking the SOQL limits Limits.getLimitQueries:' + Limits.getLimitQueries());
                    //Changes made to exclude NA Renewal record type
                    List<Opportunity> OpportunitysWithOpportunityCompetitors = [select id, name,OwnerId,Owner.Email,Owner.Sales_Division__c, StageName , (select id, Name,Opportunity_Owner_Email__c from Opportunity_Competitors1__r) from Opportunity where Id IN:Trigger.newMap.keySet()and RecordType.Name!='NA Renewal'];
                    for(Opportunity o: Trigger.new) {
                        if(Trigger.oldMap.get(o.Id).OwnerId != o.OwnerId) {    
                            validUserIdSet.add(o.OwnerId); 
                        }
                    }
                    if(!validUserIdSet.isEmpty()) {
                        Map<Id, User> userMap = new Map<Id, User>([Select Id, Name, Sales_Division__c FROM User WHERE Id IN: validUserIdSet]);// AND Sales_Division__c =: 'North America']);  
                        
                        if(userMap != null && !userMap.isEmpty()) {
                            // For loop to iterate through all the queried Account records 
                            for(Opportunity o: OpportunitysWithOpportunityCompetitors){
                               if(userMap.get(o.OwnerId) != null) {
                                 // Use the child relationships dot syntax to access the related Opportunity Competitors.
                                 for(Opportunity_Competitor__c oc: o.Opportunity_Competitors1__r){
                                   System.debug('---29------o.Owner.Email :'+o.Owner.Email +'\t oc.Opportunity_Owner_Email__c:'+oc.Opportunity_Owner_Email__c +'\t o.StageName:'+o.StageName +'\t o.Owner.Sales_Division__c:'+o.Owner.Sales_Division__c);
                                   if((o.Owner.Sales_Division__c == 'North America') && (o.Owner.Email != oc.Opportunity_Owner_Email__c) && 
                                     (o.StageName == '1 - Qualification' || o.StageName == '2 - Solution Developed' || o.StageName == '3 - Solution Agreed' || o.StageName == '4 - Negotiate' || o.StageName == '5 - Signed/PO in') ){
                                       oc.Opportunity_Owner_Email__c = o.Owner.Email;
                                       System.debug('---33 inside if----oc.Opportunity_Owner_Email__c:'+oc.Opportunity_Owner_Email__c);
                                   } else {
                                       oc.Opportunity_Owner_Email__c = '';
                                       System.debug('---36 inside else----oc.Opportunity_Owner_Email__c:'+oc.Opportunity_Owner_Email__c);
                                   }
                                                      
                                   OpportunityCompetitorsToUpdate.add(oc);
                                 }
                               }        
                            }
                              
                           //Now outside the FOR Loop, perform a single Update DML statement. 
                           update OpportunityCompetitorsToUpdate;
                       }
                   }
                }
            }else{
                System.debug('++++ IsUpdate after code not executed++++');
            }
                /****UpdateOppotunityOwnerEmailTrigger***
                /*---End---
         }                   
        }   
/*********************************************END OF AFTER INSERT AND UPDATE**************************************

    /****OpportunityOwnerLinkTrg***
    /*---start---
    System.debug('------Executing OpportunityOwnerLinkTrg Trigger:'+OpportunityOwnerLinkTrg);
    if(OpportunityOwnerLinkTrg == 'True'){ 
        System.debug('********648*******OpportunityOwnerLinkTrg:'+OpportunityOwnerLinkTrg);
        if(runOpportunityOwnerLinkTrg==true){ 
            System.debug('******649********runOpportunityOwnerLinkTrg:'+runOpportunityOwnerLinkTrg);
            if(triggerFlowControl.triggerRunCount('OpportunityOwnerLinkTrg') <= 1 ){
                for(Integer i = 0; i<Trigger.new.size(); i++){
                    Trigger.new.get(i).Owner_Link__c = Trigger.new.get(i).OwnerId;
                    System.debug('*******653********Trigger.new.get(i).Owner_Link__c:'+Trigger.new.get(i).Owner_Link__c);
                }
            }   
        }
                    
    }    
    /****OpportunityOwnerLinkTrg***
    /*---End---
    //*******************SV Status Changes**********************
    /*if(Trigger.IsBefore && Trigger.IsInsert && OpportunitySVStatus == 'TRUE'){
        SVStatus svInst = new SVStatus();
        svInst.insertSVStatus(trigger.New);
    }
    if(Trigger.IsBefore && Trigger.IsUpdate && OpportunitySVStatus == 'TRUE'){
        SVStatus svUpd = new SVStatus();
        svUpd.updateSVStatus(trigger.New, Trigger.OldMap);
    }
    
    
    //Updated fields on Opportunity,Contract and dsfs__DocuSign_Status__c for case 06462026
    Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
    if(Trigger.IsInsert && Trigger.IsBefore)
    {
        Set<Id> AccountIds = new Set<Id>();        
        for (opportunity o : Trigger.new) 
        {            
            if(o.recordtypeid ==IMERecordTypeId){
                AccountIds.add(o.AccountId);
            }
        }
        
        Map<Id,Account> oppAccounts = new Map<Id,Account>();      
        for(Account acc : [select id,CDM_Registration_Number__c,Billingstreet,Billingcity,BillingCountry,BillingState,BillingPostalCode,Name from Account where id in :AccountIds])
        {
            oppAccounts.put(acc.Id,acc);            
        }
        
        system.debug('oppAccounts=='+oppAccounts);
        for (opportunity opp : Trigger.new) 
        {
            if(oppAccounts.containsKey(opp.AccountId)){
                Account accDets  = oppAccounts.get(opp.AccountId);
                opp.Company_Number__c = accDets.CDM_Registration_Number__c; 
                string address = accDets.Billingstreet != null ? accDets.Billingstreet + ' ' : '' ;
                address+= accDets.Billingcity != null ? accDets.Billingcity + ' ' : '' ;
                address+= accDets.BillingState != null ? accDets.BillingState + ' ' : '' ;
                address+= accDets.BillingPostalCode!= null ?accDets.BillingPostalCode+ ' ': '' ;
                address+= accDets.BillingCountry!= null ?  accDets.BillingCountry : ''  ;      
                opp.Company_Registered_Address2__c = address;
                opp.Company_Name__c = accDets.Name;
            }
        }
    }
    
    if(Trigger.IsUpdate && Trigger.IsBefore)
    {
        Set<Id> ContractIds = new Set<Id>();
        List<Contract> contracts = new List<Contract>();
        Set<Id> OppContracts = new Set<Id>();
                
        for(Opportunity opp : trigger.new) 
        {
            if(opp.IME_Contract__c!=null){
            OppContracts.add(opp.IME_Contract__c);}
            
            if((trigger.oldMap.get(opp.Id).StageName != trigger.newMap.get(opp.Id).StageName && trigger.newMap.get(opp.Id).StageName == 'Lost' && opp.IME_Contract__c != null) && (opp.recordtypeid ==IMERecordTypeId))
            {
               contractIds.add(opp.IME_Contract__c);

               Contract cont = new Contract();
               cont.Status ='Cancelled';
               cont.id=trigger.newMap.get(opp.Id).IME_Contract__c;
               contracts.add(cont);
            }
        }
        if(contracts.size()>0)
        {
            update contracts;
           /* List<dsfs__DocuSign_Status__c> docList = [SELECT id FROM dsfs__DocuSign_Status__c WHERE dsfs__Contract__c =: contractIds];
            for(dsfs__DocuSign_Status__c d : docList)
            {
                d.dsfs__Voided_Reason__c = 'Stage of the Opportunity is changed to Lost';
                d.dsfs__Voided_Date_Time__c = system.today();
               // docList.add(d);
            }
            if(docList.size()>0)update docList;
            
         }
         
         system.debug('OppContracts=='+OppContracts);
         if(OppContracts.size()>0)
         {
             Map<id,contract> contrctDets= new Map<id, contract>([SELECT id, Name from contract where id in:OppContracts]);
             for(Opportunity opp : trigger.new) 
             {
                if(trigger.oldMap.get(opp.Id).IME_Contract__c!= trigger.newMap.get(opp.Id).IME_Contract__c && (opp.recordtypeid ==IMERecordTypeId))
                {
                     Contract contrt = contrctDets.get(opp.IME_Contract__c);
                     opp.Contract_Number__c = contrt.name;
                }           
             }
          }
    } 
    
    //Case# 08861942 IGDS case starts here
    if(Trigger.IsBefore)
    {
        Id IMERecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        Id standardRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        Decimal convertedAmt;
        
        List<CurrencyType> currencyTpyeList = [select id,IsoCode,ConversionRate from CurrencyType where isActive = true] ;
        Map<String , Decimal> isoWithRateMap = new Map<String, Decimal>();
        for(CurrencyType c : currencyTpyeList) {
            isoWithRateMap.put(c.IsoCode , c.ConversionRate) ;
        }
        
        if(Trigger.IsUpdate && !IGDSOpportunityChtter.IDGSPostChatter() && IGDSMillionDollarPost == 'True')
        {            
            for(Opportunity opp:trigger.new)
            {    
                if(trigger.oldmap.get(opp.id).StageName != trigger.newmap.get(opp.id).StageName && trigger.newmap.get(opp.id).StageName == '5 - Signed/PO in')
                {
                    convertedAmt = opp.Amount;
                    
                    if(opp.CurrencyIsoCode != 'USD' && isoWithRateMap.containsKey(opp.CurrencyIsoCode))
                    {
                        convertedAmt = opp.Amount/isoWithRateMap.get(opp.CurrencyIsoCode);
                    }
                    
                    system.debug('convertedAmt=='+convertedAmt);
                    
                    if(opp.RecordTypeId == standardRecordTypeId && convertedAmt >= millionDollar)
                    {                
                        IGDSOpportunityChtter.OppDetails(Trigger.new);
                    }
                    else if(opp.RecordTypeId == IMERecordTypeId && convertedAmt >= millionDollar)
                    {
                        IGDSOpportunityChtter.IMEOppDetails(Trigger.new);
                    }
                }
            } 
        }               
    }
     //Case# 08861942 IGDS case ends here
    
   /**************************************************END TRIGGER********************************************  
     //Method to fetch Opportunity Record Type
     private void fillRecordTypeIds(){
        System.debug('---76---inside RT Method-----');
        Schema.DescribeSObjectResult d = Schema.SObjectType.Opportunity; 
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        //System.debug('------Contains:'+rtMapByName.containsKey('Standard Opportunity'));         
        if(rtMapByName.containsKey('Standard Opportunity')){
            recordTypeIds.add(rtMapByName.get('Standard Opportunity').getRecordTypeId());  
            System.debug('--88--recordTypeIds:'+recordTypeIds);
        }   
         
        if(rtMapByName.containsKey('IME Standard Opportunity')){
            EUrecordTypeIds.add(rtMapByName.get('IME Standard Opportunity').getRecordTypeId());  
            System.debug('--88--EUrecordTypeIds:'+EUrecordTypeIds);
        }  
    }        */     
}
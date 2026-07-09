/**
* Class: OpportunityHelper
*
* Author: Revathy Saminathan
*
* Date Created: 06.05.2020
*
* Purpose: OpportunityHelper is a handler class for all business logic related to opportunity object
*
Change History :
Removed the fields (CDM_Registration_Number__c) dependency as part of #16051
*/
public class OpportunityHelper
{
    public static Set<Id> recordTypeIds = new Set<Id>(); 
    public static Set<Id> EUrecordTypeIds = new Set<Id>();
    public static List <Country_Settings__c> country_list = Country_Settings__c.getall().values();
    public static Set<string> country = new  Set<string>();
    public static string country_query ='';
    public static List<Opportunity_Security__c> Opty = Opportunity_Security__c.getall().values();
    public static Set <String> Opty_fields = new Set <String>();
    public static List<OpportunityShare> Opty_share = new List<OpportunityShare>();
    public static List<OpportunityShare> Opty_share_insert = new List<OpportunityShare>();
    public static Set <String> Postal_Code_fields = new Set <String>();
    public static List <String> Postal_Code_fields_list = new List <String>();
    public static string Opty_query_fields ='';
    public static Map<String, String> Visibility_setting = new Map<String, String>(); 
    public static Set <String> Account_fields = new Set <String>();
    public static List <String> Account_fields_list = new List <String>(); 
    public static List <String> Opty_fields_list = new List <String>(); 
    public static string Account_query_fields ='';
    public static string Postal_Code_query_fields =''; 
    public static string opty_id_list = '';
    public static string account_id_list = '';
    public static Map<String,String> opty_owner = new Map<String,String>();
    public static Map<String, List<String>> acc_opty_map = new Map<String, List<String>>();
    public static Set<String> optyshare_userid = new Set<String>();
    public static Map<Id, User> Optyshare_activeuser = new Map<Id, User>();
    public static Set<Id> validUserIdSet = new Set<Id>();    
    public static List<Opportunity_Competitor__c> OpportunityCompetitorsToUpdate = new List<Opportunity_Competitor__c>{};
    Public static Final Decimal millionDollar = 1000000;
    public static List<Id> optyOwnerIds = new List<Id> ();
    public static List<string> contOldIds = new List<string>(); 
    public static Map<Id, Double> contractOldMap = new Map<Id, Double>();
    private static Set<Id> OppIdForCAInsert = new Set<Id>();
    private static Set<Id> AccIdForCAInsert = new Set<Id>();
    //Boolean variable to control multiple excetion of BeforeUpdate, AfterUpdate - 14 DEC 2020
    public static Boolean isBeforeUpdateTriggerExecuted = false; 
    public static Boolean isAfterUpdateTriggerExecuted = false;
    
    public static void OpportunityBeforeInsert(List<Opportunity> triggerNewList)
    { 
        Set<id> accIds = new set<id>();  
        Id IMERecordTypeId = App_Constants.IME_STD_OPPORTUNITY_RECTYPE_ID;
        Set<Id> AccountIds = new Set<Id>();                  
        for(Opportunity op : triggerNewList) 
        {              
            if(op.US_Federal_GSA_Pricing__c == 'No')
            {
                op.GSA_Eligibility__c = 'Standard Pricing Applies';
            }
            else 
            {
                op.GSA_Eligibility__c = 'GSA Eligible';   
            }          
            accIds.add(op.AccountId);            
            optyOwnerIds.add(op.OwnerId);
            if(op.recordtypeid == IMERecordTypeId)
            {
                AccountIds.add(op.AccountId);
            }     
            op.Global_Chatter__c= true;  
        }   
        //Method to Populate IMGA Owner on the opportunity and Opportunity Owner Information
        populateOpportunityOwner(accIds,triggerNewList);
        if(!AccountIds.isEmpty()){
            //Method to update fields on Opportunity account details
            opportunityAccountUpdate(AccountIds,triggerNewList);
        }
    } 
    
    public static void OpportunityBeforeUpdate(List<Opportunity> triggerNewList,Map<Id,Opportunity> OpportunityOldMap, Map<Id,Opportunity> OpportunityNewMap)
    {
        List<Opportunity> optyList4Update = new List<Opportunity>();
        Set<id> accIds = new set<id>();
        Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> stage5Opp = new Map<Id, Opportunity>(); 
        Id standardRecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID;
        Id IMERecordTypeId = App_Constants.IME_STD_OPPORTUNITY_RECTYPE_ID;
        List<String> opportunityIds = new List<String>();
        Set<Id> recordTypeIds = new Set<Id>();
        //Opps with Contracts
        Set<Id> OppContracts = new Set<Id>();
        List<Contract> contracts = new List<Contract>();
        recordTypeIds.add(IMERecordTypeId);
        recordTypeIds.add(App_Constants.IMAP_STD_OPPORTUNITY_RECTYPE_ID);
        recordTypeIds.add(App_Constants.IMLA_STD_OPPORTUNITY_RECTYPE_ID);
        List<CurrencyType> currencyTpyeList = [select id,IsoCode,ConversionRate from CurrencyType where isActive = true] ;
        Map<String , Decimal> isoWithRateMap = new Map<String, Decimal>();
        for(CurrencyType c : currencyTpyeList)
        {
            isoWithRateMap.put(c.IsoCode , c.ConversionRate) ;
        }
        
        for(Opportunity op : triggerNewList) 
        {       
            // Method in before update to validate at least 1 Opportunity Contact Role on opportunity
            //  when created with stage 3 and beyond
            if(op.RecordTypeId != NULL && op.StageName != NULL && OpportunityOldMap.get(op.Id).StageName != NULL && (op.StageName != 'Lost')){
                if(op.recordtypeid != App_Constants.CPQ_BILLING_OPPORTUNITY_RECTYPE_ID 
                   && App_Constants.OPPORTUNITY_STAGE.contains(op.StageName) 
                   && op.StageName != OpportunityOldMap.get(op.Id).StageName){
                       oppsMap.put(op.Id,op);  
                   }   
            } 
            //Method to filter out the CPQ Sales Opps which has been moved to stage 5 
                        if(op.RecordTypeId != NULL && op.StageName != NULL 
                        && OpportunityOldMap.get(op.Id).StageName != op.StageName 
                        && op.RecordTypeId == App_Constants.CPQ_SALES_OPPORTUNITY_RECTYPE_ID 
                        && op.StageName == '5 - Signed/PO in'){
                        stage5Opp.put(op.Id,op);

                        }

            //Check for the Contract on Opps
            if(op.IME_Contract__c != null){
                OppContracts.add(op.IME_Contract__c);
            } 
            // Cancelling Contract for the lost Opp
            if((OpportunityOldMap.get(op.Id).StageName != op.StageName && op.StageName == 'Lost' && op.IME_Contract__c != null) && (op.recordtypeid == IMERecordTypeId))
            { 
                Contract cont = new Contract();
                cont.Status = 'Cancelled';
                cont.id = op.IME_Contract__c;
                contracts.add(cont);
            }
            if(contracts.size()>0)
            {
                update contracts; 
            }
            accIds.add(op.AccountId);   
            if(op.Ownerid != OpportunityOldMap.get(op.Id).OwnerId)
            {
                optyOwnerIds.add(op.OwnerId);
                OptyList4Update.add(op);
            }
            if((OpportunityOldMap.get(op.Id).US_Federal_GSA_Pricing__c != op.US_Federal_GSA_Pricing__c) || (op.GSA_Eligibility__c == 'GSA Eligible' &&  OpportunityOldMap.get(op.Id).GSA_Eligibility__c != 'GSA Eligible'))
            {
                 if(op.US_Federal_GSA_Pricing__c == 'No')
            {
                op.GSA_Eligibility__c = 'Standard Pricing Applies';
            }
            else 
            {
                op.GSA_Eligibility__c = 'GSA Eligible';   
            }     
                           
            }
            /*if(!oppsMap.isEmpty()){
                //Method to validate the count of Opportunity Contact Role on an Opportunity.
                validateOpportunityStage(oppsMap,OpportunityNewMap);
            }*/
            
            if (op.RecordTypeId == standardRecordTypeId)
            {
                if((OpportunityOldMap.get(op.id).StageName != op.StageName) && op.CurrencyIsoCode == 'USD')
                {
                    if(op.StageName == '2 - Solution Developed'|| op.StageName == '3 - Solution Agreed'||
                       op.StageName == '4 - Negotiate'|| op.StageName == '5 - Signed/PO in')
                    {
                        if(OppPartnerAction.getOppProductAndParnterCount(op.id) == true){ 
                            Op.addError(Label.Cloud_Solution_Product_Line_Label);
                        }
                    }
                }
                else{ 
                    /* Case # 07754082 : Read/write ability For Cloud Solutions Opportunities*/
                    OppPartnerAction.getOppCSProductCount(op); 
                }
                
            }
            else
            {
                /* For other record types with cloud solution product : user try change recordtype from untabbed opportunity*/
                if(op.IsCloudSolutionProductCreated__c == true)
                {
                    op.IsCloudSolutionProductCreated__c = false;
                }
            }
            //setOpptyCompetitorFlag            
            if(recordTypeIds.contains(op.RecordTypeId)){
                opportunityIds.add(op.Id);  
            }   
        } 
        //Method to Populate IMGA Owner on the opportunity and Opportunity Owner Information
        populateOpportunityOwner(accIds,triggerNewList);
        //Method for Global Account Chatter
        globalAccountChatter(triggerNewList);
        if(opportunityIds.size() > 0){
            //Method to Checks if the opportunity in the trigger context has competitors and sets the flag to true
            setOpptyCompetitorFlag(triggerNewList,opportunityIds);
        }
         if(!oppsMap.isEmpty()){
                //Method to validate the count of Opportunity Contact Role on an Opportunity.
                validateOpportunityStage(oppsMap,OpportunityNewMap);
            }
             if(!stage5Opp.isEmpty()){
                //Method to validate the count of approved quotes on stage 5 Opportunity
                validateOpportunityForApprovedQuotes(stage5Opp,OpportunityNewMap);
            } 
        //Method Update SV Status field
        SVStatus.updateSVStatus(triggerNewList,OpportunityOldMap,isoWithRateMap);
        //Method to Check a Contact on Opportunities for IME,IMLA,IMAP and IMNA. 
       // OpportunityValidator.ValidateOCR_OnOppStageChange(OpportunityNewMap,OpportunityOldMap); 
        //Method to IGDS Automated Chatter Post to Chatter Group 
        IGDSAutomatedChatterPost(OpportunityOldMap,triggerNewList,isoWithRateMap);
        if(OppContracts.size()>0){
            //Method to Populating Contracts Name on Opps
            populateContractsNameOnOpps(OppContracts,triggerNewList,OpportunityOldMap);
        }
    }
    
    //Populating Contracts Name on Opps 
    private static void populateContractsNameOnOpps(Set<ID> contractIds ,List<Opportunity> triggerNewList ,Map<Id,Opportunity> OpportunityOldMap ){
        Map<id,contract> contrctDets= new Map<id, contract>([SELECT id, Name from contract where id in:contractIds]);
        for(Opportunity opp : triggerNewList) 
        {
            if(OpportunityOldMap.get(opp.Id).IME_Contract__c != opp.IME_Contract__c && (opp.recordtypeid == App_Constants.IME_STD_OPPORTUNITY_RECTYPE_ID))
            {
                Contract contrt = contrctDets.get(opp.IME_Contract__c);
                opp.Contract_Number__c = contrt.name;
            }           
        }
    }
    //Populate IMGA Owner on the opportunity and Opportunity Owner Information
    public static void populateOpportunityOwner(Set<id> accIds, List<Opportunity> triggerNewList){
        try{
            //Populate IMGA Owner on the opportunity - before insert
            Map<id, Account> imgas = new Map<id, Account>();
            Map<id,User> ownerInfo = new Map<id,User>();
            if(accIds != null && accIds.size() > 0){
                imgas = new Map<id, Account>([select IMGA_Owner__c from Account where Id in :accIds]); 
            }
            //Populate Opportunity Owner Information before insert
            if(!Validator_OpportunityObjectTrigger.hasAlreadyDone()){
                Validator_OpportunityObjectTrigger.setAlreadyDone();
                if ( optyOwnerIds.size() > 0) {
                    //Capture Owner information
                    ownerInfo = new Map<id,User>([SELECT Id, FirstName, LastName, email FROM User WHERE Id in :optyOwnerIds]); 
                }
            }
            for(Opportunity opp : triggerNewList) {
                //Populate IMGA Owner on the opportunity - before insert
                if(!imgas.isEmpty() && imgas.containsKey(opp.AccountId) != null){
                    opp.IMGA_Owner__c = imgas.get(opp.AccountId).IMGA_Owner__c;
                }
                //Populate Opportunity Owner Information before insert
                if(!ownerInfo.isEmpty()){
                    opp.Owner_First_Name__c = ownerInfo.get(opp.OwnerId).FirstName;
                    opp.Owner_Last_Name__c = ownerInfo.get(opp.OwnerId).LastName;
                    opp.Owner_Email__c = ownerInfo.get(opp.OwnerId).email; 
                    opp.Owner_Link__c = opp.OwnerId;
                }
            }
        }catch(Exception e){
            System.debug('[OpportunityHelper.populateOpportunityOwner] [Exception] : ['+e.getMessage()+'] ['+e.getLineNumber()+']');
        }
    }
    public static void OpportunityAfterInsert(List<Opportunity> triggerNewList)
    {
        List<String> Opty_ids = new List<string>();
        List<Id> conNewIds = new List<Id>(); 
        //create new OppTeam Member on Oppprtunity insert.
        List<OpportunityTeamMember> oppTeamInsert = new List<OpportunityTeamMember>();  
        for (Opportunity op: triggerNewList)
        { 
            OppIdForCAInsert.add(op.Id);
            AccIdForCAInsert.add(op.AccountId);
            GSAEligibilityFederal(op);
            if(op.recordtypeid != QTB_Utils.OPP_BILL_RECTYPEID && op.recordtypeid != QTB_Utils.OPP_SALES_RECTYPEID)
            {
                opty_ids.add (op.id);               
            }
            // Check the new Opp for TSU user and record type should not belong to Bill Rec Type &
            // Sales Rec Type
            if(op.tsu__c != null && (op.recordtypeid != QTB_Utils.OPP_BILL_RECTYPEID && op.recordtypeid != QTB_Utils.OPP_SALES_RECTYPEID))
            { 
                OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId = op.Id,UserId = op.tsu__c,TeamMemberRole = App_Constants.Team_MemberROLE_NA_SALES_UNIT);     
                oppTeamInsert.add(otm); 
            }
            //Check Rec Type and Contract
            if(op.RecordTypeId == App_Constants.IME_STD_OPPORTUNITY_RECTYPE_ID ||  
               op.RecordTypeId == App_Constants.IMAP_STD_OPPORTUNITY_RECTYPE_ID ||  
               op.RecordTypeId == App_Constants.IMLA_STD_OPPORTUNITY_RECTYPE_ID )  
            {  
                if(op.IME_Contract__c != Null)  
                {  
                    conNewIds.add(op.IME_Contract__c);  
                }  
            }
        }
        if(opty_ids.size() > 0){
            //// Creating Opportunity sharing
            createOpportunityShare(triggerNewList,opty_ids);
        }
        // extends Edit sharing of incoming opps to the new team member of the Opps
        if(oppTeamInsert.size()>0){
            //Insert Opportunity share
            opportunityShare(oppTeamInsert);
        } 
        if(conNewIds.size()>0){  
            updateContractAmount(conNewIds,triggerNewList);  
        }
        //Validate duplicate Customer Account and create new Customer Account on Insert of New Opps
        createCustAccountOnInsert(triggerNewList);
    }
    
    public static void OpportunityAfterUpdate(Map<Id,Opportunity> OpportunityOldMap, List<Opportunity> triggerNewList)
    {
        List<OpportunityTeamMember> oppTeamUpdate = new List<OpportunityTeamMember>(); 
        List<String> oppTeamDelteStr = new List<String>(); 
        List<String> OpptyIdLst = new List<String>();
        List<Id> contOldIds = new List<string>();  
        List<Id> conNewIds = new List<Id>();
        
        for(Opportunity op : triggerNewList) 
        {
            OppIdForCAInsert.add(op.Id);
            AccIdForCAInsert.add(op.AccountId);
            if(op.GSA_Eligibility__c == 'GSA Eligible' &&  OpportunityOldMap.get(op.Id).GSA_Eligibility__c != 'GSA Eligible')
            {
                GSAEligibilityFederal(op);                
            }
            //IMNA Opportunity Team member Delete
            if (op.recordtypeid != QTB_Utils.OPP_BILL_RECTYPEID && op.recordtypeid != QTB_Utils.OPP_SALES_RECTYPEID)
            {
                if(op.tsu__c != OpportunityOldMap.get(op.Id).tsu__c && OpportunityOldMap.get(op.Id).tsu__c != null && op.tsu__c != null || op.tsu__c != null && OpportunityOldMap.get(op.Id).tsu__c == null)
                {
                    OpportunityTeamMember otmUpdate = new OpportunityTeamMember(OpportunityId = op.Id,UserId = op.tsu__c,TeamMemberRole = 'NA - Tactical Sales Unit');     
                    oppTeamUpdate.add(otmUpdate);  
                }
                if(OpportunityOldMap.get(op.Id).tsu__c != null && op.tsu__c != OpportunityOldMap.get(op.Id).tsu__c && op.tsu__c != null || OpportunityOldMap.get(op.Id).tsu__c != null && op.tsu__c == null)
                {
                    OpptyIdLst.add(op.Id);
                    oppTeamDelteStr.add(OpportunityOldMap.get(op.Id).tsu__c);
                } 
                if(op.RecordTypeId == App_Constants.IME_STD_OPPORTUNITY_RECTYPE_ID ||  
                   op.RecordTypeId == App_Constants.IMAP_STD_OPPORTUNITY_RECTYPE_ID ||  
                   op.RecordTypeId == App_Constants.IMLA_STD_OPPORTUNITY_RECTYPE_ID)  
                {    
                    if(OpportunityOldMap.get(op.Id).IME_Contract__c !=null){
                        contOldIds.add(OpportunityOldMap.get(op.Id).IME_Contract__c);  
                    }
                    if(op.IME_Contract__c!=null){
                        conNewIds.add(op.IME_Contract__c);
                    }  
                }         
            }
        }
        //Validate duplicate Customer Account and 
        // create new customer account on Opportunity update with new customer Id.
        createCustAccountOnUpdate((Map<Id, Opportunity>) OpportunityOldMap, triggerNewList);
        //B2B integration
        B2BIntegration(OpportunityOldMap,triggerNewList); 
        //IMNA Opportunity Team member Delete
        opportunityTeamMemberDelete(OpportunityOldMap,triggerNewList, oppTeamUpdate, oppTeamDelteStr, OpptyIdLst, contOldIds, conNewIds);
        
    }
    
    /*************************************************************************************************
* Method      : validateOpportunityStage
* Purpose     : This method will validate the count of Opportunity Contact Role on an Opportunity.
* Params      : oppsMap an incoming Opportunity, OpportunityNewMap an incoming Trigger.NewMap.
**************************************************************************************************/
    private static void validateOpportunityStage(Map<Id , Opportunity> oppsMap ,Map<Id , Opportunity> OpportunityNewMap){
        for(OPPORTUNITY opty : [SELECT ID ,StageName, (SELECT OpportunityId FROM OpportunityContactRoles WHERE Role != NULL) 
                                FROM OPPORTUNITY
                                WHERE Id =:oppsMap.keySet()]){
                                    if(opty.OpportunityContactRoles.size() == 0 && (!Test.isRunningTest())) {
                                        OpportunityNewMap.get(opty.Id).StageName.addError(Label.OpportunityStage3ErrorForUpdate);
                                    }
                                }
    }
    /*************************************************************************************************
* Method      : validateOpportunityForApprovedQuotes
* Purpose     : This method will validate Opportunity at stage 5 should have approved quotes.
* Params      : oppsMap an incoming Opportunity, OpportunityNewMap an incoming Trigger.NewMap.
**************************************************************************************************/
    private static void validateOpportunityForApprovedQuotes(Map<Id , Opportunity> oppsMap ,Map<Id , Opportunity> OpportunityNewMap){
        for(OPPORTUNITY opty : [SELECT ID ,StageName, (SELECT ID FROM SBQQ__Quotes2__r WHERE SBQQ__Status__c ='Accepted' AND ApprovalStatus__c = 'Approved') 
                                FROM OPPORTUNITY
                                WHERE Id =:oppsMap.keySet()]){
                                    if(opty.SBQQ__Quotes2__r.size() == 0 && (!Test.isRunningTest())) {
                                        OpportunityNewMap.get(opty.Id).StageName.addError(Label.Approved_Quote_Validation_Error);
                                    }
                                }
    }

    
    /**GSA Eligibility based on US Federal/ GSA Pricing Starts- Before insert **/
    Public static void GSAEligibilityFederal(Opportunity op)
    { 
        try{
            if(!Test.isRunningTest()){            
                if (op.GSA_Eligibility__c == 'GSA Eligible') {
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setComments('Submitted for approval. Please approve.');
                    req.setObjectId(op.Id);
                    Approval.ProcessResult result = Approval.process(req);
                }
            }
        }catch(Exception e){
            System.debug('[OpportunityHelper.GSAEligibilityFederal] [Exception] : ['+e.getMessage()+'] ['+e.getLineNumber()+']');
        }
    } 
    //Global Account Chatter - Before update
    public static void globalAccountChatter(List<Opportunity> triggerNewList)
    {
        try{
            Decimal conversionrate;
            Decimal opportunityamount;
            Map<String,Decimal> currencymap = new Map<String,Decimal>();
            List<CurrencyType> currencylist = [SELECT IsoCode,ConversionRate FROM CurrencyType];
            for(CurrencyType c : currencylist)
            {
                currencymap.put(c.IsoCode,c.ConversionRate);
            }
            for(Opportunity op: triggerNewList)
            {
                conversionrate = currencymap.get(op.CurrencyIsoCode);
                if(op.Amount != null)
                {
                    opportunityamount = op.Amount / conversionrate ;
                    if(!(opportunityamount != null && opportunityamount >= 30000))
                    {
                        op.Global_Chatter__c = false;
                    }
                }                
            }
        }catch(Exception e){
            System.debug('[OpportunityHelper.globalAccountChatter] [Exception] : ['+e.getMessage()+'] ['+e.getLineNumber()+']');
        }
    }    
    //Get the recorType value for Standard Opportunity and IME Standard Opportunity
    private static void fillRecordTypeIds()
    { 
        
        Schema.DescribeSObjectResult d = Schema.SObjectType.Opportunity; 
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByDeveloperName();   
        if(rtMapByName.containsKey('Standard_Opportunity')){
            recordTypeIds.add(rtMapByName.get('Standard_Opportunity').getRecordTypeId());  
        }   
        if(rtMapByName.containsKey('IME_Standard_Opportunity')){
            EUrecordTypeIds.add(rtMapByName.get('IME_Standard_Opportunity').getRecordTypeId());  
        }
        
    }
    
    // Creating Opportunity sharing - After insert functionality 
    public static void createOpportunityShare(List<Opportunity> triggerNewList,List<string> opty_ids)
    {
        try{                        
            for (Country_Settings__c c: country_list){
                if(!country.contains(c.Name))
                {
                    country.add(c.Name);
                    country_query += '\''+c.Name+'\',';
                }
                //system.debug('$$$$$$$$$$$$$$country_query:' + country_query);
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
*/
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
*/
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
*/
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
            optyshare_activeuser = new Map<id,user>([select id, isactive from user where id in: optyshare_userid and isactive = true]);
            
            for(OpportunityShare opshare: opty_share)
            {
                system.debug('$$$$$$$$$424$$$$$$$$$$opshare.userorgroupid:'+ opshare.userorgroupid);
                if(optyshare_activeuser.containskey(opshare.userorgroupid)&& opty_owner.get(opshare.OpportunityId) != opshare.userorgroupid)
                    opty_share_insert.add(opshare);
            }
            system.debug('$$$$$$$$$$428$$$$$$$$$$$$total_optyshare:' + opty_share_insert);
            insert Opty_share_insert;
            
        }catch(exception e){
            for (Opportunity op: triggerNewList)
            {  op.adderror('An issue occured in creating sharing rule for Opportunity: '+e.getMessage());
            }       
        }
        // }
        
    }
    
    // after update B2BIntegration
    public static void B2BIntegration(Map<Id,Opportunity> OpportunityOldMap, 
                                      List<Opportunity> triggerNewList)
    {
        try{
            Id IMERecordTypeId = App_Constants.IME_STD_OPPORTUNITY_RECTYPE_ID;
            Id standardRecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID;
            boolean executeBlock=false;
            Set<Id> newOpptyId = new Set<Id>();
            Set<String> customerids = new Set<String>();
            
            //Added on 4/22/13 to handle issues with system update done by sfdc internally 
            if(Validator_OpportunityObjectTrigger.CloseDataOnOpportunity == false)
            {
                for(Opportunity op : triggerNewList){
                    if(op.CloseDate != OpportunityOldMap.get(op.id).CloseDate && (op.RecordTypeId == standardRecordTypeId || op.RecordTypeId == IMERecordTypeId)){
                        Validator_OpportunityObjectTrigger.CloseDataOnOpportunity = true;
                        newOpptyId.add(op.Id);
                        customerids.add(op.IM_Up_Sell_Sold_To__c);
                    }
                }
            }  
            if(!Validator_OpportunityObjectTrigger.hasAlreadyDoneForAfterUpdate() || Validator_OpportunityObjectTrigger.CloseDataOnOpportunity || Test.isRunningTest())
            {
                System.debug('+++++++++ Executing trigger for after update++++++++ ');
                Validator_OpportunityObjectTrigger.setAlreadyDoneForAfterUpdate();
                /* Book to Billing- Web Service Callout Start */
                system.debug('++B2B_Integration.firstRun++'+B2B_Integration.firstRun);    
                if(B2B_Integration.firstRun && (!system.isFuture()) && (!system.isBatch())){
                    system.debug('++B2B_Integration.firstRun++'+B2B_Integration.firstRun);
                    //Set<String> customerids = new Set<String>();
                    Map<String, IM_Customer_Account__c> customeracctMap = new Map<String,IM_Customer_Account__c>();
                    system.debug(' 0001 --InTrigger--Limits.getQueries:--- '+ Limits.getQueries());
                    
                    List<Opportunity> opportunitylist=[ Select Id,Owner.Name,Status__c,IM_Booked_Date__c,Name,Type,StageName,Commissionable_Window_Close_Date__c,
                                                       IMGA_Name__c,First_Bill_Booked_Date__c,Upsell_Customer_ID__c,Upsell_Customer_ID__r.Source_System__c,Customer_Account_Number__c ,IM_Up_Sell_Sold_To__c,RecordTypeId,SKP_Opportunity_Sync_Date__c,
                                                       (Select Id,Customer_ID__c,CaseNumber from Cases1__r where RecordType.Name IN ('NCSP: SKP New Customer Setup','NCSP: DMS'))
                                                       from Opportunity where Id IN : newOpptyId];
   
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
                                &&(OpportunityOldMap.get(op.Id).Type !=op.Type || OpportunityOldMap.get(op.Id).StageName !=op.StageName ||OpportunityOldMap.get(op.Id).Customer_Account_Number__c !=op.Customer_Account_Number__c || OpportunityOldMap.get(op.Id).Upsell_Customer_ID__c !=op.Upsell_Customer_ID__c ||
                                   OpportunityOldMap.get(op.Id).Commissionable_Window_Close_Date__c !=OpportunityOldMap.get(op.Id).Commissionable_Window_Close_Date__c || OpportunityOldMap.get(op.Id).IM_Booked_Date__c !=op.IM_Booked_Date__c || OpportunityOldMap.get(op.Id).Status__c !=op.Status__c ||OpportunityOldMap.get(op.Id).Name !=op.Name || 
                                   OpportunityOldMap.get(op.Id).OwnerId !=op.OwnerId || OpportunityOldMap.get(op.Id).IMGA_Name__c !=op.IMGA_Name__c || OpportunityOldMap.get(op.Id).First_Bill_Booked_Date__c !=op.First_Bill_Booked_Date__c)){
                                       if(!Test.isRunningTest())
                                           B2B_Integration.update_opportunity(op.Id,false);
                                       B2B_Integration.firstRun=false;
                                       system.debug('+++update opportunity++'+ customerId);
                                   }
                    }     
                }
                /* UpdateOppotunityOwnerEmailTrigger (after update ) */ 
                
                Set<Id> newopId = new Set<Id>();
                //Changes made to exclude NA Renewal record type
                
                for(Opportunity o: triggerNewList) {
                    newopId.add(o.Id);
                    if(OpportunityOldMap.get(o.Id).OwnerId != o.OwnerId) {    
                        validUserIdSet.add(o.OwnerId); 
                    }
                }
                
                if(!validUserIdSet.isEmpty()) {
                    List<Opportunity> OpportunitysWithOpportunityCompetitors = [select id, name,OwnerId,Owner.Email,Owner.Sales_Division__c, StageName , (select id, Name,Opportunity_Owner_Email__c from Opportunity_Competitors1__r) from Opportunity where Id IN: newopId];
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
                        if(OpportunityCompetitorsToUpdate.size() > 0){
                            update OpportunityCompetitorsToUpdate;
                        }                        
                    }
                }
                
            }else{
                System.debug('++++ IsUpdate after code not executed++++');
            }
            //}
        }catch(Exception e){
            System.debug('[OpportunityHelper.B2BIntegration] [Exception] : ['+e.getMessage()+'] ['+e.getLineNumber()+']');
        }
    }
    
    /* update fields on Opportunity account details update for case 06462026 - before insert */
    public static void opportunityAccountUpdate(Set<id> AccountIds,List<Opportunity> triggerNewList)
    {   
        try{
            //Added Query Map instead of For loop
            Map<Id,Account> oppAccounts = new Map<Id,Account>([select id,Billingstreet,Billingcity,BillingCountry,BillingState,BillingPostalCode,Name from Account where id in :AccountIds]);                 
            for (opportunity opp : triggerNewList) 
            {
                if(oppAccounts.containsKey(opp.AccountId)){
                    Account accDets  = oppAccounts.get(opp.AccountId);
                   // opp.Company_Number__c = accDets.CDM_Registration_Number__c; 
                    string address = accDets.Billingstreet != null ? accDets.Billingstreet + ' ' : '' ;
                    address+= accDets.Billingcity != null ? accDets.Billingcity + ' ' : '' ;
                    address+= accDets.BillingState != null ? accDets.BillingState + ' ' : '' ;
                    address+= accDets.BillingPostalCode!= null ?accDets.BillingPostalCode+ ' ': '' ;
                    address+= accDets.BillingCountry!= null ?  accDets.BillingCountry : ''  ;      
                    opp.Company_Registered_Address2__c = address;
                    opp.Company_Name__c = accDets.Name;
                }
            }
        }catch(Exception e){
            System.debug('[OpportunityHelper.opportunityAccountUpdate] [Exception] : ['+e.getMessage()+'] ['+e.getLineNumber()+']');
        }
    }
    /* IGDS Automated Chatter Post to Chatter Group -- before update*/
    public static void IGDSAutomatedChatterPost(Map<Id,Opportunity> OpportunityOldMap, 
                                                List<Opportunity> triggerNewList,Map<String , Decimal> isoWithRateMap)
    {
        Id standardRecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID;
        Id IMERecordTypeId = App_Constants.IME_STD_OPPORTUNITY_RECTYPE_ID;
        Decimal convertedAmt;
        
        if(!IGDSOpportunityChtter.IDGSPostChatter())
        {
            for(Opportunity opp : triggerNewList)
            {    
                if(OpportunityOldMap.get(opp.id).StageName != opp.StageName && opp.StageName == '5 - Signed/PO in')
                {
                    convertedAmt = opp.Amount;                    
                    if(opp.CurrencyIsoCode != 'USD' && isoWithRateMap.containsKey(opp.CurrencyIsoCode))
                    {
                        convertedAmt = opp.Amount/isoWithRateMap.get(opp.CurrencyIsoCode);
                    }                    
                    if(opp.RecordTypeId == standardRecordTypeId && convertedAmt >= millionDollar)
                    {                
                        IGDSOpportunityChtter.OppDetails(triggerNewList);
                    }
                    else if(opp.RecordTypeId == IMERecordTypeId && convertedAmt >= millionDollar)
                    {
                        IGDSOpportunityChtter.IMEOppDetails(triggerNewList);
                    }
                }
            }             
        }
    } 
    
    //IMNA Opportunity Team member Delete -After update
    public static void opportunityTeamMemberDelete(Map<Id,Opportunity> OpportunityOldMap,  List<Opportunity> triggerNewList,List<OpportunityTeamMember> oppTeamUpdate,List<String> oppTeamDelteStr, List<String> OpptyIdLst, List<Id> contOldIds, List<Id> conNewIds)
    { 
        List<OpportunityShare> oppShareUpdate = new List<OpportunityShare>();
        List<OpportunityTeamMember> oppTeamDelte = new List<OpportunityTeamMember>();
        if(!contOldIds.isEmpty() || !conNewIds.isEmpty())  
        {  
            updateOpportunityContractAmount(contOldIds,conNewIds,OpportunityOldMap,triggerNewList);  
        }
        if(!oppTeamDelteStr.isEmpty() && !OpptyIdLst.isEmpty()){ 
            oppTeamDelte = [Select Id, UserId, OpportunityId from OpportunityTeamMember WHERE UserId IN: oppTeamDelteStr and OpportunityId IN:OpptyIdLst];
        }        
        if(!oppTeamDelte.isEmpty())
        { 
            delete oppTeamDelte;
        } 
        if(oppTeamUpdate.size()>0)
        {
            opportunityShare(oppTeamUpdate);
        }   
    }
    //Insert Opportunity share
    public static void opportunityShare(List<OpportunityTeamMember> oppTeamList)
    { 
        List<OpportunityShare> oppShare = new List<OpportunityShare>();  
        try 
        {
   
            if (oppTeamList.size() > 0) 
            {  
                Integer insertRecNum = 0; 
                Database.Saveresult[] dbSave1 = Database.insert(oppTeamList, false); 
                for (Database.Saveresult recSave : dbSave1) 
                { 
                    if (recSave.isSuccess())
                    {  
                        oppShare.add( new OpportunityShare(UserOrGroupID = oppTeamList[insertRecNum].UserId,OpportunityId = oppTeamList[insertRecNum].OpportunityId,OpportunityAccessLevel = 'Edit')); 
                    } else {  
                        Database.Error eMsg = recSave.getErrors()[0];  
                    }
                    insertRecNum++;
                }
                Database.Saveresult[] dbShrSave1 = Database.insert(oppShare, false); 
            } 
        }catch(DMLException e){
            System.debug('Something fatal has occurred and hence failed to create a Log! Error:' + e.getMessage());
            System.debug('[OpportunityHelper.opportunityShare] [Exception] : ['+e.getMessage()+'] ['+e.getLineNumber()+']');
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'OpportunityHelper');
        }
    }
    /*
* Method : createCustAccountOnInsert(List<opportunity> newList)
* Description : Creates customer account if the client code is added in the opportunity during Opportunity Insert
* Added By : arajendran (BCT)
* Executes : After Insert
* Work Id : W-000147
*/ 
    public static void createCustAccountOnInsert(List<opportunity> newList)
    {
        if(triggerFlowControl.triggerRunCount('OpportunityCustAcctTrg') > 1 )
            return; //Make sure that this doesn't get run twice in the same transaction
        
        // Call createCustAccount method with insert params
        system.debug('ECAOI - Entering CreateCust Account on Insert');
        map<Id, Opportunity> emptyMap = new Map<Id, Opportunity>();
        createCustomerAccount(true,false,emptyMap, newList);
    }/*
* Method : createCustAccountOnUpdate(Map<Id, Opportunity> oldItems, List<Opportunity> newlist)
* Description : Creates customer account if the client code is added in the opportunity during Opportunity Update
* Added By : arajendran (BCT)
* Executes : After Update
* Work Id : W-000147
*/ 
    public static void createCustAccountOnUpdate(Map<Id, Opportunity> oldItems, List<Opportunity> newlist)
    {
        if(triggerFlowControl.triggerRunCount('OpportunityCustAcctTrg') > 1 )
            return; //Make sure that this doesn't get run twice in the same transaction
        // Call createCustAccount method with update params
        system.debug('ECAOU - Entering CreateCust Account on Update');
        //createCustomerAccount(false, true, oldItems, newlist);
    }
    
    /**
* Method : createCustomerAccount
* Added by : Arajendran (BCT)
* Method Description : Its a common method for both After Insert and After update dml operations.
* Validates the input data for insert or update and filters the conditions for creating new customer accounts.
* For insert operation, creates the customer account
* For Update , validates the condition if the customer account was null and creates a new customer account.
* This method also creates the customer account for contracts 
* Executes : After insert , After Update
* Work Id : W-000147
*/
    public static void createCustomerAccount(boolean isInsert, boolean isUpdate, Map<Id, Opportunity> oldMap, List<Opportunity> newList){
        
        Map<String,String> opportunityProduct = new map<String,String>();
        Set<Id> opportunityIds = new Set<Id>();
        List<String> clientCodes = new List<String>();
        Map<String, String> euCountryCodes = new Map<String,String>();
        Map<String,IM_Customer_Account__c> dupClientAccounts = new Map<String,IM_Customer_Account__c>();
        //List<String> custOpportunies = new List<String>();
        Set<ID> oppCountryCodes = new Set<ID>();
        Set<ID> recordTypeIDs = new Set<ID>{App_Constants.IME_STD_OPPORTUNITY_RECTYPE_ID,
            App_Constants.IMAP_STD_OPPORTUNITY_RECTYPE_ID,
            App_Constants.IMLA_STD_OPPORTUNITY_RECTYPE_ID};
               
                //Condition to check if any of the record types contains record types that are belong to IME IMAP IMLA
                // if(optyRecMap.containsKey(recTypeIME) || optyRecMap.containsKey(recTypeIMAP) || optyRecMap.containsKey(recTypeIMLA))
                // {
                //Load the Opportunity ID List to use in subsequent queries
                for(Opportunity opptyRec : newlist){
                    // 2011-02-07   As part of the changes outlined above, check if the record type
                    //              of the opportunity is one of the types we added above
                    //Check for record type ids that belongs to any of the three record types for each opportunity record.
                    if(recordTypeIDs.contains(opptyRec.RecordTypeId))
                        opportunityIds.add(opptyRec.id);
                    
                    if(opptyRec.Customer_Account_Number__c != null )
                        clientCodes.add(opptyRec.Customer_Account_Number__c);
                    
                    if(opptyRec.Billing_Country__c != null )
                        oppCountryCodes.add(opptyRec.Billing_Country__c);
                }
        // Opportunity Line Item List for the incoming Opportunities
        List<OpportunityLineItem> opptylneitmLst = [Select o.PricebookEntry.Product2.IM_Product_Class__c,o.PricebookEntryId,o.OpportunityId 
                                                    FROM OpportunityLineItem o 
                                                    WHERE o.OpportunityId in :opportunityIds];
        // Customer Account list for the incoming Opps
        List<IM_Customer_Account__c> custAccntLst = [select id, IM_Opportunity__c
                                                     FROM IM_Customer_Account__c 
                                                     WHERE IM_Opportunity__c in :opportunityIds];
        
        //Get the opportunity line items
        for( OpportunityLineItem oli : opptylneitmLst) 
        {                               
            opportunityProduct.put(oli.OpportunityId,oli.PricebookEntry.Product2.IM_Product_Class__c);
        }                                 
        
        //Load the customerAccount map limiting on the opportunityIds list
        Map<id,IM_Customer_Account__c> existingCustAcct = new Map<id,IM_Customer_Account__c>();
        try
        {  
            for(IM_Customer_Account__c ca  : custAccntLst)
            {
                existingCustAcct.put(ca.IM_Opportunity__c,ca);
            } 
        }
        catch(Exception e){//do nothing
        }
        List<IM_Country__c> countLst = [Select p.Iso31663Code__c,p.Region__c,p.Name,p.Id 
                                        FROM IM_Country__c p 
                                        WHERE Region__c = 'Europe' or Region__c = 'Asia Pacific' or Region__c = 'Latin America'];
        for(IM_Country__c cc : countLst)
        {
            euCountryCodes.put(cc.Id, cc.Iso31663Code__c);
        }
        
        List<IM_Customer_Account__c> custAccLst = [select id, name, Billing_Country__c
                                                   FROM IM_Customer_Account__c 
                                                   WHERE name in :clientCodes AND Billing_Country__c in :oppCountryCodes];
        
        //Map to check for the duplicate custome account for the same billing count and account
        for (IM_Customer_Account__c ca : custAccLst)
        {
            dupClientAccounts.put( ca.Billing_Country__c+ca.name, ca );
        }
        
        for (IM_Customer_Account__c ca : custAccLst)
        {
            dupClientAccounts.put( ca.Billing_Country__c+ca.name, ca );
        }
        
        //Instantiate a list of CUstomer Accounts for insert
        List<IM_Customer_Account__c> newCustAcct = new List<IM_Customer_Account__c>(); 
        
        //Loop through the Trigger.new filtering down to Opportunities that need a Customer account.
        for(Opportunity opptyRec : newlist){
            //filter for existance of country relationship, New, Customer Account Number, and EU Record Type
            if((euCountryCodes.get(opptyRec.Billing_Country__c) != null) 
               && opptyRec.Customer_Account_Number__c != null 
               &&(isInsert || (isUpdate && oldMap.get(opptyRec.id).Customer_Account_Number__c == null))
               && recordTypeIDs.contains(opptyRec.RecordTypeId)
              ){
                  //system.debug('***Exist acct--'+existingCustAcct.get(opptyRec.id));
                  if (existingCustAcct.get(opptyRec.id) == null) 
                  {
                      // Only if a customer account does not exist for this oppty
                      // Check for duplicates – country code + Client Code
                      // If there is a duplicate, add an error to the 
                      // Opportunity.Client_Code__c field sourced from a label.
                      
                      if(dupClientAccounts.get(opptyRec.Billing_Country__c + opptyRec.Customer_Account_Number__c)!=null){  
                          //Error if there is a duplicate client code (Cutsomer_Account_Number)
                          //For US #16327 Removing if else condition and allowing duplicate customer IDs opptyRec.Customer_Account_Number__c.addError(Label.CustomerAccountCreateErr);
                      }
                      else {
                          //Instiantiate the Customer account and add it to the list
                          IM_Customer_Account__c ca = 
                              new IM_Customer_Account__c                                                                                                     
                              (name = opptyRec.Customer_Account_Number__c
                               ,IM_Account__c = opptyRec.AccountId
                               ,IM_Opportunity__c = opptyRec.Id
                               //,IM_Product_Class__c = opportunityProduct.get(opptyRec.Id)
                               ,Source_System__c  = opptyRec.Source_System__c 
                               ,IM_Status__c = 'New'
                               ,Billing_Country__c = opptyRec.Billing_Country__c
                              );
                          if(opportunityProduct.containsKey(opptyRec.Id))
                              ca.IM_Product_Class__c = opportunityProduct.get(opptyRec.Id);  
                          newCustAcct.add(ca);
                          //custOpportunies.add(opptyRec.Id);                            
                      }
                  }
              }
        }   
        // Code added by Pratap
        // Insert Customer account for contract by taking CustId and contract id from opportunity
        if(newCustAcct.size() > 0)
        {
            try{
                //Create Customer Account
                insert newCustAcct;
            }
            Catch(Exception e){
                System.debug('Something fatal has occurred during Customer Account Creation' + e.getMessage());
                ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'OpportunityHelper');
            }
            try
            {
                map<string,IM_Customer_Account__c> customerAccounts = new map<string,IM_Customer_Account__c>();
                List<Contract_Customer_Account__c> cas = new List<Contract_Customer_Account__c>();
                
                list<IM_Customer_Account__c> caList = [select id, IM_Opportunity__c, IM_Account__c 
                                                       FROM IM_Customer_Account__c 
                                                       WHERE IM_Opportunity__c IN: OppIdForCAInsert AND IM_Account__c IN: AccIdForCAInsert ];
                
                for(IM_Customer_Account__c i : caList){
                    String s = i.IM_Opportunity__c+''+i.IM_Account__c;
                    customerAccounts.put(s, i);
                }
                for(Opportunity opptyRec : newlist){
                    String s = opptyRec.id+''+opptyRec.AccountId;
                    if(customerAccounts.containsKey(s)){
                        IM_Customer_Account__c icac = customerAccounts.get(s);
                        Contract_Customer_Account__c Relatedca = new Contract_Customer_Account__c();                  
                        Relatedca.IME_Customer_Accounts_Id__c = icac.id;
                        Relatedca.IME_Contract_Id__c = opptyRec.IME_Contract__c;
                        cas.add(Relatedca);
                    }
                }
                system.debug('Contract Customer Accounts added : ' + cas);
                
                if(cas.size() > 0){ 
                    insert cas;
                }
                else{
                    System.debug('There are no customer accounts for contract');
                }
            }Catch(Exception e){
                System.debug('Something fatal has occurred during Customer Account Creation for Contract' + e.getMessage());
                ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'OpportunityHelper');
            }
        }
        // }//End IF
    }//End Method
    
    /*
* Method : setOpptyCompetitorFlag(List<opportunity> newList)
* Description : Checks if the opportunity in the trigger context has competitors and sets the flag to true in before update
* Added By : arajendran (BCT)
* Work Id : W-000333
* Executes : before Update
*/ 
    
    public static void setOpptyCompetitorFlag(List<Opportunity> newList, List<String> opportunityIds){
        try{
            set<Id> opp_Ids_that_needs_true=new Set<Id>();
            //Gopi Change to Query for loop
            //List<OpportunityCompetitor> opp_with_com=[select id,opportunityId from opportunityCompetitor where opportunityId in :opportunityIds and isDeleted = false];
            for(OpportunityCompetitor optyCompRec: [select id,opportunityId from opportunityCompetitor where opportunityId in :opportunityIds and isDeleted = false]){
                opp_Ids_that_needs_true.add(optyCompRec.opportunityId);
            }
            if(opp_Ids_that_needs_true.size() > 0){
                for(Opportunity opptyRec : newList){
                    if(!opp_Ids_that_needs_true.contains(opptyRec.Id)){
                        opptyRec.IM_Has_Competitors__c=false;
                    }
                    else if(opptyRec.IM_Has_Competitors__c==false){
                        opptyRec.IM_Has_Competitors__c=true;
                    }
                }
            }                
        }catch(Exception e){
            System.debug('[OpportunityHelper.setOpptyCompetitorFlag] [Exception] : ['+e.getMessage()+'] ['+e.getLineNumber()+']');
        }
    }//End Method setOpptyCompetitorFlag
    
    // When the Opportunity record deleted related Contract record Annual Value (Opportunities) value will be update  
    // Added by :Revathy Saminathan  
    // Company  : BCT  
    public static void deleteOpportunityRelatedContractAmount(List<Opportunity> triggerOldList)  
    {   
        List<Contract> conlist =new List<Contract>();   
        List<Contract> objConOldList = new List<Contract>();   
        
        try{   
            for(Opportunity op : triggerOldList)  
            {  
                // filtering record types to avoid the SOQL 101 Exception:Added by Venkat - 14/10/2014  
                if(op.RecordTypeId == App_Constants.IME_STD_OPPORTUNITY_RECTYPE_ID  
                   || op.RecordTypeId == App_Constants.IMAP_STD_OPPORTUNITY_RECTYPE_ID  
                   || op.RecordTypeId == App_Constants.IMLA_STD_OPPORTUNITY_RECTYPE_ID)   
                {  
                    contOldIds.add(op.IME_Contract__c);   
                    contractOldMap.put(op.IME_Contract__c, op.Amount);  
                }  
            }  
            if(!contOldIds.isEmpty())  
            {  
                conlist = [Select Id, IME_Annual_Value_Opportunities__c from Contract where Id IN: contOldIds   
                           and (Recordtype.DeveloperName =:App_constants.IME_PARENTCONTRCT_DEVELOPERNAME or Recordtype.DeveloperName =:App_constants.IME_CHILDCONTRACT_DEVELOPERNAME or Recordtype.DeveloperName =:App_constants.IME_ADDENDUMEXTENSION_DEVELOPENAME) LIMIT 10000]; // [RI - 08/14/14] added LIMIT  
            }  
            if(!conlist.isEmpty())  
            {  
                for(Contract contOld: conlist)  
                {  
                    if(contOld.IME_Annual_Value_Opportunities__c != null)  
                    {  
                        Contract objConOld = new Contract();  
                        objConOld.Id = contOld.Id;  
                        objConOld.IME_Annual_Value_Opportunities__c = contOld.IME_Annual_Value_Opportunities__c - contractOldMap.get(contOld.Id);  
                        objConOldList.add(objConOld);  
                    }  
                }  
            }  
            if(!objConOldList.isEmpty())  
            {                 
                Update objConOldList;  
            }  
        }catch(Exception e){  
            System.debug('Something fatal has occurred during Customer Account Creation' + e.getMessage());  
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'OpportunityHelper');  
        }  
    }  
    // Opportunity related contract, Annual_Value_Opportunities field will update based on the opportunity total amount while insert the record  
    // Added by :Revathy Saminathan   
    // Company : BCT  
    Public static void updateContractAmount(List<Id> conNewIds,List<Opportunity> triggerNewList)  
    {     
        List<CurrencyType> currenLst = new List<CurrencyType>();     
        Map<String, Double> currenMap = new Map<String, Double>();   
        List<aggregateResult> results = new List<aggregateResult>();   
        Map<String, Double> contractNewMap = new Map<String, Double>();  
        List<Contract> conLst = new List<Contract>();    
        List<Contract> objConNewList = new List<Contract>();   
        try{  
            currenLst = [Select Id, ConversionRate, ISOCode  from CurrencyType];  
            for(CurrencyType objCurren: currenLst)  
            {  
                currenMap.put(objCurren.ISOCode , objCurren.ConversionRate);   
            }  
            if(conNewIds.size() > 0)  
            {  
                results = [select IME_Contract__c cntrcId, Sum(Amount) Total from Opportunity where   
                           IME_Contract__c IN: conNewIds and OwnerId!='' group by IME_Contract__c LIMIT 10000]; // [RI - 08/14/14] added LIMIT  
            }   
            if(results.size()>0)  
            {  
                for(aggregateResult aR : results)  
                {  
                    contractNewMap.put(String.ValueOf(aR.get('cntrcId')),Double.valueOf(aR.get('Total')));   
                }   
            }  
            if(conNewIds.size() > 0)  
            {  
                conLst = [Select Id,CurrencyIsoCode, IME_Annual_Value_Opportunities__c from Contract where Id IN:conNewIds   
                          and (Recordtype.DeveloperName =:App_constants.IME_PARENTCONTRCT_DEVELOPERNAME or Recordtype.DeveloperName =:App_constants.IME_CHILDCONTRACT_DEVELOPERNAME or Recordtype.DeveloperName =:App_constants.IME_ADDENDUMEXTENSION_DEVELOPENAME) LIMIT 10000]; // [RI - 08/14/14] added LIMIT  
            }    
            for(Opportunity op : triggerNewList)  
            {  
                if(!conLst.isEmpty())  
                {  
                    for(Contract conObj: conLst)  
                    {   
                        Contract obCon = new Contract();  
                        obCon.Id = conObj.Id;  
                        if(contractNewMap.get(conObj.Id) != null)  
                        {    
                            obCon.IME_Annual_Value_Opportunities__c = contractNewMap.get(conObj.Id)*currenMap.get(conObj.CurrencyIsoCode);  
                        }  
                        objConNewList.add(obCon);  
                    }  
                }  
            }  
            if(!objConNewList.isEmpty())  
            {  
                update objConNewList;  
            }  
        }catch(Exception e){  
            System.debug('Something fatal has occurred during Customer Account Creation' + e.getMessage());
            System.debug('[OpportunityHelper.updateContractAmount] [Exception] : ['+e.getMessage()+'] ['+e.getLineNumber()+']');
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'OpportunityHelper');  
        }  
    }  
    // Opportunity related contract, Annual_Value_Opportunities field will update based on the opportunity total amount while update the record  
    // Added by :Revathy Saminathan   
    // Company : BCT  
    public static void updateOpportunityContractAmount(List<Id> contOldIds,List<Id> conNewIds,  
                                                       Map<Id,Opportunity> OpportunityOldMap,List<Opportunity> triggerNewList)  
    {  
        List<Contract> conlist= new List<Contract>();  
        Map<Id, Double> conOldMap = new Map<Id, Double>();   
        Map<Id, String> conrCodeOldMap = new Map<Id, String>();   
        List<aggregateResult> results = new List<aggregateResult>();  
        Map<String, Double> contractNewMap = new Map<String, Double>();  
        List<Contract> conLst = new List<Contract>();   
        List<CurrencyType> currenLst = new List<CurrencyType>();    
        Map<String, Double> currenMap = new Map<String, Double>();   
        Map<String, Double> conNewMap = new Map<String, Double>();   
        Map<Id, Id> contractIdNewMap = new Map<Id, Id>();   
        Map<Id, String> conrCodeNewMap = new Map<Id, String>();   
        List<Contract> objConNewList = new List<Contract>();  
        currenLst = [Select Id, ConversionRate, ISOCode  from CurrencyType];    
        List<Contract> objConNewListNew = new List<Contract>();  
        Double dCurrency;  
        Double dCurrencyOld;  
        
        for(CurrencyType objCurren: currenLst)  
        {  
            currenMap.put(objCurren.ISOCode , objCurren.ConversionRate);   
        }  
        if(conNewIds.size() > 0)  
        {  
  
            results = [select IME_Contract__c cntrcId, Sum(Amount) Total from Opportunity where     
                       IME_Contract__c IN: conNewIds and OwnerId!='' group by IME_Contract__c LIMIT 10000]; // [RI - 08/14/14] added LIMIT   
        }   
        if(results.size()>0)  
        {  
            for(aggregateResult aR : results)  
            {  
                contractNewMap.put(String.ValueOf(aR.get('cntrcId')),Double.valueOf(aR.get('Total')));   
            }    
        } 
        if(conNewIds.size() > 0)  
        {  
            conLst = [Select Id,CurrencyIsoCode, IME_Annual_Value_Opportunities__c from Contract where Id IN:conNewIds   
                      and (Recordtype.DeveloperName =:App_constants.IME_PARENTCONTRCT_DEVELOPERNAME or Recordtype.DeveloperName =:App_constants.IME_CHILDCONTRACT_DEVELOPERNAME or Recordtype.DeveloperName =:App_constants.IME_ADDENDUMEXTENSION_DEVELOPENAME) LIMIT 10000]; // [RI - 08/14/14] added LIMIT  
        }   
        if(!conLst.isEmpty())  
        {  
            for(Contract conOb: conLst)  
            {  
                conNewMap.put(conOb.Id,conOb.IME_Annual_Value_Opportunities__c);   
                conrCodeNewMap.put(conOb.Id,conOb.CurrencyIsoCode);  
            }  
        }  
        if(!contOldIds.isEmpty())  
        {  
            conlist = [Select Id,CurrencyIsoCode, IME_Annual_Value_Opportunities__c from Contract   
                       where Id IN: contOldIds and (Recordtype.DeveloperName =:App_constants.IME_PARENTCONTRCT_DEVELOPERNAME or Recordtype.DeveloperName =:App_constants.IME_CHILDCONTRACT_DEVELOPERNAME or Recordtype.DeveloperName =:App_constants.IME_ADDENDUMEXTENSION_DEVELOPENAME) LIMIT 10000]; // [RI - 08/14/14] added LIMIT  
        }  
        if(!conlist.isEmpty())  
        {  
            for(Contract conOldObj:conlist)  
            {  
                conOldMap.put(conOldObj.Id, conOldObj.IME_Annual_Value_Opportunities__c);  
                conrCodeOldMap.put(conOldObj.Id,conOldObj.CurrencyIsoCode);  
            }  
        }  
        try{  
            for(Opportunity op : triggerNewList)  
            {       //only change in opportunity amount and no change in contract while Opportunity udpate.  
                if(OpportunityOldMap.get(op.Id).IME_Contract__c == op.IME_Contract__c && OpportunityOldMap.get(op.Id).Amount != op.Amount)  
                {  
                    if(!conLst.isEmpty())  
                    {  
                        for(Contract conObj: conLst)  
                        {      
                            Contract obCon = new Contract();  
                            obCon.Id = conObj.Id;  
                            obCon.IME_Annual_Value_Opportunities__c = contractNewMap.get(op.IME_Contract__c)*currenMap.get(conObj.CurrencyIsoCode);   
                            objConNewList.add(obCon);  
                        }  
                    }  
                }  
                //added new Contract while opportunity update  
                else if(OpportunityOldMap.get(op.Id).IME_Contract__c == Null && op.IME_Contract__c !=null)  
                {  
                    if(!conLst.isEmpty())  
                    {  
                        for(Contract conObj: conLst)  
                        {     
                            Contract obCon = new Contract();  
                            obCon.Id = conObj.Id;  
                            if(contractNewMap.get(op.IME_Contract__c) != null)  
                            {   
                                obCon.IME_Annual_Value_Opportunities__c = contractNewMap.get(op.IME_Contract__c)*currenMap.get(conObj.CurrencyIsoCode);   
                            }   
                            objConNewList.add(obCon);  
                        }  
                    }  
                }  
                //removed old contract while opportunity update  
                else if(OpportunityOldMap.get(op.Id).IME_Contract__c != null && op.IME_Contract__c ==null)  
                {  
                    if(!conlist.isEmpty())  
                    {   
                        for(Contract conObj: conlist )  
                        {     
                            Contract obCon = new Contract();  
                            obCon.Id = conObj.Id;  
                            if(conObj.IME_Annual_Value_Opportunities__c != null)  
                            {   
                                if(UserInfo.getDefaultCurrency() == OpportunityOldMap.get(op.Id).CurrencyIsoCode)  
                                {   
                                    obCon.Id = OpportunityOldMap.get(op.Id).IME_Contract__c;  
                                    dCurrency =  Math.roundToLong(conOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c) - OpportunityOldMap.get(op.Id).Amount);  
                                    obCon.IME_Annual_Value_Opportunities__c =dCurrency;  
                                    objConNewListNew.add(obCon);  
                                }  
                                else if(OpportunityOldMap.get(op.Id).CurrencyIsoCode != conrCodeNewMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c))  
                                {   
                                    obCon.Id = OpportunityOldMap.get(op.Id).IME_Contract__c;  
                                    decimal ContractAmount,OpptAmount;   
                                    // Convert contract & Opp amount into USD   
                                    if(conrCodeOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c) != 'USD')  
                                    {  
                                        ContractAmount = (1/currenMap.get(conrCodeOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c)) * conOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c));  
                                    }  
                                    else {  
                                        ContractAmount = conOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c);  
                                    }  
                                    
                                    if(OpportunityOldMap.get(op.Id).CurrencyIsoCode!= 'USD'){  
                                        OpptAmount = (1/currenMap.get(OpportunityOldMap.get(op.Id).CurrencyIsoCode) * OpportunityOldMap.get(op.Id).Amount);  
                                    }  
                                    else  
                                    {  
                                        OpptAmount = OpportunityOldMap.get(op.Id).Amount;  
                                    }  
                                    dCurrency = ContractAmount > OpptAmount ? ContractAmount - OpptAmount : OpptAmount - ContractAmount;   
                                    obCon.IME_Annual_Value_Opportunities__c = conObj.CurrencyIsoCode!= 'USD' ? dCurrency * currenMap.get(conObj.CurrencyIsoCode) :dCurrency;  
                                    objConNewListNew.add(obCon);  
                                }     
                                else  
                                {   
                                    obCon.Id = OpportunityOldMap.get(op.Id).IME_Contract__c;  
                                    
                                    decimal ContractAmount,OpptAmount;   
                                    // Convert contract & Opp amount into USD   
                                    if(conrCodeOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c) != 'USD')  
                                    {  
                                        ContractAmount = (1/currenMap.get(conrCodeOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c)) * conOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c));  
                                    }  
                                    else {  
                                        ContractAmount = conOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c);  
                                    }  
                                    
                                    if(OpportunityOldMap.get(op.Id).CurrencyIsoCode!= 'USD'){  
                                        OpptAmount = (1/currenMap.get(OpportunityOldMap.get(op.Id).CurrencyIsoCode) * OpportunityOldMap.get(op.Id).Amount);  
                                    }  
                                    else  
                                    {  
                                        OpptAmount = OpportunityOldMap.get(op.Id).Amount;  
                                    }  
                                    dCurrency = ContractAmount > OpptAmount ? ContractAmount - OpptAmount : OpptAmount - ContractAmount;   
                                    obCon.IME_Annual_Value_Opportunities__c = conObj.CurrencyIsoCode!= 'USD' ? dCurrency * currenMap.get(conObj.CurrencyIsoCode) :dCurrency;  
                                    objConNewListNew.add(obCon);  
                                }         
                            }  
                            objConNewList.add(obCon);  
                        }  
                    }  
                }  
                //Modified Existing Contract while update  
                else if(OpportunityOldMap.get(op.Id).IME_Contract__c != null && op.IME_Contract__c !=null && op.IME_Contract__c != OpportunityOldMap.get(op.Id).IME_Contract__c)  
                {  
                    Contract obCon = new Contract();  
                    try  
                    {   
                        if(conOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c) != null)  
                        {   
                            if(UserInfo.getDefaultCurrency() == OpportunityOldMap.get(op.Id).CurrencyIsoCode)  
                            {   
                                obCon.Id = OpportunityOldMap.get(op.Id).IME_Contract__c;  
                                dCurrency =  Math.roundToLong(conOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c) - OpportunityOldMap.get(op.Id).Amount);  
                                if (dCurrency < 0){  
                                    dCurrency = 0;  
                                }  
                                obCon.IME_Annual_Value_Opportunities__c =dCurrency;  
                                objConNewListNew.add(obCon);  
                            }  
                            else if(OpportunityOldMap.get(op.Id).CurrencyIsoCode != conrCodeNewMap.get(op.IME_Contract__c))  
                            {   
                                if(OpportunityOldMap.get(op.Id).CurrencyIsoCode != 'HUF')  
                                {  
                                    obCon.Id = OpportunityOldMap.get(op.Id).IME_Contract__c;  
                                    dCurrency =  Math.roundToLong((conOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c)) -   
                                                                  (OpportunityOldMap.get(op.Id).Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(OpportunityOldMap.get(op.Id).CurrencyIsoCode))));  
                                    if (dCurrency < 0){  
                                        dCurrency = 0;  
                                    }  
                                    obCon.IME_Annual_Value_Opportunities__c =dCurrency;  
                                    objConNewListNew.add(obCon);  
                                }  
                                else  
                                {   
                                    obCon.Id = OpportunityOldMap.get(op.Id).IME_Contract__c;  
                                    dCurrency =  Math.roundToLong((conOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c)) -   
                                                                  (OpportunityOldMap.get(op.Id).Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(OpportunityOldMap.get(op.Id).CurrencyIsoCode))));  
                                    if (dCurrency < 0){  
                                        dCurrency = 0;  
                                    }  
                                    obCon.IME_Annual_Value_Opportunities__c =dCurrency;  
                                    objConNewListNew.add(obCon);  
                                }  
                            }     
                            else  
                            {   
                                obCon.Id = OpportunityOldMap.get(op.Id).IME_Contract__c;  
                                dCurrency =  Math.roundToLong(conOldMap.get(OpportunityOldMap.get(op.Id).IME_Contract__c) -   
                                                              (OpportunityOldMap.get(op.Id).Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(OpportunityOldMap.get(op.Id).CurrencyIsoCode))));  
                                if (dCurrency < 0){  
                                    dCurrency = 0;  
                                }  
                                obCon.IME_Annual_Value_Opportunities__c =dCurrency;  
                                objConNewListNew.add(obCon);  
                            }         
                        }  
                        update objConNewListNew;  
                    }  
                    catch (DMLException e)  
                    {   
                        System.debug('Something fatal has occurred during Customer Account Creation' + e.getMessage());  
                        ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'OpportunityHelper');  
                    }  
                    
                    if(conNewMap.get(op.IME_Contract__c) != null && op.IME_Contract__c !=null && op.IME_Contract__c != OpportunityOldMap.get(op.Id).IME_Contract__c)  
                    {   
                        if(UserInfo.getDefaultCurrency() == OpportunityOldMap.get(op.Id).CurrencyIsoCode)  
                        {  
                            obCon.Id = op.IME_Contract__c;  
                            obCon.IME_Annual_Value_Opportunities__c = Math.roundToLong((conNewMap.get(op.IME_Contract__c))+op.Amount);//*currenMap.get(conObj.CurrencyIsoCode));  
                        }  
                        else if(OpportunityOldMap.get(op.Id).CurrencyIsoCode == conrCodeNewMap.get(op.IME_Contract__c))  
                        {  
                            obCon.Id = op.IME_Contract__c;  
                            obCon.IME_Annual_Value_Opportunities__c = Math.roundToLong((conNewMap.get(op.IME_Contract__c))+op.Amount);  
                        }  
                        else   
                        {  
                            obCon.Id = op.IME_Contract__c;  
                            obCon.IME_Annual_Value_Opportunities__c = Math.roundToLong((conNewMap.get(op.IME_Contract__c))+(op.Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(OpportunityOldMap.get(op.Id).CurrencyIsoCode))));  
                        }  
                        
                    }  
                    else if(conNewMap.get(op.IME_Contract__c) == null && op.IME_Contract__c !=null && op.IME_Contract__c != OpportunityOldMap.get(op.Id).IME_Contract__c)  
                    {  
                        system.debug('adding new contract second time');  
                        if(UserInfo.getDefaultCurrency() == OpportunityOldMap.get(op.Id).CurrencyIsoCode)  
                        {  
                            obCon.Id = op.IME_Contract__c;  
                            obCon.IME_Annual_Value_Opportunities__c = op.Amount;  
                        }  
                        else  
                        {  
                            obCon.Id = op.IME_Contract__c;  
                            obCon.IME_Annual_Value_Opportunities__c = Math.roundToLong(op.Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(OpportunityOldMap.get(op.Id).CurrencyIsoCode)));  
                        }  
                    }  
                    objConNewList.add(obCon);  
                }  
            }   
            if(!objConNewList.isEmpty())  
            {  
                update objConNewList;  
            }  
        }  
        catch(Exception e){  
            System.debug('Something fatal has occurred during Customer Account Creation. updateOpportunityContractAmount()'); 
            System.debug('[OpportunityHelper.updateOpportunityContractAmount] [Exception] : ['+e.getMessage()+'] ['+e.getLineNumber()+']');
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'OpportunityHelper');  
        }  
    } 
    
}
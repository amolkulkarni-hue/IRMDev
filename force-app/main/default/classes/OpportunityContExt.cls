public class OpportunityContExt {
    public string profileImageUrl    { get; set; }
    public Opportunity op {get;set;}
    public  List<Opportunity> optylist {get;set;}
    public SFDC_Acct_Plan__c accountPlan {get; private set;}
    public final static Set<String> WINSTAGES = new Set<String>{'5 - Signed/PO in', '6 - Setup', '7 - Closed'};
    public final static Set<String> WINLOSS_STAGES = new Set<String>{'6 - Setup', '7 - Closed' , 'Lost', 'Dead', 'Postponed'};
    public final static Set<String> LOSS_STAGES = new Set<String>{'Lost', 'Dead', 'Postponed'};
    public static Set<String> STAGE_FIVE { get { return new Set<String>{'5 - Signed/PO in' };} private set;}
    public final static Set <String> ACCOUNT_PLAN_RECORD_TYPE_DEVELOPER_NAMES = new Set<String>{'Global_Sales_Account_Plan', 'IMNA_Account_Plan'};
    
    public static Set<String> SOLUTION_SUB_TYPES = new Set<String>{'Sales Coach', 'Upsell',
                                                                  'Pricing & Quotes', 'Win Plan',
                                                                  'Competitive Intelligence', 'Marketing Influence',
                                                                  'Requested References', 'Sales Support',
                                                                  'NCSP','DMS Detail','Win/Loss Analysis',
                                                                  'Opportunity Answers','System Information'};

    public static final String CLOSED_LOST_ERROR_MESSAGE = 'Please fill in a Reason Lost';
    public static final String CLOSED_LOST_ERROR_MESSAGE_2 = 'Please provide more detail as to why this opportunity was lost.';
    public static final String UPSELL_ERROR_MESSAGE = 'If Type is Up-Sell';
    public static final String NCSP_SENT_STATUS = 'Sent to NCSP';
    public static final String COMPLETED = 'Completed';  
    public static String ESCALATED { get { return 'Escalated'; } private set;}

    public static String SCHEDULE_A_TAB { get { return 'scheduleA'; } private set;}
    public static String WIN_LOSS_ANALYSIS_TAB { get { return 'winLossAnalysis'; } private set;}
    public static String UPSELL_TAB { get { return 'upsellTab'; } private set;}
    

    public static Set<String> IMGA_ACCOUNT_RT_DEVNAMES = new Set<String> {'IMGA_Record_Type'/* 
#28747 ,'IMGA_Record_Type_At_Risk'*/};

    public static String STANDARD_ACCOUNT_RT_DEVNAME = 'Standard_Account';
    
    public ApexPages.StandardController theController;
    
    public Integer showMoreObjLimit {get; set;}

    public List<Schema.FieldSetMember> commissions_fields{
        get{
            return SObjectType.Opportunity.FieldSets.Commissions.getFields();
        }
        set; 
    }

    public Boolean isIMGAAccount
    {
        get{
            return IMGA_ACCOUNT_RT_DEVNAMES.contains(op.Account.RecordType.DeveloperName);
        }
    }
    
    @TestVisible List<OpportunityAttachmentWrapper> findrelatedAttachments( List<SObject> parentRecords )
    {
        Set<ID> parentIds = new Map<Id, SObject>( parentRecords ).keySet();
        list<OpportunityAttachmentWrapper> attachmentWrapperList = new list<OpportunityAttachmentWrapper>();
        for(Attachment a : [SELECT id, Name, LastModifiedDate, CreatedById, CreatedBy.Name, ParentId, Parent.Name
                            FROM Attachment 
                            WHERE ParentId in : parentIds ]) {
            attachmentWrapperList.add(new OpportunityAttachmentWrapper(a));
        }
    
        for(Schedule_A__Feed feed : [SELECT id, Title, LastModifiedDate, CreatedById, CreatedBy.Name, ParentId, Parent.Name, RelatedRecordId  
                                        FROM Schedule_A__Feed 
                                        WHERE ParentId in : parentIds  and type = 'ContentPost' ]) {
            attachmentWrapperList.add(new OpportunityAttachmentWrapper(feed));
        }

        for(QuoteFeed feed : [SELECT id, Title, LastModifiedDate, CreatedById, CreatedBy.Name, ParentId, Parent.Name, RelatedRecordId  
                                        FROM QuoteFeed 
                                        WHERE ParentId in : parentIds  and type = 'ContentPost' ]) {
            attachmentWrapperList.add(new OpportunityAttachmentWrapper(feed));
        }
        
        return attachmentWrapperList;
              
    }
    
    public List<OpportunityAttachmentWrapper> schedAAttachments{
        get{
            
            if( schedAAttachments == null )
            {
                schedAAttachments = findrelatedAttachments( (List<SObject>) op.Quotes );
            }
            return schedAAttachments;   
        }
        private set;
    }
    
    public Boolean schedAAtachmentsEmpty{
        get{
            return schedAAttachments.isempty();
        }
        private set;
    }

    public Boolean pAModelAttachmentsEmpty{
        get{
            return pAModelAttachments.isempty();
        }
        private set;
    }

    public List<OpportunityAttachmentWrapper> pAModelAttachments{
        get{
            
            if( pAModelAttachments == null )
            {
                pAModelAttachments = findrelatedAttachments( (List<SObject>) op.Schedule_A_Opp__r );
            }
            return pAModelAttachments;  
        }
        private set;
    }

    public static Map<String,List<Solution>> knowledgeBaseMap {
        get {
    
            if( knowledgeBaseMap == null )
            {
                knowledgeBaseMap = new Map<String, List<Solution>>();
                system.debug('+++ SOLUTION_SUB_TYPES ++++'+ SOLUTION_SUB_TYPES);
                for(String sol_type : SOLUTION_SUB_TYPES)
                {
                    knowledgeBaseMap.put( sol_type, new List<Solution>() );
                }
                
                system.debug('+++++++++++ knowledgeBaseMap +++++ ' +knowledgeBaseMap);
    
                Set<String> solutionFieldSetFields = new Set<String>();
    
                String query = 'SELECT ';
    
                for (Schema.FieldSetMember fieldSetEntryLabel : SObjectType.Solution.FieldSets.Opportunity_Tab_Solution_Fields.getFields()){
                    solutionFieldSetFields.add( fieldSetEntryLabel.getFieldPath() );
                }
    
                solutionFieldSetFields.add('Id');
                solutionFieldSetFields.add('Sub_Type__c');
    
                query += String.join( new List<String> (solutionFieldSetFields), ',');
                query += ' FROM Solution WHERE Sub_Type__c in :SOLUTION_SUB_TYPES';
    
                for( Solution solutionFound : database.query( query ) )
                {
                    knowledgeBaseMap.get(solutionFound.Sub_Type__c).add( solutionFound );
                }
            }
            system.debug('++++++++++++++ return knowledgebasemap +++++++++++ '+ knowledgeBaseMap);
            return knowledgeBaseMap;
        }
        set;
    }
    
    public static User runningUser {
        get{
            if(runningUser == null){
                runningUser = [Select id, country, dsfs__DSProSFUsername__c, Docusign_User_Type__c from User where ID =: UserInfo.getUserId() limit 1];
            }
            return runningUser;
        } set;
    }
    
    public Boolean showLossFields {
        get {
            return LOSS_STAGES.contains(op.stageName) || closedLostErrorShown;
        }
        private set;
    }

    public Boolean showStorageProfile {
        get {
            if (isIMGAAccount){
                Integer numStorageProfiles = [Select Count() From Storage_Profile__c Where Customer__c = :op.Account.Id];
                if ( numStorageProfiles > 0){
                    return true;
                }
            }
            return false;
        }
        private set;
    }
    public Boolean showNCSPHelp{
        get{
            return ( (String.IsBlank(op.NCSP_Status__c) && STAGE_FIVE.contains(op.stageName)) ||  (op.NCSP_Status__c == ESCALATED) ) ? true : false;
        }
        set;
    }
    public boolean closedLostErrorShown{
        get{
            return pageMessageContains(CLOSED_LOST_ERROR_MESSAGE) || pageMessageContains(CLOSED_LOST_ERROR_MESSAGE_2);
        }
        set;
    }

    public boolean upsellErrorShown{
        get{
            
            return pageMessageContains(UPSELL_ERROR_MESSAGE);
        }
        set;
    }
     public boolean isDocusignUser {
        get{
            if (isDocusignUser == null){
                User u = [Select id, dsfs__DSProSFUsername__c, Docusign_User_Type__c from User where ID =: UserInfo.getUserId() limit 1];
                string Docusign = u.Docusign_User_Type__c;
                isDocusignUser = (u.dsfs__DSProSFUsername__c != null && Docusign != null && Docusign.Contains('Loop Plus'));
            }
            return isDocusignUser;
        }
        private set;
    }
// John Maroudas 

    public boolean isGenerateDocusignProposalUser {
        get{
            if (isGenerateDocusignProposalUser == null){
                User u = [Select id, dsfs__DSProSFUsername__c, Docusign_User_Type__c from User where ID =: UserInfo.getUserId() limit 1];
                string Docusign = u.Docusign_User_Type__c;
               isGenerateDocusignProposalUser = (u.dsfs__DSProSFUsername__c != null && Docusign != null && u.Docusign_User_Type__c.Contains('Generate Docusign Proposal'));
            }
            return isGenerateDocusignProposalUser;
        }
        private set;
    }
// End John Maroudas  
//added this code to add new button on to Tabbed oppty view - Sarath Chandra      
   
   public boolean isESignatureUser {
        get{
            if (isESignatureUser == null){
                User u = [Select id, dsfs__DSProSFUsername__c, Docusign_User_Type__c from User where ID =: UserInfo.getUserId() limit 1];
                string Docusign = u.Docusign_User_Type__c;
                isESignatureUser = (u.dsfs__DSProSFUsername__c != null && Docusign != null && u.Docusign_User_Type__c.Contains('Send to Cust for eSig button'));
            }
            return isESignatureUser;
        }
        private set;
    }    
    public String defaultTab {
        get{
            return setDefaultTab();
        }
        set;
    }

    public boolean showDMS {
        get{
            return op.Total_DMS_Revenue__c > 0;
        }
        private set;
    }

    public boolean showOpportunityAnswers{
        get{
            return op.Opportunity_Answers__r.size() > 0;
        }

        private set;
    }
    
    public boolean showAccountPlans
    {
        get
        {
            return !accountPlans.isEmpty();
        }
        private set;    
    }
    
@TestVisible private Set<String> getAccountPlanFieldsToDisplay{
        
        get{
            if( getAccountPlanFieldsToDisplay == null )
            {
                getAccountPlanFieldsToDisplay = new Set<String>{'Id', 'Name', 'Account__c', 'RecordType.DeveloperName', 'RecordtypeId'};
                
                for( Schema.FieldSetMember fMember : Schema.SObjectType.SFDC_Acct_Plan__c.fieldSets.OpportunityTabPage.getFields() )
                    getAccountPlanFieldsToDisplay.add( fMember.getFieldPath() );    
            }
            return getAccountPlanFieldsToDisplay;
        }
        
        set;
    }
    
    public List<SFDC_Acct_Plan__c> accountPlans
    {
        get
        {
            if( accountPlans == NULL )
            {
                String ImgaGroup = op.Account.IM_IMGA_Indexed__c;
                
                String query = 'Select ' + String.join(new List<String>( getAccountPlanFieldsToDisplay ),',')
                                + ', (Select RecordTypeID, RecordType.name, Id, Name, Assigned_To__r.name, Assigned_To__r.id, Targeted_Product_Line__c, '  
                                + '   Start_Date__c, Due_Date__c, Status__c, Due_Date_Warning__c '
                                + '   from Objectives__r WHERE status__c != :' + COMPLETED 
                                + ' Order By Due_Date_Warning__c NULLS LAST, Due_Date__c ASC )'
                                + ' from SFDC_Acct_Plan__c'
                                + ' where Account__r.IM_IMGA_Indexed__c = :ImgaGroup'
                                + ' AND Account__r.IM_IMGA_Indexed__c <> null'
                                + ' AND RecordType.DeveloperName in :ACCOUNT_PLAN_RECORD_TYPE_DEVELOPER_NAMES'
                                + ' AND RecordType.IsActive = true'
                                + ' Order By LastModifiedDate Desc';
                
                accountPlans = database.query( query );
            }
            return accountPlans;
        }
        private set;
    }

    public String stageName {get;set;}    
    public Decimal oppAmount {get;set;}
    
    public Decimal getoppAmount() {
        return oppAmount;
            }
    
    public String typeName{get;set;}
    public list<oppHistories> opHistories{get;set;}
    public OpportunityContExt(ApexPages.StandardController stdController) {
        List<String> field_paths = new List<String>(); 
        for(Schema.FieldSetMember fm : commissions_fields){
            field_paths.add(fm.getFieldPath());
        }
        
        if (!Test.isRunningTest())
            stdController.addFields(field_paths);
        
        this.theController = stdController;
         
        ID opID = stdController.getRecord().id;
        opHistories = new list<oppHistories>();
        Map<string,string> checkDateDuplicate = new Map<string,string>();
        //Showing Opportunity History Related List
        Map<String, Schema.SObjectField> CaseFieldmap = Schema.SObjectType.Opportunity.fields.getMap();
        for (OpportunityFieldHistory fh: [Select o.OpportunityId, o.OldValue, o.NewValue,CreatedBy.Name, o.IsDeleted, o.Id, o.Field, o.CreatedDate, o.CreatedById From OpportunityFieldHistory o WHERE OpportunityId =:opID Order by CreatedDate desc]) {
            // Create a new wrapper object
            oppHistories ch = new oppHistories();
            if(checkDateDuplicate.containskey(String.valueOf(fh.createddate.format('MM/dd/yyyy hh:mm a'))+'-'+fh.createdby.name)){
                ch.theDate = '';
                ch.who = '';
            }else{
                checkDateDuplicate.put(String.valueOf(fh.createddate.format('MM/dd/yyyy hh:mm a'))+'-'+fh.createdby.name,'');
                ch.theDate = String.valueOf(fh.createddate.format('MM/dd/yyyy hh:mm a'));
                ch.who = fh.createdby.name;
            }
            string tempLabel='';
            if(CaseFieldmap.containsKey(fh.Field)){
                tempLabel = CaseFieldmap.get(fh.Field).getDescribe().getLabel();
            }
            if (String.valueOf(tempLabel) == 'created') { // on Creation
                ch.action = 'Created.';
            }else if(fh.OldValue != null && fh.NewValue == null){ // when deleting a value from a field
                try{
                    ch.action = 'Deleted ' + Date.valueOf(fh.OldValue).format() + ' in <b>' + String.valueOf(tempLabel) + '</b>.';
                }catch (Exception e){
                    ch.action = 'Deleted ' + String.valueOf(fh.OldValue) + ' in <b>' + String.valueOf(tempLabel) + '</b>.';
                }
            } else {
                String fromText = '';
                if (fh.OldValue != null) {
                    try{
                        fromText = ' from ' + Date.valueOf(fh.OldValue).format();
                    }catch (Exception e) {
                        fromText = ' from ' + String.valueOf(fh.OldValue);
                    }
                }
                String toText = '';
                try{
                    toText = ' from ' + Date.valueOf(fh.NewValue).format();
                }catch (Exception e) {
                    toText = '' + String.valueOf(fh.NewValue);
                }
                    ch.action = 'Changed <b>' + String.valueOf(tempLabel) + '</b>' + fromText + ' to <b>' + toText + '</b>.';
            }
            opHistories.add(ch);
        }
        //-----
        
        
        this.op =   [SELECT id, name, CurrencyIsoCode, Account.IM_IMGA_Indexed__c, type, ownerID, stageName, Sent_to_NCSP_Date__c, Total_DMS_Revenue__c, Amount, 
                        Account.RecordType.DeveloperName, Account.Id, Account.RecordTypeID, Account.IMGA_Lookup__c,
                        IM_Unit_of_Measure__c, IM_Up_Sell_Sold_To__c,
                        (SELECT id from ActivityHistories),
                        (SELECT id from OpportunityLineItems),
                        (SELECT id from NotesAndAttachments),
                        (SELECT id from OpportunityContactRoles),
                        (SELECT id from OpenActivities),
                        (SELECT id from Schedule_A_Opp__r),
                        (SELECT id from Quotes),
                        (SELECT Id FROM Opportunity_Answers__r), NCSP_Status__c
                    FROM opportunity where id =: opID limit 1];
        profileImageUrl = [SELECT SmallPhotoUrl from User where Id =: this.op.ownerID limit 1].smallPhotoUrl;
        system.debug('this.op: ' + this.op);
        if(stageName == null) stageName = op.stageName;
        if(typeName == null) typeName = op.Type;
		      
        oppAmount = op.Amount;   
        if(oppAmount!=null)
        {
            List<CurrencyType> currencyTpyeList = [select id,IsoCode,ConversionRate from CurrencyType where isActive = true] ;
            Map<String , Decimal> isoWithRateMap = new Map<String, Decimal>();
            for(CurrencyType c : currencyTpyeList) {
                isoWithRateMap.put(c.IsoCode , c.ConversionRate) ;
            }
            if(op.CurrencyIsoCode != 'USD' && isoWithRateMap.containsKey(op.CurrencyIsoCode))
            {
                oppAmount = op.Amount/isoWithRateMap.get(op.CurrencyIsoCode);
            }
            oppAmount = oppAmount.round();
        }
        //Lets get the account plan
        List<SFDC_Acct_Plan__c> possibleAccountPlans = [Select Id, Strategic_Objective__c
                                                        from SFDC_Acct_Plan__c
                                                        where Account__c = :op.AccountId
                                                        Order By LastModifiedDate Desc
                                                        Limit 1 ];

        accountPlan = possibleAccountPlans.isempty() ? new SFDC_Acct_Plan__c() : possibleAccountPlans[0];
        showMoreObjLimit = 5;
    }
    
    public void showMoreObjectives(){
        showMoreObjLimit = 25;
    }
    public void showFewerObjectives(){
        showMoreObjLimit = 5;
    }

    public PageReference redirect(){

        User currentUser = [SELECT Tabbed_Opportunity_Opt_Out__c FROM User WHERE Id = :UserInfo.getUserId() ];
        Tabbed_Opportunity_Access__c pageAccessSettings = Tabbed_Opportunity_Access__c.getInstance ( UserInfo.getProfileId() );

        if (!currentUser.Tabbed_Opportunity_Opt_Out__c && pageAccessSettings.Id != null){
            PageReference customPage =  Page.OpportunityNewEditPage;
            customPage.setRedirect(true);
            customPage.getParameters().put('id', op.id);
            return customPage;
        }
        else {
            return new PageReference('/'+op.id+'?nooverride=1');
        }
    }

    public String setDefaultTab(){
        String tabName = SCHEDULE_A_TAB;
        if( upsellErrorShown ){
            tabName = UPSELL_TAB;
        } else if ( closedLostErrorShown || (WINLOSS_STAGES.contains(op.stageName)) || ( STAGE_FIVE.contains(op.stageName) && op.NCSP_Status__c != null) )
            tabName = WIN_LOSS_ANALYSIS_TAB;
        return tabName;
    }
    
    public Boolean showWinLossAnalyis {
        get {
            if (closedLostErrorShown || WINLOSS_STAGES.contains(op.stageName) || (STAGE_FIVE.contains(op.stageName) && !String.IsBlank(op.NCSP_Status__c)) ){
                return true;
            }
            return false;
        }
        private set;
    }

    public Boolean getIsUpsell(){
        return (op.type == Constants.UPSELL_LIFT);
    }

    public Boolean getIsNCSP(){
        return WINSTAGES.contains(op.StageName);
    }

    public Boolean getIsWon() {
        return (new Set<String>{Constants.OP_STAGE_CLOSED, Constants.OP_STAGE_SETUP, Constants.OP_STAGE_SIGNED_IN}).contains(op.StageName);
    }
    public Boolean getIsLost() {
        return (new Set<String>{Constants.OP_STAGE_DEAD, Constants.OP_STAGE_LOST}).contains(op.StageName);
    }

    public integer getNotesAndAttachmentsSize() {
        return op.NotesAndAttachments.size();
    }
    public integer getOpportunityContactRolesSize() {
        return op.OpportunityContactRoles.size();
    }
    public integer getOpenActivitiesSize() {
        return op.OpenActivities.size();
    }
    public integer getActivityHistoriesSize() {
        return op.ActivityHistories.size();
    }
    
    static Boolean pageMessageContains(String messageNeedle)
       {
            system.debug('+++++ size of page messages ApexPages.getMessages().size() = '+ApexPages.getMessages().size());
               if( ApexPages.getMessages().size() > 0 )
               {
                       for (ApexPages.Message message : ApexPages.getMessages() ){

                           if(message.getSummary().contains(messageNeedle))
                                   return true;
                       }
               }

               return false;
       }
       
    @RemoteAction
    public static String sendToNCSP( Id oppId ) {

        String message = '';
        Opportunity opp = [SELECT Id, Type, StageName, OwnerId, AccountId,IMGA_Name__c FROM Opportunity WHERE Id = :oppId ];
        User owner = [SELECT isActive, Commission_Id__c, Country FROM User WHERE Id = :opp.OwnerId ];

        if ( opp.Type == 'Renewal' ) {
            message = '/apex/renewalOppWizard2_step1?oppId=' + opp.Id;//+'&accId='+opp.AccountId+'&imga='+opp.IMGA_Name__c;
            //message = Label.Renewal_Error;
        }
        else if( !owner.IsActive ) {
            message = Label.Active_User_Error;
        }
        else if(owner.Commission_ID__c == null || owner.Commission_ID__c == ' ') {
            message = Label.User_Commission_Id_Error;
        }
        else {
            if(opp.StageName == '5 - Signed/PO in' ){
                if( opp.Type == 'Up-Sell/Lift' && (runningUser.Country == 'United States' || runningUser.Country == 'Canada') ) {
                    message = '/apex/NCSPSell_LiftWizard_CompletedOrder?Id=' + opp.Id;
                }
                else {
                    message = '/apex/NCSPWizard_Step1?oppId=' + opp.Id;
                }
            }
            else {
                message = Label.Stage5_Error;
            }
        }

        return message;

    }

    @RemoteAction
    public static List<InboundStorageWrapper> getInboundStorage(Id opp_id){
        List<InboundStorageWrapper> res = new List<InboundStorageWrapper>(); 
        for(Inbound_Storage__c inb : [SELECT Name
                      ,Association_To_Opportunity_Status__c 
                      ,Opportunity__r.Name
                      ,Dept_ID_del__c
                      ,Customer_Account__r.Name
                      ,Div_ID_del__c
                      ,Storage_Date__c
                      ,Total_Revenue__c
                      ,Total_Volume__c 
                      ,Total_Rate_Calculation__c
                      ,Opportunity__r.First_Bill_Booked_Date__c
                      //Commented as part of #16915
                      //,Opportunity__r.Estimated_Revenue__c
                FROM Inbound_Storage__c 
                WHERE Opportunity__c = :opp_id AND Association_To_Opportunity_Status__c LIKE 'Matched%'
                ORDER BY Storage_Date__c desc]){
            res.add(new InboundStorageWrapper(inb));
        }

        return res; 
    }

    @RemoteAction
    public static List<InboundStorageWrapper> searchInboundStorage(String opid, String cust,String dept,String div,Boolean all_types){
    Integer total_length = (cust == null ? 0 : cust.length()) + (dept == null ? 0 : dept.length()) + (div == null ? 0 : div.length());
    if(total_length == 0){
            return null; 
        }
        else{
            //Removed Opportunity__r.Estimated_Revenue__c from select query as part of  #16915
            String query = 'SELECT Name,Total_Volume__c,Total_Revenue__c,Total_Rate_Calculation__c,Storage_Date__c,Association_To_Opportunity_Status__c,Opportunity__r.Id,Opportunity__r.Name,Dept_ID_del__c,Customer_Account__r.Name,Div_ID_del__c,Opportunity__r.First_Bill_Booked_Date__c FROM Inbound_Storage__c WHERE'; 
            if(cust != ''){
                query+=' Customer_Account__r.Name LIKE \'' + cust + '\' AND'; 
            }
            if(dept != ''){
                query+= ' Dept_ID_del__c LIKE \'' + dept + '\' AND';
            }
            if(div != ''){
                query+= ' Div_ID_del__c LIKE \'' + div + '\'';
            }
            query = query.removeEnd('AND');

            if(all_types){
                query+= ' AND Association_To_Opportunity_Status__c IN (\'Matched - Pending\', \'Matched - Approved\', \'\')';
                query+= ' AND Opportunity__c != null ';
                query+= ' AND Opportunity__r.Id != \''+opid+'\'';
            } else {
                query+= ' AND Opportunity__c = null ';

            }

            query+=' AND RecordType.Name = \'Inbound Storage\' ORDER BY Storage_Date__c desc LIMIT 50';

            List<Inbound_Storage__c> resp = new List<Inbound_Storage__c>(); 
            system.debug('query is ' + query);
            try{
                resp.clear();
                resp = database.query(query); 
            }
            catch(QueryException e){
                system.debug('Query Exception occured on query ' + query);
                return null; 
            }

            List<InboundStorageWrapper> res = new List<InboundStorageWrapper>(); 
            system.debug('resp is ' + resp);
            for(Inbound_Storage__c inb : resp){
               // res.clear();
                res.add(new InboundStorageWrapper(inb));
            }
            system.debug('res is ' + res);
            return res; 
        }
    }

    @RemoteAction
    public static List<InboundStorageWrapper> addInboundStorage(List<Id> inb_ids,Id opp_id,String status){
        List<Inbound_Storage__c> inb_storage =  [SELECT Name
                                                      ,Association_To_Opportunity_Status__c 
                                                      ,Opportunity__r.Name
                                                      ,Opportunity__c
                                                      ,Dept_ID_del__c
                                                      ,Customer_Account__r.Name
                                                      ,Div_ID_del__c
                                                      ,Storage_Date__c
                                                      ,Total_Revenue__c
                                                      ,Total_Volume__c
                                                      ,Total_Rate_Calculation__c
                                                      ,Opportunity__r.First_Bill_Booked_Date__c
                                                      //Commented as part of #16915      
                                                      //,Opportunity__r.Estimated_Revenue__c 
                                                FROM Inbound_Storage__c
                                                WHERE Id IN :inb_ids
                                                ORDER BY Storage_Date__c desc];
        system.debug(inb_storage);

        List<InboundStorageWrapper> res = new List<InboundStorageWrapper>(); 
        for(Inbound_Storage__c inb : inb_storage){
            inb.Opportunity__c = opp_id; 
            inb.Association_To_Opportunity_Status__c = status; 
            res.add(new InboundStorageWrapper(inb));
        }

        update inb_storage;
        return res;
    }
    
    public void saveOpp(){
        update op;
    }
    
    public class InboundStorageWrapper {
        public Id id; 
        public String name; 

        public String status; 
        public String opp_name; 
        public String dept;
        public String div; 
        public String cust_name; 
        public String booked_date; 
        public String est_revenue; 
        public String storage_date;
        public String total_revenue;
        public String total_volume; 
        public String rate;

        public InboundStorageWrapper(Inbound_Storage__c rec){
            this.id = rec.Id; 
            this.name = rec.Name;
            this.status = rec.Association_To_Opportunity_Status__c; 
            this.opp_name = rec.Opportunity__r.Name; 
            this.dept = rec.Dept_ID_del__c; 
            this.div = rec.Div_ID_del__c; 
            this.cust_name = rec.Customer_Account__r.Name; 
            this.booked_date = String.valueOf(rec.Opportunity__r.First_Bill_Booked_Date__c); 
            //Commented as part of #16915
            //this.est_revenue = String.valueOf(rec.Opportunity__r.Estimated_Revenue__c);
            this.storage_date = String.valueOf(rec.Storage_Date__c);
            this.total_revenue = String.valueOf(rec.Total_Revenue__c);
            this.total_volume = String.valueOf(rec.Total_Volume__c);
            this.rate = String.valueOf(rec.Total_Rate_Calculation__c);
        }
    }
    public class oppHistories {
    // Class properties
        public String theDate {get; set;}
        public String who {get; set;}
        public String action {get; set;}
    }
}
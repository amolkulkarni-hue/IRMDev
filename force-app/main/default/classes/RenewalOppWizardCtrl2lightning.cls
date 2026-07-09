public class RenewalOppWizardCtrl2lightning {
    
    public static final String OPP_ID_PARAM = 'oppId';
    public static final String NEXT = 'Next';
    public static final String CREATE_CASE = 'Create Case';
    public static Id CASE_OWNER {
        get{
            if(CASE_OWNER == null){
                CASE_OWNER = [select id from group where developername = 'Data_Entry' limit 1][0].id;
            }
            return CASE_OWNER;
        }set;
    }
    
    public String searchText{get;set;} 
    public boolean showSearchResults{get;set;}
    public boolean showListOfAttachments{get;set;}
    public boolean hasTwoServiceLines{
        get{
            if(hasTwoServiceLines == null){
                hasTwoServiceLines=false;
                if(!(ctrlCaseWith2ndServLine.NCSP_Service_line__c == null || ctrlCaseWith2ndServLine.NCSP_Service_line__c == '') )
                    hasTwoServiceLines=true;
            }
            return hasTwoServiceLines;
        }
        set;}
    public Opportunity ctrlOpportunity {get; set;}
    public Case ctrlCaseWith1stServLine {get; set;}
    public Case ctrlCaseWith2ndServLine {get; set;}
    //Added for case Comments
    public CaseComment caseComm{get;set;}
    public String displayServLine {
        get{
            if(hasTwoServiceLines)
                return ctrlCaseWith1stServLine.NCSP_Service_line__c +' & '+ ctrlCaseWith2ndServLine.NCSP_Service_line__c;
            return ctrlCaseWith1stServLine.NCSP_Service_line__c;
        }
    }

    public List<customerAccountWrapper > imgaCustomerAccountWrappers{
        get{
            if(imgaCustomerAccountWrappers == null){ 
                updateImgaCustomerAccountWrappers();
            }
            return imgaCustomerAccountWrappers;
         }
         set;
    }
    public void updateImgaCustomerAccountWrappers(){ 
         imgaCustomerAccountWrappers = new List<customerAccountWrapper >();
            for (IM_Customer_Account__c custAcc: (List<IM_Customer_Account__c >)con.getRecords())
                imgaCustomerAccountWrappers.add(new CustomerAccountWrapper(custAcc));
        }
    public void resetImgaCustomerAccountWrappers(){
        for (customerAccountWrapper custAccWrapper: imgaCustomerAccountWrappers)
            custAccWrapper.checked = false;
    }
    public List<customerAccountWrapper > searchCustomerAccountWrappers {get;set;}
    private List<PageReference> previous = new List<PageReference>();
    @Testvisible private final Id opportunityId;
    @Testvisible private final Id accountId;
    @Testvisible private final String imga;
    @Testvisible private List<Case> casesToBeInserted;
    public List<Case_Customer_Account__c> caseCustomerAccountsToBeInserted{
        get{
            if(caseCustomerAccountsToBeInserted==null) 
            {
                caseCustomerAccountsToBeInserted =new List<Case_Customer_Account__c>();
            }
            return caseCustomerAccountsToBeInserted;
        } private set;
    }
    
    public RenewalOppWizardCtrl2lightning (){
        RecordType RecType = [Select Id From RecordType  Where SobjectType = 'Case' and DeveloperName = 'NCSP_Renewal'];
        ctrlCaseWith1stServLine = new Case(recordtypeid = RecType.id );
        ctrlCaseWith2ndServLine = new Case(recordtypeid = RecType.id);
        searchCustomerAccountWrappers = new List<customerAccountWrapper>();
        this.opportunityId = Apexpages.currentPage().getParameters().get( OPP_ID_PARAM ); 
        ctrlOpportunity =[Select Id, AccountId,Name, OwnerId,IMGA_Name__c From Opportunity where id =:opportunityId ];
        this.accountId = ctrlOpportunity.AccountId;
        this.imga = ctrlOpportunity.IMGA_Name__c;
        showSearchResults = false;
        showListOfAttachments = false;
        //Added for case Comments
        caseComm = new CaseComment();
    }
    
    public PageReference redirectToStep2(){
        previous.add( ApexPages.currentPage());        
         return new Pagereference('/apex/Renewaloppwizard2_step2_Lightning');//?caseId='+ caseId + '&servLine='+displayServLine+'&imga='+imga);
       
    }
    public ApexPages.StandardSetController con {
        get {
            if(con == null) {//Name == Customer Id:: IM_Customer_Account_Name__c == Customer Name::IM_Account__c == Account ::IM_Status__c == Status
                system.debug(' imga '+imga);
                String imgaQuery ='Select Id, Name,IM_Customer_Account_Name__c,IM_Account__c,IM_Account__r.name,IM_Status__c FROM IM_Customer_Account__c where IM_IMGA__c!=null and IM_IMGA__c=:imga And IM_Status__c = \'Active\' Order By Name limit 1000';
                con = new ApexPages.StandardSetController(Database.getQueryLocator(imgaQuery));
                // sets the number of records in each page set
                con.setPageSize(10);
            }return con;
        }set;
    }
    public PageReference search() {      
        for (IM_Customer_Account__c custAcc: [Select Id, Name,IM_Customer_Account_Name__c,IM_Account__c,IM_Account__r.name,IM_Status__c FROM IM_Customer_Account__c where Name like :searchText+'%' And IM_Status__c ='Active' LIMIT 1000])
            searchCustomerAccountWrappers.add(new CustomerAccountWrapper(custAcc));
        
        if(searchCustomerAccountWrappers !=null && searchCustomerAccountWrappers.size()>0){
            showSearchResults = true;
        }
        return null;
    }
    public PageReference redirectToStep3(){
        previous.add( ApexPages.currentPage());
       return new Pagereference('/apex/Renewaloppwizard2_step3_Lightning');//?caseId='+ junctionForCaseId + '&servLine='+displayServLineOnLookupPage);
       
    }
    
    public class CustomerAccountWrapper {        
        public Boolean checked{ get; set; }
        public IM_Customer_Account__c wCustAcc { get; set;}
        
        public CustomerAccountWrapper(){
            wCustAcc = new IM_Customer_Account__c();
            checked = false;
        }        
        public CustomerAccountWrapper(IM_Customer_Account__c acc){
            wCustAcc = acc;
            checked = false;
        }        
    }
    public Boolean hasNext {
        get {
            return con.getHasNext();
        }
        set;
    }
    
    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }
        set;
    }
    
    public Integer pageNumber {
        get {
            return con.getPageNumber();
        }
        set;
    }
    
    public void first() {
        con.first();
        updateImgaCustomerAccountWrappers();
    }
    
    public void last() {
        con.last();
        updateImgaCustomerAccountWrappers();
    }
    
    public void previousForSetCon() {
        con.previous();
        updateImgaCustomerAccountWrappers();
    }
    
    public void nextForSetCon() {
        con.next();
        updateImgaCustomerAccountWrappers();
    }
    
    public void cancelForSetCon() {
        con.cancel();
    }
    public PageReference cancel (){
        return new PageReference( '/' + opportunityId );
    }
    /*public List<Attachment> attachments {
        get {
            //system.debug(casesToBeInserted[ithElement].id);
            attachments = [SELECT Id, Name, LastModifiedDate, CreatedBy.Name FROM Attachment WHERE ParentId = :opportunityId];
            system.debug(showListOfAttachments +'showListOfAttachments');
            if(attachments != null && attachments.size()>0){
                showListOfAttachments = true;
            }
            system.debug(showListOfAttachments +'showListOfAttachments');
            return attachments;
        } set;
    }*/
    private transient List<sObject> internal_attachments;
    public List<sObject> FilesAttachments {
        get {
            internal_attachments = new List<sObject>();
            if ( null == internal_attachments )
                system.debug('opportunityId>>>'+opportunityId);
                internal_attachments.addAll([SELECT Id, Name, LastModifiedDate, CreatedBy.Name FROM Attachment WHERE 
                                        ParentId = :opportunityId order by LastModifiedDate desc]);
            system.debug('internal_attachments>>>>'+internal_attachments);
           	    internal_attachments.addAll([SELECT ContentDocumentId,ContentDocument.Title,ContentDocument.LastModifiedDate,
                                   		ContentDocument.CreatedBy.Name FROM ContentDocumentLink WHERE LinkedEntityId = :opportunityId
                                    	order by ContentDocument.LastModifiedDate desc]);
            System.debug('Attachment Count>>>'+internal_attachments.size());
            /*Map<String,sObject> FilenAttachMap = new Map<String,sObject>();
            Map<String,sObject> FilenAttachFinalMap = new Map<String,sObject>();
            List<String> orderingList = new List<String>();
            for (sObject FA: internal_attachments){
                system.debug('FA>>>'+FA);
                String s = FA.id;
                if(s.startsWith('00P')){
                    String LstModified = FA.LastModifiedDate;
                    FilenAttachMap.put(FA.id,FA);
                }
                else{
                    system.debug('FA>>>'+FA);
                    //FilenAttachMap.put(FA.LastModifiedDate,FA);
                }
            }
            orderingList.addAll(FilenAttachMap.keyset());
            orderingList.sort();
            
            for ( Integer i= 0;i < orderingList.size(); i++){
                    FilenAttachFinalMap.put(orderingList[i],FilenAttachMap.get(orderingList[i]));
            }
            internal_attachments = FilenAttachFinalMap.values();*/
            
            return internal_attachments;
        }
    }
    
    public Attachment attachment {
        get {
            if (attachment == null)
                attachment = new Attachment();
            return attachment;
        }
        set;
    }
    
    public PageReference upload() {
        
        attachment.OwnerId = UserInfo.getUserId();
        attachment.ParentId = opportunityId; // the record the file is attached to
        //attachment.IsPrivate = true;
        
        try {
            insert attachment;
            showListOfAttachments = true;
        } catch (DMLException e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading attachment'));
            return null;
        } finally {
            attachment = new Attachment(); 
        }
        
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Attachment uploaded successfully'));
        return null;
    }
    public PageReference previous()
    {
        if(previous.size() == 0)
            return null;
        else
            return previous.remove(previous.size()-1);
    }
    
    public void insertCases(){
        casesToBeInserted = new List<Case>();
        String caseOrigin = NCSPWizardCtrl.findCaseOrigin( Userinfo.getProfileId());
        Id userId = Userinfo.getUserId();
        ctrlCaseWith1stServLine.AccountId = accountId;
        ctrlCaseWith1stServLine.NCSP_Opportunity__c = opportunityId; 
        ctrlCaseWith1stServLine.Sales_Person_Name_Account_Manager__c = ctrlOpportunity.OwnerId;
        ctrlCaseWith1stServLine.OwnerId = CASE_OWNER;
        ctrlCaseWith1stServLine.NSCP_Case_Creator_Name__c = userId;
        ctrlCaseWith1stServLine.Origin = caseOrigin;
        System.debug('** 1st case with service line added to be inserted SL '+ ctrlCaseWith1stServLine.NCSP_Service_line__c );
        casesToBeInserted.add(ctrlCaseWith1stServLine) ;
        
        if(hasTwoServiceLines)
        {
            
            ctrlCaseWith2ndServLine.Deal_Type__c = ctrlCaseWith1stServLine.Deal_Type__c ;
            ctrlCaseWith2ndServLine.Setup_Type__c = ctrlCaseWith1stServLine.Setup_Type__c ;
            ctrlCaseWith2ndServLine.Non_Standard__c = ctrlCaseWith1stServLine.Non_Standard__c ;
            system.debug(' date contract signed  '+ctrlCaseWith1stServLine.Date_Contract_Signed__c );
            ctrlCaseWith2ndServLine.Date_Contract_Signed__c = ctrlCaseWith1stServLine.Date_Contract_Signed__c ;
            ctrlCaseWith2ndServLine.Date_Paperwork_Received__c = ctrlCaseWith1stServLine.Date_Paperwork_Received__c ;
            ctrlCaseWith2ndServLine.Contract_Effective_Date__c = ctrlCaseWith1stServLine.Contract_Effective_Date__c ;
            ctrlCaseWith2ndServLine.AccountId = accountId;
            ctrlCaseWith2ndServLine.NCSP_Opportunity__c = opportunityId;
            ctrlCaseWith2ndServLine.Sales_Person_Name_Account_Manager__c = ctrlOpportunity.OwnerId;
            ctrlCaseWith2ndServLine.OwnerId = CASE_OWNER;
            ctrlCaseWith2ndServLine.NSCP_Case_Creator_Name__c = userId;
            ctrlCaseWith2ndServLine.Origin = caseOrigin;
            System.debug('** 2nd case with service line added to be inserted SL '+ctrlCaseWith2ndServLine.NCSP_Service_line__c );
            
            casesToBeInserted.add(ctrlCaseWith2ndServLine);
            System.debug('Case List>>>>'+casesToBeInserted+'Size>>>'+casesToBeInserted.size());
        }
        try{
            if(casesToBeInserted.size()>0){
                System.debug('Case insert list>>>>'+casesToBeInserted);
                insert casesToBeInserted;
                System.debug('Case List id>>'+casesToBeInserted[0].Id);
                //Added for case Comments
                if(caseComm.CommentBody != '' || caseComm.CommentBody != null){
                    List<CaseComment> caseCommList = new List<CaseComment>();
                    for(Case ca : casesToBeInserted){
                        CaseComment cc = new CaseComment();
                        cc.CommentBody = caseComm.CommentBody;
                        cc.ParentId = ca.id;
                        caseCommList.add(cc);
                    }
                    if(caseCommList.size() > 0){
                        insert caseCommList;
                    }
                }
            }
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Following Error has occured while inserting Case '+ e.getMessage()));
        }
    }
    public void createCase(){
        insertCases();        
        searchCustomerAccountWrappers.addAll(imgaCustomerAccountWrappers);
        for(CustomerAccountWrapper caWrapper: searchCustomerAccountWrappers){
            if(caWrapper.checked){
                caseCustomerAccountsToBeInserted.add(new Case_Customer_Account__c(Case__c = casesToBeInserted[0].id,Customer_Account__c = caWrapper.wcustAcc.id));
                System.debug('Case Cusomer Account List >>>>'+caseCustomerAccountsToBeInserted);
                if(hasTwoServiceLines)
                    caseCustomerAccountsToBeInserted.add(new Case_Customer_Account__c(Case__c = casesToBeInserted[1].id,Customer_Account__c = caWrapper.wcustAcc.id));
            System.debug('Case Cusomer Account List 1 >>>>'+caseCustomerAccountsToBeInserted);
            }
        }
        if(caseCustomerAccountsToBeInserted.size()>0)
            insert caseCustomerAccountsToBeInserted;
        
    }
    public PageReference redirectToCase(){
        return new PageReference('/'+casesToBeInserted[0].id);
    }
}
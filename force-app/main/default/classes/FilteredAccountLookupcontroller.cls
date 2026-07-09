public with sharing class FilteredAccountLookupcontroller {
    public string opportunityId {get; set;}
    public String query {get; set;}
    public String elementIdHidden {get; set;}
    public String elementIdText {get; set;}
    @TestVisible static Integer MAX_PAGE_SIZE = 25;
    @TestVisible static string MAX_RESULTS_MESSAGE = 'The search returned too many results.  Try to narrow your search criteria.';
    @TestVisible static string NO_RESULTS_MESSAGE = 'The search did not find any results';
    @TestVisible static string OPP_NOT_FOUND_MESSAGE = 'The Opportunity cannot be found';
    @TestVisible static final String IM_ACCOUNT_STATUS = 'Active';
    
    public static final String SCHEDULE_A_OPPORTUNITY_ID_KEY = 'id';
    public static final String OPPORTUNITY_ID_KEY = 'opId';
    public static final String QUERY_KEY = 'q';
    public static final String HIDDEN_ID_KEY = 'hiddenId';
    public static final String TEXT_ID_KEY = 'textId';
    public String soqlQuery {get; set;} 
    public String blanketSoqlQuery {get; set;} 
    public String condition {get; set;}
    public String conditionString {get; set;}
    public String IMGA_Index {get; set;}
    public ID accountId {get; set;}
    public List<ID> selectedIDS{get;set;}
    public Map<ID, boolean> selectedIDMap {
        get{
            for(ID selectedId : SelectedIDS){
                selectedIDMap.put(selectedId, true);
            }
            return selectedIDMap;
        } set;
    }
    
    public ApexPages.StandardSetController con {
        get {
            if(con == null) {
                system.debug('IM_ACCOUNT_STATUS: ' + IM_ACCOUNT_STATUS);
                system.debug('blanketCustAccountNames : ' + blanketCustAccountNames );
                system.debug('conditionString : ' + conditionString ); 
                system.debug('IMGA_Index : ' + IMGA_Index );                 
                system.debug('soqlQuery: ' + soqlQuery);
                if(String.isBlank(ApexPages.currentPage().getParameters().get('opId')) && 
                String.isBlank(ApexPages.currentPage().getParameters().get('accId')))
                    con = new ApexPages.StandardSetController(Database.getQueryLocator(blanketSoqlQuery));    
                else
                    con = new ApexPages.StandardSetController(Database.getQueryLocator(soqlQuery));
                con.setPageSize(MAX_PAGE_SIZE);
                totalPageNumber = null;
            }
            return con;
        }
        set;
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
            if (pageNumber == null){
                pageNumber = 1;
            }
            return pageNumber;
        }
        set;
    }

    public Boolean onlyRelatedAccounts {
        get { 
            return (onlyRelatedAccounts == null) ? true : onlyRelatedAccounts; 
        } 
        set;
    }
 
    public void first() {
        con.first();
        pageNumber = con.getPageNumber();
    }
 
    public void last() {
        con.last();
        pageNumber = con.getPageNumber();
    }
 
    public void previous() {
        con.previous();
        pageNumber = con.getPageNumber();
    }
 
    public void next() {
        con.next();
        pageNumber = con.getPageNumber();
    }
    
    public List<IM_Customer_Account__c> accounts {
        get{
            
            pageNumber = con.getPageNumber();
            List<IM_Customer_Account__c> result = (List<IM_Customer_Account__c>) con.getRecords();

            if ( result.IsEmpty() )
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, NO_RESULTS_MESSAGE));
            }
            return result; 
        }
        set;
    }

    public Integer accountsSize {
        get{
            return accounts.size(); 
        }
        set;
    }
    
    public List<IM_Customer_Account__c> blanketAccounts {
        get{
            if(blanketAccounts == null) {
                blanketAccounts = new List<IM_Customer_Account__c>();
                if( ! blanketCustAccountNames.isEmpty() ) {
                    blanketAccounts = Database.query(blanketSoqlQuery);
                }
            }
            return blanketAccounts;
        }    
        set;
    }   
        
    public Integer blanketAccountsSize {
        get{
            return blanketAccounts.size(); 
        }
        set;
    }

    public Integer totalPageNumber {
       get{
           if(totalPageNumber == null){
               Integer extraPage = (Math.mod(con.getResultSize(), MAX_PAGE_SIZE) == 0) ? 0 : 1;
               totalPageNumber = (con.getResultSize() / MAX_PAGE_SIZE) + extraPage ;
           }
           return totalPageNumber;   
       }
       set;
    }
    
    @TestVisible private List<String> blanketCustAccountNames {
        get{
            if(blanketCustAccountNames == null){

                blanketCustAccountNames = new List<String>();   
                Map<String, blanketCustomerIds__c> currentBlankets = blanketCustomerIds__c.getAll();

                if( !currentBlankets.isEmpty() ) 
                    blanketCustAccountNames.addAll( new List<String>( currentBlankets.keySet() ));
                }
                return blanketCustAccountNames; 
            }
        set;
    }
    
    
    public void gotoPage(){
        if (pageNumber != con.getPageNumber() && pageNumber > 0 && pageNumber <= totalPageNumber){
            con.setpageNumber(pageNumber);
        }
    }
    
    public FilteredAccountLookupcontroller()
    {
        this.opportunityId = ApexPages.currentPage().getParameters().get(OPPORTUNITY_ID_KEY);
        if(opportunityID != null && opportunityID.startsWith('006')) {
            this.query = ApexPages.currentPage().getParameters().get(QUERY_KEY);
            this.elementIdHidden = ApexPages.currentPage().getParameters().get(HIDDEN_ID_KEY);
            this.elementIdText = ApexPages.currentPage().getParameters().get(TEXT_ID_KEY);
            generateAccountsQuery();
        } else {
            this.opportunityId = ApexPages.currentPage().getParameters().get(SCHEDULE_A_OPPORTUNITY_ID_KEY);
            this.AccountId = ApexPages.currentPage().getParameters().get('accId');
            generateAccountsQuery();
        }
        //Get the current page name  
        String pageName = ApexPages.CurrentPage().getUrl();
        pageName = pageName.replaceFirst('/apex/','');
        pageName = EncodingUtil.urlEncode(pageName, 'UTF-8');
        string[] pageNameExtra = pageName.split('%3F',0);
        pageName = pageNameExtra[0];
        //If the controller accessed from "FilteredAccountLookup" vf page then show the message
        if(pageName == 'FilteredAccountLookup')
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This lookup shows Customer IDs related to the Opportunity’s Account Hierarchy.  The Opportunity and Customer ID Accounts must match unless prepaid OTS deal.'));
    }
    
    public void generateAccountsQuery()
    {
        conditionString = '';
        con = null;
        this.accounts = new List<IM_Customer_Account__c>();
        if( String.IsNotBlank( condition ) )
        {
            if (condition.contains('*'))
            {
                condition = query.replaceAll('\\*','%');
            }
            conditionString = '%' + condition;
            conditionString += '%';
        }
        Set<String> queryFields = new Set<String>();
        queryFields.add('Id');
        queryFields.add('IM_Account__r.Name');
        
        soqlQuery = 'SELECT ';
            
        for (Schema.FieldSetMember fieldSetEntryLabel : SObjectType.IM_Customer_Account__c.FieldSets.Custom_Lookup_Fields.getFields()){
            queryFields.add(fieldSetEntryLabel.getFieldPath());
        }
       
        soqlQuery += String.join( new List<String> (queryFields), ',');
        
        //soqlQuery += ' FROM IM_Customer_Account__c';
       
        //blanketSoqlQuery = soqlQuery + ' Where Name IN : blanketCustAccountNames ';
        blanketSoqlQuery = soqlQuery + ' FROM IM_Customer_Account__c Where Name IN : blanketCustAccountNames ';
       
       // soqlQuery    += ' WHERE (NA_PY_YTD_TOTAL__c > 0 OR NA_CY_YTD_TOTAL__c > 0)'
                   //  +  ' AND IM_Status__c = :IM_ACCOUNT_STATUS ' ;
                   
        if(! blanketCustAccountNames.isempty()) {
            //soqlQuery +=  ' AND NAME NOT IN : blanketCustAccountNames';
            soqlQuery +=  ' FROM IM_Customer_Account__c WHERE NAME NOT IN : blanketCustAccountNames';
            soqlQuery +=    String.IsNotBlank( conditionString ) ? ' AND ( Name Like :conditionString OR IM_Account__r.Name like :conditionString )' : '';
        }else{
            soqlQuery +=  ' FROM IM_Customer_Account__c ';
            soqlQuery +=    String.IsNotBlank( conditionString ) ? ' WHERE ( Name Like :conditionString OR IM_Account__r.Name like :conditionString )' : '';
        }
        system.debug(soqlQuery+'before');

        if( String.IsNotBlank(this.opportunityId) || String.IsNotBlank(this.accountId) )
        {
            if(String.IsNotBlank(this.opportunityId)) {
            //We need to find the account IMGA details for this oppty
            List<Opportunity> opp = [SELECT Id, Account.IM_IMGA_Indexed__c 
                                    FROM Opportunity
                                    WHERE Id = :this.opportunityId
                                    Limit 1];
            
            if( opp.isEmpty() )
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, OPP_NOT_FOUND_MESSAGE));
                return;
            }
            
                IMGA_Index = opp[0].Account.IM_IMGA_Indexed__c;
                accountId = opp[0].AccountId;
            }
            else {
                 List<Account> acc = [SELECT Id, Account.IM_IMGA_Indexed__c 
                                    FROM Account
                                    WHERE Id = :this.AccountId
                                    Limit 1];
                                    
                IMGA_Index = acc[0].IM_IMGA_Indexed__c; 
            }
            system.debug('++++++onlyRela######'+soqlQuery );
            if(onlyRelatedAccounts)
            {
                system.debug('++++++onlyRelatedAccounts'+onlyRelatedAccounts);
                Boolean presentWhere =soqlQuery.contains('WHERE');
                system.debug('$$$$'+presentWhere);
                system.debug('$$$$'+accountId);
                if(presentWhere){
                    soqlQuery += String.IsNotBlank(IMGA_Index) ? ' AND IM_Account__r.IM_IMGA_Indexed__c = :IMGA_Index' : ' AND IM_Account__c = :accountId';                
                }else{
                    soqlQuery += String.IsNotBlank(IMGA_Index) ? ' WHERE IM_Account__r.IM_IMGA_Indexed__c = :IMGA_Index' : ' WHERE IM_Account__c = :accountId';                                
                }
                
            }

            soqlQuery += ' ORDER BY NA_CY_YTD_TOTAL__c DESC';
            
            if(!onlyRelatedAccounts)
            {
                system.debug('++++++onlyRelatedAccountsElse'+onlyRelatedAccounts);
                soqlQuery += ' LIMIT 1000';
            }
        }
        else{
          //  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, OPP_NOT_FOUND_MESSAGE));
            return;
        }
        system.debug('ending'+soqlQuery);
    }
}
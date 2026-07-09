public with sharing class CustomOpportunityLookupController {
    public string opportunityId {get; set;}
    public String query {get; set;}
    public String elementIdHidden {get; set;}
    public String elementIdText {get; set;}
    public Set<id> optyids = new Set<id>();
    public String link;
    @TestVisible static Integer MAX_PAGE_SIZE = 25;
    @TestVisible static string MAX_RESULTS_MESSAGE = 'The search returned too many results.  Try to narrow your search criteria.';
    @TestVisible static string NO_RESULTS_MESSAGE = 'The search did not find any results';
    @TestVisible static string OPP_NOT_FOUND_MESSAGE = 'The Opportunity cannot be found';
    public static final String OPPORTUNITY_ID_KEY = 'opId';
    public static final String QUERY_KEY = 'q';
    public static final String HIDDEN_ID_KEY = 'hiddenId';
    public static final String TEXT_ID_KEY = 'textId';
    public String soqlQuery {get; set;} 
    public String condition {get; set;}
    public String conditionString {get; set;}
    public String IMGA_Index {get; set;}
    public ID accountId {get; set;}
    public ID parentid {get; set;}
    public List<WrapChildOpportunity> WrapChildOpportunitylist {get;set;}
    public List<Opportunity> optylist {get;set;}
    public List<Opportunity> opp {get;set;}
    public Boolean displayopp{get;set;}

    
    public ApexPages.StandardSetController con {
        get {
            if(con == null) {
                system.debug('conditionString : ' + conditionString ); 
                system.debug('IMGA_Index : ' + IMGA_Index );                 
                system.debug('soqlQuery: ' + soqlQuery);
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
 
    public void first() {
        con.first();
        pageNumber = con.getPageNumber();
        ChildOpportunitylist();
    }
 
    public void last() {
        con.last();
        pageNumber = con.getPageNumber();
         ChildOpportunitylist();
    }
 
    public void previous() {
        con.previous();
        pageNumber = con.getPageNumber();
        ChildOpportunitylist();
    }
 
    public void next() {
        con.next();
        pageNumber = con.getPageNumber();
       ChildOpportunitylist();
    }

    public void ChildOpportunitylist(){
     pageNumber = con.getPageNumber();
         WrapChildOpportunitylist = new List<WrapChildOpportunity>();
        for(Opportunity opp :(List<Opportunity>) con.getRecords()){
           WrapChildOpportunitylist.add(new WrapChildOpportunity(opp));
           }
       }
    
    public pageReference updateopportunity(){
        if(elementIdHidden== null){
            for(WrapChildOpportunity wrap :WrapChildOpportunitylist){
            if(wrap.IsSelected == true){
               opp[0].IM_Parent_Opportunity__c= wrap.childOpp.Id;
            }
        }
        update opp;
        }
        else{
            List<Opportunity> oppList = new List<Opportunity>();
        for(WrapChildOpportunity wrap :WrapChildOpportunitylist){
            if(wrap.IsSelected == true){
                wrap.childOpp.IM_Parent_Opportunity__c = opportunityId;
                oppList.add(wrap.childOpp);
            }
        }
        if(oppList.size()>0){
        try{
        update oppList;
        }
        catch(Exception e){
                system.debug('**Child Opportunities**' + e.getMessage()); 
            }
         }
        }
       WrapChildOpportunitylist.clear();
        return null;
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
   
    public void gotoPage(){
        if (pageNumber != con.getPageNumber() && pageNumber > 0 && pageNumber <= totalPageNumber){
            con.setpageNumber(pageNumber);
        }
         ChildOpportunitylist();
    }
    
    public CustomOpportunityLookupController()
    {
       
        this.opportunityId = ApexPages.currentPage().getParameters().get(OPPORTUNITY_ID_KEY); 
        this.query = ApexPages.currentPage().getParameters().get(QUERY_KEY);
        this.elementIdHidden = ApexPages.currentPage().getParameters().get(HIDDEN_ID_KEY);
        this.elementIdText = ApexPages.currentPage().getParameters().get(TEXT_ID_KEY);
        if(elementIdHidden== null){
           displayopp=true; 
        }else {
            displayopp=false; 
        }
        generateOpportunitysQuery();
     
        //Get the current page name  
        String pageName = ApexPages.CurrentPage().getUrl();
        pageName = pageName.replaceFirst('/apex/','');
        pageName = EncodingUtil.urlEncode(pageName, 'UTF-8');
        string[] pageNameExtra = pageName.split('%3F',0);
        pageName = pageNameExtra[0];
        if(pageName == 'CustomOpportunityLookup' && elementIdText == null ){
            if(elementIdHidden== null){
              link= '<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/apex/CustomOpportunityLookup?opId='+opportunityId+'&textId=006" target="_self" style="color:blue; font-weight:bold; font-size: 11px; margin-left: 3.5px;">Here</a>';  
            } else{
              link= '<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/apex/CustomOpportunityLookup?opId='+opportunityId+'&hiddenId=child&textId=006" target="_self" style="color:blue; font-weight:bold; font-size: 11px; margin-left: 3.5px;">Here</a>';  
            }
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This search will return Opportunities associated to Accounts within the same Account Hierarchy of this Opportunity’s Account.  To associate this Opportunity to an Opportunity belonging to another Account Hierarchy click'+link));
    }
   }
    
    public void generateOpportunitysQuery()
    {
        
        conditionString = '';
        con = null;
        if( String.IsNotBlank( condition ) )
        {
            if (condition.contains('*'))
            {
                condition = query.replaceAll('\\*','%');
            }
            conditionString = '%' + condition;
            conditionString += '%';
            system.debug('++conditionString++'+conditionString);
        }
        Set<String> queryFields = new Set<String>();
        queryFields.add('Id');
        queryFields.add('Account.Name');
        queryFields.add('Account.IM_IMGA_Indexed__c');
        queryFields.add('Owner.Name');
        queryFields.add('IM_Parent_Opportunity__c');
        
        soqlQuery = 'SELECT ';
            
        for (Schema.FieldSetMember fieldSetEntryLabel : SObjectType.Opportunity.FieldSets.Parent_Child_Opportunities.getFields()){
            queryFields.add(fieldSetEntryLabel.getFieldPath());
        }
       
        soqlQuery += String.join( new List<String> (queryFields), ',');
                   
        
            soqlQuery +=  ' FROM Opportunity ';
            soqlQuery +=    String.IsNotBlank( conditionString ) ? ' WHERE Name Like :conditionString' : '';

        system.debug(soqlQuery+'before');

        if( String.IsNotBlank(this.opportunityId))
        {
           
            //We need to find the account IMGA details for this oppty
            this.opp = [SELECT Id, Account.IM_IMGA_Indexed__c,IM_Parent_Opportunity__c,(Select id from Opportunities__r) 
                                    FROM Opportunity
                                    WHERE Id = :this.opportunityId
                                    Limit 1];
            
            for(Opportunity op:opp[0].Opportunities__r)
            {
                optyids.add(op.Id);
            }
            
            
            if( opp.isEmpty() )
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, OPP_NOT_FOUND_MESSAGE));
                return;
            }
            
                IMGA_Index = opp[0].Account.IM_IMGA_Indexed__c;
                accountId = opp[0].AccountId;
                parentid = opp[0].IM_Parent_Opportunity__c;
            
        
                system.debug('++++++onlyRela######'+soqlQuery );
                Boolean presentWhere =soqlQuery.contains('WHERE');
                system.debug('$$$$'+presentWhere);
                system.debug('$$$$'+accountId);
            if(elementIdText == null && accountId != null){
                if(presentWhere){
                    soqlQuery += String.IsNotBlank(IMGA_Index) ? ' AND Account.IM_IMGA_Indexed__c = :IMGA_Index AND Id != :opportunityId' : ' AND Account.Id = :accountId AND Id != :opportunityId and Account.id != null';                
                }else{
                    soqlQuery += String.IsNotBlank(IMGA_Index) ? ' WHERE Account.IM_IMGA_Indexed__c = :IMGA_Index AND Id != :opportunityId' : ' WHERE Account.Id = :accountId AND Id != :opportunityId and Account.id != null';                                
                }
            } else {
                if(presentWhere){
                    soqlQuery += ' AND Id != :opportunityId and Account.id != null';                
                }else{
                    soqlQuery += ' WHERE Id != :opportunityId and Account.id != null';                                
                }
            }
               if(parentid != null){
                soqlQuery += ' AND Id != :parentid';
              }
            if(optyids.size()>0){
                soqlQuery += ' AND Id NOT IN :optyids';
            }
              soqlQuery += ' ORDER BY IM_Booked_Date__c DESC';
            
             
             
        system.debug('ending'+soqlQuery);
    }    
          soqlQuery += ' LIMIT 100'; 
        ChildOpportunitylist();
  }
  public class WrapChildOpportunity
    {
        public opportunity  childOpp{get;set;}
        public boolean IsSelected {get;set;}
        
        public WrapChildOpportunity(Opportunity Opp)
        {
            this.childOpp= Opp;
            
            
        }
    }

}
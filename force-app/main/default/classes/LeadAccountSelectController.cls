/*     
Author       : Srinivasa Rao Mandalapu
Company      : Randstard Inc
Date         : 20-FEB-2013
Case No.     : 00430321
Description  : Opportunity Wizard 1.1-lead Convert Updates.            
               Dupeblocker has found a duplicate, but the user opts not to use the system identified duplicates and 
               instead wishes to search for their own account.The user can then use a screen to search the database for an account to use.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 08/08/2013; Srinivasa Rao/Randstad; Opty Wizard Enhancement - GSA Modification (Case # 01622446); Initial release   

* Modified By: Abarna Jeyasekaran on 13-Aug-2018
     *        -- Optimized for resolution of case #07318783
              -- Updated to include pagination, to allow state abbreviation and to optimize Search          
*/
public with sharing class LeadAccountSelectController {
    public  String   accName,postalCode, state, country,city;
    public string abbrState ;
    public string valueState ;
    public String query {get; set;}
    @TestVisible static Integer MAX_PAGE_SIZE = 5;
    @TestVisible static string MAX_RESULTS_MESSAGE = 'The search returned too many results.  Try to narrow your search criteria.';
    @TestVisible static string NO_RESULTS_MESSAGE = 'The search did not find any results';
    @TestVisible static string ACC_NOT_FOUND_MESSAGE = 'The Account cannot be found'; 
    public String condition {get; set;}
    public String conditionString1 {get; set;}
    public String conditionString2 {get; set;}
    public String conditionString3 {get; set;}
    public String conditionString4 {get; set;}
    public String conditionString5 {get; set;}
    public String soqlQuery {get; set;}  
    public String soqlQueryCondition {get; set;} 
    public List<Account> acc {get;set;}
    public Boolean displayacc{get;set;}
    public ApexPages.StandardSetController con{get; set;}
    
   public LeadAccountSelectController(ApexPages.StandardController controller)
    {
    List<Account> Accounts = new List<Account>();
    }                
  
   public PageReference Accounts() {        return null;    }
   public List<Account> getAccounts(){
       If (con!= null)
       {
           pageNumber = con.getPageNumber();
           List<Account> slRsetReturn = new List<Account>();
           for(Account acc :(List<Account>) con.getRecords())
           {
               slRsetReturn.add(acc);
           }
           return slRsetReturn;
       }
           else 
               return null;   
   } 
    //Method to generate the query to fetch the data based on the Search string
    public void generateQuery()
    {
     Map<String, String> stateMap = new MAp<String, String>{'AL' => 'Alabama', 'AK' => 'Alaska', 'AZ' => 'Arizona', 'AR' => 'Arkansas', 'CA' => 'California', 'CO' => 'Colorado',
        'CT' => 'Connecticut', 'DE' => 'Delaware', 'FL' => 'Florida', 'GA' => 'Georgia', 'HI' => 'Hawaii', 'ID' => 'Idaho', 'IL' => 'Illinois', 'IN' => 'Indiana', 'IA' => 'Iowa',
        'KS' => 'Kansas', 'KY' => 'Kentucky', 'LA' => 'Louisiana', 'ME' => 'Maine', 'MD' => 'Maryland', 'MA' => 'Massachusetts', 'MI' => 'Michigan', 'MN' => 'Minnesota', 'MS' => 'Mississippi',
        'MO' => 'Missouri', 'MT' => 'Montana', 'NE' => 'Nebraska', 'NV' => 'Nevada', 'NH' => 'New Hampshire', 'NJ' => 'New Jersey', 'NM' => 'New Mexico', 'NY' => 'New York', 'NC' => 'North Carolina',
        'ND' => 'North Dakota', 'OH' => 'Ohio', 'OK' => 'Oklahoma','OR' => 'Oregon', 'PA' => 'Pennsylvania', 'RI' => 'Rhode Island', 'SC' => 'South Carolina', 'SD' => 'South Dakota', 'TN' => 'Tennessee', 
        'TX' => 'Texas', 'UT' => 'Utah', 'VT' => 'Vermont', 'VA' => 'Virginia', 'WA' => 'Washington', 'WV' => 'West Virginia', 'WI' => 'Wisconsin', 'WY' => 'Wyoming', 'ON' => 'Ontario', 'QC' => 'Quebec',
        'BC' => 'British Columbia', 'AB' => 'Alberta', 'MB' => 'Manitoba', 'SK' => 'Saskatchewan', 'NS' => 'Nova Scotia', 'NB' => 'New Brunswick', 'NL' => 'Newfoundland And Labrador', 
        'PE' => 'Prince Edward Island', 'NT' => 'Northwest Territories','YT' => 'Yukon', 'NU' => 'Nunavut'};
          
        Map<String, String> statevalueMap = new MAp<String, String>{'alabama' => 'AL', 'alaska' => 'AK', 'arizona' => 'AZ', 'arkansas' => 'AR', 'california' => 'CA', 'colorado' => 'CO',
        'connecticut' => 'CT', 'delaware' => 'DE', 'florida' => 'FL', 'georgia' => 'GA', 'hawaii' => 'HI', 'idaho' => 'ID', 'illinois' => 'IL', 'indiana' => 'IN', 'iowa' => 'IA',
        'kansas' => 'KS', 'kentucky' => 'KY', 'louisiana' => 'LA', 'maine' => 'ME', 'maryland' => 'MD', 'massachusetts' => 'MA', 'michigan' => 'MI', 'minnesota' => 'MN', 'mississippi' => 'MS',
        'missouri' => 'MO', 'montana' => 'MT', 'nebraska' => 'NE', 'nevada' => 'NV', 'new hampshire' => 'NH', 'new jersey' => 'NJ', 'new mexico' => 'NM', 'new york' => 'NY', 'north carolina' => 'NC',
        'north dakota' => 'ND', 'ohio' => 'OH', 'oklahoma' => 'OK','oregon' => 'OR', 'pennsylvania' => 'PA', 'rhode island' => 'RI', 'south carolina' => 'SC', 'south dakota' => 'SD', 'tennessee' => 'TN', 
        'texas' => 'TX', 'utah' => 'UT', 'vermont' => 'VT', 'virginia' => 'VA', 'washington' => 'WA', 'west virginia' => 'WV', 'wisconsin' => 'WI', 'wyoming' => 'WY', 'ontario' => 'ON', 'quebec' => 'QC',
        'british columbia' => 'BC', 'alberta' => 'AB', 'manitoba' => 'MB', 'saskatchewan' => 'SK', 'nova scotia' => 'NS', 'new brunswick' => 'NB', 'newfoundland and labrador' => 'NL', 
        'prince edward island' => 'PE', 'northwest territories' => 'NT','yukon' => 'YT', 'nunavut' => 'NU'};
        abbrState = null;
        valueState = null;
        If(stateMap.containskey(state.toUpperCase()))
        {
            abbrState = stateMap.get(state.toUpperCase());
        }
        If(statevalueMap.containskey(state.toLowerCase()))
        {
            valueState = statevalueMap.get(state.toLowerCase());
        } 
        conditionString1 = '';
        conditionString2 = '';
        conditionString3 = '';
        conditionString4 = '';
        conditionString5 = '';
        con = null;
        if(String.IsNotBlank(accName))
        {
            /*if (accName.contains('*'))
            {
            system.debug('accountName'+accName);
                accName = accName.replaceAll('*','%');
            } */
            conditionString1 = '%' + accName + '%';
            system.debug('accountName'+accName);
        }
        if( String.IsNotBlank(city) )
        {
           /* if (city.contains('*'))
            {
                city = city.replaceAll('\\*','%');
            } */
            conditionString2 = '%' + city + '%';
        }
        if( String.IsNotBlank(state) )
        {
            if (state.contains('*'))
            {
                state = state.replaceAll('\\*','%');
            }
            conditionString3 = '%' + state +'%';
        }
        if( String.IsNotBlank(country) )
        {
            if (country.contains('*'))
            {
                country = country.replaceAll('\\*','%');
            }
            conditionString4 = '%' + country +'%';
        }
        if( String.IsNotBlank(postalCode) )
        {
            if (postalCode.contains('*'))
            {
                postalCode = postalCode.replaceAll('\\*','%');
            }
            conditionString5 = '%' + postalCode +'%';
        }
        Set<String> queryFields = new Set<String>();
        queryFields.add('Account.BillingStreet');
        queryFields.add('Account.BillingState');
        queryFields.add('Account.BillingCity');
        queryFields.add('Account.BillingCountry');
        queryFields.add('Account.BillingPostalCode');
        queryFields.add('Account.IM_IMGA_Indexed__c');
        queryFields.add('Account.IM_Hierarchy_Level__c');
        queryFields.add('Account.Name');
        queryFields.add('Account.Id');     
        soqlQuery = 'SELECT ';
        soqlQueryCondition  = '';           
        soqlQuery += String.join( new List<String> (queryFields), ',');                                  
        soqlQuery +=  ' FROM Account ';
            
            if(String.isNotBlank(accName))
            {
                soqlQueryCondition =  ' Name Like :conditionString1';
            }           
                     
            if(String.isNotBlank(city))
            {
                if(String.isNotBlank(soqlQueryCondition))soqlQueryCondition +=  ' AND ';
                soqlQueryCondition +=  ' BillingCity Like :conditionString2';
            }
            
            if(String.isNotBlank(state))
            {
                if(String.isNotBlank(soqlQueryCondition))soqlQueryCondition +=  ' AND ';  
                if(String.isNotBlank(abbrState))soqlQueryCondition +=  ' (BillingState Like :conditionString3 OR BillingState Like :abbrState)';
                else if(String.isNotBlank(valueState))soqlQueryCondition +=  ' (BillingState Like :conditionString3 OR BillingState Like :valueState)';
                else soqlQueryCondition +=  ' (BillingState Like :conditionString3)';
            }
            
            if(String.isNotBlank(country))
            {
                if(String.isNotBlank(soqlQueryCondition))soqlQueryCondition +=  ' AND ';
                soqlQueryCondition +=  ' BillingCountry Like :conditionString4';
            }
                
            if(String.isNotBlank(postalCode))
            {   
                if(String.isNotBlank(soqlQueryCondition))soqlQueryCondition +=  ' AND ';
                soqlQueryCondition +=  ' BillingPostalCode Like :conditionString5';
            }
            
            if(String.isNotBlank(soqlQueryCondition)) soqlQuery = soqlQuery + ' Where' +soqlQueryCondition + ' AND IM_Hierarchy_Level__c != \'IM Group (IMGA)\'';
            
            soqlQuery +=  ' ORDER BY Name ASC LIMIT 1000'; 
            
            system.debug('FINALQUERY'+soqlQuery);
            
            con = new ApexPages.StandardSetController(Database.getQueryLocator(soqlQuery));
            con.setPageSize(MAX_PAGE_SIZE);
            totalPageNumber = null;            
    }    
   //Methods to get and set the search values 
   public String getaccName(){
      return accName;
   }
   public void setaccName(String Acct){
      this.accName = Acct;    
   }
   public String getpostalCode(){
      return postalCode;
   }
   public void setpostalCode(String Acct){
      this.postalCode = Acct;
   }  
   public String getstate(){
      return state;
   }
   public void setstate(String Acct){
      this.state = Acct;
   }  
   public String getcountry(){
      return country;
   }
   public void setcountry(String Acct){
      this.country = Acct;
   }   
   public String getcity(){
      return city;
   }
   public void setcity(String Acct){
      this.city = Acct;
   }   
   //Methods to implement pagination
   public Boolean hasNext {
        get {
        if (con!= null){
            return con.getHasNext();
            }
            else
            return null;
        }
        set;
    }
    public Boolean hasPrevious {
        get {
        if (con!= null){
            return con.getHasPrevious();
            }
            else
            return null;
        }
        set;
    } 
    public Integer pageNumber {
        get {
        if (con!= null){
            if (pageNumber == null){
                pageNumber = 1;
            }
            return pageNumber;
            }
            else
            return null;
        }
        set;
    }
    public void first() {
        con.first();
        pageNumber = con.getPageNumber();
        Accounts();
    } 
    public void last() {
        con.last();
        pageNumber = con.getPageNumber();
         Accounts();
    }
    public void previous() {
        con.previous();
        pageNumber = con.getPageNumber();
        Accounts();
    }
    public void next() {
        con.next();
        pageNumber = con.getPageNumber();
       Accounts();
    }     
   public Integer totalPageNumber {
       get{
       if (con!= null)
       {
           if(totalPageNumber == null){
               Integer extraPage = (Math.mod(con.getResultSize(), MAX_PAGE_SIZE) == 0) ? 0 : 1;
               totalPageNumber = (con.getResultSize() / MAX_PAGE_SIZE) + extraPage ;
           }
           return totalPageNumber;   
           }
           else
           return null;
       }
       set;
    }  
     public void gotoPage(){
        if (pageNumber != con.getPageNumber() && pageNumber > 0 && pageNumber <= totalPageNumber){
            con.setpageNumber(pageNumber);
        }
         getAccounts();
    }  
}
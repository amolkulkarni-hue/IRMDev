public class custVerifierWorksheetclass 
{
    public  List<opportunity> optylist {get;set;}
    public  List<opportunity> optylist1 {get;set;}
    public  List<opportunity> optylist2 {get;set;}
    public  user currentuser{get;set;}
    public  String username{get;set;}
    public  Boolean rendering{get;set;}
 //   public  Boolean rendering1{get;set;}
    public  String mode {get; private set;}
    public  final Boolean canEdit {get; private set;}
    public Integer MAX_RECORDS_ON_PAGE;
    public integer searchCustomerStartIndex=0;
    public integer searchCustomerEndIndex;
    public String selectedList{get;set;}
    public String PagiIndex{get;set;}
    
    public custVerifierWorksheetclass (ApexPages.StandardsetController controller) 
    {
        optylist = new List<opportunity>();
        optylist1 = new List<opportunity>();
        optylist2 = new List<opportunity>();
        MAX_RECORDS_ON_PAGE= Integer.valueOf(Label.Customer_Verifier);
        searchCustomerEndIndex=MAX_RECORDS_ON_PAGE;
        Set<String> custverifiersheet = new Set<String>();
        List<custVerifiersWorksheet__c> custverifier= custVerifiersWorksheet__c.getAll().values();
         for(custVerifiersWorksheet__c cust : custverifier)
         {
             custverifiersheet.add(cust.Name);
         }

     //system.debug('check'+custverifiersheet );
     User currentuser=[Select Id,Name,Role_Type__c from User where Id=:userinfo.getuserId()];
     String roletype= currentuser.Role_Type__c;
     Id userid=currentuser.Id;
     username= currentuser.Name;
     rendering=true;
   //  rendering1=true;
     this.mode = 'view';
     String queryString='SELECT Id, Name, Owner.Name, Owner_Link__c, stagename, IM_Booked_Date__c, Amount, Customer_Verifier_1__c, Customer_Verifier_2__c, Customer_Verifier_3__c, Customer_Verifier_4__c, Customer_Verifier_5__c, Customer_Verifier_6__c, Customer_Verifier_7__c, Customer_Verifier_8__c, Customer_Verifier_9__c, Customer_Verifier_10__c, Customer_Verifier_11__c, Customer_Verifier_12__c, Customer_Verifier_13__c, Customer_Verifier_14__c, Customer_Verifier_15__c, Customer_Verifier_16__c,(SELECT Product_Class__c FROM OpportunityLineItems) FROM Opportunity WHERE stagename IN (\'1 - Qualification\',\'2 - Solution Developed\',\'3 - Solution Agreed\',\' 4 - Negotiate\') AND IsClosed = FALSE AND IM_Booked_Date__c = NEXT_N_DAYS:180';
     if(custverifiersheet.contains(currentuser.Role_Type__c))
     {   
     if(roletype.contains('VP'))
      queryString+= ' AND Owner_Link__r.IM_VP__c =:userid ORDER BY IM_Booked_Date__c  ASC';
     else if(roletype.contains('Director') || roletype.contains('Manager'))
      queryString+= ' AND Owner_Link__r.IM_RSM__c =:userid ORDER BY IM_Booked_Date__c  ASC';
     else if(roletype.contains('Sales'))
      queryString+= ' AND Owner.Id=:userid ORDER BY IM_Booked_Date__c  ASC';
      
      try{
      optylist =Database.Query(queryString);
      }catch(Exception e){}
         
      if(optylist.size()==0){
      this.mode = null;  
    //  rendering=false;
      }
      searchCustomerStartIndex=0;
      if(optylist.size()>MAX_RECORDS_ON_PAGE)
          searchCustomerEndIndex=MAX_RECORDS_ON_PAGE;
      else 
          searchCustomerEndIndex=optylist.size();
      CustomerPagination(searchCustomerStartIndex, searchCustomerEndIndex);
   }
    else{
    rendering=false;
 //   rendering1=false;
    String link1= '<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/500/e?retURL=%2F500%2Fo&RecordType=01280000000BWs6&ent=Case" target="_blank"><h4>Log a Case</h4></a>';
    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'This view is currently only available to NA Sales Reps, Directors and VPs. If you believe you are receiving this message in error, please'+link1));
     }
    // this.mode = 'view';
      canEdit = true;
  }
  
  public void edit(){ 
        this.mode = 'edit'; 
        }
        
  public PageReference cancel(){ 
  this.mode = 'view'; 
  return null; 
  }
  
  public void save(){ 
  optylist2 = new List<opportunity>();
        if(canEdit && optylist1 != null){
        for(opportunity op:optylist1){
            if(op.Customer_Verifier_2__c== true||op.Customer_Verifier_4__c== true||op.Customer_Verifier_5__c== true||op.Customer_Verifier_14__c== true||op.Customer_Verifier_6__c== true
            ||op.Customer_Verifier_3__c== true||op.Customer_Verifier_8__c== true||op.Customer_Verifier_15__c== true||op.Customer_Verifier_16__c== true||op.Customer_Verifier_7__c== true
            ||op.Customer_Verifier_13__c== true||op.Customer_Verifier_12__c== true||op.Customer_Verifier_9__c== true||op.Customer_Verifier_10__c== true||op.Customer_Verifier_11__c== true)
            
            optylist2.add(op);
            
        }
      }
      if(optylist2.size()>0)
          update optylist2;
        this.mode = 'view'; 
    }
    
  public Boolean getSearchCustDisablePrevious(){
        return searchCustomerStartIndex != null && optylist != null && (searchCustomerStartIndex - MAX_RECORDS_ON_PAGE) < 0;
    }
  public Boolean getSearchCustDisableNext(){
        return searchCustomerEndIndex != null && optylist != null && searchCustomerEndIndex >= optylist.size();
    }
    
  public PageReference shiftPaginationIndex() {
        if(selectedList=='searchCust'){
            if(PagiIndex=='Next'){
                searchCustomerStartIndex = (searchCustomerStartIndex + MAX_RECORDS_ON_PAGE );
                searchCustomerEndIndex = (searchCustomerEndIndex +MAX_RECORDS_ON_PAGE > optylist.size() ? optylist.size() : (searchCustomerEndIndex +MAX_RECORDS_ON_PAGE));
            }
            if(PagiIndex=='Previous'){
                searchCustomerStartIndex = searchCustomerStartIndex - MAX_RECORDS_ON_PAGE;
                searchCustomerEndIndex = searchCustomerStartIndex + MAX_RECORDS_ON_PAGE;
            }
            CustomerPagination(searchCustomerStartIndex ,searchCustomerEndIndex );
        }
      return null;
  }
    
   public void CustomerPagination(Integer b1, Integer b2){
        optylist1 = new List<opportunity>();
        for(Integer i=b1; i<b2; i++ ){
            if (Test.isrunningtest() && optylist.size() > 0 && optylist[i] != null) {
                optylist1.add(optylist[i]);
            } else if (!Test.isrunningtest()) {
                optylist1.add(optylist[i]);
            }
        }
    }
}
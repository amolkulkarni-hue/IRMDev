@isTest
public with sharing class TestingUtil {
  public String opId;
  public String scsId;
  public String scsecId;
  public String scsecItemId;
  public String actId;
  static Integer offSet = 0;

  public TestingUtil(){
    opId = makeTestableOp();
    scsId = makeSalesCoachStage();
    scsecId = makeSalesCoachSections();
    scsecItemId = makeSecItem();
    actId = makeActivities();
    ApexPages.currentPage().getParameters().put('id', this.opId);
  }
 //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
  private String makeTestableOp(){
    Opportunity op = new Opportunity();
    op.Name='testOpName';
    op.IM_Booked_Date__c = Date.today();
    op.StageName='1 - Qualification';
    op.Lead_Source_Most_Recent__c = 'Email';
    insert op;
    return op.Id;
  }
  
  private String makeSalesCoachStage(){
    Sales_Coach_Stage__c scs = new Sales_Coach_Stage__c();
    scs.Name='testStage';
    scs.Buyer_Stage__c='testBuyStage';
    scs.Active__c=true;
    insert scs;
    return scs.Id;
  }
  
  private String makeSalesCoachSections(){
    Sales_Coach_Section__c scsec =  new Sales_Coach_Section__c();
    scsec.Section_Ordering__c =1.0;
    scsec.Section_Name__c='testSection';
    scsec.Sales_Coach_Stage__c=scsId;
    scsec.Section_Width__c=33.0;
    insert scsec;
    return scsec.Id;
  }
  
  private String makeSecItem(){
    Sales_Coach_Section_Item__c secItem = new Sales_Coach_Section_Item__c();
    secItem.Section_Ordering__c=1.0;
    secItem.Sales_Coach_Section__c=scsecId;
    secItem.Link_to_Content__c='http://www.google.com';
    secItem.Item_Name__c='testItem';
    secItem.Display__c=true;
    secItem.Products__c='';
    insert secItem;
    return secItem.Id;
  }
  
  private String makeActivities(){
    Sales_Coach_Activity__c sca = new Sales_Coach_Activity__c();
    sca.Sales_Coach_Stage__c=scsId;
    sca.Ordering_Number__c=1.0;
    sca.Activity_Details__c='testActivity';
    insert sca;
    return sca.Id;
  }
  
  public static IM_Country__c createIMCountry()
  {
    IM_Country__c cntry = new IM_Country__c(Name = 'Test Country');
    insert cntry;
    
    return cntry;
  }
  
  public static Opportunity createOpportunity()
  {
    IM_Country__c cntry = createIMCountry();
     
      Account testAccount = new Account();
      testAccount.Name = 'TestAccount';
      insert testAccount;
    
    //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.  
    Opportunity opp = new Opportunity(
                                      name = 'test'
                                      ,Source_System__c = 'test SKP Europe'
                                      ,Billing_Country__c = cntry.id 
                                      ,Lead_Source_Most_Recent__c = 'x'
                                      ,StageName = '1 - Qualification'
                                      ,IM_Servicing_Region__c ='London'
                                      ,IME_Reason_Won__c = 'Benchmarking'
                                      ,AccountId = testAccount.Id   
                                      ,IM_Booked_Date__c = System.today(),
                                       CloseDate = System.today()
                                      );
    insert opp;

    return opp;
  }
  
  public static Pricebook2 createPricebook2()
  {
    Pricebook2 pr = new Pricebook2(Name = 'North America');
    insert pr;
    
    return pr;
  }
  
  public static List<User> createUsers(Integer howMany, Boolean doInsert)
  {
    Profile p = [Select id from profile where name = 'IM_Custom Sys Admin'];

    List<User> allUsers = new List<User>();
    
    for(Integer i = 0; i < howMany; i++)
    {
      offset++;
      User us = new User(alias = 'ztest'+offset, email='p'+offset+'@malkosus.com'
                         ,emailencodingkey='UTF-8'
                         , firstname='Fir'+offset
                         , lastname='Tes'+offset, languagelocalekey='en_US'
                         , localesidkey='en_US', profileid = p.id
                         , timezonesidkey='America/Los_Angeles'
                         , username='tet'+offset+'@malkosus.com'
                         ,isActive=true
                         , Country = 'United Kingdom');
      allUsers.add(us);
    }
    
    if(doInsert)
    insert allUsers;

    return allUsers;
  }
  
  public static User createUser()
  {
    Profile p = [Select id from profile where name = 'IM_Custom Sys Admin'];

    User us = new User(alias = 'hasrole', email='ptkachenko@malkosus.com'
                       ,emailencodingkey='UTF-8'
                       , lastname='Testing', languagelocalekey='en_US'
                       , localesidkey='en_US', profileid = p.id
                       , timezonesidkey='America/Los_Angeles'
                       , username='test@malkosus.com'
                       , Country = 'United Kingdom');
    insert us;

    return us;
  }
  
  public static Schedule_A__c createScheduleA(ID Id, User u)
  {
    Schedule_A__c sc = new Schedule_A__c(Approver_1__c = u.Id, Opportunity__c = Id, IsMaster__c = true, Reference__c = 'Testing File');

    insert sc;

    return sc;
  }
  
  public static Schedule_A__c createScheduleA(Boolean IsTemplate)
  {
    Schedule_A__c sc = new Schedule_A__c(IsTemplate__c = IsTemplate, IsMaster__c = true, Reference__c = 'Testing File');
    sc.Approver_1__c = UserInfo.getUserID();
    insert sc;

    return sc;
  }

  public static Schedule_A_Quote_Item__c createScheduleAQuoteItem(ID Id)
  {
    //#30912 PA Model LINES field clean up
    Schedule_A_Quote_Item__c sq = new Schedule_A_Quote_Item__c(Schedule_A__c = Id/*, Offering_Type__c = 'TEST_TYPE'*/);

    insert sq;

    return sq;
  }
  
  public static Quote createQuote()
  {
      
    Opportunity opp = createOpportunity();
    Quote quote = new Quote();
    quote.Name  = 'Test Quote';
    quote.OpportunityId  = opp.id;
    
    insert quote;

    return quote;
  } 
}
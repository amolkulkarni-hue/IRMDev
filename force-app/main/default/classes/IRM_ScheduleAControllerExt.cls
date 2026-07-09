/**  
 * Name            : IRM_SceduleAControllerExt
 * Description     : Controller to manage page flow for schedule A activities
 * 
 * Copyright       : Bluewolf
 * Author          : Chris Matthews
 * Modification Log: Created:26-Oct-2012 
 
Updated class to restrict % off changes and PA Model upload for Recall flagged accounts
Case # 05049974
Author : Vinutha
Date : 27/04/2016

Updated class to Assign Case to "IM Employees Support Cases IMNA Queue" for case#07921834
Modified by : Keerthi Senthilnathan
Case # 07921834
Date : 08-Feb-2018
 **/
public class IRM_ScheduleAControllerExt 
{
   public static String PARAMETER_STEP = 'Step';
   public static String DBnR { get{ return 'DB&R'; } set; } 
   public static String RM { get{ return 'RM'; } set; } 
   public static String SERVICE { get{ return 'Service'; } set; } 
   public static String STORAGE { get{ return 'Storage'; } set; } 
   public static String RECORDS_MANAGEMENT = 'Records Management';
   public static String UPSELL_LIFT = 'Up-Sell/Lift';
   public static String RENEWAL = 'Renewal';
    
   public static String STEP_VIEW_MAIN                 { get{ return 'STEP_VIEW_MAIN'; } set; } 
   
   public static String STEP_VIEW_SERVICE_LINES         { get{ return 'STEP_VIEW_SERVICE_LINES'; } set; }   
   public static String STEP_VIEW_LIST_PRICE         { get{ return 'STEP_VIEW_LIST_PRICE'; } set; } 
   public static String STEP_VIEW_SCHEDULE_A_ITEMS      { get{ return 'STEP_VIEW_SCHEDULE_A_ITEMS'; } set; }
   public static String STEP_VIEW_SCHEDULE_A_TEMPLATES  { get{ return 'STEP_VIEW_SCHEDULE_A_TEMPLATES'; } set; }
   public static String STEP_VIEW_UPLOAD_FILE           { get{ return 'STEP_VIEW_UPLOAD_FILE'; } set; }
   public static String STEP_VIEW_STEP1           { get{ return 'STEP_VIEW_STEP1'; } set; }
   public static String STEP_VIEW_PERCENT_STEP1           { get{ return 'STEP_VIEW_PERCENT_STEP1'; } set; }
   
   public static String STEP_VIEW_UPLOAD_EXCEL_FILE     { get{ return 'STEP_VIEW_UPLOAD_EXCEL_FILE'; } set; }
   public static String STEP_VIEW_UPLOAD_FILE_APPROVERS { get{ return 'STEP_VIEW_UPLOAD_FILE_APPROVERS'; } set; }
   public static String STEP_VIEW_UPLOAD_COMPLETE       { get{ return 'STEP_VIEW_UPLOAD_COMPLETE'; } set; }
   public static String STEP_VIEW_PRICE_ADJUST_QUESTION { get{ return 'STEP_VIEW_PRICE_ADJUST_QUESTION'; } set; }
   public static String STEP_VIEW_PRICE_ADJUST          { get{ return 'STEP_VIEW_PRICE_ADJUST'; } set; }
   public static String STEP_VIEW_QUOTE_COMPLETE        { get{ return 'STEP_VIEW_QUOTE_COMPLETE'; } set; }
   public static String STEP_VIEW_SELECT_CUSTOMER_ACCOUNTS { get{ return 'STEP_VIEW_SELECT_CUSTOMER_ACCOUNTS'; } set; }
   public static String STEP_VIEW_CUSTOMER_ACCOUNT_GENERATION_ERROR { get{ return 'STEP_VIEW_CUSTOMER_ACCOUNT_GENERATION_ERROR'; } set; }
   public static String STEP_VIEW_INCLUDE_QUOTE_CUSTOMER_ACCOUNTS { get{ return 'STEP_VIEW_INCLUDE_QUOTE_CUSTOMER_ACCOUNTS'; } set; }
   public static String STEP_VIEW_CASE_CREATED { get{ return 'STEP_VIEW_CASE_CREATED'; } set; }
   private static List<String> VALID_CUST_ACCT_SOURCE_SYS  = new List<String>{'SKP NA', 'SB NA'};
   public static Integer MAX_APPROVERS = 12;
   public Double ProposedVolume;
   public Double ProposedPrice;
   
   @TestVisible 
   private String               id               = null;
   @TestVisible
   private String               quoteId          = null;
   @TestVisible
   private Opportunity          opportunity      = null;
   public IRM_ScheduleAService scheduleAService = new IRM_ScheduleAService();
   private Boolean              isReaploadFile   = false;
   
   public String        productPricing                          { set; get; }
   public Document      paXMLFile                               { set; get; }
   public Document      paEXCELFile                             { set; get; }
   public String        selectedScheduleAId                     { set; get; }
   public Schedule_A__c selectedScheduleA                       { set; get; }
   public List<Schedule_A_Quote_Item__c> quoteItemList          { set; get; }
   public List<Schedule_A_Quote_Item__c> quoteItemListReference { set; get; }
   public Quote         quote                                   { set; get; }
   
   public Boolean       isErrorScheduleAQuoteItems              { set; get; }
   public Boolean       discountApplied                         { set; get; }
   public Boolean       percentOffPricing                       { set; get; }
   
   public List<String>  previousStepsName                       { set; get; }
   
   private Set<String> discountFieldsOnTemplate = new Set<String>{ 'RM_List_Price_Discount__c', 'DBR_Storate_List_Price_Discount__c', 'DBR_Service_List_Price_Discount__c'};
   public Set<String> customAccountIDs                          { get;set; }
   public String customerAccountsFromBrowser                    { get;set; }
   public boolean imgaContainsCustomerAccounts; 
   @TestVisible
   public Case caseCreated                                      { get; set; }
   
   
   public String currentStepName { 
       get ;
       
       set { 
          
              if( currentStepName != null)
              {
                this.previousStepsName.add( currentStepName );
              }
              
            currentStepName = value;
       }
   }
   
   public Boolean standardPricingIsEditable{
    get{
        
        Boolean isEditable = false;
        
        //if template is null return true
        if ( selectedScheduleA == null )
            return true;
        
        for( String templateField : discountFieldsOnTemplate )
        {
            Object value = selectedScheduleA.get(templateField);
            
            if( value != null && (Decimal) value > 0 )
                return false;
        }
        
        return isEditable;  
    }
    set;
   }
   
    public Map<String, boolean> exemptBillingCodeMap {
       get{
           if(exemptBillingCodeMap == null){
               exemptBillingCodeMap = new Map<String, boolean>();
               if( scheduleAService != null && IRM_ScheduleAService.exemptBillingCodeList != null) {
                   system.debug('++++111'+IRM_ScheduleAService.exemptBillingCodeList);
                   for(String billingCode : IRM_ScheduleAService.exemptBillingCodeList){
                      exemptBillingCodeMap.put(billingCode, true);
                   }
                   for(Schedule_A_Quote_Item__c quote : quoteItemList){
                      if(!exemptBillingCodeMap.containsKey(quote.product__r.name.toLowerCase())){
                          exemptBillingCodeMap.put(quote.product__r.name.toLowerCase(), false);
                      }
                   }
               }
           }
           return exemptBillingCodeMap;
       }
       set;
   }
   
   public Map<String, string> dbrTypeMap {
          get{
              if(dbrTypeMap== null){
                  dbrTypeMap = new Map<string, string>();
                  Map<String, DBRDiscountTypes__c> discountTypes = IRM_ScheduleAService.dbrDiscountTypes;
                  if( scheduleAService != null && IRM_ScheduleAService.dbrDiscountTypes != null) {
                      for(Schedule_A_Quote_Item__c quote : quoteItemList){
                          string dType = IRM_ScheduleAService.getDbrDiscountType(quote.product__r.name);
                          if(dType != null){
                              dbrTypeMap.put(quote.product__r.name.toLowerCase(), dType);
                          } else if (quote.Product_Class__c == RECORDS_MANAGEMENT ) {
                              dbrTypeMap.put(quote.product__r.name.toLowerCase(), RM);
                          }  else {
                              dbrTypeMap.put(quote.product__r.name.toLowerCase(), '');
                          }
                      }
                   }
               }
           return dbrTypeMap;
       }
       set;
   }
   
   public boolean rmIncluded {get{return includedServiceTypes.contains(RM); }}
   public boolean dbrIncluded {get{return includedServiceTypes.contains(SERVICE.toLowerCase()) || includedServiceTypes.contains(STORAGE.toLowerCase()); }}
  
   
   public Set<String> includedServiceTypes {
       get{
           if(includedServiceTypes == null ) {
               includedServiceTypes = new Set<String>();
               if(dbrTypeMap != null) {
                   includedServiceTypes.addAll(dbrTypeMap.values());
               }
           }
           return includedServiceTypes;
       } set;
   }
   
   
   public Schedule_A__c newScheduleA 
   {
      get
        { 
            if( newScheduleA == NULL ) 
            {
                newScheduleA = new Schedule_A__c();
            } 
            return newScheduleA; 
        } 
        set; 
    } 

    public List<SelectOption> navigateOptions 
    {
        get
        {
            if( navigateOptions == NULL )
            {
                navigateOptions = new List<SelectOption>();
                navigateOptions.add( new SelectOption( STEP_VIEW_SCHEDULE_A_ITEMS, Label.PA_MODEL_APPROVED ) ); 
                if(opportunity.Type != RENEWAL)
                {
                    if(opportunity!=null && (opportunity.Type == UPSELL_LIFT) && imgaContainsCustomerAccounts ) {
                        navigateOptions.add( new SelectOption( STEP_VIEW_SELECT_CUSTOMER_ACCOUNTS, Label.PA_MODEL_NOT_REQUIRED ) );
                    } else {
                        navigateOptions.add( new SelectOption( STEP_VIEW_SERVICE_LINES, Label.PA_MODEL_NOT_REQUIRED ) );
                    } 
                }
                
            }
            return navigateOptions;
        }
        set;
    }
    
    public String navigateTo { get; set; } 
   
   public List<SelectOption> serviceLines 
   {
        get
        {
            if( serviceLines == NULL )
            {
                serviceLines = new List<SelectOption>();
                serviceLines.add( new SelectOption( DBnR, DBnR ) );
                serviceLines.add( new SelectOption( RM, RM ) );
            }
            return serviceLines;
        }
        set;
    }
    
    public String selectedServiceLine { get; set; }
     
    
    public string discountStorage { get; set; } 
    public string discountService { get; set; } 
    public string discountRM {get; set;}
    public string invalidCustomerAccounts{
        get{
            if(String.isBlank(invalidCustomerAccounts))
                invalidCustomerAccounts = createInvalidCustomerAccountStr();
            return invalidCustomerAccounts;
        }
        set;
            
    }
    
    public List<IM_Customer_Account__c> approvedPAModelCustomerAccounts
    {
        get
        {
            if( approvedPAModelCustomerAccounts == null )
            {
                approvedPAModelCustomerAccounts = new List<IM_Customer_Account__c>();
                String custIds;
                if(selectedScheduleA != null && this.selectedServiceLine == null)
                   custIds = selectedScheduleA.CustomerIds__c;
                else
                   custIds = [Select CustomerIds__c from Schedule_A__c Where Id = :this.selectedScheduleAId].CustomerIds__c; 
                        
                if(!String.isBlank(custIds))
                {
                    List<String> customerIdList = custIds.split(',');
                    
                    approvedPAModelCustomerAccounts =[ select id, name, IM_Customer_Account_Name__c
                                          from IM_Customer_Account__c
                                          where name in :customerIdList and Source_System__c IN :VALID_CUST_ACCT_SOURCE_SYS ];
                }
            }
            return approvedPAModelCustomerAccounts;
        }
        set;
    }
    
    public List<SelectOption> quoteCustomerAccountPicklistOptions
    {
        get
        {
            if( quoteCustomerAccountPicklistOptions == null )
            {
                quoteCustomerAccountPicklistOptions = new List<SelectOption>();
                Schema.DescribeFieldResult fieldResult = Quote_Customer_Account__c.Schedule_A_Document__c.getDescribe();
                List<Schema.PicklistEntry> pickListEntryList = fieldResult.getPicklistValues();
        
                for( Schema.PicklistEntry field : pickListEntryList)
                    quoteCustomerAccountPicklistOptions.add(new SelectOption(field.getLabel(), field.getValue()));
            }
            return quoteCustomerAccountPicklistOptions;
        }
        set;
    }
    public List<PAModelCustomerAccountsWrapper> approvedPAModelCustomerAccountsWrapper
    {
        get
        {
            if(approvedPAModelCustomerAccountsWrapper == null)
            {
                approvedPAModelCustomerAccountsWrapper = new List<PAModelCustomerAccountsWrapper>();
                for(IM_Customer_Account__c aCustAcct : approvedPAModelCustomerAccounts)
                {
                        PAModelCustomerAccountsWrapper aWrap = new PAModelCustomerAccountsWrapper(aCustAcct);
                        approvedPAModelCustomerAccountsWrapper.add(aWrap);
                }
            }
            return approvedPAModelCustomerAccountsWrapper;
        }
        set;
    }
    
    @TestVisible
    private string createInvalidCustomerAccountStr()
    {
        string concatenatedInvalidAccounts = '';
        if(IRM_ScheduleAParseXML.INVALID_ACCOUNTS != null)
        {
            for(String aCustAccount : IRM_ScheduleAParseXML.INVALID_ACCOUNTS)
                concatenatedInvalidAccounts += (concatenatedInvalidAccounts =='') ? aCustAccount : ', ' + aCustAccount ;
        }
        return concatenatedInvalidAccounts;
    }

   public IRM_ScheduleAControllerExt()
   {
      init();
   }

   public IRM_ScheduleAControllerExt( ApexPages.StandardController controller )
   {
      init();
   }

   private void init()
   {
      
      this.previousStepsName = new List<String>();
      this.discountApplied = false; 
      
      this.dbrTypeMap = null;
      this.includedServiceTypes = null;
      this.imgaContainsCustomerAccounts = false;
      this.customAccountIDs = new Set<String>();
      this.customerAccountsFromBrowser = '';
      
      if( System.currentPageReference().getParameters() != null && 
          System.currentPageReference().getParameters().get(PARAMETER_STEP) != null )
      {
        if (System.currentPageReference().getParameters().get(PARAMETER_STEP) == STEP_VIEW_SCHEDULE_A_ITEMS ||
            System.currentPageReference().getParameters().get(PARAMETER_STEP) == STEP_VIEW_PRICE_ADJUST_QUESTION ||
            System.currentPageReference().getParameters().get(PARAMETER_STEP) == STEP_VIEW_UPLOAD_FILE || 
            System.currentPageReference().getParameters().get(PARAMETER_STEP) == STEP_VIEW_STEP1 ||
            System.currentPageReference().getParameters().get(PARAMETER_STEP) == STEP_VIEW_MAIN )
            {
                this.currentStepName = System.currentPageReference().getParameters().get(PARAMETER_STEP);
            }   
      }
      if(this.currentStepName ==  null){
          this.currentStepName = STEP_VIEW_MAIN;
      }
      
      this.paXMLFile           = new Document();
      this.paEXCELFile         = new Document();
      //this.selectedScheduleAId = null;
      //this.selectedScheduleA   = null;
      if( System.currentPageReference().getParameters() != null && 
          System.currentPageReference().getParameters().get('quoteid') != null )
      {
          this.quoteid = System.currentPageReference().getParameters().get('quoteid');
          
          if( this.quoteId != null )
          {
             Quote q =
                 [ 
                    select opportunity.id, Schedule_A__c, opportunity.Type
                    from quote
                    where id=:this.quoteId                  
                 ];
             this.id = q.opportunity.id;
                  
             if ( this.selectedScheduleAId == null && q.Schedule_A__c != null
                 && (this.currentStepName ==  STEP_VIEW_PRICE_ADJUST_QUESTION)
             ) {
                this.selectedScheduleAId = q.Schedule_A__c;
                this.discountApplied = true;
                this.selectedServiceLine = null;
                this.selectScheduleA();
             }  
          }
      }

      if( System.currentPageReference().getParameters() != null && 
          System.currentPageReference().getParameters().get('id') != null )
      {
         this.id = System.currentPageReference().getParameters().get('id');
      }
      
      if( this.id != null && this.id != '' )
      {
         opportunity = [ select id, name, accountid, Account.IM_IMGA_Indexed__c, account.name, type
                         from Opportunity 
                         where id=:this.id];
          
         List<IM_Customer_Account__c> customerAccountCheck;
         
         if(opportunity.account.im_imga_indexed__c == null) {
             customerAccountCheck = [Select id from IM_Customer_Account__c where IM_Account__c = :opportunity.accountId  
                                  AND (NA_PY_YTD_TOTAL__c > 0 OR NA_CY_YTD_TOTAL__c > 0) AND IM_Status__c = 'Active' limit 1];
         } else {
             customerAccountCheck = [Select id from IM_Customer_Account__c where IM_Account__r.IM_IMGA_Indexed__c =: opportunity.Account.IM_IMGA_Indexed__c  
                                  AND (NA_PY_YTD_TOTAL__c > 0 OR NA_CY_YTD_TOTAL__c > 0) AND IM_Status__c = 'Active' limit 1];
         }
         
         this.imgaContainsCustomerAccounts =  !customerAccountCheck.isEmpty();
         
         
      }
      
   }
   
   public PageReference mainSelect()
   {
        PageReference pageReference = null;
        this.percentOffPricing = (navigateTo == STEP_VIEW_SELECT_CUSTOMER_ACCOUNTS);
        if(navigateTo == STEP_VIEW_SERVICE_LINES || navigateTo == STEP_VIEW_SELECT_CUSTOMER_ACCOUNTS)
              this.currentStepName = STEP_VIEW_PERCENT_STEP1;
        else
            this.currentStepName = navigateTo;
        return(pageReference); 
   } 
   /*
   public PageReference buildCustomerAccountList(){
       this.customAccountIDs.addAll(customerAccountsFromBrowser.split(','));
       PageReference pageReference = null; 

       return(pageReference); 
   }
   */

   public void buildCustomerAccountList(){
        this.customAccountIDs.addAll(customerAccountsFromBrowser.split(','));
   }

   public PageReference selectCustomerAccounts() {
       
       PageReference pageReference = null; 
       this.currentStepName = STEP_VIEW_SERVICE_LINES;
       return(pageReference); 
   }
   
   
   public PageReference selectServiceLine() 
   {
        PageReference pageReference = null;
        this.currentStepName = STEP_VIEW_LIST_PRICE;
        this.discountApplied = false;
        return(pageReference);
   }
   
   public PageReference resetPage()
   {
      this.currentStepName = STEP_VIEW_MAIN;   
      return(null); 
   }

   public List<Schedule_A__c> getScheduleAList()
   {
      return( scheduleAService.getScheduleAList(this.id, false) );
   }

   public List<Schedule_A__c> getScheduleATemplateList()
   {
      Opportunity opportunity = scheduleAService.getOpportunityFields( this.id ); 
      if( selectedServiceLine == DBnR ) 
        return scheduleAService.getDBnRScheduleATemplate( opportunity ); 
      else if( selectedServiceLine == RM ) 
        return scheduleAService.getRMScheduleATemplate( opportunity ); 
        
      return( scheduleAService.getScheduleAList(this.id, true) );
      
   }

   public PageReference selectTemplateScheduleA()
   {
      PageReference pageReference = null;
      this.discountApplied = false;
      
      if( selectedServiceLine == DBnR || selectedServiceLine == RM  ) {
                 
          List<Schedule_A__c> scheduleAs = getScheduleATemplateList();
          if ( scheduleAs == null || scheduleAs.isEmpty() ){
              ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No ' + selectedServiceLine + ' templates exist' );
              ApexPages.addMessage(myMsg);
          } else {
              this.selectedScheduleAId = scheduleAs[0].id; 
              this.selectScheduleA(scheduleAs[0]); // This is setting the currentStepName to STEP_VIEW_PRICE_ADJUST
          }
          
      } else {        
          this.currentStepName = STEP_VIEW_SCHEDULE_A_TEMPLATES;
      }
      
      return(pageReference);
   }

   public PageReference stepScheduleAFromAccount()
   {
      PageReference pageReference = null;
      this.currentStepName = STEP_VIEW_SCHEDULE_A_ITEMS;
      return(pageReference);
   }

   public PageReference startUploadPAXMLFile()
   {
      PageReference pageReference = null;
      this.currentStepName = STEP_VIEW_UPLOAD_FILE;
      return(pageReference);
   }

   private final Set<String> excelExtensions = new Set<String>{'xls', 'xlsx', 'xlsb', 'xlsm'};
   public boolean isExcelFile(String filename){
      String extension = filename.substringAfterLast('.');
      return excelExtensions.contains(extension);
   }

   public PageReference stepUploadPAExcelFile()
   {
      PageReference pageReference = null;
      
      try
      {
          if( paEXCELFile != null && 
              paEXCELFile.Name != null && 
            paEXCELFile.name != '' &&
            isExcelFile(paEXCELFile.name)) 
          {
              String aName      = paXMLFile.name;

              if( aName != null )
              {
                  String prefixName = aName.substring(0, aName.indexOf('.'));   
                  String bName      = paExcelFile.Name; 
                  String bNamePrefix = bName.subString(0,bName.indexOf('.'));
                  if( prefixName == bNamePrefix)
                  {           
                      if( paEXCELFile.BodyLength != 0 )
                      {
                          try
                          {
                              Attachment attachment = new Attachment();
                              attachment.name       = paEXCELFile.name;
                              attachment.ParentId   = selectedScheduleA.id;
                              attachment.body       = paEXCELFile.body;
                              insert attachment;      
                                                                              
                              // Skip process approval for templates
                              if( selectedScheduleA.IsTemplate__c == true )
                              {
                                 // If standard discount pricing/template
                                 // then complete the wizard with no approvals 
                                 this.currentStepName = STEP_VIEW_UPLOAD_COMPLETE;
                                 
                                 // Update Schedule A status to approved
                                 selectedScheduleA.Status__c = 'Active';
                                 update selectedScheduleA;
                              }
                              else
                              {
                                 // Special discount pricing so process approval is 
                                 // requested
                                 this.currentStepName = STEP_VIEW_UPLOAD_FILE_APPROVERS;
                                  system.debug('selectedScheduleA.Approver_1_Title__c=='+selectedScheduleA.Approver_1_Title__c);
                                                                                 
                                  List<User> opportunitysupport=[SELECT Id, Name FROM User WHERE username like 'opportunitysupport@ironmountain%' limit 1];
                                  if(selectedScheduleA.Approver_1_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_1__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_2_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_2__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_3_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_3__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_4_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_4__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_5_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_5__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_6_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_6__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_7_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_7__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_8_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_8__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_9_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_9__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_10_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_10__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_11_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_11__c=opportunitysupport[0].Id;
                                  }
                                  else if(selectedScheduleA.Approver_12_Title__c=='Opportunity Support'){
                                      selectedScheduleA.Approver_12__c=opportunitysupport[0].Id;
                                  }
                                 
                                 
                                 selectedScheduleA.Pricing_Strategy__c = [SELECT Pricing_Strategy__c FROM Schedule_A__c Where Id=:selectedScheduleA.ID].Pricing_Strategy__c;
                              }
                          }
                          catch( Exception e )
                          {
                        
                              ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Error_Processing_Excel_Upload + '\n' + e );
                              ApexPages.addMessage(myMsg);                  
                              cancelUploadAction(); 
                          }
                      }
                      else
                      {
                         ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Excel_File_Is_Empty); 
                         ApexPages.addMessage(myMsg);
                      }
                  }
                  else
                  {
                     ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.File_Name_Does_Not_Match.replace('{!FILENAME}',prefixName));
                     ApexPages.addMessage(myMsg); 
                  }
              }
              else
              {
                 ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Excel_Name_Not_Specified);
                 ApexPages.addMessage(myMsg);                
              }
          }
          else
          {
             ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Excel_File_Must_Be_Specified);
             ApexPages.addMessage(myMsg);
          }
      }
      catch( Exception e )
      {         
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Exception_In_Upload);
          ApexPages.addMessage(myMsg);
          cancelUploadAction(); 
      }
      
      // Reset File
      paEXCELFile.body = null;      
      
      return(pageReference);
   }

   public PageReference viewScheduleA()
   {
      PageReference pageReference = null;
      System.debug('View Id ' + this.selectedScheduleAId );
      this.selectedScheduleA = scheduleAService.getScheduleA( this.selectedScheduleAId );
      return(pageReference);
   }

   public PageReference selectScheduleA() {
      return selectScheduleA(null);
   }
   public PageReference selectScheduleA(Schedule_A__c scheduleA )
   {
      
      PageReference pageReference = null;
      this.currentStepName = STEP_VIEW_PRICE_ADJUST;
      this.exemptBillingCodeMap = null; 
      this.dbrTypeMap = null;
      this.includedServiceTypes = null;
      List<PercentoffListBillcodes__c> billcodes = PercentoffListBillcodes__c.getall().values();
      List<Schedule_A_Quote_Item__c> quoteItemListbillcodes = new List<Schedule_A_Quote_Item__c>();
      List<Schedule_A_Quote_Item__c> quoteItemListbillcodesremove = new List<Schedule_A_Quote_Item__c>();
      
      this.selectedScheduleA = scheduleA == null ? scheduleAService.getScheduleA( this.selectedScheduleAId ) : scheduleA ;
      
      if(selectedServiceLine == RM && opportunity.Type == 'New Deal'){
         this.quoteItemList = selectedScheduleA == null ? new List<Schedule_A_Quote_Item__c>() : selectedScheduleA.Schedule_A_Quote_Items__r; 

          quoteItemListbillcodesremove= quoteItemList.clone();
          
          for(Integer j = quoteItemList.size() -1 ; j >= 0; j--){
               for(PercentoffListBillcodes__c b : billcodes){
                 if(b.Name == quoteItemList.get(j).product__r.Name){
                     quoteItemListbillcodesremove.remove(j);
                     quoteItemListbillcodes.add(quoteItemList[j]);
                }
             }
         }
    
         quoteItemList.clear();
         
         quoteItemList.addAll(quoteItemListbillcodes);
         quoteItemList.sort();
         quoteItemList.addAll(quoteItemListbillcodesremove);
         
         quoteItemListbillcodes.clear();
         quoteItemListbillcodesremove.clear();
         
      }
      else {
         this.quoteItemList = selectedScheduleA == null ? new List<Schedule_A_Quote_Item__c>() : selectedScheduleA.Schedule_A_Quote_Items__r; 
      }
      //this.quoteItemList = selectedScheduleA == null ? new List<Schedule_A_Quote_Item__c>() : selectedScheduleA.Schedule_A_Quote_Items__r;
      this.quoteItemListReference          = this.quoteItemList.deepClone(true);
      
      this.isErrorScheduleAQuoteItems = false;
      for(Schedule_A_Quote_Item__c aquoteItem : this.quoteItemList)
      {
            /*if(aquoteItem.proposed_volume__c == null ||
                      aquoteItem.proposed_volume__c == 0)
            {*/
                aquoteItem.proposed_volume__c = 1.00;
            //}
      }
            
      if (this.quoteItemList.size() != 0)
      {
         this.isErrorScheduleAQuoteItems = true;
              
      }
      else
      {
         ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ScheduleA_Missing_Quote_Items);
         ApexPages.addMessage(myMsg); 
      }
      
      if(selectedServiceLine == RM && opportunity.Type == 'New Deal'){
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,Label.PercentoffListBillcodes));      
      } 
      
      return(pageReference);
   }
   
   public PageReference includeQuoteCustomerAccounts()
   {
       PageReference pageReference = null;
       approvedPAModelCustomerAccounts = null;
       approvedPAModelCustomerAccountsWrapper = null;
       this.selectedScheduleA = scheduleAService.getScheduleA( this.selectedScheduleAId );
       this.currentStepName = STEP_VIEW_INCLUDE_QUOTE_CUSTOMER_ACCOUNTS;
       return pageReference;
       
   }
   
   public PageReference adjustScheduleAPrices()
   {
        system.debug(approvedPAModelCustomerAccountsWrapper);
        PageReference pageReference = selectScheduleA();
        this.currentStepName = STEP_VIEW_PRICE_ADJUST_QUESTION;
        this.previousStepsName.remove(this.previousStepsName.size() - 1);
        this.discountApplied = true;
        this.selectedServiceLine = null;
        
        return(pageReference);
   }
   
   public pageReference gotoNextStep()
   {

       this.currentStepName = STEP_VIEW_UPLOAD_FILE;
       return null;
       
   }
   
    public pageReference gotoPercentNextStep()
   {

       this.currentStepName = STEP_VIEW_SERVICE_LINES;
       return null;
       
   }
   
   public PageReference stepUploadPAXMLFile()
   {
          PageReference pageReference = null;
          
      try
      {
          if( paXMLFile != null && 
              paXMLFile.Name != null && paXMLFile.Name != '' )
          {
              if(paXMLFile.BodyLength != 0 )
              {
                  if (IRM_ScheduleAService.checkFileIsUploaded(paXMLFile.Name) == this.isReaploadFile)
                  {
                      selectedScheduleA = IRM_ScheduleAParseXML.parseXML( paXMLFile.Name, 
                                                                          paXMLFile.Body.toString(),
                                                                          opportunity.id );
                                                                                
                      system.debug('==========>'+IRM_ScheduleAParseXML.INVALID_ACCOUNTS);
                      if(IRM_ScheduleAParseXML.INVALID_ACCOUNTS != null && IRM_ScheduleAParseXML.INVALID_ACCOUNTS.size() != 0 )
                      { 
                            this.currentStepName = STEP_VIEW_CUSTOMER_ACCOUNT_GENERATION_ERROR;
                            return cancelUploadAction();
                      }
                      if( selectedScheduleA != null && selectedScheduleA.id != null )
                      {                        
                          this.currentStepName = STEP_VIEW_UPLOAD_EXCEL_FILE;
                      }
                      else
                      {
                          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.ScheduleA_Not_Created);
                          ApexPages.addMessage(myMsg);
                      }
                  }
                  else
                  {
                      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.File_Already_Uploaded);
                      ApexPages.addMessage(myMsg);                    
                      cancelUploadAction();                       
                  } 
              }
              else
              {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.File_Is_Empty);
                ApexPages.addMessage(myMsg);
              }
          }
          else
          {
              ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.XML_File_Must_Be_Specified);
              ApexPages.addMessage(myMsg);          
          }
      }
      catch( Exception e )
      {         
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Exception_In_Upload);
          ApexPages.addMessage(myMsg);
          cancelUploadAction(); 
      } 

      // Reset to null to fix VF viewstate issue
      paXMLFile.body = null;

      return(pageReference);
   }
   
   public PageReference savePAFileApprovers()
   {
      PageReference pageReference = null;
      ApexPages.Message myMsg = null;
    
      if( selectedScheduleA != null && 
          selectedScheduleA.id != null )
      {
        Boolean validApprovers = true;
        for (Integer i = 1; i <= MAX_APPROVERS; i++){
            if( selectedScheduleA.get('Approver_'+i+'_Title__c') != null && 
                  selectedScheduleA.get('Approver_'+i+'_Title__c') != '' &&
                  selectedScheduleA.get('Approver_'+i+'__c') == null )
              {
                  myMsg = new ApexPages.Message( ApexPages.Severity.ERROR,System.Label.Missing_Approver_To_Continue.replace('{!ApproverNumber}',String.valueOf(i))); 
                  ApexPages.addMessage(myMsg);   
                  validApprovers = false;
                  break;                
              }
              
        }
        if (validApprovers){
              // Save Approvers 4 & 5
              update selectedScheduleA;                     
            
              // create the new approval request to submit
              Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
              req.setComments(System.Label.Submitted_for_Approval_Automatic); 
              req.setObjectId(selectedScheduleA.Id);
              
              // submit the approval request for processing
              Approval.ProcessResult result = Approval.process(req);
              
              myMsg = new ApexPages.Message( ApexPages.Severity.INFO, 
                                            System.Label.Submitted_for_Approval_Automatic);
              ApexPages.addMessage(myMsg);
              
              this.currentStepName = STEP_VIEW_UPLOAD_COMPLETE;       
        }     
      }
      else
      {
          myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Valid_Schedule_A_Missing);
          ApexPages.addMessage(myMsg);
      }
      return( pageReference );      
   }

   public PageReference createQuoteFromScheduleA()
   {
      PageReference pageReference = null;
      
      //If the percent off pricing is set and the discout field is populated
      //Then set the appropriate fields on the scheduleA
      //Which will then get pulled over to the quote
      system.debug('percentOffPricing'+this.percentOffPricing);
      if( null != this.percentOffPricing && this.percentOffPricing )
      {
          if(selectedServiceLine == RM && isDecimal(this.discountRM)){
             this.selectedScheduleA.RM_List_Price_Discount__c = Decimal.valueOf(this.discountRM);
          } else if (isDecimal(this.discountService) && isDecimal(this.discountStorage) ){
             this.selectedScheduleA.DBR_Service_List_Price_Discount__c = Decimal.valueOf(this.discountService);
             this.selectedScheduleA.DBR_Storate_List_Price_Discount__c = Decimal.valueOf(this.discountStorage);
          }
      }
      system.debug('selectedScheduleA'+this.selectedScheduleA);
      this.quote = this.scheduleAService.createQuoteFromScheduleA( this.id, this.selectedScheduleA, this.percentOffPricing, this.ProposedVolume, this.ProposedPrice, this.selectedServiceLine);
      system.debug('quotecheck'+quote);
      if( quote != null && quote.id != null )
      {
         ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, System.Label.Quote_Created_Successfully);
         ApexPages.addMessage(myMsg);
        
         this.currentStepName = STEP_VIEW_QUOTE_COMPLETE;
      }      
      return(pageReference);
   }

   public PageReference saveScheduleAPrices()
   { 
      PageReference pageReference = null;
      this.percentOffPricing = false;
      // Check if any errors other wise display existing page with errors. 
      if( !ApexPages.hasMessages() )
      {
          //Case number: soon
          try{
            system.debug('+++++++++update list++++++++'+quoteItemList);
             system.debug('percentOffPricing'+this.percentOffPricing);
            if(null != this.percentOffPricing && !this.percentOffPricing) {
                update this.quoteItemList;
            }       
            createQuoteFromScheduleA();
          }
          catch(DmlException ex){
                 this.quoteItemList  = scheduleAService.getScheduleAQuoteItemList( this.selectedScheduleAId );
                 ApexPages.Message myMsg = new ApexPages.Message( ApexPages.Severity.ERROR,ex.getDmlMessage(0));
                 ApexPages.addMessage(myMsg); 
          }
         
         /*
         * Changes made by : Brinal Pereira
         *to populate the customer AccountIds when we upload an XML and the customer Accounts are not populated from browser.
         */
         
         if(customAccountIDs == null || customAccountIDs.isEmpty())
             customAccountIDs.addAll(Pluck.strings('Id', approvedPAModelCustomerAccounts)); 

         /*Changes made by Brinal 
         * Commented changes made to create a Quote Customer Account
         */
         Savepoint sp = Database.setSavepoint();
         try 
         {
             Set<Id> existingScheduleACustomerAccountIds = Pluck.ids('Customer_Account__c', scheduleAService.getScheduleACustomerAccounts(this.selectedScheduleAId));
             List<Quote_Customer_Account__c> quoteCustomerAccountJunctionsToInsert = new List<Quote_Customer_Account__c >();
             List<Schedule_A_Customer_Account__c> customerAccountJunctionsToInsert = new List<Schedule_A_Customer_Account__c>();
             if(approvedPAModelCustomerAccountsWrapper != null && (!approvedPAModelCustomerAccountsWrapper.isEmpty()) && (this.quote != null) )
             {
                 for(PAModelCustomerAccountsWrapper aWrap : approvedPAModelCustomerAccountsWrapper)
                 {
                     if(!existingScheduleACustomerAccountIds.contains(aWrap.customerAccount.Id))
                         customerAccountJunctionsToInsert.add(new Schedule_A_Customer_Account__c(Schedule_A__c = this.selectedScheduleAId, Customer_Account__c = aWrap.customerAccount.Id ));
                     quoteCustomerAccountJunctionsToInsert.add(new Quote_Customer_Account__c(Schedule_A__c = this.quote.id, Customer_Account__c = aWrap.customerAccount.Id, Schedule_A_Document__c = aWrap.includeInScheduleADocument ));
                 }
             }
             else if(customAccountIDs != null && (!customAccountIDs.isEmpty()) && (this.quote != null)) {
                
                for(string customAccountID : customAccountIDs){
                    if(customAccountID != null && customAccountID != '') {
                        if(!existingScheduleACustomerAccountIds.contains(customAccountID))
                            customerAccountJunctionsToInsert.add(new Schedule_A_Customer_Account__c(Schedule_A__c = this.selectedScheduleAId, Customer_Account__c =customAccountID));
                        quoteCustomerAccountJunctionsToInsert.add(new Quote_Customer_Account__c(Schedule_A__c = this.quote.id, Customer_Account__c =customAccountID));
                    }
                }
                
            }
            if(!quoteCustomerAccountJunctionsToInsert.isEmpty())
                insert quoteCustomerAccountJunctionsToInsert;
            if(!customerAccountJunctionsToInsert.isEmpty())
                insert customerAccountJunctionsToInsert;
        }
        catch (DmlException ex){
                
                ApexPages.Message myMsg = new ApexPages.Message( ApexPages.Severity.ERROR,'test' + ex.getDmlMessage(0));
                ApexPages.addMessage(myMsg);
                
                Database.rollback(sp);
        }
        
      //   this.quote = this.scheduleAService.createQuoteFromScheduleA( this.id, this.selectedScheduleA);         
      }
 
      return(pageReference);
   }

   public PageReference cancelAction()
   {
      PageReference pageReference = null;
      this.currentStepName = STEP_VIEW_MAIN;
      return(pageReference);
   }
   
   public PageReference back() {
      PageReference pageReference = null;
      system.debug(previousStepsName+'===prevS==='+previousStepsName.size());
      if(this.previousStepsName.size() > 0){
          this.currentStepName = this.previousStepsName.remove(previousStepsName.size() - 1);
          this.previousStepsName.remove(previousStepsName.size() - 1); // The currentStepName adds its own name back onto the list, and we want to remove it.       
      }
      
      
      if( this.previousStepsName.isEmpty() ) {
          this.previousStepsName.add(STEP_VIEW_MAIN);
      }
      
      return pageReference;
   }
   
   public pageReference applyApprovedDiscount() {
       PageReference pageReference = null;
       system.debug(logginglevel.info, '++@@@@1111 '+ quoteItemList );
       for( Schedule_A_Quote_Item__c item : quoteItemList){
       system.debug(logginglevel.info, '++@@@@ '+ item.Floor_Price__c );
           if(item.List_Price__c != null) { 
               if(! IRM_ScheduleAService.validateDiscountWithExemptList(item.Product__r.Name)){
                 
                   Double discountToApply;
                   
                   String discountType = IRM_ScheduleAService.getDiscountType( item );
                   system.debug(logginglevel.info, '+++ discount type is +++ '+ discountType );
                   if( discountType == IRM_ScheduleAService.STORAGE && isDecimal(discountStorage)){
                       discountToApply = Decimal.valueOf(discountStorage) ;
                   } else if( discountType == IRM_ScheduleAService.SERVICE && isDecimal(discountService)){
                       discountToApply =  Decimal.valueof(discountService);
                   } else if (discountType == RECORDS_MANAGEMENT && isDecimal(discountRM)) {
                       discountToApply =  Decimal.valueof(discountRM);
                   }
                  
                   if(discountToApply != null) {
                       Double discountPercentage = (100 - discountToApply) / 100;
                       Double newPrice =  item.List_Price__c * discountPercentage;
                       item.Proposed_Price__c = Math.Max(newPrice, (item.Floor_Price__c == null ? 0 : item.Floor_Price__c) );
                   }
                   
               } else {
                  system.debug('%%%%%'+item.List_Price__c+'----'+item.Floor_Price__c);
                  System.debug(LoggingLevel.ERROR, item.List_Price__c+'----'+item.Floor_Price__c);
                   item.Proposed_Price__c = Math.Max(item.List_Price__c,item.Floor_Price__c);
               }
              
           }
       }
       
       
       return pageReference;
   }

   public PageReference applyRMDiscount(){
       
       PageReference pageReference = null; 
       List<PercentoffListBillcodes__c> billcodes = PercentoffListBillcodes__c.getall().values();
       system.debug('billcodes'+billcodes);
       Double volume= 0.00;
       ProposedVolume= 0.00;
       ProposedPrice= 0.00;
       for( Schedule_A_Quote_Item__c item : quoteItemList){
             for(PercentoffListBillcodes__c b : billcodes){
                 if(item.product__r.Name == b.Name){
                     volume += item.Proposed_Volume__c;
                 }
            }
     
       }
       system.debug('ProposedVolume'+ProposedVolume);
       system.debug('ProposedPrice1'+ProposedPrice);
       system.debug('volume'+volume);
       system.debug('volume - 1'+Integer.valueOf(Label.Billcodes_Volume));
       system.debug('Type'+opportunity.Type);
       if(volume <= Integer.valueOf(Label.Billcodes_Volume) && opportunity.Type == 'New Deal'){
           discountApplied = false;
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.PercentoffListBillcodes)); 
         }
       else if(volume > 19999 && opportunity.Type == 'New Deal'){
           discountApplied = false;
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.PercentoffListBillcodesTier3)); 
         }
       else{
            
       discountApplied = true;
       Decimal maxRM = PercentoffListLimits__c.getAll().get('RM').off_List_Limit__c;
       if( isDecimal(this.discountRM) && maxRM  > Decimal.valueOf(this.discountRM) ){
           for( Schedule_A_Quote_Item__c item : quoteItemList){
               if(item.List_Price__c != null) { 
                   if(! IRM_ScheduleAService.validateDiscountWithExemptList(item.Product__r.Name)){
                    system.debug(logginglevel.info, '+++ inside if and product is +++ ' +item.Product__r.Name);
                       system.debug(logginglevel.info, '+++ discount RM is +++ ' +this.discountRM);
                       Double newPrice = (100 - Decimal.valueOf(this.discountRM) );
                       system.debug(logginglevel.info, '+++ newPrice 1  is +++ ' +newPrice );
                       newPrice = (newPrice == 0 ) ? 0 : newPrice / 100;
                       system.debug(logginglevel.info, '+++ newPrice 2  is +++ ' +newPrice + '+++ floor price is +++' + item.Floor_Price__c);
                       item.Proposed_Price__c = Math.max(item.Floor_Price__c, item.List_Price__c  * newPrice);
                       system.debug(logginglevel.info, '+++  item.Proposed_Price__c  is +++ ' + item.Proposed_Price__c);
                   } else {
                    system.debug(logginglevel.info, '+++ inside else +++ and product is '+item.Product__r.Name);
                       item.Proposed_Price__c = item.List_Price__c;
                   }
                    system.debug(logginglevel.info, '+++ proposed price is  +++ ' + item.Proposed_Price__c );
               }
           }
       } else if (isDecimal(this.discountRM) && maxRM  <= Decimal.valueOf(this.discountRM) ) {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.off_List_Limit));
         }
     
       for( Schedule_A_Quote_Item__c item : quoteItemList){
             for(PercentoffListBillcodes__c b : billcodes){
                 if(item.product__r.Name == b.Name && item.Proposed_Volume__c > 1){
                         this.ProposedVolume += item.Proposed_Volume__c;
                         this.ProposedPrice += item.Proposed_Volume__c * item.Proposed_Price__c;
                         system.debug('ProposedPrice'+ProposedPrice);
                }
            }
    }
      } 
        return pageReference;   
   }
   
   public PageReference applyDbrDiscount(){
       PageReference pageReference = null;
       discountApplied = true;
       
       Map<String, PercentoffListLimits__c> storageLimits =PercentoffListLimits__c.getAll();
       
       Decimal maxStorage = (storageLimits.get('DBRStorage') != null) ? storageLimits.get('DBRStorage').off_List_Limit__c : 0;  
       Decimal maxService = (storageLimits.get('DBRService') != null) ? storageLimits.get('DBRService').off_List_Limit__c : 0;  
       system.debug('1===>'+maxStorage+':'+maxService);
       if( (isDecimal(this.discountStorage) && maxStorage  > Decimal.valueOf(this.discountStorage)) 
           || (isDecimal(this.discountService) && maxService > Decimal.valueOf(this.discountService)) ){
           for( Schedule_A_Quote_Item__c item : quoteItemList){
               system.debug('list price ===>'+item.List_Price__c);
               if( (!IRM_ScheduleAService.validateDiscountWithExemptList(item.Product__r.Name)) && (item.List_Price__c !=null) ){
                   
                   Double discountToApply;
                   
                   String discountType = IRM_ScheduleAService.getDbrDiscountType( item.Product__r.Name.toLowerCase() );
                   system.debug('2===>'+discountType+':'+this.discountStorage);
                   if( discountType == null ){
                       continue;
                   } else if(discountType == IRM_ScheduleAService.STORAGE && isDecimal(discountStorage) 
                           && (maxStorage  > Decimal.valueOf(this.discountStorage)) ){
                       discountToApply =  Decimal.valueOf(discountStorage) ;
                   } else if(discountType == IRM_ScheduleAService.SERVICE && isDecimal(discountService)
                           && (maxService  > Decimal.valueOf(this.discountService))){
                        discountToApply =  Decimal.valueOf(discountService);
                   }
                   system.debug('3===>'+discountToApply);
                   if(discountToApply != null ) {
                      Double percentOfListPrice = (100 - discountToApply );
                      percentOfListPrice = (percentOfListPrice == 0 ) ? 0 : percentOfListPrice / 100;
                      item.Proposed_Price__c = Math.max(item.Floor_Price__c, item.List_Price__c  * percentOfListPrice);
                   }
               }
               else if( item.List_Price__c == null )
               {
                   item.Proposed_Price__c = 0;
               }
               system.debug('item.Proposed_Price__c===> '+item.Proposed_Price__c );
           }
       }
       if( (isDecimal(this.discountStorage) && maxStorage  <= Decimal.valueOf(this.discountStorage))
                  || (isDecimal(this.discountService) && maxService <= Decimal.valueOf(this.discountService))
       ){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.off_List_Limit));
       }
       return pageReference;
   }

   public PageReference cancelUploadAction()
   {
      PageReference pageReference = null;

      // Start at beginning
      
      /*try
      {*/
          if( selectedScheduleA != null && selectedScheduleA.id != null )
          {
             // Delete previous uploaded schedule A
             delete selectedScheduleA;
          }
      /*}
      catch( Exception e )
      {
        // issue deleting  
      }     */
      return(pageReference);
   }
   
   public static boolean isDecimal (String str){
       if (str == null) return false;
       
       str = str.replaceFirst('[.]', '');
       return str.isNumeric();
   } 
   
    /*Updated to Assign Case to "IM Employees Support Cases IMNA Queue" Queue for case#07921834*/
   
   public PageReference createNewCase()
   {
       String strDescription = 'Can you please add the following acquired customer account ID(s) to Salesforce as quickly as possible ' +
                        'as Customer is awaiting Schedule A pricing Document.'+'\n\nCustomer Account ID(s) : ';
       strDescription += invalidCustomerAccounts;
       PageReference pageRef;
       Case createCase = new Case();
       try
       {
           Group grp = [SELECT Id, Name from Group where Group.Type = 'Queue' AND Group.id =: system.Label.IM_Employees_Support_Cases_IMNA_Queue limit 1];
           system.debug('Group Id:'+grp.id);
           createCase = new Case(subject='Acquistion',
                                recordtypeid = IRM_ScheduleAService.supportCase_IM.Id,  
                                Description = strDescription, 
                                IM_Employee_Contact__c = System.UserInfo.getUserId(),
                                Related_To__c = 'Customer Account/Client Code',
                                Issue__c = 'Create/Import Records',
                                Origin = 'Internal',
                                IM_Division__c = 'IMNA',
                                Priority = 'Critical'
                                );  
                                system.debug('Group Id Before inserting case :'+createCase.OwnerId );                 
           insert createCase;
           createCase.ownerId = grp.Id;
           update createCase;
           caseCreated = [SELECT ID, CaseNumber FROM Case WHERE Id = :createCase.Id];
           this.currentStepName = STEP_VIEW_CASE_CREATED;
           pageRef = null;
       }
       catch(DMLException ex)
       {
           ApexPages.addMessages(ex);
           pageRef = null;
           System.debug('Exception: ' + ex);

       }
       return pageRef;
       
   }
   
    public PageReference viewCase()
   {
       system.debug('====> in case');
       return new PageReference('/'+ caseCreated.Id);
   }
   
   public class PAModelCustomerAccountsWrapper
   {
       public IM_Customer_Account__c customerAccount { get; set; }
       public String includeInScheduleADocument { get; set; }
       
       public PAModelCustomerAccountsWrapper(IM_Customer_Account__c custAcct)
       {
           customerAccount = custAcct;
       }
   }
}
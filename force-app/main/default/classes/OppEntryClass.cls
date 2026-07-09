/*
**Author: Raj Gottipolu
**Date: 10/31/11
**Company: HCL America
**     
**Author       : Ketan Benegal
**Company      : CloudFountain Inc.
**Modified Date: 18-Apr-2012
**Case No.     : 00606912
**Description  : Opportunity Wizard 1.05-Existing lead data-mapping into Wizard
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 04/22/2013; Srinivasa Rao/Randstad; Gov't Opportunity Management - Display GSA Questions (Case # 00426534); Initial release
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 05/15/2013; Srinivasa Rao/Randstad; Opty Wizard Enhancement - Option to Display List price in Wizard (Case # 01328663); Initial release
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 08/07/2013; Srinivasa Rao/Randstad; Opty Wizard Enhancement - GSA Modification (Case # 01622446); Initial release
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 08/07/2013; Srinivasa Rao/Randstad; Opty Wizard Enhancement - Contact Search (Case # 01654528); Initial release
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 09/16/2013; Srinivasa Rao/Randstad; Opty Wizard Enhancement - Contact Search warning message(Case # 01743451); Initial release
** 
**  CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.1; 05/02/2014; Venkateswarlu Avula/IMS; Oppty Entry Wizard - Contact Role Expansion(Case # 02424305); Change Request
**
**  CHANGE LOG
**    [[Version; Date; Author; Project/Case; Description]]
**    v2.0; 04/24/2015; Sandhya Ramesh/IMS; Case # 03474925; Wizard enhancement -- Competitively vended fields and Competitor screen.
**
**  CHANGE LOG
**    [[Version; Date; Author; Project/Case; Description]]
**    v2.1; 05/04/2015; Sandhya Ramesh/IMS; Case # 03408939; Wizard enhancement -- Do not display GSA if running user's Sales Sub Segment is'Government'.
*
**  CHANGE LOG
**    [[Version; Date; Author; Project/Case; Description]]
**    v2.1; 01/15/2016; Sandhya Ramesh/IMS; Case # 03250416; Wizard enhancement -- Rate x Quantity.
*
*   CHANGE LOG
**  Case# 05491582, Added by pratap, We want to retain the ability for drivers to submit sales leads, 
**  so we must create a new mechanism for them to record the lead information and transmit it 
**  to IRM sales systems

    Modified by  : Vinutha Iyengar
    Modified Date: June 05, 2019
    Case: 09154470 - Lighting Pilot 
    Description: Lightning NA users will not be redirected to Opportunity add wizard.

*/      
public with sharing class OppEntryClass {
    
    public Date schOppClosedDate;    
    public string StrGSAElibility; 
    public Integer recur =1; 
    public Integer i=0, j=0, k=0, l=0, v=0, x=0, s=0, t=0, num=0, inte=null, a=0, b=0, c=0, z=0, add=0;
    public Boolean oppdetails=true;
    public Boolean otherinformationdisplay=false;
    public Boolean roleselectblock=false;
    public Boolean othererror=false;
    public Boolean emptybundles=false;
    public String otherinformation=null; 
    public Boolean contactdisplay=false;
    public Boolean highleveldisplay=false;
    public Boolean leadaccounterror=false;    
    public String sublead=null;
    public Boolean bundlemsg=false;
    public Boolean conrolerror=false;
    public Boolean leadoppnextdisplay=true;
    public Boolean conleadbackdisplay=true;
    public Boolean emptyproductlist=false;
    public Boolean emptyprodlist=false;
    public Boolean emptynewprodlist=false;
    public Boolean leadoppsavedisplay=false;
    public Boolean bundleexists=false;
    public Boolean bundleproductlistdisplay=false;
    public Boolean bundlelistdisplay=false;
    public Boolean questionblockrender=null;
    public String dupevalue=null;    
    public Boolean fromnewlist=false;
    public Boolean questionsavedisplay=false;
    public Boolean questionsbackdisplay=true;
    public Boolean questionsnextdisplay=true;
    public Boolean addprods=false;
    public Boolean displaydetailsdisplay=true;
    public Boolean backtoquestionsdisplay=true;
    public Boolean addprodline=false;
    public Boolean emptyprodlines=false;
    public Boolean addprimaryprod=false;
    public Boolean contactbackbuttondisplay=false;
    public Boolean productsavebuttondisplay=false;
    public Boolean overwriteverify=false;
    public Boolean oppsavedisplay=false;
    public Boolean overwriterror=false;
    public Boolean oppnextdisplay=true;
    public Boolean oppcanceldisplay=true;
    public Boolean consavedisplay=true;
    public Boolean conbackdisplay=true;
    public Boolean conchangedisplay=false;
    public Boolean granularleveldisplay=false;
    public Boolean questionerror=false;
    public Boolean oppbackbuttondisplay=false;
    public Boolean pricebookdisplay=false;
    public Boolean secproselectdisplay=false;
    public Boolean pricebookexists=false;
    public Boolean pricebookerror=false;
    public Boolean location=false;
    public Boolean checkbox=false;
    public Boolean bundlequestiondisplay=false;
    public Boolean addproductsdisplay=false;
    public Boolean secprodisplay=false;
    public Boolean questionverify=false;
    public Boolean conroleselectblock=false;
    public Boolean newcontactdisplay=false;
    public Boolean questiondisplay=false; 
    public Boolean contacterror=false;
    public Boolean runwizard = false;
    public Boolean newcon=false;
    public Boolean oldcon=false;
    public Boolean secproerror=false;
    public Boolean quantityexists=true;
    public Boolean finaldetailsdiplay=false;
    public boolean VendedSecDisplay= false;
    public boolean enableCode = true;
    
    public string leadcontEmail = null;
    public String sample = null;
    public String oppname=null;
    public String profilename=null;
    public String leadaccountname=null;
    public String leadopportunityname=null;
    public String leadstatus=null;
    public String oppowner=null;
    public String strStage=null;
    public String accname=null;
    public String accbillingstreet=null;
    public String accbillingcity=null;
    public String accbillingstate=null;
    public String accdescription=null;
    public String accwebsite=null;
    public String accindustry=null;
    public String accbillingpostalcode=null;
    public String accemployees=null;
    public String accphone=null;
    public String accrevenue=null;
    public String rolestring=null;
    public String oppdescription = null;
    public String usercurrency=null;
    public String oppleadsource=null;
    public String priceoverride=null;
    public String quantityoverride=null;
    public String name=null;
    public String leadname=null;
    public String strStatus;
    public String strSubject1;
    public String strAccount;
    public String strPriority;
    public Date dtDate;
    public String strDesciption;
    public DateTime dtDateTime;
    public String tsksubject=null;
    public String tskstatus=null;
    public String tskpriority=null;
    public String tskactivitydate;
    public String tskdescription=null;
    public Integer price=0;
    public Integer quantity=0;
    public String secondaryproductquestion=null;
    public String prodgroup=null;    
    public Id prodgroupId;
    public String existingaccountname=null;
    public String existingcontactname=null;
    public Id id, pricebookid, contactid, newpricebookid, existaccid, existconid, leadownerid, oppaccid, oppconid, insertedoppid, leadid, ownerid, campid;
    public String selectedpg=null;
    public String selectedpb=null;
    public String selectedbundle=null;
    public String selectedbundletype=null;
    public String recTy, sendmail;
    public Contact contact, conew, conew1, conew2;
    public Account ac;
    public Product_Bundle__c Newbundle;
    public Opportunity opportunity ;
    public Opportunity leadopportunity;
    public Task tsk;
    public OpportunityContactRole ocr;
    public List<Product2> productids = new List<Product2>();
    public List<Decimal> Pricelist = new List<Decimal>();
    public List<Integer> Quantitylist = new List<Integer>();
    public List<Decimal> Totalpricelist = new List<Decimal>();
    public List<Product2> addproductids = new List<Product2>();
    public List<Product2> testlist = new List<Product2>();    
    public List<Id> clids = new List<Id>();
    public List<SelectOption> bundleslist = new List<SelectOption>();
    public List<PricebookEntry> pricebookentries = new List<PricebookEntry>();
    public List<PricebookEntry> newpricebookentries = new List<PricebookEntry>();
    
    List<Opportunity_Product_Wizard_Settings__c> wizardsettings = Opportunity_Product_Wizard_Settings__c.getall().values();    
    public Lead sObjLead{get;set;}
    public String defaultSalesEvent{get;set;}
    // public String compvended{get;set;}
    // public Decimal unvendedperc{get;set;}
    // public Decimal vendedperc{get;set;}
    public Contact sObjContact{get;set;}
    
    /*Developer Name: Sandhya Ramesh 
Case Number   : 03408939
Description   : Do not display GSA questions if the running user's Sales Sub Segment is 'Government'. 
*/
    /*Start*/
    public boolean finalgsadetails = false;
    ID runningUserId = userinfo.getUserId();
    User runningUser = [select Id, sales_sub_segment__c FROM User WHERE ID=: runningUserId limit 1];
    String govtSegUser = (String) runningUser.sales_sub_segment__c;
    public String canOpp{get; set;}
    /*End*/
    
    
    /*Developer Name: Srinu Mandalapu 
Case Number   : 00426534
Description   : Viariable declaration for Gov't Opportunity Management - Display GSA Questions. 
*/
    /*Start*/
    public Boolean gsaquestionblockrender=null;
    public Boolean getgsaQuestionblockrender(){return gsaquestionblockrender;}
    public Boolean gsaquestionsavedisplay=false;
    public Boolean getgsaQuestionsavedisplay(){return gsaquestionsavedisplay;}
    public Boolean GSAQuestiondisplay=false;
    public Boolean getGSAQuestiondisplay(){return GSAQuestiondisplay;}
    public Boolean showfinalpage=false;
    public Boolean isExecuteGSAtestWrap=false;
    public static boolean isThisGovtOpportunity = false;
    public static boolean isThisNARACFROpportunity = false;
    public static boolean isThisGovtContact = false;
    public static boolean isOpportunityMeetsGSA = false;
    public String govopty{get;set;}
    public String contDomain{get;set;}    
    public Boolean ContactThruNotFound=false;   
    public Boolean ContactThruNotFound2=false; 
    public boolean finalDispBackVended= false;
    public boolean finalDispBackLeadVended= false;
    Public boolean isLightningUser = false;
    /*End*/
    
    /*Developer Name: Srinu Mandalapu 
Case Number   : 01654528
Description   : Viariable declaration for Contact Search. 
*/
    /*Start*/
    public  String ContactSearchString{get{
        if(ContactSearchString==null){
            ContactSearchString='';
            return ContactSearchString;
        }
        return ContactSearchString;
    }
                                       set;}
    public static Boolean ContactSearchErrorDisplay=false;     
    public Boolean getContactSearchErrorDisplay(){return ContactSearchErrorDisplay;}                                     
    /*End*/
    
    /*Case Number: 01389380
Description: Added logic to add competitor on opportunity wizrad
*/
    Opportunity_Competitor__c oppcomp;
    //getter method for oppcomp
    public Opportunity_Competitor__c getOppcomp(){
        if(oppcomp==null)
            oppcomp=new Opportunity_Competitor__c();
        return oppcomp;
    }
    
    public OppEntryClass(ApexPages.StandardController controller) {
        sendmail=ApexPages.currentPage().getParameters().get('em');
        System.debug('-----166------sendmail:'+sendmail);
        campid=ApexPages.currentPage().getParameters().get('campid');
        System.debug('-----168------campid:'+campid);
        leadid=ApexPages.currentPage().getParameters().get('leadid');
        System.debug('-----170------leadid:'+leadid);
        oppaccid=ApexPages.currentPage().getParameters().get('straccname');
        System.debug('-----172------oppaccid:'+oppaccid);
        strStage=ApexPages.currentPage().getParameters().get('strStage');
        System.debug('-----174------strStage:'+strStage);
        existaccid=ApexPages.currentPage().getParameters().get('accid');
        System.debug('-----176------existaccid:'+existaccid);
        existconid=ApexPages.currentPage().getParameters().get('conid');
        System.debug('-------178----existconid:'+existconid);
        /*Ketan Benegal - Commented out the following line. leadaccountname will be assigned value of leadAccountName.
parameter leadAccountName will contain the account name for a contact or an account.
It is passed from leadCustomMergeController or LeadController.
*/
        leadAccountName=ApexPages.currentPage().getParameters().get('leadAccountName');
        //leadaccountname=ApexPages.currentPage().getParameters().get('accname');
        System.debug('-----180------leadaccountname:'+leadaccountname);
        leadopportunityname=ApexPages.currentPage().getParameters().get('oppname');
        System.debug('-----182------leadopportunityname:'+leadopportunityname);
        leadstatus=ApexPages.currentPage().getParameters().get('status');
        System.debug('-----184------leadstatus:'+leadstatus);
        dupevalue=ApexPages.currentPage().getParameters().get('dupe');
        System.debug('-----186------dupevalue:'+dupevalue);
        oppconid=ApexPages.currentPage().getParameters().get('strconname');
        System.debug('------188-----oppconid:'+oppconid);
        leadownerid=ApexPages.currentPage().getParameters().get('ownerId');
        System.debug('-----190------leadownerid:'+leadownerid);
        /*Srinu/Madhu: Since No Parameter has been passing with Name 'Owner'. So Commented out on 12/11*/
        //ownerid=ApexPages.currentPage().getParameters().get('owner');
        govOpty= ApexPages.currentPage().getParameters().get('govOpty');
        System.debug('---------govopty:'+govopty);
        contDomain=ApexPages.currentPage().getParameters().get('contDomain');
        System.debug('---------contDomain:'+contDomain);
        System.debug('-----194------leadid:'+leadid +'\tleadownerid:'+leadownerid);
        if(leadid==null || leadownerid==null)
        {
            oppowner=UserInfo.getName();
            usercurrency = UserInfo.getDefaultCurrency();
            System.debug('----executing------');              
        }
        else
        {   
            
            
            sObjLead = [select  IsConverted,Owner.Name, Name, LastName, FirstName, Company, Street,City,State,PostalCode,
                        NumberOfEmployees,AnnualRevenue,Country, Industry,Description,Phone,Website,MobilePhone,Email,Title,Fax,
                        LeadSource, CurrencyIsoCode, IM_Sales_Event__c,Competitively_Vended__c/* #16915 Unvended__c,Vended__c*/
                        from Lead where Id =:leadid];          
            
            usercurrency = sObjLead.CurrencyIsoCode;
            leadcontEmail = sObjLead.Email;  
            oppowner=sObjLead.Owner.Name;
            
          
            if(sObjLead.IM_Sales_Event__c != '')
                defaultSalesEvent = sObjLead.IM_Sales_Event__c;
            else{            
                defaultSalesEvent = '';
            }
            
            sObjLead.Competitively_Vended__c = null;
            /* #16915 sObjLead.Unvended__c = null;
            sObjLead.Vended__c = null; */
            
            /*   if(sObjLead.Competitively_Vended__c != null)
compvended = sObjLead.Competitively_Vended__c;
if(sObjLead.Unvended__c != null)
unvendedperc = sObjLead.Unvended__c;
if(sObjLead.Vended__c != null)
vendedperc = sObjLead.Vended__c; */
            
        }
        if(dupevalue=='true'){          
            if(sObjLead != null){
                usercurrency = sObjLead.CurrencyIsoCode;
                defaultSalesEvent = sObjLead.IM_Sales_Event__c;
            }              
        }       
        
        //Madhu: Instead of two SOQL's on Account & Contact, Written a single SOQL on Contact and retrieving the data from DB. 
        /*START*/
        if(existconid!=null){
            sObjContact =[select Name,account.Name,AccountId  from Contact where id=:existconid];
            if(sObjContact.AccountId == existaccid)    existingaccountname=sObjContact.account.Name;
            existingcontactname = sObjContact.Name;
        }
        else{               
            existingaccountname=null;
            existingcontactname = null;              
        }
        /*END*/  
        
        Profile prof = [Select Name from Profile where id =: UserInfo.getProfileId()];
        profilename = prof.Name;        
        //Checking the product group for a product from custom settings.
        for(Opportunity_Product_Wizard_Settings__c ops : wizardsettings){                        
            if(profilename == ops.Profile_Name__c) {                
                prodgroup = ops.Product_Group_Name__c;                
                Pricebook2 prodgrpname = [Select Id from  Pricebook2 where Name=:prodgroup];                
                prodgroupId = prodgrpname.Id;
                runwizard=true;
            }
        } 
        
        //check if user is using lightning or classic
        for (User u: [SELECT Id, UserPreferencesLightningExperiencePreferred FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1])
        {
            isLightningUser = u.UserPreferencesLightningExperiencePreferred;
        }
        
        system.debug('isLightningExperience=='+isLightningUser);
        
        if(isLightningUser){runwizard=false;}
    }
    /* Added by Pratap,Case: Case 05711602 */
    public Boolean getVendedSecDisplay(){
        return VendedSecDisplay;
    }
    
    /* Added by Pratap */
    public Boolean getOthererror(){return othererror;}
    public Boolean getRunwizard(){return runwizard;}
    public Boolean getContacterror(){return contacterror;}
    public Boolean getNewcontactdisplay(){return newcontactdisplay;}
    public Boolean getQuestiondisplay(){return questiondisplay;}
    
    public Boolean getSecproerror(){return secproerror;}
    public Boolean getFinaldetailsdiplay(){return finaldetailsdiplay;} 
    public Boolean getFinalDispBackVended(){return finalDispBackVended;}
    public Boolean getFinalDispBackLeadVended(){return finalDispBackLeadVended;}
    public Boolean getFinalgsadetails() {return finalgsadetails;}
    public Boolean getshowfinalpage(){return showfinalpage;}
    public Boolean getAddproductsdisplay(){return addproductsdisplay;}
    public Boolean getOppdetails(){return oppdetails;}
    public Boolean getContactdisplay(){return contactdisplay;}
    public Boolean getCheckbox(){return checkbox;}
    public Boolean getLeadoppnextdisplay(){return leadoppnextdisplay;}
    public Boolean getEmptyprodlines(){return emptyprodlines;}
    public Boolean getConleadbackdisplay(){return conleadbackdisplay;}
    public Boolean getLeadoppsavedisplay(){return leadoppsavedisplay;}
    public Boolean getBundleproductlistdisplay(){return bundleproductlistdisplay;}
    public Boolean getHighleveldisplay(){return highleveldisplay;}
    public Boolean getOtherinformationdisplay(){return otherinformationdisplay;}
    public Boolean getPricebookdisplay(){return pricebookdisplay;}
    public Boolean getGranularleveldisplay(){return granularleveldisplay;}
    public Boolean getSecproselectdisplay(){return secproselectdisplay;}
    public Boolean getSecprodisplay(){return secprodisplay;}
    public Boolean getBundlelistdisplay(){return bundlelistdisplay;}
    /*Added By    : Srinu Mandalapu
Case Number : 00426534
Description : Variable declaration for Gov't Opportunity Management - Display GSA Questions.
*/
    /*Start*/
    public Boolean getisExecuteGSAtestWrap(){return isExecuteGSAtestWrap;}
    public Boolean getisThisNARACFROpportunity(){return isThisNARACFROpportunity; }    
    public Boolean getisOpportunityMeetsGSA(){return isOpportunityMeetsGSA; }
    /*End*/
    public Id getOppaccid(){return oppaccid;}
    public Id getLeadid(){return leadid;}
    public String getOppname(){return oppname;}
    public String getLeadname()
    {      
        if(sObjLead != null)
            return sObjLead.Name;
        else 
            return null;
    }
    public String getUsercurrency(){return usercurrency;}
    public Boolean getLocation(){return location;}
    public Boolean getQuestionsavedisplay(){return questionsavedisplay;}        
    public Boolean getEmptyproductlist(){return emptyproductlist;}
    public Boolean getEmptyprodlist(){return emptyprodlist;}
    public Boolean getEmptynewprodlist(){return emptynewprodlist;}
    public Boolean getQuestionsbackdisplay(){return questionsbackdisplay;}
    public Boolean getQuestionsnextdisplay(){return questionsnextdisplay;}
    public Boolean getPricebookerror(){return pricebookerror;}
    public Boolean getQuantityexists(){return quantityexists;}
    public Boolean getConrolerror(){return conrolerror;}
    public Boolean getNewcon(){return newcon;}
    public Boolean getOldcon(){return oldcon;}
    public Boolean getEmptybundles(){return emptybundles;}
    public Boolean getBundlequestiondisplay(){return bundlequestiondisplay;}
    public Boolean getQuestionerror(){return questionerror;}
    public Boolean getOverwriterror(){return overwriterror;}
    public Boolean getOppbackbuttondisplay(){return oppbackbuttondisplay;}
    public Boolean getOppnextdisplay(){return oppnextdisplay;}
    public Boolean getQuestionblockrender(){return questionblockrender;}    
    public Boolean getOppcanceldisplay(){return oppcanceldisplay;}
    public Boolean getOppsavedisplay(){return oppsavedisplay;}
    public Boolean getContactbackbuttondisplay(){return contactbackbuttondisplay;}
    public Boolean getConchangedisplay(){return conchangedisplay;}
    public Boolean getConsavedisplay(){return consavedisplay;}
    public Boolean getConbackdisplay(){return conbackdisplay;}
    public Boolean getAddprods(){return addprods;}
    public Boolean getRoleselectblock(){return roleselectblock;}
    public Boolean getConroleselectblock(){return conroleselectblock;} 
    public Boolean getAddprodline(){return addprodline;}
    public Boolean getAddprimaryprod(){return addprimaryprod;}
    public Boolean getProductsavebuttondisplay(){return productsavebuttondisplay;}
    public Boolean getDisplaydetailsdisplay(){return displaydetailsdisplay;}
    public Boolean getBacktoquestionsdisplay(){return backtoquestionsdisplay;}
    public Boolean getBundlemsg(){return bundlemsg;}
    public String getLeadaccountname()
    {
        /* Ketan Benegal--
* LeadAccountName contains account name passed from LeadCustomeMergeController or LeadController.
* No need to do additional queries.
*/
        if(leadaccountname.length()>2)
            sublead= leadaccountname.substring(0,3);
        else
            sublead=leadaccountname;
        if(sublead=='IM_'){      leadaccounterror=true;
        }
        if(leadaccountname.contains('1x1')==true)
        {
            leadaccountname=leadaccountname.replace('1x1', '&');
        }
        if(leadaccountname.contains('2x2')==true)
        {
            leadaccountname=leadaccountname.replace('2x2', ';');
        }
        if(leadaccountname.contains('3x3')==true)
        {
            leadaccountname=leadaccountname.replace('3x3', '!');
        }
        if(leadaccountname.contains('4x4')==true)
        {
            leadaccountname=leadaccountname.replace('4x4', '@');
        }
        if(leadaccountname.contains('5x5')==true)
        {
            leadaccountname=leadaccountname.replace('5x5', '%');
        }
        if(leadaccountname.contains('6x6')==true)
        {
            leadaccountname=leadaccountname.replace('6x6', '#');
        }
        if(leadaccountname.contains('7x7')==true)
        {
            leadaccountname=leadaccountname.replace('7x7', '-');
        }
        
        return leadaccountname;
    }
    
    public String getSelectedpg() {return selectedpg;}
    public void setSelectedpg(String selectedpg){this.selectedpg = selectedpg;}
    public String getSelectedpb() {return selectedpb;}
    public void setSelectedpb(String selectedpb){this.selectedpb = selectedpb;}
    public String getOtherinformation(){return otherinformation;}
    public void setOtherinformation(String otherinformation){this.otherinformation = otherinformation;}
    public String getSelectedbundle() {return selectedbundle;}
    public void setSelectedbundle(String selectedbundle){this.selectedbundle = selectedbundle;}
    public String getSelectedbundletype() {return selectedbundletype;}
    public void setSelectedbundletype(String selectedbundletype){this.selectedbundletype = selectedbundletype;}
    public String getSample(){return sample;}
    public void setSample(String sample){this.sample=sample;}
    public String getPriceoverride(){return priceoverride;}
    public String getOppowner(){return oppowner;}
    public String getQuantityoverride(){return quantityoverride;}
    public void setRolestring(String rolestring){this.rolestring=rolestring;}
    public String getRolestring(){return rolestring;}
    public String getExistingaccountname(){return existingaccountname;}
    public String getExistingcontactname(){return existingcontactname;}
    public Integer getPrice(){return price;}
    public Integer getQuantity(){return quantity;}
    public void setPrice(Integer price){this.price=price;}
    public void setQuantity(Integer quantity){this.quantity=quantity;}
    public void setCheckbox(Boolean checkbox){this.checkbox=checkbox;}
    public Integer getCompletelistsize(){return completelist.size();}
    public Integer getTestlistsize(){return testlist.size();}
    public Id getContactid(){return contactid;}
    public Boolean showClientAgreement{
        get{
            if(showClientAgreement == null){
                showClientAgreement = False;
            }          
            return showClientAgreement;   
        }
        set;
    }      
    
    public Contact getContact() {if(contact == null) contact = new Contact();
                                 return contact;}
    
    public Product_Bundle__c getNewbundle(){if(Newbundle == null) Newbundle = new Product_Bundle__c();
                                            return Newbundle;}
    
    public Opportunity getLeadopportunity(){
        if(leadopportunity==null)  { 
            
            leadopportunity = new Opportunity();
            if(leadopportunityname.contains('1x1')==true)
            {
                leadopportunityname=leadopportunityname.replace('1x1', '&');
            }
            if(leadopportunityname.contains('2x2')==true)
            {
                leadopportunityname=leadopportunityname.replace('2x2', ';');
            }
            if(leadopportunityname.contains('3x3')==true)
            {
                leadopportunityname=leadopportunityname.replace('3x3', '!');
            }
            if(leadopportunityname.contains('4x4')==true)
            {
                leadopportunityname=leadopportunityname.replace('4x4', '@');
            }
            if(leadopportunityname.contains('5x5')==true)
            {
                leadopportunityname=leadopportunityname.replace('5x5', '%');
            }
            if(leadopportunityname.contains('6x6')==true)
            {
                leadopportunityname=leadopportunityname.replace('6x6', '#');
            }
            if(leadopportunityname.contains('7x7')==true)
            {
                leadopportunityname=leadopportunityname.replace('7x7', '-');
            }
            leadopportunity.Name=leadopportunityname;
            //Ketan Benegal
            if(defaultSalesEvent != null)
                leadopportunity.IM_Sales_Event__c = defaultSalesEvent+ ';';        
            
            /*   if(defaultSalesEvent != null)
leadopportunity.IME_Vended_Unvended__c = compvended;        

if(defaultSalesEvent != null)
leadopportunity.Unvended__c = unvendedperc;        

if(defaultSalesEvent != null)
leadopportunity.Vended__c = vendedperc;     */   
            
        }    
        return leadopportunity;
    }
    
    public Opportunity getOpportunity(){
        system.debug('in getOpportunity=='+opportunity);
        if(opportunity==null)  { 
            opportunity = new Opportunity();
            if(existaccid!=null)
                opportunity.AccountId=existaccid;
            
        }  
        return opportunity;
    }
    
    public OpportunityContactRole getOcr(){if(ocr==null) ocr = new OpportunityContactRole();
                                           return ocr;}
    
    public void sendEmailNotification(String strEmailBody, String strEmailSub)
    {
        String username = userinfo.getLastName();
        //String userId = userinfo.getUserId();
        //String username = userinfo.getUserName();
        User mailuser = [Select Email from User where LastName=:username LIMIT 1]; //AND IsActive = true LIMIT 1
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {mailuser.Email}; 
            String[] ccAddresses = new String[] {mailuser.Email}; 
                mail.setToAddresses(toAddresses); 
        mail.setCcAddresses(ccAddresses);    
        mail.setSenderDisplayName(Userinfo.getFirstName() + ' '+ userinfo.getLastName());    //This shoudl be user name
        mail.setSubject(strEmailSub);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody(strEmailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public Pagereference autorun()  {
        pagereference pf = null;
        if(leadid!=null)  {
            oppdetails=false;
            roleselectblock=true;
        }
        if(runwizard==true){
            pf = null;
            recTy=ApexPages.currentPage().getParameters().get('RecordType');
            System.debug('----561---recTy:'+recTy);
        }
        else if(isLightningUser)
        {     
            System.debug('LightningUser - URL:'+ApexPages.currentPage().geturl());
            //String urlvalue = ApexPages.currentPage().geturl();
            String urlvalue = ApexPages.currentPage().getParameters().get('backgroundContext');
            String navLoc = ApexPages.currentPage().getParameters().get('navigationLocation');
            recTy=ApexPages.currentPage().getParameters().get('RecordType');       
            System.debug('LightningUser - recTy:'+recTy);       
            System.debug('LightningUser - existaccid:'+existaccid);
            if(existaccid!=null)
                pf = new pagereference('/006/e?nooverride=1&backgroundContext='+urlvalue+'&recordTypeId='+recTy+'&accid='+existaccid+'&navLoc='+navLoc);
            else
                pf = new pagereference('/006/e?nooverride=1&backgroundContext='+urlvalue+'&recordTypeId='+recTy+'&navLoc='+navLoc);            
        }
        else {
            recTy=ApexPages.currentPage().getParameters().get('RecordType');
            System.debug('----565---recTy:'+recTy);
            if(recTy==null){
                /*Developer Name: Madhu Paladugu 
Case Number   : 00864774
Description   : if you hit 'New Opportunity' from the Account, it does not auto-populate the Account lookup on the Opportunity. 
*/
                if(campid!=null){    pf = new pagereference('/006/e?retURL=%2F006%2Fo&campid='+campid+'&ent=Opportunity&nooverride=0');
                }
                else if(existaccid==null){ pf = new pagereference('/006/e?retURL=%2F006%2Fo&ent=Opportunity&nooverride=0');
                }
                else if(existconid!=null && existaccid!=null ){ pf = new pagereference('/006/e?retURL=%2F006%2Fo&accid='+existaccid+'&conid='+existconid+'&ent=Opportunity&nooverride=0');
                }
                else{
                    pf = new pagereference('/006/e?retURL=%2F006%2Fo&accid='+existaccid+'&ent=Opportunity&nooverride=0');
                }
                //pf = new pagereference('/006/e?retURL=%2F006%2Fo&ent=Opportunity&nooverride=0');
            }
            else{
                if(campid!=null){ pf = new pagereference('/006/e?retURL=%2F006%2Fo&RecordType='+recTy+'&campid='+campid+'&ent=Opportunity&nooverride=0');
                }
                else if(existaccid==null){ pf = new pagereference('/006/e?retURL=%2F006%2Fo&RecordType='+recTy+'&ent=Opportunity&nooverride=0');
                }
                else if(existconid!=null && existaccid!=null ){ pf = new pagereference('/006/e?retURL=%2F006%2Fo&RecordType='+recTy+'&accid='+existaccid+'&conid='+existconid+'&ent=Opportunity&nooverride=0');
                }
                else{
                    pf = new pagereference('/006/e?retURL=%2F006%2Fo&RecordType='+recTy+'&accid='+existaccid+'&ent=Opportunity&nooverride=0');
                }
            }
        }        
        return pf;
    }
    
    
    public String getSecondaryproductquestion() {
        return 'Are there any secondary products associated to this deal?       ';      
    }
    
    /*Get the list of Product Bundle for selection.*/
    public pagereference bundleYes()
    {
        z=0;      
        System.debug('------578----selectedbundletype:'+selectedbundletype);  
        if(selectedbundletype!='All Other Product Lines')
        {
            a=0;         
            Set<String> blset = new Set<String>();
            Set<Id> setProductIds = new Set<Id>();          
            String s = prodgroupId;
            String subs=s.substring(0,15);
            system.debug('north america id:'+subs);
            List<Product_Bundle__c> bundlenames = [Select Name, Product_ID__r.Id From Product_Bundle__c where Bundle_Type__c=:selectedbundletype and Product_Group_ID__c=:subs];
            for(integer i=0; i<bundlenames.size(); i++){              
                blset.add(bundlenames[i].Name);
                setProductIds.add(bundlenames[i].Product_ID__r.Id);
            }         
            List<String>newblist=new List<String>();
            newblist.addAll(blset);
            newblist.sort();
            
            if(newblist.size()>0)
            {
                emptybundles=false;
                for(integer i=0; i<newblist.size(); i++)
                    bundleslist.add(new SelectOption(newblist[i], newblist[i]));
            }
            else
            {
                emptybundles=true;
                bundleslist.add(new SelectOption('NONE','NONE'));
            }
            bundleexists=true;
            bundlelistdisplay=true;
            bundlemsg=false;
            bundlequestiondisplay=false;
        }
        else
        {          
            bundlequestiondisplay=false;
            highleveldisplay=true;
            bundlemsg=false;
        }
        
        return null;
    }
    public pagereference bundleno()
    {
        bundlequestiondisplay=false;
        highleveldisplay=true;
        return null;
    }
    public pagereference bundleback()
    {        
        if(leadid==null){
            if(primarycontactlist.size()>0)  {
                primarycontactlist.clear();
                rolestring=null;
                roleslist.clear();
                primarycontactrolelist.clear();
                oldcon=false;
                for(integer m=0; m<contactList.size(); m++)   {
                    contactList[m].selected=false;
                    contactList[m].oppcont.Role=null;
                }
                contactdisplay=true;
            }
            else   {
                newcontactdisplay=true;
                newcon=false;
            }
            bundlequestiondisplay=false;
            newcon=false;
        }
        else {
            bundlequestiondisplay=false;
            conroleselectblock=true;
        }
        return null;
    }
    public Pagereference leadoppsave()
    { 
        /* Case Number: 00662466
Discription: Added the logic to check the validation rules(Upsell_Opportunity_Quantity,Upsell_Opportunity_Detail_Rule,Upsell_Opportunity_Unit_of_Measure,UpSell_Sold_To_required_for_UpSell_Opt,Validate_Booked_Date_Early) while converting the lead.
Date       : 1/23/2013
*/
        System.debug('Function: leadoppsave()');
         if((leadopportunity.IME_Vended_Unvended__c == null) && (VendedSecDisplay==true)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Competitively Vended: You must enter a value.');
            ApexPages.addMessage(myMsg);
            
            return null;
        }
        
        if(leadopportunity.IME_Vended_Unvended__c == 'Both' /*#16915 (leadopportunity.Vended__c== null || leadopportunity.Unvended__c==null)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % Vended and % Unvended values.');
            ApexPages.addMessage(myMsg);
            return null;
        } 
        
        if(enableCode){
            if(leadopportunity.IME_Vended_Unvended__c == 'Both' /* #16915  && (leadopportunity.Vended__c + leadopportunity.Unvended__c != 100)*/){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both: Enter the percent of storage Vended and Un-vended. Values must equal 100%.');
                ApexPages.addMessage(myMsg);
                return null;
            } 
        }
        ValidateOnLeadConvert.doValidate(leadopportunity);
        if(ValidateOnLeadConvert.NO_ERROR){
            leadoppsavedisplay=false;
            leadoppnextdisplay=true;
            conleadbackdisplay=true;
            finaldetailsdiplay=true;  
            FinalDispBackLeadVended= false;
            VendedSecDisplay = IsVendedSecDisplay('leadoppsave');
            if(VendedSecDisplay==false){
                leadopportunity.IME_Vended_Unvended__c = null ;
               /*#16915  leadopportunity.Vended__c= null; 
                leadopportunity.Unvended__c=null;*/
            }
            else{
                opportunity.IME_Vended_Unvended__c = leadopportunity.IME_Vended_Unvended__c;
               /*#16915  opportunity.Vended__c= leadopportunity.Vended__c; 
                opportunity.Unvended__c=leadopportunity.Unvended__c;*/
            }
                
            if(govtSegUser=='Government')
                finalgsadetails=false; 
            else
                finalgsadetails=true;
            roleselectblock=false;
        }
        
        return null;
        
    }
    public PageReference saveOpp(){      
        /*   if((oppcomp.Expiration_Notification_Date__c!=null || oppcomp.Competitor_Expiration_Date__c!=null) && oppcomp.Competitor__c==null) {
ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The competitor field must be filled in whenever the competitor expiration date, or the expiration notification date have been populated.');
ApexPages.addMessage(myMsg);
return null;
} */
        system.debug('++++ subSegHealthcare is +++' +subSegHealthcare);
        system.debug('++++ opportunity.Group_Purchasing_Organization_GPO__c is ++++ '+opportunity.Group_Purchasing_Organization_GPO__c);
        if(subSegHealthcare=='true' && (opportunity.Group_Purchasing_Organization_GPO__c == '' || opportunity.Group_Purchasing_Organization_GPO__c == null)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Select a GPO value.');
            ApexPages.addMessage(myMsg);
            return null;
            
        }
        if(opportunity.Type=='Up-Sell/Lift' && (opportunity.IM_Up_Sell_Quantity__c==null ||opportunity.IM_Up_Sell_Quantity__c<=0)){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'If Type is Up-Sell you must fill in the Up-Sell Quantity');
            Apexpages.addMessage(errMsg1); 
            return null;
        }
        else if(opportunity.Type=='Up-Sell/Lift' && String.isBlank(opportunity.Upsell_Customer_ID__c)){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'If Type is Up-Sell, you must fill in the Up-Sell Customer Id');
            Apexpages.addMessage(errMsg1); 
            return null;
        }
        else if(opportunity.Type=='Up-Sell/Lift' && opportunity.IM_Up_Sell_Detail__c==null){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'If Type is Up-Sell, you must fill in the Up-Sell Detail');
            Apexpages.addMessage(errMsg1);
            return null; 
        }
        else if(opportunity.Type=='Up-Sell/Lift' && opportunity.IM_Unit_of_Measure__c==null){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'If Type is Up-Sell you must fill in the Unit of Measure');
            Apexpages.addMessage(errMsg1); 
            return null;
        }
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        else if((opportunity.StageName == '0 - Pre-Qualification' || opportunity.StageName == '1 - Qualification' || opportunity.StageName == '2 - Solution Developed' || opportunity.StageName == '3 - Solution Agreed' || opportunity.StageName == '4 - Negotiate' || opportunity.StageName == 'Postponed') && opportunity.CloseDate < system.today()){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'Booked Date cannot be a date in the past in early stage opportunities');
            Apexpages.addMessage(errMsg1);  
            return null;        
        }
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        else if(opportunity.IM_Booked_Date__c<opportunity.CloseDate){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'The First Bill Date must be greater or equal to the Booked Date.');
            Apexpages.addMessage(errMsg1); 
            return null;
        }      
        
        if(opportunity.IME_Vended_Unvended__c == 'Both' /* #16915 && (opportunity.Vended__c== null || opportunity.Unvended__c==null)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % Vended and % Unvended values.');
            ApexPages.addMessage(myMsg);
            return null;
        }
        system.debug('opportunity.IME_Vended_Unvended__c:'+opportunity.IME_Vended_Unvended__c);
       /* #16915  system.debug('opportunity.Vended__c:'+opportunity.Vended__c);
        system.debug('opportunity.Unvended__c:'+opportunity.Unvended__c); */
        
        
        if(opportunity.IME_Vended_Unvended__c == 'Both' /* #16915  && (opportunity.Vended__c + opportunity.Unvended__c != 100)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both: Enter the percent of storage Vended and Un-vended. Values must equal 100%.');
            ApexPages.addMessage(myMsg);
            return null;
        } 
        /*      else if(opportunity.IME_Vended_Unvended__c == 'Vended'){
ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % vended.');
ApexPages.addMessage(myMsg);
return null;
}
else if(opportunity.IME_Vended_Unvended__c == 'Unvended'){
ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % unvended.');
ApexPages.addMessage(myMsg);
return null;
} */
        system.debug('opp comp vended' + opportunity.IME_Vended_Unvended__c);
        varoppaccount = opportunity.AccountId;
        varoppstage = opportunity.StageName;
        varoppprob = opportunity.probability;
        if(opportunity.IME_Vended_Unvended__c == 'Vended' || opportunity.IME_Vended_Unvended__c == 'Both'){
            //oppcompblock=true;
            oppcompblock = false;
            oppnextconbutton = true;
            skipbutton = true;
            leadskipbutton=false;
            leadoppnextconbutton=false;
            oppbackbutton = true;
            leadoppbackbutton = false;
            oppdetails=false;
            system.debug(' opp comp= ' + oppcompblock + ' opp next con button = '+ oppnextconbutton + ' leadoppnextconbutton = '+ leadoppnextconbutton + ' oppdetails '+ oppdetails);
            
        }
        else{
            location=false;
            for(integer q=0; q<contactList.size(); q++) contactList[q].selected=false;
            contactdisplay=true;
            j=0;
            oppdetails=false;
            
        }
        return null;
    }
    
    public Pagereference cancelpg(){        
        highleveldisplay=false;
        bundlequestiondisplay=true;
        return null;
    }
    
    public Pagereference nextpg(){
        
        Set<Product2> productSet = new Set<Product2>();
        Set<String> productLineSet = new Set<String>();
        List<String> newproductLineList = new List<String>();
        /*Developer Name: Madhu Paladugu
Date          : 2/27/13
Case Number   : 01192467
*/
        List<Product2> pricegroupedResults = [select Id, IM_Product_Class__c, IM_Product_Line__c,Use_List_Price_in_Wizard__c  from Product2 where IM_Product_Line__c!=null and CurrencyIsoCode in('USD', 'CAD') and IsActive=true and IM_Product_Class__c =:selectedpg and RecordType.Name Not in ('Bill Code','IME Bill Code') order by IM_Product_Line__c];
        //List<Product2> pricegroupedResults = [select Id, IM_Product_Class__c, IM_Product_Line__c  from Product2 where IM_Product_Line__c!=null and CurrencyIsoCode in('USD', 'CAD') and IsActive=true and IM_Product_Class__c =:selectedpg order by IM_Product_Line__c];
        
        for (integer i=0; i< pricegroupedResults.size() ; i++)   {  productLineSet.add(pricegroupedResults[i].IM_Product_Line__c);
        }
        
        productSet.addAll(pricegroupedResults);
        
        List<PricebookEntry> pbe1 =[select  Id,Pricebook2.IsStandard, Product2.IM_Unit_of_Measure__c, Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2Id in : productSet and CurrencyIsoCode =: usercurrency and /*Pricebook2Id =:pb1.Id*/ Pricebook2Id =:prodgroupId and IsActive=true order by Name];
        if(pbe1.size()>0){ newproductLineList.addAll(productLineSet);
        }
        newproductLineList.sort();
        if(newproductLineList.size()>0)
        {
            emptyprodlines=false;
            for (integer i=0; i< newproductLineList.size() ; i++){  pricegrp.add(new SelectOption(newproductLineList[i] ,newproductLineList[i]));                    
            }
        }  
        else
        {
            emptyprodlines=true;
            system.debug('no lines'+emptyprodlines);
            pricegrp.add(new SelectOption('NONE' ,'NONE'));                    
        } 
        
        granularleveldisplay=true;
        highleveldisplay=false;
        return null;
    }
    
    public pagereference nextbundle(){
        if(selectedbundle!='Other')
        {
            a=0;
            bundleexists=true;
            List<Id> productid = new List<Id>(); 
            List<Product_Bundle__c> selectedbundlelist = [Select Id, Product_ID__c from Product_Bundle__c where Name =:selectedbundle];
            for(integer i=0; i<selectedbundlelist.size(); i++)
                productid.add(selectedbundlelist[i].Product_ID__c);
            
            /*Developer Name: Madhu Paladugu
Date          : 2/27/13
Case Number   : 01192467
*/
            //List<PricebookEntry> pbe =[select  Id, Product2.Quantity_Override_value__c, Product2.IM_Unit_of_Measure__c,  Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Revenue_Type__c, Product2.NumberOfRevenueInstallments, Product2.IM_Product_Class__c, Product2.RevenueInstallmentPeriod, Product2.RevenueScheduleType, Product2.IM_Product_Line__c, Product2Id, Name, Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c  from PricebookEntry where Product2Id in : productid and CurrencyIsoCode =: usercurrency and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') and Pricebook2Id =:prodgroupId and IsActive=true order by Name];
            // For Rate x Quantity scheduling disable, replace above query with below query         
            List<PricebookEntry> pbe =[select  Id,  Product2.IM_Unit_of_Measure__c, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Revenue_Type__c,  Product2.IM_Product_Class__c,   Product2.IM_Product_Line__c, Product2Id, Name, Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c  from PricebookEntry where Product2Id in : productid and CurrencyIsoCode =: usercurrency and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') and Pricebook2Id =:prodgroupId and IsActive=true order by Name];
            
            system.debug('size'+pbe.size());
            for(integer i=0; i<pbe.size();i++) {  bundleproductlist.add(pbe[i]);
            } 
            if(bundleproductlist.size()>0) emptyproductlist=false;
            else
                emptyproductlist=true; 
            bundlelistdisplay=false;
            bundlequestiondisplay=false;
            bundleproductlistdisplay=true;
        }
        else
        {
            bundlelistdisplay=false;
            otherinformationdisplay=true;
        }      
        return null;
    }
    public pagereference cancelbundle(){
        emptybundles=false;
        bundlelistdisplay=false;
        bundleslist.clear();
        bundlequestiondisplay=true;
        return null;
    }
    
    public pagereference bundleproselected()
    {      
        emptyproductlist=false;
        System.debug('--888--selectedbundleproductlist:'+selectedbundleproductlist);
        if(selectedbundleproductlist.size()>0)
        {           
            secproselectdisplay=true;
            bundleproductlistdisplay=false;
            pricebookerror=false;
        }
        else
            pricebookerror=true;
        
        return null;
    }
    public pagereference bundlepronotselected()
    {      
        emptyproductlist=false;
        bundleproductlist.clear();
        selectedbundleproductlist.clear();
        bundleproductlistwrap.clear();
        //bundleslist.clear();
        if(selectedbundle!='Other')
        {
            bundlelistdisplay=true;
            bundleproductlistdisplay=false;
        }
        else
        {   
            bundleproductlistdisplay=false;
            otherinformationdisplay=true;        
        }
        return null;
    }
    public pagereference otherinformationnext(){
        if(otherinformation==null || otherinformation.trim().length()==0)
        {
            othererror=true;
        }
        else
        {      
            system.debug('otherinformation'+otherinformation);
            a=0;
            bundleexists=true;
            List<Id> productid = new List<Id>(); 
            List<Product_Bundle__c> selectedbundlelist = [Select Id, Product_ID__c from Product_Bundle__c where Name =:selectedbundle];
            for(integer i=0; i<selectedbundlelist.size(); i++)
                productid.add(selectedbundlelist[i].Product_ID__c);
            
            /*Developer Name: Madhu Paladugu
Date          : 2/27/13
Case Number   : 01192467
*/
            //List<PricebookEntry> pbe =[select  Id, Product2.IM_Unit_of_Measure__c, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Revenue_Type__c, Product2.NumberOfRevenueInstallments, Product2., Product2.RevenueInstallmentPeriod, Product2.RevenueScheduleType, Product2.IM_Product_Line__c, Product2Id, Name, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c  from PricebookEntry where Product2Id in : productid and CurrencyIsoCode =: usercurrency and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') and Pricebook2Id =:prodgroupId and IsActive=true order by Name];
            // For Rate x Quantity scheduling disable, replace above query with below query     
            List<PricebookEntry> pbe =[select  Id, Product2.Quantity_Override_value__c,  Product2.IM_Unit_of_Measure__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Revenue_Type__c,  Product2.IM_Product_Class__c,   Product2.IM_Product_Line__c, Product2Id, Name, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c  from PricebookEntry where Product2Id in : productid and CurrencyIsoCode =: usercurrency and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') and Pricebook2Id =:prodgroupId and IsActive=true order by Name];
            for(integer i=0; i<pbe.size();i++) { bundleproductlist.add(pbe[i]);
            }
            if(bundleproductlist.size()>0) emptyproductlist=false;
            else
                emptyproductlist=true; 
            otherinformationdisplay=false;
            bundleproductlistdisplay=true;
            othererror=false;
        }
        return null;
    }
    public pagereference otherinformationback(){
        bundlelistdisplay=true;
        otherinformation=null;
        otherinformationdisplay=false;
        othererror=false;      
        return null;
    }
    public Pagereference cancelprimarycontact() {        
        contactlist.clear();
        primarycontactlist.clear();
        primarycontactrolelist.clear();
        roleslist.clear();
        rolestring=null;
        
        oldcon=false;
        contactdisplay=false;
        
        if(opportunity.IME_Vended_Unvended__c=='Vended' || opportunity.IME_Vended_Unvended__c=='Both' ){
            //oppcompblock = true;
            oppcompblock = false;
            oppnextconbutton = true;
            leadoppnextconbutton = false;
            oppbackbutton = true;
            leadoppbackbutton = false;
            skipbutton = true;
            leadskipbutton=false;
            system.debug('opp comp block = '+ oppcompblock + ' oppnext con = '+ oppnextconbutton + ' leadoppnextconbutton= '+ leadoppnextconbutton);
            
        } // back button logic
        else{
            oppdetails=true;
        }
        return null;
    }
    
    public Pagereference primarycontactnotfound(){      
        for(contactwrapper cw: contactList)  {
            if(cw.selected!=true)
            {
                if(cw.oppcont.Role!=null){
                    primarycontactrolelist.add(cw.acc);
                    roleslist.add(cw.oppcont.Role);
                }
            }
        }
        primarycontactlist.clear();
        rolestring=null;
        newcontactdisplay=true;
        location=false;
        contactdisplay = false;
        return null;
    }
    
    public Pagereference newcontactsave(){
        //GSA
        //Case Number : 01622446
        /*Start*/
        //checking Opportunity Contact domain is listed in custom settings list ot not, when clicking on "Not Found" from Contact Role selection page.
        System.debug('+++886+++ContactId:'+ContactId);
        if(ContactId == Null){
            List<GSA_Contact_Email_List__c> GSAsettingsforContDomainCheck = GSA_Contact_Email_List__c.getall().values();             
            System.debug('+++889+++++contact.Email:'+contact.Email);    
            for(GSA_Contact_Email_List__c GSAEmailList: GSAsettingsforContDomainCheck){                                
                if(GSAEmailList.Domain_Extension__c == contact.Email.substringAfterLast('@')){
                    system.debug('Canada is 1036 '+ canOpp);
                    if(canOpp!='True'){
                        System.debug('+++930+++:');
                        ContactThruNotFound=true;
                        //isOpportunityMeetsGSA=true;
                        System.debug('+++934+++ContactThruNotFound:'+ContactThruNotFound);
                    }  
                }
            }
        }
        System.debug('+++938+++ContactThruNotFound:'+ContactThruNotFound);
        /*End*/
        if(ocr.Role==null){ contacterror=true;  
        }
        else
        {
            
            bundlequestiondisplay=true;
            newcontactdisplay=false;
            contacterror=false;
            
        }
        rolestring=ocr.Role;
        newcon=true;
        oldcon=false;
        return null;
    }
    
    public Pagereference newcontactback(){
        primarycontactlist.clear();
        primarycontactrolelist.clear();
        roleslist.clear();
        for(integer m=0; m<contactList.size(); m++)
            contactList[m].selected=false;
        rolestring=null;
        contactdisplay=true;
        newcontactdisplay=false;
        return null;
    }
    
    public Pagereference backtopricequantity(){
        finaldetailsdiplay=false;
        finalgsadetails=false; 
        addproductsdisplay=true;
        return null;
    }
    
    public Pagereference newbacktopricequantity(){
        finaldetailsdiplay=false;
        finalgsadetails=false; 
        addproductsdisplay=true;
        productsavebuttondisplay=true;
        backtoquestionsdisplay=false;
        displaydetailsdisplay=false;
        
        return null;
    }
    
    public pagereference productsavebutton(){
        for(testlistwrapper t: testlistwrap){
            if(t.complist[0].pe.Product2.Quantity_Override_value__c=='n/a') //if override, quantity is disabled and equal to one
            {
                t.complist[0].Quantity=1;
            }
            if(t.complist[0].pe.Product2.IM_Revenue_Type__c=='Recurring') //if recurring, total amount is multiplied by 12
            {
                recur=12;
            }
            else
            {
                recur = 1;
            }
            t.complist[0].Revenue=t.complist[0].Price*t.complist[0].Quantity*recur; //calculate value of total amount for a product
            if(t.complist[0].Price==0 || t.complist[0].Quantity==0){   overwriteverify=true;
            }
        }
        if(overwriteverify==true) {
            overwriterror=true;
            overwriteverify=false;
        }
        else {                 
            addproductsdisplay=false;
            overwriterror=false;
            finaldetailsdiplay=true;
            if(govtSegUser=='Government') finalgsadetails=false; 
            else
                finalgsadetails=true;
            productsavebuttondisplay=false;
            displaydetailsdisplay=true;
            backtoquestionsdisplay=true;
        }
        Pricelist.clear();
        Quantitylist.clear();
        Totalpricelist.clear();
        for(testlistwrapper t: testlistwrap){
            Pricelist.add(t.complist[0].Price);
            Quantitylist.add(t.complist[0].Quantity);
            TotalPricelist.add(t.complist[0].Revenue); //Add total price list which calculates rate * qty * recurring for insert
        }
        return null;
    }
    
    public Pagereference cancelpb(){
        emptyprodlines=false;
        pricegrp.clear();
        highleveldisplay=true;
        granularleveldisplay=false;
        selectedpg=null;
        return null;
    }
    public pagereference backtolead()
    {      
        System.debug('---1152---dupevalue:'+dupevalue);
        if(dupevalue=='true')
        {
            System.debug('---1155---oppconid:'+oppconid);
            if(oppconid!=null)
            {
                pagereference pf = new pagereference('/apex/LeadCustomMerge?cId='+oppconid+'&lId='+leadid);
                System.debug('---1159---pf:'+pf);
                return pf;
            }
            else
            {
                pagereference pf = new pagereference('/apex/LeadCustomMerge?aId='+oppaccid+'&lId='+leadid);
                System.debug('---1165---pf:'+pf);
                return pf;
            }
        }/*else if(dupevalue=='false'){
pagereference pf = new pagereference('/apex/LeadCustomMerge?&lId='+leadid);
Case Number: 01312903
Discription: change page return to LeadCustomConversion on oppentry Back page. 
Date       : 4/19/2013

pagereference pf = new pagereference('/apex/LeadCustomConversion?id='+leadid);
System.debug('---1170---pf:'+pf);
return pf;
} */
        /* Case Number: 01436460
Discription: change page return to CustomLeadConvert on oppentry Back page and removing functionality of case 01312903. 
Date       : 6/4/2013
*/
        else
        {
            pagereference pf1 = new pagereference('/apex/CustomLeadConvert?id='+leadid);
            System.debug('---1172---pf1:'+pf1);
            return pf1;
        }
    }
    public Pagereference nextpb()  {
        //Added on 1-31-2013
        GSATestList.clear();
        productids.clear();
        pricebookentrylist.clear();
        pricebooklist.clear();
        pricebookentries.clear();
        for(integer r=0; r<pricebookList.size(); r++) pricebookList[r].selected=false;
        k=0;
        pricebookdisplay = true;
        granularleveldisplay=false;
        Pricebook2 pb2 = new Pricebook2();        
        pricebookid = prodgroupId;
        /*Developer Name: Madhu Paladugu
Date          : 2/27/13
Case Number   : 01192467
*/
        List<Product2> pro2 = [select Id, IM_Product_Class__c, IM_Product_Line__c,Use_List_Price_in_Wizard__c from Product2 where IM_Product_Line__c = : selectedpb and IM_Product_Class__c = :selectedpg and RecordType.Name Not in ('Bill Code','IME Bill Code')];
        //List<Product2> pro2 = [select Id, IM_Product_Class__c, IM_Product_Line__c from Product2 where IM_Product_Line__c = : selectedpb and IM_Product_Class__c = :selectedpg];
        for(integer i=0; i<pro2.size();i++) { productids.add(pro2[i]);
        }
        // List<PricebookEntry> pbe =[select  Id, Product2.IM_Unit_of_Measure__c, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Revenue_Type__c, Product2.NumberOfRevenueInstallments, Product2.IM_Product_Class__c, Product2.RevenueInstallmentPeriod, Product2.RevenueScheduleType, Product2.IM_Product_Line__c, Product2Id, Name, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c from PricebookEntry where Product2Id in : productids and CurrencyIsoCode =: usercurrency and Pricebook2Id =:pricebookid and IsActive=true order by Name];
        // For Rate x Quantity scheduling disable, replace above query with below query  
        List<PricebookEntry> pbe =[select  Id,  Product2.IM_Unit_of_Measure__c, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Revenue_Type__c,  Product2.IM_Product_Class__c,   Product2.IM_Product_Line__c, Product2Id, Name, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c from PricebookEntry where Product2Id in : productids and CurrencyIsoCode =: usercurrency and Pricebook2Id =:pricebookid and IsActive=true order by Name]; 
        for(integer i=0; i<pbe.size();i++) {  pricebookentries.add(pbe[i]);
        }
        if(pricebookentries.size()>0) emptyprodlist=false;
        else
            emptyprodlist=true;                
        return null;        
    }
    
    public pagereference addprodsyes() {
        pricegrp.clear();        
        set<String> pricelistStrings = new set<String>();
        //List<Product2> pricegroupedResults = [select IM_Product_Line__c from Product2 where IM_Product_Line__c!=null and CurrencyIsoCode in('USD', 'CAD') and IsActive=true and IM_Product_Class__c =:selectedpg];
        
        /*Developer Name: Madhu Paladugu
Date          : 2/27/13
Case Number   : 01192467 
*/
        List<PricebookEntry> pricegroupedResults = [select Product2.IM_Product_Line__c,  Product2.IM_Unit_of_Measure__c, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2.IM_Product_Line__c!=null and CurrencyIsoCode =:usercurrency and Product2.IsActive=true and Product2.IM_Product_Class__c=:selectedpg and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code')];
        //List<PricebookEntry>pricegroupedResults = [select Product2.IM_Product_Line__c from PricebookEntry where Product2.IM_Product_Line__c!=null and CurrencyIsoCode =:usercurrency and Product2.IsActive=true and Product2.IM_Product_Class__c=:selectedpg];
        
        for (integer i=0; i< pricegroupedResults.size() ; i++)   {   pricelistStrings.add(pricegroupedResults[i].Product2.IM_Product_Line__c);                    
        }
        
        List<String> newpricelistStrings=new List<String>(pricelistStrings); 
        System.debug('-----1111-----pricelistStrings.size:'+pricelistStrings.size());        
        newpricelistStrings.sort(); 
        if(newpricelistStrings.size()>0)
        {
            emptyprodlines=false;
            for (integer i=0; i< newpricelistStrings.size() ; i++){  pricegrp.add(new SelectOption(newpricelistStrings[i] ,newpricelistStrings[i]));                    
            }
        }  
        else
        {
            emptyprodlines=true;
            system.debug('no lines'+emptyprodlines);
            pricegrp.add(new SelectOption('NONE' ,'NONE'));                    
        } 
        addprodline=true;
        addprods=false;
        System.debug('queries used addprodsyes: ' + Limits.getQueries());
        return null;
    }
    
    public pagereference addprodsno(){
        addprods=false;
        secproselectdisplay=true;
        return null;
    }
    
    public pagereference addprodsback(){      
        add=0;
        if(fromnewlist==true){
            addprimaryprod=true;
            addprods=false;
            for(integer r=0; r<newpricebookList.size(); r++)  newpricebookList[r].selected=false;
            Integer delsize = newpricebookentrylist.size();
            Integer prosize = additionalproductlist.size()-1;
            for(integer d=0; d<delsize; d++){  additionalproductlist.Remove(prosize-d);
            }
            newpricebookentrylist.clear();
            newpricebookList.clear();
            fromnewlist=false;
        }
        else{
            pricebookdisplay=true;
            addprods=false;
            for(integer r=0; r<pricebookList.size(); r++) pricebookList[r].selected=false;
            pricebookentrylist.clear();
        }
        return null;
    }
    
    public pagereference addprodlinenext(){      
        addproductids.clear();
        add=0;
        newpricebookentrylist.clear();
        newpricebooklist.clear();
        newpricebookentries.clear();
        addprodline=false;
        addprimaryprod=true;
        for(integer r=0; r<newpricebookList.size(); r++) newpricebookList[r].selected=false;
        k=0;
        Pricebook2 pb = new Pricebook2();        
        newpricebookid = prodgroupId;
        /*Developer Name: Madhu Paladugu
Date          : 2/27/13
Case Number   : 01192467
*/
        List<Product2> pro = [select Id, IM_Product_Class__c, IM_Product_Line__c,Use_List_Price_in_Wizard__c from Product2 where IM_Product_Line__c = : selectedpb and IM_Product_Class__c = :selectedpg and RecordType.Name Not in ('Bill Code','IME Bill Code')];
        // List<Product2> pro = [select Id, IM_Product_Class__c, IM_Product_Line__c from Product2 where IM_Product_Line__c = : selectedpb and IM_Product_Class__c = :selectedpg];
        for(integer i=0; i<pro.size();i++){ addproductids.add(pro[i]);
        }
        //List<PricebookEntry> pbr =[select  Id,  Product2.IM_Unit_of_Measure__c, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Revenue_Type__c, Product2.NumberOfRevenueInstallments, Product2.IM_Product_Class__c, Product2.RevenueInstallmentPeriod, Product2.RevenueScheduleType, Product2.IM_Product_Line__c, Product2Id, Name, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c from PricebookEntry where Product2Id in : addproductids and CurrencyIsoCode =: usercurrency and Pricebook2Id =:newpricebookid and IsActive=true order by Name];
        // For Rate x Quantity scheduling disable, replace above query with below query  
        List<PricebookEntry> pbr =[select  Id,  Product2.IM_Unit_of_Measure__c, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Revenue_Type__c,  Product2.IM_Product_Class__c,   Product2.IM_Product_Line__c, Product2Id, Name, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c from PricebookEntry where Product2Id in : addproductids and CurrencyIsoCode =: usercurrency and Pricebook2Id =:newpricebookid and IsActive=true order by Name]; 
        for(integer i=0; i<pbr.size();i++){ newpricebookentries.add(pbr[i]);
        }
        if(newpricebookentries.size()>0) emptynewprodlist=false;
        else
            emptynewprodlist=true;        
        return null;
    }
    
    public pagereference addprodlineback(){      
        addprods=true;
        addprodline=false;
        return null;
    }
    
    public PageReference nextsecpro(){
        System.debug('--1264---pricebookentrylist:'+pricebookentrylist);        
        if(pricebookentrylist.size()>0){
            pricebookdisplay=false;
            addprods=true;
            pricebookerror=false;
        }
        else
            pricebookerror=true;
        return null;
    }
    
    public pagereference addnextsecpro(){      
        if(newpricebookentrylist.size()>0){
            addprimaryprod=false;
            addprods=true;
            fromnewlist=true;
            pricebookerror=false;
            for(PricebookEntry p: newpricebookentrylist)
                additionalproductlist.add(p);
        }
        else
            pricebookerror=true;
        
        return null;
    }
    
    public List<PricebookEntry> getadditionalproductlist(){
        return additionalproductlist;
    }
    
    public PageReference cancelsecpro(){
        pricebooklist.clear();
        pricebookentrylist.clear();
        emptyprodlist=false;
        selectedpb=null;
        granularleveldisplay=true;
        pricebookdisplay=false;
        return null;
    }
    
    public PageReference addcancelsecpro(){
        newpricebooklist.clear();
        newpricebookentrylist.clear();
        emptynewprodlist=false;
        selectedpb=null;
        addprodline=true;
        addprimaryprod=false;
        return null;
    }
    
    public PageReference secprotrue(){
        secproselectdisplay=false;
        secprodisplay=true;        
        return null;
    }
    
    public PageReference secprofalse(){
        /*Start*/
        //Added by    : Srinu
        //Case Number : 00426534
        System.debug('in Method: secprofalse');
        List<ID> selectedProductIds = new List<ID>();
        List<PricebookEntry> selectedProducts = new List<PricebookEntry>();
        Boolean RMProductsExists = false;
        if(IsVendedSecDisplay('secprofalse')){ VendedSecDisplay = true;
        }
        else {
            VendedSecDisplay = false;
        }
        
        system.debug('RMProductsExists:'+RMProductsExists);
        if(govtSegUser=='Government') GSAQuestiondisplay=false; 
        else
        {
            GSAQuestiondisplay=true;            
        }
        
        
        system.debug('VendedSecDisplay:'+VendedSecDisplay);
        system.debug('opportunity.StageName:'+opportunity.StageName);
        
        GSATestList.clear();
        completelist.clear();
        isExecuteGSAtestWrap=true;        
        gsaquestionblockrender=true;
        /*End*/
        for(integer i=0; i<selectedbundleproductlist.size(); i++){ completelist.add(selectedbundleproductlist[i]);
            System.debug('Pratap:'+selectedbundleproductlist[i]);
        }
        for(Integer z=0; z<pricebookentrylist.size();z++) { completelist.add(pricebookentrylist[z]);
            System.debug('Pratap:'+pricebookentrylist[z]);
        }
        for(Integer u=0; u<additionalproductlist.size();u++) { completelist.add(additionalproductlist[u]);
            System.debug('Pratap:'+additionalproductlist[u]);
        }
        for(Integer p=0; p<secondaryproductlist.size(); p++){  completelist.add(secondaryproductlist[p]);
            System.debug('Pratap:'+secondaryproductlist[p]);
        }
        
        
        
        Product2 pd = new Product2();
        testlist.clear();
        for(PricebookEntry p : completelist){
            pd = [Select Id, Name, IM_Product_Line__c,Use_List_Price_in_Wizard__c, (Select Name, Active__c, Answer_Format__c, Answer_Picklist__c, Product__c From Opportunity_Questions__r where Active__c = true order by Question_Order__c) From Product2 where Id =:p.Product2Id];
            testlist.add(pd);
        }
        testlistwrap.clear();
        for(Product2 p: testlist) testlistwrap.add(new testlistwrapper(p));
        for(testlistwrapper ts: testlistwrap){ if(ts.questions.size()!=0)  questionblockrender=true;
        }
        secproselectdisplay=false;
        questiondisplay=true;
        
        return null;
    }
    /*Start*/
    //Added by    : Srinu
    //Case Number : 00426534
    public pagereference GSAQuestions(){
        return null;
    }
    /*End*/
    public PageReference secproback()
    {        
        selectedbundleproductlist.clear();
        for(integer n=0; n<pricebookList.size(); n++) pricebookList[n].selected=false;
        for(integer n=0; n<bundleproductlistwrap.size(); n++) bundleproductlistwrap[n].selected=false;
        secproselectdisplay=false;
        if(bundleexists==true)
            bundleproductlistdisplay=true;
        else
            addprods=true;
        questionblockrender=false;
        
        return null;
    }
    
    public Pagereference secprodisplaynext(){
        /*Start*/
        //Added by    : Srinu
        //Case Number : 00426534
        
        List<ID> selectedProductIds = new List<ID>();
        List<PricebookEntry> selectedProducts = new List<PricebookEntry>();
        Boolean RMProductsExists = false;
        if(govtSegUser=='Government'){ GSAQuestiondisplay=false; 
        }
        else{
            
            GSAQuestiondisplay=true;
        }
        
        System.Debug('Method: secprodisplaynext');
        
        if(IsVendedSecDisplay('secprodisplaynext')){ VendedSecDisplay = true;
        }
        else {
            VendedSecDisplay = false;
        }
        
        isExecuteGSAtestWrap=true;        
        gsaquestionblockrender=true;
        /*End*/
        SYstem.debug('---1376----secondaryproductlist:'+secondaryproductlist);
        if(secondaryproductlist.size()>0){
            secprodisplay=false;
            secproerror=false;            
            completelist.clear();
            for(integer i=0; i<selectedbundleproductlist.size(); i++){ completelist.add(selectedbundleproductlist[i]);
            }
            for(Integer z=0; z<pricebookentrylist.size();z++){ completelist.add(pricebookentrylist[z]);
            }
            for(Integer u=0; u<additionalproductlist.size();u++){ completelist.add(additionalproductlist[u]);
            }
            for(Integer p=0; p<secondaryproductlist.size(); p++){
                completelist.add(secondaryproductlist[p]);
            }
            Product2 pd = new Product2();
            testlist.clear();
            for(PricebookEntry p : completelist){
                pd = [Select Id, Name, IM_Product_Line__c,Use_List_Price_in_Wizard__c, (Select Name, Active__c, Answer_Format__c, Answer_Picklist__c, Product__c From Opportunity_Questions__r where Active__c = true order by Question_Order__c) From Product2 where Id =:p.Product2Id];
                testlist.add(pd);
            }
            testlistwrap.clear();
            for(Product2 p: testlist)
                testlistwrap.add(new testlistwrapper(p));
            questionblockrender=false;
            for(testlistwrapper ts: testlistwrap){
                if(ts.questions.size()!=0) questionblockrender=true;
            }
            questiondisplay=true;
            //GSA
            if(govtSegUser=='Government')    GSAQuestiondisplay=false; 
            else
                GSAQuestiondisplay=true;
        }
        else
            secproerror=true;
        return null;
    }
    
    public Pagereference secprodisplayback()
    {
        secondaryproductlist.clear();
        for(integer u=0; u<secondproductlist.size(); u++)
            secondproductlist[u].selected=false;
        secprodisplay=false;
        secproselectdisplay=true;
        return null;
    }
    public Pagereference backtosecpro(){      
        if(secondaryproductlist.size()>0){
            for(integer u=0; u<secondproductlist.size(); u++)   secondproductlist[u].selected=false;
            secondaryproductlist.clear();        
            secprodisplay=true;
        }
        else{
            secondaryproductlist.clear();
            secproselectdisplay=true;
        }
        questiondisplay=false;
        questionerror=false;  
        //GSA
        GSAQuestiondisplay=false;
        VendedSecDisplay =false;
        
        opportunity.IME_Vended_Unvended__c =null;
       /*#16915  opportunity.Vended__c= null;
        opportunity.Unvended__c=null; */
        
        return null;
    }
    
    public Pagereference addproducts() {
        //Added on 07-30-2013
        //Modified By: Srinivasa Rao Mandalapu
        //Case# :01622446
        /*Start*/  
        
        System.debug('--1585----GSATestList:'+GSATestList);
        
        if((opportunity.IME_Vended_Unvended__c == null) && (VendedSecDisplay==true)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Competitively Vended: You must enter a value.');
            ApexPages.addMessage(myMsg);
            
            return null;
        }
        
        if(opportunity.IME_Vended_Unvended__c == 'Both' /* #16915 && (opportunity.Vended__c== null || opportunity.Unvended__c==null)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % Vended and % Unvended values.');
            ApexPages.addMessage(myMsg);
            
            return null;
        }
        
        if(enableCode){
            if(opportunity.IME_Vended_Unvended__c == 'Both' /*#16915 && (opportunity.Vended__c + opportunity.Unvended__c != 100)*/){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both: Enter the percent of storage Vended and Un-vended. Values must equal 100%.');
                ApexPages.addMessage(myMsg);
                return null;
            } 
        }
        
        for(GSAWrapper testGSA: GSATestList){
            System.debug('---1587--testGSA.picklistanswer:'+testGSA.picklistanswer);
            if(testGSA.picklistanswer=='--None--'){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Every GSA Question should be answered either Yes or No.');
                ApexPages.addMessage(myMsg);
                return null;
            }           
        }
        
        /*End*/         
        //GSA
        GSAQuestiondisplay=false;
        VendedSecDisplay =false;
        if((leadid!= null) && (leadopportunity!= null)){
            
            leadopportunity.IME_Vended_Unvended__c = opportunity.IME_Vended_Unvended__c;
           /* #16915 leadopportunity.Vended__c = opportunity.Vended__c;
            leadopportunity.Unvended__c = opportunity.Unvended__c; */
        }
        System.debug('---1570---testlistwrap:'+testlistwrap);
        for(testlistwrapper tl: testlistwrap) {
            for(questionwrapper q: tl.questions)  {
                if(q.textanswer!=null) q.finalanswer=q.textanswer;
                else if(q.picklistanswer!=null) q.finalanswer=q.picklistanswer;
                else if(q.checkboxanswer=='yes') q.finalanswer='yes';
                else if(q.checkboxanswer=='no') q.finalanswer='no';
                if(q.finalanswer==null || q.finalanswer.trim().length()==0){ questionverify=true;
                }
            }
        }
        if(questionverify==true) {
            questionerror=true;
            questionverify=false;
        }
        else {
            completelistwrap.clear();
            System.debug('------completelist:'+completelist);
            for(PricebookEntry p: completelist){              
                completelistwrap.add(new completelistwrapper(p, p.Product2.Use_List_Price_in_Wizard__c));
                System.debug('------completelistwrap:'+completelistwrap);           
            }
            System.debug('--1598----testlistwrap:'+testlistwrap);
            for(Integer i=0; i<testlistwrap.size(); i++)   {
                testlistwrap[i].prodnumber=(i+1);
                testlistwrap[i].complist.add(completelistwrap[i]);
            }
            questiondisplay=false;
            addproductsdisplay=true;
            questionerror=false;
        }
        
        return null;
    }
    
    public Pagereference questionsavebutton(){
        for(testlistwrapper tl: testlistwrap) {
            for(questionwrapper q: tl.questions)  {
                if(q.textanswer!=null) q.finalanswer=q.textanswer;
                else if(q.picklistanswer!=null) q.finalanswer=q.picklistanswer;
                else if(q.checkboxanswer=='yes') q.finalanswer='yes';
                else if(q.checkboxanswer=='no') q.finalanswer='no';
                if(q.finalanswer==null || q.finalanswer.trim().length()==0) questionverify=true;            
            }
        }
        if(questionverify==true){
            questionerror=true;
            questionverify=false;
        }
        else
        {
            questiondisplay=false;
            finaldetailsdiplay=true;
            if(govtSegUser=='Government') finalgsadetails=false; 
            else
                finalgsadetails=true;
            questionerror=false;
            questionsavedisplay=false;
            questionsnextdisplay=true;
            questionsbackdisplay=true;
        }
        return null;
    }
    
    public Pagereference displaydetails(){ 
        //GSA Modification
        //Modified By: Srinivasa Rao Mandalapu
        //Case# :01622446
        /*Start*/
        //checking if any answer is Yes.
        for(GSAWrapper testGSA: GSATestList){
            if(testGSA.picklistanswer=='Yes'){ 
                system.debug('Canada is 1626'+ canOpp);
                if(canOpp!='True'){
                    //Set boolean to true.
                    isOpportunityMeetsGSA=true; 
                }
            }
        }       
        //checking Opportunity Contact domain is listed in custom settings list ot not.
        if(ContactId != Null){
            List<GSA_Contact_Email_List__c> GSAsettingsforContDomainCheck = GSA_Contact_Email_List__c.getall().values();
            Contact contEmailforContDomainCheck = [Select Email From Contact where Id =:ContactId];     
            if(contEmailforContDomainCheck.Email!=null){
                for(GSA_Contact_Email_List__c GSAEmailList: GSAsettingsforContDomainCheck){
                    if(GSAEmailList.Domain_Extension__c == contEmailforContDomainCheck.Email.substringAfterLast('@')){
                        system.debug('Canada is 1640'+ canOpp);
                        if(canOpp!='True'){
                            //Set boolean to true.
                            isOpportunityMeetsGSA=true; 
                        }
                    }              
                }
            }
        }
        //checking Lead Email domain is listed in custom settings list ot not. 
        System.debug('+++1515+++leadcontEmail:'+leadcontEmail);
        if(leadcontEmail != Null){
            List<GSA_Contact_Email_List__c> GSAsettingsforLeadContDomainCheck = GSA_Contact_Email_List__c.getall().values();
            for(GSA_Contact_Email_List__c GSAEmailList: GSAsettingsforLeadContDomainCheck){
                if(GSAEmailList.Domain_Extension__c == leadcontEmail.substringAfterLast('@')){
                    system.debug('Canada is 1655'+ canOpp);
                    if(canOpp!='True'){
                        //Set boolean to true.
                        isOpportunityMeetsGSA=true; 
                    }
                }  
            } 
        }
        //checking Potential duplicate Contact domain is listed in custom settings list ot not.
        if(contDomain=='true'){
            system.debug('Canada is 1665'+ canOpp);
            if(canOpp!='True'){
                //Set boolean to true.
                isOpportunityMeetsGSA=true; 
            }
        }
        
        //checking Opportunity Contact domain is listed in custom settings list ot not, when clicking on "Not Found" from Contact Role selection page.
        if(LeadId==null && ContactId == Null){
            List<GSA_Contact_Email_List__c> GSAsettingsforContDomainCheck = GSA_Contact_Email_List__c.getall().values();
            
            for(GSA_Contact_Email_List__c GSAEmailList: GSAsettingsforContDomainCheck){
                if(contact.Email != Null && GSAEmailList.Domain_Extension__c == contact.Email.substringAfterLast('@')){
                    system.debug('Canada is 1678'+ canOpp);
                    if(canOpp!='True'){
                        //Set boolean to true.
                        isOpportunityMeetsGSA=true; 
                    }
                }
                
            }
        }
        
        /*End*/   
        for(testlistwrapper t: testlistwrap){
            if(t.complist[0].pe.Product2.Quantity_Override_value__c=='n/a') //if override, quantity is disabled and equal to one
            {
                t.complist[0].Quantity=1;
            }
            if(t.complist[0].pe.Product2.IM_Revenue_Type__c=='Recurring') //if recurring, total amount is multiplied by 12
            {
                recur=12;
            }
            else
            {
                recur = 1;
            }
            t.complist[0].Revenue=t.complist[0].Price*t.complist[0].Quantity*recur; //calculate value of total amount for a product
            if(t.complist[0].Price==0 || t.complist[0].Quantity==0){   overwriteverify=true;
            }
        }
        if(overwriteverify==true){
            overwriterror=true;
            overwriteverify=false;
        }
        else{                 
            addproductsdisplay=false;
            overwriterror=false;
            finaldetailsdiplay=true;
            VendedSecDisplay = IsVendedSecDisplay('displaydetails');
            
            if(govtSegUser=='Government')    finalgsadetails=false; 
            else
                finalgsadetails=true;
        }
        Pricelist.clear();
        Quantitylist.clear();
        TotalPricelist.clear();
        for(testlistwrapper t: testlistwrap){
            Pricelist.add(t.complist[0].Price);
            Quantitylist.add(t.complist[0].Quantity);
            TotalPricelist.add(t.complist[0].Revenue);
        }
        return null;
    }
    
    public PageReference savePrimarycontact(){        
        for(contactwrapper cw: contactList){
            if(cw.selected==true)  {
                primarycontactlist.add(cw.acc);
                if(cw.oppcont.Role!=null){
                    rolestring=cw.oppcont.Role;
                }
            }
        }
        for(contactwrapper cw: contactList)  {
            if(cw.selected!=true)
            {
                if(cw.oppcont.Role!=null){
                    primarycontactrolelist.add(cw.acc);
                    roleslist.add(cw.oppcont.Role);
                }
            }
        }
        if(primarycontactlist.size()>0 && rolestring != null) {
            contactdisplay = false;
            bundlequestiondisplay=true;
            location=false;
            contactid=null;
            contactid = primarycontactlist[0].Id;            
            oldcon=true;
            newcon=false;
        }       
        else
        {
            location=true;
            primarycontactrolelist.clear();
            roleslist.clear();          
        }
        return null;
    }
    
    public Pagereference backtoquestions(){
        System.debug('in Method: backtoquestions');
        
        
        
        for(testlistwrapper ts: testlistwrap){
            for(questionwrapper qs: ts.questions){
                /*qs.checkboxanswer=null;
qs.finalanswer=null;
qs.picklistanswer=null;
qs.textanswer=null;*/
            }
        }
        addproductsdisplay=false;      
        questiondisplay=true;
        VendedSecDisplay = IsVendedSecDisplay('backtoquestions')  ;
        //GSA
        /*Start*/
        if(govtSegUser=='Government')     GSAQuestiondisplay=false; 
        else
        {
            GSAQuestiondisplay=true;  
        }
        
        
        gsaquestionblockrender=true;
        /*End*/
        return null;
    }
    //Srinu: Nothing has written in for loop on 09/19.
    public Pagereference newbacktoquestions(){
        for(testlistwrapper ts: testlistwrap){
            for(questionwrapper qs: ts.questions){          
            }
        }
        finaldetailsdiplay=false;
        finalgsadetails=false;
        questiondisplay=true;
        questionsavedisplay=true;
        questionsbackdisplay=false;
        questionsnextdisplay=false;
        return null;
    }
    /*Start*/
    //Added by    : Srinu
    //Case Number : 00426534
    Public PageReference newbacktogsaquestions(){
        if(govtSegUser=='Government')    GSAQuestiondisplay=false; 
        else
            GSAQuestiondisplay=true;
        finaldetailsdiplay=false;
        finalgsadetails=false;
        gsaquestionsavedisplay=true;        
        gsaquestionblockrender=true;    
        return null;
    }    
    public pagereference gsaquestionsavebutton(){
        //Added on 07-30-2013
        //Modified By: Srinivasa Rao Mandalapu
        //Case# :01622446
        /*Start*/        
        //Error message when User click Next without answering all 6 GSA questions.
        
        if(opportunity.IME_Vended_Unvended__c == 'Both' /*#16915 && (opportunity.Vended__c== null || opportunity.Unvended__c==null)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % Vended and % Unvended values.');
            ApexPages.addMessage(myMsg);
            
            return null;
        }
        
        if(enableCode){
            if(opportunity.IME_Vended_Unvended__c == 'Both' /*#16915 && (opportunity.Vended__c + opportunity.Unvended__c != 100)*/){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both: Enter the percent of storage Vended and Un-vended. Values must equal 100%.');
                ApexPages.addMessage(myMsg);
                return null;
            } 
        }
        
        for(GSAWrapper testGSA: GSATestList){
            System.debug('---1789--testGSA.picklistanswer:'+testGSA.picklistanswer);
            if(testGSA.picklistanswer=='--None--'){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Every GSA Question should be answered either Yes or No.');
                ApexPages.addMessage(myMsg);
                return null;
            }           
        }        
        //checking Opportunity Contact domain is listed in custom settings list ot not. 
        if(ContactId != Null){
            List<GSA_Contact_Email_List__c> GSAsettingsforContDomainCheck = GSA_Contact_Email_List__c.getall().values();
            Contact contEmailforContDomainCheck = [Select Email From Contact where Id =:ContactId];     
            if(contEmailforContDomainCheck.Email!=null){
                for(GSA_Contact_Email_List__c GSAEmailList: GSAsettingsforContDomainCheck){
                    if(GSAEmailList.Domain_Extension__c == contEmailforContDomainCheck.Email.substringAfterLast('@')){
                        system.debug('Canada is 1828'+ canOpp);
                        if(canOpp!='True'){
                            //Set boolean to true.
                            isOpportunityMeetsGSA=true; 
                            System.debug('++1694++inside if customsettings value++++');
                        }
                    }              
                }
            }
        }
        //checking Lead Email domain is listed in custom settings list ot not. 
        if(leadcontEmail != Null){
            List<GSA_Contact_Email_List__c> GSAsettingsforLeadContDomainCheck = GSA_Contact_Email_List__c.getall().values();
            for(GSA_Contact_Email_List__c GSAEmailList: GSAsettingsforLeadContDomainCheck){
                if(GSAEmailList.Domain_Extension__c == leadcontEmail.substringAfterLast('@')){
                    system.debug('Canada is 1844'+ canOpp);
                    if(canOpp!='True'){
                        //Set boolean to true.
                        isOpportunityMeetsGSA=true; 
                        System.debug('++1843++when Lead contact domain lists in Custom Settings list++++');
                    }  
                }
            } 
        }
        //checking if any answer is Yes. 
        for(GSAWrapper testGSA: GSATestList){
            System.debug('---1838--testGSA.picklistanswer:'+testGSA.picklistanswer);            
            //If any of GSA Answer is 'Yes' means, Opportunity is eligible for Approval.
            if(testGSA.picklistanswer=='Yes'){  
                system.debug('Canada is 1858'+ canOpp);
                if(canOpp!='True'){
                    //Set boolean to true.
                    isOpportunityMeetsGSA=true;                     
                }
            }
        }
        //checking Potential duplicate Contact domain is listed in custom settings list ot not.
        if(contDomain=='true'){
            system.debug('Canada is 1867'+ canOpp);
            if(canOpp!='True'){
                //Set boolean to true.
                isOpportunityMeetsGSA=true; 
                System.debug('++1849++when potential duplicate contact domain lists in Custom Settings list++++');
            }  }
        //checking Opportunity Contact domain is listed in custom settings list ot not, when clicking on "Not Found" from Contact Role selection page.
        System.debug('+++1686+++ContactId:'+ContactId);
        if(LeadId==null && ContactId == Null){
            List<GSA_Contact_Email_List__c> GSAsettingsforContDomainCheck = GSA_Contact_Email_List__c.getall().values();
            System.debug('+++889+++++contact.Email:'+contact.Email);    
            for(GSA_Contact_Email_List__c GSAEmailList: GSAsettingsforContDomainCheck){
                if(GSAEmailList.Domain_Extension__c == contact.Email.substringAfterLast('@')){
                    system.debug('Canada is 1880'+ canOpp);
                    if(canOpp!='True'){
                        //Set boolean to true.
                        isOpportunityMeetsGSA=true; 
                        System.debug('---1694----isOpportunityMeetsGSA:'+isOpportunityMeetsGSA);                    
                    } 
                }
            }
        } 
        /*End*/
        finaldetailsdiplay=true;
        if(govtSegUser=='Government')   finalgsadetails=false; 
        else
            finalgsadetails=true;
        GSAQuestiondisplay=false;
        VendedSecDisplay = IsVendedSecDisplay('gsaquestionsavebutton');
        gsaquestionsavedisplay=false;
        return null;
    }
    /*End*/
    public pagereference oppbackbutton(){
        oppdetails=true;
        finaldetailsdiplay=false;
        finalgsadetails=false;
        oppnextdisplay=false;
        oppcanceldisplay=false;
        oppsavedisplay=true;
        return null;
    }
    
    public pagereference oppFinalVenbackbutton(){
        oppdetails=false;
        finaldetailsdiplay=false;
        finalgsadetails=false;
        oppnextdisplay=false;
        oppcanceldisplay=false;
        oppsavedisplay=false;
        finalDispBackVended= true;   
        return null;
    }
    
    public pagereference leadoppbackbutton(){
        finaldetailsdiplay=false;
        finalgsadetails=false;
        roleselectblock=true;
        leadoppnextdisplay=false;
        conleadbackdisplay=false;
        FinalDispBackLeadVended= false;
        leadoppsavedisplay=true;
        return null;
    }
    
    public pagereference leadoppVendbackbutton(){
        finaldetailsdiplay=false;
        finalgsadetails=false;
        roleselectblock=false;
        leadoppnextdisplay=false;
        conleadbackdisplay=false;
        leadoppsavedisplay=false;      
        FinalDispBackLeadVended= true;
        return null;
    }
    
    public pagereference contactbackbutton(){
        newcontactdisplay=true;
        finaldetailsdiplay=false;
        finalgsadetails=false;
        conchangedisplay=true;
        consavedisplay=false;
        conbackdisplay=false;
        return null;
    }
    
    public Pagereference conleadnext() {
        if(ocr.Role!=null)
        {
            rolestring=ocr.Role;
            conroleselectblock=false;
            bundlequestiondisplay=true;
            conrolerror=false;
        }
        else
            conrolerror=true;
        return null;
    }
    
    
    public Pagereference conleadback() {
        if(sObjLead.Competitively_Vended__c=='Both' || sObjLead.Competitively_Vended__c=='Vended'){
            
            //oppcompblock=true;
            oppcompblock = false;
            leadoppnextconbutton = true;
            oppnextconbutton=false;
            oppbackbutton = false;
            leadoppbackbutton = true;
            skipbutton = false;
            leadskipbutton=true;
        } else{
            roleselectblock=true;
        }
        roleselectblock=true;
        conroleselectblock=false;
        ocr.Role=null;
        return null;
    }
    
    public pagereference leadoppnext(){
        
        /* Case Number: 03474925
Description: Make % Vended and Unvended mandatory if 'Both' is selected
Date       : 04/24/2015
*/
        system.debug('lead opp is +++ '+ leadopportunity);
         system.debug('lead opp insight +++ '+ leadopportunity.InSight_Opportunities__c);
        system.debug ('lead vended unvended = +++++ ' + leadopportunity.IME_Vended_Unvended__c);
        try{
            leadopportunity.IME_Vended_Unvended__c = sobjLead.Competitively_Vended__c;
           /* #16915  leadopportunity.Vended__c = sObjLead.Vended__c;
            leadopportunity.Unvended__c = sObjLead.Unvended__c;*/
        } catch(exception e){
            system.debug('Exception is '+ e);
        }
        if(leadopportunity.IME_Vended_Unvended__c== 'Both'/*#16915  && (leadopportunity.Vended__c== null || leadopportunity.Unvended__c==null)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % Vended and % Unvended values.');
            ApexPages.addMessage(myMsg);
            return null;
        }
         if(leadopportunity.Primary_Product_Line__c== 'Insight' && leadopportunity.StageName =='2 - Solution Developed' && String.isBlank(leadopportunity.InSight_Opportunities__c)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please provide a value for Insight Opportunities');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        if(enableCode){
            if(opportunity.IME_Vended_Unvended__c == 'Both'/* && (opportunity.Vended__c + opportunity.Unvended__c != 100)*/){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both: Enter the percent of storage Vended and Un-vended. Values must equal 100%.');
                ApexPages.addMessage(myMsg);
                return null;
            } 
        }
        /* Case Number: 01312903
Discription: Create a validation rule that would prevent Opportunities from being created under the System Use Only Account and prompt user to align the Customer Account with the proper Account or have a new Account created. 
Date       : 4/19/2013
*/
        system.debug('+++++++++++++leadaccount name+++++'+leadaccountname);
        if(leadaccountname=='SYSTEM USE ONLY - DO NOT MODIFY - NoParentCustAcc'){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'A lead cannot be converted into an opportunity using the “SYSTEM USE ONLY - DO NOT MODIFY - NoParentCustAcc” account. Please click the “Back” button, and select a different account for this lead.');
            Apexpages.addMessage(errMsg1);
            return null;
        }
        
        
        
        /* Case Number: 00662466
Discription: Added the logic to check the validation rules(Upsell_Opportunity_Quantity,Upsell_Opportunity_Detail_Rule,Upsell_Opportunity_Unit_of_Measure,UpSell_Sold_To_required_for_UpSell_Opt,Validate_Booked_Date_Early) while converting the lead.
Date       : 1/23/2013
*/
        ValidateOnLeadConvert.doValidate(leadopportunity);
        system.debug('ValidateOnLeadConvert.NO_ERROR:'+ValidateOnLeadConvert.NO_ERROR);
        if(ValidateOnLeadConvert.NO_ERROR){
            //  roleselectblock=true; 
            conroleselectblock=true; 
            oppnextconbutton = false;            
            leadoppnextconbutton = false;
            oppbackbutton = false;
            leadoppbackbutton = false;
            roleselectblock=false;
            /*
if(sObjLead.Competitively_Vended__c=='Both' || sObjLead.Competitively_Vended__c=='Vended'){
oppcompblock=true;
system.debug('if block: sObjLead.Competitively_Vended__c:'+ sObjLead.Competitively_Vended__c);
oppcompblock = false;
leadoppnextconbutton = true;
oppnextconbutton=false;
oppbackbutton = false;
leadoppbackbutton = true;
skipbutton = false;
leadskipbutton=true;
} else{
system.debug('else block');
conroleselectblock=true;

}          
*/   
        }        
        return null;
    }
    
    public pagereference oldcontactbackbutton(){
        primarycontactlist.clear();
        primarycontactrolelist.clear();
        roleslist.clear();
        rolestring=null;
        for(integer m=0; m<contactList.size(); m++){
            contactList[m].selected=false;
            contactList[m].oppcont.Role=null;
        }
        contactdisplay=true;
        finaldetailsdiplay=false;
        finalgsadetails=false;
        conchangedisplay=true;
        consavedisplay=false;
        conbackdisplay=false;
        return null;
    }
    
    public pagereference oppsavebutton() {
        /* if((oppcomp.Expiration_Notification_Date__c!=null || oppcomp.Competitor_Expiration_Date__c!=null) && oppcomp.Competitor__c==null) {
ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The competitor field must be filled in whenever the competitor expiration date, or the expiration notification date have been populated.');
ApexPages.addMessage(myMsg);
return null;
} */
        if((opportunity.IME_Vended_Unvended__c == null) && (VendedSecDisplay==true)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Competitively Vended: You must enter a value.');
            ApexPages.addMessage(myMsg);
            
            return null;
        } 
                
        if(opportunity.IME_Vended_Unvended__c == 'Both' /*#16915 && (opportunity.Vended__c== null || opportunity.Unvended__c==null)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % Vended and % Unvended values.');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        if(enableCode){
            if(opportunity.IME_Vended_Unvended__c == 'Both'/*#16915  && (opportunity.Vended__c + opportunity.Unvended__c != 100)*/){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both: Enter the percent of storage Vended and Un-vended. Values must equal 100%.');
                ApexPages.addMessage(myMsg);
                return null;
            } 
        }
        oppdetails=false;
        
        finaldetailsdiplay=true;
        VendedSecDisplay = IsVendedSecDisplay('oppsavebutton');
        
        if(VendedSecDisplay==false){
            opportunity.IME_Vended_Unvended__c = null ;
            /* #16915  opportunity.Vended__c= null; 
            opportunity.Unvended__c=null; */
            
            if((leadid!= null) && (leadopportunity!= null)){
                leadopportunity.IME_Vended_Unvended__c = null ;
                /*leadopportunity.Vended__c= null; 
                leadopportunity.Unvended__c=null; */
            }
        }
        else
        {
            if((leadid!= null) && (leadopportunity!= null)){
                leadopportunity.IME_Vended_Unvended__c = opportunity.IME_Vended_Unvended__c ;
                /* #16915 leadopportunity.Vended__c= opportunity.Vended__c; 
                leadopportunity.Unvended__c=opportunity.Unvended__c; */
            }
        }
        
        if(govtSegUser=='Government')  finalgsadetails=false; 
        else
            finalgsadetails=true;
        oppnextdisplay=true;
        oppcanceldisplay=true;
        oppsavedisplay=false;
        oppbackbuttondisplay=false;
        finalDispBackVended= false;
        return null;
    }
    
    public pagereference consavebutton(){
        System.debug('++1833+++++inside consavebutton method++++ContactId:'+ContactId +'\t ++++++leadid:'+leadid);
        //GSA
        //Case Number : 01622446
        /*Start*/
        if(ContactId == Null){
            List<GSA_Contact_Email_List__c> GSAsettingsforContDomainCheck = GSA_Contact_Email_List__c.getall().values();             
            System.debug('+++1837+++++contact.Email:'+contact.Email);    
            for(GSA_Contact_Email_List__c GSAEmailList: GSAsettingsforContDomainCheck){                                
                if(contact.Email != Null && GSAEmailList.Domain_Extension__c == contact.Email.substringAfterLast('@')){
                    System.debug('+++1835+++:');                    
                    ContactThruNotFound2=true; 
                    system.debug('Canada is 2070'+ canOpp);                 
                    if(canOpp!='True'){                 
                        //Set boolean to true.
                        isOpportunityMeetsGSA=true;
                    }
                    system.debug('++1839++++ContactThruNotFound2:'+ContactThruNotFound2 
                                 +'\t +++++ContactThruNotFound:'+ContactThruNotFound
                                 +'\t +++++isOpportunityMeetsGSA:'+isOpportunityMeetsGSA);
                }else{
                    ContactThruNotFound=false;
                }           
            }
        }  
        System.debug('+++1846++++++ContactThruNotFound:'+ContactThruNotFound 
                     +'\t ++++ContactThruNotFound2:'+ContactThruNotFound2);            
        /*End*/
        if(ocr.Role==null){  contacterror=true;  
        }
        else
        {
            newcontactdisplay=false;
            finaldetailsdiplay=true;
            
            if(govtSegUser=='Government')   finalgsadetails=false; 
            else
                finalgsadetails=true;
            consavedisplay=true;
            conbackdisplay=true;
            conchangedisplay=false;
            contactbackbuttondisplay=false;
        }      
        return null;
    }
    
    public pagereference oldconsavebutton(){
        for(contactwrapper cw: contactList){
            if(cw.selected==true){
                if(cw.oppcont.Role!=null){
                    rolestring=cw.oppcont.Role;
                }
            }
        }
        for(contactwrapper cw: contactList){
            if(cw.selected!=true)
            {
                if(cw.oppcont.Role!=null){ primarycontactrolelist.add(cw.acc);  roleslist.add(cw.oppcont.Role);
                }
            }
        }
        if(primarycontactlist.size()>0 && rolestring != null){
            location=false;
            contactid=null;
            contactid = primarycontactlist[0].Id;
            oldcon=true;
            newcon=false;                 
            contactdisplay=false;
            finaldetailsdiplay=true;
            
            if(govtSegUser=='Government')  finalgsadetails=false; 
            else
                finalgsadetails=true;
            consavedisplay=true;
            conbackdisplay=true;
            conchangedisplay=false;
            contactbackbuttondisplay=false;
        }       
        else
        { 
            location=true;
            roleslist.clear();
            primarycontactrolelist.clear();
        }
        return null;
    }
    
    public void savedetails(){
        system.debug('+++ in save details +++ ');
        String leadCompany, leadName; 
        
        Validator_cls.setaddingProduct();
        system.debug('Validator_cls.isaddingProduct()'+Validator_cls.isaddingProduct());
        
        if(opportunity.IME_Vended_Unvended__c == 'Both'/*#16915  && (opportunity.Vended__c== null || opportunity.Unvended__c==null)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % Vended and % Unvended values.');
            ApexPages.addMessage(myMsg); 
        } 
        
        
        if(opportunity.IME_Vended_Unvended__c == 'Both' /* #16915  && (opportunity.Vended__c + opportunity.Unvended__c != 100)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both: Enter the percent of storage Vended and Un-vended. Values must equal 100%.');
            ApexPages.addMessage(myMsg);   
        }
        else
        {
            Savepoint sp = Database.setSavepoint();
            
            try{ 
                if(leadid!=null){
                    
                    system.debug('+++++ leadopportunity.IME_Vended_Unvended__c = '+ leadopportunity.IME_Vended_Unvended__c);
                    List<Lead_Competitor__c> leadComp = new List<Lead_Competitor__c>();
                    leadComp =[SELECT l.Owner_Email__c,l.Name,l.Lead_Owner_Email__c,l.Expiration_Notification_Date__c,
                               l.Competitor__c,l.Competitor_Expiration_Date__c FROM Lead_Competitor__c l WHERE l.Lead__c =: leadid];
                    
                    System.debug('---1808----dupevalue:'+dupevalue);
                    if(dupevalue!='true')
                    {
                        Lead ld = new Lead(
                            id=leadid,
                            OwnerId=leadownerid,
                            Company=leadaccountname
                        );
                        
                        update ld;                  
                        
                        System.debug('---1820----strStage:'+strStage);
                        if(strStage=='AddToExistingAccount'){
                            //Srinu: Commented out, Below is old SOQL on 09/19
                            //ac = [select Id, name, billingStreet, billingCity, billingState, billingPostalCode, NumberOfEmployees, AnnualRevenue, Industry, Description, Phone, Website from Account where name = :StrAccountName.Name Limit 1];
                            //Srinu: Newly added SOQL on 09/19.
                            ac = [select Id, name, billingStreet, billingCity, billingState, billingPostalCode, NumberOfEmployees, 
                                  AnnualRevenue, Industry, Description, Phone, Website from Account where Id=: oppaccid Limit 1];
                            
                            Database.LeadConvertResult lcr = this.convertLead(leadid, ac.Id, null, leadopportunityname, leadstatus, 
                                                                              leadownerid);
                            /*Database.LeadConvert lc = new database.LeadConvert();
lc.setLeadId(leadid);
lc.setAccountId(ac.Id);
lc.setOpportunityName(leadopportunityname);
lc.setConvertedStatus(leadstatus);
Database.LeadConvertResult lcr = Database.convertLead(lc);*/
                            
                            contactid=lcr.getContactId();
                            insertedoppid=lcr.getOpportunityId();
                            
                            
                            System.debug('1111@@@@ insertedoppid: '+ insertedoppid);
                            System.assert(lcr.isSuccess());
                            System.debug('1111@@@@ lcr is successful');
                            
                            /*Added on 2-12-2013*/
                            /*Start*/
                            List<Id> QuesIds = new List<id>();
                            List<String> PcklstAns = new List<String>();
                            Id GSAOpportunityId;
                            for(GSAWrapper testGSA: GSATestList){
                                System.debug('---1847--testGSA.picklistanswer:'+testGSA.picklistanswer);
                                system.debug('Canada is 2198'+ canOpp);
                                if(testGSA.picklistanswer=='Yes' && govtSegUser!='Government' &&canOpp!='True'){
                                    leadopportunity.GSA_Eligibility__c='GSA Eligible';
                                    system.debug('SETTING IN LINE 2187');
                                    System.debug('---1850------leadopportunity.GSA_Eligibility__c:'+leadopportunity.GSA_Eligibility__c);
                                }
                                QuesIds.add(testGSA.Gsarec.Id);
                                System.debug('---1853------QuesIds:'+QuesIds);
                                PcklstAns.add(testGSA.picklistanswer);
                                System.debug('---1855------PcklstAns:'+PcklstAns);
                            }
                            system.debug('Canada is 2209'+ canOpp);
                            if(leadopportunity.GSA_Eligibility__c != 'GSA Eligible' && govtSegUser!='Government'&&canOpp!='True'){
                                if(isThisGovtContact){     leadopportunity.GSA_Eligibility__c='GSA Eligible';
                                    system.debug('SETTING IN LINE 2199');
                                    System.debug('---1850.55------leadopportunity.GSA_Eligibility__c:'+leadopportunity.GSA_Eligibility__c);
                                }
                            }
                            else if(canOpp=='True'){
                                //Prevent GSA eligibility for Canadian opportunities
                                leadopportunity.GSA_Eligibility__c='Undetermined';
                                
                            }
                            
                            GSAOpportunityId = insertedoppid;                  
                            System.debug('----1858-----GSAOpportunityId:'+GSAOpportunityId);  
                            //Future methd call, which inserts Questions and Answers.
                            System.debug('---1860---calling future method to insert Opportunity Answers---------');   
                            if(govtSegUser!='Government')      clsOppObjects.InsertGSAAnswers(QuesIds, PcklstAns, GSAOpportunityId, govtSegUser );
                            /*End*/
                        }
                        else{ 
                            System.debug('----1944-----inside else Means Create New Account ----------'+leadid+'@'+leadopportunityname+'#'+leadstatus);  
                            Database.LeadConvertResult lcr = this.convertLead(leadid, null, null, leadopportunityname, leadstatus, leadownerid);
                            /*Database.LeadConvert lc = new database.LeadConvert();
lc.setLeadId(leadid);
lc.setOpportunityName(leadopportunityname);
lc.setConvertedStatus(leadstatus);
Database.LeadConvertResult lcr = Database.convertLead(lc);*/
                            
                            contactid=lcr.getContactId();
                            insertedoppid=lcr.getOpportunityId();
                            if(String.isBlank(oppaccid))
                                oppaccid = lcr.getAccountId();
                            System.debug('2222@@@@ insertedoppid: '+ insertedoppid);
                            System.assert(lcr.isSuccess());
                            
                            /*Added on 2-12-2013*/
                            /*Start*/
                            List<Id> QuesIds = new List<id>();
                            List<String> PcklstAns = new List<String>();
                            Id GSAOpportunityId;
                            for(GSAWrapper testGSA: GSATestList){
                                System.debug('---1883--testGSA.picklistanswer:'+testGSA.picklistanswer);
                                if(testGSA.picklistanswer=='Yes'){
                                    system.debug('Canada is 2253'+ canOpp);
                                    if(canOpp!='True' && govtSegUser!='Government'){ leadopportunity.GSA_Eligibility__c='GSA Eligible';
                                        system.debug('SETTING IN LINE 2241');
                                        System.debug('---1886------leadopportunity.GSA_Eligibility__c:'+leadopportunity.GSA_Eligibility__c);
                                    }
                                }
                                QuesIds.add(testGSA.Gsarec.Id);
                                System.debug('---1889------QuesIds:'+QuesIds);
                                PcklstAns.add(testGSA.picklistanswer);
                                System.debug('---1891------PcklstAns:'+PcklstAns);
                            }
                            system.debug('Canada is 2265'+ canOpp);
                            if(leadopportunity.GSA_Eligibility__c != 'GSA Eligible'  && govtSegUser!='Government'&& canOpp!='True'){
                                if(isThisGovtContact){        leadopportunity.GSA_Eligibility__c='GSA Eligible';
                                    system.debug('SETTING IN LINE 2253');
                                    System.debug('---1891.55------leadopportunity.GSA_Eligibility__c:'+leadopportunity.GSA_Eligibility__c);
                                }
                            }
                            else if(canOpp=='True'){
                                //Prevent GSA eligibility for Canadian opportunities
                                leadopportunity.GSA_Eligibility__c='Undetermined';
                                
                            }
                            GSAOpportunityId = insertedoppid;                  
                            System.debug('----1894-----GSAOpportunityId:'+GSAOpportunityId);  
                            //Future methd call, which inserts Questions and Answers.
                            System.debug('---1896---calling future method to insert Opportunity Answers---------');                  
                            clsOppObjects.InsertGSAAnswers(QuesIds, PcklstAns, GSAOpportunityId, govtSegUser );
                            /*End*/
                        }
                        
                        /*CloudFountain Inc.
Contact Role logic has been moved to future method               
*/
                        leadCompany = ld.Company;
                        System.debug('ld.Company');
                        leadName = leadopportunity.Name;
                        System.debug('leadopportunity.Name');
                        String sContactName = '' ;
                        //Creating a Contact Role from future method
                        
                        clsOppObjects.createContactRole(contactid, insertedoppid, rolestring, sendMail, leadName, leadCompany, oppaccid); 
                    }
                    else{
                        System.debug('-------------inside else means Dupe=True------');
                        //dupe lead
                        //Lead ld = [select  OwnerId, IsConverted, LastName, FirstName, Company, Street,City,State,PostalCode,NumberOfEmployees,AnnualRevenue,Country, Industry,Description,Phone,Website,MobilePhone,Email,Title,Fax,LeadSource from Lead where Id =:leadid];
                        Lead ld = sObjLead;   
                        leadownerid=ld.OwnerId;
                        String sOppContId, sAccId;
                        if(oppconid!=null){ 
                            /*Srinu/Madhu: Commented out becoz Account Name has been assigned to 'Id' variable which is expecting 'AccountId'*/
                            //sAccId = leadAccountName;                
                            /*Srinu/Madhu: Added a assignment statement to pass 'AccountId' to 'Id' Variable*/
                            sAccId = oppaccid;                
                            sOppContId= oppconid;
                        }
                        else{
                            sAccId = oppaccid;
                        }
                        
                        Database.LeadConvertResult lcr = this.convertLead(leadid, sAccId, sOppContId, leadopportunityname, leadstatus, leadownerid);
                        contactid=lcr.getContactId();          
                        insertedoppid=lcr.getOpportunityId();
                        System.debug('----2045-------insertedoppid:'+insertedoppid);
                        System.assert(lcr.isSuccess());
                        /*Added on 2-12-2013*/
                        /*Start*/
                        List<Id> QuesIds = new List<id>();
                        List<String> PcklstAns = new List<String>();
                        Id GSAOpportunityId;
                        for(GSAWrapper testGSA: GSATestList){
                            System.debug('---2053--testGSA.picklistanswer:'+testGSA.picklistanswer);
                            if(testGSA.picklistanswer=='Yes'){
                                system.debug('Canada is 2329'+ canOpp);
                                if(canOpp!='True'  && govtSegUser!='Government'){
                                    leadopportunity.GSA_Eligibility__c='GSA Eligible';
                                    system.debug('SETTING IN LINE 2315');
                                    System.debug('---2055------leadopportunity.GSA_Eligibility__c:'+leadopportunity.GSA_Eligibility__c);
                                }}
                            QuesIds.add(testGSA.Gsarec.Id);
                            System.debug('---2059------QuesIds:'+QuesIds);
                            PcklstAns.add(testGSA.picklistanswer);
                            System.debug('---2061------PcklstAns:'+PcklstAns);
                        }
                        system.debug('Canada is 2340'+ canOpp);
                        if(leadopportunity.GSA_Eligibility__c != 'GSA Eligible'){
                            if(isThisGovtContact){
                                system.debug('Canada is 2343'+ canOpp);
                                if(canOpp!='True' && govtSegUser!='Government'){
                                    leadopportunity.GSA_Eligibility__c='GSA Eligible';
                                    system.debug('SETTING IN LINE 2327');
                                    System.debug('---2061.55------leadopportunity.GSA_Eligibility__c:'+leadopportunity.GSA_Eligibility__c);
                                }}
                        }
                        GSAOpportunityId = insertedoppid;                  
                        System.debug('----2064-----GSAOpportunityId:'+GSAOpportunityId);  
                        //Future methd call, which inserts Questions and Answers.
                        System.debug('---2066---calling future method to insert Opportunity Answers---------');                  
                        clsOppObjects.InsertGSAAnswers(QuesIds, PcklstAns, GSAOpportunityId, govtSegUser );
                        /*End*/
                        
                        //Creating a Contact Role from future method
                        clsOppObjects.createContactRole(contactid, insertedoppid, rolestring, sendMail='false', leadName, leadCompany, oppaccid);                    
                        
                    }   
                    
                    if(!leadComp.isEmpty()){
                        List<Opportunity_Competitor__c> oppComp = new List<Opportunity_Competitor__c>();
                        for(integer i=0; i<leadComp.size();i++){
                            Opportunity_Competitor__c oppCompInsert = new Opportunity_Competitor__c(
                                Competitor__c=leadComp[i].Competitor__c,
                                Competitor_Expiration_Date__c=leadComp[i].Competitor_Expiration_Date__c,
                                Expiration_Notification_Date__c=leadComp[i].Expiration_Notification_Date__c,
                                Opportunity__c=insertedoppid,
                                Opportunity_owner_Email__c=leadComp[i].Owner_Email__c
                            );
                            oppComp.add(oppCompInsert);
                        }
                        insert oppComp;
                        delete leadComp;
                        System.debug('queries used 1: ' + Limits.getQueries());
                    }
                    //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
                    System.debug('KAB-savedetails 9999 - leadopportunity.IM_Booked_Date__c:'+ leadopportunity.IM_Booked_Date__c +'\t leadopportunity:'+leadopportunity);
                    schOppClosedDate = leadopportunity.IM_Booked_Date__c;
                    System.debug('-------queries used test: ' + Limits.getQueries());           
                    
                }
                else{
                    opportunity.OwnerId=UserInfo.getUserId();
                    System.debug('---1950--inside else---opportunity.Id:'+opportunity.Id);
                   if(opportunity.Id==null){
                       //Commented as part of #16915
                       /* if(bundleexists==true){
                            opportunity.Bundle__c=selectedbundle;
                            System.debug('----1953----opportunity.Bundle__c:'+opportunity.Bundle__c);
                        }
                        if(otherinformation!=null){
                            opportunity.Bundle_Description__c = otherinformation;
                            System.debug('----1958----opportunity.Bundle_Description__c:'+opportunity.Bundle_Description__c);
                        }*/
                        if(campid!=null){
                            opportunity.CampaignId=campid;
                            System.debug('----1962----opportunity.CampaignId:'+opportunity.CampaignId);
                        }
                        /*Added on 2-11-2013*/
                        /*Start*/
                        List<Id> QuesIds = new List<id>();
                        List<String> PcklstAns = new List<String>();
                        Id GSAOpportunityId;  
                        
                        for(GSAWrapper testGSA: GSATestList){
                            System.debug('---1967--testGSA.picklistanswer:'+testGSA.picklistanswer);
                            if(testGSA.picklistanswer=='Yes'){
                                system.debug('Canada is 2408'+ canOpp);
                                if(canOpp!='True' && govtSegUser!='Government'){
                                    system.debug('Canada is '+ canOpp);
                                    opportunity.GSA_Eligibility__c='GSA Eligible';
                                    system.debug('SETTING IN LINE 2391');
                                    System.debug('---1967.55------oppty.GSA_Eligibility__c:'+opportunity.GSA_Eligibility__c);
                                }}
                            QuesIds.add(testGSA.Gsarec.Id);
                            System.debug('---2658------QuesIds:'+QuesIds);
                            PcklstAns.add(testGSA.picklistanswer);
                            System.debug('---2660------PcklstAns:'+PcklstAns);                  
                            
                        }
                        
                        if(opportunity.GSA_Eligibility__c != 'GSA Eligible'){
                            System.debug('++2098++++isThisGovtContact:'+isThisGovtContact);
                            if(isThisGovtContact==True){
                                system.debug('Canada is 2425'+ canOpp);
                                if(canOpp!='True' && govtSegUser!='Government'){
                                    system.debug('Canada is '+ canOpp);
                                    opportunity.GSA_Eligibility__c='GSA Eligible';
                                    system.debug('SETTING IN LINE 2406');
                                    System.debug('---2098.55------leadopportunity.GSA_Eligibility__c:'+opportunity.GSA_Eligibility__c);
                                } }
                        }         
                        else if(canOpp=='True'){
                            //Prevent GSA eligibility for Canadian opportunities
                            opportunity.GSA_Eligibility__c='Undetermined';
                            
                        }
                        System.debug('---1964----opportunity:'+opportunity);
                        system.debug('Opportunity GSA'+opportunity.GSA_Eligibility__c);
                        insert opportunity; 
                        
                        /*Case Number: 01389380
Description: Added logic to add competi on opportunity wizrad
*/
                        /* commented by Pratap on 4th Sep 2017. Case 05711602: Vended/Unvended Field on RM opptys
if(oppcomp.Competitor__c!=null){
oppcomp.Opportunity__c=Opportunity.Id;
insert oppcomp;
}
*/
//CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
                        GSAOpportunityId = Opportunity.Id;                  
                        
                        //Future methd call, which inserts Questions and Answers.
                        System.debug('------calling future method to insert Opportunity Answers---------');                  
                        clsOppObjects.InsertGSAAnswers(QuesIds, PcklstAns, GSAOpportunityId, govtSegUser );
                        /*End*/
                        schOppClosedDate=opportunity.IM_Booked_Date__c;
                        if(newcon==true){
                            contact.AccountId=opportunity.AccountId;
                            insert contact;
                            contactid=contact.Id;
                        }
                        insertedoppid=opportunity.Id;
                        clsOppObjects.createContactRole(contactid, insertedoppid, rolestring, sendMail='false', leadName, leadCompany, oppaccid);
                        
                        List<String> lstContactIds = new List<String>();
                        List<String> lstRoles = new List<String>();
                        for(Integer i=0;i<primarycontactrolelist.size();i++){
                            if(primarycontactrolelist[i].Id != contactid){                            
                                lstContactIds.add(primarycontactrolelist[i].Id);
                                lstRoles.add(roleslist[i]);
                            }
                        }
                        
                        clsOppObjects.createListContactRole(lstContactIds, opportunity.Id, lstRoles);
                    }
                } 
                //madhu added on 1/16/13
                if(insertedoppid!=null){
                    finaldetailsdiplay=false;
                    finalgsadetails=false;
                    showfinalpage=true; 
                }      
                
                /*Ketan Benegal - Line Items Insert Start*/ 
                /*Array of Product, QuestionId, FinalAnswer*/
                List<String> lstProdQuesAns = new List<String>(); 
                List<String> lstPbeIds = new List<String>();
                List<String> lstStrParams = new List<String>();
                System.debug('111111111 Creating Questions and Answers');
                for(integer i=0; i<testlistwrap.size(); i++){
                    lstPbeIds.add(testlistwrap[i].complist[0].pe.Id);              
                    if(testlistwrap[i].questions.size()>0)
                    {
                        System.debug('2222222222 Creating Questions and Answers');
                        for(questionwrapper qs: testlistwrap[i].questions)
                        {
                            System.debug('-------1997-------qs.oqc.Id:'+qs.oqc.Id);
                            lstProdQuesAns.add(testlistwrap[i].complist[0].pe.Product2.Id+';'+qs.oqc.Id+';'+qs.finalanswer);
                        }
                    }
                }
                
                System.debug('**********In OppEntry lstProdQuesAns:' + lstProdQuesAns);
                if(leadid!=null)
                    
                {   system.debug('+++ comp sobj++'+sObjLead.Competitively_Vended__c);
                 if(sObjLead.Competitively_Vended__c !=null) { leadopportunity.IME_Vended_Unvended__c = sObjLead.Competitively_Vended__c;
                  system.debug('+++ comp sobj++'+sObjLead.Competitively_Vended__c); }
                 /* #16915 if(sObjLead.Vended__c !=null)   { leadopportunity.Vended__c = sObjLead.Vended__c;
                     system.debug('+++ comp sobj++'+sObjLead.Competitively_Vended__c);
                 }
                 if(sObjLead.Unvended__c !=null){    leadopportunity.Unvended__c=sObjLead.Unvended__c; 
                     system.debug('+++ comp sobj++'+sObjLead.Competitively_Vended__c);
                 } */
                 //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
                 if(String.isBlank(leadopportunity.Upsell_Customer_ID__c)) {     leadopportunity.Upsell_Customer_ID__c = null;
                 }
                 lstStrParams.add(insertedoppid);//0
                 lstStrParams.add(leadownerid);//1
                 lstStrParams.add(leadopportunity.StageName);//2
                 lstStrParams.add(String.valueOf(leadopportunity.Probability));//3
                 lstStrParams.add(String.valueOf(leadopportunity.CloseDate));//4
                 lstStrParams.add(String.valueOf(leadopportunity.IM_Booked_Date__c));//5
                 lstStrParams.add(leadopportunity.IM_Competitor__c);//6
                 lstStrParams.add(leadopportunity.Type);//7
                 lstStrParams.add(leadopportunity.IM_Category__c);//8
                 lstStrParams.add(leadopportunity.IM_Sales_Event__c);//9
                 lstStrParams.add(leadopportunity.Description);//10
                 lstStrParams.add(String.valueOf(leadopportunity.IM_Up_Sell_Quantity__c));//11
                 //  lstStrParams.add(leadopportunity.IM_Up_Sell_Sold_To__c);
                 lstStrParams.add(leadopportunity.Upsell_Customer_ID__c);//12
                 lstStrParams.add(leadopportunity.IM_Up_Sell_Detail__c);//13
                 lstStrParams.add(leadopportunity.IM_Unit_of_Measure__c);//14
                 //lstStrParams.add((sInsideSales != 'false' ? this.leadownerid: null));//15  
                 lstStrParams.add(String.valueOf(bundleexists));//16  --> 15
                 lstStrParams.add(selectedbundle);//17  --> 16
                 lstStrParams.add(otherinformation);//18 --> 17
                 
                 
                 
                 //Added on 2-12-2012
                 System.debug('---1933-----leadopportunity.GSA_Eligibility__c:'+leadopportunity.GSA_Eligibility__c);
                 lstStrParams.add(leadopportunity.GSA_Eligibility__c); //18
                 
                 /*
Developer  : Sandhya Ramesh
Date       : 04/10/2015
Case       : 03474925
Description: Inserting Vended, unvended params to new opportunity.
*/
                 /* Start */   
                 lstStrParams.add(leadopportunity.IME_Vended_Unvended__c); //19
                /* lstStrParams.add(String.valueOf(leadopportunity.Vended__c)); //20 
                 lstStrParams.add(String.valueOf(leadopportunity.Unvended__c)); *///21
                 lstStrParams.add(leadopportunity.Account_Plan__c);//22
                 //Case# 05491582, Added by pratap, We want to retain the ability for drivers to submit sales leads, 
                 //so we must create a new mechanism for them to record the lead information and transmit it 
                 //to IRM sales systems 
                 lstStrParams.add(leadopportunity.Driver_Employee_Id__c);//23
                 lstStrParams.add(String.valueOf(leadopportunity.Primary_Product_Line__c));//24
                 lstStrParams.add(leadopportunity.InSight_Opportunities__c);//25
                 System.debug('Insight Opporty Val >>>'+lstStrParams[24] );
                 //End of Case# 05491582
                 /*End*/
                 System.debug('----1935----lstStrParams:'+lstStrParams +'\t insertedoppid:'+insertedoppid +'\t pricelist:'+pricelist +'\t quantitylist:'+quantitylist +'\t lstPbeIds:'+lstPbeIds +'\t lstProdQuesAns:'+lstProdQuesAns +'\t schOppClosedDate:'+schOppClosedDate);
                 //clsOppObjects.createOpportunityItems( insertedoppid,  pricelist,  quantitylist,  lstPbeIds,  lstProdQuesAns, schOppClosedDate, lstStrParams );
                 clsOppObjects.createOpportunityItems( insertedoppid,   quantitylist, TotalPriceList, lstPbeIds,  lstProdQuesAns, schOppClosedDate, lstStrParams ); // Modified for RxQ
                }else{
                    System.debug('----1938----lstStrParams:'+lstStrParams +'\t insertedoppid:'+insertedoppid +'\t pricelist:'+pricelist +'\t quantitylist:'+quantitylist +'\t lstPbeIds:'+lstPbeIds +'\t lstProdQuesAns:'+lstProdQuesAns +'\t schOppClosedDate:'+schOppClosedDate);
                    //clsOppObjects.createOpportunityItems( insertedoppid,  pricelist,  quantitylist,  lstPbeIds,  lstProdQuesAns, schOppClosedDate, lstStrParams );
                    clsOppObjects.createOpportunityItems( insertedoppid,  quantitylist,  TotalPricelist, lstPbeIds,  lstProdQuesAns, schOppClosedDate, lstStrParams ); //Modified for RxQ
                }  
                System.debug('queries used 3: ' + Limits.getQueries());
                try{
                    if(oc.Competitor__c!=null){      oc.Opportunity__c = insertedoppid; insert oc;}
                } catch (exception ex){
                    system.debug('oc exception thrown due to blank competitor. Can ignore.');
                }
            }
            catch(Exception e)
            {
                System.debug('e.getTypeName():'+ e.getTypeName());
                if(e.getTypeName() == 'Dmlexception'){
                    Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, e.getDmlMessage(0));
                    Apexpages.addMessage(errMsg1);
                }else{
                    ApexPages.addMessages(e);            
                }
                Database.rollback(sp);        
            }
            
            if(ApexPages.hasMessages())
            {
                ApexPages.Message[] msgs = Apexpages.getMessages();
                System.debug('Error Messages: ' + msgs[0].getDetail());
                // return null;
            } 
        }
        
    }
    public Pagereference  returnOppPage(){
        PageReference prf1 = new PageReference('/'+insertedoppid);
        System.debug('here insertedoppid: '+ insertedoppid + '\tprf1' + prf1);
        return prf1;
    }
    public List<SelectOption>getBundleslist()
    {      
        return bundleslist;
    }    
    
    
    public List<SelectOption> getProductgrouplist()
    {
        List<SelectOption> productgrp = new List<SelectOption>();
        List<String> op = new List<String>();
        //List<Product2> groupedResults = [select IM_Product_Class__c from Product2 where IM_Product_Class__c!=null and IM_Product_Class__c!='Document Management Solutions' and CurrencyIsoCode in ('USD', 'CAD') and IsActive=true];
        /*Developer Name: Madhu Paladugu
Date          : 2/27/13
Case Number   : 01192467
*/
        List<PricebookEntry> groupedResults = [select Product2.IM_Product_Class__c,  Product2.IM_Unit_of_Measure__c,Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2.IM_Product_Class__c!=null and Product2.IM_Product_Class__c!='Document Management Solutions' and CurrencyIsoCode =:usercurrency and Product2.IsActive=true and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code')];
        // List<PricebookEntry> groupedResults = [select Product2.IM_Product_Class__c from PricebookEntry where Product2.IM_Product_Class__c!=null and Product2.IM_Product_Class__c!='Document Management Solutions' and CurrencyIsoCode =:usercurrency and Product2.IsActive=true];
        for (integer i=0; i< groupedResults.size() ; i++){                   
            op.add(groupedResults[i].Product2.IM_Product_Class__c);                    
        }
        Set<String> groupedResultsSet = new Set<String>(Op);
        List<String> listStrings = new List<String>(groupedResultsSet);
        listStrings.sort();
        for (integer i=0; i< listStrings.size() ; i++){
            productgrp.add(new SelectOption(listStrings[i] ,listStrings[i]));
        }
        return productgrp;
    }
    public List<SelectOption> getBundletypelist()
    {
        List<SelectOption> bundletypelist = new List<SelectOption>(); 
        System.debug('###############prodgroupId'+ prodgroupId);       
        String s = prodgroupId;
        //System.debug('###############prodgrpname.Id:'+ prodgrpname.Id);
        String subs=s.substring(0,15);
        List<String> op = new List<String>();
        List<Product_Bundle__c> groupedResults = [select Bundle_Type__c from Product_Bundle__c where Bundle_Type__c!=null and Product_Group_ID__c=:subs];
        
        for (integer i=0; i< groupedResults.size() ; i++)   {                                 
            op.add(groupedResults[i].Bundle_Type__c);                    
        }
        Set<String> groupedResultsSet = new Set<String>(Op);
        List<String> listStrings = new List<String>(groupedResultsSet);
        listStrings.sort();
        for (integer i=0; i< listStrings.size() ; i++)   {             
            bundletypelist.add(new SelectOption(listStrings[i] ,listStrings[i]));                    
        }
        return bundletypelist;
    }
    public List<SelectOption> getPricebooklist()
    {
        return pricegrp;
    }
    public List<Opportunity_Questions__c> opportunityquestions = new List<Opportunity_Questions__c>();
    public List<contactwrapper> contactList = new List<contactwrapper>();
    //Contact Search
    public List<contactwrapper> SearchcontactList = new List<contactwrapper>();
    public List<Contact> primarycontactlist = new List<Contact>();
    public List<Contact> primarycontactrolelist = new List<Contact>();
    public List<pricebookwrapper> pricebookList = new List<pricebookwrapper>();
    public List<pricebookwrapper> newpricebookList = new List<pricebookwrapper>();
    public List<pricebookwrapper> bundleproductlistwrap = new List<pricebookwrapper>();
    public List<PricebookEntry> pricebookentrylist = new List<PricebookEntry>();
    public List<SelectOption> pricegrp = new List<SelectOption>();
    public List<PricebookEntry> bundleproductlist = new List<PricebookEntry>();
    public List<PricebookEntry> newpricebookentrylist = new List<PricebookEntry>();
    public List<PricebookEntry> selectedbundleproductlist = new List<PricebookEntry>();
    public List<PricebookEntry> additionalproductlist = new List<PricebookEntry>();
    public List<completelistwrapper> completelistwrap = new List<completelistwrapper>();
    public List<testlistwrapper> testlistwrap = new List<testlistwrapper>();
    public List<PricebookEntry> completelist = new List<PricebookEntry>();
    public List<secondproductwrapper> secondproductList = new List<secondproductwrapper>();
    public List<PricebookEntry> secondaryproductlist = new List<PricebookEntry>();
    public List<Contact> leadcontacts = new List<Contact>();
    public List<String> roleslist = new List<String>();
    /*Added on 1-31-2013*/
    /*Start*/
    public List<Opportunity_Questions__c > GSAQuestions=new List<Opportunity_Questions__c >();
    public List<GSAWrapper> GSATestList =new  List<GSAWrapper>();
    /*End*/
    
    Public static Boolean WhenClickedOnGo=false;
    public Boolean getWhenClickedOnGo(){return WhenClickedOnGo; }
    
    public List<contactwrapper> getPrimarycontacts(){
        if(contactdisplay==true &&(j==0))
        {   
            String TempQuery;
            //Added warning message incase of user tries contact search with wrong data.
            //Case Number: 01743451
            try{                
                //Modified SOQL. Added contact fields for Search functionality
                //Case Number: 01654528
                
                //Modified By Venkat for Case #02424305
                List<String> accIdList = new List<String>();
                List<String> accImgaId = new List<String>();
                system.debug('opportunity.AccountId----'+opportunity.AccountId);
                Account accIds =[Select Id, imga_lookup__c from Account where Id =:opportunity.AccountId];
                system.debug('accIds-----'+accIds);
                system.debug('accIds.imga_lookup__c-----'+accIds.imga_lookup__c);
                if(accIds.imga_lookup__c != null)
                {
                    List<Account> accImgaLst = [Select Id, imga_lookup__c from Account where imga_lookup__c =:accIds.imga_lookup__c];
                    for(Account accCon:accImgaLst) { if(accCon.imga_lookup__c != null)       accImgaId.add(accCon.Id);
                    }
                    system.debug('accImgaId-----'+accImgaId);
                    TempQuery='Select Id, FirstName, LastName, AccountId, IM_Functional_Area__c, IM_Job_Level__c, IM_Academic_Title__c, Title, Email, IM_Language_Preference__c, IM_Responsible_For__c, Phone, MobilePhone, Fax, IM_Timezone__c, Name, IM_Role__c, (Select Id, Role From AccountContactRoles) From Contact where AccountId IN: accImgaId and ( FirstName like \'%'+ContactSearchString+'%\'' +' OR LastName like \'%'+ContactSearchString+'%\''+ ' OR Email like \'%'+ContactSearchString+'%\' ) limit 200';           
                    
                }
                else
                { 
                    system.debug('opportunity.AccountId--te--'+opportunity.AccountId);
                    TempQuery='Select Id, FirstName, LastName, AccountId, IM_Functional_Area__c, IM_Job_Level__c, IM_Academic_Title__c, Title, Email, IM_Language_Preference__c, IM_Responsible_For__c, Phone, MobilePhone, Fax, IM_Timezone__c, Name, IM_Role__c, (Select Id, Role From AccountContactRoles) From Contact where AccountId IN (\''+opportunity.AccountId +'\')' + ' and ( FirstName like \'%'+ContactSearchString+'%\'' +' OR LastName like \'%'+ContactSearchString+'%\''+ ' OR Email like \'%'+ContactSearchString+'%\' ) limit 200';           
                }
                
                //Modification End By Venkat for Case #02424305
                
                System.debug('---2342---TempQuery:'+TempQuery);        
                for(Contact c: DataBase.query(TempQuery)){
                    contactList.add(new contactwrapper(c));                
                    System.debug('---2342---c.Email:'+c.Email);               
                }
                j++; 
            }catch(Exception e){         ContactSearchErrorDisplay=true; 
                System.debug('+++2377++++++ContactSearchErrorDisplay:'+ContactSearchErrorDisplay);            
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'please redefine your search.'));               
                //return null;
            }
            
        }
        return contactList;
        
    }
    //Contact Search
    //Case Number: 01654528
    /*Start*/
    public pageReference doSearchOncontactRole(){
        System.debug('++++++inside doSearchOncontactRole++++++:'+contactList);
        contactList.clear();
        j=0;
        ContactSearchErrorDisplay=false;
        System.debug('++2404+++making boolean to false and calling getPrimaryContacts method+++++ContactSearchErrorDisplay:'+ContactSearchErrorDisplay);
        getPrimarycontacts();        
        return null;
    }
    public pageReference ClearSearchOnContactRole(){
        System.debug('++++++inside ClearSearchOnContactRole++++++:'+contactList);
        contactList.clear();
        j=0;
        ContactSearchString='';
        ContactSearchErrorDisplay=false;
        System.debug('++2414+++making boolean to false and calling getPrimaryContacts method+++++ContactSearchErrorDisplay:'+ContactSearchErrorDisplay);
        getPrimarycontacts();
        return null;
    }
    /*End*/
    public List<Contact> getLeadcontacts(){
        
        if(c==0)
        {
            Contact con= [Select Id From Contact limit 1];
            leadcontacts.add(con);
            c++;
        }
        return leadcontacts;
    }
    public List<pricebookwrapper> getPricebookentries(){
        
        if((k==0)&& pricebookdisplay==true)
        {        
            System.debug('----2359----pricebookentries:'+pricebookentries);
            for(PricebookEntry c: pricebookentries)       pricebookList.add(new pricebookwrapper(c));
            
            k++;
        }
        System.debug('---2374-----pricebookList:'+pricebookList);
        return pricebookList;
    }
    public List<pricebookwrapper> getNewpricebookentries(){
        if((add==0)&& addprimaryprod==true)
        {
            for(PricebookEntry e: newpricebookentries)         newpricebookList.add(new pricebookwrapper(e));
            add++;
        }
        System.debug('---2383-----newpricebookList:'+newpricebookList);
        return newpricebookList;
    }
    public List<pricebookwrapper> getBundleproductlistwrap(){
        
        if(a==0 && bundleproductlistdisplay==true)
        {
            System.debug('---2389-----bundleproductlist:'+bundleproductlist);
            for(PricebookEntry e: bundleproductlist)        bundleproductlistwrap.add(new pricebookwrapper(e));
            System.debug('---2392-----bundleproductlistwrap:'+bundleproductlistwrap);
            a++;
        }
        System.debug('---2397-----bundleproductlistwrap:'+bundleproductlistwrap);
        return bundleproductlistwrap;
    }
    public List<completelistwrapper> getCompletelistwrap()
    {
        return completelistwrap;
    }
    public List<testlistwrapper> getTestlistwrap()
    {
        return testlistwrap;
    }
    public List<secondproductwrapper> getSecondaryproducts(){
        if(secprodisplay==true && bundleexists==false &&(l==0))
        {
            /*Developer Name: Madhu Paladugu
Date          : 2/27/13
Case Number   : 01192467
*/
            // for(PricebookEntry pb : [select  Id, CurrencyIsoCode,  Product2.IM_Unit_of_Measure__c,Product2.NumberOfRevenueInstallments, Product2.RevenueInstallmentPeriod, Product2.RevenueScheduleType, ProductCode, Product2.Id, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.IM_Business_Line__c, Product2.IM_Revenue_Type__c, Product2.IM_Product_Class__c, Product2.IM_Product_Line__c, Product2Id, Product2.Name, Name, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2.Secondary_Product_Allowed__c = true and CurrencyIsoCode=:usercurrency and IsActive = true and Pricebook2Id =:pricebookid and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code')  order by Name])
            // For Rate x Quantity scheduling disable, replace above query with below query      
            for(PricebookEntry pb : [select  Id, CurrencyIsoCode, ProductCode, Product2.Id,  Product2.IM_Unit_of_Measure__c, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.IM_Business_Line__c, Product2.IM_Revenue_Type__c, Product2.IM_Product_Class__c, Product2.IM_Product_Line__c, Product2Id, Product2.Name, Name, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2.Secondary_Product_Allowed__c = true and CurrencyIsoCode=:usercurrency and IsActive = true and Pricebook2Id =:pricebookid and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code')  order by Name])      secondproductList.add(new secondproductwrapper(pb));
            l++;
        }
        if(secprodisplay==true && bundleexists==true &&(b==0))
        {            
            /*Developer Name: Madhu Paladugu
Date          : 2/27/13
Case Number   : 01192467
*/
            //for(PricebookEntry pb : [select  Id, CurrencyIsoCode,  Product2.IM_Unit_of_Measure__c, Product2.NumberOfRevenueInstallments, Product2.RevenueInstallmentPeriod, Product2.RevenueScheduleType, ProductCode, Product2.Id, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.IM_Business_Line__c, Product2.IM_Revenue_Type__c, Product2.IM_Product_Class__c, Product2.IM_Product_Line__c, Product2Id, Product2.Name, Name, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2.Secondary_Product_Allowed__c = true and CurrencyIsoCode=:usercurrency and IsActive = true and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') and Pricebook2Id =:prodgroupId order by Name])
            // For Rate x Quantity scheduling disable, replace above query with below query 
            for(PricebookEntry pb : [select  Id, CurrencyIsoCode,   ProductCode, Product2.Id,  Product2.IM_Unit_of_Measure__c, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.IM_Business_Line__c, Product2.IM_Revenue_Type__c, Product2.IM_Product_Class__c, Product2.IM_Product_Line__c, Product2Id, Product2.Name, Name, Pricebook2.IsStandard, Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2.Secondary_Product_Allowed__c = true and CurrencyIsoCode=:usercurrency and IsActive = true and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') and Pricebook2Id =:prodgroupId order by Name])
                secondproductList.add(new secondproductwrapper(pb));
            b++;
        }
        return secondproductList;
    }
    public List<Product2> getTestlist()
    {       
        return testlist;
    }
    
    public List<PricebookEntry> GetSecondaryproductlist(){
        System.debug('-----in GetSecondaryproductlist Method----2430----secondaryproductlist:'+secondaryproductlist);        
        if(secondaryproductlist.size()>0) return secondaryproductlist;  else   return null;
    }
    public List<PricebookEntry> getCompleteproductlist()
    {
        System.debug('-----in getCompleteproductlist Method----2438----completelist:'+completelist);
        return completelist;
    }
    
    
    public List<Contact> GetPrimarycontactlist(){
        if(primarycontactlist.size()>0)
            return primarycontactlist;
        else
            return null;
    }
    
    public List<PricebookEntry> getPricebookentrieselected()
    {  
        System.debug('-----in getPricebookentrieselected Method----2466----pricebookentrylist:'+pricebookentrylist );
        
        if(pricebookentrylist.size()>0)   return pricebookentrylist;
        else
            return null;
    }
    public class contactwrapper{
        public Contact acc{get; set;}
        public Id contactexist =ApexPages.currentPage().getParameters().get('conid');        
        public Boolean selected {get; set;}
        public OpportunityContactRole oppcont;
        public OpportunityContactRole getOppcont()
        {
            if(oppcont == null) 
                oppcont = new OpportunityContactRole();
            return oppcont;
        }
        
        public contactwrapper(Contact a){
            acc = a;
            if(acc.Id==contactexist)  selected = true;  else     selected =false;
        }
    }
    public PageReference getSelected(){
        primarycontactlist.clear();
        for(contactwrapper cawrapper : contactList)
            if(cawrapper.selected == true)        
            primarycontactlist.add(cawrapper.acc);   
        return null;
    }    
    /*Added on 1-31-2013*/
    /*Start*/
    public List<GSAWrapper> getGSATestList(){
        System.debug('--------calling getGSATestList method-------isThisNARACFROpportunity:'+isThisNARACFROpportunity);
        List<GSA_Contact_Email_List__c> GSAsettings = GSA_Contact_Email_List__c.getall().values();
        if(leadid == NULL){
            if(Opportunity.AccountId != Null){
                Account acc = [Select Id, Name, Account_Segment__c,Account_Sub_Segment__c From Account where Id =: Opportunity.AccountId];
                System.debug('--748--acc:'+acc);
                if(acc.Account_Segment__c =='Vertical' && acc.Account_Sub_Segment__c =='Government'){
                    system.debug('+++++++++++inside if account+++++++'+acc);
                    isThisGovtOpportunity=true;
                    System.debug('------here Making True to First Question--------isThisGovtOpportunity:'+isThisGovtOpportunity);
                    //isQuestionEditable=true;
                }          
            }
        }else {
            System.debug('--2834---oppconid:'+oppconid);
            if(oppconid == Null){
                if(leadcontEmail != Null){
                    for(GSA_Contact_Email_List__c GSAEmailList: GSAsettings){
                        if(GSAEmailList.Domain_Extension__c == leadcontEmail.substringAfterLast('@')){
                            System.debug('------2825--LC---contact domain contains an extension listed in custom settings-------------');
                            isThisGovtContact = true;
                            System.debug('----2827-----isThisGovtContact:'+isThisGovtContact);                            
                            break;
                        }               
                    }
                }
            }else {
                System.debug('-----2852---not null means selecting contact from potential contacts---contDomain:'+contDomain);
                if(contDomain=='true'){  isThisGovtContact = true;
                    System.debug('---2855----isThisGovtContact:'+isThisGovtContact);
                }else{
                    isThisGovtContact = false;
                    System.debug('---2858----isThisGovtContact:'+isThisGovtContact);
                }
            }
            
            if(leadopportunity.AccountId != Null){
                Account acc1 = [Select Id, Name, Account_Segment__c,Account_Sub_Segment__c From Account where Id =: opportunity.AccountId];
                System.debug('--748--acc1:'+acc1);
                if(acc1.Account_Segment__c =='Vertical' && acc1.Account_Sub_Segment__c =='Government'){
                    system.debug('+++++++++++inside if account+++++++'+acc1);
                    isThisGovtOpportunity=true;
                    System.debug('------here Making True to First Question--------isThisGovtOpportunity:'+isThisGovtOpportunity);
                    //isQuestionEditable=true;
                }           
            }
            //Srinu:Added on 3-1-2013
            System.debug('---check value to true---govopty:'+govopty);
            if(govopty=='true'){    isThisGovtOpportunity=true;
                System.debug('------here Making True to First Question--------isThisGovtOpportunity:'+isThisGovtOpportunity);
            }
        }
        /*Added on 2-13-2013*/
        /*Start*/
        System.debug('++2591+++ContactId:'+ContactId +'\t leadid:'+leadid);
        if(ContactId != Null){
            Contact contEmail = [Select Email From Contact where Id =:ContactId];
            for(GSA_Contact_Email_List__c GSAEmailList: GSAsettings){
                if(contEmail.Email!=null && GSAEmailList.Domain_Extension__c == contEmail.Email.substringAfterLast('@')){
                    System.debug('-----direc opty------contact domain contains an extension listed in custom settings-------------');
                    isThisGovtContact = true;
                    break;
                }               
            }
        }else if(ContactId==null && leadid==null){
            System.debug('+++2594++++ContactThruNotFound:'+ContactThruNotFound 
                         +'\t ++++++++ContactThruNotFound2:'+ContactThruNotFound2
                         +'\t ++++++isOpportunityMeetsGSA:'+isOpportunityMeetsGSA);
            //1st loop: for direct gov contact
            //2nd loop: im.com to 404.gov
            //3rd loop: direct im.com and 404.gov to im.com
            if(ContactThruNotFound==true && isOpportunityMeetsGSA==false){  isThisGovtContact = true;
                System.debug('++++2597+++++isThisGovtContact:'+isThisGovtContact);
            }else if(ContactThruNotFound2==true && isOpportunityMeetsGSA==false){  isThisGovtContact = true;
                System.debug('++++2605+++++isThisGovtContact:'+isThisGovtContact);
            }else{
                isThisGovtContact = false;
                System.debug('++++2608+++++isThisGovtContact:'+isThisGovtContact);
            }
        }
        /*End*/
        System.debug('----2527-----:'+isExecuteGSAtestWrap); 
        if(isExecuteGSAtestWrap){
            System.debug('---2529------GSATestList:'+GSATestList); 
            if(GSATestList.size()==0){
                GSATestList.clear();
                GSAQuestions=[Select o.Product__r.Name, o.Product__c,o.Answer_Format__c, o.Name, o.Id, o.Answer_Picklist__c From Opportunity_Questions__c o where o.Product__r.Name='GSA Dummy Product' and Active__c=true order by Question_Order__c ];
                System.debug('--------GSAQuestions:'+GSAQuestions);
                for(Opportunity_Questions__c oq:GSAQuestions){
                    System.debug('--2534---isThisGovtOpportunity:'+isThisGovtOpportunity +'\t isThisNARACFROpportunity:'+isThisNARACFROpportunity);                   
                    if(oq.Name=='Is this an opportunity for a US federal government customer?' && isThisGovtOpportunity==true){     GSATestList.add(new  GSAWrapper(oq,true));
                        system.debug('SETTING IN LINE 2972 FOR FEDERAL GOVT CUSTOMER');
                        System.debug('----2537--for 1st question--GSATestList:'+GSATestList);
                    }
                    else if(oq.Name== 'Is this a NARA/CFR Compliant Opportunity?' && isThisNARACFROpportunity==true){         GSATestList.add(new  GSAWrapper(oq,true));
                        System.debug('----2532--for 2nd question--GSATestList:'+GSATestList);
                    }
                    else{
                        GSATestList.add(new  GSAWrapper(oq,false));
                        System.debug('----2536--for remaining all questions--GSATestList:'+GSATestList);
                    }
                    
                }
                
                
                
            }
        }
        System.debug('-----2545-----GSATestList:'+GSATestList);
        return  GSATestList;
    }
    /*End*/
    
    public class secondproductwrapper{
        public PricebookEntry acc{get; set;}
        public Boolean selected {get; set;}
        public secondproductwrapper(PricebookEntry a){
            acc = a;
            selected = false;
        }
    }
    public class pricebookwrapper{
        public PricebookEntry pbe{get; set;}
        public Boolean selected {get; set;}
        public pricebookwrapper(PricebookEntry pb){
            pbe = pb;
            System.debug('----2531------pbe :'+pbe );
            selected = false;
        }
    }
    public class completelistwrapper{
        public PricebookEntry pe{get; set;}
        public Decimal Price=null;
        public Decimal getPrice()
        {
            System.debug('----Price:'+Price);
            return Price;
        }
        public void setPrice(Decimal Price)
        {
            this.Price=Price.setScale(2);
            strprice=String.valueOf(Price);
            System.debug('----strprice:'+strprice);
        }
        public Integer Quantity{get; set;}
        public Decimal Revenue=null;
        public String strprice=null;
        public String getStrprice()
        {
            System.debug('----strprice.contains:'+strprice.contains('.'));
            if(strprice.contains('.'))
            {
                Integer strlength=strprice.length();
                Integer strindex = strprice.indexOf('.');
                if(strindex==(strlength-2))  strprice=strprice+'0'; else strprice= strprice.substring(0,(strindex+3));            
            }
            else
            {
                strprice = strprice + '.00';
                System.debug('--else loop-------strprice:'+strprice);
            }
            return strprice;
        }
        
        public Decimal getRevenue()
        {
            return Revenue;
        }
        public void setRevenue(Decimal Revenue)
        {
            this.Revenue=Revenue.setScale(2);
        }
        
        public completelistwrapper(PricebookEntry pb, Boolean isListPrice){
            pe=pb;
            System.debug('----3035-----pe:'+pe);   
            System.debug('---3036-----isListPrice:'+isListPrice);
            if(isListPrice){      Price=pe.UnitPrice;
                System.debug('----3039-----Price:'+Price);
            }         
        }
    }
    
    public class testlistwrapper{
        public Product2 p{get; set;}
        public Integer prodnumber{get; set;}
        public List<questionwrapper> questions = new List<questionwrapper>();
        public List<completelistwrapper> complist = new List<completelistwrapper>();
        public Boolean questionsexist;
        public List<completelistwrapper> getComplist()
        {
            return complist;
        }
        public List<questionwrapper> getQuestions()
        {
            return questions;
        }
        public Boolean getQuestionsexist()
        {
            if(questions.size()>0)     return true;
            else
                return false;
        }
        
        public testlistwrapper(Product2 pr){
            
            p=pr;
            System.debug('---2641----p:'+p +'\t p.Name:'+p.Name);
            /*Added on 1-31-2013*/
            if(p.Name == 'CFR Boxes' || p.Name == 'CFR Tape'){          isThisNARACFROpportunity = true;
                System.debug('----2646-----isThisNARACFROpportunity :'+isThisNARACFROpportunity );               
            }
            for(Opportunity_Questions__c oc :pr.Opportunity_Questions__r)  {  questions.add(new questionwrapper(oc));
            }
            /*Start*/
            if(p.Use_List_Price_in_Wizard__c==True){
                system.debug('----3032----inside if -------');
            }
            /*End*/
        }
    }
    
    public class questionwrapper{
        public Integer b=0, p=0;
        public Opportunity_Questions__c oqc{get; set;}
        public String textanswer{get; set;}
        public String picklistvalues{get; set;}
        public String finalanswer{get;set;}
        public String yes='YES';
        public String no='NO';
        public String checkboxanswer{get; set;}
        public List<SelectOption> checkboxanswers = new List<SelectOption>();
        public String picklistanswer{get; set;}
        public List<SelectOption> picklistanswers = new List<SelectOption>();
        public List<String> splitstring = new List<String>();
        public List<String> getSplitstring()
        {
            return splitstring;
        }
        public List<SelectOption> getCheckboxanswers()
        {
            if(b==0)
            {
                checkboxanswers.add(new SelectOption(YES,YES));
                checkboxanswers.add(new SelectOption(NO,NO));
                b++;
            }
            return checkboxanswers;
        }
        public List<SelectOption> getPicklistanswers()
        {
            if(p==0)
            {
                for(Integer p=0; p<splitstring.size(); p++) {   picklistanswers.add(new SelectOption(splitstring[p] ,splitstring[p]));
                }
                p++;
            }
            return picklistanswers;
        }
        public questionwrapper(Opportunity_Questions__c oq){
            oqc=oq;
            System.debug('----2506----oqc:'+oqc);
            if(oq.Answer_Format__c =='Picklist')
            {
                picklistvalues = oq.Answer_Picklist__c;
                splitstring = picklistvalues.split(',');
            }
        }
    }
    
    /*Added By   : Srinu Mandalapu
Case       : 00426534
Description: Wrapper which process the GSA Questions
Start
*/
    public class GSAWrapper{
        public Opportunity_Questions__c Gsarec{get;set;}  
        Integer coun=0;
        public Boolean isQuestionEditable{
            get{ 
                if(isQuestionEditable==null){  isQuestionEditable=false;
                    System.debug('----2699------isQuestionEditable:'+isQuestionEditable);
                }
                System.debug('----2701------isQuestionEditable:'+isQuestionEditable);
                return isQuestionEditable;              
            }
            set;
        }
        public String textanswer{get;set;}
        string picklistvalues;
        List<String> splitstring=new List<String>();
        public String picklistanswer{get; set;}
        public List<SelectOption> picklistanswers = new List<SelectOption>();
        
        public List<SelectOption> getPicklistanswers(){        
            if(coun==0){
                for(Integer p=0; p<splitstring.size(); p++){
                    picklistanswers.add(new SelectOption(splitstring[p] ,splitstring[p]));
                }
                coun++;
            }
            return picklistanswers;
        }
        
        public GSAWrapper(Opportunity_Questions__c qr,Boolean ValueForCondition){
            Gsarec=qr;
            System.debug('--2731---Gsarec.Name:'+Gsarec.Name +'\t ValueForCondition:'+ValueForCondition);
            if(Gsarec.Name == 'Is this an opportunity for a US federal government customer?' && ValueForCondition==true ){
                isQuestionEditable=true;
                picklistanswer = 'Yes';
                System.debug('---2735----picklistanswer:'+picklistanswer);
            }  
            System.debug('--2737---Gsarec.Name:'+Gsarec.Name +'\t ValueForCondition:'+ValueForCondition);
            if(Gsarec.Name == 'Is this a NARA/CFR Compliant Opportunity?' &&ValueForCondition==true){
                isQuestionEditable=true;
                picklistanswer = 'Yes';
                System.debug('---2741----picklistanswer:'+picklistanswer);
            }
            
            if(Gsarec.Answer_Format__c =='Picklist'){
                picklistvalues = Gsarec.Answer_Picklist__c;
                splitstring = picklistvalues.split(',');                     
            }
            
            
        }
    }
    /*End*/
    
    public PageReference getSelectedb(){
        selectedbundleproductlist.clear();
        for(pricebookwrapper pbwrapper : bundleproductlistwrap){
            System.debug('----2703-----pbwrapper.selected:'+pbwrapper.selected);
            if(pbwrapper.selected == true){      selectedbundleproductlist.add(pbwrapper.pbe);
            }
            /*Added By   : Srinu
Case Number: 00426534
*/
            System.debug('----2708-----pbwrapper.selected:'+pbwrapper.selected +'\t pbwrapper.pbe.Name:'+pbwrapper.pbe.Name);
            if(pbwrapper.selected == true && (pbwrapper.pbe.Name.Contains('CFR Boxes') || pbwrapper.pbe.Name.Contains('CFR Tape'))){      isThisNARACFROpportunity = true;
                //isQuestionEditable = true;
                System.debug('----2761-----isThisNARACFROpportunity :'+isThisNARACFROpportunity );
            }
        }        
        return null;
    }    
    public PageReference getSelected1(){
        System.debug('-------calling---- getSelected1 method----------pricebookList:'+pricebookList +'\t isThisNARACFROpportunity:'+isThisNARACFROpportunity);
        pricebookentrylist.clear();
        for(pricebookwrapper pbwrapper : pricebookList){  if(pbwrapper.selected == true){       pricebookentrylist.add(pbwrapper.pbe);
            }
            /*Added By   : Srinu
Case Number: 00426534
*/
            System.debug('----2784-----pbwrapper.selected:'+pbwrapper.selected +'\t pbwrapper.pbe.Name:'+pbwrapper.pbe.Name);
            if(pbwrapper.selected == true && (pbwrapper.pbe.Name.Contains('CFR Boxes') || pbwrapper.pbe.Name.Contains('CFR Tape'))){   isThisNARACFROpportunity = true;
                System.debug('----2781-----isThisNARACFROpportunity :'+isThisNARACFROpportunity );
            }
        }
        return null;
    }    
    
    public PageReference getSelected2(){
        secondaryproductlist.clear();
        for(secondproductwrapper cawrapper : secondproductList)
            if(cawrapper.selected == true)
            secondaryproductlist.add(cawrapper.acc);
        return null;
    }
    public PageReference getSelected3(){
        newpricebookentrylist.clear();
        for(pricebookwrapper pbwrapper : newpricebookList){    if(pbwrapper.selected == true){     newpricebookentrylist.add(pbwrapper.pbe);
            }
            /*Added By   : Srinu
Case Number: 00426534
*/
            System.debug('----2784-----pbwrapper.selected:'+pbwrapper.selected +'\t pbwrapper.pbe.Name:'+pbwrapper.pbe.Name);
            if(pbwrapper.selected == true && (pbwrapper.pbe.Name.Contains('CFR Boxes') || pbwrapper.pbe.Name.Contains('CFR Tape'))){      isThisNARACFROpportunity = true;
                System.debug('----2804-----isThisNARACFROpportunity :'+isThisNARACFROpportunity );
            }    
        }    
        return null;
    }
    /*Ketan Benegal/Srinu
Method for converting a lead
*/
    public Database.LeadConvertResult convertLead(String sLeadId, String sAccId, String sOppContId, String sLeadOpportunityName, String sLeadStatus, ID OwnerID){
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(sLeadId);
        
        if(sAccId != null)
            lc.setAccountId(sAccId);
        
        if(sOppContId != null)      lc.setContactId(sOppContId);
        
        lc.setOpportunityName(sLeadOpportunityName);
        lc.setConvertedStatus(sLeadStatus); 
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        ID OppId = lcr.getOpportunityId();
        return lcr;   
    }   
    
    /*  Developer Name: Sandhya Ramesh
Date          : 04/04/15
Case Number   : 03474925
Description   : Vended/unvended opportunity tracking
*/
    
    /*Start*/
    public date compExpDate=null;
    public void setCompExpDate(date compExpDate){this.compExpDate=compExpDate;}
    public date getCompExpDate(){return compExpDate;}
    
    public integer dummyX=0;
    public list<Opportunity_Competitor__c> oppcompetitors = new list<Opportunity_Competitor__c>();
    public list<Opportunity_Competitor__c> getOppcompetitors()
    {
        if(dummyx==0)
        {
            Opportunity_Competitor__c ocTemp = [select id from Opportunity_Competitor__c limit 1];
            oppcompetitors.add(ocTemp);
            dummyx++;
        }
        return oppcompetitors;
    }
    
    Public boolean oppcompblock = false;
    public boolean oppnextconbutton = false;
    public boolean leadoppnextconbutton = false;
    public boolean oppbackbutton = false;
    public boolean leadoppbackbutton = false;
    public boolean skipbutton = false;
    public boolean leadskipbutton = false;
    public boolean getLeadskipbutton(){return leadskipbutton;}
    public boolean getSkipbutton() {return skipbutton;}
    public boolean getOppcompblock() { return oppcompblock;}
    public boolean getOppnextconbutton() { return oppnextconbutton;}
    public boolean getLeadoppnextconbutton() {return leadoppnextconbutton;}
    public boolean getOppbackbutton() { return oppbackbutton;}
    public boolean getLeadoppbackbutton() { return leadoppbackbutton;}
    Public Opportunity_Competitor__c oc;
    public Opportunity_Competitor__c getOc(){
        if(oc==null)
            oc=new Opportunity_Competitor__c();
        system.debug('+++ oc initialized +++');
        return oc;
    } 
    
    public id competitor = null;
    public date competitorExpirationDate = null;
    public date expirationNotificationDate = null;
    public boolean unknownPricing = null;
    public decimal storagePrice = null;
    public decimal retrievalFile = null;
    public decimal minStorageCharge = null;
    public decimal retrievalBox = null;
    public decimal adminFee = null;
    public decimal handlingCharge = null;
    public decimal permanentWithdrawal = null;
    public decimal rushTransport = null;
    public id getCompetitor (){return competitor ;}
    public date getCompetitorExpirationDate (){return competitorExpirationDate ;}
    public date getExpirationNotificationDate (){return expirationNotificationDate ;}
    public Boolean getUnknownPricing (){return unknownPricing ;}
    public decimal getStoragePrice (){return storagePrice ;}
    public decimal getRetrievalFile(){return retrievalFile;}
    public decimal getMinStorageCharge (){return minStorageCharge ;}
    public decimal getRetrievalBox (){return retrievalBox ;}
    public decimal getAdminFee(){return adminFee;}    
    public decimal getHandlingCharge (){return handlingCharge ;}
    public decimal getPermanentWithdrawal(){return permanentWithdrawal ;}
    public decimal getRushTransport (){return rushTransport ;}
    public void setcompetitor (Id competitor ){this.competitor =competitor ;}
    public void setcompetitorExpirationDate (Date competitorExpirationDate ){this.competitorExpirationDate =competitorExpirationDate ;}
    public void setexpirationNotificationDate (Date expirationNotificationDate ){this.expirationNotificationDate =expirationNotificationDate ;}
    public void setunknownPricing (boolean unknownPricing ){this.unknownPricing =unknownPricing ;}
    public void setstoragePrice (decimal storagePrice ){this.storagePrice =storagePrice ;}
    public void setretrievalFile(decimal retrievalFile){this.retrievalFile=retrievalFile;}
    public void setminStorageCharge (decimal minStorageCharge ){this.minStorageCharge =minStorageCharge ;}
    public void setretrievalBox (decimal retrievalBox ){this.retrievalBox =retrievalBox ;}
    public void setadminFee(decimal adminFee){this.adminFee=adminFee;}
    public void sethandlingCharge (decimal handlingCharge ){this.handlingCharge =handlingCharge ;}
    public void setpermanentWithdrawal (decimal permanentWithdrawal ){this.permanentWithdrawal =permanentWithdrawal ;}
    public void setrushTransport (decimal rushTransport ){this.rushTransport =rushTransport ;}
    
    public PageReference oppcompnext(){
        /*    list<Opportunity_Competitor__c> ocList = new list<Opportunity_Competitor__c>();
Opportunity_Competitor__c ocTemp = new Opportunity_Competitor__c();
ocTemp.Competitor_Expiration_Date__c=oc.Competitor_Expiration_Date__c;
ocList.add(ocTemp); */
        
        competitor = oc.Competitor__c;
        competitorExpirationDate = oc.Competitor_Expiration_Date__c;
        expirationNotificationDate = oc.Expiration_Notification_Date__c;
        unknownPricing = oc.Unknown_Pricing__c;
        storagePrice = oc.Storage_Price_per_Unit__c;
        retrievalFile = oc.Retrieval_File__c;
        minStorageCharge = oc.Minimum_Storage_Charge__c;
        retrievalBox = oc.Retrieval_Box__c;
        adminFee = oc.Admin_Fee__c ;
        handlingCharge = oc.Handling_Charge__c;
        permanentWithdrawal = oc.Permanent_Withdrawal__c;
        rushTransport = oc.Rush_Transport__c;
        conroleselectblock=true;
        oppnextconbutton = false;
        oppcompblock=false;
        leadoppnextconbutton = false;
        oppbackbutton = false;
        leadoppbackbutton = false;
        roleselectblock=false;
        skipbutton = false;
        leadskipbutton=false;
        return null;
    }
    
    public PageReference leadoppcompback(){
        roleselectblock=true;
        oppcompblock=false;
        leadoppnextconbutton = false;
        oppnextconbutton = false;
        oppbackbutton = false;
        leadoppbackbutton = false;
        skipbutton = false;
        leadskipbutton=false;
        return null;
    }   
    
    
    public PageReference oppcompback(){
        oppdetails = true;
        oppcompblock = false;
        return null;
    }
    
    public PageReference leadcompskip(){
        //      delete oc;
        conroleselectblock=true;
        oppnextconbutton = false;
        oppcompblock=false;
        leadoppnextconbutton = false;
        oppbackbutton = false;
        leadoppbackbutton = false;
        roleselectblock=false;
        skipbutton = false;
        leadskipbutton=false;
        return null;
    }
    
    public PageReference compskip(){
        //     delete oc;
        location=false;
        for(integer q=0; q<contactList.size(); q++)      contactList[q].selected=false;
        contactdisplay=true;
        j=0;
        oppdetails=false;
        oppcompblock=false;
        return null;
    }
    
    public PageReference oppcompsaverole(){
        competitor = oc.Competitor__c;
        competitorExpirationDate = oc.Competitor_Expiration_Date__c;
        expirationNotificationDate = oc.Expiration_Notification_Date__c;
        unknownPricing = oc.Unknown_Pricing__c;
        storagePrice = oc.Storage_Price_per_Unit__c;
        retrievalFile = oc.Retrieval_File__c;
        minStorageCharge = oc.Minimum_Storage_Charge__c;
        retrievalBox = oc.Retrieval_Box__c;
        adminFee = oc.Admin_Fee__c ;
        handlingCharge = oc.Handling_Charge__c;
        permanentWithdrawal = oc.Permanent_Withdrawal__c;
        rushTransport = oc.Rush_Transport__c;
        
        location=false;
        for(integer q=0; q<contactList.size(); q++)    contactList[q].selected=false;
        contactdisplay=true;
        j=0;
        oppdetails=false;
        oppcompblock=false;
        
        return null;
    }
    
    public string varoppstage;
    public id varoppaccount;
    public decimal varoppprob;
    public string getVaroppstage() { return varoppstage; }
    public id getVaroppaccount() {return varoppaccount;}
    public decimal getvaroppprob() {return varoppprob;}
    public void setvaroppstage(){this.varoppstage=varoppstage;}
    public void setvaroppaccount(){this.varoppaccount = varoppaccount;}
    public void setvaroppprob(){this.varoppprob = varoppprob; }
    
    /*End*/
    
    
    /*  Developer Name: Sandhya Ramesh
Date          : 07/10/15
Case Number   : 03909360 
Description   : 1) If the Account.Account Sub Segment field equals Healthcare default GPO field to -None- and make the field mandatory. 
2) If the Account.Account Sub Segment field does not equal Healthcare default the GPO field to Not Contracted 
Update applies to only new Opportunity wizard. Lead to Opportunity wizard should stay as is.
*/
    
    public string acctId{get; set;}
    //public string subSegHealthcare;
    public String subSegHealthcare{get; set;}
    
    public PageReference passAccId(){
        try{
            system.debug('+++++++++++ inside pass acc id function ++++++++');
            system.debug('++++++++ acct Id is +++++'+acctId);
            if(acctId!=null){
                List<Account> acc = [select Account_Sub_Segment__c from Account where Id=:acctId limit 1];
                String subSeg = (string) acc[0].Account_Sub_Segment__c ;
                system.debug('++++++ sub seg = +++++ ' + subSeg);
                if(subSeg == 'Healthcare')
                    subSegHealthcare = 'true'; else subSegHealthcare = 'false';
            }
            system.debug('++++ sub seg is ++++++' + subSegHealthcare);
        }
        catch(exception e){
            system.debug('Exception is '+e);
        }  
        return null;
    }
    
    // Vended/Unvended section should display if opportunity Type ='New Deal' and Product class ='Records Management'
    // and Product line = storage and stage between 2 - Solution Developed and 5 - Signed/PO in
    public boolean IsVendedSecDisplay(string callFrom){
        system.debug('in Method: VendedSecDiplay');
        system.debug('Call from:' + callFrom);
        Boolean RMProductsExists = false;
        List<ID> selectedProductIds = new List<ID>(); 
        List<PricebookEntry> selectedProducts = new List<PricebookEntry>();
        string OpportunityType = '';
        for(pricebookwrapper pbwrapper : pricebookList){
            System.debug('pbwrapper.selected:'+ pbwrapper.selected + ' pbwrapper. :'+pbwrapper.pbe);
            if(pbwrapper.selected== true){                PricebookEntry pb = pbwrapper.pbe; selectedProducts.add(pbwrapper.pbe);                        
            }
            
        }
        
         for(pricebookEntry addiProdList : pricebookentrylist){
            System.debug('pricebookentrylist:'+ addiProdList); 
                selectedProducts.add(addiProdList); 
        }
        
        for(secondproductwrapper cawrapper : secondproductList){
            System.debug('cawrapper.selected:'+ cawrapper.selected + ' cawrapper. :'+cawrapper.acc); 
            if(cawrapper.selected== true){
                PricebookEntry pb = cawrapper.acc;
                selectedProducts.add(cawrapper.acc);                       
            }
        }
        
        for(pricebookwrapper pbwrapper : newpricebookList){
            System.debug('pbwrapper.selected:'+ pbwrapper.selected + ' pbwrapper. :'+pbwrapper.pbe);
            if(pbwrapper.selected== true){  PricebookEntry pb = pbwrapper.pbe; selectedProducts.add(pbwrapper.pbe);                      
            }
        }
        
        for(PricebookEntry pe: selectedProducts){
            if((pe.Product2.IM_Product_Class__c == 'Records Management') && (pe.Product2.IM_Product_Line__c=='Storage')){     RMProductsExists = true;
            }
        }
        
        if(opportunity != null){           
            OpportunityType = opportunity.Type;            
        }
        
        if(leadopportunity != null){
            OpportunityType = leadopportunity.Type;
        }
        
        if((selectedpg=='Records Management') && (selectedpb=='Storage')){   RMProductsExists = true;
        }
        
        
        
        if(leadid!=null){
            opportunity.StageName =leadopportunity.StageName;
        } 
        
        if(RMProductsExists && (OpportunityType != 'Renewal') && 
           (opportunity.StageName == '2 - Solution Developed' || opportunity.StageName == '3 - Solution Agreed' 
            || opportunity.StageName == '4 - Negotiate' || opportunity.StageName == '5 - Signed/PO in')){   VendedSecDisplay = true;
            }
        else
        {
            VendedSecDisplay = false;
        }
        return VendedSecDisplay;
    }
    
    /*  public string getSubSegHealthcare(){
system.debug('++++ inside get sub and sub value is ++++ ' + subSegHealthcare);
return subSegHealthcare;
} */ 
}
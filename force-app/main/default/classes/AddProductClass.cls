/*
/*
**Author: Raj Gottipolu
**Date: 10/31/11
**Company: HCL America
**
**Author: Ketan Benegal
**Date: 11/21/12
**Company: CloudFountain Inc.
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
        
     **Modified By: Amarendra Nallamalli  
     **Date: 6th june 2018
     **Case: 07754082 : Read/write ability For Cloud Solutions Opportunities  
**/
public with sharing class AddProductClass {

public Integer j=0, k=0, l=0, b=0, a=0, z=0, s=0;
public Integer recur =1; 
public String prodgroup=null;
public Id productgroupnameId=null;
public Id productgroupnameId1=null;
public Boolean emptybundles=false;
public Boolean othererror=false;
public Boolean noproductclass=false;
public Boolean newbundlelistdisplay=false;
public Boolean emptyprodlines=false;
public String otherinformation=null;
public Boolean emptyproductlist=false; 
public Boolean otherinformationdisplay=false;
public String oppcurrency=null;
public String profilename=null;
public String bundle=null;
public String selectedbundle=null;
public Boolean bundleexists=false;
public String selectedbundletype=null;
public Boolean bundlemsg=false;
public Boolean bundlelistdisplay=false;
public Boolean catchexception=false;
public Boolean bundlequestiondisplay=false;
public Boolean questionsavedisplay=false;
public Boolean runwizard=false;
public Boolean questionsbackdisplay=true;
public Boolean bundleproductlistdisplay=false;
public Boolean questionsnextdisplay=true;
public String productgroup=null;
public Boolean secproerror=false;
public Boolean errorblock=false;
public Boolean multipleclassdisplay=false;
public Boolean multipleclassexists=false;
public Boolean overwriteverify=false;
public Boolean questionblockrender=null;
public Boolean fromnewlist=false;
public Boolean productsavebuttondisplay=false;
public Boolean backtoquestionsdisplay=true;
public Boolean overwriterror=false;
public String selectedpg=null;
public Boolean displaydetailsdisplay=true;
public Boolean questiondisplay=false;
public Boolean addprodline=false;
public String selectedpb=null;
public Boolean addprimaryprod=false;
public Boolean questionverify=false;
public Boolean secproselectdisplay=false;
public Boolean granularleveldisplay=null;
public Id id=null, contactid=null, pricebookid=null, newpricebookid=null;
public String rolestring=null;
public Boolean secprodisplay=false;
public Boolean addprods=false;
public String ids=null, cloneid=null;
public Boolean pricebookerror=false;
public Boolean oldcon=false;
public Boolean questionerror=false;
public String strBody;
public Boolean consavedisplay=true;
public Boolean conbackdisplay=true;
public Boolean finaldetailsdiplay=false;
public Boolean contactbackbuttondisplay=false;
public Boolean newcon=false;
public Boolean conchangedisplay=false;
public Boolean contacterror=false;
public Boolean location=false;
public Boolean newcontactdisplay=false;
public Boolean highleveldisplay=false;
public Boolean addproductsdisplay=false;
public Boolean rolexists=false;
public Boolean prodexists=false;
public Boolean pricebookdisplay=false;
public Boolean contactdisplay=false;
public boolean VendedSecDisplay= false; 
public boolean finalVendedSecDisplay = false;
public boolean hasVendedValue = false;    
public Opportunity opportunity = new Opportunity();
public OpportunityContactRole ocr;
public String canOpp{get; set;}    
public Contact contact, conew1, conew2, conew;
List<SelectOption> productclass = new List<SelectOption>();
public List<contactwrapper> contactList = new List<contactwrapper>();
public List<SelectOption> pricegrp = new List<SelectOption>();
public List<String> productclasses = new List<String>();
public List<Decimal> Pricelist = new List<Decimal>();
//public List<Decimal> Quantitylist = new List<Decimal>();
public List<Integer> Quantitylist = new List<Integer>();
public List<Decimal> TotalPricelist = new List<Decimal>();
public List<Contact> primarycontactlist = new List<Contact>();
public List<PricebookEntry> pricebookentries = new List<PricebookEntry>();
public List<pricebookwrapper> pricebookList = new List<pricebookwrapper>();
public List<PricebookEntry> pricebookentrylist = new List<PricebookEntry>();
public List<Product2> productids = new List<Product2>();
public List<PricebookEntry> selectedbundleproductlist = new List<PricebookEntry>();
public List<PricebookEntry> newpricebookentries = new List<PricebookEntry>();
public List<PricebookEntry> newpricebookentrylist = new List<PricebookEntry>();
public List<completelistwrapper> completelistwrap = new List<completelistwrapper>();
public List<testlistwrapper> testlistwrap = new List<testlistwrapper>();
public List<SelectOption> bundleslist = new List<SelectOption>();
public List<PricebookEntry> completelist = new List<PricebookEntry>();
public List<secondproductwrapper> secondproductList = new List<secondproductwrapper>();
public List<PricebookEntry> secondaryproductlist = new List<PricebookEntry>();
public List<pricebookwrapper> newpricebookList = new List<pricebookwrapper>();
public List<pricebookwrapper> bundleproductlistwrap = new List<pricebookwrapper>();
public List<Product2> testlist = new List<Product2>();   
public List<Product2> addproductids = new List<Product2>();
public List<PricebookEntry> bundleproductlist = new List<PricebookEntry>();
public List<PricebookEntry> additionalproductlist = new List<PricebookEntry>();
public List<String> roleslist = new List<String>();
public List<Contact> primarycontactrolelist = new List<Contact>();
   
public Opportunity getOpportunity(){if(opportunity==null) opportunity = new Opportunity();
    return opportunity;}
public Contact getContact() {if(contact == null) contact = new Contact();
    return contact;}
public OpportunityContactRole getOcr(){if(ocr==null) ocr = new OpportunityContactRole();
    return ocr;}

/*Developer Name: Srinu Mandalapu 
  Case Number   : 00426534
  Description   : Viariable declaration for Gov't Opportunity Management - Display GSA Questions. 
*/
/*Start*/
public boolean DontAllowToAddProducts=false;
public Boolean isExecuteGSAtestWrap=false;
public static boolean isThisGovtOpportunity = false;
public static boolean isThisNARACFROpportunity = false;
public static boolean isThisGovtContact = false;
public static boolean isOpportunityMeetsGSA = false;
public Boolean GSAQuestiondisplay=false;
public Boolean gsaquestionblockrender=null;
public Boolean gsaquestionsavedisplay=false;
public Boolean gsafinaldetailsdiplay=false;
public Boolean VendedSectSaveDisplay = false;
public List<Opportunity_Questions__c > GSAQuestions=new List<Opportunity_Questions__c >();
public List<GSAWrapper> GSATestList =new  List<GSAWrapper>();
/*End*/
    
List<Opportunity_Product_Wizard_Settings__c> wizardsettings = Opportunity_Product_Wizard_Settings__c.getall().values();
        
    public AddProductClass(ApexPages.StandardController controller) {

        
        String Oppid=ApexPages.currentPage().getParameters().get('addTo');
        Profile prof = [Select Id, Name from Profile where id =: UserInfo.getProfileId()];
        profilename = prof.Name;
        /*Code modified as a part of Case 00540594
          Author: Raj Gottipolu
          Start*/
        /*Condition added as a part of case 00540594 
          Author: Srinivasa Rao Mandalapu*/
          System.debug('-----------Oppid:'+Oppid);

        //It will not allow execution, when if ‘OpportunityId’ is Null. In this case we can stop the error. 
        if((Oppid != null) && (Oppid != '')) {
          System.debug('---135 srinu--------Oppid:'+Oppid);
            //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
             try
            {
            opportunity = [select Id,Name,SyncedQuoteId,AccountId,/* #16915 Bundle__c */Pricebook2Id, IM_Booked_Date__c, CurrencyIsoCode,GSA_Eligibility__c,IMGS_Approval_Status__c, StageName,IME_Vended_Unvended__c,/* 16915 ,Unvended__c*/Type,(select Id from OpportunityContactRoles), (Select Id, OpportunityId, PricebookEntryId,PricebookEntry.Pricebook2Id,PricebookEntry.Pricebook2.Name, Product_Class__c, Product_Line__c From OpportunityLineItems) from Opportunity where Id=:Oppid];
            }
            catch(Exception e)
            {
                try
                {
                opportunity = [select Id,Name,SyncedQuoteId,AccountId,/* #16915 Bundle__c */Pricebook2Id, IM_Booked_Date__c, CurrencyIsoCode,GSA_Eligibility__c,IMGS_Approval_Status__c, StageName,IME_Vended_Unvended__c,/* 16915 Vended__c,Unvended__c,*/ Type,(select Id from OpportunityContactRoles), (Select Id, OpportunityId, PricebookEntryId, Product_Class__c,PricebookEntry.Pricebook2Id,PricebookEntry.Pricebook2.Name, Product_Line__c From OpportunityLineItems) from Opportunity where Id=:Oppid];
                }
                catch(Exception ex)
                {
                        ApexPages.addMessages(ex);
                        catchexception=true;
                        strBody = 'Error in the wizard. Please start over\n\n';
                        sendEmailNotification(strBody,'Failed to retrieve Opportunity Id');                     
                }
            }
        }
        System.debug('---155--srinu------Oppid:'+Oppid);
        /*End*/
        if(catchexception==false)
        {   
            oppcurrency=opportunity.CurrencyIsoCode;
            if(opportunity.IME_Vended_Unvended__c !=null){    hasVendedValue = true;
            }
            
            for(Opportunity_Product_Wizard_Settings__c ops : wizardsettings)
            {
                if(profilename == ops.Profile_Name__c)
                {
                    prodgroup = ops.Product_Group_Name__c;
                    
                    
                    
                    
                   //madhu added query on 12/7/12
                    productgroupnameId=[Select Id from  Pricebook2 where Name=:prodgroup].id;
                }
            }
        }
       system.debug('+++44444++++'+canOpp); 
    }
    public void sendEmailNotification(String strEmailBody, String strEmailSub)
    {
        String username = userinfo.getLastName();
        User mailuser = [Select Email from User where LastName=:username Limit 1];
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

    public pagereference autorun()
    {   
        System.debug('--208---executing AutoRun Method');
        /* Don't allow to add products when opp in sync with quote */
        /*Developer   :Madhu 
          Description :added method which will take you to detail page opportunity if there is any error occured on auto run method
          Invocation  : just make "DontAllowToAddProducts=true" to see button "Cancel" on page
       */
         /****start******/
         system.debug('++++++++++is insync with quote++++++++'+opportunity.SyncedQuoteId);
         if(opportunity.SyncedQuoteId!=null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You are unable to add products to this opportunity while there is an actively synced quote attached.');
            ApexPages.addMessage(myMsg);
            DontAllowToAddProducts=true;
            return null;   
        }
        /****End*****/
        if(opportunity.GSA_Eligibility__c == 'GSA Eligible' && opportunity.IMGS_Approval_Status__c == 'Under Review'){
           ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'This opportunity is currently under review. Once it has been reviewed by the government services team it will be unlocked for editing.');
           ApexPages.addMessage(myMsg);
           DontAllowToAddProducts=true;
           return null; 
           
           /* DontAllowToAddProducts=true;
            return null; */   
        }
         else if(catchexception==false)
         {
            
            /* #16915 if(opportunity.Bundle__c!=null)
            {
                bundleexists=true;
                bundle=opportunity.Bundle__c;
            } */
            if(opportunity.OpportunityContactRoles.size()>0)
            {
                rolexists=true;
            }
            else
            {
                rolexists=false;
                contactdisplay=true;
            }
    
            if(opportunity.OpportunityLineItems.size()>0)
            {
                    /*Code changed for case 00643765 Author: RAJ
                    Start*/
                    for(OpportunityLineItem ol : opportunity.OpportunityLineItems)
                    {
                        if(ol.Product_Class__c!=null)  productclasses.add(ol.Product_Class__c);
                    }
                    Set<String> pc = new Set<String>(productclasses);
                    List<String> prodclasses = new List<String>(pc);
                    if(prodclasses.size()==0)
                    {
                        noproductclass=true;
                    }
                    else if(prodclasses.size()==1)
                    {
                        multipleclassexists=false;
                        system.debug('multipleclassexistsfalse');   
                    
                    }
                    else
                    {   
                        //return prodclasses list and show the block
                        multipleclassexists=true;
                        for(integer i=0; i<prodclasses.size(); i++)
                            productclass.add(new SelectOption(prodclasses[i] ,prodclasses[i]));
                    }
                    /*End*/
                    selectedpg=opportunity.OpportunityLineItems[0].Product_Class__c;
                    prodexists=true;
                    /* Developer Name: Madhu Paladugu
                       Description   : added block code to optimize below commented block and remove error for case number 
                       Case number   : 01363925
                    */
                    /*new block start*/
                    if(opportunity.OpportunityLineItems[0].PriceBookEntry.Pricebook2.Name!=null){
                        productgroup=opportunity.OpportunityLineItems[0].PriceBookEntry.Pricebook2.Name;
                        System.debug('-------productgroup:'+productgroup);
                        productgroupnameId1=opportunity.OpportunityLineItems[0].PriceBookEntry.Pricebook2Id;
                       system.debug('++++++++++product group id+++++++'+productgroupnameId1);
                    }                    
                    /*new block end*/
                    
                    if(null==productgroup||prodgroup==productgroup)
                    {
                         for(Opportunity_Product_Wizard_Settings__c ops : wizardsettings){
                                if(profilename == ops.Profile_Name__c) {
                                      if(productgroupnameId1==null){
                                            productgroupnameId1=productgroupnameId;
                                            productgroup=prodgroup;
                                      }
                                        runwizard=true;
                                }
                         }
                    }
                    else
                        runwizard=false;
            }
            else
            {
                    for(Opportunity_Product_Wizard_Settings__c ops : wizardsettings)
                    {
                        if(profilename == ops.Profile_Name__c)
                        {
                        runwizard=true;
                        }
                    } 
                    prodexists=false;
                    //madhu added on 12/7/12 below assignment
                    productgroupnameId1=productgroupnameId;
                    productgroup=prodgroup; 
            }
            if(bundleexists==false)
            {
                if(rolexists==true && prodexists==true)
                {
                      /*Code changed for case 00643765 Author: RAJ
                      Start*/ 
                       if(multipleclassexists==true)   multipleclassdisplay=true;
                       else if(noproductclass==true)   errorblock=true;
                       else
                            granularleveldisplay=true;//go to prodline selection directly
                     /*End*/
                }
                if(rolexists==true && prodexists==false)
                            //highleveldisplay=true;//go to prodclass selection (no start with bundle selection)
                            bundlequestiondisplay=true;
            }
            else
            {
                if(rolexists=true)
                    bundlelistdisplay=true;
            }
            if(runwizard==true)
            {
                return null;
            }
            else
            {
                Pagereference p1 = new Pagereference('/ui/opportunity/SelectSearch?addTo='+opportunity.Id+'&retURL=%2F'+opportunity.Id);
                p1.getParameters().put('nooverride', '1');
                p1.setRedirect(false);
                return p1;
            }
        }
        else
        {
            return null;
        }
            
    }
    
    
    public String getOtherinformation(){return otherinformation;}
    public void setOtherinformation(String otherinformation){this.otherinformation = otherinformation;}
    public Boolean getRolexists(){return rolexists;}
    public Boolean getOthererror(){return othererror;}
    public Boolean getBundlelistdisplay(){return bundlelistdisplay;}
    public Boolean getProdexists(){return prodexists;}
    public Boolean getEmptybundles(){return emptybundles;}
    public Boolean getQuestionblockrender(){return questionblockrender;}
    public Boolean getLocation(){return location;}
    public Boolean getContactdisplay(){return contactdisplay;}
    public Boolean getNewcontactdisplay(){return newcontactdisplay;} 
    public Boolean getNewcon(){return newcon;}
    public Boolean getEmptyproductlist(){return emptyproductlist;}
    public String getSelectedbundletype() {return selectedbundletype;}
    public void setSelectedbundletype(String selectedbundletype){this.selectedbundletype = selectedbundletype;}
    public Boolean getOldcon(){return oldcon;}
    public String getBundle(){return bundle;}
    public Boolean getCatchexception(){return catchexception;}
    public Boolean getBundlemsg(){return bundlemsg;}
    public Boolean getMultipleclassdisplay(){return multipleclassdisplay;}
    public Boolean getContacterror(){return contacterror;}
    public Boolean getNewbundlelistdisplay(){return newbundlelistdisplay;}
    public Boolean getEmptyprodlines(){return emptyprodlines;}
    public Boolean getHighleveldisplay(){return highleveldisplay;}
    public Boolean getConsavedisplay(){return consavedisplay;}
    public Boolean getDisplaydetailsdisplay(){return displaydetailsdisplay;}
    public Boolean getConbackdisplay(){return conbackdisplay;}
    public Boolean getErrorblock(){return errorblock;}
    public Boolean getFinaldetailsdiplay(){return finaldetailsdiplay;}
    public Boolean getConchangedisplay(){return conchangedisplay;}
    public Boolean getContactbackbuttondisplay(){return contactbackbuttondisplay;}
    public String getProductgroup(){return productgroup;}    
    public Boolean getQuestionsavedisplay(){return questionsavedisplay;}
    public Boolean getQuestionsbackdisplay(){return questionsbackdisplay;}
    public Boolean getQuestionsnextdisplay(){return questionsnextdisplay;}
    public String getRolestring(){return rolestring;}
    public Boolean getGranularleveldisplay(){return granularleveldisplay;}
    public Boolean getBundleproductlistdisplay(){return bundleproductlistdisplay;}
    public Boolean getBundlequestiondisplay(){return bundlequestiondisplay;}
    public String getSelectedbundle() {return selectedbundle;}
    public void setSelectedbundle(String selectedbundle){this.selectedbundle = selectedbundle;}
    public String getSelectedpg(){return selectedpg;}
    public String getSelectedpb(){return selectedpb;}
    public void setSelectedpg(String selectedpg){this.selectedpg=selectedpg;}
    public Boolean getBacktoquestionsdisplay(){return backtoquestionsdisplay;}
    public void setSelectedpb(String selectedpb){this.selectedpb=selectedpb;}
    public Boolean getProductsavebuttondisplay(){return productsavebuttondisplay;}
    public Boolean getPricebookdisplay(){return pricebookdisplay;}
    public Boolean getOtherinformationdisplay(){return otherinformationdisplay;}
    public Boolean getPricebookerror(){return pricebookerror;}
    public Boolean getAddprods(){return addprods;}
    public Boolean getAddprodline(){return addprodline;}    
    public Boolean getSecproselectdisplay(){return secproselectdisplay;}
    public Boolean getSecprodisplay(){return secprodisplay;}
    public Boolean getQuestiondisplay(){return questiondisplay;}
    public Boolean getAddproductsdisplay(){return addproductsdisplay;}
    public Boolean getAddprimaryprod(){return addprimaryprod;}
    public Boolean getSecproerror(){return secproerror;}
    public Boolean getQuestionerror(){return questionerror;}
    public Boolean getOverwriterror(){return overwriterror;}
    public Boolean getMultipleclassexists(){return multipleclassexists;}
    
    public Boolean getVendedSecDisplay(){  return VendedSecDisplay; 
    }  
    
    public Boolean getFinalVendedSecDisplay(){  return finalVendedSecDisplay;
    } 
    /*Developer Name: Srinu Mandalapu 
      Case Number   : 00426534
      Description   : Viariable declaration (getter methods) for Gov't Opportunity Management - Display GSA Questions. 
    */
    /*Start*/
    public Boolean getDontAllowToAddProducts(){return DontAllowToAddProducts;}    
    public Boolean getisExecuteGSAtestWrap(){return isExecuteGSAtestWrap;}
    public Boolean getisThisNARACFROpportunity(){return isThisNARACFROpportunity; }    
    public Boolean getisOpportunityMeetsGSA(){return isOpportunityMeetsGSA; }
    public Boolean getGSAQuestiondisplay(){return GSAQuestiondisplay;}
    public Boolean getgsaQuestionblockrender(){return gsaquestionblockrender;}
    public Boolean getgsaQuestionsavedisplay(){return gsaquestionsavedisplay;} 
    public Boolean getVendedSectSaveDisplay(){return VendedSectSaveDisplay;} 
    public Boolean getgsafinaldetailsdiplay(){return gsafinaldetailsdiplay;} 
    /*End*/
    
    public Pagereference primarycontactnotfound()
    {
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
    public PageReference savePrimarycontact()
    {
        for(contactwrapper cw: contactList)
        {
            if(cw.selected==true)
            {
                if(cw.oppcont.Role!=null)
                {
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
        if(primarycontactlist.size()>0 && rolestring != null)
        {
            contactdisplay = false;
            if(bundleexists==false)
            {
            if(prodexists==true)
            {
                if(multipleclassexists==true)     multipleclassdisplay=true;
                else if(noproductclass==true)   errorblock=true;
                else     granularleveldisplay=true;
            }
            else
                bundlequestiondisplay=true;
            }
            else
            {
                bundlelistdisplay=true;
            }
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
         
        List<PricebookEntry> pbe =[select  Id, Product2.IM_Revenue_Type__c, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Product_Class__c, Product2.IM_Product_Line__c, Product2Id, Name,Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c, Product2.IM_Unit_of_Measure__c  from PricebookEntry where Product2Id in : productid and CurrencyIsoCode =: oppcurrency and Pricebook2Id =:productgroupnameId1 and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') and IsActive=true order by Name];
            
        for(integer i=0; i<pbe.size();i++) { bundleproductlist.add(pbe[i]);
         }
        if(bundleproductlist.size()>0)    emptyproductlist=false;
        else
            emptyproductlist=true;  
        bundlelistdisplay=false;
        newbundlelistdisplay=false;
        bundlequestiondisplay=false;
        bundleproductlistdisplay=true;
        }
        else
        {
            newbundlelistdisplay=false;
            otherinformationdisplay=true;
        }       
        return null;
    }
    public pagereference nextbundlenew(){
        //if(bundle!='Other')
        //{
        a=0;
        bundleexists=true;
        List<Id> productid = new List<Id>(); 
        List<Product_Bundle__c> selectedbundlelist = [Select Id, Product_ID__c from Product_Bundle__c where Name =:bundle];
        for(integer i=0; i<selectedbundlelist.size(); i++)
            productid.add(selectedbundlelist[i].Product_ID__c);
       
       /*Developer Name: Madhu Paladugu
          Date          : 2/27/13
          Case Number   : 01192467
        */
        
        List<PricebookEntry> pbe =[select  Id, Product2.IM_Revenue_Type__c, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Product_Class__c, Product2.IM_Product_Line__c, Product2Id, Name,Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c, Product2.IM_Unit_of_Measure__c  from PricebookEntry where Product2Id in : productid and CurrencyIsoCode =: oppcurrency and Pricebook2Id =:productgroupnameId1 and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') and IsActive=true order by Name];
        
        for(integer i=0; i<pbe.size();i++) {   bundleproductlist.add(pbe[i]);
         }
        if(bundleproductlist.size()>0)   emptyproductlist=false;
        else
            emptyproductlist=true;  
        bundlelistdisplay=false;
        bundlequestiondisplay=false;
        bundleproductlistdisplay=true;
        /*}
        else
        {
            bundlelistdisplay=false;
            otherinformationdisplay=true;
        }*/     
        return null;
    }
    public pagereference cancelbundle(){
        emptybundles=false;
        newbundlelistdisplay=false;
        bundleslist.clear();
        bundlequestiondisplay=true;
        return null;
    }
    public pagereference otherinformationnext(){
        if(otherinformation==null || otherinformation.trim().length()==0) { othererror=true;
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
        
            List<PricebookEntry> pbe =[select  Id, Product2.IM_Revenue_Type__c,  Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name,  Product2.IM_Product_Class__c, Product2.IM_Product_Line__c, Product2Id, Name,Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c, Product2.IM_Unit_of_Measure__c  from PricebookEntry where Product2Id in : productid and CurrencyIsoCode =: oppcurrency and Pricebook2Id =:productgroupnameId and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') and IsActive=true order by Name];
        
        for(integer i=0; i<pbe.size();i++) {
                bundleproductlist.add(pbe[i]);
         }
        if(bundleproductlist.size()>0)
            emptyproductlist=false;
        else
            emptyproductlist=true;  
        otherinformationdisplay=false;
        bundleproductlistdisplay=true;
        othererror=false;
        }
        return null;
    }
    public pagereference otherinformationback(){
        if(selectedbundletype!=null){
        newbundlelistdisplay=true;
        otherinformation=null;
        otherinformationdisplay=false;
        othererror=false;
        }
        else
        {
        bundlelistdisplay=true;
        otherinformation=null;
        otherinformationdisplay=false;
        othererror=false;
        }       
        return null;
    }
    public Pagereference newcontactsave()
    {
        if(ocr.Role==null)  { contacterror=true;  
        }
        else
        {
            
            newcontactdisplay=false;
            if(bundleexists==false)
            {   
            if(prodexists==true) { if(multipleclassexists==true)    multipleclassdisplay=true; else if(noproductclass==true) errorblock=true;
                 else granularleveldisplay=true;
            }
            else
                    //highleveldisplay=true;
                    bundlequestiondisplay=true;
                    contacterror=false;
            }
            else
            {
                bundlelistdisplay=true;
            }
            
        }
        rolestring=ocr.Role;
        newcon=true;
        oldcon=false;
        return null;
    }
    public Pagereference newcontactback()
    {
        primarycontactlist.clear();
        for(integer m=0; m<contactList.size(); m++)
            contactList[m].selected=false;
        rolestring=null;
        primarycontactrolelist.clear();
        roleslist.clear();
        contactdisplay=true;
        newcontactdisplay=false;
        return null;
    }
    public pagereference consavebutton()
    {
        if(ocr.Role==null){   contacterror=true;  
        }
        else
        {
        
        newcontactdisplay=false;
        finaldetailsdiplay=true;
        consavedisplay=true;
        conbackdisplay=true;
        conchangedisplay=false;
        contactbackbuttondisplay=false;
        
        }    
        return null;
    }
    public Pagereference nextpg()
    {
        granularleveldisplay=true;
        highleveldisplay=false;
        return null;
    }
    public Pagereference nextproclass()
    {        
        granularleveldisplay=true;
        multipleclassdisplay=false;     
        return null;
    }
    public Pagereference cancelpg()
    {
    if(selectedbundletype==null)
    {
        if(primarycontactlist.size()>0)
        {
        primarycontactlist.clear();
        rolestring=null;
        oldcon=false;
        for(integer m=0; m<contactList.size(); m++)
        {
            contactList[m].selected=false;
            contactList[m].oppcont.Role=null;
        }
        contactdisplay=true;
        }
        else
        {
            newcontactdisplay=true;
            newcon=false;
        }
        highleveldisplay=false;
        newcon=false;
    }
    else
    {
        highleveldisplay=false;
        bundlequestiondisplay=true;
    }
        return null;
    }
    public Pagereference cancelproclass()
    {
        if(primarycontactlist.size()>0)
        {
        primarycontactlist.clear();
        rolestring=null;
        oldcon=false;
        for(integer m=0; m<contactList.size(); m++)
        {
            contactList[m].selected=false;
            contactList[m].oppcont.Role=null;
        }
        contactdisplay=true;
        }
        else
        {
            newcontactdisplay=true;
            newcon=false;
        }
        multipleclassdisplay=false;
        newcon=false;
        return null;
    }
    public pagereference bundleyes()
    {
        z=0;        
        if(selectedbundletype!='All Other Product Lines')
        {
        a=0;
        bundleexists=true;
        newbundlelistdisplay=true;
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
            if(prodexists==true) {   if(multipleclassexists==true)     multipleclassdisplay=true;     else    granularleveldisplay=true;
            }
            else
                    highleveldisplay=true; 
        return null;
    }
    public pagereference bundleback()
    {
        
            if(primarycontactlist.size()>0) {
            primarycontactlist.clear();
            rolestring=null;
            primarycontactrolelist.clear();
            roleslist.clear();
            oldcon=false;
            for(integer m=0; m<contactList.size(); m++)     {
                contactList[m].selected=false;
                contactList[m].oppcont.Role=null;
            }
            contactdisplay=true;
            }
            else    {
                newcontactdisplay=true;
                newcon=false;
            }
            bundlequestiondisplay=false;
            newcon=false;
            return null;
    }
    public Pagereference nextpb()
    {
        productids.clear();
        pricebookentrylist.clear();
        pricebooklist.clear();
        pricebookentries.clear();
        for(integer r=0; r<pricebookList.size(); r++)     pricebookList[r].selected=false;
            k=0;
        pricebookdisplay = true;
        granularleveldisplay=false;       
        pricebookid = productgroupnameId1;//prb2.Id;
         /*Developer Name: Madhu Paladugu
          Date          : 2/27/13
          Case Number   : 01192467
        */
         List<Product2> pro2 = [select Id, IM_Revenue_Type__c , IM_Product_Class__c, IM_Product_Line__c, IM_Unit_of_Measure__c  from Product2 where IM_Product_Line__c = : selectedpb and IM_Product_Class__c = :selectedpg and RecordType.Name Not in ('Bill Code','IME Bill Code')];
         //List<Product2> pro2 = [select Id, IM_Product_Class__c, IM_Product_Line__c from Product2 where IM_Product_Line__c = : selectedpb and IM_Product_Class__c = :selectedpg];
         for(integer i=0; i<pro2.size();i++)
         {
                productids.add(pro2[i]);
         }
        
        
        List<PricebookEntry> prbe =[select  Id, Product2.IM_Revenue_Type__c , Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Product_Class__c,   Product2.IM_Product_Line__c, Product2Id, Name,Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c, Product2.IM_Unit_of_Measure__c  from PricebookEntry where Product2Id in : productids and CurrencyIsoCode =: oppcurrency and Pricebook2Id =:pricebookid and IsActive=true order by Name];
        for(integer i=0; i<prbe.size();i++)
         {
                pricebookentries.add(prbe[i]);
         }
                
        return null;
        
    }
    public Pagereference cancelpb()
    {
        emptyprodlines=false;
        pricegrp.clear();
        if(prodexists==false)
            highleveldisplay=true;
        else 
        {
            if(primarycontactlist.size()>0)
            {
                primarycontactlist.clear();
                rolestring=null;
                oldcon=false;
                for(integer m=0; m<contactList.size(); m++)
                {
                    contactList[m].selected=false;
                    contactList[m].oppcont.Role=null;
                }
                contactdisplay=true;
            }
            else
            {
                newcontactdisplay=true;
            }
        }
        granularleveldisplay=false;
        return null;
    }
    public pagereference bundleproselected()
    {
        emptyproductlist=false;
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
    public Pagereference newcancelpb()
    {
        granularleveldisplay=false;
        multipleclassdisplay=true;
        return null;
    }
    public PageReference nextsecpro()
    {
        if(pricebookentrylist.size()>0)
        {
        pricebookdisplay=false;
        addprods=true;
        pricebookerror=false;
        }
        else
            pricebookerror=true;
        return null;
    }
    public PageReference cancelsecpro()
    {
        pricebooklist.clear();
        pricebookentrylist.clear();
        selectedpb=null;
        granularleveldisplay=true;
        pricebookdisplay=false;
        return null;
    }
    public pagereference bundlepronotselected()
    {
        emptyproductlist=false;
        bundleproductlistdisplay=false;
        bundleproductlist.clear();
        selectedbundleproductlist.clear();
        bundleproductlistwrap.clear();
        if(selectedbundletype!=null)
        {
               if(selectedbundle!='Other')
                        newbundlelistdisplay=true;
               else           otherinformationdisplay=true;           
        }
        else
        {
               bundlelistdisplay=true;
        }
        return null;
    }
    public pagereference addprodsyes()
    {
        addprodline=true;
        addprods=false;
        return null;
    }
    public pagereference addprodsno()
    {
        addprods=false;
        secproselectdisplay=true;
        return null;
    }
    
    public pagereference addprodsback()
    {
        s=0;
        if(fromnewlist==true)
        {
            addprimaryprod=true;
            addprods=false;
            for(integer r=0; r<newpricebookList.size(); r++)      newpricebookList[r].selected=false;
            Integer delsize = newpricebookentrylist.size();
            Integer prosize = additionalproductlist.size()-1;
            for(integer d=0; d<delsize; d++)
            {
                    additionalproductlist.Remove(prosize-d);
            }
            newpricebookentrylist.clear();
            newpricebookList.clear();
            fromnewlist=false;
        }
        else
        {
            pricebookdisplay=true;
            addprods=false;
            for(integer r=0; r<pricebookList.size(); r++)      pricebookList[r].selected=false;
            pricebookentrylist.clear();
        }
        return null;
    }
    public PageReference secprotrue()
    {        
        secproselectdisplay=false;
        secprodisplay=true;
        return null;
    }
    public PageReference secprofalse()
    {
            //Added on 2-19-2013
            //
            
        if(DisplayVendedSection('secprofalse')){    VendedSecDisplay = true;
        }
        else
        {
            VendedSecDisplay = false;
        }
        
        if(opportunity.GSA_Eligibility__c == 'GSA Eligible' && opportunity.IMGS_Approval_Status__c == 'GSA Pricing Approved'){
            GSAQuestiondisplay=false;
        }else{
            GSAQuestiondisplay=true;
            
            
        }
            isExecuteGSAtestWrap=true;
            gsaquestionblockrender=true;
            GSATestList.clear();
            completelist.clear();
            for(integer i=0; i<selectedbundleproductlist.size(); i++)
            {
                completelist.add(selectedbundleproductlist[i]);
            }
            for(Integer z=0; z<pricebookentrylist.size();z++)
            {
                completelist.add(pricebookentrylist[z]);
            }
            for(Integer u=0; u<additionalproductlist.size();u++)
            {
                completelist.add(additionalproductlist[u]);
            }
            for(Integer p=0; p<secondaryproductlist.size(); p++)
            {
                completelist.add(secondaryproductlist[p]);
            }
            Product2 pd = new Product2();
            testlist.clear();
            for(PricebookEntry p : completelist)
            {
            pd = [Select Id, Name, IM_Revenue_Type__c, IM_Product_Line__c, IM_Unit_of_Measure__c,(Select Name, Active__c, Answer_Format__c, Answer_Picklist__c, Product__c From Opportunity_Questions__r where Active__c = true order by Question_Order__c) From Product2 where Id =:p.Product2Id];
            testlist.add(pd);
            }
            testlistwrap.clear();
            for(Product2 p: testlist)
                testlistwrap.add(new testlistwrapper(p));
            for(testlistwrapper ts: testlistwrap)
            {
                if(ts.questions.size()!=0)
                    questionblockrender=true;
            }
        secproselectdisplay=false;
        questiondisplay=true;
        return null;
    }
    public PageReference secproback()
    {
        selectedbundleproductlist.clear();
        for(integer n=0; n<pricebookList.size(); n++)
            pricebookList[n].selected=false;
        for(integer n=0; n<bundleproductlistwrap.size(); n++)
            bundleproductlistwrap[n].selected=false;
        secproselectdisplay=false;
        if(bundleexists==true)
            bundleproductlistdisplay=true;
        else
            addprods=true;
        questionblockrender=false;
        return null;
    }
    public pagereference addprodlinenext()
    {
        addproductids.clear();
        s=0;
        newpricebookentrylist.clear();
        newpricebooklist.clear();
        newpricebookentries.clear();
        addprodline=false;
        addprimaryprod=true;
        for(integer r=0; r<newpricebookList.size(); r++)
            newpricebookList[r].selected=false;
            k=0;      
        newpricebookid = productgroupnameId1;//pb.Id;
        /*Developer Name: Madhu Paladugu
          Date          : 2/27/13
          Case Number   : 01192467
        */
          List<Product2> pro = [select Id, IM_Revenue_Type__c, IM_Product_Class__c, IM_Product_Line__c, IM_Unit_of_Measure__c  from Product2 where IM_Product_Line__c = : selectedpb and IM_Product_Class__c = :selectedpg and RecordType.Name Not in ('Bill Code','IME Bill Code')];
       // List<Product2> pro = [select Id, IM_Product_Class__c, IM_Product_Line__c from Product2 where IM_Product_Line__c = : selectedpb and IM_Product_Class__c = :selectedpg];
         for(integer i=0; i<pro.size();i++)
         {
                addproductids.add(pro[i]);
         }
        
        List<PricebookEntry> pbr =[select  Id, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.Name, ProductCode, UnitPrice, CurrencyIsoCode, Product2.IM_Business_Line__c, Pricebook2.Name, Product2.IM_Revenue_Type__c,  Product2.IM_Product_Class__c,  Product2.IM_Product_Line__c, Product2Id, Name,Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c, Product2.IM_Unit_of_Measure__c  from PricebookEntry where Product2Id in : addproductids and CurrencyIsoCode =: oppcurrency and Pricebook2Id =:newpricebookid and IsActive=true order by Name];
         for(integer i=0; i<pbr.size();i++)
         {
                newpricebookentries.add(pbr[i]);
         }
                
        return null;
    }
    public pagereference addprodlineback()
    {
        addprods=true;
        addprodline=false;
        return null;
    }
    
    public List<PricebookEntry> getadditionalproductlist()
    {
        return additionalproductlist;
    }
    public pagereference addnextsecpro()
    {
        if(newpricebookentrylist.size()>0)
        {
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
    public PageReference addcancelsecpro()
    {
        newpricebooklist.clear();
        newpricebookentrylist.clear();
        selectedpb=null;
        addprodline=true;
        addprimaryprod=false;
        return null;
    }
     public Pagereference secprodisplaynext()
    {
        //Added on 2-19-2013
         
        if(DisplayVendedSection('secprodisplaynext')){    VendedSecDisplay = true;
        }
        else
        {
            VendedSecDisplay = false;
        }
        
        if(opportunity.GSA_Eligibility__c == 'GSA Eligible' && opportunity.IMGS_Approval_Status__c == 'GSA Pricing Approved'){
            GSAQuestiondisplay=false;
        }else{
            GSAQuestiondisplay=true;
            
            
        }
                
        isExecuteGSAtestWrap=true;
        gsaquestionblockrender=true;
        if(secondaryproductlist.size()>0)
        {
            questiondisplay=true;
            secprodisplay=false;
            secproerror=false;
            completelist.clear();
            for(integer i=0; i<selectedbundleproductlist.size(); i++){
                completelist.add(selectedbundleproductlist[i]);
            }
            for(Integer z=0; z<pricebookentrylist.size();z++)
            {
                completelist.add(pricebookentrylist[z]);
            }
            for(Integer u=0; u<additionalproductlist.size();u++)
            {
                completelist.add(additionalproductlist[u]);
            }
            for(Integer p=0; p<secondaryproductlist.size(); p++)
            {
                completelist.add(secondaryproductlist[p]);
            }
            Product2 pd = new Product2();
            testlist.clear();
            for(PricebookEntry p : completelist)
            {
            pd = [Select Id, Name, IM_Product_Line__c, IM_Unit_of_Measure__c ,(Select Name, Active__c, Answer_Format__c, Answer_Picklist__c, Product__c From Opportunity_Questions__r where Active__c = true order by Question_Order__c) From Product2 where Id =:p.Product2Id];
            testlist.add(pd);
            }
            testlistwrap.clear();
            for(Product2 p: testlist)
                testlistwrap.add(new testlistwrapper(p));
            questionblockrender=false;
            for(testlistwrapper ts: testlistwrap)
            {
                if(ts.questions.size()!=0)
                    questionblockrender=true;
            }
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
    public Pagereference addproducts()
    {        
        //Modified By: Srinivasa Rao Mandalapu
        //Case# :01622446
        /*Start*/   
        
        if((opportunity.IME_Vended_Unvended__c == null) && (VendedSecDisplay==true)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Competitively Vended: You must enter a value.');
            ApexPages.addMessage(myMsg);
            
            return null;
        }
         if(opportunity.IME_Vended_Unvended__c == 'Both'/*16915 && (opportunity.Vended__c== null || opportunity.Unvended__c==null)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % Vended and % Unvended values.');
             ApexPages.addMessage(myMsg);
          
              return null;
        }
        
         if(opportunity.IME_Vended_Unvended__c == 'Both' /* && (opportunity.Vended__c + opportunity.Unvended__c != 100)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both: Enter the percent of storage Vended and Un-vended. Values must equal 100%.');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        System.debug('--1585----GSATestList:'+GSATestList);
        if(opportunity.IME_Vended_Unvended__c == 'Vended'){
            /*16915 opportunity.Vended__c = 100;
            opportunity.Unvended__c =0;*/
        }
        
        if(opportunity.IME_Vended_Unvended__c == 'Unvended'){
            /*opportunity.Vended__c = 0;
            opportunity.Unvended__c =100;*/
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
        VendedSecDisplay= false;
        for(testlistwrapper tl: testlistwrap)
        {
            for(questionwrapper q: tl.questions)
            {
                if(q.textanswer!=null)     q.finalanswer=q.textanswer;
                else if(q.picklistanswer!=null)   q.finalanswer=q.picklistanswer;
                else if(q.checkboxanswer=='yes')   q.finalanswer='yes';
                else if(q.checkboxanswer=='no')  q.finalanswer='no';
                if(q.finalanswer==null || q.finalanswer.trim().length()==0)   questionverify=true;                
            }
        }
        if(questionverify==true)
        {
            questionerror=true;
            questionverify=false;
        }
        else
        {
            completelistwrap.clear();
            for(PricebookEntry p: completelist)
            completelistwrap.add(new completelistwrapper(p,p.Product2.Use_List_Price_in_Wizard__c));
            for(Integer i=0; i<testlistwrap.size(); i++)
            {
                testlistwrap[i].prodnumber=(i+1);
                testlistwrap[i].complist.add(completelistwrap[i]);
            }
            questiondisplay=false;
            addproductsdisplay=true;
            questionerror=false;
        }
        return null;
    }
    public Pagereference backtosecpro()
    {
        //GSA
        boolean flag= false;
        GSAQuestiondisplay=false;
        VendedSecDisplay = false;
        if(secondaryproductlist.size()>0)
        {
            for(integer u=0; u<secondproductlist.size(); u++)
                secondproductlist[u].selected=false;
            secondaryproductlist.clear();
            secprodisplay=true;
        }
        else
        {
            secondaryproductlist.clear();
            secproselectdisplay=true;
        }
        questiondisplay=false;
        for(OpportunityLineItem ol : opportunity.OpportunityLineItems)
        {
            if((ol.Product_Class__c!=null) && (ol.Product_Class__c == 'Records Management') && (ol.Product_Line__c=='Storage')){
                flag= true;       break;
            }
        }
        
        if(flag != true){
            opportunity.IME_Vended_Unvended__c =null;
            /*16915 opportunity.Vended__c= null;
            opportunity.Unvended__c=null;*/
        }
        return null;
    }
    public Pagereference displaydetails()
    {        
        //GSA        
        //Case Number : 00426534        
        /*Start*/
        for(GSAWrapper testGSA: GSATestList){                       
            //If any of GSA Answer is 'Yes' means, Opportunity is eligible for Approval.
            if(opportunity.GSA_Eligibility__c == 'GSA Eligible' && opportunity.IMGS_Approval_Status__c == 'GSA Pricing Approved'){
                //Set boolean to false.
                isOpportunityMeetsGSA=false;    
                System.debug('++1313++executing if setting to false');
            }else if(testGSA.picklistanswer=='Yes' && canOpp != 'True'){//Set boolean to false.        isOpportunityMeetsGSA=true;
                System.debug('++1317++executing else setting to true'); 
            }
        }  
        
       
        /*End*/
        
        for(testlistwrapper t: testlistwrap)
        {
          /* 
            if(t.complist[0].pe.Product2.Quantity_Override_value__c=='n/a')
            {
            t.complist[0].Quantity=1;
            t.complist[0].Revenue=t.complist[0].Price*t.complist[0].Quantity;
            }
            else
            {
            t.complist[0].Revenue=t.complist[0].Price*t.complist[0].Quantity;
            }
            */
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
            
            if(t.complist[0].Price==0 || t.complist[0].Quantity==0)
            {       
                    overwriteverify=true;
            }
        }
        if(overwriteverify==true)
        {
            overwriterror=true;
            overwriteverify=false;
            return null;
        }
        else
        {                 
        addproductsdisplay=false;
        overwriterror=false;
        finaldetailsdiplay=true;        
        System.debug('----1250-----finaldetailsdiplay:'+finaldetailsdiplay);
        }
        Pricelist.clear();
        Quantitylist.clear();
        TotalPricelist.clear();
        for(testlistwrapper t: testlistwrap)
        {
            Pricelist.add(t.complist[0].Price);
            system.debug('Price:'+t.complist[0].Price);
            Quantitylist.add(t.complist[0].Quantity);
            TotalPricelist.add(t.complist[0].Revenue);
        }
        
         if(opportunity.GSA_Eligibility__c == 'GSA Eligible' && opportunity.IMGS_Approval_Status__c == 'GSA Pricing Approved'){      gsafinaldetailsdiplay=false;
            System.debug('--1219---gsafinaldetailsdiplay:'+gsafinaldetailsdiplay);                     
        }else{
            gsafinaldetailsdiplay=true;         
        }
       
        if(DisplayVendedSection('displaydetails'))  {          finalVendedSecDisplay = true;
        }
        else
        {
            finalVendedSecDisplay = false;
        }
        
        return null;
    }
    public Pagereference backtoquestions()
    {
        for(testlistwrapper ts: testlistwrap)
        {
            for(questionwrapper qs: ts.questions)
            {
                
            }
        }
        
        addproductsdisplay=false;
        questiondisplay=true;
        FinalVendedSecDisplay = false;
        VendedSectSaveDisplay = false;
        if(DisplayVendedSection('backtoquestions')){    VendedSecDisplay = true;
        }
        else
        {
            VendedSecDisplay = false;
        }
        
        //GSA
        if(opportunity.GSA_Eligibility__c == 'GSA Eligible'  && opportunity.IMGS_Approval_Status__c == 'GSA Pricing Approved'){
            GSAQuestiondisplay=false;
        }else{
            GSAQuestiondisplay=true;
            
            
        }
        return null;
    }
    public Pagereference backtopricequantity()
    {
        finaldetailsdiplay=false;
        FinalVendedSecDisplay=false;
        //GSA
        gsafinaldetailsdiplay=false;
        addproductsdisplay=true;
        return null;
    }
    public pagereference contactbackbutton()
    {
        newcontactdisplay=true;
        finaldetailsdiplay=false;
        VendedSecDisplay=false;
        finalVendedSecDisplay=false;
        conchangedisplay=true;
        consavedisplay=false;
        conbackdisplay=false;
        return null;
    }
    public Pagereference newbacktoquestions()
    {
        for(testlistwrapper ts: testlistwrap)
        {
            for(questionwrapper qs: ts.questions)
            {
                
            }
        }
        finaldetailsdiplay=false;
        //GSA
        gsafinaldetailsdiplay=false;
        questiondisplay=true;
        questionsavedisplay=true;
        questionsbackdisplay=false;
        questionsnextdisplay=false;
        return null;
    }
    //GSA        
    //Case Number : 00426534
    /*Start*/
    Public PageReference newbacktogsaquestions(){
        system.debug('Method: newbacktogsaquestions');
        GSAQuestiondisplay=true;
       finalVendedSecDisplay = false;
        
        if(DisplayVendedSection('newbacktogsaquestions')){  VendedSectSaveDisplay= true; 
         }
         else
         {
               VendedSectSaveDisplay= false; 
         }
       
        gsafinaldetailsdiplay=false;
        finaldetailsdiplay=false;
        gsaquestionsavedisplay=true;
               
        gsaquestionblockrender=true;   
        system.debug('VendedSecDisplay:'+ VendedSecDisplay);
        return null;
    }
    public pagereference gsaquestionsavebutton(){
        //GSA Modification       
        //Case Number :01622446
        /*Start*/
        //Error message when User click Next without answering all 6 GSA questions.
        
        if((opportunity.IME_Vended_Unvended__c == null) && (VendedSectSaveDisplay==true)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Competitively Vended: You must enter a value.');
            ApexPages.addMessage(myMsg);
            
            return null;
        }
        
        if(opportunity.IME_Vended_Unvended__c == 'Both' /*&& (opportunity.Vended__c== null || opportunity.Unvended__c==null)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter % Vended and % Unvended values.');
             ApexPages.addMessage(myMsg);
          
              return null;
        }
        
         if(opportunity.IME_Vended_Unvended__c == 'Both'/* && (opportunity.Vended__c + opportunity.Unvended__c != 100)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both: Enter the percent of storage Vended and Un-vended. Values must equal 100%.');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        for(GSAWrapper testGSA: GSATestList){
            System.debug('---1789--testGSA.picklistanswer:'+testGSA.picklistanswer);
            if(testGSA.picklistanswer=='--None--'){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Every GSA Question should be answered either Yes or No.');
                ApexPages.addMessage(myMsg);
                return null;
            }           
        } 
        //checking if any answer is Yes. 
        for(GSAWrapper testGSA: GSATestList){
            System.debug('---1838--testGSA.picklistanswer:'+testGSA.picklistanswer); 
            if(testGSA.picklistanswer=='Yes' && canOpp != 'True'){               
                //Set boolean to true.
                isOpportunityMeetsGSA=true;                     
            }
        }
        /*End*/
        
        if(opportunity.IME_Vended_Unvended__c == 'Vended'){
            /*opportunity.Vended__c = 100;
            opportunity.Unvended__c =0;*/
        }
        
        if(opportunity.IME_Vended_Unvended__c == 'Unvended'){
           /* opportunity.Vended__c = 0;
            opportunity.Unvended__c =100;*/
        }
        
        gsafinaldetailsdiplay=true;
        System.debug('----1319-----gsafinaldetailsdiplay:'+gsafinaldetailsdiplay);
        GSAQuestiondisplay=false;
        VendedSecDisplay =false;
        gsaquestionsavedisplay=false;
        finaldetailsdiplay=true;
        if(DisplayVendedSection('gsaquestionsavebutton')){     FinalVendedSecDisplay= true;
        }
        else
        {
             FinalVendedSecDisplay= false;
        }
       
        return null;
    }
    /*End*/
    
    public Pagereference questionsavebutton()
    {
        for(testlistwrapper tl: testlistwrap)
        {
            for(questionwrapper q: tl.questions)
            {
                if(q.textanswer!=null) q.finalanswer=q.textanswer;
                else if(q.picklistanswer!=null)  q.finalanswer=q.picklistanswer;
                else if(q.checkboxanswer=='yes')  q.finalanswer='yes';
                else if(q.checkboxanswer=='no')  q.finalanswer='no';
                if(q.finalanswer==null || q.finalanswer.trim().length()==0)  questionverify=true;                
            }
        }
        if(questionverify==true)  { questionerror=true;
            questionverify=false;
        }
        else
        {
            
            questiondisplay=false;
            finaldetailsdiplay=true;
            System.debug('----1352-----finaldetailsdiplay:'+finaldetailsdiplay);
            questionerror=false;
            questionsavedisplay=false;
            questionsnextdisplay=true;
            questionsbackdisplay=true;
        }
        return null;
    }
    public pagereference productsavebutton()
    {
        
        for(testlistwrapper t: testlistwrap)
        {
                    if(t.complist[0].pe.Product2.Quantity_Override_value__c=='n/a'){  t.complist[0].Revenue=t.complist[0].Price*t.complist[0].Quantity;
                  //  t.complist[0].Quantity=1;
                   
                    }
                    else
                    {
                    t.complist[0].Revenue=t.complist[0].Price*t.complist[0].Quantity;
                    }
                    if(t.complist[0].Price==0 || t.complist[0].Quantity==0){      overwriteverify=true;
                    }
        }
        if(overwriteverify==true)
        {
            overwriterror=true;       overwriteverify=false;
        }
        else
        {                 
        addproductsdisplay=false;
        overwriterror=false;
        finaldetailsdiplay=true;
        System.debug('----1387-----finaldetailsdiplay:'+finaldetailsdiplay);
        //GSA
        gsafinaldetailsdiplay=true;
        productsavebuttondisplay=false;
        displaydetailsdisplay=true;
        backtoquestionsdisplay=true;
        }
        Pricelist.clear();
        Quantitylist.clear();
        TotalPricelist.clear();
        for(testlistwrapper t: testlistwrap)
        {
            Pricelist.add(t.complist[0].Price);
            Quantitylist.add(t.complist[0].Quantity);
            TotalPriceList.add(t.complist[0].TotalPrice);
        }
        
        if(DisplayVendedSection('productsavebutton')){    FinalVendedSecDisplay= true;
        }
        else
        {
             FinalVendedSecDisplay= false;
        }
        return null;
    }
    public pagereference oldcontactbackbutton()
    {
        primarycontactlist.clear();
        rolestring=null;
        primarycontactrolelist.clear();
        roleslist.clear();
        for(integer m=0; m<contactList.size(); m++)
        {
            contactList[m].selected=false;
            contactList[m].oppcont.Role=null;
        }
        contactdisplay=true;
        finaldetailsdiplay=false;
        finalVendedSecDisplay = false;
        VendedSecDisplay=false;
        roleslist.clear();
        primarycontactrolelist.clear();
        conchangedisplay=true;
        consavedisplay=false;
        conbackdisplay=false;
        return null;
    }
    public Pagereference newbacktopricequantity()
    {
        finaldetailsdiplay=false;
        addproductsdisplay=true;
        productsavebuttondisplay=true;
        backtoquestionsdisplay=false;
        displaydetailsdisplay=false;
        FinalVendedSecDisplay = false;
        //
        gsafinaldetailsdiplay=false;
        return null;
    }
    
    public Pagereference savedetails()
    {
        system.debug('newcon:===='+rolestring);        
        system.debug('--1438-in savedetails method--bundle name:'+selectedbundle +'\t ----otherinformation:'+otherinformation);
        system.debug('opportunity.IME_Vended_Unvended__c:'+ opportunity.IME_Vended_Unvended__c);
       /*16915 system.debug('opportunity.Vended__c:'+ opportunity.Vended__c);
        system.debug('opportunity.Unvended__c:'+ opportunity.Unvended__c); */
        
        Validator_cls.setaddingProduct();
        system.debug('Validator_cls.isaddingProduct()'+Validator_cls.isaddingProduct());
        
        if(opportunity.IME_Vended_Unvended__c == 'Both' /*&& (opportunity.Vended__c + opportunity.Unvended__c != 100)*/){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both: Enter the percent of storage Vended and Un-vended. Values must equal 100%.');
            ApexPages.addMessage(myMsg);
            return null;
        }
        Savepoint sp = Database.setSavepoint();
        try{
            system.debug('newcon:===='+rolestring);
            if(rolestring!=null)
            {   system.debug('newcon:===='+newcon);
                if(newcon==true)
                {
                    contact.AccountId=opportunity.AccountId;
                    insert contact;
                    contactid=contact.Id;
                }
                OpportunityContactRole newoppconrole = new OpportunityContactRole(ContactId = contactid, OpportunityId=opportunity.Id, Role=rolestring, IsPrimary=true);
                insert newoppconrole;
                
                List<OpportunityContactRole> conrolelist = new List<OpportunityContactRole>();
                for(Integer i=0;i<primarycontactrolelist.size();i++)
                {
                        if(primarycontactrolelist[i].Id != contactid)
                        {
                        OpportunityContactRole newoppconrole1 = new OpportunityContactRole(ContactId = primarycontactrolelist[i].Id, OpportunityId=opportunity.Id, Role=roleslist[i]);                  
                        conrolelist.add(newoppconrole1);
                        }
                }
                insert conrolelist;
            }
            System.debug('----selectedbundle:'+selectedbundle);
            //Commented as part of #16915
             /*if(selectedbundle!=null)
            {
                opportunity.Bundle__c=selectedbundle;
                System.debug('--1508-opportunity.Bundle__c:'+opportunity.Bundle__c);
            }
            System.debug('----otherinformation:'+otherinformation);
            
            
           if(otherinformation!=null)
            {
                opportunity.Bundle_Description__c = otherinformation;
                System.debug('--1513-opportunity.Bundle_Description__c:'+opportunity.Bundle_Description__c);
            }*/           
            
            /*Srinu: Commented out here declared after GSA Code*/
            //System.debug('---1474--updating Opportunity---1st time updation----:'+opportunity); 
            //update opportunity;
             
            List<OpportunityLineItem> newLine = new List<OpportunityLineItem>();
            
            List<OpportunityLineItem> newLine1 = new List<OpportunityLineItem>();
            
            for(integer i=0; i<testlistwrap.size(); i++)
            {
                //OpportunityLineItem newlineitem = new OpportunityLineItem(OpportunityId=opportunity.Id, UnitPrice = Pricelist[i], Quantity = Quantitylist[i], Product_Line__c=testlistwrap[i].complist[0].pe.Product2.IM_Product_Line__c, Product_Class__c=testlistwrap[i].complist[0].pe.Product2.IM_Product_Class__c, PricebookEntryId =testlistwrap[i].complist[0].pe.Id);
                OpportunityLineItem newlineitem = new OpportunityLineItem(OpportunityId=opportunity.Id, TotalPrice = TotalPricelist[i], Quantity = Quantitylist[i], Product_Line__c=testlistwrap[i].complist[0].pe.Product2.IM_Product_Line__c, Product_Class__c=testlistwrap[i].complist[0].pe.Product2.IM_Product_Class__c, PricebookEntryId =testlistwrap[i].complist[0].pe.Id);
                
             /******** Start of Read/write ability For Cloud Solutions Opportunities *****/ 
                 /* Case # 07955446 : Cloud Solutions Opp Partner Validation Rule */
                OpportunityProductSelection__c opprossel =[select Name,Product_Class_Name__c,Product_Line_Name__c from OpportunityProductSelection__c where name='CloudSolutionsProduct'];
                //OppPartnerAction.getOppPartnerCount(newlineitem.Opportunityid);
                if(newlineitem.Product_Line__c == opprossel.Product_Line_Name__c  &&  OppPartnerAction.getOppPartnerCount(newlineitem.Opportunityid) == true){
                   system.debug('Test Coverage inside');
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Cloud_Solution_Product_Line_Label));
                   return null;
                }
             /******** End of Read/write ability For Cloud Solutions Opportunities *****/
                system.debug(logginglevel.info, 'product is '+ newlineitem);
                newLine1.add(newlineitem);
            }
            System.debug(logginglevel.info, '---1465----newLine1:'+newLine1);
            insert newLine1;
            
            List<Opportunity_Answers__c> oppanswers = new List<Opportunity_Answers__c>();
          //  List<OpportunityLineItemSchedule> oppLineSch = new List<OpportunityLineItemSchedule>();
            
        
            System.debug('----1574---oppanswers:'+oppanswers +'\t OpportunityId:'+Opportunity.id);          
            if(oppanswers.size()>0)
            {
                 System.debug('---1577----oppanswers:'+oppanswers);
                 insert oppanswers;
                 
            }
            
            List<OpportunityLineItem> newLine2 = new List<OpportunityLineItem>();
            for(integer c=0; c<newLine1.size();c++)
            {
                OpportunityLineItem newlineitem = new OpportunityLineItem(
                Id=newLine1[c].Id);
                 newLine2.add(newlineitem);
            }
            update newLine2;
            System.debug('---IMGS1----oppanswers:'+newLine2);
            System.debug('queries used 3: ' + Limits.getQueries());
            
            /*Gsa Code start*/
            //Case Number : 00426534
            /*Start*/
            System.debug('---1663------gsafinaldetailsdiplay:'+gsafinaldetailsdiplay);
            if(gsafinaldetailsdiplay){
                List<Opportunity_Answers__c> GSAAns = new List<Opportunity_Answers__c>();
                List<Opportunity_Answers__c> GSAAns2 = new List<Opportunity_Answers__c>();
                GSAAns2 = [Select o.Product__r.Name, o.Product__c, o.Opportunity_Question__r.Product__c,o.Opportunity_Question__c, o.Opportunity_LineItem_Id__c, o.Name, o.Id, Opportunity_Question__r.Product__r.Name From Opportunity_Answers__c o where Opportunity__c=: Opportunity.id and Opportunity_Question__r.Product__r.Name='GSA Dummy Product'];
                System.debug('---IMGS2----oppanswers:'+GSAAns2);
                //4/16/13
                Map<Id,String> OLD_QUES_ANS=new Map<Id,String>();
                Boolean IS_ANY_ANS_CHANGED=false;
                Boolean IS_ANY_OF_ANS_FROM_YES_TO_NO=false;
                for(Opportunity_Answers__c OA:GSAAns2){
                    OLD_QUES_ANS.put(OA.Opportunity_Question__c,OA.Name);
                }
                system.debug('++++++++++map values of existing questions++++'+OLD_QUES_ANS);
                System.debug('---1586------GSAAns2:'+GSAAns2);
                List<Id> QuesIds = new List<id>();
                List<String> PcklstAns = new List<String>();
                Id GSAOpportunityId;
                GSAOpportunityId = Opportunity.Id;
               System.debug('---IMGS3----oppanswers:'+GSATestList);
                    for(GSAWrapper testGSA: GSATestList){
                        System.debug('---1967--testGSA.picklistanswer:'+testGSA.picklistanswer);                        
                        QuesIds.add(testGSA.Gsarec.Id);
                        System.debug('---2658------QuesIds:'+QuesIds);
                        PcklstAns.add(testGSA.picklistanswer);
                        System.debug('---2660------PcklstAns:'+PcklstAns);                  
                        
                    }
                    for(Integer i=0; i<QuesIds.Size(); i++){
                        Opportunity_Answers__c tempAns = new Opportunity_Answers__c();
                        tempAns.Name=PcklstAns.get(i);
                        tempAns.Opportunity_Question__c=QuesIds.get(i);
                        tempAns.Opportunity__c=GSAOpportunityId;        
                        GSAAns.add(tempAns);
                    }
                    System.debug('---IMGS4----oppanswers:'+GSAAns);
                    /*for(Opportunity_Answers__c OA:GSAAns){
                        System.debug('---1705-----OA.Name:'+OA.Name +'\t OLD_QUES_ANS.get(OA.Opportunity_Question__c):'+OLD_QUES_ANS.get(OA.Opportunity_Question__c));
                        if(OLD_QUES_ANS.get(OA.Opportunity_Question__c)!=OA.Name && OA.Name=='Yes' ){
                            system.debug(OLD_QUES_ANS.get(OA.Opportunity_Question__c)+'+++++++++inside no yes answer condition+++'+OA.Name);
                            IS_ANY_ANS_CHANGED=true;
                        }
                        else if(OLD_QUES_ANS.get(OA.Opportunity_Question__c)!=OA.Name ){
                            system.debug('+++++++++in side yes to no answer condition++++');
                            IS_ANY_OF_ANS_FROM_YES_TO_NO=true;
                        }
                    }*/
                    for(Opportunity_Answers__c OA:GSAAns){
                        if(OLD_QUES_ANS.get(OA.Opportunity_Question__c)!=OA.Name ){
                            system.debug('+++++++++in side yes to no answer condition++++');
                            IS_ANY_OF_ANS_FROM_YES_TO_NO=true;
                        }
                    }
                    system.debug('+++22222+++canOpp'+canOpp);
                    if(canOpp == 'false'){
                        IS_ANY_ANS_CHANGED=true;
                    }
                    system.debug(IS_ANY_ANS_CHANGED+'+++333333+++canOpp'+canOpp);
                    if(IS_ANY_ANS_CHANGED){
                        system.debug('+++++++++++inside answer change loop+++++');
                        if(GSAAns2.size()>0){
                            System.debug('--1612--deleting existed GSA----GSAAns2:'+GSAAns2);
                            delete GSAAns2;
                        }
                        System.debug('---1615---GSAAns:'+GSAAns);
                        if(GSAAns.size()>0){
                          System.debug('---1617----GSAAns:'+GSAAns);
                          insert GSAAns;
                        }
                        System.debug('---IMGS4----oppanswers:'+opportunity.GSA_Eligibility__c);
                        if(opportunity.GSA_Eligibility__c!='GSA Eligible'){
                            opportunity.GSA_Eligibility__c ='GSA Eligible';
                            //making changes to validator class allow second time
                            //Validator_OpportunityObjectTrigger.blnAlreadyDoneForAfterUpdate = false;
                            System.debug('---1733---opportunity:'+opportunity);
                            update opportunity;
                             Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                             req.setComments('Submitted for approval. Please approve.');
                             req.setObjectId(opportunity.Id);
                              try{
                                  // submit the approval request for processing
                                  Approval.ProcessResult result = Approval.process(req);
                                  // display if the reqeust was successful
                                  System.debug('-----613-------Submitted for approval successfully when Adding Products to an oppty from Add product: '+result.isSuccess());
                              }catch(Exception e){
                                 System.debug('---615------e.getMessage:'+e.getMessage());
                              }
                        }
                        else{
                        /*start*/
                            System.debug('----604------inside else if');
                             // create the new approval request to submit
                             System.debug('---1752---opportunity:'+opportunity);
                             update opportunity;
                             Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                             req.setComments('Submitted for approval. Please approve.');
                             req.setObjectId(opportunity.Id);
                              try{
                                  // submit the approval request for processing
                                  Approval.ProcessResult result = Approval.process(req);
                                  // display if the reqeust was successful
                                  System.debug('-----613-------Submitted for approval successfully when Adding Products to an oppty from Add product: '+result.isSuccess());
                              }catch(Exception e){
                                 System.debug('---615------e.getMessage:'+e.getMessage());
                              }
                        }
                        
                    }
                    else if(IS_ANY_OF_ANS_FROM_YES_TO_NO && !IS_ANY_ANS_CHANGED){
                        system.debug('+++++++++inside loop to just update opportunity questions+++++');
                        if(GSAAns2.size()>0){
                            System.debug('--1769--deleting existed GSA----GSAAns2:'+GSAAns2);
                            delete GSAAns2;
                        }
                        System.debug('---1772---GSAAns:'+GSAAns);
                        if(GSAAns.size()>0){
                          System.debug('---1774----GSAAns:'+GSAAns);
                          insert GSAAns;
                        }
                        
                        System.debug('---1777---opportunity:'+opportunity);
                        update opportunity;
                    }
                    else{ System.debug('just updating opp no change to gsa:'+opportunity);     update opportunity;
                    }
                // }
                System.debug('---1782---updating Opportunity with GSA Eligible---2nd time updation----:'+opportunity);
                /*gsa code end*/
            } else {      update Opportunity;
                System.debug('---1786------update happened to opportunity:'+Opportunity);
            }
             
        }
        catch(Exception e)
        {
            ApexPages.addMessages(e);
            Database.rollback(sp);
            
        }
        if(ApexPages.hasMessages())
        {
            return null;
        }
        else
        {
            PageReference prf1 = new PageReference('/'+opportunity.Id);    return prf1;
        }
        
    }
    
    public pagereference oldconsavebutton()
    {
        for(contactwrapper cw: contactList)
        {
            if(cw.selected==true)
            {
                if(cw.oppcont.Role!=null)
                {
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
        if(primarycontactlist.size()>0 && rolestring != null)
        {
            location=false;
            contactid=null;
            contactid = primarycontactlist[0].Id;
            oldcon=true;
            newcon=false;                 
            contactdisplay=false;
            finaldetailsdiplay=true;
            System.debug('----1729-----finaldetailsdiplay:'+finaldetailsdiplay);
            consavedisplay=true;
            conbackdisplay=true;
            conchangedisplay=false;
            contactbackbuttondisplay=false;
        }       
        else
        { 
            location=true;
            primarycontactrolelist.clear();
            roleslist.clear();
        }
        return null;
    }
    public String getSecondaryproductquestion()
    {
        return 'Are there any secondary products associated to this deal?       ';      
    }
    public List<SelectOption> getProductgrouplist()
    {
         List<SelectOption> productgrp = new List<SelectOption>();
         List<String> op = new List<String>();
          /*Developer Name: Madhu Paladugu
            Date          : 2/27/13
            Case Number   : 01192467
         */
         List<PricebookEntry> groupedResults = [select Product2.IM_Revenue_Type__c , Product2.IM_Product_Class__c,Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2.IM_Product_Class__c!=null and Product2.IM_Product_Class__c!='Document Management Solutions' and CurrencyIsoCode =:oppcurrency and Product2.IsActive=true and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code')];
         //List<PricebookEntry> groupedResults = [select Product2.IM_Product_Class__c from PricebookEntry where Product2.IM_Product_Class__c!=null and Product2.IM_Product_Class__c!='Document Management Solutions' and CurrencyIsoCode =:oppcurrency and Product2.IsActive=true];
         
          for (integer i=0; i< groupedResults.size() ; i++)   {
                     
                    op.add(groupedResults[i].Product2.IM_Product_Class__c);
                    
        }
          Set<String> groupedResultsSet = new Set<String>(Op);
        List<String> listStrings = new List<String>(groupedResultsSet);
        listStrings.sort();
        for (integer i=0; i< listStrings.size() ; i++)   {
                     
                    productgrp.add(new SelectOption(listStrings[i] ,listStrings[i]));
                    
        }
        return productgrp;
    }
    public List<Contact> GetPrimarycontactlist(){
        if(primarycontactlist.size()>0) return primarycontactlist;   else   return null;
    }
    public List<pricebookwrapper> getBundleproductlistwrap(){
        if(a==0 && bundleproductlistdisplay==true)
        {
        for(PricebookEntry e: bundleproductlist)    bundleproductlistwrap.add(new pricebookwrapper(e));
        a++;
        }
        return bundleproductlistwrap;
    }
    public List<SelectOption>getBundleslist()
    {
        bundleslist.clear();
        List<String> bl = new List<String>();
        List<Product_Bundle__c> bundlenames = [Select Name From Product_Bundle__c where Bundle_Type__c=:selectedbundletype];
        for(integer i=0; i<bundlenames.size(); i++)
                bl.add(bundlenames[i].Name);
        Set<String> blset = new Set<String>(bl);
        List<String>blist = new List<String>(blset);
        List<String>newblist=new List<String>();
        blist.sort();
        List<Id> product2id = new List<Id>();
        //Pricebook2 prodgrpname1 = [Select Id from  Pricebook2 where Name=:prodgroup]; 
        for(integer i=0; i<blist.size(); i++)
        {
            product2id.clear();
            List<Product_Bundle__c> selectedbundlelist1 = [Select Id, Product_ID__c from Product_Bundle__c where Name =:blist[i]];
            for(integer x=0; x<selectedbundlelist1.size(); x++)
                product2id.add(selectedbundlelist1[x].Product_ID__c);
            /*Developer Name: Madhu Paladugu
              Date          : 2/27/13
              Case Number   : 01192467
            */
            List<PricebookEntry> pbe5 =[select  Id,Pricebook2.IsStandard,Product2.IM_Revenue_Type__c, Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2Id in : product2id and CurrencyIsoCode =: oppcurrency and Pricebook2Id =:productgroupnameId and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') and IsActive=true order by Name];    
            //List<PricebookEntry> pbe5 =[select  Id from PricebookEntry where Product2Id in : product2id and CurrencyIsoCode =: oppcurrency and Pricebook2Id =:productgroupnameId/*prodgrpname1.Id*/ and IsActive=true order by Name];
            system.debug('checking size'+blist[i]+pbe5.size());
            if(pbe5.size()>0)
            {
                newblist.add(blist[i]);
            } 
        }
        if(newblist.size()>0)
        {
            emptybundles=false;
            for(integer i=0; i<newblist.size(); i++)
            bundleslist.add(new SelectOption(newblist[i], newblist[i]));
        }
        else
        {
            emptybundles=true;     bundleslist.add(new SelectOption('NONE','NONE'));
        }
        return bundleslist;
    }
    public List<SelectOption> getPricebooklist()
    {
         pricegrp.clear();
         List<String> opg = new List<String>();
          /*Developer Name: Madhu Paladugu
          Date          : 2/27/13
          Case Number   : 01192467
        */
         List<PricebookEntry>pricegroupedResults = [select Product2.IM_Revenue_Type__c, Product2.IM_Product_Line__c,Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2.IM_Product_Line__c!=null and CurrencyIsoCode =:oppcurrency and Product2.IsActive=true and Product2.IM_Product_Class__c=:selectedpg and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code')];
         //List<PricebookEntry>pricegroupedResults = [select Product2.IM_Product_Line__c from PricebookEntry where Product2.IM_Product_Line__c!=null and CurrencyIsoCode =:oppcurrency and Product2.IsActive=true and Product2.IM_Product_Class__c=:selectedpg];
         
          for (integer i=0; i< pricegroupedResults.size() ; i++)   {                    opg.add(pricegroupedResults[i].Product2.IM_Product_Line__c);
                    
        }
        Set<String> pricegroupedResultsSet = new Set<String>(Opg);
       // List<String> pricelistStrings = new List<String>(pricegroupedResultsSet);
        List<String> newpricelistStrings=new List<String>(pricegroupedResultsSet);
        //pricelistStrings.sort();        
        /*Developer Name: Madhu Paladugu
          Date          : 2/27/13
          Case Number   : 01192467
        */
        /*List<Product2> proids= new List<Product2>();
        Pricebook2 pb1 = new Pricebook2();
        
        for (integer i=0; i< pricelistStrings.size() ; i++)
        {        
                List<Product2> pro1 = [select Id, IM_Product_Class__c, IM_Product_Line__c from Product2 where IM_Product_Line__c = : pricelistStrings[i] and IM_Product_Class__c = :selectedpg];
                for(integer x=0; x<pro1.size();x++)
                {
                    proids.add(pro1[x]);
                }
                List<PricebookEntry> pbe1 =[select  Id from PricebookEntry where Product2Id in : proids and CurrencyIsoCode =: oppcurrency and Pricebook2Id =:productgroupnameId and IsActive=true order by Name];
                if(pbe1.size()>0)
                {
                    newpricelistStrings.add(pricelistStrings[i]);
                }
        }*/
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
         
        return pricegrp;
    }
    public List<pricebookwrapper> getPricebookentries(){
        
       if((k==0)&& pricebookdisplay==true)
       {        
        for(PricebookEntry c: pricebookentries)    pricebookList.add(new pricebookwrapper(c));
        k++;
       }
       return pricebookList;
    }
    public List<PricebookEntry> getPricebookentrieselected()
    {
        
        if(pricebookentrylist.size()>0)    return pricebookentrylist;
        else
            return null;
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
        if(secprodisplay==true &&(l==0))
        {
         for(PricebookEntry pb : [select  Id, CurrencyIsoCode,  ProductCode, Product2.Id, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.IM_Business_Line__c, Product2.IM_Product_Class__c, Product2.IM_Product_Line__c, Product2Id, Product2.Name, Name,Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c,UnitPrice, Product2.IM_Unit_of_Measure__c, Product2.IM_Revenue_Type__c from PricebookEntry where Product2.Secondary_Product_Allowed__c = true and CurrencyIsoCode=:oppcurrency and IsActive = true and Pricebook2Id =:pricebookid and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') order by Name])
       
        secondproductList.add(new secondproductwrapper(pb));
        l++;
        }
        if(secprodisplay==true && bundleexists==true &&(b==0))
        {        
        /*Developer Name: Madhu Paladugu
          Date          : 2/27/13
          Case Number   : 01192467
        */
        for(PricebookEntry pb : [select  Id, CurrencyIsoCode,  ProductCode, Product2.Id, Product2.Quantity_Override_value__c, Product2.Price_Override_value__c, Product2.IM_Business_Line__c, Product2.IM_Product_Class__c, Product2.IM_Unit_of_Measure__c, Product2.IM_Revenue_Type__c,  Product2.IM_Product_Line__c, Product2Id, Product2.Name, Name,Pricebook2.IsStandard,Product2.Use_List_Price_in_Wizard__c,UnitPrice from PricebookEntry where Product2.Secondary_Product_Allowed__c = true and CurrencyIsoCode=:oppcurrency and IsActive = true and Pricebook2Id =:productgroupnameId and Product2.RecordType.Name Not in ('Bill Code','IME Bill Code') order by Name])
        
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
        if(secondaryproductlist.size()>0)
        return secondaryproductlist;
        else     return null;
    }
    public List<SelectOption> getProductclass()
    {
        if(multipleclassdisplay==true)
            return productclass;
        else    return null;
    }
    public List<PricebookEntry> getCompleteproductlist()
    {
        return completelist;
    }
    public List<pricebookwrapper> getNewpricebookentries(){
        if(s==0 && addprimaryprod==true)
        {
        for(PricebookEntry e: newpricebookentries) newpricebookList.add(new pricebookwrapper(e));
            s++;
        }
        return newpricebookList;
    }
    public List<SelectOption> getBundletypelist()
    {
         List<SelectOption> bundletypelist = new List<SelectOption>();         
            String s = productgroupnameId;//prodgrpname.Id;
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
    public List<contactwrapper> getPrimarycontacts(){
        if(j==0)
        {
        for(Contact c: [Select FirstName, LastName, IM_Functional_Area__c, IM_Job_Level__c, IM_Academic_Title__c, Title, Email, IM_Language_Preference__c, IM_Responsible_For__c, Phone, MobilePhone, Fax, IM_Timezone__c, Name, IM_Role__c, (Select Id, Role From AccountContactRoles) From Contact where AccountId =:opportunity.AccountId limit 200])
        contactList.add(new contactwrapper(c));
        j++;
        }
        return contactList;
    }
      public class contactwrapper{
        public Contact acc{get; set;}
        public Boolean selected {get; set;}
        public OpportunityContactRole oppcont;
        public OpportunityContactRole getOppcont()
        {if(oppcont == null) oppcont = new OpportunityContactRole();
        return oppcont;}
        public contactwrapper(Contact a){
            acc = a;
            selected = false;
        }
    }
    public PageReference getSelected(){
        primarycontactlist.clear();
        for(contactwrapper cawrapper : contactList)
        if(cawrapper.selected == true)
                    primarycontactlist.add(cawrapper.acc);        
        return null;
    }
    //GSA
    //Case Number : 00426534
    /*Start*/
    public List<GSAWrapper> getGSATestList(){
        System.debug('--------calling getGSATestList method-------isThisNARACFROpportunity:'+isThisNARACFROpportunity);
        List<GSA_Contact_Email_List__c> GSAsettings = GSA_Contact_Email_List__c.getall().values();
        //if(leadid == NULL){
            if(Opportunity.AccountId != Null){
                Account acc = [Select Id, Name, Account_Segment__c,Account_Sub_Segment__c,(SELECT Contact.Email FROM Account.Contacts) From Account where Id =: Opportunity.AccountId];
                System.debug('--748--acc:'+acc);
                if(acc.Account_Segment__c =='Vertical' && acc.Account_Sub_Segment__c =='Government'){
                    system.debug('+++++++++++inside if account+++++++'+acc);
                    isThisGovtOpportunity=true;
                    System.debug('------here Making True to First Question--------isThisGovtOpportunity:'+isThisGovtOpportunity);
                    
                }          
            }
        //}
              
        if(ContactId != Null){
            Contact contEmail = [Select Email From Contact where Id =:ContactId];
            for(GSA_Contact_Email_List__c GSAEmailList: GSAsettings){
                if(contEmail.Email != Null && GSAEmailList.Domain_Extension__c == contEmail.Email.substringAfterLast('@')){
                    System.debug('-----------contact domain contains an extension listed in custom settings-------------');
                    isThisGovtContact = true;
                    break;
                }               
            }
        }  
        
        System.debug('----2527-----isExecuteGSAtestWrap:'+isExecuteGSAtestWrap); 
        if(isExecuteGSAtestWrap){
            System.debug('---2529------GSATestList:'+GSATestList); 
            if(GSATestList.size()==0){
                GSATestList.clear();
                GSAQuestions=[Select o.Product__r.Name, o.Product__c,o.Answer_Format__c, o.Name, o.Id, o.Answer_Picklist__c From Opportunity_Questions__c o where o.Product__r.Name='GSA Dummy Product' and Active__c=true order by Question_Order__c ];
                System.debug('--------GSAQuestions:'+GSAQuestions);
                for(Opportunity_Questions__c oq:GSAQuestions){
                   System.debug('--2534---isThisGovtOpportunity:'+isThisGovtOpportunity +'\t isThisNARACFROpportunity:'+isThisNARACFROpportunity);                   
                   if(oq.Name=='Is this an opportunity for a US federal government customer?' && isThisGovtOpportunity==true){     GSATestList.add(new  GSAWrapper(oq,true));
                       System.debug('----2537--for 1st question--GSATestList:'+GSATestList);
                   }
                   else if(oq.Name== 'Is this a NARA/CFR Compliant Opportunity?' && isThisNARACFROpportunity==true){  GSATestList.add(new  GSAWrapper(oq,true));
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
    
    public class pricebookwrapper{
        public PricebookEntry pbe{get; set;}
        public Boolean selected {get; set;}
        public pricebookwrapper(PricebookEntry pb){
            pbe = pb;
            selected = false;
        }
    }
    public class completelistwrapper{
        public PricebookEntry pe{get; set;}
        public Decimal Price=null;
        public String strprice=null;
        public Integer Quantity{get;set;}
        public String strqty =null;
        public Decimal TotalPrice{get; set;}
        public Decimal getPrice()
        {
            system.debug('inside price'+Price);
            return Price;
        }
        public void setPrice(Decimal Price)
        {
            this.Price=Price.setScale(2);
            strprice=String.valueOf(Price);
            
        }
    /*    public Decimal getQuantity()
        {
            return Quantity;
        }
         public void setQuantity(String strqty)
        {
            
            Quantity=Integer.valueOf(strqty);
            
        } */
        public String getStrprice()
        {
            if(strprice.contains('.'))
            {
                Integer strlength=strprice.length();
                Integer strindex = strprice.indexOf('.');
                if(strindex==(strlength-2))
                    strprice=strprice+'0';
                else          strprice= strprice.substring(0,(strindex+3));               
            }
            else     {       strprice = strprice + '.00';
            }
            return strprice;
        }
   /*     public Decimal getQuantity()
        {
           
            return Quantity;
        }
        public void setQuantity(Integer Quantity)
        {
          
            strqty = String.valueof(Quantity);
        } */
  /*      public Decimal Quantity=null;
        public String strquantity=null;
        public Decimal getQuantity()
        {
           
            return Quantity;
        }
        public void setQuantity(Decimal Quantity)
        {
            this.Quantity=Quantity.setScale(2);
            strquantity=String.valueOf(Quantity);
        }
         public String getStrquantity()
        {
            if(strquantity.contains('.'))
            {
                Integer strlength=strprice.length();
                Integer strindex = strprice.indexOf('.');
                if(strindex==(strlength-2))
                    strquantity=strquantity+'0';
                else
                    strquantity= strquantity.substring(0,(strindex+3));               
            }
            else
            {
                strquantity = strquantity + '.00';
            }
            return strquantity;
        } */
        
      /*  public Decimal Revenue=null;
        public Decimal getRevenue()
        {
            return Revenue.setScale(2);
        } */
        public Decimal Revenue{get; set;}
        public void setRevenue(Decimal Revenue)
        {
            this.Revenue=Revenue.setScale(2);
        }
        public completelistwrapper(PricebookEntry pb, Boolean isListPrice){
            pe=pb;
            System.debug('----2264-----pe:'+pe);   
            System.debug('---2265-----isListPrice:'+isListPrice);
            if(isListPrice){           Price=pe.UnitPrice;
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
            if(questions.size()>0)    return true;
            else
                return false;
        }
        public testlistwrapper(Product2 pr){
            p=pr;
            System.debug('---2641----p:'+p +'\t p.Name:'+p.Name);
            /*Added on 2-19-2013*/
            if(p.Name == 'CFR Boxes' || p.Name == 'CFR Tape'){
                isThisNARACFROpportunity = true;
                System.debug('----2646-----isThisNARACFROpportunity :'+isThisNARACFROpportunity );               
            }
            /*End*/
            for(Opportunity_Questions__c oc :pr.Opportunity_Questions__r){ questions.add(new questionwrapper(oc));
            }
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
            for(Integer p=0; p<splitstring.size(); p++){    picklistanswers.add(new SelectOption(splitstring[p] ,splitstring[p]));
            }
            p++;
            }
            return picklistanswers;
        }
        public questionwrapper(Opportunity_Questions__c oq){
            oqc=oq;
            if(oq.Answer_Format__c =='Picklist')
            {
                picklistvalues = oq.Answer_Picklist__c;
                splitstring = picklistvalues.split(',');
            }
        }
    }
    public class secondproductwrapper{
        public PricebookEntry acc{get; set;}
        public Boolean selected {get; set;}
        public secondproductwrapper(PricebookEntry a){
            acc = a;
            selected = false;
        }
    }
    public PageReference getSelected1(){
        pricebookentrylist.clear();
        for(pricebookwrapper pbwrapper : pricebookList)    if(pbwrapper.selected == true)  pricebookentrylist.add(pbwrapper.pbe);
        return null;
    }
    /*GSA
      Case Number : 00426534
      Wrapper which process the GSA Questions      
    */
    /*Start*/
    public class GSAWrapper{
        public Opportunity_Questions__c Gsarec{get;set;}  
        Integer coun=0;
        public Boolean isQuestionEditable{
            get{ 
                if(isQuestionEditable==null){        
                    isQuestionEditable=false;
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
        for(pricebookwrapper pbwrapper : bundleproductlistwrap)   if(pbwrapper.selected == true)  selectedbundleproductlist.add(pbwrapper.pbe);        
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
        for(pricebookwrapper pbwrapper : newpricebookList)   if(pbwrapper.selected == true)        newpricebookentrylist.add(pbwrapper.pbe);
        return null;
    }  
    
    public boolean DisplayVendedSection(string callFrom){
        
        List<ID> selectedProductIds = new List<ID>();
        List<PricebookEntry> selectedProducts = new List<PricebookEntry>();
        Boolean RMProductsExists = false;
        string OpportunityType = '';
        system.debug('Method: DisplayVendedSection');
        system.debug('Call From:' + callFrom);
        system.debug('selectedpg:'+ selectedpg);
        system.debug('selectedpb:'+ selectedpb);
            
        
        for(pricebookEntry pe : selectedbundleproductlist){ System.debug('pe.selected:'+ pe);      selectedProducts.add(pe);          
        }
        
        for(pricebookEntry addiProdList : pricebookentrylist){ System.debug('pricebookentrylist:'+ addiProdList);                selectedProducts.add(addiProdList); 
        }
        
        for(pricebookEntry pe1 : secondaryproductlist){
            System.debug('pe1.selected:'+ pe1); 
                selectedProducts.add(pe1); 
        }
        
       
        
        for(pricebookEntry pe2 : newpricebookentrylist){      System.debug('pe2.selected:'+ pe2);   selectedProducts.add(pe2);  
        }
        
         if(opportunity != null){           
                OpportunityType = opportunity.Type;            
        }
        
       
        
        if((selectedpg=='Records Management') && (selectedpb=='Storage')){    RMProductsExists = true;
        }
        
        for(PricebookEntry pe: selectedProducts){
            if((pe.Product2.IM_Product_Class__c == 'Records Management') && (pe.Product2.IM_Product_Line__c=='Storage')){         RMProductsExists = true;
            }
        }
        
        
        
        system.debug('RMProductsExists:'+ RMProductsExists);
        system.debug('hasVendedValue:'+hasVendedValue);
        if((RMProductsExists== true) && (hasVendedValue == false) && (OpportunityType != 'Renewal') && (opportunity.StageName == '2 - Solution Developed' || opportunity.StageName == '3 - Solution Agreed' 
            || opportunity.StageName == '4 - Negotiate' || opportunity.StageName == '5 - Signed/PO in')){    RMProductsExists = true;
            } else {  RMProductsExists = false;   }
        
        return RMProductsExists;
    }
}
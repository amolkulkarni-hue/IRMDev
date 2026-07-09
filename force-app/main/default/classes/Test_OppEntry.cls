/**
**Author: Raj Gottipolu
**Date: 10/31/11
**Company: HCL America
**Comments: Test class for 'OppEntryClass'
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 08/13/2013; Srinivasa Rao/Randstad; Opty Wizard Enhancement - Contact Search (Case # 01654528); Initial release
**/

/* 
**Modified By: TCS  
**Date: 14 Jun 2023
**Removed the fields CDM_Registration_Number__c dependency as part of #16051
*/
@isTest(SeeAllData = True)
private class Test_OppEntry {
    
    static testMethod void myUnitTest() {        
        
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];  
        User u = new User(alias = 'standt', email='standarduser@testorg.com',
                          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/Los_Angeles', username='hello.test1@testorg.com', CurrencyIsoCode='USD');
        insert u;
        
        Test.starttest();
        RecordType rec= [select Id, Name from RecordType where Name = 'Standard Opportunity'];
        System.currentPageReference().getParameters().put('RecordType',rec.Id);
        
        Pricebook2 p = [select Id, Name from Pricebook2 where Name='North America'];
        Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
        
        String s = p.Id;
        String subs=s.substring(0,15);
        
        List<Product2> newProduct2List = new List<Product2>();
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test34', 
                CurrencyIsoCode='USD', 
                IsActive=true);
                
        Product2 product1 = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test145',
                CurrencyIsoCode='USD',
                IM_Product_Line__c='test line',
                IM_Product_Class__c='test class', 
                IsActive=true);
                
        newProduct2List.add(product);
        newProduct2List.add(product1);
        insert newProduct2List;
        
        List<Product_Bundle__c> pbcList = new List<Product_Bundle__c>();
        
        Product_Bundle__c pbc = new  Product_Bundle__c(
            Name='test bundle 1',
            Bundle_Type__c='Packaged Initiative',
            Product_Group_ID__c=subs,
            Product_ID__c=newProduct2List[0].id
        );
        
        Product_Bundle__c pbc1 = new  Product_Bundle__c(
            Name='test bundle 2',
            Bundle_Type__c='Packaged Initiative',
            Product_Group_ID__c=subs,
            Product_ID__c=newProduct2List[1].id
        );
        
        pbcList.add(pbc);
        pbcList.add(pbc1);
        insert pbcList;
        
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = standardPB.Id, 
            Product2Id = newProduct2List[0].Id, 
            UnitPrice = 1, 
            IsActive = true,
            CurrencyIsoCode='USD', 
            UseStandardPrice = false);
        
        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = standardPB.Id, 
            Product2Id = newProduct2List[1].Id,
            CurrencyIsoCode='USD',  
            UnitPrice = 1, 
            IsActive = true, 
            UseStandardPrice = false);
        
        PricebookEntry pbe1 = new PricebookEntry(
            IsActive=true,
            UnitPrice=1,
            UseStandardPrice = false,
            CurrencyIsoCode='USD',
            Product2Id=newProduct2List[1].Id,
            Pricebook2Id=subs);
        
        PricebookEntry pbe2 = new PricebookEntry(
            IsActive=true,
            UnitPrice=1,
            UseStandardPrice = false,
            CurrencyIsoCode='USD',
            Product2Id=newProduct2List[0].Id,
            Pricebook2Id=subs);
        
        pbeList.add(standardPrice);
        pbeList.add(standardPrice1);
        pbeList.add(pbe1);
        pbeList.add(pbe2);
        insert pbeList;
        
        List<Opportunity_Questions__c> newqtnList = new List<Opportunity_Questions__c>();
        
        Opportunity_Questions__c newqtn1 = new Opportunity_Questions__c(
            Name='test question 1',
            Answer_Format__c='text',
            Question_Order__c='1',
            Active__c=true,
            Product__c=newProduct2List[0].Id);
                
        Opportunity_Questions__c newqtn2 = new Opportunity_Questions__c(
            Name='test question 2',
            Answer_Format__c='Checkbox',
            Question_Order__c='2',
            Active__c=true,
            Product__c=newProduct2List[0].Id);
                
        Opportunity_Questions__c newqtn3 = new Opportunity_Questions__c(
            Name='test question 2',
            Answer_Format__c='Picklist',
            Question_Order__c='2',
            Answer_Picklist__c='value1,value2,value3',
            Active__c=true,
            Product__c=newProduct2List[1].Id);
                
        Opportunity_Questions__c newqtn4 = new Opportunity_Questions__c(
            Name='test question 1',
            Answer_Format__c='text',
            Question_Order__c='1',
            Active__c=true,
            Product__c=newProduct2List[1].Id);
        
        newqtnList.add(newqtn1);
        newqtnList.add(newqtn2);
        newqtnList.add(newqtn3);
        newqtnList.add(newqtn4);
        
        insert newqtnList;
     	
        IM_Country__c testCountry = new IM_Country__c(Name='United Kingdom');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='United Kingdom');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United Kingdom';
        setting.object_name__c = 'Account';
        insert setting;
        
        List<Account> accList = new List<Account>();
        Account acc = new Account(name='Test Acct',Billing_County__c='United Kingdom',IMGA_Owner__c= u.id,
								 BillingCountry='United Kingdom',
                                 Account_Sub_Segment__c = 'Healthcare');
        
        //Account acc = new Account(Name='Account4UnitTest',Account_Sub_Segment__c = 'Healthcare');
        //Account acc1 = new Account(Name='Account4UnitTest1');
        Account acc1 = new Account(name='Test Acct1',Billing_County__c='United Kingdom',IMGA_Owner__c= u.id,
								 BillingCountry='United Kingdom');
        accList.add(acc);
        accList.add(acc1);
        
        insert accList;
            
        List<Contact> conList = new List<Contact>();
        
        Contact c1 = new Contact(LastName='TestContact1',
                                 FirstName='TestFirstName',
                                 Email='testemail@email.com',
                                 AccountId=accList[0].Id,
                                 MailingCity = 'Malden', 
                                // MailingCountry = 'USA', 
                                 //MailingCountry = 'United States',
                               //  testInCountry1__Country_field__c='United Kingdom',
                                 MailingCountry ='United Kingdom',
                                 MailingPostalCode = '02148', 
                                 MailingState = 'MA',  
                                 MailingStreet = '745 Atlantic Ave');
        
        Contact c2 = new Contact(LastName='TestContact3',
                                 FirstName='TestFirstName1',
                                 Email='testemail@email.com',
                                 AccountId=accList[1].Id,
                                 MailingCity = 'Malden', 
                                 MailingCountry ='United Kingdom',
                               //  testInCountry1__Country_field__c='United Kingdom',
                                // MailingCountry = 'USA',
                                // MailingCountry = 'United States', 
                                 MailingPostalCode = '02148',  
                                 MailingState = 'MA', 
                                 MailingStreet = '745 Atlantic Ave');
        
        conList.add(c1);
     //   conList.add(c2);
        insert conList;
        
        Competitor__c com=new Competitor__c(Name='test');
        insert com;
        
        //Test.starttest();       
        Lead l = new Lead();
        l.FirstName = 'Lead';
        l.LastName = 'TestContact';
        l.Status = 'Open'; 
        l.IM_Lead_Source_Most_Recent__c = 'Email';
        l.IM_Lead_Stage__c = '1-Inquiry';
        l.Company = 'Account4UnitTest1';
        l.Email = 'testemail@email.com';
        l.Street = '745 Atlantic Ave';
        l.City = 'London';
        l.State = 'London';
        l.Country = 'United Kingdom';
        l.PostalCode = 'SE1 2TT';
        insert l;
        Opportunity opp = new Opportunity();
        opp.IME_Vended_Unvended__c='Both';
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        System.currentPageReference().getParameters().put('leadAccountName',accList[1].Name);
        System.currentPageReference().getParameters().put('oppname','ran1x1dom');
        System.currentPageReference().getParameters().put('ownerId',u.Id);
        System.currentPageReference().getParameters().put('leadid',l.Id);
        System.currentPageReference().getParameters().put('leadid',null);
        System.currentPageReference().getParameters().put('status','Converted');
        System.currentPageReference().getParameters().put('strStage','CreateNewAccount');
        System.currentPageReference().getParameters().put('straccname',accList[1].Id);
        System.currentPageReference().getParameters().put('dupe','true');
        System.currentPageReference().getParameters().put('conid',c1.id);
        System.currentPageReference().getParameters().put('accid',acc1.id);
        ApexPages.StandardController lsc = new ApexPages.StandardController(opp);
        OppEntryClass op = new OppEntryClass(sc);
        op.acctId=accList[0].id;
        op.canOpp='test';
        op.getCompetitor(); 
        op.prodgroupId=p.Id;
        op.autorun();
        op.getRunwizard(); 
        op.getOpportunity().StageName='Lost';
        op.getOpportunity().AccountId=acc.Id;
        op.getOpportunity().Name='Test opp';
        op.getOpportunity().Type='New Deal';
        op.getOpportunity().Probability=0;
        op.getOpportunity().CloseDate=system.today();
       //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        op.getOpportunity().IM_Booked_Date__c=system.today(); 
        op.getOpportunity().Group_Purchasing_Organization_GPO__c=''; 
        op.getOppcomp().Competitor__c=com.id;
        
        op.saveOpp();
        
        op.ContactSearchString='Test';
        
        op.doSearchOncontactRole();
        op.ClearSearchOnContactRole();
        //op.getPrimarycontacts();
        op.contactList[0].selected=true;
        op.contactList[0].getOppcont();
        op.contactList[0].oppcont.Role='Evaluator';
       // op.contactList[1].selected=false;
      //  op.contactList[1].getOppcont();
        //op.contactList[1].oppcont.Role='Evaluator';
        op.getSelected();        
        op.savePrimarycontact();
        op.oldconsavebutton();
        //Srinu:Added on 1/17/2013 for Madhu's new added Page Reference Method.
        op.returnOppPage();
        op.GetPrimarycontactlist();
        op.primarycontactnotfound();
        op.getContact().Email='raj@gmail.com';
        op.getContact().Phone='6517951874';
        op.getContact().MailingCountry='USA';
        op.getContact().LastName='raj';
        op.getOcr().Role='Evaluator';
        op.newcontactsave();
        op.getBundletypelist();
        op.setSelectedbundletype('Packaged Initiative');
        op.bundleyes();
        op.getBundleslist();        
        op.setSelectedbundle(pbcList[0].Name);
        op.nextbundle();
        op.getBundleproductlistwrap();
        //op.bundleproductlistwrap[0].selected=true;
        op.getselectedb();
        op.bundleproselected();
        op.secprotrue();
        op.getSecondaryproducts();
        op.secondproductList[0].selected=true;
        op.secondproductList[1].selected=true;
        op.getSelected2();        
        op.GetSecondaryproductlist();
        op.secprodisplaynext();
        op.getTestlist();
        op.getTestlistwrap();
        for(Integer j=0; j<op.testlistwrap.size(); j++)
        {
            op.testlistwrap[j].getQuestions();
            op.testlistwrap[j].getQuestionsexist();
            if(op.testlistwrap[j].questions.size()>0)
            {
                for(Integer k=0; k<op.testlistwrap[j].questions.size(); k++)
                {
                    if(op.testlistwrap[j].questions[k].oqc.Answer_Format__c=='Checkbox')
                    {
                        op.testlistwrap[j].questions[k].getCheckboxanswers();
                        op.testlistwrap[j].questions[k].checkboxanswer='yes';
                    }
                    else if(op.testlistwrap[j].questions[k].oqc.Answer_Format__c=='Text')
                    {
                        op.testlistwrap[j].questions[k].textanswer='test';
                    }
                    else
                    {
                        op.testlistwrap[j].questions[k].getSplitstring();
                        op.testlistwrap[j].questions[k].getPicklistanswers();
                        op.testlistwrap[j].questions[k].picklistanswer='value1';
                    }
                }
            }
        }        
        op.addproducts();
        op.getCompletelistwrap();
        op.getCompleteproductlist();
        //Srinu: Commented out on 10/05, Because this method is commented out in corresponding class.
        //op.getClids();
        //op.getProductids();
        for(Integer i=0; i<op.testlistwrap.size();i++)
        {
            op.testlistwrap[i].getComplist();
            op.testlistwrap[i].complist[0].Price=50.0;
            op.testlistwrap[i].complist[0].setPrice(50.0);
            op.testlistwrap[i].complist[0].getStrprice();               
            op.testlistwrap[i].complist[0].getPrice();
            op.testlistwrap[i].complist[0].Quantity=20;
            op.testlistwrap[i].complist[0].setRevenue(1000);
            op.testlistwrap[i].complist[0].getRevenue();
        }
        op.displaydetails();
        op.oppbackbutton();
        op.getOpportunity().StageName='3-Solution Agreed';
        op.getOpportunity().AccountId=acc.Id;
        op.getOpportunity().Name='Test opp';
        op.getOpportunity().Type='New Deal';
        op.getOpportunity().IME_Vended_Unvended__c='Vended';
        op.getOpportunity().Probability=60;
        op.getOpportunity().CloseDate=system.today()-1;
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        op.getOpportunity().IM_Booked_Date__c=system.today();
        op.oppsavebutton();
        op.newbacktopricequantity();
        for(Integer i=0; i<op.testlistwrap.size();i++)
        {
            op.testlistwrap[i].getComplist();
            op.testlistwrap[i].complist[0].Price=50.032;                
            op.testlistwrap[i].complist[0].getPrice();
            op.testlistwrap[i].complist[0].Quantity=20;
        }
        op.productsavebutton();
        op.newbacktoquestions();
        //Srinu: Added on 03-20-2013
        op.newbacktogsaquestions();
        op.gsaquestionsavebutton();
        op.opportunity.IME_Vended_Unvended__c = 'Both';
       // #16915 op.opportunity.Vended__c= null;
        op.gsaquestionsavebutton();
        op.oppsavebutton();     
        op.addproducts();   
        op.opportunity.IME_Vended_Unvended__c = 'Both';
        /*#16915op.opportunity.Vended__c= 100;
        op.opportunity.Unvended__c = 3;  */      
        op.gsaquestionsavebutton();
        op.oppsavebutton();     
        op.addproducts();   
        
        op.gsaquestionsavebutton();
        op.getTestlist();
        op.getTestlistwrap();
        for(Integer j=0; j<op.testlistwrap.size(); j++)
        {
            op.testlistwrap[j].getQuestions();
            op.testlistwrap[j].getQuestionsexist();
            if(op.testlistwrap[j].questions.size()>0)
            {
                for(Integer k=0; k<op.testlistwrap[j].questions.size(); k++)
                {
                    if(op.testlistwrap[j].questions[k].oqc.Answer_Format__c=='Checkbox')
                    {
                        op.testlistwrap[j].questions[k].getCheckboxanswers();
                        op.testlistwrap[j].questions[k].checkboxanswer='yes';
                    }
                    else if(op.testlistwrap[j].questions[k].oqc.Answer_Format__c=='Text')
                    {
                        op.testlistwrap[j].questions[k].textanswer='test';
                    }
                    else
                    {
                        op.testlistwrap[j].questions[k].getSplitstring();
                        op.testlistwrap[j].questions[k].getPicklistanswers();
                        op.testlistwrap[j].questions[k].picklistanswer='value1';
                    }
                }
            }
        }
        op.questionsavebutton();        
        op.contactbackbutton();
        op.getContact().Email='raj@gmail.com';
        op.getContact().Phone='6517951874';
        op.getContact().MailingCountry='USA';
        op.getContact().LastName='raj';
        op.getOcr().Role='Evaluator';
        op.consavebutton();        
        op.savedetails();
        op.bundleback();
        op.newcontactback();
        op.oldcontactbackbutton();
        op.backtoquestions();
        op.cancelsecpro();
        op.cancelprimarycontact();
        op.bundlepronotselected();
        op.bundleno();
        op.addprodsno();
        op.otherinformationback();
        op.setSelectedbundle(pbcList[0].Name);
        op.getAddprimaryprod();
        op.getAddprodline();
        op.getAddprods();
        op.getBacktoquestionsdisplay();
        op.getAddproductsdisplay();
        //Srinu:Added on 1/17/2013 from Madhu's Extra added Page to Wizard.
        op.getshowfinalpage();
        op.getBundlelistdisplay();
        op.getBundleproductlistdisplay();
        op.getConbackdisplay();
        op.getConchangedisplay();
        op.getConleadbackdisplay();
        op.getConrolerror();
        op.getConroleselectblock();
        op.getConsavedisplay();
        op.getContactbackbuttondisplay();
        op.getContactdisplay();
        op.getContacterror();
        op.getDisplaydetailsdisplay();
        op.getFinaldetailsdiplay();
        op.getHighleveldisplay();
        op.getLeadoppnextdisplay();
        op.getLeadoppnextdisplay();
        op.getLeadoppsavedisplay();
        op.getNewcon();
        op.getNewcontactdisplay();
        op.getOldcon();
        op.getOppbackbuttondisplay();
        //Srinu:Added on 03-20-2013
        op.getgsaQuestionblockrender();
        op.getOppcanceldisplay();        
        op.getOppdetails();
        op.getOppnextdisplay();
        op.getOppsavedisplay();
        op.getOverwriterror();
        Test.stopTest();
        op.getPricebookdisplay();
        op.getPricebookerror();
        op.getProductsavebuttondisplay();
        op.getQuantityexists();
        op.getQuestionblockrender();
        op.getQuestionerror();
        op.getQuestionsavedisplay();
        op.getQuestionsbackdisplay();
        op.getQuestionsnextdisplay();
        op.getRoleselectblock();
        op.getSecprodisplay();
        op.getSecproerror();
        //Srinu: Added on 03-20-2013
        op.getGSAQuestiondisplay();
        op.getSecproselectdisplay();
        op.cancelpg();
        op.cancelbundle();
        op.backtopricequantity();
        op.cancelpb();
        op.getUsercurrency();
        op.getSelectedpg();
        op.getSelectedpb();
        op.getExistingaccountname();
        op.getExistingcontactname();
        op.getLeadid();
        op.getOppaccid();
        //Srinu: Added on 03-20-2013
        op.getisExecuteGSAtestWrap();
        op.getisThisNARACFROpportunity();
        op.getOppname();
        op.getOppowner();
        op.getPrice();
        op.getPriceoverride();
        op.getQuantity();
        op.getQuantityoverride();
        op.getRolestring();
        op.getSample();
        op.getSelectedbundle();
        op.setPrice(10);        
        op.setRolestring('rolestring');
        op.setQuantity(25);
        op.setSample('sample');
        op.setSelectedbundle('selectedbundle');
        op.setSelectedpb('selectedpb');
        op.setSelectedpg('selectedpg');
        op.getSecondaryproductquestion();
        op.getLocation();
        op.getCheckbox();
        op.getQuestiondisplay();
        op.getOthererror();
        op.getOtherinformationdisplay();
        op.getGranularleveldisplay();
        op.getBundlequestiondisplay();
        op.getBundlemsg();        
        op.getContact();
        op.getNewbundle();
        op.getOtherinformation();
        op.setOtherinformation('test');
        op.getSelectedbundletype();
        op.setSelectedbundletype('test');
        op.setCheckbox(true);      
        op.getOcr();
        op.getCompletelistsize();
        op.getTestlistsize();
        op.getTestlist();
        op.getCompleteproductlist();
        op.getTestlistwrap();
        //Srinu: Added on 03-21-2013
        for(Integer j=0; j<op.testlistwrap.size(); j++){
            for(Integer k=0; k<op.testlistwrap[j].questions.size(); k++){
                System.debug('--484---inside questions for loop----');
                op.testlistwrap[j].questions[k].getSplitstring();
                op.testlistwrap[j].questions[k].getCheckboxanswers();
                op.testlistwrap[j].questions[k].getPicklistanswers();
            }
        }
        op.getCompletelistwrap();
        op.getEmptybundles();
        op.getEmptynewprodlist();
        op.getEmptyprodlines();
        op.getEmptyprodlist();
        op.getEmptyproductlist();
        //Srinu:Added on 03-20-2013
        op.getgsaQuestionsavedisplay();
        op.getContactid();
        op.secprodisplayback();
        op.ContactSearchString='null';
        //Srinu: Added on 03-20-2013
        //if((op.getOpportunity().AccountId=acc.Id) != NULL)
        op.getGSATestList();
        
        Account acct = new Account(Name='Account4UnitTesting',Registration_Number__c='test');
        
        Opportunity oppty = TestingUtils.createOpportunity('Testing', acc.Id, true);
        oppty.IME_Vended_Unvended__c = 'Vended';
        oppty.Group_Purchasing_Organization_GPO__c='Vizient';
       /*#16915 oppty.Vended__c =100;
        oppty.Unvended__c =0; */
        update oppty; 
        
        op.saveOpp();        
        op.cancelprimarycontact();
        op.oppFinalVenbackbutton();
        op.displaydetails();
        
        op.consavebutton();
        
        op.opportunity.IME_Vended_Unvended__c = 'Both';
       //#16915 op.opportunity.Vended__c = null;        
        op.saveOpp();
        
        op.opportunity.IM_Booked_Date__c = system.today().addDays(-5);
        op.opportunity.CloseDate = system.today();      
        op.saveOpp();
        
        op.opportunity.StageName = '0 - Pre-Qualification' ;
        op.opportunity.CloseDate = system.today().addDays(-5);      
        op.saveOpp();
        
        op.opportunity.Type='Up-Sell/Lift' ;
        op.opportunity.IM_Unit_of_Measure__c =null; 
        op.opportunity.IM_Up_Sell_Quantity__c = 10;  
        op.opportunity.IM_Up_Sell_Detail__c = 'test';        
        op.saveOpp();
        
        op.opportunity.IM_Up_Sell_Detail__c = null;     
        op.saveOpp();        
        
        op.opportunity.IM_Up_Sell_Quantity__c = null;       
        op.saveOpp();
    
        op.opportunity.IM_Up_Sell_Quantity__c = 10;  
        op.opportunity.Upsell_Customer_ID__c = null;      
        op.saveOpp();
        
        op.subSegHealthcare = 'true';
        op.opportunity.Group_Purchasing_Organization_GPO__c = '';
        op.saveOpp();
        
        Opportunity_Questions__c oq  = new Opportunity_Questions__c();
        oq.Name = 'Is this an opportunity for a US federal government customer?';
        oq.Answer_Format__c = 'Picklist';
        oq.Answer_Picklist__c = 'test';
        insert oq;
        
        OppEntryClass.GSAWrapper testWrap=new OppEntryClass.GSAWrapper(oq,true); 
        testWrap.textanswer='test';
        Opportunity_Questions__c oqq  = new Opportunity_Questions__c();
        oqq.Name = 'Is this a NARA/CFR Compliant Opportunity?';
        oqq.Answer_Format__c = 'Picklist';
        oqq.Answer_Picklist__c = 'test';
        insert oqq;
        
        OppEntryClass.GSAWrapper testWrap1=new OppEntryClass.GSAWrapper(oqq,true);
        OppEntryClass.questionwrapper qw =new OppEntryClass.questionwrapper(newqtn1);
        testWrap1.getPicklistanswers();
        qw.textanswer= 'test';
        qw.finalanswer='test';
        qw.checkboxanswer ='test';
        qw.getSplitstring();
        qw.getCheckboxanswers();
        qw.getPicklistanswers();
       // Test.stopTest();       
    }
    static testMethod void myUnitTest2() {
        
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin'];  
        User u = new User(alias = 'standt', email='standarduser@testorg.com',
                          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = prof.Id, Country = 'USA',
                          timezonesidkey='America/Los_Angeles', username='hello.test1@testorg.com', CurrencyIsoCode='USD');
        insert u;    
        
        
        RecordType rec= [select Id, Name from RecordType where Name = 'Standard Opportunity'];
        System.currentPageReference().getParameters().put('RecordType',rec.Id);
        
        Pricebook2 p = [select Id, Name from Pricebook2 where Name='North America'];
        Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
        
        String s = p.Id;
        String subs=s.substring(0,15);
        
        List<Product2> newProduct2List = new List<Product2>();
        
        Product2 product = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test67', 
                CurrencyIsoCode='USD', 
                IsActive=true);
                
        Product2 product1 = 
            new Product2(
                Secondary_Product_Allowed__c=true, 
                Name='test167',
                CurrencyIsoCode='USD',
                IM_Product_Line__c='test line',
                IM_Product_Class__c='test class', 
                IsActive=true);
                
        newProduct2List.add(product);
        newProduct2List.add(product1);
        
        insert newProduct2List;
        
        List<Product_Bundle__c> pbcList = new List<Product_Bundle__c>();
        
        Product_Bundle__c pbc = new  Product_Bundle__c(
            Name='test bundle 1',
            Bundle_Type__c='Packaged Initiative',
            Product_Group_ID__c=subs,
            Product_ID__c=newProduct2List[0].id
        );
        
        Product_Bundle__c pbc1 = new  Product_Bundle__c(
            Name='test bundle 2',
            Bundle_Type__c='Packaged Initiative',
            Product_Group_ID__c=subs,
            Product_ID__c=newProduct2List[1].id
        );
        
        pbcList.add(pbc);
        pbcList.add(pbc1);
        insert pbcList;
        
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = standardPB.Id, 
            Product2Id = newProduct2List[0].Id, 
            UnitPrice = 1, 
            IsActive = true,
            CurrencyIsoCode='USD', 
            UseStandardPrice = false);
        
        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = standardPB.Id, 
            Product2Id = newProduct2List[1].Id,
            CurrencyIsoCode='USD',  
            UnitPrice = 1, 
            IsActive = true, 
            UseStandardPrice = false);
        
        PricebookEntry pbe1 = new PricebookEntry(
            IsActive=true,
            UnitPrice=1,
            UseStandardPrice = false,
            CurrencyIsoCode='USD',
            Product2Id=newProduct2List[1].Id,
            Pricebook2Id=subs);
        
        PricebookEntry pbe2 = new PricebookEntry(
            IsActive=true,
            UnitPrice=1,
            UseStandardPrice = false,
            CurrencyIsoCode='USD',
            Product2Id=newProduct2List[0].Id,
            Pricebook2Id=subs);
        
        pbeList.add(standardPrice);
        pbeList.add(standardPrice1);
        pbeList.add(pbe1);
        pbeList.add(pbe2);
        insert pbeList;
        
        List<Opportunity_Questions__c> newqtnList = new List<Opportunity_Questions__c>();
        
        Opportunity_Questions__c newqtn1 = new Opportunity_Questions__c(
            Name='test question 1',
            Answer_Format__c='text',
            Question_Order__c='1',
            Active__c=true,
            Product__c=newProduct2List[0].Id);
        
        
        Opportunity_Questions__c newqtn2 = new Opportunity_Questions__c(
            Name='test question 2',
            Answer_Format__c='Checkbox',
            Question_Order__c='2',
            Active__c=true,
            Product__c=newProduct2List[0].Id);
                
        Opportunity_Questions__c newqtn3 = new Opportunity_Questions__c(
            Name='test question 2',
            Answer_Format__c='Picklist',
            Question_Order__c='2',
            Answer_Picklist__c='value1,value2,value3',
            Active__c=true,
            Product__c=newProduct2List[1].Id);
                
        Opportunity_Questions__c newqtn4 = new Opportunity_Questions__c(
            Name='test question 1',
            Answer_Format__c='text',
            Question_Order__c='1',
            Active__c=true,
            Product__c=newProduct2List[1].Id);
        
        newqtnList.add(newqtn1);
        newqtnList.add(newqtn2);
        newqtnList.add(newqtn3);
        newqtnList.add(newqtn4);
        
        insert newqtnList;
        
        IM_Country__c testCountry = new IM_Country__c(Name='Germany');
        insert testCountry;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, 
                                                                                    Alternative_Name__c='Germany');
        insert country;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'Germany';
        setting.object_name__c = 'Account';
        insert setting;
        
        List<Account> accList = new List<Account>();
        Account acc = new Account(name='Test Acct',Billing_County__c='Germany',IMGA_Owner__c= u.id,
								 BillingCountry='Germany',
                                 Account_Sub_Segment__c = 'Healthcare');
        
        //Account acc = new Account(Name='Account4UnitTest',Account_Sub_Segment__c = 'Healthcare');
        //Account acc1 = new Account(Name='Account4UnitTest1');
        Account acc1 = new Account(name='Test Acct1',Billing_County__c='Germany',IMGA_Owner__c= u.id,
								 BillingCountry='Germany');
        
        
       // List<Account> accList = new List<Account>();        
       // Account acc = new Account(Name='Account4UnitTest', Account_Sub_Segment__c = 'Healthcare');
        //Account acc1 = new Account(Name='Account4UnitTest1');
        
        accList.add(acc);
        accList.add(acc1);
        
        insert accList;
        
        List<Contact> conList = new List<Contact>();
        
        Contact c1 = new Contact(LastName='TestContact1',
                                 FirstName = 'FirName1',
                                 Email='testemail@email.com',
                                 AccountId=accList[0].Id,
                                 MailingCity = 'Malden', 
                                 MailingCountry ='Germany',
                               //  testInCountry1__Country_field__c='Germany',
                               //  MailingCountry = 'USA', 
                                 //MailingCountry = 'United States',
                                 MailingPostalCode = '02148', 
                                 MailingState = 'MA', 
                                 MailingStreet = '745 Atlantic Ave');
        
        Contact c2 = new Contact(LastName='TestContact2',
                                 FirstName = 'FirName2',
                                 Email='testemail@email.com',
                                 AccountId=accList[0].Id,
                                 MailingCity = 'Malden', 
                               //  testInCountry1__Country_field__c='Germany',
                                 //MailingCountry = 'USA',
                                 //MailingCountry = 'United States', 
                                 MailingCountry ='Germany',
                                 MailingPostalCode = '02148', 
                                 MailingState = 'MA', 
                                 MailingStreet = '745 Atlantic Ave');
        
        conList.add(c1);
       // conList.add(c2);
        insert conList;
        
        Opportunity oppty = TestingUtils.createOpportunity('Testing-Opp', acc.id, false);
        
            Competitor__c comp = new Competitor__c();
            comp.Name = 'Test Comp';
            insert comp;
            
        Opportunity_Competitor__c optyComp = new Opportunity_Competitor__c();
            optyComp.Opportunity__c = oppty.Id;
            optyComp.Competitor__c = comp.Id;
           // optyComp.Opportunity_Owner_Email__c = opp.Owner.Email;
            insert optyComp;
                    
        ApexPages.StandardController lsctr = new ApexPages.StandardController(oppty);
        oppEntryClass oec = new oppEntryClass(lsctr );
        oec.getCompetitor();
        oec.prodgroupId=p.Id;
        oec.autorun();
        oec.getRunwizard();
        oec.ContactSearchString='Test';
        oec.doSearchOncontactRole();
        oec.ClearSearchOnContactRole();
        oec.primarycontactlist.add(c1);
        oec.bundleback();
        oec.GetPrimarycontactlist();
        oec.primarycontactnotfound();
        oec.getContact().Email='raj@gmail.com';
        oec.getContact().Phone='6517951874';
        oec.getContact().MailingCountry='USA';
        oec.getContact().LastName='raj';
        oec.getOcr().Role='Evaluator';
        oec.newcontactsave();
        oec.getBundletypelist();
        oec.setSelectedbundletype('Packaged Initiative');
        oec.bundleyes();
        oec.getBundleslist();
        oec.setSelectedbundle(pbcList[0].Name);
        oec.nextbundle();
        oec.getBundleproductlistwrap();
        //oec.bundleproductlistwrap[0].selected=true;
        oec.getselectedb();
        oec.bundleproselected();
        oec.secprotrue();
        oec.getWhenClickedOnGo();
        
        //Test.starttest();       
        Lead l = new Lead();
        l.FirstName = 'Lead';
        l.LastName = 'TestContact';
        l.Status = 'Open'; 
        l.IM_Lead_Source_Most_Recent__c = 'Email';
        l.IM_Lead_Stage__c = '1-Inquiry';
        l.Company = 'Account1x12x23x34x45x56x67x74UnitTest1';
        l.Email = 'testemail@email.com';
        l.Street = '745 Atlantic Ave';
        l.City = 'London';
        l.State = 'London';
        l.Country = 'Germany';
        l.PostalCode = 'SE1 2TT';
        l.IM_Sales_Event__c = 'Campaign;';
        insert l;
        
        Opportunity opp = new Opportunity();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        System.currentPageReference().getParameters().put('leadAccountName',l.Company);
        System.currentPageReference().getParameters().put('oppname','ran1x12x23x34x45x56x67x7dom');
        System.currentPageReference().getParameters().put('ownerId',u.Id);
        System.currentPageReference().getParameters().put('leadid',l.Id);
        System.currentPageReference().getParameters().put('status','Converted');
        System.currentPageReference().getParameters().put('strStage','CreateNewAccount');
        System.currentPageReference().getParameters().put('straccname',accList[1].Id);
        System.currentPageReference().getParameters().put('dupe','true');
        System.currentPageReference().getParameters().put('conid',c1.id);
        System.currentPageReference().getParameters().put('accid',acc1.id);
        System.currentPageReference().getParameters().put('RecordType',rec.id);
        
        ApexPages.StandardController lsc = new ApexPages.StandardController(opp);
         Test.starttest();
        OppEntryClass lp = new OppEntryClass(lsc);
        lp.autorun();
        lp.runwizard = false;
        lp.isLightningUser = true;        
        lp.autorun();
        lp.runwizard = false;
        lp.isLightningUser = false;
        lp.autorun();
        lp.getRunwizard();
        lp.getLeadaccountname();
        lp.getopportunity();       
        lp.getLeadopportunity().StageName='Lost';
        lp.getLeadopportunity().Type='New Deal';
        lp.getLeadopportunity().Probability=0;
        lp.getLeadopportunity().CloseDate=system.today()-1;
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        lp.getLeadopportunity().IM_Booked_Date__c=system.today();
        lp.getLeadname();
        
        
        lp.leadoppnext();
        lp.getLeadcontacts();
        lp.getOcr().Role='Evaluator';
        lp.conleadnext();
        lp.setSelectedbundletype('All Other Product Lines');
        lp.bundleyes();
        lp.getProductgrouplist();
        lp.setSelectedpg('test class');
        lp.nextpg();
        lp.getPricebooklist();
        lp.setSelectedpb('test line');
        lp.nextpb();
        lp.getPricebookentries();
        lp.getSelected1();
        //Srinu: Added on 03-20-2013
        lp.getGSATestList();        
        lp.getPricebookentrieselected();
        lp.nextsecpro();
        lp.addprodsyes();
        lp.setSelectedpb('test line');
        lp.addprodlinenext();
        lp.getNewpricebookentries();
        lp.getSelected3();
        lp.addnextsecpro();        
        lp.getadditionalproductlist();
        lp.secprofalse();
        //Srinu: Added on 03-20-2013
        lp.GSAQuestions();
        lp.strStage='AddToExistingAccount';
        lp.selectedbundle=pbcList[0].Name;
        lp.setOtherinformation('test');
        lp.otherinformationnext();        
        lp.leadoppbackbutton();
        lp.getLeadopportunity().StageName='7 - Closed';
        lp.getLeadopportunity().Type='Renewal';
        lp.getLeadopportunity().Probability=100;
        lp.getLeadopportunity().CloseDate=system.today()-1;
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        lp.getLeadopportunity().IM_Booked_Date__c=system.today();
        lp.leadoppsave();
        lp.conleadback();
        lp.sObjLead.Competitively_Vended__c='Both';
        lp.conleadback();
        lp.secproback();
        lp.backtosecpro();
        lp.addcancelsecpro();
        lp.fromnewlist=true;
        lp.addprodsback();
        lp.fromnewlist=false;
        lp.addprodsback();
        lp.addprodlineback();
        lp.backtolead();  
        
        lp.savedetails();  
        //lp.getGSATestList(); 
        //Srinu: Added on 03-20-2013
        lp.getTestlistwrap();
        
        
        // System.debug('---772-----lp.getGSATestList:'+lp.getGSATestList());
        for(Integer j=0; j<lp.GSATestList.size(); j++){
           // System.debug('--774---inside GSATestList for loop----');
            lp.GSATestList[j].getPicklistanswers();
        }
        for(Integer j=0; j<lp.testlistwrap.size(); j++){
            for(Integer k=0; k<lp.testlistwrap[j].questions.size(); k++){
              //  System.debug('--778---inside questions for loop----');
                lp.testlistwrap[j].questions[k].getSplitstring();
                lp.testlistwrap[j].questions[k].getCheckboxanswers();
                lp.testlistwrap[j].questions[k].getPicklistanswers();
            }
        }
        /*Variable declaration for 'sendEmailNotification method'*/ 
             
        Lead tl = new Lead();
        tl.FirstName = 'Lead234';
        tl.LastName = 'TestContact123';
        tl.Status = 'Open'; 
        tl.Company = 'Account test';
        
     /* tl.IM_Lead_Source_Most_Recent__c = 'Email';        
        tl.IM_Lead_Stage__c = '1-Inquiry';        
        tl.Email = 'test.example@email.com';
        tl.Street = '745 Atlantic Ave1';
        tl.City = 'London';
        tl.State = 'London';
        tl.Country = 'United States';
        tl.PostalCode = 'SE1 2TT';*/
        
        tl.Unvended__c = 40;
       //#16915 tl.Vended__c = 10;
        tl.Competitively_Vended__c='Both';
        tl.Competitively_Vended__c='Vended';
        insert tl;
       
        lp.leadopportunityName = 'Testing-Opp';
        lp.leadstatus = 'open';
        lp.leadid =tl.id;
        
        lp.strStage='CreateNewAccount';
        lp.conleadback();
        lp.leadoppnext();
        lp.leadoppVendbackbutton();
        lp.savedetails();
        
        lp.acctId = acc.id;
        string ac = lp.acctId;
        lp.passAccId();
        Date dt = system.today();
        lp.setCompExpDate(dt);       
        dt = lp.getCompExpDate();
        lp.getOppcompetitors();
        
        lp.getLeadskipbutton();
        lp.getSkipbutton();
        lp.getOppcompblock();
        lp.getOppnextconbutton() ;
        lp.getLeadoppnextconbutton() ;
        lp.getOppbackbutton();
        lp.getLeadoppbackbutton();
        lp.getOc();
        
        id comptId = lp.getCompetitor();
        date comptExpDate = lp.getCompetitorExpirationDate();
        date expNotiDate=lp.getExpirationNotificationDate();
        Boolean unPrice = lp.getUnknownPricing();
        decimal sprice =lp.getStoragePrice();
        decimal rFile = lp.getRetrievalFile();
        decimal msc = lp.getMinStorageCharge();
        decimal rb=lp.getRetrievalBox();
        decimal adminFee=lp.getAdminFee();   
        decimal HandleCharge=lp.getHandlingCharge();
        decimal withdrawl=lp.getPermanentWithdrawal();
        decimal rt =lp.getRushTransport();
        lp.setcompetitor (comptId);
        lp.setcompetitorExpirationDate(comptExpDate);
        lp.setexpirationNotificationDate(expNotiDate );
        lp.setunknownPricing (unPrice);
        lp.setstoragePrice (sprice);
        lp.setretrievalFile(rFile);
        lp.setminStorageCharge(msc);
        lp.setretrievalBox(rb);
        lp.setadminFee(adminFee);
        lp.sethandlingCharge (HandleCharge);
        lp.setpermanentWithdrawal (withdrawl);
        lp.setrushTransport (rt);
        lp.oppcompnext();   
        lp.leadoppcompback();
        lp.oppcompback();
        lp.leadcompskip();
        lp.compskip();
        lp.oppcompsaverole();
        
        string oppStage = lp.getVaroppstage();
        id oppAcct =lp.getVaroppaccount();
        decimal oppProb= lp.getvaroppprob();
        
        Boolean dispFinalVend=lp.getFinalDispBackVended();
        Boolean dispbkVend=lp.getFinalDispBackLeadVended();
        Boolean finalgsadt=lp.getFinalgsadetails();
        Boolean oms=lp.getisOpportunityMeetsGSA();
        Boolean omsa=lp.getisOpportunityMeetsGSA();        
        
        Boolean flagErrDisplay= lp.getContactSearchErrorDisplay(); 
        Boolean flagVendDisplay= lp.getVendedSecDisplay();
        Boolean flagShowAgrmnt=lp.showClientAgreement;
        Contact c= oec.sObjContact;
        
        lp.setvaroppstage();
        lp.setvaroppaccount();
        lp.setvaroppprob();
        lp.pricebookentrylist.add(new PriceBookEntry());
        lp.newpricebookentrylist.add(new PriceBookEntry());
        lp.secondaryproductlist.add(new PriceBookEntry());        
        lp.addnextsecpro();
        lp.nextsecpro();
        lp.backtosecpro();
        
       // new OppEntryClass.pricebookwrapper([SELECT Id FROM PriceBookEntry][0]);
        Test.stopTest();  
    }   

    static testMethod void sendEmailNotification() {
        Test.startTest();
        Opportunity opp1 = new Opportunity();
        //ApexPages.StandardController sc1 = new ApexPages.StandardController(opp1);        
        ApexPages.StandardController lsc1 = new ApexPages.StandardController(opp1);
        OppEntryClass lp1 = new OppEntryClass(lsc1);      
        
        String strEmailBody = 'Error in the wizard. Please start over\n\n';
        String strEmailSub = 'Failed to retrieve Opportunity Id';
        lp1.sendEmailNotification(strEmailBody, strEmailSub); 
        Test.stopTest();
    }
}
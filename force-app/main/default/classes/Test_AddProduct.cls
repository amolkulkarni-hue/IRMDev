/**
**Author  : Raj Gottipolu
**Date    : 10/31/11
**Company : HCL America
**Comments: Test class for 'AddProductClass'
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 08/13/2013; Srinivasa Rao/Randstad; Opty Wizard Enhancement - GSA Modification (Case # 01622446); Initial release
**/
@isTest
private class Test_AddProduct {

    static testMethod void myUnitTest() {
    SBQQ.TriggerControl.disable();
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;  

        ID rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
        Account a = new Account(name='Account4TestMethod'+system.now(), BillingCountry = 'United States', BillingState = 'MA');
        insert a;
        Pricebook2 p = [select Id, Name from Pricebook2 where Name=:'North America'];
        Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
  
        String s = p.Id;
        String subs=s.substring(0,15);
        List<Product2> products = new List<Product2>();
  
        Product2 product = new Product2(Secondary_Product_Allowed__c=true, 
                                        Name='test', 
                                        CurrencyIsoCode='USD', 
                                        IsActive=true,
                                        RecordTypeId = '01280000000UIUpAAO');
        products.add(product);
                
        Product2 product1 = new Product2(Secondary_Product_Allowed__c=true, 
                                        Name='test1',
                                        CurrencyIsoCode='USD',
                                        IM_Product_Line__c='test line',
                                        IM_Product_Class__c='test class',
                                       // RevenueInstallmentPeriod ='Monthly', 
                                        IsActive=true);
        products.add(product1);     
        insert products;
        
        List<Product_Bundle__c> prodbundle = new List<Product_Bundle__c>();
        Product_Bundle__c pbc = new  Product_Bundle__c(Name='test bundle 1',
                                                       Bundle_Type__c='Packaged Initiative',
                                                       Product_Group_ID__c=subs,
                                                       Product_ID__c=product.id);
        prodbundle.add(pbc);
  
        Product_Bundle__c pbc1 = new  Product_Bundle__c(Name='test bundle 2',
                                                        Bundle_Type__c='Packaged Initiative',
                                                        Product_Group_ID__c=subs,
                                                        Product_ID__c=product1.id);  
        prodbundle.add(pbc1);  
        insert prodbundle;
  
        List<PricebookEntry> pricebooks = new List<PricebookEntry>(); 
   
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPB.Id, 
                                                          Product2Id = product.Id, 
                                                          UnitPrice = 1, 
                                                          IsActive = true,
                                                          CurrencyIsoCode='USD', 
                                                          UseStandardPrice = false);
        pricebooks.add(standardPrice);
  
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = standardPB.Id, 
                                                           Product2Id = product1.Id, 
                                                           UnitPrice = 1,
                                                           CurrencyIsoCode='USD', 
                                                           IsActive = true, 
                                                           UseStandardPrice = false);
        pricebooks.add(standardPrice1);
  
        PricebookEntry pbe1 = new PricebookEntry(IsActive=true,
                                                 UnitPrice=1,
                                                 UseStandardPrice = false,
                                                 CurrencyIsoCode='USD',
                                                 Product2Id=product1.Id,
                                                 Pricebook2Id=subs);
        pricebooks.add(pbe1);
  
        PricebookEntry pbe2 = new PricebookEntry(IsActive=true,
                                                 UnitPrice=1,
                                                 UseStandardPrice = false,
                                                 CurrencyIsoCode='USD',
                                                 Product2Id=product.Id,
                                                 Pricebook2Id=subs);
        pricebooks.add(pbe2);
        insert pricebooks;
  
        List<Opportunity_Questions__c> qtns = new List<Opportunity_Questions__c>();
        
        Opportunity_Questions__c newqtn1 = new Opportunity_Questions__c(Name='test question 1',
                                                                        Answer_Format__c='text',
                                                                        Question_Order__c='1',
                                                                        Active__c=true,
                                                                        Product__c=product.Id);
        qtns.add(newqtn1);
        
        Opportunity_Questions__c newqtn2 = new Opportunity_Questions__c(Name='test question 2',
                                                                        Answer_Format__c='Checkbox',
                                                                        Question_Order__c='2',
                                                                        Active__c=true,
                                                                        Product__c=product.Id);
        qtns.add(newqtn2);
        
        Opportunity_Questions__c newqtn3 = new Opportunity_Questions__c(Name='test question 2',
                                                                        Answer_Format__c='Picklist',
                                                                        Question_Order__c='2',
                                                                        Answer_Picklist__c='value1,value2,value3',
                                                                        Active__c=true,
                                                                        Product__c=product1.Id);
        qtns.add(newqtn3);
        
        Opportunity_Questions__c newqtn4 = new Opportunity_Questions__c(Name='test question 1',
                                                                        Answer_Format__c='text',
                                                                        Question_Order__c='1',
                                                                        Active__c=true,
                                                                        Product__c=product1.Id);
        qtns.add(newqtn4);        
        insert qtns;
        
        List<Contact> contacts = new List<Contact>();
        Contact c1 = new Contact(LastName='TestContact1',
                                 FirstName = 'Test',
                                 Email='testemail@email.com',
                                 AccountId=a.Id,
                                 MailingCity = 'London', 
                                 //MailingCountry = 'England', 
                                 MailingCountry = 'United States',
                                 MailingPostalCode = 'SE1 2TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contacts.add(c1);
        Contact c2 = new Contact(LastName='TestContact2',
                                  FirstName = 'Test',
                                 Email='testemail@email.com',
                                 AccountId=a.Id,
                                 MailingCity = 'London', 
                                 //MailingCountry = 'England', 
                                 MailingCountry = 'United States',
                                 MailingPostalCode = 'SE1 2TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contacts.add(c2);
        
        insert contacts;
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = a.Id;
        opp1.RecordTypeID=rt;
        opp1.Name = 'Opportunity4TestMethod';
        opp1.IM_Booked_Date__c = Date.today();
        opp1.CurrencyIsoCode='USD';
        opp1.StageName = '1 - Qualification';
        opp1.Type = 'Renewal';
        opp1.Lead_Source_Most_Recent__c = 'Email';
        opp1.CloseDate = System.today();
        opp1.RecordTypeId = '01280000000UDKJAA4';
        //Srinu: Added on 03-21-2013
       //Commented as part of #16915
       // opp1.Bundle_Description__c = 'otherinformation';
        opp1.GSA_Eligibility__c  = 'GSA Eligible';
        opp1.IMGS_Approval_Status__c  = 'Under Review';
        opp1.Pricebook2Id =standardPB.Id;
        
        test.startTest();
        
        insert opp1;
        //insert Quote
        Quote quo = new Quote();
        quo = TestingUtils.createQuotes(opp1.id, 1 , true)[0];
        
        //Srinu: Added on 03-21-2013
               
        //Inserting Opportunity Line Item
        //OpportunityLineItem oppProd = new OpportunityLineItem(OpportunityId = opp1.Id, unitPrice = 1, Quantity = 12, Product_Line__c=products[0].IM_Product_Line__c, Product_Class__c=products[0].IM_Product_Class__c, PricebookEntryId = pricebooks[2].Id);
        //insert oppProd;
        
        
        System.currentPageReference().getParameters().put('addTo',opp1.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp1);
        AddProductClass mc = new AddProductClass(sc);
        
        mc.productgroupnameId = p.Id;
        mc.autorun();
        mc.getOpportunity();
        mc.getPrimarycontacts();        
        mc.contactList[0].selected=true;
        mc.contactList[0].getOppcont();
        mc.contactList[0].oppcont.Role='Evaluator';
        mc.contactList[1].selected=false;
        mc.contactList[1].getOppcont();
        mc.contactList[1].oppcont.Role='Evaluator';
        mc.getSelected();
        mc.savePrimarycontact();
        mc.oldconsavebutton();
        mc.GetPrimarycontactlist();
        mc.cancelpg();
        mc.primarycontactnotfound();
        mc.getContact().Email='raj@gmail.com';
        mc.getContact().Phone='6517951874';
        mc.getContact().MailingCountry='USA';
        mc.getContact().LastName='raj';
        mc.getOcr().Role='Evaluator';
        mc.newcontactsave();
        mc.getBundletypelist();
        mc.setSelectedbundletype('Packaged Initiative');
        mc.bundleyes();
        mc.getBundleslist();
        mc.setSelectedbundle(pbc.Name);
        mc.nextbundle();
        mc.getBundleproductlistwrap();
        if (mc.bundleproductlistwrap.size()>0)
        mc.bundleproductlistwrap[0].selected=true;
        mc.getselectedb();
        mc.bundleproselected();
        mc.secprotrue();
        mc.getSecondaryproducts();
        mc.secondproductList[0].selected=true;
        mc.secondproductList[1].selected=true;
        mc.getSelected2();
        mc.GetSecondaryproductlist();
        mc.secprofalse();
        mc.secproback();
        mc.secprodisplaynext();
        mc.getTestlist();
        mc.getTestlistwrap();
        mc.nextbundlenew();
        
        for(Integer j=0; j<mc.testlistwrap.size(); j++)
        {
            mc.testlistwrap[j].getQuestions();
            mc.testlistwrap[j].getQuestionsexist();
            if(mc.testlistwrap[j].questions.size()>0)
            {
                for(Integer k=0; k<mc.testlistwrap[j].questions.size(); k++)
                {
                    if(mc.testlistwrap[j].questions[k].oqc.Answer_Format__c=='Checkbox')
                    {
                        mc.testlistwrap[j].questions[k].getCheckboxanswers();
                        mc.testlistwrap[j].questions[k].checkboxanswer='yes';
                    }
                    else if(mc.testlistwrap[j].questions[k].oqc.Answer_Format__c=='Text')
                    {
                        mc.testlistwrap[j].questions[k].textanswer='test';
                    }
                    else
                    {
                        mc.testlistwrap[j].questions[k].getSplitstring();
                        mc.testlistwrap[j].questions[k].getPicklistanswers();
                        mc.testlistwrap[j].questions[k].picklistanswer='value1';
                    }
                }
            }
        }
        mc.addproducts();
        mc.getCompletelistwrap();
        mc.getCompleteproductlist();
        for(Integer i=0; i<mc.testlistwrap.size();i++)
        {
                mc.testlistwrap[i].getComplist();
                mc.testlistwrap[i].complist[0].Price=50;
                mc.testlistwrap[i].complist[0].Quantity=20;
                mc.testlistwrap[i].complist[0].setPrice(50.0);
                mc.testlistwrap[i].complist[0].getStrprice();
                mc.testlistwrap[i].complist[0].setRevenue(1000);
                //mc.testlistwrap[i].complist[0].getRevenue();
        }
        mc.displaydetails();
        mc.newbacktopricequantity();
        for(Integer i=0; i<mc.testlistwrap.size();i++)
        {
                mc.testlistwrap[i].getComplist();
                mc.testlistwrap[i].complist[0].setPrice(50);
                mc.testlistwrap[i].complist[0].getPrice();
                mc.testlistwrap[i].complist[0].Quantity=20;
        }
        mc.productsavebutton();
        mc.newbacktoquestions();
        //Srinu: Added on 03-20-2013
        mc.newbacktogsaquestions();
        mc.gsaquestionsavebutton();
        
        mc.getTestlist();
        mc.getTestlistwrap();
        for(Integer j=0; j<mc.testlistwrap.size(); j++)
        {
            mc.testlistwrap[j].getQuestions();
            mc.testlistwrap[j].getQuestionsexist();
            if(mc.testlistwrap[j].questions.size()>0)
            {
                for(Integer k=0; k<mc.testlistwrap[j].questions.size(); k++)
                {
                    if(mc.testlistwrap[j].questions[k].oqc.Answer_Format__c=='Checkbox')
                    {
                        mc.testlistwrap[j].questions[k].getCheckboxanswers();
                        mc.testlistwrap[j].questions[k].checkboxanswer='yes';
                    }
                    else if(mc.testlistwrap[j].questions[k].oqc.Answer_Format__c=='Text')
                    {
                        mc.testlistwrap[j].questions[k].textanswer='test';
                    }
                    else
                    {
                        mc.testlistwrap[j].questions[k].getPicklistanswers();
                        mc.testlistwrap[j].questions[k].getSplitstring();
                        mc.testlistwrap[j].questions[k].picklistanswer='value2';
                    }
                }
            }
        }
        mc.questionsavebutton();
        mc.contactbackbutton();
        mc.getContact().Email='raj@gmail.com';
        mc.getContact().Phone='6517951874';
        mc.getContact().MailingCountry='USA';
        mc.getContact().LastName='raj';
        mc.getOcr().Role='Evaluator';
        mc.consavebutton();
        mc.savedetails();
        mc.setSelectedbundletype('All Other Product Lines');
        mc.bundleyes();
        mc.getProductgrouplist();
        mc.setselectedpg('test class');
        mc.nextpg();
        mc.getPricebooklist();
        mc.setSelectedpb('test line');
        mc.nextpb();
        mc.getPricebookentries();
        if (mc.pricebookList.size()>0)
        mc.pricebookList[0].selected=true;
        mc.getSelected1();
        mc.getPricebookentrieselected();
        mc.nextsecpro();
        mc.addprodsyes();
        mc.setSelectedpb('test line');
       // mc.addprodlinenext();
        mc.getNewpricebookentries();
        if (mc.newpricebookList.size()>0)
        mc.newpricebookList[0].selected=true;
        mc.getSelected3();
        mc.addnextsecpro();
        mc.getadditionalproductlist();
        mc.bundle=pbc.Name;
        //mc.nextbundlenew();
        mc.selectedbundle=pbc.Name;
        mc.setOtherinformation('test');
       // mc.otherinformationnext();
        mc.nextproclass();
        mc.backtoquestions();
        //Srinu: Added on 03-20-2013
        mc.backtopricequantity();
        //mc.secprofalse();
        //mc.savedetails();
        mc.newcancelpb();
        mc.addprodsno();
        mc.addprodlineback();
        //mc.getOppdetails();
        mc.getOthererror();
        //mc.backtopricequantity();
        mc.getProductclass();
        mc.getOtherinformationdisplay();
        mc.getOverwriterror();
        mc.getPricebookdisplay();
        mc.getPricebookerror();
        mc.getProdexists();
        //mc.getProdselect();
        mc.getProductgroup();
        mc.getQuestionblockrender();
        mc.getQuestiondisplay();
        mc.getQuestionerror();
        mc.getQuestionsavedisplay();
        mc.getQuestionsbackdisplay();
        mc.getQuestionsnextdisplay();
        mc.getRolestring();
        mc.getRolexists();
        mc.getSecondaryproductquestion();
        mc.getSecprodisplay();
        mc.getSecproerror();
        mc.getSecproselectdisplay();
        mc.getSelectedbundle();
        mc.getSelectedbundletype();
        mc.getSelectedpb();
        mc.getSelectedpg();
        mc.getBundle();
        //Srinu: Added on 03-20-2013
        mc.getCatchexception();
        mc.getEmptybundles();
        mc.getEmptyprodlines();
        mc.getEmptyproductlist();
        mc.getAddprimaryprod();
        mc.getAddprodline();
        mc.getAddprods();
        mc.getAddproductsdisplay();
        mc.getBacktoquestionsdisplay();
        mc.getBundlelistdisplay();
        mc.getBundlemsg();
        mc.getBundleproductlistdisplay(); 
        mc.getBundlequestiondisplay();
        mc.getConbackdisplay();
        //Srinu: Added on 03-20-2013
        mc.getErrorblock();
        mc.getConchangedisplay();
        mc.getConsavedisplay();
        mc.getContactbackbuttondisplay();
        mc.getContactdisplay();
        mc.getContacterror();
        mc.getDisplaydetailsdisplay();
        mc.getFinaldetailsdiplay();
        mc.getGranularleveldisplay();
        mc.getHighleveldisplay();
        mc.getLocation();
        mc.getMultipleclassdisplay();
        mc.getMultipleclassexists();
        //Srinu: Added on 03-20-2013
        mc.getDontAllowToAddProducts();
        mc.getisExecuteGSAtestWrap();
        mc.getisThisNARACFROpportunity();
        mc.getisOpportunityMeetsGSA();
        mc.getGSAQuestiondisplay();
        mc.getgsaQuestionblockrender();
        mc.getgsaQuestionsavedisplay();
        mc.getgsafinaldetailsdiplay(); 
        mc.getNewbundlelistdisplay();
        mc.getNewcon();
        mc.getNewcontactdisplay();
        mc.getOldcon();
        mc.getOtherinformation();
        mc.getProductsavebuttondisplay();
        mc.setSelectedpb('test');
        mc.setSelectedpg('test');
        mc.oldcontactbackbutton();
        mc.backtosecpro();
        mc.secprodisplayback();
        mc.addcancelsecpro();
        mc.secproback();
        mc.addprodsback();
        mc.cancelsecpro();
        mc.bundlepronotselected();
        mc.cancelpb();
        mc.bundleno();
        // GOPI
        mc.getPrimarycontacts();   
        mc.bundleback();     
        mc.contactList[0].selected=true;
        mc.contactList[0].getOppcont();
        mc.contactList[0].oppcont.Role='Evaluator';
        mc.contactList[1].selected=false;
        mc.contactList[1].getOppcont();
        mc.contactList[1].oppcont.Role='Evaluator';
        mc.getSelected();
        mc.savePrimarycontact();
        mc.oldconsavebutton();
        mc.GetPrimarycontactlist();
        string Opp= mc.canOpp;
        mc.getSecproerror();
        mc.getQuestionerror();
        mc.getOverwriterror();
        mc.getMultipleclassexists();
        //GOpi
        mc.cancelproclass();
        // GOPI
        mc.getPrimarycontacts(); 
        mc.bundleback();       
        mc.contactList[0].selected=true;
        mc.contactList[0].getOppcont();
        mc.contactList[0].oppcont.Role='Evaluator';
        mc.contactList[1].selected=false;
        mc.contactList[1].getOppcont();
        mc.contactList[1].oppcont.Role='Evaluator';
        mc.getSelected();
        mc.savePrimarycontact();
        mc.oldconsavebutton();
        mc.GetPrimarycontactlist();
        mc.primarycontactnotfound();
        //GOpi
        // GOPI
        mc.getPrimarycontacts(); 
        mc.bundleback();       
        mc.contactList[0].selected=true;
        mc.contactList[0].getOppcont();
        mc.contactList[0].oppcont.Role='Evaluator';
        mc.contactList[1].selected=false;
        mc.contactList[1].getOppcont();
        mc.contactList[1].oppcont.Role='Evaluator';
        mc.getSelected();
        mc.savePrimarycontact();
        mc.oldconsavebutton();
        mc.GetPrimarycontactlist();
        //GOpi
        mc.prodexists = true;
        mc.cancelpb();
        mc.fromnewlist = true;
        mc.addprodsback();
        mc.newcontactback();
        mc.otherinformationback();
        System.debug('-----------queries used: ' + Limits.getQueries());        
        mc.cancelbundle();           
        //Srinu: Added on 03-20-2013
       // mc.getGSATestList();
        //Srinu: Added on 03-21-2013
        for(Integer j=0; j<mc.testlistwrap.size(); j++){
            for(Integer k=0; k<mc.testlistwrap[j].questions.size(); k++){
                System.debug('--415---inside questions for loop----');
                mc.testlistwrap[j].questions[k].getSplitstring();
                mc.testlistwrap[j].questions[k].getCheckboxanswers();
                mc.testlistwrap[j].questions[k].getPicklistanswers();
            }
        }
        for(Integer j=0; j<mc.GSATestList.size(); j++){
            System.debug('--419---inside GSATestList for loop----');
             mc.GSATestList[j].getPicklistanswers();
        }
        /*Variable declaration for 'sendEmailNotification method'*/ 
        String strEmailBody = 'Error in the wizard. Please start over\n\n';
        String strEmailSub = 'Failed to retrieve Opportunity Id';
        mc.sendEmailNotification(strEmailBody, strEmailSub); 
        mc.savePrimarycontact();
        mc.savedetails();  
        mc.setSelectedbundletype(null);
        mc.otherinformationback();
       
        system.debug('++++ SyncedQuoteid:' + quo.Id );
        /*opp1.GSA_Eligibility__c  = null;
        opp1.IMGS_Approval_Status__c  = null;
        opp1.Bundle__c ='AP';
        test.startTest();
        update opp1;
        test.stopTest();*/
        
        
       
        mc.opportunity = opp1;
        //mc.getcatchexception();
        mc.autorun();
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        //gopi
        Opportunity opp2 = new Opportunity();
        opp2.AccountId = a.Id;
        opp2.RecordTypeID=rt;
        opp2.Name = 'Opportunity4TestMethod';
        opp2.IM_Booked_Date__c = Date.today();
        opp2.CurrencyIsoCode='USD';
        opp2.StageName = '1 - Qualification';
        opp2.Type = 'Renewal';
        opp2.Lead_Source_Most_Recent__c = 'Email';
        //Srinu: Added on 03-21-2013
        //opp2.Bundle_Description__c = 'otherinformation';
        //opp2.GSA_Eligibility__c  = 'GSA Eligible';
        opp2.IMGS_Approval_Status__c  = 'Under Review';
        opp2.SyncedQuoteid = quo.Id;
       // #16915 opp2.Bundle__c ='AP';
        opp2.closedate = system.today();
        OpportunityHelper.country_query +=',';
        OpportunityHelper.opty_query_fields+=',';        
        OpportunityHelper.opty_id_list +=',';      
        OpportunityHelper.account_id_list +=',';  
        OpportunityHelper.postal_code_query_fields +=',';
        OpportunityHelper.account_query_fields +=',';
        SBQQ.TriggerControl.disable();
        
        test.stopTest();
    //    OpportunityTriggerHandler.isTriggerDisabled = true;
        insert opp2;
        
        
        System.currentPageReference().getParameters().put('addTo',opp2.Id);
        ApexPages.StandardController sc1 = new ApexPages.StandardController(opp2);
        AddProductClass mc1 = new AddProductClass(sc1);
        //gopi
        mc1.autorun();
        mc1.isExecuteGSAtestWrap = true;
        mc1.getGSATestList();
        AddProductclass.pricebookwrapper pbw =new AddProductclass.pricebookwrapper(standardPrice);
        AddProductclass.questionwrapper pbw1 =new AddProductclass.questionwrapper(newqtn1);
        pbw1.textanswer ='test';
        pbw1.picklistvalues ='test';
        pbw1.finalanswer ='test';
        pbw1.checkboxanswer ='YES';
        pbw1.picklistanswer = 'test';
        pbw1.getSplitstring();
        pbw1.getCheckboxanswers();
        pbw1.getPicklistanswers();
          try{
        
        System.currentPageReference().getParameters().put('addTo',quo.Id);
        ApexPages.StandardController sc2 = new ApexPages.StandardController(opp2);
        AddProductclass pbw2 =new AddProductclass(sc2);
        }catch(exception e){}
        
    }
    static testMethod void myUnitTestTwo() {
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;  

        List<Contact> contactsList = new List<Contact>();
        Account a = new Account(name='Account4TestMethod'+system.now(), BillingCountry = 'United States', BillingState = 'MA');
        insert a;
        Contact c1 = new Contact(LastName='TestContact1',
                                  FirstName = 'Test',
                                 Email='testemail@email.com',
                                 AccountId=a.Id,
                                 MailingCity = 'London', 
                                 //MailingCountry = 'England', 
                                 MailingCountry = 'United States',
                                 MailingPostalCode = 'SE1 2TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contactsList.add(c1);
        Contact c2 = new Contact(LastName='TestContact2',
                                  FirstName = 'Test',
                                 Email='testemail@email.com',
                                 AccountId=a.Id,
                                 MailingCity = 'London', 
                                 //MailingCountry = 'England', 
                                 MailingCountry = 'United States',
                                 MailingPostalCode = 'SE1 2TT', 
                                 MailingState = 'London', 
                                 MailingStreet = '745 Atlantic Ave');
        contactsList.add(c2);
        insert contactsList;
        ID rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
         ID productRT = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = a.Id;
        opp1.RecordTypeID=rt;
        opp1.Name = 'Opportunity4TestMethod';
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        opp1.IM_Booked_Date__c = Date.today();
        opp1.CurrencyIsoCode='USD';
        opp1.StageName = '1 - Qualification';
        opp1.CloseDate = System.today();
        opp1.Type = 'Renewal';
        opp1.Lead_Source_Most_Recent__c = 'Email';
        //Srinu: Added on 03-21-2013
        //Commented as part of #16915
       // opp1.Bundle_Description__c = 'otherinformation';
        //opp1.GSA_Eligibility__c  = 'GSA Eligible';
        //opp1.IMGS_Approval_Status__c  = 'Under Review';
        opp1.GSA_Eligibility__c  = null;
        opp1.IMGS_Approval_Status__c  = null;
        //opp1.Bundle__c ='AP';
        insert opp1;
        
        Opportunity opp2 = new Opportunity();
        opp2.AccountId = a.Id;
        opp2.RecordTypeID=rt;
        opp2.Name = 'Opportunity5TestMethod';
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        opp2.IM_Booked_Date__c = Date.today();
        opp2.CurrencyIsoCode='USD';
        opp2.StageName = '1 - Qualification';
        opp2.CloseDate = System.today();
        opp2.Type = 'Renewal';
        opp2.Lead_Source_Most_Recent__c = 'Email';
        //Srinu: Added on 03-21-2013
        //Commented as part of #16915
       // opp1.Bundle_Description__c = 'otherinformation';
        //opp1.GSA_Eligibility__c  = 'GSA Eligible';
        //opp1.IMGS_Approval_Status__c  = 'Under Review';
        opp2.GSA_Eligibility__c  = null;
        opp2.IMGS_Approval_Status__c  = null;
        //opp1.Bundle__c ='AP';
        insert opp2;
       
        Pricebook2 p = [select Id, Name from Pricebook2 where Name=:'North America'];
        Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
  
        String s = p.Id;
        String subs=s.substring(0,15);
        List<Product2> products = new List<Product2>();
  
        Product2 product = new Product2(Secondary_Product_Allowed__c=true, 
                                        Name='test', 
                                        CurrencyIsoCode='USD', 
                                        IsActive=true, RecordTypeId =productRT);
        products.add(product);
                
        Product2 product1 = new Product2(Secondary_Product_Allowed__c=true, 
                                        Name='test1',
                                        CurrencyIsoCode='USD',
                                        IM_Product_Line__c='test line',
                                        IM_Product_Class__c='test class',
                                       // RevenueInstallmentPeriod ='Monthly', 
                                        IsActive=true, RecordTypeId =productRT);
        products.add(product1);     
        insert products;
        List<PricebookEntry> pricebooks = new List<PricebookEntry>(); 
   
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPB.Id, 
                                                          Product2Id = product.Id, 
                                                          UnitPrice = 1, 
                                                          IsActive = true,
                                                          CurrencyIsoCode='USD', 
                                                          UseStandardPrice = false);
        pricebooks.add(standardPrice);
  
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = standardPB.Id, 
                                                           Product2Id = product1.Id, 
                                                           UnitPrice = 1,
                                                           CurrencyIsoCode='USD', 
                                                           IsActive = true, 
                                                           UseStandardPrice = false);
        pricebooks.add(standardPrice1);
  
        PricebookEntry pbe1 = new PricebookEntry(IsActive=true,
                                                 UnitPrice=1,
                                                 UseStandardPrice = false,
                                                 CurrencyIsoCode='USD',
                                                 Product2Id=product1.Id,
                                                 Pricebook2Id=subs);
        pricebooks.add(pbe1);
  
        PricebookEntry pbe2 = new PricebookEntry(IsActive=true,
                                                 UnitPrice=1,
                                                 UseStandardPrice = false,
                                                 CurrencyIsoCode='USD',
                                                 Product2Id=product.Id,
                                                 Pricebook2Id=subs);
        pricebooks.add(pbe2);
        insert pricebooks;
        
        OpportunityLineItem oppProd1 = new OpportunityLineItem(OpportunityId = opp2.Id, unitPrice = 1, Quantity = 12, Product_Line__c=products[0].IM_Product_Line__c, Product_Class__c=products[0].IM_Product_Class__c, PricebookEntryId = pbe2.Id);
        insert oppProd1;
        
         OpportunityContactRole OpportunityContactRoles2 = new OpportunityContactRole();
		 OpportunityContactRoles2 =  QTB_TestDataFactory.createCPQOppContactRoles(1,opp2.id, contactsList[0].id , 'Evaluator')[0];
        
        Test.startTest();

        System.currentPageReference().getParameters().put('addTo',opp1.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp1);
        AddProductClass aPclass = new AddProductClass(sc);
        aPclass.productgroupnameId = p.Id;
        aPclass.getProductgroup();
        aPclass.getProductgrouplist();
        aPclass.autorun();
        aPclass.getSecproerror();
        aPclass.getQuestionerror();
        aPclass.getOverwriterror();
        aPclass.getMultipleclassexists(); 
        
        System.currentPageReference().getParameters().put('addTo',opp2.Id);
        ApexPages.StandardController sc2 = new ApexPages.StandardController(opp2);
        AddProductClass aPclass2 = new AddProductClass(sc2);
        aPclass2.productgroupnameId = p.Id;
        aPclass2.getProductgroup();
        aPclass2.getProductgrouplist();
        aPclass2.autorun();
        aPclass2.getSecproerror();
        aPclass2.getQuestionerror();
        aPclass2.getOverwriterror();
        aPclass2.getMultipleclassexists(); 
        
        Product2 product5 = new Product2(Secondary_Product_Allowed__c=true, 
                                        Name='CFR Boxes', 
                                        CurrencyIsoCode='USD', 
                                        IsActive=true);
        insert product5;
        Opportunity_Questions__c newqtn5 = new Opportunity_Questions__c(Name='test question 1',
                                                                        Answer_Format__c='Picklist',
                                                                        Question_Order__c='1',
                                                                        Active__c=true,
                                                                        Product__c=product5.Id,
                                                                       Answer_Picklist__c ='--None--,Yes,No');
        insert newqtn5;
        AddProductclass.testlistwrapper tlw = new AddProductclass.testlistwrapper(product5);
        
        AddProductclass.questionwrapper pbw1 =new AddProductclass.questionwrapper(newqtn5);
        Opportunity_Questions__c newqtn6 = new Opportunity_Questions__c(Name='Is this an opportunity for a US federal government customer?',
                                                                        Answer_Format__c='Picklist',
                                                                        Question_Order__c='1',
                                                                        Active__c=true,
                                                                        Product__c=product5.Id,
                                                                       Answer_Picklist__c ='--None--,Yes,No');
        insert newqtn6;
        AddProductclass.GSAWrapper gw1 =new AddProductclass.GSAWrapper(newqtn6,true);
        Opportunity_Questions__c newqtn7 = new Opportunity_Questions__c(Name='Is this a NARA/CFR Compliant Opportunity?',
                                                                        Answer_Format__c='Picklist',
                                                                        Question_Order__c='1',
                                                                        Active__c=true,
                                                                        Product__c=product5.Id,
                                                                       Answer_Picklist__c ='--None--,Yes,No');
        AddProductclass.GSAWrapper gw2 =new AddProductclass.GSAWrapper(newqtn7,true);
        gw2.getPicklistanswers();
        gw2.textanswer = 'test';
        boolean isQEditable;
        gw2.isQuestionEditable = null;
        isQEditable = gw2.isQuestionEditable;
        Test.stopTest();

    }
}
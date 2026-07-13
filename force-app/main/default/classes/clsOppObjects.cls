/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   clsOppObjects (Class)
**
** PURPOSE
**   Inserting Contact Role, Opportunity Line items, GSA Answers and Updating Opportunity in future to rediuce SOQL Limit. 
**
** NOTES
**   Expected invocation format:
**     whenever creating an Opportunity through wizard. It will execute of NA Users.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 09/05/2012; Ketan Benegal,Srinivasa Rao/Randstad; Opportunity Wizard 1.05 (Project Related to Wizard 1.05 cases); Initial release
**   v1.1; 05/20/2012; Sandhya Ramesh/IMS; Case #03408939; Modified InsertGSAAnswers method to disallow insert if running user's Sub is Govt
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 01/16/2016; Sandhya Ramesh; Case # 03250416;  Opty Wizard & Add product wizard Enhancement - Rate x Quantity.
**
** CHANGE LOG
**      Case# 05491582, Added by pratap, We want to retain the ability for drivers to submit sales leads, Index[23] contains 
**      driver's information 

************************************************************************/
public class clsOppObjects {
    public clsOppObjects(){
        
    }

    @future
    public static void createContactRole(String sContactId, String sOppId, String sRoleString, String sSendMail, String sLeadName, String sLeadCompany, String sOppaccid){
        System.debug('---8-----sSendMail:'+sSendMail+''+sSendMail);
        String strBody;
        System.debug('Inside createContactRole');
        clsOppObjects obj1 = new clsOppObjects(); 
        clsOppObjects.createContactRoleMethod(sContactId, sOppId, sRoleString, sLeadName, sLeadCompany, sOppaccid); 
        if(sSendMail=='true'){
            Contact contactmail = [Select Name from Contact where Id=:sContactId];
            strBody = 'Converting a lead into the following records has successfully completed:' +'\n\n' +'Account: '+ sLeadCompany +'\n' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + sOppaccid + 
                '\n\n' +
                'Contact: ' + contactmail.Name +
                '\n' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + sContactId+  
                '\n\n'; 
                
                if(sLeadName!=null){
                    strBody = strBody + 
                    'Opportunity: '+ sLeadName +
                    '\n' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + sOppId;
                }
            strBody = strBody + '\n\n\n' + 'Thank You,'; 
            system.debug('before email notification');            
            obj1.sendEmailNotification(strBody, 'New Lead has been assigned to you.');  
        }    
    } 

    public static void createContactRoleMethod(String sContactId, String sOppId, String sRoleString, String sLeadName, String sLeadCompany, String sOppaccid){
        System.debug('----executing createContactRoleMethod method in claOppObjects class----');
        System.debug('---31----sContactId:'+sContactId);
        System.debug('----31---sOppId:'+sOppId);
        System.debug('----33---sRoleString:'+sRoleString);
        System.debug('----34---sLeadName:'+sLeadName);
        System.debug('-----35--sLeadCompany:'+sLeadCompany);
        System.debug('----36---sOppaccid:'+sOppaccid);
        List<OpportunityContactRole> role1 = new List<OpportunityContactRole>(); 
        role1 = [select Id, ContactId, OpportunityId from OpportunityContactRole where ContactId=:sContactId and OpportunityId=:sOppId];  
        if(role1.size() == 0){
          OpportunityContactRole role = new OpportunityContactRole(ContactId=sContactId, IsPrimary=true, Role=sRoleString, OpportunityId=sOppId);              
          insert role;
        }
        else{
          role1[0].Role=sRoleString;
          role1[0].IsPrimary=true;
          update role1;
        }
    }

    public void sendEmailNotification(String strEmailBody, String strEmailSub)
    {
        String username = userinfo.getLastName();
        //String userId = userinfo.getUserId();
        //String username = userinfo.getUserName();
        User mailuser = [Select Email from User where LastName=:username LIMIT 1]; //AND IsActive = true LIMIT 1
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {mailuser.Email}; 
        String[] ccAddresses = new String[] {mailuser.Email}; 
        system.debug(toAddresses+'123123123'+ccAddresses);
        mail.setToAddresses(toAddresses); 
        mail.setCcAddresses(ccAddresses);    
        mail.setSenderDisplayName(Userinfo.getFirstName() + ' '+ userinfo.getLastName());    //This shoudl be user name
        mail.setSubject(strEmailSub);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody(strEmailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    @future
    public static void createListContactRole(String[] sContactId, String sOppId, String[] sRoleString){
          List<OpportunityContactRole> conrolelist = new List<OpportunityContactRole>();
          for(Integer i=0;i<sContactId.size();i++){
            OpportunityContactRole newoppconrole1 = new OpportunityContactRole(ContactId = sContactId[i], OpportunityId=sOppId, Role=sRoleString[i]);            
            conrolelist.add(newoppconrole1);
          }
          insert conrolelist;
    } 

    @future
    public static void createOpportunityItems(String insertedoppid, Integer[] quantitylist, Decimal[] totalpricelist, String[] lstPbeIds, List<String> lstProdQuesAns, Date schOppClosedDate, list<String> lstStrParams )
    {   
        map<String, List<List<String>>> mlstProdQuesAns = new map<String, List<List<String>>> ();
        
        System.debug('----85----lstProdQuesAns:'+lstProdQuesAns);
        for(integer i=0; i< lstProdQuesAns.size(); i++){
            String [] lstTmp = lstProdQuesAns[i].split(';',-2);
            System.debug('---88---lstTmp:'+lstTmp);
            System.debug('&&&&&&&&&&&&&& lstTmp: ' + lstTmp);
            List<List<String>> lstQuesAns = new List<List<String>>();
            List<String> lstAns =  new List<String>();
            
            lstAns.add(lstTmp[1]);
            lstAns.add(lstTmp[2]);
            lstQuesAns.add(lstAns); 
            if(mlstProdQuesAns.containsKey(lstTmp[0])){
                mlstProdQuesAns.get(lstTmp[0]).addAll(lstQuesAns);
            }else{
                mlstProdQuesAns.put(lstTmp[0], new List<List<String>> ());
                mlstProdQuesAns.get(lstTmp[0]).addAll(lstQuesAns);
            }
        }
        System.debug('@@@@@@@@@@@@@@@@ mlstProdQuesAns:'+ mlstProdQuesAns +'\t insertedoppid:' +insertedoppid);
        createOpportunityLineItem( insertedoppid, quantitylist, totalpricelist, lstPbeIds, mlstProdQuesAns, schOppClosedDate );
        System.debug('---96------lstStrParams:'+lstStrParams);
        if(lstStrParams != null){
            if(lstStrParams.size() > 0){
                System.debug('-----98------lstStrParams:'+lstStrParams);
                updateOpportunityMethod(lstStrParams);              
            }
        }
    }     
     
    //Added on 2-11-2013
    @future
    public Static void InsertGSAAnswers(List<Id> QuesIds, List<String> PcklstAns, Id GSAOpportunityId, String govtSegUser ){
        List<Opportunity_Answers__c> GSAAns = new List<Opportunity_Answers__c>();
        for(Integer i=0; i<QuesIds.Size(); i++){
            Opportunity_Answers__c tempAns = new Opportunity_Answers__c();
            tempAns.Name=PcklstAns.get(i);
            tempAns.Opportunity_Question__c=QuesIds.get(i);
            tempAns.Opportunity__c=GSAOpportunityId;        
            GSAAns.add(tempAns);
        }
        System.debug('---131---GSAAns:'+GSAAns);
        if(GSAAns.size()>0 && govtSegUser!='Government')
        {
          System.debug('---134----GSAAns:'+GSAAns);
          insert GSAAns;
        }
    }
    
    @future
    public static void updateOpportunity(List<String> lstStrParams){
        System.debug('-----113----lstStrParams:'+lstStrParams);
        updateOpportunityMethod(lstStrParams);
    }
    
   /* //private static createOpportunityLineItem(String insertedoppid, Integer[] pricelist, Integer[] quantitylist, String[] lstProductLine, String[] lstProductClass, String[] lstPbeIds ){*/
    private static void createOpportunityLineItem(String insertedoppid,  Integer[] quantitylist, Decimal[] Totalpricelist, String[] lstPbeIds, map<String, List<List<String>>> mlstProdQuesAns, Date schOppClosedDate ){
        
        List<OpportunityLineItem> newLine = new List<OpportunityLineItem>();
        List<OpportunityLineItem> newLine1 = new List<OpportunityLineItem>();
        Set<Id> ProductId_RemoveDupli_Ans=new Set<Id>();
        //List<PricebookEntry> lstProducts = [Select p.id, p.Product2.Secondary_Product_Allowed__c, p.Product2.Quantity_Override_value__c, p.Product2.Price_Override_value__c, p.Product2.IM_Unit_of_Measure__c, p.Product2.IM_Business_Line__c, p.Product2.IM_Revenue_Type__c, p.Product2.IM_Product_Class__c, p.Product2.IM_Product_Line__c, p.Product2.CurrencyIsoCode, p.Product2.Family, p.Product2.IsActive, p.Product2.NumberOfRevenueInstallments, p.Product2.RevenueInstallmentPeriod, p.Product2.RevenueScheduleType, p.Product2.Description, p.Product2.ProductCode, p.Product2.Name, p.Product2.Id, p.Product2Id From PricebookEntry p where p.id in :lstPbeIds];    
        // For Rate x Quantity scheduling disable, replace above query with below query 
        List<PricebookEntry> lstProducts = [Select p.id, p.Product2.Secondary_Product_Allowed__c, p.Product2.Quantity_Override_value__c, p.Product2.Price_Override_value__c, p.Product2.IM_Unit_of_Measure__c, p.Product2.IM_Business_Line__c, p.Product2.IM_Product_Class__c, p.Product2.IM_Product_Line__c, p.Product2.CurrencyIsoCode, p.Product2.Family, p.Product2.IsActive,  p.Product2.Description, p.Product2.ProductCode, p.Product2.Name, p.Product2.Id, p.Product2Id From PricebookEntry p where p.id in :lstPbeIds];   
        System.debug('---135----lstProducts:'+lstProducts);
        
        /*
        for(integer i=0; i<lstProducts.size(); i++){
           OpportunityLineItem newlineitem = new OpportunityLineItem(OpportunityId=insertedoppid, UnitPrice = pricelist[i], Quantity = quantitylist[i], Product_Line__c=lstProducts[i].Product2.IM_Product_Line__c, Product_Class__c=lstProducts[i].Product2.IM_Product_Class__c, PricebookEntryId =lstProducts[i].Id);
           newLine1.add(newlineitem);
        }
        */
        map<Id, PricebookEntry> mProducts = new map<Id, PricebookEntry>();
        mProducts.putAll(lstProducts);
        System.debug('----139---mProducts:'+mProducts +'\t lstPbeIds.size:'+lstPbeIds.size());
        for(integer i=0; i<lstPbeIds.size(); i++){
            
           OpportunityLineItem newlineitem = new OpportunityLineItem(OpportunityId=insertedoppid,  Quantity = quantitylist[i], TotalPrice = totalpricelist[i], Product_Line__c=mProducts.get(lstPbeIds[i]).Product2.IM_Product_Line__c, Product_Class__c=mProducts.get(lstPbeIds[i]).Product2.IM_Product_Class__c, PricebookEntryId =mProducts.get(lstPbeIds[i]).Id);
           newLine1.add(newlineitem);
           System.debug('----140----newLine1:'+newLine1);
        }
        
        System.debug('------143------Map of Pricebook/Product: '+ mProducts);
      
        insert newLine1;
        
        List<Opportunity_Answers__c> oppanswers = new List<Opportunity_Answers__c>();
        /*** For Rate x Quantity scheduling disable, delete lines below ***/
        /*** For Rate x Quantity scheduling disable, delete above code ***/ 
            System.debug('---274--opty Answers check---oppanswers.size():'+oppanswers.size());
            if(oppanswers.size()>0)
            {
              insert oppanswers;
            }
            List<OpportunityLineItem> newLine2 = new List<OpportunityLineItem>();
            for(integer c=0; c<newLine1.size();c++)
            {
                OpportunityLineItem newlineitem = new OpportunityLineItem(
                Id=newLine1[c].Id); //For Rate x Quantity scheduling disable, delete Update_New_Revenue_Forecast__c parameter
                newLine2.add(newlineitem);
            }
            update newLine2;
            System.debug('----287---checking for boolean value------newLine2:'+newLine2);
            System.debug('queries used 2: ' + Limits.getQueries());
        
    }
    //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
    private static void updateOpportunityMethod(List<String> lstStrParams){
        Decimal dProbability, dUpSellQt;
        Date dtBookedDate, dtCloseDate ;
        Boolean bVal;
        System.debug('-----287-------lstStrParams:'+lstStrParams);
        try {
                if(lstStrParams[3] != null)
                  dProbability = Decimal.valueOf(lstStrParams[3]);

                if(lstStrParams[4]!= null)
                  dtBookedDate =Date.valueOf(lstStrParams[4]);

                if(lstStrParams[5]!= null)
                  dtCloseDate = Date.valueOf(lstStrParams[5]);
                  
                if(lstStrParams[10] != null)
                  dUpSellQt = Decimal.valueOf(lstStrParams[10]);
                  
                if(lstStrParams[14] != null)
                  bVal = Boolean.valueOf(lstStrParams[14]);

                System.debug('------304------inside if----');
                                system.debug(lstStrParams[12]+'@#$');
                Opportunity updateopp = new Opportunity(
                Id=lstStrParams[0], 
                OwnerId=lstStrParams[1],
                StageName=lstStrParams[2],
                Probability=dProbability, 
                CloseDate=dtBookedDate, 
                IM_Booked_Date__c=dtCloseDate,
                IM_Competitor__c=lstStrParams[6],
                Type=lstStrParams[7],
                IM_Category__c=lstStrParams[8],
                IM_Sales_Event__c=lstStrParams[9],
                Description=lstStrParams[10],
                IM_Up_Sell_Quantity__c=dUpSellQt,

                Upsell_Customer_ID__c=lstStrParams[12],
                IM_Up_Sell_Detail__c=lstStrParams[13],
                IM_Unit_of_Measure__c=lstStrParams[14]);       
                //Inside_Sales_Owner__c =  lstStrParams[15]
                //Account_Plan__c = lstStrParams[19],Primary_Product_Line__c=lstStrParams[21]
                 
               /*#16915 if(bVal==true)
                    updateopp.Bundle__c=lstStrParams[16];
                if(lstStrParams[17]!=null)
                    updateopp.Bundle_Description__c=lstStrParams[17]; */ 
                System.debug('---372-----lstStrParams[17]:'+lstStrParams[18]);
                if(lstStrParams[17]!=null)
                    updateopp.GSA_Eligibility__c=lstStrParams[17]; 
                if(lstStrParams[18]!= null)
                    updateopp.IME_Vended_Unvended__c = lstStrParams[18];
                /*#16915 if(lstStrParams[20]!=null)
                    updateopp.Vended__c = Decimal.valueOf(lstStrParams[20]);
                if(lstStrParams[21]!=null)
                    updateopp.Unvended__c= Decimal.valueOf(lstStrParams[21]); */
             //Case# 05491582, Added by pratap, We want to retain the ability for drivers to submit sales leads, 
             //so we must create a new mechanism for them to record the lead information and transmit it 
             //to IRM sales systems 
                
            if(!string.isBlank(lstStrParams[20] ))
                  updateopp.Driver_Employee_Id__c = lstStrParams[20];
             if(lstStrParams[22]!=null)
                    updateopp.InSight_Opportunities__c=lstStrParams[22]; 
            //End of Case# 05491582
                System.debug('------376--------updateopp:'+updateopp);
                //if(updateopp != Null)
                
                //madhu added on 4/17/13 to allow after update event 2nd time.
                Validator_OpportunityObjectTrigger.blnAlreadyDoneForAfterUpdate=false;
                    update updateopp;                
                System.debug('---in clsOppObject class--331-----updateopp:'+updateopp);
        }catch(System.DMLException e) {             
            System.debug('------381------e.getMessage():'+e.getMessage());            
        }
                
    }    
}
/*
Auhtor       : Nagesh Ganji
Created Date : Aug 31, 2010
Description  : Controller class for VisualForce page 'LeadCustomtMerge'.

Auhtor       : Ketan Benegal
Created Date : 09/25/2012
Description  : Modifications as part of Opportunity Optimizations.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 08/08/2013; Srinivasa Rao/Randstad; Opty Wizard Enhancement - GSA Modification (Case # 01622446); Initial release
*/
public class LeadCustomMergeController {
    private  Id  LeadId, ContactId, AccountId, ownerid;
    public Lead leadRec{get; set;}
    //public Contact conRec{get; set;}
    public Contact conRec;
    public Account accRec{get; set;}
    public Opportunity oppRec{get; set;}
    public Task task{get; set;}     
    public Boolean conDupeFlag{get; set;} //Flag is set to TRUE if any Contacts found matching to Lead record else set to FALSE.
    public Boolean accDupeFlag{get; set;} //Flag is set to TRUE if any Accounts found matching to Lead record else set to FALSE.
    public Boolean doNotCreateOpp{get; set;} //User input for Opportunity creation
    public Boolean sendNotification{get; set;} //User input for Notification email
    public String convertedStatus{get; set;} 
    public Boolean isTest;
    public Boolean taskdetails=true;
    public integer i=0;
    //Ketan Benegal - Code Start
    public String sAccountName{get;set;}
    public String sContactAccountName{get;set;}
    //Srinu:Added on 3-1-2013
    public Boolean sAccountSegmntAndSubSegmnt {get; set;}
    public Boolean sContactEmailDomain=false; //{get; set;}
    //Srinu:Added on 03-04-2013
    public String LAccountName;
    
    public Boolean getTaskdetails(){return taskdetails;}
    
    //Srinu:Added on 3-1-2013
    public static boolean isThisGovtOpportunity = false;
    public String aSegment {get;set;}
    
    public LeadCustomMergeController (ApexPages.StandardController stdController) {       
        LeadId    = ApexPages.currentPage().getParameters().get('lId');
        ContactId = ApexPages.currentPage().getParameters().get('cId');
        AccountId = ApexPages.currentPage().getParameters().get('aId');
        doNotCreateOpp = false;
        sendNotification = false;
        leadRec = new Lead();
        conRec = new Contact();
        accRec = new Account();
        oppRec = new Opportunity();
        task = new Task();
        convertedStatus = 'Converted';
        isTest = false;
        //Srinu:Added on 3-1-2013
        List<GSA_Contact_Email_List__c> GSAsettings = GSA_Contact_Email_List__c.getall().values();
        System.debug('---55------LeadId:'+LeadId);
        if(LeadId != NULL)
        {
            leadRec = [SELECT l.City, l.Company, l.Country, l.Description, l.DoNotCall, l.OwnerId,l.Related_Contact__c,
                        l.Email, l.FirstName, l.HasOptedOutOfEmail, l.Id, l.IM_Functional_Area__c, 
                        l.IM_Industry__c, l.IM_Job_Level__c, l.LastName, l.MobilePhone, l.Name, l.Phone, 
                        l.PostalCode, l.State, l.Street, l.IsConverted FROM Lead l WHERE l.Id = :LeadId];
            ownerid=leadRec.OwnerId;
            System.debug('---63------ownerid:'+ownerid);
            LAccountName=leadRec.Company;
            System.debug('---67------LAccountName:'+LAccountName);
        }                    
        /*Ketan Benegal - assigning value to sContactAccountName*/  
        System.debug('---56-----ContactId :'+ContactId );  
        if(ContactId != NULL){ 
            conRec  = [SELECT c.AccountId, c.Account.Name,c.Account.Account_Segment__c, c.Account.Account_Sub_Segment__c, c.DoNotCall, c.Email, c.FirstName, c.HasOptedOutOfEmail, c.Id, 
                        c.IM_Job_Level__c, c.LastName, c.MailingState, c.MailingStreet, c.MobilePhone, 
                        c.MailingCity, c.MailingCountry, c.MailingPostalCode, c.Name, c.Phone
                        FROM Contact c WHERE c.Id = :ContactId];
            System.debug('---62----conRec.AccountId:'+conRec.AccountId);
            sContactAccountName = conRec.Account.Name;
            //Srinu:Added on 3-1-2013
            for(GSA_Contact_Email_List__c GSAEmailList: GSAsettings){
                System.debug('---74----GSAEmailList.Domain_Extension__c:'+GSAEmailList.Domain_Extension__c +'\t conRec.Email.substringAfterLast:'+conRec.Email.substringAfterLast('@'));
                if(conRec.Email!=null && GSAEmailList.Domain_Extension__c==conRec.Email.substringAfterLast('@')){
                    sContactEmailDomain = true;    
                    System.debug('---77-----sContactEmailDomain:'+sContactEmailDomain);                
                }/*else{
                    sContactEmailDomain = false;
                    System.debug('--80-------sContactEmailDomain:'+sContactEmailDomain);
                }*/ 
                //Added on 19-04-2013
                if(conRec.Account.Account_Segment__c =='Vertical' && conRec.Account.Account_Sub_Segment__c =='Government'){
                    sAccountSegmntAndSubSegmnt=true;
                    System.debug('---91---here Making True to First Question--------sAccountSegmntAndSubSegmnt:'+sAccountSegmntAndSubSegmnt);                
                }else{
                    sAccountSegmntAndSubSegmnt=false;
                    System.debug('---94---here Making false to First Question--------sAccountSegmntAndSubSegmnt:'+sAccountSegmntAndSubSegmnt);
                }             
            }
        }
                         
        /*Ketan Benegal - assigning value to sAccountName*/    
        System.debug('---67-----AccountId :'+AccountId );
        if(AccountId != NULL){ 
            accRec  = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, IM_IMGA_Indexed__c, 
                        BillingCountry, BillingPostalCode, IM_Hierarchy_Level__c,Account_Segment__c,Account_Sub_Segment__c
                        FROM Account WHERE Id = :AccountId];
            sAccountName = accRec.Name;
            //Srinu:Added on 3-1-2013
            if(accRec.Account_Segment__c =='Vertical' && accRec.Account_Sub_Segment__c =='Government'){
                system.debug('+++++++++++inside if account+++++++:'+accRec);
                sAccountSegmntAndSubSegmnt=true;
                System.debug('------here Making True to First Question--------sAccountSegmntAndSubSegmnt:'+sAccountSegmntAndSubSegmnt);                
            }else{
                sAccountSegmntAndSubSegmnt=false;
                System.debug('------here Making false to First Question--------sAccountSegmntAndSubSegmnt:'+sAccountSegmntAndSubSegmnt);
            }
        }
                             
        if( leadRec.Id != null && conRec.Id != null) {
            conDupeFlag = true;
            accDupeFlag = false;
        }
        else if(leadRec.Id != null && accRec.Id != null) {
            conDupeFlag = false;
            accDupeFlag = true;
        }
    }
    public Pagereference back()
    {
         PageReference returnPage;
         System.debug('--84----leadRec.Related_Contact__c:'+leadRec.Related_Contact__c);  
         if(leadRec.Related_Contact__c != null)
         {
            returnPage =new PageReference('/'+leadRec.Id);
            System.debug('---125---returnPage:'+returnPage);
         }  
         else
         {  
            returnPage =new PageReference('/apex/LeadCustomConversion?id='+leadRec.Id);
            System.debug('---130---returnPage:'+returnPage);
         } 
         return returnPage; 
    }
    
    public Pagereference autorun()
    {       
            List<Opportunity_Product_Wizard_Settings__c> wizardsettings = Opportunity_Product_Wizard_Settings__c.getall().values();
            Profile prof = [Select Name from Profile where id =: UserInfo.getProfileId()];
            String profilename = prof.Name;
            system.debug('+++++++++++profile name+++++++'+profilename);
            
            for(Opportunity_Product_Wizard_Settings__c ops : wizardsettings){
                
                if(profilename == ops.Profile_Name__c) {                  
                   taskdetails=false;
                }
            }
            return null;
            
    }
    
    public Contact getConRec() {
        return conRec; 
    }
  
    public void setConRec(Contact c) {
        conRec = c; 
    }
    /*
    public List<SelectOption> getConvertStatusList() {    
        List<SelectOption> options = new List<SelectOption>();
        List<LeadStatus> lLs = [Select MasterLabel FROM LeadStatus WHERE IsConverted = true ORDER BY SortOrder ASC];       
        for( Integer i=0; i < lLs.size(); i++)
            options.add(new SelectOption(lLs[i].MasterLabel, lLs[i].MasterLabel));
        System.debug('---156-----options:'+options);
        return options;
    }
    
    //Srinu: Added on 03-04-2013
    //Kevin said, no need to display Lead Status. So commented out.
    private LeadStatus leadStatus;
    public LeadStatus getLeadStatus(){
        leadStatus = [Select MasterLabel FROM LeadStatus WHERE IsConverted = true ORDER BY SortOrder ASC LIMIT 1];
        System.debug('--168----leadStatus:'+leadStatus);
        return leadStatus;
    }
    */
    public PageReference MergeWithRecord(){
        
         
        System.debug('********Inside MergeWithContact()************');       
        PageReference returnPage;
        try{
            leadRec = [SELECT l.City, l.Company, l.Country, l.Description, l.DoNotCall, l.OwnerId,l.Related_Contact__c,
                    l.Email, l.FirstName, l.HasOptedOutOfEmail, l.Id, l.IM_Functional_Area__c, 
                    l.IM_Industry__c, l.IM_Job_Level__c, l.LastName, l.MobilePhone, l.Name, l.Phone, 
                    l.PostalCode, l.State, l.Street, l.IsConverted FROM Lead l WHERE l.Id = :leadRec.Id];
       String s = leadRec.ownerid;
        if(s.substring(0,3)== '00G')
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Leads cannot have owner Id from a Queue. Please go back and select a different owner');
            ApexPages.addMessage(myMsg);
            returnPage=null;
        }
        else
        {
            returnPage= new PageReference('/'+leadRec.Id);       
            if(leadRec.IsConverted) 
               return returnPage; 
               System.debug('---150----returnPage:'+returnPage);
                
                System.debug('---152----taskdetails:'+taskdetails);
                if(taskdetails==false){
                    if(oppRec.Name.contains('&')==true)
                    {
                        oppRec.Name=oppRec.Name.replace('&', '1x1');
                    }
                    if(oppRec.Name.contains(';')==true)
                    {
                        oppRec.Name=oppRec.Name.replace(';', '2x2');
                    }
                    if(oppRec.Name.contains('!')==true)
                    {
                        oppRec.Name=oppRec.Name.replace('!', '3x3');
                    }
                    if(oppRec.Name.contains('@')==true)
                    {               
                        oppRec.Name=oppRec.Name.replace('@', '4x4');
                    }
                    if(oppRec.Name.contains('%')==true)
                    {
                        oppRec.Name=oppRec.Name.replace('%', '5x5');
                    }
                    if(oppRec.Name.contains('#')==true)
                    {
                        oppRec.Name=oppRec.Name.replace('#', '6x6');
                    }
                    if(oppRec.Name.contains('-')==true)
                    {
                        oppRec.Name=oppRec.Name.replace('-', '7x7');    
                    }
                    
                    /* madhu added on 1/17/13 start */
                    System.debug('---184----ContactId:'+ContactId);
                    if(ContactId!=null){
                        if(sContactAccountName.contains('&')==true)
                        {
                            sContactAccountName=sContactAccountName.replace('&', '1x1');    
                        }
                         if(sContactAccountName.contains(';')==true)
                        {
                            sContactAccountName=sContactAccountName.replace(';', '2x2');
                        }
                        if(sContactAccountName.contains('!')==true)
                        {
                             sContactAccountName=sContactAccountName.replace('!', '3x3');
                        }
                        if(sContactAccountName.contains('@')==true)
                        {               
                             sContactAccountName=sContactAccountName.replace('@', '4x4');
                        }
                        if(sContactAccountName.contains('%')==true)
                        {
                             sContactAccountName=sContactAccountName.replace('%', '5x5');
                        }
                        if(sContactAccountName.contains('#')==true)
                        {
                             sContactAccountName=sContactAccountName.replace('#', '6x6');
                        }
                        if(sContactAccountName.contains('-')==true)
                        {
                             sContactAccountName=sContactAccountName.replace('-', '7x7');    
                        }
                    }
                    /*end*/
                    system.debug('++++216+++++sContactAccountName+++++++++'+sContactAccountName);
                    /*added on 1/18/13 */
                    system.debug('----218------AccountId :'+AccountId );
                    if(AccountId != NULL){
                        if(sAccountName.contains('&')==true)
                        {
                           sAccountName=sAccountName.replace('&', '1x1');    
                        }
                         if(sAccountName.contains(';')==true)
                        {
                                        sAccountName=sAccountName.replace(';', '2x2');
                        }
                        if(sAccountName.contains('!')==true)
                        {
                                        sAccountName=sAccountName.replace('!', '3x3');
                        }
                        if(sAccountName.contains('@')==true)
                        {               
                                        sAccountName=sAccountName.replace('@', '4x4');
                        }
                        if(sAccountName.contains('%')==true)
                        {
                                        sAccountName=sAccountName.replace('%', '5x5');
                        }
                        if(sAccountName.contains('#')==true)
                        {
                                        sAccountName=sAccountName.replace('#', '6x6');
                        }
                        if(sAccountName.contains('-')==true)
                        {
                                      sAccountName=sAccountName.replace('-', '7x7');    
                        }
                    }
                    /*end*/ 
                    
                    /*Srinu: Added on 03-04-2013 */
                    system.debug('----218------AccountId :'+AccountId );
                    if(LeadId != NULL){
                        if(LAccountName.contains('&')==true)
                        {
                           LAccountName=LAccountName.replace('&', '1x1');    
                        }
                         if(LAccountName.contains(';')==true)
                        {
                            LAccountName=LAccountName.replace(';', '2x2');
                        }
                        if(LAccountName.contains('!')==true)
                        {
                            LAccountName=LAccountName.replace('!', '3x3');
                        }
                        if(LAccountName.contains('@')==true)
                        {               
                            LAccountName=LAccountName.replace('@', '4x4');
                        }
                        if(LAccountName.contains('%')==true)
                        {
                            LAccountName=LAccountName.replace('%', '5x5');
                        }
                        if(LAccountName.contains('#')==true)
                        {
                            LAccountName=LAccountName.replace('#', '6x6');
                        }
                        if(LAccountName.contains('-')==true)
                        {
                          LAccountName=LAccountName.replace('-', '7x7');    
                        }
                    }
                    /*end*/
                    
                    system.debug('----251------ContactId:'+ContactId +'\t AccountId:'+AccountId);
                    //if(ContactId==null)
                    if(ContactId==null && AccountId!=null){
                        returnPage =new PageReference('/apex/OppEntryPage?leadid='+LeadId+'&status='+convertedStatus+'&leadAccountName='+sAccountName+'&accname='+sAccountName+'&oppname='+oppRec.Name+'&dupe=true'+'&ownerId='+ownerid+'&govOpty='+sAccountSegmntAndSubSegmnt+'&straccname='+AccountId);
                        System.debug('---255----returnPage:'+returnPage);
                    }else{
                        if(AccountId==null && ContactId != Null){
                            /*Srinu/Madhu: Added 'straccname' parameter and assigned 'Contact AccountId' AND Changed parameter Owner to OwnerId to make it same naming convention for parameters either from Lead Controller or Lead Custom Merge Controller on 12/11*/
                            returnPage =new PageReference('/apex/OppEntryPage?leadid='+LeadId+'&strconname='+ContactId+'&leadAccountName='+sContactAccountName+'&status='+convertedStatus+'&oppname='+oppRec.Name+'&dupe=true'+'&ownerId='+ownerid+'&straccname='+conRec.accountId +'&contDomain='+sContactEmailDomain +'&govOpty='+sAccountSegmntAndSubSegmnt); //+'&a='+strSubject1+'&b='+strStatus+'&c='+strPriority+'&d='+strDesciption+'&e='+showClientAgreement
                            System.debug('---260----returnPage:'+returnPage);
                        }
                        else{
                            //Srinu:Added on 2-28-2013
                            //returnPage =new PageReference('/apex/CustomLeadConvert?id='+LeadId);
                            returnPage =new PageReference('/apex/OppEntryPage?leadid='+LeadId+'&status='+convertedStatus+'&leadAccountName='+LAccountName+'&accname='+sAccountName+'&oppname='+oppRec.Name+'&dupe=false'+'&ownerId='+ownerid);                            
                            System.debug('---304----returnPage:'+returnPage);
                        }    
                    }
                }
                else{
                    system.debug('+++++++265++++++else executing when task details is equals to False+++++++++');
                    Database.LeadConvertResult lcr;
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(leadRec.Id);
                    lc.setDoNotCreateOpportunity(doNotCreateOpp);
                    lc.setSendNotificationEmail(sendNotification);
                    lc.setConvertedStatus(convertedStatus);
                    
                    System.debug('---278----doNotCreateOpp :'+doNotCreateOpp );
                    if (doNotCreateOpp != true) {
                        if ( oppRec != null && oppRec.Name != null && oppRec.Name != '')
                        {
                            
                            lc.setOpportunityName(oppRec.Name);
                        }
                        else 
                            lc.setOpportunityName(accRec.Name);
                    }                   
                    
                    System.debug('---289----leadRec.Id:'+leadRec.Id +'\t conRec.Id:'+conRec.Id +'\t accRec.Id:'+accRec.Id);                     
                    if( leadRec.Id != null && conRec.Id != null) {
                        lc.setAccountId(conRec.AccountId);
                        lc.setContactId(conRec.Id);
                        returnPage = new PageReference('/'+conRec.Id);
                        System.debug('---294-----returnPage :'+returnPage );
                    }
                    else if (leadRec.Id != null && accRec.Id != null) {
                        lc.setAccountId(accRec.Id);
                        returnPage = new PageReference('/'+accRec.Id);
                        System.debug('---299-----returnPage :'+returnPage );
                    }
                    
                    Id convertedAccId, convertedConId, convertedOptyId;
                   
                    //Convert Lead to merge into given Contact/Account
                    if (isTest != TRUE) {
                        lcr= Database.convertLead(lc, true);           
                        System.assert(lcr.isSuccess());
                        convertedAccId = lcr.getAccountId();
                        convertedConId = lcr.getContactId();
                        if (lcr.getOpportunityId() != null)
                            convertedOptyId = lcr.getOpportunityId();
                            System.debug('----312---convertedOptyId :'+convertedOptyId );
                    } 
                        
                    if (convertedOptyId != null)
                        returnPage = new PageReference('/'+lcr.getOpportunityId());
                        System.debug('----317---returnPage:'+returnPage);
                        
                    //Insert Task record
                    if (task.Subject != null && task.Subject != '') {               
                        task.WhoId = convertedConId;
                            
                        if(  convertedOptyId != null )
                            task.WhatId =  convertedOptyId;    
                        else { 
                            task.WhatId =  convertedAccId;
                        }   
                        if (task.IsReminderSet != true) {
                            task.ReminderDateTime = null;
                            task.IsReminderSet = false;
                        } else 
                            task.IsReminderSet = true;
                              
                        insert task;
                    }
                    
                    //Send notification email
                    if (sendNotification == true && task.Id != null) {
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        User owner = [SELECT FirstName, LastName, Email FROM USER WHERE Id = :leadRec.OwnerId];
                        String[] toAddresses = new String[] {owner.Email};
                        String url = ApexPages.currentPage().getHeaders().get('Host');
                        String taskURL = 'https://'+ url + '/' + task.Id;
                        String emailBody = 'New Task';
            
                        mail.setToAddresses(toAddresses);
                        mail.setSubject(' Force.com follow-up: ' + task.Subject);
                        emailBody += '\n\nTo: ' + owner.FirstName +' '+ owner.LastName;
                        emailBody += '\n\n' + owner.FirstName +' '+ owner.LastName + ' has assigned you the following new task:';
                        emailBody += '\n\nSubject: '+ task.Subject;
                        emailBody += '\nContact: ';
                        if ( leadRec.FirstName != null)
                            emailBody += leadRec.FirstName;
                        emailBody += ' '+leadRec.LastName;
                        if ( convertedOptyId != null)
                            emailBody += '\nOpportunity: ' + oppRec.Name;
                        emailBody += '\nDue Date: ';
                        if ( task.ActivityDate != null)
                            emailBody += task.ActivityDate;
                        emailBody += '\nPriority: ';
                        if ( task.Priority != null)
                            emailBody += task.Priority;
                        emailBody += '\nPhone: ';
                        if ( leadRec.Phone != null)
                            emailBody += leadRec.Phone;
                        emailBody += '\n\nFor more details, click the following link:';
                        emailBody += '\n\n' + taskURL;            
                        mail.setPlainTextBody(emailBody);
                                            
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });            
                    }
                }
            }
        }
        catch(DMLException dmlex){
            System.assert((dmlex.getMessage().contains('Insufficient privileges')
                        || dmlex.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY')),
                        'Contact Salesforce Admin. DMLException Message: ' + dmlex.getMessage());
        }
        catch(Exception ex){
            System.assert((ex.getMessage().contains('Insufficient privileges')
                        ||ex.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY')),
                        'Contact Salesforce Admin. Exception Message: ' + ex.getMessage());
        }   
        if(returnPage != null)
        {
            returnPage.setRedirect(true);  
            System.debug('---388----returnPage:'+returnPage);
        }  
        system.debug('++++++390++++++++page reference +++++++'+returnPage);    
        return returnPage; 
        
    }     
}
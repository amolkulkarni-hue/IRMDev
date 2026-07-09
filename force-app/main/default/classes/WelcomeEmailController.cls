/*

Updated class to attach welcome email sent to the case, and removal of tags being displayed when value is null
Case # 04983255 
Author : Vinutha
Date : 15/05/2016
Modified the class removed Welcome_Email_Service_Line__c,Welcome_Email_Ctd_Not_Ctd__c based on 
user story : #8988
Author : Rajashekar 
Date : 26/05/2022
*/

public without sharing class WelcomeEmailController {


    private final Case mainCase;
    public WelcomeEmailWizardModel model {get;set;}
    public Case[] cases{get;set;}
    transient public Messaging.SingleEmailMessage email {get;set;}
    public String bodySection {get;set;}
    public String greetingSection {get;set;}
    public String salutationSection {get;set;}
    
    @TestVisible private Boolean previousStepEncountered  = false;
    @TestVisible private static List<String> illFormedTags = new List<String>();
    @TestVisible private static List<String> unclosedTags = new List<String>();
    @TestVisible private static List<String> floatingTexts = new List<String>();
    
    @testVisible static final String NCSP_QUEUE_NAME = 'NCSP_FIFO_First_in_First_out';
    @testVisible static final String NO_RELATED_CASES_FOUND = 'There were no related cases to be found. Click next to continue with single';
    @testVisible static final String DIRECT_ACCESS_ERROR = 'You cannot directly access this page';
    @testVisible static final String MAIN_CASE_MUST_BE_OPEN = 'You cannot start the wizard with a Closed Case';
    @testVisible static final String MAIN_CASE_SUBMITTED = 'You cannot start the wizard with a Case that has been responded to.';
    @testVisible static final String NO_MAIN_CASE = 'You must select a main case for this wizard.';
    @testVisible static final String INVALID_EMAIL_ADDRESS = 'Email address(es) in To: and Cc: fields may be in invalid format';
    @testVisible static final String CASE_IS_OWNED_BY_DIFFERENT_USER = 'The main Case must be owned by You or in NCSP Queue';
    @testVisible static final String NO_FIELD_IN_FIELDSET = 'Please add a field to the Case fieldset: "Fields To Display In Welcome Wizard"';
    @testVisible static final String NO_TEMPLATE = 'There doesn\'t seem to be a template for this service line. This is an error';
    @testVisible static final String TOO_MANY_MERGE_FIELDS = 'One or more merge fields in the main template was not replaced. Either delete these merge fields or add corresponding sections for them in the child text templates:\n';
    @testVisible static final String TOO_FEW_MERGE_FIELDS = 'Warning: one or more sections in the child text template remains not merged. To merge into main template, add merge field for this section:\n';
    @testVisible static final String NO_SALUTATION_IN_TEMPLATE = 'Either the main template or the child text template do not have a salutation section. This is required';
    @testVisible static final String ILLFORMED_TAG_ERROR = 'PARSE ERROR: Tag can only contain numbers and letters. Ill-formed tags:\n';
    @testVisible static final String UNCLOSED_TAG_ERROR = 'PARSE ERROR: Outermost tags must have a closing tag. Unclosed tags:\n';
    @testVisible static final String FLOATING_TEXT_ERROR = 'PARSE ERROR: Text outside of XML tags will be ignored. Please handle the following text blocks that are not inside XML tags:\n';
    @testVisible static final String NO_FIELD_VALUE = 'Placeholder field for the following fields was not replaced because its value was null or undefined: ';
    @testVisible static final String REL_OBJ_NOT_LINKED = 'Placeholder field for the following fields was not replaced because a record of this object type was not found in the lookup of the parent Case: ';
    @testVisible static final String NO_FORMURL_MERGE_FIELD = '{formURL} merge field was not found in this template for customer not contacted';

    @testVisible enum WizardStatus {EDIT_MODE, PREVIEW_MODE, SENT_MODE}
    @testVisible WizardStatus ws;
    public Boolean isEditing { get { return ws == WizardStatus.EDIT_MODE; } set; }
    public Boolean isPreviewing { get { return ws == WizardStatus.PREVIEW_MODE; } set; }
    public Boolean isSent { get { return ws == WizardStatus.SENT_MODE; } set; }

    public WelcomeEmailController(ApexPages.StandardController controller) {
        if (!String.isBlank(controller.getRecord().Id)) {
            Case requeriedCase = [SELECT Id, CaseNumber, Contact.Email, Contact.Name, OwnerId, IsClosed, 
                                            Date_welcome_call_completed__c, Welcome_Packet_Sent_Date__c, 
                                            NCSP_Opportunity__c, NCSP_Service_line__c, Customer_Info_Form_Submitted_Date__c,Reference__c  
                                            FROM Case WHERE Id = :controller.getRecord().Id];
            this.mainCase = requeriedCase;
        
            this.errorOnStep1 = false;
            this.previewMode = false;

            if( this.mainCase.IsClosed) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MAIN_CASE_MUST_BE_OPEN));
                errorOnStep1 = true;
            }

            if( this.mainCase.Customer_Info_Form_Submitted_Date__c != null) {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MAIN_CASE_SUBMITTED));
                //errorOnStep1 = true;
            }

            if( this.mainCase.OwnerId != currentUserId && this.mainCase.OwnerId != WelcomeEmailWizardModel.nCSPQueue.Id) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CASE_IS_OWNED_BY_DIFFERENT_USER));
                errorOnStep1 = true;
            }

            ws = WizardStatus.EDIT_MODE;
            //Create model instance
            if (!errorOnStep1) {
                model = new WelcomeEmailWizardModel(this.mainCase);
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, NO_MAIN_CASE));
            errorOnStep1 = true;

        }
            
        if( !BluewolfdevUtils.getPageName( Page.WelcomeEmailWizard.getUrl() ).equalsIgnoreCase( BluewolfdevUtils.getPageName() )
            && !previousStepEncountered )
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, DIRECT_ACCESS_ERROR));
    }

    /* popup properties and methods */

    public Boolean displayPopup { get; set; }

    public void closePopup() {
        displayPopup = false;
    }

    public void showPopup() {
        displayPopup = true;
    }

    transient public String serializedAttachments {
        get; set;
    }

    public class AttWr { 
        public String title {get;set;}
        public String body {get;set;}

        public AttWr(String title, String body) {
            this.title = title;
            this.body = body;
        }
    }

    @TestVisible static String currentUserId {
        get {
            if (currentUserId == null) 
                currentUserId = UserInfo.getUserId();
            return currentUserId;
        }
        set;
    }

   @TestVisible static User currentUser {
        get {
            if (currentUser == null)
                currentUser = [Select Id, Title, Email, FirstName, LastName FROM User WHERE Id =: currentUserId];
            return currentUser;
        }
    }

    public Boolean renderCaseList {
        get {
            return !errorOnStep1 && !model.relatedCases.isEmpty();
        }
        set;
    }

    public Boolean renderDataEntryCaseList {
        get {
            return !errorOnStep1 && !model.dataEntryCases.isEmpty();
        }
        set;        
    }

    public Boolean errorOnStep2 {
        get {
            return model.errorRetrievingTemplate || replacementError || parseError || mergeError;
        }
        set;
    }

    public Boolean mergeError {
        get{
            if (mergeError == null)
                mergeError = false;
            return mergeError;
        } set;
    }

    public Boolean replacementError {
        get{
            if (replacementError == null)
                replacementError = false;
            return replacementError;
        } set;
    }

    static public Boolean parseError {
        get {
            if (parseError == null)
                parseError = false;
            return parseError;
        }
        set;
    }

    public List<SelectOption> getTemplateItems() {
        Integer orderNum;
        if (!WelcomeEmailWizardModel.templateNameForServiceLine.keySet().isEmpty()) 
            orderNum = WelcomeEmailWizardModel.templateOrderNum.get(WelcomeEmailWizardModel.templateNameForServiceLine.get(mainCase.NCSP_Service_line__c));
        orderNum = (orderNum==null?0:orderNum);
        List<SelectOption> options = new List<SelectOption>();
        for (Integer i=0; i<4; i++) {
            options.add(new SelectOption(model.templateTypes[Math.mod(i+orderNum,4)],model.templateTypes[Math.mod(i+orderNum,4)]+' Template'));
        }
        return options;
    }

    public List<SelectOption> getLanguageItems() {
        List<SelectOption> options = new List<SelectOption>();
        for (String lang : model.languages) 
            options.add(new SelectOption(lang,lang));
        return options;
    }

    public Boolean renderEmail { 
        get {
            return previousStepEncountered;
        } 
        set; 
    }

    public Boolean errorOnStep1 { get; set; }
    public Boolean reviewMode { get; set; }
    public Boolean previewMode { get; set; }
    public Integer step2State { get;set; }
    
    public List<Case> selectedCases {
        get {
            if (selectedCases == null) {
                selectedCases = new List<Case>{mainCase}; // use model.mainCase?
                for (WelcomeEmailWizardModel.SelectableCase c : model.relatedCases) {
                    if (c.selected)
                        selectedCases.add(c.caseObject);
                }
            }
            return selectedCases;
        }
        set;
    }

    /*
    * Sets all the Owners of Cases in SelectedCases to current User 
    */
    public List<Case> reassignSelectedCases() {
        List<Case> reassignedCases = new List<Case>();
        for (Case sc : selectedCases) {
            if (sc.OwnerId == WelcomeEmailWizardModel.nCSPQueue.Id) {
                sc.OwnerId = currentUserId;
                reassignedCases.add(sc);
            }
        }
        update reassignedCases;
        return reassignedCases;
    }

    public List<Case> updateEmailSentDateForSelectedCases() {
        List<Case> updatedCases = new List<Case>();
        for (Case sc : selectedCases) {
            if (sc.OwnerId == WelcomeEmailWizardModel.nCSPQueue.Id) 
                sc.OwnerId = currentUserId;
            sc.Welcome_Packet_Sent_Date__c = Datetime.now();
            sc.Welcome_Email_Language__c = model.language;
           // sc.Welcome_Email_Service_Line__c = model.templateType;
           // sc.Welcome_Email_Ctd_Not_Ctd__c = model.hasBeenContacted;
            sc.Customer_Onboarding_Reminder_Email_Link__c = model.urlUsed;
            updatedCases.add(sc);
        }
        system.debug('size in actual class updatedCases'+updatedCases.size());
        update updatedCases;
        return updatedCases;
    }

    /*
    * Precondition: selectedCases not null
    */
    @TestVisible Set<String> getSelectedOppOwnerEmails() {
        Set<String> emails = new Set<String>();
        List<Id> relatedOppIDs = new List<Id>();
        for (Case c : selectedCases) {
            relatedOppIDs.add(c.NCSP_Opportunity__c);
        }
        List<Opportunity> relatedOpps = [SELECT Owner.Email FROM Opportunity WHERE Id in :relatedOppIDs];
        for (Opportunity o : relatedOpps) {
            emails.add(o.Owner.Email);
        }
        return emails;
    }

    /*
    * Returns a dynamically generated SingleEmailMessage object that has:
    * (1) To: field set to mainCase Contact Email
    * (2) CC: field set to related Opportunity Owners
    * (3) Body field merged with contents of 3 sections: {GreetingSection}, {BodySection}, {SalutationSection}
    */
    public Messaging.SingleEmailMessage generateEditedEmailMessage() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses( model.toAddress.split('\\s*,\\s*', -1)     );
        if (!String.isBlank(model.ccAddresses))
            mail.setCcAddresses( model.ccAddresses.split('\\s*,\\s*', -1) );
            //mail.setBccAddresses( new List<String>{model.routingEmail} );
            mail.setSubject( model.emailSubject+' '+mainCase.Reference__c );
            mail.setSaveAsActivity(true);
            mail.setHTMLBody( '<font color="white">'+mainCase.Reference__c+ '</font></br>' +model.emailBody ); 
                      
            //added for getting email as related list- 20/4/16
            EmailMessage emailMsg = new EmailMessage(); // Created a EmailMessage and copy all details from above.
                emailMsg.ToAddress=(mail.getToAddresses())[0];
                emailMsg.Subject=mail.getSubject();
                emailMsg.HtmlBody=mail.getHtmlBody();
                emailMsg.ParentId = mainCase.Id; //Attach with the case
                emailMsg.MessageDate = system.now();
                //emailMsg.refernceId = mainCase.Reference__c;
                insert emailMsg;
            return mail;
      }
    
    
    

    // host = System.URL.getSalesforceBaseUrl().getHost()
    @TestVisible
    static String generateUnifiedURL(String host, List<Case> cases) {
        String[] splitted = host.split('[.]', -1);
        String siteName = splitted[0];

        if (splitted[0].contains('--')) {
            String[] sbName = splitted[0].split('--', -1);
            if (sbName[1] == 'c') {
                siteName = sbName[0].toLowerCase() + '.secure';
            } else {
                String part1 = sbName[1].toLowerCase() + '-' + sbName[0].toLowerCase();
                siteName = part1 +'.'+ splitted[1];
            }
        } 
        return 'https://' + siteName + '.force.com/customerinformationform/customerinformationform?Id=' + String.join(new List<Id>(Pluck.ids(cases)), ','); 
    }

    Pattern placeholderPattern = Pattern.compile('\\{[\\w|\\d]+\\.*[\\w|\\d]+\\}');

    /*
    *   Helper function: replaces placeholders for all relObj fields specified by fieldNames in body. 
    *       Errors are aggregated by reference in nullFieldErrs
    *       Any fields that are null (not previously queried for OR empty) are considered nullFieldErrs
    *   Note: relObjNameInPH is the API name of the lookup field on the case for this object (i.e. Customer_ID__r)
    */
    private static String replacePlaceholders(Set<String> fieldNames, Case c, String body, String relObjNameInPH, SObject relObj, 
                                                        List<String> nullFieldErrs) {
        for (String field : fieldNames) {
            String placeholder = '{'+relObjNameInPH+'.'+field+'}';
            Object fieldVal = relObj.get(field);
            if (fieldVal != null) 
                body = body.replace(placeholder, String.valueOf(fieldVal));
            else {
                body = body.replace(placeholder, '<span style="color:red">'+placeholder+'</span>');
                nullFieldErrs.add(relObjNameInPH+'.'+field);
            }
        }
        return body;
    }

    /*
    
    */
    public String replacePlaceholderInTextTemplate() {
        String templateBody = model.textTemplate.body;
        Matcher placeholderMatcher = placeholderPattern.matcher(templateBody) ;
        Boolean hasURL = false;
        Set<String> contactFields = new Set<String>();
        Set<String> caseFields = new Set<String>();
        Set<String> custIDFields = new Set<String>();
        Set<String> userFields = new Set<String>();
        while (placeholderMatcher.find()) {
            String placeholder = placeholderMatcher.group();
            placeholder = placeholder.substring(1, placeholder.length()-1);
            if (placeholder.contains('Contact.')) 
                contactFields.add(placeholder.split('\\.', 2)[1]);
            else if (placeholder.contains('Customer_ID__r.'))
                custIDFields.add(placeholder.split('\\.',2)[1]);
            else if (placeholder.contains('User.'))
                userFields.add(placeholder.split('\\.',2)[1]);
            else if (placeholder.contains('Case.'))
                caseFields.add(placeholder.split('\\.',2)[1]);
            else if (placeholder.contains('URL')) 
                hasURL = true;
            //else not added
        }

        QueryBuilder qb = new QueryBuilder(Case.SObjectType, new List<Id>{mainCase.Id});
        qb.addFields(caseFields).addFieldsToObject('Contact', contactFields).addFieldsToObject('Customer_ID__c', custIDFields);
        QueryBuilder qb2 = new QueryBuilder(User.SObjectType, new List<Id>{currentUserId});
        qb2.addFields(userFields);
        User userWithFields;
        Case mainCaseWithFields;
        try {
            // Runs SOQL Query for Case and related Contact and Customer_ID__c lookup fields
            mainCaseWithFields = (Case) qb.runQuery()[0];
            userWithFields = (User) qb2.runQuery()[0];
        } catch (QueryException qe) {
            System.assert(false, qe.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, qe.getMessage()));
        }
        //System.assert(false, mainCaseWithFields.getSobject('Customer_ID__r'));
        List<String> nullFields = new List<String>();
        List<String> relObjsNotLinked = new List<String>();
        templateBody = replacePlaceholders(caseFields, mainCaseWithFields, templateBody, 'Case', (SObject)mainCaseWithFields, nullFields);
        templateBody = replacePlaceholders(userFields, mainCaseWithFields, templateBody, 'User', (SObject)userWithFields, nullFields);

        if (!contactFields.isEmpty()) {
            sObject relObj = mainCaseWithFields.getSobject('Contact');
            if (relObj != null) 
                templateBody = replacePlaceholders(contactFields, mainCaseWithFields, templateBody, 'Contact', relObj, nullFields);
            else 
                relObjsNotLinked.add('Contact');
        }
        
        if (!custIDFields.isEmpty()) {
            sObject relObj = mainCaseWithFields.getSobject('Customer_ID__r');
            if (relObj != null) 
                templateBody = replacePlaceholders(custIDFields, mainCaseWithFields, templateBody, 'Customer_ID__r', relObj, nullFields);
            else 
                relObjsNotLinked.add('Customer_ID__r');
        }
            
        if (hasURL) templateBody = templateBody.replace('{URL}', generateUnifiedURL(System.URL.getSalesforceBaseUrl().getHost(), selectedCases));

        if (!relObjsNotLinked.isEmpty()) {
            replacementError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, REL_OBJ_NOT_LINKED+String.join(relObjsNotLinked, ', ')));
        }

        if (!nullFields.isEmpty())
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, NO_FIELD_VALUE+String.join(nullFields, ', ')));

        return templateBody;
    }

    
    private static List<String> abbreviateList(List<String> strList, Integer maxWidth) {
        List<String> abbList = new List<String>();
        for (String str: strList) 
            abbList.add(str.abbreviate(maxWidth));
        return abbList;
    }

    /*
    *   @pre - caller of this function should empty parseErrors list (class variable)
    *   @param tmpBody - tmpBody must be validated, which means that there should not be any characters outside of an XML tag. 
                            Also, XML tags must be well-formed XML tags. 
    *   @result Map<String, String> - Map of outermost XML tag to it's content
    *   @post - if parseError (class variable) is not empty, returned Map is empty
    */
    @TestVisible
    private static Map<String, String> parseTextTemplate(String tmpBody) {
        Map<String, String> parsedMap = new Map<String, String>();

        Integer startTagPosition = tmpBody.indexOf('<');
        Integer endTagPosition = tmpBody.indexOf('>');

        if (startTagPosition < 0 || endTagPosition < 0)  {
            if (!String.isBlank(tmpBody))
                floatingTexts.add(tmpBody);
            return parsedMap;
        } 

        if (!String.isBlank(tmpBody.substring(0, startTagPosition))) 
            floatingTexts.add(tmpBody.substring(0, startTagPosition));
        

        String tag = tmpBody.substring( startTagPosition+1, endTagPosition );
        String openXMLTag = '<'+tag+'>';
        String closeXMLTag = '</'+tag+'>';

        String remainingBody;
        if (tag.isAlphanumeric() && tmpBody.contains(closeXMLTag)) {
            String value = tmpBody.substringBetween( openXMLTag, closeXMLTag );
            parsedMap.put(tag, value);
            remainingBody = tmpBody.substringAfter(closeXMLTag);
        } else {
            if (!tag.isAlphanumeric()) {
                illFormedTags.add('<'+tag+'>');
                if (!tmpBody.contains(closeXMLTag)) 
                    remainingBody = tmpBody.substringAfter(openXMLTag);
                else 
                    remainingBody = tmpBody.substringAfter(closeXMLTag);
            } else {
                unclosedTags.add('<'+tag+'>');
                remainingBody = tmpBody.substringAfter(openXMLTag);
            } 
        }

        parsedMap.putAll(parseTextTemplate(remainingBody));

        if (!illFormedTags.isEmpty() || !unclosedTags.isEmpty()) {
            parseError = true;
            if (!illFormedTags.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ILLFORMED_TAG_ERROR+String.join(illFormedTags, ', ')));
            }
            if (!unclosedTags.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, UNCLOSED_TAG_ERROR+String.join(unclosedTags, ', ')));
            }
            return new Map<String,String>();
        } else if (!floatingTexts.isEmpty()) {
            parseError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, FLOATING_TEXT_ERROR+String.join(abbreviateList(floatingTexts, 20), ', ')));
            return new Map<String, String>();
        }
        return parsedMap;
    }

    Pattern mergeFieldPattern = Pattern.compile('\\{[\\w|\\d]+\\}');

    /*
    *   Errors that are handled:
            - if there are one or more outstanding merge field in parent template
            - if there are one or more less merge fields in parent template
            - if there are no salutation section in either parent template or map
        Key values of maps does NOT contain squigly braces ('{', '}');
    */
    public String mergeParentTemplateSections(MAP<String,String> textSectionMap, MAP<String,String> imgSectionMap) {
        String parentBody = model.parentTemplate.Body;
        List<String> tooFewMergeFields = new List<String>();
        if (parentBody == null) parentBody = '';
        if (!parentBody.contains('{salutation}')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, NO_SALUTATION_IN_TEMPLATE));  
            return ''; 
        }

        for (String tmf : textSectionMap.keySet()) {
            String tmf_formatted = '{'+tmf+'}';
            if (!parentBody.contains(tmf_formatted)) 
                tooFewMergeFields.add(tmf_formatted);
            else 
                parentBody = parentBody.replace(tmf_formatted, textSectionMap.get(tmf));
        }

        for (String imf : imgSectionMap.keySet()) {
            String imf_formatted = '{'+imf+'}';
            if (parentBody.contains(imf_formatted)) 
                //tooFewMergeFields.add(imf_formatted);
            //else    
                parentBody = parentBody.replace(imf_formatted, imgSectionMap.get(imf));
        }

        if (!model.hasBeenContacted) {
            if (!parentBody.contains('{formURL}'))
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, NO_FORMURL_MERGE_FIELD));
            else
                parentBody = parentBody.replace('{formURL}', model.urlUsed);
        }

        if (!tooFewMergeFields.isEmpty())
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, TOO_FEW_MERGE_FIELDS+String.join(tooFewMergeFields, ', ')));

        Matcher mergeFieldMatcher = mergeFieldPattern.matcher(parentBody);
        List<String> tooManyMergeFields = new List<String>();
        while (mergeFieldMatcher.find()) {
            tooManyMergeFields.add(mergeFieldMatcher.group());
        }

        if (!tooManyMergeFields.isEmpty()) {
            mergeError=true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, TOO_MANY_MERGE_FIELDS+String.join(tooManyMergeFields, ', ')));
            return '';
        }

        return parentBody;
    }

    public Pagereference step1() {
        PageReference step1 = Page.WelcomeEmailWizard;
        step1.getParameters().put('id',mainCase.Id);
        step1.setRedirect(true);
        previousStepEncountered = false;
        previewMode = false;
        return step1;
    }

    Pattern emailPattern = Pattern.compile('^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,10}$');
    
    public PageReference exit() {
        PageReference casePage = new PageReference('/'+mainCase.Id);
        return casePage;
    }

    public PageReference preview() {
        if (errorOnStep2) 
            ws = WizardStatus.EDIT_MODE;
        else {
            ws = WizardStatus.PREVIEW_MODE;
            previousStepEncountered = true;
            previewMode = true;
            Matcher emailMatcher;
            List<String> emailAdds = model.toAddress.split('\\s*,\\s*', -1);
            if (!String.isBlank(model.ccAddresses)) 
                emailAdds.addAll(model.ccAddresses.split('\\s*,\\s*', -1));
            for ( String address :  emailAdds){
                emailMatcher = emailPattern.matcher(address.toUpperCase());
                if (!emailMatcher.matches()) {
                    ws = WizardStatus.EDIT_MODE;
                    previewMode = false;
                }
            }
            if (!previewMode) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVALID_EMAIL_ADDRESS));
            }
        }
        return null;
    }

    public PageReference edit() {
        ws = WizardStatus.EDIT_MODE;
        previousStepEncountered = true;
        previewMode = false;
        //model.emailBody = null;
        PageReference step2 = Page.WelcomeEmailWizardStep2;
        return step2;
    }
    
    public void sendEmailCatchingError() {
        ws = WizardStatus.PREVIEW_MODE;
        try {
            sendEmail();
        } catch (EmailException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        }
    }

    public void sendEmail() {
        ws = WizardStatus.SENT_MODE;
        email = generateEditedEmailMessage();
        List<AttWr> attachments = new List<AttWr>();
        Map<String, String> contentMap = 
            (Map<String, String>) JSON.deserialize(serializedAttachments, Map<String, String>.class );
        for (String filename : contentMap.keySet()) {
            attachments.add(new AttWr(filename, contentMap.get(filename)));
        }
        
        if (!attachments.isEmpty()) {
            List<Messaging.EmailFileAttachment> atts = new List<Messaging.EmailFileAttachment>();
            for (AttWr wr : attachments) {
                Blob body = EncodingUtil.base64Decode(wr.body);
                Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
                att.setBody(body);
                att.setFileName(wr.title);
                atts.add(att);
            }
            email.setFileAttachments(atts);
        }
        Messaging.SendEmailResult result = Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ email } )[0];
        if (!result.isSuccess()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, result.getErrors()[0].getMessage()));
            ws = WizardStatus.PREVIEW_MODE;
        }
        else updateEmailSentDateForSelectedCases();
    }
    
    public Pagereference step2() {
        string tempTextBody ='';
        string tempTextBodyReplace = '';
        ws = WizardStatus.EDIT_MODE;
        model.userEmail = UserInfo.getUserEmail();
        model.toAddress = String.join(new String[]{mainCase.Contact.Email}, ', ');
        model.ccAddresses = String.join(new List<String>(getSelectedOppOwnerEmails()), ', ');
        model.emailSubject = model.textTemplate.Subject;
        model.urlUsed = generateUnifiedURL(System.URL.getSalesforceBaseUrl().getHost(), selectedCases)+'&lang='+model.language;
        
        if (model.textTemplate != null) {
            String populatedTextTemplate = replacePlaceholderInTextTemplate(); 
            if (!errorOnStep2) {
                Map<String, String> textSectionMap = parseTextTemplate(populatedTextTemplate);
                if (!errorOnStep2){
                
                //additional lines added for the template fields to show null when there exists no value for the  fields mentioned in set(String)-25/4/16-anusha
                tempTextBody = mergeParentTemplateSections(textSectionMap, WelcomeEmailWizardModel.getMapOfImages(model.language));
                Set<String> allFieldApi = new Set<String>{'{Case.Supplies_Scheduled_Date_formatted__c}', '{Case.Service_Schedule_Date_formatted__c}'};
                    for(String s:allFieldApi){
                        if(tempTextBody.contains(s)){
                            tempTextBody = tempTextBody.replace(s,'');
                        }
                    }  
                }
            }
        }
        model.emailBody = tempTextBody;
        PageReference step2 = Page.WelcomeEmailWizardStep2;
        step2.setRedirect(false);
        previewMode = false;
        previousStepEncountered = true;
        return step2;
    }

    public class WelcomeEmailCaseWrapper {
        public Boolean selected { get;set; }
        public Case caseObject { get;set; }

        public WelcomeEmailCaseWrapper(Case caseObj) {
            selected = false;
            caseObject = caseObj;
        }
    }
}
public with sharing class WelcomeEmailWizardModel {

    @testVisible static final String NCSP_QUEUE_NAME = 'NCSP_FIFO_First_in_First_out';
    @testVisible static final String DATA_ENTRY_QUEUE = 'Data_Entry';
    @testVisible static final String NO_FIELD_IN_FIELDSET = 'Please add a field to the Case fieldset: "Fields To Display In Welcome Wizard"';
    @testVisible static final String NO_RELATED_CASES_FOUND = 'There were no related cases to be found. Click next to continue with single';
    @testVisible static final String NO_TEMPLATE = 'There doesn\'t seem to be a template for this service line. This is an error. Looking for template: ';
    Case mainCase; 
    public List<Case> mainCaseList { // Always of size 1. Used in VF page to display mainCase in pageBlockTable
        get; set;
    }
    public Boolean mainCaseMatchesCriteria {get;set;}

    /*
    *   Case fields are already querired for
    */
    public WelcomeEmailWizardModel(Case c) {
        QueryBuilder qb = new QueryBuilder(Case.SObjectType, new List<Id>{c.Id});
        qb.addFieldsUsingFieldPaths(fieldsInList).addFields(new Set<String>{'ContactId', 'OwnerId', 'Date_welcome_call_completed__c', 
                                                                            'Customer_Info_Form_Submitted_Date__c', 'Welcome_Email_Language__c', 
                                                                            'Deal_Type__c', 'NCSP_Service_line__c', 'NCSP_Upsell_Type__c', 
                                                                            'Supplies_Order_Required__c'});
        mainCase = (Case) qb.runQuery()[0];
        mainCaseList = new List<Case>{mainCase};
        Map<Id, List<Customer_Onboarding_Field__c>> onboardingFieldsetForMainCase = 
                        CustomerOnboardingCriteriaServices.getOnboardingFieldSets(mainCaseList);
        mainCaseMatchesCriteria = !onboardingFieldsetForMainCase.get(mainCase.Id).isEmpty();
        errorRetrievingTemplate = false;
    }

    public WelcomeEmailWizardModel(Case c, String lang) {
        QueryBuilder qb = new QueryBuilder(Case.SObjectType, new List<Id>{c.Id});
        qb.addFieldsUsingFieldPaths(fieldsInList).addFields(new Set<String>{'ContactId', 'OwnerId', 'Date_welcome_call_completed__c', 
                                                                            'Customer_Info_Form_Submitted_Date__c', 'Welcome_Email_Language__c',
                                                                            'Deal_Type__c', 'NCSP_Service_line__c', 'NCSP_Upsell_Type__c', 
                                                                            'Supplies_Order_Required__c'});
        mainCase = (Case) qb.runQuery()[0];
        mainCaseList = new List<Case>{mainCase};
        Map<Id, List<Customer_Onboarding_Field__c>> onboardingFieldsetForMainCase = 
                        CustomerOnboardingCriteriaServices.getOnboardingFieldSets(mainCaseList);
        mainCaseMatchesCriteria = !onboardingFieldsetForMainCase.get(mainCase.Id).isEmpty();
        language = lang;
        errorRetrievingTemplate = false;
    }

    public static List<Customer_Onboarding_Images_And_Links__c> customerOnboardingImagesAndLinks {
        get{
            if(customerOnboardingImagesAndLinks==null)
            {
                customerOnboardingImagesAndLinks = new List<Customer_Onboarding_Images_And_Links__c>();
                for (Customer_Onboarding_Images_And_Links__c c : Customer_Onboarding_Images_And_Links__c.getAll().values())
                    customerOnboardingImagesAndLinks.add(c);
            }
            return customerOnboardingImagesAndLinks;
        }
    }

    public static Map<String, String> templateNameForServiceLine {
        get{
            if(templateNameForServiceLine==null)
            {
                templateNameForServiceLine = new Map<String, String>();
                for (Template_Name_For_Service_Line__c c : Template_Name_For_Service_Line__c.getAll().values())
                    templateNameForServiceLine.put(c.Name, c.Template_Type__c);
            }
            return templateNameForServiceLine;
        }
    }

    /***************************************** BEGIN: USED IN PAGE ONE OF WIZARD ************************************************/

    public static Group nCSPQueue {
        get {
            if (nCSPQueue == null) {
                List<Group> groups = [Select Id From Group Where DeveloperName = :NCSP_QUEUE_NAME and Type = 'Queue' LIMIT 1];
                System.assert(!groups.isEmpty(), 'Did not find NSCP FIFO Queue in the system');
                nCSPQueue = groups[0];
            }
            return nCSPQueue;
        }
        set;
    }

    public static Group dataEntryQueue {
        get {
            if (dataEntryQueue == null) {
                List<Group> groups = [Select Id From Group Where DeveloperName = :DATA_ENTRY_QUEUE and Type = 'Queue' LIMIT 1];
                System.assert(!groups.isEmpty(), 'Did not find Data Entry Queue in the system');
                dataEntryQueue = groups[0];
            }
            return dataEntryQueue;
        }
        set;
    }

    public static List<String> fieldsInList {
        get{
            if(fieldsInList==null) {
                fieldsInList = new List<String>();
                for(Schema.FieldSetMember field : SobjectType.Case.FieldSets.Fields_To_Display_In_Welcome_Wizard.getFields()) 
                    fieldsInList.add(field.getFieldPath());
            }
            return fieldsInList;
        }
        set;
    }

    @testVisible
    static String fieldsToDisplay {
        get{
            if(fieldsToDisplay==null) {
                if (fieldsInList.isEmpty()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, NO_FIELD_IN_FIELDSET));    
                    fieldsToDisplay = '';
                } else {
                    fieldsToDisplay = ',' + String.join(fieldsInList, ',');
                }
            }
            return fieldsToDisplay;
        }
        set;
    }

    public List<SelectableCase> relatedCases {
        get {
            if (relatedCases == null) {
                relatedCases = new List<SelectableCase>();
                if (mainCase != null) {
                    List<Case> filteredCases = filterAssociatedCases();
                    Map<Id, List<Customer_Onboarding_Field__c>> onboardingFieldsets = 
                        CustomerOnboardingCriteriaServices.getOnboardingFieldSets(filteredCases);
                    Set<Id> casesWithCriteria = new Set<Id>();
                    for (Id caseID : onboardingFieldsets.keySet()) {
                        if (!onboardingFieldsets.get(caseID).isEmpty())
                            casesWithCriteria.add(caseID);
                    }
                    //System.assert(false, onboardingFieldsets);
                    for (Case c : filteredCases) {
                        relatedCases.add(new SelectableCase(c, casesWithCriteria.contains(c.Id)));
                    }
                    if (relatedCases.isEmpty()) 
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, NO_RELATED_CASES_FOUND));
                }
            }
            return relatedCases;
        }
        set;
    }

    public List<Case> dataEntryCases {
        get { 
            if (dataEntryCases == null) {
                Set<String> fieldsToQuery = new Set<String>{'Id', 'NCSP_Opportunity__c', 'OwnerId', 'Welcome_Packet_Sent_Date__c', 
                                                    'NCSP_Service_line__c', 'Deal_Type__c', 'NCSP_Upsell_Type__c', 'Supplies_Order_Required__c'};
                fieldsToQuery.addAll(fieldsInList);
                String query = 'Select ' + String.join(new List<String>(fieldsToQuery), ',') + 
                                    ' From Case ' +
                                    'Where IsClosed = false AND Id != \''+mainCase.Id+'\' AND ContactId = \''+mainCase.ContactId+'\' ' +
                                            'AND ( OwnerId = \''+dataEntryQueue.Id+'\' ) ';
                dataEntryCases = Database.query(query);
            }
            return dataEntryCases;
        } set;
    }

    public static Map<String, Integer> templateOrderNum {
        get {
            if (templateOrderNum == null) {
                templateOrderNum = new Map<String, Integer>{ 'DM'=>0,
                                                             'SS'=>1,
                                                             'RM'=>2,
                                                          'RM_SS'=>3 };
            }
            return templateOrderNum;
        } set;
    } 

    public List<String> templateTypes {
        get {
            if (templateTypes == null) 
                templateTypes = new List<String>{'DM', 'SS', 'RM', 'RM_SS'};
            return templateTypes;
        }
        set;
    }

    public List<String> languages {
        get {
            if (languages == null) 
                languages = new List<String>{'USEnglish', 'French', 'CAEnglish'};
            return languages;
        }
        set;
    }

    public String templateType { 
        get {
            if (templateType==null)
                templateType = templateNameForServiceLine.get(mainCase.NCSP_Service_line__c);
            return templateType;
        } set;
    }

    public Boolean hasBeenContacted { 
        get {
            if (hasBeenContacted==null)
                hasBeenContacted = (mainCase.Date_welcome_call_completed__c==null?false:true) ||
                                   (mainCase.Customer_Info_Form_Submitted_Date__c==null?false:true);
            return hasBeenContacted;
        } set;
    }

    public Boolean formCompleted {
        get {
            if (formCompleted==null)
                formCompleted = (mainCase.Customer_Info_Form_Submitted_Date__c!=null);
            return formCompleted;
        } set;
    }

    public String language { 
        get {
            if (language==null)
                language = (mainCase.Welcome_Email_Language__c==null?'USEnglish':mainCase.Welcome_Email_Language__c);
            return language;
        } set;
    }

    public class SelectableCase {
        public Boolean selected { get;set; }
        public Case caseObject { get;set; }
        public Boolean hasMatchingCriteria {get;set;}

        public SelectableCase(Case caseObj) {
            selected = false;
            caseObject = caseObj;
            hasMatchingCriteria = false;
        }
        public SelectableCase(Case caseObj, Boolean matchesCriteria) {
            selected = false;
            caseObject = caseObj;
            hasMatchingCriteria = matchesCriteria;
        }
    }

    /*
    * Returns all cases that meet the following criteria:
    * (1) Case is open AND Case Contact matches Contact of selected Case (AND also NOT mainCase)
    * (2) AND (b) Case Owner matches Owner of selected Case, OR
    *         (c) Case is queued in "NCSP FIFO" 
    */
    @testVisible
    private List<Case> filterAssociatedCases() {
        if (fieldsInList.isEmpty()) 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, NO_FIELD_IN_FIELDSET));    
        Set<String> fieldsToQuery = new Set<String>{'Id', 'NCSP_Opportunity__c', 'OwnerId', 'Welcome_Packet_Sent_Date__c', 
                                                    'NCSP_Service_line__c', 'Deal_Type__c', 'NCSP_Upsell_Type__c', 'Supplies_Order_Required__c'};
        fieldsToQuery.addAll(fieldsInList);
        String query = 'Select ' + String.join(new List<String>(fieldsToQuery), ',') + 
                                    ' From Case ' +
                                    'Where IsClosed = false AND Id != \''+mainCase.Id+'\' AND ContactId = \''+mainCase.ContactId+'\' ' +
                                            'AND ( OwnerId = \''+mainCase.OwnerId+'\' OR OwnerId = \''+nCSPQueue.Id+'\' ) ';
                                            // +
                                            //'AND Customer_Info_Form_Submitted_Date__c = null';
        List<Case> filteredCases = database.query(query);
        return filteredCases;
    }


    /***************************************** END: USED IN PAGE ONE OF WIZARD ************************************************/

    /***************************************** BEGIN: USED IN PAGE TWO OF WIZARD ************************************************/


    /*
    *   Looks at the language in the model and returns a map of tags to links to replace language-specific image placeholders
    *   in the parent text template.
    */
    public static Map<String, String> getMapOfImages(String lang) {
        Map<String, String> mapOfImages = new Map<String, String>();
        for (Customer_Onboarding_Images_And_Links__c coial : customerOnboardingImagesAndLinks) {
            if (coial.Language__c == lang) {
                if (coial.Type__c == 'image')
                    mapOfImages.put('IMG:'+coial.Description__c, coial.Image_Link__c);
                else mapOfImages.put('LINK:'+coial.Description__c, coial.Image_Link__c);
            }
        }
        return mapOfImages;
    }

    /*
    *   Template Name of a given case is as follows:
    *       [Service Line]_[Contacted/Not_Contacted]_Template
    */
    public String parentTemplateDevName { 
        get {
            if (parentTemplateDevName == null) {
                parentTemplateDevName = templateType+'_'+(hasBeenContacted?'Ctd':'NotCtd')+'_Template';
            }
            return parentTemplateDevName;
        } 
        set; 
    }

    public EmailTemplate parentTemplate {
        get {
            if (parentTemplate == null) {
                try {
                    parentTemplate = [SELECT Id, Body, Subject From EmailTemplate WHERE DeveloperName = :parentTemplateDevName LIMIT 1];
                } catch (Exception e) {
                    errorRetrievingTemplate = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, NO_TEMPLATE+parentTemplateDevName));
                }
            }
            return parentTemplate;
        }
        set;
    }

    /*
    *   Template Name of a given case is as follows:
    *       [Service Line]_[Ctd/Ctd]_[Language]_Template
    */
    public String textTemplateDevName { 
        get {
            if (textTemplateDevName == null) {
                textTemplateDevName = templateType+'_'+(hasBeenContacted?'Ctd':'NotCtd')+'_'+language+'_Text';
            }
            return textTemplateDevName;
        } 
        set; 
    }

    public EmailTemplate textTemplate {
        get {
            if (textTemplate == null) {
                try {
                    textTemplate = [SELECT Id, Body, Subject, DeveloperName From EmailTemplate WHERE DeveloperName = :textTemplateDevName LIMIT 1];
                } catch (Exception e) {
                    errorRetrievingTemplate = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, NO_TEMPLATE+textTemplateDevName));
                }
            }
            return textTemplate;
        }
        set;
    }

    public String urlUsed;
    public String userEmail { get; set; }
    public String toAddress { get; set; }
    public String ccAddresses { get ; set; }
    public String emailBody { get; set; }
    public String emailSubject { get; set; }

    public Boolean errorRetrievingTemplate { get; set; }

    /***************************************** END: USED IN PAGE TWO OF WIZARD ************************************************/
}
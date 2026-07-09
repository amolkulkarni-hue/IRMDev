public without sharing class FormController {
    public static Boolean executeUpdationInTrigger = true;
    public static Integer staticIndex = 0;

    public final static String FORM_SUBMITTED = Label.Form_Submitted;
    public final static String EMAIL_NOT_SENT = Label.Form_Not_Open;
    public final static String INVALID_FIELD = 'Query Exception: Invalid field was queried for';
    public final static String NO_FIELDS_TO_DISPLAY = 'There are no modifiable fields for this Case';
    public final static String UNSUPPORTED_LANG = 'This language is not supported by this form: ';
    public final static String NO_CASES = 'No parameters';
    @testVisible
    static List<String> initialCaseFields = new List<String>{ 'Welcome_Packet_Sent_Date__c', 'Customer_Info_Form_Submitted_Date__c',
                                                              'NCSP_Service_Line__c', 'Deal_Type__c', 
                                                              'NCSP_Upsell_Type__c', 'Supplies_Order_Required__c', 
                                                              'Customer_Profile__c', 'ContactId' , 'Customer_Facing_Service_Line__c',
                                                              'Customer_ID__r.Name', 'Initial_Supply_Order_Date__c', 
                                                              'Service_Order_Date__c'};
    public String caseIds {get;set;}

    public List<Case> cases { get;set; }
    public List<Customer_Profile__c> profiles {get;set;}
    public Contact contactForCases { get;set; }
    
    public List<CaseContentWrapper> caseWrappers {get;set;}
    public Map<id, List<Customer_Onboarding_Field__c>> caseToFieldsMap {get;set;}
    public Contact placeholderContact {get; set;}
    
    public List<ModifiableField> contactFields {get;set;}
    public Set<String> contactFieldApiNames {get;set;}
    public Set<String> caseFieldApiNames {get;set;}
    public Set<String> profileFieldApiNames {get;set;}
    public boolean welcomeEmailNotSent {get;set;}
    public boolean formAlreadySubmittedForAllCases {get;set;}

    @testVisible
    private String language = 'USEnglish';
    private Set<String> validLanguages = new Set<String>{'USEnglish', 'CAEnglish', 'French'};

    public Boolean english { 
        get {
            return language == 'USEnglish' || language == 'CAEnglish';
        } set;
    }

    public Boolean french { 
        get {
            return language == 'French';
        } set;
    }
    
    Map<Id, CaseContentWrapper> profileIdToWrapperWithOriginalProfile = new Map<Id, CaseContentWrapper>();

    public FormController() {
        String langParam = ApexPages.currentPage().getParameters().get('lang');
        if (!String.isBlank(langParam))
            language = langParam;
        if (!validLanguages.contains(language)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, UNSUPPORTED_LANG + language));
            return;
        }

        caseIds = ApexPages.currentPage().getParameters().get('id');
        if (String.isBlank(caseIds)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, NO_CASES));
            this.welcomeEmailNotSent = false;
            this.formAlreadySubmittedForAllCases = false;
            system.debug('++++++11');
            return;
        }
        List<Id> caseIDList = caseIds.split(',');
        
        this.welcomeEmailNotSent = false;
        this.formAlreadySubmittedForAllCases = true;

        QueryBuilder prequeryQB = new QueryBuilder(Case.SObjectType, caseIDList);
        prequeryQB.addFieldsUsingFieldPaths(initialCaseFields);
        cases = (List<Case>) prequeryQB.runQuery();

        caseToFieldsMap = CustomerOnboardingCriteriaServices.getOnboardingFieldSets(cases);
        system.debug('======cases:'+cases);
        for(Case caseToValidate : cases) {
            if(caseToValidate.Welcome_Packet_Sent_Date__c == null){
                this.welcomeEmailNotSent = true;
            }
            system.debug(caseToValidate.Customer_Info_Form_Submitted_Date__c+'@@'+caseToValidate.Initial_Supply_Order_Date__c+'##'+caseToValidate.Service_Order_Date__c);
            if(caseToValidate.Customer_Info_Form_Submitted_Date__c == null &&
                caseToValidate.Initial_Supply_Order_Date__c == null &&
                caseToValidate.Service_Order_Date__c == null){
                this.formAlreadySubmittedForAllCases = false;
                system.debug('++++++22');
            }
        }
        system.debug('++++++formAlreadySubmittedForAllCases:'+formAlreadySubmittedForAllCases);
        this.generateFieldsToQueryLists(caseToFieldsMap) ; 
                
        if ( (!welcomeEmailNotSent) && (!formAlreadySubmittedForAllCases) &&  
                (!noFields) ) {system.debug('=========11');
            queryForCasesProfilesAndContact(caseIDList);
            Map<Id, Customer_Profile__c> profileMap = new Map<Id, Customer_Profile__c>();
            if (profiles != null)
                profileMap = new Map<Id, Customer_Profile__c>(profiles);
            caseWrappers = buildCaseWrappers(cases, caseToFieldsMap, profileMap);
        } else {
            system.debug('=========22');
            if (welcomeEmailNotSent)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, EMAIL_NOT_SENT));
            if (formAlreadySubmittedForAllCases)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, FORM_SUBMITTED));
            if (noFields) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, NO_FIELDS_TO_DISPLAY));
            }
        }

    }

    public void queryForCasesProfilesAndContact(List<Id> idsToQuery) {
        Set<Id> customerProfileIDs = Pluck.ids('Customer_Profile__c', this.cases);
            
        QueryBuilder caseQB = new QueryBuilder(Case.SObjectType, idsToQuery);
        QueryBuilder profileQB = new QueryBuilder(Customer_profile__c.SObjectType, new List<Id>(customerProfileIds));
        QueryBuilder contactQB = new QueryBuilder(Contact.SObjectType, new List<Id>{cases[0].ContactId});
        caseQB.addFieldsUsingFieldPaths(new List<String>(this.caseFieldApiNames)).orderBy('Customer_Profile__c', true);
        profileQB.addFields(this.profileFieldApiNames);
        contactQB.addFields(this.contactFieldApiNames);

        try {
            this.cases = (List<Case>) caseQB.runQuery();
            this.profiles = (List<Customer_profile__c>) profileQB.runQuery();
            this.contactForCases = (Contact) contactQB.runQuery()[0];
            this.placeHolderContact = new Contact();
        } catch (QueryException e) {
            //System.assert(false, e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVALID_FIELD + ': ' + e.getMessage()));
        }
    }
    
    public List<CaseContentWrapper> buildCaseWrappers (List<Case> cases, Map<Id, List<Customer_Onboarding_Field__c>> caseToOnboardingFields, Map<Id, Customer_profile__c> profileMap ){
        List<CaseContentWrapper> wrappers = new List<CaseContentWrapper>();
        //Set<ID> customerProfileID = new Set<ID>();    
        
        for(case c  : cases ) {
            //boolean duplicateProfile = customerProfileID.contains(c.Customer_Profile__c);
            //System.assert(false, c.Welcome_Packet_Sent_Date__c+' | '+c.Customer_Info_Form_Submitted_Date__c+' | '+caseToOnboardingFields.containsKey(c.ID)+' | '+profileMap.containsKey(c.Customer_profile__c));
            system.debug('caseToOnboardingFields.get(c.ID)==='+caseToOnboardingFields.get(c.ID));
            system.debug('c.Welcome_Packet_Sent_Date__c=='+c.Welcome_Packet_Sent_Date__c+'==caseToOnboardingFields.containsKey(c.ID)=='+caseToOnboardingFields.containsKey(c.ID)+'==profileMap.containsKey(c.Customer_profile__c)=='+profileMap.containsKey(c.Customer_profile__c));
            if(c.Welcome_Packet_Sent_Date__c != null //&& c.Customer_Info_Form_Submitted_Date__c == null
               && caseToOnboardingFields.containsKey(c.ID) && profileMap.containsKey(c.Customer_profile__c)) 
            {
                Boolean profileAlreadySeen = profileIdToWrapperWithOriginalProfile.containsKey(c.Customer_Profile__c);
                CaseContentWrapper ccwToAdd = new CaseContentWrapper(c, caseToOnboardingFields.get(c.ID), profileMap.get(c.Customer_Profile__c), profileAlreadySeen, language);
                wrappers.add(ccwToAdd);
                if (profileAlreadySeen)
                    profileIdToWrapperWithOriginalProfile.get(c.Customer_Profile__c).addMoreProfileModFields(ccwToAdd.modifiableProfileFields);
                else 
                    profileIdToWrapperWithOriginalProfile.put(c.Customer_Profile__c, ccwToAdd);
            }
        }
        return wrappers;
    }

    public void generateFieldsToQueryLists (Map<Id, List<Customer_Onboarding_Field__c>> caseToOnboardingFields){
        this.contactFields = new List<ModifiableField>();
        this.contactFieldApiNames = new Set<String>();
        this.caseFieldApiNames = new Set<String>{'Customer_ID__r.Name'};
        this.profileFieldApiNames = new Set<String>();
        
        for(List<Customer_Onboarding_Field__c> fieldsToMap : caseToOnboardingFields.values()) {
            for(Customer_Onboarding_Field__c field : fieldsToMap) {
                
                if (String.isBlank(field.Related_Object__c)){
                    caseFieldApiNames.add(field.Field_API_Name__c);
                } else if(field.Related_Object__c.equalsIgnoreCase('Customer_Profile__c')) {
                    profileFieldApiNames.add(field.Field_API_Name__c);
                } else if (field.Related_Object__c.equalsIgnoreCase('Contact') && !contactFieldApiNames.contains(field.Field_API_Name__c)) { 
                    contactFieldApiNames.add(field.Field_API_Name__c);
                    if (language == 'French')   
                        contactFields.add(new ModifiableField(field.Field_API_Name__c, field.Field_Display_Label_French__c, field.Related_Object__c));
                    else 
                        contactFields.add(new ModifiableField(field.Field_API_Name__c, field.Field_Display_Label__c, field.Related_Object__c));
                } 
            }
        }
        caseFieldApiNames.addAll(initialCaseFields);
    }
    
    public Boolean noFields {
        get {
            return ( (caseFieldApiNames==null || caseFieldApiNames.isEmpty())
                        && (contactFieldApiNames==null || contactFieldApiNames.isEmpty() )
                        && (profileFieldApiNames==null || profileFieldApiNames.isEmpty()) );
        }
        set;
    }
    
    public Boolean displayPage {
        get {
            return (!welcomeEmailNotSent) && (!formAlreadySubmittedForAllCases) && (!noFields);
        }
    }
    
    //DO WE NEED THIS?
    public String radioValue {
        get;set;
    }
    
    //DO WE NEED THIS?
    public String dummyInput {
        get;set;
    }

    //DO WE NEED THIS?
    public String getRecordName() {
        return 'Hello ' + (String)cases[0].get('name') + ' (' + (Id)cases[0].get('Id') + ')';
    }

    /*
    *  Updates the fields that the Customer has selected to be modified. ALSO CREATES CASE COMMENTS IF COMMENT SECTION IS FILLED
    */
   public void updateCases() {
        List<Customer_Profile__c> profilesToUpdate= new List<Customer_Profile__c>();
        List<Case> casesToUpdate = new List<Case>();
        List<CaseComment> caseCommentsToInsert = new List<CaseComment>();
        for(CaseContentWrapper ccw : caseWrappers) {
            List<ModifiableField> modifiedFields = new List<ModifiableField>();
            for (ModifiableField mf : ccw.modifiableCaseFields) {
                if (mf.newCheckBox) {
                    modifiedFields.add(mf);
                }
            }
            for (ModifiableField field : modifiedFields) {
                ccw.contentCase.put(field.fieldName, ccw.placeholderCase.get(field.fieldName));
            }
            
            ccw.contentCase.Customer_Info_Form_Submitted_Date__c = Datetime.now();
            if (!modifiedFields.isEmpty()){
                ccw.contentCase.Customer_Onboarding_Field_Change__c = Datetime.now();
                ccw.contentProfile.Address__c = ccw.contentCase.Address__c;
                ccw.contentProfile.Address_Line_2__c = ccw.contentCase.Address_Line_2__c;
                ccw.contentProfile.City__c = ccw.contentCase.City__c;
                ccw.contentProfile.State_Province__c = ccw.contentCase.State__c;
                ccw.contentProfile.Zip_Postal_Code__c = ccw.contentCase.Zip__c;
                ccw.contentProfile.DB_R_Service_Frequency__c= ccw.contentCase.DB_R_Service_Frequency__c;
                system.debug(ccw.contentCase.City__c+'+++++++++++ccw.contentProfile.City__c'+ccw.contentProfile.City__c);
                //Added by Gopi
                ccw.contentProfile.DB_R_Authorization_Number__c = ccw.contentCase.Authorization_Number__c;
                //ccw.contentProfile.Authorization_Number__c = ccw.contentCase.Authorization_Number__c;
                ccw.contentProfile.DB_R_Container_Quantity__c = ccw.contentCase.DP_Container_Quantity__c;
                //
                ccw.contentProfile.RM_Supply_Box_Order_Type__c = ccw.contentCase.RM_Supply_Box_Order_Type__c;
                ccw.contentProfile.RM_Supply_Box_Order_Qty__c = ccw.contentCase.RM_Supply_Box_Order_Qty__c;
                system.debug(ccw.contentCase.DP_Container_Quantity__c+'+++++++++++ccw.contentProfile.DB_R_Container_Quantity__c'+ccw.contentProfile.DB_R_Container_Quantity__c);
            }
            profilesToUpdate.add(ccw.contentProfile);    
            casesToUpdate.add(ccw.contentCase);
            if (!String.isBlank(ccw.comments) && ccw.comments != ccw.initialStateOfComments) {
                CaseComment newComment = new CaseComment();
                newComment.ParentId = ccw.contentCase.Id;
                newComment.CommentBody = ccw.comments;
                caseCommentsToInsert.add(newComment);
            }
        }
        if(!casesToUpdate.isEmpty()){
            try {
                executeUpdationInTrigger = false;
                update casesToUpdate;
            } catch (dmlexception e) {
                system.debug('errorMSG.... '+e.getMessage());
                system.assert(e.getMessage().contains('Update failed. First exception on ' +'row 0'),e.getMessage());
               // System.assert(false, e.getMessage());
                   ApexPages.addMessages(e);                   
            }
        }
        if(!caseCommentsToInsert.isEmpty()){
            try {
                executeUpdationInTrigger = false;
                insert caseCommentsToInsert;
            } catch (dmlexception e) {
                System.assert(false, e.getMessage());
                
                   ApexPages.addMessages(e);                   
            }
        }
        if(!profilesToUpdate.isEmpty()){
            try {
                executeUpdationInTrigger = false;
                update profilesToUpdate;
                       } catch (dmlexception e) {
                   ApexPages.addMessages(e);                   
            }
        }
    }
    
    public void updateProfiles() {
        List<Customer_Profile__c> profilesToUpdate= new List<Customer_Profile__c>();
        List<Case> casesToUpdate = new List<Case>();
        for(CaseContentWrapper ccw : caseWrappers) {
            List<ModifiableField> modifiedFields = new List<ModifiableField>();
            for (ModifiableField mf : ccw.modifiableProfileFields) {
                if (mf.newCheckBox) {
                    modifiedFields.add(mf);
                }
            }
            for (ModifiableField field : modifiedFields) {
                ccw.contentProfile.put(field.fieldName, ccw.placeholderProfile.get(field.fieldName));
            }
            
            if(!modifiedFields.isEmpty()) {
                profilesToUpdate.add(ccw.contentProfile);
                //additional functionality for updating the billing address in case record- anusha 19/4/2016
                if(ccw.contentCase.NCSP_Service_line__c == 'DB&R'){
                     ccw.contentCase.Billing_Address__c = ccw.contentProfile.Billing_Address__c;  
                     ccw.contentCase.Billing_City__c = ccw.contentProfile.Billing_City__c; 
                     ccw.contentCase.Billing_State_Province__c = ccw.contentProfile.Billing_State_Province__c; 
                     ccw.contentCase.Billing_Zip_Postal_Code__c = ccw.contentProfile.Billing_Zip_Postal_Code__c; 
                     ccw.contentCase.Authorization_Number__c = ccw.contentProfile.DB_R_Authorization_Number__c; 
                     ccw.contentCase.PO_Number__c = ccw.contentProfile.PO_Number__c;  
                     //Added by Gopi
                     ccw.contentCase.DP_Container_Quantity__c = ccw.contentProfile.DB_R_Container_Quantity__c;
                     //
                     ccw.contentCase.RM_Supply_Box_Order_Type__c = ccw.contentProfile.RM_Supply_Box_Order_Type__c;
                     ccw.contentCase.RM_Supply_Box_Order_Qty__c = ccw.contentProfile.RM_Supply_Box_Order_Qty__c;
                       
                 } else {
                    ccw.contentCase.Billing_Address__c = ccw.contentProfile.Billing_Address__c; 
                    ccw.contentCase.Billing_City__c = ccw.contentProfile.Billing_City__c; 
                    ccw.contentCase.Billing_State_Province__c = ccw.contentProfile.Billing_State_Province__c; 
                    ccw.contentCase.Billing_Zip_Postal_Code__c = ccw.contentProfile.Billing_Zip_Postal_Code__c; 
                
                 }
                ccw.contentCase.Customer_Onboarding_CP_Field_Change__c = Datetime.now();
                casesToUpdate.add(ccw.contentCase);
            }
        }
        if(!profilesToUpdate.isEmpty()){
            try {
                executeUpdationInTrigger = false;
                update profilesToUpdate;
                update casesToUpdate;
            } catch (dmlexception e) {
                   ApexPages.addMessages(e);                   
            }
        }
    }
    
    
    

    public void updateContact() {
        List<ModifiableField> modifiedFields = new List<ModifiableField>();
        for (ModifiableField mf : contactFields) {
            if (mf.newCheckBox) modifiedFields.add(mf);
        }
        for (ModifiableField field : modifiedFields) {
            contactForCases.put(field.fieldName, placeholderContact.get(field.fieldName));
        }
        if (!modifiedFields.isEmpty()) {
            for (Case c : cases) 
                c.Customer_Onboarding_Contact_Change__c = Datetime.now();
            try{
                executeUpdationInTrigger = false;
                update cases;
                update contactForCases;
            } catch (dmlexception e) {
                ApexPages.addMessages(e);
            }
        }
    }

    public PageReference submitForm() {
        
        updateProfiles();
        updateCases();
        updateContact();
        
        PageReference formCompletePage = new PageReference('/apex/customerinformationformcomplete?lang='+language);
        formCompletePage.setRedirect(true);
        return formCompletePage;
    }

    public class ModifiableField {
        public Boolean oldCheckBox { get;set; }

        public Boolean newCheckBox { get; set;}
        public String fieldName { get;set; }
        public String fieldLabel { get;set; }
        public String rObject { get;set; }

        public ModifiableField(String nameOfField, String labelOfField, String relatedObj) {
            oldCheckBox = true;
            newCheckBox = false;
            fieldName = nameOfField;
            fieldLabel = labelOfField;
            rObject = relatedObj;
        }
    }
    
    public class CaseContentWrapper{
        public List<ModifiableField> modifiableProfileFields {get;set;}
        public List<ModifiableField> modifiableCaseFields {get;set;}
        public Case contentCase {get;set;}
        public Case placeholderCase {get;set;}
        public Customer_Profile__c contentProfile {get;set;}
        public Customer_Profile__c placeholderProfile{get;set;}
        public String comments{get;set;}
        public boolean displayCustomerProfile{get;set;}
        public boolean first{get;set;}
        public boolean editAccess {get;set;}
        @testVisible private String initialStateOfComments;

        //private
        Set<String> profileFieldUniqueSet = new Set<String>();
        
        public CaseContentWrapper (Case c, 
                                    List<Customer_Onboarding_Field__c> customerOnboardingFields,
                                    Customer_Profile__c profile, 
                                    boolean duplicateProfile, 
                                    String lang) {
            contentCase = c;
            buildModFields(customerOnboardingFields, lang);
            comments = initialStateOfComments;
            placeholderCase = new Case();
            system.debug('++++====123'+placeholderCase);
            //placeholderCase.DB_R_Service_Frequency__c =
            placeholderProfile = new Customer_Profile__c();
            contentProfile = profile;
            displayCustomerProfile = !duplicateProfile && profile!=null;
            editAccess = c.Customer_Info_Form_Submitted_Date__c == null && 
                            c.Service_Order_Date__c == null && 
                            c.Initial_Supply_Order_Date__c == null;
            first = FormController.staticIndex==0;
            FormController.staticIndex++;
            
        }
        public void buildModFields(List<Customer_Onboarding_Field__c> onboardingFields, String language){
            this.modifiableProfileFields = new List<ModifiableField>();
            this.modifiableCaseFields = new List<ModifiableField>();
            List<String> commentLabels = new List<String>();
            
            for(Customer_Onboarding_Field__c field : onboardingFields) {
                if (String.isBlank(field.Related_Object__c)) {
                    if (language == 'French') 
                        modifiableCaseFields.add(new ModifiableField(field.Field_API_Name__c, field.Field_Display_Label_French__c, ''));
                    else 
                        modifiableCaseFields.add(new ModifiableField(field.Field_API_Name__c, field.Field_Display_Label__c, ''));
                } else if (field.Related_Object__c.equalsIgnoreCase('Customer_Profile__c')){
                    profileFieldUniqueSet.add(field.Field_API_Name__c);
                    if (language == 'French') 
                        modifiableProfileFields.add(new ModifiableField(field.Field_API_Name__c, field.Field_Display_Label_French__c, field.Related_Object__c));
                    else 
                        modifiableProfileFields.add(new ModifiableField(field.Field_API_Name__c, field.Field_Display_Label__c, field.Related_Object__c));
                } else if (field.Related_Object__c.equalsIgnoreCase('CaseComment')){
                    if (language == 'French') 
                        commentLabels.add(field.Field_Display_Label_French__c);
                    else 
                        commentLabels.add(field.Field_Display_Label__c);
                }
            }
            if (commentLabels.isEmpty())
                initialStateOfComments = '';
            else
                initialStateOfComments = String.join(commentLabels, '?\n') + '?\n';
        }

        public void addMoreProfileModFields(List<ModifiableField> moreProfFields) {
            for (ModifiableField mf : moreProfFields) {
                if (!profileFieldUniqueSet.contains(mf.fieldName)) {
                    this.modifiableProfileFields.add(mf);
                    profileFieldUniqueSet.add(mf.fieldName);
                }
            }
        }
    }
    
}
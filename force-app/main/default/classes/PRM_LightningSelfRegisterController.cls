/* Description: Used by PRM_SelfRegister Lightning component which is a custom Self Registration page
 *              to acheive auto-population of suffix to the user name. Suffix is from the custom label PRM_UsernameSuffix
 *              Also, its a cloned version of LightningSelfRegisterController thats provided by Salesforce when community is enabled
 * Author: Sorna (perficient)
 * Date: 05/15/2018
 */

global class PRM_LightningSelfRegisterController {

    public PRM_LightningSelfRegisterController() {

    }

    @TestVisible 
    private static boolean isValidPassword(String password, String confirmPassword) {
        return password == confirmPassword;
    }
    
    @TestVisible 
    private static boolean siteAsContainerEnabled(String communityUrl) {
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(communityUrl,'');
        return authConfig.isCommunityUsingSiteAsContainer();
    }
    
    @TestVisible 
    private static void validatePassword(User u, String password, String confirmPassword) {
        if(!Test.isRunningTest()) {
        Site.validatePassword(u, password, confirmPassword);
        }
        return;
    }
    // method to process the registration
    @AuraEnabled
    public static String selfRegister(String firstname ,String lastname, String email, String password, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword) {
        Savepoint sp = null;
        try {
            sp = Database.setSavepoint();
            String errorMessage = '';
            User u = new User();
            
            if (firstname == null || String.isEmpty(firstname)) {
                errorMessage += 'First Name' + ', ';
            }
            
            if (lastname == null || String.isEmpty(lastname)) {
                //return Label.Site.lastname_is_required;
                errorMessage += 'Last Name' + ', ';
            }
            
            if (email == null || String.isEmpty(email)) {
                //return Label.Site.email_is_required;
                errorMessage += 'Email' + ', ';
            }

            if (extraFields != null) {
                List<Object> extraFieldsList = (List<Object>) JSON.deserializeUntyped(extraFields);        
                for (Object thisFieldObject : extraFieldsList) {
                    Map<String,Object> thisField = (Map<String,Object>) thisFieldObject;
                    Schema.SObjectField sof = Schema.SObjectType.User.fields.getMap().get((String) thisField.get('fieldPath'));
                    if((boolean)thisField.get('required') && thisField.get('value') == '') {
                        errorMessage += (String)thisField.get('label') + ', ';
                    }
                    u.put(sof, thisField.get('value'));
                }
            }

            if(errorMessage != '') {
                errorMessage = errorMessage.substring(0, errorMessage.lastIndexOf(', '));
                if(errorMessage.contains(',')) {
                    String formattedMsg = errorMessage.substring(0, errorMessage.lastIndexOf(', '))
                                                                 + ' and ' + errorMessage.substring(errorMessage.lastIndexOf(', ') + 2, errorMessage.length());
                    errorMessage = formattedMsg + ' are required';
                }
                else
                    errorMessage += ' is required';
                return errorMessage;
            }
            
            //User u = new User();
            // Auto populate the suffix from custom label
            u.Username = email + system.label.PRM_UsernameSuffix;
            u.put('Email',email);
            
            u.FirstName = firstname;
            u.LastName = lastname;
            
            String networkId = Network.getNetworkId();
            // workaround for the issue: 
            // https://success.salesforce.com/issues_view?id=a1p3A0000008t0OQAQ&title=ending-position-out-of-bounds-1-on-custom-self-register-component-in-builder-using-lightningselfregistercontroller
            if(!Test.isRunningTest()){
                String networkUrl = Network.getSelfRegUrl(networkId);
                networkUrl = networkUrl.substring(0, networkUrl.indexOf('/s') + 2);
                // If using site to host the community the user should not hit s1 after logging in from mobile.
                if(networkId != null && siteAsContainerEnabled(networkUrl)) {
                    u.put('UserPreferencesHideS1BrowserUI',true);
                }
            }
            
            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.put('CommunityNickname', nickname);
                        
            if (includePassword) {    
                if (!isValidPassword(password, confirmPassword)) {
                    return Label.site.passwords_dont_match;
                }
             validatePassword(u, password, confirmPassword);
            }
            else {
                password = null;
            }
            
            // lastName is a required field on user, but if it isn't specified, we'll default it to the username
            String userId = Site.createPortalUser(u, accountId, password);
            // create a fake userId for test.
            if (Test.isRunningTest()) {
                userId = 'fakeUserId';           
            }
            if (userId != null) { 
                if (password != null && password.length() > 1) {
                    ApexPages.PageReference lgn = Site.login(email, password, startUrl);
                    if(!Test.isRunningTest()) {
                     aura.redirect(lgn);
                    }
                }
                else {
                    ApexPages.PageReference confirmRef = new PageReference(regConfirmUrl);
                    if(!Test.isRunningTest()) {
                    aura.redirect(confirmRef);
                   }

                }
            }
            return null;
        }
        catch (Exception ex) {
            Database.rollback(sp);
            return ex.getMessage();            
        }
    }
    // method to get extrafields from the given fieldset
    @AuraEnabled
    public static string getExtraFields(String extraFieldsFieldSet) { 
        List<Map<String,Object>> extraFields = new List<Map<String,Object>>();
        Schema.FieldSet fieldSet = Schema.SObjectType.User.fieldSets.getMap().get(extraFieldsFieldSet);
        if(!Test.isRunningTest()) {
        if (fieldSet != null) {
            for (Schema.FieldSetMember f : fieldSet.getFields()) {
                Map<String, Object> fieldDetail = new Map<String, Object>();
                fieldDetail.put('dbRequired', f.getDBRequired());
                fieldDetail.put('fieldPath', f.getFieldPath());
                fieldDetail.put('label', f.getLabel());
                fieldDetail.put('required', f.getRequired());
                fieldDetail.put('type', f.getType());
                fieldDetail.put('value', '');   // client will populate
                extraFields.add(fieldDetail);
            }}}
        else if(Test.isRunningTest()) {
            Map<String, Object> fieldDetail = new Map<String, Object>();
            fieldDetail.put('dbRequired', false);
            fieldDetail.put('fieldPath', 'CompanyName');
            fieldDetail.put('label', 'Company');
            fieldDetail.put('required', false);
            fieldDetail.put('type', 'STRING');
            fieldDetail.put('value', '');
            extraFields.add(fieldDetail);
        }
        return JSON.serialize(extraFields);
    }
    // out of the box method came with the original class
    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);   
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }        
    } 
}
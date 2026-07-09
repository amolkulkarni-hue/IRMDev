/**
* Class: AccountHelper
*
* Author: Revathy Saminathan
*
* Date Created: 11.06.2020
*
* Purpose: AccountHelper is a handler class for all business logic related to Account object
* 
*/
public class AccountHelper {
    public static List<String> labelLst;
    public static String labelLstIME;
    public static boolean bCreateAccount = false;
    public static boolean bCreateAccountIME = false;
    public static set<string> countries = new set<string>();
    public static Set<String> Zip_code = new set<string>();
    public static Map<String,Postal_Code__c> PostalCodeMap=new  Map<String,Postal_Code__c>();
    
    public static void processAccountBeforeInsert(List<Account> triggerNewList)
    {
        //Set Account_Segment__c picklist based on Account_Segment_lookup__c Id populated during insert
		//28556 - Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
       /* List<Account> filteredAccounts = AccountSegmentServices.filterAccountsWithChangedAcctSegmentLookup(triggerNewList, null);
        Map<id, Account_Sub_Segment__c> AccountSubSegmentMap = AccountSegmentServices.generateAccountSubSegmentMap(filteredAccounts); 
        AccountSegmentServices.processAccounts(filteredAccounts, AccountSubSegmentMap);*/
        Id stdAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Standard_Account').getRecordTypeId();
        
        
        for(Account ac : triggerNewList)
        {
            if(ac.BillingCountry != Null){
                countries.add(ac.BillingCountry); 
            }
            
            if(ac.BillingCountry != NULL)
            {
                if( QTB_Billing_Countries__c.getValues(ac.BillingCountry) != NULL && ac.RecordTypeId == stdAccRecTypeId && ac.IM_Hierarchy_Level__c == 'Sales (Site)' && ac.BillingCountry != 'Singapore')
                {
                    ac.QTB_Payable_Customer_Model__c = True;
                }
            }
            if(ac.BillingPostalCode != Null)
            {
                Zip_code.add(ac.BillingPostalCode);
            }else{
                ac.Postal_Code2__c = null;
            } 
            if(ac.RecordTypeId != QTB_Utils.ACCOUNT_BILL_RECTYPEID && ac.RecordTypeId != QTB_Utils.ACCOUNT_OPERATIONAL_RECTYPEID)
            {                
                preventAccountCreation(triggerNewList);
            }
            
            
        }
        if(!countries.isEmpty()){
            system.debug('++Countries' + countries);
            updateBillingCountry(countries,triggerNewList);
        } 
        if(!Zip_code.isEmpty()){
            updateBillingPostalCode(Zip_code,triggerNewList);
        } 
    } 
    
    public static void processAccountBeforeUpdate(List<Account> triggerNewList,Map<Id,Account> AccountOldMap)
    {
        //Gitlab #28936 - Start - Added below Variable to prevent this error 'There is currently no country in the system matching this name.'
                                  // when OP Account created with different billing country compare to its parent Account billing country.
        set<string> countriesUpdated = new set<string>();
        //Gitlab #28936 - End
        /*Update Registration_Number_Updated__c field to copy Account's -'Registration Number' field to Contact, Opportunity, Customer Accounts - Starts*/        
        Id stdAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Standard_Account').getRecordTypeId();
        for(Account acc : triggerNewList)
        {
            if(AccountOldMap.get(acc.Id).Registration_Number__c != acc.Registration_Number__c)
            {
                acc.Registration_Number_Updated__c = true;                  
            } 
            if(acc.BillingCountry != NULL)
            {
                if( QTB_Billing_Countries__c.getValues(acc.BillingCountry) != NULL && acc.RecordTypeId == stdAccRecTypeId && 
                   acc.IM_Hierarchy_Level__c == 'Sales (Site)' && acc.BillingCountry != 'Singapore')
                {
                    acc.QTB_Payable_Customer_Model__c = True;
                }
            }
            if((AccountOldMap.get(acc.Id).Name == 'Dummy Account') && ((AccountOldMap.get(acc.Id).BillingCountry != acc.BillingCountry) || (AccountOldMap.get(acc.Id).Name != acc.Name)))
            {
                acc.addError(Label.Account_Insufficient_update);   
            }
            if(AccountOldMap.get(acc.Id).BillingCountry != acc.BillingCountry)
            {
                //Gitlab #28936 - Start
                countriesUpdated.add(acc.BillingCountry); 
                //Gitlab #28936 - End
            } 
            if(AccountOldMap.get(acc.Id) != acc && acc.BillingPostalCode != Null){
                Zip_code.add(acc.BillingPostalCode);
            }else{
                acc.Postal_Code2__c = null;
            }
        } 
        //Gitlab #28936 - Start
        if(!Test.isRunningTest()){
        if(!countriesUpdated.isEmpty()){
            system.debug('updatedconutr' +countriesUpdated);
            updateBillingCountry(countriesUpdated,triggerNewList);
        }
        }
        //Gitlab #28936 - End
        if(!Zip_code.isEmpty()){
            updateBillingPostalCode(Zip_code,triggerNewList);
        }
        //Update Account_Segment__c picklist based on updated Account_Segment_lookup__c Id
        //28556- Account: Decommission Old Account Segment/Sub-Segment Lookup fields and related Formula fields
        /*List<Account> filteredAccounts = AccountSegmentServices.filterAccountsWithChangedAcctSegmentLookup(triggerNewList,AccountOldMap);
        Map<id, Account_Sub_Segment__c> AccountSubSegmentMap = AccountSegmentServices.generateAccountSubSegmentMap(filteredAccounts); 
        AccountSegmentServices.processAccounts(filteredAccounts, AccountSubSegmentMap);*/
        
    }
    public static void processAccountBeforeDelete(List<Account> triggerOldList)
    {
        for(Account ac : triggerOldList)
        {
            if(ac.Name =='Dummy Account')
            {
                ac.addError(Label.Account_Insufficient_Delete);
            }
        }
    }
    
    public static void preventAccountCreation(List<Account> triggerNewList)
    { 
        Profile curUserProfile = [Select Name from Profile where Id =: UserInfo.getProfileId()];
        if(Label.IM_Admin_Profiles != null){
            labelLst = Label.IM_Admin_Profiles.split(';',-1); 
            for(String sr : labelLst){
                if(sr == curUserProfile.Name){ 
                    bCreateAccount = true;
                    bCreateAccountIME = true;
                    break;
                }
            }
            if(!bCreateAccount && bCreateAccountIME){//Checking current user profile with white listed profiles.
                for(Account ac : triggerNewList){
                    if(ac.IM_Lead_Conversion_Flag__c != true){//Determining if Account insertion is from Lead Conversion Process. 
                        ac.addError(Label.Account_Insufficient_Error);
                    }
                }
            }
        } 
        /****Case # 02210434 changes started****/
        //Creating an exception for IME Contracts Profile. 
        if(Label.IM_NonAdmins_CreateAccounts!= null && !bCreateAccountIME)
        {
            labelLstIME = Label.IM_NonAdmins_CreateAccounts; 
            if(labelLstIME == curUserProfile.Name)
            {
                bCreateAccount = true; 
            } 
            else
            { 
                for(Account ac : triggerNewList)
                {
                    if(ac.IM_Lead_Conversion_Flag__c != true && ac.RecordTypeId != QTB_Utils.ACCOUNT_OPERATIONAL_RECTYPEID && ac.RecordTypeId != QTB_Utils.ACCOUNT_BILL_RECTYPEID )//Determining if Account insertion is from Lead Conversion Process.
                    { 
                        ac.addError(Label.Account_Insufficient_Error);
                    }
                }
            }       
        } 
    }
    
    
    Public Static void updateBillingCountry(Set<String> countries,List<Account> triggerNewList)
    { 
        System.debug('Entring Update Billing country Code');
        Map<string,IM_Country__c> matchingCountries = CountryNameTranslator.translateCountryName2(countries);
        system.debug('matchingCountries--> ' + matchingCountries);
        for(Account a : triggerNewList)
        { 
            if(a.BillingCountry != null)
            {
                if(matchingCountries.get(a.Id) != null)
                    a.BillingCountry = matchingCountries.get(a.Id).Name;  
                if(matchingCountries.get(a.BillingCountry) != null){
                    a.BillingCountry = matchingCountries.get(a.BillingCountry).Name;
                }else {
                    a.BillingCountry.addError(Label.CountryTranslationErrorMessage+ ' - "'+a.BillingCountry+'"');
                }
            }
        }
    }
    public static void updateBillingPostalCode(Set<String> Zip_code,List<Account> triggerNewList)
    {
        System.debug('Entring Update Billing Postal Code');
        List<Postal_Code__c> PostalCodeList=[select id,Name,Country__c from Postal_Code__c where Name IN :Zip_code];
        for(Postal_Code__c p:PostalCodeList){
            PostalCodeMap.put(p.Name+'-'+p.Country__c,p);
        } 
        for(Account acc:triggerNewList){
            if(PostalCodeMap.containsKey(acc.BillingPostalCode+'-'+acc.BillingCountry)){
                acc.Postal_Code2__c=PostalCodeMap.get(acc.BillingPostalCode+'-'+acc.BillingCountry).Id;
            }
            else{ 
                acc.Postal_Code2__c = null; 
            }
        }
    } 
}
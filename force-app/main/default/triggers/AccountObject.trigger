/*COMBINATION OF TWO TRIGGERS ON ACCOUNT OBJECT 
**IN REFERNCE TO CASE 00924109
**AUTHOR: SRINIVASA RAO MANDALAPU
**DATE: 11/14/2012

Updated the Trigger to allow IME Contracts to create new accounts through Accounts Tab. This is in REFERENCE to 
Case # 02210434.
AUTHOR :- APURVA DUTTA
Date - 3/7/2014

Updated Trigger to Flag as Recall Accounts if Accounts's Billing city is Recall flagged city
Case # 05049974
Author : Vinutha Iyengar
Date : 27/04/2016

Updated Trigger to Prevent the Dummy Account used for CS being deleted or having country value changed
Case # 04773247 
Author : Vinutha Iyengar
Date : 06/05/2016

Update Trigger to remove "RealignRateTableOwner" functionality as part of Q2W decommission
Case # 09517433
Author : Vinutha Iyengar
Date : 11/02/2019

Updated Trigger to update Registration_Number_Updated__c field. Based on this field, Batch job executes to copy Account's - 'Registration Number' field to Contact, Opportunity, Customer Accounts
Case # 05119686 
Author : Vinutha Iyengar
Date : 06/Feb/2019

Update Trigger to remove "Tier 1, FlagRecallAccountByCity" functionality
Case # 09438409 
Author : Vinutha Iyengar
Date : 06/May/2019
*/
trigger AccountObject on Account (after insert, before insert, before update, before delete) {
    /****Variable declaration for 'preventAccountCreateTrigger' Trigger****/
   /* public String preventAccountCreateTrigger = null;
    public Boolean runpreventAccountCreateTrigger = false;
    boolean bCreateAccount = false;
    boolean bCreateAccountIME = false;
    List<String> labelLst;
    String labelLstIME;
    
    /****Variable declaration for 'AccountCountryLookup' Trigger****/
  /*  public String AccountCountryLookup = null;
    public Boolean runAccountCountryLookup = false;
    set<string> countries = new set<string>();
    
    /****Variable declaration for 'AccountPostalCode' Trigger****/
 /*   public String AccountPostalCode = null;
    public Boolean runAccountPostalCode = false;
    Set <String> Zip_code = new set <string>();
    Map<String,Postal_Code__c> PostalCodeMap=new  Map<String,Postal_Code__c>();
    public string BlockDummyAccountEdit='false';
    public string copyAccountRegNo='false';
    
    /***Retrieving Custom Settings***/
  /*  List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Account'){
            if(cs.Trigger__c == 'preventAccountCreateTrigger') {
                preventAccountCreateTrigger = cs.Value__c;    
            }
            if(cs.Trigger__c == 'AccountCountryLookup') {
                AccountCountryLookup = cs.Value__c;    
            }
            if(cs.Trigger__c == 'AccountPostalCode') {
                AccountPostalCode = cs.Value__c;    
            }
            if(cs.Trigger__c == 'BlockDummyAccountEdit') {
                BlockDummyAccountEdit= cs.Value__c.toLowerCase();    
            }
            if(cs.Trigger__c == 'CopyRegToRelatedObjects'){
                copyAccountRegNo=cs.Value__c;
          }
      }
  }
    /*****************************************START TRIGGER*************************************************/

    /*****************************************BEFORE INSERT AND UPDATE*************************************/
  /***  if(Trigger.isBefore){
        if(Trigger.isInsert){
            runAccountCountryLookup = true;
            runAccountPostalCode = true;
            /****preventAccountCreateTrigger****/
            /*---start---*/
           /** if(preventAccountCreateTrigger == 'True'){
                Profile curUserProfile = [Select Name from Profile where Id =: UserInfo.getProfileId()];
                System.debug('----22----curUserProfile:'+curUserProfile );
                System.debug('------23----Label.IM_Admin_Profiles: '+ Label.IM_Admin_Profiles);
                if(Label.IM_Admin_Profiles != null){
                    labelLst = Label.IM_Admin_Profiles.split(';',-1);
                    System.debug('----26------labelLst: '+ labelLst );
                    for(integer i = 0 ; i < labelLst.size() ; i++){
                            if(labelLst[i] == curUserProfile.Name){
                                bCreateAccount = true;
                                bCreateAccountIME = true;
                                break;
                            }
                    }
                    if(!bCreateAccount && bCreateAccountIME){//Checking current user profile with white listed profiles.
                        for(Integer i=0; i<Trigger.new.size(); i++){
                            if(Trigger.new[i].IM_Lead_Conversion_Flag__c != true){//Determining if Account insertion is from Lead Conversion Process. 
                                Trigger.new[0].addError('Insufficient Privileges to create new Account');
                            }
                        }
                    }
                } 
                /****Case # 02210434 changes started****/
                //Creating an exception for IME Contracts Profile. 
        /**        if(Label.IM_NonAdmins_CreateAccounts!= null && !bCreateAccountIME)
                {
                    labelLstIME = Label.IM_NonAdmins_CreateAccounts;

                        if(labelLstIME == curUserProfile.Name)
                        {
                            bCreateAccount = true;
                            
                        }
                    
                        else
                            {
                            System.debug('---11--labelLstIME:');
                                    for(Integer i=0; i<Trigger.new.size(); i++)
                                    {
                                        if(Trigger.new[i].IM_Lead_Conversion_Flag__c != true)//Determining if Account insertion is from Lead Conversion Process.
                                        { 
                                            Trigger.new[0].addError('Insufficient Privileges to create new Account');
                                        }
                                    }
                            }       
                }/****Case # 02210434 changes Finished****/
                
          /**}*/
            /****preventAccountCreateTrigger****/
            /*---End---*/

            //Set Account_Segment__c picklist based on Account_Segment_lookup__c Id populated during insert
           /** List<Account> filteredAccounts = AccountSegmentServices.filterAccountsWithChangedAcctSegmentLookup(Trigger.new, null);
            Map<id, Account_Sub_Segment__c> AccountSubSegmentMap = AccountSegmentServices.generateAccountSubSegmentMap(filteredAccounts);

            AccountSegmentServices.processAccounts(filteredAccounts, AccountSubSegmentMap);
        }
        if(Trigger.isUpdate){
            runAccountCountryLookup = true;
            runAccountPostalCode = true;

            //Update Account_Segment__c picklist based on updated Account_Segment_lookup__c Id
            List<Account> filteredAccounts = AccountSegmentServices.filterAccountsWithChangedAcctSegmentLookup(Trigger.new, Trigger.oldMap);
            Map<id, Account_Sub_Segment__c> AccountSubSegmentMap = AccountSegmentServices.generateAccountSubSegmentMap(filteredAccounts);

            AccountSegmentServices.processAccounts(filteredAccounts, AccountSubSegmentMap);

        }     
        
    }
    /*************************************END OF BEFORE INSERT AND UPDATE***************************/
    
    /****AccountCountryLookup****/
    /*---start---*/
     /*if(AccountCountryLookup == 'True'){
        if(runAccountCountryLookup==true){
            
            system.debug('+++++++++executing AccountCountryLookup trigger++++++++');
            for(Account a : Trigger.new){
                if(a.BillingCountry != null)
                    countries.add(a.BillingCountry);
                    System.debug('---19---countries:'+countries);
            }     
            Map<string,IM_Country__c> matchingCountries = CountryNameTranslator.translateCountryName2(countries);
            System.debug('---19---matchingCountries:'+matchingCountries);
             
            for(Account a : Trigger.new)
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
     }     
    /****AccountCountryLookup****/
    /*---End---*/
    
    /****AccountPostalCode****/
    /*---start---*/
    /** if(AccountPostalCode == 'True'){
        if(runAccountPostalCode==true){
               system.debug('+++++++++executing AccountCountryLookup trigger++++++++');
                //Creation of set of Billing Postal Code from Account.
                for (Account acc:trigger.new)
                {
                    if(acc.BillingPostalCode !=null && (Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(acc.id)!=Trigger.NewMap.get(acc.id)))){
                        Zip_code.add(acc.BillingPostalCode);
                         
                    }else{
                        acc.Postal_Code2__c = null;
                    }
                }
                system.debug('++++++++++zip codes+++++++++++'+Zip_code);
                if(!Zip_code.isEmpty()) {
                    List<Postal_Code__c> PostalCodeList=[select id,Name,Country__c from Postal_Code__c where Name IN :Zip_code];
                    for(Postal_Code__c p:PostalCodeList){
                        PostalCodeMap.put(p.Name+'-'+p.Country__c,p);
                    }
                    system.debug('++++++++++++postal code map+++++++++'+PostalCodeMap);
                    for(Account acc:trigger.new){
                        if(PostalCodeMap.containsKey(acc.BillingPostalCode+'-'+acc.BillingCountry)){
                            acc.Postal_Code2__c=PostalCodeMap.get(acc.BillingPostalCode+'-'+acc.BillingCountry).Id;
                        }
                        else{
                             system.debug('++++++++++there was no matching for this postal code so changing lookup to null+++++'); 
                             acc.Postal_Code2__c = null; 
                        }
                    }
                }     
         }
     }
    /****AccountPostalCode****/
     
    /*---End---*/
    
    //Case No - 04773247 
    //Prevent the Dummy Account & Dummy Contact records used for CS being deleted or having country value changed    
  /**  if(BlockDummyAccountEdit=='true')
    {
        if(Trigger.isBefore)
        {    
            if(trigger.isUpdate)
            {
                for(Account acc1 : Trigger.New)
                {
                    if((Trigger.oldMap.get(acc1.Id).Name == 'Dummy Account') && ((Trigger.oldMap.get(acc1.Id).BillingCountry != acc1.BillingCountry) || (Trigger.oldMap.get(acc1.Id).Name != acc1.Name)))
                    {
                        acc1.addError('Insufficient privileges to update the record.');   
                    }
                }
            
            }      
            if(Trigger.isDelete)
            {
                for(Account a : Trigger.old)
                {
                    if(a.Name =='Dummy Account')
                    {
                        a.addError('Insufficient privileges to delete Account.');
                    }
                }
            }
        }
    }
    
    /*Update Registration_Number_Updated__c field to copy Account's -'Registration Number' field to Contact, Opportunity, Customer Accounts - Starts*/
    /**if(copyAccountRegNo=='True' )
    {
        if(Trigger.isBefore && Trigger.isUpdate)
        {
            for(Account acct : Trigger.New)
            {
                if(Trigger.oldMap.get(acct.id).Registration_Number__c != Trigger.newMap.get(acct.id).Registration_Number__c)
                {  
                    acct.Registration_Number_Updated__c = true;
                }
            }
        }
    }*/
    
    /**************************************************END TRIGGER*********************************************/  
}
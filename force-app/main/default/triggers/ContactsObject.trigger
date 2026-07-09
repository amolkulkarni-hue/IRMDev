/*

Updated Trigger to Prevent the Dummy Contact used for CS being deleted or having country value changed
Case # 04773247 
Author : Vinutha
Date : 06/05/2016

*/

trigger ContactsObject on Contact (before delete, before insert, before update) {
    public String ContactCountryLookup=null;
    public String preventContactDelete=null; 
    Boolean runContactCountryLookup=false;
    Boolean runpreventContactDelete=false;
    public string BlockDummyContactEdit='false';
    
  List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
  for(Trigger_Activation_Settings__c cs : customsettings){
      if(cs.Object__c=='Contact'){
            if(cs.Trigger__c == 'ContactCountryLookup') {
            ContactCountryLookup = cs.Value__c;
            }
            if(cs.Trigger__c == 'preventContactDelete') {
              preventContactDelete = cs.Value__c;    
            }
            if(cs.Trigger__c == 'BlockDummyContactEdit') {
                BlockDummyContactEdit= cs.Value__c.toLowerCase();    
            }
        
      }
  }
  if(Trigger.isBefore){
        if(Trigger.isInsert||Trigger.isUpdate){
            if(ContactCountryLookup=='True')
            runContactCountryLookup=true;
            
        }
        if(Trigger.isDelete){
            if(preventContactDelete=='True')
            runpreventContactDelete=true;
        }
   }
   if(runContactCountryLookup){
       system.debug('++++++++ContactCountryLookup trigger++++++++');
         
         set<string> countries = new set<string>();
         for(Contact c : Trigger.new)
         {
             if(c.MailingCountry != null)
             countries.add(c.MailingCountry);
         }
         Map<string,IM_Country__c> matchingCountries = CountryNameTranslator.translateCountryName2(countries);
         for(Contact c : Trigger.new)
         { 
               if(c.MailingCountry != null)
               {
                if(matchingCountries.get(c.MailingCountry) != null)
                   c.MailingCountry= matchingCountries.get(c.MailingCountry).Name;
                else
                   c.MailingCountry.addError(Label.CountryTranslationErrorMessage);
               }
         }
    }
    if(runpreventContactDelete){
        system.debug('+++++++executing preventContactDelete Trigger+++++++');
            Profile curUserProfile = [Select Name from Profile where Id =: UserInfo.getProfileId()];
            if(Label.IM_Admin_Profiles != null && !Label.IM_Admin_Profiles.contains(curUserProfile.Name)){//Checking current user profile with white listed profiles.
                for(Integer i=0; i<Trigger.old.size(); i++){
                    Trigger.old[0].addError('Insufficient privileges to delete Contact.');
                }
            }
   }
   
   //Case No - 04773247 
    //Prevent the Dummy Account & Dummy Contact records used for CS being deleted or having country value changed    
    system.debug('BlockDummyContactEdit=='+BlockDummyContactEdit);
    if(BlockDummyContactEdit=='true')
    {
        if(Trigger.isBefore)
        {    
            Id dummyContId=Label.Dummy_Contact_Id;
            
            if(trigger.isUpdate)
            {
                for(Contact cont : Trigger.New)
                {
                    system.debug('Trigger.oldMap.get(cont.Id).Name =='+Trigger.oldMap.get(cont.Id).Firstname);
                    if(cont.Id == dummyContId) 
                    if((Trigger.oldMap.get(cont.Id).MailingCountry != cont.MailingCountry ) || (Trigger.oldMap.get(cont.Id).Firstname != cont.Firstname ) ||(Trigger.oldMap.get(cont.Id).LastName != cont.LastName) || (Trigger.oldMap.get(cont.Id).Phone!= cont.Phone))
                    {
                        cont.addError('Insufficient privileges to update the record.');   
                    }
                }
            
            }      
            if(Trigger.isDelete)
            {
                for(Contact cont : Trigger.old)
                {
                    if(cont.Id == dummyContId)
                    {
                        cont.addError('Insufficient privileges to delete Contact.');
                    }
                }
            }
        }
    }
}
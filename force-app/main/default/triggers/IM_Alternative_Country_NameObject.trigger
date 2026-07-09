/*Developer Name: Madhu Paladugu
  Company       : TheCloudFountain Inc.
  Desrciption   :  Used to ensure that a copy of the IM Country name exists in the IM_Alternative_Country_Name__c.
  Date          : 12/3/12
  case number   : 00924109   */
trigger  IM_Alternative_Country_NameObject on IM_Alternative_Country_Name__c (before delete, before update) {
   public String IM_Alternative_Country_Name_Manager=null;
   Boolean runIM_Alternative_Country_Name_Manager=false;
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    system.debug('+++++++++customsettings ++++++++++'+customsettings );
     for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c =='IM_Alternative_Country_Name__c') {
            if(cs.Trigger__c == 'IM_Alternative_Country_Name_Manager'){
          IM_Alternative_Country_Name_Manager=cs.Value__c;
        }
        }
     }
    if(Trigger.isBefore){
        if(Trigger.isDelete || Trigger.isUpdate){
            if(IM_Alternative_Country_Name_Manager=='True')
            runIM_Alternative_Country_Name_Manager=true;
        }
    }
    if(runIM_Alternative_Country_Name_Manager){
    system.debug('++++++++++++++executing IM_Alternative_Country_Name_Manager trigger+++++');
       set<id> imCountryIds = new set<id>();
       for(IM_Alternative_Country_Name__c acn : trigger.old)
          imCountryIds.add(acn.IM_Country__c );
       map<id,IM_Country__c> parentCountry = new map<id,IM_Country__c>();
      for(IM_Country__c c : [select id, Name from IM_Country__c where id in :imCountryIds])
          parentCountry.put(c.id, c);
      if(Trigger.isDelete)
      {
        for(IM_Alternative_Country_Name__c acn : trigger.old)
        {
          if(parentCountry.get(acn.IM_Country__c).id == acn.IM_Country__c
           && trigger.oldMap.get(acn.Id).Alternative_Name__c == parentCountry.get(acn.IM_Country__c).Name )
           acn.addError('Cannot Delete the Alternative Country Name Record that matches the Parent Country Record.');
        }
      }
    else
    {
    //if changing the name of the parent, IM_Country's IM_Alternative_Country_Name clone, throw an error.
    for(IM_Alternative_Country_Name__c acn : trigger.new)
    {
      if(parentCountry.get(acn.IM_Country__c).id == acn.IM_Country__c
         && trigger.oldMap.get(acn.Id).Alternative_Name__c == parentCountry.get(acn.IM_Country__c).Name
         && parentCountry.get(acn.IM_Country__c).Name != acn.Alternative_Name__c  )
         acn.addError('Cannot Change the Alternative Country Name Record that matches the Parent Country Record.');
    }
   }
  }
}
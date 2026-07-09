/*Developer Name: Madhu Paladugu
  Company       : TheCloudFountain Inc.
  Desrciption   :  Used to ensure that a copy of the IM Country name exists in the IM_Alternative_Country_Name__c.
  Date          : 12/3/12
  case number   : 00924109   */
 
trigger  IM_CountryObject on IM_Country__c (after insert,after update) {
 //change the event from "befor update" to "after update" to remove error while updatinh the child recods of altenativ ecountry record.
 public String IM_Country_Manager=null;
 Boolean runIM_Country_Manager=false;  
 List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    System.debug('++++++++++83++++++++customsettings:'+customsettings);
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='IM_Country__c')
        {
            if(cs.Trigger__c == 'IM_Country_Manager') {
                IM_Country_Manager= cs.Value__c;    
            }
         }
     }
     if(IM_Country_Manager=='True')
     runIM_Country_Manager=true;
     if(runIM_Country_Manager){
     system.debug('+++++++executing the IM_Country_Manager trigger+++++');
         List<IM_Alternative_Country_Name__c> altCountryUpdates = new List<IM_Alternative_Country_Name__c>();
  
         List<IM_Alternative_Country_Name__c> altCountryInserts = new List<IM_Alternative_Country_Name__c>();
  
         map<id,String> matchingCountries = new map<id,String>();
  
         set<String> imCountryNames = new set<String>();
         if(Trigger.isUpdate)
         {
            for(IM_Country__c c : Trigger.Old)
            imCountryNames.add(c.name);
          }
          //if update check to see if there is a country matching the old name and update it with the new name if diffrent
      if(Trigger.isUpdate)
       {
         for (IM_Alternative_Country_Name__c ac : [ select id,Alternative_Name__c ,IM_Country__c, IM_Country__r.Active__c from IM_Alternative_Country_Name__c where IM_Country__c in :Trigger.newMap.keySet() and Alternative_Name__c in :imCountryNames and IM_Country__r.Active__c=false])
         {
             if(ac.IM_Country__r.Active__c==true)
             {
          if(ac.Alternative_Name__c != Trigger.NewMap.Get(ac.IM_Country__c).Name)
         {
             ac.Alternative_Name__c = Trigger.NewMap.Get(ac.IM_Country__c).Name;
             altCountryUpdates.add(ac);       
          }
          matchingCountries.put(ac.IM_Country__c,ac.IM_Country__c);
         } 
         }       
      } 
      for(IM_Country__c c : Trigger.New )
      {
         //if updating and there is no matching IM_Alternative_Country_Name__c record with the same name, create one  
          //if creating a new record, create a matching IM_Alternative_Country_Name__c record.
        if(matchingCountries.get(c.Id) == null && c.Active__c==true)
        {
          IM_Alternative_Country_Name__c ac = new IM_Alternative_Country_Name__c(Alternative_Name__c = c.Name 
                                                                     , IM_Country__c  = c.Id);  
            altCountryInserts.add(ac);  
        }  
      }
      
      if(altCountryInserts.size() > 0)
        insert altCountryInserts;
       if(altCountryUpdates.size() > 0)
         update altCountryUpdates;
       
    }

}
public class CountryNameTranslator {
/**
Auhtor       : Nathan Shinn
Company      : Fujitsu America
Created Date : 11/14/2010
Description  : Use this class to find alternative names for a given country.
               the IM_Alternative_Country_Name__c should carry the actual name
               of the parent record's Country as well as any known alternatives.
               
               The IM_Alternative_Country_Name__c contains the duplicated Name of the
               IM_Country__c record in order to keep the number of queries executed to find the 
               matching country to a minimum. It is also expected that all Countries have at least
               one corresponding, child IM_Alternative_Country_Name__c record. This will be
               enforced via a trigger on both the IM_Alternative_Country_Name__c as well as
               the IM_Country__c table. 
               
*/
       
       public static Map<Id,IM_Country__c> translateCountryName(Map<Id,String> CountryMap) 
       {
       	       set<String> countries = new set<String>();
       	       
       	       Map<Id,IM_Country__c> matchingCountries = new Map<Id,IM_Country__c>();
       	       
       	       for( Id key : CountryMap.keySet() ){ 
       	       	    countries.add(CountryMap.get(key));
       	       }
       	      
   	       	   for(IM_Alternative_Country_Name__c altCountry : [ select IM_Country__r.Id
								       	       	                      , IM_Country__r.Iso31662Code__c
								       	       	                      , IM_Country__r.Iso31663Code__c
								       	       	                      , IM_Country__r.Name
								       	       	                      , IM_Country__r.Region__c
								       	       	                      , Alternative_Name__c
								       	       	                   from IM_Alternative_Country_Name__c
								       	       	                  where Alternative_Name__c in :countries])
		       {
	                 IM_Country__c country = new IM_Country__c( id = altCountry.IM_Country__r.Id
						       	       	                      , Iso31662Code__c  = altCountry.IM_Country__r.Iso31662Code__c
						       	       	                      , Iso31663Code__c = altCountry.IM_Country__r.Iso31663Code__c
						       	       	                      , Name = altCountry.IM_Country__r.Name
						       	       	                      , Region__c = altCountry.IM_Country__r.Region__c);
			   
				     for( Id key : CountryMap.keySet() )
				     {
				     	 
	                     String cntryString = CountryMap.get(key);
	                     
	                     if(altCountry.Alternative_Name__c.equalsIgnoreCase(cntryString) 
	                         && matchingCountries.get(key) == null )
	                     {
	                        matchingCountries.put(key,country);
	                       
	                     }
	                     
       	             }
       	         
   	           }
       	      
       	       
       	       return matchingCountries;
       }
       
       public static Map<string,IM_Country__c> translateCountryName2(set<String> CountryMap) 
       {
       	       
       	       Map<string,IM_Country__c> matchingCountries = new Map<string,IM_Country__c>();
       	       
       	       
       	      
   	       	   for(IM_Alternative_Country_Name__c altCountry : [ select IM_Country__r.Id
								       	       	                      , IM_Country__r.Iso31662Code__c
								       	       	                      , IM_Country__r.Iso31663Code__c
								       	       	                      , IM_Country__r.Name
								       	       	                      , IM_Country__r.Region__c
								       	       	                      , Alternative_Name__c
								       	       	                   from IM_Alternative_Country_Name__c
								       	       	                  where Alternative_Name__c in :CountryMap])
		       {
	                 IM_Country__c country = new IM_Country__c( id = altCountry.IM_Country__r.Id
						       	       	                      , Iso31662Code__c  = altCountry.IM_Country__r.Iso31662Code__c
						       	       	                      , Iso31663Code__c = altCountry.IM_Country__r.Iso31663Code__c
						       	       	                      , Name = altCountry.IM_Country__r.Name
						       	       	                      , Region__c = altCountry.IM_Country__r.Region__c);
			   
				     for( string key : CountryMap )
				     {
				     	 
	                     String cntryString = key;
	                     
	                     if(altCountry.Alternative_Name__c.equalsIgnoreCase(cntryString) 
	                         && matchingCountries.get(key) == null )
	                     {
	                        matchingCountries.put(key,country);
	                       
	                     }
	                     
       	             }
       	         
   	           }
       	      
       	       
       	       return matchingCountries;
       }
       
       public static IM_Country__c getOrCreateTestCountry(IM_Country__c country)
       {
       	    IM_Country__c retCountry = new IM_Country__c();
       	    try{
       	    	retCountry = [select id from IM_Country__c where name = :country.name];
       	    }
       	    catch(Exception e)
       	    {
       	    	insert country;
       	    	retCountry = country; 
       	    }
       	    return retCountry;
       }
}
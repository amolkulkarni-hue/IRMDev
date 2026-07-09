public class updateContractNumber {
   
   /* 
      Created Date:  7/20/2010 
      Auhtor: Nathan Shinn
      Description : Used to manager the "Name" attribute (AKA Customer Number) on the contract object
    */  
   public static boolean isTriggered = false; 
   public static void generateContractNumber(List<String> contractIds)
   {
      /*
       * Generates the Name for a new Contract. Currently called via insert trigger
       */
      system.debug('contractIds=='+contractIds);
      //retrieve all the relevant attributes for the list of Contract IDs
      List<Contract> contracts = [Select id,recordTypeid, Main_Contract__c
                                       ,Main_Contract__r.IM_Contract_Number__c,RecordType.Name
                                       ,name, Main_Contract__r.name,IM_Contract_Number__c
                                    from Contract 
                                   where id in :contractIds];
      system.debug('contracts =='+contracts );                                   
                                    
      //Parent Contracts
      list<Contract> mainContracts = new list<Contract>();
      list<Contract> mainContractsnew = new list<Contract>();
      
      //Addendums
      list<Contract> addendums = new list<Contract>();
      list<Contract> addendumsnew = new list<Contract>();
      
      //Parent Ids
      List<Id>  parentContractIds = new List<Id>();
      List<Id>  parentContractIdsnew = new List<Id>();
      
      //maps the parent contract by ID
      Map<Id,String> parentContractMap = new Map<Id, String>();
      Map<Id,String> parentContractMapnew = new Map<Id, String>();
      
      //used to retrieve addendums by id                                
      map<Id,Integer> peerAddendums = new map<Id,Integer>();
      map<Id,Integer> peerAddendumsnew = new map<Id,Integer>();
      
      system.debug('all contracts=='+contracts);
      for(Contract c : contracts)
      {
          system.debug('c.RecordType.Name=='+c.RecordType.Name);
          //separate into two lists -- parents and addendums
          if(c.RecordType.Name == 'IME Addendum' || c.RecordType.Name =='IME Child Contract' || c.RecordType.Name=='IME Other Ancillary Document' || c.RecordType.Name=='IME Addendum Extension')
          {
             parentContractIds.add(c.Main_Contract__c);
             if(parentContractMap.get(c.Main_Contract__c) ==  null)
             {
               //load the parent contract map if it hasn't already been loaded
               parentContractMap.put(c.Main_Contract__c,c.Main_Contract__r.Name);
             }
             addendums.add(c);
          }
          else
          {           
            c.name = c.IM_Contract_Number__c;
            mainContracts.add(c);
            system.debug('+++++mainContracts+++++'+mainContracts);
          }
      }
      
      system.debug('all mainContracts=='+mainContracts);
       
       
      system.debug('all addendums=='+addendums);
       
      //Used to name the addendum contracts according the name of their parent plus an interation number. 
      List<aggregateResult> results = [select Main_Contract__c, count_distinct(id) totalAddendums
                                         from Contract 
                                        where Main_Contract__c in :parentContractIds
                                         and isDeleted = false
                                        group by Main_Contract__c ];      
        
      for (AggregateResult ar : results)
      { 
          Id mainContract = (ID)ar.get('Main_Contract__c');
          Integer addendumCount = (Integer.valueOf(ar.get('totalAddendums')) );
          
          peerAddendums.put(mainContract,addendumCount);
      }
    
     
      
      for(Integer i = 0; i < addendums.size(); i++)
      {
        //compose the name from the parent's name and the contract interation
        addendums.get(i).name = (parentContractMap.get(addendums.get(i).Main_Contract__c)
                                    + '-'
                                    +(peerAddendums.get(addendums.get(i).Main_Contract__c))
                                    );
      }
      
      
      //update the contract and addendum names
      if(addendums.size() > 0)
      {
        update addendums;
      }
      
      else if(mainContracts.size() > 0)
      {
        update mainContracts;
      }
      
   }
   
   public static void updateAddendumNumber(Map<String, String> parentNameMap)
   {
      /* used to update the Name of a contract if the country code has changed. The driver is a triggger 
         on the Contract Object that sends Parent records here if a Parent contract's country code has changed.
       */
      //list of addendums to update
      list<Contract> addendums = new list<Contract>();
      
      //iterate through all the addendums and update the name to suit the new country code
      for(Contract c : [Select name
                              ,id
                              ,RecordType.Name
                              ,Main_Contract__r.id
                         from Contract 
                        where Main_Contract__c in :parentNameMap.keySet() ])
                        
                        
      {
           System.debug('++++++++Contract++++'+c);
          //loop through the contracts and create a separate list the main contracts
          //Create a map with the addendum contracts
          try{
              System.debug('+++++++Name+++++'+ c.name);
              c.name = parentNameMap.get(c.Main_Contract__c)
                      + (c.Name).subString(3,(c.Name).length());
          }
          catch(Exception e)
          {
            
          }
          addendums.add(c);         
      }
      
      //perform the update
      if(addendums.size() > 0 )
         update addendums;
   }
}
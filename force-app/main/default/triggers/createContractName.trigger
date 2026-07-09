trigger createContractName on Contract ( after insert, before update,after update)
{ 
    /* 
      Created Date: 7/20/2010 
      Auhtor: Nathan Shinn
      Description : used in conjunction with the updateContractNumber class to manage contract names.
      
      Modified Date    :     23rd Fed 2017
      Author           :     C. Pratap Reddy
      Description      :    when an Addendum or Addendum extention is changed and parent contract is activated 
                            then update the parent contract and all the child Contracts (‘Draft’ or ‘Activated’ Status) 
                            of the parent contract with addendum or Addendum extention values
                            Also added after update
    */ 
            
    system.debug(!updateContractNumber.isTriggered+'firstline');
    //used to exclude addendums
        RecordType rt = [Select id, name 
                           from RecordType 
                          where SObjectType = 'Contract'
                            and (name = 'IME Parent Contract') ];
        
        RecordType rtime = [Select id, name 
                           from RecordType 
                          where SObjectType = 'Contract'
                            and (name = 'IME Addendum') ];
       
        
        ID rAddendumExt =  DataFactory.getRecordTypeId('Contract','IME Addendum Extension');
        ID nChildContractRecType =  DataFactory.getRecordTypeId('Contract','IME Child Contract');
        
         List<ID> recordTypeIds = new List<ID>();
        recordTypeIds.add(rtime.id);
        recordTypeIds.add(rAddendumExt);
        
    if(!updateContractNumber.isTriggered)
    {
        
        system.debug('inside block');
        if(triggerFlowControl.triggerRunCount('createContractName') > 1 )
           return;
        
        //list of new country codes to name
        list<String> contractIds = new list<string>();
        
        //list of parent contracts for which addendums must be re-named
        Map<String, String> parentNameMap = new Map<String, String>();
        
        
                             
        //iterate through the list of Contracts loading the map changed parents and list of new contracts                    
        for (Integer i = 0; i < trigger.new.size(); i++)
        {
            system.debug('trigger.new.get(i).recordTypeId == rt.Id'+trigger.new.get(i).recordTypeId +'dd'+rt.Id+'qq'+trigger.new.get(i).Main_Contract__c);
            if(    trigger.isUpdate 
                && trigger.old.get(i).Billing_Country__c != trigger.new.get(i).Billing_Country__c
                && trigger.new.get(i).recordTypeId == rt.Id 
                //&& trigger.new.get(i).recordTypeId != rtime.Id
                && trigger.new.get(i).Main_Contract__c == null)
             {
                //change the name of the parents before insert
                trigger.new.get(i).name = trigger.new.get(i).IM_Country_Code__c 
                                      + (trigger.new.get(i).Name).subString(3,(trigger.new.get(i).name).length());
               
                //load a map of the parents and their new country codes to update the addendums
                parentNameMap.put(trigger.old.get(i).Id,trigger.new.get(i).IM_Country_Code__c);
                
             }
             system.debug('Inside trigger for loop ');
            if(trigger.isInsert)//New Contracts to be named 
            { 
                system.debug('trigger.isInsert');
                 contractIds.add(trigger.new.get(i).id);
                 system.debug('New Contracts to be named =='+contractIds);
            }
            
        }
        system.debug('outside for =='+contractIds);
        if(trigger.isInsert )//create the contract name
          updateContractNumber.generateContractNumber(contractIds);
          
        if(trigger.isUpdate  && parentNameMap.size() > 0)//adjust the addendum names
           updateContractNumber.updateAddendumNumber(parentNameMap);
        

        
          
     }
    updateContractNumber.isTriggered = true; 
      system.debug('aaaaa');
      
        
      
     // Added by Pratap 
     // 
        if(trigger.isBefore){
              if(trigger.isUpdate){
                    
              }
        }
    
     if(trigger.isAfter){
               System.debug('Pratap test');
                list<Contract> changedContracts = new List<Contract>();
               if(trigger.isUpdate){ 
                   // update TotalAnnualValue
                   // Fetch contracts only if IME_Annual_Value_Opportunities__c value changed 
                   for(COntract c: trigger.new){
                       system.debug('c.IME_Annual_Value_Opportunities__c:'+ c.IME_Annual_Value_Opportunities__c);
                       if( (c.IME_Annual_Value_Opportunities__c!=0) && ((c.status == 'Activated') ||
                         (c.status == 'Cancelled') || (c.status == 'Terminated'))
                         )
                           changedContracts.add(c);
                   }
                   system.debug('contractTotalAnnualAmount.runOnce():'+ contractTotalAnnualAmount.run + 
                                ' changedContracts.size():'+ changedContracts.size() );
                   if(changedContracts.size() > 0){ 
                       if(contractTotalAnnualAmount.runOnce()){ 
                        contractTotalAnnualAmount con = new contractTotalAnnualAmount();
                        con.UpdateTotalAnnualValue(changedContracts);
                       }
                    }
                       
                    contractTotalAnnualAmount updateParentChilds = new contractTotalAnnualAmount();
                    map<id,Contract> actualIds = new map<id,Contract>();
                    
                    for(contract currentRec : trigger.new){
                    system.debug('currentRec.Status:'+ currentRec.Status + ' Record Type:'+ currentRec.recordTypeId + ' rAddendumExt:'+ rAddendumExt);
                        if((currentRec.recordTypeId == rtime.Id) || (currentRec.recordTypeId == rAddendumExt) ) {
                        if(currentRec.Status == 'Activated'){
                        
                            actualIds.put(currentRec.Main_Contract__c,currentRec);
                        }
                    }
                     system.debug('actualIds:'+actualIds);   
                    updateParentChilds.UpdateParentAndChild(actualIds,trigger.oldMap);
                   // End of update TotalAnnualValue
                   
                   
               
                }
              }
            }
      
}
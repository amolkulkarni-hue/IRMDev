/****************************** 
   Developer Name    : Venkateshwarlu Avula and Apurva Dutta
   
   Date              : 3/26/2014
   
   Company Name      : Iron Mountain Service India Pvt. Ltd.
   
   Purpose           : This class is used for Calculating the Sum of Total Annual Amount from Opportunity and display in Parent Object(Contract).
   
   Test Class        :  Apex Class  : Test_IME_OpportunityRollUpContract
   
   Case Number       : 01590130
   ********************************
   Developer Name    : Kavya Somashekar
   
   Date              : 8/27/2014
   
   Company Name      : Iron Mountain Service India Pvt. Ltd.
   
   Purpose           : Error raised associating contract to opportunity:-error was caused by the validation rule 'IME_Renewal_Evergreen' with the trigger: IME_OpportunityRollUpContract 
  
   Case Number       : 02766280
                                  
 ********************************
  Developer Name    : Venkateshwarlu Avula
   
   Date              : 10/14/2014
   
   Company Name      : Iron Mountain Service India Pvt. Ltd.
   
   Purpose           : filtering record types to avoid the SOQL 101 Exception.
                                  
 ********************************/
trigger IME_OpportunityRollUpContract on Opportunity (after insert, after update, after delete) 
{
    /****Variable declaration for 'customrollupcontract' Trigger****/
  /**  public String customrollupcontract = null;
    public Boolean isRecursive = false;
    
    map<Id, Schema.RecordTypeInfo> rt_map = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosById();

    
    /***Retrieving Custom Settings***/
   /** List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings)
    {
        if(cs.Object__c=='Opportunity')
        {
            if(cs.Trigger__c == 'customrollupcontract') 
            {
                customrollupcontract = cs.Value__c;    
            }
        }
    }
    
    if(customrollupcontract == 'True')
    {

        List<string> contOldIds = new List<string>();
        List<Id> conNewIds = new List<Id>();
        List<Id> optyOldIds = new List<Id>();
        List<Contract> objConNewList = new List<Contract>();
        List<Contract> objConNewListNew = new List<Contract>();
        List<Contract> objConOldList = new List<Contract>();
        List<CurrencyType> currenLst = new List<CurrencyType>();           
        Map<Id, Double> optyNewMap = new Map<Id, Double>();
        Map<String, Double> contractNewMap = new Map<String, Double>();
        Map<Id, Double> contractOldMap = new Map<Id, Double>();
        Map<String, Double> conNewMap = new Map<String, Double>();
        Map<Id, Double> conOldMap = new Map<Id, Double>();
        Map<Id, Id> contractIdNewMap = new Map<Id, Id>();
        Map<Id, Id> contractIdOldMap = new Map<Id, Id>();
        Map<Id, String> conrCodeNewMap = new Map<Id, String>();
        Map<Id, String> conrCodeOldMap = new Map<Id, String>();
        Map<String, Double> currenMap = new Map<String, Double>();
        Double dCurrency;
        Double dCurrencyOld;
          
          if(trigger.isInsert || trigger.isUpdate)
            { 
            system.debug('entering isinsert or isupdate');
               for(Opportunity objOpty : Trigger.new)
                {
                system.debug('Trigger.new--------'+Trigger.new);
                // filtering record types to avoid the SOQL 101 Exception:Added by Venkat - 14/10/2014
                    if(rt_map.get(objOpty.recordTypeID).getName().containsIgnoreCase('IME Standard Opportunity') || rt_map.get(objOpty.recordTypeID).getName().containsIgnoreCase('IMLA Standard Opportunity') || rt_map.get(objOpty.recordTypeID).getName().containsIgnoreCase('IMAP Standard Opportunity'))
                    {
                        isRecursive = true;
                    }
                    IF(objOpty.IME_Contract__c != null)
                    {
                    system.debug('entering insert or isupdate if');
                        conNewIds.add(objOpty.IME_Contract__c);
                        optyOldIds.add(objOpty.Id);
                        
                    }
                    
                }
                if(isRecursive)
                {
                        currenLst = [Select Id, ConversionRate, ISOCode  from CurrencyType];
                }
                for(CurrencyType objCurren: currenLst)
                {
                    currenMap.put(objCurren.ISOCode , objCurren.ConversionRate);
                    System.debug('--- objCurren.ISOCode---' +objCurren.ISOCode);
                    System.debug('---objCurren.ConversionRate---' +objCurren.ConversionRate);
                }
                List<aggregateResult> results = new List<aggregateResult>();
                if(isRecursive)
                {
                    if(conNewIds.size() > 0){
                    results = [select IME_Contract__c cntrcId, Sum(Amount) Total from Opportunity where 
                                                        IME_Contract__c IN: conNewIds and OwnerId!='' group by IME_Contract__c LIMIT 10000]; // [RI - 08/14/14] added LIMIT
                    }    
                }                         
                for(Integer i=0;i<results.size();i++)
                {
                    contractNewMap.put(String.ValueOf(results[i].get('cntrcId')),Double.valueOf(results[i].get('Total')));
                }
                
                List<Contract> conLst = new List<Contract>();
                
                if(isRecursive)
                {
                    if(conNewIds.size() > 0){
                        conLst = [Select Id,CurrencyIsoCode, IME_Annual_Value_Opportunities__c from Contract where Id IN:conNewIds 
                            and (Recordtype.Name = 'IME Parent Contract' or Recordtype.Name = 'IME child contract' or Recordtype.Name ='IME Addendum Extension') LIMIT 10000]; // [RI - 08/14/14] added LIMIT
                    }    
                }
                if(!conLst.isEmpty())
                {
                    for(Contract conOb: conLst)
                    {
                        conNewMap.put(conOb.Id,conOb.IME_Annual_Value_Opportunities__c);
                        contractIdNewMap.put(conOb.Id,conOb.Id);
                        conrCodeNewMap.put(conOb.Id,conOb.CurrencyIsoCode);
                    }
                }
                if(trigger.isInsert){
                system.debug('entering only isinsert');
                    if(trigger.isAfter)
                    {
                    system.debug('entering isinsert and isafter');
                        for(Opportunity objOpty : Trigger.new)
                        {
                        system.debug('Trigger.new11111---------'+Trigger.new);
                            if(!conLst.isEmpty())
                            {
                            system.debug('entering conlist.empty');
                                for(Contract conObj: conLst)
                                {   
                                    Contract obCon = new Contract();
                                    obCon.Id = conObj.Id;
                                    if(contractNewMap.get(conObj.Id) != null)
                                    {
                                        System.debug('conObj.Id---'+conObj.Id);
                                        System.debug('contractNewMap.get(conObj.Id)---'+contractNewMap.get(conObj.Id));
                                        System.debug('conObj.CurrencyIsoCode---'+conObj.CurrencyIsoCode);
                                        System.debug('currenMap.get(conObj.CurrencyIsoCode)-----'+currenMap.get(conObj.CurrencyIsoCode));
                                        
                                        obCon.IME_Annual_Value_Opportunities__c = contractNewMap.get(conObj.Id)*currenMap.get(conObj.CurrencyIsoCode);
                                    }
                                    objConNewList.add(obCon);
                                }
                            }
                       }
                       System.debug('objConNewList---'+objConNewList);
                       if(!objConNewList.isEmpty())
                       {
                            update objConNewList;
                       }
                     }   
                        
                     
                }
                if(trigger.isUpdate)
                {
                system.debug('entering only isupdate');
                    try
                    {                    
                        if(trigger.isAfter)
                        {
                        system.debug('entering first try');
                        system.debug('entering isupdate isafter');
                            for(Opportunity Oppty : trigger.old)
                            {
                             // filtering record types to avoid the SOQL 101 Exception:Added by Venkat - 14/10/2014
                                if(rt_map.get(Oppty.recordTypeID).getName().containsIgnoreCase('IME Standard Opportunity') || rt_map.get(Oppty.recordTypeID).getName().containsIgnoreCase('IMLA Standard Opportunity') || rt_map.get(Oppty.recordTypeID).getName().containsIgnoreCase('IMAP Standard Opportunity'))
                                {
                                    contOldIds.add(Oppty.IME_Contract__c);
                                    optyOldIds.add(Oppty.Id);
                                    contractOldMap.put(Oppty.IME_Contract__c, Oppty.Amount);
                                }
                            }       
                        
                            List<Contract> conlist= new List<Contract>();
                            
                            if(!contOldIds.isEmpty())
                            {
                                    conlist = [Select Id,CurrencyIsoCode, IME_Annual_Value_Opportunities__c from Contract 
                                        where Id IN: contOldIds and (Recordtype.Name = 'IME Parent Contract' or Recordtype.Name = 'IME child contract' or Recordtype.Name ='IME Addendum Extension') LIMIT 10000]; // [RI - 08/14/14] added LIMIT
                            }
                            if(!conlist.isEmpty())
                            {
                                for(Contract conOldObj:conlist)
                                {
                                    conOldMap.put(conOldObj.Id, conOldObj.IME_Annual_Value_Opportunities__c);
                                    conrCodeOldMap.put(conOldObj.Id,conOldObj.CurrencyIsoCode);
                                }
                            }
                            for(Opportunity objOptyNew : Trigger.new)
                            {
                                system.debug('Trigger.new222----'+Trigger.new);
                                system.debug('check----------'+rt_map.get(objOptyNew.recordTypeID).getName().containsIgnoreCase('IME Standard Opportunity'));
                                system.debug('check22222----------'+rt_map.get(objOptyNew.recordTypeID).getName()=='IME Standard Opportunity');
                               system.debug('objOptyNew.recordTypeID--------'+objOptyNew.recordTypeID);
                               system.debug('rt_map.get(objOptyNew.recordTypeID)--------'+rt_map.get(objOptyNew.recordTypeID));
                               system.debug('rt_map.get(objOptyNew.recordTypeID).getName()--------'+rt_map.get(objOptyNew.recordTypeID).getName()+'---------------');
                               // filtering record types to avoid the SOQL 101 Exception:Added by Venkat - 14/10/2014
                               if(rt_map.get(objOptyNew.recordTypeID).getName().containsIgnoreCase('IME Standard Opportunity') || rt_map.get(objOptyNew.recordTypeID).getName().containsIgnoreCase('IMLA Standard Opportunity') || rt_map.get(objOptyNew.recordTypeID).getName().containsIgnoreCase('IMAP Standard Opportunity'))
                               {
                                    Opportunity objOptyOld = Trigger.OldMap.get(objOptyNew.Id);
                                    
                                        if(objOptyNew.IME_Contract__c == objOptyOld.IME_Contract__c && objOptyNew.Amount !=objOptyOld.Amount)
                                        {
                                        system.debug('entering if amount not equal');
                                            if(!conLst.isEmpty())
                                            {
                                                for(Contract conObj: conLst)
                                                {   
                                                    System.debug('------conObj.Id---------'+conObj.Id);
                                                    System.debug('------objOptyNew.IME_Contract__c---------'+objOptyNew.IME_Contract__c);
                                                    System.debug('------contractNewMap.get(objOptyNew.IME_Contract__c)---------'+contractNewMap.get(objOptyNew.IME_Contract__c));
                                                    System.debug('------conObj.CurrencyIsoCode---------'+conObj.CurrencyIsoCode);
                                                    System.debug('------currenMap.get(conObj.CurrencyIsoCode)---------'+currenMap.get(conObj.CurrencyIsoCode));
                                                    
                                                    Contract obCon = new Contract();
                                                    obCon.Id = conObj.Id;
                                                    obCon.IME_Annual_Value_Opportunities__c = contractNewMap.get(objOptyNew.IME_Contract__c)*currenMap.get(conObj.CurrencyIsoCode);
                                                    system.debug('obCon.IME_Annual_Value_Opportunities__c------------'+obCon.IME_Annual_Value_Opportunities__c);
                                                    objConNewList.add(obCon);
                                                }
                                            }
                                        }
                                        else if(objOptyOld.IME_Contract__c == null && objOptyNew.IME_Contract__c !=null)
                                        {
                                        system.debug('entering if adding contract');
                                            if(!conLst.isEmpty())
                                            {
                                                for(Contract conObj: conLst)
                                                {   
                                                    Contract obCon = new Contract();
                                                    obCon.Id = conObj.Id;
                                                    if(contractNewMap.get(objOptyNew.IME_Contract__c) != null)
                                                    { 
                                                    System.debug('-- if(contractNewMap.get(objOptyNew.IME_Contract__c) != null)--'); 
                                                    System.debug('------conObj.Id---------'+conObj.Id);
                                                    System.debug('------objOptyNew.IME_Contract__c---------'+objOptyNew.IME_Contract__c);
                                                    System.debug('------contractNewMap.get(objOptyNew.IME_Contract__c)---------'+contractNewMap.get(objOptyNew.IME_Contract__c));
                                                    System.debug('------conObj.CurrencyIsoCode---------'+conObj.CurrencyIsoCode);
                                                    System.debug('------currenMap.get(conObj.CurrencyIsoCode)---------'+currenMap.get(conObj.CurrencyIsoCode));
                                                        obCon.IME_Annual_Value_Opportunities__c = contractNewMap.get(objOptyNew.IME_Contract__c)*currenMap.get(conObj.CurrencyIsoCode);
                                                    system.debug('obCon.IME_Annual_Value_Opportunities__c:'+ obCon.IME_Annual_Value_Opportunities__c);
                                                    }
                                                  /*  else
                                                    { 
                                                    System.debug('-- if(contractNewMap.get(objOptyNew.IME_Contract__c) != null) ELSE--'); 
                                                    System.debug('------conObj.Id---------'+conObj.Id);
                                                    System.debug('------objOptyNew.IME_Contract__c---------'+objOptyNew.IME_Contract__c);
                                                    System.debug('------objOptyNew.Amount---------'+objOptyNew.Amount);
                                                    System.debug('------conObj.CurrencyIsoCode---------'+conObj.CurrencyIsoCode);
                                                    System.debug('------currenMap.get(conObj.CurrencyIsoCode)---------'+currenMap.get(conObj.CurrencyIsoCode));
                                                   
                                                        obCon.IME_Annual_Value_Opportunities__c = objOptyNew.Amount*currenMap.get(conObj.CurrencyIsoCode);
                                                        
                                                    }*/
                                          /*          objConNewList.add(obCon);
                                                }
                                               System.debug('---objConNewList---'+objConNewList); 
                                            }
                                        }
                                        else if(objOptyOld.IME_Contract__c != null && objOptyNew.IME_Contract__c ==null)
                                        {
                                        System.debug('---entering removing contract---'); 
                                            if(!conlist.isEmpty())
                                            {
                                            system.debug('---not empty--');
                                                for(Contract conObj: conlist )
                                                { 
                                                system.debug('---entering remove for---');  
                                                    Contract obCon = new Contract();
                                                    obCon.Id = conObj.Id;
                                                    if(conObj.IME_Annual_Value_Opportunities__c != null)
                                                    {
                                                    system.debug('--annual value not equal to null---');
                                                        if(UserInfo.getDefaultCurrency() == objOptyOld.CurrencyIsoCode)
                                                        {
                                                        system.debug('--equal---');
                                                        system.debug('conOldMap.get(objOptyOld.IME_Contract__c:'+ conOldMap.get(objOptyOld.IME_Contract__c));
                                                        system.debug('objOptyOld.Amount:'+ objOptyOld.Amount);
                                                            obCon.Id = objOptyOld.IME_Contract__c;
                                                            dCurrency =  Math.roundToLong(conOldMap.get(objOptyOld.IME_Contract__c) - objOptyOld.Amount);
                                                            obCon.IME_Annual_Value_Opportunities__c =dCurrency;
                                                            objConNewListNew.add(obCon);
                                                        }
                                                        else if(objOptyOld.CurrencyIsoCode != conrCodeNewMap.get(objOptyOld.IME_Contract__c))
                                                        {
                                                            
                                                        system.debug('--not equal---');
                                                        system.debug('conOldMap.get(objOptyOld.IME_Contract__c:'+ conOldMap.get(objOptyOld.IME_Contract__c));
                                                        system.debug('objOptyOld.Amount:'+ objOptyOld.Amount);
                                                            system.debug('currenMap.get(objOptyOld.CurrencyIsoCode:'+currenMap.get(objOptyOld.CurrencyIsoCode));
                                                            obCon.Id = objOptyOld.IME_Contract__c;
                                                          decimal ContractAmount,OpptAmount; 
                                                            // Convert contract & Opp amount into USD 
                                                            if(conrCodeOldMap.get(objOptyOld.IME_Contract__c) != 'USD')
                                                            {
                                                                ContractAmount = (1/currenMap.get(conrCodeOldMap.get(objOptyOld.IME_Contract__c)) * conOldMap.get(objOptyOld.IME_Contract__c));
                                                            }
                                                            else {
                                                                ContractAmount = conOldMap.get(objOptyOld.IME_Contract__c);
                                                            }
                                                            
                                                            if(objOptyOld.CurrencyIsoCode!= 'USD'){
                                                                OpptAmount = (1/currenMap.get(objOptyOld.CurrencyIsoCode) * objOptyOld.Amount);
                                                            }
                                                            else
                                                            {
                                                                OpptAmount = objOptyOld.Amount;
                                                            }
                                                            dCurrency = ContractAmount > OpptAmount ? ContractAmount - OpptAmount : OpptAmount - ContractAmount;
                                                           // dCurrency =  Math.roundToLong((conOldMap.get(objOptyOld.IME_Contract__c)) - 
                                                            //                                (objOptyOld.Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(objOptyOld.CurrencyIsoCode))));
                                                            obCon.IME_Annual_Value_Opportunities__c = conObj.CurrencyIsoCode!= 'USD' ? dCurrency * currenMap.get(conObj.CurrencyIsoCode) :dCurrency;
                                                            objConNewListNew.add(obCon);
                                                        }   
                                                        else
                                                        {
                                                        system.debug('--not equal else---');
                                                            obCon.Id = objOptyOld.IME_Contract__c;
                                                            
                                                            decimal ContractAmount,OpptAmount; 
                                                            // Convert contract & Opp amount into USD 
                                                            if(conrCodeOldMap.get(objOptyOld.IME_Contract__c) != 'USD')
                                                            {
                                                                ContractAmount = (1/currenMap.get(conrCodeOldMap.get(objOptyOld.IME_Contract__c)) * conOldMap.get(objOptyOld.IME_Contract__c));
                                                            }
                                                            else {
                                                                ContractAmount = conOldMap.get(objOptyOld.IME_Contract__c);
                                                            }
                                                            
                                                            if(objOptyOld.CurrencyIsoCode!= 'USD'){
                                                                OpptAmount = (1/currenMap.get(objOptyOld.CurrencyIsoCode) * objOptyOld.Amount);
                                                            }
                                                            else
                                                            {
                                                                OpptAmount = objOptyOld.Amount;
                                                            }
                                                            dCurrency = ContractAmount > OpptAmount ? ContractAmount - OpptAmount : OpptAmount - ContractAmount;
                                                           
                                                           // dCurrency =  Math.roundToLong(conOldMap.get(objOptyOld.IME_Contract__c) - 
                                                              //                            (objOptyOld.Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(objOptyOld.CurrencyIsoCode))));
                                                            //obCon.IME_Annual_Value_Opportunities__c =dCurrency;
                                                            obCon.IME_Annual_Value_Opportunities__c = conObj.CurrencyIsoCode!= 'USD' ? dCurrency * currenMap.get(conObj.CurrencyIsoCode) :dCurrency;
                                                            objConNewListNew.add(obCon);
                                                        }       
                                                    }
                                                    objConNewList.add(obCon);
                                                }
                                            }
                                        }
                                        else if(objOptyOld.IME_Contract__c != null && objOptyNew.IME_Contract__c !=null && objOptyNew.IME_Contract__c != objOptyOld.IME_Contract__c)
                                        {
                                        system.debug('entering else if where adding new contract replacing old one');
                                                    //for(Contract conObj: conlist )
                                                    //{   
                                                        Contract obCon = new Contract();
                                                        try
                                                        {
                                                        system.debug('entering second try');
                                                            if(conOldMap.get(objOptyOld.IME_Contract__c) != null)
                                                            {
                                                            system.debug('--if not equal---');
                                                                if(UserInfo.getDefaultCurrency() == objOptyOld.CurrencyIsoCode)
                                                                {
                                                                system.debug('--if equal---');
                                                                    obCon.Id = objOptyOld.IME_Contract__c;
                                                                    dCurrency =  Math.roundToLong(conOldMap.get(objOptyOld.IME_Contract__c) - objOptyOld.Amount);
                                                                    if (dCurrency < 0){
                                                                        dCurrency = 0;
                                                                    }
                                                                    obCon.IME_Annual_Value_Opportunities__c =dCurrency;
                                                                    objConNewListNew.add(obCon);
                                                                }
                                                                else if(objOptyOld.CurrencyIsoCode != conrCodeNewMap.get(objOptyNew.IME_Contract__c))
                                                                {
                                                                system.debug('--else if not equal---');
                                                                    if(objOptyOld.CurrencyIsoCode != 'HUF')
                                                                    {
                                                                        obCon.Id = objOptyOld.IME_Contract__c;
                                                                        dCurrency =  Math.roundToLong((conOldMap.get(objOptyOld.IME_Contract__c)) - 
                                                                                    (objOptyOld.Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(objOptyOld.CurrencyIsoCode))));
                                                                         if (dCurrency < 0){
                                                                            dCurrency = 0;
                                                                        }
                                                                        obCon.IME_Annual_Value_Opportunities__c =dCurrency;
                                                                        objConNewListNew.add(obCon);
                                                                    }
                                                                    else
                                                                    {
                                                                    system.debug('--else not equal---');
                                                                        obCon.Id = objOptyOld.IME_Contract__c;
                                                                        dCurrency =  Math.roundToLong((conOldMap.get(objOptyOld.IME_Contract__c)) - 
                                                                                    (objOptyOld.Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(objOptyOld.CurrencyIsoCode))));
                                                                         if (dCurrency < 0){
                                                                            dCurrency = 0;
                                                                        }
                                                                        obCon.IME_Annual_Value_Opportunities__c =dCurrency;
                                                                        objConNewListNew.add(obCon);
                                                                    }
                                                                }   
                                                                else
                                                                {
                                                                system.debug('--else else not equal---');
                                                                    obCon.Id = objOptyOld.IME_Contract__c;
                                                                    dCurrency =  Math.roundToLong(conOldMap.get(objOptyOld.IME_Contract__c) - 
                                                                    (objOptyOld.Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(objOptyOld.CurrencyIsoCode))));
                                                                    if (dCurrency < 0){
                                                                        dCurrency = 0;
                                                                    }
                                                                    obCon.IME_Annual_Value_Opportunities__c =dCurrency;
                                                                    objConNewListNew.add(obCon);
                                                                }       
                                                            }
                                                            update objConNewListNew;
                                                        }
                                                           catch (DMLException e)
                                                           {
                                                           system.debug('entering first catch');
                                                                 for(Opportunity objOpty : Trigger.new) {
                                                                      objOpty.addError('There was a problem updating the opportunity. Please check the attached contract with valid values');
                                                                 }
                                                           }

                                                            if(conNewMap.get(objOptyNew.IME_Contract__c) != null && objOptyNew.IME_Contract__c !=null && objOptyNew.IME_Contract__c != objOptyOld.IME_Contract__c)
                                                            {
                                                            system.debug('entering connewmap if');
                                                                if(UserInfo.getDefaultCurrency() == objOptyOld.CurrencyIsoCode)
                                                                {
                                                                    obCon.Id = objOptyNew.IME_Contract__c;
                                                                    obCon.IME_Annual_Value_Opportunities__c = Math.roundToLong((conNewMap.get(objOptyNew.IME_Contract__c))+objOptyNew.Amount);//*currenMap.get(conObj.CurrencyIsoCode));
                                                                }
                                                                else if(objOptyOld.CurrencyIsoCode == conrCodeNewMap.get(objOptyNew.IME_Contract__c))
                                                                {
                                                                    obCon.Id = objOptyNew.IME_Contract__c;
                                                                    obCon.IME_Annual_Value_Opportunities__c = Math.roundToLong((conNewMap.get(objOptyNew.IME_Contract__c))+objOptyNew.Amount);
                                                                }
                                                                else 
                                                                {
                                                                    obCon.Id = objOptyNew.IME_Contract__c;
                                                                    obCon.IME_Annual_Value_Opportunities__c = Math.roundToLong((conNewMap.get(objOptyNew.IME_Contract__c))+(objOptyNew.Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(objOptyOld.CurrencyIsoCode))));
                                                                }
                                                                
                                                            }
                                                            else if(conNewMap.get(objOptyNew.IME_Contract__c) == null && objOptyNew.IME_Contract__c !=null && objOptyNew.IME_Contract__c != objOptyOld.IME_Contract__c)
                                                            {
                                                            system.debug('adding new contract second time');
                                                                if(UserInfo.getDefaultCurrency() == objOptyOld.CurrencyIsoCode)
                                                                {
                                                                    obCon.Id = objOptyNew.IME_Contract__c;
                                                                    obCon.IME_Annual_Value_Opportunities__c = objOptyNew.Amount;
                                                                }
                                                                else
                                                                {
                                                                    obCon.Id = objOptyNew.IME_Contract__c;
                                                                    obCon.IME_Annual_Value_Opportunities__c = Math.roundToLong(objOptyNew.Amount*(currenMap.get(UserInfo.getDefaultCurrency())/currenMap.get(objOptyOld.CurrencyIsoCode)));
                                                                }
                                                            }
                                                            objConNewList.add(obCon);

                                                    //}
                                        }
                                }
                            }
                        } 
                            if(!objConNewList.isEmpty())
                            {
                                system.debug('objConNewList:'+ objConNewList);
                                update objConNewList;
                                List<Contract> testResult =[SELECT id,IME_Annual_Value_Opportunities__c FROM contract where id in:objConNewList];
                                system.debug('testResult:'+ testResult);
                            }
                    }
                    catch (DMLException e)
                    {
                    system.debug('entering second catch');
                    system.debug('caught----'+e.getMessage());
                     for(Opportunity objOpty : Trigger.new) {
                     string str = 'There was a problem updating the opportunity. Please check the attached contract with valid values.';
                     string str1 = '1. If the contract is "Fixed Term", only positive integer is accepted, or you can leave the Renewal term(months) field blank.';
                     string str2 ='2.If the contract is "Evergreen", only positive integer or zero is accepted for the Renewal term(months) field.';
                     string str3 = '3.If the contract is "Evergreen (open rolling)", "Contract Term (months)" and "Renewal Term (months)" have to be blank.';
                     string str4 = str +'\n' +str1+'\n' +str2+'\n' +str3;   
                     system.debug('str4-------'+str4);
                        objOpty.addError(str4);
                        }
                    }
                }
            
            }
            if(trigger.isDelete)
            {
                 system.debug('entering isdelete');
                for(Opportunity Oppty : trigger.old)
                {
                 // filtering record types to avoid the SOQL 101 Exception:Added by Venkat - 14/10/2014
                    if(rt_map.get(Oppty.recordTypeID).getName().containsIgnoreCase('IME Standard Opportunity') || rt_map.get(Oppty.recordTypeID).getName().containsIgnoreCase('IMLA Standard Opportunity') || rt_map.get(Oppty.recordTypeID).getName().containsIgnoreCase('IMAP Standard Opportunity')) 
                    {
                        contOldIds.add(Oppty.IME_Contract__c);
                        optyOldIds.add(Oppty.Id);
                        contractOldMap.put(Oppty.IME_Contract__c, Oppty.Amount);
                    }
                }       
                
                List<Contract> conlist =new List<Contract>();
                
                if(!contOldIds.isEmpty())
                {
                    conlist = [Select Id, IME_Annual_Value_Opportunities__c from Contract where Id IN: contOldIds 
                        and (Recordtype.Name = 'IME Parent Contract' or Recordtype.Name = 'IME child contract' or Recordtype.Name ='IME Addendum Extension') LIMIT 10000]; // [RI - 08/14/14] added LIMIT
                }
                
                if(!conlist.isEmpty())
                {
                    for(Contract contOld: conlist)
                    {
                        if(contOld.IME_Annual_Value_Opportunities__c != null)
                        {
                            Contract objConOld = new Contract();
                            objConOld .Id = contOld.Id;
                            objConOld.IME_Annual_Value_Opportunities__c = contOld.IME_Annual_Value_Opportunities__c - contractOldMap.get(contOld.Id);
                            objConOldList.add(objConOld );
                        }
                    }
                }
                if(!objConOldList.isEmpty())
                {               
                    Update objConOldList;
                }
            }
    }   */
}
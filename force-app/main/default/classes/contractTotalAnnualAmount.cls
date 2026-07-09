public class contractTotalAnnualAmount {
    
    public static boolean run = true;
    public static boolean runOnce(){
        if(run){
            run=false;
            return true;
        }else{
            return run;
        }
    }
    
    ID rtAddendum = DataFactory.getRecordTypeId('Contract','IME Addendum');
    ID rtAddendumExt =  DataFactory.getRecordTypeId('Contract','IME Addendum Extension');
    ID rtChildContractRecType =  DataFactory.getRecordTypeId('Contract','IME Child Contract');
    ID  rtOtherAncillary    =  DataFactory.getRecordTypeId('Contract','IME Other Ancillary Document');
    ID rtIMEParent =  DataFactory.getRecordTypeId('Contract','IME Parent Contract');
    
    Set<ID> AnnualValueContracts = new set<ID>();
    List<Contract> ParentChildContractList = new     List<Contract>(); 
    
    public contractTotalAnnualAmount() { 
		system.debug('Constructor called');
  	}
    public void UpdateTotalAnnualValue(List<contract> cont){
        
        System.debug('UpdateTotalAnnualValue called');
        Boolean isAddendumExt = false;
        Decimal Total_Annual_Value = 0;
        Date startDate= null;
        
        AnnualValueContracts.add(rtAddendumExt);
        AnnualValueContracts.add(rtChildContractRecType);
        
        
        Map<Id, Id> getParentId = new Map<Id,Id>();
        set<id> parentContracts = new set<id>();
        set<id> ChildContracts = new set<id>();
        map<id,Contract> getParentContrcat = new map<id,Contract>();
        
        map<id,date> AddendumExtStartDate = new map<id,date>();
        map<id,decimal> TotalAnnualValueList = new map<id,decimal>();
        List<Contract> ContractsWithOutAddendumExts = new List<Contract>();
        List<Contract> ContractsWithAddendumExts = new List<Contract>();
        map<id,Contract> finalmap= new map<id,Contract>();
        List<Contract> CurrentUpdateList= new List<Contract>();
        List<Contract> returnList= new List<Contract>();
        
        Map<String, Double> currenMap = new Map<String, Double>();
        List<CurrencyType> currenLst = new List<CurrencyType>();
        string finalCurrency;
        for(contract con: cont){
            //Fetch all IME parent contracts
            if(con.recordtypeid == rtIMEParent){
                parentContracts.add(con.Id);
            }
            //Fetch all IME Child contracts and addendum extensions
            if(con.recordtypeid == rtChildContractRecType || con.recordtypeid == rtAddendumExt){
                ChildContracts.add(con.id);
                //
                //parentContracts = [SELECT ID  FROM Contract WHERE ID =: con.Main_Contract__c];
            }
        }
        
        // Fetch parent contract record from child record. 
        if(ChildContracts.size() > 0){
            List<Contract> cList = [select ID, Name,Main_Contract__c,Total_Annual_Value_Opportunities__c,IME_Annual_Value_Opportunities__c,recordTypeID FROM CONTRACT WHERE id IN:ChildContracts];
            for(Contract ct : cList){
                getParentId.put(ct.Id, ct.Main_Contract__c);
                parentContracts.add(ct.Main_Contract__c);
            }
            
        }
        if(parentContracts.size() > 0) {
            currenLst = [Select Id, ConversionRate, ISOCode  from CurrencyType];
            for(CurrencyType objCurren: currenLst)
            {
                currenMap.put(objCurren.ISOCode , objCurren.ConversionRate);
                System.debug('--- objCurren.ISOCode---' +objCurren.ISOCode);
                System.debug('---objCurren.ConversionRate---' +objCurren.ConversionRate);
            }
            List<contract> contractsList = [SELECT ID, Name,Total_Annual_Value_Opportunities__c,IME_Annual_Value_Opportunities__c,recordTypeID,Contract_Signed_Date__c,currencyISOcode,Status,  
                                            (SELECT ID, Name,Total_Annual_Value_Opportunities__c,IME_Annual_Value_Opportunities__c,recordTypeID,Contract_Signed_Date__c,
                                             currencyISOcode,Status  FROM Addendums__r 
                                             WHERE recordTypeID in: AnnualValueContracts
                                             AND     Status in ('Activated','Cancelled','Terminated')
                                             AND     IME_Annual_Value_Opportunities__c != null
                                             order by Contract_Signed_Date__c,name
                                            ) 
                                            FROM    Contract
                                            WHERE   ID in:parentContracts
                                            AND     Status in ('Activated','Cancelled','Terminated')
                                           ];
            
            system.debug('contractsList:'+ contractsList);
            
            if(contractsList.size() > 0){
                //iterate through parent
                for(Contract parent: contractsList){
                    isAddendumExt = false;
                    //iterate through child records
                    for(contract child: parent.Addendums__r){
                        system.debug('child.RecordTypeId:'+ child.RecordTypeId + ' rtAddendumExt:'+ rtAddendumExt);
                        if((child.RecordTypeId == rtAddendumExt) && 
                           (child.IME_Annual_Value_Opportunities__c != null) &&
                           (child.Status == 'Activated')
                          ){
                              isAddendumExt = true;
                          }
                    }
                    //seperate all parent contracts with & without addendum extension records
                    if(isAddendumExt){
                        ContractsWithAddendumExts.add(parent);
                    }
                    else{
                        ContractsWithOutAddendumExts.add(parent);
                    }  
                    system.debug(' ContractsWithAddendumExts:'+  ContractsWithAddendumExts);
                    system.debug(' ContractsWithOutAddendumExts:'+  ContractsWithOutAddendumExts);
                }
            }
            
            if(ContractsWithOutAddendumExts.size() > 0){
                //sum all annual value opportunities and store in map 
                for(contract parent:ContractsWithOutAddendumExts ){
                    Total_Annual_Value =0;
                    
                    if((parent.IME_Annual_Value_Opportunities__c != null) &&(parent.status == 'Activated')){
                        system.debug('id:' +parent.Id + 'parent currency: '+ parent.CurrencyIsoCode + 'IME_Annual_Value_Opportunities__c:'+ parent.IME_Annual_Value_Opportunities__c);
                        if(parent.CurrencyIsoCode == 'USD'){
                            Total_Annual_Value = parent.IME_Annual_Value_Opportunities__c;
                            finalCurrency =  parent.CurrencyIsoCode;  
                        }
                        else
                        {
                            Total_Annual_Value = (1/currenMap.get(parent.currencyISOcode) * parent.IME_Annual_Value_Opportunities__c);
                            finalCurrency =  parent.CurrencyIsoCode;  
                        }
                        
                    }
                    
                    system.debug('parent.Addendums__r:'+ parent.Addendums__r);
                    for(contract child: parent.Addendums__r){
                        system.debug('child.IME_Annual_Value_Opportunities__c:'+ child.IME_Annual_Value_Opportunities__c);
                        if((child.IME_Annual_Value_Opportunities__c != null) && (child.status == 'Activated')){
                            system.debug('child currency:'+ child.currencyISOcode);
                            system.debug('conversion:'+ currenMap.get(child.currencyISOcode));
                            system.debug('child.IME_Annual_Value_Opportunities__c:'+ child.IME_Annual_Value_Opportunities__c);
                            system.debug('Total_Annual_Value:'+ Total_Annual_Value);
                            system.debug('Total_Annual_Value * currenMap.get(child.currencyISOcode):'+ (Total_Annual_Value * currenMap.get(child.currencyISOcode)));
                            system.debug('finalCurrency:'+ finalCurrency);
                            
                            if((child.IME_Annual_Value_Opportunities__c!=0) ){
                                system.debug('finalCurrency:'+ finalCurrency + ' child.CurrencyIsoCode:'+child.CurrencyIsoCode + ' child.ID:'+ child.ID);
                                if(child.CurrencyIsoCode != 'USD'){
                                    Total_Annual_Value = Total_Annual_Value + (1/currenMap.get(child.currencyISOcode) * child.IME_Annual_Value_Opportunities__c);
                                    finalCurrency =  child.CurrencyIsoCode;  
                                }
                                else
                                {
                                    Total_Annual_Value = Total_Annual_Value  + child.IME_Annual_Value_Opportunities__c;
                                }
                                
                                system.debug('finalCurrency:'+ finalCurrency);
                            }
                        }
                    }
                    if(Total_Annual_Value < 0){
                        Total_Annual_Value =0;
                    }
                    system.debug('Total_Annual_Value:'+ Total_Annual_Value);
                    system.debug('finalCurrency:'+ finalCurrency + ' parent.currencyISOcode:'+parent.currencyISOcode + ' parent.ID:'+ parent.ID); 
                    TotalAnnualValueList.put(parent.ID,Total_Annual_Value);
                    
                }
                //Update Total annual value by iterate through parent and child contracts 
                for(contract parent:ContractsWithOutAddendumExts ){
                    if(parent.CurrencyIsoCode == 'USD'){
                        parent.Total_Annual_Value_Opportunities__c =    TotalAnnualValueList.get(parent.id) ;
                    }
                    else{
                        parent.Total_Annual_Value_Opportunities__c =    TotalAnnualValueList.get(parent.id) * currenMap.get(parent.currencyISOcode);
                    }
                    
                    system.debug('parent.Total_Annual_Value_Opportunities__c:'+ parent.Total_Annual_Value_Opportunities__c);
                    for(contract child: parent.Addendums__r){
                        if(child.currencyISOcode!= 'USD'){
                            child.Total_Annual_Value_Opportunities__c =TotalAnnualValueList.get(parent.id) * currenMap.get(child.currencyISOcode);
                        }
                        else
                        {
                            child.Total_Annual_Value_Opportunities__c =TotalAnnualValueList.get(parent.id);
                        }
                        system.debug('child.Total_Annual_Value_Opportunities__c:'+ child.Total_Annual_Value_Opportunities__c);
                        system.debug('child:'+ child);
                        finalmap.put(child.ID,child);
                    }
                    finalmap.put(parent.Id,parent);
                }
            }
            system.debug(' finalmap:'+  finalmap);
            
            
            if(ContractsWithAddendumExts.size() > 0){
                for(Contract parent:ContractsWithAddendumExts){
                    startDate= null;
                    for(contract child: parent.Addendums__r){
                        if(child.RecordTypeId == rtAddendumExt ){
                            startDate =child.Contract_Signed_Date__c;
                        }
                    }
                    AddendumExtStartDate.put(parent.Id,startDate);
                }
                
                for(Contract parent:ContractsWithAddendumExts){
                    
                    Total_Annual_Value =0;
                    system.debug('parent.Addendums__r:'+parent.Addendums__r);
                    for(contract child: parent.Addendums__r){
                        if(child.Contract_Signed_Date__c >= AddendumExtStartDate.get(parent.Id) ){
                            if((child.IME_Annual_Value_Opportunities__c!=0) && (child.status=='Activated') && child.RecordTypeId == rtAddendumExt){
                                if(child.currencyISOcode!= 'USD'){
                                    system.debug('currenMap.get(child.currencyISOcode):'+currenMap.get(child.currencyISOcode));
                                    Total_Annual_Value = Total_Annual_Value + (1/currenMap.get(child.currencyISOcode)  * child.IME_Annual_Value_Opportunities__c);
                                }
                                else{
                                    Total_Annual_Value = Total_Annual_Value + child.IME_Annual_Value_Opportunities__c;
                                }
                                
                            }
                        }
                    }
                    
                    if(Total_Annual_Value < 0){
                        Total_Annual_Value =0;
                    }
                }
                // If there is no opportunity linked to Addendum extention's then do normal calculation
                // This is similar to ContractsWithOutAddendumExts
                // If opportunity is linked to Addendum extention's then sum up Addendum extention's + childs records which 
                // are added after addendum
                if (Total_Annual_Value !=0)
                {
                    
                    for(Contract parent:ContractsWithAddendumExts){
                        
                        Total_Annual_Value =0;
                        system.debug('parent.Addendums__r:'+parent.Addendums__r);
                        for(contract child: parent.Addendums__r){
                            system.debug('child:'+child);
                            if(child.Contract_Signed_Date__c >= AddendumExtStartDate.get(parent.Id) ){
                                if((child.IME_Annual_Value_Opportunities__c!=0) && (child.status=='Activated') ){
                                    if(child.currencyISOcode!= 'USD'){
                                        system.debug('currenMap.get(child.currencyISOcode):'+currenMap.get(child.currencyISOcode));
                                        Total_Annual_Value = Total_Annual_Value + (1/currenMap.get(child.currencyISOcode)  * child.IME_Annual_Value_Opportunities__c);
                                    }
                                    else{
                                        Total_Annual_Value = Total_Annual_Value + child.IME_Annual_Value_Opportunities__c;
                                    }
                                    
                                }
                            }
                        }
                        
                        if(Total_Annual_Value < 0){
                            Total_Annual_Value =0;
                        }
                        
                        System.debug('Total_Annual_Value:'+Total_Annual_Value);
                        
                        // Here Total_Annual_Value is stored in USD
                        TotalAnnualValueList.put(parent.Id,Total_Annual_Value);                    
                        system.debug('TotalAnnualValueList:'+ TotalAnnualValueList);
                    }
                    
                    //Update Total annual value by iterate through parent and child contracts 
                for(contract parent:ContractsWithAddendumExts ){
                    if(parent.currencyISOcode != 'USD'){
                        parent.Total_Annual_Value_Opportunities__c = (currenMap.get(parent.currencyISOcode) * TotalAnnualValueList.get(parent.id));
                    }
                    else{
                        parent.Total_Annual_Value_Opportunities__c = TotalAnnualValueList.get(parent.id);
                    }
                    for(contract child: parent.Addendums__r){
                        system.debug('child.currencyISOcode:'+ child.currencyISOcode);
                        system.debug('currenMap.get(child.currencyISOcode):'+ currenMap.get(child.currencyISOcode));
                        system.debug('TotalAnnualValueList:'+ TotalAnnualValueList);
                        if(child.currencyISOcode != 'USD'){
                            child.Total_Annual_Value_Opportunities__c =(currenMap.get(child.currencyISOcode) * TotalAnnualValueList.get(parent.id));
                        }
                        else
                        {
                            child.Total_Annual_Value_Opportunities__c =TotalAnnualValueList.get(parent.id);
                        }
                        finalmap.put(child.Id,child);
                    }
                    finalmap.put(parent.Id,parent);
                }
                    
                }
                else{
                    //sum all annual value opportunities and store in map 
                    for(contract parent1:ContractsWithAddendumExts ){
                        Total_Annual_Value =0;
                        
                        if((parent1.IME_Annual_Value_Opportunities__c != null) &&(parent1.status == 'Activated')){
                            system.debug('id:' +parent1.Id + 'parent1 currency: '+ parent1.CurrencyIsoCode + 'IME_Annual_Value_Opportunities__c:'+ parent1.IME_Annual_Value_Opportunities__c);
                            if(parent1.CurrencyIsoCode == 'USD'){
                                Total_Annual_Value = parent1.IME_Annual_Value_Opportunities__c;
                                finalCurrency =  parent1.CurrencyIsoCode;  
                            }
                            else
                            {
                                Total_Annual_Value = (1/currenMap.get(parent1.currencyISOcode) * parent1.IME_Annual_Value_Opportunities__c);
                                finalCurrency =  parent1.CurrencyIsoCode;  
                            }
                            
                        }
                        
                        system.debug('parent1.Addendums__r:'+ parent1.Addendums__r);
                        for(contract child: parent1.Addendums__r){
                            system.debug('child.IME_Annual_Value_Opportunities__c:'+ child.IME_Annual_Value_Opportunities__c);
                            if((child.IME_Annual_Value_Opportunities__c != null) && (child.status == 'Activated')){
                                system.debug('child currency:'+ child.currencyISOcode);
                                system.debug('conversion:'+ currenMap.get(child.currencyISOcode));
                                system.debug('child.IME_Annual_Value_Opportunities__c:'+ child.IME_Annual_Value_Opportunities__c);
                                system.debug('Total_Annual_Value:'+ Total_Annual_Value);
                                system.debug('Total_Annual_Value * currenMap.get(child.currencyISOcode):'+ (Total_Annual_Value * currenMap.get(child.currencyISOcode)));
                                system.debug('finalCurrency:'+ finalCurrency);
                                
                                if((child.IME_Annual_Value_Opportunities__c!=0) ){
                                    system.debug('finalCurrency:'+ finalCurrency + ' child.CurrencyIsoCode:'+child.CurrencyIsoCode + ' child.ID:'+ child.ID);
                                    if(child.CurrencyIsoCode != 'USD'){
                                        Total_Annual_Value = Total_Annual_Value + (1/currenMap.get(child.currencyISOcode) * child.IME_Annual_Value_Opportunities__c);
                                        finalCurrency =  child.CurrencyIsoCode;  
                                    }
                                    else
                                    {
                                        Total_Annual_Value = Total_Annual_Value  + child.IME_Annual_Value_Opportunities__c;
                                    }
                                    
                                    system.debug('finalCurrency:'+ finalCurrency);
                                }
                            }
                        }
                        if(Total_Annual_Value < 0){
                            Total_Annual_Value =0;
                        }
                        system.debug('Total_Annual_Value:'+ Total_Annual_Value);
                        system.debug('finalCurrency:'+ finalCurrency + ' parent1.currencyISOcode:'+parent1.currencyISOcode + ' parent1.ID:'+ parent1.ID); 
                        TotalAnnualValueList.put(parent1.ID,Total_Annual_Value);
                        
                    }
                    //Update Total annual value by iterate through parent and child contracts 
                    for(contract parent2:ContractsWithAddendumExts ){
                        if(parent2.CurrencyIsoCode == 'USD'){
                            parent2.Total_Annual_Value_Opportunities__c =    TotalAnnualValueList.get(parent2.id) ;
                        }
                        else{
                            parent2.Total_Annual_Value_Opportunities__c =    TotalAnnualValueList.get(parent2.id) * currenMap.get(parent2.currencyISOcode);
                        }
                        
                        system.debug('parent2.Total_Annual_Value_Opportunities__c:'+ parent2.Total_Annual_Value_Opportunities__c);
                        for(contract child: parent2.Addendums__r){
                            if(child.currencyISOcode!= 'USD'){
                                child.Total_Annual_Value_Opportunities__c =TotalAnnualValueList.get(parent2.id) * currenMap.get(child.currencyISOcode);
                            }
                            else
                            {
                                child.Total_Annual_Value_Opportunities__c =TotalAnnualValueList.get(parent2.id);
                            }
                            system.debug('child.Total_Annual_Value_Opportunities__c:'+ child.Total_Annual_Value_Opportunities__c);
                            system.debug('child:'+ child);
                            finalmap.put(child.ID,child);
                        }
                        finalmap.put(parent2.Id,parent2);
                    }
                    
                }   
            }
            
            system.debug(' finalmap:'+  finalmap);            
            system.debug(finalmap);
            
            update finalmap.values();
            
        }
        
    }
    
    public void UpdateParentAndChild(map<id,contract> ActualIds,map<id,contract> oldMap){
        System.debug(' UpdateParentAndChild called:'+ ActualIds);
        AnnualValueContracts.add(rtAddendumExt);
        AnnualValueContracts.add(rtAddendum);
        map<id,contract> filteredAddendums = new map<id,contract>();
        
        List<contract> contractsParentAddendumList = [SELECT ID, Name,recordTypeID,Contract_Signed_Date__c,
                                                      (SELECT ID, Name,recordTypeID,Contract_Signed_Date__c FROM Addendums__r 
                                                       WHERE recordTypeID in: AnnualValueContracts
                                                       AND        Status ='Activated'                                             
                                                       order by Contract_Signed_Date__c Desc,name desc limit 1
                                                      ) 
                                                      FROM    Contract
                                                      WHERE   ID in:ActualIds.keySet()
                                                      AND     Status ='Activated'
                                                     ];
        
        
        system.debug('contractsParentAddendumList :'+contractsParentAddendumList);
        for(contract parent: contractsParentAddendumList ){
            System.debug('Parent.Id:' + parent.id);
            for(contract child:parent.Addendums__r){
                system.debug('child.id:'+ child.id);
                System.debug('ActualIds.get(parent.id).id :' + ActualIds.get(parent.id).id );
                if(child.id == ActualIds.get(parent.id).id ){
                    filteredAddendums.put(parent.id,child);
                }
            }
        }
        
        system.debug('filteredAddendums:'+filteredAddendums);
        
        List<contract> contractsParentChildList = [SELECT id,IME_Expiration_Notice_days__c,IME_Liability_Currency__c,IM_Max_Liability__c,SpecialTerms,
                                                   IME_MFP_Clause__c,IME_Non_Standard_Clause__c,IME_Financial_Controller_Comments__c,IME_Price_Increase_Type_Storage__c,
                                                   IME_Index_Storage__c,IME_Capped_Percentage_Storage__c,IME_Fixed_Pricing_Period_months_Storage__c,IME_End_of_Fixed_Pricing_Period_Storage__c,
                                                   IME_Special_Terms_Other_Storage__c,IME_Price_Increase_Type_Services__c,IME_Index_Services__c,IME_Capped_Percentage_Services__c,
                                                   IME_Special_Terms_Other_Services__c,IME_Fixed_Pricing_Period_months_Services__c,IME_End_of_Fixed_Pricing_Period_Services__c,
                                                   IME_Price_Increase_Type_Transport__c,IME_Index_Transport__c,IME_Capped_Percentage_Transport__c,IME_Special_Terms_Other_Transp__c,
                                                   IME_Fixed_Pricing_Period_months_Transp__c,IME_End_of_Fixed_Pricing_Period_Transp__c,IME_Price_Increase_Type_Product_Sales__c,
                                                   IME_Index_Product_Sales__c,IME_Capped_Percentage_Product_Sales__c,IME_Fixed_Pricing_Period_months_Prod_S__c,IME_End_of_Fixed_Pricing_Period_Prod_S__c,
                                                   IME_Special_Terms_Other_Prod_S__c,IM_Liability__c,Contract_Signed_Date__c,IME_Contract_Term_Type__c,ContractTerm,IM_Renewal_Term__c,StartDate,
                                                   (      SELECT id,IME_Expiration_Notice_days__c,IME_Liability_Currency__c,IM_Max_Liability__c,SpecialTerms,
                                                    IME_MFP_Clause__c,IME_Non_Standard_Clause__c,IME_Financial_Controller_Comments__c,IME_Price_Increase_Type_Storage__c,
                                                    IME_Index_Storage__c,IME_Capped_Percentage_Storage__c,IME_Fixed_Pricing_Period_months_Storage__c,IME_End_of_Fixed_Pricing_Period_Storage__c,
                                                    IME_Special_Terms_Other_Storage__c,IME_Price_Increase_Type_Services__c,IME_Index_Services__c,IME_Capped_Percentage_Services__c,
                                                    IME_Special_Terms_Other_Services__c,IME_Fixed_Pricing_Period_months_Services__c,IME_End_of_Fixed_Pricing_Period_Services__c,
                                                    IME_Price_Increase_Type_Transport__c,IME_Index_Transport__c,IME_Capped_Percentage_Transport__c,IME_Special_Terms_Other_Transp__c,
                                                    IME_Fixed_Pricing_Period_months_Transp__c,IME_End_of_Fixed_Pricing_Period_Transp__c,IME_Price_Increase_Type_Product_Sales__c,
                                                    IME_Index_Product_Sales__c,IME_Capped_Percentage_Product_Sales__c,IME_Fixed_Pricing_Period_months_Prod_S__c,IME_End_of_Fixed_Pricing_Period_Prod_S__c,
                                                    IME_Special_Terms_Other_Prod_S__c,IM_Liability__c,Contract_Signed_Date__c,IME_Contract_Term_Type__c,ContractTerm,IM_Renewal_Term__c,StartDate from Addendums__r 
                                                    WHERE recordTypeID =: rtChildContractRecType 
                                                    AND Status ='Activated'                                             
                                                    
                                                   ) 
                                                   FROM    Contract
                                                   WHERE   ID IN: filteredAddendums.keySet()
                                                   AND     Status ='Activated'
                                                  ];
        
        system.debug('contractsParentChildList count:'+ contractsParentChildList.size() +' contractsParentChildList ' + contractsParentChildList) ;
        system.debug('ParentChildContractList Count:'+  ParentChildContractList.size() +' ParentChildContractList:'+ ParentChildContractList);
       	ParentChildContractList.clear();
        for(contract con : contractsParentChildList ){   
            system.debug('con.ID:'+ con.Id);
             system.debug('ActualIds.get(con.id):'+ ActualIds.get(con.id));
            
            UpdateParentAndChildData(con,ActualIds.get(con.id),oldMap); 
            for(Contract c : con.Addendums__r){
                system.debug('c.ID:'+ c.Id);
                UpdateParentAndChildData(c,ActualIds.get(con.id),oldMap);
            }                                  
        }
        system.debug('ParentChildContractList:' + ParentChildContractList);
        if(ParentChildContractList.size() > 0){
            update ParentChildContractList;
        }
    }
    
    public void UpdateParentAndChildData(contract contractstoUpdate,Contract currentRec, map<id,contract> oldMap){
        
        System.debug('contractstoUpdate.IME_Expiration_Notice_days__c:'+ contractstoUpdate.IME_Expiration_Notice_days__c);
        System.debug('currentRec.IME_Expiration_Notice_days__c:'+ currentRec.IME_Expiration_Notice_days__c );
        if((contractstoUpdate.IME_Expiration_Notice_days__c != currentRec.IME_Expiration_Notice_days__c) 
           &&  (currentRec.IME_Expiration_Notice_days__c != null )  ){
               contractstoUpdate.IME_Expiration_Notice_days__c =    currentRec.IME_Expiration_Notice_days__c;
           }
        
        if((contractstoUpdate.IM_Liability__c!=  currentRec.IM_Liability__c)
           && (currentRec.IM_Liability__c!= null) )
            contractstoUpdate.IM_Liability__c=  currentRec.IM_Liability__c;
        
        if((contractstoUpdate.IM_Max_Liability__c !=  currentRec.IM_Max_Liability__c)
           && currentRec.IM_Max_Liability__c != null)
            contractstoUpdate.IM_Max_Liability__c =  currentRec.IM_Max_Liability__c;
        
        System.debug('contractstoUpdate.SpecialTerms:'+ contractstoUpdate.SpecialTerms);
        System.debug('currentRec.SpecialTerms:'+ currentRec.SpecialTerms);
        
        if(contractstoUpdate.SpecialTerms == null && currentRec.SpecialTerms != null){
            contractstoUpdate.SpecialTerms = 'ADD '+ currentRec.Name +  '\n' 
                + currentRec.SpecialTerms;
        }
        else if ((contractstoUpdate.SpecialTerms !=  currentRec.SpecialTerms)  &&
                 ((currentRec.SpecialTerms != null) && (currentRec.SpecialTerms != oldMap.get(currentRec.Id).SpecialTerms )
                  ||((currentRec.Status == 'Activated') && (oldMap.get(currentRec.Id).Status == 'Draft')))
                )                
        {
            contractstoUpdate.SpecialTerms =  contractstoUpdate.SpecialTerms + '\n ADD '+ currentRec.Name +  '\n' + currentRec.SpecialTerms;
        }
        
        
        if((currentRec.IME_MFP_Clause__c!= null) && (currentRec.IME_MFP_Clause__c =='Yes'))
            contractstoUpdate.IME_MFP_Clause__c =  currentRec.IME_MFP_Clause__c;
        
        if((currentRec.IME_Non_Standard_Clause__c != null) && (currentRec.IME_Non_Standard_Clause__c == 'Yes'))
            contractstoUpdate.IME_Non_Standard_Clause__c =  currentRec.IME_Non_Standard_Clause__c;
        
        System.debug('IME_Financial_Controller_Comments__c:'+ currentRec.IME_Financial_Controller_Comments__c);
        System.debug('oldMap.IME_Financial_Controller_Comments__c:'+ oldMap.get(currentRec.Id).IME_Financial_Controller_Comments__c);
        
        if ((contractstoUpdate.IME_Financial_Controller_Comments__c == null) && (currentRec.IME_Financial_Controller_Comments__c != null)){
            contractstoUpdate.IME_Financial_Controller_Comments__c = 'ADD '+ currentRec.Name +  '\n'  
                + currentRec.IME_Financial_Controller_Comments__c;
        }
        else if((currentRec.IME_Financial_Controller_Comments__c != null) && (contractstoUpdate.IME_Financial_Controller_Comments__c !=  currentRec.IME_Financial_Controller_Comments__c)
                && (((currentRec.IME_Financial_Controller_Comments__c !=oldMap.get(currentRec.Id).IME_Financial_Controller_Comments__c)) 
                    ||((currentRec.Status == 'Activated') && (oldMap.get(currentRec.Id).Status == 'Draft'))))
        {
            system.debug('in Financial_Controller_Comments__c:');
            contractstoUpdate.IME_Financial_Controller_Comments__c = contractstoUpdate.IME_Financial_Controller_Comments__c + '\n ADD '+ currentRec.Name 
                +  '\n' + currentRec.IME_Financial_Controller_Comments__c ;
        }   
        
        if((contractstoUpdate.IME_Special_Terms_Other_Storage__c == null) && (currentRec.IME_Special_Terms_Other_Storage__c!= null))
        {
            contractstoUpdate.IME_Special_Terms_Other_Storage__c = 'ADD ' + currentRec.Name 
                + '\n' + currentRec.IME_Special_Terms_Other_Storage__c;
        }
        else if((currentRec.IME_Special_Terms_Other_Storage__c != null) 
                && ((currentRec.IME_Special_Terms_Other_Storage__c != oldMap.get(currentRec.Id).IME_Special_Terms_Other_Storage__c  )
                    ||((currentRec.Status == 'Activated') && (oldMap.get(currentRec.Id).Status == 'Draft')))
               )
        {
            contractstoUpdate.IME_Special_Terms_Other_Storage__c = contractstoUpdate.IME_Special_Terms_Other_Storage__c +
                '\n ADD ' + currentRec.Name 
                + '\n' + currentRec.IME_Special_Terms_Other_Storage__c;
        } 
        
        if((currentRec.IME_Price_Increase_Type_Storage__c != null) && (contractstoUpdate.IME_Price_Increase_Type_Storage__c !=  currentRec.IME_Price_Increase_Type_Storage__c))
            contractstoUpdate.IME_Price_Increase_Type_Storage__c =  currentRec.IME_Price_Increase_Type_Storage__c;
        
        if((currentRec.IME_Price_Increase_Type_Storage__c != 'Other')){
            contractstoUpdate.IME_Special_Terms_Other_Storage__c ='';
        }
        
        if((currentRec.IME_Price_Increase_Type_Storage__c != null ) && (contractstoUpdate.IME_Index_Storage__c !=  currentRec.IME_Index_Storage__c))
            contractstoUpdate.IME_Index_Storage__c =  currentRec.IME_Index_Storage__c;
        
        
        if((currentRec.IME_Price_Increase_Type_Storage__c != null) && (contractstoUpdate.IME_Capped_Percentage_Storage__c !=  currentRec.IME_Capped_Percentage_Storage__c))  
            contractstoUpdate.IME_Capped_Percentage_Storage__c =  currentRec.IME_Capped_Percentage_Storage__c;
        
        if((currentRec.IME_End_of_Fixed_Pricing_Period_Storage__c != null) && (contractstoUpdate.IME_End_of_Fixed_Pricing_Period_Storage__c !=  currentRec.IME_End_of_Fixed_Pricing_Period_Storage__c)){
            contractstoUpdate.IME_End_of_Fixed_Pricing_Period_Storage__c =  currentRec.IME_End_of_Fixed_Pricing_Period_Storage__c;
            contractstoUpdate.IME_Fixed_Pricing_Period_months_Storage__c = null;
        }
        
        
        if((contractstoUpdate.IME_Special_Terms_Other_Services__c== null)
           && (currentRec.IME_Special_Terms_Other_Services__c!= null ))
            contractstoUpdate.IME_Special_Terms_Other_Services__c =  'ADD '+ currentRec.Name 
            +'\n' + currentRec.IME_Special_Terms_Other_Services__c;
        else if((currentRec.IME_Special_Terms_Other_Services__c!= null) && 
                ((currentRec.IME_Special_Terms_Other_Services__c != oldMap.get(currentRec.Id).IME_Special_Terms_Other_Services__c)
                 ||((currentRec.Status == 'Activated') && (oldMap.get(currentRec.Id).Status == 'Draft')))
               )
        {
            contractstoUpdate.IME_Special_Terms_Other_Services__c =  contractstoUpdate.IME_Special_Terms_Other_Services__c + '\n ADD '+ currentRec.Name 
                +'\n' + currentRec.IME_Special_Terms_Other_Services__c;
        }  
        
        if((currentRec.IME_Price_Increase_Type_Services__c!= null) && (contractstoUpdate.IME_Price_Increase_Type_Services__c !=  currentRec.IME_Price_Increase_Type_Services__c))
            contractstoUpdate.IME_Price_Increase_Type_Services__c =  currentRec.IME_Price_Increase_Type_Services__c;
        
        if((currentRec.IME_Price_Increase_Type_Services__c != 'Other')){
            contractstoUpdate.IME_Special_Terms_Other_Services__c ='';
        }
        
        if((currentRec.IME_Price_Increase_Type_Services__c!= null) && (contractstoUpdate.IME_Index_Services__c !=  currentRec.IME_Index_Services__c))
            contractstoUpdate.IME_Index_Services__c =  currentRec.IME_Index_Services__c;
        
        if((currentRec.IME_Price_Increase_Type_Services__c!= null) && (contractstoUpdate.IME_Capped_Percentage_Services__c !=  currentRec.IME_Capped_Percentage_Services__c))
            contractstoUpdate.IME_Capped_Percentage_Services__c =  currentRec.IME_Capped_Percentage_Services__c;
        
        if((currentRec.IME_End_of_Fixed_Pricing_Period_Services__c!= null) 
           && (contractstoUpdate.IME_End_of_Fixed_Pricing_Period_Services__c !=  currentRec.IME_End_of_Fixed_Pricing_Period_Services__c))  {
               contractstoUpdate.IME_End_of_Fixed_Pricing_Period_Services__c =  currentRec.IME_End_of_Fixed_Pricing_Period_Services__c;
               contractstoUpdate.IME_Fixed_Pricing_Period_months_Services__c = null;
           }
        
        if((contractstoUpdate.IME_Special_Terms_Other_Transp__c == null) && (currentRec.IME_Special_Terms_Other_Transp__c!= null))
        {
            contractstoUpdate.IME_Special_Terms_Other_Transp__c =  'ADD ' + currentRec.Name 
                + '\n' + currentRec.IME_Special_Terms_Other_Transp__c;
        }
        else if((currentRec.IME_Special_Terms_Other_Transp__c!= null) && 
                ((currentRec.IME_Special_Terms_Other_Transp__c !=oldMap.get(currentRec.Id).IME_Special_Terms_Other_Transp__c  )
                 ||((currentRec.Status == 'Activated') && (oldMap.get(currentRec.Id).Status == 'Draft')))
               )
            contractstoUpdate.IME_Special_Terms_Other_Transp__c = contractstoUpdate.IME_Special_Terms_Other_Transp__c +
            '\n ADD ' + currentRec.Name 
            + '\n' + currentRec.IME_Special_Terms_Other_Transp__c;
        
        if((currentRec.IME_Price_Increase_Type_Transport__c!= null) 
           && (contractstoUpdate.IME_Price_Increase_Type_Transport__c !=  currentRec.IME_Price_Increase_Type_Transport__c))
            contractstoUpdate.IME_Price_Increase_Type_Transport__c =  currentRec.IME_Price_Increase_Type_Transport__c;
        
        if((currentRec.IME_Price_Increase_Type_Transport__c != 'Other')){
            contractstoUpdate.IME_Special_Terms_Other_Transp__c ='';
        }
        if((currentRec.IME_Price_Increase_Type_Transport__c!= null)
           && (contractstoUpdate.IME_Index_Transport__c !=  currentRec.IME_Index_Transport__c))
            contractstoUpdate.IME_Index_Transport__c =  currentRec.IME_Index_Transport__c;
        
        if((currentRec.IME_Price_Increase_Type_Transport__c!= null) 
           && (contractstoUpdate.IME_Capped_Percentage_Transport__c !=  currentRec.IME_Capped_Percentage_Transport__c))
            contractstoUpdate.IME_Capped_Percentage_Transport__c =  currentRec.IME_Capped_Percentage_Transport__c;
        
        if((currentRec.IME_End_of_Fixed_Pricing_Period_Transp__c!= null) 
           && (contractstoUpdate.IME_End_of_Fixed_Pricing_Period_Transp__c !=  currentRec.IME_End_of_Fixed_Pricing_Period_Transp__c)){
               contractstoUpdate.IME_End_of_Fixed_Pricing_Period_Transp__c =  currentRec.IME_End_of_Fixed_Pricing_Period_Transp__c;
               contractstoUpdate.IME_Fixed_Pricing_Period_months_Transp__c = null;
           }
        
        if((contractstoUpdate.IME_Special_Terms_Other_Prod_S__c == null) && (currentRec.IME_Special_Terms_Other_Prod_S__c!= null))
        {
            contractstoUpdate.IME_Special_Terms_Other_Prod_S__c =  'ADD ' + currentRec.Name 
                + '\n' + currentRec.IME_Special_Terms_Other_Prod_S__c;
        }
        else if((currentRec.IME_Special_Terms_Other_Prod_S__c!= null) && 
                ((currentRec.IME_Special_Terms_Other_Prod_S__c !=oldMap.get(currentRec.Id).IME_Special_Terms_Other_Prod_S__c  )
                 ||((currentRec.Status == 'Activated') && (oldMap.get(currentRec.Id).Status == 'Draft')))
               )
            contractstoUpdate.IME_Special_Terms_Other_Prod_S__c = contractstoUpdate.IME_Special_Terms_Other_Prod_S__c +
            '\n ADD ' + currentRec.Name 
            + '\n' + currentRec.IME_Special_Terms_Other_Prod_S__c;
        
        if((currentRec.IME_Price_Increase_Type_Product_Sales__c!= null) 
           && (contractstoUpdate.IME_Price_Increase_Type_Product_Sales__c !=  currentRec.IME_Price_Increase_Type_Product_Sales__c))
            contractstoUpdate.IME_Price_Increase_Type_Product_Sales__c =  currentRec.IME_Price_Increase_Type_Product_Sales__c;
        
        if((currentRec.IME_Price_Increase_Type_Product_Sales__c != 'Other')){
            contractstoUpdate.IME_Special_Terms_Other_Prod_S__c ='';
        }
        if((currentRec.IME_Price_Increase_Type_Product_Sales__c!= null) 
           && (contractstoUpdate.IME_Index_Product_Sales__c !=  currentRec.IME_Index_Product_Sales__c))
            contractstoUpdate.IME_Index_Product_Sales__c =  currentRec.IME_Index_Product_Sales__c;
        
        if((currentRec.IME_Price_Increase_Type_Product_Sales__c!= null) 
           && (contractstoUpdate.IME_Capped_Percentage_Product_Sales__c !=  currentRec.IME_Capped_Percentage_Product_Sales__c))
            contractstoUpdate.IME_Capped_Percentage_Product_Sales__c =  currentRec.IME_Capped_Percentage_Product_Sales__c;
        
        
        if((currentRec.IME_End_of_Fixed_Pricing_Period_Prod_S__c!= null)
           && (contractstoUpdate.IME_End_of_Fixed_Pricing_Period_Prod_S__c !=  currentRec.IME_End_of_Fixed_Pricing_Period_Prod_S__c)){
               contractstoUpdate.IME_End_of_Fixed_Pricing_Period_Prod_S__c =  currentRec.IME_End_of_Fixed_Pricing_Period_Prod_S__c;
               contractstoUpdate.IME_Fixed_Pricing_Period_months_Prod_S__c = null;
           }
        
        
        
        if(currentRec.recordTypeId == rtAddendumExt){
            if((currentRec.StartDate != contractstoUpdate.StartDate) ){
                contractstoUpdate.StartDate = currentRec.StartDate;
            }
            
            if((currentRec.IME_Contract_Term_Type__c != contractstoUpdate.IME_Contract_Term_Type__c ) ){
                contractstoUpdate.IME_Contract_Term_Type__c = currentRec.IME_Contract_Term_Type__c;
            }
            // If contract term type is Fixed term or Evergreen then ContractTerm field is mandatory
            if(((currentRec.IME_Contract_Term_Type__c =='Fixed term') ||(currentRec.IME_Contract_Term_Type__c =='Evergreen') )
               &&(currentRec.ContractTerm != null))
            {
                contractstoUpdate.ContractTerm    = currentRec.ContractTerm;
            }                    
            else if( (currentRec.IME_Contract_Term_Type__c !='Fixed term') && (currentRec.IME_Contract_Term_Type__c !='Evergreen')){
                contractstoUpdate.ContractTerm    = currentRec.ContractTerm;
            }
            
            if((currentRec.IM_Renewal_Term__c != contractstoUpdate.IM_Renewal_Term__c ) ){
                contractstoUpdate.IM_Renewal_Term__c = currentRec.IM_Renewal_Term__c;
            }
            
            if((contractstoUpdate.IME_Liability_Currency__c !=  currentRec.IME_Liability_Currency__c)
               && (currentRec.IME_Liability_Currency__c != null)
              )
                contractstoUpdate.IME_Liability_Currency__c =  currentRec.IME_Liability_Currency__c;
        }
        
         boolean flag = false;
        //Check whether contract already exists in List
        for(Contract c: ParentChildContractList){
            if (c.id == contractstoUpdate.id){
                flag = true;
            }
        }
        
        if(flag == false){        
        	ParentChildContractList.add(contractstoUpdate);
             system.debug('ParentChildContractList Count:'+  ParentChildContractList.size() +' ParentChildContractList:'+ ParentChildContractList);
       }
    }
}
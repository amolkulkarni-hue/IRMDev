/*****************************************************************************************************
* Class: QTB_FuelSurchargesBatch
* Author: IRM
* Requirement: Gitlab 2719
* Purpose : This is to add new fuel Surcharge Usage record related to Pre-bill run Process.
* Change History: 05/05/2021
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Gopinandan   05/05/2021
* IRM/Virtusa  11/11/2021    #5998,  #5924 -- Fuel Surcharge Usages
* IRM/Virtusa  11/26/2021    #6403 Double Fuel Surcharge amount is calculated -- Defect fix
* IRM/Virtusa  12/06/2021    #6518 Fuel Surcharge invoice line is aggregating the usages subtotal to calculate the % amount
* IRM/TCS      18/05/2023    #15325 Add Proper product identifier and Bill Code for the Fuel Surcharge product in the PreBill Run
*******************************************************************************************************/
global class QTB_FuelSurchargesBatch implements Database.Batchable<sObject>,Database.Stateful {
    public string invoiceBatch;
    public date targetDate;
    public Id preBillcheckRecordId;
    public static boolean throwExplicitException = false;
    public static final string FUEL_SURCHARGES_BATCH = QTB_FuelSurchargesBatch.class.getName();
    public static final String PENDING = QTB_Constants.INVOICE_STATUS_PENDING_BILLING;
    public static final String QUEUED_FOR_INVOICE = QTB_Constants.STATUS_QUEUED_FOR_INVOICE;    
    public Map<String, Date> mapBatchesToDate = new Map<String, Date>();
    public Set<String> invSchBatch = new Set<String>();
    public static final Id accountBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
    public List<QTB_Bill_Code_Product_Lookup__c> billCode;
    public Map<string, List<QTB_Fuel_Surcharge_Config__c>> fuelSurchargeUSStartDateMap = new Map<string, List<QTB_Fuel_Surcharge_Config__c>>();
    public Set<Id> accountIds = new Set<Id>();
    Map<String,String> oracleProductCodeWithFuelSurchargeProductCodeMap = new Map<String,String>();
    Map<string,string> ProductCodeTobillCodeMap = new Map<string,string>();
    public string rebillType = '';
    public Set<Id> rebillOrderIds = new Set<Id>(); // Gitlab US#24172 (Credit/Rebill Billnow)
    public List<QTB_Bill_Flow_Controller__c> billFlowList; // Gitlab US#24172 (Credit/Rebill Billnow)
    
    public QTB_FuelSurchargesBatch(string Schedularbatch, Date targtDate, Id prebillFlowRecord){
        mapBatchesToDate.put(Schedularbatch,targtDate);
        invoiceBatch = Schedularbatch;
        targetDate = targtDate;
        preBillcheckRecordId = prebillFlowRecord;
        //create new map of Country & List of Fuel Surchange Map
        for(QTB_Fuel_Surcharge_Config__c fuelS: [SELECT Id,QTB_IM_Country__r.Name,QTB_Surcharge__c,QTB_From_Date__c,QTB_To_Date__c,CreatedDate
                                                 FROM QTB_Fuel_Surcharge_Config__c order by CreatedDate desc])
        {
            if(fuelSurchargeUSStartDateMap.containsKey(fuelS.QTB_IM_Country__r.Name)){
                fuelSurchargeUSStartDateMap.get(fuelS.QTB_IM_Country__r.Name).add(fuelS);
            }
            else{
                fuelSurchargeUSStartDateMap.put(fuelS.QTB_IM_Country__r.Name, new List<QTB_Fuel_Surcharge_Config__c>{fuelS});
            }
        }
        //Gitlab US#22511 -- instead of equals to change to contains of "Rebill Run"
        // Gitlab US#24172 (Credit/Rebill Billnow)
        if(Schedularbatch.containsIgnoreCase('Rebill Run')){            
            billFlowList = [SELECT Id,
                            QTB_Rebill_Order__r.QTB_Rebill_Type__c, QTB_Rebill_Order__c, QTB_Rebill_Order__r.QTB_OrderCategory__c,QTB_Rebill_Order__r.AccountId
                            From QTB_Bill_Flow_Controller__c WHERE Id = :prebillFlowRecord  limit 1];
            if(billFlowList[0].QTB_Rebill_Order__c != null && billFlowList[0].QTB_Rebill_Order__r.AccountId != null) {
                accountIds.add(billFlowList[0].QTB_Rebill_Order__r.AccountId);
                rebillOrderIds.add(billFlowList[0].QTB_Rebill_Order__c);
                rebillType = billFlowList[0].QTB_Rebill_Order__r.QTB_Rebill_Type__c;  //either Split or Regular
            }  
        }
        
        //US #5998, populate productIdentifier1 on usage.
        string FSProduct = 'Fuel Surcharge';
        List<Product2> prd = [Select Id,ProductCode From Product2 where Name =: FSProduct];           
        if( !prd.isEmpty() && prd.size() >0) {            
            for(QTB_Bill_Code_Product_Lookup__c billCodeLook : [Select Id, Name,QTB_Source_Bill_Code__c,QTB_Product2__c,QTB_Country__r.Name,QTB_Product2__r.ProductCode 
                                                                From QTB_Bill_Code_Product_Lookup__c where QTB_Product2__c  IN :prd ])
            {
                ProductCodeTobillCodeMap.put(billCodeLook.QTB_Product2__r.ProductCode + billCodeLook.QTB_Country__r.Name, billCodeLook.QTB_Source_Bill_Code__c);
                System.debug('billCodeLook@@'+billCodeLook);
            }
            System.debug('ProductCodeTobillCodeMap@@outsidefor'+ProductCodeTobillCodeMap);
        }
        System.debug('ProductCodeTobillCodeMap@@outsideif'+ProductCodeTobillCodeMap);
        system.debug('Fuel@@@@11--'+fuelSurchargeUSStartDateMap);
        
        //Gitlab US #12825
        //Fetching oracleProductCode with FuelSurchargeProductCode data from custom metadata
        List<QTB_Fuel_Surcharge_Oracle_Product_Code__mdt> fuelSurchargeOracleProductCodeMetadata = QTB_Fuel_Surcharge_Oracle_Product_Code__mdt.getAll().values();
        if(fuelSurchargeOracleProductCodeMetadata != null && !fuelSurchargeOracleProductCodeMetadata.isEmpty()){
            for(QTB_Fuel_Surcharge_Oracle_Product_Code__mdt fuelMDT : fuelSurchargeOracleProductCodeMetadata ){
                //storing oracleProductCode & FuelSurchargeProductCode in map
                oracleProductCodeWithFuelSurchargeProductCodeMap.put(fuelMDT.QTB_Oracle_Product_Code__c,fuelMDT.QTB_FS_Product_Code_Code__c);
            }
        }
        System.debug('oracleProductCodeWithFuelSurchargeProductCodeMap@@'+oracleProductCodeWithFuelSurchargeProductCodeMap);       
    }
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
Requirement: Gitlab 2719
Description: Query Account required records
**********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        invSchBatch.addAll(mapBatchesToDate.keySet());
        System.debug(invSchBatch);
        
        if (Test.isRunningTest()) {
            mapBatchesToDate.put('Norway-26th', date.newInstance(2021, 1, 27));
            invSchBatch.add('Norway-26th');
        }
        String query;
        //for Rebill invoice
        if(invoiceBatch.containsIgnoreCase('Rebill Run'))
        {
            // As part of GITLAB #16257,for Split rebill type We don't need to run execute method so we made the dummy query to return zero records
            if (rebillType == System.Label.QTB_SplitRebill) {  
                query = 'SELECT id FROM Account WHERE IsDeleted = true AND IsDeleted = false';
            }
            else { 
                query = 'SELECT id,QTB_Hold_Billing__c,QTB_Legal_Entity_Country__c,ParentId,QTB_Fuel_Surcharge_Exempt__c,QTB_Bill_Cycle_Day__c,QTB_Customer_Number__c,QTB_Customer_District__c,CurrencyIsoCode ' +
                        ' FROM Account where Id IN:accountIds AND RecordTypeId=: accountBillRecordTypeId and ParentId != null and QTB_Hold_Billing__c = False and QTB_Fuel_Surcharge_Exempt__c=False';
            }
        }
        //for Regualr invoice we have invoice schedular
        else{
            query = 'SELECT id,QTB_Hold_Billing__c,QTB_Legal_Entity_Country__c,ParentId,QTB_Fuel_Surcharge_Exempt__c,QTB_Bill_Cycle_Day__c,QTB_Customer_Number__c,QTB_Customer_District__c, CurrencyIsoCode ' +
                ' FROM Account where  RecordTypeId=: accountBillRecordTypeId and ParentId != null and QTB_Hold_Billing__c = False and  QTB_Bill_Cycle_Day__c IN :invSchBatch and QTB_Fuel_Surcharge_Exempt__c=False';
        }      
        return Database.getQueryLocator(query);
    }
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__UsageSummary__c>
Return Type: void
Requirement: Gitlab 2719
Description: Calculates Fuel Surcharges for each Billing Account
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        try {
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if (!scope.isEmpty()) {
                System.debug('scope.size@@'+scope.size());
                if (Test.isRunningTest()) {
                    mapBatchesToDate.put('Norway-26th', date.newInstance(2021, 1, 27));
                    invSchBatch.add('Norway-26th');
                    list<IM_Country__c> countryList = new list<IM_Country__c>();
                    IM_Country__c cou = new IM_Country__c();
                    cou.Name = 'Norway';
                    cou.Iso31662Code__c = 'Iso31662Code';
                    countryList.add(cou);
                    insert countryList;
                    QTB_Fuel_Surcharge_Config__c fs = new QTB_Fuel_Surcharge_Config__c();
                    fs.QTB_IM_Country__c = countryList[0].id;
                    fs.QTB_From_Date__c = date.newInstance(2021, 1, 24);
                    fs.QTB_Surcharge__c = 10;
                    fs.QTB_To_Date__c = date.newInstance(2021, 1, 28);
                    insert fs;
                    fuelSurchargeUSStartDateMap.put('Norway', new List<QTB_Fuel_Surcharge_Config__c>{fs});
                }
                
                Map<ID, Account> relatedAccs = new Map<ID, Account>();
                map<string, double> accountUSOrderTotalMap = new Map<string, double>();
                map<string, String> accountUSWithFuelSurchargeCodeMap = new Map<string, String>();
                map<string, Date> FSUSEndDateMap = new Map<string, Date>();
                map<string, id> keyToaccountIdMap = new map<string, id>();
                map<string, decimal> accountFuelSurchargeMap = new map<string, decimal>();
                List<blng__Usage__c> usgList = new List<blng__Usage__c>();
                Map<string, String> accountIdWithUsgSumMatchingAttributeMap = new Map<string, String>(); // GITLAB US - #25254 (Credit/Rebill Billnow)
                
                //Keep Account Id and Account 
                for (Account blngacc : scope) {
                    relatedAccs.put(blngacc.id, blngacc);
                    system.debug('Fuel@@@@00--'+blngacc);
                }
                system.debug('Fuel@@@@22--'+relatedAccs);
                Map<String, String> billedOrderNumberByAccountId = new Map<String, String>();
                String ProductId = '';
                string usgSummary = ' SELECT id, blng__OrderProduct__r.QTB_PrefixMatchingID__c,blng__Order__r.OrderNumber,QTB_Legal_Entity_Country__c,blng__OrderProduct__r.OrderId,blng__Order__c, '+
                    ' blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,blng__Account__r.QTB_Minimum_Storage_Charges__c, '+
                    ' blng__Subtotal__c,blng__SummaryStartDate__c,blng__SummaryEndDate__c,blng__UnitPrice__c,blng__MatchingAttribute__c, '+
                    ' blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c '+ 
                    ' FROM blng__UsageSummary__c WHERE '+
                    ' blng__OrderProduct__r.Product2.QTB_Fuel_Surcharge_Applicable__c = TRUE '+
                    ' AND blng__Subtotal__c != NULL '+
                    ' AND blng__Subtotal__c > 0 '+
                    ' AND blng__OrderProduct__r.SBQQ__Activated__c = TRUE '+
                    ' AND blng__Status__c = :QUEUED_FOR_INVOICE ';
                // Gitlab US#24172 (Credit/Rebill Billnow)
                if(invoiceBatch.containsIgnoreCase('Rebill Run')){
                    usgSummary+= ' AND blng__Order__c IN: rebillOrderIds ';
                }else{
                    Set<id> ids = relatedAccs.keySet();
                    usgSummary+= ' AND blng__InvoiceRunProcessingStatus__c = :PENDING AND blng__Account__c IN :ids';
                }
                System.debug('usgSummary@@'+usgSummary);
                
                List<blng__UsageSummary__c> usgSumList = Database.query(usgSummary);
				// GITLAB US - #25254 (Credit/Rebill Billnow) - To get the FS usage summery based on OrderId
                List<blng__UsageSummary__c> usegeSumlistForFS = new  List<blng__UsageSummary__c>();
                Set<Id> orderIds = new Set<Id>(); 
                if(usgSumList != null && !usgSumList.isEmpty()){
                    for(blng__UsageSummary__c usgsumm : usgSumList){
                        if(usgsumm.blng__Order__c != null){
                            orderIds.add(usgsumm.blng__Order__c); 
                        }
                    }
                    if(orderIds != null && !orderIds.isEmpty()){
                        usegeSumlistForFS = [SELECT id,blng__MatchingAttribute__c 
                                             From blng__UsageSummary__c 
                                             WHERE blng__OrderProduct__r.OrderId IN :orderIds AND
                                             blng__OrderProduct__r.QTB_Product_Name__c = 'Fuel Surcharge'];
                    }
                }
                
                //Get all the Usage Summary related to the scope
                for (blng__UsageSummary__c eachAccountUS :usgSumList) {
                    //accountUSOrderTotalMap = new Map<id, double>(); //Git #6518 fix, initialize the obj in for loop to reset new value for every usageSummary to get correct calculation for usage 
                    /* GitLab # 1733 Stand */
                    System.debug('inside for loop@@');
                    
                    billedOrderNumberByAccountId.put(
                        eachAccountUS.blng__Account__c+String.ValueOf(eachAccountUS.blng__SummaryStartDate__c) + String.ValueOf(eachAccountUS.blng__SummaryEndDate__c)+eachAccountUS.blng__Order__c+
                        eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c,
                        eachAccountUS.blng__OrderProduct__r.QTB_PrefixMatchingID__c <> null ?
                        eachAccountUS.blng__OrderProduct__r.QTB_PrefixMatchingID__c : ''
                    );
                    System.debug('billedOrderNumberByAccountId@@'+billedOrderNumberByAccountId);
					// GITLAB US - #25254 (Credit/Rebill Billnow)
                    if(usegeSumlistForFS!= null && !usegeSumlistForFS.isEmpty()){
                        accountIdWithUsgSumMatchingAttributeMap.put( eachAccountUS.blng__Account__c+String.ValueOf(eachAccountUS.blng__SummaryStartDate__c) + String.ValueOf(eachAccountUS.blng__SummaryEndDate__c)+eachAccountUS.blng__Order__c+eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c,
                                                                    usegeSumlistForFS[0].blng__MatchingAttribute__c); 
                    }else{
                        accountIdWithUsgSumMatchingAttributeMap.put(eachAccountUS.blng__Account__c,eachAccountUS.blng__MatchingAttribute__c);
                    }
                    
                    System.debug('accountIdWithUsgSumMatchingAttributeMap@@'+accountIdWithUsgSumMatchingAttributeMap);
                    system.debug('Fuel@@@@33--'+eachAccountUS.QTB_Legal_Entity_Country__c);
                    system.debug('Fuel@@@@44--'+fuelSurchargeUSStartDateMap.containsKey(eachAccountUS.QTB_Legal_Entity_Country__c));
                    system.debug('Fuel@@@@55--'+eachAccountUS.blng__SummaryEndDate__c);
                    system.debug('Fuel@@@@66--'+mapBatchesToDate.get(eachAccountUS.blng__Order__r.blng__InvoiceBatch__c));
                    
                    
                    //Check the Legal Country <=> FuelSurcharge Country & Usage Summary End date <=> FuelSurcharge Start/End date
                    if(fuelSurchargeUSStartDateMap.containsKey(eachAccountUS.QTB_Legal_Entity_Country__c) && eachAccountUS.blng__SummaryEndDate__c < mapBatchesToDate.get(eachAccountUS.blng__Order__r.blng__InvoiceBatch__c)){
                        //Get all the matching country's Fuel Surcharge records // Currently the assumption will be only for each month one record will be there
                        for(QTB_Fuel_Surcharge_Config__c fSurc : fuelSurchargeUSStartDateMap.get(eachAccountUS.QTB_Legal_Entity_Country__c)){
                            system.debug('Fuel@@@@77--'+fSurc.QTB_From_Date__c);
                            system.debug('Fuel@@@@88--'+eachAccountUS.blng__SummaryEndDate__c);
                            system.debug('Fuel@@@@99--'+fSurc.QTB_To_Date__c);
                            if(fSurc.QTB_From_Date__c <= eachAccountUS.blng__SummaryEndDate__c && fSurc.QTB_To_Date__c >= eachAccountUS.blng__SummaryEndDate__c){
                                //created unique key based on combination of AccountId + US StartDate + US EndDate + OrderId --> to avoid addition subtotal multiple times.
                                accountFuelSurchargeMap.put(eachAccountUS.blng__Account__c+String.ValueOf(eachAccountUS.blng__SummaryStartDate__c) + String.ValueOf(eachAccountUS.blng__SummaryEndDate__c)+eachAccountUS.blng__Order__c+eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c,fSurc.QTB_Surcharge__c);
                                FSUSEndDateMap.put(eachAccountUS.blng__Account__c+String.ValueOf(eachAccountUS.blng__SummaryStartDate__c) + String.ValueOf(eachAccountUS.blng__SummaryEndDate__c)+eachAccountUS.blng__Order__c+eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c,eachAccountUS.blng__SummaryEndDate__c);
                                keyToaccountIdMap.put(eachAccountUS.blng__Account__c+String.ValueOf(eachAccountUS.blng__SummaryStartDate__c) + String.ValueOf(eachAccountUS.blng__SummaryEndDate__c)+eachAccountUS.blng__Order__c+eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c,eachAccountUS.blng__Account__c);
                                accountUSWithFuelSurchargeCodeMap.put(
                                    eachAccountUS.blng__Account__c+String.ValueOf(eachAccountUS.blng__SummaryStartDate__c) + String.ValueOf(eachAccountUS.blng__SummaryEndDate__c)+eachAccountUS.blng__Order__c+eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c,
                                    oracleProductCodeWithFuelSurchargeProductCodeMap.get(eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c));
                                System.debug('accountUSWithFuelSurchargeCodeMap@@'+accountUSWithFuelSurchargeCodeMap);
                                if (
                                    accountUSOrderTotalMap.containsKey(eachAccountUS.blng__Account__c+String.ValueOf(eachAccountUS.blng__SummaryStartDate__c) + String.ValueOf(eachAccountUS.blng__SummaryEndDate__c)+eachAccountUS.blng__Order__c+eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c)
                                    //GIT-535- to take usage summaries before target day
                                ) {
                                    accountUSOrderTotalMap.put(
                                        eachAccountUS.blng__Account__c+String.ValueOf(eachAccountUS.blng__SummaryStartDate__c) + String.ValueOf(eachAccountUS.blng__SummaryEndDate__c)+eachAccountUS.blng__Order__c+eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c,
                                        accountUSOrderTotalMap.get(eachAccountUS.blng__Account__c+String.ValueOf(eachAccountUS.blng__SummaryStartDate__c) + String.ValueOf(eachAccountUS.blng__SummaryEndDate__c)+eachAccountUS.blng__Order__c+eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c) +
                                        eachAccountUS.blng__Subtotal__c
                                    );                                    
                                } else {
                                    // System.debug('inside slecetd storage usgsummary');
                                    accountUSOrderTotalMap.put(
                                        eachAccountUS.blng__Account__c+String.ValueOf(eachAccountUS.blng__SummaryStartDate__c) + String.ValueOf(eachAccountUS.blng__SummaryEndDate__c)+eachAccountUS.blng__Order__c+eachAccountUS.blng__OrderProduct__r.Product2.QTB_Oracle_Product_Code__c,
                                        eachAccountUS.blng__Subtotal__c
                                    );
                                }
                                break;  //Git #6403 adding break to avoid to duplicate fuel surcharge config record for the same month(same duration)
                            }
                            system.debug('Fuel@@@@12--'+eachAccountUS);
                        }
                    }
                }
                
                //System.debug('Account map--->'+accountUSOrderTotalMap);
                //Loop to Compare accountUSOrderTotalMap with the Fuel SurCharge on Billing Account
                //and Create Usage for Fuel SurCharge Product accordingly
                if (accountUSOrderTotalMap != null) {
                    system.debug('Fuel@@@@13--');
                    //Delete the existing Usage for the FuelSurcharge and insert fresh usage // If we are running the Prebill more than 1 time to avoid duplicate
                    list<string> matchingIdsUsage = new list<string>();
                    Set<Id> usageSummaryIdSet = new Set<Id>();
                    List<Datetime> usageDates = new List<Datetime>();
                    for (string acc : accountUSOrderTotalMap.keySet()) {
                        system.debug('Fuel@@@@14--'+acc);
                        if ( accountUSOrderTotalMap.get(acc) > 0 ) 
                        {
                            date insertDate =FSUSEndDateMap.get(acc); //setting UsageSummary EndDate
                            datetime endDateTime = insertDate;
                            blng__Usage__c usage = new blng__Usage__c();
                            system.debug('Fuel@@@@15--'+billedOrderNumberByAccountId.get(acc));
                            system.debug('Fuel@@@@16--'+relatedAccs.get(keyToaccountIdMap.get(acc)).QTB_Customer_Number__c);
                            system.debug('Fuel@@@@17--'+LABEL.QTB_Fuel_Surcharge);
                            //Matching Id to insert the Usage record under a specific Fuel Product/ Usage Summary
                            usage.blng__MatchingId__c = billedOrderNumberByAccountId.get(acc) + // added as part of GitLab # 1733
                                relatedAccs.get(keyToaccountIdMap.get(acc)).QTB_Customer_Number__c +
                                accountUSWithFuelSurchargeCodeMap.get(acc);                                
                            //Delete the existing Usage for the FuelSurcharge and insert fresh usage // If we are running the Prebill more than 1 time to avoid duplicate
                            matchingIdsUsage.add(usage.blng__MatchingId__c);
                            system.debug('MatchingId@@--'+usage.blng__MatchingId__c);
                            System.debug('accountIdWithUsgSumMatchingAttributeMap1@@'+accountIdWithUsgSumMatchingAttributeMap);
                            System.debug('accountIdWithUsgSumMatchingAttributeMap2@@'+accountIdWithUsgSumMatchingAttributeMap.get(acc));
                            usage.blng__MatchingAttribute__c = accountIdWithUsgSumMatchingAttributeMap.get(acc);
                            usage.blng__StartDateTime__c = endDateTime;
                            usage.blng__EndDateTime__c = endDateTime;
                            usageDates.add(endDateTime);
                            //Update PreratedAmount //Get account related FuelSurcharges % for respective Account
                            system.debug('Fuel@@@@18--'+accountUSOrderTotalMap.get(acc));
                            system.debug('Fuel@@@@19--'+accountFuelSurchargeMap.get(acc));
                            usage.blng__PreratedAmount__c = (accountUSOrderTotalMap.get(acc)* accountFuelSurchargeMap.get(acc))/100;
                            system.debug('Fuel@@@@20--'+usage.blng__PreratedAmount__c);
                            usage.QTB_System_Generated__c = true;
                            usage.QTB_Invoice_Quantity__c = 1;
                            //Done as part or Bill trust requrement // GIT #5924
                            usage.blng__PreratedQuantity__c = 1;
                            usage.blng__UnitPrice__c = usage.blng__PreratedAmount__c;
                            //US #5998 populate serviceDistrict & ProductIdentifier1 on usage object for fuel surcharge.
                            usage.QTB_Service_District__c = relatedAccs.get(keyToaccountIdMap.get(acc)).QTB_Customer_District__c; 
                            //usage.QTB_Product_Identifier_1__c = billCode!= null ? billCode[0].QTB_Source_Bill_Code__c : '';
                            //US #15325, QTB_Product_Identifier_1__c updated
                            usage.QTB_Product_Identifier_1__c = ProductCodeTobillCodeMap.containsKey(accountUSWithFuelSurchargeCodeMap.get(acc)+relatedAccs.get(keyToaccountIdMap.get(acc)).QTB_Legal_Entity_Country__c) ? ProductCodeTobillCodeMap.get(accountUSWithFuelSurchargeCodeMap.get(acc)+relatedAccs.get(keyToaccountIdMap.get(acc)).QTB_Legal_Entity_Country__c): '' ;
                            System.debug('QTB_Product_Identifier_1__c@@'+usage.QTB_Product_Identifier_1__c);
                            System.debug('ProductCodeTobillCodeMap.containsKey(accountUSWithFuelSurchargeCodeMap.get(acc)+relatedAccs.get(keyToaccountIdMap.get(acc)).QTB_Legal_Entity_Country__c)@@'+ProductCodeTobillCodeMap.containsKey(accountUSWithFuelSurchargeCodeMap.get(acc)+relatedAccs.get(keyToaccountIdMap.get(acc)).QTB_Legal_Entity_Country__c));
                            usage.CurrencyIsoCode = relatedAccs.get(keyToaccountIdMap.get(acc)).CurrencyIsoCode;
                            usageSummaryIdSet.add(usage.blng__UsageSummary__c);
                            usgList.add(usage);
                            System.debug('Usage---->'+usage);
                        }
                    }
                    //Delete the existing Usage for the FuelSurcharge and insert fresh usage // If we are running the Prebill more than 1 time to avoid duplicate
                    if(matchingIdsUsage.size() > 0){
                        List<blng__Usage__c> CheckExistinUsage = [SELECT id from blng__Usage__c WHERE blng__MatchingId__c IN: matchingIdsUsage 
                                                                  AND blng__UsageSummary__r.blng__Status__c = :QUEUED_FOR_INVOICE 
                                                                  AND blng__StartDateTime__c IN: usageDates AND blng__EndDateTime__c IN: usageDates
                                                                  AND blng__UsageSummary__c IN :usageSummaryIdSet ];
                        if(CheckExistinUsage.size() > 0){
                            delete CheckExistinUsage;
                        }
                    }
                }
                //Database.insert(usgList,false);
                if (usgList <> null && usgList.size() > 0) {
                    String errorMessage = '';
                    Database.SaveResult[] systemUsageInsert = Database.insert(usgList, false);
                    for (Integer i = 0; i < systemUsageInsert.size(); i++) {
                        if (!systemUsageInsert[i].isSuccess()) {
                            system.debug('Fuel@@@@21--');
                            errorMessage +=
                                ';;Matching ID -' +
                                usgList[i].blng__MatchingId__c +
                                '::End Date Time -' +
                                usgList[i].blng__EndDateTime__c +
                                'Error is::' +
                                systemUsageInsert[i].getErrors()[0].getMessage();
                        }
                    }
                    List<blng__Usage__c> UpdateUsagefinal = new List<blng__Usage__c>();
                    List<blng__UsageSummary__c> usageSummaryfinal = new List<blng__UsageSummary__c>();
                    List<blng__Usage__c> UpdateUsage = [Select Id,blng__UsageSummary__c,blng__UnitPrice__c,blng__PreratedAmount__c,blng__MatchingId__c From blng__Usage__c where Id IN :usgList  ];
                    Map<Id,Decimal> usgSummryUnitPrice = new Map<Id,Decimal>();
                    
                    if(UpdateUsage.size() > 0 ){
                        System.debug('UpdateUsage@@'+UpdateUsage);
                        for(blng__Usage__c usg : UpdateUsage){
                            usg.blng__UnitPrice__c = usg.blng__PreratedAmount__c;
                            UpdateUsagefinal.add(usg);                            
                            blng__UsageSummary__c usgS = new blng__UsageSummary__c();
                            usgS.id = usg.blng__UsageSummary__c;
                            usgS.blng__UnitPrice__c = usg.blng__PreratedAmount__c;
                            usageSummaryfinal.add(usgS);
                        } 
                    }
                    if(UpdateUsagefinal.size () > 0){
                        System.debug('UpdateUsagefinal@@'+UpdateUsagefinal);
                        update UpdateUsagefinal; 
                    }
                    
                    if(!usageSummaryfinal.isEmpty() && usageSummaryfinal.size() > 0){
                        update usageSummaryfinal;
                    }
                    
                    system.debug('errorMessage-->' + errorMessage);
                    if (errorMessage != '') {
                        if (errorMessage.length() > 100000)
                            errorMessage = errorMessage.substring(0, 100000);
                        QTB_ExceptionLogger.createLog(
                            1,
                            'Fuel Surcharge Usage Insert Failed',
                            errorMessage,
                            '',
                            FUEL_SURCHARGES_BATCH
                        );
                    }
                }
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                FUEL_SURCHARGES_BATCH
            );
        }
    }
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: Void
Requirement: SFCPQBLG-88
Description: Calls QTB_InvoiceMinimumBatch Batch Class to Calculate Invoice Minimum Charges
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
        if(!Test.isRunningTest()){
            QTB_InvoiceMinimumBatch qtb = new QTB_InvoiceMinimumBatch(invoiceBatch,targetDate,preBillcheckRecordId);
            Database.executeBatch(qtb, 5);
        }
    }
}
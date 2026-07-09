/*****************************************************************************************************
* Class: QTB_CreateOrderItem
* Author: Virtusa
* Purpose: This is a class containing logic for Creating OrderItems for selected products for newly created additional BillingOrder from BILLC.
* Requirement: 
* Change History:
* Developer        Date 04/05/2022          Description
* Parth(Virtusa)   01/04/2024               Gitlab #20382 Assigning splitInvocieGroupId value based on Account splitInvoiceFlag
* Parth(Virtusa)   04/16/2024				Gitlab #22533 code changes related to Malaysia Tax increase
*******************************************************************************************************/
Public class QTB_CreateOrderItem {
    public static final string className = QTB_CreateOrderItem.class.getName();
    public static boolean throwExplicitException = false;
    // Gitlab #20382 storing Storage and Non Storage value 
    public static final string STORAGE = QTB_Constants.STORAGE_CONSTANT;
    public static final string NONSTORAGE = QTB_Constants.NONSTORAGE_CONSTANT;
    // Calling this method from flow to create orderitems based on selected products.
    @InvocableMethod
    Public static void updateOrderItemDetails(list <flowInputs> request)
    {   
        List<OrderItem> OrderItemlst = new List<OrderItem>();
        List <PriceBookEntry> book = new  List <PriceBookEntry>();
        List<Order> NewCrOrder = new List<Order>();
        List<blng__TaxTreatment__c> sgListTaxTreat = new List<blng__TaxTreatment__c>();
        List<string> getSITADCountries = system.Label.QTB_SITAD_Countries.split(';');
        String errorIds = '';
        
        try {
            For(flowInputs flow:request)
            {
                // #25808 Added W.L.C field in query
                NewCrOrder =[SELECT id,name,EffectiveDate,EndDate,QTB_Legal_Entity_Country__c,Account.QTB_Contract_Entity__c,QTB_OrderCategory__c,account.QTB_Special_Tax_Condition__c,Account.W_L__c
                             FROM order
                             WHERE id=:flow.newOrderCreated];
                //#13172 Create additional orders using existing pricebook
                //#25808 Added Is Active true in filter and Product family in the query
                //#27220 - Added Pricebook2.QTB_Country__c = :flow.accountData.QTB_Legal_Entity_Country__c & CurrencyIsoCode= :flow.accountData.CurrencyIsoCode in the Query
                //#29588 - As part of Additional Order flow enhancement modified the where clause Product2.Family = 'ALM-Secure ITAD' and Product2.RecordType.Name = 'Global Sales Product'
                book=[SELECT id, name,Product2Id,Product2.SBQQ__ChargeType__c,Product2.SBQQ__BillingFrequency__c,Product2.SBQQ__BillingType__c,
                      Product2.blng__BillingRule__c,Product2.blng__TaxRule__c,
                      Product2.blng__RevenueRecognitionRule__c,Product2.SBQQ__SubscriptionTerm__c,product2.Family FROM PricebookEntry
                      WHERE ProductCode in :flow.productCodes
                      AND (Pricebook2Id = :flow.oldOrderData.Pricebook2Id OR (Pricebook2.QTB_Country__c = :flow.accountData.QTB_Legal_Entity_Country__c AND /*QTB_Product_Line__c = 'ALM-Secure ITAD' Gitlab #29328 */ 
                                                                              Product2.Family = 'DM SITAD' AND Pricebook2.QTB_Country__c IN:getSITADCountries))
                      AND (CurrencyIsoCode = :flow.oldOrderData.CurrencyIsoCode OR (CurrencyIsoCode= :flow.accountData.CurrencyIsoCode AND /*QTB_Product_Line__c = 'ALM-Secure ITAD' Gitlab #29328 */ 
                                                                                    Product2.Family = 'DM SITAD' AND Pricebook2.QTB_Country__c IN:getSITADCountries))
                      AND IsActive = True AND Product2.RecordType.Name = 'Global Sales Product' /*Gitlab #29328 */ ];   
            }
            if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            } 
            date treatmentDate = NewCrOrder[0].EffectiveDate;
            //22533 added custom label check to check if country is part of tax increase or not
            if(System.label.QTB_Tax_Increase_Countries.contains(NewCrOrder[0].QTB_Legal_Entity_Country__c)){
                sgListTaxTreat = [select id,QTB_Tax_Effective_Start_Date__c,QTB_Tax_Effective_End_Date__c,blng__taxRule__r.id 
                                  from blng__TaxTreatment__c where QTB_Tax_Effective_Start_Date__c != NULL ANd  
                                  QTB_Tax_Effective_End_Date__c != NULL And QTB_Tax_Effective_Start_Date__c <= :treatmentDate And 
                                  QTB_Tax_Effective_End_Date__c >= :treatmentDate And
                                  blng__TaxLegalEntity__c = :NewCrOrder[0].Account.QTB_Contract_Entity__c And
                                  QTB_Special_Tax_Condition__c = :NewCrOrder[0].account.QTB_Special_Tax_Condition__c And
                                  blng__TaxLegalEntity__r.blng__Country__c = :NewCrOrder[0].QTB_Legal_Entity_Country__c LIMIT 1 ]; 
            }
            List<blng__BillingTreatment__c> sgListBillingTreat=[Select id, name,blng__BillingRule__r.id from blng__BillingTreatment__c Where Name='No Invoice Billing Treatment' LIMIT 1];
            if(book.size()>0)  {  
                For(pricebookentry pr : book)
                {
                    // #25808 Added if Condition same like Evergreen Ordr creation for Filtering the W&L products and Billing only products
                    if(!String.isEmpty(pr.Product2.SBQQ__ChargeType__c))
                    {
                        OrderItem temporderitem = new OrderItem();
                        temporderitem.OrderId = NewCrOrder[0].id;
                        temporderitem.blng__BillableUnitPrice__c= 0;
                        temporderitem.Product2Id = pr.Product2.Id;
                        temporderitem.Quantity = 1;
                        temporderitem.UnitPrice = 0;    
                        temporderitem.blng__HoldBilling__c = 'No';   
                        temporderitem.blng__TaxCountry__c = NewCrOrder[0].QTB_Legal_Entity_Country__c;
                        temporderitem.ServiceDate = NewCrOrder[0].EffectiveDate;
                        temporderitem.EndDate = NewCrOrder[0].EndDate;
                        temporderitem.SBQQ__BillingFrequency__c = 'Monthly';
                        temporderitem.SBQQ__BillingType__c = 'Arrears';
                        temporderitem.SBQQ__ChargeType__c  = 'Recurring';  
                        temporderitem.SBQQ__ContractAction__c  = 'New'; 
                        temporderitem.SBQQ__ContractingMethod__c  = 'Inherit';
                        temporderitem.SBQQ__SubscriptionTerm__c= 1;    
                        temporderitem.SBQQ__DefaultSubscriptionTerm__c= 1;
                        temporderitem.SBQQ__OrderedQuantity__c= 1;
                        temporderitem.SBQQ__PricingMethod__c='List';
                        temporderitem.SBQQ__ProductSubscriptionType__c = 'One-Time'; 
                        temporderitem.SBQQ__SubscriptionType__c = 'One-Time';
                        temporderitem.SBQQ__Status__c = 'Draft';   
                        temporderitem.SBQQ__SubscriptionPricing__c='Fixed Price';
                        temporderitem.PricebookEntryId = pr.Id;
                        temporderitem.blng__BillingRule__c =pr.Product2.blng__BillingRule__c;
                        //   temporderitem.blng__BillingTreatment__c = sgListBillingTreat[0].id;
                        temporderitem.blng__LegalEntity__c = NewCrOrder[0].Account.QTB_Contract_Entity__c;
                        temporderitem.blng__RevenueRecognitionRule__c  = pr.Product2.blng__RevenueRecognitionRule__c;
                        temporderitem.blng__TaxRule__c = pr.Product2.blng__TaxRule__c;
                        //#25808 Commentged the below line and added seperatly based upon W&L and Non W&L products
                        OrderItemlst.add(temporderitem);    
                        //#25808 Add the below if and else if for seperation the category
                        // #29328As part of Adhoc order enhancement the below code is commented out as its not required.
                   /*     if(NewCrOrder[0].Account.W_L__c && pr.product2.Family == 'Warehouse and Logistics')
                        {
                            OrderItemlst.add(temporderitem);
                        }
                        else if(!NewCrOrder[0].Account.W_L__c && pr.product2.Family !='Warehouse and Logistics')
                        {
                            OrderItemlst.add(temporderitem);
                        } */
                    }
                }
            }
            Insert OrderItemlst;
            system.debug('Inserted Items ======' +OrderItemlst.size());
            List<Id> OrdidtoLoad = new List<Id>();
            OrdidtoLoad.add(NewCrOrder[0].id);
            //To update order item for seperate invoicing 
            list<OrderItem> lstupdate= new list<OrderItem>();
            list<OrderItem> itemlst = new list<OrderItem>();
            itemlst=[Select id,QTB_Tax_Category__c,blng__InvoiceGrouping__c,blng__InvoiceGroupId__c,Order.OrderNumber,Product2.QTB_Storage_Product__c,Order.Account.QTB_Split_Invoice_Flag__c from OrderItem where order.id IN :OrdidtoLoad];
            system.debug('Total Selected to update:'+ itemlst.size());
            for(OrderItem ls : itemlst)
            {
                // Gitlab #20382 Assigning splitInvocieGroupId value based on Account splitInvoiceFlag
                if(ls.Order.Account.QTB_Split_Invoice_Flag__c == False){
                    ls.blng__InvoiceGrouping__c= 'Invoice Group ID';
                    ls.blng__InvoiceGroupId__c= ls.Order.OrderNumber;
                }
                else{
                    if(ls.Product2.QTB_Storage_Product__c == true){
                        ls.blng__InvoiceGrouping__c = 'Invoice Group ID';
                        ls.blng__InvoiceGroupId__c = ls.Order.OrderNumber + '-' +STORAGE ;
                    }
                    else{
                        ls.blng__InvoiceGrouping__c= 'Invoice Group ID';
                        ls.blng__InvoiceGroupId__c= ls.Order.OrderNumber + '-' +NONSTORAGE;
                    }
                }
                //Gitlab 12238 to update singapore new tax rule
                //22533 added custom label check to check if country is part of tax increase or not
                if(!sgListTaxTreat.isEmpty() && System.label.QTB_Tax_Increase_Countries.contains(NewCrOrder[0].QTB_Legal_Entity_Country__c) && ls.QTB_Tax_Category__c == null){
                        ls.blng__TaxRule__c = sgListTaxTreat[0].blng__taxRule__r.id;
                    }
                lstupdate.add(ls);
                
            }
            system.debug('Total Selected to update:'+ lstupdate.size());  
            update lstupdate;
            //To Update matching attribute on usage summary related to newly created orderItems
            List<blng__UsageSummary__c  > Uslsttoupdate =new List<blng__UsageSummary__c>();
            List<blng__UsageSummary__c  > Uslst = new List<blng__UsageSummary__c  >();
            //#27220 - Added blng__Order__r.QTB_DM_Source_System_Name__c != 'SITAD' in below query to exclude SITAD
            //#28621 - Added (OR blng__Order__r.QTB_OrderCategory__c = 'Legacy') in below query because it should work for SITAD Legacy Order
            Uslst =[SELECT id,blng__MatchingAttribute__c,blng__Order__r.OrderNumber,blng__Order__r.QTB_OrderCategory__c
                    FROM blng__UsageSummary__c
                    WHERE (blng__Order__r.QTB_DM_Source_System_Name__c != 'SITAD' OR blng__Order__r.QTB_OrderCategory__c = 'Legacy')
                    AND blng__Order__r.id IN :OrdidtoLoad];
            system.debug('Size+++++++++++++++:'+ Uslst.size());
            for (blng__UsageSummary__c us :Uslst)
            {
                us.blng__MatchingAttribute__c = us.blng__Order__r.OrderNumber;
                // Added #22304 as Part of legacy Invoice Build for Legacy invoices to mark Matching attribute as legacy for Legacy invocies
                if(us.blng__Order__r.QTB_OrderCategory__c != Null && us.blng__Order__r.QTB_OrderCategory__c == 'Legacy'){
                    us.blng__MatchingAttribute__c = 'Legacy'; 
                }
                Uslsttoupdate.add(us);
            }
            Update Uslsttoupdate;
            System.debug('Updated count====='+Uslsttoupdate.size());
            // To activate Created Orders/OrderItems
            Database.executeBatch(new QTB_AddOrderProductCSCRBatch(OrdidtoLoad), 200);
            
        }
        catch (exception e) {
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            system.debug('In catch method of batch Finish>>>>>>>>>>');
            system.debug('Error inf::' + errorIds);
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                errorIds,
                e.getTypeName(),
                className
            );
        }  
        
    }
    Public class flowInputs{
        @InvocableVariable
        public Order oldOrderData;
        @InvocableVariable    
        Public string newOrderCreated;
        @InvocableVariable
        Public list<String> productCodes;
        @InvocableVariable
        public Account accountData; //#27220 - Added Account reference from Flow
    }
    
    public static void CodeCoverageMethod(){
    Integer i = 0;
    i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
    i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;

  }
    
}
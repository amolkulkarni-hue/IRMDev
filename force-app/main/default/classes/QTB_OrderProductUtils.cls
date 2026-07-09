/*****************************************************************************************************
* Class         : QTB_OrderProductUtils
* Test Class    : QTB_OrderProductUtils_Test
* Functionality : QTB/Billing only implementation
* Author        : Virtusa
* Purpose       : Utilize this class for writing methods related to orderProduct and related object records
* Change History: 05/15/2023
* Developer      Date           Description
* Parth          03/20/2024     #22533 code changes regarding malaysia tax increase
* Parth          04/30/2024     #23284 setting Translated value for price schedule category
*******************************************************************************************************/
public class QTB_OrderProductUtils {
    public static final String ORDER_PRODUCT_UTILS = 'QTB_OrderProductUtils';
    public static boolean throwExplicitException = false;
    /***********************************************************************************************************
* Method        : updateSingaporeOrdProductTaxRuleAndTreatment
* Parameters    : Set<Id> ReBillOrderPdtTaxRuleUpdate
* Return type   : void
* Requirement   : Taxrule and treatment for rebill orderProduct for Singapore. Since Singapore treatment is dependant on year and category
* Description   : Currently below classes are using this method
1. QTB_OrderProductHelper : GitLab #14255, To update rebill orderProduct & OPCS.
2. QTB_TaxTreatmentPopulationBatch : GitLab #13959, To update correct treatment and rule whenever Singapore
accounts are put on/off Hold Billing.
**************************************************************************************************************/
    public static void updateSingaporeOrdProductTaxRuleAndTreatment(Set<Id> ordItemId){
        try{
            //#32975 Added below Null Pointer Exception loop for Test coverage
            if (QTB_OrderProductHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            System.debug('Inside try block updateSingaporeOrdProductTaxRuleAndTreatment');
            System.debug('before soql =='+Limits.getQueries());
            //fetching Singapore Tax Treatments, to pick the correct treatment based on the effective start date and end date
            List<blng__TaxTreatment__c> sgListTaxTreat = [select id,QTB_Tax_Effective_Start_Date__c,QTB_Tax_Effective_End_Date__c,blng__taxRule__r.id,blng__TaxLegalEntity__r.blng__Country__c,
                                                          blng__TaxLegalEntity__r.id,QTB_Special_Tax_Condition__c from blng__TaxTreatment__c where 
                                                          QTB_Tax_Effective_Start_Date__c != NULL ANd  QTB_Tax_Effective_End_Date__c != NULL And 
                                                          blng__TaxLegalEntity__r.blng__Country__c in :system.label.QTB_Tax_Increase_Countries.split(',')];
            system.debug('sgListTaxTreat-->'+sgListTaxTreat);
            Map<Id,orderItem> orderItemUpdateMap = new Map<Id,orderItem>();
            List<OrderItem> updateOrdItm = [select id,blng__TaxTreatment__c,QTB_Tax_Category__c,order.EffectiveDate,order.QTB_OrderCategory__c,order.Account.QTB_Hold_Billing__c,order.QTB_Legal_Entity_Country__c,
                                            order.account.QTB_Special_Tax_Condition__c,order.account.QTB_Contract_Entity__c from orderItem where 
                                            order.QTB_Legal_Entity_Country__c in  :system.label.QTB_Tax_Increase_Countries.split(',') and id in :ordItemId ];
            if(!sgListTaxTreat.isEmpty() && !updateOrdItm.isEmpty()){
                //iterating over all tax treatments
                for(blng__TaxTreatment__c taxtreat :sgListTaxTreat ){
                    //iterating over all order items received
                    for(OrderItem orditm :updateOrdItm){
                        boolean updateOrderItem = true;
                        //22533 iterating treatment based on account legal entity and special tax condition
                        if(orditm.order.account.QTB_Contract_Entity__c != null &&
                           orditm.order.account.QTB_Contract_Entity__c == taxtreat.blng__TaxLegalEntity__r.id && orditm.order.account.QTB_Special_Tax_Condition__c == taxtreat.QTB_Special_Tax_Condition__c){
                               Date effectiveDateTocomapre;
                               //Assign date based on order category
                               //For rebill order, orderEffectivedate = (invoiceDate - 1) months
                               if(orditm.order.QTB_OrderCategory__c == 'Rebill'){
                                   effectiveDateTocomapre = orditm.order.EffectiveDate.addMonths(1);
                                   effectiveDateTocomapre=effectiveDateTocomapre.addDays(-1);
                                   updateOrderItem = false; // making it false so that if treatment condition is not met than not adding to the update list as nothing we are updating on this
                               }
                               //For Evergreen order, tax treatment should be updated with latest treatment based on system Date
                               //so comparing it with system date
                               //Check account's hold billing value, and assign the same on order product only for 'evergreen' and 'ad-hoc' order
                               else if(orditm.order.QTB_OrderCategory__c == 'Evergreen'){
                                   effectiveDateTocomapre = system.today();
                                   if(orderItemUpdateMap.containsKey(orditm.Id)){
                                       orderItemUpdateMap.get(orditm.Id).blng__HoldBilling__c = orditm.order.Account.QTB_Hold_Billing__c == true? 'Yes': 'No';
                                   }else{
                                       orditm.blng__HoldBilling__c = orditm.order.Account.QTB_Hold_Billing__c == true? 'Yes': 'No';
                                   }
                               }
                               //For Evergreen order, tax treatment should be updated with latest treatment based on order's effective date
                               //so comparing it with the order Effective date
                               else if(orditm.order.QTB_OrderCategory__c == 'Ad-Hoc'){
                                   effectiveDateTocomapre = orditm.order.EffectiveDate;
                                   if(orderItemUpdateMap.containsKey(orditm.Id)){
                                       orderItemUpdateMap.get(orditm.Id).blng__HoldBilling__c = orditm.order.Account.QTB_Hold_Billing__c == true? 'Yes': 'No';
                                   }else{
                                       orditm.blng__HoldBilling__c = orditm.order.Account.QTB_Hold_Billing__c == true? 'Yes': 'No';
                                   }
                               }
                               //if effective date is in between the range of effective start date and end date then assign that tax treatment and rule
                               if(taxtreat.QTB_Tax_Effective_Start_Date__c <= effectiveDateTocomapre
                                  && taxTreat.QTB_Tax_Effective_End_Date__c >= effectiveDateTocomapre){
                                      updateOrderItem = true; // making it true so that if this condition satisfy for rebill OI than it got added to the update list
                                      if(orderItemUpdateMap.containsKey(orditm.Id)){
                                          orderItemUpdateMap.get(orditm.Id).blng__TaxTreatment__c = taxtreat.id;
                                          orderItemUpdateMap.get(orditm.Id).blng__TaxRule__c = taxtreat.blng__taxRule__r.id;
                                      }else{
                                          ordItm.blng__TaxTreatment__c = taxtreat.id;
                                          ordItm.blng__TaxRule__c = taxtreat.blng__taxRule__r.id;
                                      }
                                  }
                               if(!orderItemUpdateMap.containsKey(ordItm.Id) && updateOrderItem){
                                   orderItemUpdateMap.put(ordItm.Id,ordItm);
                               }
                           }
                    }
                }
                //trigger is disabled while update operation, since active orderItem and OPCS are updated
                if(!orderItemUpdateMap.isEmpty() && !test.isRunningTest()){
                    SBQQ.TriggerControl.disable();
                    update orderItemUpdateMap.values();
                    SBQQ.TriggerControl.enable();
                    orderItemUpdateMap.clear();
                }
            }
            System.debug('after soql =='+Limits.getQueries());
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),ORDER_PRODUCT_UTILS);
            throw e;
        }
        
    }
    /***********************************************************************************************************
* Method        : updateTaxCategoryBasedTaxTreatments
* Parameters    : List<OrderItem> scrapItems
* Return type   : List<OrderItem>
* Requirement   : GIT lab #19786 TCS --> Based upon Tax category field from PricebookEntry the tax rule and Treatments population
* Description   : This method is called from class where all Order products are created for updating the Tax rule and
treatment after creation (Apex classes ---> QTB_OrderProductHelper,QTB_TaxTreatmentPopulationBatch )
**************************************************************************************************************/
    public static List<OrderItem> updateTaxCategoryBasedTaxTreatments(List<OrderItem> scrapItems){
        system.debug('Inside updateMetalPaperScrapTaxTreatments method');
        try{
            List<OrderItem> updatedList = new List<OrderItem>();
            // The below condition is for checking the Tax category of that order Product != null and adding to a list else Adding to Updation list
            if(!scrapItems.isEmpty()){
                List<orderItem> scrapUpdateList = new List<OrderItem>();
                for(OrderItem opScrap : scrapItems)
                {
                    // This is for all batch classes where are Inserting the order Item like QTB_CreateAdditionalOrderBatch,QTB_CreateExtraOrderBatch,QTB_CreateOrderItem,QTB_CreateOrderOrderItemBatch,QTB_InFlowOrderItemBatch
                    // If there is Special Category on OP level then we are adding to scrapUpdateList for populating the Special tax rule and treatment related to Metal Scrap4
                    if(opScrap.QTB_Tax_Category__c != null){
                        scrapUpdateList.add(opScrap);
                    }
                    else {
                        // this Updated list is for QTB_TaxTreatmentPopulationBatch batch where it returns the OrderItems which is not eligible for tax category for Updating its respective tax rule and its Treatment
                        //If there are no Special Tax category products present, send it back as is
                        updatedList.add(opScrap);
                    }
                }
                // checking the tax Category Products list not empty
                if(!scrapUpdateList.isempty()){
                    Set<String> accSpecialTaxCondition = new Set<String>();
                    Set<Double> legalEntityNumber = new set<Double>();
                    // As part of 20604 Updated Shipping country to Legal Entity country
                    Set<String> legalEntityCountry = new set<String>();
                    Set<String>  taxable = new Set<String>();
                    Set<String>  taxCategory = new Set<String>();
                    //#31117 WHT Turkey
                    Boolean withHold = false;
                    Set<String> convertlegalEntityNumbertoString = new Set<String>();
                    List<orderItem> scrapUpdationItems = new List<OrderItem>();
                    Map<String,blng__TaxTreatment__c> taxTreatmentMap = new Map<String,blng__TaxTreatment__c>();
                    Map<String,String> specialTaxMap = new Map<String,String>();
                    for(OrderItem opScrap : [select id,
                                             order.Account.QTB_Special_Tax_Condition__c, 
                                             blng__LegalEntity__r.QTB_Legal_Entity_Number__c,
                                             order.Account.SBQQ__TaxExempt__c,
                                             QTB_Tax_Category__c,Order.QTB_Legal_Entity_Country__c,
                                             blng__TaxCountry__c,order.account.shippingCountry,
                                             blng__TaxRule__c,blng__TaxTreatment__c,order.Account.QTB_Hold_Billing__c,
                                             blng__TaxRule__r.name,blng__TaxTreatment__r.name,Order.Account.QTB_Withholding_Applicable__c
                                             from orderitem
                                             where id IN :scrapUpdateList]){
                                                 taxable.add(opScrap.order.Account.SBQQ__TaxExempt__c);
                                                 accSpecialTaxCondition.add(opScrap.order.Account.QTB_Special_Tax_Condition__c);
                                                 legalEntityNumber.add(opScrap.blng__LegalEntity__r.QTB_Legal_Entity_Number__c);
                                                 // The below If loop logic is for Converting Legal Entity number data field to String for Comparing with metadata Text field(Legal_Entity_Number__c)
                                                 if(!legalEntityNumber.isempty()){
                                                     String convertDecimalToString = String.valueOf(opScrap.blng__LegalEntity__r.QTB_Legal_Entity_Number__c);
                                                     convertlegalEntityNumbertoString.add(convertDecimalToString);
                                                 }
                                                 // As part of 20604 Updated Shipping country to Legal Entity country
                                                 legalEntityCountry.add(opScrap.Order.QTB_Legal_Entity_Country__c);
                                                 taxCategory.add(opScrap.QTB_Tax_Category__c);
                                                 scrapUpdationItems.add(opScrap);
                                                 //#31117 WHT
                                                 if(opScrap.Order.Account.QTB_Withholding_Applicable__c){
                                                     withHold = true;  
                                                 }
                                             }
                    // As part of 20604 Updated Shipping country to Legal Entity country
                    if(!taxable.isEmpty() && !accSpecialTaxCondition.isempty() && !convertlegalEntityNumbertoString.isempty() && !legalEntityCountry.isempty() && !taxCategory.isempty()){
                        // Getting the Custom meta data Record based upon Account's Tax Exempt,Account's Shipping country, Account's Special Tax Condition and Legal Entity number and Order product Tax category value
                        // A map created with key as label value of meta data and Value as QTB_Treatment_Special_Tax_Condition__c (In Meta data we give the value)
                        //#31117 Added QTB_WithHold__c & Name__c field as part of Turkey
                        for(QTB_Category_Tax_Treatment_Condition_Map__mdt  mdt : [select Id, Label, Tax_Category__c,
                                                                                  Account_Special_Tax_Condition__c, QTB_Treatment_Special_Tax_Condition__c, Legal_Entity_Number__c, QTB_TaxExempt__c,QTB_WithHold__c,Name__c  
                                                                                  from QTB_Category_Tax_Treatment_Condition_Map__mdt where  Account_Special_Tax_Condition__c IN :accSpecialTaxCondition and 
                                                                                  Legal_Entity_Number__c IN :convertlegalEntityNumbertoString and QTB_TaxExempt__c IN :taxable and Tax_Category__c IN: taxCategory and QTB_WithHold__c =: withHold ]){
                                                                                      specialTaxMap.put(mdt.Name__c,mdt.QTB_Treatment_Special_Tax_Condition__c);
                                                                                  }
                        
                    }
                    //Iterating Tax treatment Records based upon Special tax condition,Shipping Country and Legal Entity number values map which is derived from custom meta data map and tax related info
                    //Key=Special String (Treatment's Special tax condition, Tax Country, Taxable), value =Tax Treatment record
                    // As part of 20604 Updated Shipping country to Legal Entity country
                    for(blng__TaxTreatment__c tt:[select id,blng__TaxRule__r.Id,blng__TaxRule__r.name,name,QTB_Special_Tax_Condition__c, QTB_TaxCountry__c, blng__TaxLegalEntity__c,
                                                  QTB_Taxable__c from blng__TaxTreatment__c where blng__Active__c=TRUE and QTB_Special_Tax_Condition__c IN : specialTaxMap.Values() 
                                                  and QTB_TaxCountry__c IN: legalEntityCountry  and blng__TaxLegalEntity__r.QTB_Legal_Entity_Number__c IN: legalEntityNumber]
                       ){
                           //Tax treatment map which holds the values of below fields for comparison with String Key
                           taxTreatmentMap.put(tt.QTB_Special_Tax_Condition__c+
                                               tt.QTB_TaxCountry__c+
                                               // tt.blng__TaxLegalEntity__c+
                                               tt.QTB_Taxable__c,tt);
                       }
                    // clearing all list which is not used again for code efficiency
                    accSpecialTaxCondition.clear();
                    legalEntityNumber.clear();
                    // As part of 20604 Updated Shipping country to Legal Entity country
                    legalEntityCountry.clear();
                    taxCategory.clear();
                    convertlegalEntityNumbertoString.clear();
                    // Iterating the List of order products that are having tax category is having some value which is added from passed Parameter
                    //Gitlab #31117 Addition of Order.Account.QTB_Withholding_Applicable__c to the key as part of Withhold tax
                    if(!scrapUpdationItems.isempty()){
                        for(OrderItem opScrap : scrapUpdationItems)
                        {
                            String taxableValue = (opScrap.order.Account.SBQQ__TaxExempt__c == 'Yes') ?
                                QTB_Constants.TAXABLE_NO : QTB_Constants.TAXABLE_YES;
                            // create key string for matching the tax treatment's Special key
                            String key = specialTaxMap.get(opscrap.order.Account.QTB_Special_Tax_Condition__c+';'+
                                                           opscrap.blng__LegalEntity__r.QTB_Legal_Entity_Number__c+';'+
                                                           opscrap.QTB_Tax_Category__c+';'+
                                                           opscrap.order.Account.SBQQ__TaxExempt__c+';'+
                                                           opscrap.Order.Account.QTB_Withholding_Applicable__c)+
                                opscrap.Order.QTB_Legal_Entity_Country__c+
                                //opScrap.blng__LegalEntity__c+
                                taxableValue;
                            //check whether key string is present in the map
                            if(taxtreatmentMap.containsKey(key)){
                                //Assign the tax rule & treatment on the order product
                                opScrap.blng__TaxRule__c= taxtreatmentMap.get(key).blng__TaxRule__r.Id;
                                opScrap.blng__TaxTreatment__c=taxtreatmentMap.get(key).Id;
                            }
                            //add it back to the list which should br returned
                            updatedList.add(opScrap);
                        }
                    }
                    scrapUpdationItems.clear();
                    taxTreatmentMap.clear();
                    specialTaxMap.clear();
                }
            }
            return updatedList;
        }
        
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),ORDER_PRODUCT_UTILS);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method        : setLocalisedProductName
* Parameters    : List<OrderItem> ordItemNewList
* Return type   : void
* Requirement   : Gitlab US #18864
* Description   : Setting QTB_Localized_Product_Name__c to the translated value defined at Product localisation
**************************************************************************************************************/
    public static void setLocalisedProductName(List<OrderItem> ordItemNewList,List<Account> accountList){
        Set<Id> product2Ids = new Set<Id>();
        set<string> accLan = new set<string>();
        List<OrderItem> updateLocTranslatedList = new List<OrderItem>();
        
        try{
            //When Before_Insert is triggered from Order item then iterating on list of OP and getting the product2Ids & accLan values
            if(ordItemNewList !=null && !ordItemNewList.isempty())
            {
                for(OrderItem ordItem : ordItemNewList)
                {
                    product2Ids.add(ordItem.Product2Id);
                    accLan.add(ordItem.QTB_Language__c);//variable which holds the Order items -> Language
                }
                
                //query localization records for converting product name based on Order Item language
                map<String,string> maplocalization = new map<String,string>();//Gitlab #30001
                if(!product2Ids.isEmpty() && !accLan.isEmpty())
                {
                    //Create a Map as key productId and value being -> Translated value of that Product Name
                    for(SBQQ__Localization__c loc: [select SBQQ__Text__c,SBQQ__Product__c, SBQQ__Language__c 
                                                    from SBQQ__Localization__c 
                                                    Where SBQQ__Product__c IN: product2Ids and SBQQ__Language__c IN: accLan and  SBQQ__APIName__c = 'Name']){
                                                        maplocalization.put(loc.SBQQ__Product__c+loc.SBQQ__Language__c,loc.SBQQ__Text__c); //Gitlab #30001 Addition of language to solve laguage issue
                                                    }
                    
                }
                product2Ids.clear();
                accLan.clear();
                //Iterating on list of Order item received
                for(OrderItem ordItem : ordItemNewList)
                {
                    if(ordItem.Product2Id != null && maplocalization.containsKey(ordItem.Product2Id + ordItem.QTB_Language__c))//Gitlab #30001 Addition of language to solve laguage issue
                    {
                        ordItem.QTB_Localized_Product_Name__c = maplocalization.get(ordItem.Product2Id + ordItem.QTB_Language__c);//Gitlab #30001 Assigning the values defined at Localisation level onto OP'sQTB_Localized_Product_Name__c
                        //Addition of language to solve laguage issue
                    }
                }
                maplocalization.clear();
            }
            //When After_Update is triggered from Account helper when language is changed then iterating on list of Account ids and getting the Order items (Filtering based upon Order end date)
            else if(!accountList.isempty())
            {
                List<OrderItem> ordLocAccounList = [select Product2Id,order.Account.QTB_Language__c from OrderItem where order.AccountId IN: accountList and (order.EndDate = null or order.EndDate = LAST_90_DAYS  or order.EndDate >= TODAY)];
                //adding the values of product2Ids & Account language to a variable
                for(OrderItem ordItem : ordLocAccounList )
                {
                    product2Ids.add(ordItem.Product2Id);
                    accLan.add(ordItem.order.Account.QTB_Language__c);//variable which holds the Account -> Language
                }
                
                //query localization records for converting product name based on Order Item language
                map<Id,string> maplocalization = new map<Id,string>();
                if(!product2Ids.isEmpty() && !accLan.isEmpty()){
                    //Create a Map as key productId and value being -> Translated value of that Product Name
                    for(SBQQ__Localization__c loc:[select SBQQ__Text__c,SBQQ__Product__c
                                                   from SBQQ__Localization__c 
                                                   Where SBQQ__Product__c IN: product2Ids and SBQQ__Language__c IN: accLan and  SBQQ__APIName__c = 'Name']){
                                                       maplocalization.put(loc.SBQQ__Product__c,loc.SBQQ__Text__c);
                                                   }
                    
                }
                product2Ids.clear();
                accLan.clear();
                //Iterating on list of Order item received
                for(OrderItem ordItem : ordLocAccounList)
                {
                    if(ordItem.Product2Id != null && maplocalization.containsKey(ordItem.Product2Id)){
                        ordItem.QTB_Localized_Product_Name__c = maplocalization.get(ordItem.Product2Id);//Assigning the values defined at Localisation level onto OP'sQTB_Localized_Product_Name__c
                        updateLocTranslatedList.add(ordItem);
                    }
                    //if no translated value present then to update a null value
                    else{
                        ordItem.QTB_Localized_Product_Name__c = '';
                        updateLocTranslatedList.add(ordItem);
                    }
                }
                maplocalization.clear();
                if(!updateLocTranslatedList.isempty()){
                    Update updateLocTranslatedList;
                }
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),ORDER_PRODUCT_UTILS);
            throw e;
        }
        
    }
    
    /***********************************************************************************************************
* Method        : updateUOMDescription
* Parameters    : List<OrderItem> ordItemNewList,set<String> countries
* Return type   : void
* Requirement   : Gitlab US #18864
* Description   : Setting QTB_Localized_UOM_Description__c to the translated value defined at UOM Translation custom metadata
                  #32975 Changed the Apex method name as well to make it both Versions Update
                  Changed this method as per the requirement like the UOM description should be displayed for both English version and Non English Version like below
                  //If Account language is English creating key as Country + Product Code + UOm and getting the value from QTB_Bill_Code_Product_Lookup__c table
                  //If Account Language is other than English creating the key as UOM + language and getting the value from QTB_UOM_Translation__mdt table
                  //Removed List<Account> accList parameter as the method is running on Account Language update the method is firing in backend and upodating the values respectively
**************************************************************************************************************/
    public static void updateUOMDescription(List<OrderItem> ordItemNewList,set<String> countries){
        system.debug('Inside updateUOMDescription method');
        Map<String,String> mapOfKeyWithDefaultDescvalue = new Map<String,String>();
        Map<String,String> mapOfKeyWithTransDescvalue = new Map<String,String>();
        List<SBQQ__OrderItemConsumptionSchedule__c> opcsList = new List<SBQQ__OrderItemConsumptionSchedule__c>();
        List<OrderItem> orderProductsToUpdate = new List<OrderItem>();
        Set<Id> opcsOrderProdIds = new Set<Id>();
        try{
            if (QTB_OrderProductHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            //When After Update is triggered and querying the OPCS's from the Order item list received
            if(ordItemNewList !=null && !ordItemNewList.isempty())
            {
                //Query to get the list of OPCS based on the Order Item recieved
                List<SBQQ__OrderItemConsumptionSchedule__c> ordPrdtCSlist = [SELECT Id,Name,SBQQ__OrderItem__c,SBQQ__OrderItem__r.QTB_Language__c,SBQQ__UnitOfMeasure__c,SBQQ__OrderItem__r.QTB_Legal_Entity_Country__c,
                                                                             SBQQ__OrderItem__r.Product2.ProductCode,QTB_Localized_UOM_Description__c,QTB_UOM_Description_Text__c
                                                                             FROM SBQQ__OrderItemConsumptionSchedule__c 
                                                                             WHERE SBQQ__OrderItem__c IN :ordItemNewList AND (SBQQ__OrderItem__r.EndDate = null OR SBQQ__OrderItem__r.EndDate <= LAST_90_DAYS or SBQQ__OrderItem__r.order.EndDate >= TODAY) AND SBQQ__UnitOfMeasure__c!= Null ];
                
                Map<String, QTB_UOM_Translation__mdt> allTranslations = QTB_UOM_Translation__mdt.getAll();
                // Querying the QTB_Bill_Code_Product_Lookup__c records to create a map of Combo as Country + ProductCode + UOM to get the unique combo and add
                //  the Default description value of that
                for(QTB_Bill_Code_Product_Lookup__c bcpl : [SELECT Id, QTB_Country__r.name, QTB_Product_Code__c, 
                                                            QTB_UOM__c, QTB_Default_Bill_Code_Description__c 
                                                            FROM QTB_Bill_Code_Product_Lookup__c 
                                                            WHERE QTB_UOM__c != null 
                                                            AND QTB_Default_Bill_Code_Description__c != null 
                                                            AND QTB_Country__r.name != Null
                                                            AND QTB_Country__r.name IN : countries
                                                            AND QTB_Product_Code__c != null ] ){
                                                                //Converting the key of COuntry and UOM to Lower case to make Key as same as Alphabetical issue
                                                                String key = (string)bcpl.QTB_Country__r.name.toLowerCase() + '-' + bcpl.QTB_Product_Code__c + '-'+ (string)bcpl.QTB_UOM__c.toLowerCase();
                                                                //Adding only unique value as basically first record to get added only unique Values
                                                                if (mapOfKeyWithDefaultDescvalue != Null && key != Null && !mapOfKeyWithDefaultDescvalue.containsKey(key)) {
                                                                    mapOfKeyWithDefaultDescvalue.put(key, bcpl.QTB_Default_Bill_Code_Description__c);
                                                                }              
                                                            }
                system.debug('mapOfKeyWithDefaultDescvalue:'+mapOfKeyWithDefaultDescvalue);
                
                // Querying the QTB_UOM_Translation__mdt records to create a map of Combo as UOM + Language to get the unique combo and add
                //  the Translated value of that
                for(QTB_UOM_Translation__mdt uomTranslate : allTranslations.values()){
                    mapOfKeyWithTransDescvalue.put((String)uomTranslate.QTB_UnitOfMeasure__c.toLowerCase() + '-'+ uomTranslate.QTB_Language__c,uomTranslate.QTB_Translated_Value__c);   
                }
                //Iterating on list of Order item ids and OPCS
                
                for (SBQQ__OrderItemConsumptionSchedule__c ordPdtCS: ordPrdtCSlist )
                {
                    string keyCompare; 
                    //If Account language is English creating key as Country + Product Code + UOm and getting the value from QTB_Bill_Code_Product_Lookup__c table
                    //If Account Language is other than English creating the key as UOM + language and getting the value from QTB_UOM_Translation__mdt table
                    if(ordPdtCS.SBQQ__OrderItem__r.QTB_Language__c != 'en_US'){
                        if(ordPdtCS.SBQQ__UnitOfMeasure__c != Null && ordPdtCS.SBQQ__OrderItem__r.QTB_Language__c!= Null){
                            //Converting the key of COuntry and UOM to Lower case to make Key as same as Alphabetical issue
                            keyCompare = (string)ordPdtCS.SBQQ__UnitOfMeasure__c.toLowerCase() + '-' +ordPdtCS.SBQQ__OrderItem__r.QTB_Language__c;
                        }
                        
                        if(mapOfKeyWithTransDescvalue !=null && keyCompare != Null && mapOfKeyWithTransDescvalue.containsKey(keyCompare) ){
                            ordPdtCS.QTB_Localized_UOM_Description__c =  mapOfKeyWithTransDescvalue.get(keyCompare);
                        }
                        else {
                            ordPdtCS.QTB_Localized_UOM_Description__c = '';  // clear if no match
                        }
                        ordPdtCS.QTB_UOM_Description_Text__c = '';// Always clear the English field
                    }
                    else {
                        if(ordPdtCS.SBQQ__OrderItem__r.QTB_Legal_Entity_Country__c != Null &&
                          ordPdtCS.SBQQ__OrderItem__r.Product2.ProductCode != Null &&
                          ordPdtCS.SBQQ__UnitOfMeasure__c != Null){
                            //Converting the key of COuntry and UOM to Lower case to make Key as same as Alphabetical issue
                            keyCompare  = (String)ordPdtCS.SBQQ__OrderItem__r.QTB_Legal_Entity_Country__c.toLowerCase() + '-' + ordPdtCS.SBQQ__OrderItem__r.Product2.ProductCode + '-' + (String)ordPdtCS.SBQQ__UnitOfMeasure__c.toLowerCase();
                        }
                        
                        if(mapOfKeyWithDefaultDescvalue !=null && keyCompare != Null && mapOfKeyWithDefaultDescvalue.containsKey(keyCompare) ){
                            ordPdtCS.QTB_UOM_Description_Text__c =  mapOfKeyWithDefaultDescvalue.get(keyCompare);
                        }
                        else {
                            ordPdtCS.QTB_UOM_Description_Text__c = ''; // clear if no match
                        }
                        ordPdtCS.QTB_Localized_UOM_Description__c = ''; // Always clear the Localized field
                    }
                    opcsList.add(ordPdtCS);
                }
                if(!opcsList.isempty()){
                    update opcsList;
                    //passing Order Products that relate to updated opcsList
                    for(SBQQ__OrderItemConsumptionSchedule__c opcs : opcsList) {
                        opcsOrderProdIds.add(opcs.SBQQ__OrderItem__c);
                    }
                }
            //#32975 Commented the below Code due to this methos is triggering twice on Account Update now on Update on Account the above method is working
            //When triggered from Account helper upon change of Acc language
           /* else if(!accountList.isempty())
            {
                //Query to get the list of OPCS based on the Order Item-> Account recieved (Filtering based upon Order end date)
                List<SBQQ__OrderItemConsumptionSchedule__c> ordPrdtCSlist = [SELECT Id,Name,SBQQ__OrderItem__c,SBQQ__OrderItem__r.QTB_Language__c,SBQQ__UnitOfMeasure__c,SBQQ__OrderItem__r.QTB_Legal_Entity_Country__c,SBQQ__OrderItem__r.Product2.ProductCode,QTB_Localized_UOM_Description__c,QTB_UOM_Description_Text__c  
                                                                             FROM SBQQ__OrderItemConsumptionSchedule__c 
                                                                             WHERE SBQQ__OrderItem__r.order.AccountId IN :accountList and (SBQQ__OrderItem__r.order.EndDate = null or SBQQ__OrderItem__r.order.EndDate = LAST_90_DAYS  or SBQQ__OrderItem__r.order.EndDate >= TODAY) AND SBQQ__UnitOfMeasure__c!= Null];
                
                Map<String, QTB_UOM_Translation__mdt> allTranslations = QTB_UOM_Translation__mdt.getAll();
                // Querying the QTB_Bill_Code_Product_Lookup__c records to create a map of Combo as Country + ProductCode + UOM to get the unique combo and add
                //  the Default description value of that
                for(QTB_Bill_Code_Product_Lookup__c bcpl : [SELECT Id, QTB_Country__r.name, QTB_Product_Code__c, 
                                                            QTB_UOM__c, QTB_Default_Bill_Code_Description__c 
                                                            FROM QTB_Bill_Code_Product_Lookup__c 
                                                            WHERE QTB_UOM__c != null 
                                                            AND QTB_Default_Bill_Code_Description__c != null 
                                                            AND QTB_Country__r.name IN : countries
                                                            AND QTB_Product_Code__c != null ] ){
                                                                String key = bcpl.QTB_Country__r.name + '-' + bcpl.QTB_Product_Code__c + '-'+ bcpl.QTB_UOM__c;
                                                                //Adding only unique value as basically first record to get added only unique Values
                                                                if (mapOfKeyWithDefaultDescvalue != Null && !mapOfKeyWithDefaultDescvalue.containsKey(key)) {
                                                                    mapOfKeyWithDefaultDescvalue.put(key, bcpl.QTB_Default_Bill_Code_Description__c);
                                                                }              
                                                            }
                system.debug('mapOfKeyWithDefaultDescvalue:'+mapOfKeyWithDefaultDescvalue);
                
                // Querying the QTB_UOM_Translation__mdt records to create a map of Combo as UOM + Language to get the unique combo and add
                //  the Translated value of that
                for(QTB_UOM_Translation__mdt uomTranslate : allTranslations.values()){
                    mapOfKeyWithTransDescvalue.put(uomTranslate.QTB_UnitOfMeasure__c + '-'+ uomTranslate.QTB_Language__c,uomTranslate.QTB_Translated_Value__c);   
                }
                //Iterating on list of Order item ids and OPCS
                
                for (SBQQ__OrderItemConsumptionSchedule__c ordPdtCS: ordPrdtCSlist )
                {
                    string keyCompare; 
                    //If Account language is English creating key as Country + Product Code + UOm and getting the value from QTB_Bill_Code_Product_Lookup__c table
                    //If Account Language is other than English creating the key as UOM + language and getting the value from QTB_UOM_Translation__mdt table
                    if(ordPdtCS.SBQQ__OrderItem__r.QTB_Language__c != 'en_US'){
                        if(ordPdtCS.QTB_UOM_Description_Text__c != Null){
                            ordPdtCS.QTB_UOM_Description_Text__c = '';
                            opcsList.add(ordPdtCS);
                        }
                        keyCompare = ordPdtCS.SBQQ__UnitOfMeasure__c + '-' + ordPdtCS.SBQQ__OrderItem__r.QTB_Language__c;
                        if(mapOfKeyWithTransDescvalue !=null && mapOfKeyWithTransDescvalue.containsKey(keyCompare) ){
                            ordPdtCS.QTB_Localized_UOM_Description__c =  mapOfKeyWithTransDescvalue.get(keyCompare);
                            opcsList.add(ordPdtCS);
                        }
                    }
                    else {
                        if(ordPdtCS.QTB_Localized_UOM_Description__c != Null){
                            ordPdtCS.QTB_Localized_UOM_Description__c = '';
                            opcsList.add(ordPdtCS);
                            
                        }
                        keyCompare  = ordPdtCS.SBQQ__OrderItem__r.QTB_Legal_Entity_Country__c + '-' + ordPdtCS.SBQQ__OrderItem__r.Product2.ProductCode + '-' + ordPdtCS.SBQQ__UnitOfMeasure__c;
                        if(mapOfKeyWithDefaultDescvalue !=null && mapOfKeyWithDefaultDescvalue.containsKey(keyCompare) ){
                            ordPdtCS.QTB_UOM_Description_Text__c =  mapOfKeyWithDefaultDescvalue.get(keyCompare);
                            opcsList.add(ordPdtCS);
                        }
                    }
                }
                if(!opcsList.isempty()){
                    update opcsList;
                }
            }*/
            //Adding the Instance For updating the newly Created field QTB_language_Changed_Value__c to Existing one and which will be used for triggering point on Order Product helper
            //And also Adding to Recursive check of uomDescriptionUpdateOPCSIds of Updated OpCs Op Ids for Further excluding the recursion
                if(!opcsOrderProdIds.isEmpty()){
                    for(OrderItem ordProd : ordItemNewList) {
                        if(opcsOrderProdIds.contains(ordProd.Id)) {
                            orderProductsToUpdate.add(new OrderItem(Id = ordProd.Id, QTB_language_Changed_Value__c = ordProd.QTB_Language__c));
                        }
                        QTB_RecursiveHandlerCheck.uomDescriptionUpdateOPCSIds.add(ordProd.Id);
                    }
                    
                    if(!orderProductsToUpdate.isEmpty()) {
                        update orderProductsToUpdate;
                    }
                }
            //Clearing all the List and Set of IDs after updation
            mapOfKeyWithDefaultDescvalue.clear();
            mapOfKeyWithTransDescvalue.clear();
            opcsList.clear();
            orderProductsToUpdate.clear();
            opcsOrderProdIds.clear();
        }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),ORDER_PRODUCT_UTILS);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method        : UpdateAccountHoldBillingStatus
* Parameters    : Set<Id> ordersIdSet
* Return type   : void
* Requirement   : GitLab # 22554
* Description   : GitLab # 22554 Utils class to Update Account Hold Billing Status field based on OI Hold Billing value
**************************************************************************************************************/
    
    public static void updateAccountHoldBillingStatus(Set<Id> ordersIdSet){
        if(QTB_RecursiveHandlerCheck.updateAccountHoldBillingStatus==true){
            try{
                if(!ordersIdSet.isEmpty()){
                    // map to store product Id and its related orderitem
                    map<Id,List<orderItem>> productOrderItemMap = new Map<Id,List<orderItem>>();
                    //List of order item on which to check hold billing value, excluding bundle header order products
                    List<OrderItem> ordItmLst = new List<orderItem>();
                    Set<Id>bundleProductCheck = new Set<Id>();
                    // querying on order item to check whether OI is bundle product or not, checking with field SBQQ__RequiredBy__c
                    for(orderItem ordItm :[SELECT Id,SBQQ__RequiredBy__c ,Product2Id,OrderId,blng__HoldBilling__c,Order.Account.QTB_Hold_Status__c ,Order.AccountId,Order.Account.QTB_Hold_Billing__c
                                           FROM OrderItem WHERE OrderId IN :ordersIdSet AND SBQQ__Activated__c = true AND Order.QTB_OrderCategory__c !='Rebill'
                                           AND Order.QTB_OrderCategory__c !='Legacy' AND (SBQQ__TerminatedDate__c = null OR SBQQ__TerminatedDate__c >= TODAY)])
                    {
                        // storing product ID and its related list of order item into map
                        if(productOrderItemMap.containsKey(ordItm.product2Id)){
                            productOrderItemMap.get(ordItm.product2Id).add(ordItm);
                            if(ordItm.SBQQ__RequiredBy__c != null){
                                //adding this product to main list as these products are part of bundle product
                                ordItmLst.add(ordItm);
                            }
                            else{
                                // if SBQQ__RequiredBy__c is null -> order item is either standalone product or bundle product
                                bundleProductCheck.add(ordItm.Product2Id);
                            }
                        }
                        else{
                            productOrderItemMap.put(ordItm.product2Id,new List<OrderItem>{ordItm});
                            if(ordItm.SBQQ__RequiredBy__c != null){
                                ordItmLst.add(ordItm);
                            }
                            else{
                                bundleProductCheck.add(ordItm.Product2Id);
                            }
                        }
                    }
                    // checking on the order item's product, whethere it is bundle product or not
                    if(!bundleProductCheck.isEmpty()){
                        for(product2 prd :[select id,(select id from sbqq__Options__r limit 1) from Product2 where Id in :bundleProductCheck]){
                            // if product is not having any product option that means, it is not bundle product
                            if(prd.sbqq__Options__r.isEmpty()){
                                // adding the order item to the list to chcking hold billing
                                ordItmLst.addAll(productOrderItemMap.get(prd.Id));
                            }
                        }
                        bundleProductCheck.clear();
                        productOrderItemMap.clear();
                    }
                    if(!ordItmLst.isEmpty()){
                        // List to update account
                        List<Account> lstAccForHoldBillingUpdate = new List<Account>();
                        // Map to store accountId and hold billing
                        Map<id,boolean> mapofAccIdAndHoldBilling = new Map<id,boolean>();
                        //Set to Store AccountId Having Hold Billing
                        Set<Id> setAccIdOrdProHavingHb = new Set<id>();
                        //Set to Store AccountId not having Hold Billing
                        Set<Id> setAccIdOrdProNotHavingHb = new Set<id>();
                        
                        for (OrderItem oi :ordItmLst){
                            if(!mapofAccIdAndHoldBilling.containsKey(oi.Order.AccountId)){
                                mapofAccIdAndHoldBilling.put(oi.Order.AccountId,oi.Order.Account.QTB_Hold_Billing__c);
                            }
                            // If both Account and OI having Hold billing true
                            if(oi.blng__HoldBilling__c == 'Yes' &&  oi.Order.Account.QTB_Hold_Billing__c == true){
                                setAccIdOrdProHavingHb.add(oi.Order.AccountId);
                            }
                            else{
                                // If both Account and OI having Hold billing false
                                if(oi.blng__HoldBilling__c == 'No' &&  oi.Order.Account.QTB_Hold_Billing__c == false){
                                    setAccIdOrdProNotHavingHb.add(oi.Order.AccountId);
                                }
                            }
                        }
                        if(!setAccIdOrdProHavingHb.isEmpty() || !setAccIdOrdProNotHavingHb.isEmpty()){
                            for(Id acId : mapofAccIdAndHoldBilling.keySet()){
                                Account acc = new account();
                                acc.id = acId;
                                // Update On Hold Status when both Account and OI having Hold billing true
                                if(mapofAccIdAndHoldBilling.get(acId) && (!setAccIdOrdProHavingHb.isEmpty() && setAccIdOrdProHavingHb.contains(acId))){
                                    acc.QTB_Hold_Status__c = 'On Hold';
                                }
                                else{
                                    // Update Ready To Bill Status when both Account and OI having Hold billing false
                                    if(!mapofAccIdAndHoldBilling.get(acId) && (!setAccIdOrdProNotHavingHb.isEmpty() && setAccIdOrdProNotHavingHb.contains(acId))){
                                        acc.QTB_Hold_Status__c = 'Ready to Bill';
                                    }
                                }
                                lstAccForHoldBillingUpdate.add(acc);
                            }
                            mapofAccIdAndHoldBilling.clear();
                            setAccIdOrdProHavingHb.clear();
                            setAccIdOrdProNotHavingHb.clear();
                        }
                        if(!lstAccForHoldBillingUpdate.isEmpty()){
                            QTB_RecursiveHandlerCheck.updateAccountHoldBillingStatus = false;
                            update lstAccForHoldBillingUpdate;
                            lstAccForHoldBillingUpdate.clear();
                        }
                    }
                }
            }catch (exception e) {
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(
                    e.getLineNumber(),
                    e.getStackTraceString(),
                    e.getMessage(),
                    e.getTypeName(),
                    ORDER_PRODUCT_UTILS
                );
                throw e;
            }
        }
    }
    /***********************************************************************************************************
* Method        : setTranslatedProductGroup
* Parameters    : List<Id> ordItemId,List<Account>AccountList
* Return type   : void
* Requirement   : Gitlab US #23284
* Description   : setting Translated value for price schedule category, this method is getting called from
QTB_accountHelper also when account language is updated
**************************************************************************************************************/
    public static void setTranslatedProductGroup(List<OrderItem> ordItemLst,List<Account> accountList){
        system.debug('Inside setTranslatedProductGroup method ');
        Set<String> priceScheduleCategoryValues = new Set<String>();
        set<string> accLan = new set<string>();
        List<OrderItem> updateProductGroupTranslatedList = new List<OrderItem>();
        
        try{
            //When Before_Insert is triggered from Order item then iterating on list of OP and getting the QTB_Price_Schedule_Category__c & accLan values
            if(ordItemLst !=null && !ordItemLst.isempty())
            {
                for(OrderItem ordItem :ordItemLst)
                {
                    priceScheduleCategoryValues.add(ordItem.QTB_Price_Schedule_Category__c);
                    accLan.add(ordItem.QTB_Language__c);//variable which holds the Order items -> Language
                }
                //query QTB_translatedProductGroup__mdt records for converting productgroup name based on Order Item language
                map<String,QTB_translatedProductGroup__mdt> translationMap = new map<String,QTB_translatedProductGroup__mdt>();
                if(!priceScheduleCategoryValues.isEmpty() && !accLan.isEmpty())
                {
                    //Create a Map of QTB_translatedProductGroup__mdt, key as combination of QTB_Price_Schedule_Category__c and language
                    for(QTB_translatedProductGroup__mdt transProdGrp :[Select id,QTB_Price_Schedule_Category__c,QTB_Translated_Value__c,QTB_Language_Code__c from QTB_translatedProductGroup__mdt where
                                                                       QTB_Language_Code__c in :accLan and QTB_Price_Schedule_Category__c in :priceScheduleCategoryValues]){
                                                                           translationMap.put(transProdGrp.QTB_Price_Schedule_Category__c+transProdGrp.QTB_Language_Code__c,transProdGrp);
                                                                       }
                }
                priceScheduleCategoryValues.clear();
                accLan.clear();
                //Iterating on list of Order item received
                for(OrderItem ordItem : ordItemLst)
                {
                    if(ordItem.QTB_Price_Schedule_Category__c != null && translationMap.containsKey(ordItem.QTB_Price_Schedule_Category__c+ordItem.QTB_Language__c))
                    {
                        ordItem.QTB_Translated_Product_Group__c = translationMap.get(ordItem.QTB_Price_Schedule_Category__c+ordItem.QTB_Language__c).QTB_Translated_Value__c;
                    }
                    else{
                        ordItem.QTB_Translated_Product_Group__c = ordItem.QTB_Price_Schedule_Category__c;
                    }
                }
                translationMap.clear();
            }
            //When After_Update is triggered from Account helper when language is changed then iterating on list of Account ids and getting the Order items (Filtering based upon Order end date)
            else if(!accountList.isempty())
            {
                List<OrderItem> ordLocAccounList = [select QTB_Price_Schedule_Category__c,QTB_Language__c from OrderItem where order.AccountId IN: accountList and (order.EndDate = null or order.EndDate = LAST_90_DAYS  or order.EndDate >= TODAY)];
                //adding the values of QTB_Price_Schedule_Category__c & language to a variable
                for(OrderItem ordItem : ordLocAccounList )
                {
                    priceScheduleCategoryValues.add(ordItem.QTB_Price_Schedule_Category__c);
                    accLan.add(ordItem.QTB_Language__c);//variable which holds the Account -> Language
                }
                
                //query QTB_translatedProductGroup__mdt records for converting productgroup name based on Order Item language
                map<String,QTB_translatedProductGroup__mdt> translationMap = new map<String,QTB_translatedProductGroup__mdt>();
                if(!priceScheduleCategoryValues.isEmpty() && !accLan.isEmpty()){
                    //Create a Map of QTB_translatedProductGroup__mdt, key as combination of QTB_Price_Schedule_Category__c and language
                    for(QTB_translatedProductGroup__mdt transProdGrp :[Select id,QTB_Price_Schedule_Category__c,QTB_Translated_Value__c,QTB_Language_Code__c from QTB_translatedProductGroup__mdt where
                                                                       QTB_Language_Code__c in :accLan and QTB_Price_Schedule_Category__c in :priceScheduleCategoryValues]){
                                                                           translationMap.put(transProdGrp.QTB_Price_Schedule_Category__c+transProdGrp.QTB_Language_Code__c,transProdGrp);
                                                                       }
                    
                }
                priceScheduleCategoryValues.clear();
                accLan.clear();
                //Iterating on list of Order item received
                for(OrderItem ordItem : ordLocAccounList)
                {
                    if(ordItem.QTB_Price_Schedule_Category__c != null && translationMap.containsKey(ordItem.QTB_Price_Schedule_Category__c+ordItem.QTB_Language__c)){
                        ordItem.QTB_Translated_Product_Group__c = translationMap.get(ordItem.QTB_Price_Schedule_Category__c+ordItem.QTB_Language__c).QTB_Translated_Value__c;//Assigning the translated values defined at QTB_translatedProductGroup__mdt level onto OP's QTB_Translated_Product_Group__c
                        updateProductGroupTranslatedList.add(ordItem);
                    }
                    //if no translated value present then to update a null value
                    else{
                        ordItem.QTB_Translated_Product_Group__c = ordItem.QTB_Price_Schedule_Category__c;
                        updateProductGroupTranslatedList.add(ordItem);
                    }
                }
                translationMap.clear();
                if(!updateProductGroupTranslatedList.isempty()){
                    Update updateProductGroupTranslatedList;
                }
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),ORDER_PRODUCT_UTILS);
            throw e;
        }
        
    }
}
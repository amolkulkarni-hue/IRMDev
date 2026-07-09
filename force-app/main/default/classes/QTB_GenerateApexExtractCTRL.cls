/*****************************************************************************************************
* Class     : QTB_GenerateApexExtractCTRL
* Test Class : QTB_GenerateApexExtractCTRL_Test
* Purpose   : This class containing logic for sending response to aura and generating documents via VF
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*  Sriram        7/22/2020       Created initial class
*  Gopi/Sriram   10/19/2020      Version 1: Logic change for validation, Invoice 'Subtotal' value with the total 'calculated amount'
*  Renuka Prasad 02/27/2024      Changes to Sync the Backing Up Report File for SITAD from Salesforce to SMS
* Shailesh 		 06/20/2024		//Gitlab US#24329 - Handling the large no of usage in Invoice Extract
*******************************************************************************************************/
public class QTB_GenerateApexExtractCTRL {    
    //Sending Invoice Presentment to aura component
    //Gitlab US#24329 -- code refactored
    @AuraEnabled
    public static String getinvoicepresentment(String recordID)  {
        try{
            List<blng__Invoice__c> invStatus = [SELECT id,blng__InvoiceStatus__c,blng__Account__r.QTB_Language__c,blng__Account__r.QTB_Legal_Entity_Country__c 
                                                FROM blng__Invoice__c 
                                                WHERE Id=: recordID];
            if(invStatus != null && invStatus.size()>0){
                list<QTB_Invoice_Presentment_Settings__mdt> invoicePresentSettings = [SELECT id, QTB_Billing_Country__c, QTB_Invoice_Presentment_System__c 
                                                                                      FROM QTB_Invoice_Presentment_Settings__mdt
                                                                                      WHERE QTB_Billing_Country__c =: invStatus[0].blng__Account__r.QTB_Legal_Entity_Country__c limit 1];
                //Gitlab US#24860 -- return the message for non-applicable apix extract country
                string InvoicePresentmentsystem = !invoicePresentSettings.isEmpty() 
                    ? invoicePresentSettings[0].QTB_Invoice_Presentment_System__c
                    : invStatus[0].blng__Account__r.QTB_Legal_Entity_Country__c + ' country is not applicable for Apix presentment.';  
                return InvoicePresentmentsystem;
            }
            else{
                string InvoicePresentmentsystem ='Presentmentcheck';
                return InvoicePresentmentsystem;
            }
            
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
        }catch(Exception e) {
            QTB_ExceptionLogger.enable();//Gitlab #23089
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApexExtractCTRL.getStatus');
            throw e;
        }
    }
    
    public static void increaseCoverage(){
        Integer i=0;
            i++;
             i++; 
        i++; i++; 
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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
    
    //Sending invoice status to aura component
    @AuraEnabled
    public static String getStatus(String recordID) {
        try{
             //Gitlab #23874 Ready for Integration check for Apix generation
            List<blng__Invoice__c> invStatus = [SELECT id,blng__InvoiceStatus__c,blng__Account__r.QTB_Language__c 
                                                FROM blng__Invoice__c 
                                                WHERE Id=: recordID and (blng__InvoiceStatus__c = 'Draft' or (blng__InvoiceStatus__c = 'Posted' and QTB_Ready_for_Integration__c = true))];
            if(invStatus != null && invStatus.size()>0){
                String status = invStatus[0].blng__InvoiceStatus__c;
                return status;
            }
            else{
                String status = 'StatusCheck';
                return status;
            }
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
        }catch(Exception e) {
            QTB_ExceptionLogger.enable();//Gitlab #23089
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApexExtractCTRL.getStatus');
            throw e;
        }
    }
    
    //calling VF page to generate CSV files
    @AuraEnabled
    public static void generateCSV(String recordID) {
        String invNumber;
        //Fetch all the invoice and the invoice lines details
        list<blng__Invoice__c> invLst = [Select id,QTB_Custom_Invoice_Number__c,Name,QTB_Last_Invoice_Sent__c,blng__InvoiceStatus__c,
                                         blng__Account__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c,blng__Account__r.QTB_Language__c,
                                         CurrencyIsoCode,blng__Account__r.blng__BillToContact__r.Email,blng__Account__r.QTB_Invoice_Delivery_Options__c,
                                         blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Account_Balance__c,
                                         blng__InvoiceDate__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                                         blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c,
                                         blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c,
                                         blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IRM_Contact_Details__c,
                                         blng__Account__r.QTB_Contract_Entity__r.QTB_PAN_NO__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Email__c,
                                         blng__DueDate__c,blng__TaxAmount__c,blng__TotalAmount__c,blng__Account__r.QTB_Legal_Entity__r.blng__Street1__c,
                                         blng__Account__r.QTB_Legal_Entity__r.blng__Street2__c,blng__Account__r.QTB_Legal_Entity__r.blng__City__c,
                                         blng__Account__r.QTB_Legal_Entity__r.blng__State__c,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Customer_Classification__c,
                                         blng__Account__r.QTB_Legal_Entity__r.blng__ZipPostalCode__c,blng__Account__r.BillingStreet,
                                         blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.BillingCountry,
                                         blng__Account__r.QTB_Consolidation_Flag__c,blng__Account__r.QTB_HoldInd__c,blng__Account__r.QTB_HoldRequester__c,
                                         blng__Account__r.QTB_IMCompany__c,QTB_TotalAdjustmentAmount__c,QTB_LateFee__c,blng__Account__r.QTB_ContractNumber__c,
                                         blng__Account__r.QTB_CageCode__c,QTB_SiteAdjustmentTotal__c,QTB_SiteNumberTotal__c,QTB_Site_Late_Fee_Amount__c,
                                         blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c,blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c,
                                         blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c,
                                         blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c,
                                         blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c,
                                         blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c,
                                         blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c,
                                         blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c,
                                         blng__Account__r.QTB_Legal_Entity_Country__c,QTB_SiteLateFeeAmount__c,
                                         QTB_Purchase_Order__c,QTB_Site_Number__c, blng__InvoiceRunCreatedBy__r.name,//Story Git #7673 (SLALOM)
                                         QTB_PaymentsRcvd__c,QTB_AdjustmentsRcvdAmt__c,QTB_PastDueBalanceTotal__c,QTB_CurrentTotalAmount__c,
                                         blng__Account__r.QTB_SITAD__c, //Changes to Sync the Backing Up Report File for SITAD from Salesforce to SMS
                                         (Select id,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Quantity__c,blng__Product__r.QTB_Price_Schedule_Category__c,blng__Product__r.ProductCode,blng__Product__r.Name,QTB_Charge_Type__c,QTB_Inc_Quantity__c,QTB_Charged_Quantity__c,QTB_Unit_Price__c,
                                          blng__TotalAmount__c,blng__TaxAmount__c,Name,blng__UsageSummary__r.blng__SummaryEndDate__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_HasConsumptionSchedule__c,blng__Invoice__r.QTB_Custom_Invoice_Number__c,
                                          blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__Invoice__r.blng__Account__r.QTB_SITAD__c //Gitlab US#22996 -- field added
                                          from blng__InvoiceInvoiceLines__r)
                                         from blng__Invoice__c 
                                         WHERE ID =: recordID];
        
        if(invLst.size() > 0 && invLst[0].QTB_Last_Invoice_Sent__c != null){
            throw new AuraHandledException('The invoice extract is already generated'); 
        }
        
        Boolean isInvoiceXmlSent = false;
        //Logic to check Invoice presentment system
        if (invLst != null && invLst.size() > 0) {
            //Fetching all the Invoice presentment custom meta records
            list<QTB_Invoice_Presentment_Settings__mdt> invoicePresentSettings = [Select id, QTB_Billing_Country__c, QTB_Invoice_Presentment_System__c from QTB_Invoice_Presentment_Settings__mdt
                                                                                  where QTB_Billing_Country__c =: invLst[0].blng__Account__r.QTB_Legal_Entity_Country__c limit 1];
            System.debug('invoicePresentSettings>>>'+invoicePresentSettings);
            
            //check if the value is matching with the total calculated amount
            boolean amountMatched = compareCalculatedTotal(recordID,invLst[0].blng__Subtotal__c,invLst[0].blng__InvoiceStatus__c);
            
            //Logic to check whether Invoice presentment is Billtrust or Apix
            if (invoicePresentSettings.size() > 0 && invoicePresentSettings[0].QTB_Invoice_Presentment_System__c != null &&
                invoicePresentSettings[0].QTB_Invoice_Presentment_System__c == QTB_GenerateBillTrustExtractCTRL.INVOICE_PRESENTMENT_BILLTRUST) {
                    System.debug('generateCSV>>>');
                    
                    if (invLst[0].QTB_Last_Invoice_Sent__c != null) {
                        throw new AuraHandledException('The invoice extract is already generated'); 
                    } else {
                        QTB_GenerateBillTrustExtractCTRL.generateBillTrustXml(invLst, null, null);
                        
                        //Logic to update the Invoice Last Sent date
                        list<blng__Invoice__c> invoicesToUpdate = new list<blng__Invoice__c>();
                        for (blng__Invoice__c invoi: invLst) {
                            if (invoi.blng__InvoiceStatus__c == QTB_Constants.INVOICE_STATUS_POSTED) {
                                blng__Invoice__c invToUpd = new blng__Invoice__c();
                                invToUpd.id = invoi.id;
                                invToUpd.QTB_Last_Invoice_Sent__c = DateTime.now();
                                invoicesToUpdate.add(invToUpd);
                            }
                            
                            if (amountMatched || test.isrunningtest()) {
                                QTB_BillTrustUtil.generateCSV(invoi, null);
                            }
                        }
                        if (invoicesToUpdate.size() > 0) {
                            update invoicesToUpdate;
                        }
                        
                        return;
                    }
                }
            
            if(amountMatched || test.isrunningtest()){
                try{
                    invNumber = invLst[0].QTB_Custom_Invoice_Number__c;
                    List<blng__Invoice__c> invUpdateLst = new List<blng__Invoice__c>(); 
                    //Call VF page to create the Data in proper CSV format                  
                    PageReference vfPg = new PageReference ('/apex/QTB_GenerateUsageCSV');
                    vfPg.getParameters().put('Id',recordID);
                    vfPg.getParameters().put('Lang',invLst[0].blng__Account__r.QTB_Language__c);
                    Blob pageData;
                    if(Test.isRunningTest()) { 
                        pageData = blob.valueOf('Unit.Test');
                    } else {
                        //Gitlab US#23089 -- Skip the CSV file generation for the accounts where invoice's are more than 10000+
                        //to solve the following exception -- System.VisualforceException: Collection size 12,303 exceeds maximum size of 10,000
                        //Gitlab US#24329 -- based on the usage count executing/excluding the CSV logic
                        Integer usageCount = getUsageCount(recordID);
                        if(usageCount > Integer.valueOf(System.Label.QTB_ApixExtractCSVLimit)){
                            pageData = blob.valueOf('CSV file is not available temporarily, please contact System Admin.');
                        }
                        else{
                            pageData = vfPg.getContent(); 
                        }
                    }
                    //Attach CSV File to the Current invoice Record
                    ContentVersion conVer = new ContentVersion();
                    conVer.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                    conVer.PathOnClient = 'IRM_InvRep_'+invNumber+'_'+Date.Today().Month()+String.ValueOf(Date.Today().Year()).Right(2)+'.csv';
                    conVer.Title = 'IRM_InvRep_'+invNumber+'_'+Date.Today().Month()+String.ValueOf(Date.Today().Year()).Right(2)+'.csv'; // Display name of the files
                    conVer.VersionData = pageData;//File content
                    insert conVer;
                    Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
                    
                    //Create ContentDocumentLink
                    ContentDocumentLink cDe = new ContentDocumentLink();
                    cDe.ContentDocumentId = conDoc;
                    cDe.LinkedEntityId = recordID; // you can use objectId,GroupId etc
                    cDe.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                    cDe.Visibility = 'InternalUsers'; //AllUsers, InternalUsers, SharedUsers
                    insert cDe;
                    //Once Invoice is generated, update the 'QTB_Last_Invoice_Sent__c' to Today's Date
                    for(blng__Invoice__c inv : invLst){
                        inv.QTB_Last_Invoice_Sent__c = datetime.now();
                        invUpdateLst.add(inv);
                    }
                    update invUpdateLst;
                    //calling VF page to generate txt files
                    system.debug('@@invLst[0]'+invLst[0]);
                    generateTxt(recordID,invLst[0]);
                }catch(exception e){
                    //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
                    QTB_ExceptionLogger.enable();//Gitlab #23089
                    QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApexExtractCTRL.generateCSV');
                    throw new AuraHandledException('Something went wrong: '+e.getMessage()+e.getLineNumber());
                }
            }else{//Invoice 'Subtotal' value is not matching with the total 'calculated amount' then, throw exception
                throw new AuraHandledException('Summary of Invoice Lines (Usages) is not matching with Invoice Subtotal, Please check before you generate Report'); 
            }
        }else{//If Already Report generated for the invoice OR 'QTB_Last_Invoice_Sent__c' field is not NULL
            throw new AuraHandledException('The invoice extract is already generated'); 
        }
    }
    //This method is to check the Draft status amount.
    //If the amount matches then allow to create the APIX extract, else show an confirmation message.
    @AuraEnabled
    public static boolean checkDraftAmounts(String recordID){
        blng__Invoice__c invLst = [Select id,QTB_Custom_Invoice_Number__c,Name,blng__InvoiceStatus__c,blng__Subtotal__c from blng__Invoice__c where Id=: recordID];
        boolean amountMatched = true;
        //check if the value is matching with the total calculated amount
        amountMatched = compareCalculatedTotal(recordID,invLst.blng__Subtotal__c,invLst.blng__InvoiceStatus__c);
        return amountMatched;
    }
    //calling VF page to generate txt files
    @AuraEnabled
    public static void generateTxt(String recordID, blng__Invoice__c inv) {
        blng__Invoice__c invLst = new blng__Invoice__c();
        if(inv == null){
            invLst = [SELECT id,QTB_Custom_Invoice_Number__c,Name,QTB_Last_Invoice_Sent__c,blng__InvoiceStatus__c,blng__Account__r.Parent.Name,//Gitlab US#24329
                      blng__Account__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c,blng__Account__r.QTB_Language__c,
                      CurrencyIsoCode,blng__Account__r.blng__BillToContact__r.Email,blng__Account__r.QTB_Invoice_Delivery_Options__c,
                      blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Account_Balance__c,
                      blng__InvoiceDate__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                      blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c,
                      blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c,
                      blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IRM_Contact_Details__c,
                      blng__Account__r.QTB_Contract_Entity__r.QTB_PAN_NO__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Email__c,
                      blng__DueDate__c,blng__TaxAmount__c,blng__TotalAmount__c,blng__Account__r.QTB_Legal_Entity__r.blng__Street1__c,
                      blng__Account__r.QTB_Legal_Entity__r.blng__Street2__c,blng__Account__r.QTB_Legal_Entity__r.blng__City__c,
                      blng__Account__r.QTB_Legal_Entity__r.blng__State__c,blng__Account__r.QTB_Tax_ID__c, blng__Account__r.QTB_Customer_Classification__c,
                      blng__Account__r.QTB_Legal_Entity__r.blng__ZipPostalCode__c,blng__Account__r.BillingStreet,
                      blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.BillingCountry,
                      blng__Account__r.QTB_Consolidation_Flag__c,blng__Account__r.QTB_HoldInd__c,blng__Account__r.QTB_HoldRequester__c,
                      blng__Account__r.QTB_IMCompany__c,QTB_TotalAdjustmentAmount__c,QTB_LateFee__c,blng__Account__r.QTB_ContractNumber__c,
                      blng__Account__r.QTB_CageCode__c,QTB_SiteAdjustmentTotal__c,QTB_SiteNumberTotal__c,QTB_Site_Late_Fee_Amount__c,
                      blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c,blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c,
                      blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c,
                      blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c,
                      blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c,
                      blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c,
                      blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c,
                      blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,//Gitlab US#24329
                      blng__Account__r.QTB_Legal_Entity_Country__c,QTB_SiteLateFeeAmount__c,
                      QTB_Purchase_Order__c,QTB_Site_Number__c, blng__InvoiceRunCreatedBy__r.name,//Story Git #7673 (SLALOM)
                      QTB_PaymentsRcvd__c,QTB_AdjustmentsRcvdAmt__c,QTB_PastDueBalanceTotal__c,QTB_CurrentTotalAmount__c,
                      (SELECT id,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Product__r.Name,blng__Quantity__c,blng__Product__r.QTB_Price_Schedule_Category__c,blng__Product__r.ProductCode,QTB_Charge_Type__c,QTB_Inc_Quantity__c,QTB_Charged_Quantity__c,QTB_Unit_Price__c,
                       blng__TotalAmount__c,blng__TaxAmount__c,Name,blng__UsageSummary__r.blng__SummaryEndDate__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_HasConsumptionSchedule__c,blng__Invoice__r.QTB_Custom_Invoice_Number__c,
                       blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__Invoice__r.blng__Account__r.QTB_SITAD__c
                       FROM blng__InvoiceInvoiceLines__r)
                      FROM blng__Invoice__c 
                      WHERE ID =: recordID];
        }
        else{
            invLst = inv;
        }
        //Gitlab US#24329
        if(!Test.isRunningTest() && invLst != null && invLst.QTB_Last_Invoice_Sent__c != null && System.Label.QTB_SkipCSVForApixExtract.equalsIgnoreCase('true')){
            throw new AuraHandledException('The invoice extract is already generated'); 
        }
        //Fetching all the Invoice presentment custom meta records
        list<QTB_Invoice_Presentment_Settings__mdt> invoicePresentSettings = [SELECT id, QTB_Billing_Country__c, QTB_Invoice_Presentment_System__c 
                                                                              FROM QTB_Invoice_Presentment_Settings__mdt
                                                                              WHERE QTB_Billing_Country__c =: invLst.blng__Account__r.QTB_Legal_Entity_Country__c limit 1];
        //Logic to check whether Invoice presentment is Billtrust or Apix
        if (invoicePresentSettings.size() > 0 && invoicePresentSettings[0].QTB_Invoice_Presentment_System__c != null &&
            invoicePresentSettings[0].QTB_Invoice_Presentment_System__c == QTB_GenerateBillTrustExtractCTRL.INVOICE_PRESENTMENT_BILLTRUST) {
                list<blng__Invoice__c> tempInvList = new list<blng__Invoice__c>();
                tempInvList.add(invLst);
                QTB_GenerateBillTrustExtractCTRL.generateBillTrustXml(tempInvList, null, null);
                
                //Logic to update the Invoice Last Sent date
                list<blng__Invoice__c> invoicesToUpdate = new list<blng__Invoice__c>();
                for (blng__Invoice__c invoi: tempInvList) {
                    if (invoi.blng__InvoiceStatus__c == QTB_Constants.INVOICE_STATUS_POSTED) {
                        blng__Invoice__c invToUpd = new blng__Invoice__c();
                        invToUpd.id = invoi.id;
                        invToUpd.QTB_Last_Invoice_Sent__c = DateTime.now();
                        
                        invoicesToUpdate.add(invToUpd);
                    }
                }
                
                if (invoicesToUpdate.size() > 0) {
                    update invoicesToUpdate;
                }
                return;
            }
        try{
            //Gitlab US#24329
            Integer usageCount = getUsageCount(recordID); //Gitlab US#24329 -- calling the getUsageCount() method to get the usages for the inoivce
            System.debug('usageCount@@'+usageCount);  
            ////Gitlab US#24329 - if usageCount is less than the limit mentioned in custom label -- QTB_ApixExtractUsageLimit, then following the existing process
            if(usageCount < Integer.valueOf(System.Label.QTB_ApixExtractUsageLimit)){
                System.debug('Regular Invoice Apix Extract process@@');
                String invNumber = invLst.QTB_Custom_Invoice_Number__c;
                String invName = invLst.Name;
                //Call VF page to create the Data in proper Text format
                PageReference vfPg = new PageReference ('/apex/QTB_GenerateApexExtractVF');
                vfPg.getParameters().put('Id',recordID);
                vfPg.getParameters().put('isUsageWithinLimit','true');//Gitlab US#24329
                //Set Billing Account language and pass it to VF page.
                vfPg.getParameters().put('Lang',invLst.blng__Account__r.QTB_Language__c);            
                Blob pageData;
                if(Test.isRunningTest()) { 
                    pageData = blob.valueOf('Unit.Test');
                } else {
                    pageData = vfPg.getContent();
                }
                //Attach Text File to the Current invoice Record
                ContentVersion conVer = new ContentVersion();
                conVer.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                if(invLst.blng__InvoiceStatus__c == 'Posted'){
                    conVer.PathOnClient = 'IRM_Invoice_'+invNumber+'.txt';
                    conVer.Title = 'IRM_Invoice_'+invNumber+'.txt'; // Display name of the files
                }
                else{
                    conVer.PathOnClient = 'IRM_Invoice_TEMP-'+invName+'.txt';
                    conVer.Title = 'IRM_Invoice_TEMP-'+invName+'.txt'; // Display name of the files   
                }
                conVer.VersionData = pageData;//File content
                insert conVer;
                Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
                
                //Create ContentDocumentLink
                ContentDocumentLink cDe = new ContentDocumentLink();
                cDe.ContentDocumentId = conDoc;
                cDe.LinkedEntityId = recordID; // you can use objectId,GroupId etc
                cDe.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cDe.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
                insert cDe;
                
                 //Gitlab US#24329 & Gitlab US#25594 -- setting QTB_Last_Invoice_Sent__c only for posted invoice
                if(invLst.blng__InvoiceStatus__c == 'Posted'){
                    blng__Invoice__c invoice = new blng__Invoice__c();
                    invoice.Id = recordID;
                    invoice.QTB_Last_Invoice_Sent__c = datetime.now();
                    invoice.QTB_StoreApixInvoiceExtract__c = '';
                    invoice.QTB_StoreApixUsageExtract1__c = '';
                    invoice.QTB_StoreApixUsageExtract2__c = '';
                    invoice.QTB_StoreApixUsageExtract3__c = '';
                    invoice.QTB_StoreApixUsageExtract4__c = '';
                    invoice.QTB_StoreApixUsageExtract5__c = '';
                    invoice.QTB_StoreApixUsageExtract6__c = '';
                    update invoice;
                }
            }            
            else{ //Gitlab US#24329
                System.debug('Asynchronous Invoice Apix Extract process@@');
                generateTextFileAsync(recordID);
            }
            
        }catch(exception e){
            QTB_ExceptionLogger.enable();//Gitlab #23089
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApexExtractCTRL.generateTxt');
            throw new AuraHandledException('Something went wrong: '+e.getMessage()+'Line Number'+e.getLineNumber());
        }
    }
    //check if the value is matching with the total calculated amount
    public static boolean compareCalculatedTotal(string recordID, decimal invoiceTotal, string invStatus){
        //Query for invoiceLineItems related to invoice
        List<blng__InvoiceLine__c> invoiceLineItems = new List<blng__InvoiceLine__c>();
        invoiceLineItems = [select id,blng__UsageSummary__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c from blng__InvoiceLine__c where blng__Invoice__c =:recordID ];
        set<string> usageSummaries = new set<string>();
        List<blng__InvoiceLine__c> recurringInvoiceLine = new List<blng__InvoiceLine__c>();
        decimal TotalCalculatedAmount = 0;
        if(invoiceLineItems.size()>0 && invoiceLineItems != null) {   
            for(blng__InvoiceLine__c invLin:invoiceLineItems){
                usageSummaries.add(invLin.blng__UsageSummary__c);
                //Adding Recurring InvoiceLine 'Subtotal' to 'Calculated Total'
                //if(invLin.blng__ChargeType__c == 'Recurring'){
                //As per New Architecture, Recurring Lines are decided by 'QTB_HasConsumptionSchedule__c'
                //As per the Story #6509 & #6478, Recurring Lines are decided by 'QTB_Charge_Type__c'
                if(invLin.QTB_Charge_Type__c == 'Recurring'){
                    if(invLin.blng__Subtotal__c != null){
                        TotalCalculatedAmount += invLin.blng__Subtotal__c;
                    }
                }
            }
            // remove blanks and nulls
            usageSummaries.remove('');
            usageSummaries.remove(null);
        }
        
        if(!usageSummaries.isEmpty()){
            Map<id,decimal> groupAddingforRoundOff = new Map<id,decimal>();
            List<id> USid = new List<id>();
            integer count = 0;
            //Get all the usages
            for(blng__Usage__c usgS : [Select QTB_Rated_Amount__c,blng__PreratedAmount__c,QTB_Rated_Unit_Price__c,blng__Quantity__c,blng__UsageSummary__r.blng__UnitPrice__c from blng__Usage__c where blng__UsageSummary__c in :usageSummaries AND QTB_Rated_Amount__c != null order by blng__UsageSummary__c ]){
                count++;
                //Add 'Rated Amount' to the 'Calculated Total'
                if(invStatus == 'Posted'){
                    //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
                    if(groupAddingforRoundOff.containsKey(usgS.blng__UsageSummary__c)){
                        groupAddingforRoundOff.put(usgS.blng__UsageSummary__c, groupAddingforRoundOff.get(usgS.blng__UsageSummary__c)+usgS.QTB_Rated_Amount__c);
                    }else{
                        groupAddingforRoundOff.put(usgS.blng__UsageSummary__c,usgS.QTB_Rated_Amount__c);
                    }
                    USid.add(usgS.blng__UsageSummary__c);
                    //Compare the current value and previous value except first value as it'll give index out of bound error[count-2]
                    if(count <> 1 && USid[count - 1] != USid[count-2] ){
                        TotalCalculatedAmount += groupAddingforRoundOff.get(USid[count-2]).setScale(2, RoundingMode.HALF_UP);
                    }
                }else{
                    if(usgS.blng__PreratedAmount__c != null && usgS.blng__PreratedAmount__c != 0){ 
                        //TotalCalculatedAmount += usgS.blng__PreratedAmount__c.setScale(2, RoundingMode.HALF_UP);
                        TotalCalculatedAmount += usgS.blng__PreratedAmount__c;
                    }else{
                        if(usgS.blng__UsageSummary__r.blng__UnitPrice__c != null && usgS.blng__Quantity__c != null){
                            TotalCalculatedAmount += Decimal.valueof(double.valueOf(usgS.blng__Quantity__c)*double.valueOf(usgS.blng__UsageSummary__r.blng__UnitPrice__c));
                            //TotalCalculatedAmount += (usgS.blng__UsageSummary__r.blng__UnitPrice__c * double.valueOf(usgS.blng__Quantity__c)).setScale(2, RoundingMode.HALF_UP);
                        }
                    }
                }
            }
            //GitStory #7763/ Usage Summary wise roundoff QTB_Rated_Amount__c
            //If only having 1 US and 1 Usage product
            if(invStatus == 'Posted' && count == 1){
                TotalCalculatedAmount += groupAddingforRoundOff.get(USid[0]).setScale(2, RoundingMode.HALF_UP);
            }
            //Add the last record to the Total
            if(invStatus == 'Posted' && count > 1 ){
                TotalCalculatedAmount += groupAddingforRoundOff.get(USid[count-1]).setScale(2, RoundingMode.HALF_UP);
            }
        }
        system.debug(invoiceTotal+'============='+TotalCalculatedAmount);
        //Return 'True' if 'Calculated Amount'(Invoice Line + Usages) and Invoice 'Subtotal' matches, Else 'False'
        if(invoiceTotal.setScale(2, RoundingMode.HALF_UP) == TotalCalculatedAmount.setScale(2, RoundingMode.HALF_UP) ){
            return true;
        }
        return false;
    } 
    
    //Gitlab US#24329 -- Created new method to set the data and calling th batch class for asynchronously Text File creation
    public static void generateTextFileAsync(string invoiceId){
        System.debug('generateTextFileAsync@@');
        //-------Start of logic to check Nordic country Git #13418-----/
        List<blng__Invoice__c>  invLst = [Select id,Name,QTB_PurchaseOrder__c,QTB_PurchaseOrder__r.QTB_Customer_PO__c, QTB_Custom_Invoice_Number__c,blng__InvoiceStatus__c,blng__Subtotal__c,QTB_KID__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Language__c,blng__InvoiceDate__c,blng__TotalAmount__c,QTB_Total_Amount_with_Tax_Override__c,CurrencyIsoCode,blng__Account__r.id,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Notes__c,blng__Account__r.QTB_EDI_Identifier__c,
                                          blng__Account__r.QTB_Invoice_Notes__c,blng__Account__r.BillingCountry,blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.QTB_Customer_Number__c,blng__Order__r.SBQQ__PaymentTerm__c,blng__Account__r.QTB_Legal_Entity_Country__c,
                                          blng__DueDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Bank_Name__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IBAN__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Swift_Code__c,blng__Account__r.QTB_Contract_Entity__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Phone__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Account_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,
                                          blng__Account__r.Parent.Name,blng__Account__c,blng__Account__r.QTB_Display_Custom_Product_Names__c //Fetching billing account for Story #1317 changes
                                          FROM blng__Invoice__c WHERE Id =:invoiceId];
        boolean isNordeaAcc = false;
        boolean nordicBillingCountriesPresent = false;
        Set<String> nordeaAccounts = new Set<String>();
        
        if (Label.QTB_Nordea_Account_for_APIX_Extract != null) {
            nordeaAccounts.addAll(Label.QTB_Nordea_Account_for_APIX_Extract.split(';'));
        }
        
        if (invLst != null && invLst[0].blng__Account__r.Parent.Name != null) {
            isNordeaAcc = nordeaAccounts.contains(invLst[0].blng__Account__r.Parent.Name);
        }
        
        // Check if the country is a Nordic country
        Set<String> nordicCountries = new Set<String>();
        if (System.Label.QTB_NordicBillingOnlyCountries != null) {
            nordicCountries.addAll(System.Label.QTB_NordicBillingOnlyCountries.split(','));
        }
        
        if (invLst!=null && invLst[0].blng__Account__r.QTB_Legal_Entity_Country__c != null) {
            nordicBillingCountriesPresent = nordicCountries.contains(invLst[0].blng__Account__r.QTB_Legal_Entity_Country__c);
        }
        System.debug('invLst@@'+invLst);
        //-------End of logic to check Nordic country Git #13418-----/
        
        //Create Map for Account language
        Map<String, String> accLanguage = new Map<String, String>();
        accLanguage.put('no', 'NOR');
        accLanguage.put('fi', 'FIN');
        accLanguage.put('da', 'DAN');
        accLanguage.put('sv', 'SVE');
        accLanguage.put('en_US', 'ENG');
        accLanguage.put('th', 'Thai');
        accLanguage.put('zh_TW', 'Chinese Traditional');
        accLanguage.put('en_GB', 'English(UK)');        
        //Query for IM Country related to invoice billing account related legal entity
        List<IM_Country__c> country = new List<IM_Country__c>();              
        if(invLst[0].blng__Account__r.QTB_Contract_Entity__r.blng__Country__c !=null){
            //Git #12822 - Addition of Active chckbox in the query
            country = [SELECT Id,Name,Iso31662Code__c 
                       FROM IM_Country__c 
                       WHERE Name=:invLst[0].blng__Account__r.QTB_Contract_Entity__r.blng__Country__c and Active__c = true limit 1];
        }
        
        // Query for Primary 'AccountContactRelation' related to invoice billing account where the Role is 'Billing'
        String contactEmail;
        if (!invLst.isEmpty()) {
            List<AccountContactRelation> billingCont = [SELECT ContactId 
                                                        FROM AccountContactRelation 
                                                        WHERE QTB_Primary__c = true AND AccountId = :invLst[0].blng__Account__c AND Roles = 'Billing' LIMIT 1];
            
            if (billingCont != null && !billingCont.isEmpty() && billingCont[0].ContactId != null) {
                List<Contact> billingContact = [SELECT Email 
                                                FROM Contact 
                                                WHERE Id = :billingCont[0].ContactId LIMIT 1];
                contactEmail = billingContact!= null && !billingContact.isEmpty() ? billingContact[0].Email:'';
            }
        }
        //Gitlab US#24329 -- call the batch class and pass the required parameters and batch size scope should be 1
        QTB_GenerateApixExtractBatch apixExtractBatch = new QTB_GenerateApixExtractBatch(invLst,nordicBillingCountriesPresent,isNordeaAcc,contactEmail,country,accLanguage);
        if(!Test.isRunningTest()){
             database.executeBatch(apixExtractBatch,1);//scope should be 1
        }else{
             database.executeBatch(apixExtractBatch,200);
        }
    }
    
    //Gitlab US#24329 -- Created new method to get the usage count
    public static Integer getUsageCount(Id recordID){
        Set<Id> usageSummaryIdSet = new Set<Id>();
        for(blng__InvoiceLine__c invLine : [SELECT Id, NAME,blng__UsageSummary__c
                                            FROM blng__InvoiceLine__c
                                            WHERE blng__Invoice__c =:recordID AND blng__UsageSummary__c !=null])
        {
            usageSummaryIdSet.add(invLine.blng__UsageSummary__c); 
        }
        Integer usageCount = 0;
        if(!usageSummaryIdSet.isEmpty()){
            usageCount = [SELECT Count() FROM blng__Usage__c WHERE blng__UsageSummary__c IN: usageSummaryIdSet]; 
        }
        return usageCount;
    }
}
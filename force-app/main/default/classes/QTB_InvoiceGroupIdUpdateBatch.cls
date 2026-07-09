/*****************************************************************************************************
* Class: QTB_InvoiceGroupIdUpdateBatch 
* Author: Accenture
* Purpose: Batch Apex to update Invoice Group Id and Invoice Group on Order Product to Split Invoices
* Requirement: [SFCPQBLG-305] - Sprint 4
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture    5/15/2020
* Virtusa	   09/29/2023	Added constructor to pass set of account Id from trigger where 'Split Invoice Flag' field 
							value is changed
* Virtusa	   01/04/2024	Gitlab #20382 Assigning splitInvocieGroupId value based on Account splitInvoiceFlag for Ad-Hoc orderProduct
*******************************************************************************************************/
global class QTB_InvoiceGroupIdUpdateBatch implements Database.Batchable<SObject>{
    
    public static final string GROUPIDBATCH =QTB_InvoiceGroupIdUpdateBatch.class.getName();
    public static final string INV_GROUPID ='Invoice Group ID';
    public static final string STORAGE = QTB_Constants.STORAGE_CONSTANT;
    public static final string NONSTORAGE = QTB_Constants.NONSTORAGE_CONSTANT;
    public static boolean throwExplicitException = false;    
    public string query;
    public set<Id>AccountIdSet = new Set<Id>();
    
    /*********************************************************************************************************
Method Name: constructor
Parameters: Set<Id>
Return Type: void
Description: constructor of QTB_InvoiceGroupIdUpdateBatch
**********************************************************************************************************/
    global QTB_InvoiceGroupIdUpdateBatch(set<Id>AccountIds){
        AccountIdSet.addAll(AccountIds);
        //#31228 Added With Holding Applicable from Account level, Legal ENtity Country, Tax Category field on the query
        query = 'SELECT Id,blng__InvoiceGroupId__c,blng__InvoiceGrouping__c,OrderId,'+
            'Order.AccountId,Order.Account.QTB_Split_Invoice_Flag__c,SBQQ__Activated__c ,'+
            'Product2Id,Product2.QTB_Storage_Product__c,order.QTB_OrderCategory__c,Order.OrderNumber,order.Account.QTB_Withholding_Applicable__c,order.QTB_Legal_Entity_Country__c,QTB_Tax_Category__c from OrderItem '+
            'where Order.AccountId != null and SBQQ__Activated__c = True and order.AccountId IN :AccountIdSet';
        
    }
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
Description: Query required OrderProduct records
**********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext, List<OrderItem>
Return Type: void
Description: Update Invoice Group and Invoice Group Id based on Split Invoice Flag on Account and Products 
Price Schedule category
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<OrderItem> scope){
        String errorMessage='';
        //#31228 Added below Map for turkey Enhancement
        Map<Id,String> prod2IDTaxCategoryMap = new Map<Id,String>();
        try{
            if(throwExplicitException){
                throw new NullPointerException();
            }
            if(!scope.isEmpty()){
                List<OrderItem> listToUpdate=new List<OrderItem>();
                for(OrderItem ordProduct : scope){
                    //#31228 Added If loop for Existing logic to work
                    if(!ordProduct.order.Account.QTB_Withholding_Applicable__c){
                        if(ordProduct.Order.Account.QTB_Split_Invoice_Flag__c==true){ 
                            //Update Invoice Group and Invoice Group Id if split invoice flag is true
                            if(ordProduct.Product2Id!=null){
                                // Gitlab #20382 Assigning splitInvocieGroupId value based on Account splitInvoiceFlag for Ad-Hoc orderProduct
                                if(ordProduct.order.QTB_OrderCategory__c == 'Ad-Hoc'){
                                    if(ordProduct.Product2.QTB_Storage_Product__c==true){
                                        if(ordProduct.blng__InvoiceGroupId__c != ordProduct.Order.OrderNumber + '-' +STORAGE){
                                            
                                            ordProduct.blng__InvoiceGrouping__c=INV_GROUPID;
                                            ordProduct.blng__InvoiceGroupId__c=ordProduct.Order.OrderNumber + '-' + STORAGE;
                                            listToUpdate.add(ordProduct);
                                            errorMessage=ordProduct.Id+';;';
                                        }
                                    }
                                    else if(ordProduct.blng__InvoiceGroupId__c != ordProduct.Order.OrderNumber + '-' + NONSTORAGE){
                                        ordProduct.blng__InvoiceGrouping__c = INV_GROUPID;
                                        ordProduct.blng__InvoiceGroupId__c = ordProduct.Order.OrderNumber + '-' + NONSTORAGE;
                                        listToUpdate.add(ordProduct);
                                        errorMessage=ordProduct.Id+';;';
                                    } 
                                }
                                else{
                                    if(ordProduct.Product2.QTB_Storage_Product__c==true){
                                        if(ordProduct.blng__InvoiceGroupId__c!=STORAGE){
                                            ordProduct.blng__InvoiceGrouping__c=INV_GROUPID;
                                            ordProduct.blng__InvoiceGroupId__c=STORAGE;
                                            listToUpdate.add(ordProduct);
                                            errorMessage=ordProduct.Id+';;';
                                        }
                                    }
                                    else if(ordProduct.blng__InvoiceGroupId__c!=NONSTORAGE){
                                        ordProduct.blng__InvoiceGrouping__c=INV_GROUPID;
                                        ordProduct.blng__InvoiceGroupId__c=NONSTORAGE;
                                        listToUpdate.add(ordProduct);
                                        errorMessage=ordProduct.Id+';;';
                                    }
                                }
                            }
                        }
                        else{ 
                            // Gitlab #20382 for ad-hoc order update invoice group id to order number
                            if(ordProduct.order.QTB_OrderCategory__c == 'Ad-Hoc'){
                                ordProduct.blng__InvoiceGroupId__c=ordProduct.order.orderNumber;
                                listToUpdate.add(ordProduct);
                            }
                        }
                    }
                    //#31228 Added else blok for updating OrderItems Invoice group Id and Grouping based upon Account With Holding flag
                    //For Example : Account level With Holding true and On price Book Entry tax category value = 2/5 WHT then 
                    //OrderItem.blng__InvoiceGrouping__c = 'Invoice Group ID'
                    //OrderItem.blng__InvoiceGroupId__c = 2/5 WHT
                    //And if Split Invoice flag = True then
                    //OrderItem.blng__InvoiceGrouping__c = 'Invoice Group ID'
                    //OrderItem.blng__InvoiceGroupId__c = 2/5 WHT Storage or 2/5 WHT Service
                    else{
                        system.debug('Inside Else block for InvoicegroupUpdate abcth');
                        if(ordProduct.order.QTB_OrderCategory__c == 'Evergreen' && ordProduct.QTB_Tax_Category__c != NUll && ordProduct.Product2Id != Null
                           && ordProduct.order.QTB_Legal_Entity_Country__c == 'Turkey'&& ordProduct.QTB_Tax_Category__c.contains('/')){
                               prod2IDTaxCategoryMap.put(ordProduct.Product2Id,ordProduct.QTB_Tax_Category__c);
                               ordProduct.blng__InvoiceGrouping__c = INV_GROUPID;
                               
                               if(ordProduct.Order.Account.QTB_Split_Invoice_Flag__c){
                                   if(prod2IDTaxCategoryMap != Null && prod2IDTaxCategoryMap.containsKey(ordProduct.Product2Id)){
                                       if(ordProduct.Product2.QTB_Storage_Product__c==true){
                                           ordProduct.blng__InvoiceGroupId__c= prod2IDTaxCategoryMap.get(ordProduct.Product2Id) +  ' STORAGE';
                                           system.debug('ordProduct.blng__InvoiceGroupId__c split Invoice Flag true storage:'+ordProduct.blng__InvoiceGroupId__c);
                                           listToUpdate.add(ordProduct);
                                           errorMessage=ordProduct.Id+';;'; 
                                           
                                       }
                                       else {
                                           //Add service check for future purpose
                                           ordProduct.blng__InvoiceGroupId__c = prod2IDTaxCategoryMap.get(ordProduct.Product2Id) + ' SERVICE';
                                           system.debug('ordProduct.blng__InvoiceGroupId__c split Invoice Flag true Service:'+ordProduct.blng__InvoiceGroupId__c);
                                           listToUpdate.add(ordProduct);
                                           errorMessage=ordProduct.Id+';;'; 
                                       }
                                       
                                   }
                               }
                               else {
                                   if(prod2IDTaxCategoryMap!= Null && prod2IDTaxCategoryMap.containskey(ordProduct.Product2Id)){
                                       ordProduct.blng__InvoiceGroupId__c= prod2IDTaxCategoryMap.get(ordProduct.Product2Id);
                                       system.debug('ordProduct.blng__InvoiceGroupId__c split Invoice Flag false:'+ordProduct.blng__InvoiceGroupId__c);
                                       listToUpdate.add(ordProduct);
                                       errorMessage=ordProduct.Id+';;';       
                                   }
                                   
                               }
                               
                           }
                    }
                    //#31228 Added below this logic and added both Split and With Holding are false and Invoice Group Id having some value then updating to Null Values
                    if(String.isNotBlank(ordProduct.blng__InvoiceGroupId__c) && ordProduct.Order.Account.QTB_Split_Invoice_Flag__c == false 
                      && ordProduct.order.Account.QTB_Withholding_Applicable__c == false){
                        system.debug('Inside null check of With Hold');
                        ordProduct.blng__InvoiceGrouping__c=null;
                        ordProduct.blng__InvoiceGroupId__c=null;
                        listToUpdate.add(ordProduct);
                        errorMessage=ordProduct.Id+';;';
                    }
                }
                if(!listToUpdate.isEmpty() && listToUpdate<> null && listToUpdate.size()>0 ){
                    Database.SaveResult[] results = Database.update(listToUpdate,true);
                }
                //#31228 Added as part of new Enhancement for clearing the list
                listToUpdate.clear();
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            errorMessage = e.getMessage()+';;'+errorMessage;
            if(errormessage.length()>100000){ errormessage = errormessage.substring(0,100000);}
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),errorMessage,e.getTypeName(),GROUPIDBATCH);
        }
    }
    
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: void
Description: Method to execute any logic after batch completion
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC){
        //no action needed after batch completion
    }
}
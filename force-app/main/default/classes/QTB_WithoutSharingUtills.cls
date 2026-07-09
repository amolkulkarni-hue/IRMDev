/*****************************************************************************************************
* Class: QTB_WithoutSharingUtills
* Test class: QTB_WithoutSharingUtillsTest
* Author: Virtusa
* Purpose: This is a class WHERE created with WithoutSharing keyword to avoid the INSUFFICIENT_ACCESS_OR_READONLY exception during invoice generation.
This class called in QTB_InvoiceHelper class.
* Requirement: //GITLAB:28527 EPIC:2795 
* Change History: 01/23/2025
* Developer Name : Ayeisha Kathon
* Change History: 02/18/2025   #29101 Changed return type to List<QTB_PurchaseOrder__c> from void
*******************************************************************************************************/
public without sharing class QTB_WithoutSharingUtills {
    private static final String CLASSNAME = QTB_WithoutSharingUtills.class.getName();
    public static List<QTB_PurchaseOrder__c> calculatingPOBalanceAmountWithoutSharing(List<blng__Invoice__c> newItems, Map<ID,blng__Invoice__c> oldMap){
        try{
            if(newItems.isEmpty() || oldMap.IsEmpty()){ QTB_RecursiveHandlerCheck.calculatingPOBalanceInv = false; return null;} // 29101 early exit

            Set<ID> newPOIdSet =new Set<ID>();
            Map<ID,blng__Invoice__c> invMap;
            List<QTB_PurchaseOrder__c> purchaseOrderToUpdateList = new List<QTB_PurchaseOrder__c>(); // 29101 added
            Map<String, Decimal> billingAcntInvAmountMap = new Map<String, Decimal>();
            Decimal newPoBalanceAmount;
            Set<ID> poIdSet = new Set<ID>();
            Decimal amt = 0.0;

            //calling this method when invoice get posted , invoice have purchase order  and invoice blng__Credits__c field is 0 because when we create credit note this method calling twice.
            for(blng__Invoice__c invoice : newItems){
            
                if(newPOIdSet!= null && ((invoice.QTB_PurchaseOrder__c !=null && invoice.QTB_ReBill_Status__c == null && invoice.blng__InvoiceStatus__c!=null //#29101 added NullCheck
                    && invoice.blng__InvoiceStatus__c == 'Posted' && invoice?.blng__Credits__c == 0 && oldMap.get(invoice.ID)?.blng__InvoiceStatus__c != 'Posted')
                //RebillInvoice Calculation
                // merged code as part of 29101
                ||( invoice.blng__InvoiceStatus__c!=null && oldMap.get(invoice.ID)?.blng__InvoiceStatus__c == 'Posted' && invoice.blng__InvoiceStatus__c == 'Posted'
                    &&(invoice.QTB_Invoice_Type__c == 'ReBill'|| invoice.QTB_Invoice_Type__c == 'Legacy Invoice')))){
                
                    newPOIdSet.add(invoice?.QTB_PurchaseOrder__c);
                }
            }            
            if(newPOIdSet== null || newPOIdSet.isEmpty()){QTB_RecursiveHandlerCheck.calculatingPOBalanceInv = false; return null;} // 29101 early exit
            
            invMap = new Map<ID,blng__Invoice__c>([SELECT QTB_PurchaseOrder__c,QTB_PurchaseOrder__r.QTB_Amount__c,QTB_PurchaseOrder__r.QTB_Date_Of_100_Utilization__c, QTB_PurchaseOrder__r.QTB_End_Date__c,QTB_PurchaseOrder__r.QTB_PO_Balance_Amount__c, QTB_PurchaseOrder__r.QTB_Start_Date__c,QTB_PurchaseOrder__r.QTB_Status__c,QTB_Total_Amount_with_Tax_Override__c,QTB_Parent_Invoice__c 
                                                    FROM blng__Invoice__c 
                                                    WHERE QTB_PurchaseOrder__c IN:newPOIdSet AND QTB_PurchaseOrder__r.QTB_Status__c ='Active']) ; //Gitlab US#29100 DO NOT ADD WITH SECURITY_ENFORCED 
            if(invMap== null ||invMap.isEmpty()) {QTB_RecursiveHandlerCheck.calculatingPOBalanceInv = false; return null;} // 29101 early exit
           
            for (blng__Invoice__c inv: invMap.values()){
            
                String key = (inv?.QTB_PurchaseOrder__c)+ '-' + (inv.ID); 
                billingAcntInvAmountMap.put(key, inv.QTB_Total_Amount_with_Tax_Override__c);//#2910 note: key != null bec key has Hyphen
            }
            
            for(blng__Invoice__c invoice :newItems){
            
                //Invoking PO Number in Invoice #21525 and calculating the PO Balance once Purchase order linked with Invoice. 
                String key = invoice?.QTB_PurchaseOrder__c+'-'+ invoice.ID;
                if (poIdSet!=null &&billingAcntInvAmountMap!=null && invoice.QTB_PurchaseOrder__c != null&& billingAcntInvAmountMap.containskey(key)){
                
                    newPoBalanceAmount = (!poIdSet.contains(invoice?.QTB_PurchaseOrder__c))
                                        ? (invMap.get(invoice.ID)?.QTB_PurchaseOrder__r?.QTB_PO_Balance_Amount__c) : amt; //The amt is initialized with 0

                    poIdSet.add(invoice?.QTB_PurchaseOrder__c);
                    amt = newPoBalanceAmount  - (billingAcntInvAmountMap.get(key)); //Logic to subtract the Invoice Amount from the PO Amount to calculate the PO Balance
                    
                    purchaseOrderToUpdateList.add(new QTB_PurchaseOrder__c(ID = invoice?.QTB_PurchaseOrder__c, QTB_PO_Balance_Amount__c = amt, 
                                                                            QTB_Date_Of_100_Utilization__c = System.today())); //29101 added to the list purchaseOrderToUpdateList directly
                }    
            }
            if (purchaseOrderToUpdateList != null && !purchaseOrderToUpdateList.isEmpty()){ //# 29101 
            
                QTB_RecursiveHandlerCheck.calculatingPOBalanceInv = false;//As its calling multiple times
                return purchaseOrderToUpdateList; //#29101 return purchaseOrderToUpdateList to InvoiceHelper Class
            }else{
                return null;
            }         
        }catch(Exception e){ 
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }

    //Added the method by 29101 to update single PO MAP in withoutsharing mode
    public static void updatingPOBalanceAmountWithoutSharing(Map<ID,QTB_PurchaseOrder__c> poMap){
        try{
            if(poMap == null || poMap.isEmpty()){ return;} 

            Database.saveresult[] purchaseOrderToUpdateResult = Database.update(poMap.values(), true);
        }catch(Exception e){ 
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }
}
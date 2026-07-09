public class QTB_ReadyForIntegration_auraController {
    @AuraEnabled
    public static String getCrdtId(ID CrdtId) {
        boolean isVertexTaxCall = false;
        boolean manualCreditNote = false;
        QTB_Tax_Integration_Setting__mdt countryValForVertex = QTB_Tax_Integration_Setting__mdt.getInstance('Vertex_Integration');
        List<blng__CreditNoteLine__c> creditNoteLineList = new list<blng__CreditNoteLine__c>();
        Set<blng__CreditNote__c> creditNoteSet = new set<blng__CreditNote__c>();
        List<blng__CreditNote__c> creditNoteList = new list<blng__CreditNote__c>();
        Set<Id> cNIdSet = new Set<Id>();
        Set<Id> cNLIdSet = new Set<Id>();
        Boolean isRecordProcessed = false;
        List<blng__CreditNoteLine__c> crdtNoteLineList = new List<blng__CreditNoteLine__c>(); 
        crdtNoteLineList = [SELECT id,blng__Status__c,blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__CreditNote__r.blng__Status__c,blng__CreditNote__r.QTB_Ready_for_Integration__c,QTB_InvoiceLine__c,QTB_Invoice__r.blng__Subtotal__c,blng__CreditNote__r.blng__Subtotal__c,QTB_InvoiceLine__r.blng__Invoice__c,QTB_InvoiceLine__r.blng__Invoice__r.blng__Subtotal__c FROM blng__CreditNoteLine__c WHERE blng__CreditNote__c=:CrdtId];
        for(blng__CreditNoteLine__c crdNLineObj : crdtNoteLineList){
            if(crdNLineObj.blng__Status__c =='Draft'){
                crdNLineObj.blng__Status__c='Posted';
                creditNoteLineList.add(crdNLineObj);
            }      
            if(crdNLineObj.blng__CreditNote__r.blng__Status__c =='Error'){
                blng__CreditNote__c creditNoteNew = new blng__CreditNote__c();
                creditNoteNew.blng__Status__c ='Posted';
                creditNoteNew.Id = crdNLineObj.blng__CreditNote__c;
                creditNoteList.add(creditNoteNew);
            }
            if(crdNLineObj.blng__CreditNote__r.QTB_Ready_for_Integration__c){
                isRecordProcessed = true;
            }
            //Adding Null check as a part of #Git Issues/29824
            //during debugging here also null check should be kept
            if(crdNLineObj.blng__CreditNote__c !=null){
                cNIdSet.add(crdNLineObj.blng__CreditNote__c);               
            }
            cNLIdSet.add(crdNLineObj.Id);               
            
        }
        //Adding Null check as a part of #Git Issues/29824
        //creating instance of taxDetailList before query record and adding null check
        List<QTB_Tax_Detail__c> taxDetailList = new List<QTB_Tax_Detail__c>();
        if(!cNIdSet.isEmpty() || !cNLIdSet.isEmpty() ){
           taxDetailList= [SELECT Id,QTB_Credit_Note__c,QTB_Credit_Note_Line__c FROM QTB_Tax_Detail__c WHERE QTB_Credit_Note__c IN : cNIdSet OR QTB_Credit_Note_Line__c IN : cNLIdSet];
           }
       
        if(taxDetailList != null && !taxDetailList.isEmpty() && creditNoteList != null && !creditNoteList.isEmpty()){
            creditNoteList[0].IsTaxDetailPresent__c = true;
        }
        //Checking for manual crdit note 
        if(crdtNoteLineList[0].blng__CreditNote__r.blng__Subtotal__c != null && crdtNoteLineList[0].QTB_InvoiceLine__c != null  && 
           crdtNoteLineList[0].QTB_InvoiceLine__r.blng__Invoice__c != null && crdtNoteLineList[0].QTB_InvoiceLine__r.blng__Invoice__r.blng__Subtotal__c != null
           &&  crdtNoteLineList[0].QTB_InvoiceLine__r.blng__Invoice__r.blng__Subtotal__c != crdtNoteLineList[0].blng__CreditNote__r.blng__Subtotal__c){
           manualCreditNote=true;
        }
        //Checking condition for partial manual credit note for usa ,canada for this type of credit note we need to do vertex callout 
        if(countryValForVertex != null && countryValForVertex.QTB_End_System__c == 'Vertex' && crdtNoteLineList[0].blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c != null 
               && countryValForVertex.QTB_Country__c.containsIgnoreCase(crdtNoteLineList[0].blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c))
        {
            isVertexTaxCall = true;
        }
        
        // Git issues/33351 we are creating tax details based on conditions below for vertex country as other are tax details generate functionality already in place
        if(taxDetailList.isEmpty() && !crdtNoteLineList.isEmpty() && !cNIdSet.isEmpty() && !creditNoteList.isEmpty() && isVertexTaxCall){
            if(manualCreditNote)
            {
                //For partial manual credit note US, Canada we need to call vertax to generate tax details
                Database.executeBatch(new QTB_vertexTaxCalloutBatch(null,null,cNIdSet,null,null,false),1);         
            }
            else{
                QTB_CreditOnlyUtil.createTaxDetails(crdtNoteLineList);    
            }
        }              
    
        SBQQ.TriggerControl.disable(); 
        if(!creditNoteList.isEmpty()){
            Map<Id,blng__CreditNote__c> creditNoteToUpdateMap = new Map<Id,blng__CreditNote__c>();
            creditNoteToUpdateMap.put(creditNoteList[0].Id,creditNoteList[0]);
            update creditNoteToUpdateMap.values();
        }
        if(!creditNoteLineList.isEmpty()) {
            update creditNoteLineList;                                 
        }   
        
        SBQQ.TriggerControl.enable();
    	
        String message = '';
        if(!isRecordProcessed){
            message = 'Sucess';
        }else{
            message ='Error';
        }
        return message;
    }
}
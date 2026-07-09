/***************************************************************************************************
* Trigger for ContentVersion Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : IRM/Virtusa
* @ModifiedBy    : IRM/Virtusa
* @Created       : 12/02/2022
* @Modified      : 12/02/2022
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_RestrictUseronAttachemnetInsert on ContentVersion (before insert, before update) {
    
    if(Trigger.isInsert)
    { 
        QTB_AttachmentsEditDeleteController.processInsert(trigger.new);
    }
    
  /*if(Trigger.isUpdate)
    { 
       QTB_AttachmentsEditDeleteController.process(trigger.new); 
    }*/
    
}
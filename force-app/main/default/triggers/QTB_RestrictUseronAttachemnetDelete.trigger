/***************************************************************************************************
* Trigger for ContentDocument Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : IRM/Virtusa
* @ModifiedBy    : IRM/Virtusa
* @Created       : 12/02/2022
* @Modified      : 12/02/2022
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* Developer    Date-MM/DD/YYY  Description
* -------------------------------------------------------------------------------------------
* Simranjit Kaur     05/14/2025      Gitlab US #30945 Bypassing updation for the case/opportunity getting created by Iron Mountain Migration User 
									 as it was giving 101 SOQL error while creating email to case for multiple attachments.
****************************************************************************************************/
trigger QTB_RestrictUseronAttachemnetDelete on ContentDocument (before update, before delete) {
   
    if(Trigger.isUpdate)
    {
       //Bypassing updation for the case/opportunity getting created by Iron Mountain Migration User
       if(UserInfo.getUserId() != System.Label.Iron_Mountain_Migration_User_Id){
     		QTB_AttachmentsEditDeleteController.processDelete(trigger.new);  
        }
    }
    if(Trigger.isDelete)
    {
       QTB_AttachmentsEditDeleteController.processDelete(trigger.old);  
    }

}
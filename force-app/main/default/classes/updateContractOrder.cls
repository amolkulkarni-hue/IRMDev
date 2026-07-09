/**
* Created By: Vinutha Iyengar
     *          -- This class is used to change the Order of attachments
     *          -- Case # 06462026
**/
Global class updateContractOrder{

 public static string updateContractFileOrder(string signatureId)        
    {
        system.debug('signatureId=='+signatureId);
        List<attachment> sigAttach = [select id from attachment where ParentId = :signatureId and name like '%contract%'];
        
        if(sigAttach.size()>0)
        {
            Attachment contractDoc = new attachment();
            contractDoc.id=sigAttach[0].id;
            contractDoc.Description = 'Contract document';  
            update contractDoc;
        }
        
        return signatureId;
    }
}
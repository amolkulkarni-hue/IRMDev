/**
* Created By: Revathy Saminathan
*          -- This class is used when "Send for Signature" hyperlink is clicked on Signature Information
*          -- Case # 11211220 

Modified by  : Revathy Saminathan  
Modified date: Nov 19, 2019
Description  : Added the functionality for classic to lightning compatability implementation 
*/
public class IME_Send_for_Signature {
    
    Boolean CustomerSignFirst;	
    public IME_Signature_Information__c sign  {get;set;}
    integer custSigningOrder = 0;
    integer intSigningOrder = 0;
    integer ccSigingOrder = 0;
    string customerSigners='';
    string internalSigner;
    string ccSigner;
    string CCRM;
    string CCTM;
    string CRL;
    string OCO;
    string CES;
    string CEM;
    string RES;
    string LA;
    Boolean debug = false; 
    Boolean prod = false; 
    integer totalAttachments = 0; 
    private ApexPages.StandardController standardController;
    public Id signId; 
    public Boolean alertmsg {get;set;}
    String newLocation1; 
    
    public Boolean isSandbox {
        get {
            if (isSandbox == null) {
                isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return isSandbox;
        }
        set;
    }
    public IME_Send_for_Signature(ApexPages.StandardController controller)
    {
        System.debug('Send for signature class calling>>>>>>>>>>');
        this.standardController = controller;
        if(ApexPages.currentPage().getParameters().get('id') != Null)
        {
            signId = ApexPages.currentPage().getParameters().get('id');    
            system.debug('signId=='+signId); 
        } 
    }
    
    public PageReference IME_Send_for_Signature() 
    {    
       System.debug('Send For Signature Method Calling>>>>>>' +signId);
        if(signId != Null)
        {
             sign = [select IME_Contract__c,Id,Carbon_Copy_Signer__c, IME_Email_Message__c, IME_Email_Subject__c, IME_ExpireVoid__c, IME_ExpireNDays__c, IME_Internal_Signatories__c, sent_for_signature__c, IME_MFP_Clause__c, IME_Non_Standard_Accounting_Clause__c, IME_EnableReminders__c, IME_ReminderRepeatDays__c, IME_ReminderDays__c, IME_Signing_Order__c, Standard_Contract__c, IME_ExpireWarnNDays__c from IME_Signature_Information__c where id = :signId];
             System.debug('Signature Information List Value>>>>'+sign);
        }
        
        /*case#07945998 - Based on IME_Signing_Order__c value, the order of signing will change on the contract. If IM signs first - Order of signing - internalSigner,customerSigners,ccSigner        Client signs first - Order of signing - customerSigners,internalSigner,ccSigner*/
        if(sign.IME_Signing_Order__c == 'IM signs first')
        { 
            CustomerSignFirst = false;  
            intSigningOrder++;
            custSigningOrder++;
        }
        else if(sign.IME_Signing_Order__c == 'Client signs first')
        { 
            CustomerSignFirst = true; 
        }        
        
        IME_Signature_Information__c contractDetails = [select IME_Contract__r.Contract_Type__c, IME_Contract__r.Standard_Contract__c from IME_Signature_Information__c where IME_Contract__c =:sign.IME_Contract__c]; 
        
        
        // Construct Customer Signer CRL 
        For (IME_Signatory_Contact__c signCont :[SELECT IME_Contact__r.Name, IME_Contact__r.Email, IME_Routing_Order__c FROM IME_Signatory_Contact__c WHERE IME_DocuSign_Contract_Envelope__c = :sign.Id ORDER BY IME_Routing_Order__c ASC])
        {
            custSigningOrder++; 
            customerSigners += 'Email~'+signCont.IME_Contact__r.Email+';LastName~'+signCont.IME_Contact__r.Name+';Role~Signer '+signCont.IME_Routing_Order__c+';RoutingOrder~'+signCont.IME_Routing_Order__c+',';
        }  
        
        /*Case # 06462026 - Below code is used to change the Order of attachments and for Case # 07945998 - Added condition like below oder of attachment code will only be applicable for standard contract */        
     /*   if(contractDetails.IME_Contract__r.Standard_Contract__c == true)
        {             
            updateContractOrder.updateContractFileOrder(sign.Id); 
        } */
        
        
        // Construct Internal Signer CRL 
        if(CustomerSignFirst)intSigningOrder=custSigningOrder+1; 
        if(CustomerSignFirst) 
        { 
            ccSigingOrder=intSigningOrder+1; 
        } 
        else 
        { 
            ccSigingOrder=custSigningOrder+1; 
        }         
        
          
            internalSigner = 'SigningGroup~'+sign.IME_Internal_Signatories__c+';Role~Internal Signer;RoutingOrder~'+intSigningOrder;  
            ccSigner= ',SigningGroup~'+sign.Carbon_Copy_Signer__c+';Role~CC Signer;RoutingOrder~'+ccSigingOrder; 
             
        
        // Custom Contact Role Map (default config role) 
        CCRM = 'Signer 1~Signer 5;Signer 2~Signer 6;Signer 3~Signer 7;Signer 4~Signer 8;Financial Controller~Financial Controller;Internal Signer~Internal Signer;CC Signer~CC Signer'; 
        
        // Custom Contact Type Map (default Signer) 
        CCTM = 'CC Signer~Carbon Copy'; 
        
        if(sign.IME_Signing_Order__c == 'IM signs first'){ 
            CRL = internalSigner +','+ customerSigners + ccSigner; 
        }else if(sign.IME_Signing_Order__c == 'Client signs first'){ 
            CRL = customerSigners + internalSigner +','+ ccSigner; 
        } 
        
        //** Changed by Mark Jennison 15/10 from 'false' to 'true' to avoid DS screen in testing. This value should be 'false' in Production **/ 
        if(isSandbox) 
        { 
            OCO = 'Tag'; //'Tag' to be used for non-Production 
        } 
        else 
        { 
            if(contractDetails.IME_Contract__r.Contract_Type__c == 'IM Non Standard' || contractDetails.IME_Contract__r.Contract_Type__c == 'Customer')
            { 
                OCO = 'Tag'; //'Tag' used for Non-standard contract
            }
            else
            { 
                OCO = 'Send'; 
            } 
        }        
        
        LA = '';
        // Custom Email Message (default in config) 
        //CEM = '{!URLENCODE(JSENCODE(IME_Signature_Information__c.IME_Email_Message__c))}'.replace(/%0D%0A/g, '\\n'); 
        CEM = sign.IME_Email_Message__c;
        
        // Custom Email Subject (default in config) 
        CES = sign.IME_Email_Subject__c; 
        
        // Reminder and Expiration Settings 
        RES = sign.IME_EnableReminders__c+','+sign.IME_ReminderDays__c+','+sign.IME_ReminderRepeatDays__c+','+sign.IME_ExpireVoid__c+','+sign.IME_ExpireNDays__c+','+sign.IME_ExpireWarnNDays__c; 
        
        
        String newLocation = '/apex/dsfs__DocuSign_CreateEnvelope?DSEID=0&SourceID='+sign.Id+'&CCRM='+CCRM+'&CCTM='+CCTM+'&CRL='+CRL+'&OCO='+OCO+'&LA='+LA+'&CEM='+CEM+'&CES='+CES+'&RES='+RES;   
   
        // validate the form contents
        if(validateCriteria())
        {
        if(confirmSending())
        {
             alertmsg = false;
            // if debug then show destination else go
            //********* Page Callout (Do not modify) *********//   
            if(debug)
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,newLocation);
                ApexPages.addMessage(myMsg);
            }
            else
            {
                //**Note change made by Vinutha Iyengar Nov/17, case#06462026 to check for attachment count if standard contract **/
                if(totalAttachments !=2 && sign.Standard_Contract__c)
                {
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Schedule A is not attached. Contract could not be sent.');
                    ApexPages.addMessage(myMsg);
                }
                else
                { 
                    CRL=CRL.replace(',,', ',');
                    newLocation1 = 'apex/dsfs__DocuSign_CreateEnvelope?DSEID=0&SourceID='+sign.id+'&CCRM='+CCRM+'&CCTM='+CCTM+'&CRL='+CRL+'&OCO='+OCO+'&CEM='+CEM+'&CES='+CES+'&RES='+RES;
                    System.debug('Location>>>'+newLocation1);
                    PageReference pageRef = new PageReference('/'+newLocation1);
                    pageRef.setRedirect(true);
                    return pageRef;   
                }
            }
        }
        }
        
       return null;        
    }
    public PageReference cancel()
    { 
        PageReference pageRef = new PageReference('/'+signId);
        pageRef.setRedirect(true);
        return pageRef;    
    } 
    
    public boolean confirmAlert()
    {
        alertmsg = true;
        Boolean msg = true;
        return msg;
    }
    public boolean validateCriteria()
    {
        Boolean isValid = false;
        List<String> errorList = new List<String>();
        
        // validate attachments and recipients
        if (!isValidAttachment()) 
        { 
            errorList.add('- The envelope is missing attachments.\n'); 
        }
        if (!isValidRecipient()) 
        { 
            errorList.add('- No recipients have been specified for the envelope.\n');
        } 
        
        if (errorList.size() == 0)
        {
            isValid = true;
        }
        
        if (!isValid)
        {
            String errorMessage = 'Before sending, please correct the following errors:\n' + errorList; 
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage);
            ApexPages.addMessage(myMsg);
        }
        
        return isValid; 
    }
     
   
    public Boolean isValidAttachment()
    {
        Boolean isValid = false;
        String anyAttachment = 'Not Found';
       // List<Attachment> record = new List<Attachment>();
       List<sObject> record = new List<sObject>();
        try
        {
            record.addAll([Select Id from Attachment where ParentId =: sign.Id Limit 5]);
            record.addAll([SELECT ContentDocumentId,ContentDocument.Title,ContentDocument.LastModifiedDate,
                                        ContentDocument.CreatedBy.Name FROM ContentDocumentLink WHERE LinkedEntityId = :sign.Id]);
            totalAttachments = record.size();
            System.debug('Attachment Record List>>>>'+record);
            if(record.size()>0 || Test.isRunningTest()){
                anyAttachment = 'Records Found';
                isValid = true;
            }
        }
        catch (DMLException ex)
        {
            
            if(debug)
            {
                System.debug('Exception Name>>>>>>>>>'+ex.getMessage());
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Exception Message'+ex.getMessage());
                ApexPages.addMessage(myMsg);
            }
        }
        finally
        {
            if(debug)
            {
                 System.debug('Finally - isValidAttachment: anyAttachment = ' + anyAttachment);
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Finally - isValidAttachment: anyAttachment ='+anyAttachment);
                ApexPages.addMessage(myMsg);
            }
        }
        return isValid;
        
    }
    public Boolean isValidRecipient()
    {
        Boolean isValid = false;
        String anyRecipients = 'Not Found';
        List<IME_Signatory_Contact__c> signCon = new List<IME_Signatory_Contact__c>();
        try
        {
            signCon = [Select Id from IME_Signatory_Contact__c Where IME_DocuSign_Contract_Envelope__c =:sign.Id Limit 1];
            if(signCon.size()>0)
            {
                anyRecipients = 'Records Found';
                isValid = true;
            }
        }
        catch(DMLException ex)
        {
          if(debug)
            {
                System.debug('Exception Name>>>>>>>>>'+ex.getMessage());
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Exception Message'+ex.getMessage());
                ApexPages.addMessage(myMsg);
            }   
        }
        finally
        {
          if(debug)
            {
                System.debug('Finally - isValidAttachment: anyRecipients = ' + anyRecipients);
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Finally - isValidAttachment: anyRecipients ='+anyRecipients);
                ApexPages.addMessage(myMsg);
            }   
        }
     
        return isValid;
    }
    
    public Boolean isValidReminder()
    {
        Boolean isValid = false;
        isValid = sign.IME_EnableReminders__c;
        return isValid;
    }
    
    public Boolean confirmSending()
    {
        Boolean oppUp = sign.sent_for_signature__c;
        Boolean showAlert = false ;
        if(oppUp == true)
        {
            showAlert = false;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The contract has already been fully executed, this cannot be sent again for signature.');
            ApexPages.addMessage(myMsg);
        }
        else
        {  
           showAlert = confirmAlert(); 
        }  
         return showAlert;
    }   
  /*  public PageReference redirect()
    {        
        string newLocation = '/apex/dsfs__DocuSign_CreateEnvelope?DSEID=0&SourceID='+sign.id+'&CCRM='+CCRM+'&CCTM='+CCTM+'&CRL='+CRL+'&OCO='+OCO+'&CEM='+CEM+'&CES='+CES+'&RES='+RES;
        PageReference pageRef = new PageReference(newLocation);
        return pageRef;        
    }*/
}
/**
* Created By: Keerthi Senthilnathan on 14-Sep-2017
*          -- This class is used when "Create Standard Contract" Button is clicked on opportunity
*          -- Case # 06462026

//
Modified by  : Masthan vali Patnam
Modified date: April 06, 2018
Description  : Modified this class for case #07704279.

//
Modified by  : Amarendra Nallamalli
Modified date: July 16, 2018
Description  : Modified this class for case #07945998.

//
Modified by  : Vinutha Iyengar  
Modified date: Nov 21, 2018
Description  : Added field Account_Registration_Number__c to copy from opporunity #05119686.

//
Modified By  : Revathy Saminathan
Modified Date: Nov19, 2019
Description  : Added the Custom Metadata Type for have the dynamic value to create the contract and converting 
javascript to lightning compatability implementation

//
Modified By  : Revathy Saminathan
Modified Date: Nov25, 2019
Description  : Added the new opportunity edit functionality on new contract creation page. 
*/

Global class createNewContract{
    
    private ApexPages.StandardController standardController;
    public String ContractStatus='';
    public Boolean StandardContract; 
    public Boolean createContract = false;
    public Boolean cancelContract = false; 
    public Boolean javaScriptfn { get; set;}
    public Boolean renderfn { get; set;}
    public Opportunity oppty { get; set;}
    public Boolean alert{ get; set;}
    //Added the Custom metadata type to have dynamic value
    public List<IME_Contract_Conga_URLs__mdt> contractCongaList { get;set; }
    public String conga_params {get; set;} 
    public String product {get;set;}
    public Boolean editshow {get;set;}
    
    public createNewContract(ApexPages.StandardController controller)
    {
        init(); 
        this.standardController = controller;
    }
    public void init()
    {
        if( System.currentPageReference().getParameters() != null && 
           System.currentPageReference().getParameters().get('id') != null )   
        {
            Id recordId = ApexPages.currentPage().getParameters().get('id'); 
            System.debug('Opportunity Record Id>>>>>>>>>>'+recordId);
            alert = false;
            editshow =false;
            javaScriptfn = false;
            oppty =  [Select Id,IME_Contract__c,Type,StageName,Company_Name__c,Billing_Country__r.Name,
                      Company_Registered_Address2__c,Company_Number__c,Initial_Period__c,Contract_Term__c,Contracting_Country__c,
                      Effective_Date__c,Product__c,Registered_In__c from Opportunity Where id=:recordId limit 1];
            System.debug('Opportunity Record Details>>>>>>>> '+oppty);
        }
    }
    
    public PageReference createNewContract()
    {      
            List<contract> contr = [Select Id,Status,Standard_Contract__c from contract where id =:oppty.IME_Contract__c limit 1];
            if(contr.size()>0)
            {
                ContractStatus = contr[0].Status; 
                StandardContract = contr[0].Standard_Contract__c; 
            } 
            if(ContractStatus =='Activated')
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'There is an active contract already linked to this Opportunity');
                ApexPages.addMessage(myMsg);
            }
            
            else if(StandardContract!= true && oppty.IME_Contract__c !=Null)
            { 
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The contract linked havent gone through the Standard Contract Process. Please contact Contracts Team to assist.');
                ApexPages.addMessage(myMsg);   
            }
            else if(oppty.Type != 'New Deal' || oppty.StageName !='4 - Negotiate')
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Standard Contracts can only be created for ’New Deal’ Opportunities at "Stage 4 - Negotiate".');
                ApexPages.addMessage(myMsg);    
            }
            else if(oppty.IME_Contract__c !=Null)
            {
                javaScriptfn = true;
                alert = false; 
            } 
            else
            {
                javaScriptfn = false;
                alert = true;
            }
        return null;
    } 
    
    public void alertContract()
    {
        alert = true;  
        javaScriptfn = false;
        cancelContract = true;
    }
    public PageReference contractCancel()
    {
        PageReference pageRef = new PageReference('/'+oppty.Id);
        pageRef.setRedirect(true);
        return pageRef;           
    }
    public PageReference cancel()
    {
        PageReference pageRef = new PageReference('/apex/createNewContract?id='+oppty.Id);
        pageRef.setRedirect(true);
        return pageRef; 
    }
    public void editcontract(){
        editshow =true;
    }	
    public PageReference save()
    {  
        try {   
            Database.SaveResult sr = Database.update(oppty, false);
            this.standardController.save();
            //PageReference ContractDetailPg;
            if(sr.isSuccess()) { 
                System.debug('Success');
                String recordId = ApexPages.currentpage().getParameters().get('id'); 
                System.debug('REcord ID>>>>'+recordId);
                pageReference rPage = null; 
                if(!String.isBlank(recordId)){ 
                    rPage = new pageReference('/apex/createNewContract?id='+recordId); 
                }
                editshow=false;
                rPage.setRedirect(true);
                return rPage;  
            }
            else{
                if(sr.getErrors()!=Null){
                     System.debug('failure');
                    String er='';
                    for(Database.Error err : sr.getErrors()) {
                        er += err.getMessage();
                    }
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'Failed to update contract: '+er));
                    editshow=false;
                }
                return null;
            }
            
        } catch(DMLException e) {  
            System.debug('An exception occurred: ' + e.getMessage());
            Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'Failed to update contract: '+e));
            return null;  
        }
        
    } 
    public PageReference createContract()
    {
        System.debug('Fields Value>>>>> Company Name>> '+oppty.Company_Name__c);
        System.debug('Fields Value>>>>> Company Address>> '+oppty.Company_Registered_Address2__c);
        System.debug('Fields Value>>>>> Company No>> '+oppty.Company_Number__c); //CmpNo
        System.debug('Fields Value>>>>> Contract_Terms>> '+oppty.Contract_Term__c);//ContractTerms
        System.debug('Fields Value>>>>> Product Name>> '+oppty.Product__c);//Product
        System.debug('Fields Value>>>>> Contracting Country>> '+oppty.Contracting_Country__c); //Contracting Country
        System.debug('Fields Value>>>>> Registered In>> '+oppty.Registered_In__c);//Registered In
        System.debug('Fields Value>>>>> Initial Period>> '+oppty.Initial_Period__c);//Initial Period
        System.debug('Fields Value>>>>> Effective Date>>'+oppty.Effective_Date__c); //Effective Date
        alert = false;
        if(oppty.Company_Name__c =='' || oppty.Company_Name__c ==Null || oppty.Company_Registered_Address2__c =='' || oppty.Company_Registered_Address2__c == Null ||
           oppty.Company_Number__c =='' || oppty.Company_Number__c == Null || oppty.Initial_Period__c =='' || oppty.Initial_Period__c == Null ||
           oppty.Contract_Term__c =='' || oppty.Contract_Term__c == Null || oppty.Effective_Date__c == Null || oppty.Product__c=='' || oppty.Product__c== Null)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'All fields in the "Standard Contract Details" section should be populated in Contract');
            ApexPages.addMessage(myMsg); 
        }
        else 
        {
            if(oppty.Contracting_Country__c == oppty.Billing_Country__r.Name) //added r.Name
            {
                try{ 
                String signature = createStandardContract(oppty.Id,cancelContract);
                System.debug('Signature>>>>>'+signature);
                String partnerServerURL = ApexPages.currentPage().getHeaders().get('Host');
                System.debug('Conga Partner Server Url>>>>>'+partnerServerURL);
                // String sCongaUrl = 'https://composer.congamerge.com?sessionId=';
                String sCongaUrl='/apex/APXTConga4__Conga_Composer?serverUrl=';
                contractCongaList = [Select Product__c, Conga_Params__c,Country__c from IME_Contract_Conga_URLs__mdt];
                for(IME_Contract_Conga_URLs__mdt cc :contractCongaList)
                {
                    if(cc.Product__c == oppty.Product__c && cc.Country__c == oppty.Contracting_Country__c)
                    {
                        conga_params = cc.Conga_Params__c;
                        System.debug('Conga Params>>>>'+conga_params);
                    }
                }
                    System.debug('Oppty Id>>'+oppty.Id+'Attachment Id>>>'+signature);
                    String congalocation = sCongaUrl+partnerServerURL+'&id='+oppty.Id+'&AttachmentParentId='+signature+conga_params;
                    PageReference pageRef = new PageReference(congalocation); 
                    return pageRef;
                }
                catch(Exception e)
                {
                    System.debug('An exception occurred: ' + e.getMessage());
                    Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'Failed to update contract: '+e)); 
                } 
            }
            else
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Billing Country needs to match with Contracting Country');
                ApexPages.addMessage(myMsg); 
            }
        }
        return null;
    }
    
    public static string createStandardContract(string opportunityId, boolean UpdateContract)        
    {
		system.debug('createStandardContract started');
        //Query Contract Opportunity details
        Opportunity Opp = [Select Id,AccountId,Billing_Country__c,Effective_Date__c,Product__c,IME_Contract__c,Initial_Period__c,Contract_Term__c,Contracting_Country__c,Company_Number__c FROM Opportunity WHERE id=:opportunityId LIMIT 1];
        list<OpportunityContactRole> oppCont = [Select ContactId, isPrimary from OpportunityContactRole WHERE Role='Decision Maker' and OpportunityId=:opportunityId];
        system.debug('OpportunityContactRole is selected '+oppCont);
        
        IME_Contract_Conga_URLs__mdt contractCongList = [SELECT CC_Signer__c,Conga_Params__c,Contract_Term_Type__c,Contract_Version__c,Country__c,DeveloperName,Email_message__c,
                                                         Email_subject__c,Expiration_Notice_days__c,Fixed_Pricing_Period_months_Prod_S__c,Fixed_Pricing_Period_months_Services__c,
                                                         Fixed_Pricing_Period_months_Storage__c,Fixed_Pricing_Period_months_Transp__c,Id,Internal_Signatories__c,Label,Language,
                                                         Liability_Currency__c,Liability__c,MasterLabel,Max_Liability__c,NamespacePrefix,Price_Increase_Type_Product_Sales__c,
                                                         Price_Increase_Type_Services__c,Price_Increase_Type_Storage__c,Price_Increase_Type_Transport__c,Product__c,QualifiedApiName,
                                                         Renewal_Term_months__c,Capped_Percentage_Product_Sales__c,Capped_Percentage_Services__c,Capped_Percentage_Storage__c,Capped_Percentage_Transport__c,
                                                         Special_Terms_Other_Services__c,Special_Terms_Other_Prod_S__c,Special_Terms_Other_Storage__c,Special_Terms_Other_Transp__c,Index_Product_Sales__c,
                                                         Index_Services__c,Index_Storage__c,Index_Transport__c FROM IME_Contract_Conga_URLs__mdt Where Country__c=: Opp.Contracting_Country__c and Product__c=:Opp.Product__c];
        system.debug('244 after contractCongList ');
        Contract cont = new Contract();
        // added By Masthan for the case # 07704279  - Start - 
        
        cont.IME_Contract_Version__c = contractCongList.Contract_Version__c;
        cont.IME_Liability_Currency__c = contractCongList.Liability_Currency__c; 
        
        // added By Masthan for the case # 07704279  - End - 
        
        cont.RecordTypeid = '01280000000UJX3';
        cont.AccountId = Opp.AccountId;
        cont.Billing_Country__c = Opp.Billing_Country__c;
        cont.StartDate = Opp.Effective_Date__c;
        cont.Contract_Type__c = 'IM Standard'; 
        
        cont.IME_Contract_Term_Type__c = contractCongList.Contract_Term_Type__c;
        cont.ContractTerm = Integer.valueOf(Opp.Contract_Term__c);
        cont.Initial_Period__c = Integer.valueOf(Opp.Initial_Period__c);
        cont.IM_Renewal_Term__c = contractCongList.Renewal_Term_months__c;
        cont.IME_Expiration_Notice_days__c = contractCongList.Expiration_Notice_days__c;
        
        cont.IM_Liability__c = contractCongList.Liability__c;
        cont.IM_Max_Liability__c = contractCongList.Max_Liability__c;
        cont.IME_MFP_Clause__c = 'NO';
        cont.IME_Non_Standard_Clause__c = 'NO';
        cont.IME_Price_Increase_Type_Storage__c = contractCongList.Price_Increase_Type_Storage__c;
        cont.IME_Fixed_Pricing_Period_months_Storage__c = contractCongList.Fixed_Pricing_Period_months_Storage__c;
        cont.IME_Price_Increase_Type_Services__c = contractCongList.Price_Increase_Type_Services__c;
        cont.IME_Fixed_Pricing_Period_months_Services__c = contractCongList.Fixed_Pricing_Period_months_Services__c;
        cont.IME_Price_Increase_Type_Transport__c = contractCongList.Price_Increase_Type_Transport__c;
        cont.IME_Fixed_Pricing_Period_months_Transp__c = contractCongList.Fixed_Pricing_Period_months_Transp__c;
        cont.IME_Price_Increase_Type_Product_Sales__c = contractCongList.Price_Increase_Type_Product_Sales__c;
        cont.IME_Fixed_Pricing_Period_months_Prod_S__c = contractCongList.Fixed_Pricing_Period_months_Prod_S__c;
        if(contractCongList.Special_Terms_Other_Services__c == 'N/A')
        {
            cont.IME_Special_Terms_Other_Services__c='';
        }else{
            cont.IME_Special_Terms_Other_Services__c=contractCongList.Special_Terms_Other_Services__c;
        }
         if(contractCongList.Special_Terms_Other_Prod_S__c == 'N/A')
        {
            cont.IME_Special_Terms_Other_Prod_S__c='';
        }else{
            cont.IME_Special_Terms_Other_Prod_S__c=contractCongList.Special_Terms_Other_Prod_S__c;
        }
         if(contractCongList.Special_Terms_Other_Storage__c == 'N/A')
        {
            cont.IME_Special_Terms_Other_Storage__c='';
        }else{
            cont.IME_Special_Terms_Other_Storage__c=contractCongList.Special_Terms_Other_Storage__c;
        }
         if(contractCongList.Special_Terms_Other_Transp__c == 'N/A')
        {
            cont.IME_Special_Terms_Other_Transp__c='';
        }else{
            cont.IME_Special_Terms_Other_Transp__c=contractCongList.Special_Terms_Other_Transp__c;
        } 
        
        if(contractCongList.Index_Product_Sales__c == 'N/A')
        {
            cont.IME_Index_Product_Sales__c='';
        }else{
            cont.IME_Index_Product_Sales__c=contractCongList.Index_Product_Sales__c;
        } 
        
        if(contractCongList.Index_Services__c == 'N/A')
        {
            cont.IME_Index_Services__c='';
        }else{
            cont.IME_Index_Services__c=contractCongList.Index_Services__c;
        } 
        
        if(contractCongList.Index_Storage__c == 'N/A')
        {
            cont.IME_Index_Storage__c='';
        }else{
            cont.IME_Index_Storage__c=contractCongList.Index_Storage__c;
        } 
        
        if(contractCongList.Index_Transport__c == 'N/A')
        {
            cont.IME_Index_Transport__c='';
        }else{
            cont.IME_Index_Transport__c=contractCongList.Index_Transport__c;
        }   
        if(contractCongList.Capped_Percentage_Product_Sales__c == '999')
        {
            cont.IME_Capped_Percentage_Product_Sales__c = Null;
        }
        else
        {
            cont.IME_Capped_Percentage_Product_Sales__c = Decimal.ValueOf(contractCongList.Capped_Percentage_Product_Sales__c);
        }
        if(contractCongList.Capped_Percentage_Services__c == '999')
        {
            cont.IME_Capped_Percentage_Services__c = Null;
        }
        else
        {
            cont.IME_Capped_Percentage_Services__c = Decimal.ValueOf(contractCongList.Capped_Percentage_Services__c);
        }
        if(contractCongList.Capped_Percentage_Storage__c == '999')
        {
            cont.IME_Capped_Percentage_Storage__c = Null;
        }
        else
        {
            cont.IME_Capped_Percentage_Storage__c = Decimal.ValueOf(contractCongList.Capped_Percentage_Storage__c);
        }
        
        if(contractCongList.Capped_Percentage_Transport__c == '999')
        {
            cont.IME_Capped_Percentage_Transport__c = Null;
        }
        else
        {
            cont.IME_Capped_Percentage_Transport__c = Decimal.ValueOf(contractCongList.Capped_Percentage_Transport__c);
        }
      
        cont.Standard_Contract__c = True;
        cont.Account_Registration_Number__c = Opp.Company_Number__c;
        
        if(Opp.Product__c == 'RM') 
        {
            cont.IME_Records_Management_RM__c = True;
        }
        if(Opp.Product__c == 'DM') 
        {
            cont.IME_Data_Protection_DP__c = True;
        }
        if(Opp.Product__c == 'DMS')
        {
            cont.IME_Document_Management_Services_DMS__c = True;
        }
        if(Opp.Product__c == 'RM+DM') 
        {
            cont.IME_Records_Management_RM__c = True;
            cont.IME_Data_Protection_DP__c = True;
        }
        if(Opp.Product__c == 'RM+DMS') 
        {
            cont.IME_Records_Management_RM__c = True;
            cont.IME_Document_Management_Services_DMS__c = True;
        } 
        if(Opp.Product__c == 'RM+DM+DMS') 
        {
            cont.IME_Records_Management_RM__c = True;
            cont.IME_Data_Protection_DP__c = True;
            cont.IME_Document_Management_Services_DMS__c = True;
        }        
        // Added by Revathy Saminathan for the Case 11211220
        if(Opp.Product__c == 'Shred')
        {
            cont.IME_Secure_Shredding_SS_Scheduled__c = True;
        }
        if(Opp.Product__c =='' || Opp.Product__c =='Null')
        {
            cont.IME_Other__c = True;   
        }
        cont.Status = 'Draft';
        insert cont; 
        
        IME_Signature_Information__c sig = new IME_Signature_Information__c();
        sig.IME_Internal_Signatories__c = contractCongList.Internal_Signatories__c;
        sig.IME_Signing_Order__c = 'Client signs first';// For case#07945998 UK Non-Standard Contracting Process with DocuSign
        sig.IME_Contract__c = cont.id;
        sig.IME_Email_Subject__c = contractCongList.Email_subject__c;
        sig.IME_Email_Message__c = contractCongList.Email_message__c;
        sig.IME_EnableReminders__c = True;
        sig.IME_ReminderDays__c = '7';
        sig.IME_ReminderRepeatDays__c = '7';
        sig.IME_ExpireVoid__c = True;
        sig.IME_ExpireNDays__c = '180';
        sig.IME_ExpireWarnNDays__c = '30';  
        sig.Standard_Contract__c = True;     
        sig.Carbon_Copy_Signer__c = contractCongList.CC_Signer__c; 
        insert sig;
        System.debug('OppCont List>>>'+oppCont.size());
        if(oppCont.size()>0)
        {
            IME_Signatory_Contact__c sign = new IME_Signatory_Contact__c();
            sign.IME_DocuSign_Contract_Envelope__c = sig.id;
            sign.IME_Routing_Order__c = 1;
            boolean PrimaryDecisionMaker = false;
            for(OpportunityContactRole contRole:oppCont)
            {
                if(contRole.isPrimary==true) {               
                    sign.IME_Contact__c = contRole.ContactId; 
                    PrimaryDecisionMaker =true;
                }
            }    
            if(PrimaryDecisionMaker==false)
                sign.IME_Contact__c = oppCont[0].ContactId; 
            
            insert sign;
        }          
        
        if(UpdateContract && Opp.IME_Contract__c != Null)
        {
            Contract ct = [select id,Status from Contract where id=:Opp.IME_Contract__c];
            ct.Status ='Cancelled';
            update ct;
        }
        
        //Associate the Opportunity to the Contract
        Opp.IME_Contract__c = cont.id;
        update Opp;        
        return sig.id;
    }
}
public without sharing class requestIntakeForm {
    
    public String requestTypes{get;set;}
    public Corporate_Request__c request{get;set;}
    private ApexPages.StandardController controller;
    public Boolean showSave {get;set;}
    
    
    public requestIntakeForm(ApexPages.StandardController stdController) {
        this.controller = stdController; 
        this.request = new Corporate_Request__c(); 
        request.Requestor_s_Name__c = '';
        request.Requestor_s_Email__c = '';
        showSave = false;
    } 
    
    public PageReference setRecordType() {
        
        Id ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Corp_Records_Subsidiary_Matters').getRecordTypeId();
        switch on requestTypes
        {
            when 'Corp'
            {
                ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Corp_Records_Subsidiary_Matters').getRecordTypeId();              
            }
            when 'Customer'
            {
                ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Customer_Contract').getRecordTypeId();               
            }                                                                                              
            when 'Employment'
            {
                ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Employment_Labor').getRecordTypeId();               
            }
            when 'General'
            {
                ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_General').getRecordTypeId();               
            }when 'Intellectual'
            {
                ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Intellectual_Property_Marketing').getRecordTypeId();               
            }
            when 'Litigation'
            {
                ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Litigation_Dispute_Incident').getRecordTypeId();               
            }
            when 'Tuck'
            {
                ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Tuck_In').getRecordTypeId();               
            }
            when 'Privacy'
            {
                ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Privacy_Compliance').getRecordTypeId();               
            }
            when 'Real Estate'
            {
                ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Real_Estate').getRecordTypeId();               
            }
            when 'Vendor'
            {
                ReqRecordTypeId =  Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Vendors_Partnerships').getRecordTypeId();               
            }
        }
        
        request.RecordTypeId = ReqRecordTypeId;
        showSave=true;
        return null;
    }
        
    public List<SelectOption> getRequestsOptions() {
        List<SelectOption> requestOptions = new List<SelectOption>();
        
        requestOptions.add(new SelectOption('','-Select-'));
        requestOptions.add(new SelectOption('Corp','Corp. Records & Subsidiary Matters'));
        requestOptions.add(new SelectOption('Customer','Customer Related (Contracts/Amendments)'));
        requestOptions.add(new SelectOption('Employment','Employment & Labor'));
        requestOptions.add(new SelectOption('General','General/Questions'));
        requestOptions.add(new SelectOption('Intellectual','Intellectual Property & Marketing'));
        requestOptions.add(new SelectOption('Litigation','Litigation/Dispute/Incident'));
        requestOptions.add(new SelectOption('Privacy','Privacy & Compliance'));
        requestOptions.add(new SelectOption('Real Estate','Real Estate'));
        requestOptions.add(new SelectOption('Tuck','Tuck-In'));
        requestOptions.add(new SelectOption('Vendor','Vendors & Partnerships'));
        
        return requestOptions;
    }
    
    public PageReference saveAndSuccess() {
        Id privacyRecordTypeId = Schema.Sobjecttype.Corporate_Request__c.getRecordTypeInfosByDeveloperName().get('Legal_Privacy_Compliance').getRecordTypeId();
        if(request.RecordTypeId == privacyRecordTypeId && request.Request_Type__c=='Vendor Contract Review' && request.Vendor_Services_Provided__c == null)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.error,'Please enter value for Vendor Services'));            
            return null;
        }
        else
        {
            insert request;
            string requestId= request.id;
            PageReference successPage = Page.requestIntakeSuccess;
            successPage.setRedirect(true);
            successPage.getParameters().put('id',requestId);        
            return successPage;            
        }
    }
    
    
}
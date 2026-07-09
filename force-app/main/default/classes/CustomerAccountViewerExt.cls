/**
**Author: Kenny W
**Date: 9/21/13
**Company: Bluewolf
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 09/30/2013; Kenny W/Bluewolf; Cac Responsiblity Viewer - Cac Responsiblity Viewer (Case # 01153062); Initial release
**/

public with sharing class CustomerAccountViewerExt
{
    public static final String COUNTRY_PARENT = 'Country Parent';
    public static final String IM_GROUP = 'IM Group (IMGA)';
    public static final String ALL_OPTIONS = 'all';
    
    public static final Map<String, String> customerAcctSelectOptionMap = new Map<String, String>
    {
        'contact' => System.Label.ConCustAcct,
        'contactAcct' => System.Label.ConAcctCustAccts,
        'countryParent' => System.Label.CountParentCustAccts,
        'imga' => System.Label.IMGACustAccts,
        'custAcct' => 'Customer Account View'
    };
    
    public List<SelectOption> customerAccountList{get;set;}
    public List<SelectOption> cacResponsiblityList{get;set;}
    public String customerAcctFilter{get;set;}
    public String cacResponsibilityFilter{get;set;}
    public IME_SC_CAc_Responsibility__c newContactLookupDummy{get;set;}
    public IME_SC_CAc_Responsibility__c replaceContactLookupDummy{get;set;}
    
    Id accountId;
    Id targetObject;
    public String hierarchyParent{get;set;}
    
    public String objectType{get;set;}
    public List<CacWrapper> visibleCacResponsibilities{get;set;}
    public boolean RespActiveFilter{get;set;}
    public boolean noRecordsFound{
        get
        {
            return visibleCacResponsibilities.isEmpty();
        }
    }
    
    public List<String> CAC_FIELDS{get;set;}
    
    public CustomerAccountViewerExt()
    {
        this.RespActiveFilter = false;
        newContactLookupDummy = new IME_SC_CAc_Responsibility__c();
        replaceContactLookupDummy = new IME_SC_CAc_Responsibility__c();
        cacResponsibilityFilter = 'all';
        targetObject = Apexpages.currentPage().getParameters().get('id');
        objectType = targetObject.getSObjectType().getDescribe().getName();
        if(objectType == 'Contact')
        {
            customerAcctFilter = 'contact';
        }
        else if(objectType == 'IM_Customer_Account__c')
        {
            customerAcctFilter = 'custAcct';
        }
        this.queryCacs();
    }
    
    public void queryCacs()
    {
        List<String> queryBuilder = new List<String>();
        if(this.objectType == 'Contact')
        {
            List<Contact> targetContacts = [SELECT Id, accountId FROM Contact WHERE Id = :targetObject];
            if(targetContacts.size() == 1)
            {
                this.accountId = targetContacts[0].accountId;
            }
            this.newContactLookupDummy.IME_SC_Contact__c = this.targetObject;
            CAC_FIELDS = new List<String>{  'IME_SC_Customer_Account__r.IM_Status__c', 
                                            'IME_SC_Customer_Account__c',
                                            'IME_SC_Customer_Account__r.IM_Account__r.Name',
                                            'IME_SC_Customer_Account__r.IM_Account__r.BillingStreet', 
                                            'IME_SC_Customer_Account__r.IM_Account__r.BillingCity', 
                                            'IME_SC_Customer_Account__r.IM_Account__r.BillingPostalCode' , 
                                            'IME_SC_Customer_Account__r.IM_Account__r.BillingCountry', 
                                            'IME_SC_Contact__c',
                                            'Resp_Active__c', 
                                            'IME_CAc_Responsibility__c',
                                            'IME_SC_Contact__r.IM_No_Longer_With_Company__c'};
        }
        else if(objectType == 'IM_Customer_Account__c')
        {
            List<IM_Customer_Account__c> targetCustomers = [SELECT Id, IM_Account__c FROM IM_Customer_Account__c WHERE Id = :targetObject];
            if(targetCustomers.size() == 1)
            {
                this.accountId = targetCustomers[0].IM_Account__c;
            }
            this.newContactLookupDummy.IME_SC_Customer_Account__c = targetObject;
            CAC_FIELDS = new List<String>{  'IME_SC_Contact__c', 
                                            'IME_SC_Contact__r.Email',
                                            'IME_SC_Contact__r.Title',
                                            'IME_CAc_Responsibility__c',
                                            'Resp_Active__c',
                                            'IME_SC_Contact__r.IM_No_Longer_With_Company__c'};
        }
        List<Id> hierarchyIds;
        if(this.accountId == null)
        {
            visibleCacResponsibilities = new List<CacWrapper>();
            return;
        }
        List<IM_Customer_Account__c> customerAccounts = new List<IM_Customer_Account__c>();
        
        if(customerAcctFilter == 'custAcct')
        {
            this.hierarchyParent = null;
            customerAccounts.addAll([SELECT Id FROM IM_Customer_Account__c WHERE Id = :this.targetObject]);
        }
        if(customerAcctFilter == 'contactAcct')
        {
            this.hierarchyParent = null;
            customerAccounts.addAll([SELECT Id FROM IM_Customer_Account__c WHERE IM_Account__c = :this.accountId]);
        }
        if(customerAcctFilter == 'countryParent')
        {
            hierarchyIds = hierarchyGathererAllUmbrellaAccounts(accountId, COUNTRY_PARENT);
            customerAccounts.addAll([SELECT Id FROM IM_Customer_Account__c WHERE IM_Account__c IN :hierarchyIds]);
            this.hierarchyParent = [SELECT Id, Name FROM Account WHERE Id = :hierarchyIds.get(hierarchyIds.size()-1)].Name;
        }
        if(customerAcctFilter == 'imga')
        {
            hierarchyIds = hierarchyGathererAllUmbrellaAccounts(accountId, IM_GROUP);
            customerAccounts.addAll([SELECT Id FROM IM_Customer_Account__c WHERE IM_Account__c IN :hierarchyIds ]);
            this.hierarchyParent = [SELECT Id, Name FROM Account WHERE Id = :hierarchyIds.get(hierarchyIds.size()-1)].Name;
            
        }
        
        queryBuilder.add('SELECT Id, ');
        queryBuilder.add(String.join(this.CAC_FIELDS, ', '));
        queryBuilder.add(' FROM IME_SC_CAc_Responsibility__c WHERE');
        queryBuilder.add(' ((IME_SC_Customer_Account__c IN :customerAccounts');
        
        queryBuilder.add(')');
        if(customerAcctFilter == 'contact')
        {
            queryBuilder.add(' OR IME_SC_Contact__c = :targetObject');
        }
        queryBuilder.add(')');
        if(customerAcctFilter != null && cacResponsibilityFilter != ALL_OPTIONS)
        {
            queryBuilder.add(' AND IME_CAc_Responsibility__c = :cacResponsibilityFilter');
        }
        if(this.RespActiveFilter)
        {
            queryBuilder.add(' AND Resp_Active__c = true');
        }
        
        
        visibleCacResponsibilities = new List<CacWrapper>();
        List<IME_SC_CAc_Responsibility__c> foundCacs = Database.query(String.join(queryBuilder, ''));
        for(IME_SC_CAc_Responsibility__c aCac : foundCacs)
        {
            visibleCacResponsibilities.add(new CacWrapper(aCac));
        }
        generateSelectOptions();
    }
    
    public void generateSelectOptions()
    {
        customerAccountList = new List<SelectOption>();
        cacResponsiblityList = new List<SelectOption>{new SelectOption(ALL_OPTIONS, 'All CAc Responsibilities')};
        for(String aKey : customerAcctSelectOptionMap.keySet())
        {
            if(aKey == 'imga' && hierarchyGathererAllUmbrellaAccounts(this.accountId, IM_GROUP).isEmpty()) continue;
            if(aKey == 'countryParent' && hierarchyGathererAllUmbrellaAccounts(this.accountId, COUNTRY_PARENT).isEmpty()) continue;
            if(aKey == 'contact' && objectType != 'Contact') continue;
            if(aKey == 'contactAcct' && objectType != 'Contact') continue;
            if(aKey == 'custAcct' && objectType != 'IM_Customer_Account__c') continue;
            customerAccountList.add(new SelectOption(aKey,customerAcctSelectOptionMap.get(aKey)));
        }
        Set<String> uniqueSetCacResponsibilities = new Set<String>();
        
        for(CacWrapper aCac : visibleCacResponsibilities)
        {
            uniqueSetCacResponsibilities.add(aCac.theCac.IME_CAc_Responsibility__c);
        }
        for(String aString : uniqueSetCacResponsibilities)
        {            
            if(aString != null)
            cacResponsiblityList.add(new SelectOption(aString, aString));
        }
    }

    @TestVisible static Id findNearestAccountWith( String imHierarchyLevel, Account act )
    {
        String flag = act.IM_Hierarchy_Level__c;
        if ( flag == imHierarchyLevel )
        {
            return act.Id;
        }
        if ( act.Parent == null )
        { 
            return null;
        }
        return findNearestAccountWith( imHierarchyLevel, act.Parent );
    }

    public static List<Id> hierarchyGathererAllUmbrellaAccounts(Id acctId, String hierarchyTarget)
    {
        List<Id> accountsToGather = new List<Id>();
        Account firstAccount = [Select IM_Hierarchy_Level__c,
                                       Parent.Id, Parent.IM_Hierarchy_Level__c,
                                       Parent.Parent.Id, Parent.Parent.IM_Hierarchy_Level__c,
                                       Parent.Parent.Parent.Id, Parent.Parent.Parent.IM_Hierarchy_Level__c,
                                       Parent.Parent.Parent.Parent.Id, Parent.Parent.Parent.Parent.IM_Hierarchy_Level__c,
                                       Parent.Parent.Parent.Parent.Parent.Id, Parent.Parent.Parent.Parent.Parent.IM_Hierarchy_Level__c
                                  from Account where Id = :acctId];


        Id accountWithHierachy = findNearestAccountWith( hierarchyTarget, firstAccount );
        if( accountWithHierachy == null ) return accountsToGather;
        List<Account> childrenAccounts = [Select Id from Account
                                            where Id = :accountWithHierachy
                                              or  Parent.Id = :accountWithHierachy
                                              or  Parent.Parent.Id = :accountWithHierachy
                                              or  Parent.Parent.Parent.Id = :accountWithHierachy
                                              or  Parent.Parent.Parent.Parent.Id = :accountWithHierachy
                                              or  Parent.Parent.Parent.Parent.Parent.Id = :accountWithHierachy];
        for( Account act : childrenAccounts )
        {
            accountsToGather.add( act.Id );
        }
        return accountsToGather;
    }

    public List<Id> acctHierarchyGatherer(Id acctId, String hierarchyTarget)
    {
        List<Id> gatheredAcctIds = new List<Id>();
        Account currentAcct;
        do
        {
            currentAcct = [SELECT Id, Name, ParentId,IM_Hierarchy_Level__c FROM Account WHERE Id = :acctId Limit 1];
            gatheredAcctIds.add(currentAcct.Id);
            acctId = currentAcct.ParentId;
        }
        while(currentAcct.IM_Hierarchy_Level__c != hierarchyTarget && !String.isBlank(currentAcct.ParentId));
        if(String.isBlank(currentAcct.ParentId) && currentAcct.IM_Hierarchy_Level__c != hierarchyTarget)
        {
            gatheredAcctIds.clear();
        }
        return gatheredAcctIds;
    }
    
    public PageReference selectNewContact()
    {
        if(String.isBlank(newContactLookupDummy.IME_SC_Contact__c) && objectType == 'contact')
        {
            Apexpages.addMessage(new Apexpages.Message(Apexpages.SEVERITY.Info, System.Label.ContactSwitchError));
            return null;
        }
        if(String.isBlank(newContactLookupDummy.IME_SC_Customer_Account__c) && objectType == 'IM_Customer_Account__c')
        {
            Apexpages.addMessage(new Apexpages.Message(Apexpages.SEVERITY.Info, System.Label.CustomerAcctSwitchError));
            return null;
        }
        PageReference ref = Apexpages.currentPage();
        if(this.objectType == 'Contact')
        {
            ref.getParameters().put('id', newContactLookupDummy.IME_SC_Contact__c);
        }
        else if(this.objectType == 'IM_Customer_Account__c')
        {
            ref.getParameters().put('id', newContactLookupDummy.IME_SC_Customer_Account__c);
        }
        ref.setRedirect(true);
        return ref;
    }
    public PageReference replaceContacts()
    {
        if(String.isBlank(replaceContactLookupDummy.IME_SC_Contact__c))
        {
            Apexpages.addMessage(new Apexpages.Message(Apexpages.SEVERITY.Info, System.Label.contactReplaceError));
            return null;
        }
        List<IME_SC_CAc_Responsibility__c> cacsToUpdate = new List<IME_SC_CAc_Responsibility__c>();
        for(CacWrapper aWrap : visibleCacResponsibilities)
        {
            if(aWrap.isChecked)
            {
                aWrap.theCac.IME_SC_Contact__c = replaceContactLookupDummy.IME_SC_Contact__c;
                cacsToUpdate.add(aWrap.theCac);
            }
        }
        try
        {
            update cacsToUpdate;
            
        }
        catch(System.dmlException dEX)
        {
            Apexpages.addMessages(dEX);
            return null;
        }
        PageReference ref = Apexpages.currentPage();
        ref.setRedirect(true);
        return ref;
    }
    
    public class CacWrapper
    {
        public Boolean isChecked{get;set;}
        public IME_SC_CAc_Responsibility__c theCac{get;set;}
        
        public CacWrapper(IME_SC_CAc_Responsibility__c aCac)
        {
            this.theCac = aCac;
            isChecked = false;
        }
    }
}
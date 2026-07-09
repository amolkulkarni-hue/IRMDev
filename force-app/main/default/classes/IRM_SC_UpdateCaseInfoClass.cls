/**  
       * Name            : IRM_SC_UpdateCaseInfoClass
       * Description     : 1. Update the case Status to In Progress if case Status is Assigned and is edited by CSR.
                           2. Update the case Status to In Progress and assign the case to CSR if the case Status is Validated 
                              and Case Owner is a queue and case is edited by CSR.
                           3. Set Business Hours as per the running user's timezone if case country is "Australia"
                           4. Populate case Owner Manager and Owner's Manager's Manger if the Case Owner is a User.
                           5. Populate Contact and Account for email-to-case if there are multiple contacts with same email address
                              and mark it as Duplicate Contact Email
                           6. Change Owner as running user when case status is changed from Validated to closed, resolved or in progress
                           7. To populate request type on the basis of category and sub category
                           8. Change the case stauts to Validated if the case owner is changed to queue from user
       * Copyright       : HCL Technologies
       * Author          : Sejal Shah
       * Modification Log: Created :6-Mar-2012
                           Modified:13-Mar-2012 
**/

public with sharing class IRM_SC_UpdateCaseInfoClass {
     
    Set<ID> ownerForStatusChangeIdSet = new Set<ID>();
    Map<Id,User> ownerMap;     
    Set<ID> userIdSet = new Set<ID>();
    Set<ID> ownerSet = new Set<ID>();
    Map<Id,User> ownerManagerMap;

    //Update case Owner Manager and Owner's Manager's Manger if the Case Owner is a User. 
    public void populateUsers(List<Case> newCaseTriggerList)
    {
        for(Case caseTrigger: newCaseTriggerList)
        {
            if(String.valueOf(caseTrigger.OwnerId).startsWith('005'))
            {
                ownerSet.add(caseTrigger.OwnerId);
            }
        }
        
        try{
            if(ownerSet != null && !ownerSet.isEmpty())
            {
                ownerManagerMap = new Map<Id,User>([Select Id, ManagerId, Manager.ManagerId From User where Id IN :ownerSet]);
            }
        }
        catch(system.QueryException QE)
        {
            system.debug('Exception in catch block is: '+QE.getMessage());
        }
        
        for(Case caseTrigger: newCaseTriggerList)
        {
            //to check whether Case Owner is User
            if(String.valueOf(caseTrigger.OwnerId).startsWith('005'))
            {     
                //to check whether Owner has Manager
                if(ownerManagerMap != null && !ownerManagerMap.isEmpty())
                {
                    caseTrigger.IME_SC_Owner_Manager__c = ownerManagerMap.get(caseTrigger.OwnerId).ManagerId;
                    
                    //to check whether Owner's Manager has Manager
                    if(ownerManagerMap.get(caseTrigger.OwnerId).Manager.ManagerId != null)
                    {
                        caseTrigger.IME_SC_Manager_of_Manager_OwnerId__c = ownerManagerMap.get(caseTrigger.OwnerId).Manager.ManagerId;
                    }
                    else
                    {
                        caseTrigger.IME_SC_Manager_of_Manager_OwnerId__c = null;
                    }
                }
            }
            //if case Owner is a queue
            else
            {
                caseTrigger.IME_SC_Owner_Manager__c = null;
                caseTrigger.IME_SC_Manager_of_Manager_OwnerId__c = null;
            }
        }
    }

    //Update the case Status to In Progress if case Status is Assigned and is edited by CSR.
    //Update the case Status to In Progress and assign the case to CSR if the case Status is Validated and Case Owner is a queue and case is edited by CSR.
    public void updateStatus(List<Case> newCaseTriggerList, Map<Id,Case> oldCaseTriggerMap) 
    {
        //used for setting business hours.
        Map<Id, BusinessHours> businessHoursIdMap = IRM_SC_UtilityClass.getBusinessHours();
        Map<String, BusinessHours> businessHoursMap = new Map<String, BusinessHours>();
        IME_SC_Country_BH__c countryCustomSetBHours;
        BusinessHours countryBHour;
        Id businessHourID;
    
        if(businessHoursIdMap != null && !(businessHoursIdMap.isEmpty()))
        {
            for(BusinessHours businessHourLoop : businessHoursIdMap.values())
            {
                businessHoursMap.put(businessHourLoop.Name, businessHourLoop);
            }
        }
        ownerForStatusChangeIdSet.add(UserInfo.getUserId());
        for(Case caseTrigger: newCaseTriggerList)
        {
            if(String.valueOf(caseTrigger.OwnerId).startsWith('005'))
            {
                if(caseTrigger.status=='Assigned')
                {
                    userIdSet.add(caseTrigger.ownerid);
                }
            }
            //Change Owner as running user when case status is changed from Validated to closed or Resolved or In Progress
            if((caseTrigger.Status == 'Closed' || caseTrigger.Status == 'Resolved' || caseTrigger.Status == 'In Progress' || caseTrigger.Status == 'Assigned') 
                && (oldCaseTriggerMap != null) && (!oldCaseTriggerMap.isEmpty()) 
                && (oldCaseTriggerMap.get(caseTrigger.Id).Status == 'Validated' || oldCaseTriggerMap.get(caseTrigger.Id).Status == 'New') 
                && String.valueOf(caseTrigger.OwnerId).startsWith('00G'))
            {
                caseTrigger.OwnerId = Userinfo.getUserId();
            }
        }
        getOwnerMap(userIdSet,ownerForStatusChangeIdSet);
        if(ownerMap != null)
        {
            for(Case caseTrigger: newCaseTriggerList)
            {
                //Set Business Hour for Australia on update based on CSR
                if(caseTrigger.IME_SC_Country__c == 'Australia')
                {
                    User currentUser = ownerMap.get(caseTrigger.ownerID);
                    if(currentUser != null)
                    {
                        countryCustomSetBHours = IME_SC_Country_BH__c.getvalues((caseTrigger.IME_SC_Country__c+'-'+currentUser.State).toUpperCase());
                        if(countryCustomSetBHours != null)
                            countryBHour = businessHoursMap.get((IME_SC_Country_BH__c.getvalues((caseTrigger.IME_SC_Country__c+'-'+currentUser.State).toUpperCase())).Business_Hour__c);
                        if(countryCustomSetBHours != null)
                            businessHourID = (businessHoursMap.get((IME_SC_Country_BH__c.getvalues((caseTrigger.IME_SC_Country__c+'-'+currentUser.State).toUpperCase())).Business_Hour__c)).id;
                        if(businessHourID != null)
                            caseTrigger.BusinessHoursId = businessHourID;
                    }
                }
            
                //to check whether Case Owner is User
                if(String.valueOf(caseTrigger.OwnerId).startsWith('005'))
                {  
                    if(caseTrigger.IME_SC_First_Assigned_owner__c == null && caseTrigger.Status == 'In Progress' && ownerMap.get(caseTrigger.OwnerId) != null)
                    {
                        caseTrigger.IME_SC_First_Assigned_owner__c = ownerMap.get(caseTrigger.OwnerId).Name;
                        caseTrigger.IME_SC_Date_First_Edited__c = System.now(); //of CSR user on that case;
                    }
                    for(User CSRUser: ownerMap.values())
                    {
                        if(userIdSet != null && !userIdSet.isEmpty())
                        {
                            //If the logged in User is CSR and Case Status is Assigned, Change status to In Progress
                            if((caseTrigger.OwnerId == CSRUser.Id) && (caseTrigger.status == 'Assigned')
                                && userIdSet.contains(CSRUser.Id) && ownerMap.containsKey(UserInfo.getUserId()) && (ownerMap.get(UserInfo.getUserId()).UserRole.Name != null) 
                                && (CSRUser.UserRole.Name.endsWith('CSR')) && oldCaseTriggerMap != null && !oldCaseTriggerMap.isEmpty()
                                /*&& (String.valueof((oldCaseTriggerMap.get(caseTrigger.Id)).ownerid).StartsWith('00G'))*/
                                && (oldCaseTriggerMap.get(caseTrigger.Id).Status == 'Assigned') && (caseTrigger.OwnerId == Userinfo.getUserId()))
                            {
                                caseTrigger.status='In Progress';
                            }
                        }
                    }
                
                    //For Changing the status to In Progress for a CSR user
                    if((caseTrigger.Status == 'Validated') && (ownerMap.get(caseTrigger.ownerid)!= null 
                        && (String.valueof(caseTrigger.ownerid).StartsWith('005'))))
                    {
                        if(ownerMap.get(caseTrigger.ownerid).UserRole.Name != null && (ownerMap.get(caseTrigger.ownerid).UserRole.Name).endsWith('CSR'))
                        {
                            //added for proper validation rule message for state transition on 18th may.
                            if(oldCaseTriggerMap != null && !oldCaseTriggerMap.isEmpty() && (oldCaseTriggerMap.get(caseTrigger.Id).Status != 'Resolved'))
                            caseTrigger.Status = 'In Progress';
                        }
                    }
                }
                //if case Owner is a queue
                else
                {
                    caseTrigger.IME_SC_Owner_Manager__c = null;
                    caseTrigger.IME_SC_Manager_of_Manager_OwnerId__c = null;
                
                    //to change the status to In Progress if Case is Assigned to queue and is edited by CSR
                    if(/*(oldCase.Status == 'Validated') && (String.valueof(oldCase.ownerid).StartsWith('00G'))*/(oldCaseTriggerMap != null)
                        && (!oldCaseTriggerMap.isEmpty()) && (oldCaseTriggerMap.get(caseTrigger.Id).Status == 'Validated') && 
                        (String.valueof((oldCaseTriggerMap.get(caseTrigger.Id)).ownerid).StartsWith('00G'))
                        && (ownerMap.get(UserInfo.getUserId()) != null))
                    {
                        //to check whether the user updating case is CSR
                        if(((ownerMap.get(UserInfo.getUserId()).UserRole.Name != null) && (ownerMap.get(UserInfo.getUserId()).UserRole.Name).endsWith('CSR')) && 
                            (caseTrigger.Status != 'Closed'))
                        {
                            caseTrigger.Status = 'In Progress';
                            caseTrigger.ownerid = UserInfo.getUserId();
                        }
                    }
                    //Change the case stauts to Validated if the case owner is changed to queue
                    if((oldCaseTriggerMap != null) && (!oldCaseTriggerMap.isEmpty()) && (caseTrigger.Status == 'Assigned' 
                        || caseTrigger.Status == 'In Progress') && 
                        (String.valueof((oldCaseTriggerMap.get(caseTrigger.Id)).ownerid).StartsWith('005')) &&
                        (String.valueof(caseTrigger.ownerid).StartsWith('00G')))
                    {
                        caseTrigger.Status = 'Validated';
                    }
                }
            }
        }
    }
        
    private void getOwnerMap(Set<Id> userIdSet, Set<Id> ownerForStatusChangeIdSet)
    {
        try{
            ownerMap = new Map<Id,User>([Select Id, Name, state, ManagerId, Manager.ManagerId, TimeZoneSidKey, UserRole.Name,UserRole.Id,UserRoleId From User
                                            where ((Id IN :userIdSet) /*AND (UserRole.Name LIKE '%CSR')*/)
                                            OR ((Id IN :ownerForStatusChangeIdSet) /*AND (UserRole.Name LIKE '%CSR')*/)]);
                                                
            }
            catch(system.QueryException QE)
            {
                  system.debug('Exception in catch block is: '+QE.getMessage());
            }
    } 
     
    //To populate Contact on the basis of web email (Case Field) if there are multiple contacts with same Email for Email-to-case and mark it as Duplicate Contact Email
    public void populateContactForEmailToCase(List<Case> newCaseTriggerList)   
    {
        Set<String> caseEmailSet = new Set<String>();
        Map<String, List<Contact>> contactMap = new Map<String, List<Contact>>();
        List<Contact> contactList;
        List<Contact> mapContactList = new List<Contact>();
        List<Contact> getMapContactList = new List<Contact>();
        
        for(Case newCase: newCaseTriggerList)
        {
            if(newCase.SuppliedEmail != null && newCase.ContactId == null)
            {
                caseEmailSet.add(newCase.SuppliedEmail);
            }
        }
        try{
            if(caseEmailSet != null && !caseEmailSet.isEmpty())
            {
                contactList = [Select Id, Email, AccountId, CreatedDate From Contact c 
                               where Email IN :caseEmailSet Order By CreatedDate ASC];
            }
        }
        catch(system.QueryException QE)
        {
            system.debug('Exception in catch block is: '+QE.getMessage());
        }
        if(contactList!= null && caseEmailSet != null && !(contactList.isEmpty()) && !(caseEmailSet.isEmpty()))
        {
            for(String email: caseEmailSet)
            {
                if(!mapContactList.isEmpty())
                {
                    mapContactList.clear();
                }
                for(Contact emailContact: contactList)
                {
                    if(email.equalsIgnoreCase(emailContact.Email))
                    {
                        mapContactList.add(emailContact);
                    }
                }
                if(!(mapContactList.isEmpty()))
                {
                    contactMap.put(email, mapContactList);
                }
            }
            for(Case newCase: newCaseTriggerList)
            {
                if(newCase.SuppliedEmail != null && newCase.ContactId == null)
                {
                    getMapContactList = contactMap.get(newCase.SuppliedEmail);
                    if(getMapContactList!= null && !(getMapContactList.isEmpty()))
                    {
                        if(getMapContactList.size() > 1)
                        {
                            newCase.IME_SC_Duplicate_Contact_Email__c = true;
                        }
                        newCase.ContactId = getMapContactList[0].Id;
                        newCase.AccountId = getMapContactList[0].AccountId;
                        getMapContactList.clear();
                    } 
                }
            }
        }
    }
     
    //To populate request type on the basis of category and sub category from custom settings
    public void populateRequestType(List<Case> newCaseTriggerList, Map<Id, Case>oldCaseTriggerMap)
    {
        for(Case caseTrigger: newCaseTriggerList)
        {
            if(oldCaseTriggerMap!= null && !oldCaseTriggerMap.isEmpty() && oldCaseTriggerMap.containskey(caseTrigger.Id) &&
                caseTrigger.IME_SC_Category__c != null && caseTrigger.IME_SC_Sub_Category__c != null &&
                (caseTrigger.IME_SC_Category__c  != oldCaseTriggerMap.get(caseTrigger.Id).IME_SC_Category__c || 
                caseTrigger.IME_SC_Sub_Category__c != oldCaseTriggerMap.get(caseTrigger.Id).IME_SC_Sub_Category__c))
            {
                caseTrigger.IME_SC_Request_Type__c = null;
            }
            for (IME_SC_RequestType__c strRequestType: IME_SC_RequestType__c.getAll().values())
            {
                if(caseTrigger.IME_SC_Category__c == null || caseTrigger.IME_SC_Sub_Category__c == null ||
                    caseTrigger.IME_SC_Category__c =='' || caseTrigger.IME_SC_Sub_Category__c =='')
                {
                    if(caseTrigger.IME_SC_Request_Type__c != null)
                    {
                        caseTrigger.IME_SC_Request_Type__c = null;
                    }
                    break;
                }
                else if (caseTrigger.IME_SC_Category__c.equals(strRequestType.IME_SC_Category__c) 
                    && caseTrigger.IME_SC_Sub_Category__c.equals(strRequestType.IME_SC_SubCategory__c))
                {
                    caseTrigger.IME_SC_Request_Type__c = 'Order';
                    break;
                }
            }
            if(caseTrigger.IME_SC_Request_Type__c == null && caseTrigger.IME_SC_Category__c != null && caseTrigger.IME_SC_Sub_Category__c != null)
            {
                caseTrigger.IME_SC_Request_Type__c = 'Non-order';
            }
        }
    }
}
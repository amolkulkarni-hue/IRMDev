/**  
       * Name: IRM_SC_UtilityClass
       * Description: To fire static queries which are most frequently used
       * Copyright: HCL Technologies
       * Author: Sejal Shah
       * Modification Log: Created :2-May-2012
**/

/**
     * Modified By: Vinutha Iyengar on 31-May-2016 
     * Modified getContactInfo method to retreive Contact based on Id stored in custom label Dummy_Contact_Id
**/


public with sharing class IRM_SC_UtilityClass {
    
    private static Map<Id, BusinessHours> BusinessHoursIdMap;// = new Map<Id, BusinessHours>();
    private static User runningUser;
    private static Contact dummyContact;
    private static List<EmailTemplate> emailTemplateList;// = new List<EmailTemplate>();
    private static List<OrgWideEmailAddress> orgWideAddressList;// = new List<OrgWideEmailAddress>();
    private static List<GroupMember> groupMemberList;
    public static Boolean firstRun = true;
    
    //get running user
    public static User getUserInfo()
    {
        system.debug('runningUser1: '+runningUser);
        if(runningUser == null)
        {
            User currentUser = [select id, country, Division, State, TimeZoneSidKey, userRoleID, userRole.name from User where id = :Userinfo.getUserId()];
            runningUser = currentUser;
            system.debug('Limits.getQueries(): '+Limits.getQueries());
        }
        system.debug('runningUser2: '+runningUser);
        return runningUser;
    }
    
    //get Dummy Contact for sending Email.
    public static Contact getContactInfo()
    {
        if(dummyContact == null)
        {
            Contact tempContact;
            try{
                    Id tempContId=Label.Dummy_Contact_Id;
                    //tempContact = [Select id, name, Email From contact where FirstName = 'Dummy' and LastName = 'Contact' and Phone = '789' Limit 1];
                    tempContact = [Select id, name, Email From contact where Id = :tempContId];
                    dummyContact = tempContact;
            }
            catch(System.Queryexception QE){
                    tempContact = null;
                    dummyContact = tempContact;
                    system.debug('In Catch Block');
            }
        }
        system.debug('dummyContact: '+dummyContact);
        return dummyContact;
    }
    
    //get Email Templates for sending email
    public static List<EmailTemplate> getEmailTemplateList(Case caseToSendEmail)
    {
        if(emailTemplateList == null) //&& emailTemplateList.isEmpty())
        {
            List<EmailTemplate> emailList = [Select id, IsActive From EmailTemplate where name = :caseToSendEmail.IME_SC_Email_Template_Name_test__c];
            emailTemplateList = emailList;
        }
        system.debug('emailTemplateList: '+emailTemplateList);
        return emailTemplateList;
    }
    
    //get Businiess Hours for Case
    public static Map<Id, BusinessHours> getBusinessHours()
    {
        if(BusinessHoursIdMap == null)// && BusinessHoursIdMap.isEmpty())
        {
            Map<Id, BusinessHours> BusinessHoursMap = new Map<Id, BusinessHours>([Select Id, IsDefault, WednesdayStartTime, WednesdayEndTime, TuesdayStartTime, TuesdayEndTime,
                                                           ThursdayStartTime, ThursdayEndTime, Name, MondayStartTime, MondayEndTime, TimeZoneSidKey,
                                                           FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime, SundayStartTime, SundayEndTime From BusinessHours]);
            BusinessHoursIdMap = BusinessHoursMap;
            system.debug('BusinessHoursMap.size: '+BusinessHoursMap.size());
        }
        system.debug('BusinessHoursIdMap.size: '+BusinessHoursIdMap.size());
        return BusinessHoursIdMap;
    }
    
    //get Org Wide Address
    public static List<OrgWideEmailAddress> getOrgWideAddress(Case caseOrgAddress)
    {
        if(orgWideAddressList == null)// && orgWideAddressList.isEmpty())
        {
            String orgWideId = 'Iron Mountain Customer Service '+caseOrgAddress.IME_SC_Country_Code__c;
            List<OrgWideEmailAddress> orgAddressList = [Select DisplayName, Address From OrgWideEmailAddress where DisplayName LIKE :orgWideId];
            orgWideAddressList = orgAddressList;
            system.debug('orgAddressList: '+orgAddressList);
            
        }
        system.debug('orgWideAddressList: '+orgWideAddressList);
        return orgWideAddressList;
    }
}
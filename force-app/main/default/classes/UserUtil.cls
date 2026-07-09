/****************************** 
   Developer Name    : Venakteswarlu Avula
   
   Date              : 1/3/2014
   
   Company Name      : Iron Mountain India.
   
   Purpose           : Common class for all User functionality. 
         
   Test Class        : Test_UserUtil
   
   Dependents        : Apex Class:UserUtil
   
   Case Number       : 02069901
                                  
   Case Number       : 02315806 - Change the IM Employee value from New User Id to Created User Id.                               
 ********************************/ 
public class UserUtil
{
    
    @future(callout = true)
    public Static void createCases(Set<String> usrIds)
    {
        RecordType rtype = new RecordType();
        rtype = [Select Id From RecordType  Where SobjectType = 'Case' and name = 'IM Employees Support Case'];
        Group grp = [select Id,Name from Group where Name = 'IMS SSO Fed. Id queue' and Type = 'Queue'];
        system.debug('usrIds----'+usrIds);
        List<User> usrLst = [select Id, FirstName,LastName,IsActive from User where Id IN: usrIds];
        
        List<Case> casLst = new List<Case>();
        system.debug('usrLst----'+usrLst);
            for(User usr : usrLst){
                case cas = new case();
                    cas.Related_To__c = 'Users';
                    cas.Issue__c = 'Create/Deactivate User';
                    cas.Status = 'New';
                    cas.Origin = 'Internal';
                    cas.IM_Division__c = 'IME';
                    cas.Priority = 'Medium';
                    cas.Subject = 'Creation of New User :'+''+usr.FirstName+''+usr.LastName;
                    cas.Description = 'A new user has been created in the Org. Please update the Fedration Id so that they can login and use the system.';
                    cas.RecordTypeId = rtype.id;
                    cas.Case_Category__c = 'Issue';
                    cas.Case_Sub_Category__c = 'User Management';
                    cas.IM_Functional_Group__c = 'Sales Operations';
                    cas.IM_Functional_Sub_Group__c = 'Sales Operations';
                    cas.Sales_Tools_Ranking__c = '2. Medium';
                    /* #8991 Delete 10 case field deletion :- Part 3 "Estimated_Dev_Effort_hrs__c" */
                	//cas.Estimated_Dev_Effort_hrs__c = 1.00;
                    cas.OwnerId = UserInfo.getUserId();
                    //cas.ContactId = '003V000000FZdmd';
                    cas.IM_Employee_Contact__c = UserInfo.getUserId();
                    cas.Hidden_Field__c = True;
                    system.debug('cas----'+cas);
                    system.debug('cas.OwnerId----'+cas.OwnerId);
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    system.debug('dmo----'+dmo.assignmentRuleHeader.useDefaultRule);
                    dmo.assignmentRuleHeader.useDefaultRule = true;
                    cas.setOptions(dmo);
                    casLst.add(cas);
               }
           
         Insert casLst;
    }
    
    @future
    public static void updateUserInfo(String casLst,String casLstNew){  

        List<Case> casToUpdt = null;
        List<Case> casNewToUpdt = null;
        casToUpdt = (List<Case>)JSON.deserialize(casLst, List<Case>.class);
        casNewToUpdt = (List<Case>)JSON.deserialize(casLstNew, List<Case>.class);
        
		if(casToUpdt != null)
         	Update casToUpdt;
        if(casNewToUpdt != null)
         	Update casNewToUpdt;
    }  
}
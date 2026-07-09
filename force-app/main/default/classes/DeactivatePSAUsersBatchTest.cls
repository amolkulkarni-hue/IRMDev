/**
* Class: DeactivatePSAUsersBatchTest
*
* Author: TCS
*
* Purpose: This is a test class for DeactivatePSAUsersBatch
*
* Requirement: GitLab : #26984
*
* Change History:
*
* Developer                     Date                    Description
* -------------------------------------------------------------------------------------------
* Prajna                       29/Oct/2024                test class for DeactivatePSAUsersBatch
*/
@isTest(seeAllData=false)
global class DeactivatePSAUsersBatchTest {
    static Integer offSet = 0;
    
   @testSetup
    static void testSetupData() {
        quoteFieldValidationSetting();
        createIMCountry();
         Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];

        // Insert Profile-level Hierarchy Custom Setting
        Profiles__c profileSetting = new Profiles__c(
            SetupOwnerId = p.Id,
            Allowed__c = true);
        insert profileSetting;
    }
    
    static void testSetupDataFail() {
        quoteFieldValidationSetting();
        createIMCountry();
         Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin' LIMIT 1];

        // Insert Profile-level Hierarchy Custom Setting
        Profiles__c profileSetting = new Profiles__c(
            SetupOwnerId = p.Id,
            Allowed__c = true);
        insert profileSetting;
    }
    
    @isTest static void testDeactivation() {
        //testSetupData();
        List<User> userList = CreateUser(2,false);
        List<User> u4 = [select id,FederationIdentifier,IM_VP__c,SVP__c,DelegatedApproverId from user];
        Test.startTest();
        DeactivatePSAUsersBatch DIUBatch = new DeactivatePSAUsersBatch();
        //Database.executeBatch(new MassUserInactivationBatch(), 1);
        String batch = 'Test Batch Class';
        String chron = '0 0 23 * * ?';        
        // system.schedule('Test Sched', chron, massInactiveUserBatch);
        
        Database.executeBatch(DIUBatch);
        System.schedule(batch,chron,DIUBatch);
        Test.stopTest();
    }
    
   /* @isTest static void testsendDeactivationEmails() {
        
        //List<User> userList = CreateUser(2,false);
        User badUser = [SELECT Id FROM User WHERE Profile.Name='System Administrator' LIMIT 1];
        badUser.IsActive = false;
        badUser.Email = null;
        Test.startTest();
        Database.SaveResult sr = Database.update(badUser, false);
        DeactivatePSAUsersBatch DIUBatch = new DeactivatePSAUsersBatch();
        DIUBatch.sendDeactivationEmails();
        System.assertEquals(false, sr.isSuccess());
        Test.stopTest();
    }*/
    
    /*@isTest static void testremovePackageLicenses() {
      testSetupDataFail();
        List<User> userList = CreateUser(2,false);
        List<Id> userIds = new List<Id>(); 
        for(User u1 : userList)
        {
         userIds.add(u1.Id);
        }
        Test.startTest();
        DeactivatePSAUsersBatch DIUBatch = new DeactivatePSAUsersBatch();
        //DIUBatch.removePackageLicenses(userIds);
        Test.stopTest();
    } */
    
    /***********************************************************************************************************
* Method : CreateUser
* Parameters: Integer
* Return Type: List<User>
* Author : TCS
* Description: Method to create User
**************************************************************************************************************/
    public static List<User> CreateUser(Integer howMany,boolean status) {
        
        DateTime theDate = DateTime.now().addDays(-85);
         DateTime theDate2 = DateTime.now().addDays(-95);

        Profile pfr = [
            SELECT id
            FROM profile
            WHERE name = 'Standard Platform User'
            LIMIT 1
        ];
        
        PackageLicense Pl = [
            SELECT Id
            FROM PackageLicense
            WHERE NamespacePrefix  = 'pse'
            LIMIT 1
        ];        
        
        Set<Id> userSet = new Set<ID>();
        List<User> usrLst = new List<User>();
        offset++;
        User usr1 = new User();
        usr1.alias = 'standt' + offset;
        usr1.email = 'testuser'+ offset +'@example.com';
        usr1.emailencodingkey = 'UTF-8';
        usr1.firstname = 'Testing' + offset;
        usr1.lastname = 'Invalid_1' + offset;
        usr1.languagelocalekey = 'en_US';
        usr1.localesidkey = 'en_US';
        usr1.profileid = pfr.id;
        usr1.timezonesidkey = 'America/Los_Angeles';
        usr1.username = 'hello1.test1' + offset + '@testorg.com';
        usr1.Country = 'USA';
        usr1.MobilePhone = '+1 9999999999';
        usr1.Phone = '9999999999';
        usr1.FederationIdentifier = 'hello1.test1' + offset + '@testorg.com';
        insert usr1;
        Test.setCreatedDate(usr1.ID,theDate);
        
        /*usr1.IsActive = false;
        update usr1;
        usr1.IsActive = true;
        update usr1;*/

        for (Integer i = 1; i < howMany; i++) {
            offset++;
            User usr = new User();
            usr.alias = 'standt' + offset;
            usr.email = 'testuser'+ offset +'@example.com';
            usr.emailencodingkey = 'UTF-8';
            usr.firstname = 'Testing' + offset;
            usr.lastname = 'Invalid_1' + offset;
            usr.languagelocalekey = 'en_US';
            usr.localesidkey = 'en_US';
            usr.profileid = pfr.id;
            usr.timezonesidkey = 'America/Los_Angeles';
            usr.username = 'hello1.test1' + offset + '@testorg.com';
            usr.Country = 'USA';
            usr.MobilePhone = '+1 9999999999';
            usr.Phone = '9999999999';
            usr.DelegatedApproverId = usr1.Id;
            usr.IM_VP__c = usr1.Id;
            usr.SVP__c = usr1.Id;
            usr.FederationIdentifier = 'hello1.test1' + offset + '@testorg.com';
            usrLst.add(usr);
        }
        User usr2 = new User();
        usr2.alias = 'standt' + offset;
        usr2.timezonesidkey = 'America/Los_Angeles';
        usr2.emailencodingkey = 'UTF-8';
        usr2.languagelocalekey = 'en_US';
        usr2.email = 'testuser'+ offset +'@example.com';
        usr2.localesidkey = 'en_US';
        usr2.firstname = 'Testing3' + offset;
        usr2.lastname = 'Invalid_3' + offset;
        usr2.profileid = pfr.id;
        usr2.username = 'hello1.test2' + offset + '@testorg.com';
        usr2.Country = 'USA';
        Insert usr2;
        Test.setCreatedDate(usr1.ID,theDate2);
        
        /*usr2.IsActive = false;
        update usr2;
        usr2.IsActive = true;
        update usr2;*/
        
        User usr3 = new User();
        usr3.alias = 'standt' + offset;
        usr3.emailencodingkey = 'UTF-8';
        usr3.localesidkey = 'en_US';
        usr3.languagelocalekey = 'en_US';
        usr3.timezonesidkey = 'America/Los_Angeles';
        usr3.email = 'testuser@Invalid.com';
        usr3.firstname = 'Testing 4' + offset;
        usr3.lastname = 'Invalid_4' + offset;
        usr3.profileid = pfr.id;
        usr3.username = 'hello1.test3' + offset + '@testorg.com';
        usr3.Country = 'USA';
        usr3.DelegatedApproverId = usr2.Id;
        usr3.IM_VP__c = usr2.Id;
        usr3.SVP__c = usr2.Id;
        insert usr3;
        
        
        
        try {
            if (!usrLst.isEmpty()) {
                Database.saveResult[] sr = database.insert(usrLst, false);
                for (Database.saveResult res : sr) {
                    if (res.isSuccess()) {
                        userSet.add(res.getId());
                       system.debug(res.getId());

                    }
                }
            }
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        usrLst.add(usr2);
        usrLst.add(usr1);
        usrLst.add(usr3);
        
        for(User user : usrLst){
            userPackageLicense userPkgLicense2 = new userPackageLicense(userId = user.Id , PackageLicenseId = Pl.Id );
            Database.saveResult sresult = database.insert(userPkgLicense2, false);
            Test.setCreatedDate(user.ID,theDate2);
            
        }
       
        //85 day notification test
        Test.setCreatedDate(usr1.Id,theDate);
        return usrLst;
    }
    /***********************************************************************************************************
* Method : createIMCountry
* Parameters:
* Return Type:
* Author : TCS
* Description: Method to create IM Country record
**************************************************************************************************************/
    public static void createIMCountry() {
        IM_Country__c country1 = new IM_Country__c(
            Iso31662Code__c = 'IN',
            Iso31663Code__c = 'IND',
            Name = 'India',
            Region__c = 'India'
        );
        IM_Country__c country2 = new IM_Country__c(
            Iso31662Code__c = 'NO',
            Iso31663Code__c = 'NOR',
            Name = 'Norway',
            Region__c = 'Europe'
        );
        
        List<IM_Country__c> countryList2 = new List<IM_Country__c>{
            country1,
                country2
                };
                    
                    }
    
    /***********************************************************************************************************
* Method : quoteFieldValidationSetting
* Parameters:
* Return Type:
* Author : TCS
* Description: Method to create IM Country record
**************************************************************************************************************/
    public static void quoteFieldValidationSetting() {
        QTB_Quote_Field_Validations__c fieldCust = new QTB_Quote_Field_Validations__c();
        fieldCust.QTB_Field_List__c = 'QTB_Minimum_Charges_Start_Date__c,QTB_Work_Order_Minimum_Start_Date__c,QTB_Invoice_Minimum_Start_Date__c,QTB_Free_Up_Start__c,QTB_Free_Products_Start_Date__c';
        fieldCust.Name = 'Date field names';
        fieldCust.QTB_Delta_Fields__c = 'QTB_Delta_Minimum_StartDate__c,QTB_Delta_Work_Order_StartDate__c,QTB_Delta_Invoice_Minimum_StartDate__c,QTB_Delta_Free_Up_StartDate__c,QTB_Delta_Free_Products_StartDate__c';
        fieldCust.QTB_Restrict_on_Accepted_Quote__c = 'QTB_Minimum_Charges_Start_Date__c,QTB_Work_Order_Minimum_Start_Date__c,QTB_Invoice_Minimum_Start_Date__c,QTB_Free_Up_Start__c,QTB_Free_Products_Start_Date__c,SBQQ__StartDate__c,SBQQ__Primary__c';
        insert fieldCust;
    }
}
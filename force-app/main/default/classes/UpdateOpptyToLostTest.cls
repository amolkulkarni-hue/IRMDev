@isTest
public class UpdateOpptyToLostTest {
    
   @Testsetup static void setup(){
        List<Opportunity> opptys = new List<Opportunity>();
        Date close = Date.today().addDays(-33);
        User user=[select id from user where Profile.Name='IM_Custom Sys Admin'and UserRole.name='Iron MTN Admin' and isActive=true limit 1];
        System.runAs(user)
        {
            String[] stage=new String[]{'2 - Solution Developed','3 - Solution Agreed'};
                
                //Custom setting: Adding UpdateOpptyStageToLost__c data   
            UpdateOpptyStageToLost__c closeDateNRole=new UpdateOpptyStageToLost__c();
            closeDateNRole.Name='Iron MTN Admin';
            closeDateNRole.DaysInThePast__c=30;
            closeDateNRole.RoleId__c='00E800000017xZdEAI';
          
            insert closeDateNRole;
            System.debug('closeDateNRole:' +closeDateNRole.RoleId__c);
            //Custom Setting: Adding Country_Settings__c data
            List<Country_Settings__c> countrySetting = new List<Country_Settings__c>();
            Country_Settings__c cS = new Country_Settings__c();
            cS.Name = 'Canada';
            cS.Object_Name__c = 'Account';
            countrySetting.add(cS);
            
            Country_Settings__c cS1 = new Country_Settings__c();
            cS1.Name = 'United States';
            cS1.Object_Name__c = 'Account';
            countrySetting.add(cS1);
            
            insert countrySetting;
            
            //Custom Setting: Adding OpportunityProductSelection__c data
            List<OpportunityProductSelection__c> PS=new List<OpportunityProductSelection__c>();
            OpportunityProductSelection__c ps1=new OpportunityProductSelection__c();
            ps1.Name='CloudSolutionsProduct';
            ps1.Product_Class_Name__c='Data Backup and Recovery';
            ps1.Product_Line_Name__c='Cloud Solutions';
            PS.add(ps1);
            insert PS;
            
            //Custom Setting: Adding SVStatus__c data 
            List<SVStatus__c> sv=new List<SVStatus__c>();
            SVStatus__c sv1=new SVStatus__c();
            sv1.Name='SVStatusPassed';
            sv1.Amount__c=2400;
            sv1.OpptType__c='New Deal,Up-Sell';
            sv1.Stage__c='6 - Setup';
            sv.add(sv1);
            insert sv;
            
            System.debug('Queries used Before account insert:'+Limits.getQueries());
            Account acc=TestingUtils.createAccounts(1,true).get(0);
            System.debug('Queries used After account insert: '+Limits.getQueries());
            
            System.debug('Queries used Before Contact insert: '+Limits.getQueries());  
            contact cont=TestingUtils.createContact(acc.id, true);
            System.debug('Queries used After Contact insert: '+Limits.getQueries());

            Profile p = [Select id from profile where name = 'IM_Custom Sys Admin']; 
            IM_Country__c cntry=[select id from IM_Country__c where name='United States' limit 1];
            
            User us = new User(alias = 'test', email='testuser@roletest1.com',
                               emailencodingkey='UTF-8',lastname='TestingUpdateOppty', languagelocalekey='en_US',
                               localesidkey='en_US', profileid =p.id,timezonesidkey='America/Los_Angeles',
                               username='test@userAk.com',Country = 'United States',ISACTIVE=true);
            insert us;
            Id StandardOpptyRecordtype = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();

            System.debug('Queries used Before Opportunities insert: '+Limits.getQueries());
            List<Opportunity> TestOpportunities=TestingUtils.createOpportunities(null,acc.id,true,2,StandardOpptyRecordtype);
            
            System.debug('Queries used After Opportunities insert: '+Limits.getQueries());
			system.debug('setup completed');
            }
        }
    
    @isTest
    static void testScheduledJob() {
        System.debug('Entered test method');
        
        // Setup test environment for scheduled job
        String CRON_EXP = '0 0 0 ? * * *';
        
        UpdateOpptyStageToLost__c custSettingData = [SELECT Id, RoleId__c, DaysInThePast__c FROM UpdateOpptyStageToLost__c LIMIT 1];
        Date close = System.today() - custSettingData.DaysInThePast__c.intValue() - 2920;
        List<Opportunity> OpptyList = [SELECT Id, OwnerId, Owner.UserRoleId, StageName, CloseDate FROM Opportunity];
        system.debug('OpptyList:' +OpptyList);
        User u = [SELECT Id FROM User WHERE Profile.Name = 'IM_Custom Sys Admin' 
                     AND UserRole.Name = 'Iron MTN Admin' 
                     AND IsActive = TRUE 
                     LIMIT 1];
        system.debug('Userid:' +u);
        Contact cont = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        
        // Prepare OpportunityContactRole and Opportunities to update
        List<OpportunityContactRole> OCRList = new List<OpportunityContactRole>();
        List<Opportunity> toUpdate = new List<Opportunity>();
        
        for(Opportunity o : OpptyList) { 
            OpportunityContactRole OCR = new OpportunityContactRole(OpportunityId = o.Id, ContactId = cont.Id, Role = 'Business User');
            OCRList.add(OCR);
            
             System.debug('Opportunity Id: ' + o.Id + ' | Close Date: ' + o.CloseDate + ' | Stage Name: ' + o.StageName);
     

            o.StageName = '2 - Solution Developed';
            o.CloseDate = close;
            o.OwnerId = u.Id;
            toUpdate.add(o);
        }

        // Insert OpportunityContactRole and update Opportunities
        insert OCRList;
        update toUpdate;

         System.debug('ootyroleid:'+ toUpdate);
        // Schedule the job and start the test
        String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new UpdateOpptyToLost());
        Test.stopTest();
        
        // Verify the batch job status and validate the results
        AsyncApexJob aJob = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'UpdateOpptyToLost'];

        if(aJob.Status == 'Completed') {
            List<Opportunity> OpptyListAfter = [SELECT Id, OwnerId, Owner.UserRoleId, StageName, CloseDate 
                                                FROM Opportunity WHERE IsClosed = TRUE AND CloseDate < :close];
            System.debug(OpptyListAfter.size());
            
            // Assert that 2 Opportunities are marked as Lost
            System.assertEquals(2, OpptyListAfter.size(), 'Two opportunities should be updated to Lost stage');
            System.assertEquals(2, Limits.getEmailInvocations(), 'There should be 2 email invocations');
        }
    }
    
     @isTest
    static void testExecuteWithExceptionFromCustomSetting() {
      

User testUser = [SELECT Id FROM User WHERE Profile.Name = 'IM_Custom Sys Admin' 
                     AND UserRole.Name = 'Iron MTN Admin' 
                     AND IsActive = TRUE 
                     LIMIT 1];
        // Create a custom setting record that will cause an error (e.g., null value where not expected)
        UpdateOpptyStageToLost__c settingWithError = new UpdateOpptyStageToLost__c();
        settingWithError.Name = 'SMB_Lost_Rule_Error';
        settingWithError.DaysInThePast__c = null;
        settingWithError.RoleId__c = '00E80000001XNJYEA4';
        insert settingWithError;
        
         Test.startTest();
        // Create a test opportunity that will trigger this setting
        Opportunity errorOpportunity = new Opportunity(
            Name = 'Error Opportunity',
            OwnerId = testUser.Id,
            StageName = '1 - Qualification',
            CloseDate = Date.today().addDays(-40)
        );
        insert errorOpportunity;

        String sch = '0 0 0 * * ?';
        UpdateOpptyToLost scheduler = new UpdateOpptyToLost();
        System.schedule('ExceptionJob', sch, scheduler);
        Test.stopTest();

    // Verify the batch job status and validate the results
       
        List<ApexLog> logs = [SELECT LogUser.Name, LogLength, Status FROM ApexLog WHERE
                              LogUser.Id = :UserInfo.getUserId() ORDER BY Status DESC LIMIT 10];
        for (ApexLog log : logs) {
            System.debug('Apex Log: '+ log.Status);
            // You could parse the log content (if needed and if your ExceptionLogger does logging)
        }
    }
    }
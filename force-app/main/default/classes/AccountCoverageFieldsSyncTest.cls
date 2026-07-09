/*Tets class for AccountCoverageFieldsSync*/
@isTest
private class AccountCoverageFieldsSyncTest {

    static Profile p = [select id from profile where name='Standard User' limit 1];
    static List<Account> testAccounts = new List<Account>();  
   
    @testSetup
    static void setup(){
        User u=TestingUtils.createUser('Test',True);
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
          IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country; 
        
        Account IMGAAcc = new Account(Name = 'IMGA Test',recordtypeid=TestingUtils.IMGA_ACCOUNT_RECORD_TYPE.id,IM_Hierarchy_Level__c='IM Group (IMGA)',
                                      BillingCountry='United States',Global_IMGA_Owner__c=u.Id,IM_Industry__c='Legal',Sector__c='Business Services');
        insert IMGAAcc;
        Account cpOverrideTrue = new Account(Name = 'CP Test1',IM_Hierarchy_Level__c='Country Parent',ParentId=IMGAAcc.Id,
                               BillingCountry='United States',Global_IMGA_Owner__c=u.Id,Industry_Override__c=True);
        insert cpOverrideTrue;
        Account cpOverrideFalse = new Account(Name = 'CP Test2',IM_Hierarchy_Level__c='Country Parent',ParentId=IMGAAcc.Id,
                               BillingCountry='United States',Global_IMGA_Owner__c=u.Id,Industry_Override__c=False);
        insert cpOverrideFalse;
            for(Integer i=0; i<25; i++){
            Account ac1 = new Account(Name = 'AccountCoverageFieldsSyncFalse ' + i,ParentId=cpOverrideFalse.id,IM_Hierarchy_Level__c='Sales (Site)',BillingCountry='United States');
            
            testAccounts.add(ac1);
        	}
        	for(Integer i=0; i<25; i++){
            Account ac2 = new Account(Name = 'AccountCoverageFieldsSyncTrue ' + i,ParentId=cpOverrideTrue.id,IM_Hierarchy_Level__c='Sales (Site)',BillingCountry='United States');
            
            testAccounts.add(ac2);
        	}
        insert testAccounts;
        
        //AccountCoverageFieldsSync__c fieldMap=new AccountCoverageFieldsSync__c(Name='MD',from_field__c='Global_IMGA_Owner_Formula__c',to_field__c='Global_IMGA_Owner__c');
        //insert fieldMap;
        List<AccountCoverageFieldsSync__c> settings = new List<AccountCoverageFieldsSync__c>{
            new AccountCoverageFieldsSync__c(
                Name = 'Industry',
                from_field__c ='Industry_Formula__c',
                to_field__c= 'IM_Industry__c'
            ),
            new AccountCoverageFieldsSync__c(
                Name = 'Sector',
                from_field__c ='Sector_Formula__c',
                to_field__c= 'Sector__c'
            ),
                new AccountCoverageFieldsSync__c(
                Name = 'Industry Override',
                from_field__c ='Industry_Override_formula__c',
                to_field__c= 'Industry_Override__c'
            ),
            new AccountCoverageFieldsSync__c(
                Name = 'Global Managing Director',
                from_field__c ='Global_IMGA_Owner_Formula__c',
                to_field__c= 'Global_IMGA_Owner__c'
            )              
        };
        insert settings;
    }       


    static testMethod void runTest() {       
        
        Test.startTest();        
        
        String query = 'Select id from account where (AccountCoverageUpdated1__c =true or AccountCoverageUpdated2__c=true or Sync_fields__c=True) and  IM_Hierarchy_Level__c in (\'Sales (Site)\',\'Country Parent\')';
        AccountCoverageFieldsSync job = new AccountCoverageFieldsSync(query);
        Id jobId = Database.executeBatch(job);
        AccountCoverageFieldValuesScheduler jobSchd = new AccountCoverageFieldValuesScheduler();
        DateTime objdatetime = datetime.now().addminutes(1);

        string CRON_EXP ='';
        CRON_EXP += objdatetime.Second();
        CRON_EXP += ' ' + objdatetime.minute();
        CRON_EXP += ' ' + objdatetime.hour();
        CRON_EXP += ' ' + objdatetime.day();
        CRON_EXP += ' ' + objdatetime.month();
        CRON_EXP += ' ' +'?';
        CRON_EXP += ' ' + objdatetime.year();
        
        String schJobId = System.schedule('testScheduledApex',CRON_EXP , jobSchd);         
        
        Test.stopTest();
        
        List<Account> AfterUpdate = [select id,name,Global_IMGA_Owner_Formula__c,Global_IMGA_Owner__c,Sector__c,IM_Industry__c,Sector_Formula__c,Industry_Formula__c, Industry_Override__c,IM_Hierarchy_Level__c,Industry_Override_formula__c from Account];
	
        for(Account acc: AfterUpdate){
            System.assertEquals(acc.Global_IMGA_Owner__c,acc.Global_IMGA_Owner_Formula__c);
            if(acc.Industry_Override__c == True){
                System.assertEquals(null, acc.Sector__c, 'Sector must NOT copy when override is True');
        		System.assertEquals(null, acc.IM_Industry__c, 'Industry must NOT copy when override is True');
            }
            if(acc.Industry_Override__c == False && acc.IM_Hierarchy_Level__c == 'Country Parent'){
                System.assertEquals('Business Services' , acc.Sector__c, 'Sector should copy when override is False');
        		System.assertEquals('Legal' , acc.IM_Industry__c, 'Industry should copy when override is False');
            }
            if(acc.IM_Hierarchy_Level__c == 'Sales (Site)'){
				System.assertEquals(acc.Industry_Override__c,acc.Industry_Override_formula__c);  
            }
        }
        
        AsyncApexJob jobActual = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                            from AsyncApexJob where Id = :jobId];
        System.assertEquals('Completed',jobActual.Status, 'Scheduler must run batch successfully');
        System.assertEquals(jobActual.TotalJobItems, 1);
        System.assertEquals(jobActual.JobItemsProcessed, 1);
        System.assertEquals(jobActual.NumberOfErrors, 0);
        System.assertEquals(jobActual.Status, 'Completed');        
        
    }
}
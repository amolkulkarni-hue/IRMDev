@isTest 
public class Test_UtilUpdateSladaysAndSlaTargetDate{
    static testMethod void testMethod1() {
        Lead testLead;
        // insert Country_Settings__c
        Country_Settings__c testCs = new Country_Settings__c(name='United States', Object_Name__c = 'Account');
        insert testCs;
        //insert OpportunityProductSelection__c 
        OpportunityProductSelection__c testOps = new OpportunityProductSelection__c (Name='CloudSolutionsProduct', Product_Class_Name__c='Data Backup and Recovery',Product_Line_Name__c='Cloud Solutions');
        insert testOps;
        //insert Account
        Account testAccount = new Account();
        testAccount = TestingUtils.createAccounts ( 1, true)[0];
        //insert contact
        Contact testContact = new Contact();
        testContact = TestingUtils.createContact(testAccount.id,true);
        //insert Opportunity
        
        Opportunity testOpp = new Opportunity();
        string name = 'testOpp';
        testOpp = TestingUtils.createOpportunity(name,testAccount.Id,true);
        //insert Holiday
        Holiday__c hD = new Holiday__c();
            hD.Country__c = 'india';
            hD.CurrencyIsoCode = 'USD';
        insert hD;
        //insert Holiday schedule
        Holiday_Schedule__c hS = new Holiday_Schedule__c();
        hS.CurrencyIsoCode = 'USD';
        insert hS;
        //insert Holiday schedule Line
        Holiday_Schedule_Line__c hSL = new Holiday_Schedule_Line__c();
            hSL.Holiday__c =hD.Id;
            hSL.CurrencyIsoCode = 'USD';
            hSL.Holiday__c =hD.Id;
            hSL.Holiday_Schedule__c = hS.Id;
            insert hSL;
        List<Holiday_Schedule_Line__c> listHoliScheLine = new List<Holiday_Schedule_Line__c>();
        Holiday_Schedule_Line__c hSL1 = new Holiday_Schedule_Line__c();
            hSL1.Holiday__c =hD.Id;
            hSL1.CurrencyIsoCode = 'EUR';
            hSL1.Holiday__c =hD.Id;
            hSL1.Holiday_Schedule__c = hS.Id;
            insert hSL1;
        listHoliScheLine.add(hSL);
        listHoliScheLine.add(hSL1);
        /*for(integer i =0 ; i< 5 ; i++){
            //Date dtt = Date.today();
            //hSL.Holiday_Date__c = dtt.addDays(i);
            hSL.Holiday__c =hD.Id;
            hSL.CurrencyIsoCode = 'USD';
            hSL.Holiday__c =hD.Id;
            hSL.Holiday_Schedule__c = hS.Id;
            listHoliScheLine.add(hSL);
        }*/
        
        //insert listHoliScheLine;
        //insert Time Zone
        Time_Zone__c tZ = new Time_Zone__c();
        tZ.Name = 'MOUNTAIN STANDARD TIME';
        tZ.CurrencyIsoCode = 'USD';
        //insert Off set hour
        tZ.Off_Set_Hours__c = '-5';
            insert tZ;
        //insert market
        Market__c testMarket = new Market__c( name= 'testMarket' ,Time_Zone__c = tZ.Id ,Holiday_Schedule__c = hS.id);
        insert testMarket;
        //insert Customer Account
        IM_Customer_Account__c testcustomeraccount = new IM_Customer_Account__c(Name='Test12',Owning_District_Id__c =testMarket.Id,Source_System__c='SKP NA',IM_Account__c=testAccount.Id,IM_Status__c='Active',NA_CY_YTD_Film_Sound__c=10,NA_PY_YTD_Secure_Shredding__c=10);
            insert testcustomeraccount;

        //update testcustomeraccount;
        Division__c d = new Division__c();
            d.CurrencyIsoCode ='USD';
            insert d;
        Service_Location__c Slocation = new Service_Location__c();
            Slocation.Customer_Id__c = testcustomeraccount.Id;
            Slocation.CurrencyIsoCode =  'USD';
            Slocation.Svc_District_Id__c = testMarket.Id;
            //Slocation.Division= d.id;
            insert Slocation;
         
        //insert case
        integer count = 10;
        List<case> testCase = new List<case>();
        testCase = TestingUtils.createCases(count,testOpp,testContact,false);
        List<case> tempCaseList = new List<case>();
        for(Case ca : testCase){
            ca.Customer_ID__c = testcustomeraccount.id;
            ca.Service_Location__c = Slocation.Id;
            double dd = 12;
            ca.SLA_Days__c = dd;
            ca.Initial_Due_Date__c = date.today();
            ca.SLA_Target_Date__c = system.now();
            //ca.CreatedDate = system.now();
            
            tempCaseList.add(ca);
            
        }
        insert tempCaseList;
        UtilUpdateSladaysAndSlaTargetDate.GetCaseCustomerAccountAndHolidaySchedule(tempCaseList);
        List<case> caseList = [select id,Customer_ID__c,Service_Location__c,CreatedDate,SLA_Days__c FROM case where id in:tempCaseList];
        UtilUpdateSladaysAndSlaTargetDate.getSlaTargetDateForCases(caseList, true);
        UtilUpdateSladaysAndSlaTargetDate.isInitialDueDateOnHoliday(tempCaseList[0]);
        UtilUpdateSladaysAndSlaTargetDate.GetSlaTargetDateForClonedCase(tempCaseList);
        UtilUpdateSladaysAndSlaTargetDate.GetSlaTargetDateForClonedCase(tempCaseList[0]);
        double slaD = 5;
        DateTime createD = system.now();
        UtilUpdateSladaysAndSlaTargetDate.getSlaTargetDateForSingleCase(tempCaseList[0], slaD, createD);
        string tName = 'America/New_York';
        UtilUpdateSladaysAndSlaTargetDate.GetCaseCreatorTimeZone(tName);
        UtilUpdateSladaysAndSlaTargetDate.getLastWorkingDay(createD,listHoliScheLine);
    }
    static testMethod void testMethod2() {
        string tName = 'Pacific/Chatham';
        UtilUpdateSladaysAndSlaTargetDate.GetCaseCreatorTimeZone(tName);
    }
}
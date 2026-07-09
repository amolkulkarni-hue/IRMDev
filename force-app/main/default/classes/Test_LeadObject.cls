/*Developer Name: Madhu Paladugu
Company       : TheCloudFountain Inc.
Desrciption   : Test utility for LeadObject Trigger. 
Date          : 12/4/12
case number   : 00924109  




*/

@isTest(SeeAllData=false)
public class Test_LeadObject{
    @TestSetup
static void createTestData() {
    Account acc = TestingUtils.createAccounts(1,true)[0];
    Contact cont = TestingUtils.createContact(acc.id, true);
}
   public static testmethod void dotest(){
      











        test.startTest();
        List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
        Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
        tA.name = 'StageUpdateAfterConvert';
        tA.Object__c = 'Lead';
        tA.Trigger__c = 'StageUpdateAfterConvert';
        tA.Value__c = 'True';
        custSettingList.add(tA);
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'PopulateOriginalLeadOwner';
        tA1.Object__c = 'Lead';
        tA1.Trigger__c = 'PopulateOriginalLeadOwner';
        tA1.Value__c = 'True';
        custSettingList.add(tA1);
        
        Trigger_Activation_Settings__c tA2 = new Trigger_Activation_Settings__c();
        tA2.name = 'UpdateLeadOwnerEmailTrigger';
        tA2.Object__c = 'Lead';
        tA2.Trigger__c = 'UpdateLeadOwnerEmailTrigger';
        tA2.Value__c = 'True';
        custSettingList.add(tA2);
        
        Trigger_Activation_Settings__c tA3 = new Trigger_Activation_Settings__c();
        tA3.name = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Object__c = 'Lead';
        tA3.Trigger__c = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Value__c = 'True';
        custSettingList.add(tA3);    
        
        
        Trigger_Activation_Settings__c tA5 = new Trigger_Activation_Settings__c();
        tA5.name = 'RelatedContactupdate';
        tA5.Object__c = 'Lead';
        tA5.Trigger__c = 'RelatedContactupdate';
        tA5.Value__c = 'True';
        custSettingList.add(tA5);
        
        
        Trigger_Activation_Settings__c tA7 = new Trigger_Activation_Settings__c();
        tA7.name = 'LeadCountryLookup';
        tA7.Object__c = 'Lead';
        tA7.Trigger__c = 'LeadCountryLookup';
        tA7.Value__c = 'True';
        custSettingList.add(tA7);
        
        Trigger_Activation_Settings__c tA8 = new Trigger_Activation_Settings__c();
        tA8.name = 'reassignLeads';
        tA8.Object__c = 'Lead';
        tA8.Trigger__c = 'reassignLeads';
        tA8.Value__c = 'True';
        custSettingList.add(tA8);
        
        Trigger_Activation_Settings__c tA9 = new Trigger_Activation_Settings__c();
        tA9.name = 'LeadRouting';
        tA9.Object__c = 'Lead';
        tA9.Trigger__c = 'LeadRouting';
        tA9.Value__c = 'True';
        custSettingList.add(tA9);
        
        Trigger_Activation_Settings__c tA10 = new Trigger_Activation_Settings__c();
        tA10.name = 'Update_LastNonQueueOnr_on_Owner_Update';
        tA10.Object__c = 'Lead';
        tA10.Trigger__c = 'Update_LastNonQueueOnr_on_Owner_Update';
        tA10.Value__c = 'True';
        custSettingList.add(tA10);
       
        Trigger_Activation_Settings__c tA11 = new Trigger_Activation_Settings__c();
        tA11.name = 'RelatedAccountupdate';
        tA11.Object__c = 'Lead';
        tA11.Trigger__c = 'RelatedAccountupdate';
        tA11.Value__c = 'True';
        custSettingList.add(tA11);
        
        insert custSettingList;
        
        String usrId = UserInfo.getUserId();

































        
        //new code
        Lead myLead = new Lead(firstname='test',LastName = 'Fry',Status='open', Company='Fry And Sons',
                               Email='test.test@ironmountain.com',Division='02d8000000000kT',IsConverted=false,
                               OwnerId=usrId);
        insert myLead; 
        
        //myLead.IsConverted=true;
        myLead.OwnerId=usrId;
        myLead.Email='invalid.paladugu@ironmountain.com';
        myLead.IM_Lead_Stage__c = '2-Marketing Qual';
        myLead.IM_Industry__c='Banking';
        update myLead;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(myLead.id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        //Database.LeadConvertResult lcr = Database.convertLead(lc);
        //System.assert(lcr.isSuccess());   
        test.stopTest();

    }
    
    static testMethod void Test_UpdateLeadOwnerEmailTrigger1(){
    
		test.startTest();
        List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();        











        List<Lead_Routing_Settings__c> custRoute = new List<Lead_Routing_Settings__c>();
        Lead_Routing_Settings__c lrc= new Lead_Routing_Settings__c();
        
        lrc.Name = 'For DPR Product Interest';
        lrc.Account_User_Lookup__c = 'IMGA_Owner_DB_R__r';
        lrc.Assigned_Owner_Lookup__c='IM_RSM__r.ADA__c';
        lrc.Lead_Country__c='United States,Canada';
        lrc.Lead_RecordType_Name__c='Standard Lead,IMAP Lead';
        lrc.Lead_Source__c='Inbound NBI,Online Display Advertising,NA - Customer Service Lead,Referral,Click to Call,Contact Us Form,Search Advertising';
        lrc.Product_Interest__c   ='Data Protection & Recovery,Custom Solutions';
        custRoute.add(lrc);
        
        lrc= new Lead_Routing_Settings__c();           
        lrc.Name = 'For Non DPR Product Interest';
        lrc.Account_User_Lookup__c =  'IMGA_Owner__r';
        lrc.Assigned_Owner_Lookup__c='IM_RSM__r.ADA__c';
        lrc.Lead_Country__c='United States,Canada';
        lrc.Lead_RecordType_Name__c='Standard Lead';
        lrc.Lead_Source__c='Inbound NBI,Online Display Advertising,NA - Customer Service Lead,Referral,Click to Call,Contact Us Form,Search Advertising';
        lrc.Product_Interest__c    ='Non DPR';
        custRoute.add(lrc);
        
        insert custRoute;
                

        List<Lead_Owner_Eligible_for_Reassignment__c> loe = new List<Lead_Owner_Eligible_for_Reassignment__c>();
        Lead_Owner_Eligible_for_Reassignment__c loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Disqualified';
        loeRec.Lead_OwnerId__c = '00G80000001rLbV';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        
        loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Duplicates';
        loeRec.Lead_OwnerId__c = '00G80000001rLSx';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        
        loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Marketing Expired';
        loeRec.Lead_OwnerId__c = '00G800000023vgn';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        
        loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Nurture';
        loeRec.Lead_OwnerId__c = '00G80000001pIrU';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        insert loe;
        
        Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
        tA.name = 'StageUpdateAfterConvert';
        tA.Object__c = 'Lead';
        tA.Trigger__c = 'StageUpdateAfterConvert';
        tA.Value__c = 'True';
        custSettingList.add(tA);
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'PopulateOriginalLeadOwner';
        tA1.Object__c = 'Lead';
        tA1.Trigger__c = 'PopulateOriginalLeadOwner';
        tA1.Value__c = 'True';
        custSettingList.add(tA1);
        
        Trigger_Activation_Settings__c tA2 = new Trigger_Activation_Settings__c();
        tA2.name = 'UpdateLeadOwnerEmailTrigger';
        tA2.Object__c = 'Lead';
        tA2.Trigger__c = 'UpdateLeadOwnerEmailTrigger';
        tA2.Value__c = 'True';
        custSettingList.add(tA2);
        
        Trigger_Activation_Settings__c tA3 = new Trigger_Activation_Settings__c();
        tA3.name = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Object__c = 'Lead';
        tA3.Trigger__c = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Value__c = 'True';
        custSettingList.add(tA3);    
                

        Trigger_Activation_Settings__c tA5 = new Trigger_Activation_Settings__c();
        tA5.name = 'RelatedContactupdate';
        tA5.Object__c = 'Lead';
        tA5.Trigger__c = 'RelatedContactupdate';
        tA5.Value__c = 'True';
        custSettingList.add(tA5);
                

        Trigger_Activation_Settings__c tA7 = new Trigger_Activation_Settings__c();
        tA7.name = 'LeadCountryLookup';
        tA7.Object__c = 'Lead';
        tA7.Trigger__c = 'LeadCountryLookup';
        tA7.Value__c = 'True';
        custSettingList.add(tA7);
        
        Trigger_Activation_Settings__c tA8 = new Trigger_Activation_Settings__c();
        tA8.name = 'reassignLeads';
        tA8.Object__c = 'Lead';
        tA8.Trigger__c = 'reassignLeads';
        tA8.Value__c = 'True';
        custSettingList.add(tA8);
        
        Trigger_Activation_Settings__c tA9 = new Trigger_Activation_Settings__c();
        tA9.name = 'LeadRouting';
        tA9.Object__c = 'Lead';
        tA9.Trigger__c = 'LeadRouting';
        tA9.Value__c = 'True';
        custSettingList.add(tA9);
        
        Trigger_Activation_Settings__c tA10 = new Trigger_Activation_Settings__c();
        tA10.name = 'Update_LastNonQueueOnr_on_Owner_Update';
        tA10.Object__c = 'Lead';
        tA10.Trigger__c = 'Update_LastNonQueueOnr_on_Owner_Update';
        tA10.Value__c = 'True';
        custSettingList.add(tA10);
        
        Trigger_Activation_Settings__c tA11 = new Trigger_Activation_Settings__c();
        tA11.name = 'RelatedAccountupdate';
        tA11.Object__c = 'Lead';
        tA11.Trigger__c = 'RelatedAccountupdate';
        tA11.Value__c = 'True';
        custSettingList.add(tA11);
        
        insert custSettingList; 
        
        list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'Standard User'];
        
        User us1=new user();        
        us1.FirstName = 'Test';
        us1.LastName = 'User';
        us1.Email = 'Test@ironmountain.com';
        us1.Username = 'Test.User1@ironmountain.com';
        us1.Sales_Division__c='North America';
        us1.DefaultDivision ='02d8000000000kT';
        us1.Alias ='Test909';
        us1.CommunityNickname = 't909';
        us1.TimeZoneSidKey ='America/New_York';
        us1.LocaleSidKey = 'en_US';
        us1.EmailEncodingKey = 'UTF-8';
        us1.ProfileId = p1[0].id;
        us1.LanguageLocaleKey = 'en_US';
        us1.Country = 'United States';
        insert us1;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c();
        IM_Country__c  r = new IM_Country__c();
        r.Iso31662Code__c ='US';
        r.Iso31663Code__c ='USA';
        r.Name ='United States';
        r.Region__c ='North America';
        insert r;
        country.IM_Country__c = r.id;
        country.Alternative_Name__c = 'United States';
        insert country;
        
		us1.Sales_Division__c='North America';
        update us1;
                
        Account A = new Account(name='AccountPratapTestMethod'+system.now(),
                                BillingCountry='United States', 
                                IMGA_Owner__c = us1.id, D_B_DUNS__c ='Test');
        insert A;
        Lead led1=new Lead();
        led1.FirstName='test1';
        led1.Email='madhu.paladugu@ironmountain.com';
        led1.Country = 'United States';
        led1.IsConverted=false;
        led1.Company='Test';
        led1.LastName='paladugu';
        led1.OwnerId=us1.Id;
        led1.LeadSource='Online Display Advertising';//'Manual';
        led1.Status='open';
        led1.IM_Lead_Stage__c='1-Inquiry';       
        led1.DUNs_Number__c ='Test';
        led1.Product_Interest__c ='Non DPR1';
        led1.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId();
        insert led1;
        
        RecordType comprt = [Select Name, Id From RecordType where sObjectType='Competitor__c' and Name = 'Competitors'];
        Competitor__c compt = new Competitor__c();
        compt.Name = 'BlahBlah';
        compt.RecordTypeid = comprt.id;
        insert compt;
        
        Lead_Competitor__c ledcompt = new Lead_Competitor__c();
        ledcompt.Lead__c = led1.id;
        ledcompt.Competitor__c = compt.id;
        ledcompt.Lead_Owner_Email__c = 'Test@ironmountain.com';
        insert ledcompt;
        


        ledcompt.Lead_Owner_Email__c = '';
        update ledcompt;
        
        led1.Status = 'New Activity'; 
        led1.IM_Lead_Stage__c = '2-Marketing Qual';
        led1.IM_Stage_2_Entered_Date__c = system.today();
        update led1;
        test.stopTest();    
    }
    
   static testMethod void Test_UpdateLeadOwnerEmailTrigger2(){
                      
        //list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'Standard User'];        
        test.startTest();
        
       List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
       
       List<Lead_Routing_Settings__c> custRoute = new List<Lead_Routing_Settings__c>();
        Lead_Routing_Settings__c lrc= new Lead_Routing_Settings__c();
        
        lrc.Name = 'For DPR Product Interest';
        lrc.Account_User_Lookup__c = 'IMGA_Owner_DB_R__r';
        lrc.Assigned_Owner_Lookup__c='IM_RSM__r.ADA__c';
        lrc.Lead_Country__c='United States,Canada';
        lrc.Lead_RecordType_Name__c='Standard Lead,IMAP Lead';
        lrc.Lead_Source__c='Inbound NBI,Online Display Advertising,NA - Customer Service Lead,Referral,Click to Call,Contact Us Form,Search Advertising';
        lrc.Product_Interest__c   ='Data Protection & Recovery,Custom Solutions';
        custRoute.add(lrc);
        
        lrc= new Lead_Routing_Settings__c();           
        lrc.Name = 'For Non DPR Product Interest';
        lrc.Account_User_Lookup__c =  'IMGA_Owner__r';
        lrc.Assigned_Owner_Lookup__c='IM_RSM__r.ADA__c';
        lrc.Lead_Country__c='United States,Canada';
        lrc.Lead_RecordType_Name__c='Standard Lead';
        lrc.Lead_Source__c='Inbound NBI,Online Display Advertising,NA - Customer Service Lead,Referral,Click to Call,Contact Us Form,Search Advertising';
        lrc.Product_Interest__c    ='Non DPR';
        custRoute.add(lrc);
        
        insert custRoute;
        
        List<Lead_Owner_Eligible_for_Reassignment__c> loe = new List<Lead_Owner_Eligible_for_Reassignment__c>();
        Lead_Owner_Eligible_for_Reassignment__c loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Disqualified';
        loeRec.Lead_OwnerId__c = '00G80000001rLbV';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        
        loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Duplicates';
        loeRec.Lead_OwnerId__c = '00G80000001rLSx';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        
        loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Marketing Expired';
        loeRec.Lead_OwnerId__c = '00G800000023vgn';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        
        loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Nurture';
        loeRec.Lead_OwnerId__c = '00G80000001pIrU';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        insert loe;
        
        Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
        tA.name = 'StageUpdateAfterConvert';
        tA.Object__c = 'Lead';
        tA.Trigger__c = 'StageUpdateAfterConvert';
        tA.Value__c = 'True';
        custSettingList.add(tA);
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'PopulateOriginalLeadOwner';
        tA1.Object__c = 'Lead';
        tA1.Trigger__c = 'PopulateOriginalLeadOwner';
        tA1.Value__c = 'True';
        custSettingList.add(tA1);
        
        Trigger_Activation_Settings__c tA2 = new Trigger_Activation_Settings__c();
        tA2.name = 'UpdateLeadOwnerEmailTrigger';
        tA2.Object__c = 'Lead';
        tA2.Trigger__c = 'UpdateLeadOwnerEmailTrigger';
        tA2.Value__c = 'True';
        custSettingList.add(tA2);
        
        Trigger_Activation_Settings__c tA3 = new Trigger_Activation_Settings__c();
        tA3.name = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Object__c = 'Lead';
        tA3.Trigger__c = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Value__c = 'True';
        custSettingList.add(tA3);    
                
        Trigger_Activation_Settings__c tA5 = new Trigger_Activation_Settings__c();
        tA5.name = 'RelatedContactupdate';
        tA5.Object__c = 'Lead';
        tA5.Trigger__c = 'RelatedContactupdate';
        tA5.Value__c = 'True';
        custSettingList.add(tA5);
        
        
        Trigger_Activation_Settings__c tA7 = new Trigger_Activation_Settings__c();
        tA7.name = 'LeadCountryLookup';
        tA7.Object__c = 'Lead';
        tA7.Trigger__c = 'LeadCountryLookup';
        tA7.Value__c = 'True';
        custSettingList.add(tA7);
        
        Trigger_Activation_Settings__c tA8 = new Trigger_Activation_Settings__c();
        tA8.name = 'reassignLeads';
        tA8.Object__c = 'Lead';
        tA8.Trigger__c = 'reassignLeads';
        tA8.Value__c = 'True';
        custSettingList.add(tA8);
        
        Trigger_Activation_Settings__c tA9 = new Trigger_Activation_Settings__c();
        tA9.name = 'LeadRouting';
        tA9.Object__c = 'Lead';
        tA9.Trigger__c = 'LeadRouting';
        tA9.Value__c = 'True';
        custSettingList.add(tA9);
        
        Trigger_Activation_Settings__c tA10 = new Trigger_Activation_Settings__c();
        tA10.name = 'Update_LastNonQueueOnr_on_Owner_Update';
        tA10.Object__c = 'Lead';
        tA10.Trigger__c = 'Update_LastNonQueueOnr_on_Owner_Update';
        tA10.Value__c = 'True';
        custSettingList.add(tA10);
       
       Trigger_Activation_Settings__c tA11 = new Trigger_Activation_Settings__c();
        tA11.name = 'RelatedAccountupdate';
        tA11.Object__c = 'Lead';
        tA11.Trigger__c = 'RelatedAccountupdate';
        tA11.Value__c = 'True';
        custSettingList.add(tA11);
        
        insert custSettingList; 
       
       
        User us1=new User();
        us1.FirstName = 'Test';
        us1.LastName = 'User';
        us1.Email = 'Test@ironmountain.com';
        us1.Username = 'Test.User1@ironmountain.com';
        us1.Sales_Division__c='North America';
        us1.DefaultDivision ='02d8000000000kT';
        us1.Alias ='Test909';
        us1.CommunityNickname = 't909';
        us1.TimeZoneSidKey ='America/New_York';
        us1.LocaleSidKey = 'en_US';
        us1.EmailEncodingKey = 'UTF-8';
        us1.ProfileId = '00e80000000l0XrAAI';
            //p1[0].id;
        us1.LanguageLocaleKey = 'en_US';
        us1.Country = 'United States';
        insert us1;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c();
        IM_Country__c  r = new IM_Country__c();
        r.Iso31662Code__c ='US';
        r.Iso31663Code__c ='USA';
        r.Name ='United States';
        r.Region__c ='North America';
        insert r;
        
        country.IM_Country__c = r.id;
        country.Alternative_Name__c = 'United states';
        insert country;
        system.debug('Country inserted @ LINE 255');
        
        Id id = us1.id;
        
      /*  Account A = new Account(name='Test Acct',Billing_County__c='United States',IMGA_Owner__c=id,
                                BillingCountry='United States',D_B_DUNS__c ='Test');
        insert A;
        system.debug('Account inserted @ LINE 262');*/
        Lead led1=new Lead();
        led1.FirstName='test1';
        led1.Email='madhu.paladugu@ironmountain.com';
        led1.Country = 'United States';
        led1.IsConverted=false;
        led1.Company='Test';
        led1.LastName='paladugu';
        led1.OwnerId=id;
        led1.LeadSource='Online Display Advertising';//'Manual';
        led1.Status='open';
        led1.IM_Lead_Stage__c='1-Inquiry'; 
        led1.DUNs_Number__c ='Test';
        led1.Product_Interest__c ='Non DPR';
        led1.Country='United States';
        //A.Billing_County__c;
        //led1.Division='North America';
            //A.Division;
        led1.RecordTypeId = '01280000000UDKPAA4';
            //Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId();
        insert led1;
        system.debug('Lead inserted @ LINE # 283');
        //RecordType comprt = [Select Name, Id From RecordType where sObjectType='Competitor__c' and Name = 'Competitors'];
        Competitor__c compt = new Competitor__c();
        compt.Name = 'BlahBlah';
        compt.RecordTypeid = '01280000000UGv0AAG';
            //comprt.id;
        insert compt;
        system.debug('Insert completed till 290 line');
        
        Lead_Competitor__c ledcompt = new Lead_Competitor__c();
        ledcompt.Lead__c = led1.id;
        ledcompt.Competitor__c = compt.id;
        ledcompt.Lead_Owner_Email__c = 'Test@ironmountain.com';
        insert ledcompt;
        
        us1.Sales_Division__c='Europe';
        update us1;
        ledcompt.Lead_Owner_Email__c = '';
        update ledcompt;
        
        led1=new Lead();
        led1.FirstName='test1';
        led1.Email='madhu.paladugu@ironmountain.com';
        led1.Country = 'United States';
        led1.IsConverted=false;
        led1.Company='Test';
        led1.LastName='paladugu';
        led1.OwnerId=id;
        led1.LeadSource='Online Display Advertising';//'Manual';
        led1.Status='open';
        led1.IM_Lead_Stage__c='1-Inquiry';    
        led1.DUNs_Number__c ='Test';
        led1.Product_Interest__c ='Non DPR1';
        led1.Account__c=Null;
        led1.RecordTypeId = '01280000000UDKPAA4';
            //Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId();

        insert led1;
        
       /* Delete A;
             
        A = new Account(name='Test Acct',Billing_County__c='United States',IMGA_Owner__c=id,
                        BillingCountry='United States');
        insert A;
        
        system.debug('Insert A is done @ 326');*/
                       
        led1 = new Lead(FirstName='test1',
        Email='madhu.paladugu@ironmountain.com',
        Country = 'United States',
        IsConverted=false,
        Company='Test',
        LastName='paladugu',
        OwnerId=id,
        LeadSource='Online Display Advertising',
        Status='open',
        IM_Lead_Stage__c='1-Inquiry',
        DUNs_Number__c ='Test',
        Product_Interest__c ='Non DPR1',
        Account__c=Null,
        RecordTypeId = '01280000000UDKPAA4');
      //  insert led1;
        system.debug('Insert lead @ 343');
        test.stopTest();
    }
    
   static testMethod void Test_UpdateLeadOwnerNOAssignedOwner(){
        test.startTest();
        
        List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
        
        List<Lead_Owner_Eligible_for_Reassignment__c> loe = new List<Lead_Owner_Eligible_for_Reassignment__c>();
        Lead_Owner_Eligible_for_Reassignment__c loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Disqualified';
        loeRec.Lead_OwnerId__c = '00G80000001rLbV';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        
        loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Duplicates';
        loeRec.Lead_OwnerId__c = '00G80000001rLSx';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        
        loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Marketing Expired';
        loeRec.Lead_OwnerId__c = '00G800000023vgn';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        
        loeRec = new Lead_Owner_Eligible_for_Reassignment__c();
        loeRec.Name ='Nurture';
        loeRec.Lead_OwnerId__c = '00G80000001pIrU';
        loeRec.Lead_RecordType_Name__c ='Standard Lead,NA Account Management Lead';
        loe.add(loeRec);
        insert loe;
        
        Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
        tA.name = 'StageUpdateAfterConvert';
        tA.Object__c = 'Lead';
        tA.Trigger__c = 'StageUpdateAfterConvert';
        tA.Value__c = 'True';
        custSettingList.add(tA);
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'PopulateOriginalLeadOwner';
        tA1.Object__c = 'Lead';
        tA1.Trigger__c = 'PopulateOriginalLeadOwner';
        tA1.Value__c = 'True';
        custSettingList.add(tA1);
        
        Trigger_Activation_Settings__c tA2 = new Trigger_Activation_Settings__c();
        tA2.name = 'UpdateLeadOwnerEmailTrigger';
        tA2.Object__c = 'Lead';
        tA2.Trigger__c = 'UpdateLeadOwnerEmailTrigger';
        tA2.Value__c = 'True';
        custSettingList.add(tA2);
        
        Trigger_Activation_Settings__c tA3 = new Trigger_Activation_Settings__c();
        tA3.name = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Object__c = 'Lead';
        tA3.Trigger__c = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Value__c = 'True';
        custSettingList.add(tA3);    
                

        Trigger_Activation_Settings__c tA5 = new Trigger_Activation_Settings__c();
        tA5.name = 'RelatedContactupdate';
        tA5.Object__c = 'Lead';
        tA5.Trigger__c = 'RelatedContactupdate';
        tA5.Value__c = 'True';
        custSettingList.add(tA5);
        
        
        Trigger_Activation_Settings__c tA7 = new Trigger_Activation_Settings__c();
        tA7.name = 'LeadCountryLookup';
        tA7.Object__c = 'Lead';
        tA7.Trigger__c = 'LeadCountryLookup';
        tA7.Value__c = 'True';
        custSettingList.add(tA7);
        
        Trigger_Activation_Settings__c tA8 = new Trigger_Activation_Settings__c();
        tA8.name = 'reassignLeads';
        tA8.Object__c = 'Lead';
        tA8.Trigger__c = 'reassignLeads';
        tA8.Value__c = 'True';
        custSettingList.add(tA8);
        
        Trigger_Activation_Settings__c tA9 = new Trigger_Activation_Settings__c();
        tA9.name = 'LeadRouting';
        tA9.Object__c = 'Lead';
        tA9.Trigger__c = 'LeadRouting';
        tA9.Value__c = 'True';
        custSettingList.add(tA9);
        
        Trigger_Activation_Settings__c tA10 = new Trigger_Activation_Settings__c();
        tA10.name = 'Update_LastNonQueueOnr_on_Owner_Update';
        tA10.Object__c = 'Lead';
        tA10.Trigger__c = 'Update_LastNonQueueOnr_on_Owner_Update';
        tA10.Value__c = 'True';
        custSettingList.add(tA10);
       
       Trigger_Activation_Settings__c tA11 = new Trigger_Activation_Settings__c();
        tA11.name = 'RelatedAccountupdate';
        tA11.Object__c = 'Lead';
        tA11.Trigger__c = 'RelatedAccountupdate';
        tA11.Value__c = 'True';
        custSettingList.add(tA11);
        
        insert custSettingList; 
        
        list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'Standard User'];
        
        User us1=new user();        
        us1.FirstName = 'Test';
        us1.LastName = 'User';
        us1.Email = 'Test@ironmountain.com';
        us1.Username = 'Test.User1@ironmountain.com';
        us1.Sales_Division__c='North America';
        us1.DefaultDivision ='02d8000000000kT';
        us1.Alias ='Test909';
        us1.CommunityNickname = 't909';
        us1.TimeZoneSidKey ='America/New_York';
        us1.LocaleSidKey = 'en_US';
        us1.EmailEncodingKey = 'UTF-8';
        us1.ProfileId = p1[0].id;
        us1.LanguageLocaleKey = 'en_US';
        us1.Country = 'United States';
        insert us1;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c();
        IM_Country__c  r = new IM_Country__c();
        r.Iso31662Code__c ='US';
        r.Iso31663Code__c ='USA';
        r.Name ='United States';
        r.Region__c ='North America';
        insert r;
        country.IM_Country__c = r.id;
        country.Alternative_Name__c = 'United States';
        insert country;
        
		us1.Sales_Division__c='North America';
        update us1;
                
        Account A = new Account(name='AccountPratapTestMethod'+system.now(),
                                BillingCountry='United States', 
                                IMGA_Owner__c = us1.id, D_B_DUNS__c ='Test');
        insert A;
        Lead led1=new Lead();
        led1.FirstName='test1';
        led1.Email='madhu.paladugu@ironmountain.com';
        led1.Country = 'United States';
        led1.IsConverted=false;
        led1.Company='Test';
        led1.LastName='paladugu';
        led1.OwnerId=us1.Id;
        led1.LeadSource='Online Display Advertising';//'Manual';
        led1.Status='open';
        led1.IM_Lead_Stage__c='1-Inquiry';       
        led1.DUNs_Number__c ='Test';
        led1.Product_Interest__c ='Non DPR1';
        led1.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId();
        insert led1;
        
        RecordType comprt = [Select Name, Id From RecordType where sObjectType='Competitor__c' and Name = 'Competitors'];
        Competitor__c compt = new Competitor__c();
        compt.Name = 'BlahBlah';
        compt.RecordTypeid = comprt.id;
        insert compt;
        
        Lead_Competitor__c ledcompt = new Lead_Competitor__c();
        ledcompt.Lead__c = led1.id;
        ledcompt.Competitor__c = compt.id;
        ledcompt.Lead_Owner_Email__c = 'Test@ironmountain.com';
        insert ledcompt;
        


        ledcompt.Lead_Owner_Email__c = '';
        update ledcompt;
        
        led1.Status = 'New Activity'; 
        led1.IM_Lead_Stage__c = '3-Sales Accepted';
        led1.IM_Stage_3_Entered_Date__c = system.today();
        update led1;
        test.stopTest();
    }
    
   static testMethod void Test_reassignLeadsUsers() {
        // TO DO: implement unit test
        










        Test.startTest();
        List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
        Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
        tA.name = 'StageUpdateAfterConvert';
        tA.Object__c = 'Lead';
        tA.Trigger__c = 'StageUpdateAfterConvert';
        tA.Value__c = 'True';
        custSettingList.add(tA);
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'PopulateOriginalLeadOwner';
        tA1.Object__c = 'Lead';
        tA1.Trigger__c = 'PopulateOriginalLeadOwner';
        tA1.Value__c = 'True';
        custSettingList.add(tA1);
        
        Trigger_Activation_Settings__c tA2 = new Trigger_Activation_Settings__c();
        tA2.name = 'UpdateLeadOwnerEmailTrigger';
        tA2.Object__c = 'Lead';
        tA2.Trigger__c = 'UpdateLeadOwnerEmailTrigger';
        tA2.Value__c = 'True';
        custSettingList.add(tA2);
        
        Trigger_Activation_Settings__c tA3 = new Trigger_Activation_Settings__c();
        tA3.name = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Object__c = 'Lead';
        tA3.Trigger__c = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Value__c = 'True';
        custSettingList.add(tA3);    
        

        Trigger_Activation_Settings__c tA5 = new Trigger_Activation_Settings__c();
        tA5.name = 'RelatedContactupdate';
        tA5.Object__c = 'Lead';
        tA5.Trigger__c = 'RelatedContactupdate';
        tA5.Value__c = 'True';
        custSettingList.add(tA5);
                

        Trigger_Activation_Settings__c tA7 = new Trigger_Activation_Settings__c();
        tA7.name = 'LeadCountryLookup';
        tA7.Object__c = 'Lead';
        tA7.Trigger__c = 'LeadCountryLookup';
        tA7.Value__c = 'True';
        custSettingList.add(tA7);
        
        Trigger_Activation_Settings__c tA8 = new Trigger_Activation_Settings__c();
        tA8.name = 'reassignLeads';
        tA8.Object__c = 'Lead';
        tA8.Trigger__c = 'reassignLeads';
        tA8.Value__c = 'True';
        custSettingList.add(tA8);
        
        Trigger_Activation_Settings__c tA9 = new Trigger_Activation_Settings__c();
        tA9.name = 'LeadRouting';
        tA9.Object__c = 'Lead';
        tA9.Trigger__c = 'LeadRouting';
        tA9.Value__c = 'True';
        custSettingList.add(tA9);
        
        Trigger_Activation_Settings__c tA10 = new Trigger_Activation_Settings__c();
        tA10.name = 'Update_LastNonQueueOnr_on_Owner_Update';
        tA10.Object__c = 'Lead';
        tA10.Trigger__c = 'Update_LastNonQueueOnr_on_Owner_Update';
        tA10.Value__c = 'True';
        custSettingList.add(tA10);
       
       Trigger_Activation_Settings__c tA11 = new Trigger_Activation_Settings__c();
        tA11.name = 'RelatedAccountupdate';
        tA11.Object__c = 'Lead';
        tA11.Trigger__c = 'RelatedAccountupdate';
        tA11.Value__c = 'True';
        custSettingList.add(tA11);
        
        insert custSettingList;
        
        User user=[select id from user where Profile.Name='IM_Custom Sys Admin'and 
                   UserRole.name='Iron MTN Admin' and isActive=true limit 1];
        



















        //34592
        //Create a new Account
        //Account A = new Account(name='Account4TestMethod'+system.now(),testInCountry1__Country_field__c='United States',);
        //insert A;
        
        //34592 Account A;
       /*34592 IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c();
        IM_Country__c  r = new IM_Country__c();
        r.Iso31662Code__c ='US';
        r.Iso31663Code__c ='USA';
        r.Name ='United States';
        r.Region__c ='North America';
        insert r;
        country.IM_Country__c = r.id;
        country.Alternative_Name__c = 'United states';
        insert country;*/
       
        System.runAs(user){
           //34592 A = new Account(name='Test Acct',Billing_County__c='United States',IMGA_Owner__c=user.id,
                           //34592 BillingCountry='United States');
        //34592 insert A;
        
        //Create a new Lead
        Lead led1 = new Lead();
        led1.FirstName = 'led1fname';
        led1.LastName = 'led1lname';
        led1.Status = 'New'; 
        led1.IM_Lead_Source_Most_Recent__c = 'Email';
        led1.IM_Lead_Stage__c = '1-Inquiry';
        led1.Company = 'Account4UnitTest';
        led1.Email = 'testemail@email.com';        
        led1.IM_Functional_Area__c = 'x';       
        led1.OwnerId = user.Id;
        led1.Reassign_Lead__c  = false;

        insert led1;
        
        led1.Reassign_Lead__c  = true;      
        
        led1.Status = 'New Activity';
        update led1;
        list<id> lds=new list<id>();
        lds.add(led1.id);
        //Passing List of Lead Ids to Assign method to fire all lead assignment rules.
        //AssignLeads.assign(lds);
        }
        test.stopTest();        
    }
    
   static testMethod void Test_reassignLeadsQueues() {
        
        // TO DO: implement unit test
        test.startTest();
        List<Trigger_Activation_Settings__c> updatesettings;      
        User u1;
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            updatesettings = new List<Trigger_Activation_Settings__c>();
            


            List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
            Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
            tA.name = 'StageUpdateAfterConvert';
            tA.Object__c = 'Lead';
            tA.Trigger__c = 'StageUpdateAfterConvert';
            tA.Value__c = 'True';
            custSettingList.add(tA);
            
            Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
            tA1.name = 'PopulateOriginalLeadOwner';
            tA1.Object__c = 'Lead';
            tA1.Trigger__c = 'PopulateOriginalLeadOwner';
            tA1.Value__c = 'True';
            custSettingList.add(tA1);
            
            Trigger_Activation_Settings__c tA2 = new Trigger_Activation_Settings__c();
            tA2.name = 'UpdateLeadOwnerEmailTrigger';
            tA2.Object__c = 'Lead';
            tA2.Trigger__c = 'UpdateLeadOwnerEmailTrigger';
            tA2.Value__c = 'True';
            custSettingList.add(tA2);
            
            Trigger_Activation_Settings__c tA3 = new Trigger_Activation_Settings__c();
            tA3.name = 'Update_OwnerDetails_on_Owner_Update';
            tA3.Object__c = 'Lead';
            tA3.Trigger__c = 'Update_OwnerDetails_on_Owner_Update';
            tA3.Value__c = 'True';
            custSettingList.add(tA3);           

            
            Trigger_Activation_Settings__c tA5 = new Trigger_Activation_Settings__c();
            tA5.name = 'RelatedContactupdate';
            tA5.Object__c = 'Lead';
            tA5.Trigger__c = 'RelatedContactupdate';
            tA5.Value__c = 'True';
            custSettingList.add(tA5);
            

            Trigger_Activation_Settings__c tA7 = new Trigger_Activation_Settings__c();
            tA7.name = 'LeadCountryLookup';
            tA7.Object__c = 'Lead';
            tA7.Trigger__c = 'LeadCountryLookup';
            tA7.Value__c = 'True';
            custSettingList.add(tA7);
            
            Trigger_Activation_Settings__c tA8 = new Trigger_Activation_Settings__c();
            tA8.name = 'reassignLeads';
            tA8.Object__c = 'Lead';
            tA8.Trigger__c = 'reassignLeads';
            tA8.Value__c = 'True';
            custSettingList.add(tA8);
            
            Trigger_Activation_Settings__c tA9 = new Trigger_Activation_Settings__c();
            tA9.name = 'LeadRouting';
            tA9.Object__c = 'Lead';
            tA9.Trigger__c = 'LeadRouting';
            tA9.Value__c = 'True';
            custSettingList.add(tA9);
            
            Trigger_Activation_Settings__c tA10 = new Trigger_Activation_Settings__c();
            tA10.name = 'Update_LastNonQueueOnr_on_Owner_Update';
            tA10.Object__c = 'Lead';
            tA10.Trigger__c = 'Update_LastNonQueueOnr_on_Owner_Update';
            tA10.Value__c = 'True';
            custSettingList.add(tA10);
            
            Trigger_Activation_Settings__c tA11 = new Trigger_Activation_Settings__c();
        tA11.name = 'RelatedAccountupdate';
        tA11.Object__c = 'Lead';
        tA11.Trigger__c = 'RelatedAccountupdate';
        tA11.Value__c = 'True';
        custSettingList.add(tA11);
            
            insert custSettingList;
            
            //Create a test user who belongs to 'North America' Sales Division.
            list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'Standard User'];            
            u1 = new User(FirstName = 'fstName',LastName = 'lstName',Email = 'Testemail@testorg.com',
                          Username = 'Test9080808@mail.com',Alias ='Test808',CommunityNickname = 't808',
                          TimeZoneSidKey ='America/New_York',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',
                          ProfileId = p1[0].id,LanguageLocaleKey = 'en_US',Country = 'United States');          











/* 34592
            
            //Create a new Account
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c();
        IM_Country__c  r = new IM_Country__c();
        r.Iso31662Code__c ='US';
        r.Iso31663Code__c ='USA';
        r.Name ='United States';
        r.Region__c ='North America';
        insert r;
        country.IM_Country__c = r.id;
        country.Alternative_Name__c = 'United states';
        insert country;
       
            Account A = new Account(name='Test Acct',Billing_County__c='United States',IMGA_Owner__c=u1.id,
                                    BillingCountry='United States');
            insert A;        */  
           
            //Create a new Queue
            Group g1 = new Group(Name='group name', type='Queue');
            insert g1;
            QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Lead');
            insert q1;     

            
            //Create a new Lead
            Lead led1 = new Lead(FirstName = 'led1fname',LastName = 'led1lname',Status = 'New',IM_Lead_Source_Most_Recent__c = 'Email',
                                 IM_Lead_Stage__c = '1-Inquiry',
                                 Company = 'Account4UnitTest',Email = 'testemail@email.com',IM_Functional_Area__c = 'x',OwnerId = q1.QueueId,Reassign_Lead__c  = false);
            insert led1; 
            
            led1.Reassign_Lead__c  = true;      
            update led1;
            
            led1.Status = 'New Activity';
            update led1;
            list<id> lds=new list<id>();
            lds.add(led1.id);
            //Passing List of Lead Ids to Assign method to fire all lead assignment rules.
            AssignLeads.assign(lds);
            test.stopTest();
        }
        System.runAs(u1){
            //Updating custom settings data.
            update updatesettings;
        }  
    }
    
    static testMethod void Test_RunStageUpdateAfterConvert(){
        test.startTest();
        
        List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
         Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
            tA.name = 'StageUpdateAfterConvert';
            tA.Object__c = 'Lead';
            tA.Trigger__c = 'StageUpdateAfterConvert';
            tA.Value__c = 'True';
            custSettingList.add(tA);
        
        Trigger_Activation_Settings__c tA2 = new Trigger_Activation_Settings__c();
            tA2.name = 'RelatedContactupdate';
            tA2.Object__c = 'Lead';
            tA2.Trigger__c = 'RelatedContactupdate';
            tA2.Value__c = 'True';
            custSettingList.add(tA2);
        insert custSettingList;
        
        list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'Standard User'];
        
        User us1=new user();        
        us1.FirstName = 'Test';
        us1.LastName = 'User';
        us1.Email = 'Test@ironmountain.com';
        us1.Username = 'Test.User1@ironmountain.com';
        us1.Sales_Division__c='North America';
        us1.DefaultDivision ='02d8000000000kT';
        us1.Alias ='Test909';
        us1.CommunityNickname = 't909';
        us1.TimeZoneSidKey ='America/New_York';
        us1.LocaleSidKey = 'en_US';
        us1.EmailEncodingKey = 'UTF-8';
        us1.ProfileId = p1[0].id;
        us1.LanguageLocaleKey = 'en_US';
        us1.Country = 'United States';
        insert us1;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c();
        IM_Country__c  r = new IM_Country__c();
        r.Iso31662Code__c ='US';
        r.Iso31663Code__c ='USA';
        r.Name ='United States';
        r.Region__c ='North America';
        insert r;
        country.IM_Country__c = r.id;
        country.Alternative_Name__c = 'United States';
        insert country;
        
		us1.Sales_Division__c='North America';
        update us1;

        List<Country_Settings__c> countrySetting = new List<Country_Settings__c>();
            Country_Settings__c cS = new Country_Settings__c();
            cS.Name = 'Canada';
            cS.Object_Name__c = 'Account';
            countrySetting.add(cS);
        
            Country_Settings__c cS2 = new Country_Settings__c();
            cS2.Name = 'United States';
            cS2.Object_Name__c = 'Account';
            countrySetting.add(cS2);
           
             insert  countrySetting;  
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Lead led1=new Lead();
        led1.FirstName='test1';
        led1.Email='madhu.paladugu@ironmountain.com';
        led1.Country = 'United States';
        led1.street='Street1';
        led1.city='test city';
        led1.state='test state';
        led1.PostalCode='10000';
        led1.IsConverted=false;
        led1.Company='Test';
        led1.LastName='paladugu';
        led1.OwnerId=us1.Id;
        led1.LeadSource='Online Display Advertising';//'Manual';
        led1.Status='open';
        led1.IM_Lead_Stage__c='1-Inquiry';       
        led1.DUNs_Number__c ='Test';
        led1.Product_Interest__c ='Non DPR1';
        led1.IM_Industry__c='Banking';
        led1.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId();
        insert led1;
        System.debug('Lead convert');
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(led1.id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.debug([select id,name,isconverted,ConvertedOpportunityId,convertedcontactId from lead where IsConverted=true limit 1]);
        system.debug('COnversion status'+convertStatus);
        
        test.stopTest();
    }
    
    static testMethod void Test_RunAccountContactUpdate(){
        test.startTest();
        
        List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
         Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
            tA.name = 'StageUpdateAfterConvert';
            tA.Object__c = 'Lead';
            tA.Trigger__c = 'StageUpdateAfterConvert';
            tA.Value__c = 'True';
            custSettingList.add(tA);
        
        Trigger_Activation_Settings__c tA2 = new Trigger_Activation_Settings__c();
            tA2.name = 'RelatedContactupdate';
            tA2.Object__c = 'Lead';
            tA2.Trigger__c = 'RelatedContactupdate';
            tA2.Value__c = 'True';
            custSettingList.add(tA2);
        
        Trigger_Activation_Settings__c tA3 = new Trigger_Activation_Settings__c();
            tA3.name = 'RelatedAccountupdate';
            tA3.Object__c = 'Lead';
            tA3.Trigger__c = 'RelatedAccountupdate';
            tA3.Value__c = 'True';
            custSettingList.add(tA3);
        insert custSettingList;
        
        list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'Standard User'];
        
        User us1=new user();        
        us1.FirstName = 'Test';
        us1.LastName = 'User';
        us1.Email = 'Test@ironmountain.com';
        us1.Username = 'Test.User1@ironmountain.com';
        us1.Sales_Division__c='North America';
        us1.DefaultDivision ='02d8000000000kT';
        us1.Alias ='Test909';
        us1.CommunityNickname = 't909';
        us1.TimeZoneSidKey ='America/New_York';
        us1.LocaleSidKey = 'en_US';
        us1.EmailEncodingKey = 'UTF-8';
        us1.ProfileId = p1[0].id;
        us1.LanguageLocaleKey = 'en_US';
        us1.Country = 'United States';
        insert us1;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c();
        IM_Country__c  r = new IM_Country__c();
        r.Iso31662Code__c ='US';
        r.Iso31663Code__c ='USA';
        r.Name ='United States';
        r.Region__c ='North America';
        insert r;
        country.IM_Country__c = r.id;
        country.Alternative_Name__c = 'United States';
        insert country;
        
		us1.Sales_Division__c='North America';
        update us1;

        List<Country_Settings__c> countrySetting = new List<Country_Settings__c>();
            Country_Settings__c cS = new Country_Settings__c();
            cS.Name = 'Canada';
            cS.Object_Name__c = 'Account';
            countrySetting.add(cS);
        
            Country_Settings__c cS2 = new Country_Settings__c();
            cS2.Name = 'United States';
            cS2.Object_Name__c = 'Account';
            countrySetting.add(cS2);
           
             insert  countrySetting;  
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        Lead led1=new Lead();
        led1.FirstName='test1';
        led1.Email='madhu.paladugu@ironmountain.com';
        led1.Country = 'United States';
        led1.street='Street1';
        led1.city='test city';
        led1.state='test state';
        led1.PostalCode='10000';
        led1.IsConverted=false;
        led1.Company='Test';
        led1.LastName='paladugu';
        led1.OwnerId=us1.Id;
        led1.LeadSource='Online Display Advertising';//'Manual';
        led1.Status='open';
        led1.IM_Lead_Stage__c='1-Inquiry';       
        led1.DUNs_Number__c ='Test';
        led1.Product_Interest__c ='Non DPR1';
        led1.IM_Industry__c='Banking';
        led1.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId();
        led1.contact_id__c=[select id from contact limit 1].id;
        led1.Account_id__c=[select id from Account limit 1].id;
        insert led1;
        
        test.stopTest();
    }
    
    static testMethod void Test_UpdateLeadOwner2(){
        test.startTest();
        
        List<Trigger_Activation_Settings__c> custSettingList = new List<Trigger_Activation_Settings__c>();
         
        Trigger_Activation_Settings__c tA3 = new Trigger_Activation_Settings__c();
        tA3.name = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Object__c = 'Lead';
        tA3.Trigger__c = 'Update_OwnerDetails_on_Owner_Update';
        tA3.Value__c = 'True';
        custSettingList.add(tA3);  
        
        Trigger_Activation_Settings__c tA1 = new Trigger_Activation_Settings__c();
        tA1.name = 'PopulateOriginalLeadOwner';
        tA1.Object__c = 'Lead';
        tA1.Trigger__c = 'PopulateOriginalLeadOwner';
        tA1.Value__c = 'True';
        custSettingList.add(tA1);
        
                
        insert custSettingList; 
        
        list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'Standard User'];
        
        User us1=new user();        
        us1.FirstName = 'Test';
        us1.LastName = 'User';
        us1.Email = 'Test@ironmountain.com';
        us1.Username = 'Test.User1@ironmountain.com';
        us1.Sales_Division__c='North America';
        us1.DefaultDivision ='02d8000000000kT';
        us1.Alias ='Test909';
        us1.CommunityNickname = 't909';
        us1.TimeZoneSidKey ='America/New_York';
        us1.LocaleSidKey = 'en_US';
        us1.EmailEncodingKey = 'UTF-8';
        us1.ProfileId = p1[0].id;
        us1.LanguageLocaleKey = 'en_US';
        us1.Country = 'United States';
        insert us1;
        
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c();
        IM_Country__c  r = new IM_Country__c();
        r.Iso31662Code__c ='US';
        r.Iso31663Code__c ='USA';
        r.Name ='United States';
        r.Region__c ='North America';
        insert r;
        country.IM_Country__c = r.id;
        country.Alternative_Name__c = 'United States';
        insert country;
        
		us1.Sales_Division__c='North America';
        update us1;
                
        Account A = new Account(name='AccountPratapTestMethod'+system.now(),
                                BillingCountry='United States', 
                                IMGA_Owner__c = us1.id, D_B_DUNS__c ='Test');
        insert A;
        Lead led1=new Lead();
        led1.FirstName='test1';
        led1.Email='madhu.paladugu@ironmountain.com';
        led1.Country = 'United States';
        led1.IsConverted=false;
        led1.Company='Test';
        led1.LastName='paladugu';
        led1.OwnerId=us1.Id;
        led1.LeadSource='Online Display Advertising';//'Manual';
        led1.Status='open';
        led1.IM_Lead_Stage__c='1-Inquiry';       
        led1.DUNs_Number__c ='Test';
        led1.Product_Interest__c ='Non DPR1';
        led1.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Standard Lead').getRecordTypeId();
        insert led1;
        
        led1.Status = 'New'; 
        led1.IM_Lead_Stage__c = '2-Marketing Qual';
        led1.IM_Stage_2_Entered_Date__c = system.today();
        led1.Most_Recent_Sales_Activity__c=system.today()+1;
        update led1;
        
        led1.IM_Lead_Stage__c = '3-Marketing Qual';
        led1.IM_Stage_3_Entered_Date__c = system.today();
        led1.Most_Recent_Sales_Activity__c=system.today();
        update led1;
        
        led1.IM_Stage_3_Entered_Date__c = system.today();
        led1.Most_Recent_Sales_Activity__c=system.today()-1;
        led1.StageComparisonDate__c=system.today()-1;
        update led1;
        
        led1.IM_Stage_3_Entered_Date__c = system.today();
        led1.Most_Recent_Sales_Activity__c=system.today()+1;
        led1.StageComparisonDate__c=system.today()-1;
        update led1;
        
        led1.IM_Stage_3_Entered_Date__c = null;
        update led1;
        
        System.debug('dates'+led1.IM_Stage_3_Entered_Date__c+' '+led1.Most_Recent_Sales_Activity__c+' '+led1.StageComparisonDate__c);
        led1.firstname='After update';
        led1.IM_Original_Lead_Owner__c=null;
        update led1;
        
        led1.IM_Stage_3_Entered_Date__c=system.today();
        led1.Most_Recent_Sales_Activity__c=null;
        update led1;
        
        System.debug('dates'+led1.IM_Stage_3_Entered_Date__c+' '+led1.Most_Recent_Sales_Activity__c+' '+led1.StageComparisonDate__c);
        led1.firstname='After update2';
        update led1;
        
        
        
        test.stopTest();
    }
    
    
}
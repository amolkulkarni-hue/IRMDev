/*Developer Name: Madhu Paladugu
  Company       : TheCloudFountain Inc.
  Desrciption   : Test utility for ContactObject Trigger. 
  Date          : 12/4/12
  case number   : 00924109   */
@isTest(seeAllData=true)
public class Test_ContactObject{

public static testMethod void doTest(){
List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
      List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
      for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c == 'contact') {
          cs.Value__c='True';
          updatesettings.add(cs);
        }
      }
      update updatesettings;
      List<contact> conlist=new List<Contact>();
        String usrId = UserInfo.getUserId();
contact c=new contact(MailingCity='Boston',MailingState='MA',MailingCountry='United States',LastName='Test',OwnerId=usrId,Email='madhu.paladugu@ironmountain.com');

contact c1=new contact(MailingCity='Boston',MailingState='MA',MailingCountry='United Kingdom',LastName='Test',OwnerId=usrId,Email='madhu.paladugu@ironmountain.com');
contact c2=new contact(MailingCity='Boston',MailingState='MA',MailingCountry='INDIA',LastName='Test',OwnerId=usrId,Email='madhu.paladugu@ironmountain.com');


conlist.add(c);
conlist.add(c1);
  insert conlist; 
  try{
      insert c2;
  }

catch(Exception e){
system.debug('++++++++++++do nothing++++++');
}

delete c;


}
}
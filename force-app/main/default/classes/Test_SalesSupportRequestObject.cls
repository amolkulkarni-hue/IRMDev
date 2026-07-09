/*****************************************************************************************************************************
Name : Test_SalesSupportRequestObject 
Created By : Srinivasa Rao Mandalapu
Created Date : 03rd Dec, 201
Usages : Test coverage of SalesSupportRequestTrigger with custom settings logic.
*****************************************************************************************************************************/
@isTest(SeeAllData=true)
private class Test_SalesSupportRequestObject {
    
    public static String SalesSupportRequestTrigger=null;
    
    /*SalesSupportRequestTrigger code coverage for bulkPositive*/
    static testMethod void bulkPositive() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
          if(cs.Object__c == 'Sales_Support_Request__c') {
            cs.Value__c='True';
            updatesettings.add(cs);
          }
        }
        update updatesettings;
        
        // TO DO: implement unit test
        Profile p = [select id from profile where name='Marketing User'];
        // create a user to run the test as
        User u = new User(alias = 'test123', email='test1234@noemail.com',
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id, country='United States',
            timezonesidkey='America/Los_Angeles', username='12test1234@noemail.com');
        insert u;
         Sales_Support_Request_Users__c custset=new Sales_Support_Request_Users__c();
            custset.Name='test1';
            custset.UserId__c=u.id;
            insert custset;

            Sales_Support_Request__c ssr = new Sales_Support_Request__c(
                Name='testName',
                OwnerId=u.Id,
                Assigned_to__c=u.id
            );
        insert ssr;
        Sales_Support_Request__c ssr1=[select id,Sales_Rep__c from Sales_Support_Request__c where id=:ssr.id];
       
        System.assertEquals (ssr1.Sales_Rep__c , userInfo.getUserId());
        
        ssr1.Sales_Rep__c = u.Id;
        
        System.assertEquals (ssr1.Sales_Rep__c , u.Id);
    }
    
   
}
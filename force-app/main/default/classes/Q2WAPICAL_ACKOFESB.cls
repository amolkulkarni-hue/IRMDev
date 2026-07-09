/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 5/7/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used as SOAP resuorce to ESB do the ACK for quotes received. 
   
   Test Class        : This class it self as the test method in it.
   
   Case Number       : 00222919
                                  
 ********************************/  
global WithOut Sharing class  Q2WAPICAL_ACKOFESB{ 
      static String ERRORMESSAGE='Id,Successfully_Received_by_ESB__c \n';
      static Boolean ISERROR_WHILE_UPDATE_RATETABLE=false;   
     
     webservice static void updateQuotes(string QuoteId){
         system.debug('+++++++++++++quote id from esb++++++++'+QuoteId);
          
          //getting quote records
         List<Quote> Quote_list=[select id,Stage__c,opportunityId,Received_By_ESB__c from quote where id=:QuoteId];
         List<Quote> Quotes_Needs_update=new List<Quote>();
         
         for(Quote Q:Quote_list){
             Q.Received_By_ESB__c=true;
             Quotes_Needs_update.add(Q);
         }
         
         //making the updates and check sucess/failure of updates if there are any failures send an email
         Database.SaveResult[] sr=DataBase.Update(Quotes_Needs_update,false);
         for (Integer I = 0; I < sr.size(); I++) {
             if (!sr[I].isSuccess()) {
                  ERRORMESSAGE+=sr[I].getId()+','+'True'+'\n';
                  ISERROR_WHILE_UPDATE_RATETABLE=true;
             }
         }
        
         
        
        if(ISERROR_WHILE_UPDATE_RATETABLE){
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            string toaddress=Label.email_to_report_error_for_pros;
            blob csvBlob = Blob.valueOf(ERRORMESSAGE);
            string csvname= 'QuoteIdsReceivedByESB.csv';
            csvAttc.setFileName(csvname);
            csvAttc.setBody(csvBlob);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {toaddress};
            mail.setToAddresses(toAddresses);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {csvAttc});
            mail.setSubject('There was problem occured while updating ESB acknowledgement on quote');
            mail.setPlainTextBody(' Please find the attachment and do the manual update to the quote.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
     }
     //Test method
     static TestMethod void doTest(){
        //insert Account
        Account A = new Account(name='Account4TestMethod'+system.now(), BillingStreet='test',BillingState='MA',BillingCity='Boston',BillingCountry='United States');
        insert A;
        RecordType rt=[select id from recordtype where name='NA Renewal'];
        //insert opportunity
        Opportunity opp = new Opportunity();
        opp.AccountId = A.Id;
        opp.Name = 'Opportunity4TestMethod';
        opp.CloseDate = System.today().addMonths(3);
        opp.StageName = '5-Closred - In fulfillment';
        opp.Type = 'Renewal';
        opp.RecordtypeId=rt.id;
        insert opp;
        
        //insert Quote 
        Quote Q=new Quote(Name='Test Quote',opportunityId=opp.id);
        Insert Q;
        
        //calling the update method 
        ISERROR_WHILE_UPDATE_RATETABLE=true;
        updateQuotes(Q.Id);
        
     }
}
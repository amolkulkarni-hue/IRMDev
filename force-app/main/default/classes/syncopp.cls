/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 10/9/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used to sync quotes with opp. 
   
   Test Class        : Test_syncopp.
   
   Case Number       : 00222919
                                  
 ********************************/ 
public class syncopp{
   @future
   public static void doSync(Map<id,id> Map_Opp_Quote){
    
           try{
            system.debug('+++++++++opp_quote id map++++++++'+Map_Opp_Quote);
            List<opportunity> OppList=[select id,SyncedQuoteId from opportunity where Id IN:Map_Opp_Quote.keySet()];
            List<opportunity> oppListUpdate=new List<opportunity>();
            
            for(opportunity op:OppList){
                op.SyncedQuoteId=Map_Opp_Quote.get(op.id);
                oppListUpdate.add(op);
            }
            system.debug('+++++++++++++List before start sync++++++++++'+oppListUpdate);
            update oppListUpdate;
      }
      catch(Exception e){
            sendemail();
      }  
    }
    
    @future
    public static void doSyncOnDelete(List<id> Ids){
           try{
           system.debug('+++++++++executing the delete sync future method+++++++++');
            List<opportunity> OppList=[select id,SyncedQuoteId,(select id from quotes ORDER BY createdDate DESC limit 1) from opportunity where Id IN:Ids and RecordType.Name='NA Renewal'];
            List<opportunity> oppListUpdate=new List<opportunity>();
            
            for(opportunity op:OppList){
                for(Quote q:op.Quotes){
                    op.SyncedQuoteId=q.id;
                    oppListUpdate.add(op);
                }
            }
            system.debug('+++++++++++++quote id++++++++++'+oppListUpdate);
            update oppListUpdate;
      }
      catch(Exception e){
           sendemail();
      }
    }
   
    static void sendemail(){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            string toaddress1=Label.email_to_report_error_for_pros;
            String[] toAddresses = new String[] {toaddress1};
            mail.setToAddresses(toAddresses);
            mail.setSubject('problem occured whill syncing quotes');
            mail.setPlainTextBody('please do run the quote sync job manually to fix these issues from Q2WBatchJobsManager.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
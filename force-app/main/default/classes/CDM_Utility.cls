/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 10/18/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used helper class to post error messages to chatter group. 
   
   Test Class        : Test_CDM_Utility.
      
   Case Number       : 01733573
                                  
 ********************************/ 
 
 public class CDM_Utility{
   /*  
     public static void feedRegularPost(String message,List<Account> accList){
            
          //Chatter Group to send an alert message.
            CollaborationGroup CG = [Select c.Name, c.Id From CollaborationGroup c where c.Name='CDM_INTEGRATION_GROUP'];           
             
             List<FeedItem> feedItemList=new List<FeedItem>();
            //Chatter post.
            for(Account a:accList){
                FeedItem post = new FeedItem(); 
                post.ParentId = CG.Id;
                post.Body = message+' Problem was encountered while processing the following account';
                post.LinkUrl= '/apex/CDM_ProcessChatterErrorRecords?accid='+a.id;//'//'+a.id;
                feedItemList.add(post);
            }
            system.debug('+++++++++insert chatter post+++++++'+feedItemList);
            insert feedItemList;
         
     }
     public static void feedCSVfilePost(String message,List<Account> accList){
           
           string header = 'Id, CDM_Key__c, CDM_Id__c, Contract_Address_1__c, Contract_Address_2__c, Contract_Address_3__c, Contract_Address_4__c, Contract_Floor__c, Contract_City__c,Contract_State__c, Contract_County__c, Contract_Country__c, Contract_Postal_Code__c, CDM_Last_Refresh_Date__c, CDM_Last_Refresh_Owner__c \n';
            string finalstr = header ;
            for(Account a: accList)
            {
                   string recordString = a.id+','+a.CDM_Key__c+','+a.CDM_Id__c+','+a.Contract_Address_1__c+','+a.Contract_Address_2__c+','+a.Contract_Address_3__c+','+a.Contract_Address_4__c+','+a.Contract_Floor__c+','+a.Contract_City__c+','+a.Contract_State__c+','+a.Contract_County__c+','+a.Contract_Country__c+','+a.Contract_Postal_Code__c+','+a.CDM_Last_Refresh_Date__c+','+a.CDM_Last_Refresh_Owner__c +'\n';
                   finalstr = finalstr +recordString;
            }
            blob csvBlob = Blob.valueOf(finalstr);
          
          //Chatter Group to send an alert message.
            CollaborationGroup CG = [Select c.Name, c.Id From CollaborationGroup c where c.Name='CDM_INTEGRATION_GROUP'];           
               
               //Chatter post.
                FeedItem post = new FeedItem(); 
                post.ParentId = CG.Id;
                post.Body = message+' Problem was encountered while processing the following goleden account record';
                post.ContentData=csvBlob;
                post.ContentFileName = 'GoldenAccount.csv';
          
                insert post;
     
     }
*/
 }
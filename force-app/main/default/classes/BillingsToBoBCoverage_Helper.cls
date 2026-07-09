/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   BillingsToBoBCoverage_Helper (Class)
**
** PURPOSE
**   Methods and variables used by other classes:
**     postToChatterGroup()
**     jobStatus()
**     dumpList()
**     dumpMap()
**     dumpBilling()
**     dumpCoverage()
**     strDef()
**
** NOTES
**
** BUNDLE SUMMARY
**   See class BillingsToBoBCoverage_Master.
**
** POTENTIAL ENHANCEMENTS
**   1. From the documentation:
**      "For each 10,000 AsyncApexJob records, Apex creates one additional AsyncApexJob record
**      of type BatchApexWorker for internal use. When querying for all AsyncApexJob records, 
**      we recommend that you filter out records of type BatchApexWorker using the JobType field. 
**      Otherwise, the query will return one more record for every 10,000 AsyncApexJob records.""
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/02/15; Bill Cloward/Bluewolf; Iron Mountain SFDC Billings Data Project (Project a0b00000000FTkA); Initial release
**
************************************************************************/
/* Commenting the entire code as part of Gitlab #24446 */

public virtual class BillingsToBoBCoverage_Helper {  
    public BillingsToBoBCoverage_Helper(){
        
    }
/*
    // log access
    private final static String       moduleName = '_Helper';         
    protected BillingsToBoBCoverage_Log logger;    

    
    //-----------------------------------------------------------------------------------
    // constructor 
    public BillingsToBoBCoverage_Helper () {}
     
    public BillingsToBoBCoverage_Helper (String customSetting) {
        logger = new BillingsToBoBCoverage_Log(customSetting);
    } // BillingsToBoBCoverage_Helper
    

    //-----------------------------------------------------------------------------------
    // post a TextPost to a Chatter group
    public void postToChatterGroup (String groupName, String textBody) { 
        try {
            // look up the target group's ID
            List<CollaborationGroup> cGroup = [SELECT Id, Name, MemberCount,CanHaveGuests, 
                                                      CollaborationType 
                                                 FROM CollaborationGroup 
                                                WHERE Name = :groupName ];
            
            // found it?
            if (cGroup != null  &&  !cGroup.isEmpty()) {
                // submit the new post
                FeedItem post = new FeedItem();
                
                post.ParentId = cGroup[0].Id;
                post.Body     = textBody;
                
                insert post;
                logger.newEntry(moduleName, 'Info', 'Message posted to Chatter group: ' + groupName, textBody, -1);
            }
            else {
                logger.newEntry(moduleName, 'Warning', 'Chatter group not found', groupName, 1);  
            }      
        }
        catch (Exception curse) {
            system.debug('Chatter post failed: ' + curse);
            logger.newException(moduleName, 'Chatter post failed', curse);
        }           

    } // postToChatterGroup   
        
     
    //-----------------------------------------------------------------------------------   
    // determine the current status of the batch job chain
    public virtual AsyncApexJob jobStatus () {
        // find the most recent batch job in this family/sequence/chain
        List<AsyncApexJob> latest = [ SELECT Id, JobType, ApexClassId, 
                                             ApexClass.Name, MethodName,
                                             TotalJobItems, JobItemsProcessed, 
                                             LastProcessed, LastProcessedOffset,
                                             Status, ExtendedStatus, NumberOfErrors,
                                             CreatedDate, CompletedDate,
                                             CreatedBy.Name
                                        FROM AsyncApexJob
                                       WHERE ApexClassId IN (SELECT Id
                                                               FROM ApexClass
                                                              WHERE NAME LIKE 'BillingsToBoBCoverage_%' )
                                    ORDER BY CreatedDate Desc
                                       LIMIT 1 ];
        system.debug('latest: ' + latest);
        
        // found it?
        if (latest != null  &&  !latest.isEmpty())
            return latest[0];
        else
            return null;
            
    } // jobStatus    
                
     
    //----------------------------------------------------------------------------------- 
    // return a default value in place of a null string
    public String strDef (String sCurrent, String sDefault) {
        if (sCurrent != null)
            return sCurrent;
        else
            return sDefault;
            
    } // strDef    
                           
     
    //----------------------------------------------------------------------------------- 
    // compare Id values regardless of length (15 or 18 characters)
    public Boolean idMatches (Id idA, String stringB) {
      String stringA = (String) idA;
      return stringA.startsWith(stringB.left(15));

    } // strDef 
    */
} // BillingsToBoBCoverage_Helper
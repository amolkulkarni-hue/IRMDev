/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   IRM_SC_EmailToCase_BatchJobsList (Apex Controller)
**
** PURPOSE
**   Showing List of Email-to-Case Batch jobs when clicked on Chatter Post Link. 
**
** NOTES
**   Expected invocation format:
**     whenever User clicks on chatter post link, "IRM_SC_EmailToCase_BatchJobsList" VF page will call this controller.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 09/12/2013; Srinivasa Rao/Randstad; Email-to-case emails not creating cases (Customer Services) (Case # 01414611); Initial release
**
************************************************************************/
public class IRM_SC_EmailToCase_BatchJobsList{
    public List<AsyncApexJob> AsyncApexJobs;
    
    public List<AsyncApexJob> getAsyncApexJobs() {
        AsyncApexJobs=[Select Id, JobType,Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname, CompletedDate, ApexClass.Name from AsyncApexJob 
                        where ApexClass.Name='IRM_SC_Email_to_CaseBatchJob' AND JobType='BatchApex'];
        return AsyncApexJobs;
    }
}
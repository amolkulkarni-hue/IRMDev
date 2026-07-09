/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Test_IRM_SC_EmailToCase_BatchJobsList(Test Class)
**
** PURPOSE
**   Code coverage for "IRM_SC_EmailToCase_BatchJobsList" Controller. 
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 09/12/2013; Srinivasa Rao/Randstad; Email-to-case emails not creating cases (Customer Services) (Case # 01414611); Initial release
**
************************************************************************/
@isTest(SeeAllData=true)
public class Test_IRM_SC_EmailToCase_BatchJobsList{
    public static testMethod void testMyController() {
       
        //Creating instance for controller
        IRM_SC_EmailToCase_BatchJobsList cntlr = new IRM_SC_EmailToCase_BatchJobsList();
        
        //Calling Controller methods
        cntlr.getAsyncApexJobs();

    }
    

}
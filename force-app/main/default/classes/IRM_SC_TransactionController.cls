/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Email_to_CaseBatchJob (Batch Class)
**
** PURPOSE
**   Email-to-Case Fix when locking error occurs. 
**
** NOTES
**   Expected invocation format:
**     whenever locking error gets upon case insertion from IRM_SC_ClosedCaseEmail Trigger on EmailMessage Object.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 06/03/2013; Srinivasa Rao/Randstad; Email-to-case emails not creating cases (Customer Services) (Case # 01414611); Initial release
**
************************************************************************/
public with sharing class IRM_SC_TransactionController {
    //Varibale is passing from Batch Class to delete EmailMessages and insert New EmailMessage manually.
    Public Static Boolean AllowDeleteFromBatchClass=false; 
    
    //Variable used to call batch class from trigger in After insert to pass EmailMessage Id's to batch class.
    Public Static Boolean calBatchClassInsert=false; 
    
    public static boolean CalingFromControllerPage=false;
}
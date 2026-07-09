/**  
       * Name: IRM_SC_IfUpdateCaseViewFired
       * Description: Checks if the trigger is fired again due to insert or update
       * Copyright: HCL Technologies
       * Author: Priyamvada Singh
       * Modification Log: Created:27-April-2012
  **/



public class IRM_SC_IfUpdateCaseViewFired 
{

     private static boolean alreadyUpdatedCaseView = false;


    public static boolean hasAlreadyUpdatedCaseViewInfo() 
    {
        return alreadyUpdatedCaseView;
    }

 
    public static void setAlreadyUpdatedCaseViewInfo() 
    {
        alreadyUpdatedCaseView = true;
    }



}
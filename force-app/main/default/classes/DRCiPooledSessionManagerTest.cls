/**
* Class: DRCiPooledSessionManagerTest
*
* Author: TCS
*
* Purpose: Test class for DRCiPooledSessionManager
*
* Requirement: GitLab * #5164  
*
* Change History:
*
* Developer  : Praneel Patalay                   Date : 13/Feb/2022	             		
* Description : This test class for DRCiPooledSessionManager
* Modification: 
* Modification Date: 
* Modified By: 
* -------------------------------------------------------------------------------------------
* 
*/
@isTest
public class DRCiPooledSessionManagerTest {
	
    public static testmethod void testSingleton() {  
     DRCiPooledSessionManager.getInstance().setBusyTransaction();  
     boolean isItBusy = DRCiPooledSessionManager.getInstance().isBusyTransaction();
     DRCiPooledSessionManager.getInstance().releaseBusyTransaction();
   }
}
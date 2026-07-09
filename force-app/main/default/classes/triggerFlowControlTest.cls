/**
* Class: triggerFlowControlTest
*
* Author: TCS
*
* Purpose: Test class for triggerFlowControl
*
* Requirement: GitLab * #5164  
*
* Change History:
*
* Developer  : Praneel Patalay                   Date : 13/Feb/2022	             		
* Description : This test class is for triggerFlowControl
* Modification:
* Modification Date: 
* Modified By: 
* -------------------------------------------------------------------------------------------
* 
*/
@isTest
public class triggerFlowControlTest {
static testMethod void runTest(){
    triggerFlowControl.setControlEnabled(true);
    triggerFlowControl fc = new triggerFlowControl();
    
    Integer t = triggerFlowControl.triggerRunCount('ContactCountryLookup');
    System.assertEquals(t, 1);
    
    t = triggerFlowControl.triggerRunCount('ContactCountryLookup');
    System.assertEquals(t, 2);
    
    t = triggerFlowControl.triggerRunCount('ContactCountryLookup');
    System.assertEquals(t, 3);
    
    triggerFlowControl.resetTriggerRunCount('ContactCountryLookup');
    
    t = triggerFlowControl.triggerRunCount('ContactCountryLookup');
    System.assertEquals(t, 1);
    
    t = triggerFlowControl.triggerRunCount('ManageDRCiWebServiceConnection');
    System.assertEquals(t, 1);
    
    
    
    triggerFlowControl.setControlEnabled(false);
    
    t = triggerFlowControl.triggerRunCount('ContactCountryLookup');
    System.assertEquals(t, 0);
    
    Map<string,User> l = new Map<string,User>([select name, Id from user limit 10]);
    
    set<string> ids = new set<string>();
    ids.addAll(l.keySet());
    
    triggerFlowControl.setControlEnabled(true);
    
    t = triggerFlowControl.triggerRunCountBulk('ContactCountryLookup', ids);
    
    t = triggerFlowControl.triggerRunCountBulk('ContactCountryLookup', ids);
  }
}
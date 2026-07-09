/**
* Class: SalesCoachSetupTest
*
* Author: TCS
*
* Purpose: Test class for SalesCoachSetup
*
* Requirement: GitLab * #5164  
*
* Change History:
*
* Developer  : Praneel Patalay                   Date : 13/Feb/2022	             		
* Description : This test class for SalesCoachSetup
* Modification: 
* Modification Date: 
* Modified By: 
* -------------------------------------------------------------------------------------------
* 
*/
@isTest
public class SalesCoachSetupTest {
	static testMethod void SalesCoachSetup() {
      SalesCoachSetup SCS = new SalesCoachSetup();
      System.assert(SCS.getShowSections()!=null);
      SCS.getScStage();
      System.assert(SCS.getScActivities()==null);
      System.assert(SCS.getSwi()==null);
      System.assert(SalesCoachSetup.getOpptyStages()!=null);
      System.assert(SCS.getSections()==null);
      SCS.saveSections();
      SCS.stage='Closed Won';
      SCS.getSections();
      SCS.stage='Prospecting';      
      System.assert(SCS.getSections()==null);
      SCS.saveActivities();
      SCS.saveStage();
      SCS.saveSections();
      SCS.deleteSection();
      SCS.deleteActivity();
      SCS.deleteSectionItem();
      System.debug('!!!!!!!!!!!!END OF TESTS!!!!!!!!!!!!!!!!!');
          } 
}
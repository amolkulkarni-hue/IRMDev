public with sharing class caseSolutionsController {
public ID caseID{get;set;} 
    public String searchSol {get;set;}
    public caseSolutionsController(ApexPages.StandardController controller) {
         caseID = ((case)controller.getRecord()).ID;
         fetchSolutions();
    }

    public  List<CaseSolution> caseSolutions {get;set;}
    
    public void fetchSolutions(){
        caseSolutions = [Select c.SystemModstamp, c.SolutionId,c.Solution.SOP_Link__c, c.IsDeleted,
                             c.Id, c.CreatedDate, c.CreatedById, c.CaseId ,c.solution.SolutionNumber , c.solution.SolutionName , c.solution.Status , c.solution.CreatedByID ,c.solution.CreatedBy.Alias From CaseSolution c
                             Where c.caseID = :caseID];  
                               System.debug('queries used: ' + Limits.getQueries());
               
    }   
}
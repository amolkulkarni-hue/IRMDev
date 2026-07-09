public class BillCodeTriggerHandler{
    /*public static void onBeforeInsert(List<pse__Milestone__c> newBillCodeList){
checkDuplicateRecord(newBillCodeList, null);
}*/
    public static void onBeforeUpdate(List<pse__Milestone__c> newBillCodeList, Map<Id,pse__Milestone__c> mapOfOldBillCode){
        checkDuplicateRecord(newBillCodeList, mapOfOldBillCode);
    }
    public static void onBeforeDelete(List<pse__Milestone__c> oldBillCodeList){
        preventForDelete(oldBillCodeList);
    }
    
    public static void onAfterDelete(List<pse__Milestone__c> oldBillCodeList){
        updateProjectFieldsAfterBillCodeDelete(oldBillCodeList);
        updateCountOnParentBillCode(oldBillCodeList);
        
    }
    
    public static void onAfterInsert(List<pse__Milestone__c> newRecords) {
        updateWIPAmountOnProject(newRecords); 
    } 
    
    public static void onAfterUpdate(List<pse__Milestone__c> newRecords, Map<Id, pse__Milestone__c> oldMap) {
        List<pse__Milestone__c> recordsToProcess = new List<pse__Milestone__c>();
        for (pse__Milestone__c newBillCode : newRecords) {
            pse__Milestone__c oldBillCode = oldMap.get(newBillCode.Id);

            // We only want to run the roll-up if the Units_Complete__c field has actually changed.
            if (newBillCode.Units_Complete__c != oldBillCode.Units_Complete__c) {
                recordsToProcess.add(newBillCode);
            }
        }

        // If any records met the criteria, call the roll-up logic.
        if (!recordsToProcess.isEmpty()) {
            updatedWIPAmountOnProjectAfterUpdate(recordsToProcess);
        }
    }


    public static void updatedWIPAmountOnProjectAfterUpdate(List<pse__Milestone__c> recordsToProcess) {
        
        Set<Id> allProjectIds = new Set<Id>();
        for (pse__Milestone__c billCode : recordsToProcess) {
            if (billCode.pse__Project__c != null) {
                allProjectIds.add(billCode.pse__Project__c);
            }
        }

        if (allProjectIds.isEmpty()) {
            return;
        }

        Map<Id, pse__Proj__c> multiMarketProjects = new Map<Id, pse__Proj__c>([
            SELECT Id, pse__Bookings__c,pse__Billing_Type__c
            FROM pse__Proj__c
            WHERE Id IN :allProjectIds AND Multiple_Markets__c = true
        ]);
        
        if (multiMarketProjects.isEmpty()) {
            return;
        }

        Map<Id, Decimal> projectToAmountCompleteSum = new Map<Id, Decimal>();
        Map<Id, Decimal> projectToUnitCostSum = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT pse__Project__c, SUM(Amount_Complete__c) totalAmount
            FROM pse__Milestone__c
            WHERE pse__Project__c IN :multiMarketProjects.keySet()
            AND Bill_Code_District_ID__c != NULL
            GROUP BY pse__Project__c
        ]) {
            Id projectId = (Id) ar.get('pse__Project__c');
            Decimal totalAmount = (Decimal) ar.get('totalAmount');
            projectToAmountCompleteSum.put(projectId, totalAmount);
        }
        // Query for Unit Complete Cost (Itemized Actual Total Cost)
          for (AggregateResult ar : [
          SELECT pse__Project__c, SUM(Units_Complete_Cost__c) totalCost
          FROM pse__Milestone__c
          WHERE pse__Project__c IN :multiMarketProjects.keySet()
          AND Bill_Code_District_ID__c != NULL
          GROUP BY pse__Project__c
          ]) {
          Id projectId = (Id) ar.get('pse__Project__c');
          Decimal totalCost = (Decimal) ar.get('totalCost');
          projectToUnitCostSum.put(projectId, totalCost);
        }
        
        // to calculate WIP amount
        List<pse__Proj__c> projectsToUpdate = new List<pse__Proj__c>();
        for (pse__Proj__c proj : multiMarketProjects.values()) {
            Decimal totalAmountComplete = projectToAmountCompleteSum.containsKey(proj.Id)
                ? projectToAmountCompleteSum.get(proj.Id)
                : 0;

             pse__Proj__c projUpdate = new pse__Proj__c(
                Id = proj.Id,
                WIP_Amount_Remaining__c = (proj.pse__Bookings__c != null ? proj.pse__Bookings__c : 0) - totalAmountComplete
            );
            //Only for Itemized billing type, update Actual_Total_Cost__c
    if (proj.pse__Billing_Type__c == 'Time and Materials') {
        Decimal totalUnitCost = projectToUnitCostSum.containsKey(proj.Id)
            ? projectToUnitCostSum.get(proj.Id)
            : 0;

       
                   projUpdate.Actual_Total_Cost__c = totalUnitCost;

    } 
            projectsToUpdate.add(projUpdate);

     }

        if (!projectsToUpdate.isEmpty()) {
            try {
                update projectsToUpdate;
            } catch (DmlException e) {
                System.debug('Could not update projects. Error: ' + e.getMessage());
            }
        }
    }
    
    
    public static void updateWIPAmountOnProject(List<pse__Milestone__c> newRecords) {
        
        Set<Id> allProjectIds = new Set<Id>();
        for (pse__Milestone__c billCode : newRecords) {
            if (billCode.pse__Project__c != null) {
                allProjectIds.add(billCode.pse__Project__c);
            }
        }

        if (allProjectIds.isEmpty()) {
            return;
        }

        Map<Id, pse__Proj__c> multiMarketProjects = new Map<Id, pse__Proj__c>([
            SELECT Id, pse__Bookings__c,pse__Billing_Type__c
            FROM pse__Proj__c
            WHERE Id IN :allProjectIds AND Multiple_Markets__c = true
        ]);
        
        if (multiMarketProjects.isEmpty()) {
            return;
        }

        Map<Id, Decimal> projectToAmountCompleteSum = new Map<Id, Decimal>();
        Map<Id, Decimal> projectToUnitCostSum = new Map<Id, Decimal>();

        for (AggregateResult ar : [
            SELECT pse__Project__c, SUM(Amount_Complete__c) totalAmount
            FROM pse__Milestone__c
            WHERE pse__Project__c IN :multiMarketProjects.keySet()
            AND Bill_Code_District_ID__c != NULL
            GROUP BY pse__Project__c
        ]) {
            Id projectId = (Id) ar.get('pse__Project__c');
            Decimal totalAmount = (Decimal) ar.get('totalAmount');
            projectToAmountCompleteSum.put(projectId, totalAmount);
        }
        // Query for Unit Complete Cost (Itemized Actual Total Cost)
          for (AggregateResult ar : [
          SELECT pse__Project__c, SUM(Units_Complete_Cost__c) totalCost
          FROM pse__Milestone__c
          WHERE pse__Project__c IN :multiMarketProjects.keySet()
          AND Bill_Code_District_ID__c != NULL
          GROUP BY pse__Project__c
          ]) {
          Id projectId = (Id) ar.get('pse__Project__c');
          Decimal totalCost = (Decimal) ar.get('totalCost');
          projectToUnitCostSum.put(projectId, totalCost);
        }

        List<pse__Proj__c> projectsToUpdate = new List<pse__Proj__c>();
        for (pse__Proj__c proj : multiMarketProjects.values()) {
            Decimal totalAmountComplete = projectToAmountCompleteSum.containsKey(proj.Id)
                ? projectToAmountCompleteSum.get(proj.Id)
                : 0;

            pse__Proj__c projUpdate = new pse__Proj__c(
                Id = proj.Id,
                WIP_Amount_Remaining__c = (proj.pse__Bookings__c != null ? proj.pse__Bookings__c : 0) - totalAmountComplete
            );
            //Only for Itemized billing type, update Actual_Total_Cost__c
    if (proj.pse__Billing_Type__c == 'Time and Materials') {
        Decimal totalUnitCost = projectToUnitCostSum.containsKey(proj.Id)
            ? projectToUnitCostSum.get(proj.Id)
            : 0;

       
                   projUpdate.Actual_Total_Cost__c = totalUnitCost;

    } 
            projectsToUpdate.add(projUpdate);

     }
        if (!projectsToUpdate.isEmpty()) {
            try {
                update projectsToUpdate;
            } catch (DmlException e) {
                System.debug('Could not update projects. Error: ' + e.getMessage());
            }
        }
    }
    
    public static void updateProjectFieldsAfterBillCodeDelete(List<pse__Milestone__c> deletedMilestones) {
    
    Set<Id> projectIds = new Set<Id>();
    
    // Collect related Project IDs
    for (pse__Milestone__c billCode : deletedMilestones) {
        if (billCode.pse__Project__c != null && billCode.Units_Complete_Cost__c != null) {
            projectIds.add(billCode.pse__Project__c);
        }
    }
    
    if (projectIds.isEmpty()) {
        return;
    }

    // Query all possible fields in one go
    Map<Id, pse__Proj__c> projectsMap = new Map<Id, pse__Proj__c>(
        [
            SELECT Id,
                   WIP_Amount_Remaining__c,
                   Actual_Total_Cost__c,
                   pse__Billing_Type__c,
                   Multiple_Markets__c
            FROM pse__Proj__c
            WHERE Id IN :projectIds
        ]
    );

    if (projectsMap.isEmpty()) {
        return;
    }
    
    // Aggregate values for both scenarios
    Map<Id, Decimal> wipDeductions = new Map<Id, Decimal>();
    Map<Id, Decimal> actualCostDeductions = new Map<Id, Decimal>();
    
    for (pse__Milestone__c billCode : deletedMilestones) {
        Id projId = billCode.pse__Project__c;
        
        if (projectsMap.containsKey(projId) && billCode.Units_Complete_Cost__c != null) {
            
            pse__Proj__c proj = projectsMap.get(projId);
            
            // Case 1: WIP Amount Remaining (when NOT Outcome billing & has multiple markets)
            if (proj.Multiple_Markets__c == true && proj.pse__Billing_Type__c != 'Outcome') {
                Decimal currentWip = wipDeductions.get(projId);
                if (currentWip == null) currentWip = 0;
                currentWip += billCode.Amount_Complete__c;
                wipDeductions.put(projId, currentWip);
            }
            
            // Case 2: Actual Total Cost (when Time and Materials & has multiple markets)
            if (proj.Multiple_Markets__c == true && proj.pse__Billing_Type__c == 'Time and Materials') {
                Decimal currentCost = actualCostDeductions.get(projId);
                if (currentCost == null) currentCost = 0;
                currentCost += billCode.Units_Complete_Cost__c;
                actualCostDeductions.put(projId, currentCost);
            }
        }
    }
    
    // Apply both updates in a single list
    List<pse__Proj__c> projectsToUpdate = new List<pse__Proj__c>();
    for (Id projId : projectsMap.keySet()) {
        pse__Proj__c proj = projectsMap.get(projId);
        Boolean needsUpdate = false;
        
        // Apply WIP Adjustment
        if (wipDeductions.containsKey(projId)) {
            Decimal deduction = wipDeductions.get(projId);
            proj.WIP_Amount_Remaining__c = (proj.WIP_Amount_Remaining__c != null ? proj.WIP_Amount_Remaining__c : 0) + deduction;
            needsUpdate = true;
        }
        
        // Apply Actual Cost Adjustment
        if (actualCostDeductions.containsKey(projId)) {
            Decimal deduction = actualCostDeductions.get(projId);
            proj.Actual_Total_Cost__c = (proj.Actual_Total_Cost__c != null ? proj.Actual_Total_Cost__c : 0) - deduction;
            needsUpdate = true;
        }
        
        if (needsUpdate) {
            projectsToUpdate.add(proj);
        }
    }
    
    // Perform one DML
    if (!projectsToUpdate.isEmpty()) {
        update projectsToUpdate;
    }
}


    
    public static void updateCountOnParentBillCode(List<pse__Milestone__c> oldBillCodeList){
        Set<Id> ParentBillCodeIds = new Set<Id>();
        for(pse__Milestone__c deletedMilestone : oldBillCodeList){
            if (deletedMilestone.Parent_Bill_Code__c != null) {
                ParentBillCodeIds.add(deletedMilestone.Parent_Bill_Code__c);
            }
            
        }
        
        if (ParentBillCodeIds.isEmpty()) {
            return;
        }
        
        Map<Id, AggregateResult> parentChildCounts = new Map<Id, AggregateResult>();
        for (AggregateResult ar : [
            SELECT Parent_Bill_Code__c, COUNT(Id) childCount 
            FROM pse__Milestone__c 
            WHERE Parent_Bill_Code__c IN :ParentBillCodeIds 
            GROUP BY Parent_Bill_Code__c
        ]) {
            Id parentId = (Id) ar.get('Parent_Bill_Code__c');
            parentChildCounts.put(parentId, ar);
        }
        
        List<pse__Milestone__c> parentsToUpdate = new List<pse__Milestone__c>();
        
        for (Id parentId : ParentBillCodeIds) {
            // Default the count to 0. If a parent has no remaining children, its count will be set to zero.
            Integer newChildCount = 0; 
            
            // If the parent ID exists in our map, it still has children. Get the new count.
            if (parentChildCounts.containsKey(parentId)) {
                newChildCount = (Integer) parentChildCounts.get(parentId).get('childCount');
            }
            
            // Create a pse__Milestone__c sObject in memory for the update list.
            parentsToUpdate.add(new pse__Milestone__c(
                Id = parentId,
                Total_Child_Bill_Codes__c = newChildCount
            ));
        }
        
         if (!parentsToUpdate.isEmpty()) {
            try {
                update parentsToUpdate;
            } catch (DmlException e) {
                // Best practice: Handle potential errors, e.g., by logging the error message.
                System.debug('Error updating parent Milestones: ' + e.getMessage());
            }
        }
    }
    
    public static void checkDuplicateRecord(List<pse__Milestone__c> newBillCodelst, Map<Id,pse__Milestone__c> mapOfOldBillCode ){
        Set<Id> setOfProjectIds = new Set<Id>();
        Set<Id> setOfProjectsBilingIds = new Set<Id>();
        
        // Check Duplicate Records from Validate parameters 
        for(pse__Milestone__c billCode : newBillCodelst){ 
            if(mapOfOldBillCode != null && (mapOfOldBillCode.get(billcode.Id).Name =='Project Services' || 
                                            mapOfOldBillCode.get(billcode.Id).Name =='Project Price Outcome') 
               && billCode.pse__Project__c != null
               && billCode.Name != mapOfOldBillCode.get(billcode.Id).Name){
                   System.debug('billCode.Name' + billCode.Name);
                   billCode.Name.addError('We cannot change bundle type billcode Name.');
               }
        }
    }
    public static void preventForDelete(List<pse__Milestone__c> oldBillCodeList){
        Set<Id> setOfProjectIds = new Set<Id>();
        Set<Id> setOfProjectIdsNew = new Set<Id>();
        Set<Id> accProjectsBilingIds = new Set<Id>();
        Map<Id, String> mapofProjectBillingType = new Map<Id, String>();
        
        for(pse__Milestone__c bill : oldBillCodeList){
            setOfProjectIds.add(bill.pse__Project__c);
        }
        // fetch billing type for project
        for(pse__Proj__c proj : [SELECT Id, pse__Billing_Type__c FROM pse__Proj__c WHERE Id IN :setOfProjectIds]){
            mapofProjectBillingType.put(proj.Id, proj.pse__Billing_Type__c);
            // Set Project Id Parameters
        }    
        for(pse__Milestone__c billCode : oldBillCodeList){
            String billingType = mapofProjectBillingType.get((billCode.pse__Project__c));
            if(billcode.Name =='Project Services' && billCode.pse__Project__c != null){
                if(billingType =='Bundle'){
                    setOfProjectIdsNew.add(billCode.pse__Project__c);
                }
            }
            else if(billcode.Name =='Project Price Outcome' && billCode.pse__Project__c != null){
                if(billingType =='Outcome'){
                    billCode.addError('You cannot delete outcome type record');
                }
                else if(billcode.Units__c > 0){
                    billcode.addError('This billcode cannot be deleted due to the units being greater than 0');
                }
            }
            else if(billcode.Units__c > 0){
                System.debug('Tst' + billcode.Units__c);
                billcode.addError('This billcode cannot be deleted due to the units being greater than 0');
            }
        }
        // Set Project Billing Id Parameters
        for(pse__Proj__c  project : [SELECT Id , (SELECT Id,Name FROM pse__Milestones__r WHERE Name = 'Project Services' and Bill_Code_District_ID__c =null) 
                                     FROM pse__Proj__c WHERE Id IN : setOfProjectIdsNew])
                                     {
                                         if(project.pse__Milestones__r.size() == 1){
                                             accProjectsBilingIds.add(project.Id);
                                         }    
                                     }
       for(pse__Milestone__c milestone : oldBillCodeList){
                if(accProjectsBilingIds.contains(milestone.pse__Project__c) && milestone.Bill_Code_District_ID__c == null){
        milestone.addError('You cannot delete this record one bundle type record required');
            }
        }
    }
}
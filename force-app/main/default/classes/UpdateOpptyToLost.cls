/**
 * Class: UpdateOpptyToLost
 *
 * Author: Akhila Veerabommala
 *
 * Date Created: 30.03.2022
 * 
 * Service Now ticket  #SCTASK0131605
 * 
 * Requirement :Continually update the Stage to 'Lost' for any Open Opportunities (in Stages 1 thru 4), owned by Role IMNA-US-SMB-RM-Inbound-BDA with a Close Date more than 30 days in the past.
 *
 * Purpose: UpdateOpptyToLost class fetches all the opportunity records which match
 * the user role and days in the past as in a custom setting, UpdateOpptyStagetoLost__c and
 * calls UpdateOpptyToLostInBatch class which updates the records to Lost stage
 * 
 */

global class UpdateOpptyToLost implements Schedulable{        
    global void execute(SchedulableContext ctx){
        try{
            
            List<Opportunity> OpportunitiesToBeLost = new List<Opportunity>();
            
            //Fetch all the list of (Role, DaysInThePast) from UpdateOpptyStagetoLost__c custom setting and store the set of Role and DaysInthePast values in RoleNDays variable
            List<UpdateOpptyStageToLost__c> RoleNDays=UpdateOpptyStageToLost__c.getAll().values();
            Map<String, Date> roleDays= new Map<String,Date>();
            
            //Map the Role and Date fetched in line 8
            for(UpdateOpptyStageToLost__c R : RoleNDays)
            {
                Date d = System.today() - R.DaysInThePast__c.intValue();
                String role=R.RoleId__c;
                roleDays.put(role,d);
            }
            
            //Get the list of opportunities with owner role in roleDays(Map)
            List<Opportunity> AllOppty=[Select id,Name,OwnerId,Owner.Name,Owner.UserRole.Name,Owner.Email,stageName,closeDate From Opportunity where Owner.UserRole.Id in: roleDays.keySet() and StageName in ('1 - Qualification','2 - Solution Developed','3 - Solution Agreed','4 - Negotiate')];
            
            //Filter out the opportunities based on closeDate days
            for(Opportunity oppty:AllOppty)
            {
                if(oppty.closeDate < roleDays.get(oppty.Owner.UserRole.Id))
                    OpportunitiesToBeLost.add(oppty);
            }
            
            //Proceed if the OpportunitiesToBeLost size is greater than zero
            if(OpportunitiesToBeLost .size() > 0){
                System.debug(OpportunitiesToBeLost.size());
                ID batchJob=Database.executeBatch(new UpdateOpptyToLostInBatch(OpportunitiesToBeLost), 50);
                 AsyncApexJob batchJobStatus = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                    FROM AsyncApexJob WHERE ID =: batchJob ];

                System.debug(batchJobStatus.status);
            }
        }
        catch(Exception e)
        {
            System.debug(e.getStackTraceString());
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'UpdateOpptyToLost');
        }
        
    }
}
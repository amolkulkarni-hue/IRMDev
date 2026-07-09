/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   BillingsToBoBCoverage_LauncherCont (Class)
**
** PURPOSE
**   Supports the BillingsToBoBCoverage_Launcher Visualforce page, which
**   provides a simple user interface for executing the batch job.
**
** NOTES
**
** BUNDLE SUMMARY
**   See class BillingsToBoBCoverage_Master.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/03/11; Bill Cloward/Bluewolf; Iron Mountain SFDC Billings Data Project (Project a0b00000000FTkA); Initial release
**
************************************************************************/

/* Commenting the entire code as part of Gitlab #25402 */

public with sharing class BillingsToBoBCoverage_LauncherCont {
    
    public BillingsToBoBCoverage_LauncherCont(){
        
    }
}
/*    
    // name of Custom Setting to be passed to runBatch()
    @TestVisible String customSettingToUse = 'Production';
    @TestVisible String customSettingToUse1 = 'IME Production';
    @TestVisible String customSettingToUse2 = 'IME M4 Production';
    @TestVisible String m4currentYearField = 'M4_CY_YTD__c';
    @TestVisible String m4previousYearField = 'M4_PY__c';
    @TestVisible ID processID;
            
    //-----------------------------------------------------------------------------    
    // launch the batch job
    public void runBatch () { 
       
        BillingsToBoBCoverage_Master master = new BillingsToBoBCoverage_Master(customSettingToUse);
        master.runBatch();    
    
    } // runBatch  
    
    public void runBatch1 () { 
       
        BillingsToBoBCoverage_Country_Master master = new BillingsToBoBCoverage_Country_Master(customSettingToUse1);
        master.runBatch();    
    
    } 
    
    public void runSyncjob(){
        BillingsToBoBCoverage_SyncIMGA_Name job=new BillingsToBoBCoverage_SyncIMGA_Name(customSettingToUse);
        DataBase.ExecuteBatch(job,2000);
    }

    
    public void runSyncjob1(){
        BillingsToBoBCoverage_Country_Sync_Name job=new BillingsToBoBCoverage_Country_Sync_Name(customSettingToUse1);
        DataBase.ExecuteBatch(job,2000);
    }
    
    //----------------------------------------------------------------------------- 
    // specify which Custom Settings record to use
    // returns true if successful, or false if there is no Custom Setting by that name
    public Boolean setSettingsName (String settingsName) {
        Integer settingsFound;
        
       
            // does the specified Custom Setting exist?
            settingsFound = [ SELECT COUNT()
                                FROM BillingsToBoBCoverageJoins__c
                               WHERE Name = :settingsName ];
      
        
        // found the specified Custom Setting?
        if (settingsFound > 0) {
            system.debug('changing Custom Setting name to: ' + settingsName);
            customSettingToUse = settingsName;
            return true;
        }
        else {
            system.debug('getSettingsName: no Custom Setting named: ' + settingsName);
            return false;           
        }
        
    } // setSettingsName
    
    public void runTerritorySnapshotBatch(){
        TerritorySnapshotBatch job = new TerritorySnapshotBatch();
        DataBase.ExecuteBatch(job,TerritorySnapshotBatch.BATCH_SCOPE_SIZE);
    }
    public void runCurrentEndingBalanceBatch(){
        EndingBalanceBatch job = new EndingBalanceBatch();
        DataBase.ExecuteBatch(job,EndingBalanceBatch.BATCH_SCOPE_SIZE);
    }
    public void runInboundStorageBatchJob(){
        M1_Physical_CDE_Batch job = new M1_Physical_CDE_Batch(customSettingToUse, 'M1_Joins_' + DateTime.now().format('MM/dd_HH:mm:ss'));
        processID = DataBase.ExecuteBatch(job,50);
    }
    
    public void runM4AggregateStorageBatchJob(){
        M4AggregateStorageRevenueBatch job = new M4AggregateStorageRevenueBatch(M4AggregateStorageRevenueBatch.BILLING_CY_H1, M4AggregateStorageRevenueBatch.Aggregate_CY_H1 );
        job.BATCH_SCOPE_SIZE = integer.valueOf(Label.Default_Scope_Size);
        
        M4AggregateStorageRevenueBatch job2 = new M4AggregateStorageRevenueBatch(M4AggregateStorageRevenueBatch.BILLING_CY_H2, M4AggregateStorageRevenueBatch.Aggregate_CY_H2 );
        job2.BATCH_SCOPE_SIZE = integer.valueOf(Label.Default_Scope_Size);
        
        Database.ExecuteBatch(job, job.BATCH_SCOPE_SIZE);
        processID = Database.ExecuteBatch(job2, job.BATCH_SCOPE_SIZE);
    }
    
    public void runM4AggregateStorageBatchJob1(){
    
    BillingsToBoBCoverage_Country_M4_Master master = new BillingsToBoBCoverage_Country_M4_Master (customSettingToUse2);
    master.runBatch();  
    }
    
    public void runM4AggregateStorageBatchJobPY(){
        
        M4AggregateStorageRevenueBatch job = new M4AggregateStorageRevenueBatch(M4AggregateStorageRevenueBatch.BILLING_PY_H1, M4AggregateStorageRevenueBatch.Aggregate_PY_H1 );
        job.BATCH_SCOPE_SIZE = integer.valueOf(Label.Default_Scope_Size);
        
        M4AggregateStorageRevenueBatch job2 = new M4AggregateStorageRevenueBatch(M4AggregateStorageRevenueBatch.BILLING_PY_H2, M4AggregateStorageRevenueBatch.Aggregate_PY_H2 );
        job2.BATCH_SCOPE_SIZE = integer.valueOf(Label.Default_Scope_Size);
        
        Database.ExecuteBatch(job, job.BATCH_SCOPE_SIZE);
        processID = Database.ExecuteBatch(job2, job.BATCH_SCOPE_SIZE);
    }
    
    public void startInboundAssignment(){
        Batch_Setting__c settings = Batch_Setting__c.getInstance('Inbound Assignment');
        String currentCommissionYear = System.Label.Current_Commission_Year;
        String query = 'SELECT ID,Customer_Account__r.Id,Opportunity__c,Association_to_Opportunity_Status__c,Dept_ID_del__c,Div_ID_del__c,Storage_Date__c FROM Inbound_Storage__c WHERE CALENDAR_YEAR(Storage_Date__c) = '+ currentCommissionYear +' '+ settings.Query_Condition__c;
        //query = String.escapeSingleQuotes(query);
        BatchInboundStorageAssignment batch_job = new BatchInboundStorageAssignment(query);
        Id batch_id = Database.executeBatch(batch_job,Integer.valueOf(settings.Batch_Size__c)); 
    }
    
    public void startAccountPrioritizationBatch(){
        Priority_Batch_Settings__c settings = [SELECT Id, Name, Batch_Size__c FROM Priority_Batch_Settings__c ORDER BY Created_Date__c DESC LIMIT 1];
        AccountPrioritizationBatch job = new AccountPrioritizationBatch();
        Id jobId = Database.executeBatch(job, Integer.valueOf(settings.Batch_Size__c));
    }
    
    public void startProspectingEntryCreationBatch(){
        ProspectingEntryCreationBatch b = new ProspectingEntryCreationBatch();
        Id jobId = Database.executeBatch(b, Integer.valueOf(b.settings.Batch_Size__c));
    }
    
} // BillingsToBoBCoverage_LauncherCont
*/
/**
Author       : Andrey Volosevich
Company      : Fujitsu America
Created Date : 22 Dec-2009
Description  : Controller for custom VF page that allows execute Field Synchronization Apex Batch Job
               This is a pilot version.
               
Author       : Abhay Gupta
Company      : Patni Computer Systems Ltd.
Modified Date: 12-May-2011
Description  : Modified Controller for custom VF page that allows execute Manual Oppshare delete and insert Apex Batch Job.                              

Author       : Nagesh Earamti
Company      : HCL
Modified Date: Aug 24 2011
Description  : Modified Controller for custom VF page that allows execute Manual Case count on Cutomser Account Apex Batch Job.                              

Author       : Matthew Keasling
Company      : Bluewolf
Modified Date: 22-Apr-2014
Description  : Modified Controller to add new Batch Job start method: startAccountPrioritizationBatch()

Author       : Vinutha Iyengar
Modified Date: 15-Mar-2019
Case         : 09542928
Description  : Modified Controller to 
                1. Remove Instance name hardcoding 
                2. Remove invalidate email feature, functioanlity moved out (04867369)
                3. Test method cannot reside inside non-test classes, so moved test method to BatchJobsManagerTest
*/

public class BatchJobsManager {
    
    public String error {get; private set;}
    public static final Integer queueLimit = 5; //maximum number of jobs that can be stored in the queue.
    @TestVisible public boolean runningTest{get; private set;}
   
    
    public void startSynchFieldValuesJob(){    
         
    system.debug('runningTest=='+runningTest);
        try{
            AsyncApexJob [] activeJobs = new List<AsyncApexJob>(
                [select Id From AsyncApexJob where Status IN ('Queued', 'Processing')and jobtype !='BatchApexWorker']);
            
            if(activeJobs.size()<queueLimit ||  runningTest){       
                SynchronizeFieldValues job = new SynchronizeFieldValues();
                Id jobId = Database.executeBatch(job);
                
                error = '';
            }
            else{
                error = ' Attempted to schedule too many concurrent batch jobs. Only up ' + queueLimit + ' active jobs can be running or scheduled at the same time.Account Synchronize Batch';
            }
        }
        catch(System.Exception e){
            ApexPages.addMessages(e);
        }
    }
    
      
    public void startOppsharedeletebatchclassJob(){
        
        try{
            AsyncApexJob [] activeJobs = new List<AsyncApexJob>([select Id From AsyncApexJob where Status IN ('Queued','Processing')and jobtype !='BatchApexWorker']);
            
            if(activeJobs.size()<queueLimit ||  runningTest){       
                List <Country_Settings__c> country_list = Country_Settings__c.getall().values();
                if(country_list.size()>0){
                    Oppshare_delete_new_batch_class job = new Oppshare_delete_new_batch_class();
                    Id jobId = Database.executeBatch(job,2000);
                    error = '';
                }
                else{
                     error = 'There were no country values in custom setting';
                }
            }
            else{
                error = ' Attempted to schedule too many concurrent batch jobs. Only upto ' + queueLimit + ' active jobs can be running or scheduled at the same time.Opp Share delete batch';
            }
        }
        catch(System.Exception e){
            ApexPages.addMessages(e);
        }
    }
    /*Code written as part of Case 00443373
    Author: Raj Gottipolu*/
    public void startForecastDateAmountbatchclassJob(){
        
        try{
            AsyncApexJob [] activeJobs = new List<AsyncApexJob>([select Id From AsyncApexJob where Status IN ('Queued','Processing')and jobtype !='BatchApexWorker']);
            
            if(activeJobs.size()<queueLimit ||  runningTest){       
                CurrentMonthForecast_Populate_batchclass job = new CurrentMonthForecast_Populate_batchclass();
                Id jobId = Database.executeBatch(job,200);
                
                error = '';
            }
            else{
                error = ' Attempted to schedule too many concurrent batch jobs. Only upto ' + queueLimit + ' active jobs can be running or scheduled at the same time.Opp Share delete batch';
            }
        }
        catch(System.Exception e){
            ApexPages.addMessages(e);
        }
    }
    
    public void startOppshareinsertbatchclassJob(){
        
        try{
            AsyncApexJob [] activeJobs = new List<AsyncApexJob>([select Id From AsyncApexJob where Status IN ('Queued','Processing')and jobtype !='BatchApexWorker']);
            
            if(activeJobs.size()<queueLimit ||  runningTest){       
                Oppshare_insert_batch_class job = new Oppshare_insert_batch_class();
                Id jobId = Database.executeBatch(job,2500);
                
                error = '';
            }
            else{
                error = ' Attempted to schedule too many concurrent batch jobs. Only upto ' + queueLimit + ' active jobs can be running or scheduled at the same time.Opp share insert batch';
            }
        }
        catch(System.Exception e){
            ApexPages.addMessages(e);
        }
    } 
    
    public void sampleMethod(){
        String a = 'a';
        String b = 'b';
        String c = 'c';
        String d = 'd';
        String e = 'e';
    }
}
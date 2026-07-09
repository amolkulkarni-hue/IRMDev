/****************************** 
   Developer Name    : Madhu Paladugu
   
   Date              : 6/25/13
   
   Company Name      : CloudFountain Inc.
   
   Purpose           : This class is used as a Controller for VF Page(ChatterActionOnCase) which provides the chatter functionality to submit for IT developemnt,Approve UAT or Approve for prod from Chatter it self. 
   
   Test Class        : Test_ChatterActionOnCaseController.
   
   Case Number       : 01512696
   
   * Modified By     : Keerthi Senthilnathan on 22-June-2017
   *           -- Removed the reference to Development_Priority__c for case # 05142766
   * Modified By     : TCS
                        2022/06/08; TCS ; #8989 Delete 10 case field deletion :- Part 1;  
                        Part of the #8989 story commented Target_Prod_Deployment_Date__c,estimated_it_dev_effort_hrs__c the field reference.
                        2022/06/08; TCS ; #8991 Delete 10 case field deletion :- Part 3;  
                        Part of the #8991 story commented Target_Development_Completion_Date__c,Estimated_Dev_Effort_hrs__c,IM_Division_Impacted__c the field reference.
 ********************************/  

public with sharing class ChatterActionOnCaseController {
    public case curcaseid=new case();
    public case updateCase=new Case();
    public Boolean refreshPage {get; set;}
    public Boolean showCancelButton {get; set;}
    public Boolean ShowITDev{get;set;}
    public Boolean ShowUAT{get;set;}
    public Boolean ShowProd{get;set;}
   
    //Constructor method
    public ChatterActionOnCaseController(ApexPages.StandardController controller) {
        refreshPage=false;
        curcaseid=(Case)controller.getrecord();
       
        UpdateCase=[select id,Status,Development_Status__c,Case_Category__c,
                            Case_Sub_Category__c,Sales_Tools_Ranking__c,Change_Control_Required__c,
                            Development_Completion_Date__c
                    		//Estimated_IT_Dev_Effort_hrs__c
                            //IM_Division_Impacted__c
                    		//Estimated_Dev_Effort_hrs__c
                    		//Target_Development_Completion_Date__c
                            //Target_Prod_Deployment_Date__c 
                            from case 
                            where id=:curcaseid.id];
        if(UpdateCase.Status=='Closed' || UpdateCase.Development_Status__c=='12. Pending Change Control Approval' || UpdateCase.Development_Status__c=='13. Ready for Prod Deployment' || UpdateCase.Development_Status__c=='14. Released to Production'){
           system.debug('++++++++++status is closed+++++++');
            ShowITDev=true;
            ShowUAT=true;
            ShowProd=true;
        }
        else if(UpdateCase.Development_Status__c=='10. Pending Business Approval in UAT' || UpdateCase.Development_Status__c=='11. UAT On Hold' ){
            system.debug('++++++++++dont allow IT,Uat++++++++');
            ShowITDev=true;
            ShowUAT=true;
           
        }
        else {
           system.debug('+++++++++++++dont allow prod+++++++');          
           ShowProd=true;
        }
       
    }
       
    
    //method to submit case to it development
    public void SubmitToIT(){
           
            if(UpdateCase.Change_Control_Required__c==false){
                
                UpdateCase.Change_Control_Required__c=true;
            }
            // As per the case(no 05142766), Development_Priority__c has been deleted 
            /*if(UpdateCase.Development_Priority__c==null){
                
                if(UpdateCase.Sales_Tools_Ranking__c=='1. High'){
                    UpdateCase.Development_Priority__c='2';
                }
                else if(UpdateCase.Sales_Tools_Ranking__c=='2. Medium'){
                    UpdateCase.Development_Priority__c='4';
                }
                else{
                    UpdateCase.Development_Priority__c='5';
                }
                
            }*/
            /* #8991 Delete 10 case field deletion :- Part 3 "Target_Development_Completion_Date__c" */
            /*if(UpdateCase.Target_Development_Completion_Date__c==null){
                
                if(UpdateCase.Estimated_IT_Dev_Effort_hrs__c<=20 || UpdateCase.Estimated_IT_Dev_Effort_hrs__c==null){
                    UpdateCase.Target_Development_Completion_Date__c=Date.Today().addDays(7);
                }
                else if(UpdateCase.Estimated_IT_Dev_Effort_hrs__c>20 && UpdateCase.Estimated_IT_Dev_Effort_hrs__c<=40){
                    UpdateCase.Target_Development_Completion_Date__c=Date.Today().addDays(14);
                }
                else{
                    UpdateCase.Target_Development_Completion_Date__c=Date.Today().addDays(30);
                }
            }*/
            /* #8991 Delete 10 case field deletion :- Part 3 "IM_Division_Impacted__c" */
            /*if(UpdateCase.IM_Division_Impacted__c==null){
                UpdateCase.IM_Division_Impacted__c='Global';
            }*/
            if(UpdateCase.Case_Sub_Category__c!='IT Development'){
                 UpdateCase.Case_Sub_Category__c='IT Development';
            }
            /*if(UpdateCase.Target_Prod_Deployment_Date__c==null || UpdateCase.Target_Development_Completion_Date__c > UpdateCase.Target_Prod_Deployment_Date__c){
                UpdateCase.Target_Prod_Deployment_Date__c=UpdateCase.Target_Development_Completion_Date__c.addDays(21);
            }*/
            UpdateCase.Status='In Progress';
            UpdateCase.Development_Status__c='4. Initial Development';
            
            try{
                 CollaborationGroup CG = [Select c.Name, c.Id From CollaborationGroup c where c.Name='NA_IT_DEVELOPMENT'];
                
                 //Chatter post
                 List<FeedItem> postList=new List<FeedItem>();
                  
                  FeedItem chatterpost = new FeedItem(); 
                  chatterpost.ParentId = CG.Id;
                  chatterpost.Body = 'Case has been submitted for IT development.';
                  chatterpost.LinkUrl=URL.getSalesforceBaseUrl().toExternalForm() + '/' + UpdateCase.id;                
                  postList.add(chatterpost);
                  
                  FeedItem post = new FeedItem(); 
                  post.ParentId = UpdateCase.Id;
                  post.Body = 'Case has been submitted for IT development.';
                  postList.add(post);
                  
                  insert  postList; 
                                 
                  update UpdateCase;
                  refreshPage=true;
             
           }
           catch(dmlException e){
               ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(0));
                ApexPages.addMessage(myMsg);
                showCancelButton=true; 
           }
        
    }
    
    //appprove uat method
    public void ApproveUAT(){
        
            try{
                if(UpdateCase.Case_Sub_Category__c=='IT Development' && UpdateCase.Development_Completion_Date__c==null){
                    UpdateCase.Development_Completion_Date__c=Date.Today();
                }
                /* #8991 Delete 10 case field deletion :- Part 3 "IM_Division_Impacted__c" */
            	/*if(UpdateCase.IM_Division_Impacted__c==null){
                    UpdateCase.IM_Division_Impacted__c='Global';
                }*/
                /*if(UpdateCase.Target_Prod_Deployment_Date__c==null || UpdateCase.Target_Prod_Deployment_Date__c < Date.today() || UpdateCase.Case_Sub_Category__c=='IT Development'){
                    UpdateCase.Target_Prod_Deployment_Date__c=Date.Today().addDays(14);
                }*/
                if(UpdateCase.Status!='In Progress'){
                    UpdateCase.Status='In Progress';
                }
                UpdateCase.Development_Status__c='8. Ready for UAT Deployment';
                
                  // chatter post
                  FeedItem post = new FeedItem(); 
                  post.ParentId = UpdateCase.Id;
                  post.Body = 'Case has been approved for UAT.';
                  insert post;
                
                system.debug('++++++++++++case to update in uat++++++++'+UpdateCase);
                 update UpdateCase;
                 refreshPage=true;
              
            }
            catch(DmlException e){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(0));
                ApexPages.addMessage(myMsg); 
                showCancelButton=true;
            }
    }
    
    //method approved for prod
    public void ApproveProd(){
                
            try{    
                
                if(UpdateCase.Target_Prod_Deployment_Date__c==null || UpdateCase.Target_Prod_Deployment_Date__c < Date.today()){
                    UpdateCase.Target_Prod_Deployment_Date__c=Date.Today().addDays(7);
                }
                UpdateCase.Development_Status__c='12. Pending Change Control Approval';
                // chatter post
                  FeedItem post = new FeedItem(); 
                  post.ParentId = UpdateCase.Id;
                  post.Body = 'Case has been approved for production.';
                  insert post;
                
                 system.debug('++++++++++++case to update in prod++++++++'+UpdateCase);
                 update UpdateCase;
                 refreshPage=true;
              }
              catch(dmlException e){
                 ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(0));
                 ApexPages.addMessage(myMsg); 
                 showCancelButton=true;
              }
    }
    
    //Cancel Button
    public pageReference Cancel(){
         refreshPage=true;
         return null;
      }
}
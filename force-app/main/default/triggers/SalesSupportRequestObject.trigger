/*COMBINATION OF ALL TRIGGERS ON Sales_Support_Request__c OBJECT 
**IN REFERNCE TO CASE 00924109
**AUTHOR: SRINIVASA RAO MANDALAPU
**DATE: 12/03/2012
*/
trigger SalesSupportRequestObject on Sales_Support_Request__c (before insert, before update) {
    /****Variable declaration for 'SalesSupportRequestTrigger' Trigger****/
    public String SalesSupportRequestTrigger = null;
    public Boolean runSalesSupportRequestTrigger = false;
    
    /***Retrieving Custom Settings***/
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='Sales_Support_Request__c'){
            if(cs.Trigger__c == 'SalesSupportRequestTrigger') {
                SalesSupportRequestTrigger = cs.Value__c; 
                System.debug('----------SalesSupportRequestTrigger:'+SalesSupportRequestTrigger);   
            }
        }
    }
    
    /*****************************************START TRIGGER*************************************************/

    /*****************************************BEFORE INSERT AND UPDATE*****************************/
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            runSalesSupportRequestTrigger=true;  
            System.debug('+++++28+++++++runSalesSupportRequestTrigger:'+runSalesSupportRequestTrigger);
            }   

        if(Trigger.isUpdate){
            runSalesSupportRequestTrigger=true;  
            System.debug('++++++32++++++runSalesSupportRequestTrigger:'+runSalesSupportRequestTrigger);
            if(SalesSupportRequestTrigger == 'true') {
            List<Sales_Support_Request__c> openChildsList = [ SELECT ID,Status__c,Parent_Sales_Support_Request__c from Sales_Support_Request__c
                                                              Where Parent_Sales_Support_Request__c  IN :Trigger.newMap.keySet() and Status__c != 'Closed'];
                                                              
            if(openChildsList.Size() > 0 ){
            for(Sales_Support_Request__c ssrs: Trigger.New ){
            if (ssrs.Status__c == 'Closed') {
            ssrs.addError('You can’t close the Request because it has open Child Request');
            }
            }           
            }
                                                               
            }
        }
        if(Trigger.isDelete){}
    }
       
    /*************************************END OF BEFORE INSERT AND UPDATE**************************/
    
    
    /*********************************************AFTER INSERT AND UPDATE**************************/
    /*************************************END OF AFTER INSERT AND UPDATE***************************/
    
    /**************************************************END TRIGGER******************************************/
    
    /****SalesSupportRequestTrigger****/
    /*---start---*/
     System.debug('-----48-----Firing SalesSupportRequestTrigger:'+SalesSupportRequestTrigger);
     if(SalesSupportRequestTrigger == 'True'){
        if(runSalesSupportRequestTrigger==true){
            System.debug('+++++28+++++++runSalesSupportRequestTrigger:'+runSalesSupportRequestTrigger);
            Set<Id> UserIdsFromCustomSettings=new Set<Id>();
            List<Sales_Support_Request_Users__c> allowedusers=Sales_Support_Request_Users__c.getAll().values();
                
            for(Sales_Support_Request_Users__c s:allowedusers){
                 UserIdsFromCustomSettings.add(s.UserId__c);
            }
            if(Trigger.isBefore)
            {
                if(Trigger.isInsert || Trigger.isupdate)
                {
                    for(Sales_Support_Request__c ssr:Trigger.new)
                    {
                    //    if(UserIdsFromCustomSettings.contains(ssr.OwnerId)&& ssr.Assigned_Date__c==null /*&& ssr.Assigned_To__c!=null*/){
                    //        ssr.Assigned_Date__c=DateTime.now(); 
                    //    } 
                        System.debug('---57---ssr.Task_Type__c:'+ssr.Task_Type__c);
                        if(ssr.Task_Type__c != 'IMPD' && ssr.Sales_Rep__c==null)
                        {
                            ssr.Sales_Rep__c = userInfo.getUserId();
                            System.debug('---60----ssr.Sales_Rep__c:'+ssr.Sales_Rep__c);
                        }
                    }
                    
                }
                if(Trigger.isupdate){
                 for(Sales_Support_Request__c ssr:Trigger.new)
                    {
                    if(String.valueof(Trigger.oldMap.get(ssr.id).OwnerId).startsWith('00G') && String.valueof(Trigger.newMap.get(ssr.id).OwnerId).startsWith('005')){
                    ssr.Assigned_Date__c=DateTime.now(); 
                    }
                  }
                }
            }

        }       
     }
    /****SalesSupportRequestTrigger****/
    /*---end---*/
    System.debug('-------queries has been executed by end of SalesSupportRequestObject trigger:'+Limits.getQueries());
    System.debug('-------DML Used by end of SalesSupportRequestObject trigger:'+Limits.getDMLStatements()); 
    // ---------------------------- For queue assignment purpose ------------------------------ //   
    /*if(SalesSupportRequestTrigger == 'True'){
        if(Trigger.isBefore && Trigger.isInsert) {
            Map<string,string> divisionMap= new Map<string,string>();
            List<QueueSobject> queueList = [select queueid, queue.developername from QueueSobject where SobjectType =: 'Sales_Support_Request__c'];
            for(QueueSobject qList :queueList)
                divisionMap.put(qList.queue.developername,qList.queueId);
            User u =[Select division from user where id=:userinfo.getuserid()];
            for(Sales_Support_Request__c ssr:Trigger.new) { 
                 if(u.Division == 'IME')
                     ssr.OwnerId = divisionMap.get('IME_Sales_Support_Queue');
                 else if(u.Division == 'IMLA')
                     ssr.OwnerId = divisionMap.get('IMLA_Sales_Support_Queue');
                 else if(u.Division == 'IMAP') 
                     ssr.OwnerId = divisionMap.get('IMAP_Sales_Support_Queue');
                 else
                     ssr.OwnerId = divisionMap.get('NA_Sales_Support');                     
             }
            
        }
    }*/
}
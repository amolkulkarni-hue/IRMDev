/* Commenting the entire code as part of Gitlab #24448 */
global class BatchInboundStorageAssignment{
    public BatchInboundStorageAssignment(){
        
    }
}
/*
global class BatchInboundStorageAssignment implements Database.Batchable<sObject> {
    global String query; 
    global String type;
    global String status_matched; 
    global String status_unmatched; 

    global BatchInboundStorageAssignment(String query){
        this.query = query;
    }

    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(query);
    }

    //delete this 
    //[SELECT Id,Dept_ID_del__c,Div_ID_del__c,IM_Customer_Account__r.Id FROM Inbound_Storage__c ]
    global void execute(Database.BatchableContext bc, List<SObject> scope){
        String currentCommissionYear = System.Label.Current_Commission_Year;
        Boolean caught_error = false;
        Map<Id,List<Inbound_Storage__c>> acctids_storageLst = new Map<Id,List<Inbound_Storage__c>>(); 
        //map to hold acct to cases data: account Id -> case list 
        Map<Id,List<Case>> acctid_caseLst = new Map<Id,List<Case>>();
        List<Inbound_Storage__c> inbslSTforDMLOpperation = new List<Inbound_Storage__c>();
        Batch_Setting__c settings = Batch_Setting__c.getInstance('Inbound Assignment');
        Date cutOffDate = settings.Cut_Off_Date__c;
        try{
            for(SObject s : scope){
                Inbound_Storage__c in_storage = (Inbound_Storage__c)s;
                //map customer accts to inbound storage for final opp assignment and status 
                if(!acctids_storageLst.containsKey(in_storage.Customer_Account__r.Id)){
                    List<Inbound_Storage__c> ibnsLSt = new List<Inbound_Storage__c>();
                    ibnsLSt.add(in_storage);
                    acctids_storageLst.put(in_storage.Customer_Account__r.Id, ibnsLSt);
                }else{
                    acctids_storageLst.get(in_storage.Customer_Account__r.Id).add(in_storage);
                }
            }
            //create map acctid_caseLst with empty caseLst to make sure all account in the map has a list to avoid NPE
            for(Id acctId: acctids_storageLst.keySet()){
                acctid_caseLst.put(acctId,new List<Case>());
            }
            //find all the new customer setup cases for each customer accts, via the record type name
            for(Case c : [SELECT NCSP_Opportunity__r.Id
                                 ,NCSP_Opportunity__r.Type
                                 ,New_Division_ID__c
                                 ,New_Department_ID__c 
                                 ,NCSP_Opportunity__r.First_Bill_Booked_Date__c
                                 ,NCSP_Opportunity__r.Commissionable_Window_Close_Date__c
                                 ,NCSP_Opportunity__r.CloseDate
                                 ,Customer_ID__r.Id
                           FROM Case 
                           WHERE Customer_ID__c IN :acctids_storageLst.keySet() 
                             AND NCSP_Opportunity__c != null 
                             AND NCSP_Opportunity__r.CloseDate >= :cutOffDate
                             AND (RecordType.Name = 'NCSP: SKP New Customer Setup' OR RecordType.Name = 'NCSP: SKP Department Add Only' OR RecordType.Name = 'NCSP: Upsell')]){
                //add case into the map: acctid_caseLst
                acctid_caseLst.get(c.Customer_ID__r.Id).add(c);
            }
            for(Id acctId : acctids_storageLst.keySet()){
                //first check if we have 0 cases - if not, we start looking for the opp
                if(acctid_caseLst.get(acctId)!=null && acctid_caseLst.get(acctId).size() != 0){
                    //if only one, that's the opp and continue
                    if(acctid_caseLst.get(acctId).size() == 1){
                        for(Inbound_Storage__c ibns : acctids_storageLst.get(acctId)){
                            if((acctid_caseLst.get(acctId).get(0).NCSP_Opportunity__r.CloseDate < ibns.Storage_Date__c 
                                || acctid_caseLst.get(acctId).get(0).NCSP_Opportunity__r.CloseDate.monthsBetween(ibns.Storage_Date__c)==0)
                                && ibns.Storage_Date__c < acctid_caseLst.get(acctId).get(0).NCSP_Opportunity__r.Commissionable_Window_Close_Date__c){
                                ibns.Opportunity__c = acctid_caseLst.get(acctId).get(0).NCSP_Opportunity__r.Id; 
                                ibns.Association_to_Opportunity_Status__c = getStatus(acctid_caseLst.get(acctId).get(0).NCSP_Opportunity__r.Type);
                                //set the associated date 
                                ibns.Associated_to_Opportunity_Date__c = Datetime.now();
                                continue;
                            }
                            else{
                                ibns.Association_to_Opportunity_Status__c = 'Unmatched';
                            }
                        }
                    }
                    //otherwise we start paring down the list 
                    else{
                        for(Inbound_Storage__c ibns : acctids_storageLst.get(acctId)){
                            InboundStorageAssignment inbound_assignment = new InboundStorageAssignment(acctid_caseLst.get(acctId),ibns); 
                            InboundStorageAssignment.OppStack match = inbound_assignment.getMatch(); 
                            if(match != null){
                                ibns.Opportunity__c = match.opp; 
                                ibns.Association_to_Opportunity_Status__c = getStatus(match.type); 
                                //set the associated date 
                                ibns.Associated_to_Opportunity_Date__c = Datetime.now();
                            }
                            else{
                                ibns.Association_to_Opportunity_Status__c = 'Unmatched';
                            }
                        }
                    }
                }
                //if it's 0 we set it to unmatched 
                else{
                    for(Inbound_Storage__c ibns : acctids_storageLst.get(acctId)){
                        ibns.Association_to_Opportunity_Status__c = 'Unmatched';
                    }
                }

            }
        }
        catch(Exception e){
            caught_error = true;
            Inbound_Storage_Error__c err = new Inbound_Storage_Error__c(Name = 'Inbound Assignment - ' + String.valueOf(Date.today())
                                                                        ,Type__c = e.getTypeName()
                                                                        ,Message__c = e.getMessage()
                                                                        ,Stack_Trace__c = e.getStackTraceString()
                                                                        ,Line_Number__c = e.getLineNumber()
                                                                        );
            insert err; 
        }
        if(!caught_error){
            for(List<Inbound_Storage__c> inbsLst : acctids_storageLst.values()){
                inbslSTforDMLOpperation.addAll(inbsLst);
            }
            List<Database.SaveResult> res = Database.update(inbslSTforDMLOpperation,false);
            List<Inbound_Storage_Error__c> errs = new List<Inbound_Storage_Error__c>(); 

            for(Database.SaveResult sr : res){
                if(!sr.isSuccess()){
                    for(Database.Error e : sr.getErrors()){
                        Inbound_Storage_Error__c err = new Inbound_Storage_Error__c(Name = 'Inbound Assignment - ' + String.valueOf(Date.today())
                                                                                    ,Message__c = e.getMessage()
                                                                                    ,Inbound_Storage__c = sr.getId());
                        errs.add(err);
                    }
                }
            }

            if(!errs.isEmpty()){
                insert errs; 
            }
        }  
    }

    public static String getStatus(String type){
        if(type == 'New Deal'){
            return 'Matched - Approved';
        }
        else{
            return 'Matched - Pending';
        }
    }
    global void finish(Database.BatchableContext bc){
        Batch_Setting__c settings = Batch_Setting__c.getInstance('Inbound Assignment');
        AsyncApexJob apex_job = [SELECT CompletedDate,TotalJobItems,NumberOfErrors FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = settings.Email_List__c.split(',');
        //String[] toAddresses = new String[] {'drahl@bluewolfgroup.com'};
        mail.setToAddresses(toAddresses);
        mail.setReplyTo('noreply@wherever.com');
        mail.setSenderDisplayName('Salesforce');
        mail.setSubject('Inbound Storage Assignment Completed');
        mail.setPlainTextBody('Completed Date: ' + apex_job.CompletedDate + '\nNumber of Errors: ' + apex_job.NumberOfErrors + '\nTotal Batches: ' + apex_job.TotalJobItems);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}*/
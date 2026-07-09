global class QTB_ScheduleDocumentSendDelete implements Schedulable {
    global void execute(SchedulableContext sc) { 
       
      Database.executeBatch(new QTB_BatchableDocumentSendDelete());   
     
        
       // QTB_ScheduleDocumentSendDelete dbs=new QTB_ScheduleDocumentSendDelete();

//String jobID = System.schedule('jobName','0 0 23 ? * * *',dbs);

    }   
}
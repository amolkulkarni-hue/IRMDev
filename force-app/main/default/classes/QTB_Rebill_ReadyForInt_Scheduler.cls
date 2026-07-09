/*****************************************************************************************************
* Class: QTB_Rebill_ReadyForInt_Scheduler
* Author: Lokesh Tewari / Pragathi B V
* Purpose: For checking Ready for Intgeration flag on Rebill Invoices
* Requirement: To iterate on the draft invoice lines
* Developer                 Date                    Description
* ------------------------------------------------------------------------------------------- 
Lokesh Tewari           24/05/2024         checking Ready for Intgeration flag on Rebill Invoices
*******************************************************************************************************/
global class QTB_Rebill_ReadyForInt_Scheduler implements Schedulable{
     global void execute(SchedulableContext sc) {
	    List<blng__Invoice__c> lstUpdatedInvc = new List<blng__Invoice__c>();
        // Calculate the time one hour ago from now
        DateTime oneHourAgo = DateTime.now().addHours(-1);
       
        // Query Account records modified in the last one hour
        List<blng__Invoice__c> lstRebillInvc = [SELECT Id, Name,QTB_Ready_for_Integration_Status__c,QTB_Invoice_Type__c, QTB_Rebilled__c, blng__InvoiceStatus__c, QTB_Ready_for_Integration__c, LastModifiedDate FROM blng__Invoice__c WHERE 
                                                QTB_Invoice_Type__c='ReBill' and QTB_Rebilled__c = true and blng__InvoiceStatus__c ='Posted' and 
                                                QTB_Ready_for_Integration__c = false and LastModifiedDate >= :oneHourAgo];
        
        // Update with the retrieved records
        if(!lstRebillInvc.isEmpty()){
        for (blng__Invoice__c invc : lstRebillInvc) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.id = invc.id;
            invoice.QTB_Ready_for_Integration__c = True;
            invoice.QTB_Ready_for_Integration_Status__c = 'Success';
            lstUpdatedInvc.add(invoice);
        }
            
            if(!lstUpdatedInvc.isEmpty()){
                 update lstUpdatedInvc;
            }
        }
         				Datetime dt1 = Datetime.now();
                	Datetime dt = dt1.addminutes(50);
                    Integer seconds = dt.second();
                    Integer minutes = dt.minute();
                    Integer hours = dt.hour();
                    Integer dayOfMonth = dt.day();
                    Integer month = dt.month();
                    Integer year = dt.year();
                    // Constructing the cron expression
                    String cronExpression = seconds + ' ' + minutes + ' ' + hours + ' ' +
                        dayOfMonth + ' ' + month + ' ? ' + year;
         
        System.schedule('ReBill Script Run '+ cronExpression, cronExpression, new QTB_Rebill_ReadyForInt_Scheduler());
    
         
    }
}
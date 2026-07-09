//*************************************************************************************
// Name:ScheduleForDeleteCaseAttachment
// Description: To Delete Case Attachment
// Created By: Vinod Kumar

// ************************Version Updates********************************************
//
// Updated Date     Updated By      Update Comments 
//  
// 
// ************************************************************************************
global class ScheduleForDeleteCaseAttachment implements schedulable {
    
    global void execute(SchedulableContext sc)
    { 
        start();
    } 
    public static void start() 
    {
       system.Debug('===============start()----------------');
       // Get RecordType
        Set<Id> recordTypeIds = new Set<Id>();
        List<Case> lstcase;
        Map<String,Schema.RecordTypeInfo> rtMapByName = RecordTypeSelection.getRecordTypeIds();
        if(rtMapByName.containsKey('NCSP: DMS'))
            recordTypeIds.add(rtMapByName.get('NCSP: DMS').getRecordTypeId());          
        if(rtMapByName.containsKey('NCSP: DP New Customer Setup'))
            recordTypeIds.add(rtMapByName.get('NCSP: DP New Customer Setup').getRecordTypeId());           
        if(rtMapByName.containsKey('NCSP: SKP Department Add Only'))
            recordTypeIds.add(rtMapByName.get('NCSP: SKP Department Add Only').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP: SKP New Customer Setup'))
            recordTypeIds.add(rtMapByName.get('NCSP: SKP New Customer Setup').getRecordTypeId()); 
            
       Datetime currentTime = Datetime.now(); 
       currentTime = currentTime.addDays(-7);
        if(Test.isRunningTest())
			lstcase=[Select ID from case where RecordTypeId in: recordTypeIds and (Status = 'Closed' or Status = 'Cancelled' or Status = 'Duplicate') and ClosedDate >:currentTime LIMIT 10];        
        else
    		lstcase=[Select ID from case where RecordTypeId in: recordTypeIds and (Status = 'Closed' or Status = 'Cancelled' or Status = 'Duplicate') and ClosedDate >:currentTime ];                
       //List<Case> lstcase=[Select ID from case where RecordTypeId in: recordTypeIds and (Status = 'Closed' or Status = 'Cancelled' or Status = 'Duplicate') and ClosedDate >:currentTime ];
       if( lstcase.size() > 0){
        List <EmailMessage> lstEmailMessage =[Select e.Id From EmailMessage e where e.ParentId in:lstcase];
        List<Attachment> lstAttachment = [Select ParentId, Id From Attachment where ParentId in:lstcase or ParentId in: lstEmailMessage];
        if(lstAttachment.size() > 0)
            delete lstAttachment;               
         system.Debug('===============Total no of attachment deleted ='+ lstAttachment.size());    
       }        
      
       system.Debug('===============Finish:start()---------------- No O' );  
     
    }
         
}
/*COMBINATION OF ALL TRIGGERS ON EVENT OBJECT 
**IN REFERNCE TO CASE 00924109
**AUTHOR: SRINIVASA RAO MANDALAPU
**DATE: 11/29/2012
*/
trigger EventObject on Event (before insert, before update, after insert, after update) {
    
    /****Variable declaration for 'CheckEventCreatedOnClosedCase' Trigger****/
    public String CheckEventCreatedOnClosedCase = null;
    public Boolean runCheckEventCreatedOnClosedCase = false;
    Set<Id> recordTypeIds = new Set<Id>();
    Map<ID,Event> mapEventCreated = new map<Id,Event>();
    
    /*****************************************START TRIGGER*************************************************/

    /*****************************************BEFORE INSERT AND UPDATE*************************************/
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            // Get recod id
            fillRecordTypeIds(); 
            
            /***Retrieving Custom Settings***/
            List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
            for(Trigger_Activation_Settings__c cs : customsettings){
                if(cs.Object__c=='Event'){
                    if(cs.Trigger__c == 'CheckEventCreatedOnClosedCase') {
                        CheckEventCreatedOnClosedCase = cs.Value__c; 
                        System.debug('----22------CheckEventCreatedOnClosedCase:'+CheckEventCreatedOnClosedCase);   
                    }
                }
            }
            /****CheckEventCreatedOnClosedCase****/
            /*---start---*/
             System.debug('-----34-----CheckEventCreatedOnClosedCase:'+CheckEventCreatedOnClosedCase);
             if(CheckEventCreatedOnClosedCase == 'True'){
                for(Event newEvent : trigger.new){
                    mapEventCreated.put(newEvent.WhatId,newEvent);
                }
                
                List<Case> lstCase = [select id ,isclosed,Status from Case where id in:mapEventCreated.keySet() and RecordTypeId in :recordTypeIds];
                if(lstCase.size() > 0){
                    for(Case c : lstCase){
                        if(c.isclosed == True && mapEventCreated.containsKey(c.ID)){
                            Event createdEvent = mapEventCreated.get(c.ID);
                            createdEvent.addError('Event cannot be created on a closed case');
                        }
                    }
                }
             }
            /****CheckEventCreatedOnClosedCase****/
            /*---end---*/   
        }
        if(Trigger.isUpdate){}
        if(Trigger.isDelete){}

        if(Trigger.isInsert || Trigger.isUpdate){
            ActivityService.getContactLevel(Trigger.new);
        }
    }   
    /*************************************END OF BEFORE INSERT AND UPDATE***************************/
    
    
    /*********************************************AFTER INSERT AND UPDATE*********************/
    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate){
            ActivityService.rollUp(trigger.new);
        }
    }
    
    /*************************************END OF AFTER INSERT AND UPDATE***************************/
    
    /**************************************************END TRIGGER*********************************************/
    
     private void fillRecordTypeIds(){
        Map<String,Schema.RecordTypeInfo> rtMapByName = CaseRecordTypeSelection.getRecordTypeIds();
        if(rtMapByName.containsKey('CAC_DP_Closure'))
            recordTypeIds.add(rtMapByName.get('CAC_DP_Closure').getRecordTypeId());
        if(rtMapByName.containsKey('CAC_SKP_RM'))
            recordTypeIds.add(rtMapByName.get('CAC_SKP_RM').getRecordTypeId());    
        if(rtMapByName.containsKey('CAC_SKP_Shred'))
            recordTypeIds.add(rtMapByName.get('CAC_SKP_Shred').getRecordTypeId());
        if(rtMapByName.containsKey('Issue'))
            recordTypeIds.add(rtMapByName.get('Issue').getRecordTypeId());
        if(rtMapByName.containsKey('Issues_Question'))
            recordTypeIds.add(rtMapByName.get('Issues_Question').getRecordTypeId());    
        if(rtMapByName.containsKey('Issue_Request'))
            recordTypeIds.add(rtMapByName.get('Issue_Request').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_DMS'))
            recordTypeIds.add(rtMapByName.get('NCSP_DMS').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_DP_Onboarding_team'))
            recordTypeIds.add(rtMapByName.get('NCSP_DP_Onboarding_team').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_SKP_Department_Add_Only'))
            recordTypeIds.add(rtMapByName.get('NCSP_SKP_Department_Add_Only').getRecordTypeId());
        if(rtMapByName.containsKey('NCSP_SKP_New_customer_setup'))
            recordTypeIds.add(rtMapByName.get('NCSP_SKP_New_customer_setup').getRecordTypeId());
        /*if(rtMapByName.containsKey('Retention'))
            recordTypeIds.add(rtMapByName.get('Retention').getRecordTypeId()); */                 
        if(rtMapByName.containsKey('Task'))
            recordTypeIds.add(rtMapByName.get('Task').getRecordTypeId());
        if(rtMapByName.containsKey('Task_Question'))
            recordTypeIds.add(rtMapByName.get('Task_Question').getRecordTypeId());
        if(rtMapByName.containsKey('Task_Request'))
            recordTypeIds.add(rtMapByName.get('Task_Request').getRecordTypeId());
        //
        if(rtMapByName.containsKey('NCSP_Tech_Services_New_Customer_Setup'))
            recordTypeIds.add(rtMapByName.get('NCSP_Tech_Services_New_Customer_Setup').getRecordTypeId());
        
        //Developer Name: Madhu Paladugu
        //Case number:00593195
        //Changed the logic to add  new record types
        if(rtMapByName.containsKey('NCSP_Upsell'))
            recordTypeIds.add(rtMapByName.get('NCSP_Upsell').getRecordTypeId());   
               
     }
}
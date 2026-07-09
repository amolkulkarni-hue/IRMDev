global class Schedule_updateOpportunityAttribution implements Schedulable{
    global void execute(SchedulableContext sc){
        updateOpportunityAttribution oppAtt = new updateOpportunityAttribution();
        System.debug('+++++testing+++++'+oppAtt);
        id batched = database.executeBatch(oppAtt, 10);        
    }
    
}
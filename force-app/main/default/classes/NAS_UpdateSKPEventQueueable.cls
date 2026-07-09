/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Implementation of Queueable interface that allows callouts. This class updates a List of SKP 
* Events to closed. 
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class NAS_UpdateSKPEventQueueable implements Queueable, Database.AllowsCallouts {
	/**
     * @name updateEvent
     * @description Service method to enque the queueable job if no ther queueable of same type is
     * running and there are some cases with pending SKP Event update.
    **/
	public static void updateEvent() {
        if(NAS_Utilities.isExecuteUpdateSKPEventQueueable())
            System.enqueueJob(new NAS_UpdateSKPEventQueueable());
    }
    /**
     * @name execute
     * @description Implementation of execute method of Queueable interface that calls the SKP API
     * for each of the Cases with pending event update. If the request is successful, updates the
     * case with the notified status. If there is more Cases with pending SKP event update, it
     * enqueues another queueable job. 
    **/
    public void execute(QueueableContext context) {
    	List<Case> casePendingSKPEventUpdateList = NAS_DataFactory.getCasePendingSKPEventUpdateList();
		List<Case> caseUpdateList = new List<Case>();
    	for(Case cs : casePendingSKPEventUpdateList)
    	{
    		try
    		{
    			Map<String, Object> updateEventsJSON = NAS_RequestFactory.postSKPHttpRequest(NAS_Constants.RQTYPE_SKP_API_UPDATE_REPLICATION_EVENTS, 
                                                                            NAS_RequestParamBuilder.getUpdateReplicationEventsParam(cs));
            	if(updateEventsJSON != null && updateEventsJSON.get('success') == true)
            	{
            		cs.NAS_CECOMM_Event_Status__c = NAS_Constants.CECOMM_NOTIFIED;
            		caseUpdateList.add(cs);
            	}
    		}
    		catch(Exception e) { }
    	}
    	if(!caseUpdateList.isEmpty())
    		update caseUpdateList;
      if(!Test.isRunningTest() && NAS_Utilities.isCasePendingSKPEventUpdate()) System.enqueueJob(new NAS_UpdateSKPEventQueueable());
    }
}
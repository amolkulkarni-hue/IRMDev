/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Apex class to implement update communicator functionality. On closure of a CE 
* Communicator case, this class sends the case resolution information via a SKP API to update a 
* SKP Communicator.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public class NAS_UpdateCommunicatorQueueable implements Queueable, Database.AllowsCallouts {
	/**
     * @name updateCommunicator
     * @description Invocable method to enque a job to update the communicator asynchronously.
     * This method is called from a Visual Workflow once conditions are met.
    **/
    @InvocableMethod(label='Update SKP Communicator' 
                     description='Updates a SKP Comminicator once a Communicator Case is closed.')
    public static void updateCommunicator() {
        NAS_UpdateCommunicatorQueueable.enqueueJob();
    }
		public static void enqueueJob() {
			if(NAS_Utilities.isExecuteUpdateCommunicatorQueueable())
    		System.enqueueJob(new NAS_UpdateCommunicatorQueueable());
		}
    /**
     * @name execute
     * @description Implementation of execute method of Queueable interface. Implements the update communicator API call.
    **/
    public void execute(QueueableContext context) {
    	List<Case> casePendingSKPCommunicatorUpdateList = NAS_DataFactory.getCasePendingSKPCommunicatorUpdateList();
		List<Case> caseUpdateList = new List<Case>();
		System.debug(casePendingSKPCommunicatorUpdateList);
    	for(Case cs : casePendingSKPCommunicatorUpdateList)
    	{
    		try
    		{
    			Map<String, Object> updateEventsJSON = NAS_RequestFactory.postSKPHttpRequest(NAS_Constants.RQTYPE_SKP_API_UPDATE_COMMUNICATOR, 
                                                                            NAS_RequestParamBuilder.getUpdateCommunicatorParam(cs));
					System.debug(updateEventsJSON);
            	if(updateEventsJSON != null && updateEventsJSON.get('success') == true)
            	{
            		cs.NAS_CECOMM_Event_Status__c = NAS_Constants.CECOMM_CLOSED;
            		caseUpdateList.add(cs);
            	}
    		}
    		catch(Exception e) { }
    	}
    	if(!caseUpdateList.isEmpty())
    		update caseUpdateList;
      if(!Test.isRunningTest() && NAS_Utilities.isCasePendingSKPCommunicatorUpdate()) System.enqueueJob(new NAS_UpdateCommunicatorQueueable());
    }
}
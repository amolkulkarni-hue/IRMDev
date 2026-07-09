/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Implementation of Batchable and Database.AllowsCallouts interfaces. Implements the funtionality 
* to invoke a SKP API to get the new resplication events and create case in multiple batch jobs.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
global class NAS_GetReplicationEventsBatchable implements Database.Batchable<NAS_DataTypeFactory.CECommEvent>, Database.AllowsCallouts {
	/**
     * @name executeGetReplicationEventsBatch
     * @description Service method to execute the batch job.
    **/
    public static Id executeGetReplicationEventsBatch()
    {
        Id batchProcessId = Database.executeBatch(new NAS_GetReplicationEventsBatchable(), 
                                               NAS_Constants.BATCH_SIZE_GET_REPLICATION_EVENTS_CECOMM);
        return batchProcessId;
    }
    /**
     * @name getEvents
     * @description Service method to invoke SKP API get replication events and return a list of Iterable<NAS_DataTypeFactory.CECommEvent>.
     * This is utilized by the start method to prepare the BatchableContext.
    **/
    private static Iterable<NAS_DataTypeFactory.CECommEvent> getEvents()
    {
        Iterable<NAS_DataTypeFactory.CECommEvent> returnValue = new NAS_DataTypeFactory.CECommEventIterable(new List<NAS_DataTypeFactory.CECommEvent>(), 
        																									new NAS_DataTypeFactory.CECommSKPCustomer());
        Map<String, Object> eventsJSON = NAS_RequestFactory.postSKPHttpRequest(NAS_Constants.RQTYPE_SKP_API_GET_REPLICATION_EVENTS, 
                                                                            NAS_RequestParamBuilder.getReplicationEventsParam());
        if(eventsJSON != null && eventsJSON.get('statusCode') == 200)
        {
            Map<String, Object> replicationEvents = (Map<String, Object>) eventsJSON.get('replicationEvents');
            if(replicationEvents != null)
            {
                NAS_DataTypeFactory.CECommSKPCustomerIdSet skpIdSet = new NAS_DataTypeFactory.CECommSKPCustomerIdSet();
                List<NAS_DataTypeFactory.CECommEvent> eventList = NAS_TransformationFactory.formatReplicationEvents(
                    replicationEvents,
                    skpIdSet);
                NAS_DataTypeFactory.CECommSKPCustomer skpCustomer = NAS_DataFactory.getCECommSKPCustomer(skpIdSet);
                
                returnValue = new NAS_DataTypeFactory.CECommEventIterable(eventList, skpCustomer);
            }
        }
        return returnValue;
    }
    /**
     * @name start
     * @description Implementation of Batchable start method. Returns Iterable<NAS_DataTypeFactory.CECommEvent>.
    **/
    global Iterable<NAS_DataTypeFactory.CECommEvent> start(Database.BatchableContext bc)
    {
        return NAS_GetReplicationEventsBatchable.getEvents();
    }
    /**
     * @name execute
     * @description Impementation of Batchable execute method. Creates the CE Communicator cases for each of the events.
    **/
    global void execute(Database.BatchableContext bc, List<NAS_DataTypeFactory.CECommEvent> eventList)
    {
        NAS_DataFactory.createCECommunicatorCases(eventList);
    }
    /**
     * @name finish
     * @description Impementation of Batchable finish method. Invokes update event functionality on successfull 
     * creation of case records.
    **/ 
    global void finish(Database.BatchableContext BC)
    {
        NAS_UpdateSKPEventQueueable.updateEvent();
    }
}
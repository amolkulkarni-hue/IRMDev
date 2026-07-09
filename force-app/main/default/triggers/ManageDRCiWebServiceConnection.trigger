trigger ManageDRCiWebServiceConnection on DRCiWebServiceConfig__c (before delete, before update) {
	
	if(triggerFlowControl.triggerRunCount('ManageDRCiWebServiceConnection') > 1 )
		   return;
	
	for(Integer i = 0; i < Trigger.old.size(); i++)
	{
		if(!Trigger.isDelete && (Trigger.new.get(i).password__c != Trigger.old.get(i).password__c) )
		{
			//clean up the pooled connections -- web service callout in a future method
			//DRCiDocumentLink.cleanupPooledConnection(Trigger.old.get(i).pooled_session_Id__c 
			//                                        ,Trigger.old.get(i).Endpoint__c);
			//null the session information so it can be re-set
			Trigger.new.get(i).pooled_session_Id__c = null;
			Trigger.new.get(i).pooled_session_Cookie__c = null;
						
		}
		else if(Trigger.isDelete )
		{
			//clean up the pooled connections -- web service callout in a future method
			DRCiDocumentLink.cleanupPooledConnection(Trigger.old.get(i).pooled_session_Id__c 
			                                        ,Trigger.old.get(i).Endpoint__c);
		}
	}

}
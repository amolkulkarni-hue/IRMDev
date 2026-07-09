/**
 * @author Nathan Ross, Bluewolf LLC
 * @date 2017-11
 *
 * @group ProxyPattern
 *
 * @description Mock for IApexJobProxy
 */
@isTest
public class ApexJobProxyMock implements IApexJobProxy {
    static final String ASYNC_APEX_JOB_KEY_PREFIX = '707';
    static Integer idCounter = 0;
    Map<Id, CronTrigger> returnForQueryCronTrigger = new Map<Id, CronTrigger>();
    
    public List<List<Object>> executeBatchCalls = new List<List<Object>>();
    public List<List<Object>> enqueueJobCalls = new List<List<Object>>();

    public void executeBatch(Object batchable, Integer scopeSize) {
        executeBatchCalls.add(new List<Object>{
            batchable, scopeSize});
    }

    public Id enqueueJob(Queueable job) {
        enqueueJobCalls.add(new List<Object>{job});
        return ASYNC_APEX_JOB_KEY_PREFIX + String.valueOf(idCounter++).leftpad(15, '0');
    }

    public CronTrigger queryCronTrigger(Id cronTriggerId) {
        return returnForQueryCronTrigger.get(cronTriggerId);
    }
    
    /**
     * provide a field-> value mapping of values to return for a queryCronTriggerCall
     */
    public void setReturnQueryCronTrigger(Id cronTriggerId, Map<String, Object> values) {
        returnForQueryCronTrigger.put(cronTriggerId,
            (CronTrigger) JSON.deserialize(JSON.serialize(values), CronTrigger.class));
    }
}
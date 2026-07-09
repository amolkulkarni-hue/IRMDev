trigger NAS_AgentWorkTrigger on AgentWork (after INSERT, after update) {
    NAS_TriggerWorker.execute('NAS_AgentWorkTriggerHandler');
}
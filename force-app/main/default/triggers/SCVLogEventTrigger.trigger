trigger SCVLogEventTrigger on SG_Log__e (after insert) {
	SCVGoEventHandler.createLogs(Trigger.New);
}
trigger CaseTeamMemberTrigger on CaseTeamMember (after insert) {
    TriggerDispatcher.run(new CaseTeamMemberTriggerHandler());
}

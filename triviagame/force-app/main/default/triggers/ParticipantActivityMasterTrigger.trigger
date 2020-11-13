trigger ParticipantActivityMasterTrigger on ParticipantActivity__e (after insert) {
	ParticipantActivityTriggerHandler triggerHandler = new ParticipantActivityTriggerHandler();
    if (Trigger.isAfter){
        if (Trigger.isInsert){
            triggerHandler.onAfterInsert(Trigger.new);
        }
    }
}
trigger TriviaGameMasterTrigger on Trivia_Game__c (after update) {
    TriviaGameTriggerHandler handler = new TriviaGameTriggerHandler();
    if (Trigger.isAfter){
        if (Trigger.isUpdate){
            handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
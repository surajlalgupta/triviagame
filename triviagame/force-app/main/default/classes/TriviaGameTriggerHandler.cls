public class TriviaGameTriggerHandler {
	public void onAfterUpdate(List<Trivia_Game__c> newList, Map<Id, Trivia_Game__c> oldMap){
        try{
            Set<Id> endedGameIds = new Set<Id>();
            for (Trivia_Game__c game: newList){
                if (String.isNotBlank(game.status__c) && game.status__c.toUpperCase().equals('ENDED') && oldMap.get(game.Id).status__c != game.status__c){
                    endedGameIds.add(game.Id);
                }
            }
            if (endedGameIds.size() > 0){
                TriviaGameTriggerHelper.notifyParticipantsOnGameEnd(endedGameIds);
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }
    }    
}
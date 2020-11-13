public class TriviaGameTriggerHelper {
    public static void notifyParticipantsOnGameEnd(Set<Id> gameIds){
        try{
            Map<Id, Trivia_Game_Participant__c> players = new Map<Id, Trivia_Game_Participant__c>([select Id, Trivia_Participant__r.Email_Address__c from Trivia_Game_Participant__c where Trivia_Game__c IN :gameIds and Trivia_Participant__r.Email_Address__c != null]);
            for (Trivia_Game_Participant__c player: players.values()){
                sendEmail(player);
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        } 
    }
    
    public static void sendEmail(Trivia_Game_Participant__c player){
        try{
            EmailTemplate et=[Select id from EmailTemplate where name = 'GameResultsNotification' limit 1];
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setToAddresses(new String[] {player.Trivia_Participant__r.email_address__c});
            message.setTemplateId(et.Id);
            message.setTargetObjectId([select id from contact limit 1].Id);
            message.setTreatTargetObjectAsRecipient(false);
            message.setWhatId(player.Id);
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }    
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }     
    }
}
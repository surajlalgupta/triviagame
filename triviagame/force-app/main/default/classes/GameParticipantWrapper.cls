public class GameParticipantWrapper implements Comparable{
    @AuraEnabled
    public Trivia_Game_Participant__c getGameParticipant {get;set;}
    public GameParticipantWrapper(Trivia_Game_Participant__c gameParticipant){
        this.getGameParticipant = gameParticipant;
    }
    public Integer compareTo(Object obj){
        try{
            GameParticipantWrapper targetObj = (GameParticipantWrapper)obj;
            if (this.getGameParticipant.Score__c < targetObj.getGameParticipant.Score__c){
                return 1;
            }
            else if (this.getGameParticipant.Score__c > targetObj.getGameParticipant.Score__c){
                return -1;
            }
            else{
                List<Trivia_Participant_Question__c> participantQuestions = this.getGameParticipant.Trivia_Participant_Questions__r;
                List<Trivia_Participant_Question__c> participantQuestionsTarget = targetObj.getGameParticipant.Trivia_Participant_Questions__r;
                
                Integer totalTime = 0, totalTimeTarget = 0;
                if (participantQuestions != null && participantQuestions.size() > 0){
                    for (Trivia_Participant_Question__c question: participantQuestions){
                        totalTime += Integer.valueOf(question.Time_to_Answer__c);
                    }
                } 
                if (participantQuestionsTarget != null && participantQuestionsTarget.size() > 0){
                    for (Trivia_Participant_Question__c question: participantQuestionsTarget){
                        totalTimeTarget += Integer.valueOf(question.Time_to_Answer__c);
                    }
                }
                
                if (totalTime < totalTimeTarget){
                    return 1;
                }
                else if (totalTime > totalTimeTarget){
                    return -1;
                }
                else {
                    return this.getGameParticipant.Trivia_Participant__r.First_Name__c.compareTo(targetObj.getGameParticipant.Trivia_Participant__r.First_Name__c);
                }
            }
        }
        catch (Exception ex){
			system.debug(ex.getStackTraceString());
        }
        return 1;
    }
}
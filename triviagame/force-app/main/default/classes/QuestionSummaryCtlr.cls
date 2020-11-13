public class QuestionSummaryCtlr {
    public List<QuestionWrapper> questions {
        get {
            List<QuestionWrapper> questionWraps = new List<QuestionWrapper>();
            try{    
                Trivia_Game__c game = [select Id, (select Id, Trivia_Question__r.Question__c, Trivia_Question__r.Correct_Answer_Option__c, 
                                                   Trivia_Question__r.Choice_A__c, Trivia_Question__r.Choice_B__c, Trivia_Question__r.Choice_C__c, 
                                                   Trivia_Question__r.Choice_D__c, Trivia_Question__r.Choice_E__c from Trivia_Game_Questions__r) 
                                       from Trivia_Game__c where Id = :gameIds limit 1];
                Trivia_Game_Participant__c participant = [select Id, (select Id, Answer_Chosen__c, Trivia_Game_Question__c, 
                                                          Time_To_Answer__c from Trivia_Participant_Questions__r)
                                                          from Trivia_Game_Participant__c where id = :playerId limit 1];
                if (game != null){
                    
                    for (Trivia_Game_Question__c question: game.Trivia_Game_Questions__r){
                        QuestionWrapper questionWrap = new QuestionWrapper();
                        List<String> answers = new List<String>();
                        if (String.isNotBlank(question.Trivia_Question__r.Choice_A__c)){
                            answers.add('A. '+question.Trivia_Question__r.Choice_A__c);
                        }
                        if (String.isNotBlank(question.Trivia_Question__r.Choice_B__c)){
                            answers.add('B. '+question.Trivia_Question__r.Choice_B__c);
                        }
                        if (String.isNotBlank(question.Trivia_Question__r.Choice_C__c)){
                            answers.add('C. '+question.Trivia_Question__r.Choice_C__c);
                        }
                        if (String.isNotBlank(question.Trivia_Question__r.Choice_D__c)){
                            answers.add('D. '+question.Trivia_Question__r.Choice_D__c);
                        }
                        if (String.isNotBlank(question.Trivia_Question__r.Choice_E__c)){
                            answers.add('E. '+question.Trivia_Question__r.Choice_E__c);
                        }
                        questionWrap.answers = answers;
                        questionWrap.body = question.Trivia_Question__r.Question__c;
                        questionWrap.correctAnswer = question.Trivia_Question__r.Correct_Answer_Option__c;
                        questionWrap.playerAnswer = getPlayerAnswer(question.Id, participant);
                        
                        questionWraps.add(questionWrap);
                    }
                } 
                
            }
            catch (Exception ex){
                system.debug(ex.getStackTraceString());
            } 
            return questionWraps;
    	}
		set;
    }
    
    public String getPlayerAnswer(Id questionId, Trivia_Game_Participant__c participant){
        try{
        	if (String.isNotBlank(questionId) && participant != null && 
            participant.Trivia_Participant_Questions__r != null && participant.Trivia_Participant_Questions__r.size() > 0){
                for (Trivia_Participant_Question__c question: participant.Trivia_Participant_Questions__r){
                    if (question.Trivia_Game_Question__c == questionId){
                        return question.Answer_Chosen__c;
                    }
                }
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }    
        return '';
    }
    
    public Trivia_Game_Participant__c player{get;set;}
    public Id playerId{get;set;}
    public Id gameIds{get;set;}
    
    public class QuestionWrapper{
        public String body{get;set;}
        public List<String> answers{get;set;}
        public String playerAnswer{get;set;}
        public String correctAnswer{get;set;}
    }
}
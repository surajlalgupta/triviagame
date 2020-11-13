public class STMGPlaygroundCtlr{
    @AuraEnabled
    public static Trivia_Game__c fetchGame(Integer gameId){
        try{
            List<Trivia_Game__c> game = [select Id, Status__c from Trivia_Game__c
                                         where Game_Identifier__c = :gameId limit 1];
            if (game != null && game.size() > 0){
                return game[0];
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }
        return null;
    }
    
    @AuraEnabled
    public static Integer instantiateGame(){
        try{
            List<Trivia_Game__c> liveGames = [select Id, Status__c, Game_Identifier__c from Trivia_Game__c 
                                              where Status__c IN ('New', 'Live')  limit 1];
            Set<Integer> gameIds = new Set<Integer>();
            for (Trivia_Game__c liveGame: liveGames){
                gameIds.add(Integer.valueOf(liveGame.Game_Identifier__c));
            }
            Integer gameId = generateGameId();
            while (gameIds.contains(gameId) || gameId < 100000){
                gameId = generateGameId();
            }
            Trivia_Game__c game = new Trivia_Game__c();
            game.status__c = 'New';
            game.Game_Identifier__c = gameId;
            insert game;
            loadQuestionsOntoGame(game);
            return gameId;
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }
    	return -1;
    }
    
    @AuraEnabled
    public static void loadQuestionsOntoGame(Trivia_Game__c game){
        try{
            List<Trivia_Question__c> allQuestions = [select Id, Question__c, Choice_A__c, Choice_B__c, Choice_C__c, 
                                                     Choice_D__c, Choice_E__c, Correct_Answer_Option__c from
                                                     Trivia_Question__c];
            List<Trivia_Game_Config__mdt> questionsPerGameConfig = [select Id, value__c from Trivia_Game_Config__mdt where developerName = 'QUESTIONS_PER_GAME' limit 1];
            if (questionsPerGameConfig != null && questionsPerGameConfig.size() > 0){
                Integer questionsPerGame = Integer.valueOf(questionsPerGameConfig[0].value__c);
                List<Trivia_Game_Question__c> gameQuestions = new List<Trivia_Game_Question__c>();
                for (Integer i = 0; i < questionsPerGame; i++){
                    Trivia_Game_Question__c gameQuestion = new Trivia_Game_Question__c();
                    gameQuestion.Trivia_Game__c = game.Id;
                    Integer randomIndex = generateRandomInteger(allQuestions.size());
                    gameQuestion.Trivia_Question__c = allQuestions.get(randomIndex).Id;
                    gameQuestion.Serial_Number__c = Decimal.valueOf(i+1);
                    allQuestions.remove(randomIndex);
                    gameQuestions.add(gameQuestion);
                }
                if (gameQuestions.size() > 0){
                    insert gameQuestions;
                }
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static List<Trivia_Game_Question__c> fetchGameQuestions(Integer gameId){
        try{
            Trivia_Game__c game = fetchGame(gameId);
            if (game != null){
                game.status__c = 'Live';
                update game;
            }
            List<Trivia_Game_Question__c> questions = [select Id, Trivia_Question__r.Question__c, 
                                                       Trivia_Question__r.Correct_Answer_Option__c, Trivia_Question__r.Choice_A__c,
                                                       Trivia_Question__r.Choice_B__c, Trivia_Question__r.Choice_C__c,
                                                       Trivia_Question__r.Choice_D__c, Trivia_Question__r.Choice_E__c from Trivia_Game_Question__c
                                                       where Trivia_Game__r.Game_Identifier__c = :gameId order by Serial_Number__c asc];
            return questions; 
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }
        return null;
    }
    @AuraEnabled
    public static List<GameParticipantWrapper> fetchGameParticipants(Integer gameId){
        try{
            List<GameParticipantWrapper> participants = new List<GameParticipantWrapper>();
            
            List<Trivia_Game_Participant__c> players = [select Id, Trivia_Participant__r.First_Name__c, Trivia_Participant__r.Last_Name__c,
                                                        (select Id, Trivia_Game_Question__c, Time_to_Answer__c from Trivia_Participant_Questions__r), 
                                                        Score__c, Trivia_Participant__r.Mobile_Number__c, Ranking__c from Trivia_Game_Participant__c
                                                        where Trivia_Game__r.Game_Identifier__c = :gameId];
            for (Trivia_Game_Participant__c player: players){
                participants.add(new GameParticipantWrapper(player));
            }
            participants.sort();
            return participants;
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }  
        return null;
    }
    
    @AuraEnabled
    public static void processAnswer(Integer gameId, String player, String answer, Trivia_Game_Question__c question, Integer timeToAnswer){
        try{
            ParticipantWrapper participant = (ParticipantWrapper)JSON.deserialize(player, ParticipantWrapper.class);
            List<Trivia_Participant_Question__c> participantQuestions = [select Id from Trivia_Participant_Question__c where Trivia_Game_Participant__c = :participant.id
                                                                  and Trivia_Game_Question__c = :question.Id limit 1];
            if (participantQuestions == null || participantQuestions.size() == 0){
                Trivia_Participant_Question__c participantQuestion = new Trivia_Participant_Question__c();
                participantQuestion.Trivia_Game_Participant__c = participant.id;
                participantQuestion.Trivia_Game_Question__c = question.Id;
                participantQuestion.Answer_Chosen__c = answer;
                participantQuestion.Time_to_Answer__c = timeToAnswer;
                
                insert participantQuestion;
                if (answer.equals(question.Trivia_Question__r.Correct_Answer_Option__c)){
                    List<Trivia_Game_Participant__c> participants = [select Id, Score__c from Trivia_Game_Participant__c where id = :participant.id limit 1];
                    if (participants != null && participants.size() > 0){
                        participants[0].Score__c = participants[0].Score__c + 1;
                        update participants[0];
                    }
                }
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static void terminateGame(Integer gameId){
        try{
            Trivia_Game__c game = fetchGame(gameId);
            if (game != null){
                game.status__c = 'Ended';
                update game;
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static Integer generateGameId(){
        return Integer.valueOf(Math.random()*1000000);
    	
    }
    
    @AuraEnabled
    public static Integer generateRandomInteger(Integer n){
        return Integer.valueOf(Math.random()*n);
    }
    
    
    public class ParticipantWrapper{
        @AuraEnabled
        public Id id {get;set;}
        @AuraEnabled
        public Integer score{get;set;}
        @AuraEnabled
        public Integer ranking{get;set;}
    }
}
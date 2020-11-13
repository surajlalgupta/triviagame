public class ParticipantActivityTriggerHandler {
    public void onAfterInsert(List<ParticipantActivity__e> newList){
        try{
            
            // list of request wrappers which will be used to talk to the participants through twilio
            List<InvalidGameIdNotifRequest> invalidGameIdNotifRequests = new List<InvalidGameIdNotifRequest>();
            List<UserRegisterNotifRequest> userRegisterNotifRequests = new List<UserRegisterNotifRequest>();
            List<MissingEnrollmentNotifRequest> missingEnrollmentNotifRequests = new List<MissingEnrollmentNotifRequest>();
            List<UserNameNotifRequest> usernameNotifRequests = new List<UserNameNotifRequest>();
            
            // list of platform events which will be consumed by empApi in UI
            List<ParticipantActivityEnhanced__e> enhancedEvents = new List<ParticipantActivityEnhanced__e>();
            
            // lists of entities which need to be added to the database
            List<Trivia_Participant__c> participantsToBeAdded = new List<Trivia_Participant__c>();
            List<Trivia_Game_Participant__c> gameParticipantsToBeAdded = new List<Trivia_Game_Participant__c>();
            
            // set of mobile numbers after parsing raw mobile numbers from platform event
            Set<String> mobileNumbers = new Set<String>();
            for (ParticipantActivity__e event: newList){
                mobileNumbers.add(ParticipantActivityTriggerHelper.parseMobileNumber(event.MobileNumber__c));
            }    
            
            // map of participant mobile number and gameParticipant record
            Map<String, Trivia_Game_Participant__c> gameParticipantMap = new Map<String, Trivia_Game_Participant__c>();
            List<Trivia_Game_Participant__c> gameParticipants = [Select Id, Trivia_Participant__r.Mobile_Number__c, Trivia_Game__r.Game_Identifier__c 
                                                                 from Trivia_Game_Participant__c where Trivia_Participant__r.Mobile_Number__c IN :mobileNumbers
                                                                 and Trivia_Game__r.Status__c in ('New', 'Live') Order by Createddate DESC];
            for (Trivia_Game_Participant__c gameParticipant : gameParticipants){
                gameParticipantMap.put(gameParticipant.Trivia_Participant__r.Mobile_Number__c, gameParticipant);
            }
            
            // map of participant mobile number and participant record
            Map<String, Trivia_Participant__c> participantMap = new Map<String, Trivia_Participant__c>();
            List<Trivia_Participant__c> participants = [Select Id, Mobile_Number__c, First_Name__c, Last_Name__c from Trivia_Participant__c 
                                                        where Mobile_Number__c IN :mobileNumbers
                                                        and Is_Banned__c != true Order by Createddate DESC];
            for (Trivia_Participant__c participant : participants){
                participantMap.put(participant.Mobile_Number__c, participant);
            }
            
            // set of gameIds which are either new or live
            Map<Integer, Trivia_Game__c> gameMap = new Map<Integer, Trivia_Game__c>();
            List<Trivia_Game__c> liveGames = [Select Id, Game_Identifier__c from Trivia_Game__c where Status__c in ('New', 'Live')];
            for (Trivia_Game__c game: liveGames){
                gameMap.put(Integer.valueOf(game.Game_Identifier__c), game);
            }
            
            for (ParticipantActivity__e event: newList){
                String mobileNumber = ParticipantActivityTriggerHelper.parseMobileNumber(event.MobileNumber__c);
                if (mobileNumber != null){
                    ParticipantActivityEnhanced__e enhancedEvent = new ParticipantActivityEnhanced__e();
                    enhancedEvent.MobileNumber__c = mobileNumber;
                    enhancedEvent.Type__c = event.Type__c;
                    enhancedEvent.Payload__c = event.Payload__c;
                    if (event.Type__c.equals('ANS_GAME')){
                    	if (gameParticipantMap.get(mobileNumber) != null){
                        	enhancedEvent.GameId__c = gameParticipantMap.get(mobileNumber).Trivia_Game__r.Game_Identifier__c;
                        }
                        else{
                            missingEnrollmentNotifRequests.add(new MissingEnrollmentNotifRequest(mobileNumber));
                        }
                    }
                    else if (event.Type__c.equals('JOIN_GAME')){
                        Integer gameId = Integer.valueOf(event.Payload__c.split(' ')[1].trim());
                        if (gameMap != null && gameMap.keySet().contains(gameId)){
                            enhancedEvent.GameId__c = Decimal.valueOf(gameId);
                            if (participantMap.get(mobileNumber) != null){
                                if (gameParticipantMap.get(mobileNumber) == null){
                                    gameParticipantsToBeAdded.add(new Trivia_Game_Participant__c(Trivia_Game__c = gameMap.get(gameId).Id, Trivia_Participant__c = participantMap.get(mobileNumber).Id));
                                }
                                else{
                                    continue;
                                }
                            }
                            else{
                                participantsToBeAdded.add(new Trivia_Participant__c(Mobile_Number__c = mobileNumber, First_Name__c = mobileNumber, Last_Name__c = ''));
                                Trivia_Participant__c participant = new Trivia_Participant__c(Mobile_Number__c = mobileNumber);
                                gameParticipantsToBeAdded.add(new Trivia_Game_Participant__c(Trivia_Game__c = gameMap.get(gameId).Id, Trivia_Participant__r = participant));
                                usernameNotifRequests.add(new UserNameNotifRequest(mobileNumber));
                            }
                        }
                        else{
                            invalidGameIdNotifRequests.add(new InvalidGameIdNotifRequest(gameId, mobileNumber));
                            continue;
                        }
                    }
                    else if (event.Type__c.equals('NAME')){
                        if (participantMap.get(mobileNumber) != null){
                            if (!String.isBlank(event.Payload__c)){
                                List<String> tokens = event.Payload__c.trim().split(' ');
                                if (tokens != null && tokens.size() > 0){
                                    participantMap.get(mobileNumber).First_Name__c = tokens[0].trim();
                                    if (tokens.size() == 2){
                                    	participantMap.get(mobileNumber).Last_Name__c = tokens[1].trim();
                                    }
                                    else if (tokens.size() > 2){
                                        participantMap.get(mobileNumber).First_Name__c = event.Payload__c.trim();
                                    }
                                } 
                            	userRegisterNotifRequests.add(new UserRegisterNotifRequest(mobileNumber));
                            }
                            enhancedEvent.GameId__c = gameParticipantMap.get(mobileNumber).Trivia_Game__r.Game_Identifier__c;
                        }  
                    }
                    enhancedEvents.add(enhancedEvent); 
                }
            }
            if (participantsToBeAdded.size() > 0){
                insert participantsToBeAdded;
            }
            if (gameParticipantsToBeAdded.size() > 0){
                insert gameParticipantsToBeAdded;
            }
            if (participantMap.values() != null && participantMap.values().size() > 0){
                update participantMap.values();
            }
            EventBus.publish(enhancedEvents);
            if (invalidGameIdNotifRequests.size() > 0){
            	ParticipantActivityTriggerHelper.notifyUserForInvalidGameId(invalidGameIdNotifRequests);
            }
            if (missingEnrollmentNotifRequests.size() > 0){
            	ParticipantActivityTriggerHelper.notifyUserForMissingEnrollment(missingEnrollmentNotifRequests);
            } 
            if (userRegisterNotifRequests.size() > 0){
            	ParticipantActivityTriggerHelper.notifyUserForRegistration(userRegisterNotifRequests);
            } 
            if (usernameNotifRequests.size() > 0){
            	ParticipantActivityTriggerHelper.notifyUserForUsername(usernameNotifRequests);
            } 
        }
        catch (Exception ex){
            system.debug(ex.getMessage());
            system.debug(ex.getStackTraceString());
        }
    }
}
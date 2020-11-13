({
	doInit : function(component, event) {
        var gameId = localStorage.getItem('gameId');
        var liveQuestionSN = localStorage.getItem('liveQuestionSN');
        if (gameId){
        	var action = component.get("c.fetchGame");
            action.setParams({
                'gameId': gameId
            });
            action.setCallback(this, function(result){
                if (result.getState() == 'SUCCESS' && component.isValid()){
                    var gameObj = result.getReturnValue();
                    console.log(gameObj);
                    if (gameObj && gameObj != null){
                        if (gameObj.Status__c.toUpperCase() === 'NEW'){
                            component.set("v.gameId", gameId);
                            component.set("v.liveQuestionSN", 1);
                            this.reloadGame(component, event, 1);
                            //that.loadParticipants(component, event);
                        }
                        else if (gameObj.Status__c.toUpperCase() === 'LIVE'){
                            component.set("v.gameId", gameId);
                            component.set("v.liveQuestionSN", liveQuestionSN);
                    		this.reloadGame(component, event, 2);
                            //this.loadParticipants(component, event);
                        }
                        else{
                            this.reloadGame(component, event, 0);
                        }
                    }
                    else{
                    	this.reloadGame(component, event, 0);
                    }
                }
                else{
                    this.reloadGame(component, event, 0);
                }
            });
            $A.enqueueAction(action);
        }
        else{
            this.reloadGame(component, event, 0);
        }
        
	},
    subscribe: function (component, event){
        const empApi = component.find('empApi');
        const channel = '/event/ParticipantActivityEnhanced__e';
        // Replay option to get new events
        const replayId = -1;

        empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
            var payload = eventReceived.data.payload;
            console.log(payload);
            if (payload.GameId__c && payload.GameId__c == component.get('v.gameId')){
            	if (payload.Type__c === 'JOIN_GAME'){
            		this.loadParticipants(component, event);
        		}
				else if (payload.Type__c === 'ANS_GAME'){
                	this.handleAnswer(component, payload);       
                }
    			else if (payload.Type__c === 'NAME'){
                    this.loadParticipants(component, event);
                }
        	}
        }))
        .then(subscription => {
            console.log('Subscription request sent to: ', subscription.channel);
            component.set('v.subscription', subscription);
        });            
    },       
    reloadGame: function(component, event, level){
        console.log(level);
        component.set("v.isNewGame", false);
        component.set("v.hasLoaded", false);
        component.set("v.isPlaying", false);
        component.set("v.hasEnded", false);
        if (level === 0){
            component.set("v.isNewGame", true);
        }
        else if (level === 1){
            component.set("v.hasLoaded", true);
            this.subscribe(component);
        }
        else{
            component.set("v.isPlaying", true);
            this.subscribe(component);
            this.launchGame(component, event);
        }
    },
    loadGame: function(component, event){
        component.set("v.isNewGame", false);
        component.set("v.hasLoaded", true);
        component.set("v.isPlaying", false);
        var action = component.get("c.instantiateGame");
        action.setCallback(this, function(result){
            if (result.getState() == 'SUCCESS' && component.isValid()){
                component.set("v.gameId", result.getReturnValue());
                localStorage.setItem('gameId', result.getReturnValue());
                this.subscribe(component);
            }    
        });
        $A.enqueueAction(action);
    },
    launchGame: function(component, event){
        component.set("v.isNewGame", false);
        component.set("v.hasLoaded", false);
        component.set("v.isPlaying", true);
        var action = component.get("c.fetchGameQuestions");
        action.setParams({
            'gameId': component.get('v.gameId')
        });
        action.setCallback(this, function(result){
            if (result.getState() == 'SUCCESS' && component.isValid()){
                component.set("v.gameQuestions", result.getReturnValue());
                component.set("v.numOfQuestions", result.getReturnValue().length);
                this.loadQuestion(component, event);
            }
        });
        $A.enqueueAction(action);
    },
	loadQuestion: function(component, event){
        var liveQuestionSN = component.get("v.liveQuestionSN");
        localStorage.setItem('liveQuestionSN', liveQuestionSN);
        var liveQuestion = component.get("v.gameQuestions")[liveQuestionSN-1];
        component.set("v.liveQuestion", liveQuestion);
        component.set("v.timeOfQuestion", Math.round(Date.now()/ 1000));
        this.setAnswerOptions(component, event);
        this.loadParticipants(component, event);
    },
	setAnswerOptions: function(component, event){  
        var liveQuestion = component.get('v.liveQuestion');
        var answerOptions = [];
        if (liveQuestion && liveQuestion.Trivia_Question__r){
            if (liveQuestion.Trivia_Question__r.Choice_A__c){
                answerOptions.push('A. '+liveQuestion.Trivia_Question__r.Choice_A__c);
            }
            if (liveQuestion.Trivia_Question__r.Choice_B__c){
                answerOptions.push('B. '+liveQuestion.Trivia_Question__r.Choice_B__c);
            }
            if (liveQuestion.Trivia_Question__r.Choice_C__c){
                answerOptions.push('C. '+liveQuestion.Trivia_Question__r.Choice_C__c);
            }
            if (liveQuestion.Trivia_Question__r.Choice_D__c){
                answerOptions.push('D. '+liveQuestion.Trivia_Question__r.Choice_D__c);
            }
            if (liveQuestion.Trivia_Question__r.Choice_E__c){
                answerOptions.push('E. '+liveQuestion.Trivia_Question__r.Choice_E__c);
            }
        }
        component.set('v.answerOptions', answerOptions);
	},
	loadNextQuestion : function(component, event){      
        var liveQuestionSN = component.get("v.liveQuestionSN");
		liveQuestionSN++;
        component.set("v.liveQuestionSN", liveQuestionSN);
        this.loadQuestion(component, event);
	},
	endGame : function(component, event){
    	var action = component.get("c.terminateGame");
        action.setParams({
            'gameId': component.get('v.gameId')
        });
        action.setCallback(this, function(result){
            if (result.getState() == 'SUCCESS' && component.isValid()){
                component.set('v.hasEnded', true);
                component.set("v.isPlaying", false);
                localStorage.removeItem('gameId');
                localStorage.removeItem('liveQuestionSN');
            }
        });
        $A.enqueueAction(action);
    },
	loadParticipants : function (component, event){
        var action = component.get("c.fetchGameParticipants");
		action.setParams({
            'gameId': component.get('v.gameId')
        });
        action.setCallback(this, function(result){
            if (result.getState() == 'SUCCESS' && component.isValid()){
                var gameParticipants = result.getReturnValue();
                var players = [];
                console.log(gameParticipants);
                var questionId;
                var question = component.get('v.liveQuestion');
                if (question){
                    questionId = question.Id;
                }
                if (gameParticipants && gameParticipants.length > 0){
                    gameParticipants.forEach(function(item, index, self){
                        item = item.getGameParticipant;
                        var firstName = item.Trivia_Participant__r.First_Name__c != undefined ? item.Trivia_Participant__r.First_Name__c : '';
                        var lastName = item.Trivia_Participant__r.Last_Name__c != undefined ? item.Trivia_Participant__r.Last_Name__c : '';
                        var answered = false;
                        if (questionId && item.Trivia_Participant_Questions__r){
                            for (var i = 0 ; i<item.Trivia_Participant_Questions__r.length; i++){
                                var participantQuestion = item.Trivia_Participant_Questions__r[i];
                                if (participantQuestion.Trivia_Game_Question__c == questionId){
                                    answered = true;
                                    break;
                                }
                            }
                        }
                        players.push({
                            'id': item.Id,
                            'name': firstName+" "+lastName,
                            'score': item.Score__c,
                            'ranking': item.Ranking__c,
                            'mobileNumber': item.Trivia_Participant__r.Mobile_Number__c,
                            'answered': answered
                        });
                    });
                    component.set("v.participants", players);        
                }
            }
        });
        $A.enqueueAction(action);        
    },
	handleAnswer : function(component, payload){
        var timeOfAnswer = Math.round(Date.now()/ 1000);
        var timeToAnswer = timeOfAnswer - component.get("v.timeOfQuestion");
        console.log(timeToAnswer);
    	var mobileNumber = payload.MobileNumber__c; 
        var players = component.get("v.participants");
        var answeringPlayer, answeringPlayerIdx;
        for (var i= 0; i<players.length; i++){
            var player = players[i];
            if (player.mobileNumber == mobileNumber){
                answeringPlayer = player;
                answeringPlayerIdx = i;
                break;
            }
        }
        console.log(answeringPlayer, answeringPlayerIdx);
        if (answeringPlayer){
            console.log('in here');
            var action = component.get("c.processAnswer");
            action.setParams({
                'gameId': component.get('v.gameId'),
                'player': JSON.stringify(answeringPlayer),
                'answer': payload.Payload__c,
                'question': component.get('v.liveQuestion'),
                'timeToAnswer': timeToAnswer
            });
            action.setCallback(this, function(result){
                console.log(result.getState());
                if (result.getState() == 'SUCCESS' && component.isValid()){
                    players[answeringPlayerIdx].answered = true;
                    component.set("v.participants", players);
                    console.log(component.get("v.participants"));
                    this.loadParticipants(component, event);
                }
            });
            $A.enqueueAction(action);
        }
	}        
})
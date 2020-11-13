({
	doInit : function(component, event, helper) {
		helper.doInit(component, event);
	},
    scriptsLoaded: function(component, event, helper){
        
    },
    loadGame: function(component, event, helper){
        helper.loadGame(component, event);
    },
    launchGame: function(component, event, helper){
        helper.launchGame(component, event);
    },
    loadNextQuestion: function (component, event, helper){
        helper.loadNextQuestion(component, event);
    },
    endGame : function (component, event, helper){
        helper.endGame(component, event);
    }
})
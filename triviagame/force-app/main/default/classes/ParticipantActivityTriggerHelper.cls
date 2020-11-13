public class ParticipantActivityTriggerHelper {
    public static String parseMobileNumber(String mobileNumber){
        try{
            if (!String.isBlank(mobileNumber)){
                List<String> tokens = mobileNumber.trim().split(':');
                if (tokens != null && tokens.size() > 0){
                    return tokens[tokens.size() - 1].trim();
                }
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }    
        return null;
    } 
    
    public static void notifyUserForInvalidGameId(List<InvalidGameIdNotifRequest> requests){
        try{
            for (InvalidGameIdNotifRequest req: requests){
                notifyUserForInvalidGameId(req.gameId, req.mobileNumber);
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }    
    }
    
    @future (callout = true)
    public static void notifyUserForInvalidGameId(Integer gameId, String toPhoneNumber){
        try{
            String body = 'You seem to be trying to join an invalid game (GameID: {0}). Please check the 6 digit GameID again and retry.';
            body = String.format(body, new List<String>{String.valueOf(gameId)});
            TwilioMessagingHelper.sendWhatsappMessage(toPhoneNumber, body);
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }    
    }
    
    public static void notifyUserForUsername(List<UserNameNotifRequest> requests){
        try{
            for (UserNameNotifRequest req: requests){
                notifyUserForUsername(req.mobileNumber);
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }    
    }
    
    @future (callout = true)
    public static void notifyUserForUsername(String toPhoneNumber){
        try{
            String body = 'Please reply with your name to proceed futher.';
            TwilioMessagingHelper.sendWhatsappMessage(toPhoneNumber, body);
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }    
    }
    
    public static void notifyUserForMissingEnrollment(List<MissingEnrollmentNotifRequest> requests){
        try{
            for (MissingEnrollmentNotifRequest req: requests){
                notifyUserForMissingEnrollment(req.mobileNumber);
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }
    }
    
    @future (callout = true)
    public static void notifyUserForMissingEnrollment(String toPhoneNumber){
        try{
            String body = 'You seem to not have joined any game.';
            TwilioMessagingHelper.sendWhatsappMessage(toPhoneNumber, body);
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }    
    }
    
    public static void notifyUserForRegistration(List<UserRegisterNotifRequest> requests){
        try{
            for (UserRegisterNotifRequest req: requests){
                notifyUserForRegistration(req.mobileNumber);
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }
    }
    
    @future (callout = true)
    public static void notifyUserForRegistration(String toPhoneNumber){
        try{
            toPhoneNumber = toPhoneNumber.substring(0,1) == '+' ? toPhoneNumber.substring(1) : toPhoneNumber;
            String body = 'Please fill your details here. https://groundswellchallenge-developer-edition.na139.force.com/registerparticipant?mobile={0}';
            body = String.format(body, new List<String>{String.valueOf(toPhoneNumber)});
            TwilioMessagingHelper.sendWhatsappMessage(toPhoneNumber, body);
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }    
    }
}
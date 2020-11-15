public class TwilioMessagingHelper {
	public static void sendWhatsappMessage(String toPhoneNumber, String body){
        try{
            String accountSid = Label.TwilioAccountId;        
            String authToken = Label.TwilioAuthToken;        
            String fromPhoneNumber = Label.TwilioPhoneNumber;                 
            HttpRequest req = new HttpRequest();        
            req.setEndpoint('https://api.twilio.com/2010-04-01/Accounts/'+accountSid+'/Messages.json');        
            req.setMethod('POST');            
            req.setHeader('Accept', 'application/json');        
            req.setHeader('Accept-Charset', 'utf-8');        
            req.setHeader('Authorization','Basic '+EncodingUtil.base64Encode(Blob.valueOf(accountSid+':' +authToken)));        
            req.setBody('To='+EncodingUtil.urlEncode('whatsapp:'+toPhoneNumber,'UTF-8')+'&From='+EncodingUtil.urlEncode('whatsapp:'+fromPhoneNumber,'UTF-8')+'&Body='+body);        
            Http http = new Http();        
            HTTPResponse res = http.send(req);        
            System.debug(res.getBody());        
            if(res.getStatusCode()==201) 
            System.Debug('Message sending Successful');        
            else{            
                System.Debug('Message sending Unsuccessful');
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }    
    } 
}

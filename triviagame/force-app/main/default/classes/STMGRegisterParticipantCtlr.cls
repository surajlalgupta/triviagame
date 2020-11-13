public class STMGRegisterParticipantCtlr { 
    
    public STMGRegisterParticipantCtlr(){
    }    
    
    @RemoteAction
    public static Trivia_Participant__c getDetails(String mobileNumber){
        try{
            List<Trivia_Participant__c> participants = [select Id, First_Name__c, Last_Name__c, Mobile_Number__c,
                                                        Age__c, Email_Address__c, Country__c, City__c from Trivia_Participant__c 
                                                        where Mobile_Number__c = :mobileNumber limit 1];
            if (participants != null && participants.size() > 0){
                return participants[0];
            }
        }
        catch (Exception ex){
            system.debug(ex.getStackTraceString());
        }    
        return null;
    }    
    
    @RemoteAction
    public static ParticipantDetailResponse registerParticipant(String data){
        ParticipantDetailResponse resp = new ParticipantDetailResponse();
        resp.isSuccess = false;
        try{
            ParticipantDetailRequest req = (ParticipantDetailRequest)JSON.deserialize(data, ParticipantDetailRequest.class);
            
            
            Trivia_Participant__c participant = getDetails(req.mobileNumber);
            if (participant != null){
                participant = new Trivia_Participant__c(Id = participant.Id, First_Name__c= req.firstName, Last_Name__c= req.lastName, 
                                                        Email_Address__c= req.email, Age__c= req.age, Country__c = req.country, City__c = req.city);
                update participant;
            }
            else{
                participant = new Trivia_Participant__c(First_Name__c= req.firstName, Last_Name__c= req.lastName, 
                                                                Email_Address__c= req.email, Mobile_Number__c= req.mobileNumber, 
                                                                Age__c= req.age, Country__c = req.country, City__c = req.city);
                
            
            	insert participant;
            }    
            
            if (req.file != null){
                Blob fileData = EncodingUtil.base64Decode(req.file.split('base64,')[1].trim());
                List<String> fileNameParts = req.fileName.split('\\.');
                ContentVersion cv = new ContentVersion();
                cv.Title = 'ProfilePhoto';
                cv.PathOnClient = 'profilephoto.'+fileNameParts[fileNameParts.size()-1];
                cv.VersionData = fileData;
                cv.IsMajorVersion = true;
                Insert cv;
                
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
                
                ContentDocumentLink cdl = New ContentDocumentLink();
                cdl.LinkedEntityId = participant.Id;
                cdl.ContentDocumentId = conDocId;
                cdl.shareType = 'V';
                Insert cdl;
                
            }
            resp.isSuccess = true;
        }
        catch (Exception ex){
            ErrorDetail error = new ErrorDetail();
            error.messages = new List<String>{'Registration failed. Please contact Program Administrator!'};
            resp.error = error;
            system.debug(ex.getMessage());
            system.debug(ex.getStackTraceString());
        }
        return resp;
    }
    
    public class ParticipantDetailRequest{
        public String file { get; set; }
        public String fileName {get;set;}
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String country {get;set;}
        public String city {get;set;}
        public String email {get; set;}
        public Integer age {get; set;}
        public String mobileNumber {get;set;}
    }
    
    public class ParticipantDetailResponse{
        public boolean isSuccess {get; set;}
        public ErrorDetail error {get; set;}
    }
    
    public class ErrorDetail{
        public List<String> messages {get; set;}
    }
}
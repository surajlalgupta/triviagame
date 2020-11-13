public class InvalidGameIdNotifRequest {
	public Integer gameId {get;set;}
    public String mobileNumber {get;set;}
    
    public InvalidGameIdNotifRequest (Integer gameId, String mobileNumber){
        this.gameId = gameId;
        this.mobileNumber = mobileNumber;
    }
}
public class SplitAccountNameAction {
	@InvocableMethod(label='Split Account Names' description='Returns the billing account name without prefix BILLC-.' category='Account')
  	public static List<String> splitAccountName(List<String> bAccountName) {
        String bAN = bAccountName[0]; List<String> splitString = bAN.split('-'); List<String> returnString = new List<String>();
        returnString.add(splitString[1]);
        return returnString;
  	}
}
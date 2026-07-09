/**
 * 	Class:				NF_PhoneSearchAction
 * 
 * 	Author:				Yashwant Verma (NeuraFlash LLC)
 * 
 * 	Purpose:			Returns the list of all the records having the passed Phone Number without the need of phone formatting
 * 
 * 	Requirements:		IMSLB-27
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
/*
 *  @description    Returns the list of all the records having the passed Phone Number without the need of phone formatting
 *  @author 	    Yashwant Verma
 *  @date           2022-05-25
 */
public class NF_PhoneSearchAction {
    @InvocableMethod(label = 'Search Records by ANI' description = 'Returns the list of all the records having the passed Phone Number without the need of phone formatting')
    public static List<List<SObject>> NF_PhoneSearchAction(List<Requests> requestList) {
        List<SObject> objectRecordList = new List<SObject>();
        try{
            //Storing API Name of the passed Object for SOSL
            String objectAPIName = requestList[0].objectAPIName;

            //Creating search string from phone number
			String phoneNumberSearchString = requestList[0].phoneNumber.right(10) + ' OR ' + requestList[0].phoneNumber.remove('+') + ' OR ' + requestList[0].phoneNumber;
            
            //Storing the API names of fields to return in SOSL
            String fieldAPINames = requestList[0].commaSeparatedFieldAPINames;

            system.debug('objectAPIName -->> ' + objectAPIName);
            system.debug('phoneNumber -->> ' + phoneNumberSearchString);
            system.debug('fieldAPINames -->> ' + fieldAPINames);

            Search.SearchResults searchResults = Search.find('FIND \''+ phoneNumberSearchString + '\' IN PHONE FIELDS RETURNING ' + objectAPIName + '('+fieldAPINames+')');
            system.debug('searchList >> ' + searchResults);
            
            for (Search.SearchResult eachResult : searchResults.get(objectAPIName)){
                SObject response = eachResult.getSObject();
                system.debug('result>>'+ response);
                objectRecordList.add(response);
            }
            
        }
        catch (Exception e){
            system.debug('Exception Occured in NF_PhoneSearchAction >> ' + e.getLineNumber() + ' ' + e.getMessage());
        }
        system.debug('objectRecordList >> '+objectRecordList);
        return new List<List<SObject>>{objectRecordList};
    }


    public class Requests{
        @InvocableVariable(label = 'ANI or Phone Number to search' description = 'Pass the Phone Number for which the records need to be filtered' required = true)
        public String phoneNumber;
        
        @InvocableVariable(label = 'Object API Name' description = 'Name of the object whose records need to be searched' required = true)
        public String objectAPIName;

        @InvocableVariable(label = 'Comma Separated Field API Names' description = 'Provide the comma separated field API names which needs to be fethched(for using in flow by storing in a record collection variable) for eg. Name, Email, Phone' required = true)
        public String commaSeparatedFieldAPINames;
    }

    
}
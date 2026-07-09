public with sharing class PayMyBillPopupController {
    

    @AuraEnabled
    public static List<URLWrapper> getUrlBasedOnLocation(){
        List<URLWrapper> urllist = new List<URLWrapper>();
        try{
            Map<String, PayMyBillUrlChoices__mdt> mapEd = PayMyBillUrlChoices__mdt.getAll();
                for(String nameEmailDomain : mapEd.keySet()){
                    URLWrapper obj = new URLWrapper();
                    obj.Url=mapEd.get(nameEmailDomain).URL__c;
                    obj.Label=mapEd.get(nameEmailDomain).Label;
                    urllist.add(obj);
                }
                return urllist;
            
        }catch(Exception ex){
            throw new AuraHandledException('Error::'+ex.getMessage()+' '+ ex.getLineNumber());
            
        }
        
    }

     /**Wrapper Class to hold event table columns and data */
     public class URLWrapper{
        @AuraEnabled public String Url {get;Set;}
        @AuraEnabled public String Label {get;set;}
    }
    
}
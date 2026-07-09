/*****************************************************************************************************
 * Class: QTB_Subscription_Batch
 * Author: Vinutha Iyengar
 * Purpose: This is a Batch class to call Utility Class to convert Price Schedule-based Subscription Records to Consumption Schedule-based records for Finland Renewals/Amends
 *******************************************************************************************************/

global class QTB_Subscription_Batch implements Database.Batchable<SObject>{
    
    public String query;
    public String CountryCode ='FIN';
    public String ContractRecType ='CPQ Contract';
    
    
    
    /***********************************************************************************************************
     * Method :  Constructor
     * Description: Used to initaite query string.
     **************************************************************************************************************/
    global QTB_Subscription_Batch() {
      //query = 'select id from Contract where IM_Country_Code__c = \''+CountryCode+'\' AND RecordType.Name = \''+ContractRecType+'\' AND EndDate = 2021-12-26 AND Status != \'Terminated\' and QTB_Converted_to_Consumption_Schedule__c!=true and id in (\'8002H000002pDRXQA2\')limit 100';
		query = Label.FinlandRenewalQuery;
        system.debug('query=='+query);
        
    }
    
    /***********************************************************************************************************
     * Method : start
     * Parameters: Database.BatchableContext
     * ReturnType: Database.QueryLocator
     * Description: To collect all Renewal Contracts
     **************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext bc) {
      return Database.getQueryLocator(query);
    }
    
    /***********************************************************************************************************
     * Method : execute
     * Description: Used to call Utility Class
     **************************************************************************************************************/
    global void execute(Database.BatchableContext bc, List<Contract> ContractsList) {
        
        for (Contract temp : ContractsList) {
            List<String> contractIds = new  List<String>();
            contractIds.add(temp.id);
            system.debug('contractIds=='+contractIds);
            QTB_Subscription_Converter_Utility.convertSubscriptionFromPriceScheduleToConsumptionSchedule(contractIds);
        }        
        
    }
   
    global void finish(Database.BatchableContext bc) {

    }

}
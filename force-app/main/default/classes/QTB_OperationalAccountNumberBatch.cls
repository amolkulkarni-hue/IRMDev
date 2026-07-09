/**********************************************************************************************************************************************
 * Class: QTB_OperationalAccountNumberBatch
 * Test Class : QTB_OperationalAccountNumberBatch_Test
 * Author: Virtusa
 * Purpose: This is class will handle Operational Account Number related logic
 * Requirement: GITLAB #28887 Dev: Batch class creation for new object (QTB_Operational_Account_Number__c) records and deletion of records
 * Change History:
 * Developer                 Date                       Description
 * ----------------------------------------------------------------------------------------------------------------------------------------------
 * Thrinethra                12/02/2025             Creation of batch class for insertion and deletion of Operational Account Number records
 *************************************************************************************************************************************************/

global class QTB_OperationalAccountNumberBatch implements Database.Batchable<sObject> {
    
    /*********************************************************************************************************
    Method Name: start
        Parameters: Database.BatchableContext
        Return Type: Database.QueryLocator
         **********************************************************************************************************/
    global Database.QueryLocator start (Database.BatchableContext bc) {
        //Query for records whose number utilised is true
        return Database.getQueryLocator([SELECT Id FROM QTB_Operational_Account_Number__c WHERE QTB_Number_Utilised__c = true]);
    }
    
    /*********************************************************************************************************
    Method Name: execute: Deletes the records in the scope
        Parameters: Database.BatchableContext, List<QTB_Operational_Account_Number__c>
        Return Type: void
         **********************************************************************************************************/
    global void execute(Database.BatchableContext bc, List<QTB_Operational_Account_Number__c> scope) {
        if(!scope.isEmpty()){
            try {
                delete scope;
            }
            catch (Exception e) {
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_OperationalAccountNumberBatch');
                System.debug('Error while deleting utilised records: ' + e.getMessage());
            }
        }
    }
    
    /*********************************************************************************************************
    Method Name: finish: After deletion, check how many records remain and insert new records (with sequence numbers) so that total matches the custom label value
        Parameters: Database.BatchableContext
        Return Type: void
         **********************************************************************************************************/
    global void finish(Database.BatchableContext bc) {
        Integer recordsCountAsPerCustomLabel=Integer.valueOf(System.Label.Count_of_Records_for_Operational_Account);
        //Count remaining un utilised records
        Integer availableCount = [SELECT COUNT() FROM QTB_Operational_Account_Number__c];
        Integer recordsToCreate = recordsCountAsPerCustomLabel - availableCount;
        
        if(recordsToCreate > 0){
            
            //Get the last sequence value used. Using ALL ROWS to consider even deleted records
            String lastSequence = getLastSequence();
            
            //Generating new records with unique sequence continuation and number of records to create
            List<QTB_Operational_Account_Number__c> newRecords = generateRecords(lastSequence, recordsToCreate);
            
            if(!newRecords.isEmpty()) {
                try {
                    insert newRecords;
                }
                catch (Exception e) {
                    QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_OperationalAccountNumberBatch');
                    System.debug('Error while inserting new records: ' + e.getMessage());
                }
            }
        }
    }
    
    //Method to retrieve the last used QTB_Unique_Number__c value. Querying with ALL ROWS to include even deleted records
    @TestVisible
    private String getLastSequence() {
        String lastSeq;
        List<QTB_Operational_Account_Number__c> lastRec = [SELECT Id, QTB_Unique_Number__c FROM QTB_Operational_Account_Number__c ORDER BY QTB_Unique_Number__c DESC LIMIT 1 ALL ROWS];
        
        if(lastRec.isEmpty()){
            lastSeq = null;
        } else {
            lastSeq = lastRec[0].QTB_Unique_Number__c;
        }
        return lastSeq;
    }
    
    //Method to generate a list of QTB_Operational_Account_Number__c records, with sequential QTB_Unique_Number__c value
    //Passing last sequence number and number of records to create. Returning list of QTB_Operational_Account_Number__c records
    @TestVisible
    private List<QTB_Operational_Account_Number__c> generateRecords(String lastSeq, Integer countToCreate) {
        List<QTB_Operational_Account_Number__c> recordsToInsert = new List<QTB_Operational_Account_Number__c>();
        
        //Initializing the starting Letter and sequence number
        String currentLetter;
        Integer currentNumber;
        if(String.isBlank(lastSeq)){
            //Stating with 'A' and 0 so that later we will increment it.
            currentLetter = 'A';
            currentNumber = 0;
        } else {
            currentLetter = lastSeq.substring(0, 1);
            currentNumber = Integer.valueOf(lastSeq.substring(1));
            //As per Gitlab US #32195 Jump from A to D series and rest continues.
            if (currentLetter == 'A') {
                currentLetter = 'D';
                currentNumber = 0;
            }
        }
        
        //Loop to create required number of records
        for (Integer i = 0; i<countToCreate; i++) {
            //Incrementing the number
            currentNumber++;
            
            //If we exceed 99999, we are going to the next letter
            if (currentNumber > 99999) {
                if(currentLetter == 'Z'){
                    //If we are already at Z, we are resetting letter to A
                    currentLetter = 'A';
                }
                //Using lookup string to get next letter
                String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                Integer currentIndex = alphabet.indexOf(currentLetter);
                if (currentIndex < alphabet.length() - 1){
                    currentLetter = alphabet.substring(currentIndex + 1, currentIndex + 2);
                }
                currentNumber = 1;
            }
            
            //formatting the number part of unique number as 5 digit number string with 0 padding
            String numberString = String.valueOf(currentNumber);
            while (numberString.length() < 5) {
                numberString = '0' + numberString;
            }
            
            String sequenceNumber = currentLetter + numberString;
            
            QTB_Operational_Account_Number__c newRec = new QTB_Operational_Account_Number__c();
            newRec.QTB_Unique_Number__c = sequenceNumber;
            recordsToInsert.add(newRec);
        }
        return recordsToInsert;
    }
}
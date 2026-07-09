/**********************************************************************************************************************************************
 * Class: QTB_GenerateOnAccountCreditNote
 * Test Class : QTB_GenerateOnAccountCreditNoteTest
 * Author: Virtusa
 * Purpose: This is class will generate the On Account Credit Note & Credit Note Lines
 * Requirement: GITLAB #27013 Dev: FMV on Account Credits for All 7 Countries
 * Change History:
 * Developer                 Date
 * ----------------------------------------------------------------------------------------------------------------------------------------------
 * Chandraprakash/Thrinethra 24/10/2024
 *************************************************************************************************************************************************/
public class QTB_GenerateOnAccountCreditNote {
    
    @InvocableMethod
    public static void createOnAccountCredit(List<StagingSelectedRecords> selectedRecords){
        
        //Retrive selected stating ids
        list<String> creditStgId =  selectedRecords[0].stagingId;
        system.debug('selected values'+ creditStgId);
        
        try {
            //Query credit staging records and create a map
            //GitLab 29058 - Added QTB_MatchingAttribute__c in the below query
            Map<Id, QTB_CreditStaging__c> creditStagingMap = new Map<id, QTB_CreditStaging__c> ([SELECT Id, Name, QTB_Account__c, QTB_Account__r.QTB_SITAD__c, 
                                                                QTB_Department_Code__c, QTB_PreratedAmount__c, QTB_PreratedQuantity__c, QTB_Purchase_Order__c, 
                                                                QTB_Product__c, QTB_Product__r.ProductCode, QTB_Is_CreditNote_Generated__c, QTB_Start_Date_MRC__c, 
                                                                QTB_End_Date_MRC__c, QTB_Tax_Street__c, QTB_Tax_City__c, QTB_Tax_State__c, QTB_Tax_ZipCode__c,QTB_MatchingAttribute__c, QTB_Product_Identifier_1__c 
                                                                FROM QTB_CreditStaging__c 
                                                                WHERE Id IN : creditStgId]);
            
            system.debug('Retrieved values'+ creditStagingMap);
            
            //Create Credit Note records
            List<blng__CreditNote__c> creditNoteList = new List<blng__CreditNote__c>();
            Map<Id, Id> creditStagingToCreditNoteMap = new Map<Id, Id>();
            if(!creditStagingMap.isEmpty()){
                for(QTB_CreditStaging__c cs : creditStagingMap.values()){
                    if(cs.QTB_Account__r.QTB_SITAD__c && !cs.QTB_Is_CreditNote_Generated__c) {
                        blng__CreditNote__c creditNote = new blng__CreditNote__c();
                        creditNote.blng__Account__c = cs.QTB_Account__c;
                        creditNote.QTB_Credit_Staging__c=cs.id;
                        creditNote.QTB_On_Account_Credit__c = true;
                        creditNote.blng__CreditNoteDate__c = system.today();
                        creditNote.QTB_Reason_Code__c = 'Legacy Credit';
                        creditNote.QTB_Site_Number__c = cs.QTB_Department_Code__c;
                        creditNote.QTB_PO_Number__c = cs.QTB_Purchase_Order__c;
                        //GitLab 29058 - Start - As EDP assigning matching attribute as the Case number from SMS
                        creditNote.QTB_Case_Number__c = cs.QTB_MatchingAttribute__c;
                        //GitLab 29058 - End
                        creditNoteList.add(creditNote);
                    }
                }
            }
            
            //Partial insert Credit Notes and handle errors
            if(!creditNoteList.isEmpty()){
                Database.SaveResult[] saveNoteResults = Database.insert(creditNoteList, false);
                system.debug('saveNoteResults@@'+ saveNoteResults);
                
                for (Database.SaveResult result : saveNoteResults) {
                    blng__CreditNote__c creditNote = creditNoteList[saveNoteResults.indexOf(result)];
                    if (result.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted credit note. Credit Note ID: ' + result.getId());
                        creditStagingToCreditNoteMap.put(creditNote.QTB_Credit_Staging__c, creditNote.Id);
                    }
                    else {
                        // Operation failed, so get all errors
                        for(Database.Error err : result.getErrors()) {
                            System.debug('The following error has occurred.');
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Credit Note fields that affected this error: ' + err.getFields());
                            QTB_ExceptionLogger.enable();
                            QTB_ExceptionLogger.createLog(57, ' ', err.getMessage(),' ', 'QTB_GenerateOnAccountCreditNote: creditNoteList Insert');
                            system.debug('Error while inserting credit note: '+result.getId()+' '+result.getErrors());
                        }
                    }
                }
            }
            system.debug('CreditStagingtoCrediNotemap@@@@'+ creditStagingToCreditNoteMap);
            
            //Create Credit Note Lines
            List<blng__CreditNoteLine__c> creditNoteLinesList = new List<blng__CreditNoteLine__c>();
            if(!creditStagingToCreditNoteMap.isEmpty()){
                for(Id stagingId : creditStagingToCreditNoteMap.keySet()) {
                    Id creditNoteId = creditStagingToCreditNoteMap.get(stagingId);
                    if(creditNoteId != null){
                        QTB_CreditStaging__c relatedCreditStaging = creditStagingMap.get(stagingId);
                        blng__CreditNoteLine__c creditNoteLine = new blng__CreditNoteLine__c();
                        creditNoteLine.blng__CreditNote__c = creditNoteId;
                        creditNoteLine.QTB_Credit_Quantity__c = (relatedCreditStaging.QTB_PreratedQuantity__c != null
                            && relatedCreditStaging.QTB_PreratedQuantity__c < 0)
                            ? Math.abs(relatedCreditStaging.QTB_PreratedQuantity__c)
                            : (relatedCreditStaging.QTB_PreratedQuantity__c != null ? relatedCreditStaging.QTB_PreratedQuantity__c : 0);
                        creditNoteLine.blng__Subtotal__c = (relatedCreditStaging.QTB_PreratedAmount__c != null
                            && relatedCreditStaging.QTB_PreratedAmount__c < 0)
                            ? Math.abs(relatedCreditStaging.QTB_PreratedAmount__c)
                            : (relatedCreditStaging.QTB_PreratedAmount__c != null ? relatedCreditStaging.QTB_PreratedAmount__c : 0);
                        creditNoteLine.blng__Product__c = relatedCreditStaging.QTB_Product__c;
                        creditNoteLine.QTB_Product_Identifier_1__c = relatedCreditStaging.QTB_Product_Identifier_1__c;
                        creditNoteLine.blng__StartDate__c = relatedCreditStaging.QTB_Start_Date_MRC__c;
                        creditNoteLine.blng__EndDate__c = relatedCreditStaging.QTB_End_Date_MRC__c;
                        creditNoteLine.blng__TaxStreet__c = relatedCreditStaging.QTB_Tax_Street__c;
                        creditNoteLine.blng__TaxCity__c = relatedCreditStaging.QTB_Tax_City__c;
                        creditNoteLine.blng__TaxState__c = relatedCreditStaging.QTB_Tax_State__c;
                        creditNoteLine.blng__TaxZipCode__c = relatedCreditStaging.QTB_Tax_ZipCode__c;
                        creditNoteLinesList.add(creditNoteLine);
                    }
                }
            }
            
            //Insert Credit Note Lines and handle errors
            Set<Id> failedCreditNoteIdsToDelete = new Set<Id>();
            if(!creditNoteLinesList.isEmpty()){
                Database.SaveResult[] lineSaveResults = Database.insert(creditNoteLinesList, false);
                
                for(Database.SaveResult lineResult : lineSaveResults) {
                    blng__CreditNoteLine__c creditNoteLine = creditNoteLinesList[lineSaveResults.indexOf(lineResult)];
                    if(!lineResult.isSuccess()){
                        System.debug('Error while inserting Credit Note Line: ' + lineResult.getErrors()[0].getMessage());
                        failedCreditNoteIdsToDelete.add(creditNoteLine.blng__CreditNote__c);
                        for(Database.Error err : lineResult.getErrors()) {
                            QTB_ExceptionLogger.enable();
                            QTB_ExceptionLogger.createLog(114, '', err.getMessage(), '', 'QTB_GenerateOnAccountCreditNote: creditNoteLinesList Insert');
                        }
                    }
                }
            }
            
            //Delete Credit Notes if their Lines failed to be created
            List<blng__CreditNote__c> creditNotesToDelete = new List<blng__CreditNote__c>();
            if(!failedCreditNoteIdsToDelete.isEmpty()){
                try{
                    for(Id creditNoteId : failedCreditNoteIdsToDelete){
                        blng__CreditNote__c creditNote = new blng__CreditNote__c(Id = creditNoteId);
                        creditNotesToDelete.add(creditNote);
                    }
                    System.debug('Credit Notes being deleted@@@' + creditNotesToDelete);
                    if(!creditNotesToDelete.isEmpty()){
                        SBQQ.TriggerControl.disable();
                        delete creditNotesToDelete;
                        SBQQ.TriggerControl.enable();
                    }
                }
                catch (Exception e) {
                    QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateOnAccountCreditNote: failedCreditNoteIdsToDelete');
                    System.debug('Error while deleting credit notes: ' + e.getMessage());
                }
            }
            
            //Updating the checkbox field to true for successful credit staging records, for which credit note and credit note lines created
            List<QTB_CreditStaging__c> stagingRecordToUpdate = new List<QTB_CreditStaging__c>();
            if(!creditStagingToCreditNoteMap.isEmpty()){
                for(Id stagingId : creditStagingToCreditNoteMap.keySet()){
                    if( creditStagingToCreditNoteMap.get(stagingId)!= null && !failedCreditNoteIdsToDelete.contains(creditStagingToCreditNoteMap.get(stagingId)) ){
                        QTB_CreditStaging__c cs = new QTB_CreditStaging__c();
                        cs.id=stagingId;
                        cs.QTB_Is_CreditNote_Generated__c = true;
                        stagingRecordToUpdate.add(cs);
                    }
                }
            }
            
            //Updating Credit staging record and handling errors
            try {
                if(!stagingRecordToUpdate.isEmpty()){
                    update stagingRecordToUpdate;
                    System.debug('Updated Credit Staging records to check checkbox to true: ' + stagingRecordToUpdate);
                }
            } catch (Exception e) {
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateOnAccountCreditNote: stagingRecordToUpdate');
                System.debug('Error while Updating Credit Staging records: ' + e.getMessage());
            }
            
            //Clear List and Maps
            creditNoteList.clear();
            creditStagingToCreditNoteMap.clear();
            creditNoteLinesList.clear();
            stagingRecordToUpdate.clear();
            
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateOnAccountCreditNote');
            System.debug('Error while inserting Credit Notes:  ' + e.getMessage());
        }
    }
    
    //Inner class to hold selected records
    public class StagingSelectedRecords{
        @InvocableVariable
        public List<string> stagingId;
    }
}
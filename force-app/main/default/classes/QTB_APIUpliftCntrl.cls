/*****************************************************************************************************
* Class			: QTB_APIUpliftCntrl
* Test Class	: QTB_APIUpliftCntrl_Test
* Author		: IRM/Virtusa
* Purpose	 	: Read the csv file data, and then pass data to batch class to update rates
* Requirement	: Gitlab #11113 Advanced Storage Billing - Read the data and run the batch ,
: Gitlab #10928 Internal Bulk Amendment Process: Functionality to Parse Data from Uploaded Spreadsheet
* Developer                Date            Description
* ------------------------------------------------------------------------------------------- 
* Shailesh       		12/10/2022	       Gitlab US #11113 Advanced Storage Billing - Read the data and run the batch
* Shailesh       		15/11/2022	       Gitlab #10928 Internal Bulk Amendment Process: Functionality to Parse Data from Uploaded Spreadsheet
*******************************************************************************************************/
public class QTB_APIUpliftCntrl {
    public static final string QTB_APIUpliftCntrl = 'QTB_APIUpliftCntrl';
    public static String upliftAPIRecordTypeID = Schema.getGlobalDescribe().get('QTB_Data_Holder__c').getDescribe().getRecordTypeInfosByName().get('Uplift').getRecordTypeId();
    public static final string REGULAR_API = 'Regular API';
    public static final string ADVANCE_API = 'Advance API';
    /*********************************************************************************************************
* Method Name: getUploadedData()
* Parameters : nonw
* Return Type: List<FileUploadedData>
* Requirement: Gitlab US #11113 
* Description: Fetch uploaded files from ContentDocument obj and show on UI (API Uplift tab)
getUploadedData() method is called from qtb_APIUpliftRenewal lwc component to show uploded file data in table
**********************************************************************************************************/
    @AuraEnabled(cacheable=false)
    public static List<FileUploadedData> getUploadedData(){
        List<FileUploadedData> fileObjList = new List<FileUploadedData>();
        List<String> documentIds = new List<String>();
        Map<String,String> dataHolderIdWithStatusMap = new Map<String,String>();
        Map<String,String> dataHolderIdWithAPITypeMap = new Map<String,String>();
        try{
            List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                              FROM ContentDocument 
                                              WHERE Description IN ('Regular API', 'Advance API') order by createdDate desc];
            System.debug('getUploadedData_fileList@@'+fileList);  
            
            if(fileList != null && !fileList.isEmpty()){
                for(ContentDocument cd : fileList){
                    documentIds.add(cd.Id);
                }
            }      
            
            //fetching API data from QTB_Data_Holder__c object based on documentId
            for(QTB_Data_Holder__c dhAPI : [SELECT Id,QTB_APIDocument_Id__c,QTB_APIStatus__c,QTB_APIType__c
                                            FROM QTB_Data_Holder__c 
                                            WHERE QTB_APIDocument_Id__c IN : documentIds])
            {
                if(dhAPI != null){
                    dataHolderIdWithStatusMap.put(dhAPI.QTB_APIDocument_Id__c,dhAPI.QTB_APIStatus__c ); 
                    dataHolderIdWithAPITypeMap.put(dhAPI.QTB_APIDocument_Id__c,dhAPI.QTB_APIType__c );
                }
            }
            
            //iterating over list of records of content documents
            for(ContentDocument cd : fileList){
                FileUploadedData fileObj = new FileUploadedData();
                fileObj.FileId = cd.Id;
                fileObj.FileName = cd.Title;     
                fileObj.APIType = dataHolderIdWithAPITypeMap.get(cd.Id);
                fileObj.Status = dataHolderIdWithStatusMap.get(cd.Id);
                //referred following url for color --> https://www.lightningdesignsystem.com/icons/#custom     
                if(fileObj.Status == 'Success'){
                    fileObj.StatusColorCSSClass =  'slds-icon-custom-custom79'; // green color   
                }else if(fileObj.Status == 'Failed' || fileObj.Status == 'Partially Failed'){
                    fileObj.StatusColorCSSClass =  'slds-icon-custom-custom53' ; // red color
                }else if(fileObj.Status == 'InProgress'){
                    fileObj.StatusColorCSSClass = 'slds-icon-custom-custom46'; // blue color
                }else if(fileObj.Status == 'New'){
                    fileObj.StatusColorCSSClass = 'slds-icon-custom-custom4'; //yellow color
                }
                fileObj.FileSize = cd.ContentSize;
                fileObj.UploadedDate = cd.createdDate.date();
                fileObj.UploadedBy = cd.Owner.Name;
                fileObjList.add(fileObj);
            }
            if(fileObjList != null && !fileObjList.isEmpty()){
                System.debug('fileObjList@@'+fileObjList);
                return fileObjList;
            }else{
                return null;
            }
        }
        catch (Exception e){
            System.debug('Apex Class@@'+QTB_APIUpliftCntrl);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIUpliftCntrl); 
            return null;
        }
    }
    
    /*********************************************************************************************************
* Method Name: deleteCancelFile()
* Parameters : String 
* Return Type: List<FileUploadedData>
* Requirement: Gitlab US #11113, #10928 
* Description: on change of API type, delete the uploaded file, restart process again with reference with newly selected API type
: this method is gets called from qtb_APIUpliftRenewal lwc component
**********************************************************************************************************/
    @AuraEnabled
    public static boolean deleteCancelFile(Id contentDocumentId){
        try{
            System.debug('QTB_APIUpliftCntrl_deleteCancelFile@@');
            //Fetching ContentDocument based on uploaded documentId
            List<ContentDocument> recentUploadedFile = [SELECT Id, Title, ContentSize,FileType,Owner.Name,createdDate 
                                                        FROM ContentDocument 
                                                        WHERE Id = : contentDocumentId];
            if(recentUploadedFile != null && !recentUploadedFile.isEmpty()){
                System.debug('recentUploadedFile@@'+recentUploadedFile);
                delete recentUploadedFile;
                return true;
            }else{
                return false; 
            }
        } 
        catch (Exception e){
            System.debug('Apex Class@@'+QTB_APIUpliftCntrl);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIUpliftCntrl); 
            return false;
        }
    }
    
    /*********************************************************************************************************
* Method Name: saveFile()
* Parameters : Id contentDocumentId, string apiType 
* Return Type: List<FileUploadedData>
* Requirement: Gitlab US #11113 
* Description: saveFile() methods read the csv file and store the data in wrapper class, and it also insert data in DataHolder object.
: this method is called on click of Process button of API Uplift screen from qtb_APIUpliftRenewal LWC comp
**********************************************************************************************************/
    @AuraEnabled
    public static List<FileUploadedData> saveFile(Id contentDocumentId, string apiType) {        
        System.debug('QTB_APIUpliftCntrl_saveFile_contentDocumentId@@'+contentDocumentId +', apiType@@'+apiType);
        List<FileUploadedData> fileObjList = new List<FileUploadedData>();       
        List<String> splitContentStringByNewLine = new List<String>();
        List<String> splitContentStringByComma = new List<String>();        
        List<SubscriptionDataWrapper> subDataWrapperList = new List<SubscriptionDataWrapper>();
        List<QTB_Data_Holder__c> dataHolderAPIObjList = new List<QTB_Data_Holder__c>();
        Map<String,Id> dataHolderAPIObjMap = new Map<String,Id>();           
        
        //Fetching ContentDocument based on uploaded documentId
        List<ContentDocument> uploadedFile = [SELECT Id, Title, ContentSize,FileType,Owner.Name,createdDate 
                                              FROM ContentDocument 
                                              WHERE Id = : contentDocumentId];
        try{
            System.debug('uploadedFile@@'+uploadedFile);
            if(uploadedFile != null && !uploadedFile.isEmpty()){
                //Setting description as "API Advance Storage", as based on this description filter it our documents
                uploadedFile[0].Description = apiType;
                update uploadedFile[0];
                
                QTB_Data_Holder__c dataHolderObj = new QTB_Data_Holder__c();
                dataHolderObj.QTB_APIDocument_Id__c = contentDocumentId;
                dataHolderObj.QTB_APIStatus__c = 'New';
                dataHolderObj.QTB_APIType__c = APIType;
                dataHolderObj.QTB_APIUploaded_By__c = uploadedFile[0].Owner.Name;
                dataHolderObj.QTB_APIUploaded_Date__c =  uploadedFile[0].createdDate.date();
                dataHolderObj.RecordTypeId = upliftAPIRecordTypeID;
                dataHolderAPIObjList.add(dataHolderObj);
                if(dataHolderAPIObjList !=null && !dataHolderAPIObjList.isEmpty()){
                    insert dataHolderAPIObjList;
                }
                dataHolderAPIObjMap.put(dataHolderAPIObjList[0].QTB_APIDocument_Id__c,dataHolderAPIObjList[0].Id); 
                //Creating instance of wrapper obj -- its used to show file data in table
                FileUploadedData fileObj = new FileUploadedData();
                fileObj.FileId = uploadedFile[0].Id;
                fileObj.FileName = uploadedFile[0].Title;  
                fileObj.APIType = apiType;
                fileObj.Status = 'New'; //on upload setting file status as "New"                
                if(fileObj.Status == 'New'){
                    fileObj.StatusColorCSSClass = 'slds-icon-custom-custom4'; //yellow color //https://www.lightningdesignsystem.com/icons/#custom    
                }
                fileObj.FileSize = uploadedFile[0].ContentSize;
                fileObj.UploadedDate = uploadedFile[0].createdDate.date();
                fileObj.UploadedBy = uploadedFile[0].Owner.Name;
                fileObjList.add(fileObj);
                
                //Changing Product's Subscription Type to 'Renewable'
				QTB_APISubscriptionUpliftBatch.revertProductSubtypeChanges(true);
                
                //Fetching File content of latest uploaded file
                List<ContentVersion> contentVersionList = [SELECT VersionData 
                                                           FROM ContentVersion 
                                                           WHERE ContentDocumentId = :uploadedFile[0].Id AND IsLatest = true order by createdDate desc limit 1];
                //Storing file content data to Blob format
                Blob contentDocumentData = contentVersionList[0].VersionData;
                //Converting Blob data format to string for further manipulation
                String contentDocString = contentDocumentData.toString();
                System.debug('contentDocString@@'+contentDocString);
                
                if(contentDocString != null && contentDocString.contains('\n')){
                    splitContentStringByNewLine = contentDocString.split('\n');
                    string removedColumnHeading = splitContentStringByNewLine.remove(0);
                }
                
                System.debug('splitContentStringByNewLine_Size@@'+splitContentStringByNewLine.size());
                System.debug('splitContentStringByNewLine@@'+splitContentStringByNewLine);            
                
                //filtering file contents based on "," and storing all values in list splitContentStringByComma
                for(string splitContentDoc : splitContentStringByNewLine){
                    if(splitContentDoc != null && splitContentDoc.contains(',')){
                        System.debug('splitContentDoc@@'+splitContentDoc);
                        splitContentStringByComma.addAll(splitContentDoc.split(','));               
                    }                     
                }
                splitContentStringByNewLine.clear(); //clearing the memory of List.
                System.debug('splitContentStringByComma_size@@'+splitContentStringByComma.size());
                System.debug('splitContentStringByComma@@'+splitContentStringByComma);
                
                //initializing the SubscriptionDataWrapper class to hold file content data
                //Limitatation -- File content column sequence & no of columns should not be change, else it will throw the error
                SubscriptionDataWrapper subDataWrap = new SubscriptionDataWrapper();
                integer count = -1;
                if(splitContentStringByComma != null){
                    for(Integer i = 0 ; i < splitContentStringByComma.size(); i ++){
                        count = count+1;
                        //Adding only required values to wrapper object, and commenting all other values.
                        switch on count{
                            when 0{                          
                                subDataWrap.subscriptionId = splitContentStringByComma[i];
                            }
                            when 1{
                                subDataWrap.contractName = splitContentStringByComma[i];
                            }
                            when 2{
                                subDataWrap.productId = splitContentStringByComma[i];
                            }
                            when 3{ 
                                subDataWrap.subscriptionCSName = splitContentStringByComma[i];
                            }
                            when 4{
                                subDataWrap.subscriptionCSRateId = splitContentStringByComma[i];
                            }
                            when 5{
                                subDataWrap.subscriptionCSRateName = splitContentStringByComma[i];
                            }
                            when 6{
                                subDataWrap.subscriptionCSRateLowerBound = splitContentStringByComma[i];
                            }
                            when 7{
                                subDataWrap.subscriptionCSRateUpperBound = splitContentStringByComma[i];
                            }
                            when 8{
                                subDataWrap.oldPrice = Decimal.valueOf(splitContentStringByComma[i]);
                            }
                            when 9{
                                string newPrice = splitContentStringByComma[i];
                                System.debug('newPrice1@@'+newPrice);
                                newPrice = newPrice.substringBefore('\r');
                                newPrice = newPrice.replaceAll('[^.\\d]','');
                                System.debug('newPrice2@@'+newPrice);
                                subDataWrap.newPrice = Decimal.valueOf(newPrice);
                                System.debug('subDataWrap.newPrice@@'+subDataWrap.newPrice);   
                                
                                //Add the wrapper record to the List
                                subDataWrapperList.add(subDataWrap);
                                // Initialize the wrapper List
                                subDataWrap = new SubscriptionDataWrapper();
                                count = -1 ;
                                System.debug('subDataWrapperList@@'+subDataWrapperList);
                            }
                        }	 
                    }
                    /*   
* for(Integer i = 0 ; i < splitContentStringByComma.size(); i ++){
count = count+1;
//Adding only required values to wrapper object, and commenting all other values.
switch on count{
when 0{                          
subDataWrap.subscriptionId = splitContentStringByComma[i];
}
when 1{ //subDataWrap.subscriptionStartDate = splitContentStringByComma[i];
}
when 2{ //subDataWrap.subscriptionEndDate = splitContentStringByComma[i];
}
when 3{
subDataWrap.contractName = splitContentStringByComma[i];
}                            
when 4{ //subDataWrap.salesAccountId = splitContentStringByComma[i];
}
when 5{ //subDataWrap.salesAccountName = splitContentStringByComma[i];
}
when 6{ //subDataWrap.productLine = splitContentStringByComma[i];
}
when 7{
subDataWrap.productId = splitContentStringByComma[i];
}
when 8{ //subDataWrap.productCode = splitContentStringByComma[i];
}
when 9{ //subDataWrap.oneilBillCode = splitContentStringByComma[i];
}
when 10{ //subDataWrap.productName = splitContentStringByComma[i];
}
when 11{ //subDataWrap.billingType = splitContentStringByComma[i];
}
when 12{ 
subDataWrap.subscriptionCSName = splitContentStringByComma[i];
}
when 13{
subDataWrap.subscriptionCSRateId = splitContentStringByComma[i];
}
when 14{
subDataWrap.subscriptionCSRateName = splitContentStringByComma[i];
}
when 15{
subDataWrap.subscriptionCSRateLowerBound = splitContentStringByComma[i];
}
when 16{
subDataWrap.subscriptionCSRateUpperBound = splitContentStringByComma[i];
}
when 17{ // subDataWrap.currencyVal = splitContentStringByComma[i];
}
when 18{
subDataWrap.oldPrice = Decimal.valueOf(splitContentStringByComma[i]);
}
when 19{
string newPrice = splitContentStringByComma[i];
System.debug('newPrice1@@'+newPrice);
newPrice = newPrice.substringBefore('\r');
newPrice = newPrice.replaceAll('[^.\\d]','');
System.debug('newPrice2@@'+newPrice);
subDataWrap.newPrice = Decimal.valueOf(newPrice);
System.debug('subDataWrap.newPrice@@'+subDataWrap.newPrice);                            
// subDataWrap.newPrice = Decimal.valueOf(splitContentStringByComma[i]); 

//Add the wrapper record to the List
subDataWrapperList.add(subDataWrap);
// Initialize the wrapper List
subDataWrap = new SubscriptionDataWrapper();
count = -1 ;
System.debug('subDataWrapperList@@'+subDataWrapperList);
}
}
} 
*/
                }
                splitContentStringByComma.clear(); //clearing the memory of this List variable.
            }
            System.debug('subDataWrapperList.size()@@'+subDataWrapperList.size());
            if(subDataWrapperList != null && !subDataWrapperList.isEmpty()){
                System.debug('subDataWrapperList_if@@'+subDataWrapperList);
                System.debug('apiType@@'+apiType);
                if(apiType == ADVANCE_API){
                    //Batch size is 1, calling Advance Storage API Batch and passing subscription wrapper data and documentId
                    Database.executeBatch(new QTB_APIAdvanceStorageBatch(subDataWrapperList,contentDocumentId),Integer.valueOf(System.Label.QTB_APIAdvanceBatchSize)); 
                }
                else if(apiType == REGULAR_API){
                    //Batch size is 1, calling Regular API Batch and passing subscription wrapper data and documentId
                    Database.executeBatch(new QTB_APISubscriptionUpliftBatch(subDataWrapperList,contentDocumentId),Integer.valueOf(System.Label.QTB_APIRegularBatchSize));
                }
            }
            if(fileObjList !=null && !fileObjList.isEmpty()){
                System.debug('fileObjList@@'+fileObjList);
                return fileObjList;
            }
            return null;
        }
        catch (Exception e){            
            //Updating DataHolder record as Failed
            QTB_Data_Holder__c dataHolderAPIObj = new QTB_Data_Holder__c();
            dataHolderAPIObj.QTB_APIStatus__c = 'Failed';
            dataHolderAPIObj.Id = dataHolderAPIObjMap.get(contentDocumentId);
            update dataHolderAPIObj;
            
            System.debug('Apex Class@@'+QTB_APIUpliftCntrl);
            System.debug('e.getLineNumber()@@'+e.getLineNumber());
            System.debug('e.getMessage()@@'+e.getMessage());
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_APIUpliftCntrl); 
            return null;
        }
    }
    
    public class FileUploadedData{  
        @AuraEnabled public string FileId {get;set;}
        @AuraEnabled public string FileName {get;set;}
        @AuraEnabled public string APIType {get;set;}
        @AuraEnabled public string Status {get;set;}
        @AuraEnabled public string StatusColorCSSClass {get;set;}
        @AuraEnabled public Integer FileSize {get;set;}
        @AuraEnabled public Date UploadedDate {get;set;}
        @AuraEnabled public String UploadedBy {get;set;}
    }
    
    public class SubscriptionDataWrapper{  
        public String subscriptionId;        
        public String contractName;
        public String productId;
        public String subscriptionCSName; 
        public String subscriptionCSRateId;
        public String subscriptionCSRateName;
        public String subscriptionCSRateLowerBound;
        public String subscriptionCSRateUpperBound;
        public Decimal oldPrice;
        public Decimal newPrice;
        //public String subscriptionStartDate;
        //public String subscriptionEndDate;
        //public String oneilId; -- this is not in report
        //public String salesAccountId;
        //public String salesAccountName;
        //public String productLine;       
        //public String productCode;
        //public String oneilBillCode;
        //public String productName;
        //public String billingType;               
        //public String currencyVal;       
    }
}
/*****************************************************************************************************
* Class         : QTB_APIUpliftCntrl_Test
* Purpose       : This is a Test Class used to test QTB_APIUpliftCntrl
* Requirement   : Gitlab US #11113 Advanced Storage Billing - Read the data and run the batch, 
				: Gitlab #10928 Internal Bulk Amendment Process: Functionality to Parse Data from Uploaded Spreadsheet
* Author        : Virtusa
* Developer     : Shailesh
* Developer                 Date                Description 
* ------------------------------------------------------------------------------------------- 
*  Shailesh               12/10/2022	Gitlab US #11113 Advanced Storage Billing - Read the data and run the batch
										Gitlab #10928 Internal Bulk Amendment Process: Functionality to Parse Data from Uploaded Spreadsheet
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_APIUpliftCntrl_Test {
    @testSetup
    static void setup() {
        string FileData = 'Subscription ID,Start Date,End Date,Contract: Contract Number,Contract: Account Name: Account ID,Account: API Account Name,Product: Product Line,Product Id,Product: Product Code,Product: Bill Code,Product: API Product Name,Product: Billing Type,Consumption Schedule: Consumption Schedule Name,Subscription Consumption Rate ID,Subscription Consumption Rate Name,API Lower Bound,API Upper Bound,Currency,API Price,New Price\n';
        FileData = FileData +'aIB7b0000004Gch,10/14/2022,10/13/2023,FIN-22-00101487,0017b00000yNFny,Finland_SalesAccount1,Products,01t2H000005WIoS,01100-0341,01100-0341,Retrieval unregistered document add-on fee,Arrears,Work Order Rate 01100-0341,aI97b0000008QFl,R-001900,1,51,EUR,4.98,5.976';
        ContentVersion contentVersionAdvanceAPI = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'AdvanceAPI.csv',
            VersionData    = Blob.valueOf(FileData),
            IsMajorVersion = true,
        	Description = 'Advance API');
        insert contentVersionAdvanceAPI;
        
        ContentVersion contentVersionRegularAPI = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'RegularAPI.csv',
            VersionData    = Blob.valueOf(FileData),
            IsMajorVersion = true,
        	Description = 'Regular API');
        insert contentVersionRegularAPI;
        
        List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ];
      
    }
    
    static testMethod void testmethod1(){
        List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ];
        QTB_APIUpliftCntrl.saveFile(fileList[0].Id, 'Advance API');
        QTB_APIUpliftCntrl.saveFile(fileList[0].Id, 'Regular API');
        QTB_APIUpliftCntrl.getUploadedData();
        QTB_APIUpliftCntrl.deleteCancelFile(fileList[0].Id);
        QTB_APIUpliftCntrl.SubscriptionDataWrapper abc = new QTB_APIUpliftCntrl.SubscriptionDataWrapper();
    }
}
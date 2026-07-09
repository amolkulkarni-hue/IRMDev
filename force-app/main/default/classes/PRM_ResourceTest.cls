@isTest
public class PRM_ResourceTest {
    
    @testSetup static void resourceSetup() {
 		ContentVersion cv = new ContentVersion();
        cv.Description = 'test';
        cv.VersionData = Blob.valueOf('test');
        cv.Title = 'test';
        cv.PathOnClient = 'test.txt';
        insert cv;
        
        ContentVersion cv2 = [select Id, ContentDocumentId from ContentVersion where Id= : cv.Id];
        
        PRM_SAVOSetting__mdt savoSetting = [SELECT 	PRM_ContentLibraries__c  
                                           	FROM	PRM_SAVOSetting__mdt 
                                           	WHERE 	DeveloperName = 'SAVO'];
        
        List<String> libNames = savoSetting.PRM_ContentLibraries__c.split(';');
        
        ContentWorkspace lib = [select Id, Name
                                from ContentWorkspace 
                                where Name =: libNames[0]];
        
     
        
       /* ContentWorkspaceDoc workspace = new ContentWorkspaceDoc();
        workspace.ContentDocumentId = cv2.ContentDocumentId;
        workspace.ContentWorkspaceId = lib.Id;
        insert workspace;    */
        
	}
    
	@isTest static void testResource() {

        Test.startTest();
        PRM_ResourceWrapper wrp = PRM_ResourceController.getFilters();
        wrp = PRM_ResourceController.getResources(JSON.serialize(wrp), 'PRM_ContentSearch');
        System.assert(wrp != null);
        
        wrp.searchText = 'test';
        wrp = PRM_ResourceController.getResources(JSON.serialize(wrp), 'PRM_ContentSearch');
        System.assert(wrp != null);
        
        wrp.channel = 'test';
        wrp.solution = 'test';
        wrp.productFamily = 'test';
        wrp.fileType = 'test';        
        wrp = PRM_ResourceController.getResources(JSON.serialize(wrp), 'PRM_ContentSearch');
        System.assert(wrp != null);
        
        
        Test.stopTest();
    }
    
    
    @isTest static void testContentWrapper() {

        Test.startTest();
        ContentVersion cv = new ContentVersion();
        PRM_ContentWrapper wrp = new PRM_ContentWrapper(cv);
        wrp.libraries = new List<String>();
        wrp.contentSize = 1001;
        wrp.setSize();
        System.assert(wrp.fileSize.endsWith('KB'));
        
        wrp.contentSize = 1000001;
        wrp.setSize();
        System.assert(wrp.fileSize.endsWith('MB'));
        
        wrp.contentSize = 1000000001;
        wrp.setSize();
        System.assert(wrp.fileSize.endsWith('GB'));
        
        PRM_Helper.getAllQueryString('Account');
        //PRM_Helper.getFieldInfo('ContentVersion', 'PRM_SAVODocumentID__c');
        
        
        PRM_Helper.getAccountManager();
        
        Test.stopTest();
    }
    
}
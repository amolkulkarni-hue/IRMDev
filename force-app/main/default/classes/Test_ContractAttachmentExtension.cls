@isTest
    public class Test_ContractAttachmentExtension {
        public static Account testAccount;
        public static Contact testContact;
        public static Contact secondContact;
        public static OpportunityContactRole opptContRole;
        public static Opportunity testOpp;
        public static Quote testquote;
        public static Attachment testattachment;
        public static ContentVersion testContentVersion;
        public static FeedItem testFeedItem;
    
        public static void setup() {
            IM_Country__c cntry = TestingUtil.createIMCountry();	
            RecordType EUOppType = [select id from RecordType	
                                    where name = 'Standard Opportunity'	
                                    and sObjectType = 'Opportunity'];	
            Id standardPB = Test.getStandardPricebookId();	
            //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
            
           OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
            oppprodsel.Name = 'CloudSolutionsProduct';	
            oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
            oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
            insert oppprodsel; 	
            Country_Settings__c setting = new Country_Settings__c();	
            setting.Name = 'United States';	
            setting.object_name__c = 'Account';	
            insert setting;
            
            Account testAccount = TestingUtils.createAccounts(1, true)[0];
            System.debug('testAccount ID: ' + testAccount.Id);
            
             testContact = TestingUtils.createContact(testAccount.Id, true);
            System.debug('testContact ID: ' + testContact.Id);
            testOpp = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
            
            System.runAs ( TestingUtils.ADMIN_USER ){
                User currentUser = new User ( Id = UserInfo.getUserId() );
                currentUser.Commission_ID__c = '123';
                update currentUser;
                insert testOpp;
                
            }
            
           // testAccount = TestingUtils.createAccounts(1, true)[0];
           
           /* testOpp = new Opportunity( 
                Name='testoppty', 
                CloseDate=Date.today(), 
                StageName='1 - Qualification', 
                AccountId=testAccount.Id, 
                Group_Purchasing_Organization_GPO__c='HealthTrust', 
                IME_Vended_Unvended__c='Unknown'
            );
            insert testOpp; */
    
            testattachment = new Attachment(
                ParentId=testOpp.Id, 
                Name='Test Attachment for Parent', 
                Body=Blob.valueOf('Test Data')
            );  
            insert testattachment;
    
            Loop__DDP__c ddp1 = new Loop__DDP__c(Name = 'DDP 1', Loop__Filter__c = 'FieldSales');
            Loop__DDP__c ddp2 = new Loop__DDP__c(Name = 'DDP 2', Loop__Filter__c = 'FieldSales');
            insert new List<Loop__DDP__c>{ ddp1, ddp2 };
    
            testContentVersion = new ContentVersion(
                Title = 'Test', 
                PathOnClient = 'Test.dot',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
            );
            insert testContentVersion;    
    
            testFeedItem = new FeedItem(ParentId = testOpp.Id, RelatedRecordId = testContentVersion.Id);
            insert testFeedItem;     
            
        }
    
        @isTest
        static void myUnitTest() {
            setup(); 
            ContractAttachmentExtension.OrderedSelectOption wrap = new ContractAttachmentExtension.OrderedSelectOption(
                1, 
                testattachment.Id, 
                testFeedItem.Id, 
                'Test', 
                false, 
                testOpp.Id
            );
            
            Loop__DDP__c ddp1 = new Loop__DDP__c(Name = 'DDP 1', Loop__Filter__c = 'FieldSales');
            Loop__DDP__c ddp2 = new Loop__DDP__c(Name = 'DDP 2', Loop__Filter__c = 'FieldSales');
            insert new List<Loop__DDP__c>{ ddp1, ddp2 };
                
                ContentVersion testContentVersion2 = new ContentVersion(
                Title = 'Test', 
                PathOnClient = 'Test.pdf',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
            );
            insert testContentVersion2;
    
            PageReference pageRef = Page.DL_VF_Working_On;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('id', testOpp.id);
            ApexPages.StandardController stdController = new ApexPages.StandardController(testOpp);
            ContractAttachmentExtension cont = new ContractAttachmentExtension(stdController);
            cont.selectedDdpId = ddp1.id;
            Test.startTest();
            ContractAttachmentExtension.cleanTempAttachments(testOpp.Id);
            ContractAttachmentExtension.convertAttachment(testContentVersion.Id, testOpp.Id); // 
            ContractAttachmentExtension.convertAttachment(testContentVersion2.Id, testOpp.Id);
            ContractAttachmentExtension.convertpdfAttachment(testattachment.Id, testOpp.Id);
            ContractAttachmentExtension.convertpdfAttachment(testContentVersion2.Id, testOpp.Id);
            ContractAttachmentExtension.findAttachment(testattachment.Id, testOpp.Id, testattachment.Id, '006');
            cont.changeDdp();
            cont.changeContact();
            cont.runDdp();
            Test.stopTest();
        }
    
        @isTest
        static void testAttachmentLoopLogic() {
            setup(); 
            delete [SELECT Id FROM Attachment WHERE ParentId = :testOpp.Id];
            
            Loop__DDP__c ddp1 = new Loop__DDP__c(Name = 'DDP 1', Loop__Filter__c = 'FieldSales');
            Loop__DDP__c ddp2 = new Loop__DDP__c(Name = 'DDP 2', Loop__Filter__c = 'FieldSales');
            insert new List<Loop__DDP__c>{ ddp1, ddp2 };
    
            Id selectedDdpId = ddp1.Id;
    
            Attachment a = new Attachment(
                Name = 'DDP 1_Attachment', 
                ParentId = testOpp.Id, 
                Body = Blob.valueOf('Test Data')
            );
            insert a;
    
            List<ContractAttachmentExtension.OrderedSelectOption> attachments = new List<ContractAttachmentExtension.OrderedSelectOption>();
    
            List<Attachment> attList = [SELECT Id, Name FROM Attachment WHERE ParentId = :testOpp.Id];
    
            for (Attachment att : attList) {
                System.debug(LoggingLevel.Info, 'Inside Normal Attachment ===' + att.Name);
    
                if (att.Name.startsWith(ddp1.Name)) { 
                    attachments.add(new ContractAttachmentExtension.OrderedSelectOption(
                        attachments.size(), 
                        att.Id, 
                        '', 
                        'Contract', 
                        false, 
                        ''
                    ));
                } else {
                    attachments.add(new ContractAttachmentExtension.OrderedSelectOption(
                        attachments.size(), 
                        att.Id, 
                        '', 
                        att.Name, 
                        false, 
                        ''
                    ));
                }
            }
    
            System.assertEquals(1, attachments.size(), 'There should be one attachment in the list.');
            System.assertEquals('Contract', attachments[0].Label, 'The label should be "Contract" if the name starts with DDP 1.');
        }
         
      static testMethod void myUnitTest2() {
            setup(); 
        
            
            Loop__DDP__c ddp1 = new Loop__DDP__c(Name = 'DDP 1', Loop__Filter__c = 'FieldSales');
            
             Attachment a = new Attachment(
                Name = 'DDP 1_Attachment', 
                ParentId = testOpp.Id, 
                Body = Blob.valueOf('Test Data22')
            );
            insert a;
    
            List<ContractAttachmentExtension.OrderedSelectOption> attachments = new List<ContractAttachmentExtension.OrderedSelectOption>();
    
            List<Attachment> attList = [SELECT Id, Name FROM Attachment WHERE ParentId = :testOpp.Id];
             
            for (Attachment att : attList) {
                System.debug(LoggingLevel.Info, 'Inside Normal Attachment ===' + att.Name);
    
                if (att.Name.startsWith(ddp1.Name)) { 
                    
                   ContractAttachmentExtension.OrderedSelectOption ifWrapper =  new ContractAttachmentExtension.OrderedSelectOption(
                        attachments.size(), 
                        att.Id, 
                        '', 
                        'Contract', 
                        false, 
                        ''
                    );
                    
                    ifWrapper.isSelected = true;
                    
                    attachments.add(ifWrapper);
                } else {
                    
                    ContractAttachmentExtension.OrderedSelectOption elseWrapper = new ContractAttachmentExtension.OrderedSelectOption(
                        attachments.size(), 
                        att.Id, 
                        '', 
                        att.Name, 
                        false, 
                        ''
                    );
                    elseWrapper.isSelected = true;
                    attachments.add(elseWrapper);
                }
            }
            system.debug('testContact '+testContact.id);
          
            PageReference pageRef = Page.DL_VF_Working_On;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('id', testOpp.id);
            ApexPages.StandardController stdController = new ApexPages.StandardController(testOpp);
            ContractAttachmentExtension cont = new ContractAttachmentExtension(stdController);
            cont.attachments = attachments;
            
            for(ContractAttachmentExtension.OrderedSelectOption os:attachments ){
                system.debug(''+os.isSelected);
            }
            
            Id selectedDdpId = a.Id;
            cont.selectedDdpId = selectedDdpId;
            cont.selectedContact = testContact.id;
    
           Test.startTest();
          //  cont.changeDdp();
           // cont.changeContact();
            cont.runDdp();
            Test.stopTest();
        }
    
    
        @isTest
        static void testContractsProperty() {
            setup();
            ApexPages.StandardController sc = new ApexPages.StandardController([SELECT Id FROM Opportunity LIMIT 1]);
            ContractAttachmentExtension obj = new ContractAttachmentExtension(sc);
            List<SelectOption> contracts = obj.contracts;
    
            System.assertEquals(2, contracts.size(), 'There should be two contracts.');
            System.assertEquals('DDP 1', contracts[0].getLabel(), 'The first contract should be "DDP 1".');
            System.assertEquals('DDP 2', contracts[1].getLabel(), 'The second contract should be "DDP 2".');
        }
  
    }
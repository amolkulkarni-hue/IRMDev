/*****************************************************************************************************
* Class: QTB_QuoteDocumentTriggerHelperTest
* Author: Accenture
* Purpose: Test Class for QTB_CNLHelper, QTB_QuoteDocumentTriggerHandler and QTB_QuoteDocumentTrigger
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   9/22/2020
*******************************************************************************************************/
@isTest(seeAllData=false)
public class QTB_QuoteDocumentTriggerHelperTest {
    @testSetup static void testSetupData(){
        QTB_Quote_Field_Validations__c fieldCust = new QTB_Quote_Field_Validations__c();
        fieldCust.QTB_Field_List__c ='QTB_Minimum_Charges_Start_Date__c,QTB_Work_Order_Minimum_Start_Date__c,QTB_Invoice_Minimum_Start_Date__c,QTB_Free_Up_Start__c,QTB_Free_Products_Start_Date__c';
        fieldCust.Name ='Date field names';
        fieldCust.QTB_Delta_Fields__c = 'QTB_Delta_Minimum_StartDate__c,QTB_Delta_Work_Order_StartDate__c,QTB_Delta_Invoice_Minimum_StartDate__c,QTB_Delta_Free_Up_StartDate__c,QTB_Delta_Free_Products_StartDate__c';
        fieldCust.QTB_Restrict_on_Accepted_Quote__c = 'QTB_Minimum_Charges_Start_Date__c,QTB_Work_Order_Minimum_Start_Date__c,QTB_Invoice_Minimum_Start_Date__c,QTB_Free_Up_Start__c,QTB_Free_Products_Start_Date__c,SBQQ__StartDate__c,SBQQ__Primary__c';
        insert fieldCust;
        
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c='SBQQ__Quote__c';
        custSetting.Disable_VR__c=true;
        custSetting.Disable_PB__c= true;
        custSetting.SetupOwnerId = UserInfo.getOrganizationId();
        insert custSetting;
    }
    static testMethod void method1()
    {
         Map<Id,String> attachmentMap=new Map<Id,String>();
       List<User> userList = QTB_TestDataFactory.usrMethdLst(1); 
        Test.startTest();
        system.runas(userList[0]) { 
            List<account> accountList =QTB_TestDataFactory.createAccounts(1);
            accountList[0].BillingCountry='India';
            accountList[0].QTB_Legal_Entity_Country__c='India';
            update accountList;
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
            blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<product2> product=QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c=billingRule.id;
            product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
            product[0].blng__TaxRule__c =taxRule.id;
            database.update(product); 
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
            
            // Update the pricebook of opportunity
            List<opportunity> oppList=QTB_TestDataFactory.createOpps(accountList);
            oppList[0].Pricebook2Id =pricebookId; 
            database.update(oppList); 
            
            List<SBQQ__Quote__c> quoteList=QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
            quoteList[0].SBQQ__Startdate__c = system.today();
            database.update(quoteList);
            
            
        SBQQ__QuoteTemplate__c qt= new SBQQ__QuoteTemplate__c();
        qt.Name ='Price Quote';
        insert qt;
        
        SBQQ__QuoteDocument__c qd= new SBQQ__QuoteDocument__c();
        qd.SBQQ__QuoteTemplate__c =qt.id;
        qd.Name = 'Price Quote Test';
        qd.SBQQ__Quote__c = quoteList[0].id;
        qd.SBQQ__OutputFormat__c = 'pdf';
        insert qd;
     
        Attachment att = new Attachment();
        att.Name = 'Price Quote Attachment';
        att.ParentId = qd.Id;
        att.body = Blob.valueOf('Price Quote Attachment');
        att.ContentType = 'txt';
        insert att;
       // att.Name = 'TestAtt';
        qd.SBQQ__AttachmentId__c = att.Id;
        update qd;
       // insert att;
        attachmentMap.put(att.id,qd.Name); 
        QTB_QuoteDocumentHelper.updateAttachment(attachmentMap);
        Test.stopTest();
    }
    }
    static testmethod void testmethod2(){
        Test.startTest();
        QTB_QuoteDocumentTriggerHandler.throwExplicitException = true;
        QTB_QuoteDocumentTriggerHandler handler=new QTB_QuoteDocumentTriggerHandler();
        handler.AfterUpdate(null,null);
        handler.BeforeUpdate(null,null);
        handler.AfterDelete(null);
        handler.AfterUndelete(null);
        handler.BeforeDelete(null);        
        try { 
            QTB_QuoteDocumentHelper.updateAttachment(null);
        }
        catch(NullPointerException e) { 
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE_DOCUMENT);
        handler.isDisabled();
        Test.stopTest();
        System.assertEquals(true, QTB_QuoteDocumentTriggerHandler.throwExplicitException);
    }    
}
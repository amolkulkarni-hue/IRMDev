public class QTB_InFlowOrderItemBatch_SITAD implements Database.Batchable<SObject>,Database.Stateful{    
  @InvocableMethod(Label='CallQTB_InFlowOrderItemBatch_SITAD' description='This method will be execute QTB_InFlowOrderItemBatch_SITAD')
  public static void executeBatchMethod(List<Id> ordidlst) {
  Database.executeBatch(new QTB_InFlowOrderItemBatch_SITAD(ordidlst), 1);
  } 
  public static final string className = QTB_InFlowOrderItemBatch_SITAD.class.getName();
  public static boolean throwExplicitException = false;
  public String query;
  public List<Id> OrderRecordTypeId = new List<Id>();
  public Set<Id> orderIdSet = new Set<Id>(); 
  public Set<String> CountrySet = new Set<String>();
  public List<ID> OrderListprcID = new List<ID>();
  public List<pricebookentry> PriceBklst = new List<pricebookentry>(); 
  public List<Pricebook2> SgPricebook = new List<Pricebook2>();
  public List<blng__BillingTreatment__c> sgListBillingTreat = new List<blng__BillingTreatment__c>();  
  public List<blng__LegalEntity__c> SgLegalEnity = new List<blng__LegalEntity__c>();
  public List<Order> SgOrder = new List<Order>(); 
    
public QTB_InFlowOrderItemBatch_SITAD(List<Id> currOrderID) {
   // Retreive Country and Currency from Order 
    sgOrder=[Select id,QTB_Legal_Entity_Country__c, CurrencyIsoCode from order where Id =:currOrderID]; 
    
    QTB_Billing_Countries__c Billcust = QTB_Billing_Countries__c.getInstance(sgOrder[0].QTB_Legal_Entity_Country__c);
    orderIdSet.addAll(currOrderID);
    CountrySet.add(sgOrder[0].QTB_Legal_Entity_Country__c);
    
    //To retrieve the Billing Treatment
    sgListBillingTreat=[Select id, name,blng__BillingRule__r.id from blng__BillingTreatment__c Where Name='No Invoice Billing Treatment' LIMIT 1];
    
    //To retrieve the Legal Entity
    SgLegalEnity=[Select id, name from blng__LegalEntity__c Where blng__Country__c=:sgOrder[0].QTB_Legal_Entity_Country__c and CurrencyIsoCode=:sgOrder[0].CurrencyIsoCode LIMIT 1];
    
    String myCountry = sgOrder[0].QTB_Legal_Entity_Country__c ;
    system.debug('myCountry>>>>>>>>>>>>>>>>>>>>>>>>>>'+ myCountry);
    
    //To retreive the Pricebook2
    SgPricebook=[Select id, name from Pricebook2 Where name =:myCountry and QTB_Country__c =: myCountry LIMIT 1];    
    OrderRecordTypeId.add(Schema.SObjectType.Order.getRecordTypeInfosByName().get('Billing Order').getRecordTypeId());
  
    //To retreive the PriceBookEntry
    if(SgPricebook.size() > 0) 
    {
        PriceBklst=[select id, name,Product2Id,Product2.SBQQ__ChargeType__c,Product2.SBQQ__BillingFrequency__c,Product2.SBQQ__BillingType__c,Product2.blng__BillingRule__c,Product2.blng__TaxRule__c,Product2.blng__RevenueRecognitionRule__c,Product2.SBQQ__SubscriptionTerm__c from pricebookentry where pricebook2id =: SgPricebook[0].id  and Product2.IM_Product_Line__c = 'ALM-Secure ITAD'];
        
    }
    
    query=
            ' Select Id,EffectiveDate,Status' +
            ' from Order where ID' + 
            ' IN :orderIdSet' +
            ' AND QTB_Legal_Entity_Country__c  IN :CountrySet' +
            ' AND Order.RecordtypeID IN :OrderRecordTypeId'; 
      system.debug('In Start method of batch>>>>>>>>>>1111111111111999999'+ query);
    }
 /*********************************************************************************************************
    Method Name: start
    Parameters: Database.BatchableContext
    Return Type: Iterable
    Requirement: 
    Description: Fetch required records
    **********************************************************************************************************/
 public Database.QueryLocator start(Database.BatchableContext BC) {
       return Database.getQueryLocator(query);
  
  /*********************************************************************************************************
    Method Name: execute
    Parameters: Database.BatchableContext,List<Order>
    Return Type: void
    Requirement: 
    Description: Creates/Updates OPCS and OPCR on order product.
    **********************************************************************************************************/
  }
  public void execute(Database.BatchableContext BC, List<Order> scope) {
    system.debug('In execute method of batch>>>>>>>>>>');
    String errorIds = '';   
    try {
      if (throwExplicitException) {
          system.debug('NullPointer');
        throw new NullPointerException();
      }
       List<OrderItem> OrderItemlst = new List<OrderItem>();      
        For(Order ord : scope)
        { 
         For(pricebookentry pr : PriceBklst)
           { 
            OrderItem temporderitem = new OrderItem();
                temporderitem.OrderId = ord.id;
                temporderitem.Product2Id = pr.Product2.Id;
                temporderitem.Quantity = 1;
                temporderitem.SBQQ__BillingFrequency__c = pr.Product2.SBQQ__BillingFrequency__c;
                temporderitem.SBQQ__BillingType__c = pr.Product2.SBQQ__BillingType__c;
                temporderitem.SBQQ__ChargeType__c = pr.Product2.SBQQ__ChargeType__c; 
                temporderitem.SBQQ__ProductSubscriptionType__c = 'Evergreen';
                temporderitem.SBQQ__Status__c = 'Draft';
                temporderitem.SBQQ__SubscriptionTerm__c= pr.Product2.SBQQ__SubscriptionTerm__c;
                temporderitem.ServiceDate = ord.EffectiveDate;
                temporderitem.blng__TaxRule__c = pr.Product2.blng__TaxRule__c;
                temporderitem.PricebookEntryId = pr.Id;
                temporderitem.blng__RevenueRecognitionRule__c = pr.Product2.blng__RevenueRecognitionRule__c;
                temporderitem.SBQQ__DefaultSubscriptionTerm__c = pr.Product2.SBQQ__SubscriptionTerm__c;                   
                temporderitem.SBQQ__SubscriptionType__c = 'Evergreen';
                temporderitem.blng__BillingTreatment__c = sgListBillingTreat[0].id;
                temporderitem.blng__BillableUnitPrice__c= 0;
                temporderitem.UnitPrice = 0;
                temporderitem.blng__BillingRule__c = pr.Product2.blng__BillingRule__c;
                temporderitem.blng__LegalEntity__c = SgLegalEnity[0].id;
                OrderItemlst.add(temporderitem);    
                }
            OrderListprcID.add(ord.id);
              }
             if (!OrderItemlst.isEmpty())
                { 
               insert OrderItemlst;
               system.debug('in Execute Records Created  OrderItems =========='+ OrderItemlst.size());
                }
           
         
      } catch (exception e) {
      errorIds = e.getMessage() + errorIds;
      if (errorIds.length() > 100000)
        errorIds = errorIds.substring(0, 100000);
          system.debug('In catch method of batch 147>>>>>>>>>>');
      system.debug('Error inf::' + errorIds);
      QTB_ExceptionLogger.createLog(
        e.getLineNumber(),
        e.getStackTraceString(),
        errorIds,
        e.getTypeName(),
        className
      );
           if (!OrderListprcID.isEmpty())
        {
      // Delete OrderListprcID;
         }
    }
  }
  /*********************************************************************************************************
    Method Name: finish
    Parameters: Database.BatchableContext
    Return Type: void
    Requirement: 
    Description: No action to be taken
    **********************************************************************************************************/
  public void finish(Database.BatchableContext BC) {
      
       system.debug('in finish==========');
       String errorIds = '';
      try {
      if (throwExplicitException) {
          system.debug('NullPointer');
        throw new NullPointerException();
      } 
       if (!OrderListprcID.isEmpty())
                { 
                    Database.executeBatch(new QTB_AddOrderProductCSCRBatch(OrderListprcID), 300);
                }
     
     
      }   
   catch (exception e) {
      errorIds = e.getMessage() + errorIds;
      if (errorIds.length() > 100000)
        errorIds = errorIds.substring(0, 100000);
      system.debug('In catch method of batch Finish>>>>>>>>>>');
      system.debug('Error inf::' + errorIds);
      QTB_ExceptionLogger.createLog(
        e.getLineNumber(),
        e.getStackTraceString(),
        errorIds,
        e.getTypeName(),
        className
      );
    }         
   
      
  }
}
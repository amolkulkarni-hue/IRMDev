/* 
  Created Date: July 08,2010
  Auhtor: Nathan Shinn
  Description : Creates a Customer Account record when a client code is added to the opportunity.
  
  Updates: 11/19/2010: Nathan Shinn: base duplicate client codes on the customer account country instead of the 
                       Opportunity Country.
*/ 

trigger IME_OpportunityCustAcctTrg on Opportunity (after insert, after update) 
{
    /****Variable declaration for 'createcustomeraccounts' Trigger****/
    
        public String createcustomeraccounts = null;
        
        /***Retrieving Custom Settings***/
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        for(Trigger_Activation_Settings__c cs : customsettings)
        {
            if(cs.Object__c=='Opportunity')
            {
                if(cs.Trigger__c == 'createcustomeraccounts') 
                {
                    createcustomeraccounts = cs.Value__c;    
                }
            }
        }
    if(createcustomeraccounts == 'True')
    {
        for(Opportunity o : Trigger.new)
        {
           System.debug('At the start of OpportunityCustAcctTrg --kab---closedate:' + o.CloseDate);
            
        }
       if(triggerFlowControl.triggerRunCount('OpportunityCustAcctTrg') > 1 )
         return; //Make sure that this doesn't get run twice in the same transaction
         
       //Global Variables
       Map<String,String> opportunityProduct = new map<String,String>();
       Map<id,String> opportunityProductClass = new map<Id,String>();
       Set<id> opportunityIds = new Set<id>();
       List<String> clientCodes = new List<String>();
       List<String> custOpportunies = new List<String>();
       set<id> oppCountryCodes = new set<id>();
       map<Id, Schema.RecordTypeInfo> rt_map = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosById();
       Map<String,String> optyRecMap =new Map<String,String>();
       
       // Changes begin
       // 2011-02-07    Removed this query as part of changes to add IMAP region to the system.
       //               Previously, a query was made for the EU record type for Opportunity,
       //               however we now need to check for EU and IMAP record types. Instead
       //               of a query, we use Schema and Describe objects to get record types
       //               and add the EU and IMAP ones to a set of IDs. This set is then used
       //               in other places where the EUOppType variables was used. Record types
       //               for new regions can be added by extending the code below.
       //               - Gary Breavington
       // 2011-06-07    MJ - added IMLA
       
        ID recTypeIME = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
        ID recTypeIMAP = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IMAP Standard Opportunity').getRecordTypeId();
        ID recTypeIMLA = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IMLA Standard Opportunity').getRecordTypeId();
        
        for(Opportunity recOpty : Trigger.new){
            optyRecMap.put(recOpty.RecordTypeId, recOpty.RecordTypeId);
            system.debug('optyRecMap----'+optyRecMap);
        }
       
       //retrieve the EU Oppty Record Type
       /*RecordType EUOppType = [select id from RecordType
                              where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];*/
        
        // Get the Describe information for Opportunity, and get the RecordTypeInfo 
        // objects associated with it                       
        Schema.DescribeSObjectResult oppDescribeInfo = Schema.SObjectType.Opportunity;
        Map<String, Schema.RecordTypeInfo> oppRecordTypes = oppDescribeInfo.getRecordTypeInfosByName();
        System.debug('oppRecordTypes-----'+oppRecordTypes);
        // Create a set to store the record types in, then store only the relevant record type IDs in it
        Set<ID> recordTypeIDs = new Set<ID>();
        // Check first that we have record types with the name to prevent nulls being added to the Set.
        if(oppRecordTypes.containsKey('IME Standard Opportunity'))
            recordTypeIDs.add(oppRecordTypes.get('IME Standard Opportunity').getRecordTypeId());
        if(oppRecordTypes.containsKey('IMAP Standard Opportunity'))
            recordTypeIDs.add(oppRecordTypes.get('IMAP Standard Opportunity').getRecordTypeId());
        if(oppRecordTypes.containsKey('IMLA Standard Opportunity'))
            recordTypeIDs.add(oppRecordTypes.get('IMLA Standard Opportunity').getRecordTypeId());

        // Changes end
       
        if(optyRecMap.containsKey(recTypeIME) || optyRecMap.containsKey(recTypeIMAP) || optyRecMap.containsKey(recTypeIMLA))
        {
           //Load the Opportunity ID List to use in subsequent queries
           for(Opportunity i : Trigger.new){
                // 2011-02-07   As part of the changes outlined above, check if the record type
                //              of the opportunity is one of the types we added above
               //if(i.RecordTypeId == EUOppType.Id ) // Old line
               System.debug('++++60+++recordTypeIDs.contains(i.RecordTypeId):'+recordTypeIDs.contains(i.RecordTypeId));
               System.debug('OpportunityCustAcctTrg---kab---CloseDate: '+ i.CloseDate);
               System.debug('-------------------recordTypeIDs: '+ recordTypeIDs +'\t i.RecordTypeId:'+i.RecordTypeId);
               if(recordTypeIDs.contains(i.RecordTypeId)) // New line
                  opportunityIds.add(i.id);
               System.debug('+++63++++opportunityIds:'+opportunityIds);
               
               System.debug('+++65++++i.Customer_Account_Number__c:'+i.Customer_Account_Number__c);
               if(i.Customer_Account_Number__c != null )
                  clientCodes.add(i.Customer_Account_Number__c);
               System.debug('+++68++++clientCodes:'+clientCodes);
               
               System.debug('+++70++++i.Billing_Country__c:'+i.Billing_Country__c);
               if(i.Billing_Country__c != null )
                  oppCountryCodes.add(i.Billing_Country__c);
               System.debug('+++73++++oppCountryCodes:'+oppCountryCodes);
            }
            
            List<OpportunityLineItem> opptylneitmLst = [Select o.PricebookEntry.Product2.IM_Product_Class__c,o.PricebookEntryId,o.OpportunityId From OpportunityLineItem o where o.OpportunityId in :opportunityIds];
            List<IM_Customer_Account__c> custAccntLst = [select id, name, IM_Opportunity__c, IM_Opportunity__r.Billing_Country__c from IM_Customer_Account__c where IM_Opportunity__c in :opportunityIds];
            
            
           //get the opportunity line items
           for( OpportunityLineItem oli : opptylneitmLst) 
            {                               
               opportunityProduct.put(oli.OpportunityId,oli.PricebookEntry.Product2.IM_Product_Class__c);
               System.debug('+++84++++opportunityProduct.put(oli.OpportunityId,oli.PricebookEntry.Product2.IM_Product_Class__c):'+opportunityProduct.put(oli.OpportunityId,oli.PricebookEntry.Product2.IM_Product_Class__c));
            
            }                                 
           //Load the customerAccount map limiting on the opportunityIds list
           Map<id,IM_Customer_Account__c> existingCustAcct = new Map<id,IM_Customer_Account__c>();
           try
            {  
               for(IM_Customer_Account__c ca  : custAccntLst)
                {
                    existingCustAcct.put(ca.IM_Opportunity__c,ca);
                    System.debug('+++99++++existingCustAcct.put(ca.IM_Opportunity__c,ca):'+existingCustAcct.put(ca.IM_Opportunity__c,ca));
                } 
            }
           catch(Exception e){//do nothing
           }
           
           List<IM_Country__c> countLst = [Select p.Iso31663Code__c,p.Region__c,p.Name,p.Id From IM_Country__c p where Region__c = 'Europe' or Region__c = 'Asia Pacific' or Region__c = 'Latin America'];
            
           //Load the euCountryCodes map. We only effectivly execute this for European Opportunities 
           Map<String, String> euCountryCodes = new Map<String,String>();
           for(IM_Country__c cc : countLst)
            {
                euCountryCodes.put(cc.Id, cc.Iso31663Code__c);
                System.debug('+++119++++euCountryCodes.put(cc.Id, cc.Iso31663Code__c):'+euCountryCodes.put(cc.Id, cc.Iso31663Code__c));
            }
           
           List<IM_Customer_Account__c> custAccLst = [select id, name, Billing_Country__c from IM_Customer_Account__c where name in :clientCodes and Billing_Country__c in :oppCountryCodes];
           
           //Load the Customer Account Map for this client code
           Map<String,IM_Customer_Account__c> dupClientAccounts = new Map<String,IM_Customer_Account__c>();
               
           for (IM_Customer_Account__c ca : custAccLst)
            {
                dupClientAccounts.put( ca.Billing_Country__c+ca.name, ca );
                System.debug('+++132++++dupClientAccounts.put( ca.Billing_Country__c+ca.name, ca ):'+dupClientAccounts.put( ca.Billing_Country__c+ca.name, ca ));
            }
            
            
            
           //Instantiate a list of CUstomer Accounts for insert
           List<IM_Customer_Account__c> newCustAcct = new List<IM_Customer_Account__c>();
           
           //Loop through the Trigger.new filtering down to Opportunities that need a Customer account.
           for(Integer i = 0; i < Trigger.new.size(); i++ ) {  
             //filter for existance of country relationship, New, Customer Account Number, and EU Record Type
             System.debug('++++143+++++euCountryCodes.get(Trigger.new[i].Billing_Country__c):'+euCountryCodes.get(Trigger.new[i].Billing_Country__c));
             System.debug('++++144+++++Trigger.new[i].Customer_Account_Number__c:'+Trigger.new[i].Customer_Account_Number__c);
             System.debug('++++145+++++Trigger.isInsert:'+Trigger.isInsert);
             System.debug('++++146+++++Trigger.isUpdate:'+Trigger.isUpdate);
             if(Trigger.isUpdate)
                System.debug('++++147+++++Trigger.old[i].Customer_Account_Number__c:'+Trigger.old[i].Customer_Account_Number__c);
             System.debug('++++148+++++recordTypeIDs.contains(Trigger.new[i].RecordTypeId):'+recordTypeIDs.contains(Trigger.new[i].RecordTypeId));

             if(euCountryCodes.get(Trigger.new[i].Billing_Country__c) != null 
                  && Trigger.new[i].Customer_Account_Number__c != null 
                  && (Trigger.isInsert || (Trigger.isUpdate 
                  && Trigger.old[i].Customer_Account_Number__c == null))
                  && recordTypeIDs.contains(Trigger.new[i].RecordTypeId) // New line
                  //&& Trigger.new[i].RecordTypeId == EUOppType.Id // Old line
                  // 2011-02-07 2 lines above: Part of the changes explained above.
                  )
                {
                    System.debug('++++157+++++existingCustAcct.get(trigger.new[i].id):'+existingCustAcct.get(trigger.new[i].id));
                    if (existingCustAcct.get(trigger.new[i].id) == null) 
                    {
                          // Only if a customer account does not exist for this oppty
                          // Check for duplicates – country code + Client Code
                          // If there is a duplicate, add an error to the 
                          // Opportunity.Client_Code__c field sourced from a label.
                          
                         System.debug('++++164+++++dupClientAccounts.get(Trigger.new[i].Billing_Country__c + trigger.new[i].Customer_Account_Number__c):'+dupClientAccounts.get(Trigger.new[i].Billing_Country__c + trigger.new[i].Customer_Account_Number__c));
                         if(dupClientAccounts.get(Trigger.new[i].Billing_Country__c + trigger.new[i].Customer_Account_Number__c)!=null){  
                            //Error if there is a duplicate client code (Cutsomer_Account_Number)
                            trigger.new[i].Customer_Account_Number__c.addError(Label.CustomerAccountCreateErr);
                            System.debug('++++168+++++trigger.new[i].Customer_Account_Number__c.addError(Label.CustomerAccountCreateErr):'+trigger.new[i].Customer_Account_Number__c.addError(Label.CustomerAccountCreateErr));
                         }
                         else {
                            //Instiantiate the Customer account and add it to the list
                            IM_Customer_Account__c ca = 
                             new IM_Customer_Account__c                                                                                                     
                                          (name = trigger.new[i].Customer_Account_Number__c
                                          ,IM_Account__c = trigger.new[i].AccountId
                                          ,IM_Opportunity__c = trigger.new[i].Id
                                          ,IM_Product_Class__c = opportunityProduct.get(trigger.new[i].Id)
                                          ,Source_System__c  = trigger.new[i].Source_System__c 
                                          ,IM_Status__c = 'New'
                                          ,Billing_Country__c = Trigger.new[i].Billing_Country__c
                                         );
                             System.debug('++++182++++ca:'+ca);
                             
                             newCustAcct.add(ca);
                            
                            custOpportunies.add(trigger.new[i].Id);
                            System.debug('++++187+++++custOpportunies.add(trigger.new[i].Id):'+custOpportunies.add(trigger.new[i].Id));
                            
                        }
                    }
                
                }
            }
            // Code added by Pratap
            // Insert Customer account for contract by taking CustId and contract id from opportunity
           System.debug('++++194+++++newCustAcct.size():'+newCustAcct.size());
           if(newCustAcct.size() > 0)
           {
              //Create the Customer Accounts
              insert newCustAcct;
              System.debug('++++198+++insert:'+newCustAcct);
              
              try
              {
                set<string> oppacc = new set<string>();
                  set<Id> oppId = new set<Id>();
                  set<Id> accId = new set<Id>();
                map<string,IM_Customer_Account__c> customerAccounts = new map<string,IM_Customer_Account__c>();
                List<Contract_Customer_Account__c> cas = new List<Contract_Customer_Account__c>();
                  for(Opportunity o : Trigger.New){
                      String s = o.id+''+o.AccountId;
                      oppacc.add(s);
                      oppId.add(o.Id);
                      accId.add(o.AccountId);
                  }
                list<IM_Customer_Account__c> caList = [select id, IM_Opportunity__c, IM_Account__c from IM_Customer_Account__c where IM_Opportunity__c IN: oppId AND IM_Account__c IN: accId ];
                
                  for(IM_Customer_Account__c i : caList){
                      String s = i.IM_Opportunity__c+''+i.IM_Account__c;
                      customerAccounts.put(s, i);
                  }
                  system.debug('Pratap customerAccounts:' + customerAccounts);
                  
                  for(Integer i = 0; i < Trigger.new.size(); i++ ) { 
                    //IM_Customer_Account__c icac = [SELECT id from IM_Customer_Account__c where IM_Opportunity__c =: Trigger.new[i].id and IM_Account__c =: trigger.new[i].AccountId limit 1];
                      String s = Trigger.new[i].id+''+trigger.new[i].AccountId;
                      IM_Customer_Account__c icac = customerAccounts.get(s);
                      Contract_Customer_Account__c Relatedca = new Contract_Customer_Account__c();                  
                      Relatedca.IME_Customer_Accounts_Id__c = icac.id;
                      Relatedca.IME_Contract_Id__c = Trigger.new[i].IME_Contract__c;
                    cas.add(Relatedca);
                }
                system.debug('Pratap cas: ' + cas);
                  
                  if(cas.size() > 0){
                    insert cas;
                  }
                  else
                  {
                      System.debug('There are no customer accounts for contract');
                  }
              }
              catch(Exception ex)
              {
                   System.debug('Error:' + ex.getMessage());
              }
            }
           
            system.debug('queries used in opportunitycustacct:'+Limits.getQueries()); 
        }
    }
}
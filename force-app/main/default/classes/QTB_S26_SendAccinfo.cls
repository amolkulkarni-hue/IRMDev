/*****************************************************************************************************
* @File Name:    QTB_S26_SendAccinfo 
* @Author:       Virtusa
* @Developer:    Suresh Uppala
* @Story Number: #471
* @Description:  Sending the Customer Account, opportunity contact roles Product and product bundle Information to the Fire Base Application 
-------------------------------------------------------------------------------------------------
* Version          Developer          Date               Description
*  1.0              Suresh U      	01/05/2021          Initial Creation                                                      
**************************************************************************************************/
global class QTB_S26_SendAccinfo {
    
    public static final String QTBs26AccInfo = QTB_S26_SendAccinfo.class.getName();
    public static boolean throwExplicitException = false;
    // When order is created it will triggers and we are passing the orderId to this method
    @future(callout=true)
    global static void Sierra26_SendAccData(String orderId){
        system.debug('The sendaccinfo class of order id:'+orderId);
        try{
            if(QTB_OrderTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            List<account> accList = new List<account>();
            List<OpportunityContactRole> opptyContactRole = new List<OpportunityContactRole>();
            List<orderitem> listordItem = new List<orderitem>();
            list<SBQQ__ProductOption__c> sbqqproductOption = new list<SBQQ__ProductOption__c>();
            set<Id> accountSet = new set<Id>();
            set<Id> prodOptions = new set<Id>();
            order orderDetails =new order();
            if(orderId!=null){
                orderDetails = [select id,AccountId,EffectiveDate,EndDate,SBQQ__Quote__r.SBQQ__Opportunity2__c  from Order where Id=: orderId];
            }
            system.debug('orderDetails>>>>>>'+orderDetails);
            Date OrdEndDate;
            if(orderDetails.EndDate!=null){
                OrdEndDate=orderDetails.EndDate;
            }else{
                OrdEndDate= orderDetails.EffectiveDate.addYears(1);
            }
            // Get all the accounts with respect to Order
            
            Map<id, Account> accMap = new Map<id, Account>([select id, Name from Account where id =: orderDetails.AccountId]);
            String customerAccountJSON;
            List<cutomerAccountWrapper> customerAccWrap = new List<cutomerAccountWrapper>();
            if(accMap !=null){
                //  Get all custmer account with respect to the account and iterate
                for(IM_Customer_Account__c accountwrap :[Select Id,Name,IM_Customer_Account_Name__c,IM_District_Branch_Id__c,IM_Account__c From IM_Customer_Account__c where IM_Account__c IN: accMap.keyset() Limit 1]){
                    cutomerAccountWrapper customerWrap = new cutomerAccountWrapper();
                    customerWrap.wmsId  = Label.QTB_S26_wmsId; 
                    customerWrap.wmsAccountId    = accountwrap.Name;
                    customerWrap.customerName   = accountwrap.IM_Customer_Account_Name__c;
                    customerWrap.districtId   = accountwrap.IM_District_Branch_Id__c;
                    customerWrap.region   = Label.QTB_S26_Region;
                    customerWrap.sfAccountId   = accountwrap.IM_Account__c;
                    customerAccWrap.add(customerWrap);
                } 
            }
            system.debug('customerAccWrap>>>>'+customerAccWrap);
            String JSONContactRole;
            list<opptyContactRoleWrapper> opptycontwrapList = new list<opptyContactRoleWrapper>();
            // Get all opportunitycontactrole with respect to opportunity
            for(OpportunityContactRole ocr :[SELECT Id, Opportunity.Name, Contact.Email,Contact.IM_Job_Level__c, Contact.Name,ContactId,Contact.Primary_NCSP_Contact__c, Role, IsPrimary,OpportunityId,QTB_S26_Okta_ID__c FROM OpportunityContactRole Where OpportunityId=:orderDetails.SBQQ__Quote__r.SBQQ__Opportunity2__c]){
                opptyContactRoleWrapper opptycontwrap = new opptyContactRoleWrapper();
                opptycontwrap.id = ocr.QTB_S26_Okta_ID__c;
                opptycontwrap.email =ocr.Contact.Email;
                opptycontwrap.isPrimary = ocr.IsPrimary;
                opptycontwrap.provider = Label.QTB_S26_Provider;
                opptycontwrapList.add(opptycontwrap);
                JSONContactRole = JSON.serialize(opptycontwrapList);
                
            }
            //  Get all the orderItem  with respect to order and checck the sierra26 product family
            listordItem = [select OrderId,product2id,product2.Name,product2.Family,product2.SBQQ__ConfigurationType__c,
                           product2.SBQQ__ConfigurationEvent__c from orderitem where product2.Family=:Label.QTB_S26_Family 
                           AND product2.SBQQ__ConfigurationType__c != null AND product2.SBQQ__ConfigurationEvent__c != null AND OrderId =:orderId];
            system.debug('listordItem >>>>>'+listordItem);
            Set<ID> SProd= new Set<ID>();
            ID prodInformation;
            //  Iterate all orderItem and get product2Id
            for(orderitem OI: listordItem){
                prodInformation = OI.product2id;
            }
            system.debug('prodInformation:'+prodInformation);
            
            String JSONString;
            List<BundleOptions> productBundleOption = new List<BundleOptions>();
            //Get all the productoptions with respect to product2
            sbqqproductOption = [select Id,Name,SBQQ__Number__c,SBQQ__Quantity__c,SBQQ__QuantityEditable__c,SBQQ__Selected__c,SBQQ__Required__c,SBQQ__MinQuantity__c,SBQQ__MaxQuantity__c,SBQQ__DiscountSchedule__c,SBQQ__ConfiguredSKU__c,
                                 SBQQ__OptionalSKU__c,SBQQ__Feature__c,SBQQ__Type__c,SBQQ__Bundled__c,SBQQ__UnitPrice__c,SBQQ__Discount__c,SBQQ__DiscountAmount__c,
                                 QTB_S26_IncQuantity__c from SBQQ__ProductOption__c where SBQQ__ConfiguredSKU__c =:prodInformation];
            system.debug('sbqqproductOption>>>>>'+sbqqproductOption);
            // Iterate the productoptions
            for(SBQQ__ProductOption__c options :sbqqproductOption){
                BundleOptions probundWrap = new BundleOptions();
                if(options.SBQQ__Quantity__c!=null && options.SBQQ__Quantity__c!=0){
                    probundWrap.optionTypeId =options.Id;
                    probundWrap.optionSubTypeId =options.Id;			       
                    probundWrap.allowedCredits = options.SBQQ__Quantity__c;
                    productBundleOption.add(probundWrap);			
                }	
                JSONString = JSON.serialize(productBundleOption);
            }
            system.debug('productBundleOption>>>>'+productBundleOption);
            if(customerAccWrap.size()>0)
                // Passing the paramaters to accInfo method
                accInfo(orderDetails,accList,customerAccWrap,JSONContactRole,prodInformation,JSONString,OrdEndDate);
            
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                QTBs26AccInfo
            );
            throw e;
        }
    }
    
    // Http Call out method
    public static HttpResponse accInfo(Order orderDetails,List<Account> accList,List<cutomerAccountWrapper> customerAccWrap,String JSONContactRole, String prodInformation, String JSONString, Date OrdEndDate){	
        try{
            if(QTB_OrderTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            // Get all custommetadata records with respect to developername ='RS256'
            QTB_S26_RS256_JWT__mdt rs=[Select id,DeveloperName,QTB_S26_Alg__c,QTB_S26_Aud__c,QTB_S26_Iss__c,QTB_S26_Type__c,QTB_S26_Sub__c,
                                       QTB_S26_Private_Key__c,QTB_S26_Kid__c From QTB_S26_RS256_JWT__mdt Where DeveloperName=: Label.QTB_S26_JWTAlgorithm];
            String token;
            //calling the QTB_S26_JWT class t generate JWT Token
            QTB_S26_JWT.generateJWT();
            System.debug('QTB_S26_JWT.generateJWT :: '+QTB_S26_JWT.generateJWT());
            token=QTB_S26_JWT.generateJWT();
            Http http=new Http();
            HttpRequest req=new HttpRequest();
            req.setEndpoint(rs.QTB_S26_Aud__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');  
            req.setHeader('Authorization','Bearer '+token); 
            req.setBody('{"account":{"wmsId":"SKP","wmsAccountId":"'+customerAccWrap[0].wmsAccountId+'","customerName":"'+customerAccWrap[0].customerName+'","districtId":"'+customerAccWrap[0].districtId+'","region":"AMER","sfAccountId":"'+customerAccWrap[0].sfAccountId+'","users":' + JSONContactRole +',"addresses":[{"addressType":"BILL","addressCode":"BILL"},{"addressType":"SHIP","addressCode":"SHIP"}],"bundle":{"purchaseOrderId":"'+orderDetails.Id+'","bundleTypeId":"'+prodInformation+'","startDate":"'+orderDetails.EffectiveDate+'","expiryDate":"'+OrdEndDate+'","bundleOptions":' + JSONString +'}}}');
            system.debug('req:'+req);
            HttpResponse res=http.send(req);
            system.debug('res:'+res); 
            
            if(res.getStatusCode() == 200){
                system.debug('res:'+res.getBody());
            } else{  
                system.debug('Error :'+res.getStatusCode());
                system.debug('Error res.getBody :'+res.getBody());            
            }
            return res;     
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                QTBs26AccInfo
            );
            throw e;
        }
    }
    
    // Customer account Information
    public class cutomerAccountWrapper{
        public string sfAccountId {get; set;}
        public string wmsId {get; set;}
        public String wmsAccountId {get; set;}
        public String customerName {get; set;}
        public String districtId {get; set;}
        public String region {get; set;}
        
    } 
    
    // Opportunity Contact Role Information
    public class opptyContactRoleWrapper{
        public string id {get; set;}
        public string email {get; set;}
        public String provider {get; set;}
        public Boolean isPrimary {get; set;}
    }
    
    //  Product Option Information
    public class BundleOptions{
        public string optionTypeId {get; set;}
        public string optionSubTypeId {get; set;}
        public Decimal allowedCredits {get; set;}
    }
}
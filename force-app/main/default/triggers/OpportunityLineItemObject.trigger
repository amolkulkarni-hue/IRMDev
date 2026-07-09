/*Developer Name: Madhu Paladugu
Company       : TheCloudFountain Inc.
Desrciption   :  This is the combined trigger of both Maintainforecat and delbundle(The code of deldundle trigger has been modified to reduce count of soql and accept bulk transctions).
Date          : 12/6/12
case number   : 00924109   */
trigger OpportunityLineItemObject on OpportunityLineItem (after insert,before delete, before update,after delete, before insert) {
    //[Reyna Illanes - 08/12/14] Added before insert event to the trigger, in order to match condition in line 54
    Integer l=0, k=0, temp=0;
    List<OpportunityLineItem> os = new List<OpportunityLineItem>();
    /*Variables for maintainOpportunityForecastObject trigger*/
    public string maintainOpportunityForecastObject=null;
    Boolean runmaintainOpportunityForecastObject=false;
    /* Variables for OppBundleDelete trigger*/
    public String OppBundleDelete=null;
    public string runSyncOppLineItemData='false';
    Boolean runOppBundleDelete=false;
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    system.debug('+++++++++customsettings ++++++++++'+customsettings );
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c =='OpportunityLineItem') {
            if(cs.Trigger__c == 'maintainOpportunityForecastObject') {
                maintainOpportunityForecastObject=cs.Value__c;   
            }
            if(cs.Trigger__c == 'OppBundleDelete') {
                OppBundleDelete=cs.Value__c;   
            }
            if(cs.Trigger__c == 'SyncOppLineItemData') {
                runSyncOppLineItemData=cs.Value__c;   
            }
        }
    }
    
    if(Trigger.IsBefore){
        if(Trigger.isdelete || Trigger.IsUpdate){
            if(maintainOpportunityForecastObject=='True'){
                runmaintainOpportunityForecastObject=true;
                
            }
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isDelete){
            if(OppBundleDelete=='True'){
                runOppBundleDelete=true;
            }
        }
        if(Trigger.isInsert){
            if(maintainOpportunityForecastObject=='True'){
                runmaintainOpportunityForecastObject=true;
            }  
        }
    }
    /************* SyncOppLineItemData start***********/
    if(runSyncOppLineItemData=='True' && Trigger.isBefore && Trigger.isInsert){
        system.debug('+++++++++++++++Executing SyncLineItemData Trigger before insert++++++++++++');
        
        List<LineItemsSync__c> CustomSettingData=LineItemsSync__c.getAll().Values();
        
        If(!CustomSettingData.isEmpty()){
            
            Map<String,String> QLI_TO_OPPPROD_FIELDS=new Map<String,String>();
            
            for(LineItemsSync__c Temp1 : CustomSettingData){
                
                if(Temp1.Opportunity_Product_API_Name__c!=null)
                    QLI_TO_OPPPROD_FIELDS.put(Temp1.Quote_Line_Item_API_Name__c,Temp1.Opportunity_Product_API_Name__c);
                
            }
            
            system.debug('++++++++++quote line - oppline fileds map+++++'+QLI_TO_OPPPROD_FIELDS);
            
            Set<id> Oppids=new Set<id>();
            Set<id> PBEids=new Set<id>(); 
            
            for(OpportunityLineItem opl:Trigger.new){
                Oppids.add(opl.opportunityId);
                PBEids.add(opl.pricebookentryid);
            }
            
            Map<id,opportunity> ValidateOpportunityLIneItem=new Map<Id,Opportunity>([select id,SyncedQuoteId from opportunity where id IN:Oppids
                                                                                     and RecordType.Name='NA Renewal' and SyncedQuoteId !=null]);
            
            system.debug('+++++++++Validate OpportunityLIneItem+++++++'+ValidateOpportunityLIneItem);
            
            if(!QLI_TO_OPPPROD_FIELDS.keySet().isEmpty() && !ValidateOpportunityLIneItem.isEmpty()){
                
                String QuoteLineItemFields='';
                
                //getting quote fileds from custom settings
                for(String s:QLI_TO_OPPPROD_FIELDS.keySet()){
                    if(QuoteLineItemFields!=''){
                        QuoteLineItemFields+=',';
                    }
                    QuoteLineItemFields+= s;
                }
                
                //getting opportunity ids for query
                String oppIdsInQuery='';
                
                for(id oppid:ValidateOpportunityLIneItem.keySet()){
                    
                    if(oppIdsInQuery!=''){
                        oppIdsInQuery +=',';
                    }
                    oppIdsInQuery +='\''+oppid+'\'';
                    
                }
                
                
                String priceEntryIds='';
                
                for(String s : PBEids){
                    if(priceEntryIds!=''){
                        priceEntryIds+=',';
                    }
                    priceEntryIds+='\''+s+'\'';
                }
                
                String QuoteLineItemQuery=' select id,Quote.opportunityId,priceBookEntryid,'+QuoteLineItemFields+' from QuoteLineItem where Quote.opportunityId IN ('+oppIdsInQuery+ ') and pricebookentryId IN ('+ priceEntryIds+')';
                
                system.debug('++++++++Quote item query++++++++'+QuoteLineItemQuery);
                
                List<QuoteLineItem> QuoteLList=Database.query(QuoteLineItemQuery);
                
                Map<id,List<QuoteLineItem>> OppMap=new Map<id,List<QuoteLineItem>>();
                
                for(QuoteLineItem ql:QuoteLList) {
                    
                    List<QuoteLineItem> temp2=OppMap.get(ql.quote.opportunityId);
                    if(temp2==null){
                        temp2=new List<QuoteLineItem >();
                    }
                    temp2.add(ql);
                    OppMap.put(ql.quote.opportunityid,temp2);
                }  
                system.debug('+++++++++++opp map before do sync++++++++'+OppMap);
                
                if(!OppMap.isEmpty()){
                    
                    for(OpportunityLineItem opl : Trigger.new ){
                        
                        if(ValidateOpportunityLIneItem.containsKey(opl.opportunityId)){ 
                            system.debug('++++++++++++inside the validate loop+++++');  
                            
                            List<QuoteLineItem> tempQL=OppMap.get(opl.opportunityId);
                            
                            if(tempQL!=null){
                                
                                for(QuoteLineItem qli : tempQL ){
                                    
                                    if(qli.priceBookEntryId==opl.priceBookEntryId ){
                                        
                                        for(String s:QLI_TO_OPPPROD_FIELDS.keySet()){
                                            
                                            opl.put(QLI_TO_OPPPROD_FIELDS.get(s),qli.get(s));
                                        }
                                        break;
                                    }
                                }
                            }
                        } 
                    }
                }
                
                system.debug('+++++++++++opp line item list before insert+++++++'+trigger.new);
            }      
        }
    }
    
    /************** End **************************/
    /*** // For Rate x Quantity scheduling disable, comment block below this line ***/
    /*if(runmaintainOpportunityForecastObject){
System.debug('++++++++executing the maintainOpportunityForecastObject trigger+++++');
Set<Id> oppLineItemIds = new Set<Id>();
List<IM_Opportunity_Forecast__c> OppFcstListforDelete = new List<IM_Opportunity_Forecast__c>();
Map<Id, List<OpportunityLineItemSchedule>> oppProd_ScheduleMap = new Map<Id, List<OpportunityLineItemSchedule>>();

if(Trigger.isAfter && Trigger.isInsert){
System.debug('-------21--------After Insert Event------------');
oppLineItemIds.addAll(Trigger.newMap.keySet());       
System.debug('------23--------Total Opp Prod(INSERTED) Ids:  '+oppLineItemIds.size());
}

if(Trigger.isBefore && Trigger.isUpdate){
for(Integer i=0; i<Trigger.new.size(); i++){
System.debug('----28-------Trigger.new[i].Update_New_Revenue_Forecast__c:'+Trigger.new[i].Update_New_Revenue_Forecast__c);
if(Trigger.new[i].Update_New_Revenue_Forecast__c){//Fileritng records for update when Update_New_Revenue_Forecast__c is checked
Trigger.new[i].Update_New_Revenue_Forecast__c = false;
System.debug('----31-------Trigger.new[i].Update_New_Revenue_Forecast__c:'+Trigger.new[i].Update_New_Revenue_Forecast__c);
oppLineItemIds.add(Trigger.new[i].Id);
System.debug('------before update event--------Total Opp Prod(INSERTED) Ids:  '+oppLineItemIds);
}
}
System.debug('-----35------oppLineItemIds.size():'+oppLineItemIds.size() +'\t oppLineItemIds:'+oppLineItemIds);
if(oppLineItemIds.size()>0){

try{
//Going to delete Opportunity forecast reocrds in batches as no can be more than 1000
for(List<IM_Opportunity_Forecast__c> OppFcst: [Select Id 
from IM_Opportunity_Forecast__c 
where OpportunityLineItemId__c in: oppLineItemIds]){
System.debug('----42-------OppFcst:'+OppFcst);
System.debug('----43-------OppFcstListforDelete.size():'+OppFcstListforDelete.size());
System.debug('----44---OppFcst.size():'+OppFcst.size());
if((OppFcstListforDelete.size()+OppFcst.size())<=1000){//making batches of 1000 and then deleting
OppFcstListforDelete.addAll(OppFcst);
}  
else{
delete OppFcstListforDelete;
OppFcstListforDelete.clear();
}                  
}
System.debug('-----53------OppFcstListforDelete.size():'+OppFcstListforDelete.size());
if(OppFcstListforDelete.size()>0){
System.debug('--------------55--------OppFcstListforDelete:'+OppFcstListforDelete);
delete OppFcstListforDelete;
}
}
catch(DMLException dmlex){
Trigger.new[0].addError('Failed to delete existing Opportunity Forecast records:  '+dmlEx.getDmlId(0)+' Error: '+dmlex.getMessage());
}
catch(Exception ex){
Trigger.new[0].addError('Too many Opportunity Forecast records found 10001. Please reduce the batch size:'+ex.getMessage());
}

}
System.debug('------66-------Total Opp Prod(UPDATED and filtered) Ids:  '+oppLineItemIds.size() +'\t oppLineItemIds:'+oppLineItemIds);

}

if(Trigger.isBefore && Trigger.isDelete){
System.debug('-------71--------Before Delete Event------------');
try{
//Going to delete Opportunity forecast reocrds in batches as no can be more than 1000
for(List<IM_Opportunity_Forecast__c> OppFcst: [Select Id 
from IM_Opportunity_Forecast__c 
where OpportunityLineItemId__c in: Trigger.oldMap.keySet() ]){
System.debug('----77-------OppFcstListforDelete.size():'+OppFcstListforDelete.size());
System.debug('---78----OppFcst.size():'+OppFcst.size());
if((OppFcstListforDelete.size()+OppFcst.size())<=1000){//making batches of 1000 and then deleting
OppFcstListforDelete.addAll(OppFcst);
}  
else{
delete OppFcstListforDelete;
OppFcstListforDelete.clear();
}                  
}
System.debug('-----87------OppFcstListforDelete.size():'+OppFcstListforDelete.size());
if(OppFcstListforDelete.size()>0){
System.debug('----------OppFcstListforDelete:'+OppFcstListforDelete);
delete OppFcstListforDelete;
}
}
catch(DMLException dmlex){
Trigger.new[0].addError('Failed to delete existing Opportunity Forecast records:  '+dmlEx.getDmlId(0)+' Error: '+dmlex.getMessage());
}
catch(Exception ex){
Trigger.new[0].addError('Too many Opportunity Forecast records found 10001. Please reduce the batch size:'+ex.getMessage());
}
}
System.debug('-----99------oppLineItemIds.size():'+oppLineItemIds.size() +'\t oppLineItemIds:'+oppLineItemIds);
if(oppLineItemIds.size()>0){
System.debug('-----101------Starting Process for Inserting Opp FCST Reocrds------------');

try{
System.debug('-------queries used before method 106: ' + Limits.getQueries());
System.debug('-----115------oppLineItemIds:'+oppLineItemIds);
for(OpportunityLineItemSchedule olis: [Select Id, OpportunityLineItem.PricebookEntry.Product2.Name,OpportunityLineItem.PricebookEntry.Product2Id,
OpportunityLineItemId, Revenue, ScheduleDate, OpportunityLineItem.OpportunityId,OpportunityLineItem.Opportunity.Owner.Sales_Division__c 
from OpportunityLineItemSchedule
where OpportunityLIneItemId in:oppLineItemIds and Type = 'Revenue' 
//and OpportunityLineItem.Opportunity.Owner.Sales_Division__c='North America'
order by ScheduleDate Asc]){
System.debug('------109-------olis:'+olis +'\t olis.Id:'+olis.Id +'\t olis.OpportunityLineItem.PricebookEntry.Product2.Name:'+olis.OpportunityLineItem.PricebookEntry.Product2.Name);
//Creating Map of Opporunity Product and corresponding Opportunity Schedules
System.debug('----111-----oppProd_ScheduleMap.containsKey(olis.OpportunityLineItemId):'+oppProd_ScheduleMap.containsKey(olis.OpportunityLineItemId));                          
if(oppProd_ScheduleMap.containsKey(olis.OpportunityLineItemId)){
oppProd_ScheduleMap.get(olis.OpportunityLineItemId).add(olis);
System.debug('---114----oppProd_ScheduleMap:'+oppProd_ScheduleMap);
}
else{
oppProd_ScheduleMap.put(olis.OpportunityLineItemId, new List<OpportunityLineItemSchedule>());
System.debug('------118-------oppProd_ScheduleMap:' +oppProd_ScheduleMap);
oppProd_ScheduleMap.get(olis.OpportunityLineItemId).add(olis);
System.debug('------120-------ooppProd_ScheduleMap:' +oppProd_ScheduleMap);
}
}
System.debug('-------queries has been executed by end of method: ' + Limits.getQueries());
}
catch(Exception e){
Trigger.new[0].addError('Too many Opportunity Schedule records found 10001. Please reduce the batch size:'+e.getMessage());
}

try{
List<OpportunityLineItemSchedule> oppProdScheduleList = new List<OpportunityLineItemSchedule>();
Map<Id, List<OpportunityLineItemSchedule>> tempoppScheduleMap = new Map<Id, List<OpportunityLineItemSchedule>>();
System.debug('-----131----oppProd_ScheduleMap.size():'+oppProd_ScheduleMap.size());
if(oppProd_ScheduleMap.size()>0){
for(Id oppProdId: oppProd_ScheduleMap.keySet()){

//Making a map of max size size 1000 from Opportunity Product and Opportunity Schedule map for generating Opportunity Forecast records          
System.debug('------136-----oppProdScheduleList.size():'+oppProdScheduleList.size());
System.debug('----137---oppProd_ScheduleMap.get(oppProdId).size():'+oppProd_ScheduleMap.get(oppProdId).size());
if((oppProdScheduleList.size()+oppProd_ScheduleMap.get(oppProdId).size())<=1000){
oppProdScheduleList.addAll(oppProd_ScheduleMap.get(oppProdId));
tempoppScheduleMap.put(oppProdId, new List<OpportunityLineItemSchedule>());
tempoppScheduleMap.get(oppProdId).addAll(oppProd_ScheduleMap.get(oppProdId));
System.debug('--------tempoppScheduleMap:'+tempoppScheduleMap);
}
//Sending subset Map for processing to generate Opportunity Forecast records
System.debug('------144-----oppProdScheduleList.size():'+oppProdScheduleList.size());
System.debug('------145----oppProd_ScheduleMap.get(oppProdId).size():'+oppProd_ScheduleMap.get(oppProdId).size());
if((oppProdScheduleList.size()+oppProd_ScheduleMap.get(oppProdId).size())>1000){
//try{
populateOpportunityForecastHelper(tempoppScheduleMap);
System.debug('----***calling forecast helper method****-----');
//}catch(Exception e){
//Trigger.new[0].addError('Too many Opportunity Schedule records found 10001. Please reduce the batch size:'+e.getMessage());
//}
oppProdScheduleList.clear();
tempoppScheduleMap.clear();
}
}
}
System.debug('----153-------tempoppScheduleMap.size():'+tempoppScheduleMap.size());
if(tempoppScheduleMap.size()>0){
System.debug('--------156--------tempoppScheduleMap:'+tempoppScheduleMap);
try{
populateOpportunityForecastHelper(tempoppScheduleMap);
System.debug('----calling forecast helper method-----');
}catch(Exception e){
Trigger.new[0].addError('Too many Opportunity Schedule records found 10001. Please reduce the batch size:'+e.getMessage());
}
}
}
catch(Exception ex){
Trigger.new[0].addError('Failed to process: '+ex.getMessage()+':'+ex.getCause());
}
}
}*/
    /*** // For Rate x Quantity scheduling disable, comment block above this line ***/
    if(runOppBundleDelete ){
        system.debug('+++++++++++executing the OppBundleDelete trigger++'); 
        Set<Id> oppIds=new Set<Id>();
        Set<Id> oppLineIds=new Set<Id>();
        set<Id> PribookIds=new Set<Id>();
        Boolean multiplebundle=false;
        integer rmProdCount=0;    
        set<String> profilesOfWizard=new Set<String>();
        Map<Id,Id> opportunityMap=new MaP<Id,Id>();
        List<opportunity> vendedOpp = new List<opportunity>();
        List<Opportunity_Product_Wizard_Settings__c> wizardsettings = Opportunity_Product_Wizard_Settings__c.getall().values();
        for(Opportunity_Product_Wizard_Settings__c opwiz:wizardsettings){
            profilesOfWizard.add(opwiz.Profile_Name__c);
        }
        
        Map<Id,String> mapOfuserProfiles=new Map<Id,String>();
        for(OpportunityLineItem ol:Trigger.old){
            oppLineIds.add(ol.Id);
            PribookIds.add(ol.PricebookEntryId);
            oppIds.add(ol.OpportunityId);
            opportunityMap.put(ol.Id,ol.OpportunityId);
            
        }
        Map<Id,Opportunity> oppMap=new Map<Id,Opportunity>();
        
        List<Opportunity> opp=[select id,ownerId,owner.profile.Name,IME_Vended_Unvended__c,/*#16915Vended__c,Unvended__c,*/
                               (select Id,PricebookEntryId,Product_Class__c,Product_Line__c from OpportunityLineItems) from Opportunity where id IN:oppIds];
        
        system.debug('+++++++++price book ids are+++++'+PribookIds);
        system.debug('+++++++++++++++opp++++++++'+opp);
        for(Opportunity op:opp){
            system.debug('++++++++opp line items++++++++'+op.OpportunityLineItems);
            rmProdCount = 0;
            for(OpportunityLineItem olinsideop:op.OpportunityLineItems){
                system.debug('++++++ids++++++'+olinsideop.PricebookEntryId);
                PribookIds.add(olinsideop.PricebookEntryId); 
                if((olinsideop.Product_Class__c =='Records Management') && (olinsideop.Product_Line__c=='storage')){
                    rmProdCount = rmProdCount +1;
                }            
            }
            // if there are no records management and storage products then update vended fields to null
            if(rmProdCount==0){
                op.IME_Vended_Unvended__c=null;
                /*#16915 op.Vended__c=null;
                op.Unvended__c=null;*/
                vendedOpp.add(op);      
            }
            
            oppMap.put(op.Id,op);
            mapOfuserProfiles.put(op.Id,op.Owner.profile.Name);
        }
        
        update vendedOpp;
        system.debug('++++++++++++++Profile Map was+++++'+mapOfuserProfiles);
        List<PricebookEntry> pribookdetails=[select Product2Id from PricebookEntry where Id IN:PribookIds];
        Map<Id,Id> pribokMap=new Map<Id,Id>();
        set<Id> prodIds=new set<Id>();
        for(PricebookEntry pe:pribookdetails){
            prodIds.add(pe.Product2Id);
            pribokMap.put(pe.Id,pe.Product2Id);
        }
        
        system.debug('++++++++++map of price book entry is+++'+pribokMap);
        List<Product2> prodlist=[select Id,(select Id, Name from Product_Bundles__r) from Product2 where Id IN:prodIds]; 
        MaP<Id,Product2> productMap=new MaP<Id,Product2>();
        for(Product2 p:prodlist){
            productMap.put(p.Id,p);
        }
        
        List<Opportunity_Answers__c> oppanswers = [SELECT Id from Opportunity_Answers__c where Opportunity_LineItem_Id__c IN:oppLineIds];      
        List<Opportunity> thatNeddsPricebokToNull=new List<Opportunity>();
        List<Opportunity> ThatNeedstoUpdate=new List<Opportunity>();
        Map<Id,Opportunity> mapofpriceboknull=new Map<Id,Opportunity>();
        for(OpportunityLineItem opline:trigger.old){
            
            if(profilesOfWizard.contains(mapOfuserProfiles.get(opportunityMap.get(opline.Id)))){
                
                if((oppMap.get(opline.OpportunityId).OpportunityLineItems).size()==0){
                    //DELETE REMOVING THE PRICE BOOK ID TO REMOVE THE SYNC ISSUE ON QUOTE
                    Opportunity oppnew1 = new Opportunity(Id=opline.OpportunityId/*Pricebook2Id=null,*/
                                                         /* #16915 Bundle__c=null,Bundle_Description__c=null*/);
                    if(!mapofpriceboknull.containsKey(opline.OpportunityId)){
                        mapofpriceboknull.put(opline.OpportunityId,oppnew1);
                    }   
                }
                
                /*CASE      : 01363925
DESCRIPTION : ADDED CONDITON TO REMOVE NULL POINTER EXCEPTIONS
*/
                if(null!=productMap.get(pribokMap.get(opline.PricebookEntryId)) && (productMap.get(pribokMap.get(opline.PricebookEntryId)).Product_Bundles__r).size()>0){
                    
                    for(OpportunityLineItem o:oppMap.get(opline.OpportunityId).OpportunityLineItems){
                        if(o.Id!=opline.Id){
                            system.debug('++++++++map of price book id++++'+o.PricebookEntryId);
                            system.debug('++++++++map of price book++++'+pribokMap.get(o.PricebookEntryId));
                            if(null!=productMap.get(pribokMap.get(o.PricebookEntryId)) &&(productMap.get(pribokMap.get(o.PricebookEntryId)).Product_Bundles__r).size()>0){
                                multiplebundle=true;
                            }
                        }
                    } 
                    if(multiplebundle==false){
                        system.debug('++++++++inside second  if++++');
                        Opportunity oppnew = new Opportunity(Id=opline.OpportunityId/* #16915 Bundle__c=null,Bundle_Description__c=null*/); 
                        if(!mapofpriceboknull.containsKey(opline.OpportunityId)){
                            mapofpriceboknull.put(opline.OpportunityId,oppnew);
                        }  
                    }
                }
            }
        }
        if(!mapofpriceboknull.isEmpty())
        {
            ThatNeedstoUpdate.addAll(mapofpriceboknull.values());
        } 
        try{
            update ThatNeedstoUpdate;
        }
        catch(DmlException exp){
            ThatNeedstoUpdate[0].addError(exp.getMessage()); 
        }
        delete oppanswers;
        
    }
    /*helper method: generates Opportunity Foreacst records.
@param oppProdSchedules: Map of Opportunity Porduct and corresponding schedules.
*/ 
    /*** // For Rate x Quantity scheduling disable, comment block below this line ***/
    /*private void populateOpportunityForecastHelper(Map<Id, List<OpportunityLineItemSchedule>> oppProdSchedules){
System.debug('--------167------In Opp Fcst Helper Method-----------'+oppProdSchedules.size());

List<IM_Opportunity_Forecast__c> tempOppForecastList = new List<IM_Opportunity_Forecast__c>();
List<OpportunityLineItemSchedule> oppProdScheduleList = new List<OpportunityLineItemSchedule>();
map<Id, String> mOppOwnerSalesDiv = new map<Id, String> ();
String sOwnerSalesDiv ;
System.debug('------171-------oppProdSchedules.keySet():'+oppProdSchedules.keySet());
for(Id oppProdId : oppProdSchedules.keySet()){
oppProdScheduleList.addAll(oppProdSchedules.get(oppProdId));
System.debug('---173-----oppProdScheduleList:'+oppProdScheduleList);
System.debug('-------174-----Size for generation-----------'+oppProdScheduleList.size());
for(Integer i=0; i<oppProdScheduleList.size(); i++){

OpportunityLineItemSchedule oppProdScheduleCur = oppProdScheduleList[i];
System.debug('----180----oppProdScheduleCur:'+oppProdScheduleCur);
OpportunityLineItemSchedule oppProdSchedulePrev = (i>0 && oppProdScheduleList[i-1].OpportunityLineItemId == oppProdScheduleList[i].OpportunityLineItemId) ? oppProdScheduleList[i-1] : null;
Decimal netNewRevenueThisPeriod = 0;

if(oppProdSchedulePrev!=null){
netNewRevenueThisPeriod = oppProdScheduleCur.Revenue - oppProdSchedulePrev.Revenue;
System.debug('----184-----netNewRevenueThisPeriod:'+netNewRevenueThisPeriod);
} 
else{
System.debug('----187-------oppProdScheduleCur.Revenue:'+oppProdScheduleCur.Revenue);
netNewRevenueThisPeriod = oppProdScheduleCur.Revenue;
mOppOwnerSalesDiv.put(oppProdScheduleCur.OpportunityLineItemId, oppProdScheduleCur.OpportunityLineItem.Opportunity.Owner.Sales_Division__c);
System.debug('----188-----netNewRevenueThisPeriod:'+netNewRevenueThisPeriod);
}
//Generating Opportunity forecast record only if difference between revenue of current schedule and previous schedule is not equal to 0
System.debug('------191---netNewRevenueThisPeriod:'+netNewRevenueThisPeriod);
if(netNewRevenueThisPeriod<>0){
IM_Opportunity_Forecast__c oppFcst = new IM_Opportunity_Forecast__c();
oppFcst.OpportunityLIneItemScheduleId__c = oppProdScheduleCur.Id;
System.debug('-----192---:'+oppFcst.OpportunityLIneItemScheduleId__c);          
oppFcst.Name = oppProdScheduleCur.OpportunityLineItem.PricebookEntry.Product2.Name + ' - ' + String.valueOf(oppProdScheduleCur.ScheduleDate);
System.debug('-----194---:'+oppFcst.Name);  
oppFcst.Opportunity__c = oppProdScheduleCur.OpportunityLineItem.OpportunityId;
System.debug('------196--:'+oppFcst.Opportunity__c);  
oppFcst.Product__c = oppProdScheduleCur.OpportunityLineItem.PricebookEntry.Product2Id;
System.debug('------198--:'+oppFcst.OpportunityLIneItemScheduleId__c);  
oppFcst.OpportunityLineItemId__c = oppProdScheduleCur.OpportunityLineItemId;
System.debug('------200--:'+oppFcst.OpportunityLineItemId__c);  
oppFcst.Revenue__c = netNewRevenueThisPeriod;
System.debug('------202--:'+oppFcst.Revenue__c);  
oppFcst.Schedule_Date__c = oppProdScheduleCur.ScheduleDate;
System.debug('------204--:'+oppFcst.Schedule_Date__c);  
tempOppForecastList.add(oppFcst);
System.debug('-----206--:'+tempOppForecastList);
}
}
oppProdScheduleList.clear();
}
System.debug('--------211----tempOppForecastList:'+tempOppForecastList);
insert tempOppForecastList;
if(Trigger.isBefore && Trigger.isUpdate){
System.debug('----214------Trigger.new:'+Trigger.new);
for(OpportunityLineItem olitem: Trigger.new){
System.debug('olitem.Opportunity.Owner.Sales_Division__c: '+ olitem.Opportunity.Owner.Sales_Division__c);
System.debug('olitem.Opportunity.Owner: '+ olitem.Opportunity.Owner);
if(olitem.Opportunity.Owner <> null){
sOwnerSalesDiv = olitem.Opportunity.Owner.Sales_Division__c;
System.debug('--------******sOwnerSalesDiv:'+sOwnerSalesDiv);
}else{
sOwnerSalesDiv = mOppOwnerSalesDiv.get(olitem.Id);
System.debug('--------sOwnerSalesDiv:'+sOwnerSalesDiv);
}
System.debug('--------sOwnerSalesDiv: '+ sOwnerSalesDiv);
if(sOwnerSalesDiv=='North America'){
l=0;
k=0;
System.debug('---219-----tempOppForecastList:'+tempOppForecastList);
for(IM_Opportunity_Forecast__c im: tempOppForecastList)
{
system.debug('-----222---comparing FCT ine Item External Id with olitem ID for First Forecast Amount & Date:'+im.OpportunityLineItemId__c+'---'+olitem.Id);
if(im.OpportunityLineItemId__c==olitem.Id && l==0)
{
olitem.First_Forecast_Amount__c=im.Revenue__c;
System.debug('--------226-----olitem.First_Forecast_Amount__c:'+olitem.First_Forecast_Amount__c);
olitem.First_Forecast_Date__c=im.Schedule_Date__c;
System.debug('--------228-----olitem.First_Forecast_Date__c:'+olitem.First_Forecast_Date__c);
l++;                        
}
system.debug('-----231---comparing FCT ine Item External Id with olitem ID for Current Month Forecast Amount & Date:'+im.OpportunityLineItemId__c+'----'+olitem.Id);
if(im.OpportunityLineItemId__c==olitem.Id && k==0)
{
if((im.Schedule_Date__c.month()==system.today().month()) && (im.Schedule_Date__c.year()==system.today().year()))
{
olitem.Current_Month_Forecast_Date__c=im.Schedule_Date__c;
System.debug('-------238------olitem.Current_Month_Forecast_Date__c:'+olitem.Current_Month_Forecast_Date__c);
olitem.Current_Month_Forecast_Amount__c=im.Revenue__c;
System.debug('-------239-----olitem.Current_Month_Forecast_Amount__c:'+olitem.Current_Month_Forecast_Amount__c);
k++;
}
else
{
olitem.Current_Month_Forecast_Date__c=null;
System.debug('-------245------olitem.Current_Month_Forecast_Date__c:'+olitem.Current_Month_Forecast_Date__c);
olitem.Current_Month_Forecast_Amount__c=null;
System.debug('--------247-----olitem.Current_Month_Forecast_Amount__c:'+olitem.Current_Month_Forecast_Amount__c);
}       
}

}

os.add(olitem);
system.debug('--------254-----opplineitemlist:'+os);          
}
}

}    
}
*/
    /*** // For Rate x Quantity scheduling disable, comment block above this line ***/
}
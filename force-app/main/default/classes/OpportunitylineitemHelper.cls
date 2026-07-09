/*
@Class : OpportunitylineitemHelper  
@Author : Gouthami Redlapalli
@BuiltDate :06.05.2020
@Description : OpportunitylineitemHelper is a helper class for all business logic related to OpportunitylineitemHandler class
@Company : BahwanCyberTek
*/
public class OpportunitylineitemHelper {
    
    /************* OppBundleDelete start***********/
    public static void OppBundleDelete(Map<Id, Sobject> OpplineDeleteMap)
    {
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
        List<OpportunityLineItem> oppBeforeUpdateOldList = OpplineDeleteMap.values();
        
        for(OpportunityLineItem ol: oppBeforeUpdateOldList)
        {
            oppLineIds.add(ol.Id);
            PribookIds.add(ol.PricebookEntryId);
            oppIds.add(ol.OpportunityId);
            opportunityMap.put(ol.Id,ol.OpportunityId);            
        }
        
        Map<Id,Opportunity> oppMap=new Map<Id,Opportunity>();
        
        List<Opportunity> opp=[select id,ownerId,owner.profile.Name,IME_Vended_Unvended__c,/* 16915 Vended__c,Unvended__c,*/
                               (select Id,PricebookEntryId,Product_Class__c,Product_Line__c from OpportunityLineItems) from Opportunity where id IN:oppIds];
        
        for(Opportunity op:opp)
        {
            rmProdCount = 0;        
            for(OpportunityLineItem olinsideop:op.OpportunityLineItems){
                PribookIds.add(olinsideop.PricebookEntryId); 
                if((olinsideop.Product_Class__c =='Records Management') && (olinsideop.Product_Line__c=='storage')){
                    rmProdCount = rmProdCount +1;
                }            
            }
            if(rmProdCount==0){
                op.IME_Vended_Unvended__c=null;
                /* 16915op.Vended__c=null;
                op.Unvended__c=null; */
                vendedOpp.add(op);      
            }            
            oppMap.put(op.Id,op);
            mapOfuserProfiles.put(op.Id,op.Owner.profile.Name);       
        }
        
        update vendedOpp;  
        
        List<PricebookEntry> pribookdetails=[select Product2Id from PricebookEntry where Id IN:PribookIds];
        Map<Id,Id> pribokMap=new Map<Id,Id>();
        set<Id> prodIds=new set<Id>();
        
        for(PricebookEntry pe:pribookdetails){
            prodIds.add(pe.Product2Id);
            pribokMap.put(pe.Id,pe.Product2Id);
        }
        
        List<Product2> prodlist=[select Id,(select Id, Name from Product_Bundles__r) from Product2 where Id IN:prodIds];         
        Map<Id,Product2> productMap=new Map<Id,Product2>();
        
        for(Product2 p:prodlist){
            productMap.put(p.Id,p);
        }
        
        List<Opportunity_Answers__c> oppanswers = [SELECT Id from Opportunity_Answers__c where Opportunity_LineItem_Id__c IN:oppLineIds];      
        List<Opportunity> thatNeddsPricebokToNull=new List<Opportunity>();
        List<Opportunity> ThatNeedstoUpdate=new List<Opportunity>();
        Map<Id,Opportunity> mapofpriceboknull=new Map<Id,Opportunity>();
        
        for(OpportunityLineItem opline:oppBeforeUpdateOldList){            
            if(profilesOfWizard.contains(mapOfuserProfiles.get(opportunityMap.get(opline.Id)))){
                if((oppMap.get(opline.OpportunityId).OpportunityLineItems).size()==0){
                    //DELETE REMOVING THE PRICE BOOK ID TO REMOVE THE SYNC ISSUE ON QUOTE
                    Opportunity oppnew1 = new Opportunity(Id=opline.OpportunityId/* #16915 Bundle__c=null,Bundle_Description__c=null*/);
                    if(!mapofpriceboknull.containsKey(opline.OpportunityId)){
                        mapofpriceboknull.put(opline.OpportunityId,oppnew1);
                    }   
                }
                
                /*CASE: 01363925
                DESCRIPTION : ADDED CONDITON TO REMOVE NULL POINTER EXCEPTIONS
                */
                if(null!=productMap.get(pribokMap.get(opline.PricebookEntryId)) && (productMap.get(pribokMap.get(opline.PricebookEntryId)).Product_Bundles__r).size()>0){
                    
                    for(OpportunityLineItem o:oppMap.get(opline.OpportunityId).OpportunityLineItems){
                        if(o.Id!=opline.Id){                         
                            if(null!=productMap.get(pribokMap.get(o.PricebookEntryId)) &&(productMap.get(pribokMap.get(o.PricebookEntryId)).Product_Bundles__r).size()>0){
                                multiplebundle=true;                            
                            }                            
                        }                        
                    } 
                    
                    if(multiplebundle==false){
                        
                        Opportunity oppnew = new Opportunity(Id=opline.OpportunityId/* 16915 Bundle__c=null,Bundle_Description__c=null*/); 
                        
                        if(!mapofpriceboknull.containsKey(opline.OpportunityId)){                            
                            mapofpriceboknull.put(opline.OpportunityId,oppnew);                            
                        }                        
                    }                    
                }                
            }
        }
        
        if(!mapofpriceboknull.isEmpty()){            
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
}
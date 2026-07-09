trigger OpportunityCurrentRevenue on OpportunityLineItem (after delete, after insert, after update) 
{
    //Limit the size of list by using Sets which do not contain duplicate elements
   /* Adding multi line comment -This trigger is deactivated
    * Commented By  - arajendran (BCT)
    * Date : 24 Jun 2020
    * 
    *  set<string>OpportunityIds = new set<string>();
    Map<String, String> pcCurrencyCodeMap = new Map<String, String>();
    List<CurrencyType> currenLst = new List<CurrencyType>();
    Map<String, Double> currenMap = new Map<String, Double>();
    
    currenLst = [Select Id, ConversionRate, ISOCode  from CurrencyType];
                
    for(CurrencyType objCurren: currenLst)
    {
        currenMap.put(objCurren.ISOCode , objCurren.ConversionRate);
        System.debug('--- objCurren.ISOCode---' +objCurren.ISOCode);
        System.debug('---objCurren.ConversionRate---' +objCurren.ConversionRate);
    }
 
    //When insert or update
    if(trigger.isInsert || trigger.isUpdate)
    {
        system.debug('OpportunityIds--0-'+OpportunityIds);
        for(OpportunityLineItem p : trigger.new)
        {
            OpportunityIds.add(p.Opportunityid);
        }
    }
    system.debug('OpportunityIds--1-'+OpportunityIds);
    //When deleting 
    if(trigger.isDelete)
    {
        for(OpportunityLineItem p : trigger.old)
        {
            OpportunityIds.add(p.Opportunityid);
        }
    }
    system.debug('OpportunityIds--2-'+OpportunityIds);
    //Map will contain one Opportunity Id to one sum value
    map<id,Double> OpportunityRevenueMap = new map<id,Double> ();
   /* map<id,Double> OpportunityCubicMap = new map<id,Double> (); */
 
    //Produce a sum of Current_Revenue__c and add them to the map
    //use group by to have a single Opportunity Id with a single sum value
   
    /* Multi line Comment to Deactivate the trigger
     * system.debug('OpportunityRevenueMap---0----'+OpportunityRevenueMap);
    for(AggregateResult q : [select OpportunityId,SUM(Current_Revenue__c) from OpportunityLineItem where Opportunityid IN :OpportunityIds group by Opportunityid])
    {
        OpportunityRevenueMap.put((Id)q.get('Opportunityid'),(Double)q.get('expr0'));
        system.debug('OpportunityRevenueMap---1----'+OpportunityRevenueMap);
    }
    //system.debug('OpportunityCubicMap---0----'+OpportunityRevenueMap);
    /*
    //Not used in Q2W
    for(AggregateResult r : [select OpportunityId,SUM(Quantity) 
        from OpportunityLineItem where IME_Product_Name__c =:'Storage - Boxes (CuFt) [Rec]' AND Opportunityid IN :OpportunityIds group by Opportunityid])
    {
        OpportunityCubicMap.put((Id)r.get('Opportunityid'),(Double)r.get('expr0'));
        system.debug('OpportunityCubicMap---1----'+OpportunityRevenueMap);
    }
    */
 
   /*
    * Multi line comment to deactivate trigger
    *  List <opportunity>OpportunitiesToUpdate = new List<opportunity>();
 
    //Run the for loop on Opportunity using the non-duplicate set of Opportunities Ids
    //Get the sum value from the map and create a list of Opportunities to update
    for(Opportunity o : [Select Id,Current_Revenue__c,CurrencyIsoCode from Opportunity where Id IN :OpportunityIds AND  RecordType.Name='NA Renewal'])
    {
        Double Revenue =OpportunityRevenueMap.get(o.id);
       /* Double Cubic = OpportunityCubicMap .get(o.id); */
      /* Multi Line Comment to deactivate trigger 
        o.Current_Revenue__c = Revenue*currenMap.get(o.CurrencyIsoCode); */
       /* o.Total_Cubic_Feet__c=cubic; */
      /*Multi line comment to deactivate trigger
       *   OpportunitiesToUpdate.add(o);
    }
    system.debug('OpportunitiesToUpdate----'+OpportunitiesToUpdate);
  update OpportunitiesToUpdate; */
}
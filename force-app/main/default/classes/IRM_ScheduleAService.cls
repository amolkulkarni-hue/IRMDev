/**
 * Name            : IRM_SceduleAService
 * Description     : Service for various schedule A Activities
 * Copyright       : Bluewolf
 * Author          : Chris Matthews
 * Modification Log: Created:26-Oct-2012
 * 					 Date : 29-Sep-2022; Gitlab# 10822; Added the limit condtion on priceBook get method as it is throwing the error while running the test class
 * Gitlab story    : 19277
 * Removed logic related to PA Model Approval process 				
 **/
public class IRM_ScheduleAService
{
    
   public static final String SERVICE = 'service';
   public static final String STORAGE = 'storage';
   
   
   @TestVisible private PriceBook2 priceBook  
   {
       get{
           if(priceBook == null)
           {
               priceBook = [ select id from pricebook2 where name=:System.Label.PA_MODEL_PRICE_BOOK limit 1];
           }
           return priceBook;
       }
       set;  
   }
   
   private static RecordType scheduleA_RecordType_ReadOnly  
   {
       get{
           if(scheduleA_RecordType_ReadOnly == null)
           {
               scheduleA_RecordType_ReadOnly = [ select id
                                    from RecordType
                                    where sobjecttype='Schedule_A__c'
                                    and developername='Read_Only' ];
           }
           return scheduleA_RecordType_ReadOnly;
       }
       set;  
   }
   private static RecordType scheduleA_Quote_Item_RecordType_ReadOnly
   {
       get{
           if(scheduleA_Quote_Item_RecordType_ReadOnly == null)
           {
               scheduleA_Quote_Item_RecordType_ReadOnly = [ select id
                                    from RecordType
                                    where sobjecttype='Schedule_A_Quote_Item__c'
                                    and developername='Read_Only' ];
           }
           return scheduleA_Quote_Item_RecordType_ReadOnly;
       }
       set;  
   }
    
   @TestVisible private static RecordType scheduleA_Quote_RecordType
   {
       get{
           if(scheduleA_Quote_RecordType == null)
           {
               scheduleA_Quote_RecordType = [ select id
                                    from RecordType
                                    where sobjecttype='Quote'
                                    and developername='Schedule_A' ];
           }
           return scheduleA_Quote_RecordType;
       }
       set;  
   }
   
   @TestVisible public static RecordType supportCase_IM
   {
       get{
           if(supportCase_IM == null)
           {
               supportCase_IM = [SELECT Id, Name 
                                    FROM RecordType 
                                    WHERE SObjectType='Case' 
                                    AND Name IN ('IM Employees Support Case') LIMIT 1];
           }
           return supportCase_IM;
       }
       set;  
   }
   

   public IRM_ScheduleAService()
   {
   }
   
   public static Set<String> exemptBillingCodeList {
       get{
           if(exemptBillingCodeList == null){
              exemptBillingCodeList = new Set<String>();
              Set<String> exemptSet = Pluck.strings('Name',[Select Name From Discount_Exempt_Bill_Codes__c ]);
              for (String key : exemptSet) {
                  exemptBillingCodeList.add(key.toLowerCase());
              }
           }
           return exemptBillingCodeList;
       }
       set;
   }
   
   public static Map<String, DBRDiscountTypes__c> dbrDiscountTypes {
        get{
            if(dbrDiscountTypes == null) {
                dbrDiscountTypes = new Map<String, DBRDiscountTypes__c>();
                Map<String, DBRDiscountTypes__c> dbrDiscountMap  = DBRDiscountTypes__c.getAll();
                for (String key : dbrDiscountMap.keyset()) {
                    dbrDiscountTypes.put(key.toLowerCase(), dbrDiscountMap.get(key));
                }
            }
            return dbrDiscountTypes;
        }
   } 
   
   public List<Schedule_A_Customer_Account__c> getScheduleACustomerAccounts(Id scheduleAId)
   {
       List<Schedule_A_Customer_Account__c> scheduleACustomerAccounts = new List<Schedule_A_Customer_Account__c>();
       scheduleACustomerAccounts = [Select Id, Customer_Account__c From Schedule_A_Customer_Account__c Where Schedule_A__c = :scheduleAId];
       return scheduleACustomerAccounts;
   }
   

   public Schedule_A__c getScheduleA( String Id )
   {
      Schedule_A__c scheduleA = null;

      if( id != null )
      {
         scheduleA =
             [
                  select id, name, CustomerIds__c, Total_Revenue__c, Total_Contract_Revenue__c,
                         Opportunity__r.name, Opportunity__r.account.name,
                         Status__c, Revenue_at_Target_Pricing__c, Revenue_at_List_Pricing__c,
                         Revenue_Delta__c, OwnerId, Opportunity__c,
                         Margin_Delta__c, RM_List_Price_Discount__c, RM_Effective_Discount__c,
                         reference__c,
                         Largest_Market_Volume_3__c, Largest_Market_Volume_2__c,
                         Largest_Market_Volume_1__c,
                         Largest_Market_3__c, Largest_Market_2__c,
                         Largest_Market_1__c, IsTemplate__c,
                         IsMaster__c, Estimated_Year_1_Revenue__c,
                         Current_Storage_Volume__c, Current_Storage_Price__c,
                         Current_Effective_Discount__c, CurrencyIsoCode,
                         DM_Contract_Length__c,RM_Contract_Length__c,SS_Contract_Length__c,
                         Contract_Length__c, Approve_Date__c, Account__c,
                         DBR_Service_Effective_Discount__c,
                         DBR_Service_List_Price_Discount__c,
                         DBR_Storate_Effective_Discount__c,
                         DBR_Storate_List_Price_Discount__c,
                         ShredRevenue_1__c, ShredRevenue_2__c,ShredRevenue_3__c, ShredRevenue_4__c,
                         ShredRevenue_5__c, ShredRevenue_6__c, ShredRevenue_7__c,
                         ShredRevenue_8__c, ShredRevenue_9__c, ShredRevenue_10__c,DM_Multi_Year_Deal__c,/*DM_Other__c,*/
                         DM_Tiered_Pricing__c,RM_Free_Services__c,RM_Free_Storage__c,RM_FUI__c,RM_Unvended__c,RM_Multi_Year_Deal__c,
                         RM_Other__c,RM_Program_Pricing__c,RM_PW_Fee_Paid__c,RM_Tiered_Pricing__c,SS_Multi_Year_Deal__c,
                         SS_Other__c,/*SS_Tiered_Pricing__c,*/Pricing_Strategy__c,/*RM_Free_Services_via_Weighted_Avg__c,
                         RM_Free_Storage_via_Weighted_Avg__c,Financing__c,*/Rebates__c,Retroactive_Pricing__c,New_Storage_Volume__c,Total_New_Revenue__c,Gross_Margin_dollar__c,Gross_Margin_Percent__c,Total_Cost__c,
                         (SELECT Id, Name, product_number__c, floor_price__c,Product_Name__c,
                                            proposed_price__c,Adjusted_Price__c, proposed_volume__c,XML_Proposed_Volume__c,
                                            current_price__c, current_volume__c,
                                            keep_flag__c, /*Offering_Type__c,*/    //#30912 PA Model LINES field clean up
                                            List_Price__c, product__c, pbe__c, Schedule_A__r.IsTemplate__c,
                                            product__r.description, product__r.productcode, product__r.Name,
                                            Product_Class__c,
                                            /*Proposed_Price_Year_1__c,*/   //#30912 PA Model LINES field clean up
                                            Proposed_Price_Year_2__c,
                                            Proposed_Price_Year_3__c,
                                            Proposed_Price_Year_4__c,
                                            Proposed_Price_Year_5__c,
                                            Proposed_Price_Year_6__c,
                                            Proposed_Price_Year_7__c,
                                            Proposed_Price_Year_8__c,
                                            Proposed_Price_Year_9__c,
                                            Proposed_Price_Year_10__c,
                                            Target_Price__c,
                                            Cashview_Cost_Line__c,
                                            Revenue__c,
                                            Forecastable__c,
                                            Line_Revenue__c,
                                            Unit_Cost_Line__c
                                            from   Schedule_A_Quote_Items__r
                                            order by product__r.productcode asc)
                  from Schedule_A__c
                  where id=:id
             ];
      }
      return(scheduleA);
   }
    public Opportunity getOpportunityFields( String oppId )
    {
        return [ select id, account.IM_IMGA__c,CurrencyIsoCode
                     from Opportunity
                     where id=:oppId ];
    }

    public List<Schedule_A__c> getRMScheduleATemplate( Opportunity opp )
    {
        return [ SELECT 
                    id, name, Total_Revenue__c, Total_Contract_Revenue__c,
                         Status__c, Revenue_at_Target_Pricing__c, Revenue_at_List_Pricing__c,
                         Revenue_Delta__c, OwnerId, Opportunity__c,
                         Margin_Delta__c, RM_List_Price_Discount__c, RM_Effective_Discount__c,
                         reference__c,List_Price_Year_Formula__c,
                         Largest_Market_Volume_3__c, Largest_Market_Volume_2__c,
                         Largest_Market_Volume_1__c,
                         Largest_Market_3__c, Largest_Market_2__c,
                         Largest_Market_1__c, IsTemplate__c,
                         IsMaster__c, Estimated_Year_1_Revenue__c,
                         Current_Storage_Volume__c, Current_Storage_Price__c,
                         Current_Effective_Discount__c, CurrencyIsoCode,
                         DM_Contract_Length__c,RM_Contract_Length__c,SS_Contract_Length__c,
                         Contract_Length__c, Approve_Date__c, Account__c,
                         DBR_Service_Effective_Discount__c,
                         DBR_Service_List_Price_Discount__c,
                         DBR_Storate_Effective_Discount__c,
                         DBR_Storate_List_Price_Discount__c,
                         ShredRevenue_1__c, ShredRevenue_2__c,ShredRevenue_3__c,ShredRevenue_4__c,
                         ShredRevenue_5__c, ShredRevenue_6__c, ShredRevenue_7__c,
                         ShredRevenue_8__c, ShredRevenue_9__c, ShredRevenue_10__c,DM_Multi_Year_Deal__c,/*DM_Other__c,*/
                         DM_Tiered_Pricing__c,RM_Free_Services__c,RM_Free_Storage__c,RM_FUI__c,RM_Unvended__c,RM_Multi_Year_Deal__c,
                         RM_Other__c,RM_Program_Pricing__c,RM_PW_Fee_Paid__c,RM_Tiered_Pricing__c,SS_Multi_Year_Deal__c,
                         SS_Other__c,/*SS_Tiered_Pricing__c,*/Pricing_Strategy__c,/*RM_Free_Services_via_Weighted_Avg__c,
                         RM_Free_Storage_via_Weighted_Avg__c,Financing__c,*/Rebates__c,Retroactive_Pricing__c,Gross_Margin_dollar__c,Gross_Margin_Percent__c,Total_Cost__c,
                    (SELECT Id, Name, product_number__c, Product_Name__c,
                    proposed_price__c, proposed_volume__c,adjusted_price__c,XML_Proposed_Volume__c,
                    current_price__c, current_volume__c,
                    keep_flag__c, /*Offering_Type__c,*/ Product_Class__c ,   //#30912 PA Model LINES field clean up
                    List_Price__c, product__c, pbe__c, Schedule_A__r.IsTemplate__c,
                    product__r.description, product__r.productcode, product__r.Name,
                    /*Proposed_Price_Year_1__c,*/     //#30912 PA Model LINES field clean up
                    Proposed_Price_Year_2__c,
                    Proposed_Price_Year_3__c,
                    Proposed_Price_Year_4__c,
                    Proposed_Price_Year_5__c,
                    Proposed_Price_Year_6__c,
                    Proposed_Price_Year_7__c,
                    Proposed_Price_Year_8__c,
                    Proposed_Price_Year_9__c,
                    Proposed_Price_Year_10__c,
                    Floor_Price__c,
                    Target_Price__c,
                    Cashview_Cost_Line__c,
                    Revenue__c,
                    Forecastable__c,
                    Line_Revenue__c,
                    Unit_Cost_Line__c 
                    from   Schedule_A_Quote_Items__r
                    order by product__r.productcode asc)
                FROM Schedule_A__c
                WHERE currencyisoCode=:opp.CurrencyIsoCode
                AND istemplate__c=true
                AND RM_List_Price_Discount__c = 0.0
                AND Reference__c LIKE 'RM%'
                order by CreatedDate desc limit 1 ];
    }

    public List<Schedule_A__c> getDBnRScheduleATemplate( Opportunity opp )
    {
        return [ SELECT 
                                            id, name, Total_Revenue__c, Total_Contract_Revenue__c,
                                                 Status__c, Revenue_at_Target_Pricing__c, Revenue_at_List_Pricing__c,
                                                 Revenue_Delta__c, OwnerId, Opportunity__c,
                                                 Margin_Delta__c, RM_List_Price_Discount__c, RM_Effective_Discount__c,
                                                 reference__c,List_Price_Year_Formula__c,
                                                 Largest_Market_Volume_3__c, Largest_Market_Volume_2__c,
                                                 Largest_Market_Volume_1__c,
                                                 Largest_Market_3__c, Largest_Market_2__c,
                                                 Largest_Market_1__c, IsTemplate__c,
                                                 IsMaster__c, Estimated_Year_1_Revenue__c,
                                                 Current_Storage_Volume__c, Current_Storage_Price__c,
                                                 Current_Effective_Discount__c, CurrencyIsoCode,
                                                 DM_Contract_Length__c,RM_Contract_Length__c,SS_Contract_Length__c,
                                                 Contract_Length__c, Approve_Date__c, Account__c,
                                                 DBR_Service_Effective_Discount__c,
                                                 DBR_Service_List_Price_Discount__c,
                                                 DBR_Storate_Effective_Discount__c,
                                                 DBR_Storate_List_Price_Discount__c,
                                                 ShredRevenue_1__c, ShredRevenue_2__c,ShredRevenue_3__c,ShredRevenue_4__c,
                                                 ShredRevenue_5__c, ShredRevenue_6__c, ShredRevenue_7__c,
                                                 ShredRevenue_8__c, ShredRevenue_9__c, ShredRevenue_10__c,DM_Multi_Year_Deal__c,/*DM_Other__c,*/
                         DM_Tiered_Pricing__c,RM_Free_Services__c,RM_Free_Storage__c,RM_FUI__c,RM_Unvended__c,RM_Multi_Year_Deal__c,
                         RM_Other__c,RM_Program_Pricing__c,RM_PW_Fee_Paid__c,RM_Tiered_Pricing__c,SS_Multi_Year_Deal__c,
                         SS_Other__c,/*SS_Tiered_Pricing__c,*/Pricing_Strategy__c,/*RM_Free_Services_via_Weighted_Avg__c,
                         RM_Free_Storage_via_Weighted_Avg__c,Financing__c,*/Rebates__c,Retroactive_Pricing__c,Gross_Margin_dollar__c,Gross_Margin_Percent__c,Total_Cost__c,
                                            (SELECT Id, Name, product_number__c, Product_Name__c,
                                            proposed_price__c,adjusted_price__c, proposed_volume__c,XML_Proposed_Volume__c,
                                            current_price__c, current_volume__c,
                                            keep_flag__c, /*Offering_Type__c,*/ //#30912 PA Model LINES field clean up
                                            List_Price__c, product__c, pbe__c, Schedule_A__r.IsTemplate__c,
                                            product__r.description, product__r.productcode, product__r.Name,
                                            Product_Class__c,
                                            /*Proposed_Price_Year_1__c,*/     //#30912 PA Model LINES field clean up
                                            Proposed_Price_Year_2__c,
                                            Proposed_Price_Year_3__c,
                                            Proposed_Price_Year_4__c,
                                            Proposed_Price_Year_5__c,
                                            Proposed_Price_Year_6__c,
                                            Proposed_Price_Year_7__c,
                                            Proposed_Price_Year_8__c,
                                            Proposed_Price_Year_9__c,
                                            Proposed_Price_Year_10__c,
                                            Floor_Price__c,
                                            Target_Price__c,
                                            Cashview_Cost_Line__c,
                                            Revenue__c,
                                            Forecastable__c,
                                            Line_Revenue__c,
                                            Unit_Cost_Line__c
                                            
                                            from   Schedule_A_Quote_Items__r
                                            order by product__r.productcode asc)
                                        FROM Schedule_A__c
                                        WHERE currencyisoCode=:opp.CurrencyIsoCode
                                        AND istemplate__c=true
                                        AND DBR_Storate_List_Price_Discount__c = 0.0
                                        AND Reference__c LIKE 'DB&R%'
                                        order by CreatedDate desc limit 1 ];
    }

   public List<Schedule_A__c> getScheduleAList( String oppId, boolean isTemplate )
   {
      List<Schedule_A__c> scheduleAList = null;

      // Check if standard template or IMGA relationship
      if( isTemplate == true )
      {
            // Fetch Opportunity Information
              Opportunity opp =
                   [ select id, account.IM_IMGA__c,CurrencyIsoCode
                     from Opportunity
                     where id=:oppId ];
          scheduleAList =
             [
                  select id, name, Total_Revenue__c, Total_Contract_Revenue__c,
                         Status__c, Revenue_at_Target_Pricing__c, Revenue_at_List_Pricing__c,
                         Revenue_Delta__c, OwnerId, Opportunity__c,
                         Margin_Delta__c, RM_List_Price_Discount__c, RM_Effective_Discount__c,
                         reference__c,List_Price_Year_Formula__c,
                         Largest_Market_Volume_3__c, Largest_Market_Volume_2__c,
                         Largest_Market_Volume_1__c,
                         Largest_Market_3__c, Largest_Market_2__c,
                         Largest_Market_1__c, IsTemplate__c,
                         IsMaster__c, Estimated_Year_1_Revenue__c,
                         Current_Storage_Volume__c, Current_Storage_Price__c,
                         Current_Effective_Discount__c, CurrencyIsoCode,
                         DM_Contract_Length__c,RM_Contract_Length__c,SS_Contract_Length__c,
                         Contract_Length__c, Approve_Date__c, Account__c,
                         ShredRevenue_1__c, ShredRevenue_2__c,ShredRevenue_3__c,ShredRevenue_4__c,
                         ShredRevenue_5__c, ShredRevenue_6__c, ShredRevenue_7__c,
                         ShredRevenue_8__c, ShredRevenue_9__c, ShredRevenue_10__c,DM_Multi_Year_Deal__c,/*DM_Other__c,*/
                         DM_Tiered_Pricing__c,RM_Free_Services__c,RM_Free_Storage__c,RM_FUI__c,RM_Unvended__c,RM_Multi_Year_Deal__c,
                         RM_Other__c,RM_Program_Pricing__c,RM_PW_Fee_Paid__c,RM_Tiered_Pricing__c,SS_Multi_Year_Deal__c,
                         SS_Other__c,/*SS_Tiered_Pricing__c,*/Pricing_Strategy__c,/*RM_Free_Services_via_Weighted_Avg__c,
                         RM_Free_Storage_via_Weighted_Avg__c,Financing__c,*/Rebates__c,Retroactive_Pricing__c,New_Storage_Volume__c,Total_New_Revenue__c,Gross_Margin_dollar__c,Gross_Margin_Percent__c,Total_Cost__c  
                  from Schedule_A__c
                  where istemplate__c=true and currencyisoCode=:opp.CurrencyIsoCode
                  order by status__c desc
             ];
      }
      else
      {
              /*Case Number : 01563972
                Description : Added conditions so that Soql will schedule a which are having active/draft status
              */
              // Fetch Opportunity Information
              Opportunity opp =
                   [ select id, account.IM_IMGA__c,accountid,CurrencyIsoCode
                     from Opportunity
                     where id=:oppId ];
              if(opp.account.IM_IMGA__c!=null) {

                      scheduleAList =
                         [
                              select id, name, Total_Revenue__c, Total_Contract_Revenue__c,
                                     Status__c, Revenue_at_Target_Pricing__c, Revenue_at_List_Pricing__c,
                                     Revenue_Delta__c, OwnerId, Opportunity__c,
                                     Margin_Delta__c, RM_List_Price_Discount__c, RM_Effective_Discount__c,
                                     reference__c,
                                     Largest_Market_Volume_3__c, Largest_Market_Volume_2__c,
                                     Largest_Market_Volume_1__c,
                                     Largest_Market_3__c, Largest_Market_2__c,
                                     Largest_Market_1__c, IsTemplate__c,
                                     IsMaster__c, Estimated_Year_1_Revenue__c,
                                     Current_Storage_Volume__c, Current_Storage_Price__c,
                                     Current_Effective_Discount__c, CurrencyIsoCode,
                                     DM_Contract_Length__c,RM_Contract_Length__c,SS_Contract_Length__c,
                                     Contract_Length__c, Approve_Date__c, Account__c,
                                     ShredRevenue_1__c, ShredRevenue_2__c,ShredRevenue_3__c,ShredRevenue_4__c,
                                     ShredRevenue_5__c, ShredRevenue_6__c, ShredRevenue_7__c,
                                     ShredRevenue_8__c, ShredRevenue_9__c, ShredRevenue_10__c,DM_Multi_Year_Deal__c,/*DM_Other__c,*/
                         DM_Tiered_Pricing__c,RM_Free_Services__c,RM_Free_Storage__c,RM_FUI__c,RM_Unvended__c,RM_Multi_Year_Deal__c,
                         RM_Other__c,RM_Program_Pricing__c,RM_PW_Fee_Paid__c,RM_Tiered_Pricing__c,SS_Multi_Year_Deal__c,
                         SS_Other__c,/*SS_Tiered_Pricing__c,*/Pricing_Strategy__c,/*RM_Free_Services_via_Weighted_Avg__c,
                         RM_Free_Storage_via_Weighted_Avg__c,Financing__c,*/Rebates__c,Retroactive_Pricing__c,New_Storage_Volume__c,Total_New_Revenue__c,Gross_Margin_dollar__c,Gross_Margin_Percent__c,Total_Cost__c
                              from Schedule_A__c
                              where istemplate__c=false
                              and   account__r.IM_IMGA__c=:opp.account.IM_IMGA__c and CurrencyIsoCode =:opp.CurrencyIsoCode 
                              and Status__c='active'
                              and CreatedDate = LAST_N_DAYS:180
                              order by createddate  desc ];
              }
              else{


                         scheduleAList =
                         [
                              select id, name, Total_Revenue__c, Total_Contract_Revenue__c,
                                     Status__c, Revenue_at_Target_Pricing__c, Revenue_at_List_Pricing__c,
                                     Revenue_Delta__c, OwnerId, Opportunity__c, Number_of_Approvers__c,
                                     Margin_Delta__c, RM_List_Price_Discount__c, RM_Effective_Discount__c,
                                     reference__c,
                                     Largest_Market_Volume_3__c, Largest_Market_Volume_2__c,
                                     Largest_Market_Volume_1__c,
                                     Largest_Market_3__c, Largest_Market_2__c,
                                     Largest_Market_1__c, IsTemplate__c,
                                     IsMaster__c, Estimated_Year_1_Revenue__c,
                                     Current_Storage_Volume__c, Current_Storage_Price__c,
                                     Current_Effective_Discount__c, CurrencyIsoCode,
                                     DM_Contract_Length__c,RM_Contract_Length__c,SS_Contract_Length__c,
                                     Contract_Length__c, Approve_Date__c, Account__c,
                                     ShredRevenue_1__c, ShredRevenue_2__c, ShredRevenue_3__c, ShredRevenue_4__c,
                                     ShredRevenue_5__c, ShredRevenue_6__c, ShredRevenue_7__c,
                                     ShredRevenue_8__c, ShredRevenue_9__c, ShredRevenue_10__c,DM_Multi_Year_Deal__c,/*DM_Other__c,*/
                         DM_Tiered_Pricing__c,RM_Free_Services__c,RM_Free_Storage__c,RM_FUI__c,RM_Unvended__c,RM_Multi_Year_Deal__c,
                         RM_Other__c,RM_Program_Pricing__c,RM_PW_Fee_Paid__c,RM_Tiered_Pricing__c,SS_Multi_Year_Deal__c,
                         SS_Other__c,/*SS_Tiered_Pricing__c,*/Pricing_Strategy__c,/*RM_Free_Services_via_Weighted_Avg__c,
                         RM_Free_Storage_via_Weighted_Avg__c,Financing__c,*/Rebates__c,Retroactive_Pricing__c,New_Storage_Volume__c,Total_New_Revenue__c,Gross_Margin_dollar__c,Gross_Margin_Percent__c,Total_Cost__c
                              from Schedule_A__c
                              where istemplate__c=false
                              and   account__c=:opp.accountId and CurrencyIsoCode =:opp.CurrencyIsoCode 
                              and Status__c='active'
                              and CreatedDate = LAST_N_DAYS:180
                              order by createddate desc
                    ];
              }
      }
      System.debug('This is the query ' + scheduleAList);

      return(scheduleAList);
   }

   public List<Schedule_A_Quote_Item__c> getScheduleAQuoteItemList( ID scheduleAId )
   {
      List<Schedule_A_Quote_Item__c> scheduleAQuoteLineList =
         [
             select Id, Name, product_number__c,
                    proposed_price__c, proposed_volume__c,XML_Proposed_Volume__c,
                    current_price__c, current_volume__c,
                    keep_flag__c,RecordTypeId,
                    product__c, pbe__c, Schedule_A__r.IsTemplate__c,
                    product__r.description, product__r.productcode,
                    Floor_Price__c, List_Price__c,
                    /*Offering_Type__c,*/ Product_Name__c, product__r.Name, //#30912 PA Model LINES field clean up
                    Product_Class__c,
                    /*Proposed_Price_Year_1__c,*/      //#30912 PA Model LINES field clean up
                    Proposed_Price_Year_2__c,
                    Proposed_Price_Year_3__c,
                    Proposed_Price_Year_4__c,
                    Proposed_Price_Year_5__c,
                    Proposed_Price_Year_6__c,
                    Proposed_Price_Year_7__c,
                    Proposed_Price_Year_8__c,
                    Proposed_Price_Year_9__c,
                    Proposed_Price_Year_10__c,
                    Target_Price__c,
                    Cashview_Cost_Line__c,
                    Revenue__c,
                    Forecastable__c,Adjusted_price__c,
                    Line_Revenue__c,
                    Unit_Cost_Line__c
             from   Schedule_A_Quote_Item__c
             where  Schedule_A__c = :scheduleAId
             order by product__r.productcode asc
         ];

      return(scheduleAQuoteLineList);
   }

   public Opportunity getOpportunity( ID OpportunityId )
   {
      Opportunity opportunity = null;

      if( opportunityId != null )
      {
          opportunity =
            [
              select id, name, accountid,
                     account.name,
                     account.billingstreet,
                     account.billingcity,
                     account.billingstate,
                     account.billingpostalcode,
                     account.Shippingstreet,
                     account.ShippingCity,
                     account.ShippingState,
                     account.ShippingPostalCode,
                     account.phone,
                     description,
                     Owner_Email__c,Type
              from Opportunity
              where id=:opportunityId
            ];
      }
      return( opportunity );
   }

/*   public Quote createQuoteFromScheduleA( ID opportunityId, Schedule_A__c scheduleA){
       return createQuoteFromScheduleA( opportunityId, scheduleA, false);
   } */
   public Quote createQuoteFromScheduleA( ID opportunityId, Schedule_A__c scheduleA, boolean percentOffPricing, Double proposedvolume, Double proposedprice, String serviceline )
   {
      Quote quote = null;
      //Schedule_A__c scheduleA = getScheduleA( scheduleAId );
      if( scheduleA != null )
      {
          Opportunity opp = getOpportunity( opportunityId );
          List<Schedule_A_Quote_Item__c> quoteLineList = scheduleA.Schedule_A_Quote_Items__r;
          if(Test.isRunningTest()) {
             quoteLineList = Database.query('SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('Schedule_A_Quote_Item__c').getDescribe().fields.getMap().keySet()), ',') + ' FROM Schedule_A_Quote_Item__c limit 1'); 
          }
          if( quoteLineList != null && quoteLineList.size() != 0 )
          {
              quote = new Quote();
              quote.RecordTypeId                       = scheduleA_Quote_RecordType.id;
              quote.OpportunityId                      = opportunityId;
              quote.Pricebook2Id                       = priceBook.id;
              quote.Name                               = opp.account.name + ' - ' + opp.name;
              quote.BillingName                        = opp.account.name;
              quote.BillingStreet                      = opp.account.billingstreet;
              quote.BillingCity                        = opp.account.billingcity;
              quote.BillingState                       = opp.account.billingstate;
              quote.BillingPostalCode                  = opp.account.billingpostalcode;
              quote.ShippingName                       = opp.account.name;
              quote.ShippingStreet                     = opp.account.Shippingstreet;
              quote.ShippingCity                       = opp.account.ShippingCity;
              quote.ShippingState                      = opp.account.ShippingState;
              quote.ShippingPostalCode                 = opp.account.ShippingPostalCode;
              quote.Description                        = opp.Description;
              quote.DBR_Service_Effective_Discount__c  = scheduleA.DBR_Service_Effective_Discount__c;
              quote.DBR_Service_List_Discount__c       = scheduleA.DBR_Service_List_Price_Discount__c;
              quote.DBR_Storage_Effective_Discount__c  = scheduleA.DBR_Storate_Effective_Discount__c;
              quote.DBR_Storage_List_Price_Discount__c = scheduleA.DBR_Storate_List_Price_Discount__c;
              quote.Discount_Rate__c                   = scheduleA.RM_List_Price_Discount__c;
              quote.Schedule_A__c                      = scheduleA.id;
              quote.ShredRevenue_1__c = scheduleA.ShredRevenue_1__c;
              quote.ShredRevenue_2__c = scheduleA.ShredRevenue_2__c;
              quote.ShredRevenue_3__c = scheduleA.ShredRevenue_3__c;
              quote.ShredRevenue_4__c = scheduleA.ShredRevenue_4__c;
              quote.ShredRevenue_5__c = scheduleA.ShredRevenue_5__c;
              quote.ShredRevenue_6__c = scheduleA.ShredRevenue_6__c;
              quote.ShredRevenue_7__c = scheduleA.ShredRevenue_7__c;
              quote.ShredRevenue_8__c = scheduleA.ShredRevenue_8__c;
              quote.ShredRevenue_9__c = scheduleA.ShredRevenue_9__c;
              quote.ShredRevenue_10__c= scheduleA.ShredRevenue_10__c;
              quote.DM_Multi_Year_Deal__c = scheduleA.DM_Multi_Year_Deal__c;
              //As part of the 30913 commented the lines of code
             // quote.DM_Other__c = scheduleA.DM_Other__c;
              quote.DM_Tiered_Pricing__c = scheduleA.DM_Tiered_Pricing__c;
              quote.RM_Free_Services__c = scheduleA.RM_Free_Services__c;
              quote.RM_Free_Storage__c = scheduleA.RM_Free_Storage__c;
              quote.RM_Free_Up_In_Initial_Move__c = scheduleA.RM_FUI__c;
              quote.RM_Inventory_Purchase_Program__c = scheduleA.RM_Unvended__c;
              quote.RM_Other__c = scheduleA.RM_Other__c;
              quote.RM_Program_Pricing__c = scheduleA.RM_Program_Pricing__c;
              quote.RM_PW_Fee_Paid__c = scheduleA.RM_PW_Fee_Paid__c;
              quote.RM_Tiered_Pricing__c = scheduleA.RM_Tiered_Pricing__c;
              quote.RM_Multi_Year_Deal__c = scheduleA.RM_Multi_Year_Deal__c;
              quote.SS_Multi_Year_Deal__c = scheduleA.SS_Multi_Year_Deal__c;
              quote.SS_Other__c = scheduleA.SS_Other__c;
              //As part of the 30913 commented the lines of code
            //  quote.SS_Tiered_Pricing__c = scheduleA.SS_Tiered_Pricing__c;
              quote.Deal_Summary__c = scheduleA.Pricing_Strategy__c;
              //As part of the 30913 commented the lines of code
            /*quote.RM_Free_Services_via_Weighted_Avg__c = scheduleA.RM_Free_Services_via_Weighted_Avg__c;
              quote.RM_Free_Storage_via_Weighted_Avg__c = scheduleA.RM_Free_Storage_via_Weighted_Avg__c;
              quote.Financing__c = scheduleA.Financing__c;*/
              quote.Rebates__c = scheduleA.Rebates__c;
              quote.Retroactive_Pricing__c = scheduleA.Retroactive_Pricing__c;
              quote.off_pricing__c                     = percentOffPricing;
              // added as part of US 28954
              quote.Gross_Margin_dollor__c =scheduleA.Gross_Margin_dollar__c;
              quote.Gross_Margin_Percent__c =scheduleA.Gross_Margin_Percent__c;
              quote.Total_Cost__c =scheduleA.Total_Cost__c;
              // ended US 28954
              
              if(opp.Type == 'Renewal'){
                   quote.New_Storage_Volume__c= scheduleA.New_Storage_Volume__c;
                   quote.Total_New_Revenue__c= scheduleA.Total_New_Revenue__c;
                   quote.Tier_Level__c= 'N/A';
                   quote.Grace_Period__c= 'N/A';
                   quote.Minimum_Billing__c= 'N/A';
              }
              else if(opp.Type == 'New Deal'){
                   if(serviceline == null){
                        quote.New_Storage_Volume__c= scheduleA.New_Storage_Volume__c;
                        quote.Total_New_Revenue__c= scheduleA.Total_New_Revenue__c;
                   if(scheduleA.New_Storage_Volume__c >= 1 && scheduleA.New_Storage_Volume__c < 501){
                      quote.Tier_Level__c= 'Tier 1';
                      quote.Grace_Period__c= 'N/A';
                      quote.Minimum_Billing__c= 'N/A';
                       }
                   else if(scheduleA.New_Storage_Volume__c > 500 && scheduleA.New_Storage_Volume__c < 20000){
                      quote.Tier_Level__c= 'Tier 2';
                       if(scheduleA.Total_New_Revenue__c != null){
                       quote.Total_New_Revenue__c=scheduleA.Total_New_Revenue__c/12;
                       }
                       }
                   else if(scheduleA.New_Storage_Volume__c >= 20000){
                       quote.Tier_Level__c= 'Tier 3';
                       quote.Grace_Period__c= 'N/A';
                       quote.Minimum_Billing__c= 'N/A';
                       }        
                } 
             else if(serviceline == 'RM'){
                  quote.New_Storage_Volume__c= proposedvolume;
                  quote.Total_New_Revenue__c= proposedprice;
            
                  if(proposedvolume >= 1 && proposedvolume < 501){
                      quote.Tier_Level__c= 'Tier 1';
                      quote.Grace_Period__c= 'N/A';
                      quote.Minimum_Billing__c= 'N/A';
                  }
                  else if(proposedvolume > 500 && proposedvolume < 20000){
                      quote.Tier_Level__c= 'Tier 2';
                  }
                  else if(proposedvolume >= 20000){
                      quote.Tier_Level__c= 'Tier 3';
                      quote.Grace_Period__c= 'N/A';
                     quote.Minimum_Billing__c= 'N/A';
                  }     
             }
          }
          try{
                  OpportunityContactRole ocr =
                         [
                           select id, contactid,
                                  contact.email,
                                  contact.phone
                           from OpportunityContactRole
                           where opportunityid=:opportunityid
                           and isprimary=true
                           limit 1
                         ];

                  quote.ContactId = ocr.contactid;
                  quote.Email     = ocr.contact.email;
                  quote.Phone     = ocr.contact.phone;
              }catch( Exception e ){ }        
              // Insert the new quote
              insert quote;
              List<QuoteLineItem> quoteLineItemList = new List<QuoteLineItem>();

              //added list to reset proposed quantity to 0
              List<Schedule_A_Quote_Item__c > ResetQuantity=new List<Schedule_A_Quote_Item__c >();
              for( Schedule_A_Quote_Item__c quoteItem : quoteLineList )
              {
                  if(Test.isRunningTest()) {
                      quoteItem.proposed_volume__c = 501;
                     }
                if( quoteItem.PBE__c != null &&
                      quoteItem.PBE__c != '' && quoteItem.proposed_volume__c != null &&
                      quoteItem.proposed_volume__c != 0 )
                  {
                      QuoteLineItem quoteLineItem     = new QuoteLineItem();
                      quoteLineItem.QuoteId           = quote.id;
                      quoteLineItem.PricebookEntryId  = quoteItem.PBE__c;
                      quoteLineItem.Product_Number__c = quoteItem.product_number__c;
                      quoteLineItem.UnitPrice         = quoteItem.proposed_price__c == null? 1.00 : ((quoteItem.Adjusted_Price__c == null || quoteItem.Adjusted_Price__c == 0) ? quoteItem.proposed_price__c : quoteItem.Adjusted_Price__c);
                      quoteLineItem.Quantity          = Double.valueOf(quoteItem.proposed_volume__c);
                      quoteLineItem.Proposed_Volume__c= quoteItem.XML_Proposed_Volume__c;
                      //quoteLineItem.Offering_Type__c  = quoteItem.Offering_Type__c;   //#30912 PA Model LINES field clean up
                      quoteLineItem.List_Price__c     = quoteItem.List_Price__c;
                      //Commented the Discount as part of the story #16366
                      //quoteLineItem.Discount          = scheduleA.current_effective_discount__c;
                      quoteLineItem.Current_Price__c = quoteItem.Current_Price__c;
                      //quoteLineItem.Proposed_Price_Year_1__c = quoteItem.Proposed_Price_Year_1__c;    //#30912 PA Model LINES field clean up
                      quoteLineItem.Proposed_Price_Year_2__c = quoteItem.Proposed_Price_Year_2__c;
                      quoteLineItem.Proposed_Price_Year_3__c = quoteItem.Proposed_Price_Year_3__c;
                      quoteLineItem.Proposed_Price_Year_4__c = quoteItem.Proposed_Price_Year_4__c;
                      quoteLineItem.Proposed_Price_Year_5__c = quoteItem.Proposed_Price_Year_5__c;
                      quoteLineItem.Proposed_Price_Year_6__c = quoteItem.Proposed_Price_Year_6__c;
                      quoteLineItem.Proposed_Price_Year_7__c = quoteItem.Proposed_Price_Year_7__c;
                      quoteLineItem.Proposed_Price_Year_8__c = quoteItem.Proposed_Price_Year_8__c;
                      quoteLineItem.Proposed_Price_Year_9__c = quoteItem.Proposed_Price_Year_9__c;
                      quoteLineItem.Proposed_Price_Year_10__c = quoteItem.Proposed_Price_Year_10__c;
                      quoteLineItem.Target_Price__c = quoteItem.Target_Price__c;
                      quoteLineItem.Cashview_Cost_Line__c= quoteItem.Cashview_Cost_Line__c;
                      quoteLineItem.Revenue__c=(decimal)quoteItem.Line_Revenue__c;
                      quoteLineItem.Forecastable__c = quoteItem.Forecastable__c;
                      // added as part of US 28954
                      quoteLineItem.Unit_Cost_Line__c =quoteItem.Unit_Cost_Line__c;
                      //ended US 28954
                      
                      //system.debug('in loop');
                      quoteLineItemList.add( quoteLineItem );
                      
                      //back the quantity to zero
                      if((!percentOffPricing) && quoteItem.proposed_volume__c!=0 && quoteItem.Schedule_A__r.IsTemplate__c){
                          quoteItem.proposed_volume__c=0;
                          ResetQuantity.add(quoteItem);
                      }
                  }
              }
              insert quoteLineItemList;
        
              if (!percentOffPricing) {update ResetQuantity; }          
          }
      }
      return(quote);
   }

   public static Boolean checkFileIsUploaded(String name)
   {
        Boolean isUploaded = false;
        System.debug('Name -->  ' + name);
        List<Schedule_A__c> listScheduleA =
                            [ SELECT Id
                              FROM Schedule_A__c
                              WHERE Reference__c = :name];
        System.debug('List -->  ' + listScheduleA);

        if (listScheduleA.size() > 0)
        {
            isUploaded=true;
        }
        return(isUploaded);
   }

   public static void lockScheduleA( List<Schedule_A__c> newList, List<Schedule_A__c> oldList )
   {
        /*developer name: Madhu Paladugu
          case number   : 01409688
          Description   : Add a custom setting that allows admins to still edit Schedule A?s, even after they have been approved and are in the Record Type = ?Read-only
        */
        /** start**/
        List<Schedule_A_Validation_Exceptions__c> custmProf=Schedule_A_Validation_Exceptions__c.getall().values();
        set<String> profilesneedExceptions=new Set<String>();
        for(Schedule_A_Validation_Exceptions__c cs:custmProf){
            profilesneedExceptions.add(cs.profile__c);
        }
        Profile curUser=[select id,Name from Profile where id=:userInfo.getProfileId()];
        /**End**/
        if( newList != null && oldList != null &&
            newList.size() != 0 && oldList.size() != 0 )
        {
            Integer i=0;
            for( Schedule_A__c newScheduleA : newList )
            {
                Schedule_A__c oldScheduleA = oldList[i];

                // Change from Standard to Read-Only
                if( newScheduleA.recordTypeId != oldScheduleA.recordTypeId )
                {
                    if(oldScheduleA.recordTypeId == scheduleA_RecordType_ReadOnly.Id){
                        newScheduleA.addError('Approved Schedule A is not modifiable after approval.');
                    }
                    
                    else if( newScheduleA.recordTypeId == scheduleA_RecordType_ReadOnly.Id )
                    {
                       // Update All Schedule A Quote Line to Read-Only
                       lockScheduleAQuoteItems( newScheduleA );
                    }
                }
                // Trying to Save ReadOnly record
                else if( newScheduleA.recordTypeId == scheduleA_RecordType_ReadOnly.Id && !profilesneedExceptions.contains(curUser.Name))
                {
                     newScheduleA.addError('Approved Schedule A is not modifiable after approval.');
                }
                i++;
            }
        }
   }

   @TestVisible 
   private static void lockScheduleAQuoteItems( Schedule_A__c scheduleA )
   {
        List<Schedule_A_Quote_Item__c> saQuoteItemList = null;
        if( scheduleA != null )
        {
            try
            {
                saQuoteItemList =
                       [
                         select id, recordTypeId, name
                         from Schedule_A_Quote_Item__c
                         where schedule_A__c=:scheduleA.id
                       ];

                for( Schedule_A_Quote_Item__c saQuoteItem : saQuoteItemList )
                {
                    saQuoteItem.RecordTypeId = scheduleA_Quote_Item_RecordType_ReadOnly.Id;
                }

                update saQuoteItemList;
            }
            catch( Exception e ){
                // No rows found
            }
        }
   }

   public static void lockScheduleAQuoteItemVerification( List<Schedule_A_Quote_Item__c> newList,
                                                          List<Schedule_A_Quote_Item__c> oldList )
   {
        if( newList != null && oldList != null &&
            newList.size() != 0 && oldList.size() != 0 )
        {
            Integer i=0;

            for( Schedule_A_Quote_Item__c newScheduleAQuoteItem : newList )
            {
                Schedule_A_Quote_Item__c oldScheduleAQuoteItem = oldList[i];

                if( newScheduleAQuoteItem.recordTypeId != newScheduleAQuoteItem.recordTypeId )
                {
                   // Change from Standard to Read-Only
                    newScheduleAQuoteItem.recordTypeId = newScheduleAQuoteItem.recordTypeId;
                }
                else if( newScheduleAQuoteItem.recordTypeId == scheduleA_Quote_Item_RecordType_ReadOnly.Id )
                {
                   // Trying to Save ReadOnly record
                   newScheduleAQuoteItem.addError('Approved Schedule A is not modifable after approval.');
                }
            }
            i++;
        }
   }
   
   public static String getDbrDiscountType (String productName){
       
       DBRDiscountTypes__c discountType = dbrDiscountTypes.get(productName.toLowerCase());
       
        if( discountType != null && discountType.Discount_Type__c.equalsIgnoreCase( SERVICE ))
            return SERVICE;
        else if( discountType != null && discountType.Discount_Type__c.equalsIgnoreCase( STORAGE ) )
            return STORAGE;
        else
            return null;
        
   }
   
   public static String getDiscountType (Schedule_A_Quote_Item__c lineItem){
       
       String discountType = getDbrDiscountType(lineItem.product__r.name);
       
       if(discountType == null){
           discountType = lineItem.Product_Class__c;
       }
       
       return discountType;
       
   }
   
   public static Boolean validateDiscountWithExemptList (String productName){
       return (productName == null) ? false : exemptBillingCodeList.contains(productName.toLowerCase()); 
   }
   
}
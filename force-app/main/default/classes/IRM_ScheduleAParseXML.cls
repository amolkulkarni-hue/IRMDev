/**
 * Name            : IRM_IRM_ScheduleAParseXML
 * Description     : XML Parser for Schedule A PA Files gnerated from Excel PA tool
 *
 * Copyright       : Bluewolf
 * Author          : Chris Matthews
 * Modification Log: Created:26-Oct-2012
 * Modification Log: Created:08-feb-2023:ticket Number:13315
 * Modification Log: Gitlab story #28215. Added errors and warnings to the list
 * Modification Log: Gitlab story #28199. Added code to save 2 new fields from the XML
 * Gitlab story    : 19277 Removed logic related to PA Model Approval process 
 **/
public class IRM_ScheduleAParseXML
{
   private static String ELEMENT_SCHEDULEA_BLOCK                                = 'schedulea';
   private static String ELEMENT_SCHEDULEA_CUSTOMER_NAME                        = 'customername';
    
   //Added as per Gitlab story #28199
   private static string ELEMENT_SCHEDULEA_QUOTE_NUMBER                         = 'QuoteNumber';
   private static string ELEMENT_SCHEDULEA_QUOTE_DESCRIPTION                    = 'QuoteDescription';
    
   private static String ELEMENT_SCHEDULEA_IMGA                                 = 'imga';
   private static String ELEMENT_SCHEDULEA_AWS_REQUEST_ID                       = 'awsrequestid';
   private static String ELEMENT_SCHEDULEA_CUSTOMERIDs                          = 'customerids';
   private static String ELEMENT_SCHEDULEA_TOTAL_REVENUE                        = 'totalrevenue';
   private static String ELEMENT_SCHEDULEA_REVENUE_DELTA                        = 'revenuedelta';
   //Gitlab: 19277 code cleanup private static String ELEMENT_SCHEDULEA_NUM_OF_APPROVERS                     = 'numberofapprovers';
   private static String ELEMENT_SCHEDULEA_MARGIN_DELTA                         = 'margindelta';
   // #30914 PA Model: Clean Up the XML mapping job
   /*private static String ELEMENT_SCHEDULEA_TEMPLATE                             = 'template';
   private static String ELEMENT_SCHEDULEA_MASTER                               = 'master';*/
   /* Gitlab: 19277 code cleanup private static String ELEMENT_SCHEDULEA_APPROVER1                            = 'approver1';
   private static String ELEMENT_SCHEDULEA_APPROVER2                            = 'approver2';
   private static String ELEMENT_SCHEDULEA_APPROVER3                            = 'approver3';
   private static String ELEMENT_SCHEDULEA_APPROVER4                            = 'approver4';
   private static String ELEMENT_SCHEDULEA_APPROVER5                            = 'approver5';
   private static String ELEMENT_SCHEDULEA_APPROVER6                            = 'approver6';
   private static String ELEMENT_SCHEDULEA_APPROVER7                            = 'approver7';
   private static String ELEMENT_SCHEDULEA_APPROVER8                            = 'approver8';
   private static String ELEMENT_SCHEDULEA_APPROVER9                            = 'approver9';
   private static String ELEMENT_SCHEDULEA_APPROVER10                           = 'approver10';
   private static String ELEMENT_SCHEDULEA_APPROVER11                           = 'approver11';
   private static String ELEMENT_SCHEDULEA_APPROVER12                           = 'approver12';*/
   // #30914 PA Model: Clean Up the XML mapping job
   /*private static String ELEMENT_SCHEDULEA_CONTRACT_LENGTH                      = 'contractlength';*/
   private static String ELEMENT_SCHEDULEA_RM_CONTRACT_LENGTH                   = 'rmcontractlength';
   private static String ELEMENT_SCHEDULEA_DM_CONTRACT_LENGTH                   = 'dmcontractlength';
   private static String ELEMENT_SCHEDULEA_SS_CONTRACT_LENGTH                   = 'sscontractlength';
   private static String ELEMENT_SCHEDULEA_LARGEST_MARKET1                      = 'largestmarket1';
   private static String ELEMENT_SCHEDULEA_LARGEST_MARKETVOL1                   = 'largestmarketvolume1';
   private static String ELEMENT_SCHEDULEA_LARGEST_MARKET2                      = 'largestmarket2';
   private static String ELEMENT_SCHEDULEA_LARGEST_MARKETVOL2                   = 'largestmarketvolume2';
   private static String ELEMENT_SCHEDULEA_LARGEST_MARKET3                      = 'largestmarket3';
   private static String ELEMENT_SCHEDULEA_LARGEST_MARKETVOL3                   = 'largestmarketvolume3';
   private static String ELEMENT_SCHEDULEA_CUR_STORAGE_VOL                      = 'currentstoragevolume';
   private static String ELEMENT_SCHEDULEA_CUR_STORAGE_PRICE                    = 'currentstorageprice';
   private static String ELEMENT_SCHEDULEA_NEW_STORAGE_VOLUME                   = 'newstoragevolume';
   private static String ELEMENT_SCHEDULEA_NEW_STORAGE_PRICE                    = 'newstorageprice';
   private static String ELEMENT_SCHEDULEA_CUR_EFFECTIVE_DISC                   = 'currenteffectivediscount';
   private static String ELEMENT_SCHEDULEA_RM_LIST_PRICE_DISCOUNT               = 'rmstoragelistpricediscount';
   private static String ELEMENT_SCHEDULEA_RM_SERVICE_LIST_PRICE_DISCOUNT       = 'rmservicelistpricediscount';
   private static String ELEMENT_SCHEDULEA_ESTIMATED_YEARLY_REVENUE             = 'estimatedyear1revenue';
   private static String ELEMENT_SCHEDULEA_REVENUE_YEAR_TARGET_PRICING          = 'revenueyeartargetpricing';
   private static String ELEMENT_SCHEDULEA_REVENUE_LIST_PRICING                 = 'revenueatlistpricing';
   private static String ELEMENT_SCHEDULEA_TOTAL_CONTRACT_REVENUE               = 'totalcontractrevenue';
   private static String ELEMENT_SCHEDULEA_RM_EFFECTIVE_DISCOUNT                = 'rmeffectivediscount';
   private static String ELEMENT_SCHEDULEA_DBR_STORATE_EFFECTIVE_DISCOUNT       = 'dbrstorageeffectivediscount';
   private static String ELEMENT_SCHEDULEA_DBR_SERVICE_EFFECTIVE_DISCOUNT       = 'dbrserviceeffectivediscount';
   private static String ELEMENT_SCHEDULEA_DBR_STORATE_LIST_PRICE_DISCOUNT      = 'dbrstoragelistpricediscount';
   private static String ELEMENT_SCHEDULEA_DBR_SERVICE_LIST_PRICE_DISCOUNT      = 'dbrservicelistpricediscount';
   private static String ELEMENT_SCHEDULEA_PA_VERSION                           = 'paversion';
   private static String ELEMENT_SCHEDULEA_TOTAL_CASHVIEW_COST                  = 'totalcashbasedcost';
   private static String ELEMENT_SCHEDULEA_RED_FLAG                             = 'redflagitems';
   //case number:01459625
   private static String ELEMENT_SCHEDULEA_LIST_PRICE_YEAR                      = 'listpriceyear';
   private static String ELEMENT_SCHEDULEA_NUMBER_OF_SHRED_LOCATIONS            = 'numberofShredlocations';
   private static string ELEMENT_SCHEDULEA_PRICING_PROMOTIONS                   = 'pricingpromotions';

   private static String ELEMENT_SCHEDULEA_QUOTE_LINES                          = 'quotelines';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM                           = 'quoteitem';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_NUM               = 'productnumber';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_CUR_PRICE         = 'currentprice';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_CUR_VOLUME        = 'currentvolume';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_PROPOSED_PRICE    = 'proposedprice';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_PROPOSED_VOLUME   = 'proposedvolume';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_KEEP_FLAG         = 'keepflag';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_OFFERINGTYPE      = 'offeringtype';
   //case number:01459625
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_LIST_PRICE                = 'listprice';
   
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_1_PRICE              = 'yr1price';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_2_PRICE              = 'yr2price';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_3_PRICE              = 'yr3price';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_4_PRICE              = 'yr4price';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_5_PRICE              = 'yr5price';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_6_PRICE              = 'yr6price';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_7_PRICE              = 'yr7price';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_8_PRICE              = 'yr8price';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_9_PRICE              = 'yr9price';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_10_PRICE             = 'yr10price';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_TARGET_PRICE      = 'targetprice';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_FORECASTABLEFLAG   = 'forecastableflag';
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_CASHVIEW_COST_LINE = 'unitcostcashview';
  
   //14497 to include Floor Price
   
   private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_FLOOR_PRICE       = 'floorprice';
      
   private static String ELEMENT_SCHEDULEA_SHRED_LOCATIONS                      = 'shredlocations';
   private static String ELEMENT_SCHEDULEA_SHRED_LOCATION                       = 'shredlocation';
    // #30914 PA Model: Clean Up the XML mapping job
    /*
   private static String ELEMENT_SCHEDULEA_SHRED_LOCATION_NUM                   = 'location_number';
   private static String ELEMENT_SCHEDULEA_SHRED_DESCRIPTION                    = 'description';
   private static String ELEMENT_SCHEDULEA_SHRED_MARKET                         = 'market';
   private static String ELEMENT_SCHEDULEA_SHRED_NUM_CONTAINERS                 = 'number_containers';
   private static String ELEMENT_SCHEDULEA_SHRED_CONTAINER_TYPE                 = 'container_type';
   private static String ELEMENT_SCHEDULEA_SHRED_SERVICE_TYPE                   = 'service_type';
   private static String ELEMENT_SCHEDULEA_SHRED_FREQENCY                       = 'frequency';
   private static String ELEMENT_SCHEDULEA_DEAL_SUMMARY1                        = 'dealsummary1';
   
   private static String ELEMENT_SCHEDULEA_NONBILL1                             = 'nonbillableterm1';
   private static String ELEMENT_SCHEDULEA_NONBILL2                             = 'nonbillableterm2';
   private static String ELEMENT_SCHEDULEA_NONBILL3                             = 'nonbillableterm3';
   private static String ELEMENT_SCHEDULEA_NONBILL4                             = 'nonbillableterm4';
   private static String ELEMENT_SCHEDULEA_NONBILL5                             = 'nonbillableterm5';
   private static String ELEMENT_SCHEDULEA_NONBILL6                             = 'nonbillableterm6';
   private static String ELEMENT_SCHEDULEA_COST_IRM1                            = 'costtoirm1';
   private static String ELEMENT_SCHEDULEA_COST_IRM2                            = 'costtoirm2';
   private static String ELEMENT_SCHEDULEA_COST_IRM3                            = 'costtoirm3';
   private static String ELEMENT_SCHEDULEA_COST_IRM4                            = 'costtoirm4';
   private static String ELEMENT_SCHEDULEA_COST_IRM5                            = 'costtoirm5';
   private static String ELEMENT_SCHEDULEA_COST_IRM6                            = 'costtoirm6';*/
   private static String ELEMENT_SCHEDULEA_SHRED_REVENUE1                       = 'shredrevenues_1';
   private static String ELEMENT_SCHEDULEA_SHRED_REVENUE2                       = 'shredrevenues_2';
   private static String ELEMENT_SCHEDULEA_SHRED_REVENUE3                       = 'shredrevenues_3';
   private static String ELEMENT_SCHEDULEA_SHRED_REVENUE4                       = 'shredrevenues_4';
   private static String ELEMENT_SCHEDULEA_SHRED_REVENUE5                       = 'shredrevenues_5';
   private static String ELEMENT_SCHEDULEA_SHRED_REVENUE6                       = 'shredrevenues_6';
   private static String ELEMENT_SCHEDULEA_SHRED_REVENUE7                       = 'shredrevenues_7';
   private static String ELEMENT_SCHEDULEA_SHRED_REVENUE8                       = 'shredrevenues_8';
   private static String ELEMENT_SCHEDULEA_SHRED_REVENUE9                       = 'shredrevenues_9';
   private static String ELEMENT_SCHEDULEA_SHRED_REVENUE10                      = 'shredrevenues_10';
    // #30914 PA Model: Clean Up the XML mapping job
   /*
   private static String ELEMENT_SCHEDULEA_REC1                                 = 'recommendations1';
   private static String ELEMENT_SCHEDULEA_REC2                                 = 'recommendations2';
   private static String ELEMENT_SCHEDULEA_REC3                                 = 'recommendations3';
   private static String ELEMENT_SCHEDULEA_REC4                                 = 'recommendations4';
   private static String ELEMENT_SCHEDULEA_UNITS1                               = 'units1';
   private static String ELEMENT_SCHEDULEA_UNITS2                               = 'units2';
   private static String ELEMENT_SCHEDULEA_UNITS3                               = 'units3';
   private static String ELEMENT_SCHEDULEA_UNITS4                               = 'units4';
   private static String ELEMENT_SCHEDULEA_UNITS5                               = 'units5';
   private static String ELEMENT_SCHEDULEA_UNITS6                               = 'units6';
   private static String ELEMENT_SCHEDULEA_DEAL_SUMMARY2                        = 'dealsummary2';
   private static String ELEMENT_SCHEDULEA_DEAL_SUMMARY3                        = 'dealsummary3';
   private static String ELEMENT_SCHEDULEA_DEAL_SUMMARY4                        = 'dealsummary4';*/
   private static String ELEMENT_SCHEDULEA_ADDITIONAL_TERMS1                    = 'additionalterms1';
   private static String ELEMENT_SCHEDULEA_ADDITIONAL_TERMS2                    = 'additionalterms2';
   private static String ELEMENT_SCHEDULEA_ADDITIONAL_TERMS3                    = 'additionalterms3';
   private static String ELEMENT_SCHEDULEA_ADDITIONAL_TERMS4                    = 'additionalterms4';
   private static String ELEMENT_SCHEDULEA_ADDITIONAL_TERMS5                    = 'additionalterms5';
   private static String ELEMENT_SCHEDULEA_ADDITIONAL_TERMS6                    = 'additionalterms6';
   private static String ELEMENT_SCHEDULEA_ADDITIONAL_TERMS7                    = 'additionalterms7';
   private static String ELEMENT_SCHEDULEA_ADDITIONAL_TERMS8                    = 'additionalterms8';
    // #30914 PA Model: Clean Up the XML mapping job
 //  private static String ELEMENT_SCHEDULEA_TIERED_PRICING                       = 'tieredpricing';
 //  private static String ELEMENT_SCHEDULEA_PROGRAM_PRICING                      = 'programpricing';
 //  private static String ELEMENT_SCHEDULEA_BUNDLED_PRICING                      = 'bundledpricing';
   private static String ELEMENT_SCHEDULEA_INCLUDE_CLAWBACK                     = 'includeclawback';
   private static String ELEMENT_SCHEDULEA_RM_MULTI_YEAR_DEAL                   = 'rmmultiyear';
   private static String ELEMENT_SCHEDULEA_RM_FREE_UP_IN                        = 'rmfui';
   private static String ELEMENT_SCHEDULEA_RM_UNVENDED                          = 'rmunvended';
   private static String ELEMENT_SCHEDULEA_RM_PW_FEE_PAID                       = 'rmpwpaid';
   private static String ELEMENT_SCHEDULEA_RM_PROGRAM_PRICING                   = 'rmprogrampricing';
   private static String ELEMENT_SCHEDULEA_RM_TIERED_PRICING                    = 'rmtieredpricing';
   private static String ELEMENT_SCHEDULEA_RM_FREE_STORAGE                      = 'rmfreestorage';
   private static String ELEMENT_SCHEDULEA_RM_FREE_SERVICES                     = 'rmfreeservices';
   private static String ELEMENT_SCHEDULEA_RM_FREE_STORAGEVIA_WA                = 'rmfreestorageviawa';
   private static String ELEMENT_SCHEDULEA_RM_FREE_SERVICESVIA_WA               = 'rmfreeservicesviawa';
   private static String ELEMENT_SCHEDULEA_RM_OTHER                             = 'rmother';
   private static String ELEMENT_SCHEDULEA_DM_MULTI_YEAR_DEAL                   = 'dmmultiyear';
   private static String ELEMENT_SCHEDULEA_DM_TIERED_PRICING                    = 'dmtieredpricing';
   private static String ELEMENT_SCHEDULEA_DM_OTHER                             = 'dmother';
   private static String ELEMENT_SCHEDULEA_SS_MULTI_YEAR_DEAL                   = 'ssmultiyear';
   private static String ELEMENT_SCHEDULEA_SS_TIERED_PRICING                    = 'sstieredpricing';
   private static String ELEMENT_SCHEDULEA_SS_OTHER                             = 'ssother';
   private static String ELEMENT_SCHEDULEA_FINANCING                            = 'financing';
   private static String ELEMENT_SCHEDULEA_REBATE                               = 'rebate';
   private static String ELEMENT_SCHEDULEA_RETROACTIVE                          = 'retroactive';
   private static String ELEMENT_SCHEDULEA_SALES_SEG                            = 'salesseg';
   private static String ELEMENT_SCHEDULEA_INDUSTRY                             = 'industry';
   private static String ELEMENT_SCHEDULEA_RM_PRICE_DECREASE                    = 'rm-pricedecrease';
   private static String ELEMENT_SCHEDULEA_RM_VENDED                            = 'rm-vended';
   private static String ELEMENT_SCHEDULEA_RM_COMPETITION                       = 'rm-competition';
   private static String ELEMENT_SCHEDULEA_DM_PRICE_DECREASE                    = 'dm-pricedecrease';
   private static String ELEMENT_SCHEDULEA_DM_VENDED                            = 'dm-vended';
   private static String ELEMENT_SCHEDULEA_DM_COMPETITION                       = 'dm-competition';
   private static String ELEMENT_SCHEDULEA_SS_PRICE_DECREASE                    = 'ss-pricedecrease';
   private static String ELEMENT_SCHEDULEA_SS_VENDED                            = 'ss-vended';
   private static String ELEMENT_SCHEDULEA_SS_COMPETITION                       = 'ss-competition';
   private static String ELEMENT_SCHEDULEA_TOTAL_MINIMUM_AMOUNT                 = 'newrev';
   
   /* #14450 including Service labour hours, service labour costs, Total Cost*/
   private static String ELEMENT_SCHEDULEA_SERVICE_LABOUR_HOURS                 = 'servicehours';
   private static String ELEMENT_SCHEDULEA_SERVICE_LABOUR_COST                  = 'servicelaborcost';
  /*end of 14450 */
    
  /* #17061 */  
  
  private static String ELEMENT_SCHEDULEA_REVENUE_DILUTION                      = 'revenuedilution';
    
  /*end of #17061 */  
 
    /* #21572 Included Revenue Dilution $*/
  private static String ELEMENT_SCHEDULEA_REVENUE_DOLLAR                        = 'revenuedilutiondollar';
  //end of 21572
  
  /* #26139 Included Revenue Dilution $*/
  private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_LINE_REVENUE       = 'proposedrevenue';
  //end of 26139
  
  private Static String ELEMENT_SCHEDULEA_FLOOR_REVENUE_REALIZATION             = 'floorrevenuerealization' ;
  /* #19532 */
  private Static String ELEMENT_SCHEDULEA_FLOOR_REVENUE                         = 'floorrevenue' ;
  /*end of #19532 */
  //14497 To include Investment $ 
  private static String ELEMENT_SCHEDULEA_INVESTMENT                           = 'investment';
  // #28954 include Totalcost, unitcost
  private static String ELEMENT_SCHEDULEA_TOTAL_COST                           = 'totalcost';
  private static String ELEMENT_SCHEDULEA_QUOTE_ITEM_UNIT_COST                 = 'unitcost';
    // end of #28954

   private static List<String> VALID_CUST_ACCT_SOURCE_SYS                       = new List<String>{'SKP NA', 'SB NA'};
   private static String PRICEBOOK_NA                                           = System.Label.PA_MODEL_PRICE_BOOK;//'North America';
   private static String Billcode                                               = 'Bill_Code';
   private static PriceBook2  pbeBook                                           = [ select id, name
                                                                                    from pricebook2
                                                                                    where name=:PRICEBOOK_NA ];
   
   
   
   private static String ELEMENT_CURRENCY                                       = 'currency';
   private static String CURRENCY_VALUE_FROM_XML;
    //made changes for #17520
   private static String baseVersionNumber{
    get{
        if(baseVersionNumber == null){
            baseVersionNumber = BaseVersionNumber__c.getOrgDefaults().Version__c;   
        } return baseVersionNumber;
    }set;
   }
   
   public static Set<String> INVALID_ACCOUNTS = new Set<String>(); 
   @TestVisible static Boolean PA_MODEL_OK=false;
    
   //Added variables for the Gitlab#28215
   public static String INVOCATION_CONTEXT='';
   public static List<String> ERROR_LIST= NEW List<String>();
   public static List<String> WARNING_LIST= NEW List<String>();
    
   /**
       <?xml version="1.0" encoding="UTF-8"?>
       <schedulea>
          <currency>USD</currency>
          <customername>ACME</customername>
          <imga>IM_Customer</imga>
          <pricingpromotions></pricingpromotions>
          <awsrequestid>0</awsrequestid>
          <customerids>adfe2,31fd,21wda</customerids>
          <totalrevenue>$213.98</totalrevenue>
          <revenuedelta>-$190.00</revenuedelta>
          <numberofapprovers>4</<numberofapprovers>
          <margindelta>$673.42</margindelta>
          <listpriceyear>2013</listpriceyear>
          <numberofShredlocations>5</numberofShredlocations>
          <approver1>Opportunity Owner</approver1>
          <approver2>RDM</approver2>
          <approver3>VP</approver3>
          <approver4></approver4>
          <approver5></approver5>
          <approver6></approver6>
          <approver7></approver7>
          <approver8></approver8>
          <approver9></approver9>
          <approver10></approver10>
          <approver11></approver11>
          <approver12></approver12>
          <approver13></approver13>
          <approver14></approver14>
          <approver15></approver15>
          <approver16></approver16>
          <approver17></approver17>
          <approver18></approver18>
          <contractlength>3</contractlength>
          <largestmarket1>Atlanta, GA</largestmarket1>
          <largestmarketvolume1>10000</largestmarketvolumn1>
          <largestmarket2>Albany, NY</largestmarket2>
          <largestmarketvolume2>7500</largestmarketvolumn2>
          <largestmarket3>Baltimore,MD</largestmarket3>
          <largestmarketvolume3>5000</largestmarketvolumn3>
          <currentstoragevolume>20000</currentstoragevolume>
          <currentstorageprice>0.123</currentstorageprice>
          <newstoragevolume>10000</newstoragevolume>
          <newstorageprice>0.234</newstorageprice>
          <currenteffectivediscount>54%</currenteffectivediscount>
          <RMlistpricediscount>60%</RMlistpricediscount>
          <estimatedyear1revenue>$144000</estimatedyear1revenue>
          <revenueyeartargetpricing>$150000</revenueyeartargetpricing>
          <revenueatlistpricing>$147500</revenueatlistpricing>
          <totalcontractrevenue>450000</totalcontractrevenue>
          <RMEffectiveDiscount>0</RMEffectiveDiscount>
          <DBRStorageEffectiveDiscount>0</DBRStorateEffectiveDiscount>
          <DBRServiceEffectiveDiscount>0</DBRServiceEffectiveDiscount>
          <DBRStoragelistpricediscount>0</DBRStoratelistpricediscount>
          <DBRServicelistpricediscount>0</DBRServicelistpricediscount>
          <PAVersion>8.0.1</PAVersion>
          <shredlocations>
            <shredlocation>
                <Description>Headquarters</Description>
                <Market>Boston</Market>
                <Number_Containers>5</Number_Containers>
                <Container_Type>Console</Container_Type>
                <Service_Type>Staged</Service_Type>
                <Frequency>2 Weeks</Frequency>
           </shredlocation>
          </shredlocations>
          <quoteLines>
             <quoteItem>
                 <productNumber>PR00010101</productNumber>
                 <price>.0234</price>
                 <volume>10000</volume>
                 <offeringType>test1</offeringType>
                 <listprice>44.0</listprice>
             </quoteItem>
             <quoteItem>
                 <productNumber>PR00010102</productNumber>
                 <price>.0244</price>
                 <volume>10000</volume>
                 <offeringType>test1</offeringType>
                 <listprice>44.0</listprice>
             </quoteItem>
             <quoteItem>
                 <productNumber>PR00010103</productNumber>
                 <price>.0255</price>
                 <volume>10000</volume>
                 <offeringType>test1</offeringType>
                 <listprice>44.0</listprice>
             </quoteItem>
          </quoteLines>
       </schedulea>
   **/
   
   public static Schedule_A__c parseXML( String referenceName,
                                         String xml,
                                         String opportunityId )
   {
       Schedule_A__c scheduleA = null;
      //Gitlab: 19277 code cleanup List<String> approverList = new List<String>();

      try
       {
           if( xml != null && xml != '')
           {
               // Fetch the opportunity information
               Opportunity opportunity = [ select id, name, accountid, ownerId,CurrencyIsoCode
                                           from Opportunity
                                           where id=:opportunityId ];

               System.debug('XML String: ' + xml);
               XmlStreamReader reader1 = new XmlStreamReader(xml);
               /*Case number: 01495436
                 Description: Checking currency match with opportunity currency
               */

               while(reader1.hasNext()){
                // Increment Next
                  reader1.next();
                  String localName;
                  if( reader1.getEventType() == XmlTag.START_ELEMENT || reader1.getEventType() == XmlTag.END_ELEMENT || reader1.getEventType() == XmlTag.ENTITY_REFERENCE  )
                    localName = reader1.getLocalName();
                  if( localName != null )
                  {
                     //System.debug('LocalName [' + localName + ']');

                     localName = localName.toLowerCase();
                     if( reader1.getEventType() == XmlTag.START_ELEMENT )
                     {
                           //added condition to check currency
                         if( localName == ELEMENT_CURRENCY )
                         {
                             CURRENCY_VALUE_FROM_XML = getValue( reader1, null );
                         }
                         //added condition to check PA model(#17520)
                         if(localName== ELEMENT_SCHEDULEA_PA_VERSION){
                           String versionNumber = getValue(reader1, null);
                           PA_MODEL_OK = (compareVersionNumbers(versionNumber, baseVersionNumber) != -1);
                         }
                         if(CURRENCY_VALUE_FROM_XML!=null && PA_MODEL_OK){
                            system.debug('+++++++++inside the break condition++++');
                            break;
                         }
                     }


                  }
               }
               if(CURRENCY_VALUE_FROM_XML!=opportunity.CurrencyIsoCode){
                   //Added function call and commented old code - Gitlab story#28215
                   addMessage('error',System.Label.Currency_Noted_Does_Not_Match);
                   
                     /*ApexPages.Message myMsg =
                       new ApexPages.Message( ApexPages.Severity.ERROR,
                                             System.Label.Currency_Noted_Does_Not_Match);
                    ApexPages.addMessage(myMsg);*/
               }
               //added condition to throw error if PA Model version is less than the baseversion(#17520)
              else if(!PA_MODEL_OK){
                  //Added function call and commented old code - Gitlab story#28215
                  addMessage('error',String.format(System.Label.PA_Model_Older_Version_Alert,new List<String>{String.valueOf(baseVersionNumber)}));
                     /*ApexPages.Message myMsg =
                       new ApexPages.Message( ApexPages.Severity.ERROR,String.format(System.Label.PA_Model_Older_Version_Alert,new List<String>{String.valueOf(baseVersionNumber)}));
                                             //System.Label.PA_Model_Older_Version_Alert);
                    ApexPages.addMessage(myMsg);*/
               }
               else{

                 XmlStreamReader reader = new XmlStreamReader(xml);

                while(reader.hasNext())
                 {
                  // Increment Next
                  reader.next();
                  String localName;
                  if( reader.getEventType() == XmlTag.START_ELEMENT || reader.getEventType() == XmlTag.END_ELEMENT || reader.getEventType() == XmlTag.ENTITY_REFERENCE  )
                    localName = reader.getLocalName();


                  if( localName != null )
                  {
                     //System.debug('LocalName [' + localName + ']');

                     localName = localName.toLowerCase();

                     if( reader.getEventType() == XmlTag.START_ELEMENT )
                     {
                        if( localName == ELEMENT_SCHEDULEA_BLOCK )
                        {   system.debug('+++++++executing to intialize schedule a++');
                           // New Schedule A
                           scheduleA = new Schedule_A__c();
                           scheduleA.Reference__c =  referenceName;
                        }

                        /*Case Number : 01495436
                          Description : added element currency to xml
                        */
                        else if( localName == ELEMENT_CURRENCY )
                         {
                             CURRENCY_VALUE_FROM_XML = getValue( reader, null );
                             scheduleA.currencyIsoCode=CURRENCY_VALUE_FROM_XML;
                             system.debug('++++++++++++currency value+++++++'+CURRENCY_VALUE_FROM_XML);
                         }
                        /*Gitlab: 19277 code cleanup else if(SCHEDULE_A_APPROVER_FIELDS.contains(localName) ) {
                             String approver = getValue( reader, null );
                             if( approver != null && approver != '') {
                                 approverList.add(approver);
                             }
                         }*/ else if ( SCHEDULE_A_XML_TO_DECIMAL.containsKey(localName) ) {
                             Decimal value = toDecimal( reader );
                             if(value != null) {
                                 if(localName != ELEMENT_SCHEDULEA_REVENUE_DILUTION )
                                 {
                                 scheduleA.put(SCHEDULE_A_XML_TO_DECIMAL.get(localName), value);
                             }
                             else
                             {
                                 scheduleA.put(SCHEDULE_A_XML_TO_DECIMAL.get(localName), (value*100));
                             }
                             }
                         } else if ( SCHEDULE_A_XML_TO_FIELD_VALUE.containsKey(localName) ) {
                             scheduleA.put(SCHEDULE_A_XML_TO_FIELD_VALUE.get(localName), getValue( reader, null ));
                         } else if ( SCHEDULE_A_XML_TO_BOOLEAN.containsKey(localName) ) {
                             boolean value = toBoolean( reader);
                             if(value != null) {
                                 scheduleA.put(SCHEDULE_A_XML_TO_BOOLEAN.get(localName), value);
                             }
                         } else if (SCHEDULE_A_XML_SET_VALUE.containsKey(localName)) {
                             setScheduleAValue( scheduleA, SCHEDULE_A_XML_SET_VALUE.get(localName), reader, null);
                         }
                         
                        else if( localName == ELEMENT_SCHEDULEA_CUSTOMER_NAME )
                        {
                            scheduleA.Customer_Name__c = getValue( reader, null );
                        }
                         
                        //Save new fields per Gitlab story #28199
                        else if(localName == ELEMENT_SCHEDULEA_QUOTE_NUMBER )
                        {
                            scheduleA.Quote_Number__c = getValue( reader, null );
                        } 
                        else if(localName == ELEMENT_SCHEDULEA_QUOTE_DESCRIPTION)
                        {
                            scheduleA.Quote_Description__c = getValue( reader, null );
                        } 
                         
                        /*else if( localName == ELEMENT_SCHEDULEA_SALES_SEG )
                        {
                            scheduleA.Salesseg__c = getValue( reader, null );
                        }
                        else if( localName == ELEMENT_SCHEDULEA_INDUSTRY )
                        {
                            scheduleA.Industry__c = getValue( reader, null );
                        }
                        else if( localName == ELEMENT_SCHEDULEA_IMGA )
                        {
                            scheduleA.IMGA__c = getValue( reader, null );
                        }
                        else if( localName == ELEMENT_SCHEDULEA_AWS_REQUEST_ID )
                        {
                            scheduleA.AWSRequestID__c = getValue( reader, null );
                        }*/
                        else if( localName == ELEMENT_SCHEDULEA_CUSTOMERIDs )
                        {
                            scheduleA.CustomerIds__c = getValue( reader, null );
                        }
                        else if( localName == ELEMENT_SCHEDULEA_TOTAL_REVENUE )
                        {
                            scheduleA.Total_Revenue__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_REVENUE_DELTA )
                        {
                            scheduleA.Revenue_Delta__c = toDecimal( reader );
                        }
                       /*Gitlab: 19277 code cleanup else if ( localName == ELEMENT_SCHEDULEA_NUM_OF_APPROVERS )
                        {
                            scheduleA.Number_of_Approvers__c = toDecimal( reader );
                        }*/
                        /*
                        else if ( localName == ELEMENT_SCHEDULEA_TEMPLATE )
                        {
                            scheduleA.istemplate__c = toBoolean( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_MASTER )
                        {
                            scheduleA.isMaster__c = toBoolean( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_NUM_OF_APPROVERS )
                        {
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_MARGIN_DELTA )
                        {
                            scheduleA.Margin_Delta__c = toDecimal( reader );
                        }
                        //case :01459625
                         else if ( localName == ELEMENT_SCHEDULEA_LIST_PRICE_YEAR )
                        {
                            scheduleA.List_Price_Year__c = toDecimal( reader );
                        }
                         else if ( localName == ELEMENT_SCHEDULEA_NUMBER_OF_SHRED_LOCATIONS )
                        {
                            scheduleA.Number_of_Shred_Locations__c= toDecimal( reader );
                        }
                        //pricing promotions
                        else if ( localName == ELEMENT_SCHEDULEA_PRICING_PROMOTIONS )
                        {
                            scheduleA.Pricing_Promotions__c= getValue( reader,null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER1 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER2 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER3)
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER4 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER5 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER6 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER7 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER8 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER9 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER10 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER11 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_APPROVER12 )
                        {
                            String approver = getValue( reader, null );
                            if( approver != null && approver != '')
                                approverList.add(approver);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_CONTRACT_LENGTH )
                        {
                            scheduleA.Contract_Length__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_LARGEST_MARKET1 )
                        {
                            scheduleA.Largest_Market_1__c = getValue( reader, null );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_LARGEST_MARKETVOL1 )
                        {
                            scheduleA.Largest_Market_Volume_1__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_LARGEST_MARKET2 )
                        {
                            scheduleA.Largest_Market_2__c = getValue( reader, null );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_LARGEST_MARKETVOL2 )
                        {
                            scheduleA.Largest_Market_Volume_2__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_LARGEST_MARKET3 )
                        {
                            scheduleA.Largest_Market_3__c = getValue( reader, null );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_LARGEST_MARKETVOL3 )
                        {
                            scheduleA.Largest_Market_Volume_3__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_CUR_STORAGE_VOL )
                        {
                            scheduleA.Current_Storage_Volume__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_CUR_STORAGE_PRICE )
                        {
                            scheduleA.Current_Storage_Price__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_NEW_STORAGE_VOLUME )
                        {
                            scheduleA.New_Storage_Volume__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_NEW_STORAGE_PRICE )
                        {
                            scheduleA.New_Storage_Price__c = toDecimal( reader ) ;
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_CUR_EFFECTIVE_DISC )
                        {
                            scheduleA.Current_Effective_Discount__c = toDecimal( reader );
                        }
                        {
                            scheduleA.RM_List_Price_Discount__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_RM_SERVICE_LIST_PRICE_DISCOUNT )
                        {
                            scheduleA.RM_Service_List_Price_Discount__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_ESTIMATED_YEARLY_REVENUE )
                        {
                            scheduleA.Estimated_Year_1_Revenue__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_REVENUE_YEAR_TARGET_PRICING )
                        {
                            scheduleA.Revenue_Year_Target_Pricing__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_REVENUE_LIST_PRICING )
                        {
                            scheduleA.Revenue_at_List_Pricing__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_TOTAL_CONTRACT_REVENUE )
                        {
                            scheduleA.Total_Contract_Revenue__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_RM_EFFECTIVE_DISCOUNT )
                        {
                            scheduleA.RM_Effective_Discount__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_DBR_STORATE_EFFECTIVE_DISCOUNT )
                        {
                            scheduleA.DBR_Storate_Effective_Discount__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_DBR_SERVICE_EFFECTIVE_DISCOUNT )
                        {
                            scheduleA.DBR_Service_Effective_Discount__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_DBR_STORATE_LIST_PRICE_DISCOUNT )
                        {
                            scheduleA.DBR_Storate_List_Price_Discount__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_DBR_SERVICE_LIST_PRICE_DISCOUNT )
                        {
                            scheduleA.DBR_Service_List_Price_Discount__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_PA_VERSION )
                        {
                            scheduleA.pa_version__c = getValue( reader, null );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_DEAL_SUMMARY1 )
                        {
                            setScheduleAValue( scheduleA, 'Pricing_Strategy__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_NONBILL1 )
                        {
                            setScheduleAValue( scheduleA, 'Non_Billable_Deal_Term1__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_NONBILL2 )
                        {
                            setScheduleAValue( scheduleA, 'Non_Billable_Deal_Term2__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_NONBILL3 )
                        {
                            setScheduleAValue( scheduleA, 'Non_Billable_Deal_Term3__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_NONBILL4 )
                        {
                            setScheduleAValue( scheduleA, 'Non_Billable_Deal_Term4__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_NONBILL5 )
                        {
                            setScheduleAValue( scheduleA, 'Non_Billable_Deal_Term5__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_NONBILL6 )
                        {
                            setScheduleAValue( scheduleA, 'Non_Billable_Deal_Term6__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_COST_IRM1 )
                        {
                           scheduleA.Cost_to_IRM1__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_COST_IRM2 )
                        {
                            scheduleA.Cost_to_IRM2__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_COST_IRM3 )
                        {
                            scheduleA.Cost_to_IRM3__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_COST_IRM4 )
                        {
                            scheduleA.Cost_to_IRM4__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_COST_IRM5 )
                        {
                            scheduleA.Cost_to_IRM5__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_COST_IRM6 )
                        {
                            scheduleA.Cost_to_IRM6__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_REC1 )
                        {
                            setScheduleAValue( scheduleA, 'Pricing_Recommendations1__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_REC2 )
                        {
                            setScheduleAValue( scheduleA, 'Pricing_Recommendations2__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_REC3 )
                        {
                            setScheduleAValue( scheduleA, 'Pricing_Recommendations3__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_REC4 )
                        {
                            setScheduleAValue( scheduleA, 'Pricing_Recommendations4__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_UNITS1 )
                        {
                            setScheduleAValue( scheduleA, 'Units1__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_UNITS2 )
                        {
                            setScheduleAValue( scheduleA, 'Units2__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_UNITS3 )
                        {
                            setScheduleAValue( scheduleA, 'Units3__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_UNITS4 )
                        {
                            setScheduleAValue( scheduleA, 'Units4__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_UNITS5 )
                        {
                            setScheduleAValue( scheduleA, 'Units5__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_UNITS6 )
                        {
                            setScheduleAValue( scheduleA, 'Units6__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_DEAL_SUMMARY2 )
                        {
                            setScheduleAValue( scheduleA, 'Deal_Summary2__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_DEAL_SUMMARY3 )
                        {
                            setScheduleAValue( scheduleA, 'Deal_Summary3__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_DEAL_SUMMARY4 )
                        {
                            setScheduleAValue( scheduleA, 'Deal_Summary4__c', reader, null);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_TIERED_PRICING )
                        {
                            scheduleA.Tiered_Pricing__c = toBoolean( reader);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_PROGRAM_PRICING )
                        {
                            scheduleA.Program_Pricing__c = toBoolean( reader);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_BUNDLED_PRICING )
                        {
                            scheduleA.Bundled_Pricing__c = toBoolean( reader);
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_INCLUDE_CLAWBACK )
                        {
                            scheduleA.include_Clawback__c = toBoolean( reader);
                        }
                        */
                        else if ( localName == ELEMENT_SCHEDULEA_SHRED_LOCATIONS )
                        {
                            // Create initial list
                            // Commenting below block to Decommissioning of Shred Location Object and its fields as per story #30915
                            /*List<Schedule_A_Shred_Location__c> shredItemList =
                                                           new List<Schedule_A_Shred_Location__c>();*/

                            // If Schedule A is not a generic template
                            // assign the schedule to an opportunity and account hiarchy
                            if( scheduleA.IsTemplate__c == false )
                            {
                               scheduleA.Opportunity__c = opportunity.id;
                               scheduleA.Account__c     = opportunity.AccountId;
                            }

                            // Save the schedule A
                            upsert scheduleA;

                            // Loop through shred items
                            // Commenting below block to Decommissioning of Shred Location Object and its fields as per story #30915
                           /* processShredLocations( reader,
                                                   scheduleA,
                                                   shredItemList );

                            // Insert shred item list
                            if( shredItemList != null && shredItemList.size() != 0 )
                            {
                                //System.debug('Shred Items [' + shredItemList + ']' );

                                // Map names to approvers
                             //Gitlab: 19277 code cleanup   updateApprovers( scheduleA,
                                                 //opportunity,
                                                 //approverList );

                                insert shredItemList;
                            }*/
                            //System.debug('LEAVING SHRED [' + localName + ']' );
                        }

                        // Insert the current schedule A
                        else if ( localName == ELEMENT_SCHEDULEA_QUOTE_LINES )
                        {
                            //System.debug('PROCESSING LocalName [' + localName + ']');
                            // Map names to approvers
                           //Gitlab: 19277 code cleanup updateApprovers( scheduleA,
                                             //opportunity,
                                             //approverList );

                            // If Schedule A is not a generic template
                            // assign the schedule to an opportunity and account hiarchy
                            if( scheduleA.IsTemplate__c == false )
                            {
                               scheduleA.Opportunity__c = opportunity.id;
                               scheduleA.Account__c     = opportunity.AccountId;
                            }

                            // Save the schedule A
                            upsert scheduleA;

                            //System.debug('Schedule A Info [' + scheduleA + ']' );
                            List<Schedule_A_Quote_Item__c> quoteItemList =
                                                           new List<Schedule_A_Quote_Item__c>();

                            // Loop through quote items
                            processQuoteItems( reader,
                                               scheduleA,
                                               quoteItemList );

                            // Insert list of quote items
                            if( quoteItemList != null && quoteItemList.size() != 0 )
                            {
                               //System.debug('Quote Items [' + quoteItemList + ']' );

                               // Validate PA pricecode with Pricebook
                               List<Schedule_A_Quote_Item__c> validQuoteItemList =
                                         populateQuoteItemPricebookEntries(quoteItemList);

                               //System.debug('Quote Items Before [' + quoteItemList + ']' );

                               system.debug('++++++++quote line items++++++++'+validQuoteItemList);
                                  // Insert product set
                               insert validQuoteItemList;

                               //System.debug('Quote Items After [' + quoteItemList + ']' );
                            }
                            else
                            {
                               //Added function call and commented old code - Gitlab story#28215 
                               addMessage('warning',System.Label.No_pricing_info_found + '\n');
                               /*ApexPages.Message myMsg =
                                         new ApexPages.Message( ApexPages.Severity.WARNING,
                                                                    System.Label.No_pricing_info_found + '\n');
                               ApexPages.addMessage(myMsg);*/
                            }

                            // Process Schedule A Customer Associations
                            if( scheduleA.CustomerIds__c != null )
                            {
                                processCustomerAssociations( scheduleA );
                                  
                            }
                        }
                     }
                  }
               }
             }
           }
           else
           {
              //Added function call and commented old code - Gitlab story#28215 
              addMessage('error',System.Label.PA_XML_File_Invalid + '\n');
              /*ApexPages.Message myMsg =
                       new ApexPages.Message( ApexPages.Severity.ERROR,
                                             System.Label.PA_XML_File_Invalid + '\n');
              ApexPages.addMessage(myMsg);*/
           }
       }
       catch( Exception e )
        {
          System.debug( e );
          //Added function call and commented old code - Gitlab story#28215
          addMessage('error',System.Label.Error_occured_processing_PA_File + '\n');
          /*ApexPages.Message myMsg =
                   new ApexPages.Message( ApexPages.Severity.ERROR,
                                         System.Label.Error_occured_processing_PA_File + '\n' +
                                         e );
          ApexPages.addMessage(myMsg);*/
       }
       return(scheduleA);
   }
    
    private static void setScheduleAValue( Schedule_A__c scheduleA, String fieldName, XmlStreamReader reader, String defaultValue)
    {
        String val = getValue( reader, defaultValue );                            
        
        if( val == '0'){
            scheduleA.put( fieldName, null );
        }   
        else if( val != null )
            scheduleA.put( fieldName, val );
    }

   private static List<Schedule_A_Quote_Item__c>
                  populateQuoteItemPricebookEntries( List<Schedule_A_Quote_Item__c> quoteItemList )
   {
       List<Schedule_A_Quote_Item__c> returnQuoteList  = new List<Schedule_A_Quote_Item__c>();
       List<String>                   productCodeList  = new List<String>();
       List<PricebookEntry>           pbeList          = new List<PricebookEntry>();
       Map<String,PricebookEntry>     pbeMap           = new Map<String,PricebookEntry>();

       try
       {
           String test = '';
           for( Schedule_A_Quote_Item__c quoteItem : quoteItemList )
           {
               if( quoteItem.product_number__c != null &&
                   quoteItem.product_number__c != '' )
               {
                  productCodeList.add( quoteItem.product_number__c );
               }
           }

           //System.debug('Product Code List ' + productCodeList + ' And Test ' + test );

           // Query Product Information
           //System.debug('PBE Code List: ' + productCodeList );

            /*Case number: 01495436
              Description: getting pricebook entry matches with opportunity currency
            */
           
           /*   #Gitlab story: 16321
                Adding a condition to fetch only products with record type as Bill code
            */
           system.debug('++++++++currency from XML+++++++'+CURRENCY_VALUE_FROM_XML);
           pbeList = [
                        select id, name, productcode, pricebook2.name,
                               product2id
                        from pricebookentry
                        where IsActive=true
                        and pricebook2.name=:PRICEBOOK_NA
                        and name in :productCodeList  and CurrencyIsoCode=:CURRENCY_VALUE_FROM_XML and product2.recordtype.developername=:Billcode
                     ];

           system.debug('+++++++++++price book entries++++++++++'+pbeList);

           if( pbeList != null )
           {
               //System.debug('PBE List Count [' + pbeList.size() +
                //            '] Values [' + pbeList + ']');

               for( PriceBookEntry pbe : pbeList )
                    pbeMap.put(pbe.name, pbe);

               for( Schedule_A_Quote_Item__c quoteItem : quoteItemList )
               {
                  PricebookEntry pbe = pbeMap.get( quoteItem.product_number__c );

                  if( pbe != null )
                  {
                      if( quoteItem.keep_flag__c == true )
                      {
                          //System.debug('PBE Map [' + quoteItem.product_number__c + '] to PBE [' + pbe + ']');
                          quoteItem.currencyisocode=CURRENCY_VALUE_FROM_XML;
                          quoteItem.PBE__c     = pbe.id;
                          quoteItem.Product__c = pbe.Product2Id;

                          returnQuoteList.add(quoteItem);
                      }
                      else
                      {
                          //System.debug('PBE Skip (Keep=False) [' + quoteItem.product_number__c + ']');

                          // Ignore $0 entries in the file based on business
                          // requirements
                          //ApexPages.Message myMsg =
                          //         new ApexPages.Message( ApexPages.Severity.WARNING,
                          //                               'Ignore NOKEEP products [ ' + quoteItem.product_number__c + ' ]\n');
                          //ApexPages.addMessage(myMsg);
                      }
                  }
                  else
                  {
                      System.debug('PBE NOT FOUND[' + quoteItem.product_number__c + ']');
                      //Added function call and commented old code - Gitlab story#28215
                      addMessage('warning','Product [ ' + quoteItem.product_number__c + ' ] is not associated with '+ pbeBook.name + ' pricebook. Product ignored.\n');
                      /*ApexPages.Message myMsg =
                               new ApexPages.Message( ApexPages.Severity.WARNING,
                                                     'Product [ ' + quoteItem.product_number__c + ' ] is not associated with '+ pbeBook.name + ' pricebook. Product ignored.\n');
                      ApexPages.addMessage(myMsg);*/
                  }
               }
           }
           else
           {
               //Added function call and commented old code - Gitlab story#28215
               addMessage('warning',System.Label.Pricebook_Entries_result_is_empty+'\n');
               /*ApexPages.Message myMsg =
                         new ApexPages.Message( ApexPages.Severity.WARNING,
                                                 System.Label.Pricebook_Entries_result_is_empty+'\n');
               ApexPages.addMessage(myMsg);*/
           }
       }
       catch( Exception e )
       {
           //Added function call and commented old code - Gitlab story#28215
           addMessage('error','PA products not found in [' + pbeBook.name + '] pricebooks.\n\r' + e);
           /*ApexPages.Message myMsg =
                    new ApexPages.Message( ApexPages.Severity.ERROR,
                                          'PA products not found in [' + pbeBook.name + '] pricebooks.\n\r' + e );
           ApexPages.addMessage(myMsg);*/
       }
       return(returnQuoteList);
   }

   private static void processQuoteItems( XmlStreamReader reader,
                                          Schedule_A__c scheduleA,
                                          List<Schedule_A_Quote_Item__c> quoteItemList )
   {

      String localName;
      if( reader.getEventType() == XmlTag.START_ELEMENT || reader.getEventType() == XmlTag.END_ELEMENT || reader.getEventType() == XmlTag.ENTITY_REFERENCE  )
        localName = reader.getLocalName().toLowerCase();
      //String localName = reader.getLocalName().toLowerCase();
      //System.debug(localName);

      //System.debug('LOCAL NAME ----- ' + localName );

      if( reader.getEventType() == XmlTag.START_ELEMENT &&
          localName == ELEMENT_SCHEDULEA_QUOTE_LINES )
      {
          Schedule_A_Quote_Item__c quoteItem = null;

          while( reader.hasNext() )
          {
              // Increment Next
              reader.next();
              if( reader.getEventType() == XmlTag.START_ELEMENT || reader.getEventType() == XmlTag.END_ELEMENT || reader.getEventType() == XmlTag.ENTITY_REFERENCE  )
                  localName = reader.getLocalName();

              if( localName != null )
              {
                 localName = localName.toLowerCase();

                 if( reader.getEventType() == XmlTag.START_ELEMENT )
                 {
                     if( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM )
                     {
                         //System.debug('NEW QUOTE ITEM');
                         quoteItem = new Schedule_A_Quote_Item__c();
                         quoteItem.Schedule_A__c = scheduleA.id;
                     }
                     else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_NUM )
                     {
                         quoteItem.Product_Number__c = getValue( reader, '' );
                         
                     }
                     else if ( SCHEDULE_A_ITEM_XML_TO_DECIMAL.containsKey(localName) ) {
                         Decimal value = toDecimal( reader );
                         if(value != null) {
                             quoteItem.put(SCHEDULE_A_ITEM_XML_TO_DECIMAL.get(localName), value);
                         }
                     }
                     else if ( SCHEDULE_A_ITEM_XML_TO_BOOLEAN.containsKey(localName) ) {
                         boolean value = toBoolean( reader);
                         if(value != null) {
                             quoteItem.put(SCHEDULE_A_ITEM_XML_TO_BOOLEAN.get(localName), value);
                         }
                     } else if ( SCHEDULE_A_ITEM_XML_SET_VALUE.containsKey(localName)) {
                         String value = getValue( reader, null );
                         if(value != null) {
                             quoteItem.put(SCHEDULE_A_ITEM_XML_SET_VALUE.get(localName), value);
                         }
                     }
                    /* else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_PROPOSED_PRICE )
                     {
                         quoteItem.Proposed_Price__c = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_PROPOSED_VOLUME )
                      {
                         quoteItem.Proposed_Volume__c = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_CUR_PRICE )
                      {
                         quoteItem.Current_Price__c = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_CUR_VOLUME )
                      {
                         quoteItem.Current_Volume__c = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_KEEP_FLAG )
                      {
                         quoteItem.keep_flag__c = toBoolean( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_OFFERINGTYPE )
                      {
                         quoteItem.Offering_Type__c = getValue( reader, null );
                      }
                      //case number:01459625
                      else if(localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_LIST_PRICE){
                          quoteItem.List_Price__c = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_2_PRICE){
                          quoteItem.Proposed_Price_Year_2__c    = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_3_PRICE){
                          quoteItem.Proposed_Price_Year_3__c    = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_4_PRICE){
                          quoteItem.Proposed_Price_Year_4__c    = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_5_PRICE){
                          quoteItem.Proposed_Price_Year_5__c    = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_6_PRICE){
                          quoteItem.Proposed_Price_Year_6__c    = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_7_PRICE){
                          quoteItem.Proposed_Price_Year_7__c    = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_8_PRICE){
                          quoteItem.Proposed_Price_Year_8__c    = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_9_PRICE){
                          quoteItem.Proposed_Price_Year_9__c    = toDecimal( reader );
                      }
                      else if ( localName == ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_10_PRICE){
                          quoteItem.Proposed_Price_Year_10__c    = toDecimal( reader );
                      }
                      //end
                      */
                  }
                  else if( reader.getEventType() == XmlTag.END_ELEMENT &&
                           localName == ELEMENT_SCHEDULEA_QUOTE_ITEM )
                  {
                      //System.debug('END TAG [' + localName + ']');
                      //System.debug('Adding Quote Item [' + quoteItem + ']');
                      quoteItemList.add( quoteItem );
                  }
                  else if(  reader.getEventType() == XmlTag.END_ELEMENT &&
                            localName == ELEMENT_SCHEDULEA_QUOTE_LINES )
                  {
                      //System.debug('END TAG [' + localName + ']');
                      //System.debug('End of Quote Locations');
                      break;
                  }
                  else
                  {
                      // skip
                  }
              }
          }
      }
   }
   
   // Commenting below private method block "processShredLocations" as per story #30915
   // Decommissioning of Shred Location Object and its fields
   /*private static void processShredLocations( XmlStreamReader reader,
                                              Schedule_A__c scheduleA,
                                              List<Schedule_A_Shred_Location__c> shredItemList )
   {
    String localName;
      if( reader.getEventType() == XmlTag.START_ELEMENT || reader.getEventType() == XmlTag.END_ELEMENT || reader.getEventType() == XmlTag.ENTITY_REFERENCE  )
        localName = reader.getLocalName().toLowerCase();

      //System.debug(localName);

      //System.debug('LOCAL NAME ----- ' + localName );

      if( reader.getEventType() == XmlTag.START_ELEMENT &&
          localName == ELEMENT_SCHEDULEA_SHRED_LOCATIONS )
      {
           Schedule_A_Shred_Location__c shredLocationItem = null;

           while( reader.hasNext() )
           {
               // Increment Next
               reader.next();
               if( reader.getEventType() == XmlTag.START_ELEMENT || reader.getEventType() == XmlTag.END_ELEMENT || reader.getEventType() == XmlTag.ENTITY_REFERENCE  )
                  localName = reader.getLocalName();

               if( localName != null )
               {
                   localName = localName.toLowerCase();

                   if( reader.getEventType() == XmlTag.START_ELEMENT )
                   {
                        if( localName == ELEMENT_SCHEDULEA_SHRED_LOCATION )
                        {
                           //System.debug('NEW SHRED LOCATION');
                           shredLocationItem = new Schedule_A_Shred_Location__c();
                           shredLocationItem.Schedule_A__c = scheduleA.id;
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_SHRED_LOCATION_NUM )
                        {
                            shredLocationItem.Location_Num__c = getValue( reader, '' );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_SHRED_DESCRIPTION )
                        {
                            shredLocationItem.Service_Location_Description__c = getValue( reader, '' );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_SHRED_MARKET )
                        {
                            shredLocationItem.Market_Selection__c = getValue( reader, '' );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_SHRED_NUM_CONTAINERS )
                        {
                            shredLocationItem.Number_of_Containers_at_Site__c = toDecimal( reader );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_SHRED_CONTAINER_TYPE )
                        {
                            shredLocationItem.Container_Type__c = getValue( reader, '' );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_SHRED_SERVICE_TYPE )
                        {
                            shredLocationItem.Service_Type__c = getValue( reader, '' );
                        }
                        else if ( localName == ELEMENT_SCHEDULEA_SHRED_FREQENCY )
                        {
                            shredLocationItem.Pickup_Frequency__c = getValue( reader, '' );
                        }
                        
                   }
                   else if( reader.getEventType() == XmlTag.END_ELEMENT &&
                            localName == ELEMENT_SCHEDULEA_SHRED_LOCATION )
                   {
                      //System.debug('END TAG [' + localName + ']');
                      //System.debug('Adding Shred Location Item [' + shredLocationItem + ']');
                      shredItemList.add( shredLocationItem );
                   }
                   else if( reader.getEventType() == XmlTag.END_ELEMENT &&
                            localName == ELEMENT_SCHEDULEA_SHRED_LOCATIONS )
                   {
                      //System.debug('END TAG [' + localName + ']');
                      //System.debug('End of Shred Locations');
                      break;
                   }
                   else
                   {
                      // skip
                   }
                }
           }
      }
   }*/

   @TestVisible
   private static boolean processCustomerAssociations( Schedule_A__c scheduleA )
   {
       Boolean validAccounts = true;
       //system.debug('===> in cust associations');
      if( scheduleA != null && scheduleA.CustomerIds__c != null )
      {
          List<String> customerIdList = scheduleA.CustomerIds__c.split(',');

          if( customerIdList != null )
          {
              try
              {
                  //system.debug('===> '+customerIdList.size());
                  List<Schedule_A_Customer_Account__c> schedulaCustomAccountList =
                                 new List<Schedule_A_Customer_Account__c>();
           //System.debug('===>'+VALID_CUST_ACCT_SOURCE_SYS);
                  List<IM_Customer_Account__c> custAccList =
                            [ SELECT Id, name
                              FROM IM_Customer_Account__c
                              WHERE name in :customerIdList AND Source_System__c IN :VALID_CUST_ACCT_SOURCE_SYS ];
                              
          if(custAccList.size() < customerIdList.size())
          {
             INVALID_ACCOUNTS = filterInvalidCustomerAccounts(customerIdList, custAccList);
             validAccounts = false;
          }
          else
          {
            for( IM_Customer_Account__c custAccount : custAccList )
                    {
                       Schedule_A_Customer_Account__c saCustAccItem =
                                        new Schedule_A_Customer_Account__c();
  
                       saCustAccItem.Schedule_A__c       = scheduleA.id;
                       saCustAccItem.Customer_Account__c = custAccount.id;
  
                       schedulaCustomAccountList.add( saCustAccItem );
                    }
  
                    if( schedulaCustomAccountList.size() != 0 )
                    {
                       insert schedulaCustomAccountList;
                    }
                    validAccounts = true;
          }
                  
              }
              catch( Exception e )
              {
                  //Added function call and commented old code - Gitlab story#28215
                  addMessage('warning','Customer Account Match Exception\n\r' + e);
                   /*ApexPages.Message myMsg =
                            new ApexPages.Message( ApexPages.Severity.WARNING,
                                                  'Customer Account Match Exception\n\r' + e );
                   ApexPages.addMessage(myMsg);*/
              }
          }
      }
      return validAccounts;
   }
   
   /**
    * Filters the List of Customer Account Names that are not a part of Salesforce.
    */
   @TestVisible 
   private static Set<String> filterInvalidCustomerAccounts(List<String>xmlCustomerAccountNames, List<IM_Customer_Account__c> customerAccounts)
   {
       Set<String> invalidCustomerAccounts = new Set<String>();
       Set<String> validCustomerAccountNames = new Set<String>();
       for(IM_Customer_Account__c aCustomerAccount : customerAccounts)
         validCustomerAccountNames.add(aCustomerAccount.Name);
       
       for(String aCustomerAcctName : xmlCustomerAccountNames)
       {
         if(!validCustomerAccountNames.contains(aCustomerAcctName))
           invalidCustomerAccounts.add(aCustomerAcctName);
       }
       return invalidCustomerAccounts;
   }

   /**
    * Find the users associated with the approver names
    */
   /*Gitlab: 19277 code cleanup @TestVisible
   private static void updateApprovers( Schedule_A__c scheduleA,
                                        Opportunity   opportunity,
                                        List<String>  approverList )
   {
      try
      {
          User user = [ select id, name, IM_VP__c, IM_SVP__c, IM_RSM__c
                        from user
                        where id=:opportunity.ownerId
                        and IsActive = true ];

          System.debug('User Found [' + user + ']');

          // Assign Approvers
          //scheduleA.Approver_1__c = user.id;
          //scheduleA.Approver_2__c = user.IM_RSM__c;
          //scheduleA.Approver_3__c = user.IM_VP__c;

          // Update the Approver Title
          Integer i=1;
          for( String approverTitle : approverList )
          {
              // no switch statement supported in apex
              if( i == 1 )
                  scheduleA.Approver_1_Title__c = approverTitle;
              else if( i == 2 )
                  scheduleA.Approver_2_Title__c = approverTitle;
              else if( i == 3 )
                  scheduleA.Approver_3_Title__c = approverTitle;
              else if( i == 4 )
                  scheduleA.Approver_4_Title__c = approverTitle;
              else if( i == 5 )
                  scheduleA.Approver_5_Title__c = approverTitle;
              else if( i == 6 )
                  scheduleA.Approver_6_Title__c = approverTitle;
              else if( i == 7 )
                  scheduleA.Approver_7_Title__c = approverTitle;
              else if( i == 8 )
                  scheduleA.Approver_8_Title__c = approverTitle;
              else if( i == 9 )
                  scheduleA.Approver_9_Title__c = approverTitle;
              else if( i == 10 )
                  scheduleA.Approver_10_Title__c = approverTitle;
              else if( i == 11 )
                  scheduleA.Approver_11_Title__c = approverTitle;
              else if( i == 12 )
                  scheduleA.Approver_12_Title__c = approverTitle;

              i++;
          }
      }
      catch( QueryException qEx )
      {
          ApexPages.Message myMsg =
                   new ApexPages.Message( ApexPages.Severity.WARNING,
                                         System.Label.Opportunity_Owner_Inactive );
          ApexPages.addMessage(myMsg);
      }
   }*/

   /**
    * Return the value
    */
   public static String getValue( XmlStreamReader reader,
                                  String defaultValue )
   {
       String value = null;

       while(reader.hasNext())
       {
           //if (debug>2)
           //    system.debug( 'getValue '+reader.getEventType() );
           if (reader.isEndElement())
               break;
           if (reader.isCharacters())
               value = reader.getText();
           reader.next();
       }

       if( value == null )
       {
           value=defaultValue;
       }
       return value;
    }

    private static Decimal toDecimal( XmlStreamReader reader )
    {
        Decimal newValue = 0;
        String value = getValue( reader, '0' );
        if( value != null && value != '' )
        {
           value = value.replace('$', '');
           value = value.replace('%', '');
           System.debug('Debugging value(before conversion) ' + value);
           newValue = Decimal.valueOf( value );
           System.debug('new value ' + newValue);
        }
        return( newValue  );
    }

    private static Boolean toBoolean( XmlStreamReader reader )
    {
        Boolean newValue = false;
        String value = getValue( reader, null );

        if( value != null && (value == '1' || value == 'true' ))
        {
           newValue = true;
        }
        return( newValue  );
    }
    
    //returns 1 if v0 is the most recent version number, -1 if v1 is, and 0 if they are equal
    //added condition to compare PA Model Version with BaseVersiohn(#17520)
    private static Integer compareVersionNumbers(String v0, String v1){
      List<String> sections_v0 = v0.split('\\.', -1);
      List<String> sections_v1 = v1.split('\\.', -1);

      Integer totalSections_v0 = sections_v0.size();
      Integer totalSections_v1 = sections_v1.size();

      Integer len = ( totalSections_v0 <= totalSections_v1 
                      ? totalSections_v0 
                      : totalSections_v1 );

      for(Integer i=0;i<len;i++){
        Integer a = Integer.valueOf(sections_v0[i]);
        Integer b = Integer.valueOf(sections_v1[i]);

        Integer result = compareInteger(a,b);
        if(result != 0){
          return result;
        }
        else if(i == len){
          return compareInteger(totalSections_v0, totalSections_v1);
        }
      }
      return 0;
    }

    //returns 1 if a is larger, -1 if b is larger, or 0 if they are equal
    private static Integer compareInteger(Integer a, Integer b){
      return a>b?1:(a<b?-1:0);
    }
    
   //Added new function - Gitlab story#28215
   private static void addMessage(String messageType, String message)
   {
         if (INVOCATION_CONTEXT==''){
                 ApexPages.Message myMsg =
                             new ApexPages.Message((messageType=='error'?ApexPages.Severity.ERROR:ApexPages.Severity.WARNING),
                                                     message);
                 ApexPages.addMessage(myMsg);
          }
          else if (INVOCATION_CONTEXT=='Rest_Api') {
              message=message.replace('\n','');
              if (messageType=='error') {
                   ERROR_LIST.add(message);
               }
               else {
                   WARNING_LIST.add(message);
               }
          } 
   }
    
    
    /*Gitlab: 19277 code cleanup
     *private static Set<String> SCHEDULE_A_APPROVER_FIELDS = new Set<String>
   {
       ELEMENT_SCHEDULEA_APPROVER1,
       ELEMENT_SCHEDULEA_APPROVER2,
       ELEMENT_SCHEDULEA_APPROVER3,
       ELEMENT_SCHEDULEA_APPROVER4,
       ELEMENT_SCHEDULEA_APPROVER5,
       ELEMENT_SCHEDULEA_APPROVER6,
       ELEMENT_SCHEDULEA_APPROVER7,
       ELEMENT_SCHEDULEA_APPROVER8,
       ELEMENT_SCHEDULEA_APPROVER9,
       ELEMENT_SCHEDULEA_APPROVER10,
       ELEMENT_SCHEDULEA_APPROVER11,
       ELEMENT_SCHEDULEA_APPROVER12
   };*/
   
   private static Map<String,String> SCHEDULE_A_XML_TO_DECIMAL = new Map<String,String>{ 
       // #30914 PA Model: Clean Up the XML mapping job
       /*ELEMENT_SCHEDULEA_CONTRACT_LENGTH => 'Contract_Length__c',*/
       ELEMENT_SCHEDULEA_RM_CONTRACT_LENGTH => 'RM_Contract_Length__c',
       ELEMENT_SCHEDULEA_DM_CONTRACT_LENGTH => 'DM_Contract_Length__c',
       ELEMENT_SCHEDULEA_SS_CONTRACT_LENGTH => 'SS_Contract_Length__c',
       ELEMENT_SCHEDULEA_LARGEST_MARKETVOL1 => 'Largest_Market_Volume_1__c',
       ELEMENT_SCHEDULEA_LARGEST_MARKETVOL2 => 'Largest_Market_Volume_2__c',
       ELEMENT_SCHEDULEA_LARGEST_MARKETVOL3 => 'Largest_Market_Volume_3__c',
       ELEMENT_SCHEDULEA_CUR_STORAGE_VOL => 'Current_Storage_Volume__c',
       ELEMENT_SCHEDULEA_CUR_STORAGE_PRICE => 'Current_Storage_Price__c',
       ELEMENT_SCHEDULEA_NEW_STORAGE_VOLUME => 'New_Storage_Volume__c',
       ELEMENT_SCHEDULEA_TOTAL_MINIMUM_AMOUNT => 'Total_New_Revenue__c',
       ELEMENT_SCHEDULEA_NEW_STORAGE_PRICE => 'New_Storage_Price__c',
       ELEMENT_SCHEDULEA_CUR_EFFECTIVE_DISC => 'Current_Effective_Discount__c',
       ELEMENT_SCHEDULEA_RM_LIST_PRICE_DISCOUNT => 'RM_List_Price_Discount__c',
       ELEMENT_SCHEDULEA_RM_SERVICE_LIST_PRICE_DISCOUNT => 'RM_Service_List_Price_Discount__c',
       ELEMENT_SCHEDULEA_ESTIMATED_YEARLY_REVENUE => 'Estimated_Year_1_Revenue__c',
       ELEMENT_SCHEDULEA_REVENUE_YEAR_TARGET_PRICING => 'Revenue_Year_Target_Pricing__c',
       ELEMENT_SCHEDULEA_REVENUE_LIST_PRICING => 'Revenue_at_List_Pricing__c',
       ELEMENT_SCHEDULEA_TOTAL_CONTRACT_REVENUE => 'Total_Contract_Revenue__c',
       ELEMENT_SCHEDULEA_RM_EFFECTIVE_DISCOUNT => 'RM_Effective_Discount__c',
       ELEMENT_SCHEDULEA_DBR_STORATE_EFFECTIVE_DISCOUNT => 'DBR_Storate_Effective_Discount__c',
       ELEMENT_SCHEDULEA_DBR_SERVICE_EFFECTIVE_DISCOUNT => 'DBR_Service_Effective_Discount__c',
       ELEMENT_SCHEDULEA_DBR_STORATE_LIST_PRICE_DISCOUNT => 'DBR_Storate_List_Price_Discount__c',
       ELEMENT_SCHEDULEA_DBR_SERVICE_LIST_PRICE_DISCOUNT => 'DBR_Service_List_Price_Discount__c',
       // #30914 PA Model: Clean Up the XML mapping job
       /*
       ELEMENT_SCHEDULEA_COST_IRM1 => 'Cost_to_IRM1__c',
       ELEMENT_SCHEDULEA_COST_IRM2 => 'Cost_to_IRM2__c',
       ELEMENT_SCHEDULEA_COST_IRM3 => 'Cost_to_IRM3__c',
       ELEMENT_SCHEDULEA_COST_IRM4 => 'Cost_to_IRM4__c',
       ELEMENT_SCHEDULEA_COST_IRM5 => 'Cost_to_IRM5__c',
       ELEMENT_SCHEDULEA_COST_IRM6 => 'Cost_to_IRM6__c',*/
       ELEMENT_SCHEDULEA_SHRED_REVENUE1 => 'ShredRevenue_1__c',
       ELEMENT_SCHEDULEA_SHRED_REVENUE2 => 'ShredRevenue_2__c',
       ELEMENT_SCHEDULEA_SHRED_REVENUE3 => 'ShredRevenue_3__c',
       ELEMENT_SCHEDULEA_SHRED_REVENUE4 => 'ShredRevenue_4__c',
       ELEMENT_SCHEDULEA_SHRED_REVENUE5 => 'ShredRevenue_5__c',
       ELEMENT_SCHEDULEA_SHRED_REVENUE6 => 'ShredRevenue_6__c',
       ELEMENT_SCHEDULEA_SHRED_REVENUE7 => 'ShredRevenue_7__c',
       ELEMENT_SCHEDULEA_SHRED_REVENUE8 => 'ShredRevenue_8__c',
       ELEMENT_SCHEDULEA_SHRED_REVENUE9 => 'ShredRevenue_9__c',
       ELEMENT_SCHEDULEA_SHRED_REVENUE10 => 'ShredRevenue_10__c',
       ELEMENT_SCHEDULEA_SERVICE_LABOUR_HOURS => 'Service_Labor_Hours__c',
       ELEMENT_SCHEDULEA_SERVICE_LABOUR_COST  => 'Service_Labor_rate__c',
       ELEMENT_SCHEDULEA_INVESTMENT    => 'Investment__c',
       ELEMENT_SCHEDULEA_TOTAL_CASHVIEW_COST => 'Total_Cashview_Cost__c',
       /* #17061 */ 
       ELEMENT_SCHEDULEA_REVENUE_DILUTION => 'Revenue_Dilution__c',
       /*end of #17061 */ 
       ELEMENT_SCHEDULEA_FLOOR_REVENUE_REALIZATION => 'Floor_Revenue_Realization_Shadow__c',
       /* #19532 */
       ELEMENT_SCHEDULEA_FLOOR_REVENUE => 'Total_Floor_Revenue__c',
       /*end of #19532 */   
       //21572 Parsing the data from XMl to Revenue Dilition $ field
       ELEMENT_SCHEDULEA_REVENUE_DOLLAR =>'Revenue_Dilution_dollar__c',
       //28954 Parsing the data from XMl to Total Cost field
       ELEMENT_SCHEDULEA_TOTAL_COST =>'Total_Cost__c'
       };
   
   
   private static Map<String,String> SCHEDULE_A_XML_TO_FIELD_VALUE = new Map<String,String>{ 
       ELEMENT_SCHEDULEA_LARGEST_MARKET1 => 'Largest_Market_1__c',
       ELEMENT_SCHEDULEA_LARGEST_MARKET2 => 'Largest_Market_2__c',
       ELEMENT_SCHEDULEA_LARGEST_MARKET3 => 'Largest_Market_3__c',
       ELEMENT_SCHEDULEA_PA_VERSION => 'pa_version__c',
       ELEMENT_SCHEDULEA_SALES_SEG => 'Salesseg__c',
       ELEMENT_SCHEDULEA_INDUSTRY => 'Industry__c'
      };
   private static Map<String,String> SCHEDULE_A_XML_SET_VALUE = new Map<String,String>{ 
      // #30914 PA Model: Clean Up the XML mapping job
      /*
      ELEMENT_SCHEDULEA_DEAL_SUMMARY1 => 'Pricing_Strategy__c',
      ELEMENT_SCHEDULEA_NONBILL1 => 'Non_Billable_Deal_Term1__c',
      ELEMENT_SCHEDULEA_NONBILL2 => 'Non_Billable_Deal_Term2__c',
      ELEMENT_SCHEDULEA_NONBILL3 => 'Non_Billable_Deal_Term3__c',
      ELEMENT_SCHEDULEA_NONBILL4 => 'Non_Billable_Deal_Term4__c',
      ELEMENT_SCHEDULEA_NONBILL5 => 'Non_Billable_Deal_Term5__c',
      ELEMENT_SCHEDULEA_NONBILL6 => 'Non_Billable_Deal_Term6__c',
      ELEMENT_SCHEDULEA_REC1 => 'Pricing_Recommendations1__c',
      ELEMENT_SCHEDULEA_REC2 => 'Pricing_Recommendations2__c',
      ELEMENT_SCHEDULEA_REC3 => 'Pricing_Recommendations3__c',
      ELEMENT_SCHEDULEA_REC4 => 'Pricing_Recommendations4__c',
      ELEMENT_SCHEDULEA_UNITS1 => 'Units1__c',
      ELEMENT_SCHEDULEA_UNITS2 => 'Units2__c',
      ELEMENT_SCHEDULEA_UNITS3 => 'Units3__c',
      ELEMENT_SCHEDULEA_UNITS4 => 'Units4__c',
      ELEMENT_SCHEDULEA_UNITS5 => 'Units5__c',
      ELEMENT_SCHEDULEA_UNITS6 => 'Units6__c',
      ELEMENT_SCHEDULEA_DEAL_SUMMARY2 => 'Deal_Summary2__c',
      ELEMENT_SCHEDULEA_DEAL_SUMMARY3 => 'Deal_Summary3__c',
      ELEMENT_SCHEDULEA_DEAL_SUMMARY4 => 'Deal_Summary4__c',*/
      ELEMENT_SCHEDULEA_ADDITIONAL_TERMS1 => 'Additional_Terms_1__c',
      ELEMENT_SCHEDULEA_ADDITIONAL_TERMS2 => 'Additional_Terms_2__c',
      ELEMENT_SCHEDULEA_ADDITIONAL_TERMS3 => 'Additional_Terms_3__c',
      ELEMENT_SCHEDULEA_ADDITIONAL_TERMS4 => 'Additional_Terms_4__c',
      ELEMENT_SCHEDULEA_ADDITIONAL_TERMS5 => 'Additional_Terms_5__c',
      ELEMENT_SCHEDULEA_ADDITIONAL_TERMS6 => 'Additional_Terms_6__c',
      ELEMENT_SCHEDULEA_ADDITIONAL_TERMS7 => 'Additional_Terms_7__c',
      ELEMENT_SCHEDULEA_ADDITIONAL_TERMS8 => 'Additional_Terms_8__c'
   };
   
   private static Map<String,String> SCHEDULE_A_XML_TO_BOOLEAN = new Map<String,String>{ 
      // #30914 PA Model: Clean Up the XML mapping job
       // ELEMENT_SCHEDULEA_TIERED_PRICING => 'Tiered_Pricing__c',
     //  ELEMENT_SCHEDULEA_PROGRAM_PRICING => 'Program_Pricing__c',
     // ELEMENT_SCHEDULEA_BUNDLED_PRICING => 'Bundled_Pricing__c',
       ELEMENT_SCHEDULEA_INCLUDE_CLAWBACK => 'include_Clawback__c',
       ELEMENT_SCHEDULEA_RM_MULTI_YEAR_DEAL => 'RM_Multi_Year_Deal__c',      
       ELEMENT_SCHEDULEA_RM_FREE_UP_IN => 'RM_FUI__c',
       ELEMENT_SCHEDULEA_RM_UNVENDED => 'RM_Unvended__c',
       ELEMENT_SCHEDULEA_RM_PW_FEE_PAID => 'RM_PW_Fee_Paid__c',
       ELEMENT_SCHEDULEA_RM_PROGRAM_PRICING => 'RM_Program_Pricing__c',
       ELEMENT_SCHEDULEA_RM_TIERED_PRICING => 'RM_Tiered_Pricing__c',
       ELEMENT_SCHEDULEA_RM_FREE_STORAGE => 'RM_Free_Storage__c',
       ELEMENT_SCHEDULEA_RM_FREE_SERVICES => 'RM_Free_Services__c',
       ELEMENT_SCHEDULEA_RM_OTHER => 'RM_Other__c',
       ELEMENT_SCHEDULEA_DM_MULTI_YEAR_DEAL => 'DM_Multi_Year_Deal__c',
       ELEMENT_SCHEDULEA_DM_TIERED_PRICING => 'DM_Tiered_Pricing__c',
       ELEMENT_SCHEDULEA_DM_OTHER => 'DM_Other__c',
       ELEMENT_SCHEDULEA_SS_MULTI_YEAR_DEAL => 'SS_Multi_Year_Deal__c',
       ELEMENT_SCHEDULEA_SS_TIERED_PRICING => 'SS_Tiered_Pricing__c',
       ELEMENT_SCHEDULEA_SS_OTHER => 'SS_Other__c',
       ELEMENT_SCHEDULEA_RM_FREE_STORAGEVIA_WA => 'RM_Free_Storage_via_Weighted_Avg__c',
       ELEMENT_SCHEDULEA_RM_FREE_SERVICESVIA_WA => 'RM_Free_Services_via_Weighted_Avg__c',
       ELEMENT_SCHEDULEA_FINANCING => 'Financing__c',
       ELEMENT_SCHEDULEA_REBATE => 'Rebates__c',
       ELEMENT_SCHEDULEA_RETROACTIVE => 'Retroactive_Pricing__c',
       ELEMENT_SCHEDULEA_RM_PRICE_DECREASE => 'RM_Price_Decrease_Reason__c',                  
       ELEMENT_SCHEDULEA_RM_VENDED => 'RM_Vended_Unvended__c',                       
       ELEMENT_SCHEDULEA_RM_COMPETITION => 'RM_Competition__c',                      
       ELEMENT_SCHEDULEA_DM_PRICE_DECREASE => 'DM_Price_Decrease_Reason__c',                   
       ELEMENT_SCHEDULEA_DM_VENDED => 'DM_Vended_Unvended__c',                          
       ELEMENT_SCHEDULEA_DM_COMPETITION => 'DM_Competition__c',
       ELEMENT_SCHEDULEA_RED_FLAG => 'Red_Flag__c',                  
       ELEMENT_SCHEDULEA_SS_PRICE_DECREASE => 'SS_Price_Decrease_Reason__c',                   
       ELEMENT_SCHEDULEA_SS_VENDED => 'SS_Vended_Unvended__c',                            
       ELEMENT_SCHEDULEA_SS_COMPETITION => 'SS_Competition__c'                    
       
       
   };
   
   private static Map<String, String> SCHEDULE_A_ITEM_XML_TO_BOOLEAN = new Map<String,String>{
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_KEEP_FLAG => 'keep_flag__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_FORECASTABLEFLAG => 'Forecastable__c'
   };
   private static Map<String, String> SCHEDULE_A_ITEM_XML_TO_DECIMAL = new Map<String,String>{
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_PROPOSED_PRICE => 'Proposed_Price__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_PROPOSED_VOLUME => 'XML_Proposed_Volume__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_CUR_PRICE => 'Current_Price__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_CUR_VOLUME => 'Current_Volume__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_LIST_PRICE => 'List_Price__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_1_PRICE => 'Proposed_Price_Year_1__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_2_PRICE => 'Proposed_Price_Year_2__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_3_PRICE => 'Proposed_Price_Year_3__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_4_PRICE => 'Proposed_Price_Year_4__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_5_PRICE => 'Proposed_Price_Year_5__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_6_PRICE => 'Proposed_Price_Year_6__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_7_PRICE => 'Proposed_Price_Year_7__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_8_PRICE => 'Proposed_Price_Year_8__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_9_PRICE => 'Proposed_Price_Year_9__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_YEAR_10_PRICE => 'Proposed_Price_Year_10__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_TARGET_PRICE => 'Target_Price__c',
       //ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_FORECASTABLEFLAG => 'Forecastable__c'
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_FLOOR_PRICE =>'Floor_Price__c',
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_CASHVIEW_COST_LINE => 'Cashview_Cost_Line__c',
       //26139 Parsing the data from XMl to Line Revenue field
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_LINE_REVENUE =>'Line_Revenue__c',
       //28954 Parsing the data from XMl to Unit Cost (Line) field
       ELEMENT_SCHEDULEA_QUOTE_ITEM_UNIT_COST =>'Unit_Cost_Line__c'
   };
   private static Map<String, String> SCHEDULE_A_ITEM_XML_SET_VALUE = new Map<String,String>{
       ELEMENT_SCHEDULEA_QUOTE_ITEM_PRODUCT_OFFERINGTYPE => 'Offering_Type__c'
   };
       

}
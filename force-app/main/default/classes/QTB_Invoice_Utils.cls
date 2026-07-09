/*****************************************************************************************************
* Class: QTB_Invoice_Utils
* Purpose: This is a class for all utilities related to invoice presentation
* Developer             Date           
* ------------------------------------------------------------------------------------------- 
*  Vinutha Iyengar      7/24/2020
*******************************************************************************************************/
public class QTB_Invoice_Utils 
{
    public static final string Sandbox = 'Sandbox';
    public static final string Production = 'Production';
    
    public static final String Product_Family_RM = 'Records Management'; 
    public static final String Product_Family_DM = 'Data Management'; 
    public static final String Product_Family_Shred = 'Shred'; 
    public static final String Product_Family_Scan = 'Scan'; 
    public static final String Product_Family_Special = 'Special'; 
    
    public static final String PSC_Storage = 'Storage'; 
    public static final String PSC_Transportation = 'Transportation'; 
    public static final String PSC_Supplies = 'Supplies'; 
    public static final String PSC_Services = 'Services';
    
    public static final String FX_RATETYPE_BANK = 'Bank';
    public static final String FX_RATETYPE_CORP = 'Corporate';
    
    public static final String Level_1 = 'Operating System Account (Level 1)'; 
    public static final String Level_2 = 'Division (Level 2)'; 
    public static final String Level_3 = 'Department (Level 3)'; 
    
    public static final String INV_STATUS_DRAFT = 'Draft'; 
    public static final String INV_STATUS_POSTED = 'Posted';
    
    //Addded utility set methods for quick prod family validation
    private static set<String> productFamiliesSet;
    public static set<String> productFamilies{
        get{
            if(productFamiliesSet==null){
                productFamiliesSet = new Set<String>{Product_Family_RM, Product_Family_DM, Product_Family_Shred, Product_Family_Scan};
                    }
            return productFamiliesSet;
        }
    }
    
    //Addded utility set methods for quick price sch category validation
    private static set<String> priceSchCategoySet;
    public static set<String> priceScheduleCategories{
        get{
            if(priceSchCategoySet==null){
                priceSchCategoySet = new Set<String>{PSC_Storage, PSC_Supplies, PSC_Transportation};
                    }
            return priceSchCategoySet;
        }
    }
           
   
    public static void deleteUsageSuspenses()
    {
        //List<QTB_Usage_Suspense__c> recsToDelete = [select id from QTB_Usage_Suspense__c where QTB_Mediation_Status__c = 'Processed' limit 9000];
       // delete recsToDelete;
          System.debug('deleteUsageSuspenses');
          Database.executeBatch(new QTB_UsageSuspenseBatchables(),2000); 
        
    }
}
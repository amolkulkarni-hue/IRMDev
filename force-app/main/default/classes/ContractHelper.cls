/**
* Class: ContractHelper
*
* Author: Vidya Sagar Hadpad
*
* Date Created: 06.11.2020
*
* Purpose: ContractHelper is a handler class for all business logic related to Contract object
*
* Test Class        :  Apex Class  : ContractHelperTest
*   
* Case Number       : 01590130 and 02236864
* 
*/
public class ContractHelper {
    
    /*	Method 		: updateContractDates
	 *  Description : This method is used to calculate contract end date,Renewal date,Expiration notice date and end date fixed term
	 */
    public static void updateContractDates(list<Contract> triggerNewList, map<Id,Contract> triggerOldMap)
    {
        for(Contract objContr: triggerNewList)
        {
            // checks for IME Contract record types(IME Addendum,IME Addendum Extension,IME Child Contract and IME Contract)
            if(getIMContractRecordTypes().contains(objContr.RecordTypeId))
            {
                // Checks for Contract term is equals to 'Fixed Term'
                if(objContr.IME_Contract_Term_Type__c == App_Constants.CONTRACT_TERM_FIXED_TERM && objContr.ContractTerm != null)
                {
                    contractTermFixed(objContr);
                }// Checks for Contract term is equals to 'Evergreen'
                else if(objContr.IME_Contract_Term_Type__c == App_Constants.CONTRACT_TERM_EVERGREEN)
                {
                    objContr.IME_Contract_End_Date__c =null;
                    if(objContr.ContractTerm !=null)
                    {
                        contractTermEvergreen(objContr);
                    }
                }// Checks for Contract term is equals to 'Evergreen (open rolling)'
                else if(objContr.IME_Contract_Term_Type__c == App_Constants.CONTRACT_TERM_EVERGREEN_OPEN_ROLLING)
                {
                    objContr.IME_Contract_End_Date__c =null;
                    objContr.IME_Contract_Renewal_Date__c=null;
                    objContr.IME_Expiration_Notice_Date__c = null;
                }// checks for contract status for draft and activated date
                if(objContr.Status == App_Constants.CONTRACT_STATUS_DRAFT || (!triggerOldMap.isEmpty() && (triggerOldMap.get(objContr.Id).ActivatedDate == NULL && objContr.ActivatedDate !=NUll)))
                { // Update 'Original Contract Start Date' field with the value from the 'Contract Start Date' field
                    objContr.IME_Original_Contract_Start_Date__c=objContr.StartDate;
                }
            }
            if(objContr.IME_Copy_to_all__c  && (String.isNotBlank(objContr.IME_Price_Increase_Type_Product_Sales__c) || String.isNotBlank(objContr.IME_Price_Increase_Type_Services__c ) || String.isNotBlank(objContr.IME_Price_Increase_Type_Transport__c)
                                                || String.isNotBlank(objContr.IME_Index_Product_Sales__c) || String.isNotBlank(objContr.IME_Index_Services__c) || String.isNotBlank(objContr.IME_Index_Transport__c )
                                                || String.isNotBlank(String.ValueOf(objContr.IME_Capped_Percentage_Product_Sales__c)) || String.isNotBlank(String.ValueOf(objContr.IME_Capped_Percentage_Services__c))|| String.isNotBlank(String.ValueOf(objContr.IME_Capped_Percentage_Transport__c))
                                                || String.isNotBlank(String.ValueOf(objContr.IME_Fixed_Pricing_Period_months_Prod_S__c)) || String.isNotBlank(String.ValueOf(objContr.IME_Fixed_Pricing_Period_months_Transp__c))|| String.isNotBlank(String.ValueOf(objContr.IME_Fixed_Pricing_Period_months_Services__c))
                                                || String.isNotBlank(String.ValueOf(objContr.IME_End_of_Fixed_Pricing_Period_Prod_S__c)) || String.isNotBlank(String.ValueOf(objContr.IME_End_of_Fixed_Pricing_Period_Transp__c))|| String.isNotBlank(String.ValueOf(objContr.IME_End_of_Fixed_Pricing_Period_Services__c))
                                                || String.isNotBlank(String.ValueOf(objContr.IME_Special_Terms_Other_Services__c)) || String.isNotBlank(String.ValueOf(objContr.IME_Special_Terms_Other_Transp__c))|| String.isNotBlank(String.ValueOf(objContr.IME_Special_Terms_Other_Prod_S__c))
                                               ) )
            {
                objContr.addError(Label.IME_Contract_CopyAll_ErrorMsg);
            }// checks for copy to all
            else if(objContr.IME_Copy_to_all__c)
            { // copy pirice increase from storage to product,service and transport
                copyToAllPriceIncrease(objContr);
            }
            if(objContr.IME_Original_Contract_Start_Date__c != null)
            {   // update fixed pricing of storage,service, product and transport
                fixedPricingPeriod(objContr);
            }
            
        }
    }
    
    /*	Method 		: getIMContractRecordTypes
	 *  Description : Used to get IM Contract Record type ids
	 *  Return 		: returns list of ids
	 */
    public static list<Id> getIMContractRecordTypes()
    {
        list<Id> list_RecordTypeIds = new list<Id>();
        list_recordTypeIDs.add(App_Constants.RT_ID_IME_ADDENDUM_CONTRACT);
        list_recordTypeIDs.add(App_Constants.RT_ID_IME_ADDENDUM_EXTENSION_CONTRACT);
        list_recordTypeIDs.add(App_Constants.RT_ID_IME_CHILD_CONTRACT);
        list_recordTypeIDs.add(App_Constants.RT_ID_IME_CONTRACT);
        return list_RecordTypeIds;
    }
    
    /*	Method 		: copyToAllPriceIncrease
	 *  Description : This method is used to copy price increase of storage to price increase of product,service and transport
	 */
    public static void copyToAllPriceIncrease(Contract objContr)
    {
        
        if(objContr.IME_Price_Increase_Type_Storage__c != null)
        {   // Copy IME price increase of storage to product,service and transport
            objContr.IME_Price_Increase_Type_Product_Sales__c= objContr.IME_Price_Increase_Type_Storage__c;
            objContr.IME_Price_Increase_Type_Services__c = objContr.IME_Price_Increase_Type_Storage__c;
            objContr.IME_Price_Increase_Type_Transport__c = objContr.IME_Price_Increase_Type_Storage__c;
            objContr.IME_Copy_to_all__c = false;    
        }
        if(objContr.IME_Index_Storage__c!=null)
        {   // Copy IME intex of storage to product,service and transport
            objContr.IME_Index_Product_Sales__c = objContr.IME_Index_Storage__c;
            objContr.IME_Index_Services__c = objContr.IME_Index_Storage__c;
            objContr.IME_Index_Transport__c = objContr.IME_Index_Storage__c;
            objContr.IME_Copy_to_all__c = false;            
        }
        if(objContr.IME_Capped_Percentage_Storage__c != null)
        { // Copy IME Capped percentage of storage to product,service and transport
            objContr.IME_Capped_Percentage_Product_Sales__c = objContr.IME_Capped_Percentage_Storage__c;
            objContr.IME_Capped_Percentage_Services__c = objContr.IME_Capped_Percentage_Storage__c;
            objContr.IME_Capped_Percentage_Transport__c = objContr.IME_Capped_Percentage_Storage__c;
            objContr.IME_Copy_to_all__c = false;
        }  
        if(objContr.IME_Fixed_Pricing_Period_months_Storage__c != null)
        { // Copy IME fixed pricing period months of storage to product,service and transport
            objContr.IME_Fixed_Pricing_Period_months_Prod_S__c = objContr.IME_Fixed_Pricing_Period_months_Storage__c;
            objContr.IME_Fixed_Pricing_Period_months_Services__c = objContr.IME_Fixed_Pricing_Period_months_Storage__c;
            objContr.IME_Fixed_Pricing_Period_months_Transp__c =objContr.IME_Fixed_Pricing_Period_months_Storage__c;
            objContr.IME_Copy_to_all__c = false;
        }
        if(objContr.IME_End_of_Fixed_Pricing_Period_Storage__c != null)
        { // Copy END OF fixed pricing period of storage to product,service and transport
            objContr.IME_End_of_Fixed_Pricing_Period_Prod_S__c = objContr.IME_End_of_Fixed_Pricing_Period_Storage__c;
            objContr.IME_End_of_Fixed_Pricing_Period_Services__c = objContr.IME_End_of_Fixed_Pricing_Period_Storage__c;
            objContr.IME_End_of_Fixed_Pricing_Period_Transp__c = objContr.IME_End_of_Fixed_Pricing_Period_Storage__c;
            objContr.IME_Copy_to_all__c = false;
        }
        if(objContr.IME_Special_Terms_Other_Storage__c != null)
        {   // Copy IME Special terms other of storage to product,service and transport
            objContr.IME_Special_Terms_Other_Prod_S__c = objContr.IME_Special_Terms_Other_Storage__c;
            objContr.IME_Special_Terms_Other_Services__c = objContr.IME_Special_Terms_Other_Storage__c;
            objContr.IME_Special_Terms_Other_Transp__c = objContr.IME_Special_Terms_Other_Storage__c;
            objContr.IME_Copy_to_all__c = false;
        }  
        
    }
    
    /*	Method 		: fixedPricingPeriod
	 *  Description : This method is used to calculate fixed pricing period of storage,product,service and transport
	 */
    public static void fixedPricingPeriod(Contract objContr)
    {
        if(objContr.IME_Fixed_Pricing_Period_months_Storage__c != null)
        {   // Calculate IME End of fixed pricing period storage
            objContr.IME_End_of_Fixed_Pricing_Period_Storage__c = objContr.IME_Original_Contract_Start_Date__c.addMonths(Integer.valueOf(objContr.IME_Fixed_Pricing_Period_months_Storage__c));
        }                
        if(objContr.IME_Fixed_Pricing_Period_months_Services__c != null)
        {  // Calculate IME End of fixed pricing period Services
            objContr.IME_End_of_Fixed_Pricing_Period_Services__c = objContr.IME_Original_Contract_Start_Date__c.addMonths(Integer.valueOf(objContr.IME_Fixed_Pricing_Period_months_Services__c));
        }                
        if(objContr.IME_Fixed_Pricing_Period_months_Prod_S__c != null)
        {   // Calculate IME End of fixed pricing period Prod
            objContr.IME_End_of_Fixed_Pricing_Period_Prod_S__c = objContr.IME_Original_Contract_Start_Date__c.addMonths(Integer.valueOf(objContr.IME_Fixed_Pricing_Period_months_Prod_S__c));
        }                
        if(objContr.IME_Fixed_Pricing_Period_months_Transp__c != null)
        {   // Calculate IME End of fixed pricing period transp
            objContr.IME_End_of_Fixed_Pricing_Period_Transp__c = objContr.IME_Original_Contract_Start_Date__c.addMonths(Integer.valueOf(objContr.IME_Fixed_Pricing_Period_months_Transp__c));
        }
        
    }
    
    
    /*	Method 		: contractTermFixed
	 *  Description : This method is used to calculate fixed pricing period of storage,product,service and transport
	 */
    public static void contractTermFixed(Contract objContr)
    {
        if(objContr.IM_Renewal_Term__c != null)
        { // Calculate IME Contract end date and renewal date
            objContr.IME_Contract_End_Date__c = objContr.StartDate.addMonths(Integer.ValueOf(objContr.ContractTerm + objContr.IM_Renewal_Term__c)) - 1;
            objContr.IME_Contract_Renewal_Date__c = objContr.StartDate.addMonths(Integer.ValueOf(objContr.ContractTerm)) - 1;
            if(objContr.IME_Expiration_Notice_days__c!= null)
            {  // Calculate IME Expiration notice date and contract end date fixed term
                objContr.IME_Expiration_Notice_Date__c = objContr.IME_Contract_Renewal_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                objContr.IME_Contract_End_Date_Fixed_Term__c = objContr.IME_Contract_End_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
            }else{
                objContr.IME_Expiration_Notice_Date__c = null;
            }
        }
        else
        {   // Calculate IME Contract end date 
            objContr.IME_Contract_End_Date__c = objContr.StartDate.addMonths(Integer.ValueOf(objContr.ContractTerm + 0)) - 1;
            objContr.IME_Contract_Renewal_Date__c = null;
            if(objContr.IME_Expiration_Notice_days__c!= null)
            {  // Calculate IME Expiration notice date and contract end date fixed term
                objContr.IME_Expiration_Notice_Date__c = objContr.IME_Contract_End_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                objContr.IME_Contract_End_Date_Fixed_Term__c = objContr.IME_Contract_End_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
            }
            else
            {
                objContr.IME_Expiration_Notice_Date__c = null;
            }
        }
    }
    
    /*	Method 		: contractTermEvergreen
	 *  Description : This method is used to calculate fixed pricing period of storage,product,service and transport
	 */
    public static void contractTermEvergreen(Contract objContr)
    {
        objContr.IME_Contract_Renewal_Date__c = objContr.startdate.addmonths(Integer.Valueof(objContr.ContractTerm));       
        if(objContr.IME_Contract_Renewal_Date__c > system.today())
        {   // Update IME Contract Renewal Date
            objContr.IME_Contract_Renewal_Date__c=objContr.startdate.addmonths(Integer.Valueof(objContr.ContractTerm)) - 1;
            if(objContr.IME_Expiration_Notice_days__c!=null)
            {   // Update IME Expiration Notice Date
                objContr.IME_Expiration_Notice_Date__c = objContr.IME_Contract_Renewal_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
            }
            else
            {
                objContr.IME_Expiration_Notice_Date__c = null;
            }
        }
        if(objContr.IM_Renewal_Term__c == null)
        {   // if renewal term is null then updates contact renewal date and expiration date to null
            objContr.IME_Contract_Renewal_Date__c =null;
            objContr.IME_Expiration_Notice_Date__c =null;
        }
        else if(objContr.IME_Contract_Renewal_Date__c == System.Today())
        {
                Date dt = System.Today().addMonths(Integer.ValueOf(objContr.IM_Renewal_Term__c));
                // Update IME Contract Renewal Date
                objContr.IME_Contract_Renewal_Date__c = Date.newInstance(dt.year(), dt.month(), objContr.StartDate.day()) - 1;
                
                if(objContr.IME_Expiration_Notice_days__c!=null)
                {   // Update IME Expiration Notice Date
                    objContr.IME_Expiration_Notice_Date__c = objContr.IME_Contract_Renewal_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                }
                else
                {
                    objContr.IME_Expiration_Notice_Date__c = null;
                }
        }
        else if(objContr.IME_Contract_Renewal_Date__c<System.Today() && objContr.IM_Renewal_Term__c==0)
        {
            // Update IME Contract Renewal Date
            objContr.IME_Contract_Renewal_Date__c =  objContr.StartDate.addMonths(Integer.ValueOf(objContr.ContractTerm)) - 1;
            if(objContr.IME_Expiration_Notice_days__c!=null)
            {   // Update IME Expiration Notice Date
                objContr.IME_Expiration_Notice_Date__c = objContr.IME_Contract_Renewal_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
            }
            else
            {
                objContr.IME_Expiration_Notice_Date__c = null;
            }
        }
        else if(objContr.IME_Contract_Renewal_Date__c<System.Today())
        {
            Integer monthsDiff, monthsMod;
            Date date0, date1, date2, date3 ;
            
            monthsDiff=system.today().monthsBetween(objContr.IME_Contract_Renewal_Date__c);
            monthsMod = math.mod(monthsDiff, Integer.Valueof(objContr.IM_Renewal_Term__c));
            date0=system.today().addmonths(monthsMod);
            date1=date0.addmonths(Integer.Valueof(objContr.IM_Renewal_Term__c));
            objContr.IME_Contract_Renewal_Date__c = date.newInstance(date1.year(), date1.month(), objcontr.startdate.day()) - 1;
            
            if((objContr.IME_Contract_Renewal_Date__c) == System.Today()) {  
                // Update IME Contract Renewal Date
                objContr.IME_Contract_Renewal_Date__c = objContr.IME_Contract_Renewal_Date__c.addMonths(integer.valueof(objContr.IM_Renewal_Term__c));                
            }                            
            if(objContr.IME_Contract_Renewal_Date__c.addmonths(-(integer.valueof((objContr.IM_Renewal_Term__c))))>system.today())                               
            {
                // Update IME Contract Renewal Date
                objContr.IME_Contract_Renewal_Date__c = objContr.IME_Contract_Renewal_Date__c.addmonths(-(integer.valueof((objContr.IM_Renewal_Term__c))));
            }                             
            
            if(objContr.IME_Expiration_Notice_days__c!=null)
            {  // Update IME Expiration Notice Date
                objContr.IME_Expiration_Notice_Date__c = objContr.IME_Contract_Renewal_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
            }
            else
            {
                objContr.IME_Expiration_Notice_Date__c = null;
            }
        }    
    }
}
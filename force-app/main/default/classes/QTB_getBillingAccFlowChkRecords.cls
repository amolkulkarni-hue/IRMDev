/**********************************************************************************************************************************************
* Class: QTB_getBillingAccFlowChkRecords
* Author: Virtusa
* Purpose: This is class will return the QTB_Billing_Account_Flow_Check__mdt custom metadata records.
* Requirement: GitLab #19884
* Change History:
* Developer      
* ----------------------------------------------------------------------------------------------------------------------------------------------
* ChandraPrakash    Date 01/12/2023  It will return the custom metadata record based upon Opportunity Country & Primary product Line.
*************************************************************************************************************************************************/
public class QTB_getBillingAccFlowChkRecords {
    
    //calling the method from the Flow(QTB_Opportunity_Billing_Account_Creation) to return custom metadata record based upon Opportunity country & Primary product Line
    @InvocableMethod(Label='CallQTB_getCustomMetadataRecords' description='This method will rerturn QTB_Billing_Account_Flow_Check__mdt records')
    public static List<QTB_Billing_Account_Flow_Check__mdt> getBillingAccountFlowSettingRecord(List<OppCountryAndPrimaryProduct> OppRequest){
        
        //Storing the Flow inputs in to the variables
        String oppCountryName =  OppRequest[0].oppCountry;
        String oppPrimaryPrdName =  OppRequest[0].oppPrimaryProductLine;
        
        //Storing the QTB_Billing_Account_Flow_Check__mdt records in the List
        List<QTB_Billing_Account_Flow_Check__mdt> billingAccFloeChkList = new List<QTB_Billing_Account_Flow_Check__mdt>();  
        
        if (oppCountryName != null && oppPrimaryPrdName != null) {
            
            //Fethcing the QTB_Billing_Account_Flow_Check__mdt record based upon opportunity country
            List<QTB_Billing_Account_Flow_Check__mdt> billingAccountFlowChk = [select Id,QTB_Country__c,QTB_Is_CPQ_Country__c,QTB_Primary_Product_Lines__c,
                                                                               QTB_Is_Old_Model__c,QTB_Active__c
                                                                               from QTB_Billing_Account_Flow_Check__mdt WHERE QTB_Country__c =: oppCountryName];
            
            
            for(QTB_Billing_Account_Flow_Check__mdt billingAccFlow: billingAccountFlowChk){
                //checking custom metadta QTB_Primary_Product_Line__c contains opportunity Primary product Line
                if (billingAccFlow.QTB_Primary_Product_Lines__c != null && billingAccFlow.QTB_Primary_Product_Lines__c.contains(oppPrimaryPrdName)) {
                    billingAccFloeChkList.add(billingAccFlow);
                    break;
                }   
            }
        }
        //returning the QTB_Billing_Account_Flow_Check__mdt record.
        return billingAccFloeChkList;
    }
    public class OppCountryAndPrimaryProduct{
        @InvocableVariable
        public string oppCountry;
        
        @InvocableVariable
        public string oppPrimaryProductLine;
    }
}
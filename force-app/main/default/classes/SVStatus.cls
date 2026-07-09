/**
* Modified By: Vinutha Iyengar on 20-Jun-2017 
*          -- Set 'Opportunity Total Annual Amount Test' to false when 'SV Status' != 'Passed'
*          -- Case # 06190653

* Modified By: Keerthi Senthilnathan on 14-Aug-2017 
*          -- Set 'Upsell/Lift Sales Cycle Length Test' and 'RM New Department or Ship To Address' to false when 'SV Status' != 'Passed'
*          -- Case # 06190653

* Modified By: Keerthi Senthilnathan on 24-Apr-2018 
*          -- Update 'SV Status' based on the condition
*          -- Case # 07739056

**/
public class SVStatus{
    
    public static void updateSVStatus(List<Opportunity> OppList, Map<id,Opportunity> oldMap,Map<String, Double> currenMap){
        //Id standardRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standard_Opportunity').getRecordTypeId();
        Id standardRecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID;
        Id IMERecordTypeId = App_Constants.IME_STD_OPPORTUNITY_RECTYPE_ID;
        /*currenLst = new List<CurrencyType>();
//get all the Org Currency & conversions
currenLst = [Select Id, ConversionRate, ISOCode  from CurrencyType];
currenMap = new Map<String, Double>();
//put All the currency in the Map
for(CurrencyType objCurren: currenLst)
{
currenMap.put(objCurren.ISOCode , objCurren.ConversionRate);
}*/
        for(Opportunity OppNew : OppList){
            Opportunity Oppold = oldMap.get(OppNew.Id);
            //Get Custom setting values
            SVStatus__c svStsCustom = SVStatus__c.getValues('SVStatusPassed');
            system.debug('$$$$$$$$$$$$$$ Gopi'+svStsCustom);
            //get Redord Types Details 
            if(OppNew.Amount != Oppold.Amount || OppNew.Type != Oppold.Type|| OppNew.RecordtypeId != Oppold.RecordtypeId || OppNew.StageName != Oppold.StageName){
                //if((OppNew.Type == 'Up-Sell/Lift' || OppNew.Type == 'New Deal')&& (OppNew.StageName =='6 - Setup') &&((1/(currenMap.get(OppNew.currencyIsoCode)) * (OppNew.Amount = OppNew.Amount==null?0:OppNew.Amount)) < 24000 ) &&(recordType_Map.get(OppNew.RecordtypeId).Name=='Standard Opportunity')){
                List<string> opptTypes = new List<string>();
                if(svStsCustom.OpptType__c != null){
                    opptTypes = svStsCustom.OpptType__c.split(',');
                }
                //List<string> opptTypes = svStsCustom.OpptType__c.split(',');
                boolean checkTrue = false;
                for(string opType : opptTypes){
                    if((OppNew.Type == opType)&& (OppNew.StageName == svStsCustom.Stage__c) &&((1/(currenMap.get(OppNew.currencyIsoCode)) * (OppNew.Amount = OppNew.Amount==null?0:OppNew.Amount)) < svStsCustom.Amount__c) &&(OppNew.RecordtypeId == standardRecordTypeId)){
                        checkTrue = true;
                        break;
                    }
                }
                if(checkTrue)
                {
                    OppNew.Opportunity_Total_Annual_Amount_Test__c= true;
                }
                else
                {
                    if(OppNew.SV_Status__c != 'Passed'){
                        OppNew.Opportunity_Total_Annual_Amount_Test__c= false;
                        OppNew.Upsell_Lift_Sales_Cycle_Length_Test__c = false;
                        
                    }
                }
            }
            if(OppNew.OwnerId != Oppold.OwnerId)
            {
                if(OppNew.SV_Status__c != 'Passed'){
                    OppNew.Opportunity_Total_Annual_Amount_Test__c= false;
                    OppNew.Upsell_Lift_Sales_Cycle_Length_Test__c = false;
                    
                }
            }
            
            //Update 'SV Status' based on the condition for case#07739056
            
            //(If the opportunity RecordType is equal to Standard opportunity or IME Standard opportunity and opportunity status is equal to passed and any of the filed (Amount or ownerid or Type is equal to New deal or up-sell/Lift) in opportunity is changed then the opportunity status should be updated to Queued)
            if((OppNew.RecordTypeId == standardRecordTypeId || OppNew.RecordTypeId == IMERecordTypeId) && OppNew.SV_Status__c == 'Passed' && (OppNew.Amount != Oppold.Amount || OppNew.OwnerId != Oppold.OwnerId || (OppNew.Type != Oppold.Type && (OppNew.Type == 'New Deal' || OppNew.Type == 'Up-Sell/Lift'))))
            {
                OppNew.SV_Status__c = 'Queued';
                OppNew.Opportunity_Total_Annual_Amount_Test__c= false;
                OppNew.Upsell_Lift_Sales_Cycle_Length_Test__c = false;
                
            }
            
            //(If the opportunity RecordType is equal to Standard opportunity or IME Standard opportunity and opportunity Type is equal to Renewal then the opportunity status should be updated to Blank)
            if((OppNew.RecordTypeId == standardRecordTypeId || OppNew.RecordTypeId == IMERecordTypeId) && OppNew.Type == 'Renewal')
            {
                OppNew.SV_Status__c = '';
            } 
            
            //(If the opportunity RecordType is equal to IME Standard opportunity And Opportunity Type field is equal to 'New Deal' and Opportunity Total Annual Amount Test field checkbox is checked OR all the three Checkbox fields "Opportunity Total Annual Amount Test", "Upsell/Lift Sales Cycle Length Test" and "RM New Department or Ship To Address" is checked and Opportunity 'Type' field is equal to 'Up-Sell/Lift') 
            if(OppNew.RecordTypeId == IMERecordTypeId && (OppNew.Type == 'New Deal' && OppNew.Opportunity_Total_Annual_Amount_Test__c == TRUE) || (OppNew.Opportunity_Total_Annual_Amount_Test__c == TRUE && OppNew.Type == 'Up-Sell/Lift' && OppNew.Upsell_Lift_Sales_Cycle_Length_Test__c == TRUE && OppNew.New_Department_or_SKP_Shipto_Address__c == TRUE))
            {
                OppNew.SV_Status__c = 'Passed';
            }
            
            //(If the opportunity RecordType is equal to Standard opportunity or IME Standard opportunity AND Opportunity 'StageName' is equal to '6 - Setup' AND Opportunity 'SV Status' is equal to NULL AND either Opportunity 'Type' field is equal to 'New Deal' Or 'Up-Sell/Lift')
            if((OppNew.RecordTypeId == standardRecordTypeId || OppNew.RecordTypeId == IMERecordTypeId) && OppNew.StageName == '6 - Setup' && OppNew.SV_Status__c == NULL && (OppNew.Type == 'New Deal' || OppNew.Type == 'Up-Sell/Lift'))
            {
                OppNew.SV_Status__c = 'Queued';
            }
        } 
    }   
}
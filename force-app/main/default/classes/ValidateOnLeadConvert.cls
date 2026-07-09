/*     
Author       : Madhu Paladugu / Srinivasa rao Mandalapu
Created Date : 1/23/2013
Case No.     : 00662466
Description  : Added the logic to check the validation rules(Upsell_Opportunity_Quantity,Upsell_Opportunity_Detail_Rule,Upsell_Opportunity_Unit_of_Measure,UpSell_Sold_To_required_for_UpSell_Opt,Validate_Booked_Date_Early) while converting the lead.
*/  
public Class ValidateOnLeadConvert{
    
    public static Boolean NO_ERROR=false;
    
    public static void doValidate(Opportunity opp){    
        
        Opportunity leadopportunity=opp;
                system.debug(leadopportunity.Upsell_Customer_ID__c+'testing@@');
        if((leadopportunity.StageName == '0 - Pre-Qualification' || leadopportunity.StageName == '1 - Qualification' || leadopportunity.StageName == '2 - Solution Developed' || leadopportunity.StageName == '3 - Solution Agreed' || leadopportunity.StageName == '4 - Negotiate' || leadopportunity.StageName == 'Postponed') && leadopportunity.CloseDate < system.today()){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'Booked Date cannot be a date in the past in early stage opportunities');
            Apexpages.addMessage(errMsg1);          
        }
        else if(leadopportunity.StageName=='5 - Signed/PO in' || leadopportunity.StageName=='6 - Setup' || leadopportunity.StageName=='7 - Closed' || leadopportunity.StageName=='0 - Pre-Qualification' || leadopportunity.StageName==' Lost' || leadopportunity.StageName=='Dead' || leadopportunity.StageName=='Postponed' ){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'Stage should be 1 to 4 only while converting the lead');
            Apexpages.addMessage(errMsg1); 
        }
        
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        else if(leadopportunity.IM_Booked_Date__c<leadopportunity.CloseDate){
             Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'The First Bill Date must be greater or equal to the Booked Date.');
             Apexpages.addMessage(errMsg1); 
        }      
        else if(leadopportunity.Type=='Up-Sell/Lift' && (leadopportunity.IM_Up_Sell_Quantity__c==null ||leadopportunity.IM_Up_Sell_Quantity__c<=0)){
             Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'If Type is Up-Sell you must fill in the Up-Sell Quantity');
             Apexpages.addMessage(errMsg1); 
                
        }
        /* else if(leadopportunity.Type=='Up-Sell/Lift' && leadopportunity.IM_Up_Sell_Sold_To__c==null){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'If Type is Up-Sell, you must fill in the Up-Sell Oracle Account ID#');
            Apexpages.addMessage(errMsg1); 
        } */

        else if(leadopportunity.Type=='Up-Sell/Lift' && String.isBlank(leadopportunity.Upsell_Customer_ID__c)){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'If Type is Up-Sell, you must fill in the Up-Sell Customer Id');
            Apexpages.addMessage(errMsg1); 
        }
        else if(leadopportunity.Type=='Up-Sell/Lift' && leadopportunity.IM_Up_Sell_Detail__c==null){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'If Type is Up-Sell, you must fill in the Up-Sell Detail');
            Apexpages.addMessage(errMsg1);
        }
        else if(leadopportunity.Type=='Up-Sell/Lift' && leadopportunity.IM_Unit_of_Measure__c==null){
            Apexpages.Message errMsg1 = new Apexpages.Message(ApexPages.Severity.Fatal, 'If Type is Up-Sell you must fill in the Unit of Measure');
            Apexpages.addMessage(errMsg1); 
        }
       
        else{
           NO_ERROR=true;
        }

    }
}
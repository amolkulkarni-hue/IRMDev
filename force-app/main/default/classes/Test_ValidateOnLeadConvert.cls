/**
     *Author: Madhu Paladugu / Srinivasa rao Mandalapu
     *Date: 1/23/2013
     *Comments: Test class for 'ValidateLeadConvert class'
     */
     
     //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
@isTest(seeAllData=true)
private class Test_ValidateOnLeadConvert {

    public static testmethod  void  doTest(){
       
        Opportunity opp=[select id,StageName,IM_Booked_Date__c,CloseDate,Type,IM_Up_Sell_Quantity__c,IM_Up_Sell_Sold_To__c,IM_Up_Sell_Detail__c,IM_Unit_of_Measure__c from Opportunity limit 1];
         Opportunity opp1,opp2,opp3,opp4,opp5,opp6,opp7,opp8;
         
         opp1=opp;
         opp1.StageName='1 - Qualification';
         opp1.CloseDate=date.newinstance(1960, 2, 17);
         ValidateOnLeadConvert.doValidate(opp1);
         
         opp2=opp;
         opp2.StageName='5 - Signed/PO in';
         ValidateOnLeadConvert.doValidate(opp2);
         opp3=opp;
          
         opp3.StageName=' ';
         opp3.Type='Up-Sell/Lift';
         opp3.CloseDate=system.today();
         opp3.IM_Booked_Date__c=date.newinstance(1960, 2, 17);
         opp3.IM_Up_Sell_Quantity__c=null;
         ValidateOnLeadConvert.doValidate(opp3);
          
         opp4=opp;
         opp4.StageName=' ';
         opp4.CloseDate=date.newinstance(1960, 2, 17);
         opp4.IM_Booked_Date__c=system.today();
         opp4.Type='Up-Sell/Lift';
         opp4.IM_Up_Sell_Sold_To__c=null;
         opp4.IM_Up_Sell_Quantity__c=4;
         ValidateOnLeadConvert.doValidate(opp4);
            
         opp5=opp;
         opp5.StageName=' ';
         opp5.Type='Up-Sell/Lift';
         opp5.CloseDate=date.newinstance(1960, 2, 17);
         opp5.IM_Booked_Date__c=system.today();
         opp5.Type='Up-Sell/Lift';
         opp5.IM_Up_Sell_Sold_To__c='2';
         opp5.IM_Up_Sell_Quantity__c=4;
         opp5.IM_Up_Sell_Detail__c=null;
         ValidateOnLeadConvert.doValidate(opp5);
          
         opp6=opp;
         opp6.StageName=' ';
         opp6.Type='Up-Sell/Lift';
         opp6.CloseDate=date.newinstance(1960, 2, 17);
         opp6.IM_Booked_Date__c=system.today();
         opp6.IM_Up_Sell_Sold_To__c='2';
         opp6.IM_Up_Sell_Quantity__c=4;
         opp6.IM_Up_Sell_Detail__c='test';
         opp6.IM_Unit_of_Measure__c=null;
         ValidateOnLeadConvert.doValidate(opp6);
         
         opp7=opp;
         opp7.StageName=' ';
         opp7.Type='Up-Sell/Lift';
         opp7.CloseDate=date.newinstance(1960, 2, 17);
         opp7.IM_Booked_Date__c=system.today();
         opp7.IM_Up_Sell_Quantity__c=null;
         ValidateOnLeadConvert.doValidate(opp7);
          
         opp8=opp;
         opp8.StageName='';
         opp8.Type='test';
         ValidateOnLeadConvert.doValidate(opp8);
    }
}
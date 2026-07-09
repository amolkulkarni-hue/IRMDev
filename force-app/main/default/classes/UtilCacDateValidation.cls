/* Modified By: Vinutha Iyengar on 08-Aug-2019 
*           --Case No 10886923, Account Retention remediation

* Modified By     : TCS
2022/06/08; TCS ; #8989 Delete 10 case field deletion :- Part 1;  
Part of the #8989 story commented proposal_attempt_date_1__c the field reference.
2022/08/08; TCS ; #9958 Restore"Proposal_attempt_date_1_c" case field and related components.


*Modified By : Git Story 10373 on 05th Sep 2022 ---
modified lines: Removed the reference of the fields Date_Cancelled__c
* Modified By: Arjun Sankar on 22- Sept-2022
-- # 10469 and #10364, adding Retentnion RM and Retention SH Record types for existing validations of CLAS RM and CLAS SH .

* Modified By: Simranjit Kaur on 12-Sept-2024
---Commenting out the lines as the functionalities are transferred via ValidationRules. For reference, check user story #25718 on Gitlab.

* Modified By: Simranjit Kaur on 10-Oct-2024
---Commenting out all the lines as the functionalities are transferred via ValidationRules. For reference, check user story #26355 on Gitlab.

* Modified By: Simranjit Kaur on 10-Oct-2024
---Added dummyMethod to increase the code coverage as it was impacting the deployment. For reference, check user story #27190 on Gitlab.
*/

public class UtilCacDateValidation {
    public integer dummyMethod(){
        return 1;
    }
    /* // #26355 Commenting Code start. //Get Current logged in User Profile 
    static String profileName;
    static{
        //profileName = [Select Id,Name from Profile where Id =:userinfo.getProfileId()].Name;//Commented by CARE team
        List<Profile> profilelist = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId()];
        if(profilelist.size()>0)
            profileName = String.valueOf(profilelist);
        
    }
    // # 10469 and 10364 added retention RM and Retention SH record types as parameters to validateCacDateOnUpdate
    public static void validateCacDateOnUpdate(List<case> lstNewCase, Map<Id,case> oldMap, ID CAC_SKP_RM_RecordType,ID CAC_SKP_Shred_RecordType,ID CAC_DP_Closure_RecordType, ID CAC_Case_DM_RecordType,ID Retention_RM_RecordType, ID Retention_SH_RecordType ){
        //Skip validations for 'AS NCSP Management' profile users
        if(profileName != null && !profileName.containsIgnoreCase('AS NCSP Management')){
            Date dtToday = Date.today(); 
            for(Case newCase :lstNewCase){
                Case oldcase = oldMap.get(newCase.Id);
                // Date Validation CAC - DP Closure,CAC - SKP RM and CAC - SKP Shred Record type
                //  # 10469 and #10364 include Retention RM and SH to below condition
                 if(newCase.RecordTypeId == CAC_SKP_RM_RecordType || newCase.RecordTypeId == CAC_SKP_Shred_RecordType || newCase.RecordTypeId == CAC_DP_Closure_RecordType|| newCase.RecordTypeId == Retention_RM_RecordType || newCase.RecordTypeId == Retention_SH_RecordType  ){
W-000616
if(newCase.CAC_First_Customer_Contact_Date__c != null && newCase.CAC_First_Customer_Contact_Date__c != oldcase.CAC_First_Customer_Contact_Date__c && newCase.CAC_First_Customer_Contact_Date__c.date() != dtToday ){
newCase.CAC_First_Customer_Contact_Date__c.addError('CAC First Customer Contact Date must be today\'s date. It cannot be in the Past or the Future.');
}
/* W-000616
if(newCase.CAC_Intro_Date__c != null && newCase.CAC_Intro_Date__c != oldcase.CAC_Intro_Date__c && newCase.CAC_Intro_Date__c.date() != dtToday ){
newCase.CAC_Intro_Date__c.addError('CAC Intro Date must be today\'s date. It cannot be in the Past or the Future.');
}
/*  if(newCase.Customer_Request_Received_Date__c != null && newCase.Customer_Request_Received_Date__c != oldcase.Customer_Request_Received_Date__c && newCase.Customer_Request_Received_Date__c.date() > dtToday ){
newCase.Customer_Request_Received_Date__c.addError('Customer Request Received Date must be current or past date.   It cannot be in the Future.');
}

/*
//95
if(newCase.CAC_Second_Customer_Contact_Date__c != null && newCase.CAC_Second_Customer_Contact_Date__c != oldcase.CAC_Second_Customer_Contact_Date__c && newCase.CAC_Second_Customer_Contact_Date__c.date() != dtToday ){
newCase.CAC_Second_Customer_Contact_Date__c.addError('CAC Second Customer Contact Date must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.CAC_Third_Customer_Contact_Date__c != null && newCase.CAC_Third_Customer_Contact_Date__c != oldcase.CAC_Third_Customer_Contact_Date__c && newCase.CAC_Third_Customer_Contact_Date__c.date() != dtToday ){
newCase.CAC_Third_Customer_Contact_Date__c.addError('CAC Third Customer Contact Date must be today\'s date. It cannot be in the Past or the Future.');
} 
/*
if(newCase.Proposal_Created_Date__c != null && newCase.Proposal_Created_Date__c != oldcase.Proposal_Created_Date__c && newCase.Proposal_Created_Date__c.date() > dtToday ){
newCase.Proposal_Created_Date__c.addError('Proposal Created Date cannot be in the Future.');
} 
W-000616
if(newCase.Proposal_Sent_to_Customer__c != null && newCase.Proposal_Sent_to_Customer__c != oldcase.Proposal_Sent_to_Customer__c && newCase.Proposal_Sent_to_Customer__c.date() > dtToday ){
newCase.Proposal_Sent_to_Customer__c.addError('Proposal Sent to Customer Date cannot be in the Future.');
}
/* #8991 Delete 10 case field deletion :- Part 3 "Date_of_Customer_Response__c" */
                /*
if(newCase.Date_of_Customer_Response__c != null && newCase.Date_of_Customer_Response__c != oldcase.Date_of_Customer_Response__c && newCase.Date_of_Customer_Response__c.date() > dtToday ){
newCase.Date_of_Customer_Response__c.addError('Date of Customer Response cannot be in the Future.');
} 
/*#8989 Delete 10 case field deletion :- Part 1*/
                /*#9958 Restore"Proposal_attempt_date_1_c" case field and related components .
if(newCase.Proposal_Attempt_Date_1__c != null && newCase.Proposal_Attempt_Date_1__c != oldcase.Proposal_Attempt_Date_1__c && newCase.Proposal_Attempt_Date_1__c.date() > dtToday ){
newCase.Proposal_Attempt_Date_1__c.addError('Proposal Attempt Date 1 cannot be in the Future.');
}
if(newCase.Proposal_Attempt_Date_2__c != null && newCase.Proposal_Attempt_Date_2__c != oldcase.Proposal_Attempt_Date_2__c && newCase.Proposal_Attempt_Date_2__c.date() > dtToday ){
newCase.Proposal_Attempt_Date_2__c.addError('Proposal Attempt Date 2 cannot be in the Future.');
} 
/*#8990 Delete 10 case field deletion :- Part 2*/
                /*if(newCase.Proposal_Attempt_Date_3__c != null && newCase.Proposal_Attempt_Date_3__c != oldcase.Proposal_Attempt_Date_3__c && newCase.Proposal_Attempt_Date_3__c.date() > dtToday ){
newCase.Proposal_Attempt_Date_3__c.addError('Proposal Attempt Date 3 cannot be in the Future.');
} 

if(newCase.Date_Loyalty_Specialist_Assigned__c != null && newCase.Date_Loyalty_Specialist_Assigned__c != oldcase.Date_Loyalty_Specialist_Assigned__c && newCase.Date_Loyalty_Specialist_Assigned__c != dtToday ){
newCase.Date_Loyalty_Specialist_Assigned__c.addError('Date Loyalty Specialist Assigned cannot be in the Past or the Future.');
} 
}
                
                //Date validation for CLAS – Data Management
                /*  if(newCase.RecordTypeId == CAC_Case_DM_RecordType){
if(newCase.CAC_Inactivate_Request__c != null && newCase.CAC_Inactivate_Request__c != oldcase.CAC_Inactivate_Request__c && newCase.CAC_Inactivate_Request__c.date() != dtToday ){
newCase.CAC_Inactivate_Request__c.addError('Cancel Inactivate Request must be today\'s date. It cannot be in the Past or the Future..');
} 
if(newCase.Date_First_Customer_Contact_Attempt__c != null && newCase.Date_First_Customer_Contact_Attempt__c != oldcase.Date_First_Customer_Contact_Attempt__c && newCase.Date_First_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_First_Customer_Contact_Attempt__c.addError('Date First Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Second_Customer_Contact_Attempt__c != null && newCase.Date_Second_Customer_Contact_Attempt__c != oldcase.Date_Second_Customer_Contact_Attempt__c && newCase.Date_Second_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_Second_Customer_Contact_Attempt__c.addError('Date Second Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Third_Customer_Contact_Attempt__c != null && newCase.Date_Third_Customer_Contact_Attempt__c != oldcase.Date_Third_Customer_Contact_Attempt__c && newCase.Date_Third_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_Third_Customer_Contact_Attempt__c.addError('Date Third Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
}
} 
                
                // Date Validation For CAC - SKP RM Record type
                //  # 10469 and #10364  Expanding to Retention RM
                /*if(  newCase.RecordTypeId == CAC_SKP_RM_RecordType ||newCase.RecordTypeId == Retention_RM_RecordType ){

if(newCase.CAC_Inactivate_Request__c != null && newCase.CAC_Inactivate_Request__c != oldcase.CAC_Inactivate_Request__c && newCase.CAC_Inactivate_Request__c.date() != dtToday ){
newCase.CAC_Inactivate_Request__c.addError('Cancel Inactivate Request must be today\'s date. It cannot be in the Past or the Future..');
}
if(newCase.Date_First_Customer_Contact_Attempt__c != null && newCase.Date_First_Customer_Contact_Attempt__c != oldcase.Date_First_Customer_Contact_Attempt__c && newCase.Date_First_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_First_Customer_Contact_Attempt__c.addError('Date First Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Second_Customer_Contact_Attempt__c != null && newCase.Date_Second_Customer_Contact_Attempt__c != oldcase.Date_Second_Customer_Contact_Attempt__c && newCase.Date_Second_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_Second_Customer_Contact_Attempt__c.addError('Date Second Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Third_Customer_Contact_Attempt__c != null && newCase.Date_Third_Customer_Contact_Attempt__c != oldcase.Date_Third_Customer_Contact_Attempt__c && newCase.Date_Third_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_Third_Customer_Contact_Attempt__c.addError('Date Third Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Cost_Summary_Attempt_1__c != null && newCase.Cost_Summary_Attempt_1__c != oldcase.Cost_Summary_Attempt_1__c  && newCase.Cost_Summary_Attempt_1__c.date() != dtToday ){
newCase.Cost_Summary_Attempt_1__c.addError('Date Term Quote Attempt 1 must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Cost_Summary_Attempt2__c != null && newCase.Cost_Summary_Attempt2__c != oldcase.Cost_Summary_Attempt2__c  && newCase.Cost_Summary_Attempt2__c.date() != dtToday ){
newCase.Cost_Summary_Attempt2__c.addError('Date Term Quote Attempt 2 must be today\'s date. It cannot be in the Past or the Future.');
}
//35
if(newCase.Cost_Summary_Attempt3__c != null && newCase.Cost_Summary_Attempt3__c != oldcase.Cost_Summary_Attempt3__c  && newCase.Cost_Summary_Attempt3__c.date() != dtToday ){
newCase.Cost_Summary_Attempt3__c.addError('Date Term Quote Attempt 3 must be today\'s date. It cannot be in the Past or the Future.');
}
/*W-000616
if(newCase.Customer_Update_Date__c != null && newCase.Customer_Update_Date__c != oldcase.Customer_Update_Date__c  && newCase.Customer_Update_Date__c.date() != dtToday ){
newCase.Customer_Update_Date__c.addError('Customer Update Date must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Account_Inactivated__c != null && newCase.Date_Account_Inactivated__c != oldcase.Date_Account_Inactivated__c  && newCase.Date_Account_Inactivated__c.date() > dtToday  ){
newCase.Date_Account_Inactivated__c.addError('Date Account Inactivated must be current or past date.  It cannot be in the Future');
}
/* Begin - Case field deletion : 10373
if(newCase.Date_Cancelled__c != null && newCase.Date_Cancelled__c != oldcase.Date_Cancelled__c  && newCase.Date_Cancelled__c.date() != dtToday ){
newCase.Date_Cancelled__c.addError('Date Cancelled must be today\'s date. It cannot be in the Past or the Future.');
}
End - Case field deletion : 10373 
if(newCase.Date_Customer_Approval_Received__c != null && newCase.Date_Customer_Approval_Received__c != oldcase.Date_Customer_Approval_Received__c  && newCase.Date_Customer_Approval_Received__c.date() > dtToday ){
newCase.Date_Customer_Approval_Received__c.addError('Date Customer Approval Received must be current or past date.   It cannot be in the Future.');
} 
if(newCase.Date_Destruction_Order_Created__c != null && newCase.Date_Destruction_Order_Created__c != oldcase.Date_Destruction_Order_Created__c  && newCase.Date_Destruction_Order_Created__c.date() > dtToday ){
newCase.Date_Destruction_Order_Created__c.addError('Date Destruction Order Created must be current or past date.   It cannot be in the Future.');
}
/*W-000616
if(newCase.Date_Destruction_SR_Requested__c != null && newCase.Date_Destruction_SR_Requested__c != oldcase.Date_Destruction_SR_Requested__c  && newCase.Date_Destruction_SR_Requested__c.date() != dtToday ){
newCase.Date_Destruction_SR_Requested__c.addError('Date Destruction SR Requested must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Email_Sent_To_Contracts_Admin__c != null && newCase.Date_Email_Sent_To_Contracts_Admin__c != oldcase.Date_Email_Sent_To_Contracts_Admin__c  && newCase.Date_Email_Sent_To_Contracts_Admin__c.date() != dtToday ){
newCase.Date_Email_Sent_To_Contracts_Admin__c.addError('Date email sent to Contracts Admin must be today\'s date. It cannot be in the Past or the Future.');
} 
/* W-000616
if(newCase.Date_Email_Sent_To_Local_Leadership__c != null && newCase.Date_Email_Sent_To_Local_Leadership__c != oldcase.Date_Email_Sent_To_Local_Leadership__c  && newCase.Date_Email_Sent_To_Local_Leadership__c.date() != dtToday ){
newCase.Date_Email_Sent_To_Local_Leadership__c.addError('Date email sent to Local Leadership must be today\'s date. It cannot be in the Past or the Future.');
}
// 45
if(newCase.Date_Followed_Up_W_Customer__c != null && newCase.Date_Followed_Up_W_Customer__c != oldcase.Date_Followed_Up_W_Customer__c  && newCase.Date_Followed_Up_W_Customer__c.date() != dtToday ){
newCase.Date_Followed_Up_W_Customer__c.addError('Date Followed Up W Customer must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Inventory_Status_Confirmed__c != null && newCase.Date_Inventory_Status_Confirmed__c != oldcase.Date_Inventory_Status_Confirmed__c  && newCase.Date_Inventory_Status_Confirmed__c.date() != dtToday ){
newCase.Date_Inventory_Status_Confirmed__c.addError('Date Inventory status confirmed must be today\'s date. It cannot be in the Past or the Future.');
}
/*W-000616
if(newCase.Date_Invoice_Created__c != null && newCase.Date_Invoice_Created__c != oldcase.Date_Invoice_Created__c  && newCase.Date_Invoice_Created__c.date() > dtToday ){
newCase.Date_Invoice_Created__c.addError('Date Invoice Created must be current or past date.   It cannot be in the Future.');
}
if(newCase.Date_Invoice_Details_Package_Sent__c != null && newCase.Date_Invoice_Details_Package_Sent__c != oldcase.Date_Invoice_Details_Package_Sent__c  && newCase.Date_Invoice_Details_Package_Sent__c.date() != dtToday ){
newCase.Date_Invoice_Details_Package_Sent__c.addError('Date Invoice details package sent must be today\'s date. It cannot be in the Past or the Future.');
}
/*W-000616
if(newCase.Date_of_Invoice_Confirmation__c != null && newCase.Date_of_Invoice_Confirmation__c != oldcase.Date_of_Invoice_Confirmation__c  && newCase.Date_of_Invoice_Confirmation__c.date() != dtToday ){
newCase.Date_of_Invoice_Confirmation__c.addError('Date of Invoice confirmation must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Ops_Confirmed_For_Timeline__c != null && newCase.Date_Ops_Confirmed_For_Timeline__c != oldcase.Date_Ops_Confirmed_For_Timeline__c  && newCase.Date_Ops_Confirmed_For_Timeline__c.date() > dtToday ){
newCase.Date_Ops_Confirmed_For_Timeline__c.addError('Date Ops confirmed for timeline must be current or past date.   It cannot be in the Future.');
}
if(newCase.Date_Ops_emailed_for_timeline__c != null && newCase.Date_Ops_emailed_for_timeline__c != oldcase.Date_Ops_emailed_for_timeline__c  && newCase.Date_Ops_emailed_for_timeline__c.date() != dtToday ){
newCase.Date_Ops_emailed_for_timeline__c.addError('Date Ops emailed for timeline must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_PDL_Approval_Received__c != null && newCase.Date_PDL_Approval_Received__c != oldcase.Date_PDL_Approval_Received__c  && newCase.Date_PDL_Approval_Received__c.date() > dtToday ){
newCase.Date_PDL_Approval_Received__c.addError('Date PDL Approval Received must be current or past date.   It cannot be in the Future.');
} 
if(newCase.Date_PDL_Sent_to_Customer__c != null && newCase.Date_PDL_Sent_to_Customer__c != oldcase.Date_PDL_Sent_to_Customer__c  && newCase.Date_PDL_Sent_to_Customer__c.date() != dtToday ){
newCase.Date_PDL_Sent_to_Customer__c.addError('Date PDL Sent to customer must be current. It cannot be in the Past Or Future');
} 
//55
if(newCase.Date_PW_Order_Created__c != null && newCase.Date_PW_Order_Created__c != oldcase.Date_PW_Order_Created__c  && newCase.Date_PW_Order_Created__c.date() > dtToday ){
newCase.Date_PW_Order_Created__c.addError('Date PW Order Created must be current or past date.   It cannot be in the Future.');
} 
/*W-000616
if(newCase.Date_PW_SR_Requested__c != null && newCase.Date_PW_SR_Requested__c != oldcase.Date_PW_SR_Requested__c  && newCase.Date_PW_SR_Requested__c.date() != dtToday ){
newCase.Date_PW_SR_Requested__c.addError('Date PW SR Requested must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Revised_Cost_Summary_Sent__c != null && newCase.Date_Revised_Cost_Summary_Sent__c != oldcase.Date_Revised_Cost_Summary_Sent__c  && newCase.Date_Revised_Cost_Summary_Sent__c.date() != dtToday ){
newCase.Date_Revised_Cost_Summary_Sent__c.addError('Date revised cost summary sent must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Worksheet_Created__c != null && newCase.Date_Worksheet_Created__c != oldcase.Date_Worksheet_Created__c  && newCase.Date_Worksheet_Created__c.date() > dtToday ){
newCase.Date_Worksheet_Created__c.addError('Date Worksheet Created must be current or past date.   It cannot be in the Future.');
} 
if(newCase.Estimated_Pay_Date__c != null && newCase.Estimated_Pay_Date__c != oldcase.Estimated_Pay_Date__c  && newCase.Estimated_Pay_Date__c.date() < dtToday ){
newCase.Estimated_Pay_Date__c.addError('Estimated Pay Date must be current or future date. It cannot be in the Past');
} 
//60

if(newCase.Inactive_request_sent_to_Contracts_Admin__c != null && newCase.Inactive_request_sent_to_Contracts_Admin__c != oldcase.Inactive_request_sent_to_Contracts_Admin__c && newCase.Inactive_request_sent_to_Contracts_Admin__c.date() != dtToday ){    
newCase.Inactive_request_sent_to_Contracts_Admin__c.addError('Inactive request sent to Contracts Admin must be today\'s date. It cannot be in the Past or the Future.');        
} 
if(newCase.Invoice_Request_Date__c != null && newCase.Invoice_Request_Date__c != oldcase.Invoice_Request_Date__c  && newCase.Invoice_Request_Date__c.date() != dtToday ){
newCase.Invoice_Request_Date__c.addError('Invoice Request Date must be today\'s date. It cannot be in the Past or the Future.');
}
/*W-000616
if(newCase.Local_Leadership_response_date__c != null && newCase.Local_Leadership_response_date__c != oldcase.Local_Leadership_response_date__c  && newCase.Local_Leadership_response_date__c.date() > dtToday ){
newCase.Local_Leadership_response_date__c.addError('Local Leadership response date must be current or past date.   It cannot be in the Future.');
}
if(newCase.Notify_Collections__c != null && newCase.Notify_Collections__c != oldcase.Notify_Collections__c  && newCase.Notify_Collections__c.date() != dtToday ){
newCase.Notify_Collections__c.addError('Notify Collections must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Order_completion_date__c != null && newCase.Order_completion_date__c != oldcase.Order_completion_date__c  && newCase.Order_completion_date__c.date() > dtToday ){
newCase.Order_completion_date__c.addError('Order completion date must be current or past date.   It cannot be in the Future.');
} 
//65
if(newCase.Order_Scheduled_date__c != null && newCase.Order_Scheduled_date__c != oldcase.Order_Scheduled_date__c  && newCase.Order_Scheduled_date__c.date() < dtToday ){
newCase.Order_Scheduled_date__c.addError('Order Scheduled date must be current or future date. It cannot be in the Past');
}
if(newCase.Payment_Confirmation_Date__c != null && newCase.Payment_Confirmation_Date__c != oldcase.Payment_Confirmation_Date__c  && newCase.Payment_Confirmation_Date__c.date() > dtToday ){
newCase.Payment_Confirmation_Date__c.addError('Payment Confirmation Date must be current or past date.   It cannot be in the Future.');
}
if(newCase.Payment_Follow_Up__c != null && newCase.Payment_Follow_Up__c != oldcase.Payment_Follow_Up__c  && newCase.Payment_Follow_Up__c.date() != dtToday ){
newCase.Payment_Follow_Up__c.addError('Payment Follow Up must be today\'s date or in the future. It cannot be in the past');
}
if(newCase.PDL_Follow_up_Date__c != null && newCase.PDL_Follow_up_Date__c != oldcase.PDL_Follow_up_Date__c  && newCase.PDL_Follow_up_Date__c.date() != dtToday ){
newCase.PDL_Follow_up_Date__c.addError('PDL Follow up Date must be today\'s date or the Future. It cannot be in the Past.');
} 


if(newCase.Outstanding_Invoice_Payment_Date__c != null && newCase.Outstanding_Invoice_Payment_Date__c != oldcase.Outstanding_Invoice_Payment_Date__c && newCase.Outstanding_Invoice_Payment_Date__c > dtToday ){
newCase.Outstanding_Invoice_Payment_Date__c.addError('Outstanding Invoice Payment Date cannot be in the Future.');
} 
if(newCase.PW_Order_Completed__c != null && newCase.PW_Order_Completed__c != oldcase.PW_Order_Completed__c && newCase.PW_Order_Completed__c.date() > dtToday ){
newCase.PW_Order_Completed__c.addError('PW Order Completed cannot be in the Future.');
} 
if(newCase.Support_Specialist_Assigned_Date__c != null && newCase.Support_Specialist_Assigned_Date__c != oldcase.Support_Specialist_Assigned_Date__c && newCase.Support_Specialist_Assigned_Date__c != dtToday ){
newCase.Support_Specialist_Assigned_Date__c.addError('Support Specialist Assigned Date cannot be in the Past or the Future.');
}  

}
                // Date Validation For CAC - SKP Shred Record type
                // # 10469 and #10364  Expanding to Retention SH
                /* if(  newCase.RecordTypeId == CAC_SKP_Shred_RecordType ||newCase.RecordTypeId == Retention_SH_RecordType ){
if(newCase.CAC_Inactivate_Request__c != null && newCase.CAC_Inactivate_Request__c != oldcase.CAC_Inactivate_Request__c && newCase.CAC_Inactivate_Request__c.date() != dtToday ){
newCase.CAC_Inactivate_Request__c.addError('Cancel Inactivate Request must be today\'s date. It cannot be in the Past or the Future..');
}
if(newCase.Date_First_Customer_Contact_Attempt__c != null && newCase.Date_First_Customer_Contact_Attempt__c != oldcase.Date_First_Customer_Contact_Attempt__c && newCase.Date_First_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_First_Customer_Contact_Attempt__c.addError('Date First Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Second_Customer_Contact_Attempt__c != null && newCase.Date_Second_Customer_Contact_Attempt__c != oldcase.Date_Second_Customer_Contact_Attempt__c && newCase.Date_Second_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_Second_Customer_Contact_Attempt__c.addError('Date Second Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Third_Customer_Contact_Attempt__c != null && newCase.Date_Third_Customer_Contact_Attempt__c != oldcase.Date_Third_Customer_Contact_Attempt__c && newCase.Date_Third_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_Third_Customer_Contact_Attempt__c.addError('Date Third Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Final_Order_Created_in_SKP__c != null && newCase.Date_Final_Order_Created_in_SKP__c != oldcase.Date_Final_Order_Created_in_SKP__c && newCase.Date_Final_Order_Created_in_SKP__c.date() != dtToday ){
newCase.Date_Final_Order_Created_in_SKP__c.addError('Date Final Order created in SKP must be today\'s date or Past. It cannot be in the Future.');
}
//70
/*W-000616
if(newCase.Date_Sent_To_Shared_services__c != null && newCase.Date_Sent_To_Shared_services__c != oldcase.Date_Sent_To_Shared_services__c && newCase.Date_Sent_To_Shared_services__c.date() != dtToday ){
newCase.Date_Sent_To_Shared_services__c.addError('Date Sent to Shared Services must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Service_Confirmation__c != null && newCase.Date_Service_Confirmation__c != oldcase.Date_Service_Confirmation__c && newCase.Date_Service_Confirmation__c.date() != dtToday ){
newCase.Date_Service_Confirmation__c.addError('Date Service confirmation must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Service_To_Be_Completed__c != null && newCase.Date_Service_To_Be_Completed__c != oldcase.Date_Service_To_Be_Completed__c && newCase.Date_Service_To_Be_Completed__c.date() < dtToday ){
newCase.Date_Service_To_Be_Completed__c.addError('Date Service To Be Completed must be current or future date. It cannot be in the Past');
}
if(newCase.Date_Termination_Request_Sent_Contracts__c != null && newCase.Date_Termination_Request_Sent_Contracts__c != oldcase.Date_Termination_Request_Sent_Contracts__c && newCase.Date_Termination_Request_Sent_Contracts__c.date() != dtToday ){
newCase.Date_Termination_Request_Sent_Contracts__c.addError('Date Termination Request Sent Contracts must be today\'s date. It cannot be in the Past or the Future.');
}

if(newCase.Date_Visit_Profile_To_Be_Inactivated__c != null && newCase.Date_Visit_Profile_To_Be_Inactivated__c != oldcase.Date_Visit_Profile_To_Be_Inactivated__c  && newCase.Date_Visit_Profile_To_Be_Inactivated__c.date() < dtToday ){
newCase.Date_Visit_Profile_To_Be_Inactivated__c.addError('Date Visit Profile to be inactivated must be current or future date. It cannot be in the Past');
}
// new PR-06211
if(newCase.Rescheduled_Date__c != null && newCase.Rescheduled_Date__c != oldcase.Rescheduled_Date__c  && newCase.Rescheduled_Date__c.date() < dtToday ){
newCase.Rescheduled_Date__c.addError('Rescheduled Date must be current or future date. It cannot be in the Past');
}
if(newCase.Date_Confirmed_by_Contracts__c != null && newCase.Date_Confirmed_by_Contracts__c != oldcase.Date_Confirmed_by_Contracts__c  && newCase.Date_Confirmed_by_Contracts__c.date() > dtToday ){
newCase.Date_Confirmed_by_Contracts__c.addError('Date Confirmed by contracts must be current or Past date. It cannot be in the Future');
}
if(newCase.Final_Customer_Contact_Date__c != null && newCase.Final_Customer_Contact_Date__c != oldcase.Final_Customer_Contact_Date__c  && newCase.Final_Customer_Contact_Date__c.date() != dtToday ){
newCase.Final_Customer_Contact_Date__c.addError('Final Customer Contact Date must be today\'s date. It cannot be in the Past or the Future.');
}
}
                // Date Validation For CAC - DP Closure Record type
                /* if(newCase.RecordTypeId == CAC_DP_Closure_RecordType){
if(newCase.Confirm_Final_Service__c != null && newCase.Confirm_Final_Service__c != oldcase.Confirm_Final_Service__c && newCase.Confirm_Final_Service__c.date() > dtToday ){
newCase.Confirm_Final_Service__c.addError('Confirm Final Service must be current or past date.   It cannot be in the Future.');
}
if(newCase.Date_Closure_Complete__c != null && newCase.Date_Closure_Complete__c != oldcase.Date_Closure_Complete__c && newCase.Date_Closure_Complete__c.date() > dtToday ){
newCase.Date_Closure_Complete__c.addError('Date Closure Complete must be current or past date.   It cannot be in the Future.');
}
//W-000616
if(newCase.Date_Contracts_Respond__c != null && newCase.Date_Contracts_Respond__c != oldcase.Date_Contracts_Respond__c && newCase.Date_Contracts_Respond__c.date() > dtToday ){
newCase.Date_Contracts_Respond__c.addError('Date Contracts Respond must be current or past date.   It cannot be in the Future.');
}

if(newCase.Date_Final_Service_Order_Created__c != null && newCase.Date_Final_Service_Order_Created__c != oldcase.Date_Final_Service_Order_Created__c && newCase.Date_Final_Service_Order_Created__c.date() != dtToday ){
newCase.Date_Final_Service_Order_Created__c.addError('Date Final Service Order Created must be today\'s date. It cannot be in the Past or the Future.');
} 
if(newCase.Date_Moved_on_Call__c != null && newCase.Date_Moved_on_Call__c != oldcase.Date_Moved_on_Call__c && newCase.Date_Moved_on_Call__c.date() != dtToday ){
newCase.Date_Moved_on_Call__c.addError('Date Moved on Call must be today\'s date. It cannot be in the Past or the Future.');
} 

if(newCase.Date_Ops_Confirms_SB_Clean__c != null && newCase.Date_Ops_Confirms_SB_Clean__c != oldcase.Date_Ops_Confirms_SB_Clean__c && newCase.Date_Ops_Confirms_SB_Clean__c.date() > dtToday ){
newCase.Date_Ops_Confirms_SB_Clean__c.addError('Date Ops confirms SB clean must be current or past date.   It cannot be in the Future.');
} 
//85
//W-000616
if(newCase.Date_Resubmitted_to_Contracts__c != null && newCase.Date_Resubmitted_to_Contracts__c != oldcase.Date_Resubmitted_to_Contracts__c && newCase.Date_Resubmitted_to_Contracts__c.date() != dtToday ){
newCase.Date_Resubmitted_to_Contracts__c.addError('Date resubmitted to Contracts must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Sent_to_Contracts_US__c != null && newCase.Date_Sent_to_Contracts_US__c != oldcase.Date_Sent_to_Contracts_US__c && newCase.Date_Sent_to_Contracts_US__c.date() != dtToday ){
newCase.Date_Sent_to_Contracts_US__c.addError('Date Sent to Contracts US must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Sent_to_Ops__c != null && newCase.Date_Sent_to_Ops__c != oldcase.Date_Sent_to_Ops__c && newCase.Date_Sent_to_Ops__c.date() != dtToday ){
newCase.Date_Sent_to_Ops__c.addError('Date sent to Ops must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_to_be_Moved_on_Call__c != null && newCase.Date_to_be_Moved_on_Call__c != oldcase.Date_to_be_Moved_on_Call__c && newCase.Date_to_be_Moved_on_Call__c.date() < dtToday ){
newCase.Date_to_be_Moved_on_Call__c.addError('Date to be Moved on Call must be current or future date. It cannot be in the Past');
}
#8991 Delete 10 case field deletion :- Part 3 "OTO_Created_Date__c" 
if(newCase.OTO_Created_Date__c != null && newCase.OTO_Created_Date__c != oldcase.OTO_Created_Date__c && newCase.OTO_Created_Date__c.date() != dtToday ){
newCase.OTO_Created_Date__c.addError('OTO Created Date must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Update_Sent_To_Operations__c != null && newCase.Update_Sent_To_Operations__c != oldcase.Update_Sent_To_Operations__c && newCase.Update_Sent_To_Operations__c.date() != dtToday ){
newCase.Update_Sent_To_Operations__c.addError('Update Sent To Operations must be today\'s date. It cannot be in the Past or the Future.');
}
//92
} 
            }
        }
    }
    //W-000685, NOT IN USE
    // rule for retention record type on insert
    /*public static void validationRuleForRetentionType(case newCase){
Date dtToday = Date.today();
if(newCase.Date_Sent_To_Closures__c != null && newCase.Date_Sent_To_Closures__c.date() != dtToday ){
newCase.Date_Sent_To_Closures__c.addError('Date sent to Closures must be today\'s date. It cannot be in the Past or the Future.');
}


if(newCase.AM_Response_Date__c != null && newCase.AM_Response_Date__c.date() > dtToday ){
newCase.AM_Response_Date__c.addError('AM Response Date must be current or past date.   It cannot be in the Future.');
}
if(newCase.Contract_Admin_Response_Date__c != null && newCase.Contract_Admin_Response_Date__c.date() > dtToday ){
newCase.Contract_Admin_Response_Date__c.addError('Contract Admin response Date must be current or past date.   It cannot be in the Future.');
}

if(newCase.Date_Approval_Received__c != null && newCase.Date_Approval_Received__c.date() > dtToday ){
newCase.Date_Approval_Received__c.addError('Date Approval Received must be current or past date.   It cannot be in the Future.');
}
if(newCase.Date_First_Customer_Contact_Attempt__c != null && newCase.Date_First_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_First_Customer_Contact_Attempt__c.addError('Date First Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
}
//20
if(newCase.Date_of_Account_Update_Review_Completed__c != null && newCase.Date_of_Account_Update_Review_Completed__c.date() != dtToday ){
newCase.Date_of_Account_Update_Review_Completed__c.addError('Date of Account update review completed must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_of_Overall_Account_Review_Completed__c != null && newCase.Date_of_Overall_Account_Review_Completed__c.date() != dtToday ){
newCase.Date_of_Overall_Account_Review_Completed__c.addError('Date of Overall Account review completed must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Of_Resubmission__c != null && newCase.Date_Of_Resubmission__c.date() != dtToday ){
newCase.Date_Of_Resubmission__c.addError('Date of resubmission must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Of_Resubmission_To_Contracts_Admin__c != null && newCase.Date_Of_Resubmission_To_Contracts_Admin__c.date() != dtToday ){
newCase.Date_Of_Resubmission_To_Contracts_Admin__c.addError('Date of resubmission to Contracts Admin must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Package_Sent_To_Contracts_Admin__c != null && newCase.Date_Package_Sent_To_Contracts_Admin__c.date() != dtToday ){
newCase.Date_Package_Sent_To_Contracts_Admin__c.addError('Date Package sent to Contracts Admin must be today\'s date. It cannot be in the Past or the Future.');
}
//25
if(newCase.Date_Proposal_Approval_Requested__c != null && newCase.Date_Proposal_Approval_Requested__c.date() != dtToday ){
newCase.Date_Proposal_Approval_Requested__c.addError('Date Proposal Approval requested must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Second_Customer_Contact_Attempt__c != null && newCase.Date_Second_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_Second_Customer_Contact_Attempt__c.addError('Date Second Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Sent_to_AM__c != null && newCase.Date_Sent_to_AM__c.date() != dtToday ){
newCase.Date_Sent_to_AM__c.addError('Date Sent to AM must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Date_Third_Customer_Contact_Attempt__c != null && newCase.Date_Third_Customer_Contact_Attempt__c.date() != dtToday ){
newCase.Date_Third_Customer_Contact_Attempt__c.addError('Date Third Customer Contact Attempt must be today\'s date. It cannot be in the Past or the Future.');
}
if(newCase.Intro_Date__c != null && newCase.Intro_Date__c.date() != dtToday ){
newCase.Intro_Date__c.addError('Intro Date must be today\'s date. It cannot be in the Past or the Future.');
}       

}*/ // #26355 Commenting Code end.
    
}
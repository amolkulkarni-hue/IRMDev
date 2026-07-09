@isTest(seeAllData=true)
public class Test_CallingUpdateOppRecords {
    static testmethod void test() {
        List<Id> lstOppIdThatChangeStage=new List<Id>();
        List<String> NCSP_StatusList=new List<String>();
        List<String> StageNamelist=new List<String>();
        List<Date> Service_Completed_Entered_DateList=new List<Date>();
        List<String> IM_Reason_LostListl=new List<String>();
        List<Opportunity> optylist = new List<Opportunity>();
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        Account A = new Account(name='Account4TestMethod'+system.now(), BillingCountry='United States');
        insert A;
        Opportunity opty = new Opportunity(Name='Test',IM_Booked_Date__c=System.today()+10,CloseDate = Date.Today(),NCSP_Status__c='Custom Setup',StageName='1 - Qualification',Service_Completed_Entered_Date__c=System.today(),IM_Reason_Lost__c='Decision Location', AccountId = A.Id);
        optylist.add(opty);
        insert optylist;
        for(Opportunity op: optylist){
            lstOppIdThatChangeStage.add(op.Id);
            NCSP_StatusList.add(op.NCSP_Status__c);
            StageNamelist.add(op.StageName);
            Service_Completed_Entered_DateList.add(op.Service_Completed_Entered_Date__c);
            IM_Reason_LostListl.add(op.IM_Reason_Lost__c);
            
        }
            
        CallingUpdateOppRecords cur = new CallingUpdateOppRecords();
        CallingUpdateOppRecords.doUpdate(lstOppIdThatChangeStage,NCSP_StatusList,StageNamelist,Service_Completed_Entered_DateList,IM_Reason_LostListl);
       
    }
}
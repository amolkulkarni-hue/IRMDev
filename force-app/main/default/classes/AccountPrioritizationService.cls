/* Commenting the entire code as part of Gitlab #24448 */
public with sharing class AccountPrioritizationService {
    public AccountPrioritizationService(){
        
    }
/*
    //private final Set<String> APLanRecordTypes = new Set<String>{'IMNA_Account_Brief','IMNA_Account_Plan','IME_Account_Plan_Draft'};
    private final Map<String, Id> APLanRecordTypes;

    private Priority_Batch_Settings__c settings;
    private List<User> reps;
    private Set<Id> repIds;
    private Boolean isOk;
    private Map<Id, List<Priority__c>> userPriorities;
    private Map<Id, List<Priority__c>> accountPriorities;
    private List<Priority__c> allPriorities;
    private Map<Id, Priority_Plan__c> userPlans;
    private Map<Id, List<Account>> userAccounts;
    private List<Account> allAccounts;
    private Set<Id> accountIds;
    private Map<Id, List<SFDC_Acct_Plan__c>> accountAPlans;
    private Map<Id, Iron_Mountain_Storage_Profile__c> accountSProfiles;
    private List<SFDC_Acct_Plan__c> allAPlans;
    private Map<Id, SFDC_Acct_Plan__c> aplanMap;
    private Map<Id, SFDC_Acct_Plan__c> plansToUpdate = new Map<Id, SFDC_Acct_Plan__c>();

    public AccountPrioritizationService(Priority_Batch_Settings__c settings){
        this.settings = settings;
        this.isOk = true;
        APLanRecordTypes = new Map<String, Id>();
        for(RecordType r:[SELECT Id, Name FROM RecordType WHERE sObjectType='SFDC_Acct_Plan__c' AND Name IN (:settings.FULL_Record_Type_Name__c,:settings.BRIEF_Record_Type_Name__c)]){
            APLanRecordTypes.put(r.Name, r.Id);
        }
    }

    public Boolean prioritizeForReps(List<User> reps){
        this.reps = reps;
        repIds = new Set<Id>();
        for(User u: reps){ repIds.add(u.Id); }
        getAccounts();
        createPriorityPlans();
        createPriorities();
        return isOk;
    }
    
    private void getAccounts(){
        if(accountIds==null) accountIds = new Set<Id>();
        if(allAccounts==null){
            if(userAccounts==null){ userAccounts = new Map<Id, List<Account>>(); }
            allAccounts = [SELECT Id, Name, IMGA_Owner__c, Account_At_Risk_Flag__c FROM Account WHERE IM_Hierarchy_Level__c='IM Group (IMGA)' AND IMGA_Owner__c IN :repIds];
            List<Account> accounts;
            if(allAccounts!=null && allAccounts.size()>0){
                for(Account a: allAccounts){
                    accountIds.add(a.Id);
                    accounts = userAccounts.get(a.IMGA_Owner__c);
                    if(accounts==null){ 
                        accounts = new List<Account>(); 
                        userAccounts.put(a.IMGA_Owner__c, accounts);
                    }
                    accounts.add(a);
                }
            }
        }
    }

    private void createPriorityPlans(){
        if(userPlans == null) userPlans = new Map<Id, Priority_Plan__c>();
        // Deactivate all existing Priority_Plan__c objects for the given reps
        List<Priority_Plan__c> existingPlans = [SELECT Id, Start_Date__c, End_Date__c, OwnerId FROM Priority_Plan__c WHERE OwnerId IN :repIds];
        for(Priority_Plan__c plan: existingPlans){
            if(plan.Start_Date__c==settings.Start_Date__c && plan.End_Date__c==settings.End_Date__c){
                plan.Is_Active__c = true;
                plan.Last_Batch_Run_Date__c = Date.today();
                plan.Batch_Run__c = true;
                userPlans.put(plan.OwnerId, plan);
            }else{
                plan.Is_Active__c = false;
            }
        }
        update existingPlans;

        // Cycle through each rep, and create a Priority_Plan__c object
        for(User rep: reps){
            List<Account> thisUsersAccounts = userAccounts.get(rep.Id);
            if(thisUsersAccounts==null || thisUsersAccounts.size()<1) continue;
            Priority_Plan__c plan = userPlans.get(rep.Id);
            if(plan!=null) continue;
            String rname = rep.Name;
            if(String.isNotBlank(rep.LastName)){
                rname = rep.LastName;
                if(String.isNotBlank(rep.FirstName)){
                    rname = rep.FirstName.trim().substring(0,1)+'. '+rname;
                }
            }
            plan = new Priority_Plan__c(
                OwnerId= rep.Id,
                Name = rname+' '+String.valueOf(settings.Start_Date__c)+' to '+String.valueOf(settings.End_Date__c),
                Is_Active__c= true,
                Batch_Run__c = true,
                Last_Batch_Run_Date__c = Date.today(),
                Start_Date__c= settings.Start_Date__c,
                End_Date__c= settings.End_Date__c
            );
            userPlans.put(rep.Id, plan);
        }

        // Insert new Priority Plans
        upsert userPlans.values();
    }

    private void createPriorities(){
        // Cycle through each rep and call createRepPriorities()
        userPriorities = new Map<Id, List<Priority__c>>();
        //allPriorities = new List<Priority__c>();
        for(User u:reps){
            List<Priority__c> priorities = createRepPriorities(u);
            userPriorities.put(u.Id, priorities);
            //allPriorities.addAll(priorities);
        }
        update plansToUpdate.values();

        // Upsert the returned list of Priority records
        upsert allPriorities;
    }

    private List<Priority__c> createRepPriorities(User rep){
        // Find or Create SFDC_Acct_Plan__c records for each of those IMGAs.  New Account Plans will be created only if there is not already an active plan of type “Territory Rep,” “National/Vertical BDE Plan,” or “National/Vertical BDE Brief.”
        if(allAPlans==null){
            if(accountAPlans==null){ accountAPlans = new Map<Id, List<SFDC_Acct_Plan__c>>(); }
            allAPlans = [SELECT Id, Name, OwnerId, Account__c, Plan_Status__c FROM SFDC_Acct_Plan__c WHERE Created_by_batch__c = true AND Account__c IN :accountIds AND RecordTypeId IN :APLanRecordTypes.values() AND Plan_Status__C NOT IN ('Approved','Rejected')];
            for(SFDC_Acct_Plan__c aplan: allAPlans){
                List<SFDC_Acct_Plan__c> plans = accountAPlans.get(aplan.Account__c);
                if(plans==null){
                    plans = new List<SFDC_Acct_Plan__c>();
                    accountAPlans.put(aplan.Account__c, plans);
                }
                plans.add(aplan);
            }
            if(accountSProfiles==null){ accountSProfiles = new Map<Id, Iron_Mountain_Storage_Profile__c>(); }
            for(Iron_Mountain_Storage_Profile__c p: [SELECT Id, Account__c, IM_Quantity_Cube__c, Whitespace_Cube__c FROM Iron_Mountain_Storage_Profile__c WHERE Account__c IN :accountIds ORDER BY LastModifiedDate DESC]){
                Iron_Mountain_Storage_Profile__c profile = accountSProfiles.get(p.Account__c);
                if(profile==null){
                    accountSProfiles.put(p.Account__c, p);
                }
            }

            for(Account a:allAccounts){
                List<SFDC_Acct_Plan__c> plans = accountAPlans.get(a.Id);
                if(plans==null){
                    plans = new List<SFDC_Acct_Plan__c>();
                    accountAPlans.put(a.Id, plans);
                }
                if(plans.size()==0){
                    SFDC_Acct_Plan__c plan = new SFDC_Acct_Plan__c(
                        Account__c = a.Id,
                        Name = a.Name + ' Plan',
                        OwnerId = a.IMGA_Owner__c,
                        Plan_Status__c = 'Not Started',
                        RecordTypeId = APLanRecordTypes.get(settings.BRIEF_Record_Type_Name__c),
                        Created_by_batch__c = true
                    );
                    allAPlans.add(plan);
                    plans.add(plan);
                    system.debug(plan);
                }
            }

            upsert allAPlans;

            aplanMap = new Map<Id, SFDC_Acct_Plan__c>();
            for(SFDC_Acct_Plan__c a:allAPlans){ 
                aplanMap.put(a.Id, a);
                accountAPlans.get(a.Account__c).add(a);
            }
        }


        // For each IMGA, find or create a Priority__c record, and populate with data
        if(accountPriorities==null) accountPriorities = new Map<Id, List<Priority__c>>();
        if(allPriorities==null){
            allPriorities = [SELECT Id, OwnerId, IMGA__c, Account_Plan__c, IM_Volume__c, Non_IM_Volume__c, Plan_Type__c, Risk_Profile__c FROM Priority__c WHERE Account_Plan__c IN :aplanMap.keySet()];
            for(Priority__c p:allPriorities){
                List<Priority__c> t_priorities = accountPriorities.get(p.IMGA__c);
                if(t_priorities==null){
                    t_priorities = new List<Priority__c>();
                    accountPriorities.put(p.IMGA__c, t_priorities);
                }
                t_priorities.add(p);
            }

            for(Account a: allAccounts){
                //TODO: figure out how to determine which is the active account plan
                SFDC_Acct_Plan__c aplan = accountAPlans.get(a.Id)[0];
                List<Priority__c> t_priorities = accountPriorities.get(a.Id);
                if(t_priorities==null){
                    t_priorities = new List<Priority__c>();
                    accountPriorities.put(a.Id, t_priorities);
                }
                Iron_Mountain_Storage_Profile__c profile = accountSProfiles.get(a.Id);
                Priority__c p;
                if(t_priorities.size()==0){
                    p = new Priority__c(
                        IMGA__c = a.Id,
                        Account_Plan__c = aplan.Id
                    );
                    t_priorities.add(p);
                    allPriorities.add(p);
                }else{
                    p = t_priorities[0];
                }
                p.Name = a.Name + ' Workbook';
                p.OwnerId = a.IMGA_Owner__c;
                p.IM_Volume__c = profile!=null && profile.IM_Quantity_Cube__c!=null ? profile.IM_Quantity_Cube__c : 0;
                p.Non_IM_Volume__c = profile!=null && profile.Whitespace_Cube__c!=null ? profile.Whitespace_Cube__c : 0;
                p.Plan_Type__c = 'Brief';
                p.Deadline__c = settings.End_Date__c;
                p.Risk_Profile__c = ( a.Account_At_Risk_Flag__c == null ? null :
                                            a.Account_At_Risk_Flag__c.containsIgnoreCase('Low Risk') ? 'Low' :
                                            a.Account_At_Risk_Flag__c.containsIgnoreCase('Medium Risk') ? 'Medium' :
                                            a.Account_At_Risk_Flag__c.containsIgnoreCase('High Risk') ? 'High' : null );
            }
        }

        List<Priority__c> myPriorities = new List<Priority__c>();
        for(Priority__c p:allPriorities){
            if(p.OwnerId == rep.Id){
                myPriorities.add(p);
            }
        }

        // Call prioritize() on these priority records
        List<Priority__c> ordered = prioritize(myPriorities,rep);

        // Return list of Priority__c records
        return ordered;
    }

    private List<Priority__c> prioritize(List<Priority__c> priorities, User rep){
        List<Priority__c> ordered = new List<Priority__c>();
        /*
        // Run through set of priorities, and determine which should be prioritized based on algorithm given by Bain
        // For each record given priority recommendation, add to rep’s Priority Plan
        // For each record, set corresponding Account Plan record type to Plan or Brief, as appropriate 
        // Return updated list
        * /
        Integer MAX_FULL = 9;
        Integer LARGEST = 3;
        List<PriorityByNonImVolume> nonImVolume = new List<PriorityByNonImVolume>();
        List<PriorityByImVolume> imVolume = new List<PriorityByImVolume>();
        for(Priority__c p: priorities){
            if(p.Non_IM_Volume__c >= settings.Non_IM_Volume_Threshhold__c){
                p.Centralized_Prioritization__c = true;
                p.Reason_for_Priority__c = 'Non-IM Volume >= '+settings.Non_IM_Volume_Threshhold__c;
                ordered.add(p);
                p.Plan_Type__c = ordered.size()>=MAX_FULL ? 'Brief' : 'Plan';
            }else if(p.IM_Volume__c >= settings.IM_Volume_Threshhold__c){
                p.Centralized_Prioritization__c = true;
                p.Reason_for_Priority__c = 'IM Volume >= '+settings.IM_Volume_Threshhold__c;
                ordered.add(p);
                p.Plan_Type__c = ordered.size()>=MAX_FULL ? 'Brief' : 'Plan';
            }else{
                nonImVolume.add(new PriorityByNonImVolume(p));
                imVolume.add(new PriorityByImVolume(p));
            }
        }
        nonImVolume.sort();
        while(nonImVolume.size()>LARGEST && nonImVolume.size()>0){ nonImVolume.remove(0); }
        for(PriorityByNonImVolume p: nonImVolume){
            Priority__c pri = p.pri;
            pri.Centralized_Prioritization__c = true;
            pri.Reason_for_Priority__c = 'Non-IM Volume in Top 3';
            ordered.add(pri);
            pri.Plan_Type__c = ordered.size()>=MAX_FULL ? 'Brief' : 'Plan';
        }
        imVolume.sort();
        while(imVolume.size()>LARGEST && nonImVolume.size()>0){ nonImVolume.remove(0); }
        for(PriorityByImVolume p: imVolume){
            Priority__c pri = p.pri;
            pri.Centralized_Prioritization__c = true;
            pri.Reason_for_Priority__c = 'IM Volume in Top 3';
            ordered.add(pri);
            pri.Plan_Type__c = ordered.size()>=MAX_FULL ? 'Brief' : 'Plan';
        }
        for(Priority__c p:priorities){
            if(p.Contract_Renewal_Date__c==null) continue;
            if(p.Centralized_Prioritization__c==true) continue;
            if(p.Contract_Renewal_Date__c < Date.today().addMonths(12)){
                p.Centralized_Prioritization__c = true;
                p.Reason_for_Priority__c = 'Contract Renewal Within 12 Months';
                ordered.add(p);
                p.Plan_Type__c = ordered.size()>=MAX_FULL ? 'Brief' : 'Plan';
            }
        }
        if(ordered.size()<MAX_FULL){
            List<PriorityByRisk> risk = new List<PriorityByRisk>();
            for(Priority__c p:priorities){ 
                if(p.Centralized_Prioritization__c==true) continue;
                risk.add(new PriorityByRisk(p)); 
            }
            risk.sort();
            while(ordered.size()<MAX_FULL && risk.size()>0){
                Priority__c pri = risk.remove(0).pri;
                pri.Centralized_Prioritization__c = true;
                pri.Reason_for_Priority__c = 'At-Risk Account';
                pri.Plan_Type__c = 'Plan';
                ordered.add(pri);
            }
        }

        for(Priority__c pri:ordered){
            if(pri.Centralized_Prioritization__c==true){
                pri.Priority_Plan__c = userPlans.get(rep.Id).Id;
            }
            if(pri.Plan_Type__c!='Brief'){
                SFDC_Acct_Plan__c aplan = aplanMap.get(pri.Account_Plan__c);
                aplan.RecordTypeId = APLanRecordTypes.get(settings.FULL_Record_Type_Name__c);
                plansToUpdate.put(aplan.Id, aplan);
            }
        }

        return ordered;
    }

    public class PriorityByImVolume implements Comparable {
        public Priority__c pri;
        public PriorityByImVolume(Priority__c p) {
            pri = p;
        }
        public Integer compareTo(Object compareTo) {
            PriorityByImVolume comp = (PriorityByImVolume) compareTo;
            if(pri.IM_Volume__c > comp.pri.IM_Volume__c) return 1;
            if(pri.IM_Volume__c < comp.pri.IM_Volume__c) return -1;
            return 0;
        }
    }
    public class PriorityByNonImVolume implements Comparable {
        public Priority__c pri;
        public PriorityByNonImVolume(Priority__c p) {
            pri = p;
        }
        public Integer compareTo(Object compareTo) {
            PriorityByNonImVolume comp = (PriorityByNonImVolume) compareTo;
            if(pri.Non_IM_Volume__c > comp.pri.Non_IM_Volume__c) return 1;
            if(pri.Non_IM_Volume__c < comp.pri.Non_IM_Volume__c) return -1;
            return 0;
        }
    }
    public class PriorityByRisk implements Comparable {
        public Priority__c pri;
        public PriorityByRisk(Priority__c p) {
            pri = p;
        }
        public Integer compareTo(Object compareTo) {
            PriorityByRisk comp = (PriorityByRisk) compareTo;
            if(pri.Risk_Profile__c=='High') return -1;
            if(pri.Risk_Profile__c=='Low') return 1;
            return 0;
        }
    }
*/
}
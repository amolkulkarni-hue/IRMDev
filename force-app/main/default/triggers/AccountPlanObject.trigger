/*Developer Name: Madhu Paladugu
  Company       : TheCloudFountain Inc.
  Desrciption   :  Used to keep the Owner Lookup field in sync with the OwnerId field
                   OwnerId field doesn't allow filtering based on the user's fields.
  Date          : 12/4/12
  case number   : 00924109   
  
  Lines for populating Country Name and Country Name ID hidden fields according to IME Account Plan (Phase 1) requirement
  added by Sandhya Ramesh, 11/19/2014


// This trigger will make sure that there is only one account plan for IMGA accounts.
// Global Account Plan can be created only for IMGA accounts
// Case#		: 04920759
// Author		: Pratap
// Date         : 8th Nov 2016
 */
 

trigger AccountPlanObject on SFDC_Acct_Plan__c (before insert, before update) {
public String AccountPlanOwner=null;
Boolean runAccountPlanOwner=false;

public String GlobalAccountPlan=null;
Boolean runGlobalAccountPlan=false;
    
  /* Variables declared for Global Account Plan and IMGA accounts*/
    set<Id> RecordTypes= new set<Id>();  
    set<Id> accId = new set<Id>();
    set<Id> ParentAccountId= new set<Id>();
    Map<Id, Id> mapParent = new Map<Id, Id>();
    Map<Id, String> accHier = new Map<Id, String>();
    Map<string,AccountPlan_TemplateID__c> TemplateIds = AccountPlan_TemplateID__c.getall();
    
 List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    System.debug('++++++++++83++++++++customsettings:'+customsettings);
    for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c=='SFDC_Acct_Plan__c')
        {
            if(cs.Trigger__c == 'AccountPlanOwner') {
               AccountPlanOwner= cs.Value__c;    
            }
            
            if(cs.Trigger__c == 'GlobalAccountPlan') {
               GlobalAccountPlan= cs.Value__c;    
            }
         }
     }
     if(Trigger.isBefore){
     system.debug('+++++++++++++++++Entered Is Before +++++++++++++++++');
         if(Trigger.IsInsert|| Trigger.isUpdate){
         if(AccountPlanOwner=='True')
           runAccountPlanOwner=true; 
             
           if(GlobalAccountPlan=='TRUE')
           runGlobalAccountPlan=true;   
         }
         
      /****** Populate Country Parent and Country Parent ID hidden fields ******/
      List<Id> accIds = new list<Id>();
      for(SFDC_Acct_Plan__c ap : Trigger.new)
      {
          accIds.add(ap.Account__c);
       }
      List <Account> acc =[Select Id, Name, Country_Parent_Formula__c, Country_Parent_ID__c from Account Where Id in :accIds];
      Map<Id, Account> accsMap = new Map<Id, Account>(acc);
         
      for (SFDC_Acct_Plan__c ap : Trigger.new)
      {
         
      system.debug('+++++++++++++++++ ap.Account__r.Country_Parent_Formula__c++++++++  '+ accsMap.get(ap.Account__c).Country_Parent_Formula__c);
      system.debug('+++++++++++++++++ ap.Account__c++++++++  '+ ap.Account__c);
      system.debug('+++++++++++++++++ ap.Account__r.name++++++++  '+ accsMap.get(ap.Account__c).name);
      
     
       if(accsMap.get(ap.Account__c).Country_Parent_Formula__c== null)
          {
               ap.INTL_Country_Parent__c = 'No Parent found'; 
               ap.INTL_Country_Parent_ID__c = 'No Parent ID found';
             
           }
           else{  
             ap.INTL_Country_Parent__c = accsMap.get(ap.Account__c).Country_Parent_Formula__c; 
             ap.INTL_Country_Parent_ID__c = accsMap.get(ap.Account__c).Country_Parent_ID__c;
           } 
        } 
        
      /**** End of Populate Country Parent and Country Parent ID hidden fields  ******/
 
     }
     if(runAccountPlanOwner){
     System.debug('+++++++++++Executing the AccountPlanOwner trigger+++++');
         for(SFDC_Acct_Plan__c ap : Trigger.new){
         
         if(ap.OwnerId != null && ((String)ap.OwnerId).startsWith('005')) {
            ap.Owner_Lookup__c = ap.OwnerId;
        }
     }
    }
    
    //Case#  04920759
    if (runGlobalAccountPlan) {
     for(SFDC_Acct_Plan__c aPlan : Trigger.NEW) {
        accId.add(aplan.Account__c);
            if(aPlan.Document_Language__c != null  ){
                aPlan.Template_Id__c = TemplateIds.get(aPlan.Document_Language__c).TemplateId__c;
            }
            else //  English as default document language
            {
            aPlan.Template_Id__c = TemplateIds.get('English').TemplateId__c;
            }
    }
    
    Id IMGARecType = Schema.SObjectType.SFDC_Acct_Plan__c.getRecordTypeInfosByName().get('Global Account Plan').getRecordTypeId();
    
    list<Account> PrntAcc =[select id, IMGA_Id__c, IM_Hierarchy_Level__c  from Account where id in :accId];
    
    for(Account pA : PrntAcc){
        if(pA.IM_Hierarchy_Level__c== 'IM Group (IMGA)' && pA.IMGA_Id__c == null){
        ParentAccountId.add(pA.Id);
        mapParent.put(pA.Id, pA.Id );
        }
        else {
           ParentAccountId.add(pA.IMGA_Id__c);
           mapParent.put(pA.Id, pA.IMGA_Id__c );
       }
         accHier.put(pA.Id, pA.IM_Hierarchy_Level__c);
     }    
        
    List<account> acc = [select id, (select id from R00N60000001PRP8EAO where RecordTypeId =: IMGARecType) from Account WHERE Id In: accID ]; //and IM_Hierarchy_Level__c ='IM Group (IMGA)'];
    Map<id, Boolean> bool = new map<id,Boolean>();
    Map<Id, String> planCnt = new map<Id, String>();
    for(account a : acc){
        list<SFDC_Acct_Plan__c> accPlanList = new list<SFDC_Acct_Plan__c>();
        accPlanList.addAll(a.R00N60000001PRP8EAO);
        bool.put(a.id, accPlanList.size() > 0 ? true : false);
        if(accPlanList.size() > 0)
            planCnt.put(a.id, accPlanList[0].id);
        else
            planCnt.put(a.id, '');
        
    }

    for(SFDC_Acct_Plan__c p : Trigger.new) {
    System.debug('Pratap:' + p.RecordTypeId);
    System.debug('Pratap1:' + IMGARecType + ' Hierarchy level:' + accHier.get(p.Account__c));
     if(p.RecordTypeId == IMGARecType && accHier.get(p.Account__c) != 'IM Group (IMGA)') {
          p.Account__c.addError('A Global Account Plan can only be created for an IMGA account.');

     }    
    else if(p.RecordTypeId == IMGARecType) {
        if(Trigger.isInsert) {
            if(!bool.isEmpty())
            {
            if(bool.get(p.Account__c)) {
                p.addError('A Global Account Plan already exists for this IMGA.' + 
                                    'Please either update that Account Plan, or delete it and create a new one.');
            }
            }
        }
        if(Trigger.isUpdate)
        {
            String strId = Id.valueOf(p.Id);
            System.debug('strId'+ strId  + 'Pratap:' + planCnt.get(p.Account__c)+ ' Pratap 2:'+ bool.get(p.Account__c) );
            if(planCnt.get(p.Account__c) != strId && bool.get(p.Account__c) ) {
                p.addError('A Global Account Plan already exists for this IMGA.' + 
                                    'Please either update that Account Plan, or delete it and create a new one.');
            } 
        }
    }
        
    }
    List<String> RecordTypesList = new list<String> { 'INTL Account Plan' , 'IMNA Account Brief' , 'IMNA Account Data Management Plan',
                                              'IMNA Account National/Vertical Plan','IMNA Account Territory Plan'};

    for(string rts : RecordTypesList){
        Id RecordTypeIds = Schema.SObjectType.SFDC_Acct_Plan__c.getRecordTypeInfosByName().get(rts).getRecordTypeId();
        RecordTypes.add(RecordTypeIds);
    }
    
    Map<Id,SFDC_Acct_Plan__c> globalplan =  new Map<Id,SFDC_Acct_Plan__c>();
    List<SFDC_Acct_Plan__c> listAccPlan = [select Account__c from SFDC_Acct_Plan__c where Account__c IN :ParentAccountId and recordtypeId=: IMGARecType];
    for(SFDC_Acct_Plan__c SFAccPlan : listAccPlan ){
        globalplan.put(SFAccPlan.Account__c, SFAccPlan);
    }
  if(Trigger.isInsert) {
    
    for(SFDC_Acct_Plan__c p : Trigger.new) {
        if(RecordTypes.contains(p.RecordTypeId) && globalplan.get(mapParent.get(p.Account__c)) != null && String.IsBlank(p.Global_Account_Plan__c)){
             p.Global_Account_Plan__c = globalplan.get(mapParent.get(p.Account__c)).Id;
         }
    }
  }
    } // End of runGlobalAccountPlan
}
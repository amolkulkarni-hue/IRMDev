/**
 * Class :- LCOpportunityTriggerHandler
 * 
 * Purpose:- The purpose of this class is to watch for opportunities that are converted from a lead
 * and process them to update opportunity Team Members and Partner Account Related Lists.
 *
 *  @author :- Perficient (11/7/2018)
 */

public without sharing class LCOpportunityTriggerHandler {
	public static Final String READ_WRITE_ACCESS = 'EDIT';
  public static Final String PARTNER_MANAGER_ROLE = 'Partner Manager';
  public static Final String READ_ACCESS = 'READ';
  public static Final String PARTNER_USER_ROLE = 'Partner User';
  public static Final String DEAL_REGISTRATION_RECTYPE = 'Deal Registration';
  public static Final String DEFAULT_PARTNER = 'Default';

  /** 
   * Processes Opportunities part of lead conversion to update Opportunity Team role.
   *
   * @param OpportunityOldMap :- Trigger.old
   * @param triggerNewList :- TriggerNewList
   */
  public static void processLeadConversions(Map<Id,Opportunity> OpportunityOldMap, 
    List<Opportunity> triggerNewList) {
     Set<Id> OpportunitySet = new Set<Id>(); 
     Id DealRecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
     .get(DEAL_REGISTRATION_RECTYPE).getRecordTypeId();

     System.debug('Check recordtype ID--'+DealRecordtypeId);
     if(trigger.isInsert) {

          for(Opportunity opp : triggerNewList) {
            System.debug('Check opp ID insert --'+opp.convertedFromLead__c + '---'+opp.RecordtypeId);
              if(opp.convertedFromLead__c == true) {
                OpportunitySet.add(opp.Id);
              }
          }

      } else if (trigger.isUpdate) {
        for(Opportunity opp : triggerNewList) {
          System.debug('Check opp ID update --'+opp.convertedFromLead__c + '---'+opp.RecordtypeId);
              if(opp.convertedFromLead__c ==true && 
                OpportunityOldMap.get(opp.Id).convertedFromLead__c != opp.convertedFromLead__c) {
                OpportunitySet.add(opp.Id);
              }
          }
      }
      System.debug('Check OpportunitySet --'+OpportunitySet);
      if(!OpportunitySet.isEmpty()) {
         if(!System.isBatch() && !System.isFuture()) {
            processOpportunityAsync(OpportunitySet);
         } else {
            processOpportunityInSync(OpportunitySet);
         }
      }

  }

  /** 
   * Processes Opportunities part of lead conversion to update Opportunity Team role in a future Method
   *
   * @param opportunitySet :- Opportunity to be processed
   */
  @Future
  public static void processOpportunityAsync(Set<Id> opportunitySet) {
    processOpportunityInSync(opportunitySet);

  }

  /** 
   * Processes Opportunities part of lead conversion to update Opportunity Team role in a sync 
   *
   * @param opportunitySet :- Opportunity to be processed
   */
  public static void processOpportunityInSync(Set<Id> opportunitySet) {
    List<Lead> LeadList = retrieveLeadLists(opportunitySet);
    Map<String,String> leadVsOpp = new Map<String,String>();
    Map<String,String> leadVsAccountId = new Map<String,String>();
    List<OpportunityTeamMember> opportunityTeamList = new  List<OpportunityTeamMember>();
    List<Partner> accountPartnerList = new List<Partner>();
    Map<String,Partner> newPartnerMap= new Map<String,Partner> ();
    Map<Id,Lead> leadMap = new Map<Id,Lead> ();
    System.debug('checking leadList--'+LeadList);

    for(Lead ld : LeadList)  {
       leadVsOpp.put(ld.Id, ld.ConvertedOpportunityId);
       leadVsAccountId.put(ld.Id,ld.IM_Original_Lead_Owner__r.Id);
       OpportunityTeamMember partnerManager = initialiseTeamMember(ld.ConvertedOpportunityId, 
         ld.IM_Original_Lead_Owner__r.Contact.Account.IM_Partner_Manager__c, 
          READ_WRITE_ACCESS , PARTNER_MANAGER_ROLE);
        opportunityTeamList.add(partnerManager);
    }
    if(!leadList.isEmpty()) {
      leadMap = new Map<Id,Lead> (LeadList);
    }
    System.debug('checking opportunityTeamList manager--'+opportunityTeamList);
    if(!leadVsAccountId.isEmpty()) {
      List<User> partnerUsers = retrievePartnerUserLists(leadVsAccountId);
      if(!partnerUsers.isEmpty()) {
         for(User usr : partnerUsers ){
           for (String leadId : leadVsAccountId.keySet()) {
              String leadAccountId = usr.AccountId;
               System.debug('checking leadAccountId manager--'+leadAccountId);
               System.debug('checking usr.AccountId manager--'+usr.AccountId);
               System.debug('checking usr.Id --'+usr.Id);
              if(leadAccountId != null ) {
                System.debug('checking leadAccountId --'+leadAccountId);
                 String convertedOpportunityId = leadVsOpp.get(leadId);
                 System.debug('checking convertedOpportunityId--'+convertedOpportunityId);
                 if(!String.isBlank(convertedOpportunityId)) {
                    OpportunityTeamMember partnerUser = initialiseTeamMember(convertedOpportunityId, 
                      usr.Id , READ_ACCESS , PARTNER_USER_ROLE);
                    opportunityTeamList.add(partnerUser);
                    Lead ld = leadMap.get(leadId);
                    System.debug('checking leadMap---'+leadMap);
                     System.debug('checking leadId---'+ld);
                    if(ld != null) {
                      System.debug('check account Partner User');
                      Partner accPartnerUser = initialisePartnerList(ld.ConvertedOpportunityId,
                        usr.AccountId,
                       ld.IM_Original_Lead_Owner__r.Contact.Account.IM_Partner_Type__c);
                    if(!newPartnerMap.containsKey(ld.ConvertedOpportunityId+'-'+usr.AccountId))
                      accountPartnerList.add(accPartnerUser);
                      newPartnerMap.put(ld.ConvertedOpportunityId+'-'+usr.AccountId,accPartnerUser);
                    }

                 }
              }
           }
        }

        if(!opportunityTeamList.isEmpty()) {
           Database.upsert(opportunityTeamList,false);
        }
        if(!accountPartnerList.isEmpty()) {
           validateRelatedPartner(leadVsAccountId,leadVsOpp,accountPartnerList,newPartnerMap);
           Database.upsert(accountPartnerList,false);
        }
      }
    }
  }

  /** 
   * Retrieves converted lead lists.
   *
   * @param opportunitySet :- Opportunity to be processed
   * @return List<Lead> :- Converted Lead attributes.
   */
  public static List<Lead> retrieveLeadLists (Set<Id> opportunitySet) {
    List<Lead> LeadList = new List<Lead> ();
      LeadList = [Select Id,IM_Original_Lead_Owner__c,IM_Original_Lead_Owner__r.AccountId,
       IM_Original_Lead_Owner__r.Contact.Account.IM_Partner_Manager__c,ConvertedOpportunityId ,
       ConvertedOpportunity.AccountId,
       IM_Original_Lead_Owner__r.Contact.Account.IM_Partner_Type__c 
       From Lead Where ConvertedOpportunityId in : opportunitySet];
    return LeadList;
  }

  /** 
   * Retrieves Partner Users related to the converted lead lists.
   *
   * @param leadVsAccountId :- convertedLead Vs AccountId
   * @return List<User> :- Converted Lead Users.
   */ 
  public static List<User> retrievePartnerUserLists (Map<String,String> leadVsAccountId) {
    List<User> UserList = new List<User> ();
      UserList = [Select Id,AccountId, ContactId  From User Where Id in : leadVsAccountId.values()];
    return UserList;
  }

  /** 
   * Initialises OpportunityTeamMember;
   *
   * @return OpportunityTeamMember :- OpportunityTeamMember.
   */
  public static OpportunityTeamMember initialiseTeamMember (Id OpportunityId, Id UserId, String Access, String roleName) {
          System.debug('checking usr.Id777 --'+UserId);
        OpportunityTeamMember oppMember = new OpportunityTeamMember(
          OpportunityId = OpportunityId,
          OpportunityAccessLevel = Access,
          UserId = UserId,
          TeamMemberRole = roleName);
    return oppMember;
  }

  /** 
   * Retrieves Partner Users related to the converted lead lists.
   *
   * @param leadVsAccountId :- convertedLead Vs AccountId
   * @return List<User> :- Converted Lead Users.
   */ 
  public static void validateRelatedPartner(Map<String,String> leadVsAccountId,Map<String,String> leadVsOpp,
    List<Partner> accountPartnerList,   Map<String,Partner> newPartnerMap) {
    Map<String,Partner> existingPartnerMap= new Map<String,Partner> ();
    List<Partner> deleteList = new List<Partner> ();
    List<Partner> queryPartner = 
    [Select Id,OpportunityId, AccountToId  From Partner Where OpportunityId in : leadVsOpp.values() and AccountToId
    in :leadVsAccountId.values() ];

    for(Partner existingPartner : queryPartner) {
       existingPartnerMap.put(existingPartner.OpportunityId+'-'+existingPartner.AccountToId, existingPartner);
       if(newPartnerMap.containsKey(existingPartner.OpportunityId+'-'+existingPartner.AccountToId)) {
          deleteList.add(existingPartner);
       }
    }
    System.debug('check existing partner map.existing.'+existingPartnerMap);
    System.debug('check existing partner map.new.'+newPartnerMap);
    System.debug('check deleteList.'+deleteList);
    if(!deleteList.isEmpty()) {
       Database.delete(deleteList,false);
    }
    //return partnerList;
  }

  /** 
   * Initialises Account Partner;
   *
   * @return Partner :- Account Partner.
   */
  public static Partner initialisePartnerList (Id oppId, Id ToAccountId,
    String partnerType) {
        String roleName;
      Map<String,LC_PartnerTypeVsRoleMapping__mdt> typeVsRole = new Map<String,LC_PartnerTypeVsRoleMapping__mdt> ();
      List<LC_PartnerTypeVsRoleMapping__mdt> partnerMapping = [SELECT
      DeveloperName,
      MasterLabel,Partner_Role__c FROM LC_PartnerTypeVsRoleMapping__mdt
      Where DeveloperName = :partnerType or DeveloperName = :DEFAULT_PARTNER ];

      for(LC_PartnerTypeVsRoleMapping__mdt ptype: partnerMapping){
          typeVsRole.put(ptype.DeveloperName,ptype);
      }

      if(typeVsRole.containsKey(partnerType)) {
        roleName = typeVsRole.get(partnerType).Partner_Role__c;
      } else {
        roleName = typeVsRole.get(DEFAULT_PARTNER).Partner_Role__c;
      }

        Partner partnerUser = new Partner(
          OpportunityId = oppId,
          AccountToId = ToAccountId,
          Role = roleName,
          IsPrimary = true);
    
      
      
    return partnerUser;
  }
}
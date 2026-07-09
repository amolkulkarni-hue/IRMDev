/*****************************************************************************************************
 * Class: QTB_ContractHelper
 * Author: Accenture
 * Purpose: This is a helper class for all business logic related to Contract object
 * Change History: 8/5/2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *              3/16/2020
 *******************************************************************************************************/
public with sharing class QTB_ContractHelper {
	public static final String CONTRACTHELPER = 'QTB_ContractHelper';
	public static boolean SingleTon = true;
	public static Boolean blockCustomTrigger = false;

	/***********************************************************************************************************
	 * Method : process
	 * Parameters: List<Contract>, Map<ID,Contract>, Map<ID,Contract>,System.TriggerOperation
	 * Return type: void
	 * Author : Accenture
	 * Description: Generic method to invoke all the other methods
	 **************************************************************************************************************/
	public static void process(
		List<Contract> newItems,
		Map<Id, Contract> newMap,
		Map<Id, Contract> oldMap,
		System.TriggerOperation operationType
	) {
		//updateOnActivationContract
		Set<ID> billingContractIdSet = new Set<ID>();
		Map<ID, ID> salesOptyToBillingContractIdMap = new Map<ID, ID>();

		//setCPQContractRT
		set<ID> quoteID = new Set<ID>();
		List<Contract> ctrList = new List<Contract>();
		Set<Id> oppIdSet = new Set<Id>();
		Map<Id, Opportunity> oppCountryMap = new Map<Id, Opportunity>();

		//setBillingCountry
		List<Contract> cpqSalesContractList = new List<Contract>();
        
		//CheckAmendContract
		List<Contract> contractListAB = new List<Contract>();

		//checkRenewalContract
		List<Contract> contractsList = new List<Contract>();
		Set<ID> opptyIdSet = new Set<ID>();
        
		// platformEvent
		List<Contract> pe_CtrList = new List<Contract>();
		for (Contract con : newItems) {
			opptyIdSet.add(con.SBQQ__Opportunity__c);
		}
		Map<ID, Opportunity> oppIDtoOppMap = new Map<ID, Opportunity>(
			[SELECT id, Type,QTB_APIProcess__c FROM Opportunity WHERE ID IN :opptyIdSet]
		);
		for (Contract cont : newItems) {
			switch on operationType {
				when BEFORE_INSERT {
					if (
						cont.status.equalsIgnoreCase(
							QTB_Constants.DRAFT_STATUS
						) && cont.SBQQ__Quote__c != null
					) {
						quoteID.add(cont.SBQQ__Quote__c);
						ctrList.add(cont);
						oppIdSet.add(cont.SBQQ__Opportunity__c);
					}
					if (
						cont.RecordTypeID == QTB_Utils.CONTRACT_SALES_RECTYPEID
					) {
						//Added for SFCPQBLG-648
						oppIdSet.add(cont.SBQQ__Opportunity__c);
						cpqSalesContractList.add(cont);
					}
				}
				when BEFORE_UPDATE {
					if (cont.RecordTypeID ==QTB_Utils.CONTRACT_SALES_RECTYPEID && cont.status.equalsIgnoreCase(QTB_Constants.DRAFT_STATUS)) {
					    cont.Status = QTB_Constants.ACTIVATED_STATUS;
					}
					
					//Update latest opportunity on Sales Contract for New Sales and Renewal processs
					if (
						oppIDtoOppMap.containsKey(cont.SBQQ__Opportunity__c) &&
						oppIDtoOppMap.get(cont.SBQQ__Opportunity__c).Type !=
						null &&
						(oppIDtoOppMap.get(cont.SBQQ__Opportunity__c).Type ==
						QTB_Constants.OPP_TYPE_NEWDEAL ||
						oppIDtoOppMap.get(cont.SBQQ__Opportunity__c).Type ==
						QTB_Constants.OPP_TYPE) &&
						cont.RecordTypeID ==
						QTB_Utils.CONTRACT_SALES_RECTYPEID &&
						cont.SBQQ__Opportunity__c != null &&
						cont.Status == QTB_Constants.ACTIVATED_STATUS &&
						cont.QTB_Latest_Opportunity__c == null 
					) {
						cont.QTB_Latest_Opportunity__c = cont.SBQQ__Opportunity__c;
                        cont.Name = cont.IM_Contract_Number__c;
                        if(oppIDtoOppMap.get(cont.SBQQ__Opportunity__c).QTB_APIProcess__c == true){
                           cont.QTB_APIProcess__c = true; 
                        }else{
                           cont.QTB_APIProcess__c = false; 
                        }
					}
				}
				when AFTER_UPDATE {
					if (
						oldMap.get(cont.Id).SBQQ__Order__c !=
						cont.SBQQ__Order__c &&
						cont.Status == QTB_Constants.ACTIVATED_STATUS &&
						cont.RecordtypeId == QTB_Utils.CONTRACT_BILL_RECTYPEID
					) {
						pe_CtrList.add(cont);
					}
					if (
						( !String.isEmpty(cont.QTB_ContractCategory__c) && cont.QTB_ContractCategory__c =='Renewal'	) 
                         && oldMap.get(cont.Id).SBQQ__Order__c != cont.SBQQ__Order__c && oldMap.get(cont.Id).SBQQ__Order__c==NULL && cont.SBQQ__Order__c !=null &&
						 cont.RecordtypeId == QTB_Utils.CONTRACT_SALES_RECTYPEID && cont.Status == QTB_Constants.ACTIVATED_STATUS &&
                         cont.QTB_APIProcess__c == false  //added as part of Regular API to exclude billing order creation.
					) {
						contractsList.add(Cont);
					}
					if (
						cont.RecordtypeId ==
						QTB_Utils.CONTRACT_SALES_RECTYPEID &&
						oldMap.get(cont.Id).SBQQ__Order__c != null && cont.SBQQ__Order__c !=null && 
						oldMap.get(cont.Id).SBQQ__Order__c !=
						cont.SBQQ__Order__c && cont.Status == QTB_Constants.ACTIVATED_STATUS
					) {
						contractListAB.add(cont);
					}
				}
				when else {
				}
			}
		}
        if (!oppIdSet.isEmpty()) {
			//SFCPQBLG-648
			oppCountryMap = new Map<Id, Opportunity>(
				[
					SELECT Id, Billing_Country__c
					FROM Opportunity
					WHERE Id IN :oppIdSet
				]
			);
		}

		//setCPQContractRT
		if (!quoteID.isEmpty() && !ctrList.isEmpty()) {
			setCPQContractRT(ctrList, quoteID, oppCountryMap);
		}

		//set Billing Country on Sales Contract
		if (!cpqSalesContractList.isEmpty() && oppCountryMap != null) {
			setBillingCountry(cpqSalesContractList, oppCountryMap);
		}

		if (
			!contractsList.isEmpty() &&
			(SingleTon || ContractTriggerHandler.throwExplicitException)
		) {
			checkRenewalContract(contractsList);
		}
		if (!contractListAB.isEmpty()) {
			checkAmendContract(contractListAB, oldMap);
		}

		//platformEvent
		if (!pe_CtrList.isEmpty()) {
			triggerPlatformEvent(pe_CtrList);
		}
	}
    /***********************************************************************************************************
	 * Method : setCPQContractRT
	 * Parameters: List<Contract>
	 * Return type: void
	 * Requirement :
	 * Author : Accenture
	 * Description: Set contract Record Type on Insert
	 **************************************************************************************************************/
	public static void setCPQContractRT(
		List<Contract> ctrList,
		set<ID> quoteID,
		Map<Id, Opportunity> oppCountryMap
	) {
		Map<ID, SBQQ__Quote__c> quoteMap = new Map<ID, SBQQ__Quote__c>(
			[
				SELECT id, RecordTypeID, RecordType.name
				FROM SBQQ__Quote__c
				WHERE id IN :quoteID
			]
		);
		try {
			if (ContractTriggerHandler.throwExplicitException) {
				throw new NullPointerException();
			}
			for (Contract cont : ctrList) {
				if (
					quoteMap != null &&
					quoteMap.containsKey(cont.SBQQ__Quote__c)
				) {
					cont.RecordTypeID = (QTB_constants.QUOTE_RECORD_TYPE.contains(
							quoteMap.get(cont.SBQQ__Quote__c).RecordType.name
						))
						? QTB_Utils.CONTRACT_SALES_RECTYPEID
						: cont.RecordTypeID;
					if (
						cont.RecordTypeID ==
						QTB_Utils.CONTRACT_SALES_RECTYPEID &&
						oppCountryMap != null &&
						oppCountryMap.containsKey(cont.SBQQ__Opportunity__c)
					) {
						cont.Billing_Country__c = oppCountryMap.get(
								cont.SBQQ__Opportunity__c
							)
							.Billing_Country__c; //Set Billing Country for Sales Contract
					}
				}
			}
		} catch (Exception e) {
			QTB_ExceptionLogger.createLog(
				e.getLineNumber(),
				e.getStackTraceString(),
				e.getMessage(),
				e.getTypeName(),
				QTB_ContractHelper.class.getname()
			);
			throw e;
		}
	}

	/***********************************************************************************************************
	 * Method : checkRenewalContract
	 * Parameters: Map<Id,Contract>
	 * Return type: void
	 * Requirement :Git#9
	 * Start Date : 16/03/2021
	 * Author : Accenture
	 * Description: Used to verify contract & initaite batch to create Billing related records in Renewal Billing.
	 **************************************************************************************************************/
	public static void checkRenewalContract(List<Contract> contractList) {
		try {
			if (ContractTriggerHandler.throwExplicitException) {
				throw new NullPointerException();
			}
            System.debug(contractList);
			System.enqueueJob(new QTB_QueueRenewalBilling(contractList));
			SingleTon = false;
		} catch (Exception e) {
			QTB_ExceptionLogger.createLog(
				e.getLineNumber(),
				e.getStackTraceString(),
				e.getMessage(),
				e.getTypeName(),
				CONTRACTHELPER
			);
			throw e;
		}
	}
	/***********************************************************************************************************
	 * Method : checkAmendContract
	 * Parameters: Map<Id,Contract>
	 * Return type: void
	 * Requirement :Git#15
	 * Start Date : 01/02/2021
	 * Author : Accenture
	 * Description: Used to verify contract & initaite batch to create Billing related records in Amend billing.
	 **************************************************************************************************************/
	public static void checkAmendContract(
		List<Contract> contractList,
		Map<Id, Contract> oldContractMap
	) {
		try {
			if (ContractTriggerHandler.throwExplicitException) {
				throw new NullPointerException();
			}
			system.debug('-->I am here in contract trigger method');

			System.enqueueJob(
				new QTB_QueueBillingAmend(contractList, oldContractMap)
			);
			SingleTon = false;
		} catch (Exception e) {
			QTB_ExceptionLogger.createLog(
				e.getLineNumber(),
				e.getStackTraceString(),
				e.getMessage(),
				e.getTypeName(),
				CONTRACTHELPER
			);
			throw e;
		}
	}

	/***********************************************************************************************************
	 * Method : setBillingCountry
	 * Parameters: List<Contract>, Map<Id,Opportunity>
	 * Return type: void
	 * Requirement : SFCPQBLG-648
	 * Start Date : 6/10/2020
	 * Author : Accenture
	 * Description: Method to populate Opportunity Billing Country to Sales Contracts Billing Country
	 **************************************************************************************************************/
	public static void setBillingCountry(
		List<Contract> cpqSalesContractList,
		Map<Id, Opportunity> oppCountryMap
	) {
		try {
			if (ContractTriggerHandler.throwExplicitException) {
				throw new NullPointerException();
			}
			for (Contract cont : cpqSalesContractList) {
				if (oppCountryMap.containsKey(cont.SBQQ__Opportunity__c)) {
					cont.Billing_Country__c = oppCountryMap.get(
							cont.SBQQ__Opportunity__c
						)
						.Billing_Country__c;
				}
			}
		} catch (Exception e) {
			QTB_ExceptionLogger.createLog(
				e.getLineNumber(),
				e.getStackTraceString(),
				e.getMessage(),
				e.getTypeName(),
				CONTRACTHELPER
			);
			throw e;
		}
	}

	/***********************************************************************************************************
	 * Method : triggerPlatformEvent
	 * Parameters: List<Contract>
	 * Return type: void
	 * Requirement :
	 * Start Date : 6/5/2020
	 * Author : Accenture
	 * Description:
	 **************************************************************************************************************/
	public static void triggerPlatformEvent(List<Contract> contractNewList) {
		try {
			if (ContractTriggerHandler.throwExplicitException) {
				throw new NullPointerException();
			}
			Set<Id> quoteId = new Set<Id>();
			List<Contract> contractList = new List<Contract>();

			if (!contractNewList.isEmpty()) {
				contractList = [
					SELECT
						id,
						SBQQ__Order__r.SBQQ__Quote__c,
						SBQQ__Opportunity__r.QTB_Billing_Country_Name__c
					FROM Contract
					WHERE Id IN :contractNewList
				];

				for (Contract con : contractList) {
					//GITLAB #1639 Condition for bypasssing Platform Event for finland.
					if (
						con.SBQQ__Opportunity__r.QTB_Billing_Country_Name__c !=
						QTB_Constants.Excluded_Country
					) {
						quoteId.add(con.SBQQ__Order__r.SBQQ__Quote__c);
						System.debug(
							'### Contract Country for Event: ' +
							con.SBQQ__Opportunity__r.QTB_Billing_Country_Name__c
						);
					}
				}
				if (!quoteId.isEmpty()) {
					String whereCond = ' where SBQQ__Quantity__c > 0 and SBQQ__Quote__c in : quoteId';
					QTB_Utils.publishPriceScheduleEvents(quoteId, whereCond);
				}
			}
		} catch (Exception e) {
			QTB_ExceptionLogger.createLog(
				e.getLineNumber(),
				e.getStackTraceString(),
				e.getMessage(),
				e.getTypeName(),
				QTB_Constants.CONTRACT_PLATFORM_EVENT
			);
			throw e;
		}
	}
}
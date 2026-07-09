/**
 * @description This class is responsbile for all logic to undo the rebill process, when the rebill is not approved.
 * This class must run in system mode. All records irrespective of sharing must be retrieved and deleted.
 * @requirement GitLab # 3483
 * @author Accenture
 * @since 05/28/2021
 */
public without sharing class QTB_RebillUndoService implements Queueable {
	private String toCall;
	private Map<String, Object> args;
	public QTB_RebillUndoService() {
		this.args = new Map<String, Object>();
	}
	/**
	 * Defines the method that the instance should call
	 * @param methodNameToCall
	 * @return  `QTB_RebillUndoService`
	 */
	public QTB_RebillUndoService setAction(String methodNameToCall) {
		this.toCall = methodNameToCall;
		return this;
	}
	/**
	 *
	 * @param paramName
	 * @param value
	 * @return  `QTB_RebillUndoService`
	 */
	public QTB_RebillUndoService setParam(String paramName, Object value) {
		args.put(paramName, value);
		return this;
	}
	/**
	 * Given the invoice id, delete the invoice. Deleting the invoice, deletes related
	 * invoice lines as well. Invoice cannot be deleted because of the billing package
	 * restrictions. The delete must happen when the triggers are off.
	 * @param invoiceIds List of invoice ids
	 */
	public void removeInvoices(List<Id> invoiceIds) {
		if (invoiceIds == null || invoiceIds.isEmpty()) {
			return;
		}
		try {
			SBQQ.TriggerControl.disable();
			Database.delete(invoiceIds);
			SBQQ.TriggerControl.enable();
			Database.emptyRecycleBin(invoiceIds);
		} catch (Exception dmle) {
			QTB_ExceptionLogger.enable();
			QTB_ExceptionLogger.createLog(dmle, 'QTB_RebillUndoService');
			throw dmle;
		}
	}
	/**
	 * Given the invoice id, returns the list of order ids, for which the invoice
	 * was generated.
	 * @param invoiceIds List of invoice ids
	 * @return  `List<Id>` list of order ids billed by the invoice
	 */
	public List<Id> getOrders(List<Id> invoiceIds) {
		if (invoiceIds == null || invoiceIds.isEmpty()) {
			return null;
		}
		Set<Id> orderIds = new Set<Id>();
		for (blng__InvoiceLine__c invoiceLine : [
			SELECT blng__OrderProduct__r.OrderId
			FROM blng__InvoiceLine__c
			WHERE blng__Invoice__c = :invoiceIds
		]) {
			orderIds.add(invoiceLine.blng__OrderProduct__r.OrderId);
		}
		// as multiple order products from same order might be there
		// we only need to return unique order ids
		return new List<Id>(orderIds);
	}
	/**
	 * Given the order id, returns all consumption schedules under its
	 * order products.
	 * @param orderIds List of order ids
	 * @return  `List<SBQQ__OrderItemConsumptionSchedule__c>`
	 */
	public List<SBQQ__OrderItemConsumptionSchedule__c> getOrderItemConsumptionSchedules(
		List<Id> orderIds
	) {
		if (orderIds == null || orderIds.isEmpty()) {
			return null;
		}
		return [
			SELECT Id
			FROM SBQQ__OrderItemConsumptionSchedule__c
			WHERE SBQQ__OrderItem__r.OrderId = :orderIds
		];
	}
	/**
	 * Given the order ids, returns all usage summaries under its order products
	 * @param orderIds List of order ids
	 * @return  `List<blng__UsageSummary__c>`
	 */
	public List<blng__UsageSummary__c> getUsageSummaries(List<Id> orderIds) {
		if (orderIds == null || orderIds.isEmpty()) {
			return null;
		}
		return [
			SELECT Id
			FROM blng__UsageSummary__c
			WHERE blng__Order__c = :orderIds
		];
	}
	/**
	 * Update order status to Draft
	 * @param orderIds List of rebill order ids
	 */
	public void deactivateOrders(List<Id> orderIds) {
		if (orderIds == null || orderIds.isEmpty()) {
			return;
		}
		List<Order> deactivatedOrders = new List<Order>();
		for (Id orderId : orderIds) {
			deactivatedOrders.add(new Order(Id = orderId, Status = 'Draft'));
		}
		try {
			SBQQ.TriggerControl.disable();
			update deactivatedOrders;
			SBQQ.TriggerControl.enable();
		} catch (Exception dmle) {
			QTB_ExceptionLogger.enable();
			QTB_ExceptionLogger.createLog(dmle, 'QTB_RebillUndoService');
			throw dmle;
		}
	}
	/**
	 * Given the list of order ids, deletes the orders. Deleting the order,
	 * deletes all its order products.
	 * @param orderIds List of order ids
	 */
	public void removeOrders(List<Id> orderIds) {
		if (orderIds == null || orderIds.isEmpty()) {
			return;
		}
		try {
			SBQQ.TriggerControl.disable();
			Database.delete(orderIds);
			SBQQ.TriggerControl.enable();
			Database.emptyRecycleBin(orderIds);
		} catch (Exception dmle) {
			QTB_ExceptionLogger.enable();
			QTB_ExceptionLogger.createLog(dmle, 'QTB_RebillUndoService');
			throw dmle;
		}
	}
	/**
	 * Given usage records, delete those and do not create usage suspense records.
	 * @param usages List of usage records
	 */
	public void removeUsages(List<blng__Usage__c> usages) {
		if (usages == null || usages.isEmpty()) {
			return;
		}
		// disable the custom triggers to not generate usage suspense
		// as well as bypass custom validation
		QTB_UsageTriggerHandler.disable();
		delete usages;
		Database.emptyRecycleBin(usages);
	}
	/**
	 * @description Delete order item consumption schedules.
	 * @param schedules List of order item consumption schedules
	 */
	public void removeOrderItemConsumptionSchedules(
		List<SBQQ__OrderItemConsumptionSchedule__c> schedules
	) {
		if (schedules == null || schedules.isEmpty()) {
			return;
		}
		SBQQ.TriggerControl.disable();
		delete schedules;
		SBQQ.TriggerControl.enable();
		Database.emptyRecycleBin(schedules);
	}
	/**
	 * Delete usagesummaries. This runs bypassing the package triggers.
	 * @param usageSummaries
	 */
	public void removeUsageSummaries(
		List<blng__UsageSummary__c> usageSummaries
	) {
		if (usageSummaries == null || usageSummaries.isEmpty()) {
			return;
		}
		SBQQ.TriggerControl.disable();
		delete usageSummaries;
		SBQQ.TriggerControl.enable();
		Database.emptyRecycleBin(usageSummaries);
	}

	public void execute(QueueableContext context) {
		if (String.isNotBlank(this.toCall)) {
			switch on this.toCall {
				when 'removeInvoices' {
					System.debug(LoggingLevel.INFO, 'Running Remove Invoices');
					List<Id> invoiceIds = (List<Id>) this.args.get(
						'invoiceIds'
					);
					this.setParam('orderIds', this.getOrders(invoiceIds));
					this.removeInvoices(invoiceIds);
					this.chainNextJob('removeUsages');
				}
				when 'removeUsages' {
					System.debug(
						LoggingLevel.INFO,
						'Running Remove Usages from queueable'
					);
					List<Id> orderIds = (List<Id>) this.args.get('orderIds');
					Database.executeBatch(
						new QTB_BatchableUsageRemovalService(
							orderIds,
							'removeConsumptionSchedules'
						)
					);
				}
				when 'removeConsumptionSchedules' {
					System.debug(
						LoggingLevel.INFO,
						'Running Remove ConsumptionSchedules'
					);
					List<Id> orderIds = (List<Id>) this.args.get('orderIds');
					this.removeOrderItemConsumptionSchedules(
						this.getOrderItemConsumptionSchedules(orderIds)
					);
					this.chainNextJob('removeUsageSummaries');
				}
				when 'removeUsageSummaries' {
					System.debug(
						LoggingLevel.INFO,
						'Running Remove UsageSummaries'
					);
					List<Id> orderIds = (List<Id>) this.args.get('orderIds');
					this.removeUsageSummaries(this.getUsageSummaries(orderIds));
					this.chainNextJob('removeOrders');
				}
				when 'removeOrders' {
					System.debug(LoggingLevel.INFO, 'Running Remove Orders');
					List<Id> orderIds = (List<Id>) this.args.get('orderIds');
					this.deactivateOrders(orderIds);
					this.removeOrders(orderIds);
					this.args.clear();
				}
			}
		}
	}
	/**
	 * Given the method name to call, chains the rebillundoservice to call that method.
	 * Assumption is that, the arguments are already set with the setParam method.
	 * @param nextActionToCall Name of the method to call
	 */
	@TestVisible
	private void chainNextJob(String nextActionToCall) {
		if (String.isNotBlank(nextActionToCall) && this.isChainable()) {
			System.enqueueJob(this.setAction(nextActionToCall));
		}
	}
	/**
	 * Returns true if the current instance can chain another queueable job
	 * @return  `Boolean` can chain another queueable job
	 */
	@TestVisible
	private Boolean isChainable() {
		return !(Test.isRunningTest() ||
		Limits.getQueueableJobs() == Limits.getLimitQueueableJobs());
	}
}
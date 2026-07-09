/**
 * This class is responsible for removing usages in bulk from org.
 * This class will not be scheduled, but can be called from other classes.
 * @author Accenture
 * @since 03/06/2921
 */
public inherited sharing class QTB_BatchableUsageRemovalService implements Database.Batchable<SObject> {
	private final List<Id> orderIds;
	private final String finishAction;
	/**
	 * Given list of orders, remove all usages under those.
	 * @param orderIds List of order ids
	 */
	public QTB_BatchableUsageRemovalService(List<Id> orderIds) {
		this.orderIds = orderIds;
	}
	/**
	 * Given list of orders, remove all usages under those. And then call
	 * the finish action specified. The action must be a method from RebillUndoService
	 * that can be called in the queueable execution.
	 * @param orderIds list of order ids
	 * @param finishAction name of the method to be called from finish method
	 */
	public QTB_BatchableUsageRemovalService(
		List<Id> orderIds,
		String finishAction
	) {
		this.orderIds = orderIds;
		this.finishAction = finishAction;
	}
	public Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator(
			'SELECT Id FROM blng__Usage__c WHERE blng__UsageSummary__r.blng__Order__c = :orderIds'
		);
	}
	public void execute(
		Database.BatchableContext context,
		List<blng__Usage__c> usages
	) {
		// hard delete the usages
		new QTB_RebillUndoService().removeUsages(usages);
	}
	public void finish(Database.BatchableContext context) {
		if (String.isNotBlank(this.finishAction)) {
			System.enqueueJob(
				new QTB_RebillUndoService()
					.setAction(this.finishAction)
					.setParam('orderIds', this.orderIds)
			);
		}
	}
}
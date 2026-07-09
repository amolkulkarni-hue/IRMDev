public with sharing class QTB_QuoteLineConsumptionScheduleDAO {
	@AuraEnabled
	public static List<SBQQ__QuoteLine__c> getQuoteLinesWithConsumptionSchedules(
		String quoteId
	) {
		List<SBQQ__QuoteLine__c> listOfQuoteLinesWithConsumptionSchedules = new List<SBQQ__QuoteLine__c>();
		try {
			listOfQuoteLinesWithConsumptionSchedules = [
				SELECT
					Id,
					SBQQ__ProductName__c,
					QTB_QL_Consumption_Schedule_RecordID__c,
					QTB_Quote_line_Consumption_Schedule_Name__c,
					QTB_OriginalConsumptionID__c,
					QTB_Tier_List_Price__c,
					(
						SELECT
							Id,
							Name,
							QTB_ListPriceRate__c,
							SBQQ__ConsumptionSchedule__c
						FROM SBQQ__QuoteLines__r
					)
				FROM SBQQ__QuoteLine__c
				WHERE
					SBQQ__Quote__c = :Id.valueOf(quoteId)
					AND SBQQ__HasConsumptionSchedule__c = TRUE
				WITH SECURITY_ENFORCED
			];
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return listOfQuoteLinesWithConsumptionSchedules;
	}

	@AuraEnabled
	public static string setSelectedConsumptionSchedule(String param) {
		try {
			List<SBQQ__QuoteLine__c> linesToUpdate = (List<SBQQ__QuoteLine__c>) JSON.deserialize(
				param,
				List<SBQQ__QuoteLine__c>.class
			);
			SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE,linesToUpdate);
			if (!decision.getModifiedIndexes().isEmpty() || !decision.getRemovedFields().isEmpty()) {
				throw new AuraHandledException('Insufficient privileges to update the records.');
			}
			update (List<SBQQ__QuoteLine__c>) decision.getRecords();
			return 'SUCCESS';
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static List<SBQQ__QuoteLineConsumptionSchedule__c> getConsumptionScheduleByQuoteLine(
		String quoteLineId
	) {
		try {
			return [
				SELECT
					Id,
					Name,
					SBQQ__ConsumptionSchedule__c,
					QTB_ListPriceRate__c,
                    SBQQ__QuoteLine__r.SBQQ__Quote__r.QTB_Subscription_Exemptions__c,
					(
						SELECT
							Id,
							Name,
							SBQQ__LowerBound__c,
							SBQQ__UpperBound__c,
							SBQQ__Price__c,
							SBQQ__OriginalPrice__c,
							SBQQ__PricingMethod__c,
                            CurrencyIsoCode
						FROM SBQQ__QuoteLineConsumptionRates__r
						ORDER BY SBQQ__ProcessingOrder__c
					)
				FROM SBQQ__QuoteLineConsumptionSchedule__c
				WHERE SBQQ__QuoteLine__c = :Id.valueOf(quoteLineId)
				WITH SECURITY_ENFORCED
			];
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}
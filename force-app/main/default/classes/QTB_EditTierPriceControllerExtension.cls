public with sharing class QTB_EditTierPriceControllerExtension {
    public SBQQ__Quoteline__c line { get; private set; }
    public String recordId { get; private set; }
    public String quoteId { get; private set; }
    public Boolean valid { get; private set; }
    public QTB_EditTierPriceControllerExtension() {
        this.init();
    }

    public Pagereference init() {
        this.recordId = ApexPages.currentPage().getParameters().get('id');
        this.quoteId = ApexPages.currentPage().getParameters().get('qid');
        if (
            this.recordId <> 'undefined' &&
            this.recordId <> 'null' &&
            this.recordId <> '' &&
            this.recordId <> null &&
            this.recordId.length() >= 15
        ) {
            this.valid = true;
            this.line = [
                SELECT
                    Id,
                    SBQQ__Quote__c,
                    SBQQ__ProductName__c,
                    QTB_First_Tier_Price__c,
                    QTB_Second_Tier_Price__c,
                    QTB_First_Tier_Breakpoint__c,
                    CurrencyIsoCode
                FROM SBQQ__QuoteLine__c
                WHERE Id = :Id.valueOf(this.recordId)
            ];
        } else {
            this.valid = false;
        }
        return this.toQuoteLineEditor();
    }

    public Pagereference cancel() {
        return this.toQuoteLineEditor();
    }

    public Pagereference save() {
        this.line.QTB_First_Tier_Price__c = this.line.QTB_First_Tier_Price__c.setScale(
            2,
            RoundingMode.HALF_UP
        );
        this.line.QTB_Second_Tier_Price__c = this.line.QTB_Second_Tier_Price__c.setScale(
            2,
            RoundingMode.HALF_UP
        );
        this.line.QTB_First_Tier_Breakpoint__c = Math.ceil(
            this.line.QTB_First_Tier_Breakpoint__c
        );
        SBQQ.TriggerControl.disable();
        update this.line;
        SBQQ.TriggerControl.enable();
        return this.toQuoteLineEditor();
    }

    private Pagereference toQuoteLineEditor() {
        // redirects back to quote line editor
        PageReference qleURL = Page.SBQQ__SB;
        qleURL.getParameters().put('scontrolCaching', '1');
        qleURL.getParameters().put('id', this.quoteId);
        qleURL.setRedirect(true);

        return qleURL;
    }
}
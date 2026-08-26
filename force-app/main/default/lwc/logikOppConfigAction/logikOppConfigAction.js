import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


import { loadStyle } from 'lightning/platformResourceLoader';
import hideAppPageHeader from '@salesforce/resourceUrl/hideAppPageHeader';

// Import Apex Line Upsert Method
import upsertLogikTransactionLines from '@salesforce/apex/logikTransaButtRedirectActionController.upsertLogikTransactionLines';

export default class LogikOppConfigAction extends NavigationMixin(LightningElement) {

    @api recordId;                   // Opportunity Record Id
    @api logikConfigurableProductId; 
    @api pricebook2Id;
    @api currency = 'USD';
    @api logikPid;
    @api sfTransactionId;            // SF Transaction Record Id
    @api lgkTransactionId;
    @api logikUiHost;
    @api logikApiHost;
    @api logikApiToken;
    @api frameHeight = '80vh';
    @api logikApiTransactionId;      // Logik Transaction UUID

    @track overrideIframeUrl = null; // Holds the Transaction UI URL after 'Quote' is clicked
    isCssLoaded = false;
    
    renderedCallback() {
        // 1. Inyect CSS
        if (!this.isCssLoaded) {
            loadStyle(this, hideAppPageHeader)
                .then(() => {
                    this.isCssLoaded = true;
                })
                .catch(error => {
                    console.error('[LWC] Error loading CSS from logikOppConfigAction:', error);
                });
        }

        // frameHeight
        const iframe = this.template.querySelector('iframe');
        if (iframe && this.frameHeight) {
            iframe.style.height = this.frameHeight;
        }
    }


    connectedCallback() {
        window.addEventListener("message", this.handleMessage);
    }

    disconnectedCallback() {
        window.removeEventListener("message", this.handleMessage);
    }

    handleMessage = (event) => {
        this.receiveMessage(event);
    };

    @wire(CurrentPageReference)
    handlePageRef({ state } = {}) {
        if (!state) return;

        if (state.c__recordId)                   this.recordId                   = state.c__recordId;
        if (state.c__logikConfigurableProductId) this.logikConfigurableProductId = state.c__logikConfigurableProductId;
        if (state.c__pricebook2Id)               this.pricebook2Id               = state.c__pricebook2Id;
        if (state.c__currency)                   this.currency                   = state.c__currency;
        if (state.c__logikPid)                   this.logikPid                   = state.c__logikPid;
        if (state.c__logikUiHost)                this.logikUiHost                = state.c__logikUiHost;
        if (state.c__logikApiHost)               this.logikApiHost               = state.c__logikApiHost;
        if (state.c__logikApiToken)              this.logikApiToken              = state.c__logikApiToken;
        if (state.c__frameHeight)                this.frameHeight                = state.c__frameHeight;
        if (state.c__sfTransactionId)            this.sfTransactionId            = state.c__sfTransactionId;
        if (state.c__lgkTransactionId)           this.lgkTransactionId           = state.c__lgkTransactionId;
        if (state.c__logikApiTransactionId)      this.logikApiTransactionId      = state.c__logikApiTransactionId;
    }

    get normalizedUiHost() {
        if (!this.logikUiHost) {
            return '';
        }
        return this.logikUiHost.endsWith('/')
            ? this.logikUiHost.slice(0, -1)
            : this.logikUiHost;
    }

    // Dynamic Iframe URL getter
    get finalUrl() {
        // 1. If user clicked 'Quote', load the Logik Transaction UI screen
        if (this.overrideIframeUrl) {
            return this.overrideIframeUrl;
        }

        if (!this.normalizedUiHost || !this.logikConfigurableProductId) {
            return '';
        }

        // 2. Default: Load the Logik Configurator UI screen
        const baseUrl = `${this.normalizedUiHost}/ui/configure/${encodeURIComponent(this.logikConfigurableProductId)}`;  

        const params = new URLSearchParams();
        params.set('v', '1');

        const txnId = this.logikApiTransactionId || this.lgkTransactionId;
        if (txnId) {
            params.set('tid', txnId);
        }

        if (this.currency) {
            params.set('currency', this.currency);
        }

        if (this.pricebook2Id || this.logikPid) {
            params.set('pid', this.pricebook2Id || this.logikPid);
        }

        if (this.recordId) {
            params.set('recordId', this.recordId);
            params.set('opptyId', this.recordId); // Seeds cfgRequest.opptyId on boot
        }

        return `${baseUrl}?${params.toString()}`;
    }

    async receiveMessage(event) {
        if (!event.origin || !event.origin.includes(".logik.io")) {
            return;
        }

        try {
            let data = {};
            if (typeof event.data === 'string') {
                try {
                    data = JSON.parse(event.data);
                } catch (e) {
                    data = {};
                }
            } else if (typeof event.data === 'object' && event.data !== null) {
                data = event.data;
            }

            console.log('Logik postMessage payload received: ', JSON.stringify(data));

            const configUuid = data?.uuid;

            // ---------------------------------------------------------------
            // 1. QUOTE / SAVE EVENT: User clicks 'Quote' inside Configurator
            // ---------------------------------------------------------------
            if (configUuid) {
                const targetTxnId = this.logikApiTransactionId || this.lgkTransactionId;

                // Step A: Upsert transaction lines
                await upsertLogikTransactionLines({ 
                    logikTransactionId: targetTxnId, 
                    configUuid: configUuid 
                });

                this.dispatchEvent(new ShowToastEvent({
                    title: "Logik.io Configuration Saved",
                    message: "Loading Transaction UI...",
                    variant: "success"
                }));

                // Step B: Switch iframe source to Logik Transaction UI (/ui/transact/{tid})
                this.overrideIframeUrl = `${this.normalizedUiHost}/ui/transact/${targetTxnId}`;
            } 
            // ---------------------------------------------------------------
            // 2. CANCEL EVENT: User clicks 'Cancel' inside Iframe
            // ---------------------------------------------------------------
            else {
                this.dispatchEvent(new ShowToastEvent({
                    title: "Configuration Canceled",
                    message: "Returned to Opportunity.",
                    variant: "info"
                }));

                // Redirect user back to the Opportunity record
                if (this.recordId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.recordId,
                            actionName: 'view'
                        }
                    });
                }
            }

        } catch (error) {
            console.error('Error during Logik sync operations:', error);

            const errorMessage = error?.body?.message || error.message || 'Unknown error occurred';

            this.dispatchEvent(new ShowToastEvent({
                title: "Error syncing with Logik",
                message: errorMessage,
                variant: "error",
                mode: "sticky"
            }));
        }
    }
}
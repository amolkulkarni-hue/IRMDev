import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Import the Apex methods
import saveLogikConfiguration from '@salesforce/apex/logikTransaButtRedirectActionController.saveLogikConfiguration';
import upsertLogikTransactionLines from '@salesforce/apex/logikTransaButtRedirectActionController.upsertLogikTransactionLines';


export default class LogikOppConfigAction extends LightningElement {

    @api recordId;
    @api logikConfigurableProductId;
    @api pricebook2Id;
    @api currency = 'USD';
    @api logikPid;
    @api sfTransactionId;
    @api lgkTransactionId;
    @api logikUiHost;
    @api logikApiHost;
    @api logikApiToken;
    @api frameHeight = '80vh';
    @api logikApiTransactionId;
    @api configUuid;


    // Add event listener for message from iframe
    connectedCallback() {
        console.log('connectedCallback');
        window.addEventListener("message", (event) => this.receiveMessage(event,this,this));
    }

    // Remove event listener for message from iframe
    disconnectedCallback() {
    window.removeEventListener("message", (event) => this.receiveMessage(event,this,this));
    }

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
        if (state.c__configUuid)                 this.configUuid                 = state.c__configUuid;


    }


    get normalizedUiHost() {
        if (!this.logikUiHost) {
            return '';
        }
        return this.logikUiHost.endsWith('/')
            ? this.logikUiHost.slice(0, -1)
            : this.logikUiHost;
    }

    get finalUrl() {
        if (!this.normalizedUiHost || !this.logikConfigurableProductId) {
            return '';
        }

        /*const baseUrl =
            `${this.normalizedUiHost}/ui/configure/${encodeURIComponent(this.logikConfigurableProductId)}`;
        */

        // logikApiTransactionId  or lgkTransactionId
        const baseUrl =
            `${this.normalizedUiHost}/ui/transact/${encodeURIComponent(this.logikApiTransactionId)}`;  

        const params = new URLSearchParams();

        params.set('v', '1');

        /*
        if (this.logikPid) {
            params.set('pid', this.logikPid);
        }
        */

        
        /*
        if (this.lgkTransactionId) {
            params.set('lid', this.sfTransactionId);
        }
            */
        
        
        if (this.currency) {
            params.set('currency', this.currency);
        }

        /*
        if (this.pricebook2Id) {
            params.set('pid', this.pricebook2Id);
        }
        */

        /*
        if (this.recordId) {
            params.set('recordId', this.recordId);
        }
        */

        /*
        if (this.logikApiHost) {
            params.set('rta', this.logikApiHost);
        }
        */
        

        /*
        if (this.logikApiToken) {
            params.set('rt', this.logikApiToken);
        }
        */

        /*
        if (this.sfTransactionId) {
            const returnUrl = `${window.location.origin}/lightning/cmp/LGK__transactionAuraComponent?LGK__recordId=${this.sfTransactionId}`;
            params.set('return', returnUrl);
        }
        */
        
        const finalUrl = `${baseUrl}?${params.toString()}`;
        console.log('finalUrl logikOppConfigAction: ' + finalUrl);

        return `${baseUrl}?${params.toString()}`;
    }

    renderedCallback() {
        const iframe = this.template.querySelector('iframe');
        if (iframe && this.frameHeight) {
            iframe.style.height = this.frameHeight;
        }
    }

    // log message
    async receiveMessage(event, t) {
        // Verify that the event is from Logik
        if (event.origin.includes(".logik.io") === false) {
            return;
        }

        try {
            const data = JSON.parse(event.data);
            console.log('Logik payload data: ', JSON.stringify(data));


            /*

            // Ensure the uuid exists before making callouts
            if (!data || !data.uuid) {
                return;
            }

            const configUuid = data.uuid;

            // 1. Save Logik Configuration (Synchronous wait)
            await saveLogikConfiguration({ configUuid: configUuid });
            console.log('Configuration saved successfully.');

            // 2. Upsert Logik Transaction Lines (Synchronous wait)
            await upsertLogikTransactionLines({ logikTransactionId: this.lgkTransactionId, configUuid: configUuid });
            console.log('Transaction lines upserted successfully.');

            */

            // Show success toast after both operations complete
            const toast = new ShowToastEvent({
                title: "Logik.io Configuration Synced",
                message: `Meesage received from logik.io`,
                variant: "success",
                mode: "dismissable"
            });
            this.dispatchEvent(toast);

        } catch (error) {
            console.error('Error during Logik sync operations:', error);
            
            // Extract error message
            const errorMessage = error?.body?.message || error.message || 'Unknown error occurred';
            
            // Show error toast
            const errorToast = new ShowToastEvent({
                title: "Error syncing with Logik",
                message: errorMessage,
                variant: "error",
                mode: "sticky"
            });
            this.dispatchEvent(errorToast);
        }
    }
}
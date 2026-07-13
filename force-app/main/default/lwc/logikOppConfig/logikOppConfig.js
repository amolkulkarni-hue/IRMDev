import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class LogikOppConfig extends LightningElement {
    @api recordId;


    @api logikConfigurableProductId;
    @api pricebook2Id;
    @api currency = 'USD';
    @api logikPid;
    @api logikUiHost;
    @api logikApiHost;
    @api logikApiToken;
    @api frameHeight = '80vh';


    @wire(CurrentPageReference)
        handlePageRef({ state } = {}) {
            if (!state) return;

            if (!this.recordId                   && state.recordId)                   this.recordId                   = state.recordId;
            if (!this.logikConfigurableProductId && state.logikConfigurableProductId) this.logikConfigurableProductId = state.logikConfigurableProductId;
            if (!this.pricebook2Id               && state.pricebook2Id)               this.pricebook2Id               = state.pricebook2Id;
            if (!this.currency                   && state.currency)                   this.currency                   = state.currency;
            if (!this.logikPid                   && state.logikPid)                   this.logikPid                   = state.logikPid;
            if (!this.logikUiHost                && state.logikUiHost)                this.logikUiHost                = state.logikUiHost;
            if (!this.logikApiHost               && state.logikApiHost)               this.logikApiHost               = state.logikApiHost;
            if (!this.logikApiToken              && state.logikApiToken)              this.logikApiToken              = state.logikApiToken;
            if (!this.frameHeight                && state.frameHeight)                this.frameHeight                = state.frameHeight;
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

        const baseUrl =
            `${this.normalizedUiHost}/ui/configure/${encodeURIComponent(this.logikConfigurableProductId)}`;

        const params = new URLSearchParams();

        // Basado en lo que mostraste en el DOM
        params.set('v', '1');

        if (this.logikPid) {
            params.set('pid', this.logikPid);
        }

        if (this.currency) {
            params.set('currency', this.currency);
        }

        // útiles para /debug
        if (this.pricebook2Id) {
            params.set('pricebookId', this.pricebook2Id);
        }

        if (this.recordId) {
            params.set('recordId', this.recordId);
        }

        if (this.logikApiHost) {
            params.set('apiHost', this.logikApiHost);
        }

        if (this.logikApiToken) {
            params.set('apiToken', this.logikApiToken);
        }

        console.log('baseUrl logikOppConfig: ' + baseUrl);

        return `${baseUrl}?${params.toString()}`;
    }

    renderedCallback() {
        const iframe = this.template.querySelector('iframe');
        if (iframe && this.frameHeight) {
            iframe.style.height = this.frameHeight;
        }
    }
}
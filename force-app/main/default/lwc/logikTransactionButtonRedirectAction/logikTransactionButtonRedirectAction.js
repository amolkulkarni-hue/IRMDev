import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue, createRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

// Apex Callouts & Custom Metadata
import getLogikTenantUrl from '@salesforce/apex/logikTransaButtRedirectActionController.getLogikTenantUrl';
import getBlueprintMetadata from '@salesforce/apex/logikTransaButtRedirectActionController.getBlueprintMetadata';
import createLogikTransaction from '@salesforce/apex/logikTransaButtRedirectActionController.createLogikTransaction';

// Schema Imports
import ACCOUNT_FIELD           from '@salesforce/schema/Opportunity.AccountId';
import TRANSACTION_OBJECT      from '@salesforce/schema/LGK__Transaction__c';
import TRANSACTION_OPPORTUNITY from '@salesforce/schema/LGK__Transaction__c.LGK__OpportunityId__c';
import TRANSACTION_ACCOUNT     from '@salesforce/schema/LGK__Transaction__c.LGK__AccountId__c';
import LGK_ID_FIELD            from '@salesforce/schema/LGK__Transaction__c.LGK__Id__c';

export default class LogikTransactionButtonRedirectAction extends NavigationMixin(LightningElement) {

    @api recordId;

    _accountId;
    _sfTransactionId       = null;
    _logikTenantUrl        = null;
    _hasStarted            = false;    
    _pricebook2Id          = null;
    _configurableProductId = null;
    _logikApiTransactionId = null;
    
    showIframe    = false;
    isLoading     = true; 
    statusMessage = 'Initializing transaction...';
    
    @wire(getLogikTenantUrl)
    wiredLogikUrl({ data, error }) {
        if (data) {
            this._logikTenantUrl = data;
            console.log('[LTA] Logik Tenant URL:', this._logikTenantUrl);
        } else if (error) {
            console.error('[LTA] Error fetching _logikTenantUrl:', error);
        }
    }

    @wire(getBlueprintMetadata)
    wiredMetadata({ data, error }) {
        if (data) {
            this._configurableProductId = data.blueprint__c;
            this._pricebook2Id = data.pricebook__c;
            console.log('[LTA] Custom Metadata loaded:', data);
            this._checkAndRun(); 
        } else if (error) {
            console.error('[LTA] Error fetching Custom Metadata:', error);
            this._handleError(error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_FIELD] })
    wiredOpportunity({ data, error }) {
        if (data) {
            this._accountId = getFieldValue(data, ACCOUNT_FIELD);
            this._checkAndRun(); 
        } else if (error) {
            console.error('[LTA] Error fetching Opportunity:', error);
            this._handleError(error);
        }
    }

    _checkAndRun() {
        if (this._hasStarted && 
            !this._sfTransactionId && 
            this._accountId && 
            this._pricebook2Id && 
            this._configurableProductId) {
            
            this._run();
        }
    }

    connectedCallback() {
        this._init();
    }

    @api invoke() {
        this._init();
    }

    get containerClass() {
        return this.showIframe 
            ? 'fullscreen-container' 
            : 'slds-is-relative slds-p-around_medium';
    }

    _init() {
        this._hasStarted = true;
        this.isLoading = true;
        this.statusMessage = 'Initializing transaction...';

        if (this._accountId) {
            this._run();
        }
    }

    async _run() {
        if (!this._accountId) {
            this._handleError('The related account could not be recovered.');
            return;
        }

        this.statusMessage = 'Creating Salesforce Transaction...';

        try {
            // Step 1: Create Salesforce Transaction Record
            const createdRecord = await createRecord({
                apiName : TRANSACTION_OBJECT.objectApiName,
                fields  : {
                    [TRANSACTION_OPPORTUNITY.fieldApiName] : this.recordId,
                    [TRANSACTION_ACCOUNT.fieldApiName]     : this._accountId
                }
            });

            this._sfTransactionId = createdRecord.id; 
            
            // Step 2: Immediately process Logik callout (No Polling needed)
            await this._processCallouts();

        } catch (error) {
            this._handleError(error);
        }
    }

    async _processCallouts() {
        try {
            this.isLoading = true;

            // Step 1: Create Logik Transaction via API Callout
            this.statusMessage = 'Initializing Logik Transaction...';
            this._logikApiTransactionId = await createLogikTransaction({
                accountId: this._accountId,
                opportunityId: this.recordId,
                pricebookId: this._pricebook2Id,
                sfTransactionId: this._sfTransactionId
            });
            console.log('[LTA] Logik API Transaction created ID:', this._logikApiTransactionId);

            // Step 2: Update Salesforce Transaction with Logik ID
            this.statusMessage = 'Updating Salesforce Transaction...';            
            const recordInput = {
                fields: {
                    Id: this._sfTransactionId,
                    [LGK_ID_FIELD.fieldApiName]: this._logikApiTransactionId
                }
            };
            await updateRecord(recordInput);
            console.log('[LTA] SF Transaction LGK__Id__c updated successfully.');

            // Step 3: Navigate directly to Blueprint_Page
            this._navigate();

        } catch (error) {
            console.error('[LTA] Error during Logik setup operations:', error);
            this._handleError(error);
        }
    }

    _navigate() {
        console.log('[LTA] Navigating to Blueprint Page');
        this.isLoading = false;

        const navConfig = {
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Blueprint_Page'
            },
            state: {
                c__recordId:                   this.recordId,
                c__sfTransactionId:            this._sfTransactionId,
                c__lgkTransactionId:           this._logikApiTransactionId,
                c__logikUiHost:                this._logikTenantUrl,
                c__logikApiTransactionId:      this._logikApiTransactionId,
                c__logikConfigurableProductId: this._configurableProductId,
                c__pricebook2Id:               this._pricebook2Id
            }
        };

        console.log('[LTA] Navigating to:', JSON.stringify(navConfig)); 

        this[NavigationMixin.Navigate](navConfig);

        this._showToast('Success', 'Transaction ready. Redirecting to configurator...', 'success');
        this._close();
    }

    _handleError(error) {
        this.isLoading = false;
        const msg = typeof error === 'string' ? error : (error?.body?.message ?? 'Unknown Error');
        this._showToast('Error', msg, 'error');
        this._close();
    }

    _close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    _showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue, createRecord, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getLogikTenantUrl from '@salesforce/apex/logikTransaButtRedirectActionController.getLogikTenantUrl';
import getBlueprintMetadata from '@salesforce/apex/logikTransaButtRedirectActionController.getBlueprintMetadata';

// Import all required Apex callout methods
import createLogikTransaction from '@salesforce/apex/logikTransaButtRedirectActionController.createLogikTransaction';
import createLogikConfiguration from '@salesforce/apex/logikTransaButtRedirectActionController.createLogikConfiguration';
import saveLogikConfiguration from '@salesforce/apex/logikTransaButtRedirectActionController.saveLogikConfiguration';
import upsertLogikTransactionLines from '@salesforce/apex/logikTransaButtRedirectActionController.upsertLogikTransactionLines';

import ACCOUNT_FIELD           from '@salesforce/schema/Opportunity.AccountId';
import TRANSACTION_OBJECT      from '@salesforce/schema/LGK__Transaction__c';
import TRANSACTION_OPPORTUNITY from '@salesforce/schema/LGK__Transaction__c.LGK__OpportunityId__c';
import TRANSACTION_ACCOUNT     from '@salesforce/schema/LGK__Transaction__c.LGK__AccountId__c';
import LGK_ID_FIELD            from '@salesforce/schema/LGK__Transaction__c.LGK__Id__c';

const TRANSACTION_PATH = '/lightning/cmp/LGK__transactionAuraComponent?LGK__recordId=';
const POLL_INTERVAL_MS = 2000;
const MAX_POLLS        = 60;

export default class LogikTransactionButtonRedirectAction extends NavigationMixin(LightningElement) {

    @api recordId;

    _accountId;
    _sfTransactionId  = null;
    _lgkTransactionId = null;
    _transactionUrl   = null;
    _wiredTxResult    = null;
    _pollInterval     = null;
    _pollCount        = 0;
    _logikTenantUrl   = null;
    _hasStarted = false;    
    _pricebook2Id = null;
    _configurableProductId = null;
    _logikApiTransactionId = null;
    _configUuid = null;
    
    showIframe = false;
    isLoading = true; 
    statusMessage = 'Transaction created. Waiting for processing...';
    
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
            console.log('[LTA] Custom Metadata cargado:', data);
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

    @wire(getRecord, { recordId: '$_sfTransactionId', fields: [LGK_ID_FIELD] })
    wiredTransaction(result) {
        this._wiredTxResult = result;
        const { data, error } = result;
        if (data) {
            const lgkId = getFieldValue(data, LGK_ID_FIELD);
            if (lgkId != null) {
                this._lgkTransactionId = lgkId;
                this._stopPolling();
                
                // Initiate sequential callouts once lgkId is successfully polled
                this._processSequentialCallouts();
            }
        }
        if (error) console.error('[LTA] Error polling Transaction:', error);
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
        this.statusMessage = 'Transaction created. Waiting for processing...';

        if (this._accountId) {
            this._run();
        }
    }

    async _run() {
        if (!this._accountId) {
            this._handleError('The related account could not be recovered.');
            return;
        }

        this.statusMessage = 'Creating transaction...';

        try {
            const createdRecord = await createRecord({
                apiName : TRANSACTION_OBJECT.objectApiName,
                fields  : {
                    [TRANSACTION_OPPORTUNITY.fieldApiName] : this.recordId,
                    [TRANSACTION_ACCOUNT.fieldApiName]     : this._accountId
                }
            });

            this._transactionUrl = `${window.location.origin}${TRANSACTION_PATH}${createdRecord.id}`;
            this._sfTransactionId  = createdRecord.id; 
            
            this.statusMessage = 'Processing in Logik...';

            this._pollCount    = 0;
            this._pollInterval = setInterval(async () => {
                this._pollCount++;
                if (this._pollCount >= MAX_POLLS) {
                    this._stopPolling();
                    this._showToast('Warning', 'Waiting timed out. Please check manually.', 'warning');
                    this._close();
                    return;
                }

                await refreshApex(this._wiredTxResult);
            }, POLL_INTERVAL_MS);

        } catch (error) {
            this._handleError(error);
        }
    }

    /**
     * Executes Logik API callouts sequentially following the architectural pathway.
     */
    async _processSequentialCallouts() {
        try {
            this.isLoading = true;

            console.log('this.recordId: ' + this.recordId);
            console.log('this._accountId: ' + this._accountId);
            console.log('this._pricebook2Id: ' + this._pricebook2Id);
            console.log('this._configurableProductId: ' + this._configurableProductId);
            console.log('this._sfTransactionId: ' + this._sfTransactionId);

            //Stpe 0: Create a LGK__Transaction__c records in salesforce (already created at this point)

            console.log('Step 0: [LTA] SF  Transaction (LGK__Transaction__c.LGK__Id__c): ' + this._lgkTransactionId);

            // Step 1 (Callout): Create Logik Transaction via API (THIS IS TRANSACION IN LOGIK AND IS DIFFERENT TO SF TRANSACTION CREATE IN BEFORE STEP)
            this.statusMessage = 'Initializing Logik Transaction...';
            this._logikApiTransactionId = await createLogikTransaction({
                accountId: this._accountId,
                opportunityId: this.recordId,
                pricebookId: this._pricebook2Id,
                sfTransactionId: this._sfTransactionId
            });
            console.log('Step 1 (Callout): [LTA] Logik API Transaction created (LOGIK). ID:', this._logikApiTransactionId);

            // Step 2 (Callout): Create Configuration (Returns the UUID)
            this.statusMessage = 'Creating Logik Configuration...';
            this._configUuid = await createLogikConfiguration({
                configurableProductId: this._configurableProductId
            });
            console.log('Step 2 (Callout): [LTA] Configuration created. UUID:', this._configUuid);

            // Step 3 (Callout): Save Configuration
            this.statusMessage = 'Saving Configuration...';
            await saveLogikConfiguration({ 
                configUuid: this._configUuid
            });
            console.log('Step 3 (Callout): [LTA] Configuration saved successfully.');

            await new Promise(resolve => setTimeout(resolve, 5000));
            // Step 4 (Callout): Upsert lines to Transaction
            // Using the polled lgkId as per the requirement logic.
            this.statusMessage = 'Adding Configuration to Transaction...';
            await upsertLogikTransactionLines({
                logikTransactionId: this._logikApiTransactionId,  
                configUuid: this._configUuid
            });
            console.log('Step 4 (Callout):[LTA] Transaction lines upserted with  _logikAPITransactionId: ' + this._logikApiTransactionId +  ' and configUuid: ' + this._configUuid);

            this.statusMessage = 'Updating Salesforce Transaction...';            
            const recordInput = {
                fields: {
                    Id: this._sfTransactionId,
                    [LGK_ID_FIELD.fieldApiName]: this._logikApiTransactionId
                }
            };
            
            await updateRecord(recordInput);
            console.log('Step 5: [LTA] SF Transaction LGK__Id__c updated successfully with Logik API ID.');

            // Final step: Proceed to navigation
            this._navigate(); // NOT NAVIGATE FOR NOW

        } catch (error) {
            console.error('[LTA] Error during Logik sequential sync operations:', error);
            this._handleError(error);
        }
    }

    _navigate() {
        console.log('[LTA] _navigate');
        this.isLoading = false;


        const navConfig = {
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Blueprint_Page'
            },
            state: {
                c__sfTransactionId:            this._sfTransactionId,
                c__lgkTransactionId:           this._lgkTransactionId,
                c__logikUiHost:                this._logikTenantUrl,
                c__logikApiTransactionId:      this._logikApiTransactionId,
                c__configUuid:                 this._configUuid
            }
        };

        console.log('[LTA] Navigating to:', JSON.stringify(navConfig)); 

        this[NavigationMixin.Navigate](navConfig);

        this._showToast('Success', 'Transaction ready. Redirecting...', 'success');
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

    _stopPolling() {
        if (this._pollInterval) {
            clearInterval(this._pollInterval);
            this._pollInterval = null;
        }
    }

    disconnectedCallback() { 
        this._stopPolling(); 
    }

    _showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
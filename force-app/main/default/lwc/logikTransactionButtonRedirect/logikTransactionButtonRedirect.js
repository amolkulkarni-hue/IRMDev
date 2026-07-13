import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, createRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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

export default class LogikTransactionButtonRedirect extends LightningElement {

    @api recordId;
    @api buttonLabel   = 'Create Quote';
    @api buttonTooltip = 'Open transaction link';
    @api iconName      = 'utility:link';
    @api buttonVariant = 'brand';
    @api openInNewTab  = false;

    _accountId;
    _isLoading      = false;
    _transactionId  = null;   
    _transactionUrl = null;
    _wiredTxResult  = null;
    _pollInterval   = null;
    _pollCount      = 0;
    _isProcessingCallouts = false;

    // Hardcoded parameters as per previous configurations
    _pricebook2Id = '01s80000000AnTZAA0';
    _configurableProductId = '01tgP000005UfvhQAC';
    _logikApiTransactionId = null;
    _configUuid = null;

    // Fetch AccountId from the current Opportunity
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_FIELD] })
    wiredOpportunity({ data, error }) {
        if (data) {
            this._accountId = getFieldValue(data, ACCOUNT_FIELD);
        }
        if (error) {
            console.error('[LTB] Error fetching Opportunity:', error);
        }
    }

    // Poll LGK__Transaction__c until LGK__Id__c is populated
    @wire(getRecord, { recordId: '$_transactionId', fields: [LGK_ID_FIELD] })
    wiredTransaction(result) {
        this._wiredTxResult = result; 
        const { data, error } = result;

        if (data) {
            const lgkId = getFieldValue(data, LGK_ID_FIELD);
            // Verify if lgkId is populated and we haven't started the next steps yet
            if (lgkId != null && !this._isProcessingCallouts) {
                console.log('[LTB] Logik ID populated in Salesforce record:', lgkId);
                this._stopPolling();
                
                // Execute Step 3, 4, and 5 sequentially
                this._processRemainingSteps();
            }
        }
        if (error) {
            console.error('[LTB] Error polling Transaction:', error);
        }
    }

    // Button click handler
    async handleClick() {
        if (!this.recordId) {
            console.warn('[LTB] recordId is not available.');
            return;
        }
        if (!this._accountId) {
            this._showToast('Error', 'Could not retrieve the Account from this Opportunity.', 'error');
            return;
        }

        this._isLoading = true;

        try {
            // Step 1: Callout to create Logik Transaction
            console.log('[LTB] Step 1: Creating Logik API Transaction...');
            this._logikApiTransactionId = await createLogikTransaction({
                accountId: this._accountId,
                opportunityId: this.recordId,
                pricebookId: this._pricebook2Id
            });
            console.log('[LTB] Logik API Transaction created. ID:', this._logikApiTransactionId);

            // Step 2: Create Transaction record in Salesforce
            console.log('[LTB] Step 2: Creating Salesforce Transaction record...');
            const createdRecord = await createRecord({
                apiName : TRANSACTION_OBJECT.objectApiName,
                fields  : {
                    [TRANSACTION_OPPORTUNITY.fieldApiName] : this.recordId,
                    [TRANSACTION_ACCOUNT.fieldApiName]     : this._accountId
                }
            });
            
            // Storing IDs to trigger the reactive @wire
            this._transactionId = createdRecord.id;
            this._transactionUrl = `${window.location.origin}${TRANSACTION_PATH}${this._transactionId}`;
            console.log('[LTB] Salesforce Transaction created. ID:', this._transactionId);

            this._showToast('Info', 'Transaction created. Waiting for background sync...', 'info');

            // Start polling via refreshApex to wait for LGK__Id__c
            this._pollCount    = 0;
            this._pollInterval = setInterval(async () => {
                this._pollCount++;

                if (this._pollCount >= MAX_POLLS) {
                    this._stopPolling();
                    this._isLoading = false;
                    this._showToast('Warning', 'Timeout reached. Please verify the Transaction manually.', 'warning');
                    return;
                }

                await refreshApex(this._wiredTxResult); 
            }, POLL_INTERVAL_MS);

        } catch (error) {
            console.error('[LTB] Error during step 1 or 2:', error);
            const msg = typeof error === 'string' ? error : (error?.body?.message ?? error?.message ?? 'Unknown Error');
            this._showToast('Error', msg, 'error');
            this._isLoading = false;
        }
    }

    // Executes steps 3, 4, and 5 after polling succeeds
    async _processRemainingSteps() {
        this._isProcessingCallouts = true;

        try {
            // Step 3: Callout to create Configuration
            console.log('[LTB] Step 3: Creating Logik Configuration...');
            this._configUuid = await createLogikConfiguration({
                configurableProductId: this._configurableProductId
            });
            console.log('[LTB] Configuration created. UUID:', this._configUuid);

            // Step 4: Callout to save Configuration
            console.log('[LTB] Step 4: Saving Configuration...');
            await saveLogikConfiguration({
                configUuid: this._configUuid
            });
            console.log('[LTB] Configuration saved successfully.');

            // Step 5: Callout to upsert lines to Transaction
            console.log('[LTB] Step 5: Upserting lines to Transaction...');
            await upsertLogikTransactionLines({
                logikTransactionId: this._logikApiTransactionId, 
                configUuid: this._configUuid
            });
            console.log('[LTB] Transaction lines upserted successfully.');

            // Final Step: Navigate
            this._navigate();

        } catch (error) {
            console.error('[LTB] Error during steps 3, 4, or 5:', error);
            const msg = typeof error === 'string' ? error : (error?.body?.message ?? error?.message ?? 'Unknown Error');
            this._showToast('Error', msg, 'error');
            this._isLoading = false;
        }
    }

    // Navigate to the Transaction URL
    _navigate() {
        this._isLoading = false;
        this._showToast('Success', 'Transaction is ready. Redirecting...', 'success');
        
        if (this.openInNewTab) {
            window.open(this._transactionUrl, '_blank', 'noopener,noreferrer');
        } else {
            window.location.href = this._transactionUrl;
        }
    }

    // Stop the polling interval
    _stopPolling() {
        if (this._pollInterval) {
            clearInterval(this._pollInterval);
            this._pollInterval = null;
        }
    }

    // Clean up when the component is removed from the DOM
    disconnectedCallback() {
        this._stopPolling();
    }

    // Toast helper
    _showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
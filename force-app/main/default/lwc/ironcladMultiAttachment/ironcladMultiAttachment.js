import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunityFiles from '@salesforce/apex/IroncladAttachmentController.getOpportunityFiles';
import uploadAttachments from '@salesforce/apex/IroncladAttachmentController.uploadAttachments';

export default class IroncladMultiAttachment extends LightningElement {
    @api workflowId;
    @api opportunityId;
    @api attributeId;

    @track files = [];
    @track selectedFileIds = [];
    @track isLoading = true;
    @track isUploading = false;
    @track uploadStatus = '';

    get hasFiles() {
        return this.files.length > 0;
    }

    connectedCallback() {
        this.loadFiles();
    }

    loadFiles() {
        this.isLoading = true;
        getOpportunityFiles({ opportunityId: this.opportunityId })
            .then(result => {
                this.files = result;
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Could not load files: ' + error.body.message, 'error');
            });
    }

    handleFileSelection(event) {
        const fileId = event.target.value;
        const isChecked = event.target.checked;

        if (isChecked) {
            this.selectedFileIds = [...this.selectedFileIds, fileId];
        } else {
            this.selectedFileIds = this.selectedFileIds.filter(id => id !== fileId);
        }
    }

    handleUpload() {
        if (this.selectedFileIds.length === 0) {
            this.showToast('Warning', 'Please select at least one file.', 'warning');
            return;
        }

        this.isUploading = true;
        this.uploadStatus = 'Uploading files to Ironclad...';

        uploadAttachments({
            workflowId: this.workflowId,
            attributeId: this.attributeId,
            contentVersionIds: this.selectedFileIds
        })
        .then(result => {
            this.isUploading = false;
            if (result === 'Success') {
                this.uploadStatus = '';
                this.showToast(
                    'Success',
                    this.selectedFileIds.length + ' file(s) successfully attached to Ironclad.',
                    'success'
                );
            } else {
                this.uploadStatus = 'Some files failed: ' + result;
                this.showToast('Partial Error', result, 'warning');
            }
        })
        .catch(error => {
            this.isUploading = false;
            this.uploadStatus = '';
            this.showToast('Error', 'Upload failed: ' + error.body.message, 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
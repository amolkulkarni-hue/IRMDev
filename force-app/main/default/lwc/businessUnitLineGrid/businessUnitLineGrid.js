import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getActiveLines from '@salesforce/apex/BusinessUnitLineGridController.getActiveLines';
import saveDraftValues from '@salesforce/apex/BusinessUnitLineGridController.saveDraftValues';
import createLine from '@salesforce/apex/BusinessUnitLineGridController.createLine';
import getPicklistOptions from '@salesforce/apex/BusinessUnitLineGridController.getPicklistOptions';

const COLUMNS = [
    { label: 'Business Unit', fieldName: 'Business_Unit__c', type: 'text', editable: false },
    { label: 'Product Family', fieldName: 'Product_Family__c', type: 'text', editable: true },
    { label: 'Product Line', fieldName: 'Product_Line__c', type: 'text', editable: true },
    { label: 'EAA', fieldName: 'EAA__c', type: 'currency', editable: true },
    { label: 'Primary BU', fieldName: 'Is_Primary__c', type: 'boolean', editable: false },
    { label: 'Active', fieldName: 'Is_Active__c', type: 'boolean', editable: true }
];

export default class BusinessUnitLineGrid extends LightningElement {
    @api recordId;

    columns = COLUMNS;
    draftValues = [];
    wiredLinesResult;

    showAddForm = false;
    newLine = {};

    businessUnitOptions = [];
    productFamilyOptions = [];
    productLineOptions = [];

    @wire(getActiveLines, { opportunityId: '$recordId' })
    wiredLines(result) {
        this.wiredLinesResult = result;
    }

    @wire(getPicklistOptions)
    wiredPicklistOptions({ data }) {
        if (data) {
            this.businessUnitOptions = this.toOptions(data.Business_Unit__c);
            this.productFamilyOptions = this.toOptions(data.Product_Family__c);
            this.productLineOptions = this.toOptions(data.Product_Line__c);
        }
    }

    toOptions(values) {
        return (values || []).map((value) => ({ label: value, value }));
    }

    get lines() {
        return this.wiredLinesResult && this.wiredLinesResult.data ? this.wiredLinesResult.data : [];
    }

    get hasLines() {
        return this.lines.length > 0;
    }

    handleSave(event) {
        const draftValues = event.detail.draftValues;

        saveDraftValues({ draftValuesJson: JSON.stringify(draftValues) })
            .then(() => {
                this.draftValues = [];
                this.showToast('Success', 'Business Unit line(s) updated.', 'success');
                return refreshApex(this.wiredLinesResult);
            })
            .catch((error) => {
                this.showToast('Error saving changes', this.extractErrorMessage(error), 'error');
            });
    }

    handleShowAddForm() {
        this.newLine = {};
        this.showAddForm = true;
    }

    handleCancelAdd() {
        this.showAddForm = false;
        this.newLine = {};
    }

    handleNewLineFieldChange(event) {
        const field = event.target.dataset.field;
        const value = field === 'EAA__c' ? Number(event.target.value) : event.target.value;
        this.newLine = { ...this.newLine, [field]: value };
    }

    handleSaveNewLine() {
        createLine({ opportunityId: this.recordId, newLineJson: JSON.stringify(this.newLine) })
            .then(() => {
                this.showAddForm = false;
                this.newLine = {};
                this.showToast('Success', 'Business Unit line added.', 'success');
                return refreshApex(this.wiredLinesResult);
            })
            .catch((error) => {
                this.showToast('Error adding line', this.extractErrorMessage(error), 'error');
            });
    }

    extractErrorMessage(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'An unknown error occurred.';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}

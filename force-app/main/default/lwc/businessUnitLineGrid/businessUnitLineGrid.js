import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_PRODUCT_LINE_OBJECT from '@salesforce/schema/Opportunity_Product_Line__c';
import getActiveLines from '@salesforce/apex/BusinessUnitLineGridController.getActiveLines';
import saveDraftValues from '@salesforce/apex/BusinessUnitLineGridController.saveDraftValues';
import createLine from '@salesforce/apex/BusinessUnitLineGridController.createLine';

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

    objectInfo;
    picklistFieldValues;

    @wire(getActiveLines, { opportunityId: '$recordId' })
    wiredLines(result) {
        this.wiredLinesResult = result;
    }

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_PRODUCT_LINE_OBJECT })
    wiredObjectInfo({ data }) {
        if (data) {
            this.objectInfo = data;
        }
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: OPPORTUNITY_PRODUCT_LINE_OBJECT,
        recordTypeId: '$objectInfo.defaultRecordTypeId'
    })
    wiredPicklistValues({ data }) {
        if (data) {
            this.picklistFieldValues = data.picklistFieldValues;
        }
    }

    get lines() {
        return this.wiredLinesResult && this.wiredLinesResult.data ? this.wiredLinesResult.data : [];
    }

    get hasLines() {
        return this.lines.length > 0;
    }

    get businessUnitOptions() {
        return this.picklistFieldValues ? this.picklistFieldValues.Business_Unit__c.values : [];
    }

    get productFamilyOptions() {
        return this.dependentOptions('Product_Family__c', this.newLine.Business_Unit__c);
    }

    get productLineOptions() {
        return this.dependentOptions('Product_Line__c', this.newLine.Product_Family__c);
    }

    get productFamilyDisabled() {
        return !this.newLine.Business_Unit__c;
    }

    get productLineDisabled() {
        return !this.newLine.Product_Family__c;
    }

    get productFamilyPlaceholder() {
        return this.productFamilyDisabled ? 'Select a Business Unit first' : 'Select Product Family';
    }

    get productLinePlaceholder() {
        return this.productLineDisabled ? 'Select a Product Family first' : 'Select Product Line';
    }

    dependentOptions(fieldApiName, controllingValue) {
        if (!this.picklistFieldValues || !controllingValue) {
            return [];
        }
        const field = this.picklistFieldValues[fieldApiName];
        const controllerIndex = field.controllerValues[controllingValue];
        if (controllerIndex === undefined) {
            return [];
        }
        return field.values.filter((entry) => entry.validFor.includes(controllerIndex));
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

        const updated = { ...this.newLine, [field]: value };
        if (field === 'Business_Unit__c') {
            updated.Product_Family__c = undefined;
            updated.Product_Line__c = undefined;
        } else if (field === 'Product_Family__c') {
            updated.Product_Line__c = undefined;
        }
        this.newLine = updated;
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
        if (!error) {
            return 'An unknown error occurred.';
        }
        const body = error.body;
        if (Array.isArray(body) && body.length > 0 && body[0].message) {
            return body[0].message;
        }
        if (body && body.message) {
            return body.message;
        }
        if (error.message) {
            return error.message;
        }
        return 'An unknown error occurred.';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}

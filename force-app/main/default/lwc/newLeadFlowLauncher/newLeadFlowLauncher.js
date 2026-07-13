import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import {CurrentPageReference} from 'lightning/navigation';

export default class NewLeadFlowLauncher extends NavigationMixin(LightningElement) {

    // ==== REPLACE THIS with your Flow's API Name ====
    flowApiName = 'Create_Lead_From_List_View';
    // ================================================

    @api recordId;   // Populated automatically when launched from a record page
    @api objectApiName;

    @track inputVariables = [];
    //_recordId;

   @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        // Pass inputs into the Flow if needed.
        // Only include this if your Flow has a matching input variable.
        console.log('>>>recordId>>>' + this.recordId);
        if (this.recordId) {
            this.inputVariables = [
                {
                    name: 'recordId',          // must match the Flow variable name
                    type: 'String',
                    value: this.recordId
                }
            ];
        }
    }

    handleFlowStatusChange(event) {
        const status = event.detail.status;

        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            // Optionally read an output variable from the Flow
            const outputVars = event.detail.outputVariables;
            let newRecordId;

            if (outputVars) {
                const idVar = outputVars.find(v => v.name === 'varNewLeadId');
                if (idVar) {
                    newRecordId = idVar.value;
                }
            }

            console.log('New Lead created with Id: ' + newRecordId);

            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Lead created successfully.',
                variant: 'success'
            }));


            if(this.recordId == null || this.recordId == undefined){
                // Bubble up to Aura wrapper so VF/Lightning Out context can navigate
                this.dispatchEvent(new CustomEvent('flowfinished', {
                detail: { recordId: newRecordId },
                    bubbles: true,
                    composed: true
                }));

            } else {
                //Navigate to the new record if in Lightning Experience context
                console.log('>>>newRecordId>>>'+newRecordId);
               //try {
                //Close the modal/quick action
                this.closeComponent();
                 window.location.href = '/lightning/r/Lead/' + newRecordId + '/view';

               /*this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: newRecordId,
                        actionName: 'view'
                    }
                });
               } catch (error) {

                console.error('Navigation error: ', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Navigation Error',
                    message: 'Could not navigate to the new record. Please try again.',
                    variant: 'error'
                }));
               }*/
                
                

                
            }   
            

            
        }

        if (status === 'ERROR') {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'The flow encountered an error. Please try again.',
                variant: 'error'
            }));
        }
    }

    closeComponent() {
        // Works when the component is launched as a Quick Action
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
/**
 * 	Class:				SCVGoWrapper
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class contains different wrapper classes which are used for SCV Go solution.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */

public with sharing class SCVGoWrapper {
    public class ListInstances{
        private String NextToken = null;
        @AuraEnabled
        public List<InstanceSummary> InstanceSummaryList = null;
    }

    public class InstanceSummary{
        @AuraEnabled
        public Integer Delay = 0;
        @AuraEnabled
        public String arn = null;
        @AuraEnabled
        public String id = null;
        @AuraEnabled
        public String IdentityManagementType = null;
        @AuraEnabled
        public String InstanceAlias = null;
        @AuraEnabled
        public Boolean InboundCallsEnabled = false;
        @AuraEnabled
        public Boolean OutboundCallsEnabled = false;
        @AuraEnabled
        public String InstanceStatus = null;
        @AuraEnabled
        public String ServiceRole = null;
        
        public InstanceSummary(){}
    }

    virtual public class DataTableColumn{
        @AuraEnabled
        public String type = null;
        @AuraEnabled
        public Map<String,Object> typeAttributes{get; private set;}
    }
    public class DataTableDataColumn extends DataTableColumn{
        @AuraEnabled
        public String label = null;
        @AuraEnabled
        public String fieldName = null;
        @AuraEnabled
        public Integer fixedWidth = null;
        @AuraEnabled
        public Integer initialWidth = 100;

        DataTableDataColumn(){
            this.typeAttributes = new Map<String,Object>();
        }

        public DataTableDataColumn(String inputLabel, String inputField, String inputType){
            this.label = inputLabel;
            this.fieldName = inputField;
            this.type = inputType;
            this.typeAttributes = new Map<String,Object>();
        }

        public void addAttribute(String attrName, Object attrValue){
            this.typeAttributes.put(attrName, attrValue);
        }

        public void addButtonLabel(String buttonLabel){
            this.addAttribute('label', buttonLabel);
        }

        public void addButtonName(String buttonName){
            this.addAttribute('name', buttonName);
        }

        public void addButtonVariant(String buttonVariant){
            this.addAttribute('variant', buttonVariant);
        }

        public void addButtonDisabilityIdentifier(String disableAttribute){
            this.addAttribute('disabled', new Map<String,String>{'fieldName' => disableAttribute});
        }

        public void setFixedWidth(Integer inputWidth){
            if(this.initialWidth > 0 && this.initialWidth > this.fixedWidth){
                this.fixedWidth = this.initialWidth;
            }
            else{
                this.fixedWidth = inputWidth;
            }
        }

        public void setInitialWidth(Integer inputWidth){
            this.initialWidth = inputWidth;
        }
    }

    public class PicklistOption{
        @AuraEnabled
        public String label = '';
        @AuraEnabled
        public String value = '';
        @AuraEnabled
        public String description = '';

        public PicklistOption() {}
        public PicklistOption(String inputLabel, String inputValue) {
            this.label = inputLabel;
            this.value = inputValue;
        }
        public PicklistOption(String inputLabel, String inputValue, String inputDescription) {
            this.label = inputLabel;
            this.value = inputValue;
            this.description = inputDescription;
        }
    }

    public class ListQueues{
        private String NextToken = null;
        public List<QueueSummary> QueueSummaryList = null;
        
        public ListQueues(){
            this.QueueSummaryList = new List<QueueSummary>();
        }
    }

    public class QueueSummary{
        public String Arn = null;
        public String Id = null;
        public String Name = null;
        public String QueueType = null;
        
        public QueueSummary(){}
    }

    public class ListContactFlows{
        private String NextToken = null;
        @AuraEnabled
        public List<ContactFlowSummary> ContactFlowSummaryList = null;
    }

    public class ContactFlowSummary{
        @AuraEnabled
        public String Arn = null;
        @AuraEnabled
        public String Id = null;
        @AuraEnabled
        public String ContactFlowState = null;
        @AuraEnabled
        public String ContactFlowType = null;
        @AuraEnabled
        public String Name = null;
        
        public ContactFlowSummary(){}
    }
}
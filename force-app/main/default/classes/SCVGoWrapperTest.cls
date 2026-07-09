/**
 * 	Class:				SCVGoWrapperTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoWrapper apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */

@IsTest
public with sharing class SCVGoWrapperTest {
    @IsTest
    static void testConstructors(){
        SCVGoWrapper.DataTableColumn sDataTableColumn = new SCVGoWrapper.DataTableColumn();
        SCVGoWrapper.InstanceSummary instanceSummary = new SCVGoWrapper.InstanceSummary();
        SCVGoWrapper.DataTableDataColumn dataTableDataColumn = new SCVGoWrapper.DataTableDataColumn('test', 'test', 'test');
        dataTableDataColumn.addAttribute('TEST', new SCVGoException());
        dataTableDataColumn.addButtonLabel('test');
        dataTableDataColumn.addButtonVariant('test');
        dataTableDataColumn.addButtonDisabilityIdentifier('test');
        dataTableDataColumn.setFixedWidth(2);
        dataTableDataColumn.setInitialWidth(2);
        SCVGoWrapper.PicklistOption picklistOption = new SCVGoWrapper.PicklistOption();
        SCVGoWrapper.PicklistOption picklistOption2 = new SCVGoWrapper.PicklistOption('TEST' ,'TEST', 'TEST');
        SCVGoWrapper.ListQueues listQueues = new SCVGoWrapper.ListQueues();
        SCVGoWrapper.ContactFlowSummary contactFlowSummary = new SCVGoWrapper.ContactFlowSummary();
        SCVGoWrapper.QueueSummary queueSummary = new SCVGoWrapper.QueueSummary();
        Assert.areEqual(dataTableDataColumn.initialWidth, 2);
    }
}
/**
 * 	Class:				UserInterfaceActionResult
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class creates instances for any action that is generated from Aura/LWC components.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public with sharing class UserInterfaceActionResult {
    
    @AuraEnabled
    public Boolean actionStatus{get; private set;}
    @AuraEnabled
    public String actionMessage{get; private set;}
    @AuraEnabled
    public Object actionPayload{get; private set;}

    UserInterfaceActionResult(){
        this.actionStatus = false;
        this.actionMessage = null;
        this.actionPayload = null;
    }

    public UserInterfaceActionResult(Boolean inputStatus, String inputMessage){
        this.actionStatus = inputStatus;
        this.actionMessage = inputMessage;
    }

    public UserInterfaceActionResult(Boolean inputStatus, String inputMessage, Object inputPayload){
        this.actionStatus = inputStatus;
        this.actionMessage = inputMessage;
        this.actionPayload = inputPayload;
    }

    public void setMessage(String inputMessage){
        this.actionMessage = inputMessage;
    }

    public void setPayload(Object inputPayload){
        this.actionPayload = inputPayload;
    }

    public void hasFailed(){
        this.actionStatus = false;
    }

    public void hasSucceeded(){
        this.actionStatus = true;
    }
}
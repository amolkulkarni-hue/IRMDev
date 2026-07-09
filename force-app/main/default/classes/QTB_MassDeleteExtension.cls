/*****************************************************************************************************
* Class: QTB_MassDeleteExtension
* Author: Accenture
* Purpose: This is a controller class for QTB_MassDeleteUsage VF page
* Requirement: QTB-14/SFCPQBLG 62
* Change History: 6/02/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              5/22/2020
*******************************************************************************************************/
public without sharing class QTB_MassDeleteExtension {
    
    public static boolean throwExplicitException = false;
    ApexPages.StandardSetController setCon;
    public String error { 
        get; 
        set;
    }
    public PageReference originalUrl { get; set; }
    public Boolean isValidOperation { get; private set; }

    public QTB_MassDeleteExtension(ApexPages.StandardSetController controller) {
        setCon = controller;
        this.isValidOperation = true;        
    }

    public String getMySelectedSize() {
        return setCon.getSelected().size() + '';
    }
    
    public PageReference deleteRecords(){
        originalUrl = setCon.cancel();
        try {
             system.debug(userinfo.getUserId());         
            delete setCon.getSelected();
            
            if(throwExplicitException){
               throw new NullPointerException();
           }
            return originalUrl;
        } 
        catch(Exception e) {
             //QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'Mass Delete');
            this.error = e.getMessage();
            this.isValidOperation = false;
        }  
        return null;
    }
}
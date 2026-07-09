/*****************************************************************************************************
* Class: QTB_OpportunityTeamHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to OpportunityTeamMember object
* Requirement: 
* Change History: 5/29/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              5/29/2020
*******************************************************************************************************/
public without sharing class QTB_OpportunityTeamHelper {
    public static final String OPPORTUNITYTEAMHELPER = 'QTB_OpportunityTeamHelper';
    
    /***********************************************************************************************************
    * Method :      process
    * Parameters:   List<SBQQ__Quote__c>,Map<Id, SBQQ__Quote__c>,System.TriggerOperation
    * Return Type : void
    * Description:  This method loops over the list of records to be processed 
    **************************************************************************************************************/      
    public static void process(List<OpportunityTeamMember> newItems, Map<Id, OpportunityTeamMember> oldItems, System.TriggerOperation operationType){ 
        //Storage
        Map<ID,List<ShareObjectData>> oppIdToshareObjectDataListMapInsert = new Map<ID,List<ShareObjectData>>();
        Map<ID,List<ShareObjectData>> oppIdToshareObjectDataListMapUpdate = new Map<ID,List<ShareObjectData>>();
        //process
        for(OpportunityTeamMember optyTeam : newItems)
        {
            switch on operationType 
            {
                when BEFORE_INSERT,BEFORE_DELETE,AFTER_DELETE
                {
                    
                    ShareObjectData objWrap = new ShareObjectData();
                    objWrap.userId = optyTeam.UserId;
                    objWrap.isEdit = True;
                    //To revoke access for Oppty Team if modified rom Edit to Read or if Opty Team is deleted
                    if(optyTeam.OpportunityAccessLevel == QTB_Constants.OPPTY_ACCESSLEVEL_READ || Trigger.isDelete){
                        objWrap.isEdit = False;
                    }
                    
                    if(oppIdToshareObjectDataListMapInsert.containsKey(optyTeam.OpportunityId)){
                        oppIdToshareObjectDataListMapInsert.get(optyTeam.OpportunityId).add(objWrap);
                    }
                    else{
                        oppIdToshareObjectDataListMapInsert.put(optyTeam.OpportunityId,new List<ShareObjectData>{objWrap});
                    }
                    
                }
                when AFTER_INSERT {}
                when BEFORE_UPDATE{
                    if(oldItems.get(optyTeam.Id).OpportunityAccessLevel != optyTeam.OpportunityAccessLevel){
                        
                        ShareObjectData objWrapUpdate = new ShareObjectData();
                        objWrapUpdate.userId = optyTeam.UserId;
                        objWrapUpdate.isEdit = True;
                        //To revoke access for Oppty Team if modified rom Edit to Read or if Opty Team is deleted
                        if(optyTeam.OpportunityAccessLevel == QTB_Constants.OPPTY_ACCESSLEVEL_READ || Trigger.isDelete){
                            objWrapUpdate.isEdit = False;
                        }
                        
                        if(oppIdToshareObjectDataListMapUpdate.containsKey(optyTeam.OpportunityId)){
                            oppIdToshareObjectDataListMapUpdate.get(optyTeam.OpportunityId).add(objWrapUpdate);
                        }
                        else{
                            oppIdToshareObjectDataListMapUpdate.put(optyTeam.OpportunityId,new List<ShareObjectData>{objWrapUpdate});
                        }
                        
                        
                    } 
                } 
                //when AFTER_UPDATE {}
                //when BEFORE_DELETE {}
                //when AFTER_DELETE {}
                // when AFTER_UNDELETE {}
                when else {}
            }
        }
        // post processing
        if(!oppIdToshareObjectDataListMapInsert.isEmpty()){ shareQuotewithUsers(oppIdToshareObjectDataListMapInsert);}
        if(!oppIdToshareObjectDataListMapUpdate.isEmpty()){ shareQuotewithUsers(oppIdToshareObjectDataListMapUpdate);}
    } 
    
    /***********************************************************************************************************
    * Method : shareQuotewithUsers
    * Parameters: List<OpportunityTeamMember> ,Map<ID,OpportunityTeamMember>
    * Return Type: void
    * Requirement : SFCPQBLG-50
    * Description: Triggered from before insert/update/delete of Opty Team Trigger to share quote with Oppty Team with Edit Access
    **************************************************************************************************************/
    public static void shareQuotewithUsers(Map<ID,List<ShareObjectData>> oppIdToshareObjectDataListMap){
        Map<ID,List<ShareObjectData>> quoteIdToshareObjectDataListMap = new Map<ID,List<ShareObjectData>>();
        //Loop to fetch quote Ids whose Opportunity Id is in Opportunity Team
        try{
            if(QTB_OpportunityTeamHandler.throwExplicitException){
                throw new NullPointerException();
            }
            for(SBQQ__Quote__c qte :[SELECT id,SBQQ__Opportunity2__c 
                                     FROM SBQQ__Quote__c 
                                     WHERE RecordTypeId =: QTB_Utils.QUOTE_SALES_RECTYPEID AND
                                     SBQQ__Opportunity2__c IN : oppIdToshareObjectDataListMap.keySet()
                                    ]){
                                        quoteIdToshareObjectDataListMap.put(qte.Id,oppIdToshareObjectDataListMap.get(qte.SBQQ__Opportunity2__c));
                                    }
            
            //Call generic method to insert/delete records in quote share object
            if(!quoteIdToshareObjectDataListMap.isEmpty()){
                updateQuoteAccess(quoteIdToshareObjectDataListMap);
            }
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),OPPORTUNITYTEAMHELPER);
            throw e;
        }
    }
    
    /***********************************************************************************************************
    * Method : updateQuoteAccess
    * Parameters: Map<ID,List<ShareObjectData>>
    * Return Type: void
    * Requirement : SFCPQBLG-50
    * Description: Generic function to insert/delete records in quote share object
    **************************************************************************************************************/
    public static void updateQuoteAccess(Map<ID,List<ShareObjectData>> quoteIdToshareObjectDataListMap){
        //Map of Quote Ids with user ids from quote share obj
        Map<String,Id> quoteIdUserIdToShareObjIdMap = new Map<String,Id>();
        //List to insert record in Quote Share Object
        List<SBQQ__Quote__Share> insertShareList = new List<SBQQ__Quote__Share>();
        //List to delete record in Quote Share Object
        List<SBQQ__Quote__Share> deleteShareList = new List<SBQQ__Quote__Share>();
        try{
            if(QTB_OpportunityTeamHandler.throwExplicitException){
                throw new NullPointerException();
            }
            //Query in quote share object to fetch existing quote access
            for(SBQQ__Quote__Share qteShareObj :[SELECT Id,parentId,UserOrGroupId,AccessLevel
                                                 FROM SBQQ__Quote__Share
                                                 WHERE parentId IN :quoteIdToshareObjectDataListMap.keySet() AND
                                                 AccessLevel =: QTB_Constants.QSHARE_ACCESSLEVEL]){
                                                     //Using concatenated values of Quote Id and User Id in key                               
                                                     quoteIdUserIdToShareObjIdMap.put((String)qteShareObj.parentId+qteShareObj.UserOrGroupId,qteShareObj.Id);
                                                 }
            
            //Loop on quote ID's that is keyset of quoteIdToshareObjectDataListMap
            for(ID quoteId: quoteIdToshareObjectDataListMap.keySet()){
                //Loop on list of Wrapper Object of quoteIdToshareObjectDataListMap
                for(ShareObjectData wrapData :quoteIdToshareObjectDataListMap.get(quoteId)){
                    if(wrapData.isEdit == True && 
                       !quoteIdUserIdToShareObjIdMap.containsKey((String)quoteId+wrapData.userId)){
                           insertShareList.add(new SBQQ__Quote__Share(ParentId = quoteId,
                                                                      UserorGroupId = wrapData.userId,
                                                                      AccessLevel = QTB_Constants.QSHARE_ACCESSLEVEL,
                                                                      RowCause = Schema.SBQQ__Quote__Share.RowCause.QTB_AccessToOpportunityTeam__c
                                                                     ));
                       }
                    else if(wrapData.isEdit == False && 
                            quoteIdUserIdToShareObjIdMap.containsKey((String)quoteId+wrapData.userId)){
                                deleteShareList.add(new SBQQ__Quote__Share
                                                    (Id = quoteIdUserIdToShareObjIdMap.get((String)quoteId+wrapData.userId)));
                            }
                }
            }
            //Insert Quote share record if insertShareList not empty
            if(!insertShareList.isEmpty() && Schema.sObjectType.SBQQ__Quote__Share.isCreateable()){
                Database.insert(insertShareList,false);
            }
            
            //Delete Quote share record if deleteShareList not empty
            if(!deleteShareList.isEmpty() && Schema.sObjectType.SBQQ__Quote__Share.isDeletable()){
                delete deleteShareList;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),OPPORTUNITYTEAMHELPER);
            throw e;
        }
    }
    
    /***********************************************************************************************************
    * Class : ShareObjectData
    * Author : Accenture
    * Description: Wrapper Class for user id and access level
    **************************************************************************************************************/
    public class ShareObjectData{
        public ID userId;
        public Boolean isEdit;
    }    
}
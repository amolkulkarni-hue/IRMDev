/********************************************************************************************************
@Description: This Invocable Apex class assigns a permission set to users who self-register from the NA/UKI sites.
Invoking from the flow 'Self Registration Single Account'
@Copyright: Iron Mountain
@Created on:  03/17/2025(MM/DD/YYYY)
@TestClass Name: AssignPermissionSetToUserActionTest
@GitLab : #29846
********************************************************************************************************/
public class AssignPermissionSetToUserAction {
    
    public class UserInput {
        @InvocableVariable(required=true)
        public id userId;
        
        @InvocableVariable(required=true)
        public id permissionSetId;
    }
    
    @InvocableMethod(label='Assign Permission Set to User' description='Assigns a Permission Set to a User from Flow')
    public static void assignPermissionSet(List<UserInput> inputList) {       
        Map<Id, Id> userAndPsMap = new Map<Id, Id>();
        for(UserInput input : inputList) {            
            userAndPsMap.put(input.userId, input.permissionSetId);
        }
        // Call the @future method
        assignPermissionset(userAndPsMap);
    }
    
    @future
    public static void assignPermissionSet(Map<Id, Id> userIdAndpsMap) {
        List<PermissionSetAssignment > createPermissionStAssinmnt = new List<PermissionSetAssignment>();
        try{
            for(Id userId : userIdAndpsMap.keySet()) {
                createPermissionStAssinmnt.add(new PermissionSetAssignment(
                    AssigneeId = userId,
                    PermissionSetId = userIdAndpsMap.get(userId)
                ));
            }        
            if(!createPermissionStAssinmnt.isEmpty()) {
                INSERT createPermissionStAssinmnt;
            }
            
        }catch(Exception e){ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'AssignPermissionSetToUserAction');}
        
    } 
}
public class ClosureActionController {
  
  public String id{get;set;}
  public Closure_Action__c closureActionObj {get;set;}
  public Closure_Action__c initialClosureActionObj {get;set;}
  public Case caseObj{get;set;}
  public String dateTimeString{get{return DateTime.Now().format();} set;}
  public String dateString{get{return Date.Today().format();} set;}
  public String selectedAPIName{get;set;}
  public String selectedDatatype{get;set;}
  public String selectedText{get;set;}
  public Boolean isTaskAction{get;set;}
  public Boolean isText{get;set;}
  public String keyPrefix{get;set;}
  public List<SelectOption> picklistFilters{get;set;}
  public String selectedPicklistValue{get;set;}
  public String selectedValueLookup{get;set;}
  public String selectedLookupId{get;set;}
  public String[] selectedMultiPickList{get;set;}
  public String dateTimeSelected{get;set;}
  public String dateSelected{get;set;}
  public String actionId{get;set;}
  public String tempStr{get; set;}
  
  public ClosureActionController(ApexPages.StandardController controller){
    closureActionObj = (Closure_Action__c)controller.getRecord();
    
    if(closureActionObj.id != null){      
      closureActionObj = [select Name, Action_Type__c, Case_Field_API_Name__c, Case_Field_Data_Type__c, Task_Action_Id__c, Task_ID__c, Value_To_Assign__c from Closure_Action__c where Id=: closureActionObj.Id limit 1];
    }
    initialClosureActionObj = closureActionObj.clone(false);
    caseObj = new Case();
    isTaskAction = true;
    isText = true;
    picklistFilters = new List<SelectOption>();
    changeActionType();
    changeValueComponent();
    }
  public List<SelectOption> getCaseFields(){
       return FilterUtil.getObjectFields('Case');
   }
   
   public List<SelectOption> getDataTypes(){
     return FilterUtil.getAllDataTyes();
   }
   
   public pageReference changeValueComponent(){
     Map<String, Schema.SObjectField> mapCaseFields = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
     if(mapCaseFields.get(closureActionObj.Case_Field_API_Name__c)!=null && mapCaseFields.get(closureActionObj.Case_Field_API_Name__c).getDescribe() != null){
       Schema.SObjectField tempSObjectField = mapCaseFields.get(closureActionObj.Case_Field_API_Name__c);
       Schema.DescribeFieldResult tempFieldResult = tempSObjectField.getDescribe();
       closureActionObj.Case_Field_Data_Type__c = tempFieldResult.getType().name();
       caseObj = new Case();
        system.debug('FieldTyeeeeeeeeee::'+tempFieldResult.getType()+'::');
       List<SobjectType> tempObjType = tempFieldResult.getReferenceTo();
       if(tempObjType.size() > 0){
         keyPrefix = tempObjType[0].getDescribe().getKeyPrefix();
         isText = false;
       }else if(tempFieldResult.getType() == Schema.DisplayType.STRING || tempFieldResult.getType().name() == 'NUMBER'
       || tempFieldResult.getType().name() == 'DOUBLE' || tempFieldResult.getType().name() == 'INTEGER' 
       || tempFieldResult.getType().name() == 'PERCENT' || tempFieldResult.getType().name() == 'CURRENCY'){
         isText = true; 
       }else if(tempFieldResult.getType() == Schema.DisplayType.PICKLIST || tempFieldResult.getType() == Schema.DisplayType.MULTIPICKLIST){
         picklistFilters = FilterUtil.loadPickListValues(tempSObjectField);
         isText = false;
       }else{
         isText = false;
       }
       // filling the page values with saved values
       if(isText)
          caseObj.Subject = closureActionObj.Value_To_Assign__c;
       /* #8991 Delete 10 case field deletion :- Part 3 "Account_in_Good_standing__c" */
         /*else if(closureActionObj.Case_Field_Data_Type__c != null && closureActionObj.Case_Field_Data_Type__c.equals('BOOLEAN') && closureActionObj.Value_To_Assign__c != null)
          caseObj.Account_in_Good_standing__c = Boolean.valueOf(closureActionObj.Value_To_Assign__c);*/
       else if(closureActionObj.Case_Field_Data_Type__c != null && closureActionObj.Case_Field_Data_Type__c.equals('PICKLIST') && closureActionObj.Value_To_Assign__c != null){
           selectedPicklistValue = closureActionObj.Value_To_Assign__c;
       }
       // clearing on on change if change of data type - 
       if(initialClosureActionObj.Case_Field_API_Name__c == null || initialClosureActionObj.Case_Field_API_Name__c != closureActionObj.Case_Field_API_Name__c){
          caseObj.Subject = '';
          /* #8991 Delete 10 case field deletion :- Part 3 "Account_in_Good_standing__c" */
           //caseObj.Account_in_Good_standing__c = false;
          selectedPicklistValue = '';
       }
       
     }
     return null;
   }
    
    public PageReference changeActionType(){
      if(closureActionObj.Action_Type__c != null && closureActionObj.Action_Type__c.equals('Task')){
         isTaskAction = true;
      }else if(closureActionObj.Action_Type__c != null && closureActionObj.Action_Type__c.equals('Case field Update')){
       isTaskAction = false;
      }
      return null;
   }
   
   public PageReference submit(){
      
      PageReference pageRef;
      boolean isError = false;
      // checking all mandatory fields are filled
      // Action Type Field
      if(closureActionObj.Action_Type__c == null){
        ApexPages.Message myMsg0 = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a Action Type');
       ApexPages.addMessage(myMsg0);
       isError = true;
      }
     
      if(closureActionObj.Task_ID__c == null){
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a Task Id');
        ApexPages.addMessage(myMsg);
        isError = true;
      }     
      else if(isTaskAction){
         if(closureActionObj.Task_Action_Id__c == null ||closureActionObj.Task_Action_Id__c == ''){
         ApexPages.Message myMsg1 = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a Task Action Id');
        ApexPages.addMessage(myMsg1);
        isError = true;
         } 
     }
     else if(!isTaskAction){
       if(closureActionObj.Case_Field_API_Name__c == null){
         ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a Case Field Name');
         ApexPages.addMessage(myMsg2);
         isError = true;
       }
       else if(!isTaskAction && (closureActionObj.Case_Field_Data_Type__c.equals('DOUBLE') || closureActionObj.Case_Field_Data_Type__c.equals('CURRENCY'))){
          Decimal val;
           try{
            val = Decimal.valueOf(caseObj.Subject);
           }
           catch(Exception e){
            ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a valid numerical value');
           ApexPages.addMessage(myMsg2);
           isError = true;
           } 
         }
        else if(!isTaskAction && closureActionObj.Case_Field_Data_Type__c.equals('INTEGER')){
           Integer intVal;
          try{
           intVal = Integer.valueOf(caseObj.Subject);
          }
          catch(Exception e){
           ApexPages.Message myMsg3 = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a valid numerical value');
          ApexPages.addMessage(myMsg3);
          isError = true;
          }
        }
     }
      
      // checking for error conditions on page before submit
      
           
      if(!isError) {
        if(!isTaskAction && closureActionObj.Case_Field_Data_Type__c != null){
           // clearing field for Action Type - Task
           closureActionObj.Task_Action_Id__c = null;
           if(isText){
            closureActionObj.Value_To_Assign__c = caseObj.Subject;
           }else if(closureActionObj.Case_Field_Data_Type__c.equals('REFERENCE') && selectedLookupId != null){
          closureActionObj.Value_To_Assign__c = selectedLookupId;
           }else if(closureActionObj.Case_Field_Data_Type__c.equals('PICKLIST') && selectedPicklistValue != null){
          closureActionObj.Value_To_Assign__c =  selectedPicklistValue;
           }else if(closureActionObj.Case_Field_Data_Type__c.equals('MULTIPICKLIST') && selectedMultiPicklist != null){
          closureActionObj.Value_To_Assign__c = loadMultiValues(selectedMultiPicklist);
           }else if(closureActionObj.Case_Field_Data_Type__c.equals('DATETIME')){
          closureActionObj.Value_To_Assign__c = System.now().format();
           }else if(closureActionObj.Case_Field_Data_Type__c.equals('DATE')){
          closureActionObj.Value_To_Assign__c = System.today().format();
           }else if(closureActionObj.Case_Field_Data_Type__c.equals('BOOLEAN')){
             	/* #8991 Delete 10 case field deletion :- Part 3 "Account_in_Good_standing__c" */
               // removed this condition from above else if condition && caseObj.Account_in_Good_standing__c != null
               /*if(caseObj.Account_in_Good_standing__c){
                closureActionObj.Value_To_Assign__c = 'true';
             }else{*/
                closureActionObj.Value_To_Assign__c = 'false';
            /*}*/
           }
           if(closureActionObj.Value_To_Assign__c == null || closureActionObj.Value_To_Assign__c == ''){
             ApexPages.Message myMsg4 = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a valid value');
            ApexPages.addMessage(myMsg4);
            return null;
           }
        }
        else if(isTaskAction){
            // clearing fields for Action Type - Case Field Type
            closureActionObj.Value_To_Assign__c = null;
            closureActionObj.Case_Field_Data_Type__c = null;
            closureActionObj.Case_Field_API_Name__c = null;
        }
        upsert closureActionObj;
                              System.debug('queries used: ' + Limits.getQueries());
        
        pageRef = new PageReference('/'+closureActionObj.Id);
        System.Debug('---------closureAction--------'+closureActionObj.Value_To_Assign__c);
      }
      return pageRef;
  }
  
  /*
  public PageReference cancel(){
    return new PageReference('/a0z/o');
  }
  */
   
  public String loadMultiValues(String[] selectedMultiPicklistValue){
      String tempValue = '';
      for(String str : selectedMultiPicklistValue){
       tempValue +=str+';';
     }
     return tempValue;
   }
}
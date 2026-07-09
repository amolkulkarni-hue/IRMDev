/*****************************************************************************************************
* Class: QTB_MultiSelectFlowValuesProducts
* Author: Virtusa
* Purpose: This is a class containing logic for Creating comma seperated selected product codes from 
          additional order creation product selection flow screen.
* Requirement:  # 8875
* Change History:
* Developer        Date 04/05/2022          Description
*
*******************************************************************************************************/
Global class QTB_MultiSelectFlowValuesProducts {
    public static final string className = QTB_CreateOrderItem.class.getName();
    public static boolean throwExplicitException = false;
    
    @InvocableMethod
    public static List<list<string>> CheckProductValues(List<string> values) {
        String errorIds = '';
       try {
        if (throwExplicitException) {
                system.debug('NullPointer');
                throw new NullPointerException();
            } 
          if(!(values.isEmpty())){
            list<list<string>> finalLst = new list<list<string>>();    
            for (String tStr : values) 
                if (tStr != null) 
            {
                List<String> lstnew = tStr.split(';');
                finalLst.add(lstnew);
                system.debug('lstnew' +lstnew);
                
            }
               return finalLst;   
         }
             return null;   
         
       }
        catch (exception e) {
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            system.debug('In catch method of batch Finish>>>>>>>>>>');
            system.debug('Error inf::' + errorIds);
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                errorIds,
                e.getTypeName(),
                className
            );
         
        }  
      return null;  
    }
}
/*************************************************************************************************
* Class: QTB_OrderHelperUtils
* Author: Virtusa
* Purpose: This is a helper Util class for all business logic related to Order object
* Change History: 08/27/2024
* Developer     Date           Description
* 
*******************************************************************************************************/
public class QTB_OrderHelperUtils {
    public static final String CLASSNAME = QTB_OrderHelperUtils.class.getName();
    
    /***********************************************************************************************************   
* Method 	 : updateOpPayTermBasedOnOrdPayTerms
* Parameters : List<Order> ordList
* Return Type: List <orderItem>
* Description: Gitlab US #24886 - This method is responsible to return the orderItem List what needs to be stamped based upon Account related data based upon Order Payment terms Value(As per new Code Approach)
**************************************************************************************************************/
    public static List<OrderItem> updateOpPayTermBasedOnOrdPayTerms(Set<Id> orderids){
        try{
            if (QTB_OrderTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            List<Orderitem> orderItemListUpdate = new List<OrderItem>();
            for(OrderItem oi : [select id,QTB_Payment_Term__c,order.SBQQ__PaymentTerm__c from orderItem where orderId IN : orderids]){
                string s = oi.order.SBQQ__PaymentTerm__c;
                oi.QTB_Payment_Term__c = s.substring(s.indexOf(' ') + 1);
                orderItemListUpdate.add(oi);
            }
            QTB_RecursiveHandlerCheck.updateOpPayTermBasedOnOrdPayTerms = False;
            return orderItemListUpdate;   
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    /*********************************************************************************************************
* Method Name: sitadOrderActivation
* Parameters: Set<Id> ordIdSet
* Return Type: List<Order>
* Requirement: GitLab #24893
* Description: This method will return the SITAD orders to update the Status to Activated.
**********************************************************************************************************/ 
    public static List<Order> sitadOrderActivation(Set<Id> ordIdSet){
        try {
            if (QTB_OrderTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            List<Order> OrdList = new List<Order>();
            for(Id ordId:ordIdSet){
                Order ordUpdate = new Order();
                ordUpdate.Id= ordId;
                ordUpdate.Status = 'Activated';
                OrdList.add(ordUpdate);  
                
            }
            return OrdList;
        }
        catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                CLASSNAME
            );
            throw e;
        }
    }
}
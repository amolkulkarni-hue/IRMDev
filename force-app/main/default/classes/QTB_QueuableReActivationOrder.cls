public class QTB_QueuableReActivationOrder implements Queueable {
    
    public set<ID> reactivateOrdersIds;
    public static  boolean throwExplicitException = false;
    public QTB_QueuableReActivationOrder(set<ID> activateOrderIds)
    {
        reactivateOrdersIds = activateOrderIds;
    }
       /***********************************************************************************************************
* Method : execute
* Parameters: QueueableContext
* Return Type: void
* Description: Queueable method to  handle activate and deactivate order
**************************************************************************************************************/
    public void execute(QueueableContext qc) 
    {
        
        
        try{
            helperReactivatingOrder(reactivateOrdersIds);
            
        }
        catch (Exception e) {
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                'QTB_QueuableReActivationOrder'
            );
            throw e;
        }
        
        
    }
         /***********************************************************************************************************
* Method : reactivatingOrder
* Parameters: set<ID>
* Return Type: void
* Description: future method to  handle activate and deactivate order
**************************************************************************************************************/
    @future
    Public Static void reactivatingOrder(set<ID> activateOrderIds){
        
        helperReactivatingOrder(activateOrderIds);
        
    }
             /***********************************************************************************************************
* Method : helperReactivatingOrder
* Parameters: set<ID>
* Return Type: void
* Description: helper method to  handle activate and deactivate order
**************************************************************************************************************/
    Public static void helperReactivatingOrder(set<ID> activateOrderIds)
    {
        list<Order> deactivateOrders = new list<Order>();
        
        for (ID decOrder : activateOrderIds)
        {
            Order ord = new Order();
            ord.Id= decOrder;
            ord.Status = 'Draft';
            deactivateOrders.add(ord);
        }
        
        update deactivateOrders;
        
        for (order recOrder : deactivateOrders)
        {
            
            recOrder.Status = 'Activated';
        }
        
        update deactivateOrders;   
    }
    
}
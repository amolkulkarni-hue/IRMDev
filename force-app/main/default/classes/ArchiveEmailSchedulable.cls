/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group Schedulable
 * @description When this class is scheduled and runs, the 'execute' method is called. The execute method runs a 
 * batch which is handled by the ArchiveEmailBatchable class. The getter/setter for apexJobProxy
 * allows us to mock how the batch is 'called' in tests. Rather than executing the batch, and 
 * asserting on the effects of calling the batch (which would redundantly test service class logic),
 * we are able to collect information about the batchable instance itself. 
 */

public class ArchiveEmailSchedulable implements Schedulable {
    @testVisible IApexJobProxy apexJobProxy {
        get {
            if (apexJobProxy == null) {
                apexJobProxy = new ApexJobProxyDefault();
            }
            return apexJobProxy;
        }
        set;
    }

    public void execute(SchedulableContext sc) {
        Integer scopeSize = Integer.valueOf(Label.Archived_Email_Batch_Scope_Size);
        apexJobProxy.executeBatch(new ArchiveEmailBatchable(new ArchiveEmailService()), scopeSize);
    }
}
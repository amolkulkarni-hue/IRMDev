/**
 * IRM_FlowFaultNotifier
 * Invocable used by all IRM record-triggered flows in their faultConnector paths.
 * Sends an email alert to the IRM admin address and creates a high-priority Task on the
 * owning record so failures are visible to the record owner without surfacing raw Salesforce
 * error messages to end users.
 *
 * Flows call this from a fault Assignment → this invocable pattern. If either the email or
 * the Task insert fails, the failure is logged but does not propagate — fault paths should
 * always silently absorb secondary errors.
 */
public with sharing class IRM_FlowFaultNotifier {

    private static final String NOTIFY_EMAIL = 'amol.kulkarni.contr@ironmountain.com';

    @InvocableMethod(
        label       = 'Notify Flow Fault'
        description = 'Sends email alert + creates Task on record owner when an IRM flow faults. Safe to call from After-Save flow fault paths.'
    )
    public static void notifyFault(List<Request> requests) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Task>                         tasks  = new List<Task>();

        for (Request r : requests) {
            String subject = '[IRM Flow Error] ' + r.flowName;
            String body    = 'Flow: '   + r.flowName    + '\n'
                           + 'Record: ' + r.recordId    + '\n'
                           + 'Error: '  + r.faultMessage;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ NOTIFY_EMAIL });
            email.setSubject(subject);
            email.setPlainTextBody(body);
            emails.add(email);

            if (r.recordId != null && r.ownerId != null) {
                tasks.add(new Task(
                    Subject      = subject.abbreviate(255),
                    WhatId       = r.recordId,
                    OwnerId      = r.ownerId,
                    Status       = 'Open',
                    Priority     = 'High',
                    ActivityDate = Date.today(),
                    Description  = body.abbreviate(32000)
                ));
            }
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails, false);
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN,
                    'IRM_FlowFaultNotifier: email send failed — ' + ex.getMessage());
            }
        }
        if (!tasks.isEmpty()) {
            Database.insert(tasks, false);
        }
    }

    public class Request {
        @InvocableVariable(label = 'Flow Name'     required = true)
        public String flowName;
        @InvocableVariable(label = 'Fault Message' required = true)
        public String faultMessage;
        @InvocableVariable(label = 'Record ID')
        public String recordId;
        @InvocableVariable(label = 'Owner ID')
        public String ownerId;
    }
}

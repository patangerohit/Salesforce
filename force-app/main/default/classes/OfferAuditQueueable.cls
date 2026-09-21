// Inserts audit records into Error_Log__c.
public class OfferAuditQueueable implements Queueable {
    
    private List<Application__c> appsToAudit;
    
    public OfferAuditQueueable(List<Application__c> apps) {
        this.appsToAudit = apps;
    }
    
    public void execute(QueueableContext ctx) {
        List<Error_Log__c> auditLogs = new List<Error_Log__c>();
        
        for (Application__c app : appsToAudit) {
            auditLogs.add(new Error_Log__c(
                Flow_Name__c = 'Offer Async Pipeline',
                Record_Id__c = app.Id,
                Message__c = 'Offer processed successfully. Stage is now: ' + app.Stage__c
            ));
        }
        
        // Bulk insert the audit logs
        if (!auditLogs.isEmpty()) {
            insert auditLogs;
        }
    }
}
// Processes tangible follow-up actions.
public class OfferFollowUpQueueable implements Queueable {
    
    private List<Application__c> appsToProcess;
    
    public OfferFollowUpQueueable(List<Application__c> apps) {
        this.appsToProcess = apps;
    }
    
    public void execute(QueueableContext ctx) {
        List<Task> followUpTasks = new List<Task>();
        
        // Create physical follow-up tasks for the offer records
        for (Application__c app : appsToProcess) {
            followUpTasks.add(new Task(
                WhatId = app.Id,
                Subject = 'Draft Official Offer Letter',
                Priority = 'High',
                Status = 'Not Started',
                ActivityDate = System.today().addDays(2)
            ));
        }
        
        if (!followUpTasks.isEmpty()) {
            insert followUpTasks;
        }
        
        // Chain the next job
        if (!Test.isRunningTest()) {
            System.enqueueJob(new OfferAuditQueueable(appsToProcess));
        }
    }
}
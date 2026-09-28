// Anonymizes personal data on Applicants whose associated Applications are old
public class ApplicantPurgeBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    // Stateful variable to keep track of total records processed across all chunks
    private Integer totalAnonymized = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Defined the retention cutoff
        Date cutoff = Date.today().addDays(-365);
        
        return Database.getQueryLocator([
            SELECT Id, Name, Email__c, Phone__c 
            FROM Applicant__c 
            WHERE CreatedDate < :cutoff
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Applicant__c> scope) {
        for (Applicant__c candidate : scope) {
            candidate.Name = 'Redacted Candidate';
            candidate.Email__c = 'redacted-' + candidate.Id + '@anon.invalid';
            candidate.Phone__c = null;
        }
        
        update scope;
        
        // Accumulate the tally
        totalAnonymized += scope.size();
    }

    public void finish(Database.BatchableContext bc) {
        // Querying the AsyncApexJob table to get system-level stats about the run
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems 
            FROM AsyncApexJob 
            WHERE Id = :bc.getJobId()
        ];
        
        // Writing a physical audit record proving compliance execution
        insert new Error_Log__c(
            Flow_Name__c = 'Candidate Data Retention Purge',
            Record_Id__c = job.Id,
            Message__c = 'COMPLETED: ' + job.Status + '. ' + 
                               'Processed ' + job.TotalJobItems + ' chunks. ' +
                               'Successfully anonymized ' + totalAnonymized + ' candidates.'
        );
    }
}
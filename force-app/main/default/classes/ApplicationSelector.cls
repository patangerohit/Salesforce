// Selector class for retrieving Application__c and related records.
public with sharing class ApplicationSelector {
    
    //Retrieves Applications with parent Candidate and Job data.
   
    public static List<Application__c> getApplicationsWithCandidateInfo(Set<Id> appIds) {
        if (appIds == null || appIds.isEmpty()) return new List<Application__c>();
        
        return [
            SELECT Id, Stage__c, 
                   Applicant__r.Email__c, Applicant__r.Name, 
                   Job_Posting__r.Status__c
            FROM Application__c 
            WHERE Id IN :appIds
    
        ];
    }
    
    // Retrieves Job Postings and all their related Applications.

    public static List<Job_Posting__c> getJobPostingsWithApplications(Set<Id> jobIds) {
        if (jobIds == null || jobIds.isEmpty()) return new List<Job_Posting__c>();
        
        return [
            SELECT Id, Name, Status__c,
                   (SELECT Id, Stage__c, Applicant__r.Name FROM Applications__r)
            FROM Job_Posting__c 
            WHERE Id IN :jobIds
        ];
    }

    // Retrieves Applications sitting in early stages past a certain number of days.
 
    public static List<Application__c> getStaleApplications(Integer dayThreshold) {
        // Calculate the date threshold in memory to allow the database to use indexes on CreatedDate
        DateTime cutoffDate = System.now().addDays(-dayThreshold);
        
        return [
            SELECT Id, Name, Stage__c, Is_Stale__c, CreatedDate
            FROM Application__c 
            WHERE Stage__c IN ('Applied', 'Screening') 
            AND CreatedDate < :cutoffDate
        ];
    }
    
    // Computes total Applications sitting in each stage using the database engine
    public static Map<String, Integer> getPipelineCountsByStage() {
    Map<String, Integer> counts = new Map<String, Integer>();
    for (AggregateResult ar : [
        SELECT Stage__c stage, COUNT(Id) total
        FROM Application__c
        GROUP BY Stage__c
    ]) {
        counts.put((String) ar.get('stage'), (Integer) ar.get('total'));
    }
    return counts;
}
    
    // Dynamically searches Applications applying filters only if provided
    public static List<Application__c> searchApplications(String stageFilter, String sourceFilter) {
    String q = 'SELECT Id, Stage__c, Applicant__r.Source__c FROM Application__c WHERE Id != null';
    if (String.isNotBlank(stageFilter)) {
        q += ' AND Stage__c = :stageFilter';        // bind, not concatenate
    }
    if (String.isNotBlank(sourceFilter)) {
        q += ' AND Applicant__r.Source__c = :sourceFilter';
    }
    q += ' LIMIT 200';
    return Database.query(q);
}
    // Calculates and assigns Priority for a list of Applications
    public static void assignPriorityByStage(List<Application__c> apps) {
        
        // Gather all parent Job Posting Ids into a Set
        Set<Id> jobIds = new Set<Id>();
        for (Application__c app : apps) {
            if (app.Job_Posting__c != null) {
                jobIds.add(app.Job_Posting__c);
            }
        }
        
        // Execute exactly ONE query and store it in a Map keyed by Id
        Map<Id, Job_Posting__c> jobMap = new Map<Id, Job_Posting__c>();
        if (!jobIds.isEmpty()) {
            jobMap = new Map<Id, Job_Posting__c>([
                SELECT Id, Status__c 
                FROM Job_Posting__c 
                WHERE Id IN :jobIds
            ]);
        }
        
        // Loop through the Applications 
        for (Application__c app : apps) {
            String calculatedPriority = 'Low'; // Default value
            
            // Fetch the parent Job Posting from our Map
            Job_Posting__c parentJob = jobMap.get(app.Job_Posting__c);
            
            // 1. High: If it's in the Interview stage OR the Job Posting is 'Urgent'
            if (app.Stage__c == 'Interview') {
                calculatedPriority = 'High';
            } 
            // 2. Medium: If the application
            else if (app.Is_Stale__c == true) {
                calculatedPriority = 'Medium';
            }
            
            // Assign the value
            app.Priority__c = calculatedPriority;
        }
    }
    
    // Retrieves all Applications currently in a specific stage.
    public static List<Application__c> getApplicationsByStage(String stage) {
        return [
            SELECT Id, Name, Stage__c, Offer_Approval_Status__c 
            FROM Application__c 
            WHERE Stage__c = :stage
        ];
    }
}
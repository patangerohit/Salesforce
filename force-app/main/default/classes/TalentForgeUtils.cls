// Utility class for TalentForge Application operations. 
public with sharing class TalentForgeUtils {
    
    // Returns the numeric order of a pipeline stage.
  
    public static Integer stageOrder(String stage) {
        if (String.isBlank(stage)) {
            return -1;
        }
        
        switch on stage {
            when 'Rejected'  { return 0; }
            when 'Applied'   { return 1; }
            when 'Screening' { return 2; }
            when 'Interview' { return 3; }
            when 'Offer'     { return 4; }
            when 'Hired'     { return 5; }
            when else        { return -1; }
        }
    }
    
    // Determines if a stage transition is valid (one step forward or to Rejected).
   
    public static Boolean isValidTransition(String fromStage, String toStage) {
        // Universal bypass: Any active stage can be rejected
        if (toStage == 'Rejected') {
            return true;
        }
        
        Integer fromOrder = stageOrder(fromStage);
        Integer toOrder = stageOrder(toStage);
        
        // Prevent transition if either stage is unrecognized or blank
        if (fromOrder == -1 || toOrder == -1) {
            return false;
        }
        
        // A valid forward transition must be exactly one step
        return toOrder == (fromOrder + 1);
    }
    
    // Retrieves all Applications currently in a specific stage.
    public static List<Application__c> getApplicationsByStage(String stage) {
        return [
            SELECT Id, Name, Stage__c, Offer_Approval_Status__c 
            FROM Application__c 
            WHERE Stage__c = :stage
        ];
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
}
public with sharing class ApplicationAsyncService {
    
    // Processes follow-up actions for Applications moved to the Offer stage
    @future
    public static void processOfferFollowUp(Set<Id> appIds) {
        if (appIds == null || appIds.isEmpty()) return;
        
        List<Application__c> apps = [
            SELECT Id, Stage__c, Applicant__r.Email__c, Job_Posting__r.Name
            FROM Application__c 
            WHERE Id IN :appIds
            WITH USER_MODE
        ];
    }
}
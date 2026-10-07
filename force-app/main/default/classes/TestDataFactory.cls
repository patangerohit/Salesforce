@isTest
public class TestDataFactory {
    public static Job_Posting__c createJobPosting(Boolean doInsert) {
        Job_Posting__c jp = new Job_Posting__c(
            Name = 'Test Required',
            Status__c = 'Open'
        );
        if (doInsert) insert jp;
        return jp;
    }

    public static Applicant__c createApplicant(Boolean doInsert) {
        Applicant__c a = new Applicant__c(
            Name = 'Test Applicant',
            Email__c = 'test@example.com'
        );
        if (doInsert) insert a;
        return a;
    }

    public static List<Application__c> createApplications(
            Integer count, Id applicantId, Id jobId, Boolean doInsert) {
        List<Application__c> apps = new List<Application__c>();
        for (Integer i = 0; i < count; i++) {
            apps.add(new Application__c(
                Applicant__c = applicantId,
                Job_Posting__c = jobId,
                Stage__c = 'Applied'
            ));
        }
        if (doInsert) insert apps;
        return apps;
    }
}
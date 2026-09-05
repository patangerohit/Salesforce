public with sharing class SearchService {
    
// Global search functionality to search across the objects
public static Map<String, List<SObject>> globalSearch(String term) {
    Map<String, List<SObject>> out = new Map<String, List<SObject>>();
    if (String.isBlank(term)) return out;

    List<List<SObject>> results = [
        FIND :term IN ALL FIELDS
        RETURNING Applicant__c(Id, Name, Email__c ORDER BY Name),
                 Job_Posting__c(Id, Name, Status__c),
                 Application__c(Id, Stage__c, Applicant__r.Name)
    ];
    out.put('Applicants', results[0]);
    out.put('JobPostings', results[1]);
    out.put('Applications', results[2]);
    return out;
}
    
}
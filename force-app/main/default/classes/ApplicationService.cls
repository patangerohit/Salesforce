public with sharing class ApplicationService {

    public class TransitionResult {
    public Integer successCount;
    public List<String> errors = new List<String>();
}

public static TransitionResult bulkTransitionStage(List<Application__c> apps, String newStage) {
    TransitionResult res = new TransitionResult();
    List<Application__c> toUpdate = new List<Application__c>();

    // validate each transition IN MEMORY first
    for (Application__c a : apps) {
        if (TalentForgeUtils.isValidTransition(a.Stage__c, newStage)) {
            a.Stage__c = newStage;
            toUpdate.add(a);
        } else {
            res.errors.add(a.Id + ': illegal transition ' + a.Stage__c + '→' + newStage);
        }
    }

    // partial-success DML
    Database.SaveResult[] srs = Database.update(toUpdate, false);
    Integer ok = 0;
    for (Integer i = 0; i < srs.size(); i++) {
        if (srs[i].isSuccess()) { ok++; }
        else {
            for (Database.Error e : srs[i].getErrors()) {
                res.errors.add(toUpdate[i].Id + ': ' + e.getMessage());
            }
        }
    }
    res.successCount = ok;
    return res;
}
    // Processes transitions atomically. If ANY record fails validation or DML, the entire batch is rolled back to its original state.
    
    public static TransitionResult atomicTransition(List<Application__c> apps, String newStage) {
        Savepoint sp = Database.setSavepoint();
        
        // Reused the partial logic to do the heavy lifting
        TransitionResult res = bulkTransitionStage(apps, newStage);
        
        // If there is even one error, abort the entire database transaction
        if (!res.errors.isEmpty()) {
            Database.rollback(sp);
            res.successCount = 0;
            res.errors.add(0, 'ATOMIC ABORT: Entire transaction rolled back due to failures.');
        }
        
        return res;
    }
    
    // Handles logic when an Application transitions into the Offer stage
    public static void handleMovedToOffer(List<Application__c> applications) {
        List<Task> followUpTasks = new List<Task>();
        
        for (Application__c app : applications) {
            followUpTasks.add(new Task(
                WhatId = app.Id,
                Subject = 'Send Offer Letter to Candidate',
                Priority = 'High',
                Status = 'Not Started'
            ));
        }
        
        if (!followUpTasks.isEmpty()) {
            // Bulk insert all tasks in a single DML statement
            insert followUpTasks;
        }
    }
}
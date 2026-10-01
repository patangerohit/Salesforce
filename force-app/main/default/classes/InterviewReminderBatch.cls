// Batch job to generate reminder Tasks for interviews happening tomorrow.
public class InterviewReminderBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date tomorrow = Date.today().addDays(1);
        
        return Database.getQueryLocator([
            SELECT Id, Name, Applicant__r.Email__c 
            FROM Application__c 
            WHERE Interview_Date__c = :tomorrow
        ]);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<Task> reminders = new List<Task>();
        
        List<Application__c> apps = (List<Application__c>) scope;
        
        for (Application__c app : apps) {
            reminders.add(new Task(
                Subject = 'Upcoming Interview Reminder',
                WhatId = app.Id, 
                ActivityDate = Date.today(),
                Priority = 'High',
                Status = 'Not Started'
            ));
        }
        
        if (!reminders.isEmpty()) {
            insert reminders;
        }
    }

    public void finish(Database.BatchableContext bc) {
        
    }
}
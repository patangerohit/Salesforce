public with sharing class ApplicationTriggerHandler {
       private static Boolean hasAfterRun = false;

       public static void beforeInsert(List<Application__c> newApps) {
           ApplicationSelector.assignPriorityByStage(newApps); // same-record, in memory
       }

       public static void beforeUpdate(List<Application__c> newApps, Map<Id, Application__c> oldMap) {
           ApplicationSelector.assignPriorityByStage(newApps);
       }

       public static void afterUpdate(List<Application__c> newApps, Map<Id, Application__c> oldMap) {
           if (hasAfterRun) return;
           hasAfterRun = true;

           // detect transitions using oldMap, the "changed into" pattern
           List<Application__c> movedToOffer = new List<Application__c>();
           List<Application__c> movedToRejected = new List<Application__c>();
           for (Application__c a : newApps) {
               Application__c oldA = oldMap.get(a.Id);
               if (a.Stage__c == 'Offer' && oldA.Stage__c != 'Offer') movedToOffer.add(a);
               if (a.Stage__c == 'Rejected' && oldA.Stage__c != 'Rejected') movedToRejected.add(a);
           }
           // explicit order: handles each, delegating to bulk-safe service methods
           if (!movedToOffer.isEmpty())    ApplicationService.handleMovedToOffer(movedToOffer);
           if (!movedToRejected.isEmpty()) ApplicationService.handleMovedToRejected(movedToRejected);
       }
   }
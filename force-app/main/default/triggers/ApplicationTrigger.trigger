trigger ApplicationTrigger on Application__c (before insert, before update, after insert, after update) {
    
    if (Trigger.isBefore) {
        // Same-record field updates
        ApplicationSelector.assignPriorityByStage(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Application__c> movedToOffer = new List<Application__c>();
        
        for (Application__c newApp : Trigger.new) {
            Application__c oldApp = Trigger.oldMap.get(newApp.Id);
            
            // Detect if the stage specifically changed to Offer during this transaction
            if (newApp.Stage__c == 'Offer' && oldApp.Stage__c != 'Offer') {
                movedToOffer.add(newApp);
            }
        }
        
        // Delegate to the service layer if any records meet the criteria
        if (!movedToOffer.isEmpty()) {
            System.enqueueJob(new OfferFollowUpQueueable(movedToOffer));
        }
    }
}
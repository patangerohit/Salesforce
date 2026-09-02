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
}
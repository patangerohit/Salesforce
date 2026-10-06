public class InterviewReminderScheduler implements Schedulable {
       public void execute(SchedulableContext sc) {
           Database.executeBatch(new InterviewReminderBatch(), 200);
       }
   }
public with sharing class WarehouseSyncSchedule implements Schedulable{
    /* 
    This is the code I've run inside Developer Console
    //Job Name: WarehouseSyncScheduleJob
    public static final String CRON_EXPR = '0 0 1 * * ?';
    WarehouseSyncSchedule wss = new WarehouseSyncSchedule();
    System.schedule('WarehouseSyncScheduleJob', CRON_EXPR, wss);
    */
    public void execute(SchedulableContext ctx) {
        System.enqueueJob(new WarehouseCalloutService());
    }
}
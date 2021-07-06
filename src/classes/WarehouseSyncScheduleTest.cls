@IsTest
public with sharing class WarehouseSyncScheduleTest {
    public static final String CRON_EXPR = '0 0 1 * * ?';

    @IsTest
    static void testWarehouseSyncSchedule(){
        List<Product2> equipments;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        String jobId = System.schedule('SetupScheduledJob', CRON_EXPR, new WarehouseSyncSchedule());
        Test.stopTest();

        CronTrigger ct = [SELECT State FROM CronTrigger WHERE ID = :jobId];
        System.assertEquals('WAITING', String.valueOf(ct.State));
    }
}
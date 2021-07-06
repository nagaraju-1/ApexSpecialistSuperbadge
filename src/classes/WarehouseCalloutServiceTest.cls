@IsTest
private class WarehouseCalloutServiceTest {
    @IsTest
    static void testWebServiceRespond(){
        Test.startTest();
        System.Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();
        
        List<Product2> equipments = [SELECT ProductCode FROM Product2];
        System.assertEquals(2, equipments.size());
    }
}
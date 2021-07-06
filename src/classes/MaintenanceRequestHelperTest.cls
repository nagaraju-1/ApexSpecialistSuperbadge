@IsTest
public with sharing class MaintenanceRequestHelperTest {
    @TestSetup
    static void makeData(){
        Product2 setupEquipment1 = new Product2(
            Name = 'Setup Equipment 1', Maintenance_Cycle__c = 3, Replacement_Part__c = true);
        Product2 setupEquipment2 = new Product2(
            Name = 'Setup Equipment 2', Maintenance_Cycle__c = 1, Replacement_Part__c = true);
        Vehicle__c setupVehicle = new Vehicle__c(Name = 'Setup Vehicle');

        insert setupEquipment1;
        insert setupEquipment2;
        insert setupVehicle;

        //below assert depends on this value
        Integer totalBulkOperation = 100;
        List<Case> setupRequestList = new List<Case>();
        Case setupRequest;

        for (Integer i = 0; i < totalBulkOperation; i++) {
            setupRequest = new Case(
                Subject = 'Setup Maintenance Request ' + i, Type = 'Repair', 
                Status = 'New', Vehicle__c = setupVehicle.Id);
            setupRequestList.add(setupRequest);
        }

        insert setupRequestList;

        List<Equipment_Maintenance_Item__c> setupItemList = new List<Equipment_Maintenance_Item__c>();
        Equipment_Maintenance_Item__c setupItem1;
        Equipment_Maintenance_Item__c setupItem2;
        Equipment_Maintenance_Item__c setupItem3;

        for (Case request : setupRequestList) {
            setupItem1 = new Equipment_Maintenance_Item__c(
                Maintenance_Request__c = request.Id, Equipment__c = setupEquipment1.Id);
            setupItem2 = new Equipment_Maintenance_Item__c(
                Maintenance_Request__c = request.Id, Equipment__c = setupEquipment1.Id);
            setupItem3 = new Equipment_Maintenance_Item__c(
                Maintenance_Request__c = request.Id, Equipment__c = setupEquipment2.Id);
            setupItemList.add(setupItem1);
            setupItemList.add(setupItem2);
            setupItemList.add(setupItem3);
        }

        insert setupItemList;
    }

    @IsTest
    static void createRequestAfterStatusClosedTest(){
        Case setupRequest = [
            SELECT Subject, Type, Status, Vehicle__c FROM Case 
            WHERE Subject = 'Setup Maintenance Request 0'];
        
        Test.startTest();
        setupRequest.Status = 'Closed';
        Database.SaveResult saveResult = Database.update(setupRequest, false);
        Test.stopTest();

        Case testRequest = [
            SELECT Subject, Status, Type, Vehicle__c, Date_Reported__c, Date_Due__c FROM Case 
            WHERE Subject = '[RMT] Setup Maintenance Request 0'];

        System.assertEquals('Routine Maintenance', testRequest.Type);
        System.assertEquals('New', testRequest.Status);
        System.assertEquals(Date.today(), testRequest.Date_Reported__c);
        System.assertEquals(Date.today().addDays(1), testRequest.Date_Due__c);
    }

    @IsTest
    static void changeItemReferenceRequestTest(){
        Case setupRequest = [
            SELECT Subject, Status FROM Case 
            WHERE Subject = 'Setup Maintenance Request 0'];
        
        Test.startTest();
        setupRequest.Status = 'Closed';
        Database.SaveResult saveResult = Database.update(setupRequest, false);
        Test.stopTest();

        Case testRequest = [
            SELECT Subject FROM Case 
            WHERE Subject = '[RMT] Setup Maintenance Request 0'];
        List<Equipment_Maintenance_Item__c> setupList = [
            SELECT Name FROM Equipment_Maintenance_Item__c 
            WHERE Maintenance_Request__c = :testRequest.Id];
        
        System.assertEquals(3, setupList.size());
    }

    @IsTest
    static void createRequestAfterStatusClosedBulkTest(){
        List<Case> setupRequestList = [
            SELECT Subject, Type, Status, Vehicle__c FROM Case];

        Test.startTest();
        for (Case setupRequest : setupRequestList) {
            setupRequest.Status = 'Closed';
        }
        Database.SaveResult[] saveResult = Database.update(setupRequestList, false);
        Test.stopTest();

        List<Case> testRequests = [
            SELECT Subject, Status, Type, Vehicle__c, Date_Reported__c, Date_Due__c FROM Case 
            WHERE Status <> 'Closed'];
        
        System.assertEquals(100, testRequests.size());
        for (Case testRequest : testRequests) {
            System.assertNotEquals(null, testRequest.Subject);
            System.assertEquals('Routine Maintenance', testRequest.Type);
            System.assertEquals('New', testRequest.Status);
            System.assertEquals(Date.today(), testRequest.Date_Reported__c);
            System.assertEquals(Date.today().addDays(1), testRequest.Date_Due__c);
        }
    }

    @IsTest
    static void changeItemReferenceRequestBulkTest(){
        List<Case> setupRequestList = [
            SELECT Subject, Type, Status, Vehicle__c FROM Case];

        Test.startTest();
        for (Case setupRequest : setupRequestList) {
            setupRequest.Status = 'Closed';
        }
        Database.SaveResult[] saveResult = Database.update(setupRequestList, false);
        Test.stopTest();

        List<Case> testRequests = [
            SELECT Subject, Status, Type, Vehicle__c, Date_Reported__c, Date_Due__c FROM Case 
            WHERE Status <> 'Closed'];

        List<Id> idList = new List<Id>();
        for (Case testRequest : testRequests) {
            idList.add(testRequest.Id);
        }

        List<Equipment_Maintenance_Item__c> setupItems = [
            SELECT Name FROM Equipment_Maintenance_Item__c 
            WHERE Maintenance_Request__c = :idList];
        
        System.assertEquals(300, setupItems.size());
    }
}
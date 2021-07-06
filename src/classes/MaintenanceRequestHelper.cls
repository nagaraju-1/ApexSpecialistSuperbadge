public with sharing class MaintenanceRequestHelper {
    public static void updateWorkOrders(List<Case> requestList) {
        Map<Id, Case> requestFilteredMap = new Map<Id, Case>();
        Map<Id, List<Equipment_Maintenance_Item__c>> itemPerRequestMap = new Map<Id, List<Equipment_Maintenance_Item__c>>();
        Map<String, List<Equipment_Maintenance_Item__c>> itemMapToInsert = new Map<String, List<Equipment_Maintenance_Item__c>>();
        List<Equipment_Maintenance_Item__c> itemListToBuild = new List<Equipment_Maintenance_Item__c>();
        List<Equipment_Maintenance_Item__c> itemListToInsert;
        List<Case> requestListToInsert = new List<Case>();
        Case newRequest;
        String uniqueValue; //String as the key instead of Id because the Ids are allocated after the DML insert
        
        fetchListToMaps(requestList, requestFilteredMap, itemPerRequestMap);

        //new request will have '[RMT]' at the beginning of their subject in addition to the old subject values
        //RMT stands for 'Routine Maintenance Test'
        for (Case fr : requestFilteredMap.values()) {
            newRequest = new Case(
                Vehicle__c = fr.Vehicle__c, 
                Status = 'New', Type = 'Routine Maintenance', 
                Subject = '[RMT] ' + fr.Subject, 
                Date_Reported__c = Date.newInstance(fr.ClosedDate.year(), fr.ClosedDate.month(), fr.ClosedDate.day()));
            
            newRequest.Date_Due__c = buildDueDate(itemPerRequestMap.get(fr.Id));

            requestListToInsert.add(newRequest);
            
            buildItemForEachRequest(fr, newRequest, itemPerRequestMap, itemListToBuild, itemMapToInsert, uniqueValue);
        }

        insert requestListToInsert;

        itemLinkForEachRequest(requestListToInsert, itemMapToInsert, uniqueValue);
        
        itemListToInsert = mapToList(itemMapToInsert);

        insert itemListToInsert;
    }

    private static Date buildDueDate(List<Equipment_Maintenance_Item__c> itemList) {
        Decimal minCycleValue = itemList.get(0).Equipment__r.Maintenance_Cycle__c;

        for (Equipment_Maintenance_Item__c emi : itemList) {
            minCycleValue = 
                minCycleValue > emi.Equipment__r.Maintenance_Cycle__c ? 
                    emi.Equipment__r.Maintenance_Cycle__c : minCycleValue;
        }   
        return Date.today().addDays(minCycleValue.intValue());
    }

    private static void fetchListToMaps(List<Case> requestList, Map<Id, Case> requestFilteredMap, Map<Id, List<Equipment_Maintenance_Item__c>> itemPerRequestMap) {
        List<Equipment_Maintenance_Item__c> itemList;

        for (Case mr : requestList) {
            if((mr.Type.equals('Repair') || mr.Type.equals('Routine Maintenance')) && mr.Status.equals('Closed'))
                requestFilteredMap.put(mr.Id, mr);
        }

        itemList = [
            SELECT Equipment__c, Equipment__r.Maintenance_Cycle__c, Maintenance_Request__c, Quantity__c
            FROM Equipment_Maintenance_Item__c 
            WHERE Maintenance_Request__c IN :requestFilteredMap.keySet()];

        for (Equipment_Maintenance_Item__c emi : itemList) {
            if(!itemPerRequestMap.containsKey(emi.Maintenance_Request__c))
                itemPerRequestMap.put(emi.Maintenance_Request__c, new List<Equipment_Maintenance_Item__c> {emi} );
            else
                itemPerRequestMap.get(emi.Maintenance_Request__c).add(emi);
        }
    }

    private static List<Equipment_Maintenance_Item__c> mapToList(Map<String, List<Equipment_Maintenance_Item__c>> mapList) {
        List<Equipment_Maintenance_Item__c> flattened = new List<Equipment_Maintenance_Item__c>();

        for (List<Equipment_Maintenance_Item__c> l : mapList.values())
            flattened.addAll(l);
        return flattened;
    }

    private static void buildItemForEachRequest(Case fr, Case newRequest, Map<Id, List<Equipment_Maintenance_Item__c>> itemPerRequestMap, List<Equipment_Maintenance_Item__c> itemListToBuild, Map<String, List<Equipment_Maintenance_Item__c>> itemMapToInsert, String uniqueValue){
        uniqueValue = newRequest.Subject+newRequest.Vehicle__c+newRequest.Date_Due__c;

            for(Equipment_Maintenance_Item__c emi : itemPerRequestMap.get(fr.Id)) {
                itemListToBuild.add(new Equipment_Maintenance_Item__c(
                    Equipment__c = emi.Equipment__c,
                    Quantity__c = emi.Quantity__c));
            }
            itemMapToInsert.put(uniqueValue, new List<Equipment_Maintenance_Item__c>(itemListToBuild));
            itemListToBuild.clear();
    }

    private static void itemLinkForEachRequest(List<Case> requestListToInsert, Map<String, List<Equipment_Maintenance_Item__c>> itemMapToInsert, String uniqueValue){
        for (Case ur : requestListToInsert) {
            uniqueValue = ur.Subject+ur.Vehicle__c+ur.Date_Due__c;
            for (Equipment_Maintenance_Item__c emi : itemMapToInsert.get(uniqueValue)) {
                emi.Maintenance_Request__c = ur.Id;
            }
        }
    }
}
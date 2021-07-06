public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts{
    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';
    
    public void execute(QueueableContext context) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            List<Product2> equipmentsToUpsert = new List<Product2>();
            List<Object> objList = (List<Object>) JSON.deserializeUntyped(response.getBody());

            for (Object o : objList) {
                Map<String, Object> equipmentMap = (Map<String, Object>) o;

                //in the execise is said to pass only the equipment with replacement true, but TH gives an error message
                Product2 equipment = new Product2(
                    Replacement_Part__c = (Boolean) equipmentMap.get('replacement'),
                    Cost__c = (Decimal) equipmentMap.get('cost'),
                    Current_Inventory__c = (Decimal) equipmentMap.get('quantity'),
                    Lifespan_Months__c = (Decimal) equipmentMap.get('lifespan'),
                    Maintenance_Cycle__c = (Decimal) equipmentMap.get('maintenanceperiod'),
                    Warehouse_SKU__c = (String) equipmentMap.get('sku')
                    );

                equipment.Name = (String) equipmentMap.get('name');
                equipment.ProductCode = (String) equipmentMap.get('_id'); 
                equipmentsToUpsert.add(equipment);
            }

            if(equipmentsToUpsert.size() > 0) {
                upsert equipmentsToUpsert;
            }
        }
    }

}
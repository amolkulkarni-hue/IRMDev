public class DocuSignBulkProcessor {

    /**
     * Sends envelopes to DocuSign using template IDs mapped in custom metadata.
     * Updates Customer_Notification__c with Envelope_Id__c and Envelope_Status__c = 'sent'
     * Returns list of successfully processed record Ids.
     */
    public static List<Id> process(List<Id> recordIds) {
        List<Id> processedIds = new List<Id>();
        if (recordIds == null || recordIds.isEmpty()) return processedIds;

        // Load template map from custom metadata
        // Load template map from custom metadata
Map<String, String> templateMap = new Map<String, String>();
List<DocuSign_Template_Mapping__mdt> mdList;

if (System.Test.isRunningTest()) {
    mdList = new List<DocuSign_Template_Mapping__mdt>{
        new DocuSign_Template_Mapping__mdt(
            MasterLabel = 'TestTemplate',
            Template_ID__c = 'temp-123',
            Template_Type__c = 'FM Letter'
        )
    };
} else {
    mdList = [
        SELECT MasterLabel, Template_ID__c, Template_Type__c
        FROM DocuSign_Template_Mapping__mdt
    ];
}

for (DocuSign_Template_Mapping__mdt m : mdList) {
    templateMap.put(m.Template_Type__c, m.Template_ID__c);
}

        // Query customer records (add any additional fields you need)
        List<Customer_Notification__c> customers = [
            SELECT Id, Account_Name__c, Email__c, Template_Type__c, Rate__c, EffectiveDate__c, Address_Line_1__c, Address_Line_2__c,Address_Line_3__c, ContactName__c, Country__c, percent1__c,
            info1__c,info2__c,info3__c,info4__c,info5__c,info6__c,info7__c,info8__c,info9__c,info10__c
            FROM Customer_Notification__c
            WHERE Id IN :recordIds
        ];

        String accountId = 'a3451c81-ddf7-4976-b230-22c246e126cc'; // <<< REPLACE with your DocuSign account id
        String endpointBase = 'callout:DocuSignNC/restapi/v2.1/accounts/' + accountId + '/envelopes';

        for (Customer_Notification__c c : customers) {
            try {
                String templateId = templateMap.get(c.Template_Type__c);
                if (String.isBlank(templateId)) {
                    System.debug('No template mapping for type: ' + c.Template_Type__c + ' record: ' + c.Id);
                    continue;
                }

                // Build templateRoles and tabs (map your DocuSign tab labels to Salesforce fields)
                Map<String, Object> role = new Map<String, Object>();
                role.put('email', c.Email__c);
                role.put('name', c.Account_Name__c);
                role.put('roleName', 'Customer'); // must match role used in DocuSign template

                // Add text tabs if your templates have text tabs (labels must match exactly)
                List<Object> textTabs = new List<Object>();
                textTabs.add(new Map<String, Object>{ 'tabLabel' => 'Account_Name__c', 'value' => c.Account_Name__c });
                if (c.Rate__c != null) textTabs.add(new Map<String, Object>{ 'tabLabel' => 'Rate', 'value' => String.valueOf(c.Rate__c) });
                if (c.EffectiveDate__c != null) textTabs.add(new Map<String, Object>{ 'tabLabel' => 'EffectiveDate__c', 'value' => String.valueOf(c.EffectiveDate__c) });
                
                //if (c.Name != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'Account_Name__c', 'value' => c.Account_Name__c });
                if (c.Address_Line_1__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'Address_Line_1__c', 'value' => c.Address_Line_1__c });
                if (c.Address_Line_2__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'Address_Line_2__c', 'value' => c.Address_Line_2__c });
                if (c.Address_Line_3__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'Address_Line_3__c', 'value' => c.Address_Line_3__c });
                if (c.ContactName__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'ContactName__c', 'value' => c.ContactName__c });
                if (c.Country__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'Country__c', 'value' => c.Country__c });
                if (c.percent1__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'percent1__c', 'value' => c.percent1__c });
                if (c.info1__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'info1__c', 'value' => c.info1__c });
                if (c.info2__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'info2__c', 'value' => c.info2__c });
                if (c.info3__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'info3__c', 'value' => c.info3__c });
                if (c.info4__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'info4__c', 'value' => c.info4__c });
                if (c.info5__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'info5__c', 'value' => c.info5__c });
                if (c.info6__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'info6__c', 'value' => c.info6__c });
                if (c.info7__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'info7__c', 'value' => c.info7__c });
                if (c.info8__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'info8__c', 'value' => c.info8__c });
                if (c.info9__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'info9__c', 'value' => c.info9__c });
                if (c.info10__c != null)textTabs.add(new Map<String, Object>{ 'tabLabel' => 'info10__c', 'value' => c.info10__c });
                

                Map<String, Object> tabs = new Map<String, Object>{ 'textTabs' => textTabs };
                role.put('tabs', tabs);

                Map<String, Object> envelopeReq = new Map<String, Object>();
                envelopeReq.put('templateId', templateId);
                envelopeReq.put('templateRoles', new List<Object>{ role });
                envelopeReq.put('status', 'sent'); // send immediately

                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpointBase);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(envelopeReq));

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 201 || res.getStatusCode() == 200) {
                    Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    String envelopeId = (String) resp.get('envelopeId');

                    c.Envelope_Id__c = envelopeId;
                    c.Status__c = 'sent';
                    processedIds.add(c.Id);

                    System.debug('Envelope created for ' + c.Id + ' envelopeId=' + envelopeId);
                } else {
                    System.debug('Failed to create envelope for ' + c.Id + ' status=' + res.getStatusCode() + ' body=' + res.getBody());
                }
            } catch (Exception ex) {
                System.debug('Exception sending envelope for ' + c.Id + ' : ' + ex.getMessage());
            }
        }

        if (!customers.isEmpty()) {
            try {
                update customers;
            } catch (Exception ex) {
                System.debug('Error updating customers with envelope IDs: ' + ex.getMessage());
            }
        }

        return processedIds;
    }
}
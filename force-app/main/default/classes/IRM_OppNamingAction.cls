/**
 * IRM_OppNamingAction
 * US-AUTONAME: Invocable action called by Opportunity_Auto_Name_Create_Flow and
 * Opportunity_Auto_Name_Update_Flow to dynamically build the Opportunity Name from
 * active Opp_Naming_Segment__c config records.
 *
 * Each segment's Field_API_Name__c is either:
 *   - A direct Opportunity field API name (e.g. Type, Business_Unit__c, Sales_Region__c)
 *   - A special token: __ACCOUNT_NAME__ or __QUARTER_YEAR__
 *
 * Segments are joined with an en dash ( – ) separator in ascending Order__c sequence.
 * Blank field values fall back to Fallback_Value__c (default: TBD).
 */
public class IRM_OppNamingAction {

    public class Request {
        @InvocableVariable(required=true label='Opportunity Record')
        public Opportunity opportunity;

        @InvocableVariable(required=false label='Account Name')
        public String accountName;

        @InvocableVariable(required=true label='Naming Segments')
        public List<Opp_Naming_Segment__c> segments;
    }

    public class Response {
        @InvocableVariable(label='Opportunity Name')
        public String opportunityName;
    }

    @InvocableMethod(
        label='Build Opportunity Name'
        description='Builds the Opportunity Name from configured Opp_Naming_Segment__c records. Called by Opportunity auto-name flows.'
    )
    public static List<Response> buildName(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            responses.add(process(req));
        }
        return responses;
    }

    private static Response process(Request req) {
        List<Opp_Naming_Segment__c> sorted = req.segments.clone();
        sorted.sort(new SegmentOrderComparator());

        List<String> parts = new List<String>();
        for (Opp_Naming_Segment__c seg : sorted) {
            String val = resolveValue(seg, req);
            if (String.isBlank(val)) {
                val = String.isNotBlank(seg.Fallback_Value__c) ? seg.Fallback_Value__c : 'TBD';
            }
            parts.add(val);
        }

        Response r = new Response();
        r.opportunityName = String.join(parts, ' – ');
        return r;
    }

    private static String resolveValue(Opp_Naming_Segment__c seg, Request req) {
        if (seg.Field_API_Name__c == '__ACCOUNT_NAME__') {
            return req.accountName;
        }
        if (seg.Field_API_Name__c == '__QUARTER_YEAR__') {
            return quarterYear();
        }
        Object fieldVal = req.opportunity.get(seg.Field_API_Name__c);
        return fieldVal != null ? String.valueOf(fieldVal) : null;
    }

    @TestVisible
    private static String quarterYear() {
        Date today = Date.today();
        Integer q = (Integer) Math.ceil(today.month() / 3.0);
        return 'Q' + q + ' ' + today.year();
    }

    private class SegmentOrderComparator implements Comparator<Opp_Naming_Segment__c> {
        public Integer compare(Opp_Naming_Segment__c a, Opp_Naming_Segment__c b) {
            if (a.Order__c == b.Order__c) return 0;
            return a.Order__c < b.Order__c ? -1 : 1;
        }
    }
}

public class SKPGetRecurringChargesResponse {
    public String customerId;
	public Integer count;
	public Integer offset;
	public Integer totalMatches;
	public List<RecurringCharges> recurringCharges;
    public List<CodeAndMessage> errors;
    public List<CodeAndMessage> warnings;    
   
    public SKPGetRecurringChargesResponse(){
        errors = new List<CodeAndMessage>();
        warnings = new List<CodeAndMessage>();
        recurringCharges = new List<RecurringCharges>();
    }
    
    public class CodeAndMessage {
        public String code;
        public String message;
    }

	public class RecurringCharges {
		public String divisionId;
		public String departmentId;
		public String districtId;
		public String billCode;
		public String startDate;
		public String endDate;
		public String billingCycle;
		public String quantity;
		public String rate;
		public String uom;
	}

}
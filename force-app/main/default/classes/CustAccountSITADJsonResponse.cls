public class CustAccountSITADJsonResponse{
    public cls_Account Account;
    public CustAccountSITADJsonResponse(){
        this.Account = new cls_Account();
    }
    public class cls_Account{
        public string AccountId;
        public string CustomerAccountId;
        public string ParentAccountId;
        public string ParentAccountName;
        public string CustomerAccountName;
        public string GlobalUltimateId;
        public string GlobalUltimateName;
        public cls_AccountAddress AccountAddress;
        public cls_Contact Contact;
        public string ModifiedDate;
        public string CreatedDate;
        public boolean IsDeleted;
        public string CreatedBy;
        public string ModifiedBy;
        public cls_Account(){
            this.AccountAddress = new cls_AccountAddress();
            this.Contact = new cls_Contact();
        }
        }
        public class cls_AccountAddress{
            public string AddressId;
            public cls_Address Address;
            public cls_AccountAddress(){
                this.Address = new cls_Address();
            }
            }
            public class cls_Address {
                public string Street;
                public string City;
                public string State;
                public string PostalCode;
                public string Country;
                public string ModifiedDate;
                public string CreatedDate;
                public boolean IsDeleted;
                public string CreatedBy;
                public string ModifiedBy;
                public cls_Address(){
                }
            }
        public class cls_Contact{
            public string ContactId;
            public string Name;
            public string PhoneNumber;
            public string EmailAddress;
            public string ModifiedDate;
            public string CreatedDate;
            public string IsDeleted;
            public string CreatedBy;
            public string ModifiedBy;
            public cls_Contact(){
            }
        }
}
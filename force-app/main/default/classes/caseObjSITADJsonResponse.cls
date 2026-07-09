public class caseObjSITADJsonResponse
{
        public string CaseId;
        public string CustomerAccountId;
        public string CustomerAccountName;
        public string CaseNumber;
        public string serviceScheduleDate;
        public string ServiceCompletionDate;
        public string AuditCompleteDate;
        public string SalesTypeId;
        public string SalesTypeSitad;
        public string ItadPartnerId;
        public string ItadPartner;
        public string ProgramProfileId;
        public string ProgramProfile;
        public string CaseOwner;
        public string MarketName;
        public string DistrictId;
        public string CaseStatusId;
        public string DueDate;
        public string ShredPlantShippingDate;
        public string VendorReceiptDate;
        public string CustomDateName;
        public string CustomDate;
        public string PurchaseOrderNumber;
        public decimal FairMarketValue;
        public string AccountId;
        public cls_ServiceContact ServiceContact; 
        public cls_ServiceAddress ServiceAddress;
        public string CorrectiveActionReport;
        public string Account;
        public string CaseStatus;
       // public string Services;
        public List<cls_CaseDispositionTypes> CaseDispositionTypes;
        public string Attachments;
        public string Comments;
        public string IsSaveOnly;
        public string ModifiedDate;
        public string CreatedDate;
        public string IsDeleted;
        public string CreatedBy;
        public string ModifiedBy;
    
        public caseObjSITADJsonResponse(){
            ServiceContact = new cls_ServiceContact();
            ServiceAddress = new cls_ServiceAddress();
            CaseDispositionTypes = new List<cls_CaseDispositionTypes>();
        }
   
        public class cls_ServiceContact{
            public string ServiceContactId;
            public string Name;
            public string PhoneNumber;
            public string EmailAddress;
            public string ModifiedDate;
            public string CreatedDate;
            public string IsDeleted;
            public string CreatedBy;
            public string ModifiedBy;
            public cls_ServiceContact(){
            
            }
        }
        public class cls_ServiceAddress{
            public string ServiceAddressId;
            public cls_Address Address;
            public cls_ServiceAddress(){
                Address = new cls_Address();
            }
        }
    
        public class cls_Address{
            public string AddressId;
            public string Street;
            public string City;
            public string State;
            public string PostalCode;
            public string Country;
            public string ModifiedDate;
            public string CreatedDate;
            public string IsDeleted;
            public string CreatedBy;
            public string ModifiedBy;
            public cls_Address(){
                
            }
        }
    
        public class cls_CaseDispositionTypes{
            public string CaseDispositionTypeId;
            public string ServiceDispositionTypeId;
            public string ServiceDispositionType;
            public string CaseId;
            public cls_CaseDispositionTypes(){
                
            }
        }
}
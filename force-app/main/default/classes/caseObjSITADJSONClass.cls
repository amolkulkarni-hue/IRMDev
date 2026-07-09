/******************************************************************************************************************************************
 * Class: caseObjSITADJSONClass
 * 
 * Change History:     11/07/2023
 * Developer           Date                Description
 * ------------------------------------------------------------------------------------------- 
 * Renuka Prasad       11/07/2023          Story #19589 - Changes to pass Billing Account Legal Entity for Country field for SMS Case Sync
 ******************************************************************************************************************************************/
public class caseObjSITADJSONClass{
    public cls_account account;
    public caseObjSITADJSONClass(Case Cas){
        this.account = new cls_account(Cas);
    }
    public class cls_account{
        public string customerAccountID;
        public string customerAccountName;
        //public string salesType;
        public string caseNumber;
        //public string serviceOrderDate;
        public string serviceScheduleDate;
        public string serviceCompletionDate;
        public string districtId; 
        public string marketName;
        public string salesRep;
        public cls_serviceAddress serviceAddress;
        public cls_serviceContact serviceContact;
        public List<dispositionObj> dispositionType;
        public cls_account(Case Cas){   
            //this.customerAccountID = Cas.Customer_ID__c;
            this.customerAccountId = Cas.Bill_To_Site_Number__c;//Cas.Customer_ID__r.name;
            this.customerAccountName = Cas.Account.Name;//Cas.Customer_Name__c;
            if(Cas.QTB_Case_Number__c != null){
                this.caseNumber = Cas.QTB_Case_Number__c;
            }else{
                this.caseNumber = Cas.CaseNumber;
            }
            
            this.serviceScheduleDate = string.ValueOf(Cas.Service_Schedule_Date__c);
            this.serviceCompletionDate = string.ValueOf(Cas.Service_Completion_Date__c);
            this.districtId = Cas.IM_Market__c;
            this.marketName = Cas.Market_Name__c;
            this.salesRep = Cas.Owner.name;//'Ed Fabian';
            this.serviceAddress = new cls_serviceAddress(Cas);
            this.serviceContact = new cls_serviceContact(Cas);
            this.dispositionType = new List<dispositionObj>();
            // This is for Multi Location when we get the Market from SMS(Program)
            if(String.isNotBlank(cas.QTB_Service_Market_ID__c)){
                this.districtId = cas.QTB_Service_Market_ID__c;
                //Get the respective Market Name
                List<Market__c> marIdList = [select Id,Name from Market__c where Owning_District_Id__c=:this.districtId];
                if(!marIdList.IsEmpty()){
                    this.marketName = marIdList[0].Name;
                } 
            }
            List<String> dispostionTypes = new List<string>();
            if(Cas.SITAD_Disposition_Type__c != null)
            dispostionTypes =cas.SITAD_Disposition_Type__c.split(';');
            
            for (String dispostionType : dispostionTypes){
                if(dispostionType!= null){
                    dispositionType.add(new dispositionObj(dispostionType));
                }            
            }    
        }
    }
    public class cls_serviceAddress{
        public cls_address address;
        public cls_serviceAddress(Case Ca){
            this.address = new cls_address(Ca);
        }
    }
    public class cls_address{
        public string street;
        public string city;
        public string state;
        public string postalCode;
        public string country;
        public cls_address(Case Cas){
            this.street = cas.Address__c;
            this.city = cas.City__c;
            this.state = cas.State__c;
            this.postalCode = cas.Zip__c;
            this.country = cas.Account.QTB_Legal_Entity_Country__c; //#19589 - Changes to pass Billing Account Legal Entity for Country field for SMS Case Sync
        }
    }
    public class cls_serviceContact{
        public string name;
        public string phoneNumber;
        public string emailAddress;
        public cls_serviceContact(Case caCon){
            this.name = caCon.Owner.Name;
            this.phoneNumber = caCon.Owner.Phone;
            this.emailAddress = caCon.Owner.Email;
        }
    }
    
   
    public class dispositionObj {
        public string dispositionValue;
        
        public dispositionObj(string disposition){
            this.dispositionValue = disposition;
        }
    }
   
}
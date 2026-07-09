/* Commenting the entire code as part of Gitlab #24448 */
public class InboundStorageAssignment {
    public InboundStorageAssignment(){
        
    }
    /*
    private OppStack the_match; 
    //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
    public InboundStorageAssignment(List<Case> cases,Inbound_Storage__c inb) {
        List<OppStack> opp_stack = new List<OppStack>(); 
        for(Case c : cases){
            if((c.NCSP_Opportunity__r.IM_Booked_Date__c < inb.Storage_Date__c 
                || c.NCSP_Opportunity__r.IM_Booked_Date__c.monthsBetween(inb.Storage_Date__c)==0) 
               && inb.Storage_Date__c < c.NCSP_Opportunity__r.Commissionable_Window_Close_Date__c){
                opp_stack.add(new OppStack(c,inb)); 
            }
        }
        if(!opp_stack.isEmpty()){
            //The Collection.sort() method sort list in Ascendent by default.
            opp_stack.sort(); 
            this.the_match = opp_stack[opp_stack.size()-1]; 
        }
    }   

    public OppStack getMatch(){
        return this.the_match;
    }

    public class OppStack implements Comparable {
        public Id opp; 
        public String type;
        private Integer score; 

        public OppStack(Case c,Inbound_Storage__c inb){
            this.score = 0; 
            this.type = c.NCSP_Opportunity__r.Type;
            this.opp = c.NCSP_Opportunity__r.Id; 
            if(c.New_Division_Id__c == inb.Div_ID_del__c){
                this.score++;
            }
            if(c.New_Department_ID__c == inb.Dept_ID_del__c){
                this.score++; 
            }
        } 
        public Integer compareTo(Object compTo){
            OppStack comp_obj = (OppStack)compTo; 
            if(this.score == comp_obj.score) return 0;
            if(this.score > comp_obj.score) return 1; 
            return -1;
        }
    }   
*/
}
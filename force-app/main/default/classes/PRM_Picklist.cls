public class PRM_Picklist {
    
    public PRM_Picklist(String l, string v) {
        this.label = l;
        this.value = v;
    }

    @AuraEnabled
    public String label					{ get;set; }
    
    @AuraEnabled
    public String value				{ get;set; }

}
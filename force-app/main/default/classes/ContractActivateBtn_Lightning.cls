/* Anitha Krishnamoorthy || 29th Jan 2020
 * This is created to make the custom Activate button lightning compatible
 */

public class ContractActivateBtn_Lightning {
    
    public String ContractId{get; set;}
    public Contract Con{get; set;}
    
    public ContractActivateBtn_Lightning(){
        ContractId = ApexPages.currentPage().getParameters().get('contractid');
    }
    
    public void UpdateContract(){
        Con = [Select id,Status from Contract where id=:ContractId ];
        if(Con.Status=='Activated'){
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'Contract already activated'));
        }
        else if(Con.Status=='Draft'){
            //apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'Are you sure you want to activate Contract?'));
            con.Status = 'Activated';
            try{
                Database.SaveResult sr = Database.update(con, false);
                //PageReference ContractDetailPg;
                if(sr.isSuccess()) {
                    //ContractDetailPg = new PageReference('/'+ContractId);
                    //ContractDetailPg.setRedirect(true);
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Contract updated successfully')); 
                }
                else{
                    if(sr.getErrors()!=Null){
                        String er='';
                        for(Database.Error err : sr.getErrors()) {
                            er += err.getMessage();
                        }
                        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'Failed to update contract: '+er));
                    }
                }
            }
            catch(exception e){
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'Failed to update contract: '+e)); 
            }
        }
        else if(Con.Status == 'Cancelled' || Con.Status == 'Terminated'){
            id profid = userinfo.getProfileId();
            List<Profile> prof = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
            String proflieName = prof[0].Name;
            if(proflieName=='IME_Custom Sys Admin' ||proflieName=='IME_Super_User'||proflieName=='IM_Custom Sys Admin'){
                try{
                    con.Status = 'Activated';
                    Database.SaveResult sr = Database.update(con, false);
                    PageReference ContractDetailPg;
                    if(sr.isSuccess()) {
                        //ContractDetailPg = new PageReference('/'+ContractId);
                        //ContractDetailPg.setRedirect(true);
                        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Contract updated successfully')); 
                    }
                    else{
                    if(sr.getErrors()!=Null){
                        String er='';
                        for(Database.Error err : sr.getErrors()) {
                            er += err.getMessage();
                        }
                        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'Failed to update contract: '+er));
                    }
                }
                }
                catch(exception e){
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'Failed to update contract:'+e)); 
                }
            }
        }
        else{
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'Only admin can activate cancelled/terminated contract')); 
        }
    }
    
    public pagereference GoToContract(){
        pagereference ref = new pagereference('/'+ContractId);
        ref.setRedirect(true);
        return ref;
    } 
    
}
/* Anitha Krishnamoorthy || 29th Jan 2020
* This is created to make the custom Cancel button lightning compatible
*/

public class ContractCancelBtn_Lightning {
    
    public String ContractId{get; set;}
    public Contract Con{get; set;}
    public List<Contract> ContToUpdate{get; set;}
    public List<Contract> ChildContracts{get; set;}
    
    public ContractCancelBtn_Lightning(){
        ContractId = ApexPages.currentPage().getParameters().get('contractid');
        Con = [Select id,Status,RecordTypeId from Contract where id=:ContractId ];
        if(Con.Status=='Activated' || Con.Status=='Draft'){
            system.debug('RecordTypeId>>>>'+Con.RecordTypeId);
            if(Con.RecordTypeId == '01280000000UJX3'){
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'All related contracts will be cancelled. Are you sure you wish to continue?'));
            }
            else if(Con.RecordTypeId=='01234000000Bmlb'||Con.RecordTypeId=='01234000000Bmlc'||Con.RecordTypeId=='01234000000Bmld'){
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'This contract will be cancelled. Are you sure you wish to continue?')); 
            }
            else if(Con.RecordTypeId=='01280000000UJX2'||Con.RecordTypeId=='01234000000UREB'){
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'Attention. After cancelling this addendum you need to manually update the fields this Addendum updated on all related Contract records (Parent, Child, etc.). Are you sure you wish to continue?'));
            }
            else{
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'Only activated or Draft contract can be cancelled'));
            }
        }
        else{
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'Only activated or Draft contract can be cancelled'));
        }
    }
    
    public PageReference UpdateContract(){
        system.debug('entering method UpdateContract');
        if(Con.Status=='Activated' || Con.Status=='Draft'){
            system.debug('Entering 1st if');
            if(Con.RecordTypeId == '01280000000UJX3'){
                try{
                    con.Status = 'Cancelled';
                    ContToUpdate = new List<Contract>();
                    ContToUpdate.add(con);
                    ChildContracts = new List<Contract>();
                    ChildContracts = [Select id,Status from Contract where Main_Contract__c =:ContractId AND
                                      status!='Cancelled'];
                    if(ChildContracts.size()>0){
                        for(Contract childCont : ChildContracts){
                            childCont.status = 'Cancelled';
                            ContToUpdate.add(childCont);
                        }
                    }
                    if(ContToUpdate.size()>0){
                        /* List<Database.Saveresult> sr=Database.update(ContToUpdate, false);
Set<Id> listOfIds = new Set<Id>();
for (Database.SaveResult sres : sr) {
if (!sres.isSuccess()) {
for(Database.Error err : sres.getErrors()){
apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'Failed to update contract: '+sres.errors.message));
}
}
}*/
                        update ContToUpdate;
                    }
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Info,'Contract updated successfully'));
                }
                catch(Exception e){
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'Failed to update contract: '+e));
                }
            }
            
            else if(Con.RecordTypeId=='01234000000Bmlb'||Con.RecordTypeId=='01234000000Bmlc'||Con.RecordTypeId=='01234000000Bmld'||Con.RecordTypeId=='01280000000UJX2'||Con.RecordTypeId=='01234000000UREB'){
                try{
                    con.Status = 'Cancelled';
                    Database.SaveResult sr = Database.update(con, false);
                    if(sr.isSuccess()) {
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
            else{
                system.debug('Going to else');
                //GoToContract();   
                pagereference ref = new pagereference('/'+ContractId);
                system.debug('ref>>>>>>>>'+ref);
                ref.setRedirect(true);
                return ref;
            }
        }     
        else{
            //GoToContract(); 
            pagereference ref = new pagereference('/'+ContractId);
            system.debug('ref>>>>>>>>'+ref);
            ref.setRedirect(true);
            return ref;
        }
        return null;
    }
    
    public pagereference GoToContract(){
        system.debug('enetrung ReturnContract');
        pagereference ref = new pagereference('/'+ContractId);
        system.debug('ref>>>>>>>>'+ref);
        ref.setRedirect(true);
        return ref;
    } 
    
}
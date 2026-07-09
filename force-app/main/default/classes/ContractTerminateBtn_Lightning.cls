/* Anitha Krishnamoorthy || 29th Jan 2020
* This is created to make the custom Cancel button lightning compatible
*/

public class ContractTerminateBtn_Lightning {
    
    public String ContractId{get; set;}
    public Contract Con{get; set;}
    public List<Contract> ContToUpdate{get; set;}
    public List<Contract> ChildContracts{get; set;}
    
    public ContractTerminateBtn_Lightning(){
        ContractId = ApexPages.currentPage().getParameters().get('contractid');
        Con = [Select id,Status,RecordTypeId from Contract where id=:ContractId ];
        if(Con.Status=='Activated'){
            system.debug('RecordTypeId>>>>'+Con.RecordTypeId);
            if(Con.RecordTypeId == '01280000000UJX3'){
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'All related contracts will be Terminated. Are you sure you wish to continue?'));
            }
            else if(Con.RecordTypeId=='01234000000Bmlb'||Con.RecordTypeId=='01234000000Bmlc'||Con.RecordTypeId=='01234000000Bmld'){
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'This contract will be Terminated. Are you sure you wish to continue?')); 
            }
            else if(Con.RecordTypeId=='01280000000UJX2'||Con.RecordTypeId=='01234000000UREB'){
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'Attention. After terminating this addendum you need to manually update the fields this Addendum updated on all related Contract records (Parent, Child, etc.). Are you sure you wish to continue?'));
            }
            else{
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'Only activated contract can be terminated'));
            }
        }
        else{
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Warning,'Only activated or Draft contract can be terminated'));
        }
    }
    
    public PageReference UpdateContract(){
        system.debug('entering method UpdateContract');
        if(Con.Status=='Activated'){
            if(Con.RecordTypeId == '01280000000UJX3'){
                try{
                    con.Status = 'Terminated';
                    ContToUpdate = new List<Contract>();
                    ContToUpdate.add(con);
                    ChildContracts = new List<Contract>();
                    ChildContracts = [Select id,Status from Contract where Main_Contract__c =:ContractId AND
                                      status!='Terminated'];
                    if(ChildContracts.size()>0){
                        for(Contract childCont : ChildContracts){
                            childCont.status = 'Terminated';
                            ContToUpdate.add(childCont);
                        }
                    }
                    if(ContToUpdate.size()>0){
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
                    con.Status = 'Terminated';
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
                pagereference ref = new pagereference('/'+ContractId);
                ref.setRedirect(true);return ref;
            }
        }     
        else{
            pagereference ref = new pagereference('/'+ContractId);
            ref.setRedirect(true);return ref;
        }
        return null;
    }
    
    public pagereference GoToContract(){
        pagereference ref = new pagereference('/'+ContractId);
        system.debug('ref>>>>>>>>'+ref);
        ref.setRedirect(true);
        return ref;
    } 
    
}
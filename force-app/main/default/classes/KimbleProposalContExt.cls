public class KimbleProposalContExt {
public final Opportunity opp {get; set;}
    public final Boolean canEdit {get; private set;}
    public String mode {get; private set;}
    public String uProfileId = UserInfo.getProfileId();
    public String usrProfile {get; set;}
        
    public KimbleProposalContExt(ApexPages.StandardController stdController) {
        // normally, this would be accomplished by stdController.addFields()
        // however, because this page can be included in another VF page,
        // we can't add more fields this way (because the other controller
                this.mode = 'view';
        
        Profile p = [SELECT Name FROM Profile WHERE Id =:UserInfo.getProfileId()];
        usrProfile = p.Name; 
        
        Set<String> AccessKimbleProfiles = new Set<String>();
        
        for(KimbleAccess__c KimbleProfiles: KimbleAccess__c.getall().values())
        {
            AccessKimbleProfiles.add(KimbleProfiles.name);
        }   

        if((!AccessKimbleProfiles.contains(usrProfile)))
        {
            this.mode = 'none';
            return;
        }
                canEdit = true; // for now.  will replace with real security code when defined.
    }
}
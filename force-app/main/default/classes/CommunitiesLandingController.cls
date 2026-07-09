/**
* An apex page controller that takes the user to the right start page based on credentials or lack thereof
*/
public with sharing class CommunitiesLandingController {
    
    // Code we will invoke on page load.
    public PageReference forwardToStartPage() {
        // If the network name is not 'Customer Support Center' or user is not logged in, continue with the default behavior
        return Network.communitiesLanding();
    }
    
    public CommunitiesLandingController() {}
}
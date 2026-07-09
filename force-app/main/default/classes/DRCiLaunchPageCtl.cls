public class DRCiLaunchPageCtl {

     public string contractId; 
 	 public string redirectUrl{get;set;}
 	 public boolean preProcessed{get;set;}
 	 public boolean testBypass = false;
 	 
     public DRCiLaunchPageCtl()
     { 
     	preProcessed = true;
     	contractId = System.currentPageReference().getParameters().get('contractId');
        Integer errCount = 0;
        
        //getDocs();
    	
     }
    
     public PageReference getDocs()
     {
     	string errLoc = '0';
     	preProcessed = false;
     	try
     	{
     		DRCiDOcumentLink.DRCiDocResponse res = new DRCiDOcumentLink.DRCiDocResponse();
	    	errLoc = '5';
	    	if(!testBypass)
	    	     res  = DRCiDOcumentLink.getContracts(System.currentPageReference().getParameters().get('contractId'));
	    	
	    	errLoc = '10';
	    	if(res.errorMsg != null && testBypass ==false)
	    	{
	    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR 
	    		                    ,'ERROR Accessing the DRCi System &quot;['+res.errorMsg+']')) ; 
	    		return null;
	    	}
	    	
	    	errLoc = '20';
	    	if(res.hitCount < 1  && testBypass ==false)
	    	{
	    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO 
	    		                    ,'There are no documents matching this Contract Number')) ; 
	    		return null;
	    	}
	        
	        errLoc = '30';
	    	redirectUrl = res.documents.get(0).documentLink ;
	    	//PageReference pg = new PageReference(redirectUrl);
	    	//pg.setRedirect(true);
		    //return pg;
     	}
     	catch(Exception e)
     	{   
     		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR 
    		                    ,'** '+errLoc+' **' + e.getMessage() )) ; 
    		return null;
    	}
    	return null;
     }
    
     public PageReference cancel()
	 {
	          
	        return null;
	 }
}
@isTest
private class TestWsDRCiLogOutService {

    static testMethod void runTest() {
        WsDRCiLogoutService svc = new WsDRCiLogoutService();
 	       WsDRCiLogoutService.LogoutServiceSoap Logout = new WsDRCiLogoutService.LogoutServiceSoap();
	       WsDRCiLogoutService.LogoutResponse_element LogoutRes = new WsDRCiLogoutService.LogoutResponse_element();
           try{
	           LogoutRes 
				 	   = Logout.Logout('x', 'y');
           }
           catch(Exception e)
           {
           	  
           }
    }
}
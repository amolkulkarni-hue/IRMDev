/**
*Author: NAGESH EARANTI
*Company: HCL America
*Date: 10-06-2011
*
*Comments:
*On campaign creation change the currency to USD when the user creating the case is from 
*IME, IMLA or IMAP
*
*/
trigger CampaignCurrenyUpdate on Campaign (before insert, before update) {
	
	for(Campaign c:Trigger.new) {
		if(c.CurrencyIsoCode != 'USD' && c.CurrencyIsoCode != 'CAD' ) {
			for(User u: [select Id, Division from User where Id = :c.OwnerId]) {
				if(u.Division =='IME' || u.Division == 'IMLA' || u.Division =='IMAP')
				{
					c.CurrencyIsoCode = 'USD';
				}
				
			}
		}		
	}

}
trigger AccountListener on Account (before insert, before update)
{
    if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate))
    {
        for (Account a : trigger.new)
        {
            if (a.NameCountryKey__c != (a.Name + ' | ' + (a.BillingCountry ?? '')))
                a.NameCountryKey__c = a.Name + ' | ' + (a.BillingCountry ?? '');
        }
    }
}
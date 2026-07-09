//Function is called when task/event of Lead or Contact is added.
public class MostRecentsaleActvt{
    public static void excludeEloquaUsers (set<id> setWhoId) {
       list<Lead> leadsToUpdate = new list<Lead>();
       list<Contact> contactsToUpdate = new list<Contact>();
        for(ID idAll: setWhoId){
            if(String.valueOf(idAll).startsWith('00Q')){
               Lead l = new Lead(id=idAll);
                l.Most_Recent_Sales_Activity__c = datetime.now();
                leadsToUpdate.add(l);
            }
            else if(String.valueOf(idAll).startsWith('003')){
                Contact c = new COntact(id=idAll);
                c.Most_Recent_Sales_Activity__c = datetime.now();
                contactsToUpdate.add(c);
            }
        }
        if(!leadsToUpdate.isempty())
            update leadsToUpdate;

        if(!contactsToUpdate.isEmpty())
            update contactsToUpdate;
    }        
}
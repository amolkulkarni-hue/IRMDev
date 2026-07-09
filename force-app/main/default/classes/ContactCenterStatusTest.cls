@isTest
public class ContactCenterStatusTest {
    @isTest
    static void testSetOpen(){
        ContactCenterStatus c = new ContactCenterStatus();
        c.setOpen();
        Assert.areEqual(true, c.isOpen);
    }
    @isTest
    static void testSetClose(){
        ContactCenterStatus c2 = new ContactCenterStatus();
        c2.setClose('TEST');
        Assert.areEqual(false, c2.isOpen);
    }
}
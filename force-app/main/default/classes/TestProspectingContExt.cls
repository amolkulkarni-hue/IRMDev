@isTest
public with sharing class TestProspectingContExt {

    private static ApexPages.StandardController stdCont;
    private static ProspectingContExt cont;
    private static String ident;

    static {
        ident = String.valueOf(System.currentTimeMillis()).substring(9,13);
    }

    private static Prospecting_Entry__c createEntry(Id ownerId, Boolean submitted, Boolean doDml){
        return TestingUtils.createProspectingEntry(ownerId, submitted, doDml);
    }

    @isTest private static void testConstructor_Basic(){
        //stdCont = new ApexPages.StandardController(null);
        Test.startTest();
        cont = new ProspectingContExt(null);
        Test.stopTest();

        system.assertEquals('view',cont.mode);
        system.assertEquals(0,cont.params.size());
        system.assertEquals(UserInfo.getUserId(),cont.targetUser);
        system.assert(cont.admins.size()>0);

        system.assertEquals(cont.getThisMonday(), cont.entry.Start_Date__c);
        system.assertEquals(UserInfo.getUserId(), cont.entry.OwnerId);
        system.assertEquals(null, cont.entry.Id);
    }

    @isTest private static void testConstructor_LoadsManageesAndActivites(){
        User u = TestingUtils.createUser(ident, false);
        u.IM_RSM__c = TestingUtils.ADMIN_USER.Id;
        insert u;
        Prospecting_Entry__c p = createEntry(u.Id,true,true);
        p.IsLocked__c = true;
        update p;
        system.assert([SELECT Id FROM Prospecting_Activity__c].size()==5);
        ApexPages.currentPage().getParameters().put('user',u.Id);
        ApexPages.currentPage().getParameters().put('date',String.valueOf(p.Start_Date__c));
        Test.startTest();
        system.runAs(TestingUtils.ADMIN_USER){
            cont = new ProspectingContExt(null);
        }
        Test.stopTest();
        system.assertEquals(cont.entry.Id,p.Id);
        system.assertEquals(true, cont.isManager);
        system.assertEquals(true, cont.hasActivities);
        system.assertEquals(true, cont.hasManagees);
    }

    @isTest private static void testConstructor_WithEntry(){
        Prospecting_Entry__c p = createEntry(UserInfo.getUserId(),false,true);
        stdCont = new ApexPages.StandardController(p);
        Test.startTest();
        cont = new ProspectingContExt(stdCont);
        Test.stopTest();
        system.assertEquals(cont.entry.Id,p.Id);
        system.assertEquals(true, cont.isManager);
        system.assertEquals(false, cont.hasActivities);
    }

    @isTest private static void testConstructor_WithLastWeek(){
        ApexPages.currentPage().getParameters().put('week','last');
        Test.startTest();
        cont = new ProspectingContExt(null);
        Test.stopTest();
        system.assertEquals(cont.getThisMonday()-7,cont.entry.Start_Date__c);
        system.assertEquals(null,cont.entry.Id);
        system.assertEquals(true,cont.canEdit);
        system.assertEquals(false,cont.canSubmit);
        system.assertEquals(false,cont.isThisWeek);
    }

    @isTest private static void testConstructor_WithThisWeek(){
        ApexPages.currentPage().getParameters().put('week','this');
        Test.startTest();
        cont = new ProspectingContExt(null);
        Test.stopTest();
        system.assertEquals(cont.getThisMonday(),cont.entry.Start_Date__c);
        system.assertEquals(null,cont.entry.Id);
        system.assertEquals(true,cont.isThisWeek);
        system.assert(cont.baseUrl.contains(String.valueOf(cont.getThisMonday())));
        system.assert(cont.prev.contains(String.valueOf(cont.getThisMonday()-7)));
        system.assert(cont.next.contains(String.valueOf(cont.getThisMonday()+7)));
        system.assert(cont.current.contains(String.valueOf(cont.getThisMonday())));
    }

    @isTest private static void testConstructor_WithNextWeek(){
        ApexPages.currentPage().getParameters().put('week','next');
        Test.startTest();
        cont = new ProspectingContExt(null);
        Test.stopTest();
        system.assertEquals(cont.getThisMonday()+7,cont.entry.Start_Date__c);
        system.assertEquals(null,cont.entry.Id);
    }

    @isTest private static void testDoEdit(){
        cont = new ProspectingContExt(null);
        Test.startTest();
        cont.doEdit();
        Test.stopTest();
        system.assertEquals('edit',cont.mode);
    }

    @isTest private static void testDoCancel_WithNew(){
        cont = new ProspectingContExt(null);
        cont.entry.of_initial_meetings_set_up_this_week__c = 100;
        Test.startTest();
        cont.doCancel();
        Test.stopTest();
        system.assertEquals(null, cont.entry.of_initial_meetings_set_up_this_week__c);
    }

    @isTest private static void testDoCancel_WithExisting(){
        cont = new ProspectingContExt(null);
        cont.entry.of_initial_meetings_set_up_this_week__c = 100;
        cont.doSave();
        cont.entry.of_initial_meetings_set_up_this_week__c = 50;
        Test.startTest();
        cont.doCancel();
        Test.stopTest();
        system.assertEquals(100, cont.entry.of_initial_meetings_set_up_this_week__c);
    }

    @isTest private static void testDoSave(){
        cont = new ProspectingContExt(null);
        cont.entry.of_initial_meetings_set_up_this_week__c = 100;
        Test.startTest();
        cont.doSave();
        Test.stopTest();
        system.assertEquals(100, cont.entry.of_initial_meetings_set_up_this_week__c);
        system.assertEquals(null, cont.entry.of_hours_spent_prospecting_this_week__c);
        system.assertNotEquals(null, cont.entry.Id);
    }

    @isTest private static void testDoSubmit_BeforeReady(){
        cont = new ProspectingContExt(null);
        Test.startTest();
        cont.doSubmit();
        Test.stopTest();

        List<ApexPages.Message> messages = ApexPages.getMessages();
        system.assertEquals('You may not submit at this time',messages[0].getDetail());
    }

/*  JM

    @isTest private static void testDoSubmit_WhenReady(){
        Prospecting_Entry__c p = createEntry(UserInfo.getUserId(), false, true);
        stdCont = new ApexPages.StandardController(p);
        cont = new ProspectingContExt(stdCont);
        Test.startTest();
        cont.doSubmit();
        Test.stopTest();

        List<ApexPages.Message> messages = ApexPages.getMessages();
        system.assertEquals(0, messages.size());
        system.assertEquals('Submitted', cont.entry.Status__c);
        system.assertEquals(true, cont.entry.IsSubmitted__c);
    }
    
JM END */    

    @isTest private static void testDoUnlock_WithoutPermission(){
        Prospecting_Entry__c p = createEntry(UserInfo.getUserId(), true, true);
        p.IsLocked__c = true;
        update p;
        stdCont = new ApexPages.StandardController(p);
        cont = new ProspectingContExt(stdCont);
        cont.isManager = false;
        system.assertEquals(true, cont.entry.IsLocked__c);
        Test.startTest();
        cont.doUnlock();
        Test.stopTest();
    
        List<ApexPages.Message> messages = ApexPages.getMessages();
        system.assertEquals('You do not have permissions to unlock this record.',messages[0].getDetail());
    }

    @isTest private static void testDoUnlock(){
        Prospecting_Entry__c p = createEntry(UserInfo.getUserId(), true, true);
        p.IsLocked__c = true;
        update p;
        stdCont = new ApexPages.StandardController(p);
        cont = new ProspectingContExt(stdCont);
        system.assertEquals(true, cont.entry.IsLocked__c);
        Test.startTest();
        cont.doUnlock();
        Test.stopTest();
        system.assertEquals(false, cont.entry.IsLocked__c);
    }

    @isTest private static void testDoRelock(){
        Prospecting_Entry__c p = createEntry(UserInfo.getUserId(), true, true);
        p.IsLocked__c = true;
        update p;
        stdCont = new ApexPages.StandardController(p);
        cont = new ProspectingContExt(stdCont);
        system.assertEquals(true, cont.entry.IsLocked__c);
        cont.doUnlock();
        system.assertEquals(false, cont.entry.IsLocked__c);
        Test.startTest();
        cont.doRelock();
        Test.stopTest();
        system.assertEquals(true, cont.entry.IsLocked__c);
    }

    @isTest private static void testSaveRecord_ForException(){
        cont = new ProspectingContExt(null);
        cont.doSave();
        cont.entry.Status__c = 'Submitted';
        cont.entry.IsSubmitted__c = true;
        Test.startTest();
        cont.saveRecord();
        Test.stopTest();
        List<ApexPages.Message> messages = ApexPages.getMessages();
        system.assert(messages.size()>1);
    }

}
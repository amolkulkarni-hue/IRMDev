@isTest
private class TestCarouselController {

    //static BoB_Coverage__c testCoverage;//Commenting as part of Gitlab #28236
    static ApexPages.Standardcontroller sc;
    //static Id dashboardRTId = [ SELECT Id FROM RecordType WHERE DeveloperName = 'Dashboard_Carousel_Announcement' AND SObjectType = 'Announcement__c' ].Id;
    static Id homepageRTId = [ SELECT Id FROM RecordType WHERE DeveloperName = 'Home_Carousel_Announcement' AND SObjectType = 'Announcement__c' ].Id;
    static Id bobRTId = [ SELECT Id FROM RecordType WHERE DeveloperName = 'BoB_Carousel_Announcement' AND SObjectType = 'Announcement__c' ].Id;
        
    public static final Integer NUM_OF_EXPECTED_ANNOUCEMENTS   = 4;
    public static final Integer NUM_OF_UNEXPECTED_ANNOUCEMENTS = 10;

    public static final String EXPECTED_CONTENT   = 'This is a message for today';
    public static final String UNEXPECTED_CONTENT = 'This message is not for today';
    
//Commenting as part of Gitlab #28236    
    /*static void setup()
    {
        Account testAcc = TestingUtils.createAccounts( 1, true )[0];
        //testCoverage = TestingUtils.createBoBCoverages( 1, testAcc.Id, 'TestBoB', 'Test Product', 'United Kingdom', true )[0];
        sc = new ApexPages.Standardcontroller( testCoverage );
    }*/

    static testMethod void testConstructor_noMessages(){

        List<AnnouncementModel> actualAnnouncements;

        Test.startTest();

            CarouselController controller = new CarouselController( sc );
            actualAnnouncements = controller.announcements;

        Test.stopTest();

        System.assertEquals( 1, actualAnnouncements.size(), 'There should be only one annoucement in the list' );
        System.assertEquals( Label.Carousel_no_messages, actualAnnouncements[0].content, 'The announcement should be the no announcements label' );
    }

    static testMethod void testBobCarouselController(){

        List<Announcement__c> announcements = new List<Announcement__c>();
        
        for ( Integer i=0; i < NUM_OF_EXPECTED_ANNOUCEMENTS; ++i ){
            announcements.add( new Announcement__c( Announcement_HTML__c = EXPECTED_CONTENT, Active__c = true, recordTypeId = bobRTId ) );
        }
        for ( Integer i=0; i < NUM_OF_UNEXPECTED_ANNOUCEMENTS; ++i ){
            announcements.add( new Announcement__c( Announcement_HTML__c = UNEXPECTED_CONTENT, Active__c = false, recordTypeId = bobRTId ) );
        }
        announcements.add( new Announcement__c( Announcement_HTML__c = EXPECTED_CONTENT, Active__c = true/*, recordTypeId = dashboardRTId */,recordTypeId = homepageRTId) );

        insert announcements;

        List<AnnouncementModel> actualAnnouncements;

        Test.startTest();

            CarouselController controller = new CarouselController( sc );
            actualAnnouncements = controller.announcements;

        Test.stopTest();

        System.assertEquals( NUM_OF_EXPECTED_ANNOUCEMENTS, actualAnnouncements.size(), 'Every active announcement should be displayed' );

        for ( AnnouncementModel announcement : actualAnnouncements ){
            System.assertEquals( EXPECTED_CONTENT, announcement.content, 'Only active announcements should be displayed' );
        }
    }
    
    static testMethod void testDashboardCarouselController(){
        

        List<Announcement__c> announcements = new List<Announcement__c>();
        
        
        
        for ( Integer i=0; i < NUM_OF_EXPECTED_ANNOUCEMENTS; ++i ){
            announcements.add( new Announcement__c( Announcement_HTML__c = EXPECTED_CONTENT, Active__c = true/*, recordTypeId = dashboardRTId*/) );
        }
        for ( Integer i=0; i < NUM_OF_UNEXPECTED_ANNOUCEMENTS; ++i ){
            announcements.add( new Announcement__c( Announcement_HTML__c = UNEXPECTED_CONTENT, Active__c = false/*, recordTypeId = dashboardRTId*/ ) );
        }
        
        announcements.add( new Announcement__c( Announcement_HTML__c = EXPECTED_CONTENT, Active__c = true, recordTypeId = homepageRTId ));

        insert announcements;

        List<AnnouncementModel> actualAnnouncements;

        Test.startTest();

            DashboardCarouselController controller = new DashboardCarouselController( );
            actualAnnouncements = controller.announcements;

        Test.stopTest();

        /*System.assertEquals( NUM_OF_EXPECTED_ANNOUCEMENTS, actualAnnouncements.size(), 'Every active announcement should be displayed' );

        for ( AnnouncementModel announcement : actualAnnouncements ){
            System.assertEquals( EXPECTED_CONTENT, announcement.content, 'Only active announcements should be displayed' );
        }*/
    }
    
    static testMethod void testHomepageCarouselController(){

        List<Announcement__c> announcements = new List<Announcement__c>();
        
        String profileName = [ SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() ].Name;

        for ( Integer i=0; i < NUM_OF_EXPECTED_ANNOUCEMENTS; ++i ){
            announcements.add( new Announcement__c( Announcement_HTML__c = EXPECTED_CONTENT, Active__c = true, User_Profiles__c = profileName, recordTypeId = homepageRTId) );
        }
        for ( Integer i=0; i < NUM_OF_UNEXPECTED_ANNOUCEMENTS; ++i ){
            announcements.add( new Announcement__c( Announcement_HTML__c = UNEXPECTED_CONTENT, Active__c = false, User_Profiles__c = profileName, recordTypeId = homepageRTId ) );
        }
        announcements.add( new Announcement__c( Announcement_HTML__c = EXPECTED_CONTENT, Active__c = true, User_Profiles__c = profileName, recordTypeId = bobRTId  ) );
        announcements.add( new Announcement__c( Announcement_HTML__c = EXPECTED_CONTENT, Active__c = true, User_Profiles__c = 'Other Profile;', recordTypeId = homepageRTId  ) );
        insert announcements;

        List<AnnouncementModel> actualAnnouncements;

        Test.startTest();

            HomepageCarouselController controller = new HomepageCarouselController( );
            actualAnnouncements = controller.announcements;

        Test.stopTest();

        /*System.assertEquals( NUM_OF_EXPECTED_ANNOUCEMENTS, actualAnnouncements.size(), 'Every active announcement should be displayed' );

        for ( AnnouncementModel announcement : actualAnnouncements ){
            System.assertEquals( EXPECTED_CONTENT, announcement.content, 'Only active announcements should be displayed' );
        }*/
    }
}
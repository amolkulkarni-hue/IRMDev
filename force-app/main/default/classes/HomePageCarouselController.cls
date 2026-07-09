public with sharing class HomePageCarouselController
{
	public List<AnnouncementModel> announcements { get; private set; }

	public HomePageCarouselController()
	{
		String profileName = [ SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() ].Name;
		Id homepageAnnouncements = [ SELECT Id FROM RecordType WHERE DeveloperName = 'Home_Carousel_Announcement' AND SObjectType = 'Announcement__c' ].Id;
		
		announcements =  new List<AnnouncementModel>();

		for ( Announcement__c announcement : [SELECT Announcement_HTML__c, URL_Link__c
									FROM Announcement__c
									WHERE 	Active__c = true AND
											User_Profiles__c INCLUDES (:profileName) AND
											RecordTypeId = :homepageAnnouncements
									ORDER BY Order__c ASC ] ){
			announcements.add( new AnnouncementModel( announcement.Announcement_HTML__c, announcement.URL_Link__c ) );
		}

		if ( announcements.isEmpty() ){
			announcements.add( new AnnouncementModel( Label.Carousel_no_messages, null ) );
		}
		
	}
}
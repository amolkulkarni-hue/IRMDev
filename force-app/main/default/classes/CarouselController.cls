public with sharing class CarouselController {

	public List<AnnouncementModel> announcements { get; private set; }

	public CarouselController(Apexpages.standardController controller)
	{
		Id bobAnnouncements = [ SELECT Id FROM RecordType WHERE DeveloperName = 'BoB_Carousel_Announcement' AND SObjectType = 'Announcement__c' ].Id;
		announcements =  new List<AnnouncementModel>();

		for ( Announcement__c announcement : [SELECT Announcement_HTML__c, URL_Link__c
									FROM Announcement__c
									WHERE 	Active__c = true AND 
											RecordTypeId = :bobAnnouncements
									ORDER BY Order__c ASC ] ){
			announcements.add( new AnnouncementModel( announcement.Announcement_HTML__c, announcement.URL_Link__c ) );
		}

		if ( announcements.isEmpty() ){
			announcements.add( new AnnouncementModel( Label.Carousel_no_messages, null ) );
		}
	}
}
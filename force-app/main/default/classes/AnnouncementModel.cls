public with sharing class AnnouncementModel
{
	public String content { get; set; }
	public String url	 { get; set; }

	public AnnouncementModel( String content, String url ){
		this.content = content;
		this.url = url;
	}
}
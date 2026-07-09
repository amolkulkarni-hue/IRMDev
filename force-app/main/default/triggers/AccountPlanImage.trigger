trigger AccountPlanImage on SFDC_Acct_Plan__c (before insert, before update) {
    
    Static Integer startImgTag;
    Static Integer endImgTag;
    Static Integer startSrcTag;
    Static Integer endSrcTag;
    Static String imageHtml;
    
    for(SFDC_Acct_Plan__c ap : Trigger.new){
    system.debug('+++++ Rich text field is +++++' + ap.Organizational_Chart__c);
    if(ap.Organizational_Chart__c != null){
    if(ap.Organizational_Chart__c.contains('<img')){
        system.debug('++++++++++++ Contains image ++++++++++');
        startImgTag = ap.Organizational_Chart__c.indexOf('<img', 0);
        endImgTag = ap.Organizational_Chart__c.indexOf('/img>', startImgTag);
        imageHtml = ap.Organizational_Chart__c.substring(startImgTag, endImgTag);
        system.debug('+++++++++ Image html is +++++++++++++++' + imageHtml);
        
        
        startSrcTag = imageHtml.indexOf('src', 1);
         endSrcTag = imageHTml.indexOf('" ', startSrcTag); 
         system.debug ('+++++++ TRY END SRC+++++++++++'+ endSrcTag );
        if(endSrcTag==-1){
         endSrcTag = imageHTml.indexOf('">', startSrcTag);
         system.debug ('+++++++ CATCH END SRC+++++++++++' + endSrcTag );
        }
        String ImageURL = imageHtml.substring(startSrcTag+5, endSrcTag);
        system.debug('+++++++++ Image url is +++++++++++++++' + ImageURL);
        
        String amp = 'amp;';
        String finalURL='';
        Integer startImage = imageURL.indexOf(amp, 1);
        finalURL=ImageURL.replace('amp;', '');
        system.debug('+++++++++ finalURL url is +++++++++++++++' + finalURL);
       
       ap.conga_text__c = finalURL;
       
        
            }
            
        ap.CongaRichTextForWord__c=ap.Organizational_Chart__c;
        while(ap.CongaRichTextForWord__c.contains('<img')){
            system.debug('++++++++++++ Contains extra image ++++++++++');
            startImgTag = ap.CongaRichTextForWord__c.indexOf('<img', 0);
            endImgTag = ap.CongaRichTextForWord__c.indexOf('/img>', startImgTag);
            imageHtml = ap.CongaRichTextForWord__c.substring(startImgTag, endImgTag+5);
            ap.CongaRichTextForWord__c=ap.CongaRichTextForWord__c.replace(imageHtml, ' ');
            system.debug('++++++++++++++++++++ ap.CongaRichTextForWord__c ++++ '+ap.CongaRichTextForWord__c);
        }
    }
    else{
        ap.conga_text__c = null;
    }
    }
}
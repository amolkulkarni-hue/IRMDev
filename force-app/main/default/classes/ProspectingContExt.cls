public with sharing class ProspectingContExt {

    // Private variables
    @testVisible private Map<String, String> params;
    @testVisible private Id targetUser;
    @testVisible private transient Map<Id, Profile> admins;

    // Public variables
    public Prospecting_Entry__c entry {get; set;}
    public List<Prospecting_Activity__c> activities {get; private set;}
    public List<User> managees {get; private set;}
    public String mode {get; private set;}
    public Boolean isManager {get; set;}
    public Boolean doRefresh {get; private set;}
    public String refreshUrl {get; private set;}

    // Constructor
    public ProspectingContExt(ApexPages.StandardController stdController) {
        // cache the page parameters
        params = ApexPages.currentPage().getParameters();

        // init to view mode
        mode = 'view';

        // cache the user whose entry we're displaying
        targetUser = (Id) params.get('user');
        if(targetUser==null) targetUser = UserInfo.getUserId();


        // if we've been passed an id, display that record
        if(stdController!=null && stdController.getId()!=null){
            entry = getRecord(stdController.getId());
            targetUser = entry.OwnerId;

        // otherwise, find/create a record for that user/date
        }else{
            // if we're passed a date param, use it.  otherwise, assume
            // we're looking for today
            Date d = params.get('date')==null ? Date.today() : Date.valueOf(params.get('date'));

            // if we're not given a specific date, but instead
            // week=(last|this|next), then calculate a date to match
            if(params.get('date')==null && params.get('week')!=null){
                if(params.get('week')=='last'){
                    d = Date.today().addDays(-7);
                }else if(params.get('week')=='this'){
                    d = Date.today();
                }else if(params.get('week')=='next'){
                    d = Date.today().addDays(7);
                }
            }           

            // now, round the specified date to the monday of that week
            d = getMondayFromDate(d);
            // and fetch the record for that week
            entry = getRecord(d);
        }

        // find all profiles with the word "admin" in their name
        admins = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Name LIKE '%admin%']);

        // find all users whose "Manager" field is set to the current user
        Map<Id, User> manageeMap = new Map<Id, User>([SELECT Id, Name FROM User WHERE (IM_RSM__c = :UserInfo.getUserId() OR Id=:UserInfo.getUserId()) ORDER BY Name ASC]);
        managees = manageeMap.values();

        // if we're working with an existing record, and the current user
        // is either an admin or the record owner's manager, then set the
        // isManager flag to true, and fetch the activity records for the
        // entry record
        if(entry.Id != null){
            if(admins.keySet().contains(UserInfo.getProfileId()) || manageeMap.keySet().contains(targetUser)){
                isManager = true;
                activities = [SELECT Id, Name, Date__c, Call_Count__c, Email_Count__c, Hour_Count__c, Meeting_Count__c FROM Prospecting_Activity__c WHERE Prospecting_Entry__c = :entry.Id ORDER BY Date__c ASC];
            }
        }
    }

    // Public properties

    // an entry is editable any time it has not yet been submitted
    public Boolean canEdit { 
        get { 
            return entry.IsLocked__c != true; 
        }
    }

    // an entry is submittable any time it has not yet been submitted
    // and its numbers are filled in
    // and its start date is not in the future
    public Boolean canSubmit { 
        get { 
            return entry.IsSubmitted__c != true && 
                   entry.Start_Date__c <= Date.today() &&
                   entry.of_hours_spent_prospecting_this_week__c != null &&
                   entry.of_prospecting_emails_sent_this_week__c != null &&
                   entry.of_prospecting_calls_made_this_week__c != null &&
                   entry.of_initial_meetings_set_up_this_week__c != null;
        }
    }

    // an entry will have activities (for our purposes) when
    // the entry has been locked 
    // and the current user is an admin/manager and can view them
    public Boolean hasActivities { 
        get { 
            return activities!=null && activities.size()>0; 
        }
    }

    // this will be true whenever the record being viewed is the record
    // for the current week.
    public Boolean isThisWeek { 
        get { 
            return entry.Start_Date__c == getThisMonday(); 
        }
    }

    // this will be true whenever the current user has at least one
    // other user whose manager field points to them
    public Boolean hasManagees { 
        get { 
            return managees!=null && managees.size()>0; 
        }
    }

    // this is the url to get back to the active week's record
    // for the current user (not the record user)
    public String baseUrl { 
        get { 
            PageReference p = Page.Prospecting;
            p.getParameters().put('date',String.valueOf(entry.Start_Date__c));
            return p.getUrl();
        }
    }

    // this is the url to get the record for the week prior to 
    // the active record, for the same user
    public String prev{
        get{
            PageReference p = getBasePageRef();
            Date lastWeek = entry.Start_Date__c.addDays(-7);
            p.getParameters().put('date',String.valueOf(lastWeek));
            return p.getUrl();
        }
    }

    // this is the url to get the record for the week after 
    // the active record, for the same user
    public String next{
        get{
            PageReference p = getBasePageRef();
            Date nextWeek = entry.Start_Date__c.addDays(7);
            p.getParameters().put('date',String.valueOf(nextWeek));
            return p.getUrl();
        }
    }

    // this is the url to get to the record for the current week
    // for the same user as the active record
    public String current {
        get {
            PageReference p = getBasePageRef();
            Date currentWeek = getThisMonday();
            p.getParameters().put('date',String.valueOf(currentWeek));
            return p.getUrl();
        }
    }

    // Private methods

    // finds the monday of the current week
    @testVisible private Date getThisMonday(){ return ProspectingContExt.static_getThisMonday(); }
    @testVisible private static Date static_getThisMonday(){
        return static_getMondayFromDate(Date.today());
    }

    // finds the monday of the week for the given date
    @testVisible private Date getMondayFromDate(Date d){ return ProspectingContExt.static_getMondayFromDate(d); }
    @testVisible private static Date static_getMondayFromDate(Date d){
        d = d.toStartOfWeek();
        Date epoch = Date.valueOf('1900-01-07');
        while(Math.mod(epoch.daysBetween(d), 7) != 1){
            d+=1;
        }
        return d;
    }

    // gets all pertinent entry record data for the specified id or date
    // if no record exists, creates one in memory
    @testVisible private Prospecting_Entry__c getRecord(Id i){
        return getRecord(null,i);
    }
    @testVisible private Prospecting_Entry__c getRecord(Date d){
        return getRecord(d,null);
    }
    @testVisible private Prospecting_Entry__c getRecord(Date d, Id i){
        Prospecting_Entry__c e;
        String query = 'SELECT Id, Start_Date__c, End_Date__c, ';
        query += 'of_hours_spent_prospecting_this_week__c, ';
        query += 'of_initial_meetings_set_up_this_week__c, ';
        query += 'of_prospecting_emails_sent_this_week__c, ';
        query += 'of_prospecting_calls_made_this_week__c, ';
        query += 'Status__c, OwnerId, IsSubmitted__c, ';
        query += 'IsLocked__c, IsUnlocked__c, ';
        query += 'CreatedDate, CreatedBy.Name, ';
        query += 'LastModifiedDate, LastModifiedBy.Name, ';
        query += 'Submitted_Date__c, Locked_Date__c ';
        query += 'FROM Prospecting_Entry__c WHERE ';
        if(i!=null){
            query += 'Id = :i';
        }else{
            query += 'Start_Date__c = :d AND OwnerId = :targetUser';
        }
        query += ' ORDER BY CreatedDate DESC LIMIT 1';
        try{
            e = Database.query(query);
        }catch(Exception ex){
            e = new Prospecting_Entry__c(
                Start_Date__c = d,
                End_Date__c = d+4,
                Status__c = 'Not Submitted',
                IsSubmitted__c = false,
                OwnerId = targetUser
            );
        }
        return e;
    }

    // return the url for the current week/user
    @testVisible private PageReference getBasePageRef(){
        PageReference p = Page.Prospecting;
        p.getParameters().put('user',targetUser);
        p.getParameters().put('date',String.valueOf(entry.Start_Date__c));
        return p;
    }

    // save the entry record, and reset the page state
    @testVisible private void saveRecord(){ 
        try{
            upsert entry;
            mode='view';
            entry = getRecord(entry.Id);
        }catch(Exception e){
            ApexPages.addMessages(e);
        }
    }

    // Public methods

    // unlock the record to re-edit it
    public void doUnlock(){
        if(!isManager){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have permissions to unlock this record.'));
            return;
        }
        entry.IsLocked__c = false;
        entry.IsSubmitted__c = false;
        entry.IsUnlocked__c = true;
        saveRecord();
    }

    // re-lock the record after it being unlocked
    public void doRelock(){
        entry.IsSubmitted__c = true;
        entry.IsLocked__c = true;
        entry.IsUnlocked__c = false;
        saveRecord();
        doRefresh = true;
        refreshUrl = getBasePageRef().getUrl();
    }

    // go into edit mode
    public void doEdit(){ 
        mode='edit'; 
    }

    // save the record
    public void doSave(){ 
        entry.Status__c = 'Not Submitted';
        saveRecord();
    }

    // submit and save the record
    public void doSubmit(){ 
        if(!canSubmit){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You may not submit at this time'));
            return;
        }
        entry.Status__c = 'Submitted';
        saveRecord();
    }

    // go back into view mode, and forget any changes made
    public void doCancel(){ 
        mode='view';
        if(entry.Id!=null){
            entry = getRecord(entry.Id);
        }else{
            entry = getRecord(entry.Start_Date__c);
        }
    }

}
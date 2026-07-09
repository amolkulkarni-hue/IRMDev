/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   BillingsToBoBCoverage_Log (Class)
**
** PURPOSE
**   Records what happens during the operation of the BillingsToBoBCoverage
**   batch job sequence bundle.  The following types of logging are supported:
**     newEntry     - General logging of textual content.
**     newException - Records details when an exception is caught.
**     newTrace     - Special "lightweight" (minimized DML) logging intended  
**                    for use as performance instrumentation, in terms of
**                    recording elapsed time between various execution points
**                    (performance instrumentation).  Operates by accumulating 
**                    text strings into a long buffer until traceFlush() is 
**                    called, at which time they are all stored into a single
**                    log entry.
**
**   This logging capability is intended to supplement rather than replace the
**   standard Force.com Debug Logs.  Typically its value-add is to help draw the 
**   developer's attention to the right spot in Apex code to look for a problem, at 
**   which point the more powerful and detailed diagnostic capabilities of the Debug 
**   Logs can be applied to help resolve it.  But unlike the Debug Logs's known
**   limitations, this class can:
**     a. be applied to an unlimited number of sessions (users) simultaneously,
**     b. is effectively unlimited in persistent capacity, and 
**     c. can take initiative to notify support personnel promptly but selectively 
**        when significant conditions occur. 
**
** NOTES
**   Expected invocation formats:
**     BillingsToBoBCoverage_Log logger = new BillingsToBoBCoverage_Log(customSetting);
**     logger.newEntry(module, significance, message, details, messageLimit);
**     logger.newException(module, message, gripe);
**     logger.logFlush();
**     logger.logPendingSize();
**     logger.newTrace(waypoint);
**     logger.traceFlush();
**     logger.tracePendingSize();
**     setLogImmediate(value);
**     setJobId(handle);
**     getJobId();
**     gateOpen(value);
**
**   Potential log Significance levels are:
**     Info      := Routine (e.g. start and stop)
**     Unusual   := Out of the ordinary, but probably NOT a problem
**     Warning   := Out of the ordinary, and probably IS a problem
**     Error     := Definitely a problem
**     Debug     := Optional level of greater detail for troubleshooting
**     Gated     := Optional Debug level, conditional on gateOpen() setting
**     Alarm     := Push a notification to support
**
**   The Custom Setting field BillingsToBoBCoverageJoins__c.Log_Debug_Enabled__c
**   determines whether the "Debug" significance level is allowed or filtered out.
**
**   Potential message limit values are:
**       -1 := Unlimited
**        0 := Disabled
**      > 0 := Only log at most this number of messages of that type; the message
**             meeting this cap will be flagged with " ** MESSAGE LIMIT **"
**
**   When enabled, the Log Immediate option can cause individual newEntry() or 
**   newException() records to be stored immediately via a DML insertion.  If disabled
**   via the setLogImmediate() method, however, then new entries are kept in a List<>
**   for subsequent bulkified insertion via the logFlush() method.  
**     ** Disabling Log Immediate decreases the chances of experiencing a governor DML 
**        statement limit exception, but also increases the risk of losing significant 
**        debug information if logFlush() isn't executed before a governor violation
**        causes the in-memory log entries to be lost. 
**     ** By default, log entries of significance levels "Info", "Unusual" and "Debug"
**        are bulkified, while "Warning" and "Error" entries are stored immediately.
**     ** newTrace() entries, however, are always bulkified (although in a simpler fashion).
**
** Potential Enhancements
**   1. Get default settings from dedicated Custom Setting BillingsToBoB_Log__c.
**   1. Add an email notification feature.  Would need tight controls to prevent sending
**      an annoying number of messages; perhaps by adding an emailLimit parameter 
**      (0 := never) to the calling args of newEntry() and newException().  The email's 
**      distro should be added as a field in Custom Setting BillingsToBoBCoverageJoins__c.
**
** BUNDLE SUMMARY
**   See class BillingsToBoBCoverage_Master.
**
************************************************************************/

/* Commenting the entire code as part of Gitlab #24446 */

public virtual class BillingsToBoBCoverage_Log {
    public BillingsToBoBCoverage_Log(){
        
    }
/*
    // constants
    private final String  THROWN_EXCEPTION_SIGNIFICANCE = 'Error';  // treat all exceptions as errors
    private final Integer MAX_MESSAGES_TO_HOLD          = 100;      // flush holdingPen once it contains this many   
    private final Integer MAX_STRING                    = 32767;    // maximum length of long text field 
    
    // Significance levels
    public enum Season { Info, Unusual, Warning, Error, Debug, Gated, Alarm }
            
    // access Custom Settings
    private BillingsToBoBCoverageJoins__c settings; 
    // keeps track of how many times each message topic has been logged
    protected Map<String, Integer> messageLimitCounts;
    
    // parent batch job ID
    private String batchJobName = ''; 
    
    // if true then "Debug" (detailed) level log entries are allowed   
    protected Boolean debugEnabled = false;
    
    // whether Gated-level log entries are passed
    private Boolean gateIsOpen = false;
    
    // storage for bulkifying entries
    protected Map<String, Boolean>           logImmediate;
    protected List<BoB_Coverage_Join_Log__c> holdingPen;
    
    // temporary store for not-yet-inserted trace log entries
    private String traceLog  = '';
    private Long   lastTrace = 0;   

    
    //-----------------------------------------------------------------------------------
    // constructor
    
    public BillingsToBoBCoverage_Log() {}
         
    public BillingsToBoBCoverage_Log (String customSetting) {        
        // access the custom settings
        if (customSetting != null) {
            settings = BillingsToBoBCoverageJoins__c.getInstance(customSetting);
            system.debug('settings: ' + settings);
            if(settings != null)
              debugEnabled = settings.Log_Debug_Enabled__c; 
        }   
                
        // keep track of message topic usage, for enforcing limits
        messageLimitCounts = new Map<String, Integer>(); 
        
        // bulkization storage
        holdingPen = new List<BoB_Coverage_Join_Log__c>();
        
        // set up the default Log Immediate settings
        // see also setLogImmediate() below
        logImmediate = new Map<String, Boolean>{ 'Info' => false,'Unusual' => false, 'Warning' => true,'Error'  => true,  'Debug' => false};   
        
    } // BillingsToBoBCoverage_Log   

    
    //-----------------------------------------------------------------------------------
    // create a new log entry  
    public void newEntry (String module, String significance, String message, 
        String details, Integer messageLimit) {
            
        // snapshot the current time immediately
        DateTime timestamp = DateTime.now();
        
        // only allow Gated-level entries if enabled (gate is open)
        if (significance == 'Gated'  &&  !gateIsOpen)
            return;
        
        // has a limit been imposed on this particular message topic?
        if (messageLimit >= 0) {
            // is this message topic disabled?
            if (messageLimit == 0)
                return;
                
            // don't already have a counter for this message topic?
            if (!messageLimitCounts.containsKey(message))
                messageLimitCounts.put(message, 0);
                
            // has this message topic's limit been reached?
            if (messageLimitCounts.get(message) >= messageLimit)
                return;
            else {
                // track how many times this message has been passed
                messageLimitCounts.put(message, messageLimitCounts.get(message) + 1);
                
                // is this going to be the last allowed appearance of this message topic?
                if (messageLimitCounts.get(message) == messageLimit - 1)
                    message += ' ** MESSAGE LIMIT **';
            }
        }
        
        // is this entry either not Debug-level, or is Debug-level enabled?
        if (significance != 'Debug'  ||  debugEnabled) {                              
            try {
                // construct a new log entry
                BoB_Coverage_Join_Log__c newbie = new BoB_Coverage_Join_Log__c();
                
                newbie.Module__c       = module;
                newbie.Timestamp__c    = timestamp.format('yyyy/MM/dd HH:mm:ss.SSS');
                newbie.Job_Name__c     = batchJobName;
                newbie.Significance__c = significance;
                newbie.Message__c      = message;
                newbie.Details__c      = details.left(MAX_STRING);
                
                // log right away, or wait until logFlush()?
                if (logImmediate.get(significance))               
                    insert newbie;
                else {
                    holdingPen.add(newbie);
//** /               system.debug('holdingPen: ' + holdingPen.size());
                }
            }
            catch (Exception curse) {
                system.debug('_Log newEntry insert failed: ' + curse);
            }
        } 
        
        // keep holdingPen small enough to avoid any potential heap size violations
        if (holdingPen.size() >= MAX_MESSAGES_TO_HOLD)
            logFlush();
              
    } // newEntry    

    
    //-----------------------------------------------------------------------------------
    // create a new log entry based on an exception 
    public void newException (String module, String message, Exception gripe) {     
                          
        // snapshot the current time immediately, with millisecond resolution
        String highResTime = DateTime.now().format('yyyy/MM/dd HH:mm:ss.SSS');
                              
        try {
            // construct a new log entry
            BoB_Coverage_Join_Log__c newbie = new BoB_Coverage_Join_Log__c();
            
            newbie.Module__c       = module;
            newbie.Timestamp__c    = highResTime;        
            newbie.Job_Name__c     = batchJobName;
            newbie.Significance__c = THROWN_EXCEPTION_SIGNIFICANCE;
            newbie.Message__c      = message;
            if (gripe != null) {
                newbie.Details__c = 'Exception Type: '  + gripe.getTypeName() +
                                    ' |Message: '       + gripe.getMessage() +
                                    ' |Line Number: '   + gripe.getLineNumber() +
                                    ' |Stack Trace: '   + gripe.getStackTraceString();
            }
            else
                newbie.Details__c = '';
//** /       system.debug('details: ' + newbie.Details__c);               
                
            // log right away, or wait until logFlush()?
            if (logImmediate.get(THROWN_EXCEPTION_SIGNIFICANCE))               
                insert newbie;
            else
                holdingPen.add(newbie);
        }
        catch (Exception curse) {
            system.debug('_Log newException insert failed: ' + curse);
        }
        
        // keep holdingPen small enough to avoid any potential heap size violations
        if (holdingPen.size() >= MAX_MESSAGES_TO_HOLD)
            logFlush();        
                
    } // newException      
        
    
    //-----------------------------------------------------------------------------------
    // insert all new/pending log entries into the database
    public void logFlush () { 
        system.debug('logFlush: ' + holdingPen.size());
            
        // any log entries in volatile storage?
        if (holdingPen.size() > 0) {
            try {               
                insert holdingPen;
            
                // and start over
                holdingPen.clear();                
            }
            catch (Exception curse) {
                system.debug('_Log logFlush insert failed: ' + curse);
            }           
        }
        return; 
        
    } // logFlush     
        
    
    //-----------------------------------------------------------------------------------
    // determine how many log entries are pending in the holdingPen
    public Integer logPendingSize () { 
        return holdingPen.size();
        
    } // logPendingSize 
    
    
    //-----------------------------------------------------------------------------------
    // add a new entry to the (lightweight) trace log 
    public void newTrace (String waypoint) { 
        // compose this trace log entry
        Long thisTrace = DateTime.now().getTime();
        traceLog += waypoint + ' __ when ' + String.valueOf(thisTrace) + ', delta ' + 
            String.valueOf(thisTrace - lastTrace) + '\n';
        lastTrace = thisTrace;
        
        // is the current trace log entry getting full?
        if (traceLog.length() > (MAX_STRING - 100))   // max is 32,768
            traceFlush();
        return; 
        
    } // newTrace  
        
    
    //-----------------------------------------------------------------------------------
    // insert all new trace logentries into the database
    public void traceFlush () { 
        system.debug('traceFlush: ' + traceLog.length());
        
        // any traces in volatile storage?
        if (traceLog.length() > 0) {
            // save the accumulated trace log entries            
            newEntry('_Log', 'Debug', 'traceLog', traceLog.left(MAX_STRING), -1);
            
            // and start over
            traceLog = '';
        }
        return; 
        
    } // traceFlush 
        
    
    //-----------------------------------------------------------------------------------
    // determine quantity of trace text not yet inserted
    public Integer tracePendingSize () { 
        return traceLog.length();
        
    } // tracePendingSize    
          
    
    //-----------------------------------------------------------------------------------
    // enable/disable immediate inserting of log entries based on Significance level
    public void setLogImmediate (Boolean lInfo, Boolean lUnusual, Boolean lWarning, 
        Boolean lError, Boolean lDebug) {  
                   
        logImmediate.put('Info',    lInfo); 
        logImmediate.put('Unusual', lUnusual);  
        logImmediate.put('Warning', lWarning);
        logImmediate.put('Error',   lError);
        logImmediate.put('Debug',   lDebug);
        logImmediate.put('Gated',   lDebug);
        
 /** /   system.debug('_Log setLogImmediate: ' + logImmediate);        
        
    } // setLogImmediate      

    
    //-----------------------------------------------------------------------------------
    // receive the overall AsyncApexJob Id 
    public void setJobId (String handle) { 
        system.debug('_Log new jobId: ' + handle);
        batchJobName = handle; 
        
    } // setJobId     

    
    //-----------------------------------------------------------------------------------
    // provide the current overall AsyncApexJob Id as has been reported via setJobId()
    public String getJobId () { 
        return batchJobName; 
        
    } // getJobId      

    
    //-----------------------------------------------------------------------------------
    // whether to allow Gated-level log entries
    public Boolean gateOpen (Boolean isOpen) { 
        Boolean gateWasOpen = this.gateIsOpen;
        this.gateIsOpen = isOpen; 
//** /   system.debug('gateIsOpen: ' + this.gateIsOpen);        
        return gateWasOpen;
        
    } // gateOpen      
*/    
} // BillingsToBoBCoverage_Log
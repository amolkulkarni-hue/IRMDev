public class triggerFlowControl {
/**
Auhtor       : Nathan Shinn
Company      : Fujitsu America
Created Date : 11/05/2010
Description  : Use this method to control the number of times a trigger can fire
               by calling triggerRunCount() which will set the number of times based on 
               the string (most likely tigger name) passed into it and return the number
               of times the method was called using that string for a given transaction.
               
               Use resetTriggerRunCount() so set the count back to 0./ This is useful in
               test methods where you may want to fire the trigger multiple times.
*/

    public static map<String,Integer> triggerCounts = null;    
    public static boolean controlEnabled = false;
    
    public static map<String,set<string>> triggerCounts2 = null;    
    public static boolean controlEnabled2 = false;
    
    public static void resetTriggerRunCount(String triggerName)
    { 
      if(triggerCounts != null)
      {
        if(triggerCounts.get(triggerName) != null)
        {
          Integer trgCnt = triggerCounts.get(triggerName);
          triggerCounts.put(triggerName, 0);          
        } 
      }     
    
    }
    
    public static Integer triggerRunCount(String triggerName)
    {
      
      if(!controlEnabled)
        return 0;
        
      Integer trgCnt = 0;
      
      if(triggerCounts == null)
        triggerCounts = new map<String,Integer>();
      
      if(triggerCounts.get(triggerName) != null)
      {
        trgCnt = triggerCounts.get(triggerName)+1;
        triggerCounts.put(triggerName, trgCnt);
      }      
      else
      {
        triggerCounts.put(triggerName, 1);
        trgCnt = 1;
      }
      return trgCnt;
    }
    
    
    public static Integer triggerRunCountBulk(String triggerName, set<String> Ids)
    {
      
      if(!controlEnabled2)
        return 0;
        
      Integer trgCnt = 0;
      
      if(triggerCounts2 == null)
        triggerCounts2 = new map<String,set<string>>();
        
      if(triggerCounts == null)
        triggerCounts = new map<String,Integer>();
      
      if(triggerCounts2.get(triggerName) != null)
      {
        set<string> theseIds = new set<string>();
        theseIds.addAll(triggerCounts2.get(triggerName));
        
        if (theseIds.containsAll(Ids))
        {          
            trgCnt = triggerCounts.get(triggerName)+1;
            triggerCounts.put(triggerName, trgCnt);
        }
        else
        {          
            theseIds.addAll(Ids);  
            triggerCounts2.put(triggerName,theseIds);
            triggerCounts.put(triggerName, 1); 
        }
      }      
      else
      {
        
        triggerCounts2.put(triggerName, Ids);
        trgCnt = 1;
        triggerCounts.put(triggerName, trgCnt);
      }
      return triggerCounts.get(triggerName);
    }
    
    public static void setControlEnabled(boolean enabled)
    {
      controlEnabled = enabled;
      controlEnabled2 = enabled;
    }

  //test method
  
}
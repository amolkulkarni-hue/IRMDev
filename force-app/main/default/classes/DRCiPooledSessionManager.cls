public class DRCiPooledSessionManager {

    /*  
     Note: this is the static handle to the single class reference.  
     Its set accessor is made private to dis-allow any modifications to the reference   
   */ 
 
   private static DRCiPooledSessionManager self;  

   public boolean isBusy = false;
      

      
   // NOTE: the constructor is marked "PRIVATE"  
   // so that no Apex code outside this class can create   
   // the instance  
   private  DRCiPooledSessionManager() {  
    
   }  
   
   public static DRCiPooledSessionManager getInstance() {  

     // "self" is NOT NULL, that means we already did   
     // required initalization, so just return.  

     if (self != null)
       return self;  
         
     // Create the single instance now.   
      self = new DRCiPooledSessionManager();  
      return self; 
   }   
   public  void setBusyTransaction() {  
      this.isBusy = true;  
   } 
   
   public  void releaseBusyTransaction() {  
      this.isBusy = false;  
   }
   
   public  boolean isBusyTransaction ()
   {
   	  return this.isBusy;
   }
    

  // TEST METHOD  
     
 

}
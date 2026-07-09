/**  
       * Name:IRM_SC_FetchNumberOfViews 
       * Description: Class is the controller for updating the CaseViews Visual force(Inline)Page on the case detail Page
       * Copyright: HCL Technologies
       * Author: Ninad Thaware
       * Modification Log: Created:20-Mar-2012
**/



public class IRM_SC_FetchNumberOfViews 
{

  //Variable Declaration
private final Case currentCase;
public final Id userRecordID;
private FINAL Integer COUNTER = 1;
public String numberOfViews;
public Case caseOwner;
Public Boolean ownerType;

 public IRM_SC_FetchNumberOfViews(ApexPages.StandardController controller) 
        {
               //Get running user Id and Case Id
              this.currentCase = (Case)controller.getRecord();
              userRecordID=UserInfo.getUserId();
              caseOwner=[select ownerId,owner.type from Case where id=:this.currentCase.id];
              List<UserRole> cSR = [Select Name, Id From UserRole where Name LIKE '%CSR%'];
              System.debug(cSR+'cSR');
              id uRoleId = UserInfo.getUserRoleId();
              System.debug(uRoleId+'User Role Id');
              boolean isCsr;
              for(UserRole uRol:cSR)
              {
                    if(uRol.id==uRoleId)
                    {
                    System.debug(isCsr+'Boolean CSR');
                      isCsr=true;
                      break;
                    }  
                    else
                    {
                      isCsr=false;
                    }
                             
              }
              
           if (caseOwner.owner.type=='Queue'&isCsr==true)
                  {
                   ownerType=true;
                  
                  }
                  else
                  {
                   ownerType=false;
                  }
                  
         }
   
  Public boolean getOwnerType()
        {
              return ownerType;
        }
  
  public String getNumberOfViews() 
        { 
               return numberOfViews;
        } 
           
   public void setLastView() 
        {
    
    
     
            IME_SC_Case_View_Info__c previousLastView;
          //Update the Case View object if it already exists
      
             {       
                  try
                       {
                        previousLastView= [SELECT Obj.IME_SC_Counter__c ,Obj.Id FROM IME_SC_Case_View_Info__c Obj WHERE 
                                                  Obj.IME_SC_User__c = :userRecordID and Obj.IME_SC_Case__c = :this.currentCase.Id limit 1];
                              previousLastView.IME_SC_Counter__c = previousLastView.IME_SC_Counter__c + 1;
                              update previousLastView;
                        }
           catch(System.QueryException QE)
                        {
                      
                        previousLastView= new   IME_SC_Case_View_Info__c (IME_SC_Case__c= this.currentCase.Id,
                                                             IME_SC_User__c= userRecordID,IME_SC_Counter__c = COUNTER );
                                                           
                        insert previousLastView;
                        System.debug(QE.getMessage());
                         }  
           numberOfViews= String.valueOf(previousLastView.IME_SC_Counter__c);
            }
       }
}
/****************************** 
   Developer Name    : Venkateswarlu Avula and Apurva Dutta
   
   Date              : 1/22/14
   
   Company Name      : Iron Mountain Service India Pvt. Ltd.
   
   Purpose           : This trigger is used for doing all the calculations on IME Contracts and IME Addendums.
   
   Test Class        :  Apex Class  : Test_ContractCusAccDuplicate
   
   Case Number       : 01590130 and 02236864
   
   /**************************************
 //  Change log        
 //  Date: 02/06/2015
 //  Developer: Sandhya Ramesh
 //  Case Number: 03219799 
 //  Description: Contract Renewal Date does not get updated by batch class if Renewal date is today.          
 //  
 //                      
 //                                         
    * Modified By: Vinutha Iyengar on 15-October-2016
    *       Case # 02586922
    *       Also removed hard coding of Record type name instead used custom setting - IME_Record_Types_For_Contracts__c
    *                                                                     
********************************/

trigger contractDataUpdate on Contract(before insert, before Update)
{
 /* List<String> rtId = new List<String>();
  Map<String, String> rtMap = new Map<String, String>();
  List<String> conIdlst = new List<String>();
  List<Contract> coLst = new List<Contract>();  
  
  
  for(Contract con:Trigger.New)
  {
    rtId.add(con.RecordTypeId);
    
    if(con.IME_Annual_Value_Opportunities__c != null)
    {
        conIdlst.add(con.Id);
    }
  }
  List<RecordType> rtypeList = [Select id, name from RecordType where Id IN: rtId];
  List<IME_Record_Types_For_Contracts__c> ContractRecordTypes = IME_Record_Types_For_Contracts__c.getall().values();    
  Boolean evaluateDates = false;
      
  for(RecordType rt :rtypeList)
  {
        rtMap.put(rt.Id, rt.Name);
  }
  if( trigger.isUpdate || trigger.isInsert)
  {
      system.debug('isUpdate--Contract--'+trigger.isUpdate);
      system.debug('isInsert--Contract--'+trigger.isInsert);
        if(trigger.isBefore)
        {
        system.debug('isBefore--Contract--'+trigger.isBefore);
            for(Contract objContr : trigger.new)
            {  
                evaluateDates = false;
                for(IME_Record_Types_For_Contracts__c RecType : ContractRecordTypes)
                {
                  if(RecType.name==(rtMap.get(objContr.RecordTypeId)))
                    {
                        evaluateDates=true;
                    }
                } 
                system.debug('evaluateDates');     
                if(evaluateDates== true)
                {
                     system.debug('+++++++++++ renewal < today +++++++');  
                     system.debug('++++++++++  objContr.IME_Contract_Renewal_Date__c +++' + objContr.IME_Contract_Renewal_Date__c); 
                              
                    if(objContr.IME_Contract_Term_Type__c == 'Fixed term')
                    {
                        if(objContr.ContractTerm != null )
                        {
                            Date ConEDate;
                            Date ReDate;
                            Date ExpDate;
                            Date ConEDateFixedTerm;
                            if(objContr.IM_Renewal_Term__c != null)
                            {
                                ConEDate = objContr.StartDate.addMonths(Integer.ValueOf(objContr.ContractTerm + objContr.IM_Renewal_Term__c));
                                ReDate =objContr.StartDate.addMonths(Integer.ValueOf(objContr.ContractTerm));
                                objContr.IME_Contract_End_Date__c = ConEDate.addDays(-1);
                                objContr.IME_Contract_Renewal_Date__c = ReDate.addDays(-1);
                                if(objContr.IME_Expiration_Notice_days__c!= null)
                                    {
                                        ExpDate = objContr.IME_Contract_Renewal_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                                        objContr.IME_Expiration_Notice_Date__c = ExpDate;
                                        ConEDateFixedTerm = objContr.IME_Contract_End_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                                        objContr.IME_Contract_End_Date_Fixed_Term__c = ConEDateFixedTerm;
                                    }
                                else
                                    {
                                        objContr.IME_Expiration_Notice_Date__c = null;
                                    }
                            }
                            else
                            {
                                ConEDate = objContr.StartDate.addMonths(Integer.ValueOf(objContr.ContractTerm + 0));
                                objContr.IME_Contract_End_Date__c = ConEDate.addDays(-1);
                                objContr.IME_Contract_Renewal_Date__c = null;
                                if(objContr.IME_Expiration_Notice_days__c!= null)
                                    {
                                        ExpDate = objContr.IME_Contract_End_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                                        objContr.IME_Expiration_Notice_Date__c = ExpDate;
                                        ConEDateFixedTerm = objContr.IME_Contract_End_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                                        objContr.IME_Contract_End_Date_Fixed_Term__c = ConEDateFixedTerm;
                                    }
                                else
                                    {
                                        objContr.IME_Expiration_Notice_Date__c = null;
                                    }
                            }
                        }
                    }
                    else if(objContr.IME_Contract_Term_Type__c == 'Evergreen')
                    {
                        system.debug('+++++++++++ Evergreen +++++++');
                        
                        objContr.IME_Contract_End_Date__c =null;
                        Date dtEver;
                        Date expDate;
                        Integer diffDates;
                        Date addedDate;
                        Date todayDate = System.Today();
                        Date reDate;
                        Date renewDate;
                        Date myDate;
                        Date finalRenDate;
                        if(objContr.ContractTerm !=null)
                        {
                            system.debug('+++++++++++ contract term ! null +++++++');
                            system.debug('++++++++++++ contract start date = '+objContr.startdate);
                            dtEver= objContr.startdate.addmonths(Integer.Valueof(objContr.ContractTerm));
                            objContr.IME_Contract_Renewal_Date__c=dtEver;
                            if(objContr.IME_Contract_Renewal_Date__c>system.today()){
                                system.debug('+++++++++++ renewal > today +++++++');
                                objContr.IME_Contract_Renewal_Date__c=dtEver.adddays(-1);
                                 if(objContr.IME_Expiration_Notice_days__c!=null)
                            {
                                expDate = objContr.IME_Contract_Renewal_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                                objContr.IME_Expiration_Notice_Date__c = expDate;
                            }
                            else
                            {
                                objContr.IME_Expiration_Notice_Date__c = null;
                            }
                                }
                            Integer monthsDiff, monthsMod;
                            DAte date0, date1, date2, date3;
                            System.debug('System.Today()='+System.Today());
                            System.debug('objContr.IME_Contract_Renewal_Date__c='+objContr.IME_Contract_Renewal_Date__c);
                            if(objContr.IM_Renewal_Term__c == null)
                            {
                                objContr.IME_Contract_Renewal_Date__c =null;
                                objContr.IME_Expiration_Notice_Date__c =null;
                            } 
                             else if(objContr.IME_Contract_Renewal_Date__c == System.Today())
                            {
                                system.debug('+++++++++++ renewal = today +++++++');
                                if(objContr.IM_Renewal_Term__c != null)
                                    {
                                        Date dt = System.Today().addMonths(Integer.ValueOf(objContr.IM_Renewal_Term__c));
                                        Date reNewDateToday;
                                        reNewDateToday= Date.newInstance(dt.year(), dt.month(), objContr.StartDate.day());
                                        system.debug('+++++++++++ reNewDateToday +++++++'+reNewDateToday );
                                        objContr.IME_Contract_Renewal_Date__c = reNewDateToday.adddays(-1);
                                        system.debug('+++++++++++ new obj renewal is +++++++'+objContr.IME_Contract_Renewal_Date__c);
                                        if(objContr.IME_Expiration_Notice_days__c!=null)
                                        {
                                            objContr.IME_Expiration_Notice_Date__c = objContr.IME_Contract_Renewal_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                                        }
                                        else
                                        {
                                            objContr.IME_Expiration_Notice_Date__c = null;
                                        }    
                                    }
                            }  
                            
                            else if(objContr.IME_Contract_Renewal_Date__c<System.Today() && objContr.IM_Renewal_Term__c==0)
                            {
                              system.debug('+++++++++++ renewal < today and renewal term = 0 +++++++');
                              Date reOldDate;
                              reOldDate = objContr.StartDate.addMonths(Integer.ValueOf(objContr.ContractTerm));
                              objContr.IME_Contract_Renewal_Date__c =  reOldDate.adddays(-1);
                               if(objContr.IME_Expiration_Notice_days__c!=null)
                                {
                                    expDate = objContr.IME_Contract_Renewal_Date__c - 
                                                Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                                    objContr.IME_Expiration_Notice_Date__c = expDate;
                                }
                               else
                                {
                                    objContr.IME_Expiration_Notice_Date__c = null;
                                }
                            }      
                                                       
                             else if(objContr.IME_Contract_Renewal_Date__c<System.Today()){
                            
                              /**** Comment below for demo ****/ 
                              
                            /* monthsDiff=system.today().monthsBetween(objContr.IME_Contract_Renewal_Date__c);
                             system.debug('++++++ monthsDiff is ++++++' + monthsDiff);
                             monthsMod = math.mod(monthsDiff, Integer.Valueof(objContr.IM_Renewal_Term__c));
                             system.debug('++++++ Integer.Valueof(objContr.IM_Renewal_Term__c) ++++++ '+ Integer.Valueof(objContr.IM_Renewal_Term__c));
                             system.debug('++++++ months mod is ++++++' + monthsMod);
                             date0=system.today().addmonths(monthsMod);
                             system.debug('++++++ date 0 is ++++++' + date0);
                             date1=date0.addmonths(Integer.Valueof(objContr.IM_Renewal_Term__c));
                             system.debug('++++++ date 1 is ++++++' + date1);
                             renewDate =date.newInstance(date1.year(), date1.month(), objcontr.startdate.day());
                             system.debug('++++++ renewDate  is ++++++' + renewDate);
                             objContr.IME_Contract_Renewal_Date__c = renewDate.adddays(-1);
                             system.debug('++++++ latest renewal date is ++++++' + objContr.IME_Contract_Renewal_Date__c);
                             
                             if((objContr.IME_Contract_Renewal_Date__c) == System.Today()) {
                                system.debug('++++ contract date is today ++++ ');
                                
                                objContr.IME_Contract_Renewal_Date__c=objContr.IME_Contract_Renewal_Date__c.addMonths(integer.valueof(objContr.IM_Renewal_Term__c));
                                system.debug('++++ added temp date +++++ ' + objContr.IME_Contract_Renewal_Date__c);
                            } 
                            
                            if(objContr.IME_Contract_Renewal_Date__c.addmonths(-(integer.valueof((objContr.IM_Renewal_Term__c))))>system.today())
                                 
                             {
                                 system.debug('++++++ objContr.IME_Contract_Renewal_Date__c.addmonths(-(integer.valueof((objContr.IM_Renewal_Term__c))))>system.today() ++++++');
                                 objContr.IME_Contract_Renewal_Date__c=objContr.IME_Contract_Renewal_Date__c.addmonths(-(integer.valueof((objContr.IM_Renewal_Term__c))));
                             }
                             
                            /***** End comment block here *****/
                             
                    
                            /*********************** Demo code begins *********************/
                           /* 
                            date tempDate = date.newInstance(2015, 01, 31);
                            system.debug ('+++++ temp date is +++++ '+ tempDate);
                            monthsDiff=tempDate.monthsBetween(objContr.IME_Contract_Renewal_Date__c);
                             system.debug('++++++ monthsDiff is ++++++' + monthsDiff);
                             monthsMod = math.mod(monthsDiff, Integer.Valueof(objContr.IM_Renewal_Term__c));
                             system.debug('++++++ Integer.Valueof(objContr.IM_Renewal_Term__c) ++++++ '+ Integer.Valueof(objContr.IM_Renewal_Term__c));
                             system.debug('++++++ months mod is ++++++' + monthsMod);
                             date0=tempDate.addmonths(monthsMod);
                            
                             system.debug('++++++ date 0 is ++++++' + date0);
                             date1=date0.addmonths(Integer.Valueof(objContr.IM_Renewal_Term__c));
                             system.debug('++++++ date 1 is ++++++' + date1);
                             renewDate =date.newInstance(date1.year(), date1.month(), objcontr.startdate.day());
                             system.debug('++++++ renewDate  is ++++++' + renewDate);
                             objContr.IME_Contract_Renewal_Date__c = renewDate.adddays(-1);
                             system.debug('++++++ latest renewal date is ++++++' + objContr.IME_Contract_Renewal_Date__c);
                             system.debug('++++ temp date is +++ ' + tempDate);
                             
                             if((objContr.IME_Contract_Renewal_Date__c) == tempDate) {
                                system.debug('++++ contract date is today ++++ ');
                                
                                objContr.IME_Contract_Renewal_Date__c=objContr.IME_Contract_Renewal_Date__c.addMonths(integer.valueof(objContr.IM_Renewal_Term__c));
                                system.debug('++++ added temp date +++++ ' + objContr.IME_Contract_Renewal_Date__c);
                            } 
                        //     if(objContr.IME_Contract_Renewal_Date__c.addmonths(-(integer.valueof((objContr.IM_Renewal_Term__c))))>system.today())
                            if(objContr.IME_Contract_Renewal_Date__c.addmonths(-(integer.valueof((objContr.IM_Renewal_Term__c))))>tempDate)
                                 
                             {
                                 system.debug('++++++ objContr.IME_Contract_Renewal_Date__c.addmonths(-(integer.valueof((objContr.IM_Renewal_Term__c))))>system.today() ++++++');
                                 objContr.IME_Contract_Renewal_Date__c=objContr.IME_Contract_Renewal_Date__c.addmonths(-(integer.valueof((objContr.IM_Renewal_Term__c))));
                             }
                             */
                             /****************** Demo code ends **********************/
                            
                         /*   if(objContr.IME_Expiration_Notice_days__c!=null)
                            {
                                expDate = objContr.IME_Contract_Renewal_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                                objContr.IME_Expiration_Notice_Date__c = expDate;
                            }
                            else
                            {
                                objContr.IME_Expiration_Notice_Date__c = null;
                            }
                            }
                           
                        }
                       /* if(objContr.IM_Renewal_Term__c == null)
                        {
                            objContr.IME_Contract_Renewal_Date__c =null;
                        }                       
                       else if(objContr.IME_Contract_Renewal_Date__c == System.Today())
                        {
                            if(objContr.IM_Renewal_Term__c != null)
                            {
                                Date dt = System.Today().addMonths(Integer.ValueOf(objContr.IM_Renewal_Term__c));
                                Date reNewDateToday;
                                reNewDateToday= Date.newInstance(dt.year(), dt.month(), objContr.StartDate.day());
                                objContr.IME_Contract_Renewal_Date__c = reNewDateToday.adddays(-1);
                                objContr.IME_Expiration_Notice_Date__c = objContr.IME_Contract_Renewal_Date__c - Integer.ValueOf(objContr.IME_Expiration_Notice_days__c);
                            }
                        }  */ 
                 /*   }
                    else if(objContr.IME_Contract_Term_Type__c == 'Evergreen (open rolling)')
                    {
                        objContr.IME_Contract_End_Date__c =null;
                        objContr.IME_Contract_Renewal_Date__c=null;
                       // if(objContr.IME_Expiration_Notice_days__c==null)
                        //    {
                                objContr.IME_Expiration_Notice_Date__c = null;
                          //  }
                    }
                    
                    if(objContr.IME_Fixed_Pricing_Period_months__c != null)
                    {
                        Date dtFixPr = objContr.StartDate.addMonths(Integer.ValueOf(objContr.IME_Fixed_Pricing_Period_months__c));
                        objContr.IME_End_of_Fixed_Pricing_Period__c = dtFixPr.addDays(-1);
                    }
                    if(objContr.IME_Copy_to_all__c  && (String.isNotBlank(objContr.IME_Price_Increase_Type_Product_Sales__c) || String.isNotBlank(objContr.IME_Price_Increase_Type_Services__c ) || String.isNotBlank(objContr.IME_Price_Increase_Type_Transport__c)
                                    || String.isNotBlank(objContr.IME_Index_Product_Sales__c) || String.isNotBlank(objContr.IME_Index_Services__c) || String.isNotBlank(objContr.IME_Index_Transport__c )
                                    || String.isNotBlank(String.ValueOf(objContr.IME_Capped_Percentage_Product_Sales__c)) || String.isNotBlank(String.ValueOf(objContr.IME_Capped_Percentage_Services__c))|| String.isNotBlank(String.ValueOf(objContr.IME_Capped_Percentage_Transport__c))
                                    || String.isNotBlank(String.ValueOf(objContr.IME_Fixed_Pricing_Period_months_Prod_S__c)) || String.isNotBlank(String.ValueOf(objContr.IME_Fixed_Pricing_Period_months_Transp__c))|| String.isNotBlank(String.ValueOf(objContr.IME_Fixed_Pricing_Period_months_Services__c))
                                    || String.isNotBlank(String.ValueOf(objContr.IME_End_of_Fixed_Pricing_Period_Prod_S__c)) || String.isNotBlank(String.ValueOf(objContr.IME_End_of_Fixed_Pricing_Period_Transp__c))|| String.isNotBlank(String.ValueOf(objContr.IME_End_of_Fixed_Pricing_Period_Services__c))
                                    || String.isNotBlank(String.ValueOf(objContr.IME_Special_Terms_Other_Services__c)) || String.isNotBlank(String.ValueOf(objContr.IME_Special_Terms_Other_Transp__c))|| String.isNotBlank(String.ValueOf(objContr.IME_Special_Terms_Other_Prod_S__c))
                                                       ) )
                    {
                        objContr.addError('Price Increase Method - Services / Transport / Product Sales are populated. You can\'t use \'Copy To All\'. Please amend manually.');
                    }
                             
                                          
                    }
                
                 //Price Increase Method - Copy to all 
                if(objContr.IME_Copy_to_all__c)
                    {               		
                        if(objContr.IME_Price_Increase_Type_Storage__c != null)
                        {
                            objContr.IME_Price_Increase_Type_Product_Sales__c= objContr.IME_Price_Increase_Type_Storage__c;
                            objContr.IME_Price_Increase_Type_Services__c = objContr.IME_Price_Increase_Type_Storage__c;
                            objContr.IME_Price_Increase_Type_Transport__c = objContr.IME_Price_Increase_Type_Storage__c;
                            objContr.IME_Copy_to_all__c = false;    
                        }
                        if(objContr.IME_Index_Storage__c!=null)
                        {
                            objContr.IME_Index_Product_Sales__c = objContr.IME_Index_Storage__c;
                            objContr.IME_Index_Services__c = objContr.IME_Index_Storage__c;
                            objContr.IME_Index_Transport__c = objContr.IME_Index_Storage__c;
                            objContr.IME_Copy_to_all__c = false;
                            
                        }
                        if(objContr.IME_Capped_Percentage_Storage__c != null)
                        {
                            objContr.IME_Capped_Percentage_Product_Sales__c = objContr.IME_Capped_Percentage_Storage__c;
                            objContr.IME_Capped_Percentage_Services__c = objContr.IME_Capped_Percentage_Storage__c;
                            objContr.IME_Capped_Percentage_Transport__c = objContr.IME_Capped_Percentage_Storage__c;
                            objContr.IME_Copy_to_all__c = false;
                        }    
                        
                        system.debug('In IME_Copy_to_all__c');
                        if(objContr.IME_Fixed_Pricing_Period_months_Storage__c != null)
                        {
                            system.debug('Copying Fixed_Pricing_Period_months_Prod_S__c');
                            objContr.IME_Fixed_Pricing_Period_months_Prod_S__c = objContr.IME_Fixed_Pricing_Period_months_Storage__c;
                            objContr.IME_Fixed_Pricing_Period_months_Services__c = objContr.IME_Fixed_Pricing_Period_months_Storage__c;
                            objContr.IME_Fixed_Pricing_Period_months_Transp__c =objContr.IME_Fixed_Pricing_Period_months_Storage__c;
                            objContr.IME_Copy_to_all__c = false;
                        }
                        if(objContr.IME_End_of_Fixed_Pricing_Period_Storage__c != null)
                        {
                            system.debug('Copying End_of_Fixed_Pricing_Period_Storage__c');
                            objContr.IME_End_of_Fixed_Pricing_Period_Prod_S__c = objContr.IME_End_of_Fixed_Pricing_Period_Storage__c;
                            objContr.IME_End_of_Fixed_Pricing_Period_Services__c = objContr.IME_End_of_Fixed_Pricing_Period_Storage__c;
                            objContr.IME_End_of_Fixed_Pricing_Period_Transp__c = objContr.IME_End_of_Fixed_Pricing_Period_Storage__c;
                            objContr.IME_Copy_to_all__c = false;
                        }
                        if(objContr.IME_Special_Terms_Other_Storage__c != null)
                        {
                            system.debug('Copying Special_Terms_Other_Storage__c');
                            objContr.IME_Special_Terms_Other_Prod_S__c = objContr.IME_Special_Terms_Other_Storage__c;
                            objContr.IME_Special_Terms_Other_Services__c = objContr.IME_Special_Terms_Other_Storage__c;
                            objContr.IME_Special_Terms_Other_Transp__c = objContr.IME_Special_Terms_Other_Storage__c;
                            objContr.IME_Copy_to_all__c = false;
                        }    
               }
           
                if(objContr.IME_Fixed_Pricing_Period_months_Storage__c != null && objContr.IME_Original_Contract_Start_Date__c != null)
                {
                    date FixedDate = objContr.IME_Original_Contract_Start_Date__c;
                    Integer months = Integer.valueOf(objContr.IME_Fixed_Pricing_Period_months_Storage__c);
                    date EndFixedDate = FixedDate.addMonths(months);
                    objContr.IME_End_of_Fixed_Pricing_Period_Storage__c = EndFixedDate;
                }
                
                if(objContr.IME_Fixed_Pricing_Period_months_Services__c != null && objContr.IME_Original_Contract_Start_Date__c != null)
                {
                    date FixedDate = objContr.IME_Original_Contract_Start_Date__c;
                    Integer months = Integer.valueOf(objContr.IME_Fixed_Pricing_Period_months_Services__c);
                    date EndFixedDate = FixedDate.addMonths(months);
                    objContr.IME_End_of_Fixed_Pricing_Period_Services__c = EndFixedDate;
                }
                
                if(objContr.IME_Fixed_Pricing_Period_months_Prod_S__c != null && objContr.IME_Original_Contract_Start_Date__c != null)
                {
                    date FixedDate = objContr.IME_Original_Contract_Start_Date__c;
                    Integer months = Integer.valueOf(objContr.IME_Fixed_Pricing_Period_months_Prod_S__c);
                    date EndFixedDate = FixedDate.addMonths(months);
                    objContr.IME_End_of_Fixed_Pricing_Period_Prod_S__c = EndFixedDate;
                }
                
                if(objContr.IME_Fixed_Pricing_Period_months_Transp__c != null && objContr.IME_Original_Contract_Start_Date__c != null)
                {
                    date FixedDate = objContr.IME_Original_Contract_Start_Date__c;
                    Integer months = Integer.valueOf(objContr.IME_Fixed_Pricing_Period_months_Transp__c);
                    date EndFixedDate = FixedDate.addMonths(months);
                    objContr.IME_End_of_Fixed_Pricing_Period_Transp__c = EndFixedDate;
                }
           
               /*
                ****Update 'Original Contract Start Date' field with the value from the 'Contract Start Date' field
                               
                1) When the ‘Draft’ Status is created and edited
                2) When the contract is activated
                
               */
                
               //ID ParentRecType= Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Parent Contract').getRecordTypeId();
               //ID ChildRecType= Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Child Contract').getRecordTypeId();
               //if(objContr.RecordTypeId == ParentRecType || objContr.RecordTypeId == ChildRecType)
            /*   if(evaluateDates== true)
               {
                   if(objContr.Status == 'Draft' || (Trigger.oldMap.get(objContr.Id).ActivatedDate == NULL && objContr.ActivatedDate !=NUll))
                   {
                      objContr.IME_Original_Contract_Start_Date__c=objContr.StartDate;
                   }
               }               
            }           
            
        }
        
    } */
}
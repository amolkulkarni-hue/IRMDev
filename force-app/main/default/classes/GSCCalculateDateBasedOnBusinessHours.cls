/********************************************************************************************************
* @Description: This Apex Class is created to calculate the Next Busines Day by adding the number of days after considering the Holidays/Weekends/Business Hours
* @Copyright: Iron Mountain
* @Author: Simranjit Kaur
* @Created on:  04/19/2024(MM/DD/YYYY)
* @TestClass Name: GSCCalculateDateBasedOnBusinessHoursTest
*
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
* 04/19/2024 - Simranjit Kaur - Initial Development - GitLab #22253
* ===================================================
*
********************************************************************************************************/
global class GSCCalculateDateBasedOnBusinessHours {
    //This method calculates the Next Busines Day by adding the number of days after considering the Holidays/Weekends/Business Hours
	public static Datetime calculateFollowUpDateMethod(Id businessHoursId,Integer numberOfDays)
	{	
        
        Integer elapsedHours = calculateElapsedHours(businessHoursId);
        //Calculate the next business day by adding the number of days and using the total hours in one business day i.e. elapsedHours
		Datetime followUpDate= BusinessHours.add(businessHoursId, System.now() , numberOfDays*elapsedHours*60*60*1000L);
        //Check whether the date calculated comes within the business hours or not. If now, then calculates the next business day within the business hours.
        Boolean isWithin= BusinessHours.isWithin(businessHoursId, followUpDate);
        if(isWithin==true){
			return followUpDate;
        }
        else
        {
            Datetime nextStart = BusinessHours.nextStartDate(businessHoursId, followUpDate);
            return nextStart;
        }                
	}
    //This method calculates the total hours in one business day based on the BusinessHours Id provided.
    public static Integer calculateElapsedHours(Id businessHoursId)
    {
        BusinessHours[] bh = [SELECT Id,MondayEndTime, MondayStartTime, TuesdayEndTime, TuesdayStartTime, WednesdayStartTime, WednesdayEndTime, ThursdayEndTime, ThursdayStartTime, FridayEndTime, FridayStartTime, SaturdayEndTime, SaturdayStartTime, SundayEndTime, SundayStartTime  FROM BusinessHours WHERE Id =:businessHoursId];
        Integer elapsedHours=0;
        if((bh[0].MondayEndTime.hour()<>0 && bh[0].MondayEndTime.hour()<> null) &&(bh[0].MondayStartTime.hour()<>0 && bh[0].MondayStartTime.hour()<> null))
		{
			elapsedHours= bh[0].MondayEndTime.hour() - bh[0].MondayStartTime.hour();
		}
		else if((bh[0].TuesdayEndTime.hour()<>0 && bh[0].TuesdayEndTime.hour()<> null) &&(bh[0].TuesdayStartTime.hour()<>0 && bh[0].TuesdayStartTime.hour()<> null))
		{
			elapsedHours= bh[0].TuesdayEndTime.hour() - bh[0].TuesdayStartTime.hour();
		}    
		else if((bh[0].WednesdayEndTime.hour()<>0 && bh[0].WednesdayEndTime.hour()<> null) &&(bh[0].WednesdayStartTime.hour()<>0 && bh[0].WednesdayStartTime.hour()<> null))
        {
            elapsedHours= bh[0].WednesdayEndTime.hour() - bh[0].WednesdayStartTime.hour();
        } 
      	else if((bh[0].ThursdayEndTime.hour()<>0 && bh[0].ThursdayEndTime.hour()<> null) &&(bh[0].ThursdayStartTime.hour()<>0 && bh[0].ThursdayStartTime.hour()<> null))
        {
            elapsedHours= bh[0].ThursdayEndTime.hour() - bh[0].ThursdayStartTime.hour();
        }
		else if((bh[0].FridayEndTime.hour()<>0 && bh[0].FridayEndTime.hour()<> null) &&(bh[0].FridayStartTime.hour()<>0 && bh[0].FridayStartTime.hour()<> null))
        {
            elapsedHours= bh[0].FridayEndTime.hour() - bh[0].FridayStartTime.hour();
        } 
		else if((bh[0].SaturdayEndTime.hour()<>0 && bh[0].SaturdayEndTime.hour()<> null) &&(bh[0].SaturdayStartTime.hour()<>0 && bh[0].SaturdayStartTime.hour()<> null))
        {
            elapsedHours= bh[0].SaturdayEndTime.hour() - bh[0].SaturdayStartTime.hour();
        }
		else if((bh[0].SundayEndTime.hour()<>0 && bh[0].SundayEndTime.hour()<> null) &&(bh[0].SundayStartTime.hour()<>0 && bh[0].SundayStartTime.hour()<> null))
        {
            elapsedHours= bh[0].SundayEndTime.hour() - bh[0].SundayStartTime.hour();
        }
        else
        {
            elapsedHours =9;
        }
        //Updating Elapsed Hours as 24 when the business hours are 24 Hours
        if(elapsedHours==0){
            elapsedHours = 24;
        }            
        return elapsedHours;
    }
}
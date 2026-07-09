global class ContactCenterStatus{
    public Boolean isOpen {get; private set;}
    public Boolean isHoliday {get; private set;}
    public String holidayName {get; private set;}
    public Boolean isOffHours{
        get{
            return !this.isOpen && !this.isHoliday;
        }
        private set;
    }
    
    global ContactCenterStatus(){
        this.isOpen = false;
        this.isHoliday = false;
        this.holidayName = '';
    }
    
    global void setOpen(){
        this.isOpen = true;
        this.isHoliday = false;
        this.holidayName = '';
    }
    
    global void setClose(String holidayName){
        if(String.isBlank(holidayName)){
            throw new SCVGoException('Invalid holiday name provided: ' + holidayName);
        }
        this.isHoliday = true;
        this.isOpen = false;
        this.holidayName = holidayName;
    }
}
//Call the function of a class when new Event is added 
trigger ActivityDateUpdateEvent on Event (after insert) {
    set<id> setActvtId =new set<id>();    
    if(label.eloquaUsers.contains(UserInfo.getUserId())!=TRUE){    
        for(Event evts: trigger.new){
            if (evts.whoId != null)
                setActvtId.add(evts.WhoId);
        }
       if(setActvtId.size() > 0) 
           MostRecentsaleActvt.excludeEloquaUsers(setActvtId);
    }  
}
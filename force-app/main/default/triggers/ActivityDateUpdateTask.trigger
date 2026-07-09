//Call the function of a class when new Task is added 
trigger ActivityDateUpdateTask on Task (after insert) {
    set<id> setActvtId =new set<id>();
    if(label.eloquaUsers.contains(UserInfo.getUserId())!=TRUE){    
        for(Task ts: trigger.new){
            if (ts.WhoId != null)
                setActvtId.add(ts.WhoId);            
        }
        if(setActvtId.size() > 0)        
            MostRecentsaleActvt.excludeEloquaUsers(setActvtId);
    }
}
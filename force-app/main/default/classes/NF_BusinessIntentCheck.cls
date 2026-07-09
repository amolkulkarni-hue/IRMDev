/**
 * @description       : To Check Business Intent in Bot Fallback Flow
 * @author            : Kunal Ramteke (NeuraFlash LLC)
 * @group             : 
 * @last modified on  : 05-21-2024
 * @last modified by  : Kunal Ramteke (NeuraFlash LLC)
**/

public without sharing class NF_BusinessIntentCheck {

    public class Input {
        @InvocableVariable(required=true)
        public String routableId;
    }

    public class Output {
        @InvocableVariable(required=true)
        public Boolean hasEnteredBusinessIntent;

        @InvocableVariable(required=false)
        public String businessIntentName;
    }

    @InvocableMethod(label='NeuraFlash - Has Entered Business Intent')
    public static List<Output> businessIntentCheck(List<Input> input) {
        List<Output> outputs = new List<NF_BusinessIntentCheck.Output>();
        Output out = new Output();
        out.hasEnteredBusinessIntent = false;

        try{
            String busIntent = getLastBusinessIntent(input[0].routableId);
            if(String.isNotBlank(busIntent)){
                out.hasEnteredBusinessIntent = true;
                out.businessIntentName = busIntent;
            }

            outputs.add(out);
        }catch(Exception ex){
            System.debug('NF_BusinessIntentCheck businessIntentCheck. Error Message: '+ ex.getMessage() + ' / '+ ex.getStackTraceString());
        }
        return outputs;
    }

    private static String getLastBusinessIntent(String routableId){
        String lastBusinessIntent = '';
        try {
            ebotmessaging__Messaging_Bot_Chat_Log__c[] botChatLogs = [ SELECT Id, ebotmessaging__Current_Dialog_Name__c
                                                        FROM ebotmessaging__Messaging_Bot_Chat_Log__c
                                                        WHERE ebotmessaging__Routable_Id__c = :routableId
                                                        AND ebotmessaging__Current_Dialog_Name__c LIKE 'bus_%'
                                                        ORDER BY CreatedDate DESC
                                                        LIMIT 1
                                                    ];
            if(botChatLogs.size() > 0){
                lastBusinessIntent = botChatLogs[0].ebotmessaging__Current_Dialog_Name__c;
            }
        }catch(Exception ex){
            System.debug('NF_BusinessIntentCheck getLastBusinessIntent. Error Message: '+ ex.getMessage() + ' / '+ ex.getStackTraceString());
        }
        return lastBusinessIntent;
    }
}
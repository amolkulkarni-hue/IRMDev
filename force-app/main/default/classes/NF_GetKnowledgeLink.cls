/**
 * @description       : To Get Knowledge Link and Title
 * @author            : Kunal Ramteke (NeuraFlash LLC)
 * @group             : 
 * @last modified on  : 07-17-2024
 * @last modified by  : Kunal Ramteke (NeuraFlash LLC)
**/
public without sharing class NF_GetKnowledgeLink {
    
    public class Input {
        @InvocableVariable(required=true)
        public Knowledge__kav  objKnow;
    }
    
	public class Output {
        @InvocableVariable
        public String strKLink;
        
        @InvocableVariable
        public String strKTitle;
    }
    
	@InvocableMethod(label='NF - Get Knowledge Link')
    public static List<Output> getKnowledgeLink(List<Input> input) {
        Knowledge__kav obj = input[0].objKnow;
        Output output = new Output();
        output.strKLink = obj.Knowledge_community_url__c;
        output.strKTitle = obj.Title;
        return new List<Output> { output };
    }
}
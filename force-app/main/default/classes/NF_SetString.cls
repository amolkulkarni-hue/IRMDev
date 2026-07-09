/**
 * Created by NeuraFlash LLC on 10/23/19.
 */

public with sharing class NF_SetString {
    @InvocableMethod(label='NeuraFlash - Set String')
    public static List<String> setString(List<String> input){
        return new List<String>{input[0]};
    }
}
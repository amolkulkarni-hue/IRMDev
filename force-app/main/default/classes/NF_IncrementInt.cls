/**
 * Created by NeuraFlash LLC on 14/07/2024.
 */

public without sharing class NF_IncrementInt {
    @InvocableMethod(label='Neuraflash - Increment Integer')
    public static List<Integer> increment(List<Integer> param){
        List<Integer> results = new List<Integer>();
        for(Integer i : param){
            results.add(i == null ? 1 : ++i);
        }
        return results;
    }
}
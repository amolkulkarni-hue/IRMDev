/**
 * Created by apoorvrajput on 14/07/2024.
 */


@IsTest
private class NF_IncrementIntTest {
    @IsTest
    static void test1() {
        System.assert(NF_IncrementInt.increment(new List<Integer>{1})[0] == 2);
    }
}
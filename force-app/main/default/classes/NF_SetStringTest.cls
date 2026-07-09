/**
 * Created by NeuraFlash LLC on 11/5/19.
 */

@IsTest
private class NF_SetStringTest {
    @IsTest
    static void test1() {
        System.assert(NF_SetString.setString(new List<String>{'test'})[0] == 'test');
    }
}
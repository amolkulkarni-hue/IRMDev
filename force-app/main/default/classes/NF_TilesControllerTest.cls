/**
* @author 	    : NeuraFlash, LLC
* @date 	    : 06/07/2021
* @description 	: The test class just checks for coverage since the NF_Contact_Tiles__mdt.getAll().values();
*                 is an out of box function. so no extended test is needed. 
*===========================================================
* Ver    Date          Author			Modification
*===========================================================
* 1.0    06/07/2021    Luis Rocha		Initial Version
*/
@IsTest
public with sharing class NF_TilesControllerTest {

    @IsTest
    static void testForCoverage(){
        Boolean exceptionCaught = false;
        try{
            NF_TilesController.getTiles();
        } catch (exception ex){
            exceptionCaught = true; 
        }
        System.assert(!exceptionCaught);
    }
}
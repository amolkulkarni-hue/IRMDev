/*****************************************************************************************************
* @File Name:     QTB_S26_JWT_Test
* @Author:        Virtusa
* @Developer:     Suresh Uppala
* @Story Number: #471
* @Description:   Test Class for QTB_S26_JWT                  
* Version         Developer          Date               Description
*  1.0            Suresh U      	01/05/2021          Initial Creation   
*******************************************************************************************************/

@isTest
public class QTB_S26_JWT_Test {
    public testmethod static void generateJWTToken(){
        // Get all custommetadata records with respect to developername ='RS256'
        QTB_S26_RS256_JWT__mdt rs=[Select id,DeveloperName,QTB_S26_Alg__c,QTB_S26_Aud__c,QTB_S26_Iss__c,QTB_S26_Type__c,QTB_S26_Sub__c,
                                   QTB_S26_Private_Key__c,QTB_S26_Kid__c From QTB_S26_RS256_JWT__mdt Where DeveloperName=: Label.QTB_S26_JWTAlgorithm];
        String alg =rs.QTB_S26_Alg__c;
        String type =rs.QTB_S26_Type__c;
        String Privatekey=rs.QTB_S26_Private_Key__c;
        String kid =rs.QTB_S26_Kid__c;
        String iss =rs.QTB_S26_Iss__c;
        String sub =rs.QTB_S26_Sub__c;
        String aud =rs.QTB_S26_Aud__c;
        Date iat = system.today();
        test.startTest();
        QTB_S26_JWT.generateJWT();
        test.stopTest();
    }
}
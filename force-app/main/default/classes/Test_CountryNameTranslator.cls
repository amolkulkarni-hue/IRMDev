/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Test_CountryNameTranslator (Apex Class)
**
** PURPOSE
**   To cover 'CountryNameTranslator' Apex Class. 
**
** NOTES
**   Created test class with dummy data to get code coverage always.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/05/07; Srinivasa Rao/Randstad; Reviewing code coverage for all components/Case#01367998; Initial release
**   v1.2; 2025/06/06; ChatGPT; Removed SeeAllData=true and added test data creation
**
************************************************************************/
@isTest
private class Test_CountryNameTranslator {
    
    static testMethod void myUnitTest() {
        // Create test country
        IM_Country__c country = new IM_Country__c(
            Name = 'Test Country',
            Iso31662Code__c = 'TC',
            Iso31663Code__c = 'TCT',
            Region__c = 'Test Region'
        );
        insert country;
        
        // Create alternative country names linked to the country
        IM_Alternative_Country_Name__c altName1 = new IM_Alternative_Country_Name__c(
            IM_Country__c = country.Id,
            Alternative_Name__c = 'Test Alt Name'
        );
        insert altName1;

        IM_Alternative_Country_Name__c altName2 = new IM_Alternative_Country_Name__c(
            IM_Country__c = country.Id,
            Alternative_Name__c = 'Another Alt Name'
        );
        insert altName2;

        // Prepare map input for translateCountryName
        Map<Id, String> countryMap = new Map<Id, String>{
            altName1.Id => 'Test Alt Name',
            altName2.Id => 'another alt name' // lower case to test case insensitivity
        };

        Test.startTest();
        Map<Id, IM_Country__c> resultMap = CountryNameTranslator.translateCountryName(countryMap);
 

        System.assertNotEquals(null, resultMap, 'translateCountryName should not return null');
        System.assertEquals(2, resultMap.size(), 'Should match 2 alternative names');
        System.assertEquals(country.Id, resultMap.get(altName1.Id).Id, 'Country Id should match for altName1');
        System.assertEquals(country.Id, resultMap.get(altName2.Id).Id, 'Country Id should match for altName2');

        // Prepare set input for translateCountryName2
        Set<String> altNamesSet = new Set<String>{'Test Alt Name', 'another alt name'};

        Map<String, IM_Country__c> resultMap2 = CountryNameTranslator.translateCountryName2(altNamesSet);


        System.assertNotEquals(null, resultMap2, 'translateCountryName2 should not return null');
        System.assertEquals(2, resultMap2.size(), 'Should match 2 alternative names');
        System.assert(resultMap2.containsKey('Test Alt Name'), 'Result should contain "Test Alt Name"');
        System.assert(resultMap2.containsKey('another alt name'), 'Result should contain "another alt name"');
        System.assertEquals(country.Id, resultMap2.get('Test Alt Name').Id, 'Country Id should match for Test Alt Name');

        // Test getOrCreateTestCountry method with a new country (not inserted)
        IM_Country__c newCountry = new IM_Country__c(
            Name = 'New Test Country',
            Iso31662Code__c = 'NTC',
            Iso31663Code__c = 'NTCT',
            Region__c = 'New Region'
        );

 
        IM_Country__c createdCountry = CountryNameTranslator.getOrCreateTestCountry(newCountry);
        Test.stopTest();

        System.assertNotEquals(null, createdCountry.Id, 'Country should be inserted and returned');
        System.assertEquals('New Test Country', createdCountry.Name);

        // Test retrieval of existing country (no insert)
        IM_Country__c retrievedCountry = CountryNameTranslator.getOrCreateTestCountry(createdCountry);
        System.assertEquals(createdCountry.Id, retrievedCountry.Id, 'Should return existing country without inserting');
    }
}
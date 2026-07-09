/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group test
 * @description Mock for ArchiveEmailServiceTest
 */


public with sharing class ArchiveEmailDataServiceMock implements IArchiveEmailDataService {
    @testVisible List<Archive_Email__b> upserted = new List<Archive_Email__b>();
    @testVisible static Set<Id> casesToClearArchive = new Set<Id>();

    public List<Database.SaveResult> upsertBigObject(List<Archive_Email__b> toUpsert) {
        this.upserted = toUpsert;
        return null;
    }

    public void deleteBigObject(Set<Id> cases) {
        casesToClearArchive = cases;
    }
}
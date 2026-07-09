/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group interface
 * @description handles operations on archive email big objects
 */

public interface IArchiveEmailDataService {
    /**
    * @description
    * upserts email archives
    * @param toUpsert - Records to upsert
    **/  
    List<Database.SaveResult> upsertBigObject(List<Archive_Email__b> toUpsert);


    /**
    * @description
    * clears email archives related to cases
    * @param cases - cases to clear email archives from
    **/  
    void deleteBigObject(Set<Id> cases);
}
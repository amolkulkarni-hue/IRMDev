/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Implementation of Cache.CacheBuilder interface. Current version implements retrieval of 
* NASApplicationConfiguration. May be extended for caching other configuration metadata.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public class NAS_ApplicationCacheBuilder implements Cache.CacheBuilder {
	/**
     * @name doLoad
     * @description Returns the configuration for a key.
    **/
	public Object doLoad(String key) {
        Object returnValue = null;
        if(key == NAS_Constants.KEY_ORG_CACHE_APPLICATION_CONFIGURATION)
        {
            returnValue = NAS_DataFactory.queryApplicationConfiguration();
        }
        else if(key == NAS_Constants.KEY_ORG_CACHE_TYPE_CATEGORY_MAPPING)
        {
        	returnValue = NAS_DataFactory.queryTypeCategoryMapping();
        }
        return returnValue;
    }
}
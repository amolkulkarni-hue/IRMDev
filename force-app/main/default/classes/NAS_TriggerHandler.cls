/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Trigger Handler Virual Class.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing virtual class NAS_TriggerHandler extends NAS_TriggerHandlerFramework {
	/**
	 * @name beforeInsert
     * @description Before Insert Trigger Handler.
     * Commented as this action is currently not being used.
    **/
    //public virtual override void beforeInsert() {}
 	/**
	 * @name beforeUpdate
     * @description Before Update Trigger Handler.
     * Commented as this action is currently not being used.
    **/
    //public virtual override void beforeUpdate() {}
 	/**
	 * @name beforeDelete
     * @description Before Delete Trigger Handler.
     * Commented as this action is currently not being used.
    **/
    //public virtual override void beforeDelete() {}
 	/**
	 * @name afterInsert
     * @description After Insert Trigger Handler.
    **/
    public virtual override void afterInsert() {}
 	/**
	 * @name afterUpdate
     * @description After Update Trigger Handler.
     * Commented as this action is currently not being used.
    **/
    //public virtual override void afterUpdate() {}
 	/**
	 * @name afterDelete
     * @description After Delete Trigger Handler.
     * Commented as this action is currently not being used.
    **/
    //public virtual override void afterDelete() {}
 	/**
	 * @name afterUndelete
     * @description After Undelete Trigger Handler.
     * Commented as this action is currently not being used.
    **/
    //public virtual override void afterUndelete() {}
}
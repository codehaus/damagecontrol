package com.thoughtworks.damagecontrol.buildmonitor;

/**
 * Constants representing fields and values in the results from
 * DamageControl's XML-RPC status service.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.3 $
 */
public interface BuildConstants {
    // Field names in the Ruby Build class
    String PROJECT_NAME_FIELD = "project_name";
    String CONFIG_FIELD = "config";
    String STATUS_FIELD = "status";
    String MODIFICATION_SET_FIELD = "modification_set";
    String TIMESTAMP_FIELD = "timestamp";

    // The values that STATUS_FIELD can have
    String STATUS_IDLE = "IDLE";
    String STATUS_SUCCESSFUL = "SUCCESSFUL";
    String STATUS_FAILED = "FAILED";
    String STATUS_QUEUED = "QUEUED";
    String STATUS_BUILDING = "BUILDING";
    String STATUS_CHECKING_OUT = "CHECKING OUT";
}
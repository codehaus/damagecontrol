package com.thoughtworks.damagecontrol.buildmonitor;

/**
 * Constants representing fields and values in the results from
 * DamageControl's XML-RPC status service.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public interface BuildConstants {
    // Field names in the Ruby Build class
    String PROJECT_NAME_FIELD = "project_name";
    String CONFIG_FIELD = "config";
    String SUCCESSFUL_FIELD = "successful";
    String MODIFICATION_SET_FIELD = "modification_set";
    String TIMESTAMP_FIELD = "timestamp";

    String STATUS_QUEUED = "queued";
    String STATUS_IN_PROGRESS = "in progress";
}
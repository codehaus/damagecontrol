package com.thoughtworks.damagecontrol.buildmonitor;

/**
 * Constants representing fields and values in the results from
 * DamageControl's XML-RPC status service.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public interface BuildConstants {
    String NAME_FIELD = "name";
    String STATUS_FIELD = "status";

    String STATUS_FAILED = "failed";
    String STATUS_SUCCESSFUL = "successful";
    String STATUS_QUEUED = "queued";
    String STATUS_IN_PROGRESS = "in progress";
}
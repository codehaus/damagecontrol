package com.thoughtworks.damagecontrol.buildmonitor;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public interface BuildPoller {
    void addBuildListener(BuildListener buildListener);
    void poll() throws PollException;
}
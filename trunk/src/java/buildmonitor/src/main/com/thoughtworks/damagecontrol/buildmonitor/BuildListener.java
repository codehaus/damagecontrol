/*
 * Created by IntelliJ IDEA.
 * User: ahelleso
 * Date: 08-Mar-2004
 * Time: 19:41:51
 */
package com.thoughtworks.damagecontrol.buildmonitor;

import java.util.List;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public interface BuildListener {

    /**
     * Updates the build status
     * @param buildList a list of {@link java.util.Map}. Each map may have a key-value pair using
     * fields from {@link com.thoughtworks.damagecontrol.buildmonitor.BuildConstants}.
     */
    void update(List buildList);
}
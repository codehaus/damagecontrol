/*
 * Created by IntelliJ IDEA.
 * User: ahelleso
 * Date: 08-Mar-2004
 * Time: 19:41:51
 */
package com.thoughtworks.damagecontrol.buildmonitor;

import java.util.List;
import java.util.Map;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public interface BuildListener {

    /**
     * Updates the build status
     * @param buildListMap a list of {@link java.util.Map}. Each map may have a key-value pair using
     * fields from {@link BuildConstants}.
     */
    void update(Map buildListMap);
}
package com.thoughtworks.damagecontrol.monitor;

import java.lang.reflect.InvocationTargetException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public interface TextAdder {
    void addText(String text) throws InvocationTargetException, InterruptedException;
}

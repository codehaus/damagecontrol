package com.thoughtworks.damagecontrol.buildmonitor;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class PollException extends Exception {
    public PollException(Throwable e) {
        super(e);
    }

    public PollException(String message) {
        super(message);
    }
}
package com.buildpatterns.damagecontrol.slave;

import java.io.File;
import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 */
public interface Poster {
    int post(File resultFile, String s) throws IOException;
}

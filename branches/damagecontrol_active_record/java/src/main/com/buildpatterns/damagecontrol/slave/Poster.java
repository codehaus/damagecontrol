package com.buildpatterns.damagecontrol.slave;

import java.io.File;
import java.io.IOException;
import java.net.URL;

/**
 * @author Aslak Helles&oslash;y
 */
public interface Poster {
    int post(File resultFile, URL url) throws IOException;
}

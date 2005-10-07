package com.buildpatterns.damagecontrol.slave;

import java.io.InputStream;
import java.io.File;
import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 */
public interface Compresser {
    void unzip(InputStream zip, File dir) throws IOException;
    File zip(File dir) throws IOException;
}

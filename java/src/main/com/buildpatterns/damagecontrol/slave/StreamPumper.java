package com.buildpatterns.damagecontrol.slave;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision$
 */
public class StreamPumper implements Runnable {
    private final int BUFFER = 2048;
    private final InputStream in;
    private final OutputStream out;

    public StreamPumper(InputStream in, OutputStream out) {
        this.in = new BufferedInputStream(in);
        this.out = new BufferedOutputStream(out, BUFFER);
    }

    public void run() {
        try {
            int count;
            byte data[] = new byte[BUFFER];
            while ((count = in.read(data, 0, BUFFER)) != -1) {
                out.write(data, 0, count);
            }
            out.flush();
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

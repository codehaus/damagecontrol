package com.thoughtworks.damagecontrol.monitor;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class LinePumper implements Runnable {

    private BufferedReader in;
    private final TextAdder lineReader;
    private boolean shouldRun = true;

    public LinePumper(InputStream in, TextAdder lineReader) {
        this.in = new BufferedReader(new InputStreamReader(in));
        this.lineReader = lineReader;
    }

    public void stop() {
        shouldRun = false;
    }

    public void run() {
        while (shouldRun) {
            try {
                String line = in.readLine();
                if (line != null) {
                    lineReader.addText(line + "\n");
                    synchronized (this) {
                        notify();
                    }
                }
            } catch (Exception e) {
                try {
                    lineReader.addText(e.getMessage());
                } catch (Throwable t) {
                } finally {
                    shouldRun = false;
                }
            }
        }
    }

    public synchronized void waitForLine() throws InterruptedException {
        wait();
    }
}

package com.thoughtworks.damagecontrol.monitor;

import junit.framework.TestCase;

import java.io.*;
import java.net.URL;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class URLPumperTestCase extends TestCase {
    public void testWriteToFileGetsPickedUpGradually() throws IOException {
        final StringBuffer consumed = new StringBuffer();
        File file = new File("target/testdata.txt");
        Writer w = new FileWriter(file);
        w.write("damagecontrol");
        w.flush();
        w.close();

        URL testURL = file.toURL();

        final Thread testThread = Thread.currentThread();
        CharConsumer stubConsumer = new CharConsumer() {
            public void consume(char b) {
                consumed.append(b);
                if("damagecontrol".equals(consumed.toString())) {
                    testThread.interrupt();
                }
            }
        };
        URLPumper urlPumper = new URLPumper(testURL, 10, stubConsumer);
        urlPumper.startPumping();

        synchronized(this) {
            try {
                wait(1000);
                fail();
            } catch (InterruptedException e) {
                // ok
            }
        }
    }

}

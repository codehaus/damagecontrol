package com.thoughtworks.damagecontrol.buildmonitor;

import junit.framework.TestCase;

import java.io.IOException;
import java.net.URL;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class URLPumperTestCase extends TestCase {
    public void testWriteToFileGetsPickedUpGradually() throws IOException {
        final StringBuffer consumed = new StringBuffer();

        final String data = "" +
                "damagecontrol\n" +
                "is\n" +
                "my\n" +
                "friend\n";
        URL testURL = URLPumper.createTestURL(data);

        final Thread testThread = Thread.currentThread();
        CharConsumer stubConsumer = new CharConsumer() {
            public void consume(char b) {
                consumed.append(b);
                if ("damagecontrol".equals(consumed.toString())) {
                    testThread.interrupt();
                }
            }
        };
        URLPumper urlPumper = new URLPumper(testURL, 10, stubConsumer);
        urlPumper.startPumping();

        synchronized (this) {
            try {
                wait(1000);
                fail();
            } catch (InterruptedException e) {
                // ok
            }
        }
    }

}

package com.thoughtworks.damagecontrol.buildmonitor;

import junit.framework.TestCase;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringBufferInputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLStreamHandler;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
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

package com.thoughtworks.damagecontrol.monitor;

import junit.framework.TestCase;

import java.io.IOException;
import java.io.InputStream;
import java.io.ByteArrayInputStream;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class LinePumperTestCase extends TestCase {
    private boolean didRead;

    protected void setUp() throws Exception {
        didRead = false;
    }

    public void testReadLine() throws IOException, InterruptedException {
        final String command = "howdy\n";

        InputStream in = new ByteArrayInputStream(command.getBytes());
        TextAdder lineReader = new TextAdder() {
            public void addText(String line) {
                assertEquals(command, line);
                assertFalse(didRead);
                didRead = true;
            }
        };

        LinePumper streamPumper= new LinePumper(in, lineReader);
        Thread thread = new Thread(streamPumper);
        thread.start();
        streamPumper.waitForLine();
        streamPumper.stop();
        assertTrue(didRead);
    }
}

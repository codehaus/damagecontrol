package com.thoughtworks.damagecontrol.monitor;

import junit.framework.TestCase;
import junit.framework.AssertionFailedError;

import java.lang.reflect.InvocationTargetException;
import java.io.IOException;

import com.thoughtworks.damagecontrol.testserver.TestServer;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class BuildClientTestCase extends TestCase {

    private static final int LINES_TO_READ = 4;

    private int line;
    private TestServer testServer;
    private BuildClient buildClient;

    protected void setUp() throws Exception {
        line = 0;
    }

    public void testConnection() throws IOException, InterruptedException {
        TextAdder textAdder = new TextAdder() {
            public void addText(String text) throws InvocationTargetException, InterruptedException {
                if (line < LINES_TO_READ) {
                    try {
                        line++;
                    } catch(AssertionFailedError e) {
                        stop();
                        throw e;
                    }
                }
            }
        };

        buildClient = new BuildClient("localhost", 4712, textAdder);

        testServer = new TestServer();
        testServer.start();

        buildClient.connect();
        LinePumper linePumper = buildClient.getLinePumper();
        for (int i = 0; i < LINES_TO_READ; i++) {
            linePumper.waitForLine();
        }
        stop();
        assertEquals(line, LINES_TO_READ);
    }

    private void stop() {
        buildClient.stop();
        testServer.stop();
    }
}

package damagecontrol;

import junit.framework.TestCase;

import java.io.PrintWriter;
import java.io.FileOutputStream;
import java.io.File;
import java.io.IOException;

public class ExecBuilderTest extends TestCase {
    private File successfulScript;
    private PrintWriter scriptWriter;
    private String os;
    private boolean wasCalled;
    private String scriptOutput;
    public static final String LINE_SEPARATOR = System.getProperty("line.separator");

    protected void setUp() throws Exception {
        os = System.getProperty("os.name").toLowerCase();
        successfulScript = File.createTempFile("damagecontroltest", ".bat");
        successfulScript.deleteOnExit();

        scriptWriter = new PrintWriter(new FileOutputStream(successfulScript));
        scriptOutput = "Hello world!";
        if (os.indexOf("windows") >= 0) {
            scriptWriter.println("@echo off");
            scriptWriter.println("echo " + scriptOutput);
        } else {
            fail("This test has not been implemented for your OS yet: " + os);
        }
        scriptWriter.close();
    }

    protected void tearDown() throws Exception {
        scriptWriter.close(); // if something fails in setUp, don't let an open file dangle
        successfulScript.delete();
    }

    public void testSuccesfulExecuteInformsListenersAndCapturesOutput() throws IOException {
        final ExecBuilder execBuilder = new ExecBuilder("exec", new DirectScheduler(), successfulScript.getAbsolutePath());
        execBuilder.addBuildListener(new BuildListener() {
            public void buildFinished(BuildEvent event) {
                wasCalled = true;
                assertSame(execBuilder, event.getSource());
                assertEquals(scriptOutput + LINE_SEPARATOR, event.getOutput());
            }
        });

        assertFalse(wasCalled);
        execBuilder.build();
        assertTrue(wasCalled);
    }
}

package damagecontrol.triggers;

import junit.framework.TestCase;

import java.io.IOException;
import java.io.OutputStream;
import java.io.InputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.Socket;

import damagecontrol.triggers.SocketTrigger;
import damagecontrol.Scheduler;
import damagecontrol.DirectScheduler;
import damagecontrol.Builder;
import damagecontrol.MockBuilder;

/**
 *
 * @author Aslak Helles&oslash;y
 * @author Jon Tirs&eacute;n
 * @version $Revision: 1.4 $
 */
public class SocketTriggerTest extends TestCase {
    private SocketTrigger socketTrigger;
    protected int buildRequestCount;

    protected void setUp() throws Exception {
        Scheduler scheduler = new DirectScheduler() {
            public void requestBuild(String builderName) {
                System.out.println("BUILD REQUESTED");
                buildRequestCount++;
            }
        };

        socketTrigger = new SocketTrigger(scheduler, 4711);

        Builder builder = new MockBuilder();
        scheduler.registerBuilder("testbuilder", builder);

        socketTrigger.execute();
    }

    protected void tearDown() throws Exception {
        socketTrigger.stop();
        assertTrue(socketTrigger.serverSocket.isClosed());
        assertFalse(socketTrigger.listenerThread.isAlive());
    }

    public void testConnectToSocketOnceWillRequestBuild() throws IOException {
        assertEquals(0, buildRequestCount);
        requestOnSocket(SocketTrigger.BUILD + " testproject", "OK");
        assertEquals(1, buildRequestCount);
    }

    public void testLaunchOtherThanBuildCommandWillNotTriggerBuild() throws IOException {
        assertEquals(0, buildRequestCount);
        requestOnSocket("NONSENSE", "KO");
        assertEquals(0, buildRequestCount);
    }

    public void testConnectToSocketMoreThanOnceWillRequestBuildMoreThanOnce() throws IOException {
        for (int i = 0; i < 10; i++) {
            assertEquals(i, buildRequestCount);
            requestOnSocket(SocketTrigger.BUILD + " testproject", "OK");
            assertEquals(i + 1, buildRequestCount);
        }
    }

    private void requestOnSocket(String command, String expectedResponse) throws IOException {
        Socket socket = null;
        try {
            socket = new Socket("localhost", 4711);
            OutputStream outputStream = socket.getOutputStream();
            InputStream inputStream = socket.getInputStream();

            PrintWriter bufferedWriter = new PrintWriter(new OutputStreamWriter(outputStream, "ASCII"));
            bufferedWriter.println(command);
            bufferedWriter.flush();

            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream, "ASCII"));
            String result = bufferedReader.readLine();
            assertEquals(expectedResponse, result);

        } finally {
            if (socket != null) {
                socket.close();
            }
        }
    }
}

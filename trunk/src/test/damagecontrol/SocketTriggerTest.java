package damagecontrol;

import junit.framework.TestCase;

import java.io.IOException;
import java.io.OutputStream;
import java.io.InputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.Socket;

/**
 *
 * @author Aslak Helles&oslash;y
 * @author Jon Tirs&eacute;n
 * @version $Revision: 1.2 $
 */
public class SocketTriggerTest extends TestCase {
    private SocketTrigger socketTrigger;
    private int buildRequestCount;

    protected void setUp() throws Exception {
        BuildScheduler mockBuildScheduler = new BuildScheduler() {
            private Builder builder;

            public void requestBuild(Builder builder) {
                this.builder = builder;
                buildRequestCount++;
            }

            public Builder getCurrentlyRunningBuilder() {
                return builder;
            }
        };

        socketTrigger = new SocketTrigger(mockBuildScheduler, 4711);
        socketTrigger.start();
    }

    protected void tearDown() throws Exception {
        socketTrigger.stop();
        assertTrue(socketTrigger.serverSocket.isClosed());
        assertFalse(socketTrigger.listener.isAlive());
    }

    public void testConnectToSocketOnceWillRequestBuild() throws IOException {
        assertEquals(0, buildRequestCount);
        requestOnSocket(SocketTrigger.BUILD + " testproject");
        assertEquals(1, buildRequestCount);
    }

    public void testLaunchOtherThanBuildCommandWillNotTriggerBuild() throws IOException {
        assertEquals(0, buildRequestCount);
        requestOnSocket("NONSENSE");
        assertEquals(0, buildRequestCount);
    }

    public void testConnectToSocketMoreThanOnceWillRequestBuildMoreThanOnce() throws IOException {
        for (int i = 0; i < 10; i++) {
            assertEquals(i, buildRequestCount);
            requestOnSocket(SocketTrigger.BUILD + " testproject");
            assertEquals(i + 1, buildRequestCount);
        }
    }

    private void requestOnSocket(String command) throws IOException {
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
            assertEquals("OK", result);

        } finally {
            if (socket != null) {
                socket.close();
            }
        }
    }
}

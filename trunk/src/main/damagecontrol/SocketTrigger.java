package damagecontrol;

import java.net.ServerSocket;
import java.net.Socket;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.InputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;

/**
 * This class is a socket gateway to DC. It listens for connection
 * on a port and talks a simple command protocol with the client.
 * <P>
 * The recommended way to interact with this is via a simple script
 * using telnet or netcat to send commands. The execution of this
 * scrript could be trigged by the SCM when a commit occurs.
 * <P>
 * @author Aslak Helles&oslash;y
 * @author Jon Tirs&eacute;e
 * @version $Revision: 1.1 $
 */
public class SocketTrigger {
    public static final String BUILD = "BUILD";

    private BuildScheduler builder;
    private int port;
    ServerSocket serverSocket;
    Thread listener;

    public SocketTrigger(BuildScheduler builder, int port) {
        this.builder = builder;
        this.port = port;
    }

    public void start() throws IOException {
        serverSocket = new ServerSocket(port);

        listener = new Thread(new Runnable() {
            public void run() {
                try {
                    while (true) {
                        Socket socket = serverSocket.accept();

                        InputStream inputStream = socket.getInputStream();
                        BufferedReader in = new BufferedReader(new InputStreamReader(inputStream));
                        String command = in.readLine();
                        if(BUILD.equals(command)) {
                            builder.requestBuild();
                        }

                        OutputStream outputStream = socket.getOutputStream();
                        PrintWriter out = new PrintWriter(new OutputStreamWriter(outputStream, "ASCII"));
                        out.println("OK");
                        out.flush();

                        socket.close();
                    }
                } catch (IOException e) {
                }
            }
        });
        listener.start();
    }

    public void stop() throws IOException, InterruptedException {
        serverSocket.close();
        listener.interrupt();
        listener.join(200);
    }

    /**
     * This was just added so that testing could be done from a telnet window.
     */
    public static void main(String[] args) {
        try {
            SocketTrigger socketTrigger = new SocketTrigger(new BuildScheduler() {
                public void requestBuild() {
                    System.out.println("BUILDING");
                }

                public boolean isBuildRunning() {
                    return true;
                }

            }, 4711);
            socketTrigger.start();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

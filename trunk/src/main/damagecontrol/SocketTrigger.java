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
import java.util.StringTokenizer;
import java.util.Map;
import java.util.HashMap;

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
 * @version $Revision: 1.2 $
 */
public class SocketTrigger {
    public static final String BUILD = "BUILD";

    private BuildScheduler buildScheduler;
    private int port;
    ServerSocket serverSocket;
    Thread listener;
    private Map builders = new HashMap();

    public SocketTrigger(BuildScheduler buildScheduler, int port) {
        this.buildScheduler = buildScheduler;
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
                        String commandLine = in.readLine();

                        StringTokenizer commandTokenizer = new StringTokenizer(commandLine);
                        String command = commandTokenizer.nextToken();
                        if(BUILD.equals(command)) {
                            String projectName = commandTokenizer.nextToken();
                            Builder builder = getBuilder(projectName);

                            buildScheduler.requestBuild(builder);
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

    private Builder getBuilder(String projectName) {
        return (Builder) builders.get(projectName);
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
                public void requestBuild(Builder builder) {
                    System.out.println("Build requested for " + builder.getName());
                }

                public Builder getCurrentlyRunningBuilder() {
                    return null;
                }

            }, 4711);
            socketTrigger.start();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

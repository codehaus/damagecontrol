package damagecontrol;

import damagecontrol.Scheduler;
import damagecontrol.Builder;
import damagecontrol.NoSuchBuilderException;
import damagecontrol.SocketTrigger;

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

/**
 * This class is a socket gateway to DamageControl. It is a server that
 * listens for connections on a port and talks a simple command protocol
 * with connecting clients.
 * <P>
 * The recommended way to interact with this is via a simple script
 * using netcat (or possibly telnet) to send commands. The execution of this
 * script could be trigged by the SCM when a commit occurs.
 * <P>
 * @author Aslak Helles&oslash;y
 * @author Jon Tirs&eacute;n
 * @version $Revision: 1.5 $
 */
public class SocketTrigger {
    public static final String BUILD = "BUILD";

    private Scheduler buildScheduler;
    private int port;
    ServerSocket serverSocket;
    Thread listenerThread;

    public SocketTrigger(Scheduler buildScheduler, int port) {
        this.buildScheduler = buildScheduler;
        this.port = port;
    }

    public static class WithScheduler extends SocketTrigger {
        private final static int DEFAULT_PORT = 4711;

        public WithScheduler(Scheduler buildScheduler) {
            super(buildScheduler, DEFAULT_PORT);
        }
    }

    public void execute() throws IOException {
        start();
    }

    public void start() throws IOException {
        serverSocket = new ServerSocket(port);

        listenerThread = new Thread(new Runnable() {
            public void run() {
                try {
                    while (!Thread.currentThread().isInterrupted()) {
                        Socket socket = serverSocket.accept();
                        try {

                            OutputStream outputStream = socket.getOutputStream();
                            PrintWriter out = new PrintWriter(new OutputStreamWriter(outputStream, "ASCII"));

                            InputStream inputStream = socket.getInputStream();
                            BufferedReader in = new BufferedReader(new InputStreamReader(inputStream));
                            String commandLine = in.readLine();
                            StringTokenizer commandTokenizer = new StringTokenizer(commandLine);
                            String command = commandTokenizer.nextToken();
                            if(BUILD.equals(command)) {
                                String projectName = commandTokenizer.nextToken();
                                try {
                                    buildScheduler.requestBuild(projectName);
                                } catch (NoSuchBuilderException e) {
                                    out.println("KO");
                                }
                                out.println("OK");
                            } else {
                                out.println("KO");
                            }

                            out.flush();

                        } finally {
                            socket.close();
                        }
                    }
                } catch (IOException e) {
                }
            }
        });
        listenerThread.setDaemon(true);
        listenerThread.start();
    }

    public void stop() throws IOException, InterruptedException {
        serverSocket.close();
        listenerThread.interrupt();
        listenerThread.join();
    }

    /**
     * This was just added so that testing could be done from a telnet window.
     */
    public static void main(String[] args) {
        try {
            SocketTrigger socketTrigger = new SocketTrigger.WithScheduler(new Scheduler() {
                public void requestBuild(String builderName) {
                }

                public void registerBuilder(String name, Builder builder) {
                }

            });
            socketTrigger.execute();

            synchronized (socketTrigger) {
                try {
                    socketTrigger.wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}

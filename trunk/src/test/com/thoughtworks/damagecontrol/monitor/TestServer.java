package com.thoughtworks.damagecontrol.monitor;

import java.net.ServerSocket;
import java.net.Socket;
import java.io.OutputStream;
import java.io.IOException;

/**
 * This class implements the protocol the the client speaks.
 * It will output dummy data.
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class TestServer {
    private boolean shouldRun = true;
    private Throwable failure;

    private Runnable runner = new Runnable() {
        public void run() {
            try {
                serverSocket = new ServerSocket(4712);
                while (shouldRun) {
                    acceptClient();
                }
            } catch (IOException e) {
                failure = e;
            }
        }
    };
    private ServerSocket serverSocket;

    private void acceptClient() {
        try {
            Socket socket = serverSocket.accept();
            OutputStream out = socket.getOutputStream();
            int i = 0;
            while(shouldRun) {
                try {
                    out.write(("Line " + i + "\n").getBytes());
                } catch (IOException e) {
                    // the client disconnected.
                }
                Thread.sleep(500);
                i++;
            }
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    public void start() throws InterruptedException {
        Thread serverThread = new Thread(runner);
        serverThread.start();
        Thread.sleep(500);
    }

    public void stop() {
        shouldRun = false;
    }

    public static void main(String[] args) throws InterruptedException {
        new TestServer().start();
    }
}

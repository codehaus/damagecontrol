package com.thoughtworks.damagecontrol.testserver;

import java.net.Socket;
import java.io.OutputStream;
import java.io.IOException;
import java.util.LinkedList;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class ClientStub implements Runnable {
    private final Socket socket;
    private final TestServer server;
    private OutputStream out;

    private final LinkedList lineQueue = new LinkedList();
    private boolean shouldPush = true;
    private Thread pusherThread;

    public ClientStub(Socket socket, TestServer server) {
        this.socket = socket;
        this.server = server;
    }

    public void startPushing() throws IOException {
        out = socket.getOutputStream();
        pusherThread = new Thread(this);
        pusherThread.start();
    }

    public void pushLine(String line) {
        lineQueue.add(line);
        synchronized (lineQueue) {
            System.out.println("NOTIFYING THAT THERE IS STUFF IN QUEUE");
            lineQueue.notify();
        }
    }

    public synchronized void stopPushing() {
        shouldPush = false;
    }

    public void run() {
        while(shouldPush) {
            try {
                String line = popLine();
                out.write((line + "\n").getBytes());
            } catch (InterruptedException e) {
                shouldPush = false;
            } catch (IOException e) {
                shouldPush = false;
            }
        }
        server.removeClientStub(this);
    }

    private String popLine() throws InterruptedException {
        if(lineQueue.isEmpty()) {
            synchronized(lineQueue) {
                // wait until there is something in our queue
                System.out.println("WAITING FOR LINE IN QUEUE");
                lineQueue.wait();
            }
        }
        final String line = (String) lineQueue.remove(0);
        return line;
    }

}

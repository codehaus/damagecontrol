package com.thoughtworks.damagecontrol.testserver;

import java.net.ServerSocket;
import java.net.Socket;
import java.io.IOException;
import java.util.*;

/**
 * This class implements the protocol the the client speaks.
 * It will output dummy data.
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class TestServer {
    private boolean shouldPusherRun;
    private boolean shouldDoormanRun;
    private ServerSocket serverSocket;
    private List clientStubs = Collections.synchronizedList(new ArrayList());

    private Runnable pusher = new Runnable() {
        public void run() {
            while (shouldPusherRun) {
                waitIfNoClientsAreConnected();
                pushToAllClients();
                waitAsec();
            }
        }

        private void waitIfNoClientsAreConnected() {
            if(clientStubs.isEmpty()) {
                try {
                    synchronized(this) {
                        System.out.println("PUSHER WAITING FOR MORE CLIENTS");
                        wait();
                    }
                } catch (InterruptedException e) {
                    e.printStackTrace();
                    shouldPusherRun = false;
                }
            }
        }

        private void pushToAllClients() {
            for (int i = 0; i < clientStubs.size(); i++ ) {
                ClientStub clientStub = (ClientStub) clientStubs.get(i);
                clientStub.pushLine(new Date().toString());
            }
        }

        private void waitAsec() {
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
                shouldPusherRun = false;
            }
        }
    };


    private Runnable doorman = new Runnable() {
        public void run() {
            while (shouldDoormanRun) {
                try {
                    Socket socket = serverSocket.accept();
                    ClientStub clientStub = new ClientStub(socket, TestServer.this);
                    clientStub.startPushing();
                    clientStubs.add(clientStub);
                    synchronized(pusher) {
                        System.out.println("DOORMAN NOTIFYING PUSHER THAT THERE ARE CLIENTS");
                        pusher.notify();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    shouldDoormanRun = false;
                }
            }
        }
    };

    public void start() throws InterruptedException, IOException {
        serverSocket = new ServerSocket(4712);

        Thread pusherThread = new Thread(pusher);
        shouldPusherRun = true;
        pusherThread.start();

        Thread doormanThread = new Thread(doorman);
        shouldDoormanRun = true;
        doormanThread.start();

        Thread.sleep(500);
    }

    public void stop() {
        shouldPusherRun = false;
    }

    public static void main(String[] args) throws InterruptedException, IOException {
        new TestServer().start();
    }

    public void removeClientStub(ClientStub clientStub) {
        clientStubs.remove(clientStub);
    }
}

package com.thoughtworks.damagecontrol.monitor;

import java.net.Socket;
import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class BuildClient {
    private final String host;
    private final int port;
    private final TextAdder textAdder;

    private LinePumper linePumper;

    public BuildClient(String host, int port, TextAdder textAdder) {
        this.host = host;
        this.port = port;
        this.textAdder = textAdder;
    }

    public void connect() throws IOException {
        Socket socket = new Socket(host, port);
        linePumper = new LinePumper(socket.getInputStream(), textAdder);
        Thread pumperThread = new Thread(linePumper);
        pumperThread.start();
    }

    public LinePumper getLinePumper() {
        return linePumper;
    }

    public void stop() {
        if(linePumper != null) {
            linePumper.stop();
        }
    }
}

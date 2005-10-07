package com.buildpatterns.damagecontrol.slave;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;

/**
 * Polls for new builds to execute, executes them and posts results back to server.
 *
 * @author Aslak Helles&oslash;y
 */
public class Agent {
    private final BuildSlave buildSlave;
    private final Poster poster;

    public Agent(BuildSlave buildSlave, Poster poster) {
        this.buildSlave = buildSlave;
        this.poster = poster;
    }

    public void run() {
        try {
            InputStream zip = new URL("http://localhost:3000/revision/zip/8").openStream();
            File resultFile = buildSlave.execute(zip, new File("C:\\dcslave\\myubild"));
            poster.post(resultFile, "http://localhost:3000/revision/result_zip/8");
        } catch (MalformedURLException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.monitor.TextAdder;
import com.thoughtworks.damagecontrol.monitor.BuildClient;

import javax.swing.*;
import java.net.URL;
import java.awt.*;
import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class MonitorApplet extends JApplet {

    private final GuiBuilder guiBuilder;

    public MonitorApplet() throws HeadlessException {
         guiBuilder = new GuiBuilder(getContentPane());
    }

    public void init() {
        super.init();

        TextAdder textAdder = guiBuilder.buildPanel();

        URL url = getCodeBase();
        String host = url.getHost();
        int port = Integer.parseInt(getParameter("port"));

        BuildClient buildClient = new BuildClient(host, port, textAdder);
        try {
            buildClient.connect();
        } catch (IOException e) {
            e.printStackTrace();
        }

    }
}

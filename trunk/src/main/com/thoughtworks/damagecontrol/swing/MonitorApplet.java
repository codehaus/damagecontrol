package com.thoughtworks.damagecontrol.swing;

import javax.swing.*;
import java.net.URL;
import java.awt.*;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class MonitorApplet extends JApplet {

    private final GuiBuilder guiBuilder;

    public MonitorApplet() throws HeadlessException {
         guiBuilder = new GuiBuilder(getContentPane());
    }

    public void init() {
        super.init();

        URL url = getCodeBase();
        String host = url.getHost();
        int port = Integer.parseInt(getParameter("port"));

        guiBuilder.buildPanel(host, port);

    }
}

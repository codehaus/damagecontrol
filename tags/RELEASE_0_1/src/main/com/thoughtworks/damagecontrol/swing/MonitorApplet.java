package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.monitor.CharConsumer;
import com.thoughtworks.damagecontrol.monitor.URLPumper;

import javax.swing.*;
import java.net.URL;
import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.3 $
 */
public class MonitorApplet extends JApplet {

    public void init() {
        super.init();
        GuiBuilder guiBuilder = new GuiBuilder(getContentPane());
        CharConsumer textAdder = guiBuilder.buildPanel();

        String indexPath = getParameter("indexPath");
        try {
            URL indexURL = new URL(getCodeBase(), indexPath);
            URLPumper urlPumper= new URLPumper(indexURL, 1000, textAdder);
            urlPumper.startPumping();
        } catch (IOException e) {
            e.printStackTrace();
            getContentPane().removeAll();
            getContentPane().add(new JTextField(e.getMessage()));
        }
    }
}

package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.monitor.TextAdder;
import com.thoughtworks.damagecontrol.monitor.BuildClient;

import javax.swing.*;
import java.awt.*;
import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class GuiBuilder {
    private BuildPanel buildPanel = new BuildPanel();
    private Container container;

    public GuiBuilder(Container container) {
        this.container = container;
    }

    public void buildPanel(String host, int port) {
        TextAdder textAdder = new DocumentUpdater(buildPanel.getProgressDocument());
        BuildClient buildClient = new BuildClient(host, port, textAdder);
        try {
            buildClient.connect();
            container.add(buildPanel);
        } catch (IOException e) {
            container.removeAll();
            container.add(new JLabel(e.getMessage()));
        }
    }

    public static void main(String[] args) {
        JFrame f = new JFrame();
        GuiBuilder b = new GuiBuilder(f.getContentPane());
        b.buildPanel("localhost", 4712);
        f.pack();
        f.show();
        System.out.println("SHOWED FRAME");
    }
}

package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.monitor.TextAdder;
import com.thoughtworks.damagecontrol.monitor.BuildClient;

import javax.swing.*;
import java.awt.*;
import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class GuiBuilder {
    private BuildPanel buildPanel = new BuildPanel();
    private Container container;

    public GuiBuilder(Container container) {
        this.container = container;
    }

    public TextAdder buildPanel() {
        TextAdder textAdder = new DocumentUpdater(buildPanel.getProgressDocument());
        container.add(buildPanel);
        return textAdder;
    }

    public static void main(String[] args) {
        JFrame f = new JFrame();
        GuiBuilder b = new GuiBuilder(f.getContentPane());
        TextAdder textAdder = b.buildPanel();
        f.pack();
        f.show();
        System.out.println("SHOWED FRAME");

        BuildClient buildClient = new BuildClient("localhost", 4712, textAdder);
        try {
            buildClient.connect();
        } catch (IOException e) {
            e.printStackTrace();
        }

    }
}

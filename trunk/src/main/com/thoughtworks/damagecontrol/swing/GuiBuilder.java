package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.monitor.CharConsumer;
import com.thoughtworks.damagecontrol.monitor.URLPumper;

import javax.swing.*;
import java.awt.*;
import java.io.IOException;
import java.io.File;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.3 $
 */
public class GuiBuilder {
    private BuildPanel buildPanel = new BuildPanel();
    private Container container;

    public GuiBuilder(Container container) {
        this.container = container;
    }

    public CharConsumer buildPanel() {
        CharConsumer textAdder = new DocumentUpdater(buildPanel.getProgressDocument());
        container.add(buildPanel);
        return textAdder;
    }

    public static void main(String[] args) throws IOException {
        JFrame f = new JFrame();
        GuiBuilder b = new GuiBuilder(f.getContentPane());
        CharConsumer textAdder = b.buildPanel();
        f.pack();
        f.show();
        System.out.println("SHOWED FRAME");

        URLPumper urlPumper= new URLPumper(new File("data").toURL(), 1000, textAdder);
        urlPumper.startPumping();
    }
}

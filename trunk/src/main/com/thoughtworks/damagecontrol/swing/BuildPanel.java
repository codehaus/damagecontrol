package com.thoughtworks.damagecontrol.swing;

import javax.swing.text.Document;
import javax.swing.text.PlainDocument;
import javax.swing.*;
import java.awt.*;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class BuildPanel extends JPanel {
    private Document progressDocument = new PlainDocument();
    private JTextArea progressArea = new JTextArea(progressDocument);

    public BuildPanel() {
        setLayout(new BorderLayout());
        add(new JScrollPane(progressArea), BorderLayout.CENTER);
    }

    public Document getProgressDocument() {
        return progressDocument;
    }

    public JTextArea getProgressArea() {
        return progressArea;
    }
}

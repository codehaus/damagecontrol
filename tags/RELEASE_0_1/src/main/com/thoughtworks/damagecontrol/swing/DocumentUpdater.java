package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.monitor.CharConsumer;

import javax.swing.text.Document;
import javax.swing.text.AttributeSet;
import javax.swing.text.SimpleAttributeSet;
import javax.swing.text.BadLocationException;
import javax.swing.*;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class DocumentUpdater implements CharConsumer {
    private Document document;
    private AttributeSet a = new SimpleAttributeSet();

    public DocumentUpdater(final Document document) {
        this.document = document;
    }

    public void consume(final char c) {
        SwingUtilities.invokeLater(new Runnable() {
            public void run() {
                int offset = document.getLength();
                try {
                    document.insertString(offset, new String(new char[]{c}), a);
                } catch (BadLocationException e) {
                    e.printStackTrace();
                }
            }
        });
    }
}

package com.thoughtworks.damagecontrol.swing;

import com.thoughtworks.damagecontrol.monitor.TextAdder;

import javax.swing.text.Document;
import javax.swing.text.AttributeSet;
import javax.swing.text.SimpleAttributeSet;
import javax.swing.text.BadLocationException;
import javax.swing.*;
import java.lang.reflect.InvocationTargetException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class DocumentUpdater implements TextAdder {
    private Document document;
    private AttributeSet a = new SimpleAttributeSet();

    public DocumentUpdater(Document document) {
        this.document = document;
    }

    public void addText(final String line) throws InvocationTargetException, InterruptedException {
        SwingUtilities.invokeAndWait(new Runnable() {
            public void run() {
                int offset = document.getLength();
                try {
                    document.insertString(offset, line, a);
                } catch (BadLocationException e) {
                    e.printStackTrace();
                }
            }
        });
    }
}

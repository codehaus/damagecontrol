package com.thoughtworks.damagecontrol.swing;

import junit.framework.TestCase;

import javax.swing.text.Document;
import javax.swing.text.PlainDocument;
import javax.swing.text.BadLocationException;
import java.lang.reflect.InvocationTargetException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class DocumentUpdaterTestCase extends TestCase {
    public void testUpdateDocument() throws BadLocationException, InterruptedException, InvocationTargetException {
        Document document = new PlainDocument();
        DocumentUpdater documentUpdater = new DocumentUpdater(document);
        documentUpdater.consume("I".toCharArray()[0]);
        assertEquals("I", document.getText(0, document.getLength()));
    }
}

package com.thoughtworks.damagecontrol.swing;

import junit.framework.TestCase;

import javax.swing.text.Document;
import java.lang.reflect.InvocationTargetException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class BuildPanelTestCase extends TestCase {
    public void testUpdateTextArea() throws InvocationTargetException, InterruptedException {
        BuildPanel buildPanel = new BuildPanel();
        Document progressDocument = buildPanel.getProgressDocument();
        DocumentUpdater documentUpdater = new DocumentUpdater(progressDocument);
        documentUpdater.consume("X".toCharArray()[0]);
        assertEquals("X", buildPanel.getProgressArea().getText());
    }
}

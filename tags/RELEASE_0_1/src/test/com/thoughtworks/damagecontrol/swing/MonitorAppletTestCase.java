package com.thoughtworks.damagecontrol.swing;

import junit.framework.TestCase;
import junit.framework.AssertionFailedError;

import javax.swing.*;
import java.applet.AppletStub;
import java.applet.AppletContext;
import java.net.URL;
import java.net.MalformedURLException;
import java.io.File;
import java.awt.*;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class MonitorAppletTestCase extends TestCase {
    public void testInitConnects() throws InterruptedException {
        MonitorApplet monitorApplet = new MonitorApplet();
        monitorApplet.setStub(new AppletStub(){
            public boolean isActive() {
                return false;
            }

            public void appletResize(int width, int height) {

            }

            public AppletContext getAppletContext() {
                return null;
            }

            public URL getCodeBase() {
                return getURL();
            }

            public URL getDocumentBase() {
                return getURL();
            }

            public String getParameter(String name) {
                assertEquals("indexPath", name);
                return "target/testdata.txt";
            }

            private URL getURL() {
                try {
                    return new File(".").toURL();
                } catch (MalformedURLException e) {
                    throw new AssertionFailedError();
                }
            }

        });

        monitorApplet.init();
        // yeah yeah, it's not nice to sleep in tests.
        Thread.sleep(1000);
        BuildPanel buildPanel = (BuildPanel) monitorApplet.getContentPane().getComponent(0);
        JTextArea textArea = buildPanel.getProgressArea();
        assertEquals("damagecontrol", textArea.getText());
    }
}

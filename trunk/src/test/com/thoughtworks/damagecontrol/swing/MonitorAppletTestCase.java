package com.thoughtworks.damagecontrol.swing;

import junit.framework.TestCase;
import junit.framework.AssertionFailedError;

import java.applet.AppletStub;
import java.applet.AppletContext;
import java.net.URL;
import java.net.MalformedURLException;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class MonitorAppletTestCase extends TestCase {
    public void testInitConnects() {
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
                return "4712";
            }

            private URL getURL() {
                try {
                    return new URL("http://localhost/");
                } catch (MalformedURLException e) {
                    throw new AssertionFailedError();
                }
            }

        });

        monitorApplet.init();
    }
}

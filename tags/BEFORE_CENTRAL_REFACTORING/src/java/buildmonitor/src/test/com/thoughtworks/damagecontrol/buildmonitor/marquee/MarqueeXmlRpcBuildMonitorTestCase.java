package com.thoughtworks.damagecontrol.buildmonitor.marquee;

import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;
import com.thoughtworks.damagecontrol.buildmonitor.BuildListener;
import com.thoughtworks.damagecontrol.buildmonitor.BuildPoller;
import junit.framework.TestCase;
import org.jmock.Constraint;
import org.jmock.Mock;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
//TODO refactor to an abstract test so we can subclass an integration test
//that goes against the ruby server
/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.6 $
 */
public class MarqueeXmlRpcBuildMonitorTestCase extends TestCase {
    private IOException serverEx;

    public void testResponseIsParsedToListOfMap() throws Exception {
        String testFile = System.getProperty("expected_xmlrpc_fetch_all_reply");
        FileReader in = new FileReader (new File(testFile));

        StringBuffer sb = new StringBuffer();
        int b;
        while((b = in.read()) != -1) {
            sb.append((char) b);
        }
        String xmlrpc = sb.toString();

        final String header = "" +
                "HTTP/1.1 200 OK\r\n" +
                "Connection: close\r\n" +
                "Content-Type: text/xml\r\n" +
                "Content-length: " + xmlrpc.length() + "\r\n" +
                "\r\n";

        final String payload = header + xmlrpc;

        // TODO: Use Jetty here. Will hopefully handle HTTPS
        Thread serverThread = new Thread(new Runnable() {
            public void run() {
                boolean waiting = true;
                ServerSocket fakeServer = null;
                try {
                    fakeServer = new ServerSocket(14315);
                    fakeServer.setSoTimeout(1000);
                } catch (IOException e) {
                    e.printStackTrace();
                }
                while (waiting) {
                    try {
                        Socket rpcClient = fakeServer.accept();
                        rpcClient.setSoTimeout(500);
                        InputStream is = rpcClient.getInputStream();
                        String data = "";
                        int i;
                        try {
                            while ((i = is.read()) != -1) {
                                data += (char) i;
                            }
                        } catch (SocketTimeoutException te) {
                            System.out.println("data = " + data);
                        }

                        System.out.println("data = " + data);
                        OutputStream outputStream = rpcClient.getOutputStream();
                        System.out.println("WRITING TO CLIENT");
                        outputStream.write(payload.getBytes());
                        outputStream.flush();
                        outputStream.close();
                        outputStream = null;
                        rpcClient = null;
                    } catch (SocketTimeoutException ste) {
                        System.out.println("Didn't get a connection, wait some more");
                        waiting = false;
                    } catch (IOException e) {
                        serverEx = e;
                        waiting = false;
                    }
                }
                try {
                    fakeServer.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                System.out.println("Server is dying now");
            }
        });
        serverThread.start();

        final Map expectedBuildListMap = new HashMap();

        final List expectedBuildList = new ArrayList();

        Map apple1 = new HashMap();
        apple1.put(BuildConstants.PROJECT_NAME_FIELD, "apple");
        apple1.put(BuildConstants.CONFIG_FIELD, Collections.singletonMap("build_command_line", "Apple1"));
        apple1.put(BuildConstants.MODIFICATION_SET_FIELD, Collections.EMPTY_LIST);
        apple1.put(BuildConstants.TIMESTAMP_FIELD, "20040316225946");
        apple1.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_SUCCESSFUL);
        apple1.put("___class___", "DamageControl::Build");
        expectedBuildList.add(apple1);

        Map apple2 = new HashMap();
        apple2.put(BuildConstants.PROJECT_NAME_FIELD, "apple");
        apple2.put(BuildConstants.CONFIG_FIELD, Collections.singletonMap("build_command_line", "Apple2"));
        apple2.put(BuildConstants.MODIFICATION_SET_FIELD, Collections.EMPTY_LIST);
        apple2.put(BuildConstants.TIMESTAMP_FIELD, "20040316225948");
        apple2.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_FAILED);
        apple2.put("___class___", "DamageControl::Build");
        expectedBuildList.add(apple2);

        expectedBuildListMap.put("apple", expectedBuildList);

        Mock mockBuildListener = new Mock(BuildListener.class);
        mockBuildListener.expect("update", new Constraint() {
            public boolean eval(Object o) {
                assertEquals(expectedBuildListMap, o);
                return true;
            }
        });

        BuildPoller buildMonitor = new MarqueeXmlRpcBuildPoller(new URL("http://localhost:14315/"));
        buildMonitor.addBuildListener((BuildListener) mockBuildListener.proxy());
        buildMonitor.poll();

        assertNull(serverEx);
    }

}
package com.thoughtworks.damagecontrol.buildmonitor.marquee;

import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;
import com.thoughtworks.damagecontrol.buildmonitor.BuildListener;
import com.thoughtworks.damagecontrol.buildmonitor.BuildPoller;
import org.jmock.Mock;
import org.jmock.MockObjectTestCase;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.util.*;
//TODO refactor to an abstract test so we can subclass an integration test
//that goes against the ruby server
/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.8 $
 */
public class MarqueeXmlRpcBuildMonitorTestCase extends MockObjectTestCase {
    private IOException serverEx;

    public void testResponseIsParsedToListOfMap() throws Exception {
        String testFile = System.getProperty("expected_xmlrpc_fetch_all_reply");
        FileReader in = new FileReader (new File(testFile));

        StringBuffer sb = new StringBuffer();
        int b;
        while((b = in.read()) != -1) {
            sb.append((char) b);
        }
        String expected_xmlrpc_fetch_all_reply = sb.toString();

        final String header = "" +
                "HTTP/1.1 200 OK\r\n" +
                "Connection: close\r\n" +
                "Content-Type: text/xml\r\n" +
                "Content-length: " + expected_xmlrpc_fetch_all_reply.length() + "\r\n" +
                "\r\n";

        final String payload = header + expected_xmlrpc_fetch_all_reply;

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
        mockBuildListener.expects(once()).method("update").with(eq(expectedBuildList));

        BuildPoller buildMonitor = new MarqueeXmlRpcBuildPoller(new URL("http://localhost:14315/"));
        buildMonitor.addBuildListener((BuildListener) mockBuildListener.proxy());
        buildMonitor.poll();

        assertNull(serverEx);
    }

}
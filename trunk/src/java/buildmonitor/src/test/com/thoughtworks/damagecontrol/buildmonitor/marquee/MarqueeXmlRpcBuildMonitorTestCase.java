package com.thoughtworks.damagecontrol.buildmonitor.marquee;

import com.thoughtworks.damagecontrol.buildmonitor.BuildConstants;
import com.thoughtworks.damagecontrol.buildmonitor.BuildListener;
import com.thoughtworks.damagecontrol.buildmonitor.BuildPoller;
import junit.framework.TestCase;
import org.jmock.C;
import org.jmock.Mock;

import java.io.IOException;
import java.io.OutputStream;
import java.io.InputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URL;
import java.net.SocketTimeoutException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class MarqueeXmlRpcBuildMonitorTestCase extends TestCase {
    private IOException serverEx;

    public void testResponseIsParsedToListOfMap() throws Exception {
        final String xmlrpc = "" +
                "<?xml version=\"1.0\"?>\r\n" +
                "<methodResponse>\r\n" +
                "  <params>\r\n" +
                "    <param>\r\n" +
                "      <value>\r\n" +
                "        <array>\r\n" +
                "          <data>\r\n" +
                "            <value>\r\n" +
                "              <struct>\r\n" +
                "                <member>\r\n" +
                "                  <name>name</name>\r\n" +
                "                  <value><string>three</string></value>\r\n" +
                "                </member>\r\n" +
                "                <member>\r\n" +
                "                  <name>status</name>\r\n" +
                "                  <value><string>failed</string></value>\r\n" +
                "                </member>\r\n" +
                "              </struct>\r\n" +
                "            </value>\r\n" +
                "            <value>\r\n" +
                "              <struct>\r\n" +
                "                <member>\r\n" +
                "                  <name>name</name>\r\n" +
                "                  <value><string>blind</string></value>\r\n" +
                "                </member>\r\n" +
                "                <member>\r\n" +
                "                  <name>status</name>\r\n" +
                "                  <value><string>successful</string></value>\r\n" +
                "                </member>\r\n" +
                "              </struct>\r\n" +
                "            </value>\r\n" +
                "          </data>\r\n" +
                "        </array>\r\n" +
                "      </value>\r\n" +
                "    </param>\r\n" +
                "  </params>\r\n" +
                "</methodResponse>\r\n";

        final String header = "" +
                "HTTP/1.1 200 OK\r\n" +
                "Connection: close\r\n" +
                "Content-Type: text/xml\r\n" +
                "Date: Fri, 17 Jul 1998 19:55:08 GMT\r\n" +
                "Server: UserLand Frontier/5.1.2-WinNT\r\n" +
                "Content-length: " + xmlrpc.length() + "\r\n" +
                "\r\n";

        final String payload = header + xmlrpc;

        Thread serverThread = new Thread(new Runnable() {
            public void run() {
                boolean waiting = true;
                ServerSocket fakeServer = null;
                try {
                    fakeServer = new ServerSocket(4315);
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
//                            System.out.println("data = " + data);
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
                System.out.println("Server us dying now");
            }
        });
        serverThread.start();

        List expectedBuildList = new ArrayList();

        Map three = new HashMap();
        three.put(BuildConstants.NAME_FIELD, "three");
        three.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_FAILED);
        expectedBuildList.add(three);

        Map blind = new HashMap();
        blind.put(BuildConstants.NAME_FIELD, "blind");
        blind.put(BuildConstants.STATUS_FIELD, BuildConstants.STATUS_SUCCESSFUL);
        expectedBuildList.add(blind);

        Mock mockBuildListener = new Mock(BuildListener.class);
        mockBuildListener.expect("update", C.eq(expectedBuildList));

        BuildPoller buildMonitor = new MarqueeXmlRpcBuildPoller(new URL("http://localhost:4315/"));
        buildMonitor.addBuildListener((BuildListener) mockBuildListener.proxy());
        buildMonitor.poll();

        assertNull(serverEx);
    }

}
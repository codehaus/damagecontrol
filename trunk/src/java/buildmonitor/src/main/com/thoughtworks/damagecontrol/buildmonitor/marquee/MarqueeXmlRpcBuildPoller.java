package com.thoughtworks.damagecontrol.buildmonitor.marquee;

import com.thoughtworks.damagecontrol.buildmonitor.BuildListener;
import com.thoughtworks.damagecontrol.buildmonitor.BuildPoller;
import com.thoughtworks.damagecontrol.buildmonitor.PollException;
import marquee.xmlrpc.XmlRpcClient;
import marquee.xmlrpc.XmlRpcException;
import marquee.xmlrpc.XmlRpcParser;

import java.net.URL;
import java.util.Map;

/**
 * This BuildPoller accesses DamageControl's XML-RPC status
 * server using the Marquee XML-RPC library.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class MarqueeXmlRpcBuildPoller implements BuildPoller {
    private final XmlRpcClient xmlRpcClient;

    private BuildListener buildListener;

    public MarqueeXmlRpcBuildPoller(URL url) {
        XmlRpcParser.setDriver(org.xml.sax.helpers.XMLReaderAdapter.class);
        System.setProperty("org.xml.sax.driver", "org.apache.crimson.parser.XMLReaderImpl");
        xmlRpcClient = new XmlRpcClient(url);
    }

    public void addBuildListener(BuildListener buildListener) {
        this.buildListener = buildListener;
    }

    public void poll() throws PollException {
        try {
            Object result = xmlRpcClient.invoke("status", new Object[0]);
            Map buildListMap = (Map) result;
            buildListener.update(buildListMap);
        } catch (XmlRpcException e) {
            throw new PollException(e);
        }
    }
}
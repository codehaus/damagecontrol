package com.thoughtworks.damagecontrol.buildmonitor.marquee;

import com.thoughtworks.damagecontrol.buildmonitor.BuildListener;
import com.thoughtworks.damagecontrol.buildmonitor.BuildPoller;
import com.thoughtworks.damagecontrol.buildmonitor.PollException;
import marquee.xmlrpc.XmlRpcClient;
import marquee.xmlrpc.XmlRpcException;
import marquee.xmlrpc.XmlRpcParser;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import java.net.URL;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.X509Certificate;
import java.util.Map;

/**
 * This BuildPoller accesses DamageControl's XML-RPC status
 * server using the Marquee XML-RPC library.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.5 $
 */
public class MarqueeXmlRpcBuildPoller implements BuildPoller {
    private final XmlRpcClient xmlRpcClient;

    private BuildListener buildListener;

    public MarqueeXmlRpcBuildPoller(URL url) {
        XmlRpcParser.setDriver(org.xml.sax.helpers.XMLReaderAdapter.class);
        System.setProperty("org.xml.sax.driver", "org.apache.crimson.parser.XMLReaderImpl");
        xmlRpcClient = new XmlRpcClient(url);
        if(url.toExternalForm().startsWith("https://")) {
            setUpTrustedSocketFactory();            
        }
    }

    private void setUpTrustedSocketFactory() {
        try {
            X509TrustManager trustMgr = new X509TrustManager() {
                public X509Certificate[] getAcceptedIssuers() {
                    return new X509Certificate[0];
                }

                public void checkClientTrusted(X509Certificate[] x509Certificates, String s) {
                }

                public void checkServerTrusted(X509Certificate[] x509Certificates, String s) {
                }
            };

            SSLContext context = SSLContext.getInstance("TLS");
            context.init(null, new TrustManager[]{trustMgr}, null);

            SSLSocketFactory socketFactory = context.getSocketFactory();
            HttpsURLConnection.setDefaultSSLSocketFactory(socketFactory);
            HttpsURLConnection.setDefaultHostnameVerifier(new HostnameVerifier(){
                public boolean verify(String s, SSLSession sslSession) {
                    return true;
                }
            });
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        } catch (KeyManagementException e) {
            throw new RuntimeException(e);
        }
    }

    public void addBuildListener(BuildListener buildListener) {
        this.buildListener = buildListener;
    }

    public void poll() throws PollException {
        try {
            Object result = xmlRpcClient.invoke("status.get_build_list_map", new Object[]{});
            Map map = (Map) result;

            // check the result for exceptions before passing it on
            String faultString = (String) map.get("faultString");
            if(faultString != null) {
                throw new PollException("Server error: " + faultString + " faultCode=" + (Integer) map.get("faultCode"));
            }

            buildListener.update(map);
        } catch (XmlRpcException e) {
            throw new PollException(e);
        }
    }
}
package com.thoughtworks.damagecontrol.buildmonitor;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.StringBufferInputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLStreamHandler;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class URLPumper {
    private final URL url;
    private final int pollInterval;
    private final CharConsumer charConsumer;
    private final char[] buffer = new char[1024];
    private final Runnable pumper = new Runnable() {
        public void run() {
            while (shouldPump) {
                try {
                    int read = in.read(buffer);
                    if (read == -1) {
                        waitPollInterval();
                    } else {
                        for (int i = 0; i < read; i++) {
                            charConsumer.consume(buffer[i]);
                        }
                    }
                } catch (IOException e) {
                    shouldPump = false;
                }
            }
        }

        private synchronized void waitPollInterval() {
            try {
                wait(pollInterval);
            } catch (InterruptedException e) {
            }
        }
    };

    private Reader in;
    private boolean shouldPump;
    private Thread pumperThread;

    public URLPumper(URL url, int pollInterval, CharConsumer charConsumer) {
        this.url = url;
        this.pollInterval = pollInterval;
        this.charConsumer = charConsumer;
    }

    /**
     * This method blocks forever and just pumps the URL.
     *
     * @throws IOException
     */
    public void startPumping() throws IOException {
        in = new BufferedReader(new InputStreamReader(url.openStream()));
        shouldPump = true;
        pumperThread = new Thread(pumper);
        pumperThread.start();
    }

    // util method for tests. doesn't belong here, but it is convenient, since it
    // is used by other projects too, like swing.
    public static URL createTestURL(final String data) {
        try {
            return new URL("test", "localhost", -1, "dummy", new URLStreamHandler() {
                protected URLConnection openConnection(URL u) throws IOException {
                    return new URLConnection(u) {
                        public void connect() throws IOException {
                        }

                        public InputStream getInputStream() throws IOException {
                            return new StringBufferInputStream(data);
                        }
                    };
                }
            });
        } catch (MalformedURLException e) {
            throw new RuntimeException(e);
        }
    }
}

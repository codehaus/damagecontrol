package com.thoughtworks.damagecontrol.monitor;

import java.net.URL;
import java.io.*;

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
            while(shouldPump) {
                try {
                    int read = in.read(buffer);
                    if(read == -1) {
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
}

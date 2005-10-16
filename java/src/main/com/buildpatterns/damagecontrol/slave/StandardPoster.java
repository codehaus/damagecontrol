package com.buildpatterns.damagecontrol.slave;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * @author Aslak Helles&oslash;y
 */
public class StandardPoster implements Poster {
    private static final int BUFFER = 2048;
    private static final byte[] PREFIX = getBytes("--");
    private static final byte[] BOUNDARY = getBytes("rubyqMY6QN9FKLsfj234ksed");
    private static final byte[] NEWLINE = getBytes("\r\n");

    private static byte[] getBytes(String s) {
        try {
            return s.getBytes("US-ASCII");
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException(e);
        }
    }

    public int post(File file, URL postUrl) throws IOException {
        HttpURLConnection urlConn = createUrlConnection(postUrl);
        urlConn.connect();

        BufferedOutputStream out = new BufferedOutputStream(urlConn.getOutputStream());

        writeFile(out, file);
        close(out);

        return urlConn.getResponseCode();
    }

    private HttpURLConnection createUrlConnection(URL postUrl) throws IOException {
        HttpURLConnection urlConn = (HttpURLConnection) postUrl.openConnection();

        urlConn.setDoOutput(true);
        urlConn.setUseCaches(false);
        urlConn.setRequestMethod("POST");
        urlConn.setRequestProperty("Content-Type", "multipart/form-data; boundary=" + BOUNDARY);
        return urlConn;
    }

    private void writeFile(OutputStream out, File file) throws IOException {
        out.write(PREFIX);
        out.write(BOUNDARY);
        out.write(NEWLINE);

        out.write(getBytes("Content-Disposition: form-data; name=\"zip\"; filename=\"" + file.getName() + "\""));
        out.write(NEWLINE);

        out.write(getBytes("Content-Type: application/octet-stream"));
        out.write(NEWLINE);

//        out.write("Content-Transfer-Encoding: binary".getBytes());
//        out.write(NEWLINE);

        out.write(NEWLINE);
        byte fileData[] = new byte[BUFFER];
        BufferedInputStream fileIn = new BufferedInputStream(new FileInputStream(file), BUFFER);
        int count;
        while ((count = fileIn.read(fileData, 0, BUFFER)) != -1) {
            out.write(fileData, 0, count);
        }
        out.write(NEWLINE);
    }

    private void close(OutputStream out) throws IOException {
        out.write(PREFIX);
        out.write(BOUNDARY);
        out.write(PREFIX);
        out.write(NEWLINE);
        out.flush();
        out.close();
    }
}

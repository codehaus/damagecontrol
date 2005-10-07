package com.buildpatterns.damagecontrol.slave;

import org.apache.commons.httpclient.methods.PostMethod;
import org.apache.commons.httpclient.methods.multipart.FilePart;
import org.apache.commons.httpclient.methods.multipart.MultipartRequestEntity;
import org.apache.commons.httpclient.methods.multipart.Part;
import org.apache.commons.httpclient.NameValuePair;
import org.apache.commons.httpclient.HttpClient;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.net.HttpURLConnection;

/**
 * Polls for new builds to execute, executes them and posts results back to server.
 *
 * @author Aslak Helles&oslash;y
 */
public class Agent {
    private static final int BUFFER = 2048;

    private final BuildSlave buildSlave;

    public Agent(BuildSlave buildSlave) {
        this.buildSlave = buildSlave;
    }

    public void run() {
        try {
            InputStream zip = new URL("http://localhost:3000/revision/zip/8").openStream();
            File resultFile = buildSlave.execute(zip, new File("C:\\dcslave\\myubild"));
            post2(resultFile, "http://localhost:3000/revision/result_zip/8");
        } catch (MalformedURLException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void post2(File resultFile, String postUrl) throws IOException {
        PostMethod post = new PostMethod(postUrl);
        FilePart part = new FilePart("zip", resultFile);
        post.setRequestEntity(new MultipartRequestEntity(new Part[]{part}, post.getParams()));
        HttpClient client = new HttpClient();
        int status = client.executeMethod(post);
    }

    // TODO: do a multipart post w/o commons-httpclient to reduce footprint
    private void post(File resultFile, String postUrl) throws IOException {
        URL url = new URL(postUrl);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setDoInput(true);
        connection.setDoOutput(true);
        connection.setUseCaches(false);

        connection.setRequestMethod("POST");
        connection.setRequestProperty("Content-Type", "application/octet-stream");
        connection.setRequestProperty("Content-Length", "" + resultFile.length());

        BufferedOutputStream out = new BufferedOutputStream(connection.getOutputStream());
        byte data[] = new byte[BUFFER];
        BufferedInputStream file = new BufferedInputStream(new FileInputStream(resultFile), BUFFER);
        int count;
        while ((count = file.read(data, 0, BUFFER)) != -1) {
            out.write(data, 0, count);
        }
        out.flush();
        out.close();

        BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
        System.out.println("Response:" + in.readLine());
        in.close();
    }
}

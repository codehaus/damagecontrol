package com.buildpatterns.damagecontrol.slave;

import java.io.File;
import java.io.IOException;
import java.net.URL;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.methods.PostMethod;
import org.apache.commons.httpclient.methods.multipart.FilePart;
import org.apache.commons.httpclient.methods.multipart.MultipartRequestEntity;
import org.apache.commons.httpclient.methods.multipart.Part;

/**
 * @author Aslak Helles&oslash;y
 */
public class HttpClientPoster implements Poster {
    public int post(File file, URL postUrl) throws IOException {
        PostMethod post = new PostMethod(postUrl.toExternalForm());
        FilePart part = new FilePart("zip", file);
        post.setRequestEntity(new MultipartRequestEntity(new Part[]{part}, post.getParams()));
        HttpClient client = new HttpClient();
        return client.executeMethod(post);
    }

}

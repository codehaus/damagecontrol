package com.buildpatterns.damagecontrol.slave;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.MalformedURLException;
import java.net.URL;

import com.buildpatterns.damagecontrol.slave.types.PendingBuildInfo;

/**
 * Polls for new builds to execute, executes them and posts results back to
 * server.
 * 
 * @author Aslak Helles&oslash;y
 */
public class Agent {
	private final BuildExecutor buildSlave;
	private final Poster poster;
	private final URL pendingBuildInfoUrl;

	public Agent(BuildExecutor buildSlave, Poster poster, URL pendingBuildInfoUrl) {
		this.buildSlave = buildSlave;
		this.poster = poster;
		this.pendingBuildInfoUrl = pendingBuildInfoUrl;
	}
	
	public void buildNext() throws IOException {
		PendingBuildInfo info = (PendingBuildInfo) X.stream.fromXML(new InputStreamReader(pendingBuildInfoUrl.openStream()));
	}

	private void build(URL revisionUrl, File executionDir, URL resultUrl) {
		try {
			InputStream zip = revisionUrl.openStream();
			File resultFile = buildSlave.execute(zip, executionDir);
			poster.post(resultFile, resultUrl);
		} catch (MalformedURLException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

}

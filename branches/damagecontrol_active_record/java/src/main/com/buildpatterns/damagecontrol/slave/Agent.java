package com.buildpatterns.damagecontrol.slave;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;

import com.buildpatterns.damagecontrol.slave.types.PendingBuildInfo;

/**
 * Polls for new builds to execute, executes them and posts results back to
 * server.
 * 
 * @author Aslak Helles&oslash;y
 */
public class Agent {
	private final BuildExecutor buildExecutor;
	private final Poster poster;
	private final URL pendingBuildInfoUrl;
	private final File rootDir;

	public Agent(BuildExecutor buildExecutor, Poster poster, URL pendingBuildInfoUrl, File rootDir) {
		this.buildExecutor = buildExecutor;
		this.poster = poster;
		this.pendingBuildInfoUrl = pendingBuildInfoUrl;
		this.rootDir = rootDir;
	}
	
	public void buildNext() throws IOException {
		InputStream in = pendingBuildInfoUrl.openStream();
		PendingBuildInfo info = (PendingBuildInfo) X.stream.fromXML(new InputStreamReader(in));
		URL revisionUrl = info.revisionUrl;
		URL resultUrl = info.resultUrl;
		
		File executionDir = new File(rootDir, "" + info.projectId + "/" + info.revisionId);
		
		build(revisionUrl, executionDir, resultUrl);
	}

	private void build(URL revisionUrl, File executionDir, URL resultUrl) throws IOException {
		InputStream zip = revisionUrl.openStream();
		File resultFile = buildExecutor.execute(zip, executionDir);
		poster.post(resultFile, resultUrl);
	}

}

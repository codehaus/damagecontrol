package com.buildpatterns.damagecontrol.slave;

import java.io.File;
import java.io.IOException;
import java.net.URL;

import org.jmock.Mock;
import org.jmock.MockObjectTestCase;

/**
 * @author Aslak Helles&oslash;y
 */
public class AgentTest extends MockObjectTestCase {
    public void testShouldBuildFromUrlAndPostBack() throws IOException {
    	    File resultFile = new File("build.xml");
    	
        Mock buildExecutor = mock(BuildExecutor.class);
        buildExecutor.expects(once()).method("execute").withAnyArguments().will(returnValue(resultFile));
        
        Mock poster = mock(Poster.class);
        poster
			.expects(once())
			.method("post")
			.with(same(resultFile), eq(new URL("http://localhost:9876/what/ever")))
			.will(returnValue(200));
        
        URL pendingBuildInfoUrl = getClass().getResource("/com/buildpatterns/damagecontrol/slave/pending_build_info.xml");
        Agent agent = new Agent((BuildExecutor)buildExecutor.proxy(), (Poster)poster.proxy(), pendingBuildInfoUrl, new File("target/testroot"));
        agent.buildNext();
    }
}
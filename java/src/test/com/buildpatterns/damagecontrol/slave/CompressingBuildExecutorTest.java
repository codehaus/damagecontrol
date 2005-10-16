package com.buildpatterns.damagecontrol.slave;

import com.buildpatterns.damagecontrol.slave.types.BuildInfo;
import org.jmock.MockObjectTestCase;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

/**
 * @author Aslak Helles&oslash;y
 */
public class CompressingBuildExecutorTest extends MockObjectTestCase {
    public void testShouldLoadXmlFile() throws FileNotFoundException {
        CompressingBuildExecutor executor = new CompressingBuildExecutor(new Zipper());
        File buildInfoFile = new File("src/test-project/damagecontrol_build_info.xml");
        BuildInfo buildInfo = executor.getBuildInfo(buildInfoFile);
        assertEquals(456, buildInfo.revision.label);
    }

    public void testShouldExecuteZip() throws IOException {
        BuildExecutor executor = new CompressingBuildExecutor(new Zipper());
        File zip = new File("target/test-project.zip");
        File dir = new File(zip.getParentFile(), zip.getName().substring(0, zip.getName().length() - 4));
        executor.execute(new FileInputStream(zip), dir);
    }
}
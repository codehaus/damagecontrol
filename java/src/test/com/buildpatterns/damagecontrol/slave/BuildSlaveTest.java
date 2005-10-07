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
public class BuildSlaveTest extends MockObjectTestCase {
    public void testShouldLoadXmlFile() throws FileNotFoundException {
        BuildSlave slave = new BuildSlave(new Zipper());
        File buildInfoFile = new File("src/test-project/damagecontrol_build_info.xml");
        BuildInfo buildInfo = slave.getBuildInfo(buildInfoFile);
        assertEquals(456, buildInfo.revision.label);
    }

    public void testShouldExecuteZip() throws IOException {
        BuildSlave slave = new BuildSlave(new Zipper());
        File zip = new File("target/test-project.zip");
        File dir = new File(zip.getParentFile(), zip.getName().substring(0, zip.getName().length() - 4));
        slave.execute(new FileInputStream(zip), dir);
    }
}
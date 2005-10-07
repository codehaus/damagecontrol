package com.buildpatterns.damagecontrol.slave;

import org.jmock.MockObjectTestCase;

import java.io.IOException;
import java.io.File;
import java.io.FileInputStream;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision$
 */
public class ZipperTest extends MockObjectTestCase {
    public void testShouldExplodeZip() throws IOException {
        Zipper zipper = new Zipper();
        File zip = new File("target/test-project.zip");
        File dir = new File(zip.getParentFile(), "test-project");
        zipper.unzip(new FileInputStream(zip), dir);
        assertTrue(new File(dir, "Rakefile").isFile());
    }

}
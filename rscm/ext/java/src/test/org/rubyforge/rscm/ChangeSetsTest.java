package org.rubyforge.rscm;

import junit.framework.TestCase;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;

/**
 * @author Aslak Helles&oslash;y
 */
public class ChangeSetsTest extends TestCase {
    public void testShouldSerializeChangeSetsToYaml() throws IOException {
        YamlDumpable changeSets = new TestScm().getChangeSets(null, null);
        StringWriter yaml = new StringWriter();
        PrintWriter out = new PrintWriter(yaml);
        changeSets.dumpYaml(out);
        out.flush();
        System.out.println(yaml);
    }
}

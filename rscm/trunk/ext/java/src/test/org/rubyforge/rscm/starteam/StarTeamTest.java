package org.rubyforge.rscm.starteam;

import junit.framework.TestCase;
import org.rubyforge.rscm.RSCM;
import org.rubyforge.rscm.YamlDumpable;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;

/**
 * @author Aslak Helles&oslash;y
 */
public class StarTeamTest extends TestCase {
    private String userName = System.getProperty("starteam_user");
    private String password = System.getProperty("starteam_password");
    private String serverName = "192.168.254.21";
    private String serverPort = "49201";
    private String projectName = "NGST Application";
    private String viewName = "NGST Application";
    private String folderName = "data";
    private RSCM starTeam;

    protected void setUp() throws Exception {
        starTeam = new StarTeam(userName, password, serverName, serverPort, projectName, viewName, folderName);
//        starTeam = new TestScm(null, null);
    }

    public void testShouldConvertChangesToYaml() throws IOException {
        YamlDumpable changeSets = starTeam.getChangeSets("4 Jan 2005 04:02:00 -0000", "4 Jan 2005 04:26:00 -0000");
        final PrintWriter out = new PrintWriter(System.out);
        changeSets.dumpYaml(out);
        out.flush();
    }

    public void testShouldCheckout() throws IOException {
        YamlDumpable files = starTeam.checkout("target/starteam/checkout", null);
        String expected = "--- \n- eenie/meenie/minee/mo\n- catch/a/redneck/by\n- the/toe\n";
        StringWriter yaml = new StringWriter();
        files.dumpYaml(yaml);
        System.out.println(yaml);
        assertEquals(expected, yaml.toString());
    }
}

package org.rubyforge.rscm.starteam;

import junit.framework.TestCase;
import org.rubyforge.rscm.ChangeSets;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.TimeZone;

/**
 * @author Aslak Helles&oslash;y
 */
public class StarTeamTest extends TestCase {

    public void testShouldConvertChangesToYaml() throws IOException {
        String userName = "andybarba";
        String password = "";
        String serverName = "192.168.254.21";
        int serverPort = 49201;
        String projectName = "NGST Application";
        String viewName = "NGST Application";

        TimeZone UTC = TimeZone.getTimeZone("UTC");
//        Calendar cal = new GregorianCalendar(UTC, Locale.UK);
        Calendar cal = new GregorianCalendar();
        cal.set(2005, Calendar.JANUARY, 4, 02, 0, 0);
        Date from = cal.getTime();

        cal.set(Calendar.HOUR, 03);
//        cal.set(Calendar.MINUTE, 26);
        Date to = cal.getTime();
        to = null;

        ChangeSets changeSets = new StarTeam(userName, password, serverName, serverPort, projectName, viewName).getChangeSets(from, to, "java");
        final PrintWriter out = new PrintWriter(System.out);
        changeSets.write(out);
        out.flush();
    }
}

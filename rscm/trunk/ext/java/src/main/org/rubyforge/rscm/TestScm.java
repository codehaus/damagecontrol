package org.rubyforge.rscm;

import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Locale;
import java.util.TimeZone;

/**
 * Dummy SCM used in testing only
 *
 * @author Aslak Helles&oslash;y
 */
public class TestScm implements RSCM {
    private String foo;
    private String bar;

    public TestScm() {
    }

    public TestScm(String foo, String bar) {
        this.foo = foo;
        this.bar = bar;
    }

    public YamlDumpable checkout(String dir, String toIdentifier) {
        final YamlList yamlList = new YamlList();
        yamlList.add("eenie/meenie/minee/mo");
        yamlList.add("catch/a/redneck/by");
        yamlList.add("the/toe");
        return yamlList;
    }

    public YamlDumpable getChangeSets(String fromIdentifier, String toIdentifier) {
        ChangeSets changeSets = new ChangeSets();

        changeSets.add(new Change("rinkrank",
                "En to\ntre buksa \nned\n",
                "server/rubyforge/web/AbstractAdminServlet.rb",
                "1.42",
                "1.43",
                "MODIFIED",
                utc(2004, Calendar.NOVEMBER, 30, 04, 52, 24)));

        changeSets.add(new Change("rinkrank",
                "En to\ntre buksa \nned\n",
                "server/rubyforge/web/ProjectServlet.rb",
                "1.71",
                "1.72",
                "MODIFIED",
                utc(2004, Calendar.NOVEMBER, 30, 04, 53, 23)));

        return changeSets;
    }

    private Date utc(int year, int month, int day, int hour, int min, int sec) {
        Calendar cal = new GregorianCalendar(TimeZone.getTimeZone("UTC"), Locale.UK);
        cal.set(Calendar.ZONE_OFFSET, 0);
        cal.set(year, month, day, hour, min, sec);
        return cal.getTime();
    }

}

package org.rubyforge.rscm;

import java.io.IOException;
import java.io.Writer;
import java.io.StringReader;
import java.io.BufferedReader;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Locale;
import java.util.TimeZone;

/**
 * @author Aslak Helles&oslash;y
 */
public class Change implements Comparable {
    private final String developer;
    private final String message;
    private final String path;
    private final String previous_revision;
    private final String revision;
    private final String status;
    private final Date time;
    private static final DateFormat YAML_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.UK);
    private static final TimeZone UTC = TimeZone.getTimeZone("UTC");
    static {
        YAML_FORMAT.setTimeZone(UTC);
    }

    public Change(String developer, String message, String path, String previous_revision, String revision, String status, Date time) {
        this.developer = developer;
        this.message = escape(message);
        this.path = path;
        this.previous_revision = previous_revision;
        this.revision = revision;
        this.status = status;
        this.time = time;
    }

    private String escape(String message) {
        return message.replaceAll("\"", "\\\\\"");
    }

    public void write(Writer out) throws IOException {
        out.write("      - !ruby/object:RSCM::Change \n");
        out.write("        developer: ");
        out.write(developer);
        out.write("\n");
        out.write("        message: \"");
        yamlIndent(message, "          ", out);
        out.write("\"\n");
        out.write("        path: ");
        out.write(path);
        out.write("\n");
        out.write("        previous_revision: \"");
        out.write(previous_revision);
        out.write("\"\n");
        out.write("        revision: \"");
        out.write(revision);
        out.write("\"\n");
        out.write("        status: ");
        out.write(status);
        out.write("\n");
        out.write("        time: ");
        out.write(format(time));
        out.write(" Z\n");
    }

    public static void yamlIndent(String message, String indent, Writer out) throws IOException {
        BufferedReader reader = new BufferedReader(new StringReader(message));
        String line = null;
        while((line = reader.readLine()) != null) {
            out.write(line);
            out.write("\n\n" + indent);
        }
    }

    public static String format(Date time) {
        Calendar cal = new GregorianCalendar(UTC, Locale.UK);
        cal.set(Calendar.ZONE_OFFSET, 0);
        cal.setTime(time);
        YAML_FORMAT.setCalendar(cal);
        final String result = YAML_FORMAT.format(time);
        return result;
    }

    public String getDeveloper() {
        return developer;
    }

    public String getMessage() {
        return message;
    }

    public Date getTime() {
        return time;
    }

    public boolean isSimilarWithinOneMinute(Change change) {
        return developer.equals(change.getDeveloper()) &&
                message.equals(change.getMessage()) &&
                Math.abs(time.getTime() - change.getTime().getTime()) < 60 * 1000;
    }

    public int compareTo(Object o) {
        Change other = (Change) o;
        return path.compareTo(other.path);
    }
}

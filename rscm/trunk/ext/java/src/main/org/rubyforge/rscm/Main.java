package org.rubyforge.rscm;

import java.io.IOException;
import java.io.PrintWriter;
import java.lang.reflect.InvocationTargetException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * Main class intended to be invoked from Ruby. Prints RSCM::ChangeSets YAML to
 * stdout, which can in turn be easily YAML::read into Ruby objects.
 *
 * @author Aslak Helles&oslash;y
 */
public class Main {
    // http://hedwig.sourceforge.net/xref/org/apache/james/util/RFC822Date.html
    private static final DateFormat dx = new SimpleDateFormat("EE, d MMM yyyy HH:mm:ss zzzzz", Locale.US);
    private static final DateFormat dy = new SimpleDateFormat("EE d MMM yyyy HH:mm:ss zzzzz", Locale.US);
    private static final DateFormat dz = new SimpleDateFormat("d MMM yyyy HH:mm:ss zzzzz", Locale.US);

    public static void main(String[] args) throws ParseException, IOException, ClassNotFoundException, NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException {
        Date from = parseRfc822(args[0]);
        Date to = parseRfc822(args[1]);
        String folderName = args[2];
        Class clazz = Class.forName(args[3]);

        // Now instantiate Clazz, passing in the remaining arguments to the ctor.
        final int ctorlen = args.length - 4;
        RSCM rscm = null;
        if(ctorlen == 0) {
            rscm = (RSCM) clazz.newInstance();
        } else {
            String[] ctorargs = new String[ctorlen];
            System.arraycopy(args, 4, ctorargs, 0, ctorlen);
            final Class[] parameterTypes = new Class[ctorlen];
            for (int i = 0; i < parameterTypes.length; i++) {
                parameterTypes[i] = String.class;
            }
            rscm = (RSCM) clazz.getConstructor(parameterTypes).newInstance(ctorargs);
        }
        ChangeSets changeSets = rscm.getChangeSets(from, to, folderName);
        // Print changesets to stdout in YAML form so they can be slurped on the calling ruby side.
        final PrintWriter out = new PrintWriter(System.out);
        changeSets.write(out);
        out.flush();
    }

    private static Date parseRfc822(String rfcdate) throws ParseException {
        try {
            return dx.parse(rfcdate);
        } catch (ParseException e) {
            try {
                return dz.parse(rfcdate);
            } catch (ParseException f) {
                return dy.parse(rfcdate);
            }
        }
    }
}

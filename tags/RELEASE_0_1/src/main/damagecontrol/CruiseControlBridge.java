package damagecontrol;

import net.sourceforge.cruisecontrol.Modification;
import net.sourceforge.cruisecontrol.SourceControl;
import net.sourceforge.cruisecontrol.CruiseControlException;
import org.apache.commons.beanutils.PropertyUtils;

import java.io.PrintStream;
import java.lang.reflect.InvocationTargetException;
import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.Date;
import java.util.Iterator;
import java.util.List;

public class CruiseControlBridge {
    SourceControl sourceControl;
    public static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyyMMdd'T'HHmmss");
    public Date lastbuild;
    public Date now;

    public static void main(String[] args) throws Exception {
        CruiseControlBridge bridge = new CruiseControlBridge();
        bridge.init(args);
        bridge.run(System.out);
    }

    public void init(String[] args) throws ClassNotFoundException, InstantiationException, IllegalAccessException, InvocationTargetException, NoSuchMethodException, ParseException, CruiseControlException {
        sourceControl = (SourceControl) Class.forName(args[0]).newInstance();
        for (int i = 1; i < args.length; i++) {
            String propertyName = args[i].substring(1);
            String propertyValue = args[++i];
            if ("lastbuild".equals(propertyName)) {
                lastbuild = DATE_FORMAT.parse(propertyValue);
            } else if ("now".equals(propertyName)) {
                now = DATE_FORMAT.parse(propertyValue);
            } else {
                PropertyUtils.setProperty(sourceControl, propertyName, propertyValue);
            }
        }
        sourceControl.validate();
    }

    public void run(PrintStream out) {
        List modifications = sourceControl.getModifications(lastbuild, now);
        out.println("<modification-set>");
        for (Iterator iterator = modifications.iterator(); iterator.hasNext();) {
            Modification modification = (Modification) iterator.next();
            out.println(modification.toXml(DATE_FORMAT));
        }
        out.println("</modification-set>");
    }

}

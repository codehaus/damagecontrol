package damagecontrol.util;

import org.apache.log4j.Logger;
import org.apache.log4j.BasicConfigurator;

/**
 * Logging wrapper.
 */
public class Logging {

    static boolean initRequired = true;

    public static Logger getLogger(Class c) {
        initIfRequired();
        return Logger.getLogger(c);
    }

    private static void initIfRequired() {
        if(initRequired) {
            synchronized(Logging.class) {
                if(initRequired) {
                    doInit();
                }
                initRequired = false;
            }
        }
    }

    private static void doInit() {
        BasicConfigurator.configure();
    }
}

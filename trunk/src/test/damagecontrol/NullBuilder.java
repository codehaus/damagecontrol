package damagecontrol;

import damagecontrol.AbstractBuilder;
import damagecontrol.Scheduler;
import damagecontrol.BuildEvent;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.3 $
 */
public class NullBuilder extends AbstractBuilder {
    public static final String SUCCESS_MESSAGE = "Build Successful";
    public static final String FAILED_MESSAGE = "Build Failed";
    private boolean successful;

    public NullBuilder(String name, Scheduler scheduler, Boolean successful) {
        super(name, scheduler);
        this.successful = successful.booleanValue();
    }

    public boolean doBuild(StringBuffer output) {
        output.append(successful ? SUCCESS_MESSAGE :  FAILED_MESSAGE);
        return successful;
    }
}

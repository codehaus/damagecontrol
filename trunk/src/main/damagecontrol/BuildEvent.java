package damagecontrol;

import java.util.EventObject;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class BuildEvent extends EventObject {
    private String output;
    private boolean success;

    public BuildEvent(Object source, boolean success, String output) {
        super(source);
        this.success = success;
        this.output = output;
    }

    public String getOutput() {
        return output;
    }

    public boolean isSuccess() {
        return success;
    }
}

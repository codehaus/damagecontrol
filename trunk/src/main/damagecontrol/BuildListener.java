package damagecontrol;

import java.util.EventListener;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public interface BuildListener extends EventListener {
    void buildFinished(BuildEvent evt);
}

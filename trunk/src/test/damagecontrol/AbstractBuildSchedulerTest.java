package damagecontrol;

import junit.framework.TestCase;

/**
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public abstract class AbstractBuildSchedulerTest extends TestCase {
    public void testBuild() {
        //createBuilder().requestBuild();
    }

    protected abstract BuildScheduler createBuildScheduler();
}

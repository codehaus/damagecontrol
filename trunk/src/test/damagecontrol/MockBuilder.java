package damagecontrol;

import EDU.oswego.cs.dl.util.concurrent.Latch;
import junit.framework.Assert;

/**
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.6 $
 */
public class MockBuilder extends AbstractBuilder {
    private boolean wasBuilt = false;
    private String output;
    private Latch buildLatch = new Latch();

    public MockBuilder() {
        super("MockBuilder", new DirectScheduler());
    }

    public MockBuilder(String output) {
        this();
        this.output = output;
    }

    public MockBuilder(String name, Scheduler scheduler) {
        super(name, scheduler);
    }

    public synchronized void build() {
        wasBuilt = true;
        super.build();
        buildLatch.release();
    }

    public boolean doBuild(StringBuffer output) {
        output.append(this.output);
        return true;
    }

    public void waitForBuildComplete() {
        try {
            Assert.assertTrue("timeout, was never built", buildLatch.attempt(1000));
        } catch (InterruptedException e) {
            Assert.fail();
        }
    }

    public boolean wasBuilt() {
        return wasBuilt;
    }
}

package damagecontrol;

import EDU.oswego.cs.dl.util.concurrent.Latch;

/**
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.4 $
 */
public class MockBuilder extends AbstractBuilder {
    private boolean wasBuilt;
    private Latch nextBuildLatch = new Latch();
    private String output;

    public MockBuilder() {
        super("MockBuilder", new DirectScheduler());
    }

    public MockBuilder(String output) {
        this();
        this.output = output;
    }

    public void build() {
        synchronized (this) {
            nextBuildLatch.release();
            nextBuildLatch = new Latch();
        }
        wasBuilt = true;
        fireBuildFinished(new BuildEvent(this, true, output));
    }

    public synchronized void waitForBuildComplete() {
        try {
            nextBuildLatch.attempt(1000);
        } catch (InterruptedException e) {
        }
    }

    public boolean wasBuilt() {
        return wasBuilt;
    }
}

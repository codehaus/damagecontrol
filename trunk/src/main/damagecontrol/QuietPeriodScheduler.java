package damagecontrol;

import EDU.oswego.cs.dl.util.concurrent.Latch;


/**
 * Commits to an SCM are sometimes  done in several operations,
 * (depending on whether the SCM supports atomic commits).
 * In such cases, a build for a particular project should not be invoked until
 * that project has been quiet for a while.
 *
 * This build scheduler will defer the invocation of a builder until
 * a quiet period. A quiet period means that no build requests have been
 * received within a certain period.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.4 $
 */
public class QuietPeriodScheduler extends DecoratingScheduler {
    private Clock clock;
    private long quietPeriodMillis;

    Thread buildThread;
    private String builderToBuild = null;
    private long timeToBuild;
    private Latch buildRequestedLatch = new Latch();

    public QuietPeriodScheduler(Clock clock, long quietPerionMilliseconds) {
        super(new DirectScheduler());
        this.clock = clock;
        this.quietPeriodMillis = quietPerionMilliseconds;
    }

    public void execute() {
        start();
    }

    public void start() {
        buildThread = new Thread(new Runnable() {
            public void run() {
                synchronized (QuietPeriodScheduler.this) {
                    QuietPeriodScheduler.this.notifyAll();
                }
                try {
                    while (!Thread.currentThread().isInterrupted()) {
                        waitForBuildRequested();
                        waitForTimeToBuild();
                        QuietPeriodScheduler.super.requestBuild(builderToBuild);
                    }
                } catch (InterruptedException e) {
                }
            }
        });
        buildThread.start();
    }

    private void waitForTimeToBuild() throws InterruptedException {
        while (timeToBuild > clock.currentTimeMillis()) {
            clock.waitUntil(timeToBuild);
        }
    }

    private void waitForBuildRequested() throws InterruptedException {
        buildRequestedLatch.acquire();
        synchronized (this) {
            buildRequestedLatch = new Latch();
        }
        assert builderToBuild != null;
    }

    public synchronized void requestBuild(final String builderName) {
        getBuilder(builderName); // provokes exception as early possible
        builderToBuild = builderName;
        timeToBuild = clock.currentTimeMillis() + quietPeriodMillis;
        notifyBuildRequested();
    }

    private void notifyBuildRequested() {
        buildRequestedLatch.release();
    }

    public void stop() throws InterruptedException {
        if (buildThread != null) {
            buildThread.interrupt();
            buildThread.join(1000);
        }
    }

    public void setQuietPeriodMillis(long millis) {
        this.quietPeriodMillis = millis;
    }

}

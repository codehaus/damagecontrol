package damagecontrol;

import java.util.List;
import java.util.LinkedList;
import java.util.Map;
import java.util.HashMap;

/**
 * Commits to an SCM are frequently done in several operations, and
 * a build for a particular project should not be invoked until
 * that project has been quiet for a while.
 *
 * This build scheduler will defer the invocation of a builder until
 * a quiet period. A quiet period means that no build requests have been
 * received within a certain period.
 *
 * The requested builds will be queued up. Requesting a build that is already in the
 * queue will push it back in the queue, allowing other builds to be handled before.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class QuietPeriodBuildScheduler implements BuildScheduler {
    /**
     * Sync lock used to keep waiting until quiet period is fulfilled.
     */
    private final Object lock = new Object();
    private final List builderQueue = new LinkedList();

    private long pollIntervalMilliseconds;
    private final long quietPerionMilliseconds;

    private Builder currentlyRunningBuilder;

    private Runnable builder = new Runnable() {
        public void run() {
            while (true) {
                synchronized(lock) {
                    try {
                        if (builderQueue.isEmpty()) {
                            // Wait forever (until we're notified)
                            System.out.println("Waiting forever");
                            lock.wait();
                        }else{
                            // grab the first builder in the queue and see if it has been
                            // idle (not requested) long enough (for the quiet period)
                            Builder firstBuilderInQueue = (Builder) builderQueue.get(0);
                            long lastBuildRequestTime = ((Long) buildRequestTimes.get(firstBuilderInQueue)).longValue();
                            long elapsedTime = System.currentTimeMillis() - lastBuildRequestTime;
                            System.out.println("Elapsed time for " + firstBuilderInQueue + ":" + elapsedTime);
                            if(elapsedTime > quietPerionMilliseconds) {
                                System.out.println("Building " + firstBuilderInQueue);
                                currentlyRunningBuilder = firstBuilderInQueue;
                                builderQueue.remove(0);
                                currentlyRunningBuilder.build();
                                currentlyRunningBuilder = null;
                            } else {
                                System.out.println("Waiting polltime");
                                lock.wait(pollIntervalMilliseconds);
                            }
                        }
                    } catch (InterruptedException e) {
                        // shouldn't happen
                    } finally {
                        currentlyRunningBuilder = null;
                    }
                }
            }
        }
    };

    private Thread buildThread = new Thread(builder);
    private Map buildRequestTimes = new HashMap();

    public QuietPeriodBuildScheduler(long pollIntervalMilliseconds, long quietPerionMilliseconds) {
        this.pollIntervalMilliseconds = pollIntervalMilliseconds;
        this.quietPerionMilliseconds = quietPerionMilliseconds;
        buildThread.start();
    }

    public void requestBuild(Builder requestedBuilder) {
        // Put the builder in the back of the queue.
        builderQueue.remove(requestedBuilder);
        builderQueue.add(requestedBuilder);

        synchronized (lock) {
            // Register the time build was requested for this builder.
            buildRequestTimes.put(requestedBuilder, new Long(System.currentTimeMillis()));
            lock.notify();
        }
    }

    public Builder getCurrentlyRunningBuilder() {
        return currentlyRunningBuilder;
    }
}

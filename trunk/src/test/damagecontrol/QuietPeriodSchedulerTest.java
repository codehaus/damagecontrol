package damagecontrol;

import EDU.oswego.cs.dl.util.concurrent.Latch;

/**
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class QuietPeriodSchedulerTest extends AbstractSchedulerTest {
    private static final int POLL_INTERVAL_MILLIS = 100;
    private static final int QUIET_INTERVAL_MILLIS = 300;
    private static final int BUILD_REQUEST_START_TIME = 1223234;;
    private QuietPeriodScheduler scheduler;
    private FakeClock clock;


    public static class FakeClock implements Clock {
        Latch timeChangedLatch = new Latch();
        private long currentTimeMillis;

        public void waitUntil(long timeInMillis) {
            while (true) {
                synchronized (this) {
                    try {
                        assertTrue(timeChangedLatch.attempt(1000));
                    } catch (InterruptedException e) {
                        fail();
                    }
                    if (timeInMillis >= currentTimeMillis) {
                        return;
                    }
                }
            }
        }

        public long currentTimeMillis() {
            return currentTimeMillis;
        }

        public void setCurrentTimeMillis(int currentTimeMillis) {
            this.currentTimeMillis = currentTimeMillis;
            synchronized (this) {
                timeChangedLatch.release();
                timeChangedLatch = new Latch();
            }
        }
    }

    protected void setUp() throws Exception {
        clock = new FakeClock();
        scheduler = (QuietPeriodScheduler) createScheduler();
    }

    protected void tearDown() throws Exception {
        scheduler.stop();
        if (scheduler.buildThread != null) {
            scheduler.buildThread.join(1000);
            assertFalse(scheduler.buildThread.isAlive());
        }
    }

    protected Scheduler createScheduler() {
        return new QuietPeriodScheduler(clock, POLL_INTERVAL_MILLIS, QUIET_INTERVAL_MILLIS);
    }

    public void testBuildDoesntStartUntilAQuietPeriodHasElapsed() {
        clock.setCurrentTimeMillis(BUILD_REQUEST_START_TIME);
        MockBuilder builder = new MockBuilder();
        scheduler.requestBuild(builder);
        clock.setCurrentTimeMillis(BUILD_REQUEST_START_TIME + QUIET_INTERVAL_MILLIS + 1);
        assertTrue(builder.wasBuilt());
    }


//    public void testBuildDoesntStartUntilAQuietPeriodHasElapsed() throws InterruptedException {
//        Scheduler buildScheduler = createScheduler();
//
//        Builder builder = new MockBuilder("dummy", BUILD_TIME_MILLIS);
//        buildScheduler.requestBuild(builder);
//        // Sleep half of the quiet time
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 2);
//        // Sleep half of the quiet time plus a little more to be safe
//        Thread.sleep(QUIET_INTERVAL_MILLIS );
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 10);
//
//        assertEquals(0, builder.getBuildNumber());
//        Thread.sleep(BUILD_TIME_MILLIS / 2);
//        assertEquals(0, builder.getBuildNumber());
//        Thread.sleep(BUILD_TIME_MILLIS / 2);
//        Thread.sleep(BUILD_TIME_MILLIS / 10);
//        assertEquals(1, builder.getBuildNumber());
//    }

//    public void testBuildIsSusupendedAsLongAsMultipleRequestsAreIssued() throws InterruptedException {
//        Scheduler buildScheduler = createScheduler();
//
//        Builder builder = new MockBuilder("dummy", BUILD_TIME_MILLIS);
//
//        buildScheduler.requestBuild(builder);
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 2);
//
//        buildScheduler.requestBuild(builder);
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 2);
//
//        buildScheduler.requestBuild(builder);
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 2);
//
//        buildScheduler.requestBuild(builder);
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 2);
//        assertEquals(0, builder.getBuildNumber());
//
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 2);
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 10);
//        assertEquals(0, builder.getBuildNumber());
//
//        Thread.sleep(BUILD_TIME_MILLIS);
//        assertEquals(1, builder.getBuildNumber());
//    }

//    public void testWhenMultipleBuildersAreRequestedTheBusyOnesGetPushedBackInTheQueue() throws InterruptedException {
//        Scheduler buildScheduler = createScheduler();
//
//        Builder mickey = new MockBuilder("Mickey", BUILD_TIME_MILLIS);
//        Builder goofy = new MockBuilder("Goofy", BUILD_TIME_MILLIS);
//        Builder donald = new MockBuilder("Donald", BUILD_TIME_MILLIS);
//
//        buildScheduler.requestBuild(mickey);
//        buildScheduler.requestBuild(goofy);
//        buildScheduler.requestBuild(donald);
//
//        // Wait half the period and ask mickey to build again. Should build goofy instead.
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 4);
//        buildScheduler.requestBuild(donald);
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 4);
//        buildScheduler.requestBuild(goofy);
//        Thread.sleep(QUIET_INTERVAL_MILLIS / 4);
//        buildScheduler.requestBuild(mickey);
//
//        Thread.sleep(BUILD_TIME_MILLIS );
//        Thread.sleep(BUILD_TIME_MILLIS );
//        Thread.sleep(BUILD_TIME_MILLIS );
//    }

}

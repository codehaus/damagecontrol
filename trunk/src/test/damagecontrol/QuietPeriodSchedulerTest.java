package damagecontrol;

/**
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.3 $
 */
public class QuietPeriodSchedulerTest extends AbstractSchedulerTest {
    private static final int QUIET_INTERVAL_MILLIS = 300;
    private QuietPeriodScheduler scheduler;
    private FakeClock clock;
    public static final int START_TIME = 10;


    protected void setUp() throws Exception {
        clock = new FakeClock();
        scheduler = new QuietPeriodScheduler(clock, 0);
        scheduler.start();
    }

    protected void tearDown() throws Exception {
        scheduler.stop();
        if (scheduler.buildThread != null) {
            scheduler.buildThread.join(1000);
//            assertFalse(scheduler.buildThread.isAlive());
        }
    }

    protected Scheduler getScheduler() {
        return scheduler;
    }

    public void testBuildDoesntStartUntilQuietPeriodHasElapsed() {
        scheduler.setQuietPeriodMillis(QUIET_INTERVAL_MILLIS);
        clock.changeTime(START_TIME);
        MockBuilder builder = new MockBuilder("builder", scheduler);
        scheduler.requestBuild("builder");
        clock.waitForWaiter();

        assertFalse(builder.wasBuilt());
        clock.changeTime(START_TIME + QUIET_INTERVAL_MILLIS + 1);
        builder.waitForBuildComplete();
        assertTrue("did not build", builder.wasBuilt());
    }

    public void testSecondBuildRequestWillWaitAdditionalQuietPeriod() {
        scheduler.setQuietPeriodMillis(QUIET_INTERVAL_MILLIS);

        int waitSomeTime = 10;

        clock.changeTime(START_TIME);
        MockBuilder builder = new MockBuilder("builder", scheduler);
        scheduler.requestBuild("builder");
        clock.waitForWaiter();

        assertFalse(builder.wasBuilt());
        clock.changeTime(START_TIME + waitSomeTime);
        scheduler.requestBuild("builder");

        assertFalse(builder.wasBuilt());
        scheduler.requestBuild("builder");
        assertFalse(builder.wasBuilt());
        clock.changeTime(START_TIME + QUIET_INTERVAL_MILLIS + 1);
        assertFalse(builder.wasBuilt());

        clock.changeTime(START_TIME + QUIET_INTERVAL_MILLIS + waitSomeTime + 1);
        builder.waitForBuildComplete();
        assertTrue("did not build", builder.wasBuilt());
    }

}

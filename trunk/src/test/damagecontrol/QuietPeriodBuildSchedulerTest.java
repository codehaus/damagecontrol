package damagecontrol;

/**
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class QuietPeriodBuildSchedulerTest extends AbstractBuildSchedulerTest {
    private static final int POLL_TIME_MILLIS = 100;
    private static final int QUIET_TIME_MILLIS = 300;
    private static final int BUILD_TIME_MILLIS = 400;


    protected BuildScheduler createBuildScheduler() {
        return new QuietPeriodBuildScheduler(POLL_TIME_MILLIS, QUIET_TIME_MILLIS);
    }

    public void testBuildDoesntStartUntilAQuietPeriodHasElapsed() throws InterruptedException {
        BuildScheduler buildScheduler = createBuildScheduler();

        Builder builder = new MockBuilder("dummy", BUILD_TIME_MILLIS);
        buildScheduler.requestBuild(builder);
        assertNull("BuildScheduler shouldn't kick off right away", buildScheduler.getCurrentlyRunningBuilder());
        // Sleep half of the quiet time
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        assertNull("BuildScheduler should still not kick off", buildScheduler.getCurrentlyRunningBuilder());
        // Sleep half of the quiet time plus a little more to be safe
        Thread.sleep(QUIET_TIME_MILLIS );
        Thread.sleep(QUIET_TIME_MILLIS / 10);

        assertEquals("BuildScheduler should have kicked off by now", builder, buildScheduler.getCurrentlyRunningBuilder());
        assertEquals(0, builder.getBuildNumber());
        Thread.sleep(BUILD_TIME_MILLIS / 2);
        assertEquals(0, builder.getBuildNumber());
        Thread.sleep(BUILD_TIME_MILLIS / 2);
        Thread.sleep(BUILD_TIME_MILLIS / 10);
        assertEquals(1, builder.getBuildNumber());
        assertNull("BuildScheduler should be done by now", buildScheduler.getCurrentlyRunningBuilder());
    }

    public void testBuildIsSusupendedAsLongAsMultipleRequestsAreIssued() throws InterruptedException {
        BuildScheduler buildScheduler = createBuildScheduler();

        Builder builder = new MockBuilder("dummy", BUILD_TIME_MILLIS);

        buildScheduler.requestBuild(builder);
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        assertNull(buildScheduler.getCurrentlyRunningBuilder());

        buildScheduler.requestBuild(builder);
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        assertNull(buildScheduler.getCurrentlyRunningBuilder());

        buildScheduler.requestBuild(builder);
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        assertNull(buildScheduler.getCurrentlyRunningBuilder());

        buildScheduler.requestBuild(builder);
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        assertNull(buildScheduler.getCurrentlyRunningBuilder());
        assertEquals(0, builder.getBuildNumber());

        Thread.sleep(QUIET_TIME_MILLIS / 2);
        Thread.sleep(QUIET_TIME_MILLIS / 10);
        assertEquals(builder, buildScheduler.getCurrentlyRunningBuilder());
        assertEquals(0, builder.getBuildNumber());

        Thread.sleep(BUILD_TIME_MILLIS);
        assertNull(buildScheduler.getCurrentlyRunningBuilder());
        assertEquals(1, builder.getBuildNumber());
    }

    public void testWhenMultipleBuildersAreRequestedTheBusyOnesGetPushedBackInTheQueue() throws InterruptedException {
        BuildScheduler buildScheduler = createBuildScheduler();

        Builder mickey = new MockBuilder("Mickey", BUILD_TIME_MILLIS);
        Builder goofy = new MockBuilder("Goofy", BUILD_TIME_MILLIS);
        Builder donald = new MockBuilder("Donald", BUILD_TIME_MILLIS);

        buildScheduler.requestBuild(mickey);
        buildScheduler.requestBuild(goofy);
        buildScheduler.requestBuild(donald);

        // Wait half the period and ask mickey to build again. Should build goofy instead.
        Thread.sleep(QUIET_TIME_MILLIS / 4);
        buildScheduler.requestBuild(donald);
        Thread.sleep(QUIET_TIME_MILLIS / 4);
        buildScheduler.requestBuild(goofy);
        Thread.sleep(QUIET_TIME_MILLIS / 4);
        buildScheduler.requestBuild(mickey);

        Thread.sleep(BUILD_TIME_MILLIS );
        assertEquals(donald, buildScheduler.getCurrentlyRunningBuilder());
        Thread.sleep(BUILD_TIME_MILLIS );
        assertEquals(goofy, buildScheduler.getCurrentlyRunningBuilder());
        Thread.sleep(BUILD_TIME_MILLIS );
        assertEquals(mickey, buildScheduler.getCurrentlyRunningBuilder());
    }

}

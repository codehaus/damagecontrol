package damagecontrol;

/**
 * 
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class QuietPeriodBuildSchedulerTest extends AbstractBuildSchedulerTest {
    private static final int QUIET_TIME_MILLIS = 80;
    private static final int BUILD_TIME_MILLIS = 90;

    private Builder builder;

    public void setUp() {
        builder = new MockBuilder(BUILD_TIME_MILLIS);
    }

    protected BuildScheduler createBuildScheduler() {
        return new QuietPeriodBuildScheduler(QUIET_TIME_MILLIS, builder);
    }

    public void testBuildDoesntStartUntilAQuietPeriodHasElapsed() throws InterruptedException {
        BuildScheduler buildScheduler = createBuildScheduler();

        buildScheduler.requestBuild();
        assertFalse("BuildScheduler shouldn't kick off right away", buildScheduler.isBuildRunning());
        // Sleep half of the quiet time
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        assertFalse("BuildScheduler should still not kick off", buildScheduler.isBuildRunning());
        // Sleep half of the quiet time plus a little more to be safe
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        Thread.sleep(QUIET_TIME_MILLIS / 10);

        assertTrue("BuildScheduler should have kicked off by now", buildScheduler.isBuildRunning());
        assertEquals(0, builder.getBuildNumber());
        Thread.sleep(BUILD_TIME_MILLIS / 2);
        assertEquals(0, builder.getBuildNumber());
        Thread.sleep(BUILD_TIME_MILLIS / 2);
        Thread.sleep(BUILD_TIME_MILLIS / 10);
        assertEquals(1, builder.getBuildNumber());
        assertFalse("BuildScheduler should be done by now", buildScheduler.isBuildRunning());
    }

    public void testBuildIsSusupendedAsLongAsMultipleRequestsAreIssued() throws InterruptedException {
        BuildScheduler buildScheduler = createBuildScheduler();

        buildScheduler.requestBuild();
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        assertFalse(buildScheduler.isBuildRunning());

        buildScheduler.requestBuild();
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        assertFalse(buildScheduler.isBuildRunning());

        buildScheduler.requestBuild();
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        assertFalse(buildScheduler.isBuildRunning());

        buildScheduler.requestBuild();
        Thread.sleep(QUIET_TIME_MILLIS / 2);
        assertFalse(buildScheduler.isBuildRunning());
        assertEquals(0, builder.getBuildNumber());

        Thread.sleep(QUIET_TIME_MILLIS);
        assertTrue(buildScheduler.isBuildRunning());
        assertEquals(0, builder.getBuildNumber());

        Thread.sleep(BUILD_TIME_MILLIS);
        assertFalse(buildScheduler.isBuildRunning());
        assertEquals(1, builder.getBuildNumber());
    }



}

package damagecontrol;

import junit.framework.TestCase;

/**
 * Baseclass for testing of scheduler. Extend this class to test a particular
 * Scheduler implementation.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public abstract class AbstractSchedulerTest extends TestCase {
    public void testRequestBuildWillBeHonouredEventually() throws NoSuchBuilderException {
        MockBuilder builder = new MockBuilder();
        Scheduler scheduler = createScheduler();
        scheduler.registerBuilder("projectName", builder);
        scheduler.requestBuild("projectName");
        builder.waitForBuildComplete();
        assertTrue(builder.wasBuilt());
    }

    public void testRequestBuildOnNonRegisteredBuilderWillFail() {
        Scheduler scheduler = createScheduler();
        try {
            scheduler.requestBuild("nonExistentProject");
            fail();
        } catch (NoSuchBuilderException e) {
        }
    }

    protected abstract Scheduler createScheduler();
}

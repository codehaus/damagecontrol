package damagecontrol;

import junit.framework.TestCase;

/**
 * Baseclass for testing of scheduler. Extend this class to test a particular
 * Scheduler implementation.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public abstract class AbstractSchedulerTest extends TestCase {
    public void testRequestBuildWillBeHonouredEventually() throws NoSuchBuilderException {
        Scheduler scheduler = getScheduler();

        MockBuilder builder = new MockBuilder("projectName", scheduler);
        scheduler.requestBuild("projectName");
        builder.waitForBuildComplete();
        assertTrue(builder.wasBuilt());
    }

    public void testRequestBuildOnNonRegisteredBuilderWillFail() {
        Scheduler scheduler = getScheduler();

        try {
            scheduler.requestBuild("nonExistentProject");
            fail();
        } catch (NoSuchBuilderException e) {
        }
    }

    protected abstract Scheduler getScheduler();
}

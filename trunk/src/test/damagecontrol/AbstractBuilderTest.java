package damagecontrol;

import junit.framework.TestCase;

/**
 * Baseclass for testing of builder. Extend this class to test a particular
 * Builder implementation.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public abstract class AbstractBuilderTest extends TestCase {
    private boolean wasCalled;

    public void testSucceedingBuilderWillNotifyListenersWithSuccessfulBuild() {
        build(true, createSuccessfulBuilder());
    }

    public void testFailingBuilderWillNotifyListenersWithFailingBuild() {
        build(false, createFailingBuilder());
    }

    private void build(final boolean success, final Builder builder) {
        builder.addBuildListener(new BuildListener() {
            public void buildFinished(BuildEvent evt) {
                wasCalled = true;
                assertNotNull(evt);
                assertEquals(success, evt.isSuccess());
                assertSame(builder, evt.getSource());
                assertNotNull(evt.getOutput());
            }
        });
        assertFalse(wasCalled);
        builder.build();
        assertTrue(wasCalled);
    }

    protected abstract Builder createSuccessfulBuilder();
    protected abstract Builder createFailingBuilder();
}

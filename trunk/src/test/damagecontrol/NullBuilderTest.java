package damagecontrol;

import damagecontrol.testtest.NullBuilder;
import damagecontrol.AbstractBuilderTest;
import damagecontrol.Builder;
import damagecontrol.DirectScheduler;

/**
 * Tests the NullBuilder. This class merely exists to test that the functionality
 * in our superclass is correct.
 *
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class NullBuilderTest extends AbstractBuilderTest {
    protected Builder createSuccessfulBuilder() {
        return new NullBuilder("test", new DirectScheduler(), Boolean.TRUE);
    }

    protected Builder createFailingBuilder() {
        return new NullBuilder("test", new DirectScheduler(), Boolean.FALSE);
    }
}

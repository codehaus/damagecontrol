package damagecontrol.util;

import junit.framework.TestCase;
import org.apache.log4j.Logger;

/**
 * Tests for Logging class
 */
public class LoggingTest extends TestCase {

    public void testInitIsCorrect() {
        assertTrue(Logging.initRequired);
        Logger foo = Logging.getLogger(LoggingTest.class);
        assertFalse(Logging.initRequired);
    }

    public void testCorrectLoggerIsReturned() {
        Logger l = Logging.getLogger(LoggingTest.class);
        assertEquals(LoggingTest.class.getName(), l.getName());
    }
}

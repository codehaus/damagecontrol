package damagecontrol;

import junit.framework.TestCase;

public class SystemClockTest extends TestCase {
    private SystemClock systemClock;

    protected void setUp() throws Exception {
        super.setUp();

        systemClock = new SystemClock();
    }

    public void testCurrentTimeMillisIsSameAsSystemTime() {
        assertTrue(System.currentTimeMillis() == systemClock.currentTimeMillis() ||
                System.currentTimeMillis() == systemClock.currentTimeMillis() + 1);
    }

    public void testWaitUntilReturnsAtCorrectTime() throws InterruptedException {
        long waitUntil = System.currentTimeMillis() + 20; // wait 20 ms
        systemClock.waitUntil(waitUntil);
        assertTrue(waitUntil <= System.currentTimeMillis());
    }
}

package damagecontrol;

import junit.framework.Assert;
import EDU.oswego.cs.dl.util.concurrent.Latch;

public class FakeClock implements Clock {
    private long currentTimeMillis;
    private Latch hasWaiterLatch = new Latch();
    private Latch currentTimeChangedLatch = new Latch();

    public void waitUntil(long timeToWaitUntil) {
        System.out.println("current time " + currentTimeMillis);
        System.out.println("waiting for " + timeToWaitUntil);

        hasWaiterLatch.release();

        while (!Thread.currentThread().isInterrupted()) {
            synchronized (this) {
                if (currentTimeMillis >= timeToWaitUntil) {
                    return;
                }
            }
            try {
                currentTimeChangedLatch.attempt(1000);
            } catch (InterruptedException e) {
            }
        }
    }

    public long currentTimeMillis() {
        return currentTimeMillis;
    }

    public synchronized void changeTime(int currentTimeMillis) {
        System.out.println("changing time to " + currentTimeMillis);
        this.currentTimeMillis = currentTimeMillis;
        currentTimeChangedLatch.release();
        currentTimeChangedLatch = new Latch();
    }

    public synchronized void waitForWaiter() {
        System.out.println("waitForWaiter");
        try {
            Assert.assertTrue("timeout, no waiter arrived", hasWaiterLatch.attempt(1000));
        } catch (InterruptedException e) {
            Assert.fail();
        }
    }
}

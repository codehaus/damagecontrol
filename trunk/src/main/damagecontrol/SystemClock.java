package damagecontrol;

public class SystemClock implements Clock {
    public void waitUntil(long timeInMillis) throws InterruptedException {
        long diff = timeInMillis - currentTimeMillis();
        if (diff <= 0) {
            return;
        }
        Thread.sleep(diff);
    }

    public long currentTimeMillis() {
        return System.currentTimeMillis();
    }
}
